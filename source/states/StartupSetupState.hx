package states;

import backend.AutoGraphics;
import backend.AutoGraphics.GraphicsRecommendation;
import options.GraphicsBenchmarkSubState;

/** First-start questions, using the Notices card style and menu previews. */
class StartupSetupState extends MusicBeatState
{
	static var completedThisSession:Bool = false;

	public static function isTestMode():Bool
	{
		return backend.GameConfig.getInstance().getBool('menu', 'firsttimemode', false);
	}

	public static function isNeeded():Bool
	{
		return !completedThisSession && (isTestMode() || FlxG.save.data.startupSetupComplete != true);
	}

	var page:Int = 0;
	var selected:Int = 0;
	var answer:Int = 0;
	var showNotices:Bool = true;
	var showOpening:Bool = true;
	var runAutoGraphics:Bool = false;
	var applyGraphics:Bool = true;
	var recommendation:Null<GraphicsRecommendation>;
	var benchmarkRunning:Bool = false;
	var inputDelay:Float = 0.25;
	var leaving:Bool = false;
	var heading:FlxText;
	var body:FlxText;
	var choices:FlxText;
	var hint:FlxText;
	var previews:Array<FlxSprite> = [];

	override public function create():Void
	{
		super.create();
		FlxG.camera.zoom = 1;
		FlxG.camera.bgColor = 0xFF09080D;
		FlxG.mouse.visible = false;
		if (FlxG.sound.music != null) FlxG.sound.music.stop();
		backend.MenuSelector.init();
		selected = backend.MenuSelector.getMenu() == 'oldmenu' ? 1 : 0;
		showNotices = backend.GameConfig.getInstance().getBool('menu', 'shownoticesonstartup', true);
		showOpening = backend.GameConfig.getInstance().getBool('menu', 'showopeningvideo', true);

		var chains = Paths.loadImageSafe(new FlxSprite(), 'chains');
		chains.setGraphicSize(FlxG.width, FlxG.height);
		chains.updateHitbox();
		chains.alpha = 0.25;
		add(chains);
		var card = Paths.loadImageSafe(new FlxSprite(55, 35), 'infoCard');
		card.setGraphicSize(FlxG.width - 110, FlxG.height - 100);
		card.updateHitbox();
		card.alpha = 0.85;
		add(card);
		heading = makeText(70, 60, FlxG.width - 140, 34, FlxColor.WHITE);
		body = makeText(100, 125, FlxG.width - 200, 24, FlxColor.WHITE);
		for (i in 0...2)
		{
			var preview = Paths.loadImageSafe(new FlxSprite(), i == 0
				? 'menus/preview menus/Nulldemo' : 'menus/preview menus/Sempai demo');
			var ratio = Math.min(420 / preview.width, 225 / preview.height);
			preview.scale.set(ratio, ratio);
			preview.updateHitbox();
			preview.setPosition(FlxG.width * (i == 0 ? 0.28 : 0.72) - preview.width / 2, 255);
			previews.push(preview);
			add(preview);
		}
		choices = makeText(85, 510, FlxG.width - 170, 30, 0xFFCC5363);
		hint = makeText(70, FlxG.height - 65, FlxG.width - 140, 18, 0xFFCCCCCC);
		refresh();
		FlxG.camera.fade(FlxColor.BLACK, 0.3, true);
	}

	function makeText(x:Float, y:Float, width:Float, size:Int, color:FlxColor):FlxText
	{
		var text = new FlxText(x, y, width, '');
		text.setFormat(Paths.font('VollkornRegular-ZVJEZ.ttf'), size, color, CENTER);
		text.antialiasing = ClientPrefs.data.antialiasing;
		add(text);
		return text;
	}

