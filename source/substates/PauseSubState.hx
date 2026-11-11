package substates;

import backend.WeekData;
import backend.Highscore;
import backend.Song;

import flixel.util.FlxStringUtil;

import states.StoryMenuState;
import states.FreeplayState;
import states.FreeplayState_oldmenu;
import states.MainMenuState_oldmenu;
import states.SoftCodeMenuState;
import options.OptionsState;

class PauseSubState extends MusicBeatSubstate
{
	public static var isOpen:Bool = false;

	var grpMenuShit:FlxTypedGroup<Alphabet>;

	var menuItems:Array<String> = [];
	var menuItemsOG:Array<String> = ['Resume', 'Restart Song', 'Change Difficulty', 'Options', 'Exit to menu'];
	var difficultyChoices = [];
	var curSelected:Int = 0;

	// Variables para el menú visual personalizado
	public static var useVisualPauseMenu:Bool = true;
	var disabledResume:Bool = false;
	var object:FlxSprite;
	var visualBg:FlxSprite;
	var chains:FlxSprite;
	var optionText:FlxSpriteGroup;
	var selectedText:FlxSpriteGroup;
	var prevSel:Int = -1;

	// Variables para la tabla de ayuda
	var helpTableVisible:Bool = false;
	var helpTableBG:FlxSprite;
	var helpTableTexts:Array<FlxText> = [];

	var pauseMusic:FlxSound;
	var practiceText:FlxText;
	var skipTimeText:FlxText;
	var skipTimeTracker:Alphabet;
	var curTime:Float = Math.max(0, Conductor.songPosition);

	var missingTextBG:FlxSprite;
	var missingText:FlxText;

	public static var songName:String = null;

	override function create()
	{
		// Leer configuración de pauseMenuStyle desde gameData.ini
		var pauseMenuStyle:String = "visual"; // Por defecto visual
		#if desktop
		try {
			var gameConfig = backend.GameConfig.getInstance();
			pauseMenuStyle = gameConfig.getValue("menu", "pausemenustyle", "visual").toLowerCase();
			trace("✓ Pause menu style from gameData.ini: " + pauseMenuStyle);
		} catch(e:Dynamic) {
			trace("⚠ Error reading pauseMenuStyle from gameData.ini: " + e);
		}
		#end
		
		// Si el estilo es "classic", o SHIFT está presionado, o modo charting
		if (pauseMenuStyle == "classic" || FlxG.keys.pressed.SHIFT || PlayState.chartingMode) {
			createClassicMenu();
			return;
		}

		// Crear menú visual personalizado (si pauseMenuStyle es "visual")
		createVisualMenu();
	}

