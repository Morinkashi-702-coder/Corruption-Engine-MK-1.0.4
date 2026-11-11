package options;

import states.SoftCodeMenuState;
import backend.StageData;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxGlitchEffect;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.math.FlxMath;

class GameplaySettingsSubState_oldmenu extends MusicBeatSubstate
{
	private var grpOptions:FlxTypedGroup<FlxText>;
	private var grpValues:FlxTypedGroup<FlxText>;
	private var curSelected:Int = 0;
	private var lerpSelected:Float = 0;
	private var optionsList:Array<String> = [];
	private var optionsDescriptions:Map<String, String> = [];
	private var optionsVariables:Map<String, String> = [];
	private var descText:FlxText;
	private var descBg:FlxSprite;
	private var titleText:FlxText;
	private var selectedBox:FlxSprite;
	private var maxVisibleOptions:Int = 4;
	private var drawDistance:Int = 4;
	private var lastVisibles:Array<Int> = [];
	private var waitingForInputRelease:Bool = true;

	var exiting:Bool = false;

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

		// Configurar opciones
		optionsList = [
			'Down Scroll',
			'Middlescroll',
			'Opponent Notes',
			'Ghost Tapping',
			'Disable Reset Button',
			'Hitsound Volume',
			'Rating Offset',
			'Sick! Hit Window',
			'Good Hit Window',
			'Bad Hit Window',
			'Safe Frames'
		];

		optionsDescriptions = [
			'Down Scroll' => 'Notes go down instead of up for a\ndifferent gameplay experience.',
			'Middlescroll' => 'Center your notes on the screen\nfor better accuracy and control.',
			'Opponent Notes' => 'Show or hide opponent notes during\nplaying to reduce visual clutter.',
			'Ghost Tapping' => 'No misses on empty taps, only count\nactual notes you need to hit.',
			'Disable Reset Button' => 'Disable the reset button during gameplay\nfor consistency in scores.',
			'Hitsound Volume' => 'Adjust the volume of hitsounds when\nyou hit notes correctly.',
			'Rating Offset' => 'Adjust timing offset for hit ratings\nin milliseconds.',
			'Sick! Hit Window' => 'Changes the timing window for a Sick rating\nin milliseconds.',
			'Good Hit Window' => 'Changes the timing window for a Good rating\nin milliseconds.',
			'Bad Hit Window' => 'Changes the timing window for a Bad rating\nin milliseconds.',
			'Safe Frames' => 'Changes how many frames you have to hit\na note earlier or late.'
		];

		optionsVariables = [
			'Down Scroll' => 'downScroll',
			'Middlescroll' => 'middleScroll',
			'Opponent Notes' => 'opponentStrums',
			'Ghost Tapping' => 'ghostTapping',
			'Disable Reset Button' => 'noReset',
			'Hitsound Volume' => 'hitsoundVolume',
			'Rating Offset' => 'ratingOffset',
			'Sick! Hit Window' => 'sickWindow',
			'Good Hit Window' => 'goodWindow',
			'Bad Hit Window' => 'badWindow',
			'Safe Frames' => 'safeFrames'
		];

		// Título con efecto
		titleText = new FlxText(0, 10, FlxG.width, 'GAMEPLAY SETTINGS', 48);
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
			var optionText:FlxText = new FlxText(FlxG.width + 120, 110 + (85 * num), FlxG.width, option, 36);
			optionText.setFormat(Paths.font('pixel.otf'), 36, 0xFF00ff00, CENTER);
			optionText.color = 0xFF00ff00;
			optionText.alpha = 0.6;
			optionText.ID = num;
			grpOptions.add(optionText);
			
			// Animar entrada desde la derecha con leve fade
			optionText.alpha = 0;
			FlxTween.tween(optionText, {x: 0 - 50, alpha: 0.6}, 0.55 + (num * 0.05), {ease: FlxEase.quadOut});

			// Crear texto de valor
			var valueText:FlxText = new FlxText(FlxG.width + 120, 110 + (85 * num), FlxG.width - 200, '', 32);
			valueText.setFormat(Paths.font('pixel.otf'), 32, 0xFF00ff00, RIGHT);
			valueText.color = 0xFF00ff00;
			valueText.alpha = 0.6;
			grpValues.add(valueText);

			// Animar entrada desde la derecha con leve fade
			valueText.alpha = 0;
			FlxTween.tween(valueText, {x: 0 - 50, alpha: 0.6}, 0.55 + (num * 0.05), {ease: FlxEase.quadOut});
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
		animateHeaderEntry();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence('Gameplay Settings', null);
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

		if (controls.UI_UP_P)
			changeSelection(-1);
		if (controls.UI_DOWN_P)
			changeSelection(1);

