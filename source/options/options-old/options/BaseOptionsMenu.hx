package options;

import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.gamepad.FlxGamepadManager;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.text.FlxText;
import flixel.text.FlxText.FlxTextAlign;
// FlxTextBorderStyle not available in this build; using simple format instead
// import flixel.text.FlxTextBorderStyle; // REMOVED - Type not found error
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import objects.Alphabet;

import objects.CheckboxThingie;
import objects.CheckboxThingieCustom;
import objects.AttachedText;
import options.Option;
import backend.InputFormatter;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxGlitchEffect;

class BaseOptionsMenu extends MusicBeatSubstate
{
	private var curOption:Option = null;
	private var curSelected:Int = 0;
	private var lerpSelected:Float = 0; // Variable para lerp suave como FreeplayState
	private var optionsArray:Array<Option>;
	private var isAnimating:Bool = true;
	private var animationCompleted:Bool = false; // Nueva variable para controlar post-animación // Controlar animación de entrada
	private var lockCheckboxes:Bool = false; // Controlar si checkboxes siguen automáticamente a su sprTracker
	
	// Dev controls para posicionar checkboxes
	private var devModeCheckbox:Bool = false;
	private var checkboxDevX:Float = 25; // offsetX actual
	private var checkboxDevY:Float = -30; // offsetY actual
	private var devTextCheckbox:FlxText;

	private var grpOptions:FlxTypedGroup<Alphabet>;
	private var checkboxGroup:FlxTypedGroup<CheckboxThingieCustom>;
	private var grpTexts:FlxTypedGroup<AttachedText>;

	private var descBox:FlxSprite;
	private var descText:FlxText;

	public var title:String;
	public var rpcTitle:String;
	public var showBackground:Bool = true; // Variable para controlar si se muestra el fondo
	public var useCRTStyle:Bool = false;

	public var bg:FlxSprite;
	private var titleAlphabet:Alphabet; // promote title text for animations
	private var exiting:Bool = false;
	
	// Variables para animaciones tipo FreeplayState
	var _drawDistance:Int = 4; // Distancia de dibujado (cuántos elementos visibles)
	var _lastVisibles:Array<Int> = [];

	public function new(crtStyle:Bool = false)
	{
		super();
		// Debe fijarse dentro del constructor base, antes de crear camara y fondo.
		// Asignarlo desde una subclase antes de super() podia ser sobrescrito por
		// la inicializacion de este propio BaseOptionsMenu.
		useCRTStyle = crtStyle;

		if(title == null) title = 'Options';
		if(rpcTitle == null) rpcTitle = 'Options Menu';
		
		#if DISCORD_ALLOWED
		DiscordClient.changePresence(rpcTitle, null);
		#end

		// ===== CONFIGURACIÓN DE CÁMARA IGUAL A OPTIONSSTATE =====
		var camFollow = new FlxSprite().makeGraphic(1, 1, 0xFF000000);
		camFollow.alpha = 0;
		camFollow.setPosition(636, 392);
		var camFollowPos = new FlxObject(636, 392, 1, 1);
		add(camFollow);
		add(camFollowPos);

		FlxG.camera.zoom = useCRTStyle ? 1 : 0.593;
		FlxG.camera.follow(camFollowPos, null, 1);

		// ===== FONDO DE SIDESTORYMENUSTATE (solo si showBackground es true) =====
		var crtFront:FlxSprite = null;
		if (useCRTStyle)
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

			crtFront = new FlxSprite().loadGraphic(Paths.image('menus/optionsMenu/optionsFront'));
			crtFront.antialiasing = ClientPrefs.data.antialiasing;
			crtFront.screenCenter();
		}
		else if(showBackground) {
			bg = new FlxSprite().loadGraphic(Paths.image("menus/sidestory/gradient"));
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
		}

		// avoids lagspikes while scrolling through menus!
		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		grpTexts = new FlxTypedGroup<AttachedText>();
		add(grpTexts);

