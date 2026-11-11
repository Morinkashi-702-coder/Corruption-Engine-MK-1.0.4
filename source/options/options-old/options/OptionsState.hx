package options;

import states.SoftCodeMenuState;
import states.MainMenuState;
import states.MainMenuState_oldmenu;
import backend.StageData;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxGlitchEffect;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;
import flixel.FlxObject;
import flixel.FlxBasic;
import objects.Alphabet;

class OptionsState extends MusicBeatState
{
	
	var options:Array<String> = [
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
	var useOldMenuStyle:Bool = false;
	var selectorRight:Alphabet;

	// --- DEV MENU VARS ---
	var devMenuEnabled:Bool = false;
	var devMenuGroup:FlxTypedGroup<FlxBasic>;
	var coordsText:FlxText;
	var controlsText:FlxText;
	var currentTextSize:Int = 80;
	// --- END DEV MENU VARS ---

	function openSelectedSubstate(label:String) {
		if (useOldMenuStyle) {
			switch(label)
			{
				case 'Controls': openSubState(new ControlsSubState_oldmenu());
				case 'Graphics': openSubState(new GraphicsSettingsSubState(true));
				case 'Visuals': openSubState(new VisualsSettingsSubState_oldmenu());
				case 'Gameplay': openSubState(new GameplaySettingsSubState_oldmenu());
				case 'Optimization': openSubState(new OptimizationSubState());
			}
			return;
		}

		switch(label)
		{
			case 'Controls':
				openSubState(new options.ControlsSubState());
			case 'Graphics':
				openSubState(new options.GraphicsSettingsSubState(false));
			case 'Visuals':
				openSubState(new options.VisualsSettingsSubState());
			case 'Gameplay':
				openSubState(new options.GameplaySettingsSubState());
			case 'Language':
				openSubState(new options.LanguageSubState());
			case 'Optimization':
				openSubState(new options.OptimizationSubState());
		}
	}

	var selectorLeft:Alphabet;

	override function create()
	{
		useOldMenuStyle = backend.MenuSelector.getMenu() == 'oldmenu';
		if (useOldMenuStyle) {
			createOldMenuStyle();
			return;
		}

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end

		persistentUpdate = true;
		persistentDraw = true;

		FlxG.mouse.visible = false;
		FlxG.camera.bgColor = FlxColor.BLACK;

		super.create();

		// ===== CONFIGURACIÓN DE CÁMARA IGUAL A SIDESTORY =====
		var camFollow = new FlxSprite().makeGraphic(1, 1, 0xFF000000);
		camFollow.alpha = 0;
		camFollow.setPosition(636, 392);
		var camFollowPos = new FlxObject(636, 392, 1, 1);
		add(camFollow);
		add(camFollowPos);

		FlxG.camera.zoom = 0.593;
		FlxG.camera.follow(camFollowPos, null, 1);

		// ===== FONDO DE SIDESTORYMENUSTATE =====
		var bg = new FlxSprite().loadGraphic(Paths.image("menus/sidestory/gradient"));
		bg.scrollFactor.set();
		bg.screenCenter();
		bg.alpha = 0.6;
		bg.scale.set(1.7, 1.7);
		add(bg);
		FlxTween.tween(bg, {alpha: 0.3}, 10.0, {ease: FlxEase.sineInOut, type: FlxTween.PINGPONG});

		var chains = new FlxSprite().loadGraphic(Paths.image("menus/sidestory/chains"));
		chains.scrollFactor.set();
		chains.screenCenter();
		chains.scale.set(1.7, 1.7);
		add(chains);

		// BLACKTOP TEMPORALMENTE COMENTADO
		/*var blackTop = new FlxSprite(10, -20, Paths.image('menus/mainmenu/fullBlack'));
		blackTop.scrollFactor.set(0, 0);
		blackTop.scale.set(1.7, 1.7);
		add(blackTop);*/

		// ===== OPCIONES CON FUENTE DE CREDITS =====
		grpOptions = new FlxTypedGroup<FlxText>();
		add(grpOptions);

		for (num => option in options)
		{
			var optionText:FlxText = new FlxText(-198, -31 + (80 * num), 1000, Language.getPhrase('options_$option', option), 80);
			optionText.setFormat(Paths.font("VollkornRegular-ZVJEZ.ttf"), 80, FlxColor.WHITE, LEFT);
			optionText.scrollFactor.set(1, 1);
			optionText.alpha = 0.1;
			grpOptions.add(optionText);
		}

		// selectorLeft = new Alphabet(-406, -66, '>', true);
		// selectorLeft.color = FlxColor.WHITE;
		// selectorLeft.scrollFactor.set(1, 1);
		// add(selectorLeft);

		changeSelection();
		ClientPrefs.saveSettings();

		FlxG.sound.playMusic(Paths.music('menu4'), 0.7);

		// --- DEV MENU ---
		devMenuGroup = new FlxTypedGroup<FlxBasic>();
		add(devMenuGroup);
		devMenuGroup.visible = false;

		var devBG = new FlxSprite(0, FlxG.height - 100).makeGraphic(FlxG.width, 100, FlxColor.BLACK);
		devBG.alpha = 0.7;
		devMenuGroup.add(devBG);

		coordsText = new FlxText(10, devBG.y + 10, 0, "Options X: 185 | Y: 31 | Size: 80", 16);
		coordsText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE);
		devMenuGroup.add(coordsText);

		controlsText = new FlxText(10, devBG.y + 30, 0, "Arrow X: -406 | Y: -66", 16);
		controlsText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.YELLOW);
		devMenuGroup.add(controlsText);