	function refresh():Void
	{
		inputDelay = 0.2;
		body.size = page == 7 ? 21 : page == 2 ? 22 : 24;
		for (i in 0...previews.length)
		{
			previews[i].visible = page == 0;
			previews[i].alpha = selected == i ? 1 : 0.4;
		}
		hint.text = 'LEFT / RIGHT: choose / elegir    ENTER: next / seguir'
			+ (page == 0 ? '' : '    ESC: back / volver');
		switch (page)
		{
			case 0:
				heading.text = 'Choose your menu / Elige tu menú';
				body.text = 'Which menu would you like to see when you open the game?\nYou can change it later.\n¿Qué menú quieres ver al abrir el juego?\nPuedes cambiarlo más adelante.';
				choices.text = selected == 0 ? '> Null Demo <                  Senpai Demo' : 'Null Demo                  > Senpai Demo <';
			case 1:
				heading.text = (selected == 0 ? 'Null Demo' : 'Senpai Demo') + ' — OK?';
				body.text = 'Use this menu each time you open the game?\nChoose Yes to continue, or choose another menu.\n\n¿Quieres usar este menú cada vez que abras el juego?\nElige Sí para seguir, o vuelve para elegir otro.';
				choices.text = answer == 0 ? '> Yes / Sí <          Choose another / Elegir otro' : 'Yes / Sí          > Choose another / Elegir otro <';
			case 2:
				heading.text = 'All set! / ¡Todo listo!';
				body.text = 'Your choices are saved / Tus preferencias están guardadas.\n\nMenu / Menú: ' + (selected == 0 ? 'Null Demo' : 'Senpai Demo')
					+ '\nShow notices / Mostrar avisos: ' + (showNotices ? 'Yes / Sí' : 'No')
					+ '\nIntro video / Vídeo de inicio: ' + (showOpening ? 'Yes / Sí' : 'No')
					+ '\n\nTo change these choices, open this file with Notepad:\nPara cambiarlas, abre este archivo con el Bloc de notas:'
					+ '\nassets/shared/data/gameData.ini\nEach option is explained inside / Cada opción está explicada dentro.'
					+ '\ntrue = Yes / Sí     false = No';
				if (recommendation != null && applyGraphics) body.text += '\nGraphics: ' + recommendation.profile;
				choices.text = 'Continue / Continuar';
			case 3:
				heading.text = 'Could not save / No se pudo guardar';
				body.text = 'Your choices could not be saved.\nCheck that gameData.ini exists and the game folder allows saving files.\nPress Enter to try saving again.\n\nNo se pudieron guardar tus respuestas.\nComprueba que existe gameData.ini y que puedes guardar en la carpeta del juego.\nPulsa Enter para volver a intentarlo.';
				choices.text = 'ENTER: retry / reintentar     ESC: previous / anterior';
			case 4:
				heading.text = 'Show notices? / ¿Mostrar los avisos?';
				body.text = 'Show the information screens every time you open the game?\nThese screens show warnings and information about the game.\nYes: show them. No: skip them next time.\n\n¿Mostrar los avisos cada vez que abras el juego?\nSon pantallas con advertencias e información sobre el juego.\nSí: mostrarlos. No: saltarlos la próxima vez.';
				choices.text = showNotices ? '> Yes / Sí <          No' : 'Yes / Sí          > No <';
			case 5:
				heading.text = 'Intro video / Vídeo de inicio';
				body.text = 'Play the Corruption intro video when you open the game?\nYes: play it after these questions and on future launches.\nNo: skip the video.\n\n¿Ver el vídeo de Corruption al abrir el juego?\nSí: verlo al terminar estas preguntas y en los próximos inicios.\nNo: saltar el vídeo.';
				choices.text = showOpening ? '> Yes / Sí <          No' : 'Yes / Sí          > No <';
			case 6:
				heading.text = 'Need help with graphics? / ¿Te ayudamos con los gráficos?';
				body.text = 'Not sure which graphics settings to use?\nA short test (about 15 seconds) can suggest settings for your PC.\nYou choose whether to use them. No personal files are checked or sent.\n\n¿No sabes qué ajustes gráficos elegir?\nUna prueba de unos 15 segundos puede recomendarte ajustes para tu PC.\nTú decides si los usas. No revisa ni envía archivos personales.';
				choices.text = runAutoGraphics ? '> Test / Probar <          Skip / Saltar' : 'Test / Probar          > Skip / Saltar <';
			case 7:
				heading.text = recommendation.profile;
				body.text = AutoGraphics.describe(recommendation);
				choices.text = applyGraphics ? '> Use settings / Usar ajustes <       Keep mine / Dejar los míos' : 'Use settings / Usar ajustes       > Keep mine / Dejar los míos <';
				hint.text += '    R: repeat / repetir';
		}
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		inputDelay -= elapsed;
		if (leaving || benchmarkRunning || inputDelay > 0) return;
		if (page == 7 && FlxG.keys.justPressed.R) { startBenchmark(); return; }
		if (FlxG.keys.justPressed.ESCAPE || controls.BACK)
		{
			var previous = switch (page)
			{
				case 1: 0;
				case 4: 1;
				case 5: 4;
				case 6: 5;
				case 7: 6;
				case 2, 3: recommendation != null ? 7 : 6;
				default: 0;
			};
			if (page != previous)
			{
				page = previous;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				refresh();
			}
			return;
		}
		if ((controls.UI_LEFT_P || controls.UI_RIGHT_P) && (page < 2 || page >= 4))
		{
			if (page == 0) selected = 1 - selected;
			else if (page == 4) showNotices = !showNotices;
			else if (page == 5) showOpening = !showOpening;
			else if (page == 6) runAutoGraphics = !runAutoGraphics;
			else if (page == 7) applyGraphics = !applyGraphics;
			else answer = 1 - answer;
			FlxG.sound.play(Paths.sound('scrollMenu'));
			refresh();
			return;
		}
		if (!controls.ACCEPT) return;
		FlxG.sound.play(Paths.sound('confirmMenu'));
		switch (page)
		{
			case 0: page = 1; answer = 0; refresh();
			case 1:
				page = answer == 1 ? 0 : 4;
				refresh();
			case 4: page = 5; refresh();
			case 5: page = 6; refresh();
			case 6:
				if (runAutoGraphics) startBenchmark();
				else { recommendation = null; saveChoice(); }
			case 7: saveChoice();
			case 3: saveChoice();
			case 2:
				leaving = true;
				FlxG.camera.fade(FlxColor.BLACK, 0.3, false, function()
				{
					// Continue straight to the selected title, without repeating Notices.
					var openTitle = function():Void
					{
						if (selected == 1) MusicBeatState.switchState(new TitleState_oldmenu());
						else MusicBeatState.switchState(new SoftCodeMenuState());
					};
					if (showOpening && !OpeningVideoState.playedThisSession)
						MusicBeatState.switchState(new OpeningVideoState(openTitle));
					else openTitle();
				});
		}
	}

