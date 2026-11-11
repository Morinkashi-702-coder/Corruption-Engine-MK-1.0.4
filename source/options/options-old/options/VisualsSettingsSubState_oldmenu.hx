package options;

import objects.Note;
import objects.StrumNote;
import objects.NoteSplash;
import objects.Alphabet;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxGlitchEffect;

class VisualsSettingsSubState_oldmenu extends MusicBeatSubstate
{
	private var grpOptions:FlxTypedGroup<FlxText>;
	private var grpValues:FlxTypedGroup<FlxText>;
	private var curSelected:Int = 0;
	private var lerpSelected:Float = 0;
	private var optionsList:Array<String> = [];
	private var optionsDescriptions:Map<String, String> = [];
	private var descText:FlxText;
	private var descBg:FlxSprite;
	private var titleText:FlxText;
	private var selectedBox:FlxSprite;
	private var maxVisibleOptions:Int = 4;
	private var drawDistance:Int = 4;
	private var lastVisibles:Array<Int> = [];
	private var waitingForInputRelease:Bool = true;
	private var splashPreviewTimer:Float = 0;
	private var noteSkins:Array<String> = [];
	private var noteSplashSkins:Array<String> = [];
	private var timeBarTypes:Array<String> = ['Time Left', 'Time Elapsed', 'Song Name', 'Disabled'];
	private var pauseMusics:Array<String> = ['None', 'Tea Time', 'Breakfast', 'Breakfast (Pico)'];

	var noteOptionID:Int = -1;
	var notes:FlxTypedGroup<StrumNote>;
	var splashes:FlxTypedGroup<NoteSplash>;
	var noteY:Float = FlxG.height - 290;
	var noteHideY:Float = FlxG.height + 200;

