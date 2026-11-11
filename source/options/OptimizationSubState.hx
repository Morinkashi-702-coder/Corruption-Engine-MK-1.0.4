package options;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxGlitchEffect;
import objects.Alphabet;
import objects.CheckboxThingieCustom;

/**
 * Optimization unificado.
 * Una preferencia y dos herramientas, con la presentación de cada menú.
 */
class OptimizationSubState extends MusicBeatSubstate
{
	var useOldMenuStyle:Bool;
	var waitingForInputRelease:Bool = true;
	var optionText:Alphabet;
	var checkbox:CheckboxThingieCustom;
	var oldOptionText:FlxText;
	var oldValueText:FlxText;
	var oldSelectedBox:FlxSprite;
	var oldTitleText:FlxText;
	var curSelected:Int = 0;
	var actionTexts:Array<Alphabet> = [];
	var oldActionTexts:Array<FlxText> = [];
	var descriptionText:FlxText;
	var descriptions:Array<String> = [
		'Disables menu shaders and effects for better performance.',
		'Test a gameplay scene and verify the proposed graphics settings.\nNothing changes unless you accept the result.',
		'Restore graphics settings from before the last automatic change.\nScores and controls stay unchanged.'
	];

	public function new()
	{
		super();
		useOldMenuStyle = backend.MenuSelector.getMenu() == 'oldmenu';

		if (useOldMenuStyle) createOldMenuStyle();
		else createNewMenuStyle();
		updateSelection();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence('Optimization Settings', null);
		#end
	}

	function createNewMenuStyle():Void
	{
		FlxG.camera.zoom = 0.593;

		var camFollow:FlxSprite = new FlxSprite().makeGraphic(1, 1, FlxColor.TRANSPARENT);
		camFollow.setPosition(636, 392);
		var camFollowPos:FlxObject = new FlxObject(636, 392, 1, 1);
		add(camFollow);
		add(camFollowPos);
		FlxG.camera.follow(camFollowPos, null, 1);

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menus/sidestory/gradient'));
		bg.scrollFactor.set();
		bg.screenCenter();
		bg.alpha = 0.6;
		bg.scale.set(1.7, 1.7);
		add(bg);

		var chains:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menus/sidestory/chains'));
		chains.scrollFactor.set();
		chains.screenCenter();
		chains.scale.set(1.7, 1.7);
		add(chains);

		optionText = new Alphabet(522, FlxG.height * 0.36, 'Disable Menu Shaders', true);
		optionText.scrollFactor.set();
		optionText.color = FlxColor.WHITE;
		add(optionText);

		checkbox = new CheckboxThingieCustom(optionText.x - 105, optionText.y, ClientPrefs.data.menuShaders);
		checkbox.sprTracker = optionText;
		checkbox.offsetX = 25;
		checkbox.offsetY = -30;
		checkbox.scrollFactor.set();
		add(checkbox);

		for (i in 0...2)
		{
			var text = new Alphabet(522, optionText.y + (i + 1) * 110,
				i == 0 ? 'Performance Test' : 'Restore Previous Graphics', true);
			text.scrollFactor.set();
			actionTexts.push(text);
			add(text);
		}
		var panel = new OptionsDescriptionPanel();
		descriptionText = panel.label;
		add(panel);
	}