		if (controls.BACK)
		{
			startExitAnimation();
			return; // avoid further updates while exiting
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

	function animateHeaderEntry()
	{
		// Fade-in for static elements
		for(element in [titleText, descBg, descText])
		{
			if(element != null){ element.alpha = 0; FlxTween.tween(element, {alpha: element == titleText ? 1: element.alpha==0?0.95:element.alpha}, 0.6, {ease: FlxEase.quadOut}); }
		}
	}

	function startExitAnimation()
	{
		if(exiting) return;
		exiting = true;
		FlxG.sound.play(Paths.sound('cancelMenu'));
		var all:Array<Dynamic> = [];
		grpOptions.forEachAlive(function(t:FlxText) all.push(t));
		grpValues.forEachAlive(function(t:FlxText) all.push(t));
		all.push(titleText); all.push(descBg); all.push(descText); all.push(selectedBox);
		var remaining = all.length;
		for(item in all){
			if(item == null){ remaining--; continue; }
			FlxTween.tween(item, {alpha: 0, x: item.x - 80}, 0.3, {ease: FlxEase.quadIn, onComplete: function(_){
				remaining--;
				if(remaining <= 0) close();
			}});
		}
	}

	function changeSelection(change:Int = 0)
	{
		curSelected = FlxMath.wrap(curSelected + change, 0, optionsList.length - 1);
		FlxG.sound.play(Paths.sound('scrollMenu'));

		// Actualizar descripción
		descText.text = optionsDescriptions[optionsList[curSelected]];
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
			case 'Down Scroll':
				ClientPrefs.data.downScroll ? 'ON' : 'OFF';
			case 'Middlescroll':
				ClientPrefs.data.middleScroll ? 'ON' : 'OFF';
			case 'Opponent Notes':
				ClientPrefs.data.opponentStrums ? 'ON' : 'OFF';
			case 'Ghost Tapping':
				ClientPrefs.data.ghostTapping ? 'ON' : 'OFF';
			case 'Disable Reset Button':
				ClientPrefs.data.noReset ? 'ON' : 'OFF';
			case 'Hitsound Volume':
				Std.string(Math.round(ClientPrefs.data.hitsoundVolume * 100)) + '%';
			case 'Rating Offset':
				Std.string(ClientPrefs.data.ratingOffset) + 'ms';
			case 'Sick! Hit Window':
				Std.string(ClientPrefs.data.sickWindow) + 'ms';
			case 'Good Hit Window':
				Std.string(ClientPrefs.data.goodWindow) + 'ms';
			case 'Bad Hit Window':
				Std.string(ClientPrefs.data.badWindow) + 'ms';
			case 'Safe Frames':
				Std.string(FlxMath.roundDecimal(ClientPrefs.data.safeFrames, 1));
			default:
				'';
		};
	}

	function changeOption(change:Int = 0)
	{
		var optionName:String = optionsList[curSelected];
		var varName:String = optionsVariables[optionName];

		switch(optionName)
		{
			case 'Down Scroll':
				ClientPrefs.data.downScroll = !ClientPrefs.data.downScroll;
				FlxG.sound.play(Paths.sound('confirmMenu'));
			case 'Middlescroll':
				ClientPrefs.data.middleScroll = !ClientPrefs.data.middleScroll;
				FlxG.sound.play(Paths.sound('confirmMenu'));
			case 'Opponent Notes':
				ClientPrefs.data.opponentStrums = !ClientPrefs.data.opponentStrums;
				FlxG.sound.play(Paths.sound('confirmMenu'));
			case 'Ghost Tapping':
				ClientPrefs.data.ghostTapping = !ClientPrefs.data.ghostTapping;
				FlxG.sound.play(Paths.sound('confirmMenu'));
			case 'Disable Reset Button':
				ClientPrefs.data.noReset = !ClientPrefs.data.noReset;
				FlxG.sound.play(Paths.sound('confirmMenu'));
			case 'Hitsound Volume':
				ClientPrefs.data.hitsoundVolume = FlxMath.bound(ClientPrefs.data.hitsoundVolume + (change * 0.1), 0, 1);
				FlxG.sound.play(Paths.sound('hitsound'), ClientPrefs.data.hitsoundVolume);
			case 'Rating Offset':
				ClientPrefs.data.ratingOffset = Std.int(FlxMath.bound(ClientPrefs.data.ratingOffset + (change * 10), -30, 30));
				FlxG.sound.play(Paths.sound('scrollMenu'));
			case 'Sick! Hit Window':
				ClientPrefs.data.sickWindow = Std.int(FlxMath.bound(ClientPrefs.data.sickWindow + (change * 1), 15, 45));
				FlxG.sound.play(Paths.sound('scrollMenu'));
			case 'Good Hit Window':
				ClientPrefs.data.goodWindow = Std.int(FlxMath.bound(ClientPrefs.data.goodWindow + (change * 1), 15, 90));
				FlxG.sound.play(Paths.sound('scrollMenu'));
			case 'Bad Hit Window':
				ClientPrefs.data.badWindow = Std.int(FlxMath.bound(ClientPrefs.data.badWindow + (change * 1), 15, 135));
				FlxG.sound.play(Paths.sound('scrollMenu'));
			case 'Safe Frames':
				ClientPrefs.data.safeFrames = FlxMath.roundDecimal(FlxMath.bound(ClientPrefs.data.safeFrames + (change * 0.1), 2, 10), 1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
		}

		ClientPrefs.saveSettings();
	}
}
