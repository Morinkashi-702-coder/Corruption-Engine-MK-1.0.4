package states;

import flash.display.BlendMode;

#if desktop
import backend.Discord;
#end
import states.editors.ChartingState;
import states.editors.MasterEditorMenu;
import flash.text.TextField;
import flixel.FlxG;
import flixel.addons.display.FlxRuntimeShader;
import openfl.filters.ShaderFilter;
import openfl.filters.BitmapFilter;
import flixel.util.FlxTimer;
import flixel.tweens.FlxEase;
import objects.Alphabet;
import objects.HealthIcon;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import lime.utils.Assets;

import backend.SongMetadata;
import flixel.system.FlxSound;
import openfl.utils.Assets as OpenFlAssets;
import backend.WeekData;
import backend.Difficulty;
import states.PlayState;
import states.LoadingState;
import states.ModsMenuState;
import backend.Song;
import backend.Highscore;
import backend.Paths;
import backend.ClientPrefs;
import backend.GameConfig;
import states.SideStoryMenuNotices;


import StringTools;
import flixel.math.FlxMath;
import openfl.utils.Assets;
import openfl.filters.ShaderFilter;
import flixel.system.FlxAssets;
import openfl.Lib;
import flixel.FlxG;
import backend.Discord;
import flixel.text.FlxText;
import backend.MusicBeatState;
import states.LoadingState;
import options.OptionsState;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxObject;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxGroup;
import flixel.system.FlxSound;
import openfl.display.Shader;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;
import openfl.display.BlendMode;
#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#end

// Para el manejo de canciones en freeplay
typedef WeekText = Map<Int, Alphabet>;



// TRIVIA: This menu design is something I've been imagining forever now..
// It was something I wanted for the OG senpai corruption demo, but didn't have the time to pull off.
// Big shout out to beefstarchjello for helping spice the whole thing up, a lot of elements like the distant buildings on the main menu were all his idea!!

class SoftCodeMenuState extends MusicBeatState
{
    // Shader variables
    public static var waveShader:FlxRuntimeShader;
    public static var lensShader:FlxRuntimeShader;
    public static var blurShader:FlxRuntimeShader;
    public static var waterShader:FlxRuntimeShader;
    public static var overlayShader:FlxRuntimeShader;
    public static var waterSimpleShader:FlxRuntimeShader;
    
    // GPU Capability Detection
    public static var gpuCapabilities:String = "Unknown"; // "Ultra", "High", "Medium", "Low", "None"
    public static var openglVersion:String = "Unknown";
    public static var maxShaderCount:Int = 3; // Máximo de shaders simultáneos
    
    // Variable para detectar cuando viene de Credits
    public static var fromCredits:Bool = false;
    // Variable para detectar cuando viene desde PlayState (para preservar comportamiento de cámara)
    public static var fromPlay:Bool = false;
    
    var baseSpeed:Float = 500;
    var moveSpeed:Float;
    var selectedSprite:Int = 0;
    var coordsText:FlxText;
    var scaleText:FlxText;
    var infoBG:FlxSprite;
    var textScale:Float = 1.0;
    var isDevMode:Bool = true; // MODO DEV ACTIVADO
    // var isDevMode:Bool = false; // Desactiva modo dev si cambias a false
    var showFreeplay:Bool = true;
    var baseTextX:Float = 4457; // Posición X base del texto de freeplay
    var baseTextY:Float = 350;  // Posición Y base del texto de freeplay
    
    // Variables para los elementos movibles
    var clockTick:FlxSprite;
    public var skipTitle:Bool = false;
    public var showTitle:Bool = true;
    
    // Variables para manejo de dificultad
    private var curDifficulty:Int = -1;
    private static var lastDifficultyName:String = '';
    public static var vocals:FlxSound = null;
    
    public function new(skipTitle:Bool = false) {
        super();
        this.skipTitle = skipTitle;
        
        // Si viene de Credits, saltarse título y ir directo al menú
        if (fromCredits) {
            this.skipTitle = true;
            fromCredits = false; // Reset para próximas veces
            curSelected = 0; // Resetear la selección al volver de Credits
        }
        
        this.showTitle = !this.skipTitle; // Si skipTitle es true, no mostramos el título
        
        // Inicializar velocidad de movimiento
        moveSpeed = baseSpeed;

        // Crear cámara UI si no existe
        if (uiCamera == null) {
            uiCamera = new FlxCamera();
            uiCamera.bgColor.alpha = 0;
            FlxG.cameras.add(uiCamera, false);
        }
        
        // Inicializar recuadro y textos informativos
        infoBG = new FlxSprite(10, 10);
        infoBG.makeGraphic(200, 100, 0xFF000000);
        infoBG.alpha = 0.6;
        infoBG.visible = false;
        infoBG.scrollFactor.set(0, 0);
        infoBG.cameras = [uiCamera];
        add(infoBG);
        
        coordsText = new FlxText(15, 15, 190, "", 16);
        coordsText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
        coordsText.scrollFactor.set(0, 0);
        coordsText.visible = false;
        coordsText.cameras = [uiCamera];
        add(coordsText);
        
        scaleText = new FlxText(15, 35, 190, "", 16);
        scaleText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
        scaleText.scrollFactor.set(0, 0);
        scaleText.visible = false;
        scaleText.cameras = [uiCamera];
        add(scaleText);
        
        // Establecer zoom inmediatamente para evitar transiciones bruscas visibles
        // Si venimos desde PlayState, mantenemos el control de cámara tal cual (no forzamos un tween)
        if (!fromPlay) {
            // Determinar zoom basado en si los shaders están activos
            var shadersActive = ClientPrefs.data.shaders && !ClientPrefs.data.menuShaders;
            if (shadersActive) {
                FlxG.camera.zoom = 0.59; // Zoom normal con shaders
            } else {
                FlxG.camera.zoom = 0.59; // Zoom ajustado sin shaders (título)
            }
            trace('Camera zoom set to: ' + FlxG.camera.zoom + ' (shaders active: ' + shadersActive + ')');
        }
        // Resetear flag para próximas entradas
        fromPlay = false;
        
        // Inicializar sistema de dificultades
        curDiff = 1; // Normal por defecto (0=Easy, 1=Normal, 2=Hard)
        if(lastDifficultyName == '') {
            lastDifficultyName = Difficulty.defaultList[1];
        }
        curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(lastDifficultyName)));
        
        // Asegurarnos que Difficulty.list está inicializado
        if(Difficulty.list.length < 1) Difficulty.list = Difficulty.defaultList.copy();
    }
    
    private var increaseTime:Float = 0.0;
    private var zoomSpeed:Float = 0.01;
    private var zoomActive:Bool = false; // Se activa/desactiva con F2 cuando isDevMode = true
    private var zoomText:FlxText;
    private var uiCamera:FlxCamera;

    // Variables para sistema de mensajes de error
    private var isMessageActive:Bool = false;
    private var messageContainer:FlxTypedGroup<FlxSprite>;

    private function initEditModeElements():Bool {
        try {
            // Asegurarse de que los elementos de UI existan
            if (infoBG == null) {
                infoBG = new FlxSprite(10, 10);
                infoBG.makeGraphic(200, 100, 0xFF000000);
                infoBG.alpha = 0.6;
                infoBG.scrollFactor.set(0, 0);
                infoBG.cameras = [uiCamera];
                add(infoBG);
            }
            
            if (coordsText == null) {
                coordsText = new FlxText(15, 15, 190, "", 16);
                coordsText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
                coordsText.scrollFactor.set(0, 0);
                coordsText.cameras = [uiCamera];
                add(coordsText);
            }
            
            if (scaleText == null) {
                scaleText = new FlxText(15, 35, 190, "", 16);
                scaleText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
                scaleText.scrollFactor.set(0, 0);
                scaleText.cameras = [uiCamera];
                add(scaleText);
            }
            
            if (zoomText == null) {
                zoomText = new FlxText(0, 50, FlxG.width, "Zoom: 1.00x");
                zoomText.setFormat("VCR OSD Mono", 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
                zoomText.borderSize = 2;
                zoomText.visible = false;
                zoomText.cameras = [uiCamera];
                add(zoomText);
            }
            
            return true;
        } catch(e) {
            trace('[ERROR] Error al inicializar elementos del modo edición: ' + e);
            return false;
        }
    }

    private function updateDevModeInfo() {
        if (isDevMode && weekHeaders != null && coordsText != null && infoBG != null) {
            try {
                var selectedItem:Alphabet = null;
                
                for (item in weekHeaders.members) {
                    if (item != null && Std.isOfType(item, Alphabet)) {
                        var alphabetItem:Alphabet = cast item;
                        if (alphabetItem.targetY == 0) {
                            selectedItem = alphabetItem;
                            break;
                        }
                    }
                }

                if (selectedItem != null) {
                    var infoText = 'X: ${Math.floor(selectedItem.x)}\n' +
                                 'Y: ${Math.floor(selectedItem.y)}\n' +
                                 'Scale: ${textScale}x\n' +
                                 'targetY: ${selectedItem.targetY}';
                    if (coordsText != null) {
                        coordsText.text = infoText;
                    }
                }
            } catch(e) {
                trace('[ERROR] Error al actualizar información: ' + e);
            }
        }
    }
    
    // Variables para el posicionamiento del freeplay
    var baseY:Float = 0;
    var spacing:Float = 80; // Reducido el espacio entre elementos para que sea más compacto
    
    // Esencial para el freeplay dinámico
    // --- FREEPLAY DYNAMIC DATA ---
    var freeplaySongs:Array<SongMetadata> = [];
    var freeplayIcons:Array<objects.HealthIcon> = [];
    // --- FREEPLAY DYNAMIC LOGIC ---
    function generateFreeplaySongList() {
    freeplaySongs = [];
    
    // Primero cargar las semanas
    WeekData.reloadWeekFiles(true); // Forzar recarga como en StoryMenuState
    
    // Cache inicial de recursos (como hace StoryMenuState)
    if (FlxG.sound.music != null)
        FlxG.sound.music.stop();

    // Música dinámica - no reproducir aquí, dejar que el sistema de canciones dinámicas lo maneje
    // FlxG.sound.playMusic(Paths.music('freakyMenu'), 0.7);
    
    if (WeekData.weeksList.length == 0) {
        // trace('[DEBUG] No se encontraron semanas');
        var errorText = new flixel.text.FlxText(0, 0, FlxG.width, 'Error: No hay semanas disponibles\nPor favor verifica los archivos', 32);
        errorText.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.RED, CENTER);
        errorText.scrollFactor.set();
        errorText.screenCenter();
        errorText.color = 0xFFFF0000;
        add(errorText);
        
        new FlxTimer().start(2, function(tmr:FlxTimer) {
            errorText.destroy();
        });
        freeplaySongs = [];
        return;
    }
    
    // Procesar cada semana
    for (i in 0...WeekData.weeksList.length) {
        var weekName:String = WeekData.weeksList[i];
        
        var week:WeekData = WeekData.weeksLoaded.get(weekName);
        if (week == null) {
            continue;
        }
        
        // Verificar si la semana está desbloqueada
        if (!week.startUnlocked && week.weekBefore.length > 0 && 
            (!StoryMenuState.weekCompleted.exists(week.weekBefore) || !StoryMenuState.weekCompleted.get(week.weekBefore))) {
            continue;
        }
        
        try {
            // Establecer directorio para esta semana
            WeekData.setDirectoryFromWeek(week);
            
            // Procesar cada canción de la semana
            for (song in week.songs) {
                if (song == null) continue;
                
                var colors:Array<Int> = song[2];
                if(colors == null || colors.length < 3) {
                    colors = [146, 113, 253];
                }
                
                var songName:String = song[0];
                if (songName == null) continue;
                
                var char:String = song[1];
                if (char == null) char = '';
                
                // Limpiar nombre de la canción
                songName = StringTools.replace(songName, "%", "");
                songName = StringTools.trim(songName);
                
                addFreeplaySong(songName, i, char, FlxColor.fromRGB(colors[0], colors[1], colors[2]));
            }
        } catch (e:Dynamic) {
            trace('[ERROR] Error procesando semana ' + weekName + ': ' + e);
            continue;
        }
    }
    
    // Restaurar directorio después de procesar todas las semanas
    WeekData.setDirectoryFromWeek();
}

    function addFreeplaySong(songName:String, weekNum:Int, songCharacter:String, color:Int) {
        freeplaySongs.push({
			songName: songName,
			week: weekNum,
			songCharacter: songCharacter,
			color: color,
			folder: Mods.currentModDirectory
		});
    }

    function weekIsLocked(name:String):Bool {
        var leWeek:WeekData = WeekData.weeksLoaded.get(name);
        return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
    }
    
    function updateFreeplayText() {
        if (weekHeaders != null) {
            for (item in weekHeaders.members) {
                if (item != null && Std.isOfType(item, Alphabet)) {
                    var alphabetItem:Alphabet = cast item;
                    alphabetItem.scale.set(textScale, textScale);
                }
            }
        }
    }

    function updateFreeplayPositions() {
        if (weekHeaders == null) return;

        var index = 0;
        for (item in weekHeaders.members) {
            if (item != null && Std.isOfType(item, Alphabet)) {
                var alphabetItem:Alphabet = cast item;
                var targetX = baseTextX;
                var targetY = baseTextY + (index * 60);

                alphabetItem.x = targetX;
                alphabetItem.y = targetY;
                alphabetItem.alpha = index == curSelectedFreeplay ? 1 : 0.6;
                alphabetItem.startPosition.set(targetX, targetY);
                alphabetItem.offset.set(0, 0);
                alphabetItem.velocity.set(0, 0);
                alphabetItem.snapToPosition();
                FlxTween.cancelTweensOf(alphabetItem);
                index++;
            }
        }
    }

    function updateFreeplaySelection(oldSelected:Int = -1) {
        if (weekHeaders == null) return;

        for (item in weekHeaders.members) {
            if (item != null && Std.isOfType(item, Alphabet)) {
                var alphabetItem:Alphabet = cast item;
                alphabetItem.x = ((alphabetItem.targetY - lerpSelectedFreeplay) * alphabetItem.distancePerItem.x) + alphabetItem.startPosition.x;
                alphabetItem.y = ((alphabetItem.targetY - lerpSelectedFreeplay) * 1.3 * alphabetItem.distancePerItem.y) + alphabetItem.startPosition.y;
                alphabetItem.alpha = alphabetItem.targetY == curSelectedFreeplay ? 1 : 0.6;
                alphabetItem.angle = 0;
            }
        }
    }

    function populateFreeplayVisuals() {
        // Eliminar weekHeaders existente si hay uno
        if (weekHeaders != null) {
            remove(weekHeaders);
            weekHeaders.destroy();
        }

        // Crear nuevo weekHeaders
        weekHeaders = new FlxTypedGroup<Alphabet>();
        add(weekHeaders);

        if (freeplayBg != null) freeplayBg.clear();

        for (i in 0...freeplaySongs.length) {
            var song = freeplaySongs[i];

            try {
                var name:String = song.songName;
                if (name == null || name == "") {
                    trace('[WARNING] Canción en índice ' + i + ' tiene nombre nulo, usando "Unknown"');
                    name = "Unknown Song";
                } else {
                    name = StringTools.trim(name);
                    if (name.length == 0) name = "Unknown Song";
                }
                
                // Crear el texto con animación pero sin ángulo
                var songText:Alphabet = new Alphabet(baseTextX, baseTextY, name, true);
                songText.isMenuItem = false; // Desactivar el ángulo
                songText.targetY = i; // Índice del elemento
                songText.scale.set(textScale, textScale);
                
                // Mantener el texto recto
                songText.angle = 0;
                
                // Configurar distancePerItem como en FreeplayState
                songText.distancePerItem.set(0, 120);
                
                // Guardar posición inicial
                songText.startPosition.set(baseTextX, baseTextY);
                
                var maxWidth = 980 * (1/textScale);
                if (songText.width > maxWidth)
                {
                    songText.scaleX = maxWidth / songText.width;
                }
                
                // Desactivar cualquier animación o movimiento
                songText.snapToPosition();
                FlxTween.cancelTweensOf(songText);
                weekHeaders.add(songText);
                
            } catch(e) {
                var errorSongName:String = (song != null && song.songName != null) ? song.songName : "Unknown";
                trace('[ERROR] Error al crear texto para ' + errorSongName + ': ' + e.toString());
                // En caso de error, crear un texto de error visible
                var errorText = new Alphabet(0, 0, "Error: " + errorSongName, true);
                errorText.screenCenter(X);
                errorText.x += 2510;
                errorText.color = FlxColor.RED;
                errorText.isMenuItem = true;
                errorText.targetY = i - curSelectedFreeplay;
                errorText.distancePerItem.y = 120;
                weekHeaders.add(errorText);
            }
        }
        
        // Actualizar posiciones y estados visuales
        updateFreeplaySelection(-1);
    }
   
    // --- fullBlack control vars ---
    var fullBlackX:Float = -6;
    var fullBlackY:Float = 1841;
    var fullBlackWidth:Float = 4.0;
    var fullBlackHeight:Float = 1.3;
    var fullBlackText:FlxText;
    // --- cam control vars ---
    var camX:Float = 0;
    var camY:Float = 0;
    var camText:FlxText;
    // --- blackFade control vars ---
    var blackFadeWidth:Float = 4.0;
    var blackFadeHeight:Float = 1.3;
    var blackFadeX:Float = -6;
    var blackFadeY:Float = 484;
    var blackFadeText:FlxText;
    // Activa el menú custom (navegación, animaciones, etc)
    function activateMenu() {
        // Si ya está activo, no hacer nada
        if (menuRevealed) return;
        // Solo inicializar elementos del menú principal (main menu)
        addMiddleShit();
        addRightShit(); // IMPORTANTE: agregar elementos del menú derecho
        addTextShit();

        // Mostrar y resetear los elementos del mainmenu
        if (middle != null) { middle.visible = true; middle.alpha = 1; middle.setPosition(0,0); }
        if (right != null) { right.visible = true; right.alpha = 1; right.setPosition(0,0); }
        if (optionText != null) { optionText.visible = true; optionText.alpha = 1; optionText.setPosition(-60,40); }
        if (selectedText != null) { selectedText.visible = true; selectedText.alpha = 1; selectedText.setPosition(-60,40); }
        if (optionBg != null) { optionBg.visible = true; optionBg.alpha = 1; optionBg.setPosition(-60,40); }
        // Ocultar elementos del freeplay
        if (freeplayBg != null) { freeplayBg.visible = false; }
        if (freeplayText != null) { freeplayText.visible = false; }
        if (freeplaySelectedText != null) { freeplaySelectedText.visible = false; }
        if (difficulties != null) { difficulties.visible = false; }
        // extraShit no existe como variable global, los elementos de addExtraShit se controlan individualmente

        // Ocultar/Desactivar elementos de otros menús
        // Puedes agregar aquí más grupos/elementos secundarios si existen

        // Transición animada y habilitar navegación
        enterMain(false);
        curMenu = "main";
    }
    public override function update(elapsed:Float)
    {
        super.update(elapsed);
        if (menuTransitionCamera != null) {
            menuTransitionCamera.zoom = FlxG.camera.zoom;
            menuTransitionCamera.scroll.copyFrom(FlxG.camera.scroll);
        }

        // Detectar cambios en las preferencias de shaders y recargar si es necesario
        var currentShaderState = ClientPrefs.data.shaders;
        var currentMenuShaderState = ClientPrefs.data.menuShaders;
        
        if (currentShaderState != lastShaderState || currentMenuShaderState != lastMenuShaderState) {
            trace('[SHADERS] Cambio detectado - shaders: $currentShaderState, menuShaders: $currentMenuShaderState');
            lastShaderState = currentShaderState;
            lastMenuShaderState = currentMenuShaderState;
            
            // Recargar shaders y ajustar zoom
            reloadShaderSettings();
        }

        // Animar suavemente lerpSelectedFreeplay como en FreeplayState (misma fórmula exacta)
        if (curMenu == "freeplay") {
            lerpSelectedFreeplay = FlxMath.lerp(curSelectedFreeplay, lerpSelectedFreeplay, Math.exp(-elapsed * 9.6));
            updateFreeplaySelection(); // Actualizar cada frame con la interpolación
            updateFreeplayClock(elapsed);
            
            // Debug avanzado: mostrar info del freeplay cuando está en modo dev
            if (isDevMode && coordsText != null) {
                coordsText.text = '=== FREEPLAY DEBUG ===\n' +
                    'X: ${Math.round(baseTextX)} | Y: ${Math.round(baseTextY)}\n' +
                    'Canción: ${curSelectedFreeplay}/${freeplaySongs.length - 1}\n' +
                    'Interpolación: ${FlxMath.roundDecimal(lerpSelectedFreeplay, 2)}\n' +
                    'Escala: ${FlxMath.roundDecimal(textScale, 2)}\n' +
                    '(F/H:X  T/G:Y  O/P:Escala)';
                coordsText.visible = zoomActive; // MOSTRAR CUANDO ZOOM ACTIVO
            }
        } else {
            if (coordsText != null) { // Mostrar solo si zoomActive
                coordsText.visible = zoomActive;
            }
        }

        titleInputBlockTimer = Math.max(0, titleInputBlockTimer - elapsed);

        // Decrementar timer de bloqueo de input
        if (inputBlockTimer > 0) {
            inputBlockTimer -= elapsed;
            if (inputBlockTimer <= 0) {
                inputBlockTimer = 0;
            }
        }

        // Activar/desactivar modo de edición con F2
        // Control para coordenadas de songText (F3)
        if (FlxG.keys.justPressed.F3) {
            if (weekHeaders != null) {
                for (item in weekHeaders.members) {
                    if (item != null && Std.isOfType(item, Alphabet)) {
                        var songText:Alphabet = cast item;
                    }
                }
            }
        }

        // Control para mostrar nombres de assets (F4)
        if (FlxG.keys.justPressed.F4) {
            showAssetNames = !showAssetNames;
            if (showAssetNames && zoomActive) {
                createAssetLabels();
            } else {
                clearAssetLabels();
            }
            trace('[DEBUG] Nombres de assets ' + (showAssetNames ? 'activados' : 'desactivados'));
        }

        // Control para modo edición (F2) - SIMPLIFICADO PARA DEBUG
        if (isDevMode && FlxG.keys.justPressed.F2) {
            // Verificar si debug menu está habilitado en gameData.ini
            var gameConfig = GameConfig.getInstance();
            var debugMenuEnabled = gameConfig.getBool("menu", "debugmenuenabled", true);
            
            if (!debugMenuEnabled) {
                trace('[DEBUG] Debug menu deshabilitado en gameData.ini (debugMenuEnabled = false)');
                return;
            }
            
            trace('[DEBUG] F2 presionado - modo edición simplificado');
            zoomActive = !zoomActive;
            trace('[DEBUG] Modo edición ' + (zoomActive ? 'activado' : 'desactivado'));
            return; // SALIR INMEDIATAMENTE PARA EVITAR CRASH
        }

        // Solo procesar estos controles si el modo de edición está activo - ACTIVADO
        if (zoomActive) {
            // Mover texto del freeplay con TFGH
            if (FlxG.keys.pressed.T) {
                baseTextY -= FlxG.keys.pressed.SHIFT ? 2 : 10;
                updateFreeplayPositions();
            }
            if (FlxG.keys.pressed.G) {
                baseTextY += FlxG.keys.pressed.SHIFT ? 2 : 10;
                updateFreeplayPositions();
            }
            if (FlxG.keys.pressed.F) {
                baseTextX -= FlxG.keys.pressed.SHIFT ? 2 : 10;
                updateFreeplayPositions();
            }
            if (FlxG.keys.pressed.H) {
                baseTextX += FlxG.keys.pressed.SHIFT ? 2 : 10;
                updateFreeplayPositions();
            }
            
            // Actualizar coordenadas en el texto informativo
            if (coordsText != null) {
                coordsText.text = 'Pos X: ${Math.round(baseTextX)}\nPos Y: ${Math.round(baseTextY)}';
            }
            
            // Actualizar posición del cuadro y textos
            
            
            // Control de escala del texto con O/P
            if (FlxG.keys.pressed.O) {
                textScale = Math.max(0.5, textScale - 0.02);
                updateFreeplayText();
            }
            if (FlxG.keys.pressed.P) {
                textScale = Math.min(2.0, textScale + 0.02);
                updateFreeplayText();
            }
            
            // Actualizar texto informativo
            if (coordsText != null) {
                if (weekHeaders != null && weekHeaders.members.length > 0) {
                    var firstSongText = weekHeaders.members[0];
                    coordsText.text = 'SongText Pos:\nX: ${Math.round(firstSongText.x)}\nY: ${Math.round(firstSongText.y)}\nBase X: ${Math.round(baseTextX)}\nBase Y: ${Math.round(baseTextY)}';
                } else {
                    coordsText.text = 'Pos X: ${Math.round(baseTextX)}\nPos Y: ${Math.round(baseTextY)}';
                }
            }
            if (scaleText != null) {
                scaleText.text = 'Escala: ${FlxMath.roundDecimal(textScale, 2)}';
            }
        }
        if (zoomActive) {
            // Cambiar sprite seleccionado
            if (FlxG.keys.justPressed.F5) {
                selectedSprite = 0;
            }
            if (FlxG.keys.justPressed.F6) {
                selectedSprite = 1;
            }
            if (FlxG.keys.justPressed.F7) {
                selectedSprite = 2;
                trace('Seleccionado: right6light');
            }
            if (FlxG.keys.justPressed.F8) {
                selectedSprite = 3;
                trace('Seleccionado: jan');
            }
            // Números del 1 al 6 con Shift + 1-6
            if (FlxG.keys.pressed.SHIFT) {
                if (FlxG.keys.justPressed.ONE) {
                    selectedSprite = 4;
                    trace('Seleccionado: num1');
                }
                if (FlxG.keys.justPressed.TWO) {
                    selectedSprite = 5;
                    trace('Seleccionado: num2');
                }
                if (FlxG.keys.justPressed.THREE) {
                    selectedSprite = 6;
                    trace('Seleccionado: num3');
                }
                if (FlxG.keys.justPressed.FOUR) {
                    selectedSprite = 7;
                    trace('Seleccionado: num4');
                }
                if (FlxG.keys.justPressed.FIVE) {
                    selectedSprite = 8;
                    trace('Seleccionado: num5');
                }
                if (FlxG.keys.justPressed.SIX) {
                    selectedSprite = 9;
                    trace('Seleccionado: num6');
                }
                if (FlxG.keys.justPressed.SEVEN) {
                    selectedSprite = 10;
                    trace('Seleccionado: num7');
                }
            }
            // ClockTick con F9
            if (FlxG.keys.justPressed.F9) {
                selectedSprite = 10;
                trace('Seleccionado: clockTick');
            }
            // Jan con F10
            if (FlxG.keys.justPressed.F10) {
                selectedSprite = 11;
                trace('Seleccionado: jan');
            }
            
            // Right2, Right3, Right4 con Alt + F5-F7
            if (FlxG.keys.pressed.ALT) {
                if (FlxG.keys.justPressed.F5) {
                    selectedSprite = 12;
                    trace('Seleccionado: right2');
                }
                if (FlxG.keys.justPressed.F6) {
                    selectedSprite = 13;
                    trace('Seleccionado: right3');
                }
                if (FlxG.keys.justPressed.F7) {
                    selectedSprite = 14;
                    trace('Seleccionado: right4');
                }
            }

            // Obtener el sprite actual basado en la selección y verificar que no sea null
            var currentSprite:FlxSprite = null;
            try {
                currentSprite = switch(selectedSprite) {
                    case 0 if (right6 != null): right6;
                    case 1 if (right6dark != null): right6dark;
                    case 2 if (right6light != null): right6light;
                    case 3 if (jan != null): jan;
                    case 4 if (num1 != null): num1;
                    case 5 if (num2 != null): num2;
                    case 6 if (num3 != null): num3;
                    case 7 if (num4 != null): num4;
                    case 8 if (num5 != null): num5;
                    case 9 if (num6 != null): num6;
                    case 10 if (clockTick != null): clockTick;
                    case 11 if (jan != null): jan;
                    case 12 if (right2 != null): right2;
                    case 13 if (right3 != null): right3;
                    case 14 if (right4 != null): right4;
                    default: null;
                };
                
                if (currentSprite == null) {
                    trace('[ERROR] Sprite no disponible: ' + selectedSprite);
                    selectedSprite = 0; // Resetear la selección
                    return;
                }
            } catch(e:Dynamic) {
                trace('[ERROR] Error al seleccionar sprite: ' + e);
                return;
            }

            // Movimiento con IJKL para el sprite seleccionado
            if (FlxG.keys.pressed.L) {
                currentSprite.x += moveSpeed * elapsed;
                trace('Moviendo derecha: ${currentSprite.x}');
            }
            if (FlxG.keys.pressed.J) {
                currentSprite.x -= moveSpeed * elapsed;
                trace('Moviendo izquierda: ${currentSprite.x}');
            }
            if (FlxG.keys.pressed.K) {
                currentSprite.y += moveSpeed * elapsed;
                trace('Moviendo abajo: ${currentSprite.y}');
            }
            if (FlxG.keys.pressed.I) {
                currentSprite.y -= moveSpeed * elapsed;
                trace('Moviendo arriba: ${currentSprite.y}');
            }

            // Control de zoom con Q/E
            if (FlxG.keys.pressed.Q) 
                FlxG.camera.zoom = Math.max(0.1, FlxG.camera.zoom - zoomSpeed);
            if (FlxG.keys.pressed.E) 
                FlxG.camera.zoom = Math.min(3, FlxG.camera.zoom + zoomSpeed);

            // Ajustar velocidad con CTRL
            if (FlxG.keys.pressed.CONTROL) {
                moveSpeed = baseSpeed * 0.25; // 1/4 de la velocidad normal
            } else {
                moveSpeed = baseSpeed;
            }
            
            // Ajustar velocidad de zoom con SHIFT
            zoomSpeed = FlxG.keys.pressed.SHIFT ? 0.03 : 0.01;

            // Actualizar texto de coordenadas
            var spriteName = switch(selectedSprite) {
                case 0: 'right6';
                case 1: 'right6dark';
                case 2: 'right6light';
                case 3: 'jan';
                case 4: 'num1';
                case 5: 'num2';
                case 6: 'num3';
                case 7: 'num4';
                case 8: 'num5';
                case 9: 'num6';
                case 10: 'clockTick';
                case 11: 'jan';
                case 12: 'right2';
                case 13: 'right3';
                case 14: 'right4';
                default: 'ninguno';
            };
            var speedState = FlxG.keys.pressed.CONTROL ? "LENTO" : "NORMAL";
            if (coordsText != null) {
                coordsText.text = 'Sprite: $spriteName\nX: ${Math.round(currentSprite.x)}\nY: ${Math.round(currentSprite.y)}\nVelocidad: ${Math.round(moveSpeed)} ($speedState)';
            }

            // Imprimir las coordenadas cuando se presiona P
            if (FlxG.keys.justPressed.P)
            {
                trace('Sprite seleccionado: $spriteName');
                trace('Coordenadas: ${currentSprite.x},${currentSprite.y}');
            }

            // Actualizar texto del zoom - HABILITADO EN DEV MODE
            if (zoomText != null) {
                zoomText.text = "Zoom: " + FlxMath.roundDecimal(FlxG.camera.zoom, 2) + "x";
                zoomText.alpha = 1; // VISIBLE
                zoomText.visible = true; // VISIBLE
            }
            
            // --- EDIT MODE right1 (solo en modo dev) ---
            if (FlxG.keys.justPressed.F4) {
                right1Edit = !right1Edit;
                trace('[right1 EDIT] ' + (right1Edit ? 'ACTIVADO' : 'DESACTIVADO'));
                if (right1Edit && right1 != null) trace('[right1 EDIT] Pos inicial: x='+Math.floor(right1.x)+' y='+Math.floor(right1.y)+' sfX='+right1.scrollFactor.x+' sfY='+right1.scrollFactor.y);
            }
            if (right1Edit && right1 != null) {
                var step:Float = FlxG.keys.pressed.SHIFT ? right1MoveStep * 4 : right1MoveStep;
                if (FlxG.keys.pressed.LEFT) right1.x -= step;
                if (FlxG.keys.pressed.RIGHT) right1.x += step;
                if (FlxG.keys.pressed.UP) right1.y -= step;
                if (FlxG.keys.pressed.DOWN) right1.y += step;
                if (FlxG.keys.pressed.Q) right1.scrollFactor.x = Math.max(0, right1.scrollFactor.x - 0.01);
                if (FlxG.keys.pressed.E) right1.scrollFactor.x += 0.01;
                if (FlxG.keys.pressed.W) right1.scrollFactor.y = Math.max(0, right1.scrollFactor.y - 0.01);
                if (FlxG.keys.pressed.S) right1.scrollFactor.y += 0.01;
                if (FlxG.keys.justPressed.R) {
                    right1.x = -366; right1.y = -467; right1.scrollFactor.set(0,0);
                    trace('[right1 EDIT] Reset a valores por defecto');
                }
                if (FlxG.keys.justPressed.F5 && !FlxG.keys.pressed.ALT) trace('[right1 EDIT] Pos x='+Math.floor(right1.x)+' y='+Math.floor(right1.y)+' sfX='+right1.scrollFactor.x+' sfY='+right1.scrollFactor.y);
            }
        }

        increaseTime += elapsed;
        updateShaders();

        if (curMenu == "title" || curMenu == "main" || menuRevealed) {
            inputShit();
        }
        
        // Tecla 6 - Ir a Mods con transición de story mode
        if (FlxG.keys.justPressed.SIX && !FlxG.keys.pressed.SHIFT) {
            startModsMenu();
        }
        
        // Debug menu con tecla 7 (disponible en cualquier momento)
        if (FlxG.keys.justPressed.SEVEN && !FlxG.keys.pressed.SHIFT) {
            FlxG.sound.play(Paths.sound('confirmMenu'));
            MusicBeatState.switchState(new MasterEditorMenu());
        }
    }

    private function checkEditModeElements():Bool {
        // Verificar que los elementos básicos de UI existan
        if (coordsText == null) {
            trace('[ERROR] coordsText no está inicializado');
            return false;
        }
        if (zoomText == null) {
            trace('[WARNING] zoomText no está inicializado - continúa de todos modos');
            // No retornamos false aquí porque zoomText no es crítico
        }

        // Verificar que los sprites editables existan
        var spritesOK = true;
        if (right6 == null) { trace('[ERROR] right6 no está inicializado'); spritesOK = false; }
        if (right6dark == null) { trace('[ERROR] right6dark no está inicializado'); spritesOK = false; }
        if (right6light == null) { trace('[ERROR] right6light no está inicializado'); spritesOK = false; }
        if (jan == null) { trace('[ERROR] jan no está inicializado'); spritesOK = false; }
        if (num1 == null) { trace('[ERROR] num1 no está inicializado'); spritesOK = false; }
        if (num2 == null) { trace('[ERROR] num2 no está inicializado'); spritesOK = false; }
        if (num3 == null) { trace('[ERROR] num3 no está inicializado'); spritesOK = false; }
        if (num4 == null) { trace('[ERROR] num4 no está inicializado'); spritesOK = false; }
        if (num5 == null) { trace('[ERROR] num5 no está inicializado'); spritesOK = false; }
        if (num6 == null) { trace('[ERROR] num6 no está inicializado'); spritesOK = false; }
        if (clockTick == null) { trace('[ERROR] clockTick no está inicializado'); spritesOK = false; }
        if (right2 == null) { trace('[ERROR] right2 no está inicializado'); spritesOK = false; }
        if (right3 == null) { trace('[ERROR] right3 no está inicializado'); spritesOK = false; }
        if (right4 == null) { trace('[ERROR] right4 no está inicializado'); spritesOK = false; }

        return spritesOK;
    }

    private function createAssetLabels():Void {
        try {
            // Limpiar labels existentes
            clearAssetLabels();
            
            // Array de sprites con sus nombres
            var assets = [
                {sprite: right1, name: "right1"},
                {sprite: right2, name: "right2"},
                {sprite: right3, name: "right3"},
                {sprite: right4, name: "right4"},
                {sprite: right6, name: "right6"},
                {sprite: right6dark, name: "right6dark"},
                {sprite: right6light, name: "right6light"},
                {sprite: jan, name: "jan"},
                {sprite: clockTick, name: "clockTick"},
                {sprite: num1, name: "num1"},
                {sprite: num2, name: "num2"},
                {sprite: num3, name: "num3"},
                {sprite: num4, name: "num4"},
                {sprite: num5, name: "num5"},
                {sprite: num6, name: "num6"}
            ];
            
            // Crear texto para cada asset
            for (asset in assets) {
                if (asset.sprite != null && asset.sprite.graphic != null) {
                    var label = new FlxText(0, 0, 0, asset.name, 16);
                    label.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.YELLOW, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
                    label.borderSize = 2;
                    label.cameras = [uiCamera]; // Usar cámara UI para que siempre sea visible
                    
                    // Posicionar encima del sprite
                    label.x = asset.sprite.x + (asset.sprite.width * asset.sprite.scale.x / 2) - (label.width / 2);
                    label.y = asset.sprite.y - 25; // 25 pixels arriba del sprite
                    
                    assetLabels.push(label);
                    add(label);
                }
            }
        } catch (e) {
            trace('[ERROR] Error en createAssetLabels: ' + e);
        }
    }
    
    private function clearAssetLabels():Void {
        for (label in assetLabels) {
            if (label != null) {
                remove(label, true);
                label.destroy();
            }
        }
        assetLabels = [];
    }
    
    private function updateAssetLabelsVisibility():Void {
        for (label in assetLabels) {
            if (label != null) {
                label.visible = showAssetNames && zoomActive;
            }
        }
    }

    private function updateShaders():Void
    {
        // Actualización simple de shaders
        if (!ClientPrefs.data.shaders || ClientPrefs.data.menuShaders) {
            return;
        }
        
        try {
            var time = FlxG.game.ticks / 1000.0;
            
            if (water != null) {
                water.setFloat('iTime', time);
            }
            if (lens != null) {
                lens.setFloat('iTime', time);
                lens.setFloat('ushaderStrength', lensStrength);
            }
            if (blur != null) {
                blur.setFloat('iTime', time);
                blur.setFloat('strength', blurAmount);
                blur.setFloat('angle', blurAngle);
            }
        } catch (e:Dynamic) {
            trace('[SHADER] Error actualizando: ' + e);
        }
    }
    
    private function updateFreeplayGlitch(time:Float):Void
    {
        // Las animaciones del freeplay se manejan en updateFreeplaySelection()
        // Esta función es para efectos adicionales si es necesario
    }

    public function reloadShaderSettings():Void
    {
        trace('[SHADERS] Recargando shaders...');
        
        try {
            // Limpiar y recargar
            FlxG.camera.setFilters([]);
            addShaderShit(); // Usar la función que existe
            
            // Ajustar zoom según shaders
            var targetZoom:Float = 0.593;
            
            FlxTween.cancelTweensOf(FlxG.camera, ["zoom"]);
            FlxTween.tween(FlxG.camera, {zoom: targetZoom}, 0.5, {ease: FlxEase.sineInOut});
            
            trace('[SHADERS] Shaders recargados');
        } catch (e:Dynamic) {
            trace('[ERROR] Error recargando shaders: ' + e);
        }
    }



    public static var psychEngineVersion:String = "1.0.4";
    var devSelectedRightAsset:Int = 0;
    // --- DEV MODE: mover right5 ---
    var devModeRight5:Bool = false;
