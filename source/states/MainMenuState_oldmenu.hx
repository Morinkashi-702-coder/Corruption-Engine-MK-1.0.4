package states;

import flixel.FlxObject;
import flixel.effects.FlxFlicker;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import lime.app.Application;
import states.editors.MasterEditorMenu;
import options.OptionsState;
import objects.VideoSprite;
import objects.Alphabet;
#if sys
import sys.FileSystem;
#end

enum MainMenuColumnOldmenu {
    LEFT;
    CENTER;
    RIGHT;
}

class MainMenuState_oldmenu extends MusicBeatState
{
	public static var psychEngineVersion:String = '1.0.4'; // This is also used for Discord RPC
	public static var curSelected:Int = 0;
	public static var curColumn:MainMenuColumnOldmenu = CENTER;
	var allowMouse:Bool = true; //Turn this off to block mouse movement in menus

	var leftItem:FlxSprite = null;
	var rightItem:FlxSprite = null;

	//Centered/Text options
	var optionShit:Array<String> = [
		'story_mode',
		'freeplay',
		'credits',
		'options'
	];

	// El menu antiguo ya no utiliza botones laterales.
	var leftOption:String = null;
	var rightOption:String = null;

	var bg:FlxSprite;
	var magenta:FlxSprite;
	var camFollow:FlxObject;
	var mainMenuImages:Array<FlxSprite> = [];
	var selectedImages:Array<FlxSprite> = [];
	var mainmenuNumImages:Array<FlxSprite> = []; // mainmenu0, mainmenu1, mainmenu2, mainmenu3
	var mainselectedNumImages:Array<FlxSprite> = []; // mainselected0, mainselected1, mainselected2, mainselected3
	var emberVideo:VideoSprite;
	var menuBF:FlxSprite;
	var menuBFeye:FlxSprite;
	var menuBFeyeOffsetX:Float = 0;
	var menuBFeyeOffsetY:Float = 0;
	var whiteFlash:FlxSprite;
	
	// Variables para modo desarrollador
	var devMode:Bool = false;
	var selectedElement:FlxSprite = null;
	var selectedIndex:Int = -1;
	var lastPressedKey:Int = -1;
	var lastPressTime:Float = 0;
	var devInfoText:FlxText;
	var saveMessageText:FlxText;
	var saveMessageTimer:Float = 0;

	var isBeingDestroyed:Bool = false;

