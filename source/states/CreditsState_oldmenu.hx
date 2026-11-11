package states;

#if desktop
import backend.Discord;
#end
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;
import flixel.text.FlxText.FlxTextAlign;
import states.LoadingState;

using StringTools;

class CreditsState_oldmenu extends MusicBeatState
{
    // Sprites y cámara
    var object:FlxSprite;
    var camFollow:FlxSprite;
    var camFollowPos:FlxObject;
    
    // Grupos
    var creditsText:Array<FlxText> = [];
    var curArrayText:Array<FlxText> = [];
    
    // Efectos visuales
    var selectArrow:FlxSprite;
    var arrowGhost:Array<FlxSprite> = [];
    
    // Fondos
    var bg:FlxSprite;
    var chains:FlxSprite;
    var blackTop:FlxSprite;
    
    // Variables de navegación
    var curSelected:Int = 0;
    var prevMenuCurSelected:Int = 0;
    var canSelect:Bool = false;
    
    // Variables de estado
    var layer:String = "section";
    var curArray:Array<{name:String, info:String, link:String}>;
    var allArrays:Array<Array<{name:String, info:String, link:String}>> = [];
    
    // Info y transiciones
    var infoText:FlxText;
    var infoTween:FlxTween;
    var blackTween:FlxTween;
    
    // Constantes
    var returnToMainSection:Array<String> = ["animations","general","if","memory","extra"];
    var corrSongs:Array<String> = ["nullandvoid", "chkdsk", "bloodlust", "accessdenied"];
    
    // Credits arrays
    var memoryCredits:Array<{name:String, info:String, link:String}>;
    var extraCredits:Array<{name:String, info:String, link:String}>;

    override function create()
    {
        #if desktop
        DiscordClient.changePresence("In the Credits Menu", null);
        #end

        persistentUpdate = true;
        persistentDraw = true;

        FlxG.mouse.visible = false;
        FlxG.camera.bgColor = FlxColor.BLACK;

        // Inicializar super.create() primero (que configura PsychCamera)
        super.create();

        // Configuración de cámara DESPUÉS de super.create()
        camFollow = new FlxSprite().makeGraphic(1, 1, 0xFF000000);
        camFollow.alpha = 0;
        camFollow.setPosition(951,570);
        camFollowPos = new FlxObject(951,-270, 1, 1);
        add(camFollow);
        add(camFollowPos);

        FlxG.camera.zoom = 0.593;
        FlxG.camera.follow(camFollowPos, LOCKON, 1);

        // Fondos
        bg = new FlxSprite().loadGraphic(Paths.image("menus/sidestory/gradient"));
        bg.scrollFactor.set();
        bg.screenCenter();
        add(bg);
        bg.setPosition(571,-109);
        bg.scale.set(0.8,2);
        bg.alpha = 0;
        bg.color = FlxColor.RED;
        
        FlxTween.tween(bg, {alpha: 0.4}, 8.0, {ease: FlxEase.sineInOut, type: FlxTween.PINGPONG});

        chains = new FlxSprite().loadGraphic(Paths.image("menus/sidestory/chains"));
        chains.scrollFactor.set();
        chains.screenCenter();
        chains.setPosition(561,120);
        chains.scale.set(0.9,1.4);
        add(chains);

        // Inicializar grupos
        creditsText = [];

        // Generar datos
        addCreditsToArray();
        curArray = allArrays[0];

        // Overlay negro
        blackTop = new FlxSprite(10,-20).loadGraphic(Paths.image('menus/mainmenu/fullBlack'));
        blackTop.scrollFactor.set(0,0);
        blackTop.scale.set(1.7,1.7);
        add(blackTop);

        // Flecha selectora
        // Crear flecha principal
        selectArrow = new FlxSprite(-40,-300).loadGraphic(Paths.image('menus/credits/arrow'));
        selectArrow.scrollFactor.set(1,1);
        selectArrow.scale.set(1,1);
        selectArrow.antialiasing = true;
        
        // Crear "fantasmas" de la flecha
        for (i in 0...4) {
            var ghost = new FlxSprite(-40,-300).loadGraphic(Paths.image('menus/credits/arrow'));
            ghost.scrollFactor.set(1,1);
            ghost.scale.set(1,1);
            ghost.antialiasing = true;
            ghost.alpha = 0.3 - (i * 0.07);
            arrowGhost.push(ghost);
            add(ghost);
        }
        
        add(selectArrow);

        // Texto info
        infoText = new FlxText(717,194, 1000, "", 65);
        infoText.setFormat(Paths.font("VollkornRegular-ZVJEZ.ttf"), 65, FlxColor.WHITE, CENTER);
        infoText.scrollFactor.set(0,0);
        infoText.alpha = 0.5;
        add(infoText);

        updateTexts();
        updateSelected();

        // Música
        FlxG.sound.playMusic(Paths.music('menu4'), 1);

        new FlxTimer().start(1, function(tmr) {
            canSelect = true;
        });
    }