var devTextRight5:FlxText;

    var object:FlxSprite;

    var titleScreen:FlxSpriteGroup;
    var optionText:FlxSpriteGroup;
    var selectedText:FlxSpriteGroup;
    var optionBg:FlxSpriteGroup;
    var freeplayText:FlxSpriteGroup = new FlxSpriteGroup();
    var freeplaySelectedText:FlxSpriteGroup = new FlxSpriteGroup();
    var freeplayBg:FlxSpriteGroup = new FlxSpriteGroup();
    var difficulties:FlxSpriteGroup = new FlxSpriteGroup();
    // --- right menu elements for visibility control ---
    var right1:FlxSprite;
    // Modo edición de right1
    var right1Edit:Bool = false;
    var right1MoveStep:Int = 10;
    var right6:FlxSprite;
    var right5:FlxSprite;
    var right2:FlxSprite;
    var right3:FlxSprite;
    var right4:FlxSprite;
    var jan:FlxSprite;
    var right6dark:FlxSprite;
    var right6light:FlxSprite;
    var rightRays:FlxSprite;
    var rightRays2:FlxSprite;

    var diffSelectR:FlxSprite;
    var diffSelectL:FlxSprite;

    // camera
    var camFollow:FlxSprite;
    var camFollowPos:FlxObject;

    // clock
    var values:Array<{ target:Float, desired:Float, speed:Float, prev:Float }> = [];
    var num1:FlxSprite;
    var num2:FlxSprite;
    var num3:FlxSprite;
    var num4:FlxSprite;
    var num5:FlxSprite;
    var num6:FlxSprite;

    // Asset name labels for dev mode
    var assetLabels:Array<FlxText> = [];
    var showAssetNames:Bool = false;

    // visuals
    var middle:FlxSpriteGroup;
    var right:FlxSpriteGroup;
    var bfFloat:FlxSprite;
    var layer1:FlxSprite;
    var layer2:FlxSprite;
    var blackFade:FlxSprite;
    var fullBlack:FlxSprite;
    var blackCovering:FlxSprite;
    var blackTop:FlxSprite;

    // sorry
    var titleLogo:FlxSprite;
    var titlePart0:FlxSprite;
    var titlePart1:FlxSprite;
    var titlePart2:FlxSprite;
    var titlePart3:FlxSprite;
    var titlePart4:FlxSprite;
    var titlePart5:FlxSprite;
    var titlePart6:FlxSprite;

    // extras menu
    var bfFloatRed:FlxSprite;
    var bgRed:FlxSprite;
    var buildingRed:FlxSprite;
    var chainRed:FlxSprite;
    var ifBg:FlxSprite;
    var ifText:FlxSprite;
    var ifSelected:FlxSprite;
    var sidestoryBg:FlxSprite;
    var sidestoryText:FlxSprite;
    var sidestorySelected:FlxSprite;

    // text groups
    var freeplaySongTexts:FlxTypedGroup<Alphabet>;
    var weekHeaders:FlxTypedGroup<Alphabet>;

    // functionality
    var curSelected:Int = 0;
    var curSelectedFreeplay:Int = 0;
    var lerpSelectedFreeplay:Float = 0; // Para animación suave como en FreeplayState
    var prevSelectedFreeplay:Int = 0;
    var curDiff:Int = 1; // 0=Easy, 1=Normal, 2=Hard
    var curSelectedExtra:Int = 0;
    var selectedSomethin:Bool = false;
    var canSelect:Bool = true;
    var errorDialogBlocked:Bool = false; // Bloquear input después de cerrar mensaje de error
    var inputBlockTimer:Float = 0; // Timer para bloquear input durante transiciones
    var errorDialogActive:Bool = false; // Control global para error dialog
    var errorAutoCloseTimer:FlxTimer; // Timer global para auto-cerrar error
    var forceCloseErrorDialog:Bool = false; // Forzar cierre desde input rápido
    var curMenu:String = "title";

    // audio
    var musicGroup:FlxTypedGroup<FlxSound>;

    // shader stuff
    private var wave:FlxRuntimeShader;
    private var lens:FlxRuntimeShader;
    private var blur:FlxRuntimeShader;
    private var water:FlxRuntimeShader; // ← AÑADIR ESTA VARIABLE
    
    // Runtime shaders map para PsychEngine 1.0.4 compatibility
    #if (!flash && sys)
    public var runtimeShaders:Map<String, Array<String>> = new Map<String, Array<String>>();
    #end
    
    // Efectos de blur
    private var blurAmount:Float = 0.00;
    private var maxBlur:Float = 0.05;
    private var blurAngle:Float = 90;
    
    // Efectos de lente
    private var lensStrength:Float = 0.0;
    private var maxLens:Float = 1.0;
    
    // Para detectar cambios en las preferencias de shaders
    // Inicializar al opuesto para forzar la carga inicial en el primer update
    private var lastShaderState:Bool = false;
    private var lastMenuShaderState:Bool = true;  // Opuesto al default (que será false)

    // tweens
    var initialTween:FlxTween;
    var harvesterEye:FlxTween;
    var titleInputBlockTimer:Float = 0;
    var diffTween:FlxTween;
    var diffSelectRightTween:FlxTween;
    var diffSelectLeftTween:FlxTween;

    var transition:FlxSprite;
    var menuTransitionCamera:FlxCamera;
    var transitionExtras:FlxSprite; // Transición separada para el menú Extras

    var menuRevealed:Bool = false;

    // TIMES EVENTS HAPPEN (If anyone is interested)
    // yes, we really had a call figuring this shit out just for the freeplay menu clock
    // enjoy our findings (down to the second)
    //
    // NULL AND VOID (start of first cutscene): Jan 09, 23:59.57pm
    // Harvester appears: Jan 10, 00:00.00am  (Chooses to reveal himself on the dot midnight, bro is like that)
    // NULL AND VOID (SONG START): Jan 10, 00:01.11am 
    // CHKDSK (SENPAI TRANSFORM): Jan 10, 00:02.55am (There is a few cutscenes before this, but timer is bias towards the song name, so this time appears on the freeplay)
    // CONSOLE CRASHES: Jan 10, 00:06.34 (This time differs slightly between OG video and DEMO, DEMO has a shortened cutscene, we are using OG video timings cuz that stuff still happens even when it is no longer shown.)


    public override function create():Void {
        // trace('[DEBUG] create llamado');
        // trace('[DEBUG] onStateCreate llamado');
        
        // Cargar configuración del menú desde gameData.ini
        var gameConfig = GameConfig.getInstance();
        showFreeplay = gameConfig.getBool("menu", "freeplayenabled", true);
        
        // Cargar datos del alfabeto para Alphabet
        AlphaCharacter.loadAlphabetData();
        
        addShaderShit(); // Usar la función que existe en lugar de initShaders()
        
        // Initialize groups and sprites
        musicGroup = new FlxTypedGroup<FlxSound>();
        add(musicGroup);

        // Inicializar sistema de música
        addMusicShit();

        // Crear los grupos principales
        // IMPORTANTE: right se agrega ANTES que middle para que right1 quede detrás de layer1
        right = new FlxSpriteGroup();
        add(right);
        
        middle = new FlxSpriteGroup();
        add(middle);
        
        // Asegurar que las variables de sprite están inicializadas a null
        jan = null;
        clockTick = null;
        right6 = null;
        right6dark = null;
        right6light = null;
        num1 = null;
        num2 = null;
        num3 = null;
        num4 = null;
        num5 = null;
        num6 = null;
        
        // Inicializar los sprites
        addRightShit();
        
        canSelect = true; // Aseguramos que se puede seleccionar desde el inicio
        curMenu = "title"; // Aseguramos que estamos en el título
        // PlayerSettings.init(); // Removed in 1.0.4
        // WeekData.loadTheFirstEnabledMod(); // Removed in 1.0.4
        
        // Inicializar shaders
        addShaderShit();
        Paths.clearStoredMemory();

        this.persistentUpdate = true;
        this.persistentDraw = true;

        FlxG.mouse.visible = false;
        FlxG.camera.bgColor = FlxColor.BLACK;

        // Configurar cámara UI
        uiCamera = new FlxCamera();
        uiCamera.bgColor.alpha = 0;
        FlxG.cameras.add(uiCamera, false);

        // Texto para mostrar el zoom
        zoomText = new FlxText(0, 50, FlxG.width, "Zoom: 1.00x");
        zoomText.setFormat("VCR OSD Mono", 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        zoomText.borderSize = 2;
        zoomText.visible = false;
        zoomText.cameras = [uiCamera];
        add(zoomText);

        // Texto para mostrar coordenadas
        coordsText = new FlxText(10, 30, 0, "", 16);
        coordsText.setFormat(null, 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        coordsText.borderSize = 1;
        coordsText.cameras = [uiCamera];
        coordsText.visible = false;
        add(coordsText);



        camFollow = new FlxSprite().makeGraphic(1, 1, 0xFF000000);
        camFollow.alpha = 0;
        camFollow.setPosition(951,570);
        camFollowPos = new FlxObject(951,-270, 1, 1);
        add(camFollow);
        add(camFollowPos);
// zoom state
    var initialZoom = (ClientPrefs.data.shaders && !ClientPrefs.data.menuShaders) ? 0.6 : 0.79;
    FlxG.camera.zoom = initialZoom;  // Zoom ajustado según shaders
    FlxG.camera.follow(camFollowPos, LOCKON, 1);
        // IMPORTANTE: right se agrega ANTES que middle para que right1 quede detrás de layer1
        right = new FlxSpriteGroup();
        add(right);
        middle = new FlxSpriteGroup();
        add(middle);

        // Initialize text groups
        freeplaySongTexts = new FlxTypedGroup<Alphabet>();
        add(freeplaySongTexts);
        weekHeaders = new FlxTypedGroup<Alphabet>();
        add(weekHeaders);

        values = [
            { target: 0, desired: 0, speed: 10.0, prev: 0 },
            { target: 0, desired: 0, speed: 10.0, prev: 50 },
            { target: 0, desired: 0, speed: 10.0, prev: 30 },
            { target: 0, desired: 0, speed: 20.0, prev: 10 },
            { target: 0, desired: 0, speed: 10.0, prev: 5 },
            { target: 0, desired: 0, speed: 20.0, prev: 0 }
        ];

        blackCovering = new FlxSprite(10,-20).makeGraphic(3000, 3000, FlxColor.BLACK);
    add(blackCovering);
    blackCovering.scrollFactor.set(0,0);
    blackCovering.scale.set(2,2);

        // Precargar assets del menú principal pero mantenerlos ocultos
        addMiddleShit();
        addTextShit();
        addExtraShit();
        addFreeplayText();
        
        // Ocultar todo el menú principal
        if (middle != null) middle.visible = false;
        if (right != null) right.visible = false;
        if (selectedText != null) selectedText.visible = false;
        if (optionBg != null) optionBg.visible = false;
        if (freeplaySongTexts != null) freeplaySongTexts.visible = false;
        if (weekHeaders != null) weekHeaders.visible = false;

        // Solo inicializar el título al principio
        if(showTitle) {
            addTitleShit();
            curMenu = "title";
            canSelect = true;
            menuRevealed = false;
        } else {
            // Build the title even when it is skipped. It stays hidden while
            // entering the menu, but is ready if the player later presses ESC.
            addTitleShit();
            if (harvesterEye != null) harvesterEye.cancel();
            titleInputBlockTimer = 0;
            if (titleScreen != null) titleScreen.visible = false;
            if (titleLogo != null) titleLogo.visible = false;
            if (blackTop != null) {
                FlxTween.cancelTweensOf(blackTop);
                blackTop.alpha = 0;
            }

            // Si por alguna razón showTitle es falso, mostrar el menú directamente
            addMiddleShit();
            addRightShit(); // IMPORTANTE: agregar elementos del menú derecho
            addExtraShit();
            addTextShit();
            addFreeplayText();
            
            // Aplicar shaders directamente al venir de otro state
            addShaderShit();
            lensStrength = 0.5;
            // Aplicar el valor directamente al shader
            if (lens != null) {
                lens.setFloat('ushaderStrength', 0.5);
            }
            
            // Resetear selección
            curSelected = 0;
            curMenu = "main";
            
            // enterMain configurará los textos correctamente
            enterMain(true);
            
            // Forzar actualización de textos DESPUÉS de enterMain
            new FlxTimer().start(0.1, function(tmr:FlxTimer) {
                updateOption();
                tmr.destroy();
            });
            
            // Si viene de Credits/Freeplay/etc, agregar overlay negro que se desvanece en 2 segundos
            if (skipTitle) {
                var creditsBlackOverlay = new FlxSprite().makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFF000000);
                creditsBlackOverlay.screenCenter();
                creditsBlackOverlay.alpha = 1; // Empieza completamente negro
                creditsBlackOverlay.scrollFactor.set(0, 0);
                add(creditsBlackOverlay);
                
                // Desvanecerse en 2 segundos
                FlxTween.tween(creditsBlackOverlay, {alpha: 0}, 2, {
                    ease: FlxEase.sineOut,
                    onComplete: function(twn:FlxTween) {
                        remove(creditsBlackOverlay);
                        creditsBlackOverlay.destroy();
                    }
                });
            }
        }

        // El resto de la inicialización de datos
        if (FlxG.save.data.seenIfNotice == null){
            FlxG.save.data.seenIfNotice = false;
        } else {
            FlxG.save.data.seenIfNotice = false; // Resetear para desarrollo
        }
        if (FlxG.save.data.seenSidestoryNotice == null){
            FlxG.save.data.seenSidestoryNotice = false;
        }

        // AGREGAR TRANSICIÓN AL FINAL PARA QUE ESTÉ DELANTE DE TODO
        transition = new FlxSprite();
        transition.frames = Paths.getSparrowAtlas('burnTransition');
        transition.animation.addByPrefix("idle", 'burnTransition idle', 24, false);
        transition.animation.play("idle", true);
        transition.scrollFactor.set(0,0);
        transition.scale.set(2.5,2.5);
        transition.antialiasing = true;
        transition.alpha = 0;
        transition.blend = BlendMode.MULTIPLY;
        transition.setPosition(150,119);
        transition.cameras = [FlxG.camera];
        add(transition);
    }



    function destroyVid(video){
        return ()->{
            trace("dead");
            remove(video);
            video.destroy();
        }
    }

    function onStateCreatePost(){
        addShaderShit();
        right.setPosition(2510,0);
        updateDifficulty();
        addMusicShit();
        Paths.clearUnusedMemory();
    }

    function onUpdatePost(elapsed:Float){
        // Los shaders se manejan en updateShaders() usando setFloat().
    }

    function enterMain(skipTransition:Bool){
        trace("[DEBUG] Entrando a enterMain");
        curMenu = "main";

        if (musicGroup == null || musicGroup.members == null || musicGroup.members.length == 0) {
            addMusicShit();
        }

        if (musicGroup != null && musicGroup.members != null && musicGroup.length >= 6) {
            trace("[DEBUG] Iniciando transición de música");
            FlxTween.num(0.0, 0.5, 0.8, {ease: FlxEase.sineInOut}, function(hi:Float) {
                lensStrength = hi;
            });

            var fadeTime = 1.2;
            var menu5 = musicGroup.members[5];
            var menu0 = musicGroup.members[0];

            if (menu5 != null && menu0 != null) {
                if (menu5.volume > 0) {
                    FlxTween.tween(menu5, {volume: 0}, fadeTime, {
                        ease: FlxEase.sineInOut,
                        onComplete: function(twn:FlxTween) {
                            menu5.pause();
                        }
                    });
                }

                menu0.play();
                FlxTween.tween(menu0, {volume: 1}, fadeTime, {
                    ease: FlxEase.sineInOut
                });
            }
        } else {
            trace("[ERROR] Grupo de música no inicializado correctamente");
        }

        // Transición suave del zoom - ajustado por shaders
        var targetZoom = (ClientPrefs.data.shaders && !ClientPrefs.data.menuShaders) ? 0.6 : 0.67;
        FlxTween.tween(FlxG.camera, {zoom: targetZoom}, 0.8, {
            ease: FlxEase.sineInOut,
            onComplete: function(twn:FlxTween) {
                FlxG.camera.zoom = targetZoom;
            }
        });

        if(skipTransition){
            // Mostrar elementos del menú principal
            if(middle != null) middle.visible = true;
            if(right != null) right.visible = true;
            
            // IMPORTANTE: Restaurar visibilidad de los grupos de texto
            if(selectedText != null) selectedText.visible = true;
            if(optionBg != null) optionBg.visible = true;
            if(optionText != null) optionText.visible = true;
            
            if(blackCovering != null) blackCovering.alpha = 0;
            if(titlePart1 != null) titlePart1.alpha = 1; 
            if(bfFloat != null) bfFloat.y = bfFloat.y + 10;
            if(camFollowPos != null) camFollowPos.y = 570;
            
            // Aplicar shader lens directamente sin animación
            lensStrength = 0.5;
            if(lens != null) {
                try {
                    lens.setFloat('ushaderStrength', 0.5);
                } catch(e:Dynamic) {
                    trace('[SHADER] Error aplicando lens: ' + e);
                }
            }
            
            if(musicGroup != null && musicGroup.members != null && musicGroup.members.length > 0) updateMusic(0);

            // Configurar los textos del menú respetando curSelected
            if(optionText != null && optionText.members != null) {
                for (i in 0...optionText.members.length) {
                    if(optionText.members[i] != null) {
                        // optionText tiene alpha 0 si está seleccionado, 0.2 si no
                        optionText.members[i].alpha = (i == curSelected) ? 0 : 0.2;
                        optionText.members[i].visible = true; // Restaurar visibilidad
                    }
                }
            }

            if(selectedText != null && selectedText.members != null) {
                for (i in 0...selectedText.members.length) {
                    if(selectedText.members[i] != null) {
                        // selectedText tiene alpha 1 si está seleccionado, 0 si no
                        selectedText.members[i].alpha = (i == curSelected) ? 1 : 0;
                        selectedText.members[i].visible = true; // Restaurar visibilidad
                    }
                }
            }
            
            if(optionBg != null && optionBg.members != null) {
                for (i in 0...optionBg.members.length) {
                    if(optionBg.members[i] != null) {
                        // optionBg tiene alpha 0.2 si está seleccionado, 0 si no
                        optionBg.members[i].alpha = (i == curSelected) ? 0.2 : 0;
                        optionBg.members[i].visible = true; // Restaurar visibilidad
                    }
                }
            }
            canSelect = true;
            menuRevealed = true;

        }else{
            if (harvesterEye != null) harvesterEye.cancel();

            // IMPORTANTE: Restaurar visibilidad de grupos antes de animar
            if(middle != null) middle.visible = true;
            if(right != null) right.visible = true;
            if(selectedText != null) selectedText.visible = true;
            if(optionBg != null) optionBg.visible = true;
            if(optionText != null) optionText.visible = true;

            // Ocultar todos los botones al inicio (aparecerán después con revealMainMenuTexts)
            // Pero asegurarse de que estén VISIBLES para que los tweens funcionen
            if(selectedText != null && selectedText.members != null) {
                for (i in 0...selectedText.members.length) {
                    if(selectedText.members[i] != null) {
                        selectedText.members[i].alpha = 0;
                        selectedText.members[i].visible = true; // IMPORTANTE: visible para tweens
                    }
                }
            }
            if(optionBg != null && optionBg.members != null) {
                for (i in 0...optionBg.members.length) {
                    if(optionBg.members[i] != null) {
                        optionBg.members[i].alpha = 0;
                        optionBg.members[i].visible = true; // IMPORTANTE: visible para tweens
                    }
                }
            }
            if(optionText != null && optionText.members != null) {
                for (i in 0...optionText.members.length) {
                    if(optionText.members[i] != null) {
                        optionText.members[i].alpha = 0;
                        optionText.members[i].visible = true; // IMPORTANTE: visible para tweens
                    }
                }
            }

            // Sonido movido a inputShit() para evitar duplicados

            if (camFollowPos != null)
                initialTween = FlxTween.tween(camFollowPos, {y: 570}, 6, {ease: FlxEase.backOut, onComplete: function(twn:FlxTween) {
                    // La revelación de botones se hace en inputShit() con un timer de 0.5s
                    // Desbloquear input cuando termina la transición de cámara
                    canSelect = true;
                    menuRevealed = true;
                }});
            if (bfFloat != null)
                FlxTween.tween(bfFloat,  {y: bfFloat.y + 10}, 15.0, {ease: FlxEase.sineInOut});
            
            

            if (this.playBubbleAnimation != null) playBubbleAnimation();
            if (musicGroup != null && musicGroup.members != null && musicGroup.members.length > 0) {
                // Transición fluida: menu5 baja mientras menu0 sube
                if (FlxG.sound.music != null) {
                    var fadeTime = 0.8;
                    var targetVolume = 0.8;
                    
                    // Guardar la referencia de menu5
                    var menu5 = FlxG.sound.music;
                    
                    // Crear e iniciar menu0 con volumen 0
                    FlxG.sound.playMusic(Paths.music('menu0'), 0, true);
                    var menu0 = FlxG.sound.music;
                    
                    // Restaurar menu5 como música actual temporalmente
                    FlxG.sound.music = menu5;
                    
                    // Fade out de menu5
                    FlxTween.tween(menu5, {volume: 0}, fadeTime, {
                        ease: FlxEase.sineOut,
                        onComplete: function(twn:FlxTween) {
                            menu5.stop();
                            FlxG.sound.music = menu0;
                        }
                    });
                    
                    // Fade in de menu0 simultáneo
                    FlxTween.tween(menu0, {volume: targetVolume}, fadeTime, {
                        ease: FlxEase.sineIn
                    });
                }
            }

            if (!menuRevealed){
                // Los textos se revelan cuando termina el tween de cámara
                if (this.hideTitleShit != null && curMenu != "extras") hideTitleShit();
            }

            if (blackCovering != null)
                FlxTween.tween(blackCovering,  {alpha: 0}, 1.0, {ease: FlxEase.sineInOut});
            if (titlePart1 != null)
                FlxTween.tween(titlePart1, {alpha: 0}, 0.5, {ease: FlxEase.sineInOut});

            if (lens != null && lens.data != null && lens.data.ushaderStrength != null)
                FlxTween.num(0.0, 0.5, 0.8, {ease: FlxEase.sineInOut}, function(hi){
                    lens.data.ushaderStrength.value = [hi];
                });
        }
    }

    function hideTitleShit(){
    for (layer in [titlePart0, titlePart1, titlePart2, titlePart3, titlePart4, titlePart5, titleLogo])
        if (layer != null) FlxTween.cancelTweensOf(layer);
    // trace("[DEBUG] Entrando a hideTitleShit");
    //new FlxTimer().start(0.0, function(tmr){
    if (titlePart0 != null) {
        FlxTween.tween(titlePart0, {alpha: 0}, 0.4, {ease: FlxEase.sineIn});
    } else {
        // trace('[DEBUG] titlePart0 es null');
    }
    if (titlePart6 != null) {
        FlxTween.tween(titlePart6, {alpha: 0}, 0.4, {ease: FlxEase.sineIn});
    } else {
        trace('[DEBUG] titlePart6 es null');
    }
    if (titlePart2 != null) {
        FlxTween.tween(titlePart2, {alpha: 0}, 0.4, {ease: FlxEase.sineIn});
    } else {
        trace('[DEBUG] titlePart2 es null');
    }
    //tmr.destroy();
    //});

    //new FlxTimer().start(0.1, function(tmr){
    if (titlePart3 != null) {
        FlxTween.tween(titlePart3, {alpha: 0}, 0.4, {ease: FlxEase.sineIn});
    } else {
        trace('[DEBUG] titlePart3 es null');
    }
    if (titlePart4 != null) {
        FlxTween.tween(titlePart4, {alpha: 0}, 0.6, {ease: FlxEase.sineIn});
    } else {
        trace('[DEBUG] titlePart4 es null');
    }
    //tmr.destroy();
    //});
    // Evita bucle de transición y sonido
    menuRevealed = true;
    
    // Mostrar elementos del menú que ya fueron precargados
    if (middle != null) middle.visible = true;
    if (right != null) right.visible = true;
    if (selectedText != null) selectedText.visible = true;
    if (optionBg != null) optionBg.visible = true;
    
    enterMain(false); // Llamada sin delay porque ya no hay carga bloqueante

    //new FlxTimer().start(0.2, function(tmr){
        if (titlePart5 != null) {
            FlxTween.tween(titlePart5, {alpha: 0}, 0.4, {ease: FlxEase.sineIn});
        } else {
            trace('[DEBUG] titlePart5 es null');
        }
        if (titleLogo != null) {
            FlxTween.tween(titleLogo, {alpha: 0}, 0.4, {ease: FlxEase.sineIn});
        } else {
            trace('[DEBUG] titleLogo es null');
        }
        //tmr.destroy();
    //});
}

 function startIf() {
        if(initialTween != null)
            initialTween.cancel();
        
        initialTween = FlxTween.tween(FlxG.camera, {zoom: 0.8}, 1.2, {ease: FlxEase.backIn, onComplete: storyTweenZoom});

        for(i in 0...6){
            if (musicGroup.members[i].volume != 0){
                musicGroup.members[i].fadeOut(1,0);
            }
        }

        FlxG.sound.play(Paths.sound('confirmMenu'));
        FlxG.sound.play(Paths.sound('water rush'));

        new FlxTimer().start(0.75, function(tmr){
            trace('[DEBUG] startIf - Timer 0.75s ejecutado. transitionExtras es: ' + transitionExtras);
            if (transitionExtras != null) {
                trace('[DEBUG] startIf - transitionExtras.alpha ANTES: ' + transitionExtras.alpha);
                trace('[DEBUG] startIf - transitionExtras.visible ANTES: ' + transitionExtras.visible);
                transitionExtras.alpha = 1;
                trace('[DEBUG] startIf - transitionExtras.alpha DESPUÉS DE SETEAR: ' + transitionExtras.alpha);
                if (transitionExtras.animation != null) {
                    trace('[DEBUG] startIf - Reproduciendo animación "idle"');
                    transitionExtras.animation.play("idle", true);
                    trace('[DEBUG] startIf - Animación reproduciéndose: ' + transitionExtras.animation.name + ' | Fotograma: ' + transitionExtras.animation.frameIndex);
                } else {
                    trace('[ERROR] startIf - transitionExtras.animation es null!');
                }
            } else {
                trace('[ERROR] startIf - transitionExtras es null!');
            }
            tmr.destroy();
        });

        new FlxTimer().start(1.7, function(tmr2){
            trace('[DEBUG] startIf - Timer 1.7s ejecutado. blackCovering: ' + blackCovering);
            if (blackCovering != null) {
                blackCovering.alpha = 1;
                trace('[DEBUG] startIf - blackCovering.alpha seteado a 1');
            }
            tmr2.destroy();
        });

        new FlxTimer().start(6, function(tmr3){
            trace('[DEBUG] startIf - Timer 6s ejecutado. Intentando cambiar de state...');
            if (FlxG.save.data.seenIfNotice == true) {
                trace('[DEBUG] startIf - seenIfNotice es true, entrando a IfMenu');
                MusicBeatState.switchState(new IfMenu());
            } else {
                trace('[DEBUG] startIf - seenIfNotice es false, entrando a IfNotice');
                FlxG.save.data.seenIfNotice = true;
                MusicBeatState.switchState(new IfNotice());
            }
            tmr3.destroy();
        });
    }

function addTitleShit(){
    trace('[DEBUG] addTitleShit llamado');

    // Establecer zoom inicial - ajustado por shaders
    var initialZoom = (ClientPrefs.data.shaders && !ClientPrefs.data.menuShaders) ? 0.6 : 0.59;
    FlxG.camera.zoom = initialZoom;

    titleScreen = new FlxSpriteGroup();
    add(titleScreen);
    // Restaurar posición original del grupo y logo
    titleScreen.setPosition(740,-870);
    titleScreen.scale.set(1.1,1.1);

   

    titlePart0 = new FlxSprite(0,0, Paths.image('menus/title/title0'));
    titlePart0.scrollFactor.set(1,1);
    titlePart0.scale.set(1,1);
    titlePart0.alpha = 1;
    titleScreen.add(titlePart0);

    titlePart1 = new FlxSprite(0,164, Paths.image('menus/title/title1'));
    titlePart1.scrollFactor.set(1,1);
    titlePart1.scale.set(1,1);
    titlePart1.alpha = 1;
    titleScreen.add(titlePart1);

    titlePart2 = new FlxSprite(0,0, Paths.image('menus/title/title2'));
    titlePart2.scrollFactor.set(1,1);
    titlePart2.scale.set(1,1);
    titlePart2.alpha = 1;
    titleScreen.add(titlePart2);

    titlePart3 = new FlxSprite(0,0, Paths.image('menus/title/title3'));
    titlePart3.scrollFactor.set(1,1);
    titlePart3.scale.set(1,1);
    titlePart3.alpha = 1;
    titleScreen.add(titlePart3);

    titlePart4 = new FlxSprite(0,0, Paths.image('menus/title/title4'));
    titlePart4.scrollFactor.set(1,1);
    titlePart4.scale.set(1,1);
    titlePart4.alpha = 1;
    titleScreen.add(titlePart4);

    titlePart5 = new FlxSprite(0,0, Paths.image('menus/title/title5'));
    titlePart5.scrollFactor.set(1,1);
    titlePart5.scale.set(1,1);
    titlePart5.alpha = 1;
    titleScreen.add(titlePart5);

   titleLogo = new FlxSprite(-870,-770, Paths.image('menus/title/titleLogo'));
    titleLogo.scrollFactor.set(1,1);
    titleLogo.scale.set(0.38,0.38);
    titleLogo.alpha = 1;
    add(titleLogo);  // Volvemos a add normal para mantenerlo separado

    titlePart6 = new FlxSprite(0,0, Paths.image('menus/title/title6'));
    titlePart6.scrollFactor.set(1,1);
    titlePart6.scale.set(1,1);
    titlePart6.alpha = 1;
    titleScreen.add(titlePart6);
    
    // Crear blackTop como sprite independiente
    blackTop = new FlxSprite(-1000,-1000, Paths.image('menus/mainmenu/fullBlack'));
    add(blackTop);  // Añadirlo directamente a la escena
    blackTop.scrollFactor.set(0,0);
    blackTop.scale.set(8,8);  // Escala más grande para asegurar que cubra todo
    blackTop.scrollFactor.set(0,0);
    blackTop.scale.set(10,10);
    blackTop.updateHitbox();
    add(blackTop);
    
    // Volver a añadir el titleScreen por encima
    add(titleScreen);
    
    var delayedTitleLayers = [titlePart0, titlePart1, titlePart2, titlePart3, titlePart4, titlePart5, titleLogo];
    for (layer in delayedTitleLayers) layer.alpha = 0;
    titlePart6.alpha = 0;
    titleInputBlockTimer = 2.0;

    FlxTween.tween(blackTop, {alpha: 0}, 1.0, {ease: FlxEase.sineInOut});
    harvesterEye = FlxTween.tween(titlePart6, {alpha: 1}, 1.0, {
        ease: FlxEase.sineInOut,
        onComplete: function(_) {
            if (curMenu != "title") return;
            for (layer in delayedTitleLayers)
                FlxTween.tween(layer, {alpha: 1}, 3.0, {ease: FlxEase.sineInOut});
            harvesterEye = FlxTween.tween(titlePart6, {alpha: 0.1}, 6.0, {
                ease: FlxEase.sineInOut,
                type: FlxTween.PINGPONG
            });
        }
    });

}

function onUpdate(elapsed:Float){
    
    // Aplicar los valores a blackFade siempre
    if (blackFade != null) {
        blackFade.x = blackFadeX;
        blackFade.y = blackFadeY;
        blackFade.scale.x = blackFadeWidth;
        blackFade.scale.y = blackFadeHeight;
    }
    increaseTime += elapsed;
    // Los shaders se actualizan en updateShaders()

    // Permitir input en el título, menú principal, freeplay o si el menú está revelado
    if(curMenu == "title" || curMenu == "main" || curMenu == "freeplay" || menuRevealed) {
        inputShit();
        trace('[DEBUG] inputShit() ejecutado, canSelect ahora: ' + canSelect);
    }

    if (curMenu != "freeplay") {return;}

}

function updateFreeplayClock(elapsed:Float):Void
{
    if (values == null || values.length < 6) return;

    for (i in 0...6) {
        var clockValue = values[i];
        var step = clockValue.speed * elapsed;

        if (clockValue.target < clockValue.desired) {
            clockValue.target = Math.min(clockValue.target + step, clockValue.desired);
        } else if (clockValue.target > clockValue.desired) {
            clockValue.target = Math.max(clockValue.target - step, clockValue.desired);
        }

        var digit = Math.round(clockValue.target);
        if (digit == Math.round(clockValue.prev)) continue;

        switch (i) {
            case 0: if (num1 != null) num1.animation.play(Std.string(digit), true);
            case 1: if (num2 != null) num2.animation.play(Std.string(digit), true);
            case 2: if (num3 != null) num3.animation.play(Std.string(digit), true);
            case 3: if (num4 != null) num4.animation.play(Std.string(digit), true);
            case 4: if (num5 != null) num5.animation.play(Std.string(digit), true);
            case 5: if (num6 != null) num6.animation.play(Std.string(digit), true);
        }

        FlxG.sound.play(Paths.sound('clockTick' + FlxG.random.int(0, 4)), 0.5);
        clockValue.prev = digit;
    }
}

function configureFreeplayClock(which:Int):Void
{
    if (values == null || values.length < 6) return;

    // Conserva los cuatro tiempos existentes y los repite para índices dinámicos posteriores.
    var patterns:Array<{target:Array<Int>, desired:Array<Int>}> = [
        {target: [6, 5, 9, 0, 4, 5], desired: [2, 3, 5, 9, 0, 9]},
        {target: [5, 3, 4, 9, 4, 5], desired: [0, 0, 0, 2, 1, 0]},
        {target: [4, 5, 4, 0, 4, 4], desired: [0, 0, 0, 8, 1, 0]},
        {target: [3, 3, 4, 0, 4, 3], desired: [0, 0, 0, 7, 1, 0]}
    ];
    var pattern = patterns[which % patterns.length];

    for (i in 0...6) {
        values[i].target = pattern.target[i];
        values[i].desired = pattern.desired[i];
        values[i].prev = -1;
    }
}

function addMusicShit() {
    if (FlxG.sound.music != null) {
        FlxG.sound.music.stop();
    }
        
    if (musicGroup != null) {
        musicGroup.clear();
        remove(musicGroup);
    }
    
    musicGroup = new FlxTypedGroup<FlxSound>();
    add(musicGroup);

    // Crear y empezar todas las músicas en volumen 0
    for(i in 0...6) {
        var musicPlayer:FlxSound = new FlxSound();
        var path = Paths.music('menu' + i);
        
        musicPlayer.loadEmbedded(path, true);
        musicPlayer.volume = 0;
        musicPlayer.persist = true;
        
        // Empezar a reproducir todas las músicas inmediatamente
        musicPlayer.play();
        
        FlxG.sound.list.add(musicPlayer);
        musicGroup.add(musicPlayer);
    }
    
    // Solo menu5 empieza con volumen
    if (musicGroup.members[5] != null) {
        musicGroup.members[5].volume = 1;
    }
}

function updateMusic(which:Int) {
    if (musicGroup == null || musicGroup.members == null) return;

    var fadeTime = 1.2;
    
    // Cancelar todos los tweens existentes primero
    for (i in 0...6) {
        if (musicGroup.members[i] != null) {
            FlxTween.cancelTweensOf(musicGroup.members[i], ["volume"]);
        }
    }
    
    // Hacer las transiciones de volumen
    for (i in 0...6) {
        var music = musicGroup.members[i];
        if (music != null) {
            var targetVol = (i == which) ? 1.0 : 0.0;
            if (music.volume != targetVol) {
                FlxTween.tween(music, {volume: targetVol}, fadeTime, {
                    ease: FlxEase.sineInOut
                });
            }
        }
    }
}


function easierTweenRight(tween:FlxTween):Void
{
    initialTween = FlxTween.tween(camFollowPos, {x: 5221, y: 570}, 0.8, {ease: FlxEase.backOut, onComplete: function(t) {
        right1Edit = false; // Desactivar edición de right1 cuando termina la transición
    }});
}

function easierTweenLeft(tween:FlxTween):Void
{
    initialTween = FlxTween.tween(camFollowPos, {x: 951, y: 570}, 1.2, {ease: FlxEase.backOut, onComplete: function(t) {
        right1Edit = false; // Desactivar edición de right1 cuando termina la transición
        // Limpiar elementos del grupo right cuando termina la transición
        if (right != null) {
            right.forEach(function(sprite) {
                right.remove(sprite, true);
                sprite.destroy();
            });
        }
    }});
}

function easierTweenDown(tween:FlxTween):Void
{
    camFollowPos.y = -370;
    bfFloat.alpha = 0;
    bfFloatRed.alpha = 1;
    initialTween = FlxTween.tween(camFollowPos, {y: 570}, 1.2, {ease: FlxEase.backOut});
}

function easierTweenUp(tween:FlxTween):Void
{
    camFollowPos.y = -370;
    bfFloat.alpha = 1;
    bfFloatRed.alpha = 0;
    initialTween = FlxTween.tween(camFollowPos, {y: 570}, 1.2, {ease: FlxEase.backOut});
    if (blackFade != null) FlxTween.tween(blackFade,  {alpha: 1}, 1.0, {ease: FlxEase.sineOut});
    if (fullBlack != null) FlxTween.tween(fullBlack,  {alpha: 1}, 1.0, {ease: FlxEase.sineOut});
}

function inputShit(){
    // DETECCIÓN RÁPIDA DE E PARA CERRAR ERROR DIALOG
    if (errorDialogActive && FlxG.keys.justPressed.E) {
        forceCloseErrorDialog = true; // Activar cierre forzado
        trace('[ERROR_DIALOG] E detectada - forzando cierre inmediato');
        return; // Salir inmediatamente para evitar otros inputs
    }
    
    // Bloquear input si el timer aún está activo
    if (inputBlockTimer > 0) {
        return;
    }
    
    if (curMenu == "title" && titleInputBlockTimer > 0) return;

    // Verificar si alguna tecla está presionada
    if (FlxG.keys.anyJustPressed([SPACE, ENTER])){
        if (curMenu == "title"){
            // La entrada al menú queda disponible tras el bloqueo inicial del título
            inputBlockTimer = 2.0; // Bloquear por 2 segundos
            FlxG.sound.play(Paths.sound('confirmMenu'));
            enterMain(false);
            // Revelar botones después de 0.50 segundos
            new FlxTimer().start(0.5, function(tmr:FlxTimer) {
                if (revealMainMenuTexts != null) revealMainMenuTexts();
                tmr.destroy();
            });
            return; // Salir sin hacer más checks
        }
    }
    
    // Bloquear TODO el input si canSelect es false (DESPUÉS de permitir ENTER en título)
    if (!canSelect) {
        // trace('[INPUT] Input bloqueado - canSelect = false, errorDialogBlocked = ' + errorDialogBlocked);
        return;
    }
    
    // Verificar si alguna tecla está presionada (resto de controles)
    if (FlxG.keys.anyJustPressed([SPACE, ENTER])){
        if (curMenu == "freeplay"){
            trace('[TRACE] ENTER detectado en freeplay | Cancion=' + curSelectedFreeplay + ' | Dif=' + curDifficulty + ' | canSelect=' + canSelect);
            FlxG.sound.play(Paths.sound('confirmMenu'));
            
            // BLOQUEAR INPUT inmediatamente al seleccionar una canción
            canSelect = false;
            trace('[INPUT] Input bloqueado - iniciando canción');
            
            // Llamada simple a startSong() - sin código inline masivo
            startSong();
        } else if (curMenu == "extras"){
            if (curSelectedExtra == 0){
                startIf();
            } else {
                startSidestory();
            }
        }else {
            checkSelection(curSelected);
        }
    }

    if (FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.BACKSPACE|| FlxG.keys.justPressed.X){
        if (curMenu == "title"){
            // Si estamos en el título, ir a NoticesState
            FlxG.sound.play(Paths.sound('cancelMenu'));
            canSelect = false;
            
            // Fade out suave
            var blackOverlay = new FlxSprite().makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFF000000);
            blackOverlay.screenCenter();
            blackOverlay.alpha = 0;
            blackOverlay.scrollFactor.set(0, 0);
            add(blackOverlay);
            
            FlxTween.tween(blackOverlay, {alpha: 1}, 0.8, {
                ease: FlxEase.sineOut,
                onComplete: function(twn:FlxTween) {
                    MusicBeatState.switchState(new NoticesState());
                }
            });
            
            // Fade out de música
            if (musicGroup != null && musicGroup.members != null && musicGroup.members[5] != null) {
                FlxTween.tween(musicGroup.members[5], {volume: 0}, 0.8, {ease: FlxEase.sineOut});
            }
        }
        else if (curMenu == "main"){
            // Si estamos en el menú principal, volver al título
            backToTitle();
        }
        else if (curMenu != "title"){
            // Si estamos en otro menú (freeplay, extras, etc), volver al menú principal
            backOut();
            // Reiniciar la música al volver al menú principal
            updateMusic(0);
        }
    }

    // --- FREEPLAY NAVIGATION DINÁMICA ---
    if (curMenu == "freeplay" && freeplaySongs.length > 0) {
        if (!canSelect) return; // Bloquear navegación en freeplay si input está bloqueado
        
        var oldSelected:Int = curSelectedFreeplay;
        
        if (FlxG.keys.justPressed.UP || FlxG.keys.justPressed.W) {
            FlxG.sound.play(Paths.sound('scrollMenu'));
            curSelectedFreeplay -= 1;
            if (curSelectedFreeplay < 0) curSelectedFreeplay = freeplaySongs.length - 1;
            updateFreeplaySelection(oldSelected);
            configureFreeplayClock(curSelectedFreeplay);
        }
        if (FlxG.keys.justPressed.DOWN || FlxG.keys.justPressed.S) {
            FlxG.sound.play(Paths.sound('scrollMenu'));
            curSelectedFreeplay += 1;
            if (curSelectedFreeplay >= freeplaySongs.length) curSelectedFreeplay = 0;
            updateFreeplaySelection(oldSelected);
            configureFreeplayClock(curSelectedFreeplay);
        }
    } else {
        // Menú principal y extras (deja esto igual)
        if (FlxG.keys.justPressed.UP || FlxG.keys.justPressed.W)
        {
            if (!canSelect) return; // Bloquear navegación si input está bloqueado
            
            FlxG.sound.play(Paths.sound('scrollMenu'));

            if (curMenu == "main"){
                curSelected -= 1;
                if (curSelected < 0){
                    curSelected = 4;
                }
            }

            updateOption();
        }

        if (FlxG.keys.justPressed.DOWN || FlxG.keys.justPressed.S)
        {
            if (!canSelect) return; // Bloquear navegación si input está bloqueado
            
            FlxG.sound.play(Paths.sound('scrollMenu'));

            if (curMenu == "main"){
                curSelected += 1;
                if (curSelected >=5){
                    curSelected = 0;
                }
            }

            updateOption();
        }
    }

    if (FlxG.keys.justPressed.RIGHT || FlxG.keys.justPressed.D)
    {
        if (!canSelect) {
            trace('[DEBUG] RIGHT/D bloqueado - canSelect=false, errorDialogBlocked=' + errorDialogBlocked + ', errorDialogActive=' + errorDialogActive);
            return;
        }
        
        if (curMenu == "extras"){
            FlxG.sound.play(Paths.sound('scrollMenu'));
            curSelectedExtra += 1;
            if (curSelectedExtra > 1){
                curSelectedExtra = 0;
            }
            updateOption();
        }

        if (curMenu == "freeplay"){
            trace('[DEBUG] RIGHT detectado - cambiando dificultad de ' + curDiff + ' a ' + ((curDiff + 1) > 2 ? 0 : (curDiff + 1)));
            FlxG.sound.play(Paths.sound('scrollMenu'));
            curDiff += 1;
            if (curDiff > 2){
                curDiff = 0;
            }
            curDifficulty = curDiff; // Sincronizar con curDifficulty
            if (diffSelectRightTween != null){
                diffSelectRightTween.cancel();
            }
            diffSelectR.alpha = 1;
            diffSelectRightTween = FlxTween.tween(diffSelectR,  {alpha: 0.2}, 1.0, {ease: FlxEase.sineOut});

            updateDifficulty();
            trace('[DEBUG] Dificultad cambiada a: ' + curDiff);
        }
    }

    if (FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.A)
    {
        if (!canSelect) {
            trace('[DEBUG] LEFT/A bloqueado - canSelect=false, errorDialogBlocked=' + errorDialogBlocked + ', errorDialogActive=' + errorDialogActive);
            return;
        }
        
        if (curMenu == "extras"){
            FlxG.sound.play(Paths.sound('scrollMenu'));
            curSelectedExtra -= 1;
            if (curSelectedExtra < 0){
                curSelectedExtra = 1;
            }
            updateOption();
        }

        if (curMenu == "freeplay"){
            trace('[DEBUG] LEFT detectado - cambiando dificultad de ' + curDiff + ' a ' + ((curDiff - 1) < 0 ? 2 : (curDiff - 1)));
            FlxG.sound.play(Paths.sound('scrollMenu'));
            curDiff -= 1;
            if (curDiff < 0){
                curDiff = 2;
            }
            curDifficulty = curDiff; // Sincronizar con curDifficulty

            if (diffSelectLeftTween != null){
                diffSelectLeftTween.cancel();
            }
            diffSelectL.alpha = 1;
            diffSelectLeftTween = FlxTween.tween(diffSelectL, {alpha: 0.2}, 1.0, {ease: FlxEase.sineOut});

            updateDifficulty();
            trace('[DEBUG] Dificultad cambiada a: ' + curDiff);
        }
    }

    // Tecla 8 para ir al menú de mods
    if (FlxG.keys.justPressed.EIGHT) {
        trace('[INPUT] Tecla 8 presionada - intentando abrir ModsMenuState');
        try {
            startModsMenu();
        } catch(e:Dynamic) {
            trace('[ERROR] Error al abrir ModsMenuState: $e');
            FlxG.sound.play(Paths.sound('cancelMenu'));
        }
    }
}

