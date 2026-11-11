package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.system.FlxSound;
import openfl.display.BlendMode;
import backend.Paths;
import backend.MusicBeatState;
import backend.WeekData;
import backend.ClientPrefs;
import backend.Song;
import backend.Mods;
import states.LoadingState;
import states.PlayState;

class IfMenu extends MusicBeatState
{
    var canSelect:Bool = true;
    var object:FlxSprite;
    var moveTween:FlxTween;
    var cloud:FlxSprite;
    var disk:FlxSprite;
    var titleBlack:FlxSprite;
    var transition:FlxSprite;
    var camFollow:FlxSprite;
    var camFollowPos:FlxSprite;

    override function create()
    {
        persistentUpdate = true;
        persistentDraw = true;

        if (FlxG.sound.music != null)
            FlxG.sound.music.stop();

        Paths.clearStoredMemory();
        
        FlxG.mouse.visible = false;
        FlxG.camera.bgColor = FlxColor.BLACK;

        try {
            // Inicializar super.create() primero (que configura PsychCamera)
            super.create();

            // Camera setup DESPUÉS de super.create() (igual que SideStoryMenuNotices)
            camFollow = new FlxSprite().makeGraphic(1, 1, 0xFF000000);
            camFollow.alpha = 0;
            camFollow.setPosition(951, 570);
            
            camFollowPos = new FlxSprite().makeGraphic(1, 1, 0xFF000000);
            camFollowPos.setPosition(951, -270);
            add(camFollow);
            add(camFollowPos);

            FlxG.camera.zoom = 0.593;
            FlxG.camera.follow(camFollowPos, LOCKON, 1);

            // Background elements
            try {
                var bg = new FlxSprite(0, 0).loadGraphic(Paths.image('menus/if/bgBase'));
                if (bg != null) {
                    bg.scrollFactor.set(0, 0);
                    bg.scale.set(1.7, 1.7);
                    add(bg);
                } else {
                    trace('[ERROR] bgBase es null');
                }
            } catch(e) {
                trace('[ERROR] Error cargando bgBase: ' + e);
            }

            // Cloud setup
            try {
                cloud = new FlxSprite(-2330, 0).loadGraphic(Paths.image('menus/if/cloudScroll'));
                if (cloud != null) {
                    cloud.scrollFactor.set(0, 0);
                    cloud.scale.set(1.7, 1.7);
                    cloud.alpha = 0;
                    add(cloud);
                    moveTween = FlxTween.tween(cloud, {x: -880, alpha: 0.6}, 10, {onComplete: cloudEase1});
                } else {
                    trace('[ERROR] cloud es null');
                }
            } catch(e) {
                trace('[ERROR] Error cargando cloud: ' + e);
            }

            // Disk setup
            try {
                disk = new FlxSprite(379, 267).loadGraphic(Paths.image('menus/if/spinnyDisk'));
                if (disk != null) {
                    disk.scrollFactor.set(0, 0);
                    disk.scale.set(1.7, 1.7);
                    disk.alpha = 0;
                    add(disk);
                    FlxTween.tween(disk, {alpha: 0.8}, 10);
                } else {
                    trace('[ERROR] disk es null');
                }
            } catch(e) {
                trace('[ERROR] Error cargando disk: ' + e);
            }

            // Falsethorn
            try {
                var falsethorn = new FlxSprite(700, 0).loadGraphic(Paths.image('menus/if/falsethorn'));
                if (falsethorn != null) {
                    falsethorn.scrollFactor.set(0, 0);
                    falsethorn.scale.set(1.7, 1.7);
                    falsethorn.alpha = 0;
                    add(falsethorn);
                    FlxTween.tween(falsethorn, {alpha: 1, x: 0}, 2, {ease: FlxEase.circOut});
                } else {
                    trace('[ERROR] falsethorn es null');
                }
            } catch(e) {
                trace('[ERROR] Error cargando falsethorn: ' + e);
            }

            // BF
            try {
                var bf = new FlxSprite(-700, 0).loadGraphic(Paths.image('menus/if/bf'));
                if (bf != null) {
                    bf.scrollFactor.set(0, 0);
                    bf.scale.set(1.7, 1.7);
                    bf.alpha = 0;
                    add(bf);
                    FlxTween.tween(bf, {alpha: 1, x: 0}, 2, {ease: FlxEase.circOut});
                } else {
                    trace('[ERROR] bf es null');
                }
            } catch(e) {
                trace('[ERROR] Error cargando bf: ' + e);
            }

            // Bars
            try {
                var bars = new FlxSprite(0, 0).loadGraphic(Paths.image('menus/if/bars'));
                if (bars != null) {
                    bars.scrollFactor.set(0, 0);
                    bars.scale.set(1.7, 1.7);
                    add(bars);
                } else {
                    trace('[ERROR] bars es null');
                }
            } catch(e) {
                trace('[ERROR] Error cargando bars: ' + e);
            }

            // Logo
            try {
                var logo = new FlxSprite(0, 0).loadGraphic(Paths.image('menus/if/logo'));
                if (logo != null) {
                    logo.scrollFactor.set(0, 0);
                    logo.scale.set(1.7, 1.7);
                    logo.alpha = 0;
                    if (ClientPrefs != null && ClientPrefs.data != null) {
                        logo.antialiasing = ClientPrefs.data.antialiasing;
                    }
                    add(logo);
                    FlxTween.tween(logo, {alpha: 1}, 3, {ease: FlxEase.circIn});
                } else {
                    trace('[ERROR] logo es null');
                }
            } catch(e) {
                trace('[ERROR] Error cargando logo: ' + e);
            }

            // Song Name
            try {
                var songName = new FlxSprite(0, 0).loadGraphic(Paths.image('menus/if/songName'));
                if (songName != null) {
                    songName.scrollFactor.set(0, 0);
                    songName.scale.set(1.7, 1.7);
                    songName.alpha = 0;
                    add(songName);
                    FlxTween.tween(songName, {alpha: 1}, 4, {ease: FlxEase.circIn});
                } else {
                    trace('[ERROR] songName es null');
                }
            } catch(e) {
                trace('[ERROR] Error cargando songName: ' + e);
            }

            // Music - con try-catch
            try {
                var musicPath = Paths.music('menu6');
                if (musicPath != null) {
                    FlxG.sound.playMusic(musicPath, 1);
                } else {
                    trace('[ERROR] música menu6 path es null');
                }
            } catch(e) {
                trace('[ERROR] Error cargando música menu6: ' + e);
            }

            // Transition - simplificado
            try {
                transition = new FlxSprite(150, 119);
                var transAtlas = Paths.getSparrowAtlas('burnTransition');
                if (transAtlas != null) {
                    transition.frames = transAtlas;
                    if (transition.animation != null) {
                        transition.animation.addByPrefix("idle", 'burnTransition idle', 24, false);
                        transition.animation.play("idle", true);
                    }
                    transition.scrollFactor.set(0, 0);
                    transition.scale.set(2.5, 2.5);
                    if (ClientPrefs != null && ClientPrefs.data != null) {
                        transition.antialiasing = ClientPrefs.data.antialiasing;
                    }
                    transition.alpha = 0;
                    transition.blend = BlendMode.MULTIPLY;
                    transition.cameras = [FlxG.camera];
                    add(transition);
                } else {
                    trace('[ERROR] burnTransition atlas es null');
                }
            } catch(e) {
                trace('[ERROR] Error cargando transition: ' + e);
            }

            // Black overlay
            try {
                titleBlack = new FlxSprite(0, 0).loadGraphic(Paths.image('menus/mainmenu/fullBlack'));
                if (titleBlack != null) {
                    titleBlack.scrollFactor.set(0, 0);
                    titleBlack.scale.set(1.7, 1.7);
                    titleBlack.alpha = 0;
                    add(titleBlack);
                } else {
                    trace('[ERROR] titleBlack es null');
                }
            } catch(e) {
                trace('[ERROR] Error cargando titleBlack: ' + e);
            }

            object = titleBlack;

            super.create();
        } catch(e) {
            trace('[ERROR] Error general en create de IfMenu: ' + e);
        }
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        if (disk != null)
            disk.angle += 100 * elapsed;

        inputCheck();
    }