    override function update(elapsed:Float)
    {
        if (!canSelect) return;

        var lerpVal:Float = Math.exp(-elapsed * 2.4 * 2);
        camFollowPos.setPosition(
            FlxMath.lerp(camFollow.x, camFollowPos.x, lerpVal),
            FlxMath.lerp(camFollow.y + 100, camFollowPos.y, lerpVal)
        );
        
        // Actualizar posición de los "fantasmas" de la flecha
        for (i in 0...arrowGhost.length) {
            var ghost = arrowGhost[i];
            var delay = (i + 1) * 0.05;
            ghost.x = selectArrow.x - (selectArrow.velocity.x * delay);
            ghost.y = selectArrow.y - (selectArrow.velocity.y * delay);
        }

        // Actualizar posición de elementos
        if (curArrayText != null && curArrayText.length > curSelected) {
            camFollow.y = curArrayText[curSelected].y;
            selectArrow.y = curArrayText[curSelected].y + 20;
        }

        // Input
        if (controls.ACCEPT)
            enter();
        
        if (controls.BACK)
            backOut();

        if (controls.UI_UP_P) // Cambiado a _P para "Pressed" en lugar de "Held"
        {
            FlxG.sound.play(Paths.sound('scrollMenu'));
            changeSelection(-1);
        }

        if (controls.UI_DOWN_P) // Cambiado a _P para "Pressed" en lugar de "Held"
        {
            FlxG.sound.play(Paths.sound('scrollMenu'));
            changeSelection(1);
        }

        super.update(elapsed);
    }

    var canChangeSelection:Bool = true;
    function changeSelection(change:Int = 0)
    {
        if (!canChangeSelection) return;
        
        curSelected += change;

        if (curSelected < 0)
            curSelected = curArray.length-1;
        if (curSelected >= curArray.length)
            curSelected = 0;

        // Añadir un pequeño cooldown entre selecciones
        canChangeSelection = false;
        new FlxTimer().start(0.1, function(tmr:FlxTimer) {
            canChangeSelection = true;
        });

        updateSelected();
    }

    function updateSelected()
    {
        if (infoTween != null)
            infoTween.cancel();

        infoText.alpha = 0;
        infoText.text = curArray[curSelected].info;
        infoTween = FlxTween.tween(infoText, {alpha: 0.5}, 0.5, {ease: FlxEase.sineOut});

        for (i in 0...curArrayText.length)
        {
            var text = curArrayText[i];
            if (text != null)
            {
                // Cancelar tweens anteriores
                FlxTween.cancelTweensOf(text);
                FlxTween.cancelTweensOf(text.scale);
                
                // Configurar valores objetivo
                var targetAlpha:Float = 0.1;
                var targetScale:Float = 0.95;
                var targetX:Float = -50;
                
                if (i == curSelected)
                {
                    targetAlpha = 1;
                    targetScale = 1.3;
                    targetX = 200;
                }
                else if ((i-1) == curSelected || (i+1) == curSelected)
                {
                    targetAlpha = 0.15;
                    targetScale = 1.0;
                    targetX = 0;
                }
                
                // Aplicar animaciones
                FlxTween.tween(text, {
                    x: targetX,
                    alpha: targetAlpha
                }, 0.3, {ease: FlxEase.sineOut});
                
                FlxTween.tween(text.scale, {
                    x: targetScale,
                    y: targetScale
                }, 0.3, {ease: FlxEase.sineOut});
            }
        }
    }