	static var showOutdatedWarning:Bool = true;
	override function create()
	{
		// curColumn es static: impedir que una seleccion lateral de una sesion
		// anterior sobreviva aunque los botones ya no existan.
		curColumn = CENTER;
		leftItem = null;
		rightItem = null;

		// CRITICAL: Initialize AlphaCharacter data FIRST, before anything else
		if (AlphaCharacter.allLetters == null)
		{
			AlphaCharacter.loadAlphabetData();
		}

		try
		{
			super.create();
		}
		catch (e:Dynamic)
		{
			// Ignorar error en super.create()
		}

		try
		{
			createMainMenu();
		} catch (e:Dynamic) {
			trace('ERROR in MainMenuState_oldmenu.create(): $e');
			// Crear menú simple de emergencia
			var bgBlack:FlxSprite = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
			add(bgBlack);
			
			var errorText:FlxText = new FlxText(0, FlxG.height / 2, FlxG.width, 'ERROR LOADING MAIN MENU\nPress ESC to go back', 32);
			errorText.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, CENTER);
			errorText.scrollFactor.set();
			add(errorText);
		}
	}

	function createMainMenu()
	{

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

	persistentUpdate = persistentDraw = true;

	var yScroll:Float = 0.25;
	
	bg = new FlxSprite(-183, -129).loadGraphic(Paths.image('menus/mainmenu/old/menuBG'));
	bg.antialiasing = ClientPrefs.data.antialiasing;
	bg.scrollFactor.set(0, yScroll);
	bg.setGraphicSize(Std.int(bg.width * 1.175));
	bg.updateHitbox();
	bg.alpha = 1.0; // 100% opacidad
	add(bg);
	
	#if VIDEOS_ALLOWED
	// Añadir video ember JUSTO DESPUÉS del menuBG
	trace('VIDEOS_ALLOWED está habilitado');
	var videoPath:String = Paths.video('ember');
	trace('Ruta del video: ' + videoPath);
	#if sys
	if (sys.FileSystem.exists(videoPath))
	{
		trace('¡El archivo de video existe!');
	}
	else
	{
		trace('ERROR: El archivo de video NO existe en: ' + videoPath);
	}
	#end
	emberVideo = new VideoSprite(videoPath, true, false, true);
	emberVideo.scrollFactor.set();
	emberVideo.cameras = [FlxG.camera];
	emberVideo.x = 0;
	emberVideo.y = 1;
	emberVideo.alpha = 0.26; // 26% opacidad
	add(emberVideo);
	
	// Iniciar reproducción del video explícitamente
	if (emberVideo.videoSprite != null && emberVideo.videoSprite.bitmap != null)
	{
		trace('Iniciando reproducción del video...');
		emberVideo.videoSprite.bitmap.play();
	}
	
	trace('Video ember añadido - X: ' + emberVideo.x + ', Y: ' + emberVideo.y);
	trace('Video visible: ' + emberVideo.visible + ', alpha: ' + emberVideo.alpha);
	if (emberVideo.videoSprite != null)
	{
		trace('VideoSprite interno existe');
		trace('VideoSprite X: ' + emberVideo.videoSprite.x + ', Y: ' + emberVideo.videoSprite.y);
		trace('VideoSprite width: ' + emberVideo.videoSprite.width + ', height: ' + emberVideo.videoSprite.height);
		trace('VideoSprite visible: ' + emberVideo.videoSprite.visible + ', alpha: ' + emberVideo.videoSprite.alpha);
		if (emberVideo.videoSprite.bitmap != null)
		{
			trace('Video bitmap existe - isPlaying: ' + emberVideo.videoSprite.bitmap.isPlaying);
		}
	}
	else
	{
		trace('ERROR: videoSprite interno es NULL');
	}
	#else
	trace('VIDEOS_ALLOWED NO está habilitado en tu compilación');
	#end
	
	// Agregar imagen menuBF encima del video con transición
	menuBF = new FlxSprite().loadGraphic(Paths.image('menus/mainmenu/old/menuBF'));
	menuBF.antialiasing = ClientPrefs.data.antialiasing;
	menuBF.scrollFactor.set();
	menuBF.screenCenter();
	
	// Guardar la posición final
	var finalX:Float = menuBF.x;
	
	// Posicionar fuera de la pantalla (a la izquierda)
	menuBF.x = -menuBF.width;
	
	add(menuBF);
	
	// Animar la entrada desde la izquierda hacia la derecha
	FlxTween.tween(menuBF, {x: finalX}, 1.0, {
		ease: FlxEase.expoOut,
		startDelay: 0.3
	});
	
	trace('Imagen menuBF añadida con transición - Posición final: X: ' + finalX + ', Y: ' + menuBF.y);
	
	// Agregar imagen menuBFeye (oculta inicialmente, aparecerá al seleccionar)
	menuBFeye = new FlxSprite().loadGraphic(Paths.image('menus/mainmenu/old/menuBFeye'));
	menuBFeye.antialiasing = ClientPrefs.data.antialiasing;
	menuBFeye.scrollFactor.set();
	menuBFeye.screenCenter();
	// Calcular el anclaje desde la posición final, no desde el inicio del tween.
	menuBFeyeOffsetX = menuBFeye.x - finalX;
	menuBFeyeOffsetY = menuBFeye.y - menuBF.y;
	menuBFeye.setPosition(menuBF.x + menuBFeyeOffsetX, menuBF.y + menuBFeyeOffsetY);
	menuBFeye.visible = false; // Oculta hasta que se seleccione una opción
	add(menuBFeye);
	trace('Imagen menuBFeye añadida (oculta) - X: ' + menuBFeye.x + ', Y: ' + menuBFeye.y);
	
	camFollow = new FlxObject(0, 0, 1, 1);
	camFollow.setPosition(FlxG.width / 2, FlxG.height / 2);
	add(camFollow);

		// Magenta parpadeo removido
	/*
	magenta = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
		magenta.antialiasing = ClientPrefs.data.antialiasing;
		magenta.scrollFactor.set(0, yScroll);
		magenta.setGraphicSize(Std.int(magenta.width * 1.175));
		magenta.updateHitbox();
		magenta.screenCenter();
	magenta.visible = false;
	magenta.color = 0xFFfd719b;
	add(magenta);
	*/

	// Agregar separadores (al frente)
	var seperators:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image('menus/mainmenu/old/seperators'));
	seperators.antialiasing = ClientPrefs.data.antialiasing;
	seperators.screenCenter(Y);
	add(seperators);
	
	// Agregar separadores al lado derecho
	var seperatorsRight:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image('menus/mainmenu/old/seperators'));
	seperatorsRight.antialiasing = ClientPrefs.data.antialiasing;
	seperatorsRight.screenCenter(Y);
	seperatorsRight.x = FlxG.width - seperatorsRight.width;
	add(seperatorsRight);

	// Crear las opciones del menú con imágenes
	var positionsNotSelected:Array<Array<Float>> = [
		[794, 133], // mainmenu 1
		[788, 249], // mainmenu 2
		[787, 361], // mainmenu 3
		[788, 469]  // mainmenu 4
	];
	
	var positionsSelected:Array<Array<Float>> = [
		[642, 143], // selected 1
		[646, 252], // selected 2
		[643, 363], // selected 3
		[644, 472]  // selected 4
	];
	
	for (num => option in optionShit)
	{
		// Imagen no seleccionada
		var notSelected:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menus/mainmenu/old/notselect'));
		notSelected.antialiasing = ClientPrefs.data.antialiasing;
		if (num < positionsNotSelected.length)
		{
			notSelected.x = positionsNotSelected[num][0];
			notSelected.y = positionsNotSelected[num][1];
		}
		add(notSelected);
		mainMenuImages.push(notSelected);
		
		// Imagen seleccionada
		var selected:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menus/mainmenu/old/selected'));
		selected.antialiasing = ClientPrefs.data.antialiasing;
		if (num < positionsSelected.length)
		{
			selected.x = positionsSelected[num][0];
			selected.y = positionsSelected[num][1];
		}
		selected.visible = false;
		add(selected);
		selectedImages.push(selected);
	}
	
	// Añadir las imágenes mainmenu0, mainmenu1, mainmenu2, mainmenu3
	var positionsMainmenuNum:Array<Array<Float>> = [
		[745, 165], // mainmenu0
		[739, 275], // mainmenu1
		[748, 387], // mainmenu2
		[750, 495]  // mainmenu3
	];
	
	for (i in 0...4)
	{
		var mainmenuNum:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menus/mainmenu/old/mainmenu' + i));
		mainmenuNum.antialiasing = ClientPrefs.data.antialiasing;
		if (i < positionsMainmenuNum.length)
		{
			mainmenuNum.x = positionsMainmenuNum[i][0];
			mainmenuNum.y = positionsMainmenuNum[i][1];
		}
		add(mainmenuNum);
		mainmenuNumImages.push(mainmenuNum);
	}
	
	// Añadir las imágenes mainselected0, mainselected1, mainselected2, mainselected3
	for (i in 0...4)
	{
		var mainselectedNum:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menus/mainmenu/old/mainselected' + i));
		mainselectedNum.antialiasing = ClientPrefs.data.antialiasing;
		if (i < positionsMainmenuNum.length)
		{
			mainselectedNum.x = positionsMainmenuNum[i][0];
			mainselectedNum.y = positionsMainmenuNum[i][1];
		}
		mainselectedNum.visible = false; // Ocultas por defecto
		add(mainselectedNum);
		mainselectedNumImages.push(mainselectedNum);
	}

	if (leftOption != null)
		leftItem = createMenuItem(leftOption, 60, 490);
	if (rightOption != null)
	{
		rightItem = createMenuItem(rightOption, FlxG.width - 60, 490);
		if (rightItem != null)
			rightItem.x -= rightItem.width;
	}

		var psychVer:FlxText = new FlxText(12, FlxG.height - 44, 0, "Psych Engine v" + psychEngineVersion, 12);
		psychVer.scrollFactor.set();
		psychVer.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(psychVer);
	var fnfVer:FlxText = new FlxText(12, FlxG.height - 24, 0, "Friday Night Funkin' v" + Application.current.meta.get('version'), 12);
	fnfVer.scrollFactor.set();
	fnfVer.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
	add(fnfVer);
	
	// Crear texto de información para modo desarrollador
	devInfoText = new FlxText(10, 10, FlxG.width - 20);
	devInfoText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.YELLOW, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
	devInfoText.scrollFactor.set();
	devInfoText.visible = false;
	add(devInfoText);
	
	// Crear texto de mensaje de guardado
	saveMessageText = new FlxText(0, 0, 0, "COORDENADAS GUARDADAS!");
	saveMessageText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.LIME, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
	saveMessageText.borderSize = 2;
	saveMessageText.scrollFactor.set();
	saveMessageText.screenCenter();
	saveMessageText.y = FlxG.height * 0.4;
	saveMessageText.visible = false;
	add(saveMessageText);
	
	// Crear flash blanco (oculto inicialmente)
	whiteFlash = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.WHITE);
	whiteFlash.scrollFactor.set();
	whiteFlash.alpha = 0;
	add(whiteFlash);
	
	changeItem();		#if ACHIEVEMENTS_ALLOWED
		// Unlocks "Freaky on a Friday Night" achievement if it's a Friday and between 18:00 PM and 23:59 PM
		var leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18)
			Achievements.unlock('friday_night_play');

		#if MODS_ALLOWED
		Achievements.reloadList();
		#end
		#end

	#if CHECK_FOR_UPDATES
	if (showOutdatedWarning && ClientPrefs.data.checkForUpdates && substates.OutdatedSubState.updateVersion != psychEngineVersion) {
		persistentUpdate = false;
		showOutdatedWarning = false;
		openSubState(new substates.OutdatedSubState());
	}
	#end

	FlxG.camera.follow(camFollow, null, 0.15);
	
	// Slide in desde la derecha
	for (memb in selectedImages)
	{
		memb.x += FlxG.width;
		FlxTween.tween(memb, {x: memb.x - FlxG.width}, 0.5, {ease: FlxEase.expoOut});
	}
	if (leftItem != null)
	{
		leftItem.x += FlxG.width;
		FlxTween.tween(leftItem, {x: leftItem.x - FlxG.width}, 0.5, {ease: FlxEase.expoOut});
	}
	if (rightItem != null)
	{
		rightItem.x += FlxG.width;
		FlxTween.tween(rightItem, {x: rightItem.x - FlxG.width}, 0.5, {ease: FlxEase.expoOut});
	}
	// menuBG permanece fijo durante la entrada y la selección.
	// magenta tween removido
	/*
	magenta.x += FlxG.width;
	FlxTween.tween(magenta, {x: magenta.x - FlxG.width}, 0.5, {ease: FlxEase.expoOut});
	*/
	
	// Reproducir música del menú antiguo
	if (FlxG.sound.music == null || FlxG.sound.music.playing == false)
	{
		FlxG.sound.playMusic(Paths.music('menusongold1'), 0.7);
	}
	else
	{
		// Si la música ya está playing, solo restaurar volumen (viene de un submenu)
		FlxG.sound.music.stop();
		FlxG.sound.playMusic(Paths.music('menusongold1'), 0.7);
	}
	}

	function createMenuItem(name:String, x:Float, y:Float):FlxSprite
	{
		var menuItem:FlxSprite = new FlxSprite(x, y);
		
		try
		{
			menuItem.frames = Paths.getSparrowAtlas('menus/mainmenu/old/menu_$name');
			menuItem.animation.addByPrefix('idle', '$name idle', 24, true);
			menuItem.animation.addByPrefix('selected', '$name selected', 24, true);
			menuItem.animation.play('idle');
		}
		catch (e:Dynamic)
		{
			trace('[MainMenuState_oldmenu] Advertencia: No se pudo cargar menu_$name - devolviendo null');
			return null;
		}
		
		menuItem.updateHitbox();
		menuItem.antialiasing = ClientPrefs.data.antialiasing;
		menuItem.scrollFactor.set();
		return menuItem;
	}

	var selectedSomethin:Bool = false;

	override function draw():Void
	{
		// Sincronizar antes de dibujar, también durante los tweens de entrada.
		if (menuBF != null && menuBFeye != null)
			menuBFeye.setPosition(menuBF.x + menuBFeyeOffsetX, menuBF.y + menuBFeyeOffsetY);
		super.draw();
	}

	var timeNotMoving:Float = 0;
	override function update(elapsed:Float)
	{
		try
		{
		// NO SUBIR AUTOMATICAMENTE EL VOLUMEN - dejar que los tweens lo controlen
		// if (FlxG != null && FlxG.sound != null && FlxG.sound.music != null && FlxG.sound.music.volume < 0.8)
		//	FlxG.sound.music.volume = Math.min(FlxG.sound.music.volume + 0.5 * elapsed, 0.8);

		if (!selectedSomethin && controls != null)
		{
			if (controls.UI_UP_P)
			{
				trace('[OLDMENU] UP pressed, llamando changeItem(-1)');
				changeItem(-1);
			}

			if (controls.UI_DOWN_P)
			{
				trace('[OLDMENU] DOWN pressed, llamando changeItem(1)');
				changeItem(1);
			}

			var mouseAllowed:Bool = allowMouse;
			if (mouseAllowed && ((FlxG.mouse.deltaScreenX != 0 && FlxG.mouse.deltaScreenY != 0) || FlxG.mouse.justPressed))
			{
				mouseAllowed = false;
				FlxG.mouse.visible = true;
				timeNotMoving = 0;

				var selectedItem:FlxSprite;
				switch(curColumn)
				{
					case CENTER:
						selectedItem = (curSelected < selectedImages.length) ? selectedImages[curSelected] : null;
					case LEFT:
						selectedItem = leftItem;
					case RIGHT:
						selectedItem = rightItem;
				}

				// Check hover on left item
				if(leftItem != null && FlxG.mouse.overlaps(leftItem))
				{
					mouseAllowed = true;
					if(selectedItem != leftItem)
					{
						curColumn = LEFT;
						changeItem();
					}
				}
				// Check hover on right item
				else if(rightItem != null && FlxG.mouse.overlaps(rightItem))
				{
					mouseAllowed = true;
					if(selectedItem != rightItem)
					{
						curColumn = RIGHT;
						changeItem();
					}
				}
				// Check hover on center menu items - check both visible sprites
				else
				{
					var dist:Float = -1;
					var distItem:Int = -1;
					for (i in 0...optionShit.length)
					{
						// Check both the selected and non-selected sprites for hover
						var selectedSprite:FlxSprite = (i < selectedImages.length) ? selectedImages[i] : null;
						var normalSprite:FlxSprite = (i < mainMenuImages.length) ? mainMenuImages[i] : null;
						
						// Check whichever sprite is currently visible
						var currentSprite:FlxSprite = null;
						if (selectedSprite != null && selectedSprite.visible)
							currentSprite = selectedSprite;
						else if (normalSprite != null && normalSprite.visible)
							currentSprite = normalSprite;
						
						if(currentSprite != null && FlxG.mouse.overlaps(currentSprite))
						{
							var distance:Float = Math.sqrt(Math.pow(currentSprite.getGraphicMidpoint().x - FlxG.mouse.screenX, 2) + Math.pow(currentSprite.getGraphicMidpoint().y - FlxG.mouse.screenY, 2));
							if (dist < 0 || distance < dist)
							{
								dist = distance;
								distItem = i;
								mouseAllowed = true;
							}
						}
					}

					if(distItem != -1 && curSelected != distItem)
					{
						curColumn = CENTER;
						curSelected = distItem;
						changeItem();
					}
				}
			}
			else
			{
				timeNotMoving += elapsed;
				if(timeNotMoving > 2) FlxG.mouse.visible = false;
			}

			switch(curColumn)
			{
				case CENTER:
					if(controls.UI_LEFT_P && leftOption != null)
					{
						curColumn = LEFT;
						changeItem();
					}
					else if(controls.UI_RIGHT_P && rightOption != null)
					{
						curColumn = RIGHT;
						changeItem();
					}

				case LEFT:
					if(controls.UI_RIGHT_P)
					{
						curColumn = CENTER;
						changeItem();
					}

				case RIGHT:
					if(controls.UI_LEFT_P)
					{
						curColumn = CENTER;
						changeItem();
					}
			}

		if (controls.BACK)
		{
			selectedSomethin = true;
			FlxG.mouse.visible = false;
			FlxG.sound.play(Paths.sound('cancelMenu'));
			// Misma salida que Freeplay, pero BF se retira hacia la izquierda.
			if (menuBF != null)
			{
				FlxTween.cancelTweensOf(menuBF);
				FlxTween.tween(menuBF, {x: menuBF.x - menuBF.width}, 0.5, {ease: FlxEase.expoIn});
			}
			new FlxTimer().start(0.5, function(tmr:FlxTimer) {
				MusicBeatState.switchState(new TitleState_oldmenu());
			});
		}
		else if (controls.ACCEPT || (FlxG.mouse.justPressed && mouseAllowed))
		{
			FlxG.sound.play(Paths.sound('confirmMenu'));
			selectedSomethin = true;
			FlxG.mouse.visible = false;

				// Efecto de flash blanco
				if (whiteFlash != null)
				{
					whiteFlash.alpha = 0.7; // Flash blanco al 70%
					FlxTween.tween(whiteFlash, {alpha: 0}, 1.0, {ease: FlxEase.expoOut});
				}

				// Mostrar menuBFeye encima de menuBF (sin ocultar menuBF)
				if (menuBFeye != null) menuBFeye.visible = true;

				// magenta flicker removido
				/*
				if (ClientPrefs.data.flashing)
					FlxFlicker.flicker(magenta, 1.1, 0.15, false);
				*/

				var item:FlxSprite;
				var option:String;
				switch(curColumn)
				{
					case CENTER:
						option = optionShit[curSelected];
						item = (curSelected < selectedImages.length) ? selectedImages[curSelected] : null;

					case LEFT:
						option = leftOption;
						item = leftItem;

					case RIGHT:
						option = rightOption;
				item = rightItem;
		}

		FlxFlicker.flicker(item, 1, 0.06, false, false, function(flick:FlxFlicker)
		{
			// Deslizar solo BF; menuBFeye lo sigue mediante su anclaje.
			if (menuBF != null)
			{
				FlxTween.cancelTweensOf(menuBF);
				FlxTween.tween(menuBF, {x: -menuBF.width}, 0.5, {ease: FlxEase.expoIn});
			}
		// magenta tween removido
		// FlxTween.tween(magenta, {x: -magenta.width}, 0.5, {ease: FlxEase.expoIn});
					new FlxTimer().start(0.5, function(tmr:FlxTimer)
		{
			switch (option)
			{
				case 'story_mode':
					FlxTween.tween(FlxG.sound.music, {volume: 0}, 0.5, {ease: FlxEase.expoIn});
					if (PlayState.SONG != null)
					{
						PlayState.SONG.arrowSkin = null;
						PlayState.SONG.splashSkin = null;
						PlayState.stageUI = 'normal';
					}
					MusicBeatState.switchState(new StoryMenuState());
				case 'freeplay':
					MusicBeatState.switchState(new FreeplayState_oldmenu());
				#if MODS_ALLOWED
				case 'mods':
					MusicBeatState.switchState(new ModsMenuState());
				#end

				#if ACHIEVEMENTS_ALLOWED
				case 'achievements':
					MusicBeatState.switchState(new AchievementsMenuState());
				#end

				case 'credits':
					FlxTween.tween(FlxG.sound.music, {volume: 0}, 0.5, {ease: FlxEase.expoIn});
					MusicBeatState.switchState(new CreditsState_oldmenu());
					trace('debug: entrando en CreditsState_oldmenu desde MainMenuState_oldmenu');
				case 'options':
					FlxTween.tween(FlxG.sound.music, {volume: 0}, 0.5, {ease: FlxEase.expoIn});
					MusicBeatState.switchState(new OptionsState());
					trace('debug: entrando en OptionsState unificado desde MainMenuState_oldmenu');
				case 'donate':
					CoolUtil.browserLoad('https://ninja-muffin24.itch.io/funkin');
					selectedSomethin = false;
					item.visible = true;
				default:
					trace('Menu Item ${option} doesn\'t do anything');
					selectedSomethin = false;
					item.visible = true;
			}
		});
		});
		
		for (memb in selectedImages)
		{
			if(memb == item)
				continue;					FlxTween.tween(memb, {alpha: 0}, 0.4, {ease: FlxEase.quadOut});
				}
			}
			#if desktop
			if (controls.justPressed('debug_1'))
			{
				selectedSomethin = true;
				FlxG.mouse.visible = false;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
			#end
		}

		// Activar modo desarrollador con tecla 9
		if (FlxG.keys.justPressed.NINE)
		{
			devMode = !devMode;
			FlxG.mouse.visible = devMode;
			devInfoText.visible = devMode;
			if (devMode)
				trace("Modo desarrollador activado");
			else
			{
				trace("Modo desarrollador desactivado");
				selectedElement = null;
				selectedIndex = -1;
			}
		}

		// Actualizar modo desarrollador
		if (devMode)
			updateDevMode();

		// Actualizar temporizador del mensaje de guardado
		if (saveMessageTimer > 0)
		{
			saveMessageTimer -= elapsed;
			if (saveMessageTimer <= 0)
			{
				saveMessageText.visible = false;
			}
		}

		try
		{
			super.update(elapsed);
		}
		catch (e:Dynamic)
		{
			// Ignorar errores silenciosamente
		}
		}
	}

	override function destroy():Void
	{
		isBeingDestroyed = true;
		try {
			super.destroy();
		} catch (e:Dynamic) {
			trace('[MainMenuState_oldmenu] Error during destroy: $e');
		}
	}

	function updateDevMode()
	{
		try
		{
		// Actualizar texto de información
		var infoStr:String = "=== MODO DESARROLLADOR (Presiona 9 para salir) ===\n";
		infoStr += "\nSELECCIONAR ELEMENTO:\n";
		infoStr += "- Presiona 1-4: Selecciona 'mainmenu' (notselect)\n";
		infoStr += "- Presiona 1-4 DOS VECES: Selecciona 'selected'\n";
		infoStr += "- Presiona 5: Selecciona 'mainmenu0'\n";
		infoStr += "- Presiona 5 DOS VECES: Selecciona 'mainmenu2'\n";
		infoStr += "- Presiona 6: Selecciona 'mainmenu1'\n";
		infoStr += "- Presiona 8: Selecciona 'mainmenu3'\n";
		infoStr += "- CTRL + 5/6/7/8: Selecciona 'mainselected0-3'\n";
		infoStr += "- V: Selecciona VIDEO 'ember'\n";
		infoStr += "- U: Selecciona FONDO 'menuBG'\n";
		infoStr += "\nCONTROLES:\n";
		infoStr += "- Flechas: Mover elemento seleccionado\n";
		infoStr += "- SHIFT + Flechas: Mover mas rapido (10px)\n";
		infoStr += "- Q/E: Escalar (reducir/agrandar)\n";
		infoStr += "- R: Centrar elemento\n";
		infoStr += "- N: Alejar camara (Zoom Out)\n";
		infoStr += "- M: Acercar camara (Zoom In)\n";
		infoStr += "- J: Bajar opacidad (video/fondo)\n";
		infoStr += "- K: Subir opacidad (video/fondo)\n";
		infoStr += "- P: GUARDAR coordenadas actuales\n";
		infoStr += "\nZoom actual: " + Math.round(FlxG.camera.zoom * 100) + "%\n";
		#if VIDEOS_ALLOWED
		if (emberVideo != null)
			infoStr += "Opacidad video: " + Math.round(emberVideo.alpha * 100) + "%\n";
		#end
		if (bg != null)
			infoStr += "Opacidad menuBG: " + Math.round(bg.alpha * 100) + "%\n";
		
		if (selectedElement != null && (selectedIndex >= 0 || selectedIndex == -99 || selectedIndex == -98))
		{
			var tipo:String = "";
			var realIndex:Int = 0;
			
			if (selectedIndex == -99)
			{
				// Es el video
				tipo = "VIDEO";
				realIndex = 0;
			}
			else if (selectedIndex == -98)
			{
				// Es el menuBG
				tipo = "MENUBG";
				realIndex = 0;
			}
			else if (selectedIndex >= (mainMenuImages.length * 2) + mainmenuNumImages.length)
			{
				// Es una imagen mainselected0-3
				tipo = "MAINSELECTED-NUM";
				realIndex = selectedIndex - (mainMenuImages.length * 2) - mainmenuNumImages.length;
			}
			else if (selectedIndex >= (mainMenuImages.length * 2))
			{
				// Es una imagen mainmenu0-3
				tipo = "MAINMENU-NUM";
				realIndex = selectedIndex - (mainMenuImages.length * 2);
			}
			else if (selectedIndex >= mainMenuImages.length)
			{
				// Es una imagen selected
				tipo = "SELECTED";
				realIndex = selectedIndex - mainMenuImages.length;
			}
			else
			{
				// Es una imagen mainmenu normal
				tipo = "MAINMENU";
				realIndex = selectedIndex;
			}
			
			infoStr += '\n=== ${tipo} ${realIndex + 1} ===\n';
			infoStr += 'Posicion: X=${Std.int(selectedElement.x)}, Y=${Std.int(selectedElement.y)}\n';
			infoStr += 'Escala: X=${Math.round(selectedElement.scale.x * 100) / 100}, Y=${Math.round(selectedElement.scale.y * 100) / 100}\n';
			infoStr += 'Tamaño: W=${Std.int(selectedElement.width)}, H=${Std.int(selectedElement.height)}';
		}
		else
		{
			infoStr += "\nNingun elemento seleccionado - Presiona 1-8";
		}
		
		devInfoText.text = infoStr;

		var currentTime = Date.now().getTime();
		var doubleClickTime = 500; // 500ms para detectar doble clic

		// Seleccionar elemento con teclas numéricas (1-4)
		if (FlxG.keys.justPressed.ONE)
		{
			if (lastPressedKey == 1 && (currentTime - lastPressTime) < doubleClickTime && mainMenuImages.length > 0)
			{
				// Doble clic: seleccionar "selected"
				selectedIndex = mainMenuImages.length + 0;
				selectedElement = selectedImages[0];
				lastPressedKey = -1;
			}
			else if (mainMenuImages.length > 0)
			{
				// Un clic: seleccionar "mainmenu"
				selectedIndex = 0;
				selectedElement = mainMenuImages[0];
				lastPressedKey = 1;
				lastPressTime = currentTime;
			}
		}
		else if (FlxG.keys.justPressed.TWO)
		{
			if (lastPressedKey == 2 && (currentTime - lastPressTime) < doubleClickTime && mainMenuImages.length > 1)
			{
				selectedIndex = mainMenuImages.length + 1;
				selectedElement = selectedImages[1];
				lastPressedKey = -1;
			}
			else if (mainMenuImages.length > 1)
			{
				selectedIndex = 1;
				selectedElement = mainMenuImages[1];
				lastPressedKey = 2;
				lastPressTime = currentTime;
			}
		}
		else if (FlxG.keys.justPressed.THREE)
		{
			if (lastPressedKey == 3 && (currentTime - lastPressTime) < doubleClickTime && mainMenuImages.length > 2)
			{
				selectedIndex = mainMenuImages.length + 2;
				selectedElement = selectedImages[2];
				lastPressedKey = -1;
			}
			else if (mainMenuImages.length > 2)
			{
				selectedIndex = 2;
				selectedElement = mainMenuImages[2];
				lastPressedKey = 3;
				lastPressTime = currentTime;
			}
		}
		else if (FlxG.keys.justPressed.FOUR)
		{
			if (lastPressedKey == 4 && (currentTime - lastPressTime) < doubleClickTime && mainMenuImages.length > 3)
			{
				selectedIndex = mainMenuImages.length + 3;
				selectedElement = selectedImages[3];
				lastPressedKey = -1;
			}
			else if (mainMenuImages.length > 3)
			{
				selectedIndex = 3;
				selectedElement = mainMenuImages[3];
				lastPressedKey = 4;
				lastPressTime = currentTime;
			}
		}
		// Tecla 5 con doble clic para mainmenu0 y mainmenu2
		else if (FlxG.keys.justPressed.FIVE)
		{
			if (lastPressedKey == 5 && (currentTime - lastPressTime) < doubleClickTime && mainmenuNumImages.length > 2)
			{
				// Doble clic: seleccionar mainmenu2
				selectedIndex = (mainMenuImages.length * 2) + 2;
				selectedElement = mainmenuNumImages[2];
				lastPressedKey = -1;
			}
			else if (mainmenuNumImages.length > 0)
			{
				// Un clic: seleccionar mainmenu0
				selectedIndex = (mainMenuImages.length * 2) + 0;
				selectedElement = mainmenuNumImages[0];
				lastPressedKey = 5;
				lastPressTime = currentTime;
			}
		}
		// Tecla 6 para mainmenu1
		else if (FlxG.keys.justPressed.SIX && mainmenuNumImages.length > 1)
		{
			selectedIndex = (mainMenuImages.length * 2) + 1;
			selectedElement = mainmenuNumImages[1];
		}
		// Tecla 8 para mainmenu3
		else if (FlxG.keys.justPressed.EIGHT && mainmenuNumImages.length > 3)
		{
			selectedIndex = (mainMenuImages.length * 2) + 3;
			selectedElement = mainmenuNumImages[3];
		}
		// CTRL + 5 para mainselected0
		else if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.FIVE && mainselectedNumImages.length > 0)
		{
			selectedIndex = (mainMenuImages.length * 2) + mainmenuNumImages.length + 0;
			selectedElement = mainselectedNumImages[0];
		}
		// CTRL + 6 para mainselected1
		else if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.SIX && mainselectedNumImages.length > 1)
		{
			selectedIndex = (mainMenuImages.length * 2) + mainmenuNumImages.length + 1;
			selectedElement = mainselectedNumImages[1];
		}
		// CTRL + 7 para mainselected2
		else if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.SEVEN && mainselectedNumImages.length > 2)
		{
			selectedIndex = (mainMenuImages.length * 2) + mainmenuNumImages.length + 2;
			selectedElement = mainselectedNumImages[2];
		}
		// CTRL + 8 para mainselected3
		else if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.EIGHT && mainselectedNumImages.length > 3)
		{
			selectedIndex = (mainMenuImages.length * 2) + mainmenuNumImages.length + 3;
			selectedElement = mainselectedNumImages[3];
		}
		// V para seleccionar el video ember
		#if VIDEOS_ALLOWED
		else if (FlxG.keys.justPressed.V && emberVideo != null)
		{
			selectedIndex = -99; // Índice especial para el video
			selectedElement = emberVideo;
		}
		#end
		// U para seleccionar el menuBG
		else if (FlxG.keys.justPressed.U && bg != null)
		{
			selectedIndex = -98; // Índice especial para el background
			selectedElement = bg;
		}

		// Controles de zoom de cámara (N = Zoom Out, M = Zoom In)
		if (FlxG.keys.pressed.N)
		{
			FlxG.camera.zoom -= 0.01;
			FlxG.camera.zoom = Math.max(0.1, FlxG.camera.zoom); // Mínimo 0.1
		}
		if (FlxG.keys.pressed.M)
		{
			FlxG.camera.zoom += 0.01;
			FlxG.camera.zoom = Math.min(3.0, FlxG.camera.zoom); // Máximo 3.0
		}

		// Controles de opacidad (J = Bajar, K = Subir)
		// Funciona para video y menuBG
		#if VIDEOS_ALLOWED
		if (emberVideo != null && selectedIndex == -99)
		{
			if (FlxG.keys.pressed.J)
			{
				emberVideo.alpha -= 0.01;
				emberVideo.alpha = Math.max(0.0, emberVideo.alpha); // Mínimo 0.0
			}
			if (FlxG.keys.pressed.K)
			{
				emberVideo.alpha += 0.01;
				emberVideo.alpha = Math.min(1.0, emberVideo.alpha); // Máximo 1.0
			}
		}
		#end
		
		// Controles de opacidad para el menuBG
		if (bg != null && selectedIndex == -98)
		{
			if (FlxG.keys.pressed.J)
			{
				bg.alpha -= 0.01;
				bg.alpha = Math.max(0.0, bg.alpha); // Mínimo 0.0
			}
			if (FlxG.keys.pressed.K)
			{
				bg.alpha += 0.01;
				bg.alpha = Math.min(1.0, bg.alpha); // Máximo 1.0
			}
		}

		// Controles de teclado para el elemento seleccionado
		if (selectedElement != null)
		{
			var moveSpeed:Float = FlxG.keys.pressed.SHIFT ? 10 : 1;

			// Mover con flechas
			if (FlxG.keys.pressed.UP) selectedElement.y -= moveSpeed;
			if (FlxG.keys.pressed.DOWN) selectedElement.y += moveSpeed;
			if (FlxG.keys.pressed.LEFT) selectedElement.x -= moveSpeed;
			if (FlxG.keys.pressed.RIGHT) selectedElement.x += moveSpeed;

			// Escalar
			if (FlxG.keys.pressed.Q)
			{
				selectedElement.scale.x -= 0.01;
				selectedElement.scale.y -= 0.01;
				selectedElement.updateHitbox();
			}
			if (FlxG.keys.pressed.E)
			{
				selectedElement.scale.x += 0.01;
				selectedElement.scale.y += 0.01;
				selectedElement.updateHitbox();
			}

			// Resetear posición con R
			if (FlxG.keys.justPressed.R)
			{
				selectedElement.screenCenter();
			}
			
			// Guardar coordenadas con P
			if (FlxG.keys.justPressed.P)
			{
				saveCoordinates();
				// Mostrar mensaje de confirmación
				saveMessageText.visible = true;
				saveMessageTimer = 2.0; // Mostrar por 2 segundos
				FlxG.sound.play(Paths.sound('confirmMenu'));
			}
			
			// Resaltar elemento seleccionado con alpha parpadeante (excepto video y menuBG)
			if (selectedIndex != -99 && selectedIndex != -98)
			{
				// Para sprites normales
				selectedElement.alpha = 0.5 + Math.sin(Date.now().getTime() / 200) * 0.5;
			}
		}
		
		// Restaurar alpha de elementos no seleccionados
		for (i in 0...mainMenuImages.length)
		{
			if (i != selectedIndex && mainMenuImages[i].visible)
			{
				mainMenuImages[i].alpha = 1.0;
			}
		}
		for (i in 0...selectedImages.length)
		{
			var idx = mainMenuImages.length + i;
			if (idx != selectedIndex && selectedImages[i].visible)
			{
				selectedImages[i].alpha = 1.0;
			}
		}
		for (i in 0...mainmenuNumImages.length)
		{
			var idx = (mainMenuImages.length * 2) + i;
			if (idx != selectedIndex)
			{
				mainmenuNumImages[i].alpha = 1.0;
			}
		}
		for (i in 0...mainselectedNumImages.length)
		{
			var idx = (mainMenuImages.length * 2) + mainmenuNumImages.length + i;
			if (idx != selectedIndex)
			{
				mainselectedNumImages[i].alpha = 1.0;
			}
		}
		}
		catch (e:Dynamic)
		{
			trace('[MainMenuState_oldmenu] Error en updateDevMode: $e');
		}
	}

	function changeItem(change:Int = 0)
	{
		try
		{
		trace('[OLDMENU] changeItem called with change=$change, curSelected=$curSelected');
		if(change != 0) curColumn = CENTER;
		curSelected = FlxMath.wrap(curSelected + change, 0, optionShit.length - 1);
		trace('[OLDMENU] curSelected ahora es: $curSelected');
		FlxG.sound.play(Paths.sound('scrollMenu'));

		// Mostrar todas las imágenes "no seleccionadas" y ocultar "seleccionadas"
		for (i in 0...mainMenuImages.length)
		{
			mainMenuImages[i].visible = true;  // notselect visible
			selectedImages[i].visible = false; // selected oculto
		}
		
		// Mostrar la imagen "seleccionada" del ítem actual
		if (curSelected < selectedImages.length)
		{
			selectedImages[curSelected].visible = true;   // selected visible
			mainMenuImages[curSelected].visible = false;  // notselect oculto
			
			// También mostrar mainselected correspondiente
			if (curSelected < mainselectedNumImages.length)
			{
				mainselectedNumImages[curSelected].visible = true;
			}
		}
		
		// Ocultar todos los mainselected excepto el actual
		for (i in 0...mainselectedNumImages.length)
		{
			if (i != curSelected)
				mainselectedNumImages[i].visible = false;
		}
		}
		catch (e:Dynamic)
		{
			trace('[MainMenuState_oldmenu] Error en changeItem: $e');
		}
	}
	
	function saveCoordinates()
	{
		var output:String = "=== COORDENADAS MAINMENU ===\n";
		for (i in 0...mainMenuImages.length)
		{
			output += 'mainmenu ${i + 1}: X=${Std.int(mainMenuImages[i].x)}, Y=${Std.int(mainMenuImages[i].y)}\n';
		}
		
		output += "\n=== COORDENADAS SELECTED ===\n";
		for (i in 0...selectedImages.length)
		{
			output += 'selected ${i + 1}: X=${Std.int(selectedImages[i].x)}, Y=${Std.int(selectedImages[i].y)}\n';
		}
		
		output += "\n=== COORDENADAS MAINMENU0-3 ===\n";
		for (i in 0...mainmenuNumImages.length)
		{
			output += 'mainmenu${i}: X=${Std.int(mainmenuNumImages[i].x)}, Y=${Std.int(mainmenuNumImages[i].y)}\n';
		}
		
		output += "\n=== COORDENADAS MAINSELECTED0-3 ===\n";
		for (i in 0...mainselectedNumImages.length)
		{
			output += 'mainselected${i}: X=${Std.int(mainselectedNumImages[i].x)}, Y=${Std.int(mainselectedNumImages[i].y)}\n';
		}
		
		#if VIDEOS_ALLOWED
		if (emberVideo != null)
		{
			output += "\n=== COORDENADAS VIDEO EMBER ===\n";
			output += 'emberVideo: X=${Std.int(emberVideo.x)}, Y=${Std.int(emberVideo.y)}, Alpha=${Math.round(emberVideo.alpha * 100)}%\n';
		}
		#end
		
		if (bg != null)
		{
			output += "\n=== COORDENADAS MENUBG ===\n";
			output += 'menuBG: X=${Std.int(bg.x)}, Y=${Std.int(bg.y)}, Alpha=${Math.round(bg.alpha * 100)}%\n';
		}
		
		trace(output);
		trace("Coordenadas guardadas en la consola!");
		
		#if sys
		sys.io.File.saveContent("mainmenu_coordinates.txt", output);
		trace("Coordenadas guardadas en mainmenu_coordinates.txt");
		#end
	}
}
