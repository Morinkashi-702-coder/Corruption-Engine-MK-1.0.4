package options;

import objects.Note;
import objects.StrumNote;
import objects.NoteSplash;
import objects.Alphabet;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.math.FlxMath;

class VisualsSettingsSubState extends VisualsBaseMenu
{
	var noteOptionID:Int = -1;
	var notes:FlxTypedGroup<StrumNote>;
	var splashes:FlxTypedGroup<NoteSplash>;
	var noteY:Float = 500; // Posición Y cuando las notas están visibles
	var noteHideY:Float = 1403; // Posición Y inicial (abajo)
	var noteStartX:Float = -270; // X inicial donde empiezan las notas
	var noteFinalX:Float = -297; // X final donde terminan las notas
	var noteSpacing:Float = 177; // Espaciado entre notas
	var noteScale:Float = 1.05; // Escala de las notas
	// Dev menu
	var devMode:Bool = false;
	var noteDevText:FlxText;
	public function new(?oldMenuStyle:Null<Bool>)
	{
		var wantsCRT:Bool = oldMenuStyle != null
			? oldMenuStyle
			: backend.MenuSelector.getMenu() == 'oldmenu';
		title = Language.getPhrase('visuals_menu', 'Visuals Settings');
		rpcTitle = 'Visuals Settings Menu'; //for Discord Rich Presence

		super(wantsCRT); // Llamar super() PRIMERO para inicializar VisualsBaseMenu
		if (useOldMenuStyle)
		{
			noteStartX = 370;
			noteFinalX = 370;
			noteY = FlxG.height - 290;
			noteHideY = FlxG.height + 200;
			descriptionX = 70;
			descriptionY = FlxG.height - 135;
			descriptionBoxXOffset = -20;
			descriptionBoxYOffset = -10;
		}
		else
		{
			descriptionX = -450;
			descriptionY = 650;
			descriptionBoxXOffset = -80;
			descriptionBoxYOffset = 10;
		}

		// Migración única para instalaciones que conservaron los valores de las
		// pruebas anteriores. Después de esto, las elecciones se guardan normalmente.
		if (!ClientPrefs.data.visualsDefaultsInitialized)
		{
			ClientPrefs.data.noteSkin = ClientPrefs.defaultData.noteSkin;
			ClientPrefs.data.splashSkin = ClientPrefs.defaultData.splashSkin;
			ClientPrefs.data.visualsDefaultsInitialized = true;
			ClientPrefs.saveSettings();
		}

		// for note skins and splash skins
		notes = new FlxTypedGroup<StrumNote>();
		splashes = new FlxTypedGroup<NoteSplash>();
		for (i in 0...Note.colArray.length)
		{
			// Posicionar notas en posición inicial (abajo)
			var note:StrumNote = new StrumNote(noteStartX + (noteSpacing * i), noteHideY, i, 0);
			note.scale.set(noteScale, noteScale); // Aplicar escala personalizada
			changeNoteSkin(note);
			notes.add(note);
			
			var splash:NoteSplash = new NoteSplash(0, 0, NoteSplash.defaultNoteSplash);
			splash.inEditor = true;
			splash.babyArrow = note;
			splash.ID = i;
			splash.scale.set(noteScale, noteScale); // Aplicar escala a splash
			splash.kill();
			splashes.add(splash);
		}

		// options
		var noteSkins:Array<String> = Mods.mergeAllTextsNamed('images/noteSkins/list.txt');
		if(noteSkins.length > 0)
		{
			if(!noteSkins.contains(ClientPrefs.data.noteSkin))
				ClientPrefs.data.noteSkin = ClientPrefs.defaultData.noteSkin; //Reset to default if saved noteskin couldnt be found

			noteSkins.insert(0, ClientPrefs.defaultData.noteSkin); //Default skin always comes first
			var option:Option = new Option('Note Skins',
				"Select your prefered Note skin.",
				'noteSkin',
				STRING,
				noteSkins);
			addOption(option);
			option.onChange = onChangeNoteSkin;
			noteOptionID = optionsArray.length - 1;
		}
		
		var noteSplashes:Array<String> = Mods.mergeAllTextsNamed('images/noteSplashes/list.txt');
		if(noteSplashes.length > 0)
		{
			noteSplashes.remove('None');
			if(!noteSplashes.contains(ClientPrefs.data.splashSkin) && ClientPrefs.data.splashSkin != 'None')
				ClientPrefs.data.splashSkin = ClientPrefs.defaultData.splashSkin;

			noteSplashes.insert(0, 'None');
			var option:Option = new Option('Note Splashes',
				"Select your prefered Note Splash variation.",
				'splashSkin',
				STRING,
				noteSplashes);
			addOption(option);
			option.onChange = onChangeSplashSkin;
		}

		var option:Option = new Option('Note Splash Opacity',
			'How much transparent should the Note Splashes be.',
			'splashAlpha',
			PERCENT);
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		option.displayFormat = '%v';
		addOption(option);
		option.onChange = playNoteSplashes;

		var option:Option = new Option('Time Bar',
			"What should the Time Bar display?",
			'timeBarType',
			STRING,
			['Time Left', 'Time Elapsed', 'Song Name', 'Disabled']);
		addOption(option);

		var option:Option = new Option('Health Bar Opacity',
			'How much transparent should the health bar and icons be.',
			'healthBarAlpha',
			PERCENT);
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		option.displayFormat = '%v';
		addOption(option);
		
		#if !mobile
		var option:Option = new Option('FPS Counter',
			'If unchecked, hides FPS Counter.',
			'showFPS',
			BOOL);
		addOption(option);
		option.onChange = onChangePerformanceCounter;

		var option:Option = new Option('Memory Counter',
			'If unchecked, hides the memory usage text below the FPS counter.',
			'showMemory',
			BOOL);
		addOption(option);
		option.onChange = onChangePerformanceCounter;
		#end
		
		var option:Option = new Option('Pause Music',
			"What song do you prefer for the Pause Screen?",
			'pauseMusic',
			STRING,
			['None', 'Tea Time', 'Breakfast', 'Breakfast (Pico)']);
		addOption(option);
		option.onChange = onChangePauseMusic;
		
		#if CHECK_FOR_UPDATES
		var option:Option = new Option('Check for Updates',
			'On Release builds, turn this on to check for updates when you start the game.',
			'checkForUpdates',
			BOOL);
		addOption(option);
		#end

		#if DISCORD_ALLOWED
		var option:Option = new Option('Discord Rich Presence',
			"Uncheck this to prevent accidental leaks, it will hide the Application from your \"Playing\" box on Discord",
			'discordRPC',
			BOOL);
		addOption(option);
		#end

		var option:Option = new Option('Combo Stacking',
			"If unchecked, Ratings and Combo won't stack, saving on System Memory and making them easier to read",
			'comboStacking',
			BOOL);
		addOption(option);

		// Inicializar selección
		changeSelection(0);
		
		// Actualizar display de todas las opciones
		updateAllOptions();
		
		add(notes);
		add(splashes);

		if (useOldMenuStyle)
		{
			var front:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menus/optionsMenu/optionsFront'));
			front.antialiasing = ClientPrefs.data.antialiasing;
			front.screenCenter();
			add(front);
		}

		// Animar notas desde posición inicial hasta posición final
		for (i in 0...notes.length) {
			var note = notes.members[i];
			FlxTween.tween(note, {
				y: noteY,
				x: noteFinalX + (noteSpacing * i)
			}, 0.6, {
				ease: FlxEase.backOut,
				startDelay: 0.15
			});
		}

		// Dev overlay (invisible by default)
		noteDevText = new FlxText(8, 8, 420, "");
		noteDevText.setFormat(null, 14, 0xFFFFFFFF, "left");
		noteDevText.scrollFactor.set(0, 0);
		noteDevText.visible = false;
		add(noteDevText);
	}

