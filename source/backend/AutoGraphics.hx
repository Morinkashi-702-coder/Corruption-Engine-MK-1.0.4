package backend;

typedef GraphicsRecommendation =
{
	var profile:String;
	var averageFPS:Float;
	var slowFrameMS:Float;
	var shaderFPS:Float;
	var shaderStatus:String;
	var reason:String;
	var reliable:Bool;
	var lowQuality:Bool;
	var antialiasing:Bool;
	var shaders:Bool;
	var menuShaders:Bool;
	var framerate:Int;
	@:optional var verified:Bool;
	@:optional var verificationFPS:Float;
	@:optional var onePercentFPS:Float;
	@:optional var hitchPercent:Float;
	@:optional var loadingMS:Float;
}

typedef GraphicsSettingsSnapshot =
{
	var lowQuality:Bool;
	var antialiasing:Bool;
	var shaders:Bool;
	var menuShaders:Bool;
	var framerate:Int;
}

/** Hardware is context, not a substitute for measured rendering performance. */
#if (windows && cpp)
@:cppFileCode('#include <windows.h>')
#end
class AutoGraphics
{
	public static function memoryGB():Float
	{
		#if (windows && cpp)
		return untyped __cpp__('([]() -> double { MEMORYSTATUSEX m = {}; m.dwLength = sizeof(m); return GlobalMemoryStatusEx(&m) ? (double)m.ullTotalPhys / 1073741824.0 : 0.0; })()');
		#else
		return 0;
		#end
	}

	public static function rendererInfo():String
	{
		try
		{
			for (stage in FlxG.stage.stage3Ds)
				if (stage.context3D != null) return stage.context3D.driverInfo.substr(0, 180);
		}
		catch (_:Dynamic) {}
		return 'Unknown / No disponible';
	}

	/** NVIDIA extension where supported; never confuse RAM/shared memory with VRAM. */
	public static function videoMemoryGB():Float
	{
		#if desktop
		try
		{
			var gl = FlxG.stage.application.window.context.gl;
			if (gl != null && gl.getExtension('NVX_gpu_memory_info') != null)
			{
				var kb = Std.parseFloat(Std.string(gl.getParameter(0x9047)));
				if (Math.isFinite(kb) && kb > 0) return kb / (1024 * 1024);
			}
		}
		catch (_:Dynamic) {}
		#end
		return 0;
	}

	public static function hardwareSummary():String
	{
		var cpu = 'Unknown / No disponible';
		#if windows
		var value = Sys.getEnv('PROCESSOR_IDENTIFIER');
		if (value != null && value.length > 0) cpu = value.substr(0, 95);
		#end
		var ram = memoryGB();
		var vram = videoMemoryGB();
		return 'CPU: ' + cpu + '\nRAM: ' + (ram > 0 ? Std.string(Math.round(ram * 10) / 10) + ' GB' : '?')
			+ ' | VRAM: ' + (vram > 0 ? Std.string(Math.round(vram * 10) / 10) + ' GB' : 'Unknown / No disponible')
			+ '\n' + rendererInfo();
	}

	public static function snapshot():GraphicsSettingsSnapshot
	{
		return {lowQuality: ClientPrefs.data.lowQuality, antialiasing: ClientPrefs.data.antialiasing,
			shaders: ClientPrefs.data.shaders, menuShaders: ClientPrefs.data.menuShaders, framerate: ClientPrefs.data.framerate};
	}

	public static function statistics(intervals:Array<Float>):{fps:Float, p95:Float, valid:Bool, onePercentFPS:Float, hitchPercent:Float}
	{
		var samples = [for (value in intervals) if (Math.isFinite(value) && value > 0) value];
		var total:Float = 0;
		for (value in samples) total += value;
		samples.sort(function(a, b) return a < b ? -1 : (a > b ? 1 : 0));
		var tailCount = Std.int(Math.max(1, Math.ceil(samples.length * 0.01)));
		var tailTime:Float = 0;
		var hitches = 0;
		for (i in 0...samples.length)
		{
			if (i >= samples.length - tailCount) tailTime += samples[i];
			if (samples[i] >= 0.05) hitches++;
		}
		return {fps: total > 0 ? samples.length / total : 0,
			p95: samples.length > 0 ? samples[Std.int((samples.length - 1) * 0.95)] * 1000 : 0,
			valid: samples.length >= 45 && total >= 2.5,
			onePercentFPS: tailTime > 0 ? tailCount / tailTime : 0,
			hitchPercent: samples.length > 0 ? hitches * 100.0 / samples.length : 0};
	}