function prepareMenuTransition():Void {
    canSelect = false;
    if (initialTween != null) initialTween.cancel();
    FlxTween.cancelTweensOf(FlxG.camera);
    FlxTween.cancelTweensOf(transition);
    FlxTween.cancelTweensOf(blackCovering);

    if (menuTransitionCamera == null) {
        menuTransitionCamera = new FlxCamera();
        menuTransitionCamera.bgColor.alpha = 0;
        FlxG.cameras.add(menuTransitionCamera, false);
    }
    menuTransitionCamera.zoom = FlxG.camera.zoom;
    menuTransitionCamera.scroll.copyFrom(FlxG.camera.scroll);

    transition.cameras = [menuTransitionCamera];
    transition.blend = BlendMode.MULTIPLY;
    transition.scrollFactor.set(0, 0);
    transition.scale.set(2.5, 2.5);
    transition.setSize(transition.frameWidth, transition.frameHeight);
    transition.offset.set();
    transition.centerOrigin();
    transition.setPosition(150, 119);
    transition.visible = true;
    transition.alpha = 0;
    transition.animation.play("idle", true);
    transition.animation.pause();
    remove(transition, true);
    add(transition);

    blackCovering.cameras = [menuTransitionCamera];
    blackCovering.setPosition(10, -20);
    blackCovering.visible = true;
    blackCovering.alpha = 0;
    remove(blackCovering, true);
    add(blackCovering);
}

