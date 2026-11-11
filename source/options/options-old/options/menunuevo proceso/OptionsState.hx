package options;

import states.SoftCodeMenuState;
import states.MainMenuState;
import backend.StageData;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;
import flixel.FlxObject;

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

	override function create()
	{
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
			var optionText:FlxText = new FlxText(-470, 200 + (80 * num), 1000, Language.getPhrase('options_$option', option), 50);
			optionText.setFormat(Paths.font("VollkornRegular-ZVJEZ.ttf"), 50, FlxColor.WHITE, LEFT);
			optionText.scrollFactor.set(1, 1);
			optionText.alpha = 0.1;
			grpOptions.add(optionText);
		}

		selectorLeft = new Alphabet(-160, -300, '>', true);
		selectorLeft.color = FlxColor.WHITE;
		selectorLeft.scrollFactor.set(1, 1);
		add(selectorLeft);

		changeSelection();
		ClientPrefs.saveSettings();

		FlxG.sound.playMusic(Paths.music('menu4'), 0.7);
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

		for (i in 0...grpOptions.length)
		{
			var text = grpOptions.members[i];
			if (text != null)
			{
				// Cancelar tweens anteriores
				FlxTween.cancelTweensOf(text);
				FlxTween.cancelTweensOf(text.scale);
				
				// Configurar valores objetivo
				var targetAlpha:Float = 0.1;
				var targetScale:Float = 0.95;
				
				if (i == curSelected)
				{
					targetAlpha = 1;
					targetScale = 1.3;
				}
				else if ((i-1) == curSelected || (i+1) == curSelected)
				{
					targetAlpha = 0.15;
					targetScale = 1.0;
				}
				
				// Aplicar animaciones
				FlxTween.tween(text, {
					alpha: targetAlpha
				}, 0.3, {ease: FlxEase.sineOut});
				
				FlxTween.tween(text.scale, {
					x: targetScale,
					y: targetScale
				}, 0.3, {ease: FlxEase.sineOut});
			}
		}

		// Actualizar posición de la flecha
		if (grpOptions.members[curSelected] != null) {
			selectorLeft.y = grpOptions.members[curSelected].y + 20;
		}

		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	override function destroy()
	{
		// ClientPrefs.loadPrefs(); // REMOVIDO - causaba que se perdieran los ajustes
		super.destroy();
	}
}