    function updateTexts()
    {
        if (creditsText != null && creditsText.length > 0)
        {
            for (text in creditsText)
                remove(text);
        }

        if (infoText != null)
            remove(infoText);

        creditsText = [];
        curArrayText = creditsText;

        if (blackTween != null)
            blackTween.cancel();

        blackTop.alpha = 1;
        blackTween = FlxTween.tween(blackTop, {alpha: 0}, 1.0, {ease: FlxEase.sineIn});

        var textOffsetY:Float = 0;
        for (i in 0...curArray.length)
        {
            var name = new FlxText(80, -320 + textOffsetY, 1000, curArray[i].name, 85);
            name.setFormat(Paths.font("VollkornRegular-ZVJEZ.ttf"), 85, FlxColor.WHITE, LEFT);
            name.scrollFactor.set(1,1);
            name.antialiasing = true;
            creditsText.push(name);
            add(name);
            textOffsetY += 190;
        }

        infoText.text = curArray[curSelected].info;
        add(infoText);
    }

    function enter()
    {
        FlxG.sound.play(Paths.sound('confirmMenu'));
        checkLayer();
    }

    function backOut()
    {
        FlxG.sound.play(Paths.sound('cancelMenu'));
        
        if (layer == "corruption" || layer == "animations" || layer == "general" || 
            layer == "if" || layer == "memory" || layer == "extra")
        {
            changeLayer(0, "section");
            curSelected = prevMenuCurSelected;
            updateTexts();
            updateSelected();
            bg.color = FlxColor.RED;
        }
        else if (layer == "opening" || layer == "badending")
        {
            changeLayer(2, "animations");
            curSelected = prevMenuCurSelected;
            updateTexts();
            updateSelected();
            bg.color = 0xFF6677;
        }
        else if (layer == "nullandvoid" || layer == "chkdsk" || 
                 layer == "bloodlust" || layer == "accessdenied")
        {
            changeLayer(1, "corruption");
            curSelected = prevMenuCurSelected;
            updateTexts();
            updateSelected();
            bg.color = 0xFF6677;
        }
        else
        {
            canSelect = false;
            if (blackTween != null)
                blackTween.cancel();
        
            blackTop.alpha = 0;
            
            // Transición de zoom acercándose al salir
            FlxTween.tween(FlxG.camera, {zoom: 1.3}, 0.8, {ease: FlxEase.backIn});
            // Bajar música suavemente al regresar
            FlxTween.tween(FlxG.sound.music, {volume: 0.7}, 0.5, {ease: FlxEase.expoOut});
            
            blackTween = FlxTween.tween(blackTop, {alpha: 1}, 1.0, {
                ease: FlxEase.sineOut,
                onComplete: function(twn:FlxTween) {
                    MusicBeatState.switchState(new MainMenuState_oldmenu());
                }
            });
        }
    }

