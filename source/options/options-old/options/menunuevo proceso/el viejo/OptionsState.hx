package options;

import states.SoftCodeMenuState;
import states.MainMenuState;
import backend.StageData;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxGlitchEffect;

class OptionsState extends MusicBeatState
{
	
	var options:Array<String> = [
		'Adjust Combo',
		'Note Colors',
		'Graphics',
		'Visuals',
		'Controls',
		'Gameplay',
		'Optimization',
	];
	private var grpOptions:FlxTypedGroup<FlxText>;
	private static var curSelected:Int = 0;
	public static var menuBG:FlxSprite;
	public static var onPlayState:Bool = false;

	function openSelectedSubstate(label:String) {
		switch(label)
		{
			case 'Note Colors':
				openSubState(new options.NotesColorSubState());
			case 'Controls':
				openSubState(new options.ControlsSubState());
			case 'Graphics':
				openSubState(new options.GraphicsSettingsSubState());
			case 'Visuals':
				openSubState(new options.VisualsSettingsSubState());
			case 'Gameplay':
				openSubState(new options.GameplaySettingsSubState());
			case 'Adjust Combo':
				MusicBeatState.switchState(new options.NoteOffsetState());
			case 'Language':
				openSubState(new options.LanguageSubState());
			case 'Optimization':
				openSubState(new options.OptimizationSubState());
		}
	}

	var selectorLeft:Alphabet;
	var selectorRight:Alphabet;

	override function create()
	{
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end

		// Fondo CRT/Monitor corrupto
		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menus/optionsMenu/optionsBack'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.screenCenter();
		add(bg);

		// Efecto de scanlines (opcional, pero agrega autenticidad CRT)
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

		grpOptions = new FlxTypedGroup<FlxText>();
		add(grpOptions);

		for (num => option in options)
		{
			var optionText:FlxText = new FlxText(0, 130 + (80 * num), FlxG.width, Language.getPhrase('options_$option', option), 32);
			optionText.setFormat(Paths.font('pixel.otf'), 32, 0xFF00ff00, CENTER);
			optionText.color = 0xFF00ff00; // Verde brillante
			grpOptions.add(optionText);
		}

		selectorLeft = new Alphabet(0, 0, '>', true);
		selectorLeft.color = 0xFF00ff00;
		add(selectorLeft);
		selectorRight = new Alphabet(0, 0, '<', true);
		selectorRight.color = 0xFF00ff00;
		add(selectorRight);

		// Frente del monitor (marco/bezel)
		var front:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menus/optionsMenu/optionsFront'));
		front.antialiasing = ClientPrefs.data.antialiasing;
		front.screenCenter();
		add(front);

		changeSelection();
		ClientPrefs.saveSettings();

		// Música
		FlxG.sound.playMusic(Paths.music('menu4'), 1);

		super.create();
	}

	override function closeSubState()
	{
		super.closeSubState();
		ClientPrefs.saveSettings();
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (controls.UI_UP_P)
			changeSelection(-1);
		if (controls.UI_DOWN_P)
			changeSelection(1);

		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			ClientPrefs.saveSettings(); // GUARDAR ANTES DE SALIR
			if(onPlayState)
			{
				StageData.loadDirectory(PlayState.SONG);
				LoadingState.loadAndSwitchState(new PlayState());
				FlxG.sound.music.volume = 0;
			}
			else {
				// Transición de zoom acercándose al salir
				FlxTween.tween(FlxG.camera, {zoom: 1.3}, 0.5, {ease: FlxEase.backIn});
				MusicBeatState.switchState(new SoftCodeMenuState(true));
			}
		}
		else if (controls.ACCEPT) openSelectedSubstate(options[curSelected]);
	}
	
	function changeSelection(change:Int = 0)
	{
		curSelected = FlxMath.wrap(curSelected + change, 0, options.length - 1);

		for (num => item in grpOptions.members)
		{
			// Verde oscuro para opciones no seleccionadas
			if (num == curSelected)
			{
				item.color = 0xFF00ff00; // Verde brillante
				item.alpha = 1;
				selectorLeft.x = item.x - 63;
				selectorLeft.y = item.y;
				selectorRight.x = item.x + item.width + 15;
				selectorRight.y = item.y;
			}
			else
			{
				item.color = 0xFF007700; // Verde oscuro
				item.alpha = 0.6;
			}
		}
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	override function destroy()
	{
		// NO cargar preferencias aquí - eso sobrescribe los cambios
		// ClientPrefs.loadPrefs(); // REMOVIDO - causaba que se perdieran los ajustes
		super.destroy();
	}
}