function playMenuTransition():Void {
    transition.visible = true;
    transition.alpha = 1;
    transition.animation.play("idle", true);
}

function startStoryMode(){
    prepareMenuTransition();

    initialTween = FlxTween.tween(FlxG.camera, {zoom: 0.8}, 1.2, {ease: FlxEase.backIn, onComplete: storyTweenZoom});

    // Bajar volumen de música durante la animación
    if (musicGroup != null && musicGroup.members != null) {
        for(i in 0...6){
            if (i < musicGroup.members.length && musicGroup.members[i] != null && musicGroup.members[i].volume != 0){
                musicGroup.members[i].fadeOut(1,0);
            }
        }
    }

    FlxG.sound.play(Paths.sound('water rush'));

    new FlxTimer().start(0.75, function(tmr){
        playMenuTransition();
        tmr.destroy();
    });

    new FlxTimer().start(1.7, function(tmr){
        if (blackCovering != null)
            blackCovering.alpha = 1;
        tmr.destroy();
    });

    // Cambiar a StoryMenuState después de la transición completa
    new FlxTimer().start(5, function(tmr){
        MusicBeatState.switchState(new StoryMenuState());
        tmr.destroy();
    });
}

function startModsMenu(){
    if(initialTween != null)
        initialTween.cancel();

    initialTween = FlxTween.tween(FlxG.camera, {zoom: 0.8}, 1.2, {ease: FlxEase.backIn, onComplete: storyTweenZoom});

    // Bajar volumen de música durante la animación
    if (musicGroup != null && musicGroup.members != null) {
        for(i in 0...6){
            if (i < musicGroup.members.length && musicGroup.members[i] != null && musicGroup.members[i].volume != 0){
                musicGroup.members[i].fadeOut(1,0);
            }
        }
    }

    FlxG.sound.play(Paths.sound('water rush'));

    new FlxTimer().start(0.75, function(tmr){
        if (transition != null) {
            transition.alpha = 1;
            transition.animation.play("idle", true);
        }
        tmr.destroy();
    });

    new FlxTimer().start(1.7, function(tmr){
        if (blackCovering != null)
            blackCovering.alpha = 1;
        tmr.destroy();
    });

    // Cambiar a ModsMenuState después de la transición completa
    new FlxTimer().start(5, function(tmr){
        MusicBeatState.switchState(new ModsMenuState());
        tmr.destroy();
    });
}

function startSidestory(){
    if(initialTween != null)
        initialTween.cancel();
    initialTween = FlxTween.tween(FlxG.camera, {zoom: 0.8}, 1.2, {ease: FlxEase.backIn, onComplete: storyTweenZoom});

    for(i in 0...6){
        if (musicGroup.members[i].volume != 0){
            musicGroup.members[i].fadeOut(1,0);
        }
    }

    FlxG.sound.play(Paths.sound('confirmMenu'));

    FlxG.sound.play(Paths.sound('water rush'));

    new FlxTimer().start(0.75, function(tmr){
        if (transitionExtras != null) {
            transitionExtras.alpha = 1;
            transitionExtras.animation.play("idle", true);
        }
        tmr.destroy();
    });

    new FlxTimer().start(1.7, function(tmr2){
        blackCovering.alpha = 1;
        tmr2.destroy();
    });

    new FlxTimer().start(6, function(tmr3){
        if (FlxG.save.data.seenSidestoryNotice == true){
            MusicBeatState.switchState(new SideStoryMenuNotices());
        } else {
            FlxG.save.data.seenSidestoryNotice = true;
            MusicBeatState.switchState(new SideStoryMenuNotices());
        }
        
        tmr3.destroy();
    });
    
}

function storyTweenZoom(tween:FlxTween):Void
{
    initialTween = FlxTween.tween(FlxG.camera, {zoom: 6}, 1.5);
}


