package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import backend.MusicBeatState;
import backend.Paths;

/**
 * MenuPreviewState - NUEVO MENU SELECTOR
 * Pantalla de selección de menú con fondo animado
 */
class MenuPreviewState extends MusicBeatState
{
	var nullDemoPreview:FlxSprite;
	var sempaiDemoPreview:FlxSprite;
	var nullOverlay:FlxSprite;
	var sempaiOverlay:FlxSprite;
	var nullGlow:FlxSprite; // Glow para NullDemo
	var sempaiGlow:FlxSprite; // Glow para Sempai
	var newMenuText:FlxText;
	var oldMenuText:FlxText;
	var curSelected:Int = 0; // 0 = NullDemo, 1 = Sempai Demo
	var canSelect:Bool = false; // Bloqueado hasta que termine la animación de entrada
	var allowMouse:Bool = true; // Permitir interacción con mouse
	var timeNotMoving:Float = 0; // Tiempo sin movimiento del mouse
	
	// Variables para el efecto de pulse (respiración)
	var pulseTween:FlxTween;
	var glowPulseTween:FlxTween; // Pulse para el glow también

	override public function create():Void
	{
		super.create();

		trace("========================================");
		trace("[MenuPreviewState] STATE ENTERED SUCCESSFULLY");
		trace("[MenuPreviewState] Initializing new menu selector...");
		trace("========================================");

		// Fondo con gradiente animado - MÁS ILUMINADO
		var bg = Paths.loadImageSafe(new FlxSprite(), "menus/sidestory/gradient");
		bg.scrollFactor.set();
		bg.screenCenter();
		add(bg);
		bg.alpha = 0.9; // Aumentado de 0 a 0.9 para que inicie más brillante
		bg.scale.set(1.7, 1.7);
		FlxTween.tween(bg, {alpha: 1.0}, 10.0, {ease: FlxEase.sineInOut, type: FlxTween.PINGPONG}); // Pingpong entre 0.9 y 1.0

		// Cadenas decorativas (igual que SideStoryMenuState)
		var chains = Paths.loadImageSafe(new FlxSprite(), "menus/sidestory/chains");
		chains.scrollFactor.set();
		chains.screenCenter();
		chains.scale.set(1.7, 1.7);
		add(chains);

		// OVERLAY AZUL COMENTADO - No se usa por ahora
		// nullOverlay = new FlxSprite();
		// nullOverlay.makeGraphic(100, 100, FlxColor.BLUE);
		// nullOverlay.alpha = 0;
		// add(nullOverlay);

		// Imagen preview NullDemo (izquierda) - INICIA FUERA DE PANTALLA
		nullDemoPreview = new FlxSprite();
		Paths.loadImageSafe(nullDemoPreview, "menus/preview menus/Nulldemo");
		nullDemoPreview.setGraphicSize(Std.int(nullDemoPreview.width * 0.3));
		nullDemoPreview.updateHitbox();
		nullDemoPreview.x = FlxG.width * 0.25 - nullDemoPreview.width / 2;
		nullDemoPreview.y = FlxG.height / 2 - nullDemoPreview.height / 2;
		nullDemoPreview.alpha = 0;
		nullDemoPreview.y += 100; // Empieza más abajo

		// GLOW COMO COPIA DE LA IMAGEN - MÉTODO PROFESIONAL
		// Usa la imagen de fondo azul para el glow
		nullGlow = new FlxSprite();
		Paths.loadImageSafe(nullGlow, "menus/preview menus/azulxd"); // Optional glow; stays transparent if missing.
		nullGlow.setGraphicSize(Std.int(nullGlow.width * 0.3 * 1.15)); // 15% más grande para glow más visible
		nullGlow.updateHitbox();
		nullGlow.blend = flash.display.BlendMode.ADD; // Blend mode aditivo para glow brillante
		nullGlow.alpha = 0;
		nullGlow.x = nullDemoPreview.x - (nullGlow.width - nullDemoPreview.width) / 2; // Centrado
		nullGlow.y = nullDemoPreview.y - (nullGlow.height - nullDemoPreview.height) / 2; // Centrado
		add(nullGlow); // AGREGAR PRIMERO (detrás)
		add(nullDemoPreview); // Luego la imagen real (encima)

		// Texto "new menu" - INICIA FUERA DE PANTALLA
		newMenuText = new FlxText(0, nullDemoPreview.y + nullDemoPreview.height + 20, FlxG.width * 0.5, "new menu");
		newMenuText.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, CENTER);
		newMenuText.x = FlxG.width * 0.25 - newMenuText.width / 2;
		newMenuText.alpha = 0;
		newMenuText.y += 100;
		add(newMenuText);

