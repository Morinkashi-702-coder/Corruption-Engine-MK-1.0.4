package states.editors;

import backend.WeekData;

import objects.Character;

import states.MainMenuState;
import states.MainMenuState_oldmenu;
import states.SoftCodeMenuState;
import states.FreeplayState;

class MasterEditorMenu extends MusicBeatState
{
	var options:Array<String> = [
		'Chart Editor',
		'Character Editor',
		'Stage Editor',
		'Week Editor'
	];
	private var grpTexts:FlxTypedGroup<Alphabet>;
	private var directories:Array<String> = [null];
	private var overlay:FlxSprite;

	private var curSelected = 0;
	private var curDirectory = 0;
	private var directoryTxt:FlxText;

	override function create()
	{
		FlxG.camera.bgColor = FlxColor.BLACK;
		if (FlxG.sound.music == null) FlxG.sound.playMusic(Paths.music('menu4'), 1); // evita null en volume = 0 al salir
		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Editors Main Menu", null);
		#end

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menus/freeplay/old/menuBlack'));
		bg.scrollFactor.set();
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.updateHitbox();
		add(bg);

		// BF character image on the left that slides in to the right
		var bfImg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menus/mainmenu/old/BF-CharacterEdi'));
		bfImg.antialiasing = ClientPrefs.data.antialiasing;
		bfImg.updateHitbox();
		bfImg.scrollFactor.set();
		// place off-screen to the left initially
		bfImg.x = -bfImg.width - 20;
		bfImg.y = FlxG.height * 0.5 - (bfImg.height * 0.5);
		add(bfImg);
		// animate sliding in
		FlxTween.tween(bfImg, { x: 0 }, 0.7, { ease: FlxEase.quadOut, startDelay: 0.1 });

		// Usar Overlay de freeplayC (assets/shared/images/freeplayC/Overlay.png)
		overlay = new FlxSprite().loadGraphic(Paths.image('menus/mainmenu/old/Overlay'));
		overlay.antialiasing = ClientPrefs.data.antialiasing;
		overlay.scrollFactor.set();
		overlay.x = 0;
		overlay.y = 0;
		add(overlay);

		grpTexts = new FlxTypedGroup<Alphabet>();
		add(grpTexts);

		// Dispón las opciones verticalmente y estáticas (no se mueven al cambiar selección)
		for (i in 0...options.length)
		{
			var rightX:Float = FlxG.width - 8;
			// Calcular posicion vertical para centrar el bloque de opciones
			var spacing:Float = 85;
			var startY:Float = FlxG.height * 0.5 - ((options.length - 1) * spacing) * 0.5;
			var leText:Alphabet = new Alphabet(rightX, startY, options[i], true);
			leText.isMenuItem = true;
			// Mantener estáticas (no animadas) en X/Y
			leText.changeX = false;
			leText.changeY = false;
			// Colocar manualmente posición vertical por índice
			leText.x = rightX;
			leText.y = startY + (i * spacing);
			leText.distancePerItem = new FlxPoint(0, spacing);
			leText.setAlignmentFromString('right');
			leText.targetY = i; // usado solo para resaltar (alpha)
			grpTexts.add(leText);
		}
		
		#if MODS_ALLOWED
		var textBG:FlxSprite = new FlxSprite(0, FlxG.height - 42).makeGraphic(FlxG.width, 42, 0xFF000000);
		textBG.alpha = 0.6;
		add(textBG);

		directoryTxt = new FlxText(textBG.x, textBG.y + 4, FlxG.width, '', 32);
		directoryTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		directoryTxt.scrollFactor.set();
		add(directoryTxt);
		
		for (folder in Mods.getModDirectories())
		{
			directories.push(folder);
		}

		var found:Int = directories.indexOf(Mods.currentModDirectory);
		if(found > -1) curDirectory = found;
		changeDirectory();
		#end
		changeSelection();

		FlxG.mouse.visible = false;
		super.create();
		// Evitar que la cámara siga objetos heredados del menú anterior
		FlxG.camera.follow(null, LOCKON, 0);
	}

	override function update(elapsed:Float)
	{
		if (controls.UI_UP_P)
		{
			changeSelection(-1);
		}
		if (controls.UI_DOWN_P)
		{
			changeSelection(1);
		}
		#if MODS_ALLOWED
		if(controls.UI_LEFT_P)
		{
			changeDirectory(-1);
		}
		if(controls.UI_RIGHT_P)
		{
			changeDirectory(1);
		}
		#end

		if (controls.BACK)
		{
			if (backend.MenuSelector.getMenu() == 'oldmenu')
				MusicBeatState.switchState(new MainMenuState_oldmenu());
			else
				MusicBeatState.switchState(new SoftCodeMenuState(true));
		}

		if (controls.ACCEPT)
		{
			switch(options[curSelected]) {
				case 'Chart Editor'://felt it would be cool maybe
					LoadingState.loadAndSwitchState(new ChartingState(), false);
				case 'Character Editor':
					LoadingState.loadAndSwitchState(new CharacterEditorState(Character.DEFAULT_CHARACTER, false));
				case 'Stage Editor':
					LoadingState.loadAndSwitchState(new StageEditorState());
				case 'Week Editor':
					MusicBeatState.switchState(new WeekEditorState());
				// Removed several editor options: Menu Character, Dialogue, Dialogue Portrait, Note Splash
			}
			if (FlxG.sound.music != null) FlxG.sound.music.volume = 0; // puede ser null si no hay música sonando
			FreeplayState.destroyFreeplayVocals();
		}
		
		for (num => item in grpTexts.members)
		{
			// Mantener las opciones en su lugar; sólo cambiar resaltado
			item.targetY = num;
			item.alpha = 0.6;
			if (num == curSelected)
				item.alpha = 1;
		}
		super.update(elapsed);

		// Overlay toggle removed
	}

	function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		curSelected = FlxMath.wrap(curSelected + change, 0, options.length - 1);
	}

	#if MODS_ALLOWED
	function changeDirectory(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curDirectory += change;

		if(curDirectory < 0)
			curDirectory = directories.length - 1;
		if(curDirectory >= directories.length)
			curDirectory = 0;
	
		WeekData.setDirectoryFromWeek();
		if(directories[curDirectory] == null || directories[curDirectory].length < 1)
			directoryTxt.text = '< No Mod Directory Loaded >';
		else
		{
			Mods.currentModDirectory = directories[curDirectory];
			directoryTxt.text = '< Loaded Mod Directory: ' + Mods.currentModDirectory + ' >';
		}
		directoryTxt.text = directoryTxt.text.toUpperCase();
	}
	#end
}