	public function new()
	{
		super();

		// Fondo CRT/Monitor corrupto
		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menus/optionsMenu/optionsBack'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.screenCenter();
		add(bg);

		// Efecto de scanlines
		var scanlines:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
		scanlines.alpha = 0.1;
		add(scanlines);

		// Efecto de glitch con shader (detrás de los textos)
		var optionsGlitchSprite:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menus/optionsMenu/optionsGlitch'));
		optionsGlitchSprite.antialiasing = ClientPrefs.data.antialiasing;
		
		var glitchEffect:FlxGlitchEffect = new FlxGlitchEffect();
		glitchEffect.size = 5;
		glitchEffect.delay = 0.1;
		glitchEffect.strength = 5;
		
		var optionsGlitch:FlxEffectSprite = new FlxEffectSprite(optionsGlitchSprite, [glitchEffect]);
		optionsGlitch.x = 0;
		optionsGlitch.y = 0;
		add(optionsGlitch);

		// for note skins and splash skins
		notes = new FlxTypedGroup<StrumNote>();
		splashes = new FlxTypedGroup<NoteSplash>();
		for (i in 0...Note.colArray.length)
		{
			var note:StrumNote = new StrumNote(370 + (560 / Note.colArray.length) * i, FlxG.height + 200, i, 0);
			changeNoteSkin(note);
			notes.add(note);
			
			var splash:NoteSplash = new NoteSplash(0, 0, NoteSplash.defaultNoteSplash);
			splash.inEditor = true;
			splash.babyArrow = note;
			splash.ID = i;
			splash.kill();
			splashes.add(splash);
		}
		add(notes);
		add(splashes);

		// Las dos interfaces comparten exactamente las mismas preferencias.
		noteSkins = Mods.mergeAllTextsNamed('images/noteSkins/list.txt');
		noteSkins.remove(ClientPrefs.defaultData.noteSkin);
		noteSkins.insert(0, ClientPrefs.defaultData.noteSkin);

		noteSplashSkins = Mods.mergeAllTextsNamed('images/noteSplashes/list.txt');
		noteSplashSkins.remove('None');
		noteSplashSkins.insert(0, 'None');

		if (!noteSkins.contains(ClientPrefs.data.noteSkin)) ClientPrefs.data.noteSkin = ClientPrefs.defaultData.noteSkin;
		if (!noteSplashSkins.contains(ClientPrefs.data.splashSkin)) ClientPrefs.data.splashSkin = 'None';

		// Configurar opciones
		optionsList = [
			'Note Skins',
			'Note Splashes',
			'Note Splash Opacity',
			'Time Bar',
			'Health Bar Opacity',
			'FPS Counter',
			'Memory Counter',
			'Pause Music'
		];
		#if CHECK_FOR_UPDATES optionsList.push('Check for Updates'); #end
		#if DISCORD_ALLOWED optionsList.push('Discord Rich Presence'); #end
		optionsList.push('Combo Stacking');

		optionsDescriptions = [
			'Note Skins' => 'Select your prefered Note skin.',
			'Note Splashes' => 'Select your prefered Note Splash variation.',
			'Note Splash Opacity' => 'How much transparent should the Note Splashes be.',
			'Time Bar' => 'What should the Time Bar display?',
			'Health Bar Opacity' => 'How much transparent should the health bar and icons be.',
			'FPS Counter' => 'Show or hide the FPS counter.',
			'Memory Counter' => 'Show or hide the current memory usage.',
			'Pause Music' => 'Choose the song played on the Pause Screen.',
			'Check for Updates' => 'Check for updates when the game starts.',
			'Discord Rich Presence' => 'Show the game in your Discord activity.',
			'Combo Stacking' => 'Allow ratings and combo numbers to stack.'
		];

		// Título con efecto
		titleText = new FlxText(0, 10, FlxG.width, 'VISUALS SETTINGS', 48);
		titleText.setFormat(Paths.font('pixel.otf'), 48, 0xFF00ff00, CENTER);
		add(titleText);

		// Línea separadora del título - superior
		var titleLineTop:FlxSprite = new FlxSprite(80, 68).makeGraphic(FlxG.width - 160, 4, 0xFF00ff00);
		add(titleLineTop);

		// Línea separadora del título - inferior
		var titleLineBottom:FlxSprite = new FlxSprite(80, 75).makeGraphic(FlxG.width - 160, 2, 0xFF007700);
		add(titleLineBottom);

		// Caja de selección de fondo
		selectedBox = new FlxSprite(60, 100).makeGraphic(FlxG.width - 120, 100, 0xFF001100);
		selectedBox.alpha = 0.7;
		add(selectedBox);

		grpOptions = new FlxTypedGroup<FlxText>();
		add(grpOptions);

		grpValues = new FlxTypedGroup<FlxText>();
		add(grpValues);

		for (num => option in optionsList)
		{
			var optionText:FlxText = new FlxText(FlxG.width + 100 - 50, 110 + (85 * num), FlxG.width, option, 36);
			optionText.setFormat(Paths.font('pixel.otf'), 36, 0xFF00ff00, CENTER);
			optionText.color = 0xFF00ff00;
			optionText.alpha = 0.6;
			optionText.ID = num;
			grpOptions.add(optionText);
			
			// Animar entrada desde la derecha
			FlxTween.tween(optionText, {x: 0 - 50}, 0.5 + (num * 0.05), {ease: FlxEase.quadOut});

			// Crear texto de valor
			var valueText:FlxText = new FlxText(FlxG.width + 100 - 50, 110 + (85 * num), FlxG.width - 200, '', 32);
			valueText.setFormat(Paths.font('pixel.otf'), 32, 0xFF00ff00, RIGHT);
			valueText.color = 0xFF00ff00;
			valueText.alpha = 0.6;
			grpValues.add(valueText);

			// Animar entrada desde la derecha
			FlxTween.tween(valueText, {x: 0 - 50}, 0.5 + (num * 0.05), {ease: FlxEase.quadOut});
		}

		descBg = new FlxSprite(50, FlxG.height - 145).makeGraphic(FlxG.width - 100, 125, 0xFF0a0a15);
		descBg.alpha = 0.95;
		add(descBg);

		// Borde superior de descripción - grueso
		var borderTopThick:FlxSprite = new FlxSprite(50, FlxG.height - 150).makeGraphic(FlxG.width - 100, 5, 0xFF00ff00);
		add(borderTopThick);
		
		// Borde inferior de descripción
		var borderBottomThick:FlxSprite = new FlxSprite(50, FlxG.height - 20).makeGraphic(FlxG.width - 100, 5, 0xFF007700);
		add(borderBottomThick);

		// Esquinas decorativas
		var cornerTL:FlxSprite = new FlxSprite(50, FlxG.height - 150).makeGraphic(15, 15, 0xFF00ff00);
		add(cornerTL);
		var cornerTR:FlxSprite = new FlxSprite(FlxG.width - 65, FlxG.height - 150).makeGraphic(15, 15, 0xFF00ff00);
		add(cornerTR);

		// Descripción con mejor fuente
		descText = new FlxText(70, FlxG.height - 135, FlxG.width - 140, optionsDescriptions[optionsList[0]], 18);
		descText.setFormat(Paths.font('pixel.otf'), 18, 0xFF00ff00, CENTER);
		add(descText);

		// Frente del monitor (marco/bezel)
		var front:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menus/optionsMenu/optionsFront'));
		front.antialiasing = ClientPrefs.data.antialiasing;
		front.screenCenter();
		add(front);

		changeSelection();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence('Visuals Settings', null);
		#end
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (waitingForInputRelease)
		{
			if (!controls.ACCEPT && !controls.UI_UP && !controls.UI_DOWN && !controls.UI_LEFT && !controls.UI_RIGHT)
				waitingForInputRelease = false;
			updateTexts(elapsed);
			return;
		}

		var selectedName:String = optionsList[curSelected];
		if ((selectedName == 'Note Splashes' || selectedName == 'Note Splash Opacity') && ClientPrefs.data.splashSkin != 'None')
		{
			splashPreviewTimer -= elapsed;
			if (splashPreviewTimer <= 0)
			{
				playNoteSplashes();
				splashPreviewTimer = 0.75;
			}
		}

		if (controls.UI_UP_P)
			changeSelection(-1);
		if (controls.UI_DOWN_P)
			changeSelection(1);

		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			close();
		}