	function createClassicMenu()
	{
		if(Difficulty.list.length < 2) menuItemsOG.remove('Change Difficulty'); //No need to change difficulty if there is only one!
		if(PlayState.chartingMode)
		{
			menuItemsOG.insert(2, 'Leave Charting Mode');
			var num:Int = 0;
			if(!PlayState.instance.startingSong)
			{
				num = 1;
				menuItemsOG.insert(3, 'Skip Time');
			}
			menuItemsOG.insert(3 + num, 'End Song');
			menuItemsOG.insert(4 + num, 'Toggle Practice Mode');
			menuItemsOG.insert(5 + num, 'Toggle Botplay');
		} else if(PlayState.instance.practiceMode && !PlayState.instance.startingSong)
			menuItemsOG.insert(3, 'Skip Time');
		menuItems = menuItemsOG;

		for (i in 0...Difficulty.list.length) {
			var diff:String = Difficulty.getString(i);
			difficultyChoices.push(diff);
		}
		difficultyChoices.push('BACK');

		pauseMusic = new FlxSound();
		try
		{
			var pauseSong:String = getPauseSong();
			if(pauseSong != null) pauseMusic.loadEmbedded(Paths.music(pauseSong), true, true);
		}
		catch(e:Dynamic) {}
		pauseMusic.volume = 0;
		pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));

		FlxG.sound.list.add(pauseMusic);

		var bg:FlxSprite = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		bg.scale.set(FlxG.width, FlxG.height);
		bg.updateHitbox();
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

		var levelInfo:FlxText = new FlxText(20, 15, 0, PlayState.SONG.song, 32);
		levelInfo.scrollFactor.set();
		levelInfo.setFormat(Paths.font("vcr.ttf"), 32);
		levelInfo.updateHitbox();
		add(levelInfo);

		var levelDifficulty:FlxText = new FlxText(20, 15 + 32, 0, Difficulty.getString().toUpperCase(), 32);
		levelDifficulty.scrollFactor.set();
		levelDifficulty.setFormat(Paths.font('vcr.ttf'), 32);
		levelDifficulty.updateHitbox();
		add(levelDifficulty);

		var blueballedTxt:FlxText = new FlxText(20, 15 + 64, 0, Language.getPhrase("blueballed", "Blueballed: {1}", [PlayState.deathCounter]), 32);
		blueballedTxt.scrollFactor.set();
		blueballedTxt.setFormat(Paths.font('vcr.ttf'), 32);
		blueballedTxt.updateHitbox();
		add(blueballedTxt);

		practiceText = new FlxText(20, 15 + 101, 0, Language.getPhrase("Practice Mode").toUpperCase(), 32);
		practiceText.scrollFactor.set();
		practiceText.setFormat(Paths.font('vcr.ttf'), 32);
		practiceText.x = FlxG.width - (practiceText.width + 20);
		practiceText.updateHitbox();
		practiceText.visible = PlayState.instance.practiceMode;
		add(practiceText);

		var chartingText:FlxText = new FlxText(20, 15 + 101, 0, Language.getPhrase("Charting Mode").toUpperCase(), 32);
		chartingText.scrollFactor.set();
		chartingText.setFormat(Paths.font('vcr.ttf'), 32);
		chartingText.x = FlxG.width - (chartingText.width + 20);
		chartingText.y = FlxG.height - (chartingText.height + 20);
		chartingText.updateHitbox();
		chartingText.visible = PlayState.chartingMode;
		add(chartingText);

		blueballedTxt.alpha = 0;
		levelDifficulty.alpha = 0;
		levelInfo.alpha = 0;

		levelInfo.x = FlxG.width - (levelInfo.width + 20);
		levelDifficulty.x = FlxG.width - (levelDifficulty.width + 20);
		blueballedTxt.x = FlxG.width - (blueballedTxt.width + 20);

		FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});
		FlxTween.tween(levelInfo, {alpha: 1, y: 20}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.3});
		FlxTween.tween(levelDifficulty, {alpha: 1, y: levelDifficulty.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.5});
		FlxTween.tween(blueballedTxt, {alpha: 1, y: blueballedTxt.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.7});

		grpMenuShit = new FlxTypedGroup<Alphabet>();
		add(grpMenuShit);

		missingTextBG = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		missingTextBG.scale.set(FlxG.width, FlxG.height);
		missingTextBG.updateHitbox();
		missingTextBG.alpha = 0.6;
		missingTextBG.visible = false;
		add(missingTextBG);
		
		missingText = new FlxText(50, 0, FlxG.width - 100, '', 24);
		missingText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		missingText.scrollFactor.set();
		missingText.visible = false;
		add(missingText);

		regenMenu();
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		super.create();
	}

	function createVisualMenu()
	{
		// Inicializar pauseMusic primero
		pauseMusic = new FlxSound();
		try
		{
			var pauseSong:String = getPauseSong();
			if(pauseSong != null) pauseMusic.loadEmbedded(Paths.music(pauseSong), true, true);
		}
		catch(e:Dynamic) {}
		pauseMusic.volume = 0;
		pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));
		FlxG.sound.list.add(pauseMusic);

		// Configurar menús básicos
		menuItems = ['Resume', 'Restart Song', 'Skip Song', 'Options', 'Exit to menu'];
		
		for (i in 0...Difficulty.list.length) {
			var diff:String = Difficulty.getString(i);
			difficultyChoices.push(diff);
		}
		difficultyChoices.push('BACK');

		// Inicializar grpMenuShit antes de usarlo
		grpMenuShit = new FlxTypedGroup<Alphabet>();
		add(grpMenuShit);

		// Eliminar opciones no usadas en el menú visual
		menuItems.remove("Skip Time");
		menuItems.remove("Toggle Botplay");
		menuItems.remove("Change Modifiers");

		regenMenu();
		remove(grpMenuShit);

		// Fondo visual
		visualBg = new FlxSprite(-40, 10, Paths.image('menus/pause/bg'));
		visualBg.scrollFactor.set(0, 0);
		visualBg.scale.set(1, 1.1);
		add(visualBg);

		// Cadenas animadas
		chains = new FlxSprite();
		var chainsAtlas = Paths.getSparrowAtlas('menus/pause/pause chains');
		if (chainsAtlas != null) {
			chains.frames = chainsAtlas;
			chains.animation.addByPrefix("idle", 'chains', 24, false);
			chains.animation.play("idle", true);
		} else {
			trace('WARNING: Could not load pause chains atlas');
			chains.makeGraphic(200, 200, 0xFF808080);
		}
		chains.scrollFactor.set(0, 0);
		chains.scale.set(1, 1);
		chains.antialiasing = true;
		chains.setPosition(-990, -620);
		add(chains);

		// Opciones visuales
		optionText = new FlxSpriteGroup();
		add(optionText);

		selectedText = new FlxSpriteGroup();
		add(selectedText);

		var pauseButtonsAtlas = Paths.getSparrowAtlas("menus/pause/pauseButtons");
		for (i in 0...5) {
			var textOpt = new FlxSprite(0, 0);
			if (pauseButtonsAtlas != null) {
				textOpt.frames = pauseButtonsAtlas;
				textOpt.animation.addByPrefix("idle", Std.string(i), 0, true);
				textOpt.animation.play("idle", true);
			} else {
				trace('WARNING: Could not load pauseButtons atlas');
				textOpt.makeGraphic(100, 100, 0xFF808080);
			}
			textOpt.scrollFactor.set(0, 0);
			textOpt.scale.set(1, 1);
			textOpt.alpha = 1;
			optionText.add(textOpt);

			var textSel = new FlxSprite(0, 0);
			if (pauseButtonsAtlas != null) {
				textSel.frames = pauseButtonsAtlas;
				textSel.animation.addByPrefix("idle", "p" + i, 0, true);
				textSel.animation.play("idle", true);
			} else {
				trace('WARNING: Could not load pauseButtons atlas for selected');
				textSel.makeGraphic(100, 100, 0xFF808080);
			}
			textSel.scrollFactor.set(0, 0);
			textSel.scale.set(1, 1);
			textSel.alpha = 1;
			selectedText.add(textSel);
		}

		FlxG.sound.play(Paths.sound('pause'));

		optionText.setPosition(39, 37);
		selectedText.setPosition(39, 37);

		optionText.scale.set(0.9, 0.9);
		selectedText.scale.set(0.9, 0.9);

		object = visualBg;
		updateVisualOption();

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
		super.create();
	}
	
	function getPauseSong()
	{
		var formattedSongName:String = (songName != null ? Paths.formatToSongPath(songName) : '');
		var formattedPauseMusic:String = Paths.formatToSongPath(ClientPrefs.data.pauseMusic);
		if(formattedSongName == 'none' || (formattedSongName != 'none' && formattedPauseMusic == 'none')) return null;

		return (formattedSongName != '') ? formattedSongName : formattedPauseMusic;
	}

	var holdTime:Float = 0;
	var cantUnpause:Float = 0.1;
	override function update(elapsed:Float)
	{
		cantUnpause -= elapsed;
		if (pauseMusic != null && pauseMusic.volume < 0.5)
			pauseMusic.volume += 0.01 * elapsed;

		super.update(elapsed);

		// Lógica específica del menú visual
		if (useVisualPauseMenu && !FlxG.keys.pressed.SHIFT && !PlayState.chartingMode) {
			updateVisualMenu(elapsed);
			return;
		}

		// Lógica del menú clásico
		updateClassicMenu(elapsed);
	}

	function updateVisualMenu(elapsed:Float)
	{
		// NO verificar si Resume desaparece en el menú visual
		// porque manejamos el cambio de dificultad de forma diferente
		
		if (prevSel != curSelected) {
			prevSel = curSelected;
			updateVisualOption();
		}

		if (controls.BACK) {
			// Si estamos en el menú de dificultad, volver al menú principal
			if (menuItems == difficultyChoices) {
				menuItems = ['Resume', 'Restart Song', 'Skip Song', 'Options', 'Exit to menu'];
				curSelected = 2; // Volver a "Skip Song"
				updateVisualOption();
				return;
			}
			close();
			return;
		}

		if (controls.UI_UP_P) {
			changeVisualSelection(-1);
		}
		if (controls.UI_DOWN_P) {
			changeVisualSelection(1);
		}

		// Controles rápidos: B para botplay, P para practice mode
		if (FlxG.keys.justPressed.B) {
			if (PlayState.instance.botplayAllowed) {
				PlayState.instance.cpuControlled = !PlayState.instance.cpuControlled;
				PlayState.changedDifficulty = true;
				PlayState.instance.botplayTxt.visible = PlayState.instance.cpuControlled;
				PlayState.instance.botplayTxt.alpha = 1;
				PlayState.instance.botplaySine = 0;
				trace("✓ [Pausa Menú Visual] Botplay: " + (PlayState.instance.cpuControlled ? "ACTIVADO" : "DESACTIVADO"));
			} else {
				trace("✗ [Pausa Menú Visual] Botplay BLOQUEADO por gameData.ini");
			}
		}

		if (FlxG.keys.justPressed.P) {
			if (PlayState.instance.practiceModeAllowed) {
				PlayState.instance.practiceMode = !PlayState.instance.practiceMode;
				PlayState.changedDifficulty = true;
				trace("✓ [Pausa Menú Visual] Practice Mode: " + (PlayState.instance.practiceMode ? "ACTIVADO" : "DESACTIVADO"));
			} else {
				trace("✗ [Pausa Menú Visual] Practice Mode BLOQUEADO por gameData.ini");
			}
		}

		// TAB para abrir/cerrar tabla de ayuda
		if (FlxG.keys.justPressed.TAB) {
			toggleHelpTable();
		}

		if (helpTableVisible) {
			// Permitir cerrar con TAB o ESC
			if (controls.BACK) {
				toggleHelpTable();
			}
			return; // No procesar otros controles mientras la tabla está visible
		}

		if (controls.ACCEPT && (cantUnpause <= 0 || !controls.controllerMode)) {
			var daSelected:String = menuItems[curSelected];
			
			if (menuItems == difficultyChoices) {
				// Lógica para cambio de dificultad
				var songLowercase:String = Paths.formatToSongPath(PlayState.SONG.song);
				var poop:String = Highscore.formatSong(songLowercase, curSelected);
				try {
					if(menuItems.length - 1 != curSelected && difficultyChoices.contains(daSelected)) {
						Song.loadFromJson(poop, songLowercase);
						PlayState.storyDifficulty = curSelected;
						MusicBeatState.resetState();
						FlxG.sound.music.volume = 0;
						PlayState.changedDifficulty = true;
						PlayState.chartingMode = false;
						return;
					}
				} catch(e:haxe.Exception) {
					trace('ERROR! ${e.message}');
					// Manejar error de carga de chart...
					return;
				}
				
				// Volver al menú principal
				menuItems = ['Resume', 'Restart Song', 'Skip Song', 'Options', 'Exit to menu'];
				curSelected = 0;
				updateVisualOption();
				return;
			}
			
			switch (daSelected) {
				case "Resume":
					close();
				case "Restart Song":
					restartSong();
				case 'Skip Song':
					// Usar el mismo patrón que "End Song" del engine original
					close();
					if (PlayState.instance != null) {
						PlayState.instance.notes.clear();
						PlayState.instance.unspawnNotes = [];
						PlayState.instance.finishSong(true);
					}
				case 'Options':
					PlayState.instance.paused = true;
					PlayState.instance.vocals.volume = 0;
					PlayState.instance.canResync = false;
					MusicBeatState.switchState(new OptionsState());
					if(ClientPrefs.data.pauseMusic != 'None') {
						FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath(ClientPrefs.data.pauseMusic)), pauseMusic.volume);
						FlxTween.tween(FlxG.sound.music, {volume: 1}, 0.8);
						FlxG.sound.music.time = pauseMusic.time;
					}
					OptionsState.onPlayState = true;
				case "Exit to menu":
					//#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end
					PlayState.deathCounter = 0;
					PlayState.seenCutscene = false;
					PlayState.instance.canResync = false;
					Mods.loadTopMod();
					
					if (backend.MenuSelector.getMenu() == 'oldmenu') {
						MusicBeatState.switchState(new MainMenuState_oldmenu());
					} else {
						SoftCodeMenuState.fromPlay = true;
						MusicBeatState.switchState(new SoftCodeMenuState(true));
					}
					
					PlayState.changedDifficulty = false;
					PlayState.chartingMode = false;
					FlxG.camera.followLerp = 0;
			}
		}
	}

	function updateClassicMenu(elapsed:Float)
	{

		if(controls.BACK)
		{
			close();
			return;
		}

		if(FlxG.keys.justPressed.F5)
		{
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			PlayState.nextReloadAll = true;
			MusicBeatState.resetState();
		}

		updateSkipTextStuff();
		if (controls.UI_UP_P)
		{
			changeSelection(-1);
		}
		if (controls.UI_DOWN_P)
		{
			changeSelection(1);
		}

		var daSelected:String = menuItems[curSelected];
		switch (daSelected)
		{
			case 'Skip Time':
				if (controls.UI_LEFT_P)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
					curTime -= 1000;
					holdTime = 0;
				}
				if (controls.UI_RIGHT_P)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
					curTime += 1000;
					holdTime = 0;
				}

				if(controls.UI_LEFT || controls.UI_RIGHT)
				{
					holdTime += elapsed;
					if(holdTime > 0.5)
					{
						curTime += 45000 * elapsed * (controls.UI_LEFT ? -1 : 1);
					}

					if(curTime >= FlxG.sound.music.length) curTime -= FlxG.sound.music.length;
					else if(curTime < 0) curTime += FlxG.sound.music.length;
					updateSkipTimeText();
				}
		}

		if (controls.ACCEPT && (cantUnpause <= 0 || !controls.controllerMode))
		{
			if (menuItems == difficultyChoices)
			{
				var songLowercase:String = Paths.formatToSongPath(PlayState.SONG.song);
				var poop:String = Highscore.formatSong(songLowercase, curSelected);
				try
				{
					if(menuItems.length - 1 != curSelected && difficultyChoices.contains(daSelected))
					{
						Song.loadFromJson(poop, songLowercase);
						PlayState.storyDifficulty = curSelected;
						MusicBeatState.resetState();
						FlxG.sound.music.volume = 0;
						PlayState.changedDifficulty = true;
						PlayState.chartingMode = false;
						return;
					}
				}
				catch(e:haxe.Exception)
				{
					trace('ERROR! ${e.message}');
	
					var errorStr:String = e.message;
					if(errorStr.startsWith('[lime.utils.Assets] ERROR:')) errorStr = 'Missing file: ' + errorStr.substring(errorStr.indexOf(songLowercase), errorStr.length-1); //Missing chart
					else errorStr += '\n\n' + e.stack;

					missingText.text = 'ERROR WHILE LOADING CHART:\n$errorStr';
					missingText.screenCenter(Y);
					missingText.visible = true;
					missingTextBG.visible = true;
					FlxG.sound.play(Paths.sound('cancelMenu'));

					super.update(elapsed);
					return;
				}


				menuItems = menuItemsOG;
				regenMenu();
			}

			switch (daSelected)
			{
				case "Resume":
					close();
				case 'Change Difficulty':
					menuItems = difficultyChoices;
					deleteSkipTimeText();
					regenMenu();
				case 'Toggle Practice Mode':
					PlayState.instance.practiceMode = !PlayState.instance.practiceMode;
					PlayState.changedDifficulty = true;
					practiceText.visible = PlayState.instance.practiceMode;
					trace("✓ [Menú Clásico] Practice Mode: " + (PlayState.instance.practiceMode ? "ACTIVADO" : "DESACTIVADO"));
				case "Restart Song":
					restartSong();
				case "Leave Charting Mode":
					restartSong();
					PlayState.chartingMode = false;
				case 'Skip Time':
					if(curTime < Conductor.songPosition)
					{
						PlayState.startOnTime = curTime;
						restartSong(true);
					}
					else
					{
						if (curTime != Conductor.songPosition)
						{
							PlayState.instance.clearNotesBefore(curTime);
							PlayState.instance.setSongTime(curTime);
						}
						close();
					}
				case 'End Song':
					close();
					PlayState.instance.notes.clear();
					PlayState.instance.unspawnNotes = [];
					PlayState.instance.finishSong(true);
				case 'Toggle Botplay':
					PlayState.instance.cpuControlled = !PlayState.instance.cpuControlled;
					PlayState.changedDifficulty = true;
					PlayState.instance.botplayTxt.visible = PlayState.instance.cpuControlled;
					PlayState.instance.botplayTxt.alpha = 1;
					PlayState.instance.botplaySine = 0;
					trace("✓ [Menú Clásico] Botplay: " + (PlayState.instance.cpuControlled ? "ACTIVADO" : "DESACTIVADO"));
				case 'Options':
					PlayState.instance.paused = true; // For lua
					PlayState.instance.vocals.volume = 0;
					PlayState.instance.canResync = false;
					MusicBeatState.switchState(new OptionsState());
					if(ClientPrefs.data.pauseMusic != 'None')
					{
						FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath(ClientPrefs.data.pauseMusic)), pauseMusic.volume);
						FlxTween.tween(FlxG.sound.music, {volume: 1}, 0.8);
						FlxG.sound.music.time = pauseMusic.time;
					}
					OptionsState.onPlayState = true;
				case "Exit to menu":
					//#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end
					PlayState.deathCounter = 0;
					PlayState.seenCutscene = false;

					PlayState.instance.canResync = false;
					Mods.loadTopMod();
					
					// Si es pretence, siempre volver al menú principal
					if (PlayState.instance.songName == "pretence") {
						SoftCodeMenuState.fromPlay = true;
						MusicBeatState.switchState(new SoftCodeMenuState(true));
					} else if(PlayState.isStoryMode) {
						MusicBeatState.switchState(new StoryMenuState());
					} else {
						SoftCodeMenuState.fromPlay = true;
						MusicBeatState.switchState(new SoftCodeMenuState(true));
					}

				
					PlayState.changedDifficulty = false;
					PlayState.chartingMode = false;
					FlxG.camera.followLerp = 0;
			}
		}
	}

	function deleteSkipTimeText()
	{
		if(skipTimeText != null)
		{
			skipTimeText.kill();
			remove(skipTimeText);
			skipTimeText.destroy();
		}
		skipTimeText = null;
		skipTimeTracker = null;
	}

	public static function restartSong(noTrans:Bool = false)
	{
		PlayState.instance.paused = true; // For lua
		FlxG.sound.music.volume = 0;
		PlayState.instance.vocals.volume = 0;

		if(noTrans)
		{
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
		}
		MusicBeatState.resetState();
	}

	override function destroy()
	{
		isOpen = false;
		if (pauseMusic != null) {
			pauseMusic.destroy();
		}
		super.destroy();
	}

	function changeSelection(change:Int = 0):Void
	{
		if (useVisualPauseMenu && !FlxG.keys.pressed.SHIFT && !PlayState.chartingMode) {
			changeVisualSelection(change);
			return;
		}

		// Lógica original del menú clásico
		curSelected = FlxMath.wrap(curSelected + change, 0, menuItems.length - 1);
		for (num => item in grpMenuShit.members)
		{
			item.targetY = num - curSelected;
			item.alpha = 0.6;
			if (item.targetY == 0)
			{
				item.alpha = 1;
				if(item == skipTimeTracker)
				{
					curTime = Math.max(0, Conductor.songPosition);
					updateSkipTimeText();
				}
			}
		}
		missingText.visible = false;
		missingTextBG.visible = false;
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
	}

	function changeVisualSelection(change:Int = 0):Void
	{
		trace("changeSelection");
		curSelected = FlxMath.wrap(curSelected + change, 0, menuItems.length - 1);
		updateVisualOption();
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
	}

	function updateVisualOption():Void
	{
		if (optionText == null || selectedText == null) return;
		
		// Si estamos en el menú de dificultad, usar diferentes sprites
		if (menuItems == difficultyChoices) {
			// Aquí podrías cambiar los sprites para mostrar las dificultades
			// Por ahora, solo actualizar la selección normal
			var maxOptions:Int = Std.int(Math.min(5, menuItems.length));
			for (i in 0...maxOptions) {
				if (i >= optionText.members.length || i >= selectedText.members.length) continue;
				
				if (i == curSelected) {
					optionText.members[i].alpha = 0;
					selectedText.members[i].alpha = 1;
					selectedText.members[i].scale.set(0.9, 0.9);
				} else {
					optionText.members[i].alpha = 0.2;
					selectedText.members[i].alpha = 0;
					optionText.members[i].scale.set(0.85, 0.85);
				}
			}
			return;
		}
		
		// Menú principal normal
		var maxOptions:Int = Std.int(Math.min(5, menuItems.length));
		for (i in 0...maxOptions) {
			if (i >= optionText.members.length || i >= selectedText.members.length) continue;
			
			if (i == curSelected) {
				optionText.members[i].alpha = 0;
				selectedText.members[i].alpha = 1;
				selectedText.members[i].scale.set(0.9, 0.9);
			} else {
				optionText.members[i].alpha = 0.2;
				selectedText.members[i].alpha = 0;
				optionText.members[i].scale.set(0.85, 0.85);
			}
		}
	}

	function regenMenu():Void {
		for (i in 0...grpMenuShit.members.length)
		{
			var obj:Alphabet = grpMenuShit.members[0];
			obj.kill();
			grpMenuShit.remove(obj, true);
			obj.destroy();
		}

		for (num => str in menuItems) {
			var item = new Alphabet(90, 320, Language.getPhrase('pause_$str', str), true);
			item.isMenuItem = true;
			item.targetY = num;
			grpMenuShit.add(item);

			if(str == 'Skip Time')
			{
				skipTimeText = new FlxText(0, 0, 0, '', 64);
				skipTimeText.setFormat(Paths.font("vcr.ttf"), 64, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				skipTimeText.scrollFactor.set();
				skipTimeText.borderSize = 2;
				skipTimeTracker = item;
				add(skipTimeText);

				updateSkipTextStuff();
				updateSkipTimeText();
			}
		}
		curSelected = 0;
		changeSelection();
	}
	
	function updateSkipTextStuff()
	{
		if(skipTimeText == null || skipTimeTracker == null) return;

		skipTimeText.x = skipTimeTracker.x + skipTimeTracker.width + 60;
		skipTimeText.y = skipTimeTracker.y;
		skipTimeText.visible = (skipTimeTracker.alpha >= 1);
	}

	function updateSkipTimeText()
		skipTimeText.text = FlxStringUtil.formatTime(Math.max(0, Math.floor(curTime / 1000)), false) + ' / ' + FlxStringUtil.formatTime(Math.max(0, Math.floor(FlxG.sound.music.length / 1000)), false);

	function toggleHelpTable()
	{
		helpTableVisible = !helpTableVisible;
		
		if (helpTableVisible) {
			createHelpTable();
		} else {
			destroyHelpTable();
		}
	}

	function createHelpTable()
	{
		// Crear fondo oscuro
		helpTableBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		helpTableBG.alpha = 0.7;
		helpTableBG.scrollFactor.set();
		add(helpTableBG);

		var helpLines:Array<String> = [
			"== PAUSE MENU CONTROLS ==",
			"",
			"B - Toggle Botplay",
			"P - Toggle Practice Mode",
			"UP/DOWN - Navigate Menu",
			"ENTER - Select Option",
			"ESC - Resume Game",
			"",
			"== QUICK INFO ==",
			"Botplay: " + (PlayState.instance.cpuControlled ? "ON" : "OFF"),
			"Practice Mode: " + (PlayState.instance.practiceMode ? "ON" : "OFF"),
			"",
			"Press TAB again to close"
		];

		var centerX = FlxG.width / 2;
		var startY = 100;
		var lineHeight = 30;

		for (i in 0...helpLines.length) {
			var txt = new FlxText(centerX - 200, startY + (i * lineHeight), 400, helpLines[i], 20);
			txt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			txt.scrollFactor.set();
			txt.borderSize = 2;
			add(txt);
			helpTableTexts.push(txt);
		}
	}

	function destroyHelpTable()
	{
		if (helpTableBG != null) {
			remove(helpTableBG);
			helpTableBG.destroy();
			helpTableBG = null;
		}

		for (txt in helpTableTexts) {
			remove(txt);
			txt.destroy();
		}
		helpTableTexts = [];
	}
}