    function checkLayer()
    {
        if (layer == "section")
        {
            try {
                switch (curSelected)
                {
                    case 0:
                        changeLayer(1,"corruption");
                        bg.color = 0xFF6677;
                    case 1:
                        changeLayer(2,"animations");
                        bg.color = 0xFF6677;
                    case 2:
                        try {
                            if (allArrays.length <= 9 || allArrays[9] == null || allArrays[9].length == 0) {
                                throw "Error: Sección general no disponible";
                            }
                            changeLayer(9,"general");
                            bg.color = 0xFFFFFF;
                        } catch(e:Dynamic) {
                            var errorText = new FlxText(0, 0, FlxG.width, "Error al cargar sección general\nLa información no está disponible", 32);
                            errorText.setFormat(Paths.font("VollkornRegular-ZVJEZ.ttf"), 32, FlxColor.RED, CENTER);
                            errorText.screenCenter();
                            errorText.scrollFactor.set();
                            add(errorText);
                            
                            // Efecto de desvanecimiento pulsante
                            FlxTween.tween(errorText, {alpha: 0.2}, 0.8, {
                                type: FlxTween.PINGPONG,
                                ease: FlxEase.smoothStepInOut
                            });
                            
                            // Reproducir sonido de error
                            FlxG.sound.play(Paths.sound('cancelMenu'));
                            
                            // Timer para volver atrás
                            new FlxTimer().start(3, function(tmr:FlxTimer) {
                                FlxTween.cancelTweensOf(errorText);
                                FlxTween.tween(errorText, {alpha: 0}, 0.5, {
                                    onComplete: function(twn:FlxTween) {
                                        remove(errorText);
                                        errorText.destroy();
                                        // Volver a la sección principal
                                        changeLayer(0, "section");
                                        curSelected = prevMenuCurSelected;
                                        updateTexts();
                                        updateSelected();
                                        bg.color = FlxColor.RED;
                                    }
                                });
                            });
                            return;
                        }
                    case 3:
                        try {
                            if (allArrays.length <= 8 || allArrays[8] == null || allArrays[8].length == 0) {
                                throw "Error: Sección Corruption IF no disponible";
                            }
                            changeLayer(8,"if");
                            bg.color = 0xFFFFFF;
                        } catch(e:Dynamic) {
                            var glitchText = new FlxText(0, 0, FlxG.width, "ERR0R: C0RRUPT10N_1F\nDATA_C0RRUPTED", 32);
                            glitchText.setFormat(Paths.font("VollkornRegular-ZVJEZ.ttf"), 32, FlxColor.fromRGB(255, 0, 0), CENTER);
                            glitchText.screenCenter();
                            glitchText.scrollFactor.set();
                            add(glitchText);
                            
                            // Efecto de glitch
                            var glitchTimer = new FlxTimer();
                            glitchTimer.start(0.05, function(tmr:FlxTimer) {
                                glitchText.x = glitchText.x + FlxG.random.float(-5, 5);
                                glitchText.y = glitchText.y + FlxG.random.float(-2, 2);
                                glitchText.color = FlxColor.fromRGB(
                                    FlxG.random.int(200, 255),
                                    FlxG.random.int(0, 50),
                                    FlxG.random.int(0, 50)
                                );
                            }, 60); // 60 repeticiones = 3 segundos
                            
                            // Sonido de error glitch
                            FlxG.sound.play(Paths.sound('cancelMenu'), 0.7);
                            
                            // Timer para volver atrás
                            new FlxTimer().start(3, function(tmr:FlxTimer) {
                                glitchTimer.cancel(); // Detener el efecto de glitch
                                FlxTween.tween(glitchText, {alpha: 0}, 0.5, {
                                    onComplete: function(twn:FlxTween) {
                                        remove(glitchText);
                                        glitchText.destroy();
                                        // Volver a la sección principal
                                        changeLayer(0, "section");
                                        curSelected = prevMenuCurSelected;
                                        updateTexts();
                                        updateSelected();
                                        bg.color = FlxColor.RED;
                                    }
                                });
                            });
                            return;
                        }
                    case 4:
                        changeLayer(10,"memory");
                        bg.color = 0xFFFFFF;
                    case 5:
                        changeLayer(11,"extra");
                        bg.color = 0xFFFFFF;
                }
                prevMenuCurSelected = curSelected;
                curSelected = 0;
                updateTexts();
                updateSelected();
            } catch(e:Dynamic) {
                showErrorMessage(getErrorMessage(layer));
            }
        }
        else if (layer == "corruption")
        {
            try {
                switch (curSelected)
                {
                    case 0:
                        changeLayer(12,"nullandvoid");
                    case 1:
                        changeLayer(3,"chkdsk");
                    case 2:
                        changeLayer(4,"bloodlust");
                    case 3:
                        changeLayer(5,"accessdenied");
                }
                bg.color = 0xFFFFFF;
                prevMenuCurSelected = curSelected;
                curSelected = 0;
                updateTexts();
                updateSelected();
            } catch(e:Dynamic) {
                // Crear múltiples textos para efecto de corrupción
                var errorTexts:Array<FlxText> = [];
                var messages = [
                    "ERROR: CORRUPCIÓN DETECTADA",
                    "DATOS CORROMPIDOS",
                    "SISTEMA COMPROMETIDO",
                    "ACCESO DENEGADO"
                ];
                
                for (i in 0...messages.length) {
                    var errorText = new FlxText(0, 0, FlxG.width, messages[i], 32);
                    errorText.setFormat(Paths.font("VollkornRegular-ZVJEZ.ttf"), 32, FlxColor.fromRGB(255, 0, 0), CENTER);
                    errorText.screenCenter();
                    errorText.y += (i * 40) - 60; // Espaciado vertical
                    errorText.scrollFactor.set();
                    errorTexts.push(errorText);
                    add(errorText);
                }
                
                // Efecto de glitch visual
                var glitchTimer = new FlxTimer();
                glitchTimer.start(0.05, function(tmr:FlxTimer) {
                    for (text in errorTexts) {
                        // Efecto de desplazamiento aleatorio
                        text.x = text.x + FlxG.random.float(-5, 5);
                        text.y = text.y + FlxG.random.float(-3, 3);
                        
                        // Cambio de color aleatorio en tonos rojos y negros
                        text.color = FlxG.random.bool(70) ? 
                            FlxColor.fromRGB(
                                FlxG.random.int(200, 255),
                                FlxG.random.int(0, 50),
                                FlxG.random.int(0, 50)
                            ) : 
                            FlxColor.fromRGB(0, 0, 0);
                    }
                }, 60); // 60 repeticiones = 3 segundos
                
                // Sonidos de error alternados
                var soundTimer = new FlxTimer();
                soundTimer.start(0.2, function(tmr:FlxTimer) {
                    FlxG.sound.play(Paths.sound('cancelMenu'), FlxG.random.float(0.3, 0.7));
                }, 5); // 5 sonidos en total
                
                // Timer para volver atrás
                new FlxTimer().start(3, function(tmr:FlxTimer) {
                    glitchTimer.cancel();
                    soundTimer.cancel();
                    
                    // Desvanecer todos los textos con diferentes velocidades
                    for (i in 0...errorTexts.length) {
                        var text = errorTexts[i];
                        FlxTween.tween(text, {alpha: 0}, 0.5 + (i * 0.1), {
                            onComplete: function(twn:FlxTween) {
                                remove(text);
                                text.destroy();
                                
                                // Si es el último texto, volver al menú principal
                                if (i == errorTexts.length - 1) {
                                    changeLayer(0, "section");
                                    curSelected = prevMenuCurSelected;
                                    updateTexts();
                                    updateSelected();
                                    bg.color = FlxColor.RED;
                                }
                            }
                        });
                    }
                });
                return;
            }
        }
        else if (layer == "animations")
        {
            try {
                switch (curSelected)
                {
                    case 0:
                        changeLayer(6,"opening");
                    case 1:
                        changeLayer(7,"badending");
                }
                bg.color = 0xFFFFFF;
                prevMenuCurSelected = curSelected;
                curSelected = 0;
                updateTexts();
                updateSelected();
            } catch(e:Dynamic) {
                var errorText = new FlxText(0, 0, FlxG.width, "Error al cargar animaciones\n¿Están los archivos en su lugar?", 32);
                errorText.setFormat(Paths.font("VollkornRegular-ZVJEZ.ttf"), 32, FlxColor.RED, CENTER);
                errorText.screenCenter();
                errorText.scrollFactor.set();
                add(errorText);
                
                // Animación de parpadeo
                FlxTween.tween(errorText, {alpha: 0}, 0.5, {
                    type: FlxTween.PINGPONG,
                    ease: FlxEase.sineInOut
                });
                
                // Reproducir sonido de error
                FlxG.sound.play(Paths.sound('cancelMenu'));
                
                // Timer para volver atrás
                new FlxTimer().start(3, function(tmr:FlxTimer) {
                    FlxTween.cancelTweensOf(errorText);
                    FlxTween.tween(errorText, {alpha: 0}, 0.5, {
                        onComplete: function(twn:FlxTween) {
                            remove(errorText);
                            errorText.destroy();
                            // Volver a la sección principal
                            changeLayer(0, "section");
                            curSelected = prevMenuCurSelected;
                            updateTexts();
                            updateSelected();
                            bg.color = FlxColor.RED;
                        }
                    });
                });
            }
        }
        else
        {
            openLink();
        }
    }