function checkSelection(curSelect:Int){
    if (curMenu == "main") updateOption();

    if (initialTween != null){
        initialTween.cancel();
        initialTween.destroy();
    }

    canSelect = false; // Bloquear input inicialmente

    switch (curSelect){
        case 0: // STORY MODE
            startStoryMode();
            curMenu = "main";
            // Input bloqueado hasta que entre al state (no se desbloquea)
            
        case 1: // FREEPLAY
            enterFreeplay();
            curMenu = "freeplay";
            // Desbloquear después de 2 segundos (freeplay es parte del menú)
            new FlxTimer().start(2, function(tmr){
                canSelect = true;
                tmr.destroy();
            });
            
        case 2: // OPTIONS
            enterSettings();
            curMenu = "options";
            // Input bloqueado hasta que entre al state
            new FlxTimer().start(1, function(tmr){
                tmr.destroy();
                MusicBeatState.switchState(new options.OptionsState());
            });
            
        case 3: // EXTRAS
            enterExtras();
            curMenu = "extras";
            // Desbloquear después de 2 segundos (extras es parte del menú)
            new FlxTimer().start(2, function(tmr){
                canSelect = true;
                tmr.destroy();
            });
            
        case 4: // CREDITS
            enterCredits();
            curMenu = "credits";
            // Input bloqueado hasta que entre al state (no se desbloquea)
            
        case 9: // MODO DEV - DESHABILITADO
            // isDevMode = !isDevMode; // DEBUG MODE COMPLETAMENTE DESACTIVADO
            canSelect = true;
            trace('[DEV MODE] DESHABILITADO PERMANENTEMENTE');
    }
    updateMusic(curSelect);
    FlxG.sound.play(Paths.sound('confirmMenu'));
}

public static function destroyFreeplayVocals() {
    if(vocals != null) {
        vocals.stop();
        vocals.destroy();
    }
    vocals = null;
}

function startSong() {
    // Transición exacta del HScript - Freeplay con efectos visuales completos

    // Freeplay may be entered with no valid weeks/songs. Never index the
    // selection array until it has been validated.
    if (freeplaySongs == null || freeplaySongs.length == 0 || curSelectedFreeplay < 0 || curSelectedFreeplay >= freeplaySongs.length) {
        trace('[Freeplay] No song is available to start.');
        showErrorMessage('FREEPLAY VACÍO', 'No hay canciones disponibles para iniciar.\nAñade una week con canciones válidas e inténtalo de nuevo.');
        return;
    }
    
    // MAPEO DE DIFICULTADES (igual que antes)
    var difficultyIndex = curDiff;
    var difficultyNames = ['Safe (d0)', 'Canon/Hard (d1)', 'Normal'];
    var selectedDiffName = difficultyNames[curDiff];
    
    trace('[Freeplay] ========================================');
    trace('[Freeplay] Iniciando canción: ' + freeplaySongs[curSelectedFreeplay].songName);
    trace('[Freeplay] Dificultad seleccionada (UI): ' + selectedDiffName);
    trace('[Freeplay] curDiff: ' + curDiff + ' | difficultyIndex: ' + difficultyIndex);
    trace('[Freeplay] ========================================');

    var songMeta = freeplaySongs[curSelectedFreeplay];
    if (songMeta == null) {
        trace('ERROR: Metadata de canción no encontrada.');
        return;
    }

    // Configurar mod directory ANTES de cargar (igual que FreeplayState)
    Mods.currentModDirectory = songMeta.folder;
    
    // Configurar PlayState (igual que FreeplayState)
    PlayState.storyWeek = songMeta.week;
    Difficulty.loadFromWeek();
    
    // Preparar variables exactamente como FreeplayState
    var songLowercase:String = Paths.formatToSongPath(songMeta.songName);
    
    // Crear nombre de chart según dificultad
    var chartName:String;
    if (difficultyIndex == 0) {
        chartName = songLowercase + '-safe';
    } else if (difficultyIndex == 1) {
        chartName = songLowercase + '-canon';
    } else {
        chartName = songLowercase;
    }
    
    var poop:String = chartName;
    
    // Función para intentar cargar con fallbacks
    function tryLoadSong(primaryName:String, fallbackName:String):Bool {
        try {
            trace('[Freeplay] Intentando cargar: $primaryName');
            Song.loadFromJson(primaryName, songLowercase);
            trace('[Freeplay] ✓ Canción cargada: $primaryName');
            return true;
        } catch(e:haxe.Exception) {
            trace('[Freeplay] ✗ No encontrado: $primaryName');
            if (fallbackName != null && fallbackName != primaryName) {
                try {
                    trace('[Freeplay] Intentando fallback: $fallbackName');
                    Song.loadFromJson(fallbackName, songLowercase);
                    trace('[Freeplay] ✓ Canción cargada (fallback): $fallbackName');
                    return true;
                } catch(e2:haxe.Exception) {
                    trace('[Freeplay] ✗ Fallback tampoco encontrado: $fallbackName');
                    return false;
                }
            }
            return false;
        }
    }

    try {
        // Determinar nombres primarios y fallback según dificultad
        var primaryName:String = poop;
        var fallbackName:String = null;
        
        if (difficultyIndex == 0) {
            fallbackName = songLowercase + '-easy';
        } else if (difficultyIndex == 1) {
            fallbackName = songLowercase + '-hard';
        }
        
        trace('[Freeplay] ========================================');
        trace('[Freeplay] Dificultad: ' + difficultyNames[difficultyIndex]);
        trace('[Freeplay] Primario: $primaryName');
        if (fallbackName != null) trace('[Freeplay] Fallback: $fallbackName');
        trace('[Freeplay] ========================================');
        
        // Intentar cargar con fallback
        if (!tryLoadSong(primaryName, fallbackName)) {
            throw 'No se pudo cargar la canción';
        }
        
        trace('[Freeplay] SONG.song: ' + PlayState.SONG.song);
        trace('[Freeplay] SONG.notes: ' + PlayState.SONG.notes.length + ' secciones');
        
        PlayState.isStoryMode = false;
        PlayState.storyDifficulty = difficultyIndex;

        trace('CURRENT WEEK: ' + WeekData.getWeekFileName());

        // Chequeo de mod directory (igual que FreeplayState)
        @:privateAccess
        if(PlayState._lastLoadedModDirectory != Mods.currentModDirectory) {
            trace('CHANGED MOD DIRECTORY, RELOADING STUFF');
            Paths.freeGraphicsFromMemory();
        }

        // =================== TRANSICIÓN VISUAL DEL HSCRIPT ===================
        prepareMenuTransition();

        initialTween = FlxTween.tween(FlxG.camera, {zoom: 0.8}, 1.2, {
            ease: FlxEase.backIn,
            onComplete: storyTweenZoom
        });

        // Fade out de todos los grupos de música (igual que HScript)
        for (i in 0...musicGroup.members.length) {
            if (musicGroup.members[i].volume != 0) {
                musicGroup.members[i].fadeOut(1, 0);
            }
        }

        // Sonido de agua (igual que HScript)
        FlxG.sound.play(Paths.sound('water rush'));

        // Timer 1: Activar transición visual (0.75 segundos - igual que HScript)
        new FlxTimer().start(0.75, function(tmr:FlxTimer) {
            playMenuTransition();
        });

        // Timer 2: Black covering (1.7 segundos - igual que HScript)
        new FlxTimer().start(1.7, function(tmr:FlxTimer) {
            if (blackCovering != null) {
                blackCovering.alpha = 1;
            }
        });

        // Timer 3: Cargar canción (2.4 segundos - igual que HScript)
        new FlxTimer().start(2.4, function(tmr:FlxTimer) {
            // Preparar carga final
            LoadingState.prepareToSong();
            LoadingState.loadAndSwitchState(new PlayState(), true);
            destroyFreeplayVocals();
            #if !SHOW_LOADING_SCREEN FlxG.sound.music.stop(); #end

            #if (MODS_ALLOWED && DISCORD_ALLOWED)
            DiscordClient.loadModRPC();
            #end
        });

    } catch(e:haxe.Exception) {
        // LOG COMPLETO PARA DESARROLLADORES
        trace('ERROR COMPLETO: ${e.message}');
        trace('STACK TRACE: ${haxe.CallStack.toString(haxe.CallStack.callStack())}');
        trace('CANCIÓN: ${freeplaySongs[curSelectedFreeplay].songName}');
        trace('DIFICULTAD: ${curDiff}');

        var errorTitle:String = "❌ ERROR AL CARGAR CANCIÓN";
        var errorMessage:String = "";
        var songName:String = freeplaySongs[curSelectedFreeplay].songName;
        var diffName:String = ['Safe', 'Canon/Hard', 'Normal'][curDiff];
        
        // Analizar el tipo de error y crear mensaje descriptivo con detección automática
        if(e.message.contains('There is no TEXT asset with an ID of')) {
            // Extraer el nombre del archivo del mensaje de error
            var missingFile = "";
            var parts = e.message.split('There is no TEXT asset with an ID of');
            if (parts.length > 1) {
                missingFile = parts[1].split('\n')[0].trim();
            }
            
            // DETECCIÓN AUTOMÁTICA DEL PROBLEMA
            var detectedIssue = "";
            if (missingFile.contains('-hard') || missingFile.contains('-easy') || missingFile.contains('-normal')) {
                detectedIssue = "DIFICULTAD NO ENCONTRADA";
            } else if (missingFile.contains('songs/')) {
                detectedIssue = "CHART FALTANTE";
            } else if (missingFile.contains('data/')) {
                detectedIssue = "DATOS DE CANCIÓN FALTANTES";
            } else {
                detectedIssue = "ARCHIVO NO ENCONTRADO";
            }
            
            // Error de archivo no encontrado con detección automática
            errorMessage = '🎵 Canción: "$songName"\n🎯 Dificultad: $diffName\n\n📁 $detectedIssue\n\nArchivo faltante:\n$missingFile\n\n💡 Problema detectado:\n• Esta dificultad no existe para esta canción\n• Chart faltante para esta dificultad\n• Nombre de archivo incorrecto\n• Carpeta de la semana mal configurada';
        } else if(e.message.contains('Unexpected')) {
            // Extraer información del error JSON
            var jsonError = e.message.length > 60 ? e.message.substring(0, 60) + "..." : e.message;
            
            // DETECCIÓN AUTOMÁTICA DEL PROBLEMA JSON
            var detectedJsonIssue = "";
            if (e.message.contains('Unexpected }')) {
                detectedJsonIssue = "LLAVE EXTRA DETECTADA";
            } else if (e.message.contains('Unexpected ,')) {
                detectedJsonIssue = "COMA EXTRA DETECTADA";
            } else if (e.message.contains('Expected }')) {
                detectedJsonIssue = "FALTA CERRAR LLAVE";
            } else if (e.message.contains('Expected ,')) {
                detectedJsonIssue = "FALTA COMA";
            } else if (e.message.contains('Expected "')) {
                detectedJsonIssue = "FALTA COMILLAS";
            } else if (e.message.contains('Unexpected end')) {
                detectedJsonIssue = "CHART INCOMPLETO";
            } else {
                detectedJsonIssue = "CHART CORRUPTO";
            }
            
            // Error de formato JSON con detección automática
            errorMessage = '🎵 Canción: "$songName"\n🎯 Dificultad: $diffName\n\n📋 $detectedJsonIssue\n\nDetalle técnico:\n$jsonError\n\n💡 Problema detectado:\n• Eventos del chart corruptos\n• Chart editado incorrectamente\n• Sintaxis JSON inválida\n• Revisar el chart en el editor';
        } else if(e.message.contains('FileSystem') || e.message.contains('Permission') || e.message.contains('Access')) {
            // Error del sistema de archivos
            var fsError = e.message.length > 50 ? e.message.substring(0, 50) + "..." : e.message;
            errorMessage = '🎵 Canción: "$songName"\n🎯 Dificultad: $diffName\n\n💾 ERROR DE ACCESO\n\nProblema accediendo al archivo.\n\nDetalle:\n$fsError\n\n💡 Posibles causas:\n• Archivo del chart en uso\n• Permisos de carpeta bloqueados\n• Chart siendo editado\n• Nombre con caracteres especiales';
        } else if(e.message.contains('Null Object Reference')) {
            // DETECCIÓN AUTOMÁTICA DE QUE DATO FALTA
            var detectedMissingData = "";
            if (e.message.contains('song') || e.message.contains('Song')) {
                detectedMissingData = "DATOS DE CANCIÓN FALTANTES";
            } else if (e.message.contains('notes') || e.message.contains('Notes')) {
                detectedMissingData = "NOTAS DEL CHART FALTANTES";
            } else if (e.message.contains('events') || e.message.contains('Events')) {
                detectedMissingData = "EVENTOS DEL CHART FALTANTES";
            } else if (e.message.contains('player') || e.message.contains('boyfriend')) {
                detectedMissingData = "DATOS DEL PERSONAJE FALTANTES";
            } else if (e.message.contains('speed') || e.message.contains('bpm')) {
                detectedMissingData = "CONFIGURACIÓN DE CANCIÓN FALTANTE";
            } else {
                detectedMissingData = "DATOS FALTANTES";
            }
            
            // Error de referencia nula con detección automática
            errorMessage = '🎵 Canción: "$songName"\n🎯 Dificultad: $diffName\n\n🔗 $detectedMissingData\n\nFalta información requerida\nen el chart de la canción.\n\n💡 Problema detectado:\n• Chart incompleto\n• Eventos mal configurados\n• Datos de personajes faltantes\n• Chart creado con versión antigua';
        } else {
            // Preparar mensaje de error técnico (limitado para no saturar la UI)
            var technicalError = e.message.length > 80 ? e.message.substring(0, 80) + "..." : e.message;
            
            // DETECCIÓN AUTOMÁTICA DE PROBLEMAS ESPECÍFICOS
            var detectedProblem = "";
            if (e.message.contains('Array') || e.message.contains('length')) {
                detectedProblem = "PROBLEMA CON ARRAY DE NOTAS";
            } else if (e.message.contains('Character') || e.message.contains('character')) {
                detectedProblem = "PROBLEMA CON PERSONAJES";
            } else if (e.message.contains('stage') || e.message.contains('Stage')) {
                detectedProblem = "PROBLEMA CON EL ESCENARIO";
            } else if (e.message.contains('Chart') || e.message.contains('chart')) {
                detectedProblem = "PROBLEMA CON EL CHART";
            } else if (e.message.contains('version') || e.message.contains('Version')) {
                detectedProblem = "INCOMPATIBILIDAD DE VERSIÓN";
            } else {
                detectedProblem = "ERROR DESCONOCIDO";
            }
            
            // Error genérico con detección automática
            errorMessage = '🎵 Canción: "$songName"\n🎯 Dificultad: $diffName\n\n⚠️ $detectedProblem\n\nMensaje:\n$technicalError\n\n💡 Problema detectado:\n• Chart con formato no soportado\n• Incompatibilidad de versión\n• Eventos especiales corruptos\n• Chart creado con herramientas externas';
        }

        // Mostrar mensaje de error al usuario
        showErrorMessage(errorTitle, errorMessage);
        
        // Log técnico para desarrolladores
        trace('ERROR WHILE LOADING CHART: ${e.message}');
        FlxG.sound.play(Paths.sound('cancelMenu'));
        
        // *** BUG FIX: Restaurar input cuando falla la carga ***
        canSelect = true;
        trace('[BUG FIX] Input restaurado tras error de carga de canción - curDiff permanece en: ' + curDiff);
        
        return;
    }
}