		var instructionsText = new FlxText(10, devBG.y + 50, 0, "MOUSE: Move Options | ARROWS: Move Arrow | +/-: Size | SHIFT+ARROWS: Fine Arrow", 14);
		instructionsText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.CYAN);
		devMenuGroup.add(instructionsText);
		// --- END DEV MENU ---
		
		// Animaciones de entrada fluidas
		animateEntry();
	}

	// Sempai Demo visual skin. The behavior and option list remain in this
	// shared state, so both menus use the same settings entry point.
	function createOldMenuStyle():Void
	{
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end

		persistentUpdate = true;
		persistentDraw = true;
		FlxG.mouse.visible = false;
		FlxG.camera.bgColor = FlxColor.BLACK;

		var bg = new FlxSprite().loadGraphic(Paths.image('menus/optionsMenu/optionsBack'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.screenCenter();
		add(bg);

		var scanlines = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
		scanlines.alpha = 0.1;
		add(scanlines);

		var glitchSprite = new FlxSprite().loadGraphic(Paths.image('menus/optionsMenu/optionsGlitch'));
		glitchSprite.antialiasing = ClientPrefs.data.antialiasing;
		var glitchEffect = new FlxGlitchEffect();
		glitchEffect.size = 5;
		glitchEffect.delay = 0.1;
		glitchEffect.strength = 5;
		add(new FlxEffectSprite(glitchSprite, [glitchEffect]));

		grpOptions = new FlxTypedGroup<FlxText>();
		add(grpOptions);
		for (num => option in options)
		{
			var optionText = new FlxText(0, 90 + (65 * num), FlxG.width, Language.getPhrase('options_$option', option), 30);
			optionText.setFormat(Paths.font('pixel.otf'), 30, 0xFF00ff00, CENTER);
			grpOptions.add(optionText);
		}

		selectorLeft = new Alphabet(0, 0, '>', true);
		selectorLeft.color = 0xFF00ff00;
		add(selectorLeft);
		selectorRight = new Alphabet(0, 0, '<', true);
		selectorRight.color = 0xFF00ff00;
		add(selectorRight);

		var front = new FlxSprite().loadGraphic(Paths.image('menus/optionsMenu/optionsFront'));
		front.antialiasing = ClientPrefs.data.antialiasing;
		front.screenCenter();
		add(front);

		changeSelection(0);
		ClientPrefs.saveSettings();
		FlxG.sound.playMusic(Paths.music('menu4'), 0.7);
		super.create();
	}
	
	function animateEntry()
	{
		// Animaciones de entrada más fluidas tipo FreeplayState
		var delay:Float = 0.08; // Delay mayor para efecto más elegante
		var base:Float = 0.3;   // Base más rápida
		
		for (i in 0...grpOptions.length)
		{
			var text = grpOptions.members[i];
			if (text != null)
			{
				var targetY = text.y;
				var targetAlpha = (i == curSelected) ? 1 : 0.5;
				
				// Empezar desde abajo con efecto más sutil
				text.y += FlxG.height * 0.4;
				text.alpha = 0;
				text.scale.set(0.85, 0.85);
				
				// Animación de entrada con escalado suave
				FlxTween.tween(text, {
					y: targetY, 
					alpha: targetAlpha
				}, base + i * delay, {ease: FlxEase.circOut});
				
				FlxTween.tween(text.scale, {
					x: (i == curSelected) ? 1.08 : 1.0,
					y: (i == curSelected) ? 1.08 : 1.0
				}, (base + i * delay) * 1.3, {ease: FlxEase.circOut});
			}
		}
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

		// No procesar input si hay un substate activo
		if (subState != null) return;

		// Suavizar movimiento de cámara (como en CreditsState)
		var lerpVal:Float = Math.exp(-elapsed * 2.4 * 2);
		if (grpOptions.members[curSelected] != null) {
			var targetY = grpOptions.members[curSelected].y;
			// Mover la cámara siguiendo la opción seleccionada
		}

		if (controls.UI_UP_P)
			changeSelection(-1);
		if (controls.UI_DOWN_P)
			changeSelection(1);

		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			if(onPlayState)
			{
				StageData.loadDirectory(PlayState.SONG);
				LoadingState.loadAndSwitchState(new PlayState());
				FlxG.sound.music.volume = 0;
			}
			else if (useOldMenuStyle) {
				MusicBeatState.switchState(new MainMenuState_oldmenu());
			}
			else {
				// Transición de zoom acercándose al salir
				FlxTween.tween(FlxG.camera, {zoom: 1.3}, 0.5, {ease: FlxEase.backIn});
				MusicBeatState.switchState(new SoftCodeMenuState(true));
			}
		}
		else if (controls.ACCEPT) openSelectedSubstate(options[curSelected]);

		// --- DEV MENU LOGIC ---
		if (!useOldMenuStyle && FlxG.keys.justPressed.F2)
		{
			devMenuEnabled = !devMenuEnabled;
			devMenuGroup.visible = devMenuEnabled;
			FlxG.mouse.visible = devMenuEnabled;
		}

		if (devMenuEnabled && subState == null)
		{
			// Mover opciones con el mouse
			if (FlxG.mouse.pressed)
			{
				grpOptions.forEach(function(text:FlxText) {
					text.x = FlxG.mouse.x;
					text.y = FlxG.mouse.y + (grpOptions.members.indexOf(text) * 80);
				});
			}
			
			// Cambiar tamaño de las opciones
			if (FlxG.keys.justPressed.PLUS || FlxG.keys.justPressed.NUMPADPLUS)
			{
				currentTextSize += 5;
				updateTextSize();
			}
			if (FlxG.keys.justPressed.MINUS || FlxG.keys.justPressed.NUMPADMINUS)
			{
				currentTextSize = Std.int(Math.max(10, currentTextSize - 5));
				updateTextSize();
			}
			
			// Actualizar textos de coordenadas
			if (grpOptions.members.length > 0)
			{
				var firstOption = grpOptions.members[0];
				coordsText.text = 'Options X: ' + Math.floor(firstOption.x) + ' | Y: ' + Math.floor(firstOption.y) + ' | Size: ' + currentTextSize;
				// controlsText.text = 'Arrow X: ' + Math.floor(selectorLeft.x) + ' | Y: ' + Math.floor(selectorLeft.y);
			}
		}
		// --- END DEV MENU LOGIC ---
	}
	
	function changeSelection(change:Int = 0)
	{
		curSelected = FlxMath.wrap(curSelected + change, 0, options.length - 1);

		if (useOldMenuStyle)
		{
			for (num => item in grpOptions.members)
			{
				if (item == null) continue;
				if (num == curSelected)
				{
					item.color = 0xFF00ff00;
					item.alpha = 1;
					selectorLeft.x = item.x - 63;
					selectorLeft.y = item.y;
					selectorRight.x = item.x + item.width + 15;
					selectorRight.y = item.y;
				}
				else
				{
					item.color = 0xFF007700;
					item.alpha = 0.6;
				}
			}
			FlxG.sound.play(Paths.sound('scrollMenu'));
			return;
		}

		for (i in 0...grpOptions.length)
		{
			var text = grpOptions.members[i];
			if (text != null)
			{
				// Cancelar tweens anteriores
				FlxTween.cancelTweensOf(text);
				FlxTween.cancelTweensOf(text.scale);
				
				// Configurar valores objetivo más sutiles y fluidos
				var targetAlpha:Float = 0.5; // Menos contraste
				var targetScale:Float = 1.0;
				
				if (i == curSelected)
				{
					targetAlpha = 1;
					targetScale = 1.08; // Escala más sutil
				}
				else if (Math.abs(i - curSelected) == 1) // Opciones adyacentes
				{
					targetAlpha = 0.7; // Más visibles las opciones cercanas
					targetScale = 1.0;
				}
				
				// Aplicar animaciones más fluidas tipo FreeplayState
				FlxTween.tween(text, {
					alpha: targetAlpha
				}, 0.15, {ease: FlxEase.circOut}); // Timing más rápido y suave
				
				FlxTween.tween(text.scale, {
					x: targetScale,
					y: targetScale
				}, 0.2, {ease: FlxEase.circOut});
			}
		}

		// Actualizar posición de la flecha
		// if (grpOptions.members[curSelected] != null) {
		//	selectorLeft.x = grpOptions.members[curSelected].x - 198;
		//	selectorLeft.y = grpOptions.members[curSelected].y - 31;
		// }

		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function updateTextSize()
	{
		grpOptions.forEach(function(text:FlxText) {
			text.setFormat(Paths.font("VollkornRegular-ZVJEZ.ttf"), currentTextSize, FlxColor.WHITE, LEFT);
		});
	}

	override function destroy()
	{
		// ClientPrefs.loadPrefs(); // REMOVIDO - causaba que se perdieran los ajustes
		super.destroy();
	}
}
