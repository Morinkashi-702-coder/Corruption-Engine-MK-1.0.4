package options;

import flixel.input.keyboard.FlxKey;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.text.FlxText.FlxTextAlign;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import objects.Alphabet;
import objects.CheckboxThingie;
import objects.AttachedText;
import options.Option;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxGlitchEffect;

/**
 * Base menu personalizada para VisualsSettings - Más simple que BaseOptionsMenu
 * Sin tracking automático de checkboxes, con control total y dev controls integrados
 */
class VisualsBaseMenu extends MusicBeatSubstate
{
	private var curOption:Option = null;
	private var curSelected:Int = 0;
	private var optionsArray:Array<Option>;

	private var grpOptions:FlxTypedGroup<Alphabet>;
	private var grpCheckboxes:FlxTypedGroup<CheckboxThingie>;
	private var grpTexts:FlxTypedGroup<AttachedText>;

	private var descBox:FlxSprite;
	private var descText:FlxText;
	private var crtSelectedBox:FlxSprite;
	private var crtOptions:FlxTypedGroup<FlxText>;
	private var crtValues:FlxTypedGroup<FlxText>;
	private var crtArrowLeft:FlxText;
	private var crtArrowRight:FlxText;
	public var descriptionXOffset:Float = -70;
	public var descriptionX:Null<Float> = null;
	public var descriptionY:Null<Float> = null;
	public var descriptionBoxXOffset:Float = -10;
	public var descriptionBoxYOffset:Float = -10;
	private var waitingForInputRelease:Bool = true;

	public var title:String;
	public var rpcTitle:String;
	public var useOldMenuStyle:Bool = false;

	// Dev controls para checkboxes - integrados desde el inicio
	private var checkboxDevMode:Bool = false;
	private var checkboxDevX:Float = 0;   // Offset horizontal (ajustado para centrarse)
	private var checkboxDevY:Float = 15;  // Offset vertical para centrar con el texto
	private var devText:FlxText;

	public function new(?oldMenuStyle:Null<Bool>)
	{
		super();
		useOldMenuStyle = oldMenuStyle != null ? oldMenuStyle : backend.MenuSelector.getMenu() == 'oldmenu';
		if (useOldMenuStyle)
		{
			FlxG.camera.target = null;
			FlxG.camera.scroll.set(0, 0);
			FlxG.camera.zoom = 1;
		}

		if (useOldMenuStyle)
		{
			var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menus/optionsMenu/optionsBack'));
			bg.antialiasing = ClientPrefs.data.antialiasing;
			bg.screenCenter();
			add(bg);

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

			var crtTitle:FlxText = new FlxText(0, 10, FlxG.width, title.toUpperCase(), 48);
			crtTitle.setFormat(Paths.font('pixel.otf'), 48, 0xFF00FF00, CENTER);
			add(crtTitle);
			add(new FlxSprite(80, 68).makeGraphic(FlxG.width - 160, 4, 0xFF00FF00));
			add(new FlxSprite(80, 75).makeGraphic(FlxG.width - 160, 2, 0xFF007700));
			crtSelectedBox = new FlxSprite(60, 100).makeGraphic(FlxG.width - 120, 100, 0xFF001100);
			crtSelectedBox.alpha = 0.7;
			add(crtSelectedBox);
		}
		
		optionsArray = [];
		grpOptions = new FlxTypedGroup<Alphabet>();
		grpCheckboxes = new FlxTypedGroup<CheckboxThingie>();
		grpTexts = new FlxTypedGroup<AttachedText>();
		
		add(grpOptions);
		add(grpCheckboxes);
		add(grpTexts);
		if (useOldMenuStyle)
		{
			crtOptions = new FlxTypedGroup<FlxText>();
			crtValues = new FlxTypedGroup<FlxText>();
			add(crtOptions);
			add(crtValues);
			crtArrowLeft = new FlxText(82, 125, 60, '>', 34);
			crtArrowRight = new FlxText(FlxG.width - 142, 125, 60, '<', 34);
			crtArrowLeft.setFormat(Paths.font('pixel.otf'), 34, 0xFF00FF00, CENTER);
			crtArrowRight.setFormat(Paths.font('pixel.otf'), 34, 0xFF00FF00, CENTER);
			add(crtArrowLeft);
			add(crtArrowRight);
		}

		// Setup básico de descripción
		if (useOldMenuStyle)
		{
			descBox = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
			descBox.alpha = 0.6;
			add(descBox);
			descText = new FlxText(0, 0, 900, '', 32);
			descText.setFormat(Paths.font('pixel.otf'), 32, 0xFF00FF00, CENTER);
			descText.scrollFactor.set();
			add(descText);
		}
		else
		{
			var descriptionPanel = new OptionsDescriptionPanel();
			descBox = descriptionPanel.background;
			descText = descriptionPanel.label;
			add(descriptionPanel);
		}

		// Dev text para checkboxes
		devText = new FlxText(10, FlxG.height - 100, 500, "");
		devText.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, LEFT);
		devText.scrollFactor.set();
		devText.visible = false;
		add(devText);

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end
		