    function getErrorMessage(section:String):String {
        return switch(section) {
            case "animations": "Error al cargar animaciones";
            case "general": "Error al cargar sección general";
            case "if": "Error al cargar corruption: if";
            case "memory": "Error al cargar memoria";
            case "extra": "Error al cargar extras";
            default: "Error al cargar sección";
        }
    }

    function showErrorMessage(message:String) {
        var errorText = new FlxText(0, 0, FlxG.width, message, 32);
        errorText.setFormat(Paths.font("VollkornRegular-ZVJEZ.ttf"), 32, FlxColor.RED, CENTER);
        errorText.screenCenter();
        errorText.scrollFactor.set();
        add(errorText);
        
        FlxTween.tween(errorText, {alpha: 0}, 0.5, {
            startDelay: 2,
            onComplete: function(twn:FlxTween) {
                remove(errorText);
                errorText.destroy();
            }
        });
        
        FlxG.sound.play(Paths.sound('cancelMenu'));
        
        // Volver al menú principal después del error
        new FlxTimer().start(2.5, function(tmr:FlxTimer) {
            backOut();
        });
    }

    function openLink()
    {
        if (curArray[curSelected].link != null)
        {
            try {
                CoolUtil.browserLoad(curArray[curSelected].link);
            } catch(e:Dynamic) {
                showErrorMessage("Error al abrir el enlace");
            }
        }
    }

