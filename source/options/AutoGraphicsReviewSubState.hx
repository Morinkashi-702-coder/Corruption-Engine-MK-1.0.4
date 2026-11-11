package options;

import backend.AutoGraphics;
import backend.AutoGraphics.GraphicsRecommendation;

/** A screen-space dialog shared by both options menu styles. */
class AutoGraphicsReviewSubState extends MusicBeatSubstate
{
	var restoreMode:Bool;
	var finished:Void->Void;
	var panelCamera:FlxCamera;
	var heading:FlxText;
	var body:FlxText;
	var footer:FlxText;
	var result:GraphicsRecommendation;
	var running:Bool = false;
	var delay:Float = 0.3;
	var oldStyle:Bool;

	public function new(restoreMode:Bool, finished:Void->Void)
	{
		super();
		this.restoreMode = restoreMode;
		this.finished = finished;
	}

	override public function create():Void
	{
		super.create();
		oldStyle = backend.MenuSelector.getMenu() == 'oldmenu';
		panelCamera = new FlxCamera();
		FlxG.cameras.add(panelCamera, false);
		cameras = [panelCamera];
		add(new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF09080D));
		var card = Paths.loadImageSafe(new FlxSprite(40, 30), 'infoCard');
		card.setGraphicSize(FlxG.width - 80, FlxG.height - 60);
		card.updateHitbox();
		card.alpha = 0.45;
		add(card);
		heading = label(55, 55, 32);
		body = label(75, 125, 21);
		footer = label(60, FlxG.height - 90, 22);
		if (restoreMode) showRestore(); else run();
	}

	function label(x:Float, y:Float, size:Int):FlxText
	{
		var text = new FlxText(x, y, FlxG.width - x * 2, '');
		text.setFormat(Paths.font(oldStyle ? 'pixel.otf' : 'VollkornRegular-ZVJEZ.ttf'), size,
			oldStyle ? 0xFF00FF00 : FlxColor.WHITE, CENTER);
		add(text);
		return text;
	}

	function showRestore():Void
	{
		heading.text = 'Restore graphics / Restaurar graficos';
		var saved = AutoGraphics.savedBackup();
		if (saved == null)
		{
			body.text = 'No previous automatic configuration to restore.\nNo hay una configuracion automatica anterior que restaurar.';
			footer.text = 'ENTER / ESC: close / cerrar';
			return;
		}
		body.text = 'Restore the settings from before the last automatic change?\nRestaurar los ajustes anteriores al ultimo cambio automatico?\n\nFPS: ' + saved.framerate
			+ '\nLow quality / Baja calidad: ' + (saved.lowQuality ? 'ON' : 'OFF')
			+ '\nAnti-aliasing: ' + (saved.antialiasing ? 'ON' : 'OFF')
			+ '\nShaders: ' + (saved.shaders ? 'ON' : 'OFF')
			+ '\nMenu effects: ' + (saved.menuShaders ? 'OFF' : 'ON')
			+ '\n\nScores and controls stay unchanged.\nLas puntuaciones y los controles no cambian.';
		footer.text = 'ENTER: restore / restaurar    ESC: cancel / cancelar';
	}

	function run():Void
	{
		running = true;
		persistentUpdate = false;
		heading.text = 'Automatic graphics / Graficos automaticos';
		body.text = 'Preparing / Preparando...';
		openSubState(new GraphicsBenchmarkSubState(function(value)
		{
			running = false;
			persistentUpdate = true;
			delay = 0.3;
			result = value;
			if (result == null) { leave(); return; }
			heading.text = result.profile;
			body.text = AutoGraphics.describe(result);
			footer.text = result.reliable ? 'ENTER: apply / aplicar    R: repeat / repetir    ESC: keep / mantener'
				: 'R: repeat / repetir    ENTER / ESC: keep / mantener';
		}));
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		delay -= elapsed;
		if (running || delay > 0) return;
		if (FlxG.keys.justPressed.ESCAPE || controls.BACK) { leave(); return; }
		if (!restoreMode && FlxG.keys.justPressed.R) { run(); return; }
		if (!controls.ACCEPT) return;
		if (restoreMode)
		{
			var saved = AutoGraphics.savedBackup();
			if (saved == null || AutoGraphics.saveSettings(saved, false)) leave();
			else footer.text = 'Could not save / No se pudo guardar. ENTER: retry / reintentar';
		}
		else if (result == null || !result.reliable || AutoGraphics.saveSettings(result)) leave();
		else footer.text = 'Could not save / No se pudo guardar. ENTER: retry / reintentar';
	}

	function leave():Void
	{
		close();
		finished();
	}

	override public function destroy():Void
	{
		super.destroy();
		if (panelCamera != null) { FlxG.cameras.remove(panelCamera, true); panelCamera = null; }
	}
}
