package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import openfl.display.BlendMode;

class NoticesState extends MusicBeatState
{
    var curInfo:Int = 0;
    var infoCard:FlxSpriteGroup;
    var canSelect:Bool = true;
    var canMove:Bool = false;
    var curSelected:Int = 1;

    var camFollow:FlxSprite;
    var camFollowPos:FlxObject;

    var chains:FlxSprite;
    var thankYou:FlxSprite;
    var thumb:FlxSprite;
    var takesPlace:FlxSprite;
    var takeMe:FlxSprite;
    var ignore:FlxSprite;
    
    var menuHintText:FlxText;
    var menuHintBg:FlxSprite;
    var hintPulseTween:FlxTween;
    
    var moveTween:FlxTween;
    var textTween:FlxTween;
    var alphaTween:FlxTween;
    
    var burnTransition:FlxSprite;

    override public function create()
    {
        super.create();

		// NoticesState es una pantalla silenciosa. Limpiar cualquier musica que
		// haya sobrevivido al state anterior evita que el tema del titulo o del
		// menu antiguo se filtre durante los avisos.
		if (FlxG.sound.music != null)
		{
			FlxTween.cancelTweensOf(FlxG.sound.music);
			FlxG.sound.music.stop();
		}

        persistentUpdate = true;
        persistentDraw = true;

        // NOTE: Removed ClientPrefs.loadPrefs() to prevent overwriting saved settings
        
        // Camera setup
        camFollow = new FlxSprite().makeGraphic(1, 1, 0xFF000000);
        camFollow.alpha = 0;
        camFollow.setPosition(951, 570);
        camFollowPos = new FlxObject(951, -270, 1, 1);
        add(camFollow);
        add(camFollowPos);

        FlxG.camera.zoom = 0.593;
        FlxG.camera.follow(camFollowPos, null, 1);

        FlxG.mouse.visible = false;
        FlxG.camera.bgColor = 0xFF000000;

        chains = new FlxSprite(-370, -120, Paths.image('chains'));
        chains.scrollFactor.set(0,0);
        chains.scale.set(1.7,1.7);
        chains.alpha = 0.4;
        add(chains);

        thankYou = new FlxSprite(0,0, Paths.image('thankYou'));
        thankYou.scrollFactor.set(0,0);
        thankYou.scale.set(1.7,1.7);
        thankYou.alpha = 0;
        add(thankYou);

        ignore = new FlxSprite(0,0, Paths.image('ignore'));
        ignore.scrollFactor.set(0,0);
        ignore.scale.set(1.65,1.65);
        ignore.alpha = 0;
        add(ignore);

        takeMe = new FlxSprite(0,0, Paths.image('takeMe'));
        takeMe.scrollFactor.set(0,0);
        takeMe.scale.set(1.65,1.65);
        takeMe.alpha = 0;
        add(takeMe);

        takesPlace = new FlxSprite(0,0, Paths.image('takesPlace'));
        takesPlace.scrollFactor.set(0,0);
        takesPlace.scale.set(1.7,1.7);
        takesPlace.alpha = 0;
        add(takesPlace);

        thumb = new FlxSprite(0,0, Paths.image('thumb'));
        thumb.scrollFactor.set(0,0);
        thumb.scale.set(1.7,1.7);
        thumb.alpha = 0;
        add(thumb);

        // Agregar fondo semi-transparente con efecto tétrico (esquina inferior derecha)
        var bgWidth:Int = 320; // Ajustado para texto tamaño 20
        var bgHeight:Int = 40; // Ajustado
        // Mover 50px a la izquierda (460 - 50 = 410)
        menuHintBg = new FlxSprite(1280 - bgWidth - 5 + 410, 720 - bgHeight - 5);
        menuHintBg.makeGraphic(bgWidth, bgHeight, 0xFF1A0000); // Rojo muy oscuro
        menuHintBg.alpha = 0.8;
        menuHintBg.scrollFactor.set(0, 0);
        add(menuHintBg);

        // Texto tétrico con efecto inquietante - tamaño 20
        var textX:Float = 1280 - bgWidth - 5 + 410 + 10;
        var textY:Float = 720 - bgHeight - 5 + 10;
        menuHintText = new FlxText(textX, textY, bgWidth - 20, "Press [M] to change menu", 20); // Tamaño 20
        menuHintText.setFormat(Paths.font("vcr.ttf"), 20, 0xFFFF0000, RIGHT); // Rojo sin borde
        if (StartupSetupState.isNeeded())
            menuHintText.text = "Choose your menu after the notices";
        menuHintText.scrollFactor.set(0, 0);
        menuHintText.alpha = 0.9;
        add(menuHintText);

        // Animación tétrica: parpadeo inquietante (como algo que te observa)
        hintPulseTween = FlxTween.tween(menuHintText, {alpha: 0.3}, 1.2, {
            ease: FlxEase.sineInOut,
            type: FlxTweenType.PINGPONG
        });
        
        // Animación de color tétrica: rojo sangre a rojo oscuro
        FlxTween.color(menuHintText, 2.0, 0xFFFF0000, 0xFF8B0000, {
            ease: FlxEase.sineInOut,
            type: FlxTweenType.PINGPONG
        });
        
        // Pequeño temblor inquietante en el eje Y
        FlxTween.tween(menuHintText, {y: textY - 2}, 0.3, {
            ease: FlxEase.sineInOut,
            type: FlxTweenType.PINGPONG,
            startDelay: 0.1
        });
        
        // Crear burnt transition sprite - agrandado para cubrir toda la pantalla
        burnTransition = new FlxSprite(60, 0); // Movido 60px a la derecha
        burnTransition.frames = Paths.getSparrowAtlas('burnTransition');
        burnTransition.animation.addByPrefix("idle", 'burnTransition idle', 24, false);
        burnTransition.scrollFactor.set(0, 0);
        burnTransition.scale.set(4.0, 4.0); // Agrandado para cubrir toda la pantalla
        burnTransition.antialiasing = ClientPrefs.data.antialiasing;
        burnTransition.alpha = 0;
        // Sin blend mode para que use color blanco normal
        add(burnTransition);

        nextCard();
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);
        inputShit();
    }

    function inputShit()
    {
        if (!canSelect) return;

        // Saltar los avisos sin saltarse la configuración inicial pendiente.
        if (FlxG.keys.justPressed.ESCAPE)
        {
            FlxG.sound.play(Paths.sound('cancelMenu'));
            animateExitToMenu();
            return;
        }

        // Acceder a MenuPreviewState con M
        if (FlxG.keys.justPressed.M && !StartupSetupState.isNeeded())
        {
            // No reproducir confirmMenu aquí, se hace en animateExitToMenuPreview
            animateExitToMenuPreview();
            return;
        }

        if (FlxG.keys.justPressed.SPACE || FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.Z)
        {
            canSelect = false;
            FlxG.sound.play(Paths.sound('confirmMenu'));

            if (curInfo == 5)
            {
                if (curSelected == 1)
                    hideThumb();
                else
                {
                    // Abre un link, si tienes CoolUtil.browserLoad disponible
                    CoolUtil.browserLoad('https://youtu.be/kXgwi83JTXE?si=k4trGmz-052tfLZ8');
                    canSelect = true;
                }
            }
            else if (curInfo == 6)
                hideThankYou();
            else
                removeInfoCard();
        }

        if (!canMove) return;

        if (FlxG.keys.justPressed.RIGHT || FlxG.keys.justPressed.D)
        {
            FlxG.sound.play(Paths.sound('scrollMenu'));
            curSelected += 1;
            if (curSelected > 1) curSelected = 0;
            updateOption();
        }

        if (FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.A)
        {
            FlxG.sound.play(Paths.sound('scrollMenu'));
            curSelected -= 1;
            if (curSelected < 0) curSelected = 1;
            updateOption();
        }
    }

    function updateOption()
    {
        if (curSelected == 0)
        {
            takeMe.alpha = 1;
            takeMe.scale.set(1.7,1.7);

            ignore.alpha = 0.4;
            ignore.scale.set(1.65,1.65);
        }
        else
        {
            ignore.alpha = 1;
            ignore.scale.set(1.7,1.7);

            takeMe.alpha = 0.4;
            takeMe.scale.set(1.65,1.65);
        }
    }

    function createInfoCard(infoText:String, subInfoText:String)
    {
        if (infoCard != null)
            remove(infoCard);

        infoCard = new FlxSpriteGroup();
        add(infoCard);

        var infoSprite = new FlxSprite(290, -630, Paths.image('infoCard'));
        infoSprite.scrollFactor.set(0,0);
        infoSprite.scale.set(1,1);
        infoSprite.alpha = 0.8;
        infoCard.add(infoSprite);

        var mainText = new FlxText(441, -460, 1000, infoText, 16);
        mainText.setFormat(Paths.font("VollkornRegular-ZVJEZ.ttf"), 48, 0xFFFFFFFF, FlxTextAlign.CENTER);
        mainText.alpha = 1;
        infoCard.add(mainText);

        var subText = new FlxText(441, -140, 1000, subInfoText, 16);
        subText.setFormat(Paths.font("VollkornRegular-ZVJEZ.ttf"), 52, 0xFFCC5363, FlxTextAlign.CENTER);
        subText.alpha = 0;
        infoCard.add(subText);

        infoCard.x = -1610;
        infoCard.alpha = 0;
        
        moveTween = FlxTween.tween(infoCard, {x: 0, alpha: 1}, 0.2, {ease: FlxEase.sineOut});
        textTween = FlxTween.tween(subText, {alpha: 1}, 1, {ease: FlxEase.sineOut});
    }

    function removeInfoCard()
    {
        trace("[removeInfoCard] CALLED - infoCard.x = " + infoCard.x);
        
        if (moveTween != null)
            moveTween.cancel();

        if (textTween != null)
            textTween.cancel();

        trace("[removeInfoCard] Starting left bounce to -150");
        // Animación fluida con rebote: primero a la izquierda, luego a la derecha
        moveTween = FlxTween.tween(infoCard, {x: -150}, 0.2, {
            ease: FlxEase.cubeOut,
            onComplete: function(tween:FlxTween) {
                trace("[removeInfoCard] Left bounce complete! x = " + infoCard.x);
                trace("[removeInfoCard] Starting right slide to 1800");
                // Deslizar hacia la derecha con rebote hasta salir completamente
                moveTween = FlxTween.tween(infoCard, {x: 1800, alpha: 0}, 0.6, {
                    ease: FlxEase.backOut,
                    onComplete: function(tween:FlxTween) {
                        trace("[removeInfoCard] Right slide complete! Calling nextCard()");
                        nextCard();
                    }
                });
            }
        });
    }

    function nextCard()
    {
        new FlxTimer().start(1, function(tmr:FlxTimer)
        {
            canSelect = true;
            tmr.destroy();
        });

        switch (curInfo)
        {
            case 0:
                createInfoCard("\nThis game contains flashing imagery\nwhich may trigger epileptic seizures.", "I understand. →");
            case 1:
                createInfoCard("\nFriday Night Funkin' is property of\nThe Funkin' Crew Inc.\nAnd is presented by Newgrounds.", "I understand. →");
            case 2:
                createInfoCard("If you have a weaker PC or experience lag, check the Video options.\nLow Quality mode and Shaders OFF will help in most cases.", "I understand. →");
            case 3:
                createInfoCard("\n\nYOU ARE THE KEY.", "I understand. →");
            case 4:
                showThumb();
            case 5:
                showThankYou();
            default:
                goToMainMenu();
        }
        curInfo++;
    }

    function animateExitToMenu()
    {
        canSelect = false;
        // Fade out de la pantalla completa
        FlxTween.tween(FlxG.camera, {alpha: 0}, 0.5, {
            ease: FlxEase.sineOut,
            onComplete: function(tween:FlxTween) {
                goToMainMenu();
            }
        });
    }

    function animateExitToMenuPreview()
    {
        canSelect = false;
        trace("========================================");
        trace("[NoticesState → MenuPreviewState] TRANSITION STARTED");
        trace("[animateExitToMenuPreview] Starting animation");
        trace("[animateExitToMenuPreview] This should open the MENU SELECTOR");
        trace("========================================");
        
        // Reproducir sonidos
        FlxG.sound.play(Paths.sound('confirmMenu'));
        FlxG.sound.play(Paths.sound('water rush'));
        trace("[animateExitToMenuPreview] Sounds played: confirmMenu + water rush");
        
        // Animar el hint text con rebote
        if (menuHintText != null && menuHintBg != null)
        {
            trace("[animateExitToMenuPreview] Animating hint text");
            FlxTween.tween(menuHintBg, {x: menuHintBg.x - 150}, 0.2, {
                ease: FlxEase.cubeOut,
                onComplete: function(tween:FlxTween) {
                    FlxTween.tween(menuHintBg, {x: 1800, alpha: 0}, 0.6, {ease: FlxEase.backOut});
                }
            });
            
            FlxTween.tween(menuHintText, {x: menuHintText.x - 150}, 0.2, {
                ease: FlxEase.cubeOut,
                onComplete: function(tween:FlxTween) {
                    FlxTween.tween(menuHintText, {x: 1800, alpha: 0}, 0.6, {ease: FlxEase.backOut});
                }
            });
        }
        
        // Si hay una infoCard visible, animarla con rebote
        if (infoCard != null && infoCard.exists && infoCard.visible)
        {
            trace("[animateExitToMenuPreview] Animating infoCard");
            if (moveTween != null) moveTween.cancel();
            if (textTween != null) textTween.cancel();
            
            FlxTween.tween(infoCard, {x: -150}, 0.2, {
                ease: FlxEase.cubeOut,
                onComplete: function(tween:FlxTween) {
                    trace("[animateExitToMenuPreview] Left bounce complete, going right");
                    FlxTween.tween(infoCard, {x: 1800, alpha: 0}, 0.6, {
                        ease: FlxEase.backOut
                    });
                }
            });
        }
        
        // Burnt transition y zoom después de 0.75s
        new FlxTimer().start(0.75, function(tmr:FlxTimer) {
            trace("[animateExitToMenuPreview] Starting burnt transition and zoom");
            if (burnTransition != null)
            {
                burnTransition.alpha = 1;
                burnTransition.animation.play("idle", true);
                trace("[animateExitToMenuPreview] Burnt transition playing");
            }
            // Zoom acercándose al mismo tiempo que el burnt transition
            FlxTween.tween(FlxG.camera, {zoom: 1.5}, 0.95, {ease: FlxEase.sineIn});
        });
        
        // Cambiar de estado después de que termine el sonido water rush (~4-5 segundos)
        new FlxTimer().start(4.5, function(tmr2:FlxTimer) {
            trace("========================================");
            trace("[animateExitToMenuPreview] 4.5 seconds elapsed - switching state now");
            trace("[animateExitToMenuPreview] Switching to MenuPreviewState");
            trace("[animateExitToMenuPreview] Expected: Menu selector should appear");
            trace("========================================");
            MusicBeatState.switchState(new MenuPreviewState());
        });
    }

    function goToMainMenu()
    {
        if (StartupSetupState.isNeeded())
        {
            canSelect = false;
            MusicBeatState.switchState(new StartupSetupState());
            return;
        }
        // Inicializar MenuSelector desde gameData.ini
        backend.MenuSelector.init();
        
        var menu:String = backend.MenuSelector.getMenu();
        trace("[NoticesState] Going to menu: " + menu);

        // Usar MenuSelector para ir al menú correcto
        switch(menu)
        {
            case "oldmenu":
                trace("[NoticesState] Opening MenuDemoSempai");
                MusicBeatState.switchState(new TitleState_oldmenu());
            default:
                trace("[NoticesState] Opening SoftCodeMenuState");
                MusicBeatState.switchState(new SoftCodeMenuState());
        }
    }

    function showThankYou()
    {
        if (alphaTween != null)
            alphaTween.cancel();

        new FlxTimer().start(2, function(tmr)
        {
            if (canSelect)
                hideThankYou();
            tmr.destroy();
        });

        alphaTween = FlxTween.tween(thankYou, {alpha: 1}, 1, {ease: FlxEase.sineInOut});
    }

    function hideThankYou()
    {
        alphaTween = FlxTween.tween(thankYou, {alpha: 0}, 1, {
            ease: FlxEase.sineInOut,
            onComplete: function(tween:FlxTween) {
                goToMainMenu();
            }
        });
    }

    function showThumb()
    {
        if (alphaTween != null)
            alphaTween.cancel();

        new FlxTimer().start(1, function(tmr)
        {
            canMove = true;
            updateOption();
            tmr.destroy();
        });

        alphaTween = FlxTween.tween(takesPlace, {alpha: 1}, 1, {ease: FlxEase.sineInOut});
        FlxTween.tween(thumb, {alpha: 1}, 1, {ease: FlxEase.sineInOut});
        FlxTween.tween(takeMe, {alpha: 0.4}, 0.4, {ease: FlxEase.sineInOut});
        FlxTween.tween(ignore, {alpha: 0.4}, 0.5, {ease: FlxEase.sineInOut});
    }

    function hideThumb()
    {
        canMove = false;
        if (alphaTween != null)
            alphaTween.cancel();

        FlxTween.tween(chains, {alpha: 0}, 4, {ease: FlxEase.sineInOut});
        alphaTween = FlxTween.tween(takesPlace, {alpha: 0}, 1, {
            ease: FlxEase.sineInOut,
            onComplete: function(tween:FlxTween) {
                nextCard();
            }
        });
        FlxTween.tween(thumb, {alpha: 0}, 1, {ease: FlxEase.sineInOut});
        FlxTween.tween(takeMe, {alpha: 0}, 1, {ease: FlxEase.sineInOut});
        FlxTween.tween(ignore, {alpha: 0}, 1, {ease: FlxEase.sineInOut});
    }
}