    function cloudEase1(tween:FlxTween)
    {
        if (moveTween != null)
            moveTween.cancel();

        if (cloud != null) {
            moveTween = FlxTween.tween(cloud, {x: 610, alpha: 0}, 10, {onComplete: cloudEase2});
        }
    }

    function cloudEase2(tween:FlxTween)
    {
        if (moveTween != null)
            moveTween.cancel();

        if (cloud != null) {
            cloud.x = -2330;
            moveTween = FlxTween.tween(cloud, {x: -880, alpha: 0.6}, 10, {onComplete: cloudEase1});
        }
    }

    function inputCheck()
    {
        if (!canSelect)
            return;

        // Skip con ESC - volver al menú
        if (FlxG.keys.justPressed.ESCAPE)
        {
            canSelect = false;
            FlxG.sound.play(Paths.sound('cancelMenu'));
            leaveScene();
            return;
        }

        if (controls.ACCEPT)
        {
            canSelect = false;
            FlxG.sound.play(Paths.sound('confirmMenu'));
            // Iniciar la canción pretence
            startStoryMode();
        }

        if (controls.UI_LEFT_P || controls.UI_RIGHT_P)
        {
            FlxG.sound.play(Paths.sound('scrollMenu'));
        }

        if (controls.BACK)
        {
            canSelect = false;
            FlxG.sound.play(Paths.sound('cancelMenu'));
            leaveScene();
        }
    }