    function changeLayer(whichArray:Int, whichLayer:String)
    {
        curArray = allArrays[whichArray];
        layer = whichLayer;
    }

    function addCreditsToArray() {
    var sectionCredits:Array<{ name:String, info:String, link:String }> = [
        { name: "CORRUPTION", info: "\nSelect to see credits.", link: null},
        { name: "ANIMATIONS", info: "\nSelect to see credits.", link: null},
        { name: "GENERAL", info: "\nSelect to see credits.", link: null},
        { name: "CORRUPTION: IF", info: "\nSelect to see credits.", link: null},
        { name: "MEMORY", info: "\nIn loving memory\nof those who we lost.", link: null},
        { name: "EXTRA", info: "\nSelect to see more.", link: null}
    ];

    var corruptionCredits:Array<{ name:String, info:String, link:String }> = [
        { name: "NULL AND VOID", info: "\nSelect to see credits.", link: null},
        { name: "CHKDSK", info: "\nSelect to see credits.", link: null},
        { name: "BLOODLUST", info: "\nSelect to see credits.", link: null},
        { name: "ACCESS DENIED", info: "\nSelect to see credits.", link: null}
    ];

    var animationCredits:Array<{ name:String, info:String, link:String }> = [
        { name: "OPENING", info: "\nSelect to see credits.", link: null},
        { name: "BAD ENDING", info: "\nSelect to see credits.", link: null}
    ];

    var nullAndVoidCredits:Array<{ name:String, info:String, link:String }> = [
        { name: "NULL AND VOID", info: "\nSong: fluffyFHX", link: "https://www.youtube.com/channel/UC45OK9Bcx9R7uJ1tPMJaTkg"},
        { name: "PHANTOMFEAR", info: "Director\nArt\nCode\nCutscenes\nCharting", link: "https://www.youtube.com/@PhantomFearYT"},
        { name: "FUSA", info: "\nPixel BF front view sprite.", link: "https://x.com/fusanensan_fnf"},
        { name: "NEBULA THE ZORUA", info: "\nCode\nMod chart", link: "https://bsky.app/profile/nebulazorua.bsky.social"},
        { name: "DUSKIEWHY", info: "\nOG Mod chart", link: "https://www.youtube.com/@DuskieWhy"},
        { name: "PINCERPROD", info: "\nCutscene BG wall details", link: "https://www.youtube.com/@PincerProd"},
        { name: "LEEBERT", info: "\nCutscene Song", link: "https://www.youtube.com/@leebert"},
        { name: "NOTSPRING", info: "\nCharting", link: "https://www.youtube.com/@NotSpring"},
        { name: "TSUKIMI MIKAZUKI", info: "\nHarvester VA", link: "https://www.youtube.com/@TsukimiDe1pai"},
        { name: "KOSPI", info: "\nCutscene Skybox", link: "https://x.com/@frixen__"}
    ];

    var chkdskCredits:Array<{ name:String, info:String, link:String }> = [
        { name: "CHKDSK", info: "\nSong:\nKazuya,\nLiterallyNoOne", link: "https://youtu.be/BjOvA9us7bE?si=qG5d6D1rcqn7zArB"},
        { name: "PHANTOMFEAR", info: "Director\nArt\nCode\nCutscenes", link: "https://www.youtube.com/@PhantomFearYT"},
        { name: "FUSA", info: "\nPixel BF front view sprite.", link: "https://x.com/fusanensan_fnf"},
        { name: "NEBULA THE ZORUA", info: "\nMod chart", link: "https://bsky.app/profile/nebulazorua.bsky.social"},
        { name: "DUSKIEWHY", info: "\nMod chart", link: "https://www.youtube.com/@DuskieWhy"},
        { name: "KAZUYA", info: "\nMusician", link: "https://www.youtube.com/@raytraxdtm"},
        { name: "LITERALLYNOONE", info: "\nMusician", link: "https://www.youtube.com/@LiterallyNoOne"},
        { name: "LEEBERT", info: "\nCutscene Song", link: "https://www.youtube.com/@leebert"},
        { name: "FLOOTENA", info: "\nCharting", link: "https://x.com/FlootenaDX"},
        { name: "KOSPI", info: "\nCutscene Skybox", link: "https://x.com/@frixen__"}
    ];

    var bloodlustCredits:Array<{ name:String, info:String, link:String }> = [
        { name: "BLOODLUST", info: "\nSong: Leebert", link: "https://www.youtube.com/@leebert"},
        { name: "PHANTOMFEAR", info: "Director\nArt\nCode\nCutscenes", link: "https://www.youtube.com/@PhantomFearYT"},
        { name: "BEEFSTARCHJELLO", info: "\nCutscenes\nSpider Mommy Mearest Sprite\nSprite animations", link: "https://x.com/beefstarchjello"},
        { name: "AKNIYET", info: "\nSprite Line Art\nGF + MM Sprite coloring", link: "https://x.com/akniyet_z"},
        { name: "NOVASAUR", info: "\nGF Pose Concepts Art", link: "https://www.youtube.com/@NNovasaur"},
        { name: "YUKIZAKURA", info: "\nForest Background", link: "https://x.com/yukizakura1126"},
        { name: "NEBULA THE ZORUA", info: "\nCode", link: "https://bsky.app/profile/nebulazorua.bsky.social"},
        { name: "FLOOTENA", info: "\nCharting", link: "https://x.com/FlootenaDX"},
        { name: "PINCERPROD", info: "\nGF VA", link: "https://www.youtube.com/@PincerProd"},
        { name: "KOSPI", info: "\nCutscene Skybox", link: "https://x.com/@frixen__"}
    ];

    var accessDeniedCredits:Array<{ name:String, info:String, link:String }> = [
        { name: "ACCESS DENIED", info: "\nSong: GRYSCL", link: "https://youtu.be/HRg91nxRyo0?si=8M3NUniXalOiWTur"},
        { name: "PHANTOMFEAR", info: "Director\nArt\nCode\nCutscenes", link: "https://www.youtube.com/@PhantomFearYT"},
        { name: "NEBULA THE ZORUA", info: "\nModChart\nCode", link: "https://bsky.app/profile/nebulazorua.bsky.social"},
        { name: "DUSKIEWHY", info: "\nBase modchart", link: "https://www.youtube.com/@DuskieWhy"},
        { name: "FLOOTENA", info: "\nCharting", link: "https://x.com/FlootenaDX"}
    ];

    var openingCredits:Array<{ name:String, info:String, link:String }> = [
        { name: "CORRUPTION OPENING", info: "by: Funnyleech,\nDani Susatyo,\nZhafiraWildhania,\nWillyJayasukma,\nLunaticParfait", link: "https://www.youtube.com/watch?v=rwclhBa1Tqo"},
        { name: "PHANTOMFEAR", info: "\nArt\nAnimation", link: "https://www.youtube.com/@PhantomFearYT"},
        { name: "YUKIZAKURA", info: "\nArt", link: "https://x.com/yukizakura1126"},
        { name: "SACUNIULTIMATE", info: "\nArt\nAnimation", link: "https://x.com/sacuniUltimate"},
        { name: "BLUEGARDEN", info: "\nArt", link: "https://x.com/Oceanlight375"},
        { name: "DAYANCI", info: "\nArt", link: "https://x.com/dayanci_"},
        { name: "KOSPI", info: "\nPico Week Background", link: "https://x.com/@frixen__"},
        { name: "FLOOTENA", info: "\nCharting", link: "https://x.com/FlootenaDX"}
    ];

    var badendingCredits:Array<{ name:String, info:String, link:String }> = [
        { name: "SHINIGAMI", info: "\nSong:\neverything falls to the floor", link: "https://www.youtube.com/watch?v=FN2hLbcs974"},
        { name: "BEEFSTARCHJELLO", info: "\nBF Cutscene\nBF VA", link: "https://x.com/beefstarchjello"},
        { name: "PHANTOMFEAR", info: "\nNull Deletion Cutscene\nCredits Visualizer", link: "https://www.youtube.com/@PhantomFearYT"}
    ];

    var ifCredits:Array<{ name:String, info:String, link:String }> = [
        { name: "PRETENCE", info: "Song:\nLeebert,\nZeroh\nRazorDaMusician\nAureCraft", link: null},
        { name: "PINCERPROD", info: "\nDirector\nArt\nConcept Art\nVA", link: "https://www.youtube.com/@PincerProd"},
        { name: "BEEFSTARCHJELLO", info: "\nArt\nAnimation", link: "https://x.com/beefstarchjello"},
        { name: "ACECRE4M", info: "\nIcon Art\nBackground Art\nConcept Art", link: "https://bsky.app/profile/acecre4m.bsky.social"},
        { name: "AURECRAFT", info: "\nConcept Art\nAnimator\nPromo Art\nMusician", link: "http://www.youtube.com/@AureCraft_"},
        { name: "TOTALLYNBF", info: "\nConcept Art\nPromo Art", link: "https://totallynbf.newgrounds.com/"},
        { name: "STEAMPANDAA", info: "\nPromo Art\nJolly Mode", link: "https://bsky.app/profile/steampandaa.bsky.social"},
        { name: "LEEBERT", info: "\nMusician", link: "https://x.com/Bruh_Leebert"},
        { name: "ZEROH", info: "\nMusician", link: "https://www.youtube.com/channel/UC5Km5yZrSF7t4molQk9MYhg"},
        { name: "RAZORDAMUSICIAN", info: "\nMusician\nHurt SFX", link: "https://youtube.com/@razordamusician?si=jgtm5_6OiQO1ZzXX"},
        { name: "ULTRAVIOLET", info: "\nMenu Music", link: "https://www.youtube.com/@UltraaVioletMusic"},
        { name: "PHANTOMFEAR", info: "\nCode", link: "https://www.youtube.com/@PhantomFearYT"},
        { name: "DUODOES", info: "\nVA\nChart", link: "https://www.youtube.com/@DuoDoesStuff"}
    ];

    var generalCredits:Array<{ name:String, info:String, link:String }> = [
        { name: "PHANTOMFEAR", info: "\nMenu Art\nCode", link: "https://www.youtube.com/@PhantomFearYT"},
        { name: "NEBULA THE ZORUA", info: "\nTroll Engine\nCode\nOptimization", link: "https://bsky.app/profile/nebulazorua.bsky.social"},
        { name: "BEEFSTARCHJELLO", info: "\nMenu Art", link: "https://x.com/beefstarchjello"},
        { name: "SACUNIULTIMATE", info: "\nTitle Screen Art", link: "https://x.com/sacuniUltimate"},
        { name: "FLUFFYFHX", info: "\nBF Death Screen Music", link: "https://www.youtube.com/channel/UC45OK9Bcx9R7uJ1tPMJaTkg"},
        { name: "LEEBERT", info: "\nGF Death Screen Music", link: "https://x.com/Bruh_Leebert"},
        { name: "YUKIZAKURA", info: "\nCorruption: Side Story", link: "https://x.com/yukizakura1126"},
        { name: "SMILEYSQUEAK", info: "\nOriginal Menu Song", link: "https://www.youtube.com/@smileysqueak"},
        { name: "SAI", info: "\nConverting MP4s to Spritesheets", link: "https://x.com/sacuniUltimate"},
		{ name: "SWORDCUBE", info: "\nPlaytesting for super low-end\nPixel Miss judgement", link: "https://bsky.app/profile/swordcube.bsky.social"},
		{ name: "LAVENDER", info: "\nOptimized the videos", link: "https://bsky.app/profile/lavender06.bsky.social"},
        { name: "FUNKIN' CREW INC.", info: "\nFriday Night Funkin'", link: "https://funkin.me"}
    ];

    #if mac
    // burgerballs to the burgerescue
    generalCredits.push({ name: "Burgerballs", info: "\nProvided MacOS Compilations", link: "https://bsky.app/profile/burgerballs.bsky.social"});
    #end

    memoryCredits = [
        { name: "Rod", info: "\nIn loving memory.\n24/08/03 - 17/07/24", link: "https://x.com/AstactArcade4K"},
        { name: "Onyx", info: "\nIn loving memory.", link: null}
    ];

    extraCredits = [
        { name: "MERCH", info: "\ncrowdmade.com", link: "https://crowdmade.com/collections/phantomfear"},
        { name: "FULL STORY", info: "\nEvery episode in order.", link: "https://youtube.com/playlist?list=PLPtjMqSqi-a0R38VWeZndX26rUu8TK_rc&si=YKyAwbXBs2hA1yla"}
    ];

    allArrays.push(sectionCredits);         // 0
    allArrays.push(corruptionCredits);      // 1
    allArrays.push(animationCredits);       // 2
    allArrays.push(chkdskCredits);          // 3
    allArrays.push(bloodlustCredits);       // 4
    allArrays.push(accessDeniedCredits);    // 5
    allArrays.push(openingCredits);         // 6
    allArrays.push(badendingCredits);       // 7
    allArrays.push(ifCredits);              // 8
    allArrays.push(generalCredits);         // 9
    allArrays.push(memoryCredits);          // 10
    allArrays.push(extraCredits);           // 11
    allArrays.push(nullAndVoidCredits);     // 12
    }
}