		// OVERLAY AZUL SEMPAI COMENTADO - No se usa por ahora
		// sempaiOverlay = new FlxSprite();
		// sempaiOverlay.makeGraphic(100, 100, FlxColor.BLUE);
		// sempaiOverlay.alpha = 0;
		// add(sempaiOverlay);

		// Imagen preview Sempai Demo - INICIA FUERA DE PANTALLA
		sempaiDemoPreview = new FlxSprite();
		Paths.loadImageSafe(sempaiDemoPreview, "menus/preview menus/Sempai demo");
		sempaiDemoPreview.setGraphicSize(Std.int(sempaiDemoPreview.width * 0.3));
		sempaiDemoPreview.updateHitbox();
		sempaiDemoPreview.x = FlxG.width * 0.75 - sempaiDemoPreview.width / 2;
		sempaiDemoPreview.y = FlxG.height / 2 - sempaiDemoPreview.height / 2;
		sempaiDemoPreview.alpha = 0;
		sempaiDemoPreview.y += 100;

		// GLOW COMO COPIA DE LA IMAGEN - MÉTODO PROFESIONAL
		// Usa la imagen de fondo azul para el glow
		sempaiGlow = new FlxSprite();
		Paths.loadImageSafe(sempaiGlow, "menus/preview menus/azulxd"); // Optional glow; stays transparent if missing.
		sempaiGlow.setGraphicSize(Std.int(sempaiGlow.width * 0.3 * 1.15)); // 15% más grande
		sempaiGlow.updateHitbox();
		sempaiGlow.blend = flash.display.BlendMode.ADD; // Blend mode aditivo
		sempaiGlow.alpha = 0;
		sempaiGlow.x = sempaiDemoPreview.x - (sempaiGlow.width - sempaiDemoPreview.width) / 2;
		sempaiGlow.y = sempaiDemoPreview.y - (sempaiGlow.height - sempaiDemoPreview.height) / 2;
		add(sempaiGlow); // AGREGAR PRIMERO (detrás)
		add(sempaiDemoPreview); // Luego la imagen real (encima)