	/** Verification uses local scene settings only; it never changes saved preferences. */
	public static function verify(result:GraphicsRecommendation, frames:Array<Float>, current:GraphicsSettingsSnapshot):Void
	{
		var stats = statistics(frames);
		var expected = Math.min(result.framerate, result.shaders && result.shaderStatus == 'measured' ? result.shaderFPS : result.averageFPS);
		result.verificationFPS = stats.fps;
		result.onePercentFPS = stats.onePercentFPS;
		result.hitchPercent = stats.hitchPercent;
		result.verified = stats.valid && stats.fps >= expected * 0.9
			&& stats.p95 <= Math.max(result.slowFrameMS * 1.3, 1800.0 / result.framerate)
			&& stats.hitchPercent <= 2;
		if (result.verified != true)
		{
			result.reliable = false;
			result.profile = 'Keep settings / Mantener ajustes';
			result.reason = 'Verification inconclusive: keep settings / Verificacion insuficiente: conserva tus ajustes.';
			for (key in settingKeys) Reflect.setField(result, key, Reflect.field(current, key));
		}
	}

	public static final settingKeys = ['lowQuality', 'antialiasing', 'shaders', 'menuShaders', 'framerate'];

	public static function settingsDiffer(a:GraphicsSettingsSnapshot, b:GraphicsSettingsSnapshot):Bool
	{
		for (key in settingKeys) if (Reflect.field(a, key) != Reflect.field(b, key)) return true;
		return false;
	}

	public static function backupCurrent(proposed:GraphicsSettingsSnapshot):Void
	{
		var previous = snapshot();
		if (settingsDiffer(previous, proposed)) FlxG.save.data.autoGraphicsBackup = previous;
	}

	public static function savedBackup():Null<GraphicsSettingsSnapshot>
	{
		var value:Dynamic = FlxG.save.data.autoGraphicsBackup;
		if (value == null) return null;
		for (key in settingKeys)
		{
			var field:Dynamic = Reflect.field(value, key);
			if (key == 'framerate')
			{
				if (!Std.isOfType(field, Int) || field < 60 || field > 240) return null;
			}
			else if (!Std.isOfType(field, Bool)) return null;
		}
		return cast value;
	}

	/** Write only graphics fields; rollback on save failure. No score/control changes. */
	public static function saveSettings(settings:GraphicsSettingsSnapshot, createBackup:Bool = true):Bool
	{
		var previous = snapshot();
		var oldBackup:Dynamic = FlxG.save.data.autoGraphicsBackup;
		var oldSave:Map<String, Dynamic> = [];
		var existing:Array<String> = [];
		for (key in settingKeys)
		{
			oldSave.set(key, Reflect.field(FlxG.save.data, key));
			if (Reflect.hasField(FlxG.save.data, key)) existing.push(key);
			Reflect.setField(ClientPrefs.data, key, Reflect.field(settings, key));
			Reflect.setField(FlxG.save.data, key, Reflect.field(settings, key));
		}
		FlxG.save.data.autoGraphicsBackup = createBackup ? (settingsDiffer(previous, settings) ? previous : oldBackup) : null;
		var saved = false;
		try { saved = FlxG.save.flush(); } catch (_:Dynamic) {}
		if (!saved)
		{
			for (key in settingKeys)
			{
				Reflect.setField(ClientPrefs.data, key, Reflect.field(previous, key));
				if (existing.contains(key)) Reflect.setField(FlxG.save.data, key, oldSave.get(key));
				else Reflect.deleteField(FlxG.save.data, key);
			}
			FlxG.save.data.autoGraphicsBackup = oldBackup;
			return false;
		}
		updateFramerate();
		return true;
	}