	function createOldMenuStyle():Void
	{
		FlxG.camera.zoom = 1;

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menus/optionsMenu/optionsBack'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.screenCenter();
		add(bg);

		var scanlines:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		scanlines.alpha = 0.1;
		add(scanlines);

		var glitchSprite:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menus/optionsMenu/optionsGlitch'));
		glitchSprite.antialiasing = ClientPrefs.data.antialiasing;
		var glitchEffect:FlxGlitchEffect = new FlxGlitchEffect();
		glitchEffect.size = 5;
		glitchEffect.delay = 0.1;
		glitchEffect.strength = 5;
		add(new FlxEffectSprite(glitchSprite, [glitchEffect]));

		oldTitleText = new FlxText(0, 10, FlxG.width, 'OPTIMIZATION', 48);
		oldTitleText.setFormat(Paths.font('pixel.otf'), 48, 0xFF00FF00, CENTER);
		add(oldTitleText);
		add(new FlxSprite(80, 68).makeGraphic(FlxG.width - 160, 4, 0xFF00FF00));
		add(new FlxSprite(80, 75).makeGraphic(FlxG.width - 160, 2, 0xFF007700));

		oldSelectedBox = new FlxSprite(60, 100).makeGraphic(FlxG.width - 120, 100, 0xFF001100);
		oldSelectedBox.alpha = 0.7;
		add(oldSelectedBox);

		oldOptionText = new FlxText(-50, 110, FlxG.width, 'Disable Menu Shaders', 36);
		oldOptionText.setFormat(Paths.font('pixel.otf'), 36, 0xFF00FF00, CENTER);
		add(oldOptionText);

		oldValueText = new FlxText(-50, 110, FlxG.width - 200, getOldValue(), 32);
		oldValueText.setFormat(Paths.font('pixel.otf'), 32, 0xFF00FF00, RIGHT);
		add(oldValueText);
		for (i in 0...2)
		{
			var text = new FlxText(-50, 230 + i * 120, FlxG.width,
				i == 0 ? 'Performance Test' : 'Restore Previous Graphics', 32);
			text.setFormat(Paths.font('pixel.otf'), 32, 0xFF00FF00, CENTER);
			oldActionTexts.push(text);
			add(text);
		}

		var descBg:FlxSprite = new FlxSprite(50, FlxG.height - 145).makeGraphic(FlxG.width - 100, 125, 0xFF0A0A15);
		descBg.alpha = 0.95;
		add(descBg);
		add(new FlxSprite(50, FlxG.height - 150).makeGraphic(FlxG.width - 100, 5, 0xFF00FF00));
		add(new FlxSprite(50, FlxG.height - 20).makeGraphic(FlxG.width - 100, 5, 0xFF007700));

		var descText:FlxText = new FlxText(70, FlxG.height - 135, FlxG.width - 140,
			'Disables menu shaders and effects for better performance.', 18);
		descText.setFormat(Paths.font('pixel.otf'), 18, 0xFF00FF00, CENTER);
		add(descText);
		descriptionText = descText;

		var front:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menus/optionsMenu/optionsFront'));
		front.antialiasing = ClientPrefs.data.antialiasing;
		front.screenCenter();
		add(front);
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (useOldMenuStyle)
		{
			oldTitleText.alpha = 0.85 + Math.sin(FlxG.game.ticks * 0.005) * 0.15;
			oldSelectedBox.alpha = 0.6 + Math.sin(FlxG.game.ticks * 0.003) * 0.1;
		}

		if (waitingForInputRelease)
		{
			if (!controls.ACCEPT && !controls.BACK) waitingForInputRelease = false;
			return;
		}

		if (controls.BACK)
		{
			ClientPrefs.saveSettings();
			FlxG.sound.play(Paths.sound('cancelMenu'));
			close();
			return;
		}

		if (controls.UI_UP_P || controls.UI_DOWN_P)
		{
			curSelected = (curSelected + (controls.UI_UP_P ? 2 : 1)) % 3;
			FlxG.sound.play(Paths.sound('scrollMenu'));
			updateSelection();
			return;
		}

		if (curSelected > 0 && controls.ACCEPT)
		{
			persistentUpdate = false;
			openSubState(new AutoGraphicsReviewSubState(curSelected == 2, function()
			{
				persistentUpdate = true;
				waitingForInputRelease = true;
				updateSelection();
			}));
			return;
		}

		if (curSelected == 0 && (controls.ACCEPT || controls.UI_LEFT_P || controls.UI_RIGHT_P))
		{
			ClientPrefs.data.menuShaders = !ClientPrefs.data.menuShaders;
			ClientPrefs.saveSettings();
			FlxG.sound.play(Paths.sound('scrollMenu'));

			if (checkbox != null) checkbox.daValue = ClientPrefs.data.menuShaders;
			if (oldValueText != null) oldValueText.text = getOldValue();
		}
	}

	function updateSelection():Void
	{
		if (descriptionText != null) descriptionText.text = descriptions[curSelected];
		if (checkbox != null) checkbox.daValue = ClientPrefs.data.menuShaders;
		if (oldValueText != null) oldValueText.text = getOldValue();
		if (useOldMenuStyle)
		{
			oldSelectedBox.y = 100 + curSelected * 120;
			oldOptionText.alpha = oldValueText.alpha = curSelected == 0 ? 1 : 0.45;
			for (i in 0...oldActionTexts.length) oldActionTexts[i].alpha = curSelected == i + 1 ? 1 : 0.45;
		}
		else
		{
			optionText.alpha = checkbox.alpha = curSelected == 0 ? 1 : 0.45;
			for (i in 0...actionTexts.length) actionTexts[i].alpha = curSelected == i + 1 ? 1 : 0.45;
		}
	}

	inline function getOldValue():String
		return ClientPrefs.data.menuShaders ? 'ON' : 'OFF';
}
