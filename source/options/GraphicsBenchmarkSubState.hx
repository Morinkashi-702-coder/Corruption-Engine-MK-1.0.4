package options;

import backend.AutoGraphics;
import backend.AutoGraphics.GraphicsRecommendation;
import backend.AutoGraphics.GraphicsSettingsSnapshot;
import flixel.addons.display.FlxRuntimeShader;

/** Two bounded scenes. Counts actual draw intervals; ignores warm-up and restarts on focus loss. */
class GraphicsBenchmarkSubState extends MusicBeatSubstate
{
	static final FRAGMENT = '#pragma header
		uniform float testTime;
		void main() {
			vec2 uv = openfl_TextureCoordv;
			vec4 sum = vec4(0.0);
			for (int i = 0; i < 9; i++) {
				float f = float(i) - 4.0;
				vec2 p = clamp(uv + vec2(sin(uv.y * 8.0 + testTime), cos(uv.x * 8.0 + testTime)) * f * 0.002, 0.0, 1.0);
				sum += flixel_texture2D(bitmap, p);
			}
			vec3 tint = vec3(0.12 + uv.x * 0.2, 0.08 + uv.y * 0.15, 0.2);
			gl_FragColor = vec4(sum.rgb / 9.0 * tint, sum.a / 9.0 * 0.28);
		}';

	var done:Null<GraphicsRecommendation>->Void;
	var scene:GraphicsBenchmarkScene;
	var testCamera:FlxCamera;
	var proposal:GraphicsRecommendation;
	var loadingMS:Float;
	var status:FlxText;
	var effectPlane:FlxSprite;
	var testShader:FlxRuntimeShader;
	var current:GraphicsSettingsSnapshot;
	var samples:Array<Array<Float>> = [[], [], []];
	var phase:Int = 0;
	var shaderStatus:String = 'unknown';
	var started:Float;
	var lastFrame:Float = 0;
	var focused:Bool = true;
	var finished:Bool = false;
	var oldDraw:Int;
	var oldUpdate:Int;
	var restored:Bool = false;
	var ratesCaptured:Bool = false;

	public function new(done:Null<GraphicsRecommendation>->Void)
	{
		super();
		this.done = done;
	}

	override public function create():Void
	{
		super.create();
		testCamera = new FlxCamera();
		FlxG.cameras.add(testCamera, false);
		cameras = [testCamera];
		current = AutoGraphics.snapshot();
		oldDraw = FlxG.drawFramerate;
		oldUpdate = FlxG.updateFramerate;
		ratesCaptured = true;
		FlxG.updateFramerate = 120;
		FlxG.drawFramerate = 120;
		var window = FlxG.stage.application.window;
		window.onFocusIn.add(focusIn);
		window.onFocusOut.add(focusOut);
		window.onResize.add(resized);

		add(new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF09080D));
		var title = new FlxText(50, 30, FlxG.width - 100, 'Performance test / Prueba de rendimiento');
		title.setFormat(Paths.font('VollkornRegular-ZVJEZ.ttf'), 32, FlxColor.WHITE, CENTER);
		add(title);
		var details = new FlxText(70, 90, FlxG.width - 140, AutoGraphics.hardwareSummary());
		details.setFormat(Paths.font('vcr.ttf'), 16, 0xFFDDDDDD, LEFT);
		add(details);