		// Asegurar que curSelected empiece en 0
		curSelected = 0;
	}

	public function addOption(option:Option) {
		if(optionsArray == null || grpOptions == null) return;

		optionsArray.push(option);

		// Posiciones iguales a BaseOptionsMenu para consistencia visual
		var idx = optionsArray.length - 1;
		var finalY:Float = useOldMenuStyle ? 110 + (idx * 85) : -23 + (idx * 156);
		var startY:Float = finalY + (FlxG.height * 0.8);

		var optionText:Alphabet = new Alphabet(522, startY, option.name, true);
		optionText.isMenuItem = true;
		optionText.changeY = false; // evitar animaciones internas
		optionText.targetY = idx;
		optionText.scrollFactor.set(1, 1);
		optionText.alpha = 1.0;
		optionText.color = useOldMenuStyle ? 0xFF00FF00 : FlxColor.WHITE;
		optionText.visible = true;
		grpOptions.add(optionText);
		if (useOldMenuStyle)
		{
			optionText.visible = false;
			var oldName:FlxText = new FlxText(-50, 110 + (idx * 85), FlxG.width, option.name, 36);
			oldName.setFormat(Paths.font('pixel.otf'), 36, 0xFF00FF00, CENTER);
			oldName.ID = idx;
			crtOptions.add(oldName);
			var oldValue:FlxText = new FlxText(-50, 110 + (idx * 85), FlxG.width - 200, getCRTValue(option), 32);
			oldValue.setFormat(Paths.font('pixel.otf'), 32, 0xFF00FF00, RIGHT);
			oldValue.ID = idx;
			crtValues.add(oldValue);
		}

		// Asignar el child para que Option tenga referencia al Alphabet
		option.child = optionText;

		if(option.type == BOOL) {
			var checkbox:CheckboxThingie = new CheckboxThingie(optionText.x - 105 + checkboxDevX, optionText.y + checkboxDevY, option.getValue() == true);
			checkbox.sprTracker = optionText;
			checkbox.ID = idx;
			checkbox.scrollFactor.set(1, 1);
			checkbox.visible = true;
			checkbox.alpha = 1.0;
			grpCheckboxes.add(checkbox);
			option.checkbox = checkbox;
		} else {
			// Inicializar curOption correctamente para STRING antes de mostrar
			if (option.type == STRING && option.options != null) {
				var currentVal = option.getValue();
				option.curOption = 0; // Default
				for(i in 0...option.options.length) {
					if(option.options[i] == currentVal) {
						option.curOption = i;
						break;
					}
				}
			}

			// Ajustar X similar a BaseOptionsMenu
			optionText.x -= 80;
			try { optionText.startPosition.x -= 80; } catch(e:Dynamic) {}
			optionText.color = useOldMenuStyle ? 0xFF00FF00 : FlxColor.WHITE;

			var displayValue:String = "";
			if (option.type == STRING && option.options != null && option.curOption < option.options.length) {
				displayValue = option.options[option.curOption];
			} else {
				displayValue = Std.string(option.getValue());
			}

			var valueText:AttachedText = new AttachedText(displayValue, optionText.width + 60, 0, true);
			valueText.sprTracker = optionText;
			valueText.copyAlpha = true;
			valueText.ID = idx;
			valueText.color = useOldMenuStyle ? 0xFF00FF00 : FlxColor.WHITE;
			grpTexts.add(valueText);
			option.child = valueText;
		}

		// Mantener posiciones iguales a BaseOptionsMenu
		updateCheckboxPositions();
		updateDisplay();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		// Actualizar animaciones del Alphabet
		for (i in 0...grpOptions.length) {
			var item = grpOptions.members[i];
			if(item != null) {
				var lerpVal:Float = Math.exp(-elapsed * 9.6);
				var targetY:Float = useOldMenuStyle
					? 110 + (item.targetY * 85)
					: (FlxMath.remapToRange(item.targetY, 0, 1, 0, 1.3) * 120) + (FlxG.height * 0.48);
				item.y = FlxMath.lerp(item.y, targetY, 1 - lerpVal);
			}
		}
		if (useOldMenuStyle)
		{
			for (item in grpOptions) if (item != null) item.visible = false;
			for (item in grpCheckboxes) if (item != null) item.visible = false;
			for (item in grpTexts) if (item != null) item.visible = false;
			for (i in 0...crtOptions.length)
			{
				var y:Float = 110 + ((i - curSelected) * 85);
				crtOptions.members[i].y = y;
				crtValues.members[i].y = y;
				crtOptions.members[i].alpha = i == curSelected ? 1 : 0.45;
				crtValues.members[i].alpha = i == curSelected ? 1 : 0.45;
				crtValues.members[i].text = getCRTValue(optionsArray[i]);
			}
		}

		// Dev controls para checkboxes (F4 para toggle)
		if (FlxG.keys.justPressed.F4) {
			checkboxDevMode = !checkboxDevMode;
			devText.visible = checkboxDevMode;
			if (!checkboxDevMode) devText.text = "";
			else updateDevText();
		}

		if (checkboxDevMode) {
			var moveSpeed:Float = FlxG.keys.pressed.SHIFT ? 5.0 : 1.0;
			
			if (FlxG.keys.pressed.W) checkboxDevY -= moveSpeed;
			if (FlxG.keys.pressed.S) checkboxDevY += moveSpeed;
			if (FlxG.keys.pressed.A) checkboxDevX -= moveSpeed;
			if (FlxG.keys.pressed.D) checkboxDevX += moveSpeed;
			
			if (FlxG.keys.pressed.W || FlxG.keys.pressed.S || FlxG.keys.pressed.A || FlxG.keys.pressed.D) {
				updateCheckboxPositions();
				updateDevText();
			}
		}

		// Evita que el Enter usado para abrir este submenú cambie inmediatamente
		// la primera opción (Note Skin) en su primer frame.
		if (waitingForInputRelease)
		{
			if (!controls.ACCEPT && !controls.UI_UP && !controls.UI_DOWN && !controls.UI_LEFT && !controls.UI_RIGHT)
				waitingForInputRelease = false;
			return;
		}

		// Navegación básica
		if (controls.UI_UP_P) changeSelection(-1);
		if (controls.UI_DOWN_P) changeSelection(1);

		if (controls.BACK) {
			ClientPrefs.saveSettings();
			FlxG.sound.play(Paths.sound('cancelMenu'));
			close();
		}

		if (controls.ACCEPT) {
			FlxG.sound.play(Paths.sound('scrollMenu'));
			changeOption(1);
		}

		if (controls.UI_LEFT_P)
			changeOption(-1);
		else if (controls.UI_RIGHT_P)
			changeOption(1);
	}

	function changeSelection(change:Int = 0) {
		if (optionsArray == null || optionsArray.length < 1) return;
		
		curSelected += change;
		if (curSelected < 0) curSelected = optionsArray.length - 1;
		if (curSelected >= optionsArray.length) curSelected = 0;

		curOption = optionsArray[curSelected];

		// Update visual selection - Mejorar animación del Alphabet
		for (i in 0...grpOptions.length) {
			var item = grpOptions.members[i];
			item.targetY = i - curSelected;
			item.alpha = (i == curSelected) ? 1 : 0.6;
			item.color = useOldMenuStyle ? (i == curSelected ? 0xFF00FF00 : 0xFF007700) : FlxColor.WHITE;
			
			// Forzar actualización de posición
			var targetY:Float = useOldMenuStyle ? 110 + (item.targetY * 85) : FlxG.height * 0.48 + (item.targetY * 120);
			if(Math.abs(item.y - targetY) > 10) {
				item.y = FlxMath.lerp(item.y, targetY, 0.17);
			}
		}

		// Update description
		if (curOption != null) {
			descText.text = curOption.description;
			if (!useOldMenuStyle) return; // Modern panel stays fixed in its own screen-space camera.
			descText.screenCenter(X);
			descText.x = descriptionX != null ? descriptionX : descText.x + descriptionXOffset;
			descText.y = descriptionY != null ? descriptionY : FlxG.height - descText.height - 20;
			
			descBox.setPosition(descText.x + descriptionBoxXOffset, descText.y + descriptionBoxYOffset);
			descBox.setGraphicSize(Std.int(descText.width + 20), Std.int(descText.height + 25));
			descBox.updateHitbox();
		}
	}

	function changeOption(direction:Int = 0) {
		if (curOption == null) return;
		if (curOption.type != BOOL && direction == 0) direction = 1;

		switch(curOption.type) {
			case ACTION:
				return; // Diagnostic actions are handled by BaseOptionsMenu, not Visuals.
			case BOOL:
				if (curOption.checkbox != null) {
					curOption.setValue(!curOption.getValue());
					curOption.checkbox.daValue = curOption.getValue();
				}
			case STRING:
				var num:Int = curOption.curOption;
				num += direction;
				if (num < 0) num = curOption.options.length - 1;
				else if (num >= curOption.options.length) num = 0;
				
				curOption.curOption = num;
				curOption.setValue(curOption.options[num]);
			
			case INT, FLOAT, PERCENT:
				var holdValue:Float = curOption.getValue() + (direction * curOption.changeValue);
				if (curOption.minValue != null && holdValue < cast(curOption.minValue, Float)) holdValue = cast(curOption.minValue, Float);
				else if (curOption.maxValue != null && holdValue > cast(curOption.maxValue, Float)) holdValue = cast(curOption.maxValue, Float);
				
				if (curOption.type == INT) holdValue = Math.round(holdValue);
				curOption.setValue(holdValue);
				
			case KEYBIND:
				// No hacer nada por ahora, los keybinds requieren lógica especial
		}

		updateDisplay();
		if (curOption.onChange != null) curOption.onChange();
		trace('[Visuals] ${curOption.variable} = ${Std.string(curOption.getValue())}');
	}

	function updateDisplay() {
		if (curOption == null) return;

		switch(curOption.type) {
			case BOOL:
				// Los checkboxes se actualizan automáticamente
			
			case STRING:
				if (curOption.child != null) {
					curOption.child.text = curOption.options[curOption.curOption];
				}
				
			default:
				if (curOption.child != null) {
					curOption.child.text = getDisplayValue(curOption);
				}
		}
		refreshCRTValues();
	}

	function getCRTValue(option:Option):String
	{
		if (option.type == BOOL) return option.getValue() == true ? 'ON' : 'OFF';
		return getDisplayValue(option);
	}

	function refreshCRTValues():Void
	{
		if (!useOldMenuStyle || crtValues == null) return;
		for (i in 0...crtValues.length)
			if (i < optionsArray.length && crtValues.members[i] != null)
				crtValues.members[i].text = getCRTValue(optionsArray[i]);
	}

	public function updateAllOptions() {
		for (i in 0...optionsArray.length) {
			var option = optionsArray[i];
			if (option != null) {
				switch(option.type) {
					case STRING:
						if (option.child != null) {
							option.child.text = option.options[option.curOption];
						}
					case BOOL:
						if (option.checkbox != null) {
							option.checkbox.daValue = option.getValue();
						}
					default:
						if (option.child != null) {
							option.child.text = getDisplayValue(option);
						}
				}
			}
		}
	}

	function getDisplayValue(option:Option):String
	{
		var value:String;
		if (option.type == PERCENT)
			value = Std.string(Math.round(cast(option.getValue(), Float) * 100));
		else
			value = Std.string(option.getValue());

		return option.displayFormat.replace('%v', value).replace('%d', Std.string(option.defaultValue));
	}

	function updateCheckboxPositions() {
		for (i in 0...grpCheckboxes.length) {
			var checkbox = grpCheckboxes.members[i];
			if (checkbox != null && i < grpOptions.length) {
				var option = grpOptions.members[i];
				checkbox.setPosition(
					option.x - 105 + checkboxDevX,
					option.y + checkboxDevY
				);
			}
		}
	}

	function updateDevText() {
		if (devText == null) return;
		devText.text = 'CHECKBOX DEV MODE (F4)\nX: ${FlxMath.roundDecimal(checkboxDevX, 1)} | Y: ${FlxMath.roundDecimal(checkboxDevY, 1)}\n(WASD: move  SHIFT: fast)\nPress F4 to exit';
	}

	override function destroy() {
		ClientPrefs.saveSettings();
		super.destroy();
	}
}