// Función para mostrar mensajes de error amigables al usuario
function showErrorMessage(title:String, message:String) {
    // ACTIVAR CONTROL GLOBAL DE ERROR DIALOG
    errorDialogActive = true;
    
    // BLOQUEAR TEMPORALMENTE EL INPUT DEL FREEPLAY
    canSelect = false;
    
    // Crear overlay negro semi-transparente (más grande y menos opaco)
    var errorOverlay = new FlxSprite(0, 0);
    errorOverlay.makeGraphic(FlxG.width * 2, FlxG.height * 2, 0x66000000); // Menos opacidad (0x66 en lugar de 0x88)
    errorOverlay.scrollFactor.set(0, 0);
    errorOverlay.screenCenter();
    add(errorOverlay);
    
    // Crear fondo del mensaje (más grande)
    var msgWidth:Int = 700;  // Aumentado de 500 a 700
    var msgHeight:Int = 550; // Aumentado de 400 a 550
    var msgBg = new FlxSprite();
    msgBg.makeGraphic(msgWidth, msgHeight, 0xFF1a1a1a);
    msgBg.screenCenter();
    msgBg.scrollFactor.set(0, 0);
    add(msgBg);
    
    // Crear borde del mensaje
    var msgBorder = new FlxSprite();
    msgBorder.makeGraphic(msgWidth + 4, msgHeight + 4, 0xFFff4444);
    msgBorder.screenCenter();
    msgBorder.x -= 2;
    msgBorder.y -= 2;
    msgBorder.scrollFactor.set(0, 0);
    insert(members.indexOf(msgBg), msgBorder);
    
    // Título del error (texto aún más grande)
    var titleText = new FlxText(0, 0, msgWidth - 20, title, 28); // Aumentado de 24 a 28
    titleText.setFormat(Paths.font("vcr.ttf"), 28, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    titleText.borderSize = 2; // Borde más grueso
    titleText.screenCenter(X);
    titleText.y = msgBg.y + 20; // Más espacio arriba
    titleText.scrollFactor.set(0, 0);
    add(titleText);
    
    // Mensaje del error (texto aún más grande)
    var messageText = new FlxText(0, 0, msgWidth - 60, message, 22); // Aumentado de 18 a 22
    messageText.setFormat(Paths.font("vcr.ttf"), 22, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    messageText.borderSize = 1;
    messageText.screenCenter(X);
    messageText.y = titleText.y + 50; // Más espacio entre título y mensaje
    messageText.scrollFactor.set(0, 0);
    add(messageText);
    
    // Botón de cerrar (texto aún más grande)
    var closeText = new FlxText(0, 0, msgWidth - 20, "PRESIONA E PARA CERRAR (O ESPERA 6 SEGUNDOS)", 24); // Cambió a E
    closeText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.YELLOW, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    closeText.borderSize = 2; // Borde más grueso
    closeText.screenCenter(X);
    closeText.y = msgBg.y + msgBg.height - 45; // Más espacio abajo
    closeText.scrollFactor.set(0, 0);
    add(closeText);
    
    // Animación de aparición
    errorOverlay.alpha = 0;
    msgBg.scale.set(0.8, 0.8);
    msgBorder.scale.set(0.8, 0.8);
    titleText.alpha = 0;
    messageText.alpha = 0;
    closeText.alpha = 0;
    
    FlxTween.tween(errorOverlay, {alpha: 1}, 0.3);
    FlxTween.tween(msgBg, {"scale.x": 1, "scale.y": 1}, 0.3, {ease: FlxEase.backOut});
    FlxTween.tween(msgBorder, {"scale.x": 1, "scale.y": 1}, 0.3, {ease: FlxEase.backOut});
    FlxTween.tween(titleText, {alpha: 1}, 0.5, {startDelay: 0.2});
    FlxTween.tween(messageText, {alpha: 1}, 0.5, {startDelay: 0.3});
    FlxTween.tween(closeText, {alpha: 1}, 0.5, {startDelay: 0.4});
    
    // Sistema de cierre del mensaje con timer de 6 segundos - MEJORADO
    var errorActive = true;
    var autoCloseTime = 6.0;
    var timeRemaining = autoCloseTime;
    
    // Función para limpiar todo correctamente
    function cleanupErrorDialog() {
        remove(errorOverlay);
        remove(msgBorder);
        remove(msgBg);
        remove(titleText);
        remove(messageText);
        remove(closeText);
        
        errorOverlay.destroy();
        msgBorder.destroy();
        msgBg.destroy();
        titleText.destroy();
        messageText.destroy();
        closeText.destroy();
        
        // BLOQUEAR INPUT TEMPORALMENTE PARA EVITAR INTERFERENCIA
        errorDialogBlocked = true;
        errorDialogActive = false; // DESACTIVAR CONTROL GLOBAL
        
        trace('[ERROR_DIALOG] Iniciando limpieza - canSelect ANTES: ' + canSelect);
        
        // Usar un timer para restaurar el input después de que las teclas se suelten
        new FlxTimer().start(0.2, function(tmr:FlxTimer) {
            errorDialogBlocked = false;
            canSelect = true; // SIEMPRE restaurar a true después de un error
            
            trace('[ERROR_DIALOG] ✓✓✓ Input RESTAURADO ✓✓✓');
            trace('[ERROR_DIALOG] canSelect = ' + canSelect);
            trace('[ERROR_DIALOG] errorDialogBlocked = ' + errorDialogBlocked);
            trace('[ERROR_DIALOG] errorDialogActive = ' + errorDialogActive);
            trace('[ERROR_DIALOG] curDiff = ' + curDiff);
            trace('[ERROR_DIALOG] curMenu = ' + curMenu);
            tmr.destroy();
        });
    }
    
    // Timer para auto-cerrar
    errorAutoCloseTimer = new FlxTimer().start(autoCloseTime, function(tmr:FlxTimer) {
        if (errorActive) {
            errorActive = false;
            errorDialogActive = false; // DESACTIVAR CONTROL GLOBAL
            FlxG.sound.play(Paths.sound('confirmMenu'));
            
            // Animación de salida automática
            FlxTween.tween(errorOverlay, {alpha: 0}, 0.2);
            FlxTween.tween(msgBg, {"scale.x": 0.8, "scale.y": 0.8}, 0.2, {ease: FlxEase.backIn});
            FlxTween.tween(msgBorder, {"scale.x": 0.8, "scale.y": 0.8}, 0.2, {ease: FlxEase.backIn});
            FlxTween.tween(titleText, {alpha: 0}, 0.2);
            FlxTween.tween(messageText, {alpha: 0}, 0.2);
            FlxTween.tween(closeText, {alpha: 0}, 0.2, {
                onComplete: function(twn:FlxTween) {
                    cleanupErrorDialog();
                }
            });
        }
        tmr.destroy();
    });
    
    var errorUpdate = function(elapsed:Float) {
        // Actualizar tiempo restante
        timeRemaining -= elapsed;
        if (timeRemaining > 0) {
            closeText.text = "PRESIONA E PARA CERRAR (" + Math.ceil(timeRemaining) + "s)";
        }
        
        // Revisar si se forzó el cierre desde inputShit()
        if (forceCloseErrorDialog && (errorActive || errorDialogActive)) {
            errorActive = false;
            errorDialogActive = false;
            forceCloseErrorDialog = false; // Resetear la variable
            
            // Si hay timer automático, cancelarlo
            if (errorAutoCloseTimer != null) {
                errorAutoCloseTimer.cancel();
            }
            
            FlxG.sound.play(Paths.sound('confirmMenu'));
            
            // Manejar cierre del diálogo de error normal
            if (msgBg != null) {
                // Animación de salida manual rápida
                FlxTween.tween(errorOverlay, {alpha: 0}, 0.2);
                FlxTween.tween(msgBg, {"scale.x": 0.8, "scale.y": 0.8}, 0.2, {ease: FlxEase.backIn});
                FlxTween.tween(msgBorder, {"scale.x": 0.8, "scale.y": 0.8}, 0.2, {ease: FlxEase.backIn});
                FlxTween.tween(titleText, {alpha: 0}, 0.2);
                FlxTween.tween(messageText, {alpha: 0}, 0.2);
                FlxTween.tween(closeText, {alpha: 0}, 0.2, {
                    onComplete: function(twn:FlxTween) {
                        cleanupErrorDialog();
                    }
                });
            }
            
            // Manejar cierre del diálogo de compatibilidad de shaders
            if (messageContainer != null) {
                // Animación de salida para el diálogo de shaders
                messageContainer.forEach(function(sprite:FlxSprite) {
                    FlxTween.tween(sprite, {alpha: 0}, 0.2, {
                        onComplete: function(twn:FlxTween) {
                            if (sprite == messageContainer.members[messageContainer.members.length - 1]) {
                                // Último elemento - limpiar todo
                                remove(messageContainer);
                                messageContainer.destroy();
                                messageContainer = null;
                                canSelect = true;
                                trace('[SHADER COMPATIBILITY] Diálogo cerrado por usuario');
                            }
                        }
                    });
                });
            }
        }
    };
    
    // Hacky way: usar un timer para manejar el input - MEJORADO
    var errorTimer = new FlxTimer().start(0.05, function(tmr:FlxTimer) {
        if (errorActive) {
            errorUpdate(0.05);
            tmr.reset(0.05);
        } else {
            // Cuando errorActive es false, destruir el timer y limpiar todo
            tmr.destroy();
            trace('[ERROR_DIALOG] Timer de input destruido correctamente');
        }
    });
}

function backToTitle(){
    titleInputBlockTimer = 2.0;
    // Bloquear input durante la transición
    canSelect = false;
    
    FlxG.sound.play(Paths.sound('cancelMenu'));
    
    // Cambiar el estado actual a título PRIMERO
    curMenu = "title";
    menuRevealed = false;
    
    // CRÍTICO: Cancelar TODOS los tweens activos de los elementos de menú
    if (selectedText != null && selectedText.members != null) {
        for (i in 0...selectedText.members.length) {
            if (selectedText.members[i] != null) {
                FlxTween.cancelTweensOf(selectedText.members[i]);
            }
        }
    }
    if (optionBg != null && optionBg.members != null) {
        for (i in 0...optionBg.members.length) {
            if (optionBg.members[i] != null) {
                FlxTween.cancelTweensOf(optionBg.members[i]);
            }
        }
    }
    if (optionText != null && optionText.members != null) {
        for (i in 0...optionText.members.length) {
            if (optionText.members[i] != null) {
                FlxTween.cancelTweensOf(optionText.members[i]);
            }
        }
    }
    
    // Animar el fade out de todos los botones con tween suave
    if (selectedText != null && selectedText.members != null) {
        for (i in 0...selectedText.members.length) {
            if (selectedText.members[i] != null) {
                FlxTween.tween(selectedText.members[i], {alpha: 0}, 0.5, {
                    ease: FlxEase.sineOut,
                    onComplete: function(twn:FlxTween) {
                        selectedText.members[i].visible = false;
                    }
                });
            }
        }
    }
    if (optionBg != null && optionBg.members != null) {
        for (i in 0...optionBg.members.length) {
            if (optionBg.members[i] != null) {
                FlxTween.tween(optionBg.members[i], {alpha: 0}, 0.5, {
                    ease: FlxEase.sineOut,
                    onComplete: function(twn:FlxTween) {
                        optionBg.members[i].visible = false;
                    }
                });
            }
        }
    }
    if (optionText != null && optionText.members != null) {
        for (i in 0...optionText.members.length) {
            if (optionText.members[i] != null) {
                FlxTween.tween(optionText.members[i], {alpha: 0}, 0.5, {
                    ease: FlxEase.sineOut,
                    onComplete: function(twn:FlxTween) {
                        optionText.members[i].visible = false;
                    }
                });
            }
        }
    }
    
    // Ocultar los grupos después de un pequeño delay
    new FlxTimer().start(0.6, function(tmr:FlxTimer) {
        if (selectedText != null) selectedText.visible = false;
        if (optionBg != null) optionBg.visible = false;
        if (optionText != null) optionText.visible = false;
        tmr.destroy();
    });
    
    // Animar middle y right con fade out
    if (middle != null) {
        FlxTween.tween(middle, {alpha: 0}, 0.8, {ease: FlxEase.sineOut, onComplete: function(twn:FlxTween) {
            middle.visible = false;
            middle.alpha = 1;
        }});
    }
    if (right != null) {
        FlxTween.tween(right, {alpha: 0}, 0.8, {ease: FlxEase.sineOut, onComplete: function(twn:FlxTween) {
            right.visible = false;
            right.alpha = 1;
        }});
    }
    
    // Restore every title layer before fading it back in. Some menu transitions
    // leave the sprites hidden, which used to return to an empty black screen.
    if (titleScreen != null) titleScreen.visible = true;
    var titleLayers:Array<FlxSprite> = [titlePart0, titlePart1, titlePart2, titlePart3, titlePart4, titlePart5, titlePart6, titleLogo];
    for (layer in titleLayers) {
        if (layer != null) {
            FlxTween.cancelTweensOf(layer);
            layer.visible = true;
        }
    }

    // Mostrar elementos del título gradualmente
    if (blackCovering != null) {
        FlxTween.tween(blackCovering, {alpha: 1}, 1.0, {ease: FlxEase.sineInOut});
    }
    if (titlePart0 != null) {
        FlxTween.tween(titlePart0, {alpha: 1}, 0.8, {ease: FlxEase.sineOut, startDelay: 0.2});
    }
    if (titlePart1 != null) {
        FlxTween.tween(titlePart1, {alpha: 1}, 0.8, {ease: FlxEase.sineOut, startDelay: 0.3});
    }
    if (titlePart2 != null) {
        FlxTween.tween(titlePart2, {alpha: 1}, 0.8, {ease: FlxEase.sineOut, startDelay: 0.3});
    }
    if (titlePart3 != null) {
        FlxTween.tween(titlePart3, {alpha: 1}, 0.8, {ease: FlxEase.sineOut, startDelay: 0.4});
    }
    if (titlePart4 != null) {
        FlxTween.tween(titlePart4, {alpha: 1}, 0.8, {ease: FlxEase.sineOut, startDelay: 0.4});
    }
    if (titlePart5 != null) {
        FlxTween.tween(titlePart5, {alpha: 1}, 0.8, {ease: FlxEase.sineOut, startDelay: 0.5});
    }
    if (titlePart6 != null) {
        FlxTween.tween(titlePart6, {alpha: 1}, 0.8, {
            ease: FlxEase.sineOut,
            startDelay: 0.3
        });
    }
    if (titleLogo != null) {
        FlxTween.tween(titleLogo, {alpha: 1}, 0.8, {ease: FlxEase.sineOut, startDelay: 0.5});
    }
    
    // Animar la cámara de vuelta a la posición del título
    if (camFollowPos != null) {
        FlxTween.tween(camFollowPos, {y: -270}, 1.2, {ease: FlxEase.sineInOut});
    }
    
    // Ajustar zoom de vuelta al título
    var initialZoom = (ClientPrefs.data.shaders && !ClientPrefs.data.menuShaders) ? 0.6 : 0.79;
    FlxTween.tween(FlxG.camera, {zoom: initialZoom}, 1.0, {ease: FlxEase.sineInOut});
    
    // Transición de música: de menu0 a menu5 (música del título)
    if (musicGroup != null && musicGroup.members != null && musicGroup.members.length >= 6) {
        var fadeTime = 1.2;
        var menu0 = musicGroup.members[0];
        var menu5 = musicGroup.members[5];
        
        if (menu0 != null && menu5 != null) {
            // Bajar menu0
            FlxTween.tween(menu0, {volume: 0}, fadeTime, {
                ease: FlxEase.sineInOut,
                onComplete: function(twn:FlxTween) {
                    menu0.pause();
                }
            });
            
            // Subir menu5
            menu5.play();
            FlxTween.tween(menu5, {volume: 1}, fadeTime, {
                ease: FlxEase.sineInOut
            });
        }
    }
    
    // Reducir shader lens de vuelta a 0
    FlxTween.num(lensStrength, 0.0, 1.0, {ease: FlxEase.sineInOut}, function(hi:Float) {
        lensStrength = hi;
        if (lens != null) {
            lens.setFloat('ushaderStrength', hi);
        }
    });
    
    // Restaurar la interactividad después de la transición
    new FlxTimer().start(1.5, function(tmr:FlxTimer) {
        canSelect = true;
        tmr.destroy();
    });
}

function backOut(){
    canSelect = false;

    if(curMenu != 'options'){
        FlxG.sound.play(Paths.sound('cancelMenu'));
    }

    // Asegurarse de que el sistema de música esté inicializado
    if (musicGroup == null || musicGroup.members == null || musicGroup.members.length == 0) {
        addMusicShit();
    }

    // Guardar el menú anterior antes de cambiarlo
    var prevMenu = curMenu;
    curMenu = "main";

    // Manejar animaciones de salida específicas
    switch (prevMenu){
        case "freeplay":
            leaveFreeplay();
        case "options":
            leaveSettings(); 
        case "extras":
            leaveExtras();
        case "credits":
            // Manejar salida de créditos si es necesario
        case "main":
            // No hacer nada si ya estamos en el menú principal
    }

    // Transición de música basada en el menú anterior
    if (prevMenu != "main" && musicGroup != null && musicGroup.members != null) {
        var fadeTime = 1.2;
        
        // Cancelar todos los tweens existentes de volumen
        for (music in musicGroup.members) {
            if (music != null) {
                FlxTween.cancelTweensOf(music, ["volume"]);
            }
        }
        
        // Bajar volumen de música actual
        if (musicGroup.members[curSelected] != null && musicGroup.members[curSelected].volume > 0) {
            FlxTween.tween(musicGroup.members[curSelected], {volume: 0}, fadeTime, {
                ease: FlxEase.sineInOut,
                onComplete: function(twn:FlxTween) {
                    musicGroup.members[curSelected].pause();
                }
            });
        }
        
        // Subir volumen de menu0 
        if (musicGroup.members[0] != null) {
            musicGroup.members[0].play();
            FlxTween.tween(musicGroup.members[0], {volume: 1}, fadeTime, {
                ease: FlxEase.sineInOut
            });
        }
    }

    // Restaurar la interactividad después de un momento (2 segundos)
    new FlxTimer().start(2, function(tmr){
        canSelect = true;
        tmr.destroy();
    });
}

function enterSettings(){
    // Hacer que la cámara baje más suavemente
    initialTween = FlxTween.tween(camFollowPos, {x: 951, y: 1995}, 2.4, {
        ease: FlxEase.sineInOut
    });

    // Configurar efectos de transición
    maxBlur = 0.05;
    blurAngle = 0;
    
    // Añadir blur gradualmente
    FlxTween.num(0.0, maxBlur, 1.2, {
        ease: FlxEase.sineInOut
    }, function(hi){
        blurAmount = hi;
    });

    // Fade out suave
    var blackOverlay = new FlxSprite().makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFF000000);
    blackOverlay.screenCenter();
    blackOverlay.alpha = 0;
    add(blackOverlay);
    
    // Hacer el fade out
    FlxTween.tween(blackOverlay, {alpha: 1}, 1, {
        ease: FlxEase.sineIn,
        startDelay: 1,
        onComplete: function(twn:FlxTween) {
            // Cambiar al estado de opciones
            MusicBeatState.switchState(new options.OptionsState());
        }
    });

    // Hacer fade out de la música actual
    if (FlxG.sound.music != null) {
        FlxTween.tween(FlxG.sound.music, {volume: 0}, 1.8, {
            ease: FlxEase.sineInOut
        });
    }
}

function enterCredits() {
    // Animar la cámara hacia abajo
    initialTween = FlxTween.tween(camFollowPos, {x: 951, y: 1995}, 1, {ease: FlxEase.backIn});
    
    // Configurar efecto de blur para la transición
    maxBlur = 0.05;
    blurAngle = 0;
    FlxTween.num(0.0, maxBlur, 1, {
        ease: FlxEase.quadIn, 
        onComplete: hideBlur
    }, function(hi) {
        blurAmount = hi;
    });

    // Hacer fade out de menu4 si está activo
    if (musicGroup != null && musicGroup.members != null && musicGroup.members[4] != null) {
        FlxTween.tween(musicGroup.members[4], {volume: 0}, 0.5, {
            ease: FlxEase.sineOut,
            onComplete: function(twn:FlxTween) {
                musicGroup.members[4].pause();
            }
        });
    }

    // Cambiar al estado de créditos después de la animación
    new FlxTimer().start(1, function(tmr) {
        MusicBeatState.switchState(new CreditsState());
    });
}

function leaveSettings(){
    initialTween = FlxTween.tween(camFollowPos, {x: 951, y: 570}, 4, {ease: FlxEase.backOut});
}

function fixLayers():Void
{
    // El problema: freeplayBg y freeplayText se agregan DESPUÉS de weekHeaders
    // y lo tapan. Necesitamos mover weekHeaders al FINAL de TODO.
    
    if (weekHeaders != null) {
        // Mover weekHeaders completamente al final
        remove(weekHeaders, false);
        add(weekHeaders);
    }
    
    // Si difficulties también existe, ponerlo después de weekHeaders
    // para que los selectores de dificultad estén encima
    if (difficulties != null) {
        remove(difficulties, false);
        add(difficulties);
    }
}


   function enterFreeplay(){
    trace('[DEBUG] Dificultad actualizada a: ' + lastDifficultyName + ' (curDiff=' + curDiff + ', curDifficulty=' + curDifficulty + ')');
    
    // trace('[DEBUG] Entrando a freeplay');
    
    // Primero generamos la lista de canciones
    Difficulty.list = Difficulty.defaultList.copy();
    generateFreeplaySongList();
    
    // Sincronizar curDifficulty con curDiff
    curDifficulty = curDiff;
    
    // Ocultamos elementos del menú principal
    if (middle != null) { middle.visible = true; } // Mantener visible para transición
    if (right != null) { right.visible = true; } // Mantener visible
    if (optionText != null) { optionText.visible = true; }
    if (selectedText != null) { selectedText.visible = true; }
    if (optionBg != null) { optionBg.visible = true; }
    
    
    
 
    addFreeplayText(); 
    populateFreeplayVisuals();
    addRightShit(); 
    
  
    fixLayers();

        curMenu = "freeplay"; // <-- Esto es clave
        curSelectedFreeplay = 0;
        updateOption();

        new FlxTimer().start(0.75, function(tmr){
            configureFreeplayClock(curSelectedFreeplay);
            tmr.destroy();
        });
        maxBlur = 0.05;
        blurAngle = 90;
        initialTween = FlxTween.tween(camFollowPos, {x: 4800}, 0.6, {ease: FlxEase.circIn, onComplete: function(twn) {
            
            if (middle != null) middle.visible = false;
            if (right != null) right.visible = true;
            
            easierTweenRight(twn);
            fixLayers(); 
        }});
        FlxTween.num(0.0, maxBlur, 0.3, {ease: FlxEase.quadIn, onComplete: hideBlur}, function(hi)
            
            {
            blurAmount = hi;
        });
    }

   
   

function leaveFreeplay(){
    maxBlur = 0.05;
    blurAngle = 90;

    trace('[DEBUG] leaveFreeplay llamado');
    var fadeTime = 1.2;
    
   
    if (middle != null) {
        remove(middle, true);
        middle.destroy();
    }
    middle = new FlxSpriteGroup();
    add(middle);
    
    
    addMiddleShit();
    addTextShit();
    
    
    fixLayers();
    
   
    if (layer1 != null) {
        layer1.alpha = 0;
        FlxTween.tween(layer1, {alpha: 1}, 0.6, {ease: FlxEase.quadOut});
    }
    
   
    if (musicGroup != null && musicGroup.members != null) {
       
        for (sound in musicGroup.members) {
            if (sound != null) {
                FlxTween.cancelTweensOf(sound, ["volume"]);
            }
        }
        
        // Hacer fade out de la música actual (menu1)
        var currentMusic = musicGroup.members[1];
        if (currentMusic != null && currentMusic.volume > 0) {
            FlxTween.tween(currentMusic, {volume: 0}, fadeTime, {
                ease: FlxEase.sineInOut,
                onComplete: function(twn:FlxTween) {
                    currentMusic.pause();
                }
            });
        }
        

        new FlxTimer().start(0.3, function(tmr:FlxTimer) {
            var menuMusic = musicGroup.members[0];
            if (menuMusic != null) {
                menuMusic.play();
                menuMusic.volume = 0;
                FlxTween.tween(menuMusic, {volume: 1}, fadeTime, {
                    ease: FlxEase.sineInOut
                });
            }
            tmr.destroy();
        });
    }
    
    
    if (middle != null) { middle.visible = true; } 
    if (right != null) { right.visible = true; } 
    if (optionText != null) { 
        optionText.visible = true; 
        for (i in 0...optionText.members.length) {
            if (optionText.members[i] != null) {
                
                optionText.members[i].alpha = (i == curSelected) ? 0 : 0.2;
            }
        }
    }
    if (selectedText != null) { 
        selectedText.visible = true;
        for (i in 0...selectedText.members.length) {
            if (selectedText.members[i] != null) {
                
                selectedText.members[i].alpha = (i == curSelected) ? 1.0 : 0;
            }
        }
    }
    if (optionBg != null) { 
        optionBg.visible = true;
        for (i in 0...optionBg.members.length) {
            if (optionBg.members[i] != null) {
                
                optionBg.members[i].alpha = (i == curSelected) ? 0.2 : 0;
            }
        }
    }


    updateOption();
    
    initialTween = FlxTween.tween(camFollowPos, {x: 1951}, 0.6, {
        ease: FlxEase.circIn, 
        onComplete: function(twn) {
            easierTweenLeft(twn);
            fixLayers(); 
        }
    });
    
 
    FlxTween.num(0.0, maxBlur, 0.3, {
        ease: FlxEase.quadIn, 
        onComplete: hideBlur
    }, function(hi){
        blurAmount = hi;
    });
}



           

function enterExtras(){
        addExtraShit();
    maxBlur = 0.1;
    blurAngle = 90.0;
    if (blackFade != null && Std.isOfType(blackFade, FlxSprite)) FlxTween.tween(blackFade,  {alpha: 0}, 1.0, {ease: FlxEase.sineOut});
    if (fullBlack != null && Std.isOfType(fullBlack, FlxSprite)) FlxTween.tween(fullBlack,  {alpha: 0}, 1.0, {ease: FlxEase.sineOut});
    if (bfFloat != null && Std.isOfType(bfFloat, FlxSprite)) FlxTween.tween(bfFloat,  {x:453, y: 313, alpha: 0}, 1.0, {ease: FlxEase.sineOut});
    if (bfFloatRed != null && Std.isOfType(bfFloatRed, FlxSprite)) FlxTween.tween(bfFloatRed,  {x:453, y: 313}, 1.0, {ease: FlxEase.sineOut});
    if (bgRed != null && Std.isOfType(bgRed, FlxSprite)) FlxTween.tween(bgRed, {alpha: 1}, 1.0, {ease: FlxEase.sineOut});
    if (buildingRed != null && Std.isOfType(buildingRed, FlxSprite)) FlxTween.tween(buildingRed, {angle: 0,alpha: 1}, 1.0, {ease: FlxEase.sineOut});
    if (layer2 != null && Std.isOfType(layer2, FlxSprite)) FlxTween.tween(layer2, {angle: 15}, 1.0, {ease: FlxEase.sineOut});
    if (chainRed != null && Std.isOfType(chainRed, FlxSprite)) FlxTween.tween(chainRed, {angle: 170, alpha: 1}, 1.0, {ease: FlxEase.sineOut});

    if (selectedText != null && selectedText.members != null && selectedText.members.length > 3 && selectedText.members[3] != null)
        FlxTween.tween(selectedText.members[3], {alpha: 0}, 1.0, {ease: FlxEase.sineOut});
    if (optionBg != null && optionBg.members != null && optionBg.members.length > 3 && optionBg.members[3] != null)
        FlxTween.tween(optionBg.members[3], {alpha: 0}, 1.0, {ease: FlxEase.sineOut});
    if (optionText != null && optionText.members != null && optionText.members.length > 1 && optionText.members[1] != null)
        FlxTween.tween(optionText.members[1], {alpha: 0}, 1.0, {ease: FlxEase.sineOut});
    if (optionText != null && optionText.members != null && optionText.members.length > 2 && optionText.members[2] != null)
        FlxTween.tween(optionText.members[2], {alpha: 0}, 1.0, {ease: FlxEase.sineOut});
    if (optionText != null && optionText.members != null && optionText.members.length > 0 && optionText.members[0] != null)
        FlxTween.tween(optionText.members[0], {alpha: 0}, 1.0, {ease: FlxEase.sineOut});
    if (optionText != null && optionText.members != null && optionText.members.length > 4 && optionText.members[4] != null)
        FlxTween.tween(optionText.members[4], {alpha: 0}, 1.0, {ease: FlxEase.sineOut});

    new FlxTimer().start(0.5, function(tmr){
        if (selectedText != null && selectedText.members != null && selectedText.members.length > 3 && selectedText.members[3] != null)
            selectedText.members[3].alpha = 0;
        if (optionBg != null && optionBg.members != null && optionBg.members.length > 3 && optionBg.members[3] != null)
            optionBg.members[3].alpha = 0;
        if (optionText != null && optionText.members != null && optionText.members.length > 1 && optionText.members[1] != null)
            optionText.members[1].alpha = 0;
        if (optionText != null && optionText.members != null && optionText.members.length > 2 && optionText.members[2] != null)
            optionText.members[2].alpha = 0;
        if (optionText != null && optionText.members != null && optionText.members.length > 0 && optionText.members[0] != null)
            optionText.members[0].alpha = 0;
        if (optionText != null && optionText.members != null && optionText.members.length > 4 && optionText.members[4] != null)
            optionText.members[4].alpha = 0;
        updateOption();
        tmr.destroy();
    });

    initialTween = FlxTween.tween(camFollowPos, {y: 1700}, 0.6, {ease: FlxEase.circIn, onComplete: function(twn) {
        easierTweenDown(twn);
        fixLayers(); 
    }});

    FlxTween.num(90.0, 0.0, 0.6, {ease: FlxEase.quadIn, onComplete: hideBlur}, function(hi){
        blurAngle = hi;
    });

    FlxTween.num(0.0, maxBlur, 0.5, {ease: FlxEase.quadOut, onComplete: hideBlur}, function(hi){
        blurAmount = hi;
    });

   
    new FlxTimer().start(1.05, function(tmr) {
        if (bgRed != null && Std.isOfType(bgRed, FlxSprite)) {
            bgRed.alpha = 1;
        } else {
            trace('[DEBUG] bgRed es null o tipo incorrecto');
        }
        if (buildingRed != null && Std.isOfType(buildingRed, FlxSprite)) {
            buildingRed.alpha = 1;
        } else {
            trace('[DEBUG] buildingRed es null o tipo incorrecto');
        }
        if (chainRed != null && Std.isOfType(chainRed, FlxSprite)) {
            chainRed.alpha = 1;
        } else {
            trace('[DEBUG] chainRed es null o tipo incorrecto');
        }
        if (bfFloatRed != null && Std.isOfType(bfFloatRed, FlxSprite)) {
            bfFloatRed.alpha = 1;
        } else {
            trace('[DEBUG] bfFloatRed es null o tipo incorrecto');
        }
        if (bfFloat != null && Std.isOfType(bfFloat, FlxSprite)) {
            bfFloat.alpha = 0;
        } else {
            trace('[DEBUG] bfFloat es null o tipo incorrecto');
        }
        if (blackFade != null && Std.isOfType(blackFade, FlxSprite)) {
            blackFade.alpha = 0;
        } else {
            trace('[DEBUG] blackFade es null o tipo incorrecto');
        }
        if (fullBlack != null && Std.isOfType(fullBlack, FlxSprite)) {
            fullBlack.alpha = 0;
        } else {
            trace('[DEBUG] fullBlack es null o tipo incorrecto');
        }
        if (layer2 != null && Std.isOfType(layer2, FlxSprite)) {
            layer2.alpha = 1;
        } else {
            trace('[DEBUG] layer2 es null o tipo incorrecto');
        }
        tmr.destroy();
    });
    
    // Crear transición separada para Extras al final
    if (transitionExtras != null) {
        remove(transitionExtras);
        transitionExtras.destroy();
    }
    transitionExtras = new FlxSprite();
    transitionExtras.frames = Paths.getSparrowAtlas('burnTransition');
    transitionExtras.animation.addByPrefix("idle", 'burnTransition idle', 24, false);
    transitionExtras.animation.play("idle", true);
    transitionExtras.scrollFactor.set(0,0);
    transitionExtras.scale.set(2.5,2.5);
    transitionExtras.antialiasing = true;
    transitionExtras.alpha = 0;
    transitionExtras.blend = BlendMode.MULTIPLY;
    transitionExtras.setPosition(150,119);
    transitionExtras.cameras = [FlxG.camera];
    add(transitionExtras);
    trace('[DEBUG] transitionExtras creada en enterExtras - Alpha: ' + transitionExtras.alpha);
}

function leaveExtras(){
    maxBlur = 0.1;
    blurAngle = 90.0;
    
    // Limpiar transición de extras
    if (transitionExtras != null) {
        remove(transitionExtras);
        transitionExtras.destroy();
        transitionExtras = null;
    }

    if (bfFloat != null && Std.isOfType(bfFloat, FlxSprite)) FlxTween.tween(bfFloat,  {x:574, y:200}, 1.0, {ease: FlxEase.sineOut});
    if (bfFloatRed != null && Std.isOfType(bfFloatRed, FlxSprite)) FlxTween.tween(bfFloatRed, {x:574, y:200, alpha: 0}, 1.0, {ease: FlxEase.sineOut});
    if (bgRed != null && Std.isOfType(bgRed, FlxSprite)) FlxTween.tween(bgRed, {alpha: 0}, 1.0, {ease: FlxEase.sineOut});
    if (buildingRed != null && Std.isOfType(buildingRed, FlxSprite)) FlxTween.tween(buildingRed, {angle: -14,alpha: 0}, 1.0, {ease: FlxEase.sineOut});
    if (layer2 != null && Std.isOfType(layer2, FlxSprite)) FlxTween.tween(layer2, {angle: 0}, 1.0, {ease: FlxEase.sineOut});
    if (chainRed != null && Std.isOfType(chainRed, FlxSprite)) FlxTween.tween(chainRed, {angle: 144, alpha: 0}, 1.0, {ease: FlxEase.sineOut});

    new FlxTimer().start(0.5, function(tmr){
        if (ifSelected != null) ifSelected.alpha = 0;
        if (ifBg != null) ifBg.alpha = 0;
        if (ifText != null) ifText.alpha = 0;
        if (sidestoryBg != null) sidestoryBg.alpha = 0;
        if (sidestorySelected != null) sidestorySelected.alpha = 0;
        if (sidestoryText != null) sidestoryText.alpha = 0;

      
        for (i in 0...5) {
            if (i == curSelected) {
               
                if (selectedText != null && selectedText.members != null && selectedText.members.length > i && selectedText.members[i] != null)
                    FlxTween.tween(selectedText.members[i], {alpha: 1}, 0.5, {ease: FlxEase.sineOut});
                if (optionBg != null && optionBg.members != null && optionBg.members.length > i && optionBg.members[i] != null)
                    FlxTween.tween(optionBg.members[i], {alpha: 0.2}, 0.5, {ease: FlxEase.sineOut});
                if (optionText != null && optionText.members != null && optionText.members.length > i && optionText.members[i] != null)
                    optionText.members[i].alpha = 0; 
            } else {

                if (optionText != null && optionText.members != null && optionText.members.length > i && optionText.members[i] != null)
                    FlxTween.tween(optionText.members[i], {alpha: 0.2}, 0.5, {ease: FlxEase.sineOut});
                if (selectedText != null && selectedText.members != null && selectedText.members.length > i && selectedText.members[i] != null)
                    selectedText.members[i].alpha = 0;
                if (optionBg != null && optionBg.members != null && optionBg.members.length > i && optionBg.members[i] != null)
                    optionBg.members[i].alpha = 0;
            }
        }
        tmr.destroy();
    });

    FlxTween.tween(camFollowPos, {y: 1700}, 0.6, {ease: FlxEase.circIn, onComplete: function(twn) {
        easierTweenUp(twn);
        fixLayers();
    }});

    FlxTween.num(90.0, 0.0, 0.6, {ease: FlxEase.quadIn, onComplete: hideBlur}, function(hi){
        blurAngle = hi;
    });

    FlxTween.num(0.0, maxBlur, 0.5, {ease: FlxEase.quadOut, onComplete: hideBlur}, function(hi){
        blurAmount = hi;
    });
}

    function hideBlur(tween:FlxTween):Void
{
    FlxTween.num(maxBlur, 0.0, 0.5, {ease: FlxEase.linear}, function(hi){
        blurAmount = hi;
    });
}

function updateDifficulty():Void {
    
    trace('[UPDATE_DIFFICULTY] ========== INICIO ==========');
    trace('[UPDATE_DIFFICULTY] curDiff ANTES: ' + curDiff);
    trace('[UPDATE_DIFFICULTY] Difficulty.list.length: ' + Difficulty.list.length);
    trace('[UPDATE_DIFFICULTY] Difficulty.list: ' + Difficulty.list);
  
    // *** FIX CRÍTICO: En freeplay SIEMPRE usar 3 dificultades fijas ***
    if (curMenu == "freeplay") {
        // Forzar lista de 3 dificultades para el freeplay
        Difficulty.list = ["easy", "normal", "hard"];
        trace('[UPDATE_DIFFICULTY] FORZANDO lista de freeplay a 3 dificultades: ' + Difficulty.list);
    } else if(Difficulty.list.length < 1) {
        Difficulty.list = Difficulty.defaultList.copy();
        trace('[UPDATE_DIFFICULTY] Lista reiniciada a defaultList');
    }
    
   
    if(curDiff < 0) {
        trace('[UPDATE_DIFFICULTY] curDiff < 0, ajustando a 0');
        curDiff = 0;
    }
    if(curDiff >= Difficulty.list.length) {
        trace('[UPDATE_DIFFICULTY] curDiff >= length (' + curDiff + ' >= ' + Difficulty.list.length + '), ajustando a ' + (Difficulty.list.length - 1));
        curDiff = Difficulty.list.length - 1;
    }
    
    trace('[UPDATE_DIFFICULTY] curDiff DESPUÉS de validación: ' + curDiff);

    if (curDiff >= 0 && curDiff < Difficulty.list.length) {
        lastDifficultyName = Difficulty.list[curDiff];
    } else {
        lastDifficultyName = Difficulty.defaultList[1];
    }
    
    trace('[UPDATE_DIFFICULTY] lastDifficultyName: ' + lastDifficultyName);

    curDifficulty = curDiff;
    
    trace('[UPDATE_DIFFICULTY] ========== FIN ==========');

    if(difficulties != null) {
        difficulties.visible = true;
        difficulties.forEach(function(spr:FlxSprite) {
            if (Std.isOfType(spr, FlxSprite)) {
                var i = difficulties.members.indexOf(spr);
                spr.alpha = (i == curDiff) ? 1 : 0;
            }
        });
        
        if (diffSelectL != null) {
            diffSelectL.alpha = 0.2;
            diffSelectL.setPosition(4460, 150);
        }
        if (diffSelectR != null) {
            diffSelectR.alpha = 0.2;
            diffSelectR.setPosition(4860, 150);
        }
    }
    
    
}

function allowSelection():Void{
    updateOption();
}

function updateOption():Void
{
    if (curMenu == "extras"){
        if (curSelectedExtra == 0){
            ifBg.alpha = 0.2;
            ifSelected.alpha = 1;
            ifText.alpha =  0;
    
            sidestoryBg.alpha = 0;
            sidestorySelected.alpha = 0;
            sidestoryText.alpha = 0.2;
        } else {
            ifBg.alpha = 0;
            ifSelected.alpha = 0;
            ifText.alpha =  0.2;
    
            sidestoryBg.alpha = 0.2;
            sidestorySelected.alpha = 1;
            sidestoryText.alpha = 0;
        }
        return;
    }


    if (curMenu == 'freeplay' && freeplayText != null && freeplaySelectedText != null && freeplayBg != null) {
        for (i in 0...freeplaySongs.length) {
            var fText = (freeplayText.members != null && i < freeplayText.members.length) ? freeplayText.members[i] : null;
            var fSelText = (freeplaySelectedText.members != null && i < freeplaySelectedText.members.length) ? freeplaySelectedText.members[i] : null;
            var fBg = (freeplayBg.members != null && i < freeplayBg.members.length) ? freeplayBg.members[i] : null;
            if (i == curSelectedFreeplay){
                if (fText != null) fText.alpha = 0;
                if (fSelText != null) {
                    fSelText.alpha = 1;
                    fSelText.scale.set(1.2,1.2);
                }
                if (fBg != null) {
                    fBg.alpha = 0.2;
                    fBg.scale.set(1.2,1.2);
                }
            } else{
                if (fText != null) {
                    fText.alpha = 0.2;
                    fText.scale.set(1.1,1.1);
                }
                if (fBg != null) {
                    fBg.alpha = 0;
                    fBg.scale.set(1.1,1.1);
                }
                if (fSelText != null) fSelText.alpha = 0;
            }
        }
    }

    for (i in 0...5) {
        var oText = (optionText != null && optionText.members != null && i < optionText.members.length) ? optionText.members[i] : null;
        var sText = (selectedText != null && selectedText.members != null && i < selectedText.members.length) ? selectedText.members[i] : null;
        var oBg = (optionBg != null && optionBg.members != null && i < optionBg.members.length) ? optionBg.members[i] : null;
        // The entrance fade can still be running when menu input unlocks.
        if (curMenu == "main") {
            if (oText != null) FlxTween.cancelTweensOf(oText, ["alpha"]);
            if (sText != null) FlxTween.cancelTweensOf(sText, ["alpha"]);
            if (oBg != null) FlxTween.cancelTweensOf(oBg, ["alpha"]);
        }
        if (i == curSelected){
            if (oText != null) oText.alpha = 0;
            if (sText != null) {
                sText.alpha = 1;
                sText.scale.set(0.8,0.8);
            }
            if (oBg != null) {
                oBg.alpha = 0.2;
                oBg.scale.set(0.8,0.8);
            }
        } else{
            if (oText != null) {
                oText.alpha = 0.2;
                oText.scale.set(0.75,0.75);
            }
            if (oBg != null) {
                oBg.alpha = 0;
                oBg.scale.set(0.75,0.75);
            }
            if (sText != null) sText.alpha = 0;
        }
    }
}

function getDifficultyName(diff:Int):String {
    return Difficulty.list[diff];
}

//  i want to believe nothing down here exists


// sry for this, its 3am and im ded
// im randomizing the target so it has a cooler visual effect
function updateClock(which:Int)
{
    switch (which){
        case 0:
            values[0].desired = 2;
            values[0].target = 6;
            values[1].desired = 3;
            values[1].target = 5;
            values[2].desired = 5;
            values[2].target = 9;
            values[3].desired = 9;
            values[3].target = 0;
            values[4].desired = 0;
            values[4].target = 4;
            values[5].desired = 9;
            values[5].target = 5;
        case 1:
            values[0].desired = 0;
            values[0].target = 5;
            values[1].desired = 0;
            values[1].target = 3;
            values[2].desired = 0;
            values[2].target = 4;
            values[3].desired = 2;
            values[3].target = 9;
            values[4].desired = 1;
            values[4].target = 4;
            values[5].desired = 0;
            values[5].target = 5;
        case 2:
            values[0].desired = 0;
            values[0].target = 4;
            values[1].desired = 0;
            values[1].target = 5;
            values[2].desired = 0;
            values[2].target = 4;
            values[3].desired = 8;
            values[3].target = 0;
            values[4].desired = 1;
            values[4].target = 4;
            values[5].desired = 0;
            values[5].target = 4;
        case 3:
            values[0].desired = 0;
            values[0].target = 3;
            values[1].desired = 0;
            values[1].target = 3;
            values[2].desired = 0;
            values[2].target = 4;
            values[3].desired = 7;
            values[3].target =  0;
            values[4].desired = 1;
            values[4].target = 4;
            values[5].desired =  0;
            values[5].target = 3;
    }
}
    

function addFreeplayText(){
    trace('[DEBUG] addFreeplayText llamado');
   
    if (diffTween != null) { diffTween.cancel(); diffTween = null; }
    if (diffSelectRightTween != null) { diffSelectRightTween.cancel(); diffSelectRightTween = null; }
    if (diffSelectLeftTween != null) { diffSelectLeftTween.cancel(); diffSelectLeftTween = null; }
    if (initialTween != null) { initialTween.cancel(); initialTween = null; }
  

    if (freeplayBg != null) {
        remove(freeplayBg, true);
        freeplayBg.destroy();
    }
    if (freeplayText != null) {
        remove(freeplayText, true);
        freeplayText.destroy();
    }
 if (freeplaySelectedText != null) {
        remove(freeplaySelectedText, true);
        freeplaySelectedText.destroy();
    }
    if (difficulties != null) {
        remove(difficulties, true);
        difficulties.destroy();
    }
    freeplayBg = new FlxSpriteGroup();
    add(freeplayBg);

    freeplayText = new FlxSpriteGroup();
    add(freeplayText);

    freeplaySelectedText = new FlxSpriteGroup();
    add(freeplaySelectedText);

    difficulties = new FlxSpriteGroup();
    add(difficulties);

    // *** BUG FIX #5: Asegurar que Difficulty.list tenga las 3 dificultades correctas ***
    if (Difficulty.list.length != 3) {
        trace('[BUG FIX] Difficulty.list tenía ' + Difficulty.list.length + ' elementos, reiniciando a 3 dificultades');
        Difficulty.list = Difficulty.defaultList.copy();
    }
    
    // Validar que las dificultades están en el orden correcto
    if (Difficulty.list.length >= 3) {
        trace('[DIFFICULTY] Lista de dificultades: [0]=' + Difficulty.list[0] + ', [1]=' + Difficulty.list[1] + ', [2]=' + Difficulty.list[2]);
    }

    for (i in 0...3) {
        var textDiff = new FlxSprite(0,0, Paths.image('menus/freeplay/d'+i));
        textDiff.scrollFactor.set(1,1);
        textDiff.scale.set(1,1);
        textDiff.alpha = 0;
        difficulties.add(textDiff);
    }

    diffSelectL = new FlxSprite(4660,150, Paths.image('menus/freeplay/dSelectLeft'));
    diffSelectL.scrollFactor.set(1,1);
    diffSelectL.scale.set(1,1);
    diffSelectL.alpha = 0.2;
    add(diffSelectL);

    diffSelectR = new FlxSprite(4660,150, Paths.image('menus/freeplay/dSelectRight'));
    diffSelectR.scrollFactor.set(1,1);
    diffSelectR.scale.set(1,1);
    diffSelectR.alpha = 0.2;
    add(diffSelectR);

    difficulties.setPosition(4660,150);

    freeplaySelectedText.setPosition(3410,400);
    freeplayText.setPosition(3410,400);
    freeplayBg.setPosition(3410,400);

    freeplaySelectedText.scale.set(1.2,1.2);
    freeplayText.scale.set(1.2,1.2);
    freeplayBg.scale.set(1.2,1.2);

    object = difficulties;

    // --- LÍNEAS CLAVE PARA VISIBILIDAD CORRECTA ---
    curSelectedFreeplay = 0;
    updateOption();
    configureFreeplayClock(curSelectedFreeplay);
    curDiff = 1; // *** BUG FIX #6: Iniciar en Normal (1) en lugar de Hard (2) ***
    updateDifficulty();
}

function addTextShit(){
    // trace('[DEBUG] addTextShit llamado');
    
    // IMPORTANTE: Destruir grupos existentes para evitar duplicados
    if (optionBg != null) {
        remove(optionBg, true);
        optionBg.destroy();
        optionBg = null;
    }
    if (optionText != null) {
        remove(optionText, true);
        optionText.destroy();
        optionText = null;
    }
    if (selectedText != null) {
        remove(selectedText, true);
        selectedText.destroy();
        selectedText = null;
    }
    
    optionBg = new FlxSpriteGroup();
    add(optionBg);

    optionText = new FlxSpriteGroup();
    add(optionText);

    selectedText = new FlxSpriteGroup();
    add(selectedText);

    optionText.scale.set(0.6,0.6);
    optionText.setPosition(-60,40);

    selectedText.scale.set(0.6,0.6);
    selectedText.setPosition(-60,40);

    optionBg.scale.set(0.6,0.6);
    optionBg.setPosition(-60,40);

    for (i in 0...5) {
        // Determinar alphas según si está seleccionado o no
        var isSelected = (i == curSelected);
        
        var textBg = new FlxSprite(954,-156);
        textBg.frames = Paths.getSparrowAtlas("menus/mainmenu/menuButtons");
        textBg.animation.addByPrefix("idle", "b" + i, 0, true);
               textBg.animation.play("idle");
        textBg.scrollFactor.set(1,1);
        textBg.scale.set(isSelected ? 0.8 : 0.75, isSelected ? 0.8 : 0.75);
        textBg.alpha = isSelected ? 0.2 : 0;
        textBg.blend = BlendMode.NORMAL;
        optionBg.add(textBg);

        var textOpt = new FlxSprite(954,-156);
        textOpt.frames = Paths.getSparrowAtlas("menus/mainmenu/menuButtons");
        textOpt.animation.addByPrefix("idle", "t" + i, 0, true);
        textOpt.animation.play("idle");
        textOpt.scrollFactor.set(1,1);
        textOpt.scale.set(isSelected ? 0.8 : 0.75, isSelected ? 0.8 : 0.75);
        textOpt.alpha = isSelected ? 0 : 0.2; // Si está seleccionado, ocultar optionText
               optionText.add(textOpt);

        var textSel = new FlxSprite(954,-156);
        textSel.frames = Paths.getSparrowAtlas("menus/mainmenu/menuButtons");
        textSel.animation.addByPrefix("idle", "s" + i, 0, true);
        textSel.animation.play("idle");
        textSel.scrollFactor.set(1,1);
        textSel.scale.set(isSelected ? 0.8 : 0.75, isSelected ? 0.8 : 0.75);
        textSel.alpha = isSelected ? 1 : 0; // Si está seleccionado, mostrar selectedText
        selectedText.add(textSel);
    }

    // Asegura que los grupos tengan al menos 5 miembros para evitar nulls en los timers
    while (optionBg != null && optionBg.members != null && optionBg.members.length < 5) {
        var filler = new FlxSprite(0,0);
        filler.alpha = 0;
        optionBg.add(filler);
    }
    while (optionText != null && optionText.members != null && optionText.members.length < 5) {
        var filler = new FlxSprite(0,0);
        filler.alpha = 0;
        optionText.add(filler);
    }
    while (selectedText != null && selectedText.members != null && selectedText.members.length < 5) {
        var filler = new FlxSprite(0,0);
        filler.alpha = 0;
        selectedText.add(filler);
    }

}

function revealMainMenuTexts(){
    // trace("[DEBUG] Entrando a revealMainMenuTexts");
    
    // IMPORTANTE: Asegurar que todos los grupos estén visibles
    if (optionText != null) optionText.visible = true;
    if (selectedText != null) selectedText.visible = true;
    if (optionBg != null) optionBg.visible = true;
    
    // Primero resetear todos los alphas a 0 y asegurar visibilidad individual
    if (optionText != null && optionText.members != null) {
        for (i in 0...optionText.members.length) {
            if (optionText.members[i] != null) {
                optionText.members[i].alpha = 0;
                optionText.members[i].visible = true; // Asegurar visibilidad
            }
        }
    }
    if (selectedText != null && selectedText.members != null) {
        for (i in 0...selectedText.members.length) {
            if (selectedText.members[i] != null) {
                selectedText.members[i].alpha = 0;
                selectedText.members[i].visible = true; // Asegurar visibilidad
            }
        }
    }
    if (optionBg != null && optionBg.members != null) {
        for (i in 0...optionBg.members.length) {
            if (optionBg.members[i] != null) {
                optionBg.members[i].alpha = 0;
                optionBg.members[i].visible = true; // Asegurar visibilidad
            }
        }
    }

    // Ahora revelar con animación escalonada respetando curSelected
    var delays:Array<Float> = [0.7, 0.9, 1.1, 1.3, 1.5];
    
    for (i in 0...5) {
        var delay = delays[i];
        var index = i; // Capturar el valor para el closure
        
        new FlxTimer().start(delay, function(tmr){
            if (index == curSelected) {
                // Opción seleccionada: mostrar selectedText y optionBg
                if (selectedText != null && selectedText.members != null && selectedText.members.length > index && selectedText.members[index] != null)
                    FlxTween.tween(selectedText.members[index], {alpha: 1}, 1.0, {ease: FlxEase.sineOut});
                if (optionBg != null && optionBg.members != null && optionBg.members.length > index && optionBg.members[index] != null)
                    FlxTween.tween(optionBg.members[index], {alpha: 0.2}, 1.0, {ease: FlxEase.sineOut});
                // optionText[index] permanece en alpha 0
            } else {
                // Opción no seleccionada: mostrar optionText
                if (optionText != null && optionText.members != null && optionText.members.length > index && optionText.members[index] != null)
                    FlxTween.tween(optionText.members[index], {alpha: 0.2}, 1.0, {ease: FlxEase.sineOut});
                // selectedText[index] y optionBg[index] permanecen en alpha 0
            }
            tmr.destroy();
        });
    }

    new FlxTimer().start(2, function(tmr){
        canSelect = true;
        menuRevealed = true;
        tmr.destroy();
    });
}

function addExtraShit(){
    // trace('[DEBUG] addExtraShit llamado');
    bgRed = new FlxSprite(54,-336, Paths.image('menus/mainmenu/RedBg'));
    add(bgRed);
    bgRed.scrollFactor.set(0,0);
    bgRed.scale.set(12.3,12.3);
    bgRed.alpha = 0;

    buildingRed = new FlxSprite(-36,-196, Paths.image('menus/mainmenu/RedBuildings'));
    add(buildingRed);
    buildingRed.scrollFactor.set(0,0.1);
    buildingRed.scale.set(1.8,1.8);
    buildingRed.alpha = 0;

    chainRed = new FlxSprite(-276,-1116, Paths.image('menus/mainmenu/chainRed'));
    add(chainRed);
    chainRed.scrollFactor.set(0,0.3);
    chainRed.scale.set(1.8,1.8);
    chainRed.alpha = 0;
    chainRed.angle = 144;

    bfFloatRed = new FlxSprite();
    bfFloatRed.frames = Paths.getSparrowAtlas('menus/mainmenu/floatingBfRed');
    bfFloatRed.animation.addByPrefix("idle", 'BfFloat', 24, true);
    bfFloatRed.animation.play("idle", true);
    bfFloatRed.scrollFactor.set(1, 1);
    bfFloatRed.scale.set(1,1);
    bfFloatRed.angle = 180;
    bfFloatRed.antialiasing = true;
    bfFloatRed.setPosition(574,210);
    add(bfFloatRed);
    bfFloatRed.alpha = 0;

    ifBg = new FlxSprite(-307,503, Paths.image('menus/title/ifBg'));
    ifBg.scrollFactor.set(1,1);
    ifBg.scale.set(1,1);
    ifBg.alpha = 0;
    add(ifBg);

    ifText = new FlxSprite(-300,493, Paths.image('menus/title/ifText'));
    ifText.scrollFactor.set(1,1);
    ifText.scale.set(0.9,0.9);
    ifText.alpha = 0;
    add(ifText);

    ifSelected = new FlxSprite(-307,503, Paths.image('menus/title/ifSelected'));
    add(ifSelected);
    ifSelected.scrollFactor.set(1,1);
    ifSelected.scale.set(1,1);
    ifSelected.alpha = 0;

    sidestoryBg = new FlxSprite(883,504, Paths.image('menus/title/sidestoryBg'));
    sidestoryBg.scrollFactor.set(1,1);
    sidestoryBg.scale.set(0.9,0.9);
    sidestoryBg.alpha = 0;
    add(sidestoryBg);

    sidestoryText = new FlxSprite(890,494, Paths.image('menus/title/sidestoryText'));
    sidestoryText.scrollFactor.set(1,1);
    sidestoryText.scale.set(0.8,0.8);
    sidestoryText.alpha = 0;
    add(sidestoryText);

    sidestorySelected = new FlxSprite(883,504, Paths.image('menus/title/sidestorySelected'));
    sidestorySelected.scrollFactor.set(1,1);
    sidestorySelected.scale.set(0.9,0.9);
    sidestorySelected.alpha = 0;
    add(sidestorySelected);
}

function addMiddleShit(){
    if (middle == null) {
        middle = new FlxSpriteGroup();
        add(middle);
    }
    
    // Limpiar elementos existentes del grupo middle
    middle.forEach(function(sprite) {
        middle.remove(sprite, true);
        sprite.destroy();
    });
    
    layer1 = new FlxSprite(-536,-806, Paths.image('menus/mainmenu/layer1'));
    middle.add(layer1);
    layer1.scrollFactor.set(0, 0); // Completamente fijo en pantalla

    layer2 = new FlxSprite(-387,-230, Paths.image('menus/mainmenu/layer2'));
    middle.add(layer2);
    layer2.scrollFactor.set(0.6,0.1);

    var layer3 = new FlxSprite(119,-90, Paths.image('menus/mainmenu/layer3'));
    layer3.scale.set(1.3,1.3);
    middle.add(layer3);
    layer3.scrollFactor.set(0.6,0.15);

    var layer4 = new FlxSprite(-202.3, -575.35, Paths.image('menus/mainmenu/layer4'));
    middle.add(layer4);
    layer4.scrollFactor.set(0.7,0.3);
    layer4.alpha = 0.5;
   
    bfFloat = new FlxSprite();
    bfFloat.frames = Paths.getSparrowAtlas('menus/mainmenu/floatingBf');
    bfFloat.animation.addByPrefix("idle", 'BfFloat', 24, true);
    bfFloat.animation.play("idle", true);
    bfFloat.scrollFactor.set(1, 1);
    bfFloat.scale.set(1,1);
    bfFloat.antialiasing = true;
    bfFloat.setPosition(574,200);
    middle.add(bfFloat);

    var layer5 = new FlxSprite(-132,-651, Paths.image('menus/mainmenu/layer5'));
   middle.add(layer5);
    layer5.scrollFactor.set(1.3,2);
    layer5.scale.set(1,1.5);

    var lightRays = new FlxSprite();
    lightRays.frames = Paths.getSparrowAtlas('menus/mainmenu/lightRays');
    lightRays.animation.addByPrefix("idle", 'LightRays', 8, true);
    lightRays.animation.play("idle", true);
    
    lightRays.scale.set(1.5,1.5);
    lightRays.antialiasing = true;
    lightRays.setPosition(-106,-360);
    middle.add(lightRays);
    lightRays.scrollFactor.set(1, 0);

    var lightRays2 = new FlxSprite(); // double it up
    lightRays2.frames = Paths.getSparrowAtlas('menus/mainmenu/lightRays');
    lightRays2.animation.addByPrefix("idle", 'LightRays', 8, true);
    lightRays2.animation.play("idle", true);
    lightRays2.scale.set(1.5,1.5);
    lightRays2.antialiasing = true;
    lightRays2.setPosition(-106,-160);
    middle.add(lightRays2);
    lightRays2.scrollFactor.set(1, 0);


    if (blackFade != null) {
        remove(blackFade, true);
        blackFade.destroy();
        blackFade = null;
    }
    blackFade = new FlxSprite(-6,484, Paths.image('menus/mainmenu/blackFade'));
    add(blackFade);
    blackFade.scrollFactor.set(0,1);
    blackFade.scale.set(4.0,1.3); // Mucho más ancho

    if (fullBlack != null) {
        remove(fullBlack, true);
        fullBlack.destroy();
        fullBlack = null;
    }

    fullBlack = new FlxSprite(-6,1841, Paths.image('menus/mainmenu/fullBlack'));
    add(fullBlack);
    fullBlack.scrollFactor.set(0,1);
    fullBlack.scale.set(4.0,2); // Mucho más ancho
}

function addRightShit(){
    
    if (right == null) {
        trace('[ERROR] El grupo right es null');
        return;
    }
    
    // Limpiar el grupo right si ya tiene elementos
    right.forEach(function(spr) {
        right.remove(spr, true);
        spr.destroy();
    });
    
    // Limpiar elementos existentes del grupo right si existen
    if (right != null) {
        right.forEach(function(sprite) {
            right.remove(sprite, true);
            sprite.destroy();
        });
    }

    // right1 se agrega al grupo right (que ahora se renderiza ANTES de middle)
    this.right1 = new FlxSprite(-366,-467, Paths.image('menus/mainmenu/right1'));
    this.right1.scale.set(2,2);
    right.add(this.right1);
    this.right1.scrollFactor.set(0, 0); // Completamente fijo en pantalla

    this.right3 = new FlxSprite(2769, -97, Paths.image('menus/mainmenu/right3'));
    this.right3.scale.set(2,2);
    right.add(this.right3);
    this.right3.scrollFactor.set(0.4,0.1);

    this.right4 = new FlxSprite(2317,223, Paths.image('menus/mainmenu/right4'));
    this.right4.scale.set(2,2);
    right.add(this.right4);
    this.right4.scrollFactor.set(0.6,0.3);

    this.right2 = new FlxSprite(3811,228, Paths.image('menus/mainmenu/right2'));
    this.right2.scale.set(2,2);
    right.add(this.right2);
    this.right2.scrollFactor.set(0.6,0.3);

    var right5 = new FlxSprite();
    right5.frames = Paths.getSparrowAtlas('menus/mainmenu/right5');
    right5.animation.addByPrefix("idle", 'layer5', 6, true);
    right5.animation.play("idle", true);
    right5.scrollFactor.set(1, 1);
    right5.scale.set(1,1);
    right5.antialiasing = true;
    right5.setPosition(4620,610);
    right.add(right5);

    right6 = new FlxSprite(5353,503, Paths.image('menus/mainmenu/right6'));
    right6.scale.set(2,2);
    right.add(right6);

    jan = new FlxSprite(5603,536, Paths.image('menus/mainmenu/jan'));
    jan.scrollFactor.set(1, 1);
    jan.scale.set(1,1);
    jan.antialiasing = true;
    add(jan);

    num1 = new FlxSprite();
    num1.frames = Paths.getSparrowAtlas('menus/mainmenu/num1');
    num1.scrollFactor.set(1, 1);
    num1.scale.set(1,1);
    num1.antialiasing = true;
    num1.setPosition(5210,541);
    right.add(num1);

    num2 = new FlxSprite();
    num2.frames = Paths.getSparrowAtlas('menus/mainmenu/num2');
    num2.scrollFactor.set(1, 1);
    num2.scale.set(1,1);
    num2.antialiasing = true;
    num2.setPosition(5287,524);
    right.add(num2);

    num3 = new FlxSprite();
    num3.frames = Paths.getSparrowAtlas('menus/mainmenu/num3');
    num3.scrollFactor.set(1, 1);
    num3.scale.set(1,1);
    num3.antialiasing = true;
    num3.setPosition(5416,506);
    right.add(num3);

    num4 = new FlxSprite();
    num4.frames = Paths.getSparrowAtlas('menus/mainmenu/num4');
    num4.scrollFactor.set(1, 1);
    num4.scale.set(1,1);
    num4.antialiasing = true;
    num4.setPosition(5507,490);
    right.add(num4);

    num5 = new FlxSprite();
    num5.frames = Paths.getSparrowAtlas('menus/mainmenu/num5');
    num5.scrollFactor.set(1, 1);
    num5.scale.set(1,1);
    num5.antialiasing = true;
    num5.setPosition(5655,473);
    right.add(num5);

    num6 = new FlxSprite();
    num6.frames = Paths.getSparrowAtlas('menus/mainmenu/num6');
    num6.scrollFactor.set(1, 1);
    num6.scale.set(1,1);
    num6.antialiasing = true;
    num6.setPosition(5618,479);
    right.add(num6);

    for (i in 0...10) {
        num1.animation.addByPrefix(Std.string(i), i+'first', 24, true);
        num2.animation.addByPrefix(Std.string(i), i+'second', 24, true);
        num3.animation.addByPrefix(Std.string(i), i+'third', 24, true);
        num4.animation.addByPrefix(Std.string(i), i+'fourth', 24, true);
        num5.animation.addByPrefix(Std.string(i), i+'fith', 24, true);
        num6.animation.addByPrefix(Std.string(i), i+'sixth', 24, true);
    }

    num1.animation.play("8", true);
    num2.animation.play("8", true);
    num3.animation.play("8", true);
    num4.animation.play("8", true);
    num5.animation.play("8", true);
    num6.animation.play("8", true);

    clockTick = new FlxSprite();
    clockTick.frames = Paths.getSparrowAtlas('menus/mainmenu/clockTick');
    clockTick.animation.addByPrefix("idle", 'clockTick', 24, true);
    clockTick.animation.addByPrefix("tick", 'clockTick', 24, true);
    clockTick.animation.play("idle", true);
    clockTick.scrollFactor.set(1, 1);
    clockTick.scale.set(1,1);
    clockTick.antialiasing = true;
    clockTick.setPosition(5389,582);
    right.add(clockTick);

    right6dark = new FlxSprite(5753,603, Paths.image('menus/mainmenu/right6dark'));
    right6dark.scale.set(2,2);
    right6dark.blend = MULTIPLY;
    right.add(right6dark);

    right6light = new FlxSprite(5370,591, Paths.image('menus/mainmenu/right6light'));
    right6light.scale.set(2,2);
    right6light.blend = NORMAL;
    right.add(right6light);

    var rightRays = new FlxSprite();
    rightRays.frames = Paths.getSparrowAtlas('menus/mainmenu/rightLightRays');
    rightRays.animation.addByPrefix("idle", 'right2', 12, true);
    rightRays.animation.play("idle", true);
    rightRays.scrollFactor.set(0.6, 1);
    rightRays.scale.set(1.2,1.2);
    rightRays.antialiasing = true;
    rightRays.setPosition(4620,-280);
    right.add(rightRays);

    var rightRays2 = new FlxSprite();
    rightRays2.frames = Paths.getSparrowAtlas('menus/mainmenu/rightLightRays');
    rightRays2.animation.addByPrefix("idle", 'right2', 12, true);
    rightRays2.animation.play("idle", true);
    rightRays2.scrollFactor.set(0.6, 1);
    rightRays2.scale.set(1.2,1.4);
    rightRays2.antialiasing = true;
    rightRays2.setPosition(4620, -280);
    right.add(rightRays2);
    rightRays2.alpha = 0.4;

    if (showAssetNames && zoomActive) {
        createAssetLabels();
    }
}

function playBubbleAnimation(){
    var bubbles = new FlxSprite();
    bubbles.frames = Paths.getSparrowAtlas('menus/mainmenu/bubbles');
    bubbles.animation.addByPrefix("idle", 'Symbol 29', 24, false);
    bubbles.animation.play("idle", true);
    bubbles.scrollFactor.set(1, 1);
    bubbles.scale.set(0.7,0.7);
    bubbles.antialiasing = true;
    bubbles.setPosition(94,-150);
    bubbles.alpha = 0.8;
    add(bubbles);
    FlxTween.tween(bubbles,  {alpha: 0.2}, 15.0, {ease: FlxEase.sineInOut});

    var bubbles2 = new FlxSprite();
    bubbles2.frames = Paths.getSparrowAtlas('menus/mainmenu/bubbles');
    bubbles2.animation.addByPrefix("idle", 'Symbol 29', 24, false);
    bubbles2.animation.play("idle", true);
    bubbles2.scrollFactor.set(1, 1);
    bubbles2.scale.set(0.9,0.9);
    bubbles2.antialiasing = true;
    bubbles2.setPosition(1414,-350);


    bubbles2.alpha = 0.8;
    add(bubbles2);
    FlxTween.tween(bubbles2,  {alpha: 0.2}, 15.0, {ease: FlxEase.sineInOut});

    new FlxTimer().start(4, function(tmr2){
        bubbles.alpha = 0;
        bubbles2.alpha = 0;
        bubbles.x = 2000;
        bubbles2.x = 2000;
        bubbles.destroy();
        bubbles2.destroy();
        tmr2.destroy();
    });
}

// --- AndroidPlayer's SUPERIOR Shader System ---
function addShaderShit(){
    // Verificar configuración de shaders desde gameData.ini
    var gameConfig = GameConfig.getInstance();
    var shadersEnabledConfig = gameConfig.getBool("menu", "shadersenabled", true);
    
    // Si shaders están deshabilitados en el INI, no cargar nada
    if (!shadersEnabledConfig) {
        trace('[SHADER] Shaders deshabilitados en gameData.ini (shadersEnabled = false)');
        return;
    }
    
    // Verificar si los shaders están completamente deshabilitados
    if (!ClientPrefs.data.shaders) {
        trace('[SHADER] Shaders completamente deshabilitados');
        return;
    }
    
    // Verificar si los shaders del menú están deshabilitados
    if (ClientPrefs.data.menuShaders) {
        trace('[SHADER] Menu shaders deshabilitados (menuShaders = ON)');
        return;
    }
    
    trace('[SHADER] ✓ Condiciones cumplidas - Cargando shaders...');
    trace('[SHADER] - shaders: ' + ClientPrefs.data.shaders + ' (debe ser true)');
    trace('[SHADER] - menuShaders: ' + ClientPrefs.data.menuShaders + ' (debe ser false)');

    #if (!flash && sys)
    try {
        trace('[SHADER] Cargando shaders usando Paths.getShader()...');
        
        // Array para trackear qué shaders se cargaron
        var loadedShaders:Array<String> = [];
        
        // Cargar shaders usando carga directa de archivos
        try {
            trace('[SHADER] Intentando cargar waves...');
            var wavesPath = 'assets/shaders/waves.frag';
            trace('[SHADER] Buscando waves en: ' + wavesPath);
            
            #if sys
            if (sys.FileSystem.exists(wavesPath)) {
                var wavesFrag = sys.io.File.getContent(wavesPath);
                trace('[SHADER] Resultado waves: ' + (wavesFrag != null ? 'Contenido cargado (' + wavesFrag.length + ' chars)' : 'NULL'));
                if (wavesFrag != null && wavesFrag.length > 0) {
                    water = new flixel.addons.display.FlxRuntimeShader(wavesFrag);
                    loadedShaders.push("waves");
                    trace('[SHADER] ✓ waves cargado correctamente desde: ' + wavesPath);
                } else {
                    trace('[SHADER] ✗ waves archivo vacío');
                }
            } else {
                trace('[SHADER] ✗ waves archivo no existe en: ' + wavesPath);
            }
            #end
        } catch (e:Dynamic) {
            trace('[SHADER] ✗ Error cargando waves: ' + e);
        }
        
        try {
            var lensPath = 'assets/shaders/lens.frag';
            trace('[SHADER] Buscando lens en: ' + lensPath);
            
            #if sys
            if (sys.FileSystem.exists(lensPath)) {
                var lensFrag = sys.io.File.getContent(lensPath);
                if (lensFrag != null && lensFrag.length > 0) {
                    lens = new flixel.addons.display.FlxRuntimeShader(lensFrag);
                    loadedShaders.push("lens");
                    trace('[SHADER] ✓ lens cargado correctamente desde: ' + lensPath);
                } else {
                    trace('[SHADER] ✗ lens archivo vacío');
                }
            } else {
                trace('[SHADER] ✗ lens archivo no existe en: ' + lensPath);
            }
            #end
        } catch (e:Dynamic) {
            trace('[SHADER] ✗ Error cargando lens: ' + e);
        }
        
        try {
            var blurPath = 'assets/shaders/blur.frag';
            trace('[SHADER] Buscando blur en: ' + blurPath);
            
            #if sys
            if (sys.FileSystem.exists(blurPath)) {
                var blurFrag = sys.io.File.getContent(blurPath);
                if (blurFrag != null && blurFrag.length > 0) {
                    blur = new flixel.addons.display.FlxRuntimeShader(blurFrag);
                    loadedShaders.push("blur");
                    trace('[SHADER] ✓ blur cargado correctamente desde: ' + blurPath);
                } else {
                    trace('[SHADER] ✗ blur archivo vacío');
                }
            } else {
                trace('[SHADER] ✗ blur archivo no existe en: ' + blurPath);
            }
            #end
        } catch (e:Dynamic) {
            trace('[SHADER] ✗ Error cargando blur: ' + e);
        }

        // Aplicar filtros solo si hay shaders válidos
        if (loadedShaders.length > 0) {
            var filters:Array<openfl.filters.BitmapFilter> = [];
            
            if (water != null) filters.push(new ShaderFilter(water));
            if (lens != null) filters.push(new ShaderFilter(lens));
            if (blur != null) filters.push(new ShaderFilter(blur));
            
            FlxG.camera.setFilters(filters);
            trace('[SHADER] ✓ Aplicados ' + filters.length + ' filtros de shader: [' + loadedShaders.join(", ") + ']');
            
            // Inicializar valores de shader usando tu método original
            try {
                if (water != null) {
                    water.setFloat('iTime', 0.0);
                    trace('[SHADER] ✓ water iTime inicializado');
                }
                if (blur != null) {
                    blur.setFloat('iTime', 0.0);
                    trace('[SHADER] ✓ blur iTime inicializado');
                }
                if (lens != null) {
                    lens.setFloat('iTime', 0.0);
                    lens.setFloat('ushaderStrength', 0.0);
                    trace('[SHADER] ✓ lens iTime y ushaderStrength inicializados');
                }
                
                blurAngle = 90.0;
                trace('[SHADER] ✓ Todos los valores iniciales configurados');
                
            } catch (e:Dynamic) {
                trace('[SHADER] ⚠️ Error configurando valores iniciales: ' + e);
                // Intentar método alternativo con .data si setFloat falla
                try {
                    if (water != null) water.data.iTime.value = [0.0];
                    if (blur != null) blur.data.iTime.value = [0.0];
                    if (lens != null) {
                        lens.data.iTime.value = [0.0];
                        lens.data.ushaderStrength.value = [0.0];
                    }
                    trace('[SHADER] ✓ Valores configurados usando método alternativo .data');
                } catch (e2:Dynamic) {
                    trace('[SHADER] ✗ Error con ambos métodos de configuración: ' + e2);
                }
            }
            
        } else {
            trace('[SHADER] ⚠️ No se cargó ningún shader válido');
            FlxG.camera.setFilters([]);
        }
        
    } catch (e:Dynamic) {
        trace('[SHADER] ✗ Error crítico cargando shaders: ' + e);
        FlxG.camera.setFilters([]);
        
        // Deshabilitar shaders automáticamente si hay error crítico
        ClientPrefs.data.shaders = false;
        ClientPrefs.saveSettings();
        trace('[SHADER] Shaders deshabilitados automáticamente debido al error');
    }
    #else
    trace('[SHADER] Plataforma no compatible con shaders');
    #end
}

// Función auxiliar para inicializar shaders individuales
private function initShader(shaderName:String):Bool {
    #if (!flash && sys)
    if(runtimeShaders.exists(shaderName)) {
        return true;
    }

    var shaderPath = 'assets/shaders/';
    var frag:String = shaderPath + shaderName + '.frag';
    var vert:String = shaderPath + shaderName + '.vert';
    
    var fragContent:String = null;
    var vertContent:String = null;
    var found:Bool = false;

    #if MODS_ALLOWED
    if(sys.FileSystem.exists(frag)) {
        fragContent = sys.io.File.getContent(frag);
        found = true;
    }
    if(sys.FileSystem.exists(vert)) {
        vertContent = sys.io.File.getContent(vert);
        found = true;
    }
    #end

    if(found) {
        runtimeShaders.set(shaderName, [fragContent, vertContent]);
        return true;
    }
    
    trace('[SHADER] Shader $shaderName no encontrado en: $shaderPath');
    return false;
    #else
    return false;
    #end
}

// Función auxiliar para crear runtime shaders
private function createRuntimeShader(shaderName:String):flixel.addons.display.FlxRuntimeShader {
    #if (!flash && sys)
    if(!runtimeShaders.exists(shaderName)) {
        return null;
    }
    
    var arr:Array<String> = runtimeShaders.get(shaderName);
    return new flixel.addons.display.FlxRuntimeShader(arr[0], arr[1]);
    #else
    return null;
    #end
}
}