		// Texto "old menu" - INICIA FUERA DE PANTALLA
		oldMenuText = new FlxText(0, sempaiDemoPreview.y + sempaiDemoPreview.height + 20, FlxG.width * 0.5, "old menu");
		oldMenuText.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, CENTER);
		oldMenuText.x = FlxG.width * 0.75 - oldMenuText.width / 2;
		oldMenuText.alpha = 0;
		oldMenuText.y += 100;
		add(oldMenuText);

		// ANIMACIÓN DE ENTRADA STAGGERED (brutal!)
		playEntranceAnimation();

		// Iniciar animación de parpadeo para AMBOS overlays
		startBlinkAnimation();

		// Animaciones relajadas para imágenes y textos
		startRelaxAnimations();
	}

	function playEntranceAnimation():Void
	{
		var targetYNull = nullDemoPreview.y - 100;
		var targetYSempai = sempaiDemoPreview.y - 100;
		var targetYNullText = newMenuText.y - 100;
		var targetYSempaiText = oldMenuText.y - 100;
		// var targetYNullOverlay = nullOverlay.y - 100; // COMENTADO
		// var targetYSempaiOverlay = sempaiOverlay.y - 100; // COMENTADO

		// NullDemo entra primero (desde abajo con fade in + slide)
		FlxTween.tween(nullDemoPreview, {y: targetYNull, alpha: 1}, 0.6, {
			ease: FlxEase.backOut,
			startDelay: 0.2
		});
		// Glow sigue a la imagen
		FlxTween.tween(nullGlow, {y: targetYNull - (nullGlow.height - nullDemoPreview.height) / 2}, 0.6, {
			ease: FlxEase.backOut,
			startDelay: 0.2
		});

		// Texto NullDemo entra después
		FlxTween.tween(newMenuText, {y: targetYNullText, alpha: 1}, 0.5, {
			ease: FlxEase.backOut,
			startDelay: 0.4
		});

		// Sempai entra después (staggered)
		FlxTween.tween(sempaiDemoPreview, {y: targetYSempai, alpha: 1}, 0.6, {
			ease: FlxEase.backOut,
			startDelay: 0.6
		});
		// Glow sigue a la imagen
		FlxTween.tween(sempaiGlow, {y: targetYSempai - (sempaiGlow.height - sempaiDemoPreview.height) / 2}, 0.6, {
			ease: FlxEase.backOut,
			startDelay: 0.6
		});

		// Texto Sempai entra al final
		FlxTween.tween(oldMenuText, {y: targetYSempaiText, alpha: 1}, 0.5, {
			ease: FlxEase.backOut,
			startDelay: 0.8,
			onComplete: function(tween:FlxTween):Void
			{
				// Habilitar selección cuando termine la animación
				canSelect = true;
				// Activar el glow del seleccionado
				updateSelection();
			}
		});
	}

	function startRelaxAnimations():Void
	{
		// DESACTIVAR TODAS las animaciones automáticas de escala y flotación
		// Solo dejamos las animaciones controladas por la selección del usuario
		
		// NO hay animaciones de flotación para evitar que se agranden
		// NO hay animaciones de escala automáticas
		
		// Las animaciones solo se activarán cuando el usuario seleccione con LEFT/RIGHT
	}

	function startBlinkAnimation():Void
	{
		// Animar AMBOS glows al mismo tiempo con parpadeo de 5 segundos
		// Baja opacidad en 5 segundos, luego sube en otros 5 segundos
		
		// NullDemo glow
		FlxTween.tween(nullGlow, {alpha: 0.1}, 5.0, {
			ease: FlxEase.sineInOut,
			onComplete: function(tween:FlxTween):Void
			{
				FlxTween.tween(nullGlow, {alpha: 0.4}, 5.0, {
					ease: FlxEase.sineInOut,
					onComplete: function(tween:FlxTween):Void
					{
						// Repetir el ciclo solo para nullGlow
						startNullBlinkCycle();
					}
				});
			}
		});

		// Sempai glow - mismo ciclo
		FlxTween.tween(sempaiGlow, {alpha: 0.1}, 5.0, {
			ease: FlxEase.sineInOut,
			onComplete: function(tween:FlxTween):Void
			{
				FlxTween.tween(sempaiGlow, {alpha: 0.4}, 5.0, {
					ease: FlxEase.sineInOut,
					onComplete: function(tween:FlxTween):Void
					{
						// Repetir el ciclo solo para sempaiGlow
						startSempaiBlinkCycle();
					}
				});
			}
		});
	}

	function startNullBlinkCycle():Void
	{
		FlxTween.tween(nullGlow, {alpha: 0.1}, 5.0, {
			ease: FlxEase.sineInOut,
			onComplete: function(tween:FlxTween):Void
			{
				FlxTween.tween(nullGlow, {alpha: 0.4}, 5.0, {
					ease: FlxEase.sineInOut,
					onComplete: function(tween:FlxTween):Void
					{
						startNullBlinkCycle();
					}
				});
			}
		});
	}

	function startSempaiBlinkCycle():Void
	{
		FlxTween.tween(sempaiGlow, {alpha: 0.1}, 5.0, {
			ease: FlxEase.sineInOut,
			onComplete: function(tween:FlxTween):Void
			{
				FlxTween.tween(sempaiGlow, {alpha: 0.4}, 5.0, {
					ease: FlxEase.sineInOut,
					onComplete: function(tween:FlxTween):Void
					{
						startSempaiBlinkCycle();
					}
				});
			}
		});
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (!canSelect) return; // No permitir input hasta que termine entrada

		// ========== SOPORTE PARA MOUSE ==========
		if (allowMouse && ((FlxG.mouse.deltaScreenX != 0 && FlxG.mouse.deltaScreenY != 0) || FlxG.mouse.justPressed))
		{
			FlxG.mouse.visible = true;
			timeNotMoving = 0;
			
			// Detectar hover sobre NullDemo (new menu)
			if (FlxG.mouse.overlaps(nullDemoPreview) || FlxG.mouse.overlaps(newMenuText))
			{
				if (curSelected != 0)
				{
					curSelected = 0;
					FlxG.sound.play(Paths.sound('scrollMenu'));
					updateSelection();
				}
			}
			// Detectar hover sobre Sempai Demo (old menu)
			else if (FlxG.mouse.overlaps(sempaiDemoPreview) || FlxG.mouse.overlaps(oldMenuText))
			{
				if (curSelected != 1)
				{
					curSelected = 1;
					FlxG.sound.play(Paths.sound('scrollMenu'));
					updateSelection();
				}
			}
		}
		else
		{
			timeNotMoving += elapsed;
			if (timeNotMoving > 2) FlxG.mouse.visible = false;
		}

		// Cambiar selección con LEFT/RIGHT (teclado)
		if (FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.RIGHT)
		{
			curSelected = curSelected == 0 ? 1 : 0;
			FlxG.sound.play(Paths.sound('scrollMenu'));
			updateSelection();
		}

		// ENTER/SPACE para confirmar selección O MOUSE CLICK
		if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.SPACE || (FlxG.mouse.justPressed && allowMouse))
		{
			// Solo confirmar si el mouse está sobre alguna opción válida
			if (FlxG.mouse.justPressed)
			{
				if (FlxG.mouse.overlaps(nullDemoPreview) || FlxG.mouse.overlaps(newMenuText) || 
				    FlxG.mouse.overlaps(sempaiDemoPreview) || FlxG.mouse.overlaps(oldMenuText))
				{
					confirmSelection();
				}
			}
			else
			{
				confirmSelection();
			}
		}

		// ESC para volver
		if (FlxG.keys.justPressed.ESCAPE)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new NoticesState());
		}
	}

	function confirmSelection():Void
	{
		canSelect = false;
		allowMouse = false; // Desactivar mouse durante animación
		FlxG.mouse.visible = false;
		FlxG.sound.play(Paths.sound('confirmMenu'));
		
		// Cancelar los pulses para que no interfieran con la animación de confirmación
		if (pulseTween != null)
			pulseTween.cancel();
		if (glowPulseTween != null)
			glowPulseTween.cancel();

		var selectedPreview = (curSelected == 0) ? nullDemoPreview : sempaiDemoPreview;
		var selectedGlow = (curSelected == 0) ? nullGlow : sempaiGlow;
		var selectedText = (curSelected == 0) ? newMenuText : oldMenuText;
		
		var unselectedPreview = (curSelected == 0) ? sempaiDemoPreview : nullDemoPreview;
		var unselectedGlow = (curSelected == 0) ? sempaiGlow : nullGlow;
		var unselectedText = (curSelected == 0) ? oldMenuText : newMenuText;

		// ============================================
		// CONFIRMACIÓN BRUTAL - EFECTO AAA
		// 1. Flash brillante del glow
		// 2. Scale up grande con bounce (GLOW TAMBIÉN)
		// 3. Fade out todo mientras seleccionado se mueve arriba
		// 4. No seleccionado desaparece rápido
		// ============================================

		// PASO 1: FLASH BRILLANTE instantáneo (más corto y fuerte)
		selectedGlow.alpha = 1.0; // Flash máximo
		FlxTween.tween(selectedGlow, {alpha: 0}, 0.3, {ease: FlxEase.quadIn}); // Más rápido

		// PASO 2: SCALE UP BRUTAL con elastic/back out - IMAGEN Y GLOW juntos
		FlxTween.tween(selectedPreview.scale, {x: 0.5, y: 0.5}, 0.4, {
			ease: FlxEase.elasticOut,
			onComplete: function(tween:FlxTween):Void
			{
				// PASO 3: Mover hacia arriba mientras hace fade
				FlxTween.tween(selectedPreview, {y: selectedPreview.y - 50, alpha: 0}, 0.4, {
					ease: FlxEase.quadIn
				});
			}
		});
		
		// Glow hace el MISMO scale up
		FlxTween.tween(selectedGlow.scale, {x: 0.5 * 1.08, y: 0.5 * 1.08}, 0.4, {
			ease: FlxEase.elasticOut,
			onUpdate: function(tween:FlxTween):Void
			{
				// Mantener centrado
				selectedGlow.x = selectedPreview.x - (selectedGlow.width - selectedPreview.width) / 2;
				selectedGlow.y = selectedPreview.y - (selectedGlow.height - selectedPreview.height) / 2;
			}
		});

		// Texto seleccionado también crece y desaparece
		FlxTween.tween(selectedText.scale, {x: 1.3, y: 1.3}, 0.3, {ease: FlxEase.backOut});
		FlxTween.tween(selectedText, {alpha: 0}, 0.5, {ease: FlxEase.quadIn, startDelay: 0.3});

		// PASO 4: No seleccionado desaparece rápido (fade out inmediato)
		FlxTween.tween(unselectedPreview, {alpha: 0}, 0.3, {ease: FlxEase.quadIn});
		FlxTween.tween(unselectedGlow, {alpha: 0}, 0.2, {ease: FlxEase.quadIn});
		FlxTween.tween(unselectedText, {alpha: 0}, 0.25, {ease: FlxEase.quadIn});
		
		// PASO 5: Ir al menú después de 0.8 segundos (más tiempo para ver la animación)
		new flixel.util.FlxTimer().start(0.8, function(tmr:flixel.util.FlxTimer):Void
		{
			goToSelectedMenu();
		});
	}

	function goToSelectedMenu():Void
	{
		if (curSelected == 0)
		{
			// NullDemo / New Menu
			backend.MenuSelector.setMenu('NullDemo');
			trace("[MenuPreviewState] Going to SoftCodeMenuState (NullDemo)");
			MusicBeatState.switchState(new SoftCodeMenuState());
		}
		else
		{
			// Sempai Demo / Old Menu
			backend.MenuSelector.setMenu('Sempaidemo');
			trace("[MenuPreviewState] Going to MenuDemoSempai (Old Menu)");
			MusicBeatState.switchState(new TitleState_oldmenu());
		}
	}

	function updateSelection():Void
	{
		// ============================================
		// ANIMACIÓN BRUTAL DE SELECCIÓN
		// Seleccionado: CRECE + BRILLA + ALPHA 1.0 + PULSE
		// No seleccionado: SE OSCURECE + ACHICA + ALPHA 0.6
		// GLOW sigue el mismo comportamiento que la imagen PERO mantiene su tamaño base más grande
		// ============================================
		
		// Cancelar pulses anteriores
		if (pulseTween != null)
			pulseTween.cancel();
		if (glowPulseTween != null)
			glowPulseTween.cancel();
		
		if (curSelected == 0)
		{
			// ======= NULLDEMO SELECCIONADO (ACTIVO) =======
			// Imagen CRECE y se pone brillante
			FlxTween.cancelTweensOf(nullDemoPreview);
			FlxTween.cancelTweensOf(nullDemoPreview.scale);
			FlxTween.tween(nullDemoPreview, {alpha: 1.0}, 0.3, {ease: FlxEase.quadOut});
			FlxTween.tween(nullDemoPreview.scale, {x: 0.35, y: 0.35}, 0.3, {
				ease: FlxEase.backOut,
				onComplete: function(tween:FlxTween):Void
				{
					// Iniciar pulse después de que termine la animación inicial
					startPulseAnimation(nullDemoPreview, nullGlow);
				}
			});
			
			// Glow CRECE proporcionalmente (8% más grande que la imagen)
			FlxTween.cancelTweensOf(nullGlow);
			FlxTween.cancelTweensOf(nullGlow.scale);
			FlxTween.tween(nullGlow, {alpha: 0.7}, 0.3, {ease: FlxEase.quadOut}); // Alpha más fuerte
			FlxTween.tween(nullGlow.scale, {x: 0.35 * 1.08, y: 0.35 * 1.08}, 0.3, {
				ease: FlxEase.backOut,
				onUpdate: function(tween:FlxTween):Void
				{
					// Mantener glow centrado con la imagen
					nullGlow.x = nullDemoPreview.x - (nullGlow.width - nullDemoPreview.width) / 2;
					nullGlow.y = nullDemoPreview.y - (nullGlow.height - nullDemoPreview.height) / 2;
				}
			});
			
			// Texto crece más y se pone blanco brillante
			FlxTween.cancelTweensOf(newMenuText);
			FlxTween.cancelTweensOf(newMenuText.scale);
			FlxTween.tween(newMenuText, {alpha: 1.0}, 0.3, {ease: FlxEase.quadOut});
			FlxTween.tween(newMenuText.scale, {x: 1.15, y: 1.15}, 0.3, {ease: FlxEase.backOut});

			// ======= SEMPAI NO SELECCIONADO (OSCURO) =======
			// Imagen SE OSCURECE y achica
			FlxTween.cancelTweensOf(sempaiDemoPreview);
			FlxTween.cancelTweensOf(sempaiDemoPreview.scale);
			FlxTween.tween(sempaiDemoPreview, {alpha: 0.5}, 0.3, {ease: FlxEase.quadIn});
			FlxTween.tween(sempaiDemoPreview.scale, {x: 0.28, y: 0.28}, 0.3, {ease: FlxEase.quadIn});
			
			// Glow SE ACHICA y casi invisible
			FlxTween.cancelTweensOf(sempaiGlow);
			FlxTween.cancelTweensOf(sempaiGlow.scale);
			FlxTween.tween(sempaiGlow, {alpha: 0.1}, 0.2, {ease: FlxEase.quadIn}); // Muy tenue
			FlxTween.tween(sempaiGlow.scale, {x: 0.28 * 1.08, y: 0.28 * 1.08}, 0.3, {
				ease: FlxEase.quadIn,
				onUpdate: function(tween:FlxTween):Void
				{
					sempaiGlow.x = sempaiDemoPreview.x - (sempaiGlow.width - sempaiDemoPreview.width) / 2;
					sempaiGlow.y = sempaiDemoPreview.y - (sempaiGlow.height - sempaiDemoPreview.height) / 2;
				}
			});
			
			// Texto vuelve a normal y se oscurece
			FlxTween.cancelTweensOf(oldMenuText);
			FlxTween.cancelTweensOf(oldMenuText.scale);
			FlxTween.tween(oldMenuText, {alpha: 0.6}, 0.3, {ease: FlxEase.quadIn});
			FlxTween.tween(oldMenuText.scale, {x: 1.0, y: 1.0}, 0.3, {ease: FlxEase.quadIn});
		}
		else
		{
			// ======= SEMPAI SELECCIONADO (ACTIVO) =======
			// Imagen CRECE y se pone brillante
			FlxTween.cancelTweensOf(sempaiDemoPreview);
			FlxTween.cancelTweensOf(sempaiDemoPreview.scale);
			FlxTween.tween(sempaiDemoPreview, {alpha: 1.0}, 0.3, {ease: FlxEase.quadOut});
			FlxTween.tween(sempaiDemoPreview.scale, {x: 0.35, y: 0.35}, 0.3, {
				ease: FlxEase.backOut,
				onComplete: function(tween:FlxTween):Void
				{
					// Iniciar pulse después de que termine la animación inicial
					startPulseAnimation(sempaiDemoPreview, sempaiGlow);
				}
			});
			
			// Glow CRECE proporcionalmente (8% más grande)
			FlxTween.cancelTweensOf(sempaiGlow);
			FlxTween.cancelTweensOf(sempaiGlow.scale);
			FlxTween.tween(sempaiGlow, {alpha: 0.7}, 0.3, {ease: FlxEase.quadOut});
			FlxTween.tween(sempaiGlow.scale, {x: 0.35 * 1.08, y: 0.35 * 1.08}, 0.3, {
				ease: FlxEase.backOut,
				onUpdate: function(tween:FlxTween):Void
				{
					sempaiGlow.x = sempaiDemoPreview.x - (sempaiGlow.width - sempaiDemoPreview.width) / 2;
					sempaiGlow.y = sempaiDemoPreview.y - (sempaiGlow.height - sempaiDemoPreview.height) / 2;
				}
			});
			
			// Texto crece más y se pone blanco brillante
			FlxTween.cancelTweensOf(oldMenuText);
			FlxTween.cancelTweensOf(oldMenuText.scale);
			FlxTween.tween(oldMenuText, {alpha: 1.0}, 0.3, {ease: FlxEase.quadOut});
			FlxTween.tween(oldMenuText.scale, {x: 1.15, y: 1.15}, 0.3, {ease: FlxEase.backOut});

			// ======= NULLDEMO NO SELECCIONADO (OSCURO) =======
			// Imagen SE OSCURECE y achica
			FlxTween.cancelTweensOf(nullDemoPreview);
			FlxTween.cancelTweensOf(nullDemoPreview.scale);
			FlxTween.tween(nullDemoPreview, {alpha: 0.5}, 0.3, {ease: FlxEase.quadIn});
			FlxTween.tween(nullDemoPreview.scale, {x: 0.28, y: 0.28}, 0.3, {ease: FlxEase.quadIn});
			
			// Glow SE ACHICA y casi invisible
			FlxTween.cancelTweensOf(nullGlow);
			FlxTween.cancelTweensOf(nullGlow.scale);
			FlxTween.tween(nullGlow, {alpha: 0.1}, 0.2, {ease: FlxEase.quadIn});
			FlxTween.tween(nullGlow.scale, {x: 0.28 * 1.08, y: 0.28 * 1.08}, 0.3, {
				ease: FlxEase.quadIn,
				onUpdate: function(tween:FlxTween):Void
				{
					nullGlow.x = nullDemoPreview.x - (nullGlow.width - nullDemoPreview.width) / 2;
					nullGlow.y = nullDemoPreview.y - (nullGlow.height - nullDemoPreview.height) / 2;
				}
			});
			
			// Texto vuelve a normal y se oscurece
			FlxTween.cancelTweensOf(newMenuText);
			FlxTween.cancelTweensOf(newMenuText.scale);
			FlxTween.tween(newMenuText, {alpha: 0.6}, 0.3, {ease: FlxEase.quadIn});
			FlxTween.tween(newMenuText.scale, {x: 1.0, y: 1.0}, 0.3, {ease: FlxEase.quadIn});
		}
	}

	function startPulseAnimation(sprite:FlxSprite, glow:FlxSprite):Void
	{
		// Efecto de "respiración" suave - la imagen pulsa entre 0.35 y 0.36 (más sutil)
		pulseTween = FlxTween.tween(sprite.scale, {x: 0.36, y: 0.36}, 1.2, {
			ease: FlxEase.sineInOut,
			type: FlxTween.PINGPONG,
			loopDelay: 0
		});
		
		// El glow pulsa sincronizado (8% más grande que la imagen)
		glowPulseTween = FlxTween.tween(glow.scale, {x: 0.36 * 1.08, y: 0.36 * 1.08}, 1.2, {
			ease: FlxEase.sineInOut,
			type: FlxTween.PINGPONG,
			loopDelay: 0,
			onUpdate: function(tween:FlxTween):Void
			{
				// Mantener glow centrado durante el pulse
				glow.x = sprite.x - (glow.width - sprite.width) / 2;
				glow.y = sprite.y - (glow.height - sprite.height) / 2;
			}
		});
	}
}