		var loadStart = haxe.Timer.stamp();
		scene = new GraphicsBenchmarkScene();
		scene.configure(false, true);
		add(scene);
		loadingMS = (haxe.Timer.stamp() - loadStart) * 1000;
		effectPlane = new FlxSprite().makeGraphic(2, 2, FlxColor.WHITE);
		effectPlane.setGraphicSize(FlxG.width, FlxG.height);
		effectPlane.updateHitbox();
		effectPlane.visible = false;
		add(effectPlane);
		status = new FlxText(70, 560, FlxG.width - 140, '');
		status.setFormat(Paths.font('VollkornRegular-ZVJEZ.ttf'), 22, FlxColor.WHITE, CENTER);
		add(status);
		started = haxe.Timer.stamp();
	}

	/** Check the exact expanded GLSL before giving it to OpenFL's error logger. */
	function prepareShader():String
	{
		#if desktop
		try
		{
			var gl = FlxG.stage.application.window.context.gl;
			if (gl == null) return 'unknown';
			testShader = new FlxRuntimeShader(FRAGMENT);
			var vertex = gl.createShader(gl.VERTEX_SHADER);
			var fragment = gl.createShader(gl.FRAGMENT_SHADER);
			var program = gl.createProgram();
			var valid = false;
			try
			{
				var prefix = '#ifdef GL_ES\nprecision mediump float;\n#endif\n';
				gl.shaderSource(vertex, prefix + testShader.glVertexSource);
				gl.shaderSource(fragment, prefix + testShader.glFragmentSource);
				gl.compileShader(vertex);
				gl.compileShader(fragment);
				if (gl.getShaderParameter(vertex, gl.COMPILE_STATUS) != 0
					&& gl.getShaderParameter(fragment, gl.COMPILE_STATUS) != 0)
				{
					gl.bindAttribLocation(program, 0, 'openfl_Position');
					gl.attachShader(program, vertex);
					gl.attachShader(program, fragment);
					gl.linkProgram(program);
					valid = gl.getProgramParameter(program, gl.LINK_STATUS) != 0;
				}
			}
			catch (_:Dynamic) {}
			if (program != null) gl.deleteProgram(program);
			if (vertex != null) gl.deleteShader(vertex);
			if (fragment != null) gl.deleteShader(fragment);
			if (!valid) return 'failed';
			testShader.setFloat('testTime', 0);
			effectPlane.shader = testShader;
			effectPlane.visible = true;
			return 'passed';
		}
		catch (_:Dynamic) return 'unknown';
		#else
		return 'unknown';
		#end
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (finished) return;
		if (FlxG.keys.justPressed.ESCAPE || controls.BACK) { finish(null); return; }
		if (!focused) return;
		var time = haxe.Timer.stamp() - started;
		scene.animate(time);
		if (effectPlane.visible && testShader != null) testShader.setFloat('testTime', time * 0.4);
		status.text = (phase == 0 ? '1/3 Gameplay scene / Escena de juego' : phase == 1
			? '2/3 Test shader / Shader de prueba' : '3/3 Verify settings / Comprobar ajustes')
			+ ': ' + Std.int(Math.min(100, (phase * 5 + time) / 15 * 100))
			+ '%\nKeep window focused / Manten la ventana activa\nESC: cancel / cancelar';
		if (time >= 5)
		{
			if (phase == 0)
			{
				shaderStatus = prepareShader();
				if (shaderStatus != 'passed') { beginVerification(); return; }
				phase = 1;
				started = haxe.Timer.stamp();
				lastFrame = 0;
			}
			else if (phase == 1) beginVerification();
			else
			{
				AutoGraphics.verify(proposal, samples[2], current);
				proposal.loadingMS = loadingMS;
				finish(proposal);
			}
		}
	}

	function beginVerification():Void
	{
		var refreshRate = 60;
		try { refreshRate = FlxG.stage.application.window.displayMode.refreshRate; } catch (_:Dynamic) {}
		proposal = AutoGraphics.recommend(samples[0], samples[1], shaderStatus,
			AutoGraphics.memoryGB(), refreshRate, current);
		if (!scene.representative)
		{
			proposal.reliable = false;
			proposal.profile = 'Keep settings / Mantener ajustes';
			proposal.reason = 'Test assets missing / Faltan recursos para la prueba.';
		}
		if (!proposal.reliable) { finish(proposal); return; }
		phase = 2;
		scene.configure(proposal.lowQuality, proposal.antialiasing);
		effectPlane.visible = proposal.shaders && shaderStatus == 'passed';
		if (proposal.framerate > FlxG.drawFramerate) FlxG.updateFramerate = proposal.framerate;
		FlxG.drawFramerate = proposal.framerate;
		FlxG.updateFramerate = proposal.framerate;
		started = haxe.Timer.stamp();
		lastFrame = 0;
	}

	override public function draw():Void
	{
		try { super.draw(); }
		catch (error:Dynamic)
		{
			if (phase != 1) throw error;
			effectPlane.visible = false;
			effectPlane.shader = null;
			shaderStatus = 'failed';
			samples[1] = [];
			beginVerification();
			return;
		}
		if (!focused || finished) return;
		var now = haxe.Timer.stamp();
		// A separate one-second warm-up for each scene excludes shader compilation.
		if (now - started > 1 && lastFrame > 0) samples[phase].push(now - lastFrame);
		lastFrame = now;
	}

	function focusOut():Void { focused = false; }

	function focusIn():Void
	{
		focused = true;
		restart();
	}

	function resized(width:Int, height:Int):Void { restart(); }

	function restart():Void
	{
		phase = 0;
		shaderStatus = 'unknown';
		started = haxe.Timer.stamp();
		lastFrame = 0;
		samples = [[], [], []];
		proposal = null;
		if (scene != null) scene.configure(false, true);
		FlxG.updateFramerate = 120;
		FlxG.drawFramerate = 120;
		if (effectPlane != null) { effectPlane.visible = false; effectPlane.shader = null; }
	}

	function restoreRates():Void
	{
		if (restored || !ratesCaptured) return;
		restored = true;
		if (oldUpdate > FlxG.drawFramerate) FlxG.updateFramerate = oldUpdate;
		FlxG.drawFramerate = oldDraw;
		FlxG.updateFramerate = oldUpdate;
	}

	function finish(result:Null<GraphicsRecommendation>):Void
	{
		if (finished) return;
		finished = true;
		effectPlane.visible = false;
		effectPlane.shader = null;
		restoreRates();
		close();
		done(result);
	}

	override public function destroy():Void
	{
		var window = FlxG.stage.application.window;
		window.onFocusIn.remove(focusIn);
		window.onFocusOut.remove(focusOut);
		window.onResize.remove(resized);
		restoreRates();
		super.destroy();
		if (testCamera != null) { FlxG.cameras.remove(testCamera, true); testCamera = null; }
	}
}