		checkboxGroup = new FlxTypedGroup<CheckboxThingieCustom>();
		add(checkboxGroup);

		// Cuadro explicativo removido temporalmente
		// descBox = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		// descBox.alpha = 0.6;
		// add(descBox);

		// Texto de descripción removido temporalmente
		// descText = new FlxText(50, 600, 1180, "", 32);
		// descText.setFormat(Paths.font("VollkornRegular-ZVJEZ.ttf"), 32, FlxColor.WHITE, CENTER);
		// descText.scrollFactor.set();
		// add(descText);

		for (i in 0...optionsArray.length)
		{
			// Crear opciones abajo pero VISIBLES
			var finalY = -23 + (i * 90); // Posición final donde debe estar
			var startY = finalY + (FlxG.height * 0.8); // Posición inicial abajo pero VISIBLE
			
			var optionText:Alphabet = new Alphabet(552, startY, optionsArray[i].name, true);
			optionText.isMenuItem = true;
			optionText.changeY = false; // DESACTIVAR animaciones internas para evitar interferencia
			optionText.targetY = i;
			optionText.scrollFactor.set(1, 1);
			optionText.alpha = 1.0; // Alpha completo desde el inicio
			optionText.color = useCRTStyle ? 0xFF00FF00 : FlxColor.WHITE;
			optionText.visible = true; // Forzar visibilidad
			grpOptions.add(optionText);

			if (optionsArray[i].type == BOOL)
			{
				var checkbox:CheckboxThingieCustom = new CheckboxThingieCustom(optionText.x - 105, optionText.y, optionsArray[i].getValue() == true);
				checkbox.sprTracker = optionText;
				checkbox.ID = i;
				checkbox.scrollFactor.set(1, 1);
				// Ajustes para alinear correctamente con el texto
				checkbox.offsetX = checkboxDevX; // Usar valores dev
				checkbox.offsetY = checkboxDevY; // Usar valores dev
				checkbox.visible = true; // Forzar visibilidad
				checkbox.alpha = 1.0; // Alpha completo
				checkbox.locked = lockCheckboxes; // Usar nuestra variable de control
				checkboxGroup.add(checkbox);
			}
			else
			{
				optionText.x -= 80;
				optionText.startPosition.x -= 80;
				optionText.color = useCRTStyle ? 0xFF00FF00 : FlxColor.WHITE;
				//optionText.xAdd -= 80;
				var valueText:AttachedText = new AttachedText('' + optionsArray[i].getValue(), optionText.width + 60, 0, true);
				valueText.sprTracker = optionText;
				valueText.copyAlpha = true;
				valueText.ID = i;
				valueText.color = useCRTStyle ? 0xFF00FF00 : FlxColor.WHITE;
				grpTexts.add(valueText);
				optionsArray[i].child = valueText;
			}
			//optionText.snapToPosition(); //Don't ignore me when i ask for not making a fucking pull request to uncomment this line ok
			updateTextFrom(optionsArray[i]);
		}

		changeSelection();
		reloadCheckboxes();
		
		// Inicializar lerpSelected para animaciones suaves
		lerpSelected = curSelected;
		
		// Aplicar color blanco a todos los textos después de crearlos
		new FlxTimer().start(0.1, function(tmr:FlxTimer) {
			applyWhiteColorToTexts();
		});
		
		// Crear texto dev para checkboxes (invisible por defecto)
		devTextCheckbox = new FlxText(8, FlxG.height - 80, 420, "");
		devTextCheckbox.setFormat(null, 14, 0xFFFFFFFF, "left");
		devTextCheckbox.scrollFactor.set(0, 0);
		devTextCheckbox.visible = false;
		add(devTextCheckbox);

		if (crtFront != null) add(crtFront);
		