    function startStoryMode()
    {
        try {
            FlxTween.tween(FlxG.camera, {zoom: 0.8}, 1.2, {ease: FlxEase.backIn, onComplete: storyTweenZoom});
            FlxG.sound.play(Paths.sound('water rush'));

            new FlxTimer().start(0.75, function(tmr)
            {
                if (transition != null) {
                    transition.alpha = 1;
                    if (transition.animation != null) {
                        transition.animation.play("idle", true);
                    }
                }
                tmr.destroy();
            });

            new FlxTimer().start(1.7, function(tmr)
            {
                if (titleBlack != null) {
                    titleBlack.alpha = 1;
                }
                tmr.destroy();
            });
        } catch(e) {
            trace('[ERROR] Error en startStoryMode: ' + e);
        }
    }

    function storyTweenZoom(tween:FlxTween)
    {
        try {
            trace('[IfMenu] ===== Inicio de carga de pretence =====');
            trace('[IfMenu] Mod directory antes de cargar: ' + Mods.currentModDirectory);
            trace('[IfMenu] Canción base: pretence');
            trace('[IfMenu] Dificultad: ' + PlayState.storyDifficulty + ' (Canon/Normal)');

            if (FlxG.sound.music != null) {
                FlxG.sound.music.fadeOut(1.5, 0);
            }
            FlxTween.tween(FlxG.camera, {zoom: 6}, 1.5);

            // Configurar el mod que contiene los charts de pretence antes de cargarlos.
            Mods.currentModDirectory = "aog songs corruption";
            trace('[IfMenu] Mod directory configurado: ' + Mods.currentModDirectory);

            PlayState.storyPlaylist = ['pretence'];
            PlayState.isStoryMode = true;

            // Cargar dificultad Canon (la que tienes disponible)
            PlayState.storyDifficulty = 1; // 1 = Normal/Canon
            
            try {
                // Intentar cargar pretence-canon primero, luego pretence-safe como fallback
                var songLoaded = false;
                
                // Intento 1: pretence-canon
                try {
                    trace('[IfMenu] Intento 1: cargando chart "pretence-canon" con canción base "pretence"');
                    PlayState.SONG = backend.Song.loadFromJson('pretence-canon', 'pretence');
                    if (PlayState.SONG != null) {
                        trace('[IfMenu] ✓ pretence-canon cargado. SONG.song=' + PlayState.SONG.song);
                        songLoaded = true;
                    } else {
                        trace('[IfMenu] ✗ pretence-canon devolvió SONG=null sin lanzar excepción');
                    }
                } catch(e1) {
                    trace('[IfMenu] ✗ Falló pretence-canon: ' + Std.string(e1));
                    trace('[IfMenu] Stack pretence-canon: ' + haxe.CallStack.toString(haxe.CallStack.exceptionStack()));
                }
                
                // Intento 2: pretence-safe
                if (!songLoaded) {
                    try {
                        trace('[IfMenu] Intento 2: cargando chart "pretence-safe" con canción base "pretence"');
                        PlayState.SONG = backend.Song.loadFromJson('pretence-safe', 'pretence');
                        if (PlayState.SONG != null) {
                            trace('[IfMenu] ✓ pretence-safe cargado. SONG.song=' + PlayState.SONG.song);
                            songLoaded = true;
                        } else {
                            trace('[IfMenu] ✗ pretence-safe devolvió SONG=null sin lanzar excepción');
                        }
                    } catch(e2) {
                        trace('[IfMenu] ✗ Falló pretence-safe: ' + Std.string(e2));
                        trace('[IfMenu] Stack pretence-safe: ' + haxe.CallStack.toString(haxe.CallStack.exceptionStack()));
                    }
                }
                
                // Intento 3: pretence (sin sufijo)
                if (!songLoaded) {
                    try {
                        trace('[IfMenu] Intento 3: cargando chart "pretence" con canción base "pretence"');
                        PlayState.SONG = backend.Song.loadFromJson('pretence', 'pretence');
                        if (PlayState.SONG != null) {
                            trace('[IfMenu] ✓ pretence cargado. SONG.song=' + PlayState.SONG.song);
                            songLoaded = true;
                        } else {
                            trace('[IfMenu] ✗ pretence devolvió SONG=null sin lanzar excepción');
                        }
                    } catch(e3) {
                        trace('[IfMenu] ✗ Falló pretence: ' + Std.string(e3));
                        trace('[IfMenu] Stack pretence: ' + haxe.CallStack.toString(haxe.CallStack.exceptionStack()));
                    }
                }
                
                if (!songLoaded) {
                    trace('[IfMenu] ERROR: No se pudo cargar ningún chart de pretence.');
                    trace('[IfMenu] Charts probados: pretence-canon, pretence-safe, pretence');
                    trace('[IfMenu] Mod directory usado: ' + Mods.currentModDirectory);
                    leaveScene();
                    return;
                }
            } catch(e) {
                trace('[ERROR] Error inesperado preparando la carga de pretence: ' + Std.string(e));
                trace('[ERROR] Stack de preparación: ' + haxe.CallStack.toString(haxe.CallStack.exceptionStack()));
                leaveScene();
                return;
            }
            
            PlayState.storyWeek = 0;
            PlayState.campaignScore = 0;
            PlayState.campaignMisses = 0;

            new FlxTimer().start(1.5, function(tmr)
            {
                try {
                    trace('[IfMenu] Cambiando a PlayState con SONG=' + (PlayState.SONG != null ? PlayState.SONG.song : 'NULL'));
                    LoadingState.loadAndSwitchState(new PlayState());
                    trace('[IfMenu] PlayState solicitado correctamente');
                } catch(e:Dynamic) {
                    trace('[IfMenu] ERROR creando/cambiando a PlayState: ' + Std.string(e));
                    trace('[IfMenu] Stack del cambio de estado: ' + haxe.CallStack.toString(haxe.CallStack.exceptionStack()));
                }
                tmr.destroy();
            });
        } catch(e) {
            trace('[ERROR] Error general en storyTweenZoom: ' + Std.string(e));
            trace('[ERROR] Stack de storyTweenZoom: ' + haxe.CallStack.toString(haxe.CallStack.exceptionStack()));
        }
    }

    function leaveScene()
    {
        try {
            // Transición de zoom acercándose al salir
            FlxTween.tween(FlxG.camera, {zoom: 1.3}, 0.5, {ease: FlxEase.backIn});
            MusicBeatState.switchState(new SoftCodeMenuState(true));
        } catch(e) {
            trace('[ERROR] Error al salir de IfMenu: ' + e);
        }
    }
}