	public static function describe(result:GraphicsRecommendation):String
	{
		var current = snapshot();
		var text = 'Sprites: ' + Math.round(result.averageFPS) + ' FPS | Shader: '
			+ (result.shaderStatus == 'measured' ? Math.round(result.shaderFPS) + ' FPS'
				: result.shaderStatus == 'failed' ? 'Failed / Fallo' : 'Unverified / Sin verificar');
		if (result.verificationFPS != null)
			text += '\nCheck / Verificacion: ' + Math.round(result.verificationFPS) + ' FPS'
				+ ' | 1% low: ' + Math.round(result.onePercentFPS) + ' | Hitches / Tirones: ' + Math.round(result.hitchPercent * 10) / 10 + '%';
		text += '\nCurrent -> Proposed / Actual -> Propuesto:'
			+ '\nFPS: ' + current.framerate + ' -> ' + result.framerate
			+ ' | Low quality: ' + onOff(current.lowQuality) + ' -> ' + onOff(result.lowQuality)
			+ '\nAnti-aliasing: ' + onOff(current.antialiasing) + ' -> ' + onOff(result.antialiasing)
			+ ' | Shaders: ' + onOff(current.shaders) + ' -> ' + onOff(result.shaders)
			+ '\nMenu effects: ' + onOff(!current.menuShaders) + ' -> ' + onOff(!result.menuShaders)
			+ '\n\n' + result.reason;
		if (result.loadingMS != null) text += '\nResource loading / Carga de recursos: ' + Math.round(result.loadingMS) + ' ms';
		return text + '\n\nGPU cache unchanged / Cache GPU sin cambios.'
			+ '\nTest scene only; songs may differ / Cada cancion puede rendir distinto.';
	}

	static inline function onOff(value:Bool):String return value ? 'ON' : 'OFF';

	public static function recommend(spriteFrames:Array<Float>, shaderFrames:Array<Float>, shaderStatus:String,
		ramGB:Float, refreshRate:Int, current:GraphicsSettingsSnapshot):GraphicsRecommendation
	{
		var base = statistics(spriteFrames);
		var effect = statistics(shaderFrames);
		var poor = base.valid && (base.fps < 50 || base.p95 > 34);
		var shaderMeasured = shaderStatus == 'passed' && effect.valid;
		var shaderGood = shaderMeasured && effect.fps >= 55 && effect.p95 <= 25;
		var quality = base.valid && !poor && shaderGood && (ramGB <= 0 || ramGB >= 7);
		var rate = 60;
		var measured = shaderGood ? effect : base;
		// VSync at 60 FPS does not indicate a weak PC.
		if (!poor && measured.fps >= 105 && measured.p95 <= 13)
			rate = Std.int(Math.max(60, Math.min(120, refreshRate)));
		var reason = !base.valid ? 'Not enough data. Keep settings / Datos insuficientes: conserva tus ajustes.'
			: poor ? 'Repeated slow frames / Bajadas repetidas durante la prueba.'
			: shaderGood ? 'Sprites and test shader smooth / Sprites y shader de prueba fluidos.'
			: shaderStatus == 'failed' ? 'Test shader did not compile / El shader de prueba no compilo.'
			: shaderMeasured ? 'Test shader caused slow frames / El shader provoco bajadas.'
			: 'Shader unverified: keep setting / Shader sin verificar: conserva su ajuste.';
		return {
			profile: !base.valid ? 'Keep settings / Mantener ajustes' : poor ? 'Performance / Rendimiento'
				: quality ? 'Quality / Calidad' : 'Balanced / Equilibrado',
			averageFPS: base.fps, slowFrameMS: base.p95, shaderFPS: effect.fps,
			shaderStatus: shaderMeasured ? 'measured' : shaderStatus == 'failed' ? 'failed' : 'unknown',
			reason: reason, reliable: base.valid,
			lowQuality: base.valid ? poor : current.lowQuality,
			antialiasing: base.valid ? !poor : current.antialiasing,
			shaders: !base.valid ? current.shaders : shaderMeasured ? shaderGood : shaderStatus == 'failed' ? false : current.shaders,
			menuShaders: !base.valid || (!shaderMeasured && shaderStatus != 'failed') ? current.menuShaders
				: (poor || !shaderGood || shaderStatus == 'failed'),
			framerate: base.valid ? rate : current.framerate
		};
	}

	public static function updateFramerate():Void
	{
		var rate = ClientPrefs.data.framerate;
		if (rate > FlxG.drawFramerate)
		{
			FlxG.updateFramerate = rate;
			FlxG.drawFramerate = rate;
		}
		else
		{
			FlxG.drawFramerate = rate;
			FlxG.updateFramerate = rate;
		}
	}
}
