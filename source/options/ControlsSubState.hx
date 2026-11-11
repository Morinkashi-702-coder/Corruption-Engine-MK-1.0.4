package options;

import backend.InputFormatter;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import objects.AttachedSprite;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxGlitchEffect;

import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.gamepad.FlxGamepadManager;

class ControlsSubState extends MusicBeatSubstate
{
	var useOldMenuStyle:Bool = false;
	var descriptionPanel:OptionsDescriptionPanel;
	var crtFront:FlxSprite = null;
	var crtSelectedBox:FlxSprite = null;
	var crtDescText:FlxText = null;
	var crtControlOptions:FlxTypedGroup<FlxText> = null;
	var crtControlValues:FlxTypedGroup<FlxText> = null;
	var crtArrowLeft:FlxText = null;
	var crtArrowRight:FlxText = null;
	var interfaceColor:FlxColor = FlxColor.WHITE;
	var curSelected:Int = 0;
	var curAlt:Bool = false;

	//Show on gamepad - Display name - Save file key - Rebind display name
	var options:Array<Dynamic> = [
		[true, 'NOTES'],
		[true, 'Left', 'note_left', 'Note Left'],
		[true, 'Down', 'note_down', 'Note Down'],
		[true, 'Up', 'note_up', 'Note Up'],
		[true, 'Right', 'note_right', 'Note Right'],
		[true],
		[true, 'UI'],
		[true, 'Left', 'ui_left', 'UI Left'],
		[true, 'Down', 'ui_down', 'UI Down'],
		[true, 'Up', 'ui_up', 'UI Up'],
		[true, 'Right', 'ui_right', 'UI Right'],
		[true],
		[true, 'Reset', 'reset', 'Reset'],
		[true, 'Accept', 'accept', 'Accept'],
		[true, 'Back', 'back', 'Back'],
		[true, 'Pause', 'pause', 'Pause'],
		[false],
		[false, 'VOLUME'],
		[false, 'Mute', 'volume_mute', 'Volume Mute'],
		[false, 'Up', 'volume_up', 'Volume Up'],
		[false, 'Down', 'volume_down', 'Volume Down'],
		[false],
		[false, 'DEBUG'],
		[false, 'Key 1', 'debug_1', 'Debug Key #1'],
		[false, 'Key 2', 'debug_2', 'Debug Key #2']
	];
	var curOptions:Array<Int>;
	var curOptionsValid:Array<Int>;
	static var defaultKey:String = 'Reset to Default Keys';

	var grpDisplay:FlxTypedGroup<Alphabet>;
	var grpBlacks:FlxTypedGroup<AttachedSprite>;
	var grpOptions:FlxTypedGroup<Alphabet>;
	var grpBinds:FlxTypedGroup<Alphabet>;
	var selectSpr:AttachedSprite;

	var gamepadColor:FlxColor = 0xffffffff; // Blanco
	var keyboardColor:FlxColor = 0xffffffff; // Blanco
	var onKeyboardMode:Bool = true;
	
	var controllerSpr:FlxSprite;
	