		animateEntry();
	}

	public function addOption(option:Option) {
		if(optionsArray == null || optionsArray.length < 1) optionsArray = [];
		optionsArray.push(option);
		return option;
	}

	var nextAccept:Int = 5;
	var holdTime:Float = 0;
	var holdValue:Float = 0;

	var bindingKey:Bool = false;
	var holdingEsc:Float = 0;
	var bindingBlack:FlxSprite;
	var bindingText:Alphabet;
	var bindingText2:Alphabet;
	override function update(elapsed:Float)
	{
		super.update(elapsed);

		// Dev controls para checkboxes (F4 toggle) - DESACTIVADO para evitar conflicto con VisualsSettings
		/*
		if (FlxG.keys.justPressed.F4) {
			devModeCheckbox = !devModeCheckbox;
			devTextCheckbox.visible = devModeCheckbox;
			if (!devModeCheckbox) {
				devTextCheckbox.text = "";
				// Desbloquear checkboxes cuando salgamos del dev mode
				lockCheckboxTracking(false);
			} else {
				// Lockear checkboxes cuando entremos al dev mode
				lockCheckboxTracking(true);
				updateDevTextCheckbox();
			}
		}

		// Controls dev para mover checkboxes
		if (devModeCheckbox) {
			var moveSpeed:Float = FlxG.keys.pressed.SHIFT ? 5.0 : 1.0;
			
			if (FlxG.keys.pressed.I) checkboxDevY -= moveSpeed;
			if (FlxG.keys.pressed.K) checkboxDevY += moveSpeed;
			if (FlxG.keys.pressed.J) checkboxDevX -= moveSpeed;
			if (FlxG.keys.pressed.L) checkboxDevX += moveSpeed;
			
			// Actualizar todos los checkboxes con las nuevas coordenadas
			if (FlxG.keys.pressed.I || FlxG.keys.pressed.K || FlxG.keys.pressed.J || FlxG.keys.pressed.L) {
				// LOCKEAR checkboxes para que no sigan al sprTracker durante dev mode
				lockCheckboxTracking(true);
				updateAllCheckboxPositions();
				updateDevTextCheckbox();
			}
		}
		*/

		if(bindingKey)
		{
			bindingKeyUpdate(elapsed);
			return;
		}

		// Actualizar animaciones suaves tipo FreeplayState
		updateTexts(elapsed);
		
		// BLOQUEAR NAVEGACIÓN DURANTE ANIMACIONES
		if (isAnimating) {
			return; // No procesar más input hasta que termine la animación
		}

		if (controls.UI_UP_P)
		{
			changeSelection(-1);
		}
		if (controls.UI_DOWN_P)
		{
			changeSelection(1);
		}

		if (controls.BACK) {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			close();
		}

		if(nextAccept <= 0)
		{
			switch(curOption.type)
			{
				case BOOL:
					if(controls.ACCEPT)
					{
						FlxG.sound.play(Paths.sound('scrollMenu'));
						curOption.setValue((curOption.getValue() == true) ? false : true);
						curOption.change();
						reloadCheckboxes();
					}

				case KEYBIND:
					if(controls.ACCEPT)
					{
						bindingBlack = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);
						bindingBlack.scale.set(FlxG.width, FlxG.height);
						bindingBlack.updateHitbox();
						bindingBlack.alpha = 0;
						FlxTween.tween(bindingBlack, {alpha: 0.6}, 0.35, {ease: FlxEase.linear});
						add(bindingBlack);
	
						bindingText = new Alphabet(FlxG.width / 2, 160, Language.getPhrase('controls_rebinding', 'Rebinding {1}', [curOption.name]), false);
						bindingText.alignment = CENTERED;
						add(bindingText);
						
						bindingText2 = new Alphabet(FlxG.width / 2, 340, Language.getPhrase('controls_rebinding2', 'Hold ESC to Cancel\nHold Backspace to Delete'), true);
						bindingText2.alignment = CENTERED;
						add(bindingText2);
	
						bindingKey = true;
						holdingEsc = 0;
						ClientPrefs.toggleVolumeKeys(false);
						FlxG.sound.play(Paths.sound('scrollMenu'));
					}

				default:
					if(controls.UI_LEFT || controls.UI_RIGHT)
					{
						var pressed = (controls.UI_LEFT_P || controls.UI_RIGHT_P);
						if(holdTime > 0.5 || pressed)
						{
							if(pressed)
							{
								var add:Dynamic = null;
								if(curOption.type != STRING)
									add = controls.UI_LEFT ? -curOption.changeValue : curOption.changeValue;
		
								switch(curOption.type)
								{
									case INT, FLOAT, PERCENT:
										holdValue = curOption.getValue() + add;
										if(holdValue < curOption.minValue) holdValue = curOption.minValue;
										else if (holdValue > curOption.maxValue) holdValue = curOption.maxValue;
		
										if(curOption.type == INT)
										{
											holdValue = Math.round(holdValue);
											curOption.setValue(holdValue);
										}
										else
										{
											holdValue = FlxMath.roundDecimal(holdValue, curOption.decimals);
											curOption.setValue(holdValue);
										}
		
									case STRING:
										var num:Int = curOption.curOption; //lol
										if(controls.UI_LEFT_P) --num;
										else num++;
		
										if(num < 0)
											num = curOption.options.length - 1;
										else if(num >= curOption.options.length)
											num = 0;
		
										curOption.curOption = num;
										curOption.setValue(curOption.options[num]);
										//trace(curOption.options[num]);

									default:
								}
								updateTextFrom(curOption);
								curOption.change();
								FlxG.sound.play(Paths.sound('scrollMenu'));
							}
							else if(curOption.type != STRING)
							{
								holdValue += curOption.scrollSpeed * elapsed * (controls.UI_LEFT ? -1 : 1);
								if(holdValue < curOption.minValue) holdValue = curOption.minValue;
								else if (holdValue > curOption.maxValue) holdValue = curOption.maxValue;
		
								switch(curOption.type)
								{
									case INT:
										curOption.setValue(Math.round(holdValue));
									
									case PERCENT:
										curOption.setValue(FlxMath.roundDecimal(holdValue, curOption.decimals));

									default:
								}
								updateTextFrom(curOption);
								curOption.change();
							}
						}
		
						if(curOption.type != STRING)
							holdTime += elapsed;
					}
					else if(controls.UI_LEFT_R || controls.UI_RIGHT_R)
					{
						if(holdTime > 0.5) FlxG.sound.play(Paths.sound('scrollMenu'));
						holdTime = 0;
					}
			}

			if(controls.RESET)
			{
				var leOption:Option = optionsArray[curSelected];
				if(leOption.type != KEYBIND)
				{
					leOption.setValue(leOption.defaultValue);
					if(leOption.type != BOOL)
					{
						if(leOption.type == STRING) leOption.curOption = leOption.options.indexOf(leOption.getValue());
						updateTextFrom(leOption);
					}
				}
				else
				{
					leOption.setValue(!Controls.instance.controllerMode ? leOption.defaultKeys.keyboard : leOption.defaultKeys.gamepad);
					updateBind(leOption);
				}
				leOption.change();
				FlxG.sound.play(Paths.sound('cancelMenu'));
				reloadCheckboxes();
			}
		}

		if(nextAccept > 0) {
			nextAccept -= 1;
		}
	}

	function bindingKeyUpdate(elapsed:Float)
	{
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
				if (!controls.controllerMode) curOption.keys.keyboard = FlxKey.NONE; // Prefixed to avoid collision with FlxTextBorderStyle.NONE
				else curOption.keys.gamepad = FlxGamepadInputID.NONE; // Prefixed to avoid collision with FlxTextBorderStyle.NONE
				updateBind(!controls.controllerMode ? InputFormatter.getKeyName(NONE) : InputFormatter.getGamepadName(NONE));
				FlxG.sound.play(Paths.sound('cancelMenu'));
				closeBinding();
			}
		}
		else
		{
			holdingEsc = 0;
			var changed:Bool = false;
			if(!controls.controllerMode)
			{
				if(FlxG.keys.justPressed.ANY || FlxG.keys.justReleased.ANY)
				{
					var keyPressed:FlxKey = cast (FlxG.keys.firstJustPressed(), FlxKey);
					var keyReleased:FlxKey = cast (FlxG.keys.firstJustReleased(), FlxKey);

					if(keyPressed != NONE && keyPressed != ESCAPE && keyPressed != BACKSPACE)
					{
						changed = true;
						curOption.keys.keyboard = keyPressed;
					}
					else if(keyReleased != NONE && (keyReleased == ESCAPE || keyReleased == BACKSPACE))
					{
						changed = true;
						curOption.keys.keyboard = keyReleased;
					}
				}
			}
			else if(FlxG.gamepads.anyJustPressed(ANY) || FlxG.gamepads.anyJustPressed(LEFT_TRIGGER) || FlxG.gamepads.anyJustPressed(RIGHT_TRIGGER) || FlxG.gamepads.anyJustReleased(ANY))
			{
				var keyPressed:FlxGamepadInputID = NONE;
				var keyReleased:FlxGamepadInputID = NONE;
				if(FlxG.gamepads.anyJustPressed(LEFT_TRIGGER))
					keyPressed = LEFT_TRIGGER; //it wasnt working for some reason
				else if(FlxG.gamepads.anyJustPressed(RIGHT_TRIGGER))
					keyPressed = RIGHT_TRIGGER; //it wasnt working for some reason
				else
				{
					for (i in 0...FlxG.gamepads.numActiveGamepads)
					{
						var gamepad:FlxGamepad = FlxG.gamepads.getByID(i);
						if(gamepad != null)
						{
							keyPressed = gamepad.firstJustPressedID();
							keyReleased = gamepad.firstJustReleasedID();
							if(keyPressed != NONE || keyReleased != NONE) break;
						}
					}
				}

				if(keyPressed != NONE && keyPressed != FlxGamepadInputID.BACK && keyPressed != FlxGamepadInputID.B)
				{
					changed = true;
					curOption.keys.gamepad = keyPressed;
				}
				else if(keyReleased != NONE && (keyReleased == FlxGamepadInputID.BACK || keyReleased == FlxGamepadInputID.B))
				{
					changed = true;
					curOption.keys.gamepad = keyReleased;
				}
			}

			if(changed)
			{
				var key:String = null;
				if(!controls.controllerMode)
				{
					if(curOption.keys.keyboard == null) curOption.keys.keyboard = 'NONE';
					curOption.setValue(curOption.keys.keyboard);
					key = InputFormatter.getKeyName(FlxKey.fromString(curOption.keys.keyboard));
				}
				else
				{
					if(curOption.keys.gamepad == null) curOption.keys.gamepad = 'NONE';
					curOption.setValue(curOption.keys.gamepad);
					key = InputFormatter.getGamepadName(FlxGamepadInputID.fromString(curOption.keys.gamepad));
				}
				updateBind(key);
				FlxG.sound.play(Paths.sound('confirmMenu'));
				closeBinding();
			}
		}
	}

	// ================= TRANSITIONS =================
	function animateEntry()
	{
		// Bloquear checkboxes durante la animación
		lockCheckboxTracking(true);
		
		// Transición suave que no interfiere con el sistema de navegación
		for (i in 0...grpOptions.length)
		{
			var item = grpOptions.members[i];
			if (item != null)
			{
				// Posición final: donde deben estar
				var finalY = -23 + (i * 90);
				
				// Animar hacia la posición final con delay escalonado
				FlxTween.tween(item, {y: finalY}, 1.5, {
					ease: FlxEase.backOut,
					startDelay: i * 0.08, // Delay para que suban de forma escalonada
					onComplete: function(twn:FlxTween) {
						// Fijar la posición final y evitar movimientos adicionales
						item.y = finalY;
						// Cuando termine la animación, activar la separación suave
						if (i == grpOptions.length - 1) {
							// Solo cuando termine la última opción, iniciar separación
							animateSeparation(); // Nueva función para separar suavemente
						}
					}
				});
				
				// También animar checkbox correspondiente si existe
				if (i < checkboxGroup.length && checkboxGroup.members[i] != null) {
					var checkbox = checkboxGroup.members[i];
					var checkboxFinalY = finalY; // Misma Y que la opción
					FlxTween.tween(checkbox, {y: checkboxFinalY}, 1.5, {
						ease: FlxEase.backOut,
						startDelay: i * 0.08 // Mismo delay que la opción
					});
				}
			}
		}
	}

	function animateSeparation()
	{
		// Segunda fase: separar las opciones suavemente a su espaciado final
		for (i in 0...grpOptions.length) {
			var item = grpOptions.members[i];
			if (item != null) {
				// Usar EXACTAMENTE el mismo espaciado que FreeplayState: 120 * 1.3 = 156px
				var finalSeparatedY = -23 + (i * 156); // Separación idéntica a FreeplayState
				
				// MISMA suavidad que la entrada: FlxEase.backOut
				FlxTween.tween(item, {y: finalSeparatedY}, 1.0, {
					ease: FlxEase.backOut, // MISMA curva suave que la entrada
					startDelay: 0, // PUM - se activa inmediatamente
					onComplete: function(twn:FlxTween) {
					if (i == grpOptions.length - 1) {
						// Cuando termine la separación, marcar como completado y desbloquear checkboxes
						animationCompleted = true;
						isAnimating = false;
						lockCheckboxTracking(false); // Desbloquear checkboxes
						}
					}
				});
				
				// También animar checkbox correspondiente en la separación
				if (i < checkboxGroup.length && checkboxGroup.members[i] != null) {
					var checkbox = checkboxGroup.members[i];
					var checkboxFinalY = finalSeparatedY; // Misma Y que la opción
					FlxTween.tween(checkbox, {y: checkboxFinalY}, 1.0, {
						ease: FlxEase.backOut,
						startDelay: 0
					});
				}
			}
		}
	}

	function startExitAnimation()
	{
		if(exiting) return;
		exiting = true;
		var remaining:Int = members.length;
		for(m in members)
		{
			if(Std.isOfType(m, FlxSprite) || Std.isOfType(m, FlxText) || Std.isOfType(m, Alphabet))
			{
				var spr:Dynamic = m;
				FlxTween.tween(spr, {alpha: 0}, 0.3, {ease: FlxEase.quadIn, onComplete: function(_){
					remaining--;
					if(remaining <= 0) close();
				}});
			}
			else
			{
				remaining--;
				if(remaining <= 0) close();
			}
		}
	}

	override function close()
	{
		// GUARDAR PREFERENCIAS ANTES DE CERRAR
		trace('[BaseOptionsMenu] ============ SAVING SETTINGS ============');
		trace('[BaseOptionsMenu] Current shaderQuality: ' + ClientPrefs.data.shaderQuality);
		trace('[BaseOptionsMenu] Current noteSplashes: ' + ClientPrefs.data.noteSplashes);
		ClientPrefs.saveSettings();
		trace('[BaseOptionsMenu] Settings saved successfully!');
		trace('[BaseOptionsMenu] ========================================');
		super.close();
	}

	final MAX_KEYBIND_WIDTH = 320;
	function updateBind(?text:String = null, ?option:Option = null)
	{
		if(option == null) option = curOption;
		if(text == null)
		{
			text = option.getValue();
			if(text == null) text = 'NONE';

			if(!controls.controllerMode)
				text = InputFormatter.getKeyName(FlxKey.fromString(text));
			else
				text = InputFormatter.getGamepadName(FlxGamepadInputID.fromString(text));
		}

		var bind:AttachedText = cast option.child;
		var attach:AttachedText = new AttachedText(text, bind.offsetX, 0, true);
		attach.sprTracker = bind.sprTracker;
		attach.copyAlpha = true;
		attach.ID = bind.ID;
		playstationCheck(attach);
		attach.scaleX = Math.min(1, MAX_KEYBIND_WIDTH / attach.width);
		attach.x = bind.x;
		attach.y = bind.y;

		option.child = attach;
		grpTexts.insert(grpTexts.members.indexOf(bind), attach);
		grpTexts.remove(bind);
		bind.destroy();
	}

	function playstationCheck(alpha:Alphabet)
	{
		if(!controls.controllerMode) return;

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

	function closeBinding()
	{
		bindingKey = false;
		bindingBlack.destroy();
		remove(bindingBlack);

		bindingText.destroy();
		remove(bindingText);

		bindingText2.destroy();
		remove(bindingText2);
		ClientPrefs.toggleVolumeKeys(true);
	}

	function updateTextFrom(option:Option) {
		if(option.type == KEYBIND)
		{
			updateBind(option);
			return;
		}

		var text:String = option.displayFormat;
		var val:Dynamic = option.getValue();
		if(option.type == PERCENT) val *= 100;
		var def:Dynamic = option.defaultValue;
		option.text = text.replace('%v', val).replace('%d', def);
	}
	
	function changeSelection(change:Int = 0)
	{
		curSelected = FlxMath.wrap(curSelected + change, 0, optionsArray.length - 1);

		// Descripción removida temporalmente
		// descText.text = optionsArray[curSelected].description;
		// descText.screenCenter(Y);
		// descText.y += 270;

		// Animaciones más sutiles y fluidas tipo FreeplayState
		for (i in 0...grpOptions.members.length)
		{
			var text = grpOptions.members[i];
			if (text != null)
			{
				// Cancelar tweens anteriores
				FlxTween.cancelTweensOf(text);
				FlxTween.cancelTweensOf(text.scale);
				
				// Configurar valores objetivo más sutiles
				var targetAlpha:Float = 0.5; // Menos contraste que antes
				var targetScale:Float = 1.0;
				
				if (i == curSelected)
				{
					targetAlpha = 1;
					targetScale = 1.05; // Escala más sutil
				}
				else if (Math.abs(i - curSelected) == 1) // Opciones adyacentes
				{
					targetAlpha = 0.7; // Más visibles las opciones cercanas
					targetScale = 1.0;
				}
				
				// Aplicar animaciones más fluidas
				FlxTween.tween(text, {
					alpha: targetAlpha
				}, 0.15, {ease: FlxEase.circOut}); // Timing más rápido y suave
				
				FlxTween.tween(text.scale, {
					x: targetScale,
					y: targetScale
				}, 0.2, {ease: FlxEase.circOut});
			}
		}

		// Actualizar textos de valor con transiciones suaves
		for (text in grpTexts)
		{
			FlxTween.cancelTweensOf(text);
			var targetAlpha = (text.ID == curSelected) ? 1 : 0.6;
			FlxTween.tween(text, {alpha: targetAlpha}, 0.15, {ease: FlxEase.circOut});
		}

		// Actualización de descBox removida temporalmente
		// descBox.setPosition(descText.x - 10, descText.y - 10);
		// descBox.setGraphicSize(Std.int(descText.width + 20), Std.int(descText.height + 25));
		// descBox.updateHitbox();

		curOption = optionsArray[curSelected]; //shorter lol
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	// Función de animaciones suaves tipo FreeplayState
	public function updateTexts(elapsed:Float = 0.0)
	{
		// No hacer nada mientras está animando la entrada
		if (isAnimating) return;
		
		// Lerp suave para la selección actual
		lerpSelected = FlxMath.lerp(lerpSelected, curSelected, 1 - Math.exp(-elapsed * 9.6));

		// Mantener la opción seleccionada en la misma zona y desplazar suavemente
		// toda la lista. Antes, otro bloque restauraba una Y fija cada frame y
		// anulaba por completo este movimiento.
		for (i in 0...grpOptions.length)
		{
			var item:Alphabet = grpOptions.members[i];
			if (item != null)
			{
				item.targetY = i - curSelected;
				item.y = -23 + ((i - lerpSelected) * 156);
			}
		}
		
		// DESACTIVADO: Sistema de visibilidad problemático
		// Hacer que TODOS los elementos sean siempre visibles
		for (i in 0...grpOptions.length) {
			var item = grpOptions.members[i];
			if (item != null) {
				item.visible = item.active = true;
			}
		}
		
		for (i in 0...checkboxGroup.length) {
			var checkbox = checkboxGroup.members[i];
			if (checkbox != null) {
				checkbox.visible = true;
			}
		}
		
		grpTexts.forEachAlive(function(item:AttachedText) {
			item.visible = item.active = true;
		});
	}	function reloadCheckboxes()
	{
		for (checkbox in checkboxGroup)
		{
			checkbox.daValue = Std.string(optionsArray[checkbox.ID].getValue()) == 'true'; //Do not take off the Std.string() from this, it will break a thing in Mod Settings Menu
		}
	}

	// Función para controlar el lockeo de checkboxes durante animaciones
	function lockCheckboxTracking(lock:Bool)
	{
		lockCheckboxes = lock;
		for (checkbox in checkboxGroup)
		{
			checkbox.locked = lock;
		}
	}

	function applyWhiteColorToTexts()
	{
		// Aplicar color blanco a todas las opciones: asegurar que cada letra (AlphaCharacter) sea blanca
		grpOptions.forEachAlive(function(optionText:Alphabet) {
			if (optionText != null)
			{
				// Color en el grupo por compatibilidad
				optionText.color = useCRTStyle ? 0xFF00FF00 : FlxColor.WHITE;
				// Forzar color a cada letra individual
				for (letter in optionText.letters)
				{
					if (letter != null) letter.color = useCRTStyle ? 0xFF00FF00 : FlxColor.WHITE;
				}
			}
		});
		
		// Aplicar color blanco a todos los textos de valores (AttachedText hereda Alphabet)
		grpTexts.forEachAlive(function(valueText:AttachedText) {
			if (valueText != null)
			{
				valueText.color = useCRTStyle ? 0xFF00FF00 : FlxColor.WHITE;
				for (letter in valueText.letters)
				{
					if (letter != null) letter.color = useCRTStyle ? 0xFF00FF00 : FlxColor.WHITE;
				}
			}
		});
	}

	// Funciones dev para checkboxes
	function updateAllCheckboxPositions() {
		for (checkbox in checkboxGroup) {
			checkbox.offsetX = checkboxDevX;
			checkbox.offsetY = checkboxDevY;
			// Forzar posición directa cuando está locked
			if (checkbox.locked && checkbox.sprTracker != null) {
				checkbox.setPosition(
					checkbox.sprTracker.x - 130 + checkboxDevX, 
					checkbox.sprTracker.y + 30 + checkboxDevY
				);
			}
		}
	}

	function updateDevTextCheckbox() {
		if (devTextCheckbox == null) return;
		devTextCheckbox.text = 'CHECKBOX DEV MODE (F4)\nX: ${FlxMath.roundDecimal(checkboxDevX, 1)} | Y: ${FlxMath.roundDecimal(checkboxDevY, 1)}\n(IJKL: move  SHIFT: fast)\nPress F4 to exit';
	}
}