	function startBenchmark():Void
	{
		benchmarkRunning = true;
		persistentUpdate = false;
		openSubState(new GraphicsBenchmarkSubState(function(result)
		{
			benchmarkRunning = false;
			persistentUpdate = true;
			recommendation = result;
			applyGraphics = result != null && result.reliable;
			page = result == null ? 6 : 7;
			refresh();
		}));
	}

	function saveChoice():Void
	{
		var menu = selected == 0 ? 'NullDemo' : 'Sempaidemo';
		if (!backend.GameConfig.getInstance().saveStartupMenu(menu, showNotices, showOpening)) { page = 3; refresh(); return; }
		backend.MenuSelector.setMenu(menu);
		var previousSettings:Map<String, Dynamic> = [];
		var previousSave:Map<String, Dynamic> = [];
		var savedFields:Array<String> = [];
		var oldBackup:Dynamic = FlxG.save.data.autoGraphicsBackup;
		if (recommendation != null && applyGraphics && recommendation.reliable)
		{
			AutoGraphics.backupCurrent(recommendation);
			for (key in AutoGraphics.settingKeys)
			{
				previousSettings.set(key, Reflect.field(ClientPrefs.data, key));
				previousSave.set(key, Reflect.field(FlxG.save.data, key));
				if (Reflect.hasField(FlxG.save.data, key)) savedFields.push(key);
				var value = Reflect.field(recommendation, key);
				Reflect.setField(ClientPrefs.data, key, value);
				Reflect.setField(FlxG.save.data, key, value);
			}
		}
		var previousCompletion:Dynamic = FlxG.save.data.startupSetupComplete;
		FlxG.save.data.startupSetupComplete = true;
		var saved = false;
		try { saved = FlxG.save.flush(); } catch (_:Dynamic) {}
		if (!saved)
		{
			FlxG.save.data.startupSetupComplete = previousCompletion;
			FlxG.save.data.autoGraphicsBackup = oldBackup;
			for (key in previousSettings.keys())
			{
				Reflect.setField(ClientPrefs.data, key, previousSettings.get(key));
				if (savedFields.contains(key)) Reflect.setField(FlxG.save.data, key, previousSave.get(key));
				else Reflect.deleteField(FlxG.save.data, key);
			}
			page = 3;
		}
		else
		{
			completedThisSession = true;
			if (recommendation != null && applyGraphics) AutoGraphics.updateFramerate();
			page = 2;
		}
		refresh();
	}
}