		// Cambiar valores con LEFT/RIGHT o ACCEPT
		if (controls.UI_LEFT_P)
			changeOption(-1);
		if (controls.UI_RIGHT_P)
			changeOption(1);
		if (controls.ACCEPT)
			changeOption(1);

		// Efecto de "breathing" en el título
		titleText.alpha = 0.85 + Math.sin(FlxG.game.ticks * 0.005) * 0.15;
		
		// Efecto pulse en caja seleccionada
		selectedBox.alpha = 0.6 + Math.sin(FlxG.game.ticks * 0.003) * 0.1;

		// Smooth scroll update
		updateTexts(elapsed);
	}

	function changeSelection(change:Int = 0)
	{
		curSelected = FlxMath.wrap(curSelected + change, 0, optionsList.length - 1);
		FlxG.sound.play(Paths.sound('scrollMenu'));

		// Actualizar descripción
		descText.text = optionsDescriptions[optionsList[curSelected]];
		
		// Handle note animations
		updateNoteVisuals();
	}

	private function updateTexts(elapsed:Float = 0.0)
	{
		// Smooth lerp toward selected item
		lerpSelected = FlxMath.lerp(curSelected, lerpSelected, Math.exp(-elapsed * 9.6));

		// Hide previously visible items
		for (i in lastVisibles)
		{
			grpOptions.members[i].visible = false;
			grpValues.members[i].visible = false;
		}
		lastVisibles = [];

		// Show items in draw distance
		var min:Int = Math.round(Math.max(0, Math.min(optionsList.length, lerpSelected - drawDistance)));
		var max:Int = Math.round(Math.max(0, Math.min(optionsList.length, lerpSelected + drawDistance)));

		for (i in min...max)
		{
			var item:FlxText = grpOptions.members[i];
			var valueItem:FlxText = grpValues.members[i];
			item.visible = true;
			valueItem.visible = true;

			// Smooth Y positioning based on lerp value
			var displayY:Float = ((i - lerpSelected) * 85) + 110;
			item.y = displayY;
			valueItem.y = displayY;

			// Color and scale based on distance from selected
			if (i == curSelected)
			{
				item.color = 0xFF00ff00;
				item.alpha = 1;
				item.scale.set(1.1, 1.1);

				valueItem.color = 0xFF00ff00;
				valueItem.alpha = 1;
				valueItem.scale.set(1.1, 1.1);

				// Update selection box
				selectedBox.y = item.y - 5;
			}
			else
			{
				item.color = 0xFF007700;
				item.alpha = 0.4;
				item.scale.set(0.95, 0.95);

				valueItem.color = 0xFF007700;
				valueItem.alpha = 0.4;
				valueItem.scale.set(0.95, 0.95);
			}

			// Update value text
			valueItem.text = getOptionValue(optionsList[i]);

			lastVisibles.push(i);
		}
	}

	private function getOptionValue(optionName:String):String
	{
		return switch(optionName)
		{
			case 'Note Skins':
				ClientPrefs.data.noteSkin;
			case 'Note Splashes':
				ClientPrefs.data.splashSkin;
			case 'Note Splash Opacity':
				Std.string(Math.round(ClientPrefs.data.splashAlpha * 100));
			case 'Time Bar':
				ClientPrefs.data.timeBarType;
			case 'Health Bar Opacity':
				Std.string(Math.round(ClientPrefs.data.healthBarAlpha * 100));
			case 'FPS Counter':
				ClientPrefs.data.showFPS ? 'ON' : 'OFF';
			case 'Memory Counter':
				ClientPrefs.data.showMemory ? 'ON' : 'OFF';
			case 'Pause Music':
				ClientPrefs.data.pauseMusic;
			case 'Check for Updates':
				ClientPrefs.data.checkForUpdates ? 'ON' : 'OFF';
			case 'Discord Rich Presence':
				ClientPrefs.data.discordRPC ? 'ON' : 'OFF';
			case 'Combo Stacking':
				ClientPrefs.data.comboStacking ? 'ON' : 'OFF';
			default:
				'';
		};
	}

	function changeOption(change:Int = 0)
	{
		var optionName:String = optionsList[curSelected];

		switch(optionName)
		{
			case 'Note Skins':
				ClientPrefs.data.noteSkin = cycleString(noteSkins, ClientPrefs.data.noteSkin, change);
				FlxG.sound.play(Paths.sound('confirmMenu'));
				onChangeNoteSkin();
			case 'Note Splashes':
				ClientPrefs.data.splashSkin = cycleString(noteSplashSkins, ClientPrefs.data.splashSkin, change);
				FlxG.sound.play(Paths.sound('confirmMenu'));
				onChangeSplashSkin();
			case 'Note Splash Opacity':
				ClientPrefs.data.splashAlpha = FlxMath.bound(ClientPrefs.data.splashAlpha + (change * 0.1), 0, 1);
				FlxG.sound.play(Paths.sound('confirmMenu'));
				playNoteSplashes();
			case 'Time Bar':
				ClientPrefs.data.timeBarType = cycleString(timeBarTypes, ClientPrefs.data.timeBarType, change);
				FlxG.sound.play(Paths.sound('confirmMenu'));
			case 'Health Bar Opacity':
				ClientPrefs.data.healthBarAlpha = FlxMath.bound(ClientPrefs.data.healthBarAlpha + (change * 0.1), 0, 1);
				FlxG.sound.play(Paths.sound('confirmMenu'));
			case 'FPS Counter':
				ClientPrefs.data.showFPS = !ClientPrefs.data.showFPS;
				updatePerformanceCounter();
			case 'Memory Counter':
				ClientPrefs.data.showMemory = !ClientPrefs.data.showMemory;
				updatePerformanceCounter();
			case 'Pause Music':
				ClientPrefs.data.pauseMusic = cycleString(pauseMusics, ClientPrefs.data.pauseMusic, change);
				onChangePauseMusic();
			case 'Check for Updates':
				ClientPrefs.data.checkForUpdates = !ClientPrefs.data.checkForUpdates;
			case 'Discord Rich Presence':
				ClientPrefs.data.discordRPC = !ClientPrefs.data.discordRPC;
			case 'Combo Stacking':
				ClientPrefs.data.comboStacking = !ClientPrefs.data.comboStacking;
		}

		ClientPrefs.saveSettings();
	}

	function cycleString(values:Array<String>, current:String, change:Int):String
	{
		if (values == null || values.length < 1) return current;
		var index:Int = values.indexOf(current);
		if (index < 0) index = 0;
		return values[FlxMath.wrap(index + change, 0, values.length - 1)];
	}

	private function updateNoteVisuals()
	{
		var optionName:String = optionsList[curSelected];
		if (optionName == 'Note Skins' || optionName == 'Note Splashes' || optionName == 'Note Splash Opacity')
		{
			for (note in notes.members)
			{
				FlxTween.cancelTweensOf(note);
				FlxTween.tween(note, {y: noteY}, 0.3, {ease: FlxEase.quadInOut});
			}
			if (optionName == 'Note Splash Opacity')
				playNoteSplashes();
		}
		else
		{
			for (note in notes.members)
			{
				FlxTween.cancelTweensOf(note);
				FlxTween.tween(note, {y: noteHideY}, 0.3, {ease: FlxEase.quadInOut});
			}
		}
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
		if (ClientPrefs.data.noteSkin != ClientPrefs.defaultData.noteSkin)
		{
			var normalized:String = ClientPrefs.data.noteSkin.trim().toLowerCase().replace(' ', '_');
			var candidates:Array<String> = [Note.defaultNoteSkin + '-' + normalized, 'noteSkins/' + ClientPrefs.data.noteSkin, 'NOTE_assets-' + normalized];
			for (candidate in candidates)
				if (atlasExists(candidate))
				{
					skin = candidate;
					break;
				}
		}

		note.texture = skin;
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
			rand = FlxG.random.int(0, splashes.members[0].maxAnims - 1);

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

	function getSplashPreviewTexture():String
	{
		var selectedSkin:String = ClientPrefs.data.splashSkin.replace('\\', '/');
		if (selectedSkin.contains('/'))
		{
			var parts:Array<String> = selectedSkin.split('/');
			selectedSkin = parts[parts.length - 1];
		}

		var directPath:String = 'noteSplashes/$selectedSkin';
		if (atlasExists(directPath)) return directPath;

		var legacyPath:String = NoteSplash.defaultNoteSplash + '-' + selectedSkin.trim().toLowerCase().replace(' ', '-');
		if (atlasExists(legacyPath)) return legacyPath;
		return NoteSplash.defaultNoteSplash;
	}

	function atlasExists(key:String):Bool
	{
		if (Paths.fileExists('images/$key.png', IMAGE) && Paths.fileExists('images/$key.xml', TEXT)) return true;
		#if sys
		var pngPath:String = Paths.getPath('images/$key.png', IMAGE, null, false);
		var xmlPath:String = Paths.getPath('images/$key.xml', TEXT, null, false);
		return FileSystem.exists(pngPath) && FileSystem.exists(xmlPath);
		#else
		return false;
		#end
	}

	var changedMusic:Bool = false;
	function onChangePauseMusic()
	{
		if (ClientPrefs.data.pauseMusic == 'None')
			FlxG.sound.music.volume = 0;
		else
			FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath(ClientPrefs.data.pauseMusic)));
		changedMusic = true;
	}

	function updatePerformanceCounter()
	{
		#if !mobile
		if (Main.fpsVar != null) Main.fpsVar.visible = ClientPrefs.data.showFPS || ClientPrefs.data.showMemory;
		#end
	}

	override function destroy()
	{
		// Desactivado: no restaurar freakyMenu al salir de las opciones visuales.
		// if (changedMusic && !OptionsState.onPlayState) FlxG.sound.playMusic(Paths.music('freakyMenu'), 1, true);
		Note.globalRgbShaders = [];
		ClientPrefs.saveSettings();
		super.destroy();
	}
}