	public function new(?oldMenuStyle:Null<Bool>)
	{
		super();
		useOldMenuStyle = oldMenuStyle != null ? oldMenuStyle : backend.MenuSelector.getMenu() == 'oldmenu';
		interfaceColor = useOldMenuStyle ? 0xFF00FF00 : FlxColor.WHITE;
		if (useOldMenuStyle)
		{
			FlxG.camera.target = null;
			FlxG.camera.scroll.set(0, 0);
			FlxG.camera.zoom = 1;
		}

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Controls Menu", null);
		#end

		options.push([true]);
		options.push([true]);
		options.push([true, defaultKey]);

		if (useOldMenuStyle)
		{
			var crtBack:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menus/optionsMenu/optionsBack'));
			crtBack.antialiasing = ClientPrefs.data.antialiasing;
			crtBack.screenCenter();
			add(crtBack);

			var scanlines:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
			scanlines.alpha = 0.1;
			add(scanlines);

			var glitchSprite:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menus/optionsMenu/optionsGlitch'));
			glitchSprite.antialiasing = ClientPrefs.data.antialiasing;
			var glitchEffect:FlxGlitchEffect = new FlxGlitchEffect();
			glitchEffect.size = 5;
			glitchEffect.delay = 0.1;
			glitchEffect.strength = 5;
			add(new FlxEffectSprite(glitchSprite, [glitchEffect]));

			var crtTitle:FlxText = new FlxText(0, 10, FlxG.width, 'CONTROLS', 48);
			crtTitle.setFormat(Paths.font('pixel.otf'), 48, 0xFF00FF00, CENTER);
			add(crtTitle);
			add(new FlxSprite(80, 68).makeGraphic(FlxG.width - 160, 4, 0xFF00FF00));
			add(new FlxSprite(80, 75).makeGraphic(FlxG.width - 160, 2, 0xFF007700));
			crtSelectedBox = new FlxSprite(60, 100).makeGraphic(FlxG.width - 120, 100, 0xFF001100);
			crtSelectedBox.alpha = 0.7;
			add(crtSelectedBox);

			var descBg:FlxSprite = new FlxSprite(50, FlxG.height - 145).makeGraphic(FlxG.width - 100, 125, 0xFF0A0A15);
			descBg.alpha = 0.95;
			add(descBg);
			add(new FlxSprite(50, FlxG.height - 150).makeGraphic(FlxG.width - 100, 5, 0xFF00FF00));
			add(new FlxSprite(50, FlxG.height - 20).makeGraphic(FlxG.width - 100, 5, 0xFF007700));
			crtDescText = new FlxText(70, FlxG.height - 135, FlxG.width - 140,
				'Select a control and press ENTER to change its key.', 18);
			crtDescText.setFormat(Paths.font('pixel.otf'), 18, 0xFF00FF00, CENTER);
			add(crtDescText);

			crtFront = new FlxSprite().loadGraphic(Paths.image('menus/optionsMenu/optionsFront'));
			crtFront.antialiasing = ClientPrefs.data.antialiasing;
			crtFront.screenCenter();
		}

		grpDisplay = new FlxTypedGroup<Alphabet>();
		add(grpDisplay);
		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);
		grpBlacks = new FlxTypedGroup<AttachedSprite>();
		add(grpBlacks);
		selectSpr = new AttachedSprite();
		selectSpr.makeGraphic(250, 78, interfaceColor);
		selectSpr.copyAlpha = false;
		selectSpr.alpha = useOldMenuStyle ? 0 : 0.75;
		add(selectSpr);
		grpBinds = new FlxTypedGroup<Alphabet>();
		add(grpBinds);

		controllerSpr = new FlxSprite(50, 40).loadGraphic(Paths.image('controllertype'), true, 82, 60);
		controllerSpr.antialiasing = ClientPrefs.data.antialiasing;
		controllerSpr.animation.add('keyboard', [0], 1, false);
		controllerSpr.animation.add('gamepad', [1], 1, false);
		add(controllerSpr);

		var text:Alphabet = new Alphabet(60, 90, 'CTRL', false);
		text.alignment = CENTERED;
		text.setScale(0.4);
		add(text);
		if (useOldMenuStyle) text.visible = false;

		if (!useOldMenuStyle)
		{
			descriptionPanel = new OptionsDescriptionPanel('Select a control and press ENTER to change its key.\nUse LEFT / RIGHT to choose a binding.\nPress CTRL to switch keyboard / controller.');
			add(descriptionPanel);
		}
		createTexts();
		