	// Update loop to handle dev-mode controls
	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (notesShown && curOption != null && curOption.variable.startsWith('splash') && ClientPrefs.data.splashSkin != 'None')
		{
			splashPreviewTimer -= elapsed;
			if (splashPreviewTimer <= 0)
			{
				playNoteSplashes();
				splashPreviewTimer = 0.75;
			}
		}

		// Toggle dev mode with F3
		if (FlxG.keys.justPressed.F3)
		{
			devMode = !devMode;
			noteDevText.visible = devMode;
			if (!devMode) noteDevText.text = "";
			else updateDevText();
		}

		if (devMode)
		{
			var step = FlxG.keys.pressed.SHIFT ? 5 : 1;

			// Movement: IJKL (up/down/left/right)
			if (FlxG.keys.pressed.I) noteY -= step;
			if (FlxG.keys.pressed.K) noteY += step;
			if (FlxG.keys.pressed.J) noteStartX -= step;
			if (FlxG.keys.pressed.L) noteStartX += step;

			// Spacing: Q/E (smaller changes)
			if (FlxG.keys.pressed.Q) noteSpacing -= 0.5;
			if (FlxG.keys.pressed.E) noteSpacing += 0.5;

			// Scale: Z/X
			if (FlxG.keys.pressed.Z) noteScale = Math.max(0.1, noteScale - 0.01);
			if (FlxG.keys.pressed.X) noteScale = noteScale + 0.01;

			// Apply changes to notes
			for (i in 0...notes.members.length)
			{
				var n = notes.members[i];
				if (n == null) continue;
				n.x = noteFinalX + (noteSpacing * i);  // Usar posición final cuando están visibles
				n.y = noteY;
				n.scale.set(noteScale, noteScale);
			}

			updateDevText();
		}
	}

	override function updateDevText()
	{
		if (noteDevText == null) return;
		noteDevText.text = 'DEV MODE\nXstart: ${Std.int(noteStartX)} | Y: ${Std.int(noteY)}\nSpacing: ${FlxMath.roundDecimal(noteSpacing, 2)} | Scale: ${FlxMath.roundDecimal(noteScale, 2)}\n(IJKL: move  Q/E: spacing  Z/X: scale  SHIFT: fast)';
	}

	var notesShown:Bool = false;
	var splashPreviewTimer:Float = 0;
	override function changeSelection(change:Int = 0)
	{
		super.changeSelection(change);
		
		switch(curOption.variable)
		{
			case 'noteSkin', 'splashSkin', 'splashAlpha':
				if(!notesShown)
				{
					for (i in 0...notes.members.length)
					{
						var note = notes.members[i];
						FlxTween.cancelTweensOf(note);
						FlxTween.tween(note, {
							y: noteY,
							x: noteFinalX + (noteSpacing * i)
						}, Math.abs(note.y / (200 + noteY)) / 3, {ease: FlxEase.quadInOut});
					}
				}
				notesShown = true;
				if(curOption.variable.startsWith('splash') && Math.abs(notes.members[0].y - noteY) < 25) playNoteSplashes();

			default:
				if(notesShown) 
				{
					for (i in 0...notes.members.length)
					{
						var note = notes.members[i];
						FlxTween.cancelTweensOf(note);
						FlxTween.tween(note, {
							y: noteHideY,
							x: noteStartX + (noteSpacing * i)
						}, Math.abs(note.y / (200 + noteY)) / 3, {ease: FlxEase.quadInOut});
					}
				}
				notesShown = false;
		}
	}

	var changedMusic:Bool = false;
	function onChangePauseMusic()
	{
		if(ClientPrefs.data.pauseMusic == 'None')
			FlxG.sound.music.volume = 0;
		else
			FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath(ClientPrefs.data.pauseMusic)));

		changedMusic = true;
	}

	function onChangeNoteSkin()
	{
		for (note in notes.members)
		{
			if (note == null) continue;
			changeNoteSkin(note);
			note.centerOffsets();
			note.centerOrigin();
			note.playAnim('confirm', true);
			note.resetAnim = 0.35;
		}
	}

	function changeNoteSkin(note:StrumNote)
	{
		var skin:String = Note.defaultNoteSkin;
		var selectedSkin:String = ClientPrefs.data.noteSkin;
		if (selectedSkin != ClientPrefs.defaultData.noteSkin)
		{
			var normalized:String = selectedSkin.trim().toLowerCase().replace(' ', '_');
			var candidates:Array<String> = [
				Note.defaultNoteSkin + '-' + normalized,
				'noteSkins/$selectedSkin',
				'NOTE_assets-' + normalized
			];

			for (candidate in candidates)
			{
				if (atlasExists(candidate))
				{
					skin = candidate;
					break;
				}
			}
		}

		note.texture = skin; //Load texture and anims
		note.reloadNote();
		note.playAnim('static');
	}

	function onChangeSplashSkin()
	{
		if (ClientPrefs.data.splashSkin == 'None')
		{
			for (splash in splashes) splash.kill();
			return;
		}

		var skin:String = getSplashPreviewTexture();
		for (splash in splashes)
			splash.loadSplash(skin);

		playNoteSplashes();
	}

	function playNoteSplashes()
	{
		if (ClientPrefs.data.splashSkin == 'None') return;

		var rand:Int = 0;
		if (splashes.members[0] != null && splashes.members[0].maxAnims > 1)
			rand = FlxG.random.int(0, splashes.members[0].maxAnims - 1); // For playing the same random animation on all 4 splashes

		for (splash in splashes)
		{
			splash.revive();
			splash.alpha = ClientPrefs.data.splashAlpha;

			splash.spawnSplashNote(0, 0, splash.ID, null, false);
			if (splash.maxAnims > 1)
				splash.noteData = splash.noteData % Note.colArray.length + (rand * Note.colArray.length);

			var anim:String = splash.playDefaultAnim();
			var conf = splash.config.animations.get(anim);
			var offsets:Array<Float> = [0, 0];

			var minFps:Int = 22;
			var maxFps:Int = 26;
			if (conf != null)
			{
				offsets = conf.offsets;

				minFps = conf.fps[0];
				if (minFps < 0) minFps = 0;

				maxFps = conf.fps[1];
				if (maxFps < 0) maxFps = 0;
			}

			splash.offset.set(10, 10);
			if (offsets != null)
			{
				splash.offset.x += offsets[0];
				splash.offset.y += offsets[1];
			}

			if (splash.animation.curAnim != null)
				splash.animation.curAnim.frameRate = FlxG.random.int(minFps, maxFps);
		}
	}

	override function destroy()
	{
		// Desactivado: no restaurar freakyMenu al salir de las opciones visuales.
		// if(changedMusic && !OptionsState.onPlayState) FlxG.sound.playMusic(Paths.music('freakyMenu'), 1, true);
		Note.globalRgbShaders = [];
		super.destroy();
	}

	#if !mobile
	function onChangePerformanceCounter()
	{
		if(Main.fpsVar != null)
			Main.fpsVar.visible = ClientPrefs.data.showFPS || ClientPrefs.data.showMemory;
	}

	function getSplashPreviewTexture():String
	{
		var selectedSkin:String = ClientPrefs.data.splashSkin;
		// Las listas guardan solo el nombre (por ejemplo, "Diamond"). Si un
		// guardado viejo contiene una ruta, nos quedamos únicamente con su nombre.
		selectedSkin = selectedSkin.replace('\\', '/');
		if (selectedSkin.contains('/'))
		{
			var pathParts:Array<String> = selectedSkin.split('/');
			selectedSkin = pathParts[pathParts.length - 1];
		}
		if (selectedSkin.length < 1 || selectedSkin == 'None')
			return NoteSplash.defaultNoteSplash;

		var directPath:String = 'noteSplashes/$selectedSkin';
		if (atlasExists(directPath))
			return directPath;

		var legacyPath:String = NoteSplash.defaultNoteSplash + '-' + selectedSkin.trim().toLowerCase().replace(' ', '-');
		if (atlasExists(legacyPath))
			return legacyPath;

		return NoteSplash.defaultNoteSplash;
	}

	function atlasExists(key:String):Bool
	{
		if (Paths.fileExists('images/$key.png', IMAGE) && Paths.fileExists('images/$key.xml', TEXT))
			return true;

		#if sys
		var pngPath:String = Paths.getPath('images/$key.png', IMAGE, null, false);
		var xmlPath:String = Paths.getPath('images/$key.xml', TEXT, null, false);
		return FileSystem.exists(pngPath) && FileSystem.exists(xmlPath);
		#else
		return false;
		#end
	}
	#end
}