		// La cascada de Alphabet pertenece unicamente al renderer moderno.
		if (!useOldMenuStyle) animateControlsEntry();
	}

	var lastID:Int = 0;
	function createTexts()
	{
		curOptions = [];
		curOptionsValid = [];
		grpDisplay.forEachAlive(function(text:Alphabet) text.destroy());
		grpBlacks.forEachAlive(function(black:AttachedSprite) black.destroy());
		grpOptions.forEachAlive(function(text:Alphabet) text.destroy());
		grpBinds.forEachAlive(function(text:Alphabet) text.destroy());
		grpDisplay.clear();
		grpBlacks.clear();
		grpOptions.clear();
		grpBinds.clear();

		var myID:Int = 0;
		for (i => option in options)
		{
			if(onKeyboardMode || option[0])
			{
				if(option.length > 1)
				{
					var isCentered:Bool = (option.length < 3);
					var isDefaultKey:Bool = (option[1] == defaultKey);
					var isDisplayKey:Bool = (isCentered && !isDefaultKey);

					var str:String = option[1];
					var keyStr:String = option[2];
					if(isDefaultKey) str = Language.getPhrase(str);
					var text:Alphabet = new Alphabet(475, 300, !isDisplayKey ? Language.getPhrase('key_$keyStr', str) : Language.getPhrase('keygroup_$str', str), !isDisplayKey);
					text.isMenuItem = true;
					text.changeX = false;
					text.distancePerItem.y = 60;
					text.targetY = myID;
					text.ID = myID;
					// Forzar letras blancas usando colorTransform para manejar letras negras del atlas
					for(letter in text.letters) {
						if (letter != null) {
							letter.colorTransform.color = interfaceColor;
							letter.color = interfaceColor;
						}
					}
					lastID = myID;

					if(!isDisplayKey)
					{
						text.alignment = RIGHT;
						grpOptions.add(text);
						curOptions.push(i);
						curOptionsValid.push(myID);
					}
					else grpDisplay.add(text);

					if(isCentered) addCenteredText(text, option, myID);
					else addKeyText(text, option, myID);

					text.snapToPosition();
					text.y += FlxG.height * 2;
				}
				myID++;
			}
		}
		updateText();
		if (useOldMenuStyle) rebuildCRTControls();
	}

	function rebuildCRTControls():Void
	{
		if (crtControlOptions != null)
		{
			remove(crtControlOptions, true);
			remove(crtControlValues, true);
			crtControlOptions.destroy();
			crtControlValues.destroy();
		}
		crtControlOptions = new FlxTypedGroup<FlxText>();
		crtControlValues = new FlxTypedGroup<FlxText>();
		add(crtControlOptions);
		add(crtControlValues);
		for (i in 0...curOptions.length)
		{
			var raw:Array<Dynamic> = options[curOptions[i]];
			var label:String = raw[1] == defaultKey ? Language.getPhrase(defaultKey) : Std.string(raw[1]);
			var nameText:FlxText = new FlxText(-50, 110 + ((i - curSelected) * 85), FlxG.width, label, 36);
			nameText.setFormat(Paths.font('pixel.otf'), 36, 0xFF00FF00, CENTER);
			crtControlOptions.add(nameText);
			var valueText:FlxText = new FlxText(-50, nameText.y, FlxG.width - 200, getCRTControlValue(raw), 25);
			valueText.setFormat(Paths.font('pixel.otf'), 25, 0xFF00FF00, RIGHT);
			crtControlValues.add(valueText);
		}
		if (crtArrowLeft == null)
		{
			crtArrowLeft = new FlxText(82, 125, 60, '>', 34);
			crtArrowRight = new FlxText(FlxG.width - 142, 125, 60, '<', 34);
			crtArrowLeft.setFormat(Paths.font('pixel.otf'), 34, 0xFF00FF00, CENTER);
			crtArrowRight.setFormat(Paths.font('pixel.otf'), 34, 0xFF00FF00, CENTER);
			add(crtArrowLeft);
			add(crtArrowRight);
		}
		if (crtFront != null)
		{
			remove(crtFront, true);
			add(crtFront);
		}
	}

	function getCRTControlValue(raw:Array<Dynamic>):String
	{
		if (raw.length < 3) return '';
		if (onKeyboardMode)
		{
			var keys:Array<Null<FlxKey>> = ClientPrefs.keyBinds.get(raw[2]);
			if (keys == null) return '';
			return InputFormatter.getKeyName(keys[curAlt ? 1 : 0] != null ? keys[curAlt ? 1 : 0] : NONE);
		}
		var buttons:Array<Null<FlxGamepadInputID>> = ClientPrefs.gamepadBinds.get(raw[2]);
		if (buttons == null) return '';
		return InputFormatter.getGamepadName(buttons[curAlt ? 1 : 0] != null ? buttons[curAlt ? 1 : 0] : NONE);
	}

	function updateCRTControls():Void
	{
		if (!useOldMenuStyle || crtControlOptions == null) return;
		for (item in grpDisplay) if (item != null) item.visible = false;
		for (item in grpOptions) if (item != null) item.visible = false;
		for (item in grpBinds) if (item != null) item.visible = false;
		for (item in grpBlacks) if (item != null) item.visible = false;
		for (i in 0...crtControlOptions.length)
		{
			var y:Float = 110 + ((i - curSelected) * 85);
			crtControlOptions.members[i].y = y;
			crtControlValues.members[i].y = y;
			crtControlOptions.members[i].alpha = i == curSelected ? 1 : 0.45;
			crtControlValues.members[i].alpha = i == curSelected ? 1 : 0.45;
			crtControlValues.members[i].text = getCRTControlValue(options[curOptions[i]]);
		}
	}

	function addCenteredText(text:Alphabet, option:Array<Dynamic>, id:Int)
	{
		text.alignment = LEFT;
		text.screenCenter(X);
		text.y -= 55;
		text.startPosition.y -= 55;
	}
	function addKeyText(text:Alphabet, option:Array<Dynamic>, id:Int)
	{
		var keys:Array<Null<FlxKey>> = ClientPrefs.keyBinds.get(option[2]);
		if(keys == null && onKeyboardMode)
			keys = ClientPrefs.defaultKeys.get(option[2]).copy();

		var gmpds:Array<Null<FlxGamepadInputID>> = ClientPrefs.gamepadBinds.get(option[2]);
		if(gmpds == null && !onKeyboardMode)
			gmpds = ClientPrefs.defaultButtons.get(option[2]).copy();

		for (n in 0...2)
		{
			var key:String = null;
			if(onKeyboardMode)
				key = InputFormatter.getKeyName((keys[n] != null) ? keys[n] : NONE);
			else
				key = InputFormatter.getGamepadName((gmpds[n] != null) ? gmpds[n] : NONE);

			var attach:Alphabet = new Alphabet(560 + n * 300, 248, key, false);
			attach.isMenuItem = true;
			attach.changeX = false;
			attach.distancePerItem.y = 60;
			attach.targetY = text.targetY;
			attach.ID = Math.floor(grpBinds.length / 2);
			// Forzar letras blancas usando colorTransform
			for(letter in attach.letters) {
				if (letter != null) {
					letter.colorTransform.color = interfaceColor;
					letter.color = interfaceColor;
				}
			}
			attach.snapToPosition();
			attach.y += FlxG.height * 2;
			grpBinds.add(attach);

			playstationCheck(attach);
			attach.scaleX = Math.min(1, 230 / attach.width);
			//attach.text = key;

			// spawn black bars at the right of the key name
			var black:AttachedSprite = new AttachedSprite();
			black.makeGraphic(250, 78, FlxColor.BLACK);
			black.alphaMult = 0.4;
			black.sprTracker = text;
			black.yAdd = -6;
			black.xAdd = 75 + n * 300;
			grpBlacks.add(black);
		}
	}

	function playstationCheck(alpha:Alphabet)
	{
		if(onKeyboardMode) return;

		var gamepad:FlxGamepad = FlxG.gamepads.firstActive;
		var model:FlxGamepadModel = gamepad != null ? gamepad.detectedModel : UNKNOWN;
		var letter = alpha.letters[0];
		if(model == PS4)
		{
			switch(alpha.text)
			{
				case '[', ']': //Square and Triangle respectively
					letter.image = 'alphabet_playstation';
					letter.updateHitbox();
					
					letter.offset.x += 4;
					letter.offset.y -= 5;
			}
		}
	}

	function updateBind(num:Int, text:String)
	{
		var bind:Alphabet = grpBinds.members[num];
		var attach:Alphabet = new Alphabet(350 + (num % 2) * 300, 248, text, false);
		attach.isMenuItem = true;
		attach.changeX = false;
		attach.distancePerItem.y = 60;
		attach.targetY = bind.targetY;
		attach.ID = bind.ID;
		attach.x = bind.x;
		attach.y = bind.y;
		// Forzar letras blancas usando colorTransform
		for(letter in attach.letters) {
			if (letter != null) {
				letter.colorTransform.color = interfaceColor;
				letter.color = interfaceColor;
			}
		}
		
		playstationCheck(attach);
		attach.scaleX = Math.min(1, 230 / attach.width);
		//attach.text = text;

		bind.kill();
		grpBinds.remove(bind);
		grpBinds.insert(num, attach);
		bind.destroy();
	}

	var binding:Bool = false;
	var holdingEsc:Float = 0;
	var bindingBlack:FlxSprite;
	var bindingText:Alphabet;
	var bindingText2:Alphabet;

	var timeForMoving:Float = 0.1;
	override function update(elapsed:Float)
	{
		updateCRTControls();
		if(timeForMoving > 0) //Fix controller bug
		{
			timeForMoving = Math.max(0, timeForMoving - elapsed);
			super.update(elapsed);
			return;
		}

		if(!binding)
		{
			if(FlxG.keys.justPressed.ESCAPE || FlxG.gamepads.anyJustPressed(B))
			{
				close();
				return;
			}
			if(FlxG.keys.justPressed.CONTROL || FlxG.gamepads.anyJustPressed(LEFT_SHOULDER) || FlxG.gamepads.anyJustPressed(RIGHT_SHOULDER)) swapMode();

			if(FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.RIGHT || FlxG.gamepads.anyJustPressed(DPAD_LEFT) || FlxG.gamepads.anyJustPressed(DPAD_RIGHT) ||
				FlxG.gamepads.anyJustPressed(LEFT_STICK_DIGITAL_LEFT) || FlxG.gamepads.anyJustPressed(LEFT_STICK_DIGITAL_RIGHT)) updateAlt(true);

			if(FlxG.keys.justPressed.UP || FlxG.gamepads.anyJustPressed(DPAD_UP) || FlxG.gamepads.anyJustPressed(LEFT_STICK_DIGITAL_UP)) updateText(-1);
			else if(FlxG.keys.justPressed.DOWN || FlxG.gamepads.anyJustPressed(DPAD_DOWN) || FlxG.gamepads.anyJustPressed(LEFT_STICK_DIGITAL_DOWN)) updateText(1);

			if(FlxG.keys.justPressed.ENTER || FlxG.gamepads.anyJustPressed(START) || FlxG.gamepads.anyJustPressed(A))
			{
				if(options[curOptions[curSelected]][1] != defaultKey)
				{
					bindingBlack = new FlxSprite().makeGraphic(1, 1, /*FlxColor.BLACK*/ FlxColor.WHITE);
					bindingBlack.scale.set(FlxG.width, FlxG.height);
					bindingBlack.updateHitbox();
					bindingBlack.alpha = 0;
					FlxTween.tween(bindingBlack, {alpha: 0.6}, 0.35, {ease: FlxEase.linear});
					add(bindingBlack);

					bindingText = new Alphabet(FlxG.width / 2, 160, Language.getPhrase('controls_rebinding', 'Rebinding {1}', [options[curOptions[curSelected]][3]]), false);
					bindingText.alignment = CENTERED;
					// Forzar letras blancas usando colorTransform
					for(letter in bindingText.letters) {
						if (letter != null) {
							letter.colorTransform.color = interfaceColor;
							letter.color = interfaceColor;
						}
					}
					add(bindingText);
					
					bindingText2 = new Alphabet(FlxG.width / 2, 340, Language.getPhrase('controls_rebinding2', 'Hold ESC to Cancel\nHold Backspace to Delete'), true);
					bindingText2.alignment = CENTERED;
					// Forzar letras blancas usando colorTransform
					for(letter in bindingText2.letters) {
						if (letter != null) {
							letter.colorTransform.color = interfaceColor;
							letter.color = interfaceColor;
						}
					}
					add(bindingText2);

					binding = true;
					holdingEsc = 0;
					ClientPrefs.toggleVolumeKeys(false);
					FlxG.sound.play(Paths.sound('scrollMenu'));
				}
				else
				{
					// Reset to Default
					ClientPrefs.resetKeys(!onKeyboardMode);
					ClientPrefs.reloadVolumeKeys();
					var lastSel:Int = curSelected;
					createTexts();
					curSelected = lastSel;
					updateText();
					FlxG.sound.play(Paths.sound('cancelMenu'));
				}
			}
		}
		else
		{
			var altNum:Int = curAlt ? 1 : 0;
			var curOption:Array<Dynamic> = options[curOptions[curSelected]];
			if(FlxG.keys.pressed.ESCAPE || FlxG.gamepads.anyPressed(B))
			{
				holdingEsc += elapsed;
				if(holdingEsc > 0.5)
				{
					FlxG.sound.play(Paths.sound('cancelMenu'));
					closeBinding();
				}
			}
			else if (FlxG.keys.pressed.BACKSPACE || FlxG.gamepads.anyPressed(BACK))
			{
				holdingEsc += elapsed;
				if(holdingEsc > 0.5)
				{
					if (onKeyboardMode)
						ClientPrefs.keyBinds.get(curOption[2])[altNum] = NONE;
					else
						ClientPrefs.gamepadBinds.get(curOption[2])[altNum] = NONE;
					ClientPrefs.clearInvalidKeys(curOption[2]);
					updateBind(Math.floor(curSelected * 2) + altNum, onKeyboardMode ? InputFormatter.getKeyName(NONE) : InputFormatter.getGamepadName(NONE));
					FlxG.sound.play(Paths.sound('cancelMenu'));
					closeBinding();
				}
			}
			else
			{
				holdingEsc = 0;
				var changed:Bool = false;
				var curKeys:Array<FlxKey> = ClientPrefs.keyBinds.get(curOption[2]);
				var curButtons:Array<FlxGamepadInputID> = ClientPrefs.gamepadBinds.get(curOption[2]);

				if(onKeyboardMode)
				{
					if(FlxG.keys.justPressed.ANY || FlxG.keys.justReleased.ANY)
					{
						var keyPressed:Int = FlxG.keys.firstJustPressed();
						var keyReleased:Int = FlxG.keys.firstJustReleased();
						if (keyPressed > -1 && keyPressed != FlxKey.ESCAPE && keyPressed != FlxKey.BACKSPACE)
						{
							curKeys[altNum] = keyPressed;
							changed = true;
						}
						else if (keyReleased > -1 && (keyReleased == FlxKey.ESCAPE || keyReleased == FlxKey.BACKSPACE))
						{
							curKeys[altNum] = keyReleased;
							changed = true;
						}
					}
				}
				else if(FlxG.gamepads.anyJustPressed(ANY) || FlxG.gamepads.anyJustPressed(LEFT_TRIGGER) || FlxG.gamepads.anyJustPressed(RIGHT_TRIGGER) || FlxG.gamepads.anyJustReleased(ANY))
				{
					var keyPressed:Null<FlxGamepadInputID> = NONE;
					var keyReleased:Null<FlxGamepadInputID> = NONE;
					if(FlxG.gamepads.anyJustPressed(LEFT_TRIGGER)) keyPressed = LEFT_TRIGGER; //it wasnt working for some reason
					else if(FlxG.gamepads.anyJustPressed(RIGHT_TRIGGER)) keyPressed = RIGHT_TRIGGER; //it wasnt working for some reason
					else
					{
						for (i in 0...FlxG.gamepads.numActiveGamepads)
						{
							var gamepad:FlxGamepad = FlxG.gamepads.getByID(i);
							if(gamepad != null)
							{
								keyPressed = gamepad.firstJustPressedID();
								keyReleased = gamepad.firstJustReleasedID();

								if(keyPressed == null) keyPressed = NONE;
								if(keyReleased == null) keyReleased = NONE;
								if(keyPressed != NONE || keyReleased != NONE) break;
							}
						}
					}

					if (keyPressed != NONE && keyPressed != FlxGamepadInputID.BACK && keyPressed != FlxGamepadInputID.B)
					{
						curButtons[altNum] = keyPressed;
						changed = true;
					}
					else if (keyReleased != NONE && (keyReleased == FlxGamepadInputID.BACK || keyReleased == FlxGamepadInputID.B))
					{
						curButtons[altNum] = keyReleased;
						changed = true;
					}
				}

				if(changed)
				{
					if (onKeyboardMode)
					{
						if(curKeys[altNum] == curKeys[1 - altNum])
							curKeys[1 - altNum] = FlxKey.NONE;
					}
					else
					{
						if(curButtons[altNum] == curButtons[1 - altNum])
							curButtons[1 - altNum] = FlxGamepadInputID.NONE;
					}

					var option:String = options[curOptions[curSelected]][2];
					ClientPrefs.clearInvalidKeys(option);
					for (n in 0...2)
					{
						var key:String = null;
						if(onKeyboardMode)
						{
							var savKey:Array<Null<FlxKey>> = ClientPrefs.keyBinds.get(option);
							key = InputFormatter.getKeyName(savKey[n] != null ? savKey[n] : NONE);
						}
						else
						{
							var savKey:Array<Null<FlxGamepadInputID>> = ClientPrefs.gamepadBinds.get(option);
							key = InputFormatter.getGamepadName(savKey[n] != null ? savKey[n] : NONE);
						}
						updateBind(Math.floor(curSelected * 2) + n, key);
					}
					FlxG.sound.play(Paths.sound('confirmMenu'));
					closeBinding();
				}
			}
		}
		super.update(elapsed);
	}

	function closeBinding()
	{
		binding = false;
		bindingBlack.destroy();
		remove(bindingBlack);

		bindingText.destroy();
		remove(bindingText);

		bindingText2.destroy();
		remove(bindingText2);
		ClientPrefs.reloadVolumeKeys();
	}

	function updateText(?change:Int = 0)
	{
		curSelected = FlxMath.wrap(curSelected + change, 0, curOptions.length - 1);

		var num:Int = curOptionsValid[curSelected];
		var addNum:Int = 0;
		if(num < 3) addNum = 3 - num;
		else if(num > lastID - 4) addNum = (lastID - 4) - num;

		grpDisplay.forEachAlive(function(item:Alphabet) {
			item.targetY = item.ID - num - addNum;
		});

		grpOptions.forEachAlive(function(item:Alphabet)
		{
			item.targetY = item.ID - num - addNum;
			item.alpha = (item.ID - num == 0) ? 1 : 0.6;
		});
		grpBinds.forEachAlive(function(item:Alphabet)
		{
			var parent:Alphabet = grpOptions.members[item.ID];
			item.targetY = parent.targetY;
			item.alpha = parent.alpha;
		});

		updateAlt();
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function swapMode()
	{
		onKeyboardMode = !onKeyboardMode;

		curSelected = 0;
		curAlt = false;
		controllerSpr.animation.play(onKeyboardMode ? 'keyboard' : 'gamepad');
		createTexts();
	}
	
	function updateAlt(?doSwap:Bool = false)
	{
		if(doSwap)
		{
			curAlt = !curAlt;
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}
		selectSpr.sprTracker = grpBlacks.members[Math.floor(curSelected * 2) + (curAlt ? 1 : 0)];
		selectSpr.visible = (selectSpr.sprTracker != null);
	}

	function animateControlsEntry()
	{
		// Animar todas las opciones con entrada suave
		grpOptions.forEachAlive(function(item:Alphabet) {
			if (item != null) {
				// Calculamos la posición final basada en el targetY
				var finalY = (item.targetY * 1.3 * item.distancePerItem.y) + item.startPosition.y;
				
				// Animar desde abajo hacia la posición final
				FlxTween.tween(item, {y: finalY}, 1.2, {
					ease: FlxEase.backOut,
					startDelay: item.ID * 0.05 // Delay escalonado
				});
			}
		});

		// Animar textos de display
		grpDisplay.forEachAlive(function(item:Alphabet) {
			if (item != null) {
				var finalY = (item.targetY * 1.3 * item.distancePerItem.y) + item.startPosition.y;
				
				FlxTween.tween(item, {y: finalY}, 1.2, {
					ease: FlxEase.backOut,
					startDelay: item.ID * 0.05
				});
			}
		});

		// Animar binds
		grpBinds.forEachAlive(function(item:Alphabet) {
			if (item != null) {
				var finalY = (item.targetY * 1.3 * item.distancePerItem.y) + item.startPosition.y;
				
				FlxTween.tween(item, {y: finalY}, 1.2, {
					ease: FlxEase.backOut,
					startDelay: item.ID * 0.03
				});
			}
		});

		// Animar barras negras
		grpBlacks.forEachAlive(function(item:AttachedSprite) {
			if (item != null && item.sprTracker != null) {
				// Las barras siguen a su tracker, así que las animamos basándonos en el Alphabet tracker
				var tracker = item.sprTracker;
				if (Std.isOfType(tracker, Alphabet)) {
					var alphabetTracker = cast(tracker, Alphabet);
					var finalY = (alphabetTracker.targetY * 1.3 * alphabetTracker.distancePerItem.y) + alphabetTracker.startPosition.y;
					
					FlxTween.tween(item, {y: finalY + item.yAdd}, 1.2, {
						ease: FlxEase.backOut,
						startDelay: alphabetTracker.ID * 0.05 + 0.1
					});
				}
			}
		});
	}

	
}
