package states;

import backend.WeekData;

import flixel.input.keyboard.FlxKey;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFrame;
import flixel.group.FlxGroup;
import objects.VideoSprite;
import flixel.input.gamepad.FlxGamepad;
import flixel.text.FlxText;
import haxe.Json;

import openfl.Assets;
import openfl.display.Bitmap;
import openfl.display.BitmapData;

import shaders.ColorSwap;

import states.StoryMenuState;
import states.MainMenuState_oldmenu;

typedef TitleDataOldMenu =
{
	var titlex:Float;
	var titley:Float;
	var startx:Float;
	var starty:Float;
	var gfx:Float;
	var gfy:Float;
	var backgroundSprite:String;
	var bpm:Float;
	
	@:optional var animation:String;
	@:optional var dance_left:Array<Int>;
	@:optional var dance_right:Array<Int>;
	@:optional var idle:Bool;
}

class TitleState_oldmenu extends MusicBeatState
{
	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];

	public static var initialized:Bool = false;

	var credGroup:FlxGroup = new FlxGroup();
	var textGroup:FlxGroup = new FlxGroup();
	var blackScreen:FlxSprite;
	var credTextShit:Alphabet;
	var ngSpr:FlxSprite;
	
	var titleTextColors:Array<FlxColor> = [0xFF33FFFF, 0xFF3333CC];
	var titleTextAlphas:Array<Float> = [1, .64];

	var curWacky:Array<String> = [];

	var wackyImage:FlxSprite;

	// Developer mode variables
	var devMode:Bool = false;
	var devText:FlxText;
	var devIndex:Int = 0;
	var devObjects:Array<FlxSprite> = [];
	var devNames:Array<String> = [];
	var devObjectsOriginalVisible:Array<Bool> = []; // Para recordar visibilidad original

	#if TITLE_SCREEN_EASTER_EGG
	final easterEggKeys:Array<String> = [
		'SHADOW', 'RIVEREN', 'BBPANZU', 'PESSY'
	];
	final allowedKeys:String = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
	var easterEggKeysBuffer:String = '';
	#end

	override public function create():Void
	{
		Paths.clearStoredMemory();
		super.create();
		Paths.clearUnusedMemory();

		if(!initialized)
		{
			ClientPrefs.loadPrefs();
			Language.reloadPhrases();
		}

		curWacky = FlxG.random.getObject(getIntroTextShit());

		if(!initialized)
		{
			if(FlxG.save.data != null && FlxG.save.data.fullscreen)
			{
				FlxG.fullscreen = FlxG.save.data.fullscreen;
				//trace('LOADED FULLSCREEN SETTING!!');
			}
			persistentUpdate = true;
			persistentDraw = true;
		}

		if (FlxG.save.data.weekCompleted != null)
		{
			StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;
		}

		FlxG.mouse.visible = false;
		#if FREEPLAY
		MusicBeatState.switchState(new FreeplayState());
		#elseif CHARTING
		MusicBeatState.switchState(new ChartingState());
		#else
		if(FlxG.save.data.flashing == null && !FlashingState.leftState)
		{
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			MusicBeatState.switchState(new FlashingState());
		}
		else
			startIntro();
		#end
	}

	var logoBl:FlxSprite;
	var gfDance:FlxSprite;
	var danceLeft:Bool = false;
	var titleText:FlxSprite;
	var swagShader:ColorSwap = null;
	var menuBlack:FlxSprite;
	var menuWater:FlxSprite;
	var memWter:FlxSprite;
	var menuArtEyes:FlxSprite;
	var menuArtEyesTimer:FlxTimer;
	var json_menuArtEyesBlink:Dynamic = true;
	var menuArtEyesBlinkStarted:Bool = false;
	var menuArtEyesTargetAlpha:Float = 1.0;
	var waterVideo:VideoSprite;

	function startIntro()
	{
		persistentUpdate = true;
		// Al volver desde MainMenuState_oldmenu puede seguir sonando menusongold1.
		// El titulo siempre debe recuperar su propia musica, incluso cuando ya fue
		// inicializado y se salta directamente la intro.
		if (FlxG.sound.music != null)
		{
			FlxTween.cancelTweensOf(FlxG.sound.music);
			FlxG.sound.music.stop();
		}
		FlxG.sound.playMusic(Paths.music('menusongold'), initialized ? 0.7 : 0);

		loadJsonData();
		#if TITLE_SCREEN_EASTER_EGG easterEggData(); #end
		Conductor.bpm = musicBPM;

	// MenuC background assets con coordenadas del JSON
	menuBlack = new FlxSprite(0, 0).loadGraphic(Paths.image('menus/title/old/menuBlack'));
	menuBlack.antialiasing = ClientPrefs.data.antialiasing;
	if (json_menuBlackScale != null) menuBlack.scale.set(json_menuBlackScale, json_menuBlackScale);
	if (json_menuBlackAlpha != null) {
		var mba:Float = json_menuBlackAlpha;
		if (mba > 1) mba = mba / 100;
		menuBlack.alpha = mba;
	}
	menuBlack.updateHitbox();
	if (json_menuBlackX != null && json_menuBlackY != null) {
		menuBlack.x = json_menuBlackX;
		menuBlack.y = json_menuBlackY;
	} else {
		menuBlack.screenCenter();
	}

	menuWater = new FlxSprite(0, 0).loadGraphic(Paths.image('menus/title/old/menuWater'));
	menuWater.antialiasing = ClientPrefs.data.antialiasing;
	if (json_menuWaterScale != null) menuWater.scale.set(json_menuWaterScale, json_menuWaterScale);
	if (json_menuWaterAlpha != null) {
		var mwa:Float = json_menuWaterAlpha;
		if (mwa > 1) mwa = mwa / 100;
		menuWater.alpha = mwa;
	}
	menuWater.updateHitbox();
	if (json_menuWaterX != null && json_menuWaterY != null) {
		menuWater.x = json_menuWaterX;
		menuWater.y = json_menuWaterY;
	} else {
		menuWater.screenCenter(X);
		menuWater.y = FlxG.height * 0.55;
	}

	memWter = new FlxSprite(0, 0).loadGraphic(Paths.image('menus/title/old/MemWter'));
	memWter.antialiasing = ClientPrefs.data.antialiasing;
	if (json_memWterScale != null) memWter.scale.set(json_memWterScale, json_memWterScale);
	if (json_memWterAlpha != null) {
		var mwa2:Float = json_memWterAlpha;
		if (mwa2 > 1) mwa2 = mwa2 / 100;
		memWter.alpha = mwa2;
	}
	memWter.updateHitbox();
	if (json_memWterX != null && json_memWterY != null) {
		memWter.x = json_memWterX;
		memWter.y = json_memWterY;
	} else {
		memWter.screenCenter(X);
		memWter.y = FlxG.height * 0.65;
	}

	menuArtEyes = new FlxSprite(0, 0).loadGraphic(Paths.image('menus/title/old/menuArtEyes'));
	menuArtEyes.antialiasing = ClientPrefs.data.antialiasing;
	menuArtEyes.updateHitbox();
	
	// Apply JSON position/scale
	if (json_menuArtEyesX != null && json_menuArtEyesY != null) {
		menuArtEyes.x = json_menuArtEyesX;
		menuArtEyes.y = json_menuArtEyesY;
	} else {
		menuArtEyes.screenCenter(X);
	}
	if (json_menuArtEyesScale != null) menuArtEyes.scale.set(json_menuArtEyesScale, json_menuArtEyesScale);
	
	// Determine target alpha (we'll fade from 0 to this value)
	if (json_menuArtEyesAlpha != null) {
		var maeA:Float = json_menuArtEyesAlpha;
		if (maeA > 1) maeA = maeA / 100;
		menuArtEyesTargetAlpha = maeA;
	} else {
		menuArtEyesTargetAlpha = 1;
	}
	
	// Start fully transparent; we'll fade in when appropriate
	menuArtEyes.alpha = 0;
	menuArtEyes.visible = true;
	
	// DON'T start blinking here - wait until skipIntro() is called

	// Try to load water video con coordenadas del JSON (sistema global de tu amigo)
		#if VIDEOS_ALLOWED
		var videoPath:String = Paths.video('water');
		waterVideo = new VideoSprite(videoPath, true, false, true);
		if (waterVideo.videoSprite != null && waterVideo.videoSprite.bitmap != null)
		{
			waterVideo.videoSprite.bitmap.play();
			// Posicionar detrás de menuWater
			// Si hay posición guardada en JSON, aplicarla moviendo bitmap y container
			/*
			if (waterVideo.videoSprite != null) {
				var vbmp = if (waterVideo != null && waterVideo.videoSprite != null) waterVideo.videoSprite.bitmap else null;
				// Offset visual predeterminado relativo a menuWater
				var defaultY:Float = menuWater.y - 40;
				if (vbmp != null) {
					// Si JSON tiene coordenadas bitmap-local Y container, restaurarlas exactamente
					if (json_waterBitmapX != null && json_waterBitmapY != null && json_waterContainerX != null && json_waterContainerY != null) {
						try {
							vbmp.x = cast(json_waterBitmapX, Float);
							vbmp.y = cast(json_waterBitmapY, Float);
							if (waterVideo != null) {
								waterVideo.x = cast(json_waterContainerX, Float);
								waterVideo.y = cast(json_waterContainerY, Float);
							}
						} catch(e:Dynamic) {
							// Fallback a restauración basada en coordenadas world
							var desiredX_f:Float = (json_waterX != null ? cast(json_waterX, Float) : (vbmp.x + waterVideo.x));
							var desiredY_f:Float = (json_waterY != null ? cast(json_waterY, Float) : (vbmp.y + waterVideo.y));
							if (waterVideo != null) {
								waterVideo.x = desiredX_f - vbmp.x;
								waterVideo.y = desiredY_f - vbmp.y;
							}
						}
					}
					// Si tenemos posición world guardada, aplicar moviendo el container
					else if (json_waterX != null || json_waterY != null) {
						var desiredX:Float = (json_waterX != null ? cast(json_waterX, Float) : (vbmp.x + waterVideo.x));
						var desiredY:Float = (json_waterY != null ? cast(json_waterY, Float) : (vbmp.y + waterVideo.y));
						if (waterVideo != null) {
							waterVideo.x = desiredX - vbmp.x;
							waterVideo.y = desiredY - vbmp.y;
						}
					}
					else {
						// Sin coordenadas guardadas: aplicar offset visual predeterminado O coordenadas JSON
						if (json_waterX != null && json_waterY != null) {
							// Aplicar coordenadas directamente del JSON
							waterVideo.x = cast(json_waterX, Float);
							waterVideo.y = cast(json_waterY, Float);
							trace('[DEV] Applied JSON coordinates directly: X=' + waterVideo.x + ' Y=' + waterVideo.y);
						} else {
							vbmp.y = defaultY;
						}
					}
				} else {
					// Fallback: si no hay bitmap, aplicar posicionamiento de container (solo si JSON lo tiene)
					if (json_waterX != null) waterVideo.x = cast(json_waterX, Float);
					if (json_waterY != null) waterVideo.y = cast(json_waterY, Float);
					else if (waterVideo.videoSprite != null) waterVideo.videoSprite.y = defaultY;
				}
			}
			*/
			if (json_waterScale != null) {
				waterVideo.scale.set(json_waterScale, json_waterScale);
				if (waterVideo.videoSprite != null) waterVideo.videoSprite.scale.set(json_waterScale, json_waterScale);
			}
			
			// POSICIONAMIENTO DIRECTO DEL JSON - FORZADO
			if (json_waterX != null && json_waterY != null) {
				trace('[DEBUG] json_waterX = ' + json_waterX + ', json_waterY = ' + json_waterY);
				waterVideo.x = cast(json_waterX, Float);
				waterVideo.y = cast(json_waterY, Float);
				trace('[DEV] Applied direct JSON position: X=' + waterVideo.x + ' Y=' + waterVideo.y);
				
				// FORZAR aplicación múltiples veces para combatir el screenCenter()
				for (i in 0...5) {
					new FlxTimer().start(0.1 + (i * 0.1), function(tmr:FlxTimer) {
						waterVideo.x = cast(json_waterX, Float);
						waterVideo.y = cast(json_waterY, Float);
						if (waterVideo.videoSprite != null) {
							waterVideo.videoSprite.x = cast(json_waterX, Float);
							waterVideo.videoSprite.y = cast(json_waterY, Float);
						}
						trace('[FORCE-' + i + '] Re-applied position: X=' + waterVideo.x + ' Y=' + waterVideo.y);
					});
				}
			} else {
				trace('[DEBUG] json_waterX or json_waterY is null: X=' + json_waterX + ', Y=' + json_waterY);
			}
	// NUEVA ESTRATEGIA: Video detrás + menuWater semi-transparente  
	// El video mantiene alpha completo, menuWater se vuelve transparente
	var videoAlpha:Float = 0.3; // Video 30% visible por defecto
	if (json_waterAlpha != null) {
		videoAlpha = json_waterAlpha;
		if (videoAlpha > 1) videoAlpha = videoAlpha / 100;
	}
	
	waterVideo.alpha = 0;
	new FlxTimer().start(1.0, function(tmr:FlxTimer) {
		FlxTween.tween(waterVideo, {alpha: videoAlpha}, 3.0);
	});
		
	// OCULTAR menuWater ya que el video estará detrás de MemWter
	menuWater.visible = false;
	menuWater.alpha = 0.9; // 90% opaco por defecto
	}
	#end	// Main artwork (gfDance replaced with menuArt) con coordenadas del JSON
	gfDance = new FlxSprite(0, 0).loadGraphic(Paths.image('menus/title/old/menuArt'));
	gfDance.antialiasing = ClientPrefs.data.antialiasing;
	if (json_gfScale != null) gfDance.scale.set(json_gfScale, json_gfScale);
	if (json_gfAlpha != null) {
		var gfa:Float = json_gfAlpha;
		if (gfa > 1) gfa = gfa / 100;
		gfDance.alpha = gfa;
	}
	gfDance.updateHitbox();
	gfDance.x = gfPosition.x;
	gfDance.y = gfPosition.y;

	// Logo (replaced with corruption logo) con coordenadas del JSON
	logoBl = new FlxSprite(0, 0).loadGraphic(Paths.image('menus/title/old/corruptionLogo'));
	logoBl.antialiasing = ClientPrefs.data.antialiasing;
	if (json_logoScale != null) logoBl.scale.set(json_logoScale, json_logoScale);
	if (json_logoAlpha != null) {
		var lga:Float = json_logoAlpha;
		if (lga > 1) lga = lga / 100;
		logoBl.alpha = lga;
	}
	logoBl.updateHitbox();
	logoBl.x = logoPosition.x;
	logoBl.y = logoPosition.y;
	
	if(ClientPrefs.data.shaders)
		{
			swagShader = new ColorSwap();
			gfDance.shader = swagShader.shader;
			logoBl.shader = swagShader.shader;
		}


	var animFrames:Array<FlxFrame> = [];
	titleText = new FlxSprite(0, 0);
	titleText.frames = Paths.getSparrowAtlas('titleEnter');
	@:privateAccess
	{
		titleText.animation.findByPrefix(animFrames, "ENTER IDLE");
		titleText.animation.findByPrefix(animFrames, "ENTER FREEZE");
	}
	
	if (newTitle = animFrames.length > 0)
	{
		titleText.animation.addByPrefix('idle', "ENTER IDLE", 24);
		titleText.animation.addByPrefix('press', ClientPrefs.data.flashing ? "ENTER PRESSED" : "ENTER FREEZE", 24);
	}
	else
	{
		titleText.animation.addByPrefix('idle', "Press Enter to Begin", 24);
		titleText.animation.addByPrefix('press', "ENTER PRESSED", 24);
	}
	titleText.animation.play('idle');
	if (json_titleScale != null) titleText.scale.set(json_titleScale, json_titleScale);
	else titleText.scale.set(0.48, 0.48);
	if (json_titleAlpha != null) {
		var tta:Float = json_titleAlpha;
		if (tta > 1) tta = tta / 100;
		titleText.alpha = tta;
	}
	titleText.updateHitbox();
	titleText.x = enterPosition.x;
	titleText.y = enterPosition.y;		blackScreen = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		blackScreen.scale.set(FlxG.width, FlxG.height);
		blackScreen.updateHitbox();
		credGroup.add(blackScreen);

		credTextShit = new Alphabet(0, 0, "", true);
		credTextShit.screenCenter();
		credTextShit.visible = false;

		ngSpr = new FlxSprite(0, FlxG.height * 0.52).loadGraphic(Paths.image('newgrounds_logo'));
		ngSpr.visible = false;
		ngSpr.setGraphicSize(Std.int(ngSpr.width * 0.8));
		ngSpr.updateHitbox();
		ngSpr.screenCenter(X);
		ngSpr.antialiasing = ClientPrefs.data.antialiasing;

		// Orden de capas correcto (de atrás hacia adelante):
		// 1. memWter (efecto agua de fondo)
		// 2. waterVideo (video encima del efecto agua)
		// 3. menuWater (oculto)
		// 4. gfDance (menuArt)
		// 5. menuArtEyes (encima de menuArt)
		// 6. menuBlack (detrás de logo y titleText)
		// 7. logoBl (corruptionLogo)
		// 8. titleText (Press Enter to Begin)
		
		add(memWter); // 1. Efecto agua de fondo
		#if VIDEOS_ALLOWED
		if (waterVideo != null)
			add(waterVideo); // 2. Video encima del efecto agua
		#end
		add(menuWater); // 3. Fallback oculto
		add(gfDance); // 4. MenuArt (personaje principal)
		add(menuArtEyes); // 5. Ojos encima de menuArt
		add(menuBlack); // 6. Detrás de logo y titleText
		add(logoBl); // 7. Logo de Corruption
		add(titleText); // 8. "Press Enter to Begin"
	add(credGroup);
	add(ngSpr);

	// Dev mode setup - incluir waterVideo si existe
	#if VIDEOS_ALLOWED
	if (waterVideo != null) {
		devObjects = [menuBlack, menuWater, memWter, waterVideo, menuArtEyes, gfDance, logoBl, titleText];
		devNames = ['menuBlack', 'menuWater', 'memWter', 'waterVideo', 'menuArtEyes', 'gfDance (menuArt)', 'logoBl (corruptionLogo)', 'titleText'];
	} else {
	#end
		devObjects = [menuBlack, menuWater, memWter, menuArtEyes, gfDance, logoBl, titleText];
		devNames = ['menuBlack', 'menuWater', 'memWter', 'menuArtEyes', 'gfDance (menuArt)', 'logoBl (corruptionLogo)', 'titleText'];
	#if VIDEOS_ALLOWED
	}
	#end
	
	// Guardar visibilidad original
	for (obj in devObjects) {
		devObjectsOriginalVisible.push(obj.visible);
	}
	
	devText = new FlxText(10, 10, 0, '', 16);
	devText.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
	devText.visible = false;
	add(devText);

	// Si hay coordenadas guardadas para el video (world, bitmap-local o container), reintentar aplicarlas después de que el bitmap esté listo
	// COMENTADO: Este sistema está sobrescribiendo las coordenadas que ya aplicamos arriba
	/*
	#if VIDEOS_ALLOWED
	if (waterVideo != null && (json_waterX != null || json_waterY != null || json_waterBitmapX != null || json_waterBitmapY != null || json_waterContainerX != null || json_waterContainerY != null))
	{
		var attempts:Int = 0;
		var t:FlxTimer = new FlxTimer();
		function applyPos(tm:FlxTimer):Void
		{
			attempts++;
			var vbmp = if (waterVideo != null && waterVideo.videoSprite != null) waterVideo.videoSprite.bitmap else null;
			if (vbmp != null)
			{
			// Aplicar opacidad cuando el bitmap esté listo
			var alphaVal:Float = 0.3; // Default 30% para video
			if (json_waterAlpha != null) {
				alphaVal = json_waterAlpha;
				if (alphaVal > 1) alphaVal = alphaVal / 100;
			}
			
			// Apply to videoSprite, bitmap, AND FlxVideo wrapper
			waterVideo.videoSprite.alpha = alphaVal; // ← NUEVO
			vbmp.alpha = alphaVal;
			waterVideo.alpha = alphaVal;
			trace('[DEV APPLY] Applied water alpha: ' + alphaVal);				// Si hay coordenadas bitmap-local + container explícitas guardadas, aplicarlas exactamente
				if (json_waterBitmapX != null && json_waterBitmapY != null && json_waterContainerX != null && json_waterContainerY != null) {
						try {
							vbmp.x = cast(json_waterBitmapX, Float);
							vbmp.y = cast(json_waterBitmapY, Float);
							if (waterVideo != null) {
								waterVideo.x = cast(json_waterContainerX, Float);
								waterVideo.y = cast(json_waterContainerY, Float);
							}
							trace('[DEV APPLY] Applied saved water bitmap+container coords: ' + Std.string(vbmp.x) + ',' + Std.string(vbmp.y) + ' | ' + Std.string(waterVideo.x) + ',' + Std.string(waterVideo.y));
						} catch(e:Dynamic) {
							trace('[DEV APPLY] Failed to apply bitmap+container coords due to type error');
						}
					}
					else {
						var desiredX:Float = (json_waterX != null ? cast(json_waterX, Float) : (vbmp.x + waterVideo.x));
						var desiredY:Float = (json_waterY != null ? cast(json_waterY, Float) : (vbmp.y + waterVideo.y));
						// Configurar container para que bitmap.world == desired
						waterVideo.x = desiredX - vbmp.x;
						waterVideo.y = desiredY - vbmp.y;
						trace('[DEV APPLY] Applied saved water world coords to container: ' + Std.string(waterVideo.x) + ',' + Std.string(waterVideo.y));
					}
					return; // done
				}
				else if (attempts < 12)
				{
					// retry shortly
					tm.start(0.05, applyPos);
				}
				else
				{
					trace('[DEV APPLY] Failed to apply saved water position: bitmap not ready after retries');
				}
			}
			// start shortly after creation so onFormatSetup can run first
			t.start(0.05, applyPos);
		}
		// Si NO hay coordenadas guardadas, igual aplicar opacidad cuando el video esté listo
		else if (waterVideo != null)
		{
			var attempts:Int = 0;
			var t:FlxTimer = new FlxTimer();
			function applyAlpha(tm:FlxTimer):Void
			{
				attempts++;
				var vbmp = if (waterVideo != null && waterVideo.videoSprite != null) waterVideo.videoSprite.bitmap else null;
				if (vbmp != null)
				{
					// Aplicar opacidad cuando el bitmap esté listo
					var alphaVal:Float = 0.3; // Default 30% para video
					if (json_waterAlpha != null) {
						alphaVal = json_waterAlpha;
						if (alphaVal > 1) alphaVal = alphaVal / 100;
					}
					vbmp.alpha = alphaVal;
					waterVideo.alpha = alphaVal;
					waterVideo.videoSprite.alpha = alphaVal; // ← NUEVO: aplicar al sprite también
					trace('[DEV APPLY] Applied water alpha (no coords): ' + alphaVal);
					return; // done
				}
				else if (attempts < 12)
				{
					// retry shortly
					tm.start(0.05, applyAlpha);
				}
				else
				{
					trace('[DEV APPLY] Failed to apply water alpha: bitmap not ready after retries');
				}
			}
			// start shortly after creation
			t.start(0.05, applyAlpha);
		}
		*/

		// Restaurar orden de capas guardado si está disponible - DESHABILITADO
		// COMENTADO: Este sistema está sobrescribiendo nuestro orden manual de capas
		/*
		var members:Array<Dynamic> = FlxG.state.members;
		function moveToLayer(obj:Dynamic, idx:Dynamic) {
			if (obj == null || idx == null) return;
			var target:Int = Std.int(idx);
			if (target < 0) return;
			if (members == null) return;
			// remover ocurrencia actual e insertar en índice deseado
			if (members.indexOf(obj) >= 0) members.remove(obj);
			var insertAt:Int = Std.int(Math.min(members.length, Math.max(0, target)));
			members.insert(insertAt, obj);
		}
		// Aplicar capas guardadas (menuBlack, waterVideo, memWter, menuArtEyes)
		moveToLayer(menuBlack, json_menuBlackLayer);
		#if VIDEOS_ALLOWED
		moveToLayer(waterVideo, json_waterLayer);
		#end
		moveToLayer(memWter, json_memWterLayer);
		moveToLayer(menuArtEyes, json_menuArtEyesLayer);
		*/

		// This title is reached from the menu selector as a return screen, not
		// as a boot splash. Always reveal it immediately instead of leaving the
		// intro's black layer up until the player presses Enter.
		initialized = true;
		skipIntro();

		// credGroup.add(credTextShit);
	}

	// JSON data
	var characterImage:String = 'Menuoldcords';
	var animationName:String = 'gfDance';

	var gfPosition:FlxPoint = FlxPoint.get(512, 40);
	var logoPosition:FlxPoint = FlxPoint.get(-150, -100);
	var enterPosition:FlxPoint = FlxPoint.get(100, 576);
	
	// Optional JSON overrides for positions/scales/alpha
	var json_menuBlackX:Dynamic = null;
	var json_menuBlackY:Dynamic = null;
	var json_menuBlackScale:Dynamic = null;
	var json_menuBlackAlpha:Dynamic = null;
	var json_menuBlackLayer:Dynamic = null;

	var json_menuWaterX:Dynamic = null;
	var json_menuWaterY:Dynamic = null;
	var json_menuWaterScale:Dynamic = null;
	var json_menuWaterAlpha:Dynamic = null;

	var json_memWterX:Dynamic = null;
	var json_memWterY:Dynamic = null;
	var json_memWterScale:Dynamic = null;
	var json_memWterAlpha:Dynamic = null;
	var json_memWterLayer:Dynamic = null;

	var json_menuArtEyesX:Dynamic = null;
	var json_menuArtEyesY:Dynamic = null;
	var json_menuArtEyesScale:Dynamic = null;
	var json_menuArtEyesAlpha:Dynamic = null;
	var json_menuArtEyesLayer:Dynamic = null;

	var json_gfScale:Dynamic = null;
	var json_gfAlpha:Dynamic = null;
	
	var json_logoScale:Dynamic = null;
	var json_logoAlpha:Dynamic = null;
	
	var json_titleScale:Dynamic = null;
	var json_titleAlpha:Dynamic = null;

	var json_waterX:Dynamic = null;
	var json_waterY:Dynamic = null;
	var json_waterScale:Dynamic = null;
	var json_waterAlpha:Dynamic = null;
	var json_waterBitmapX:Dynamic = null;
	var json_waterBitmapY:Dynamic = null;
	var json_waterContainerX:Dynamic = null;
	var json_waterContainerY:Dynamic = null;
	var json_waterLayer:Dynamic = null;
	
	var useIdle:Bool = false;
	var musicBPM:Float = 102;
	var danceLeftFrames:Array<Int> = [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29];
	var danceRightFrames:Array<Int> = [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14];

	function loadJsonData()
	{
		trace('[JSON] Intentando cargar images/Menuoldcords.json...');
		if(Paths.fileExists('images/Menuoldcords.json', TEXT))
		{
			trace('[JSON] Archivo encontrado!');
			var titleRaw:String = Paths.getTextFromFile('images/Menuoldcords.json');
			trace('[JSON] Contenido raw: ' + titleRaw);
			if(titleRaw != null && titleRaw.length > 0)
			{
				try
				{
					var titleJSON:TitleDataOldMenu = tjson.TJSON.parse(titleRaw);
					trace('[JSON] Parseado exitoso!');
					gfPosition.set(titleJSON.gfx, titleJSON.gfy);
					logoPosition.set(titleJSON.titlex, titleJSON.titley);
					enterPosition.set(titleJSON.startx, titleJSON.starty);
					musicBPM = titleJSON.bpm;
					trace('[JSON] gfPosition: ' + titleJSON.gfx + ', ' + titleJSON.gfy);
					trace('[JSON] logoPosition: ' + titleJSON.titlex + ', ' + titleJSON.titley);
					trace('[JSON] enterPosition: ' + titleJSON.startx + ', ' + titleJSON.starty);
					
					if(titleJSON.animation != null && titleJSON.animation.length > 0) animationName = titleJSON.animation;
					if(titleJSON.dance_left != null && titleJSON.dance_left.length > 0) danceLeftFrames = titleJSON.dance_left;
					if(titleJSON.dance_right != null && titleJSON.dance_right.length > 0) danceRightFrames = titleJSON.dance_right;
					useIdle = (titleJSON.idle == true);
	
					if (titleJSON.backgroundSprite != null && titleJSON.backgroundSprite.trim().length > 0)
					{
						var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image(titleJSON.backgroundSprite));
						bg.antialiasing = ClientPrefs.data.antialiasing;
						add(bg);
					}

					// Load JSON overrides for MenuC assets
					var jsonData:Dynamic = titleJSON;
					if (Reflect.hasField(jsonData, 'menuBlackX')) json_menuBlackX = Reflect.field(jsonData, 'menuBlackX');
					if (Reflect.hasField(jsonData, 'menuBlackY')) json_menuBlackY = Reflect.field(jsonData, 'menuBlackY');
					if (Reflect.hasField(jsonData, 'menuBlackScale')) json_menuBlackScale = Reflect.field(jsonData, 'menuBlackScale');
					if (Reflect.hasField(jsonData, 'menuBlackAlpha')) json_menuBlackAlpha = Reflect.field(jsonData, 'menuBlackAlpha');
					if (Reflect.hasField(jsonData, 'menuBlackLayer')) json_menuBlackLayer = Reflect.field(jsonData, 'menuBlackLayer');
					trace('[JSON] menuBlack: X=' + json_menuBlackX + ' Y=' + json_menuBlackY + ' Scale=' + json_menuBlackScale);

					if (Reflect.hasField(jsonData, 'menuWaterX')) json_menuWaterX = Reflect.field(jsonData, 'menuWaterX');
					if (Reflect.hasField(jsonData, 'menuWaterY')) json_menuWaterY = Reflect.field(jsonData, 'menuWaterY');
					if (Reflect.hasField(jsonData, 'menuWaterScale')) json_menuWaterScale = Reflect.field(jsonData, 'menuWaterScale');
					if (Reflect.hasField(jsonData, 'menuWaterAlpha')) json_menuWaterAlpha = Reflect.field(jsonData, 'menuWaterAlpha');
					trace('[JSON] menuWater: X=' + json_menuWaterX + ' Y=' + json_menuWaterY + ' Scale=' + json_menuWaterScale);

					if (Reflect.hasField(jsonData, 'memWterX')) json_memWterX = Reflect.field(jsonData, 'memWterX');
					if (Reflect.hasField(jsonData, 'memWterY')) json_memWterY = Reflect.field(jsonData, 'memWterY');
					if (Reflect.hasField(jsonData, 'memWterScale')) json_memWterScale = Reflect.field(jsonData, 'memWterScale');
					if (Reflect.hasField(jsonData, 'memWterAlpha')) json_memWterAlpha = Reflect.field(jsonData, 'memWterAlpha');
					if (Reflect.hasField(jsonData, 'memWterLayer')) json_memWterLayer = Reflect.field(jsonData, 'memWterLayer');
					trace('[JSON] memWter: X=' + json_memWterX + ' Y=' + json_memWterY + ' Scale=' + json_memWterScale);

				if (Reflect.hasField(jsonData, 'menuArtEyesX')) json_menuArtEyesX = Reflect.field(jsonData, 'menuArtEyesX');
				if (Reflect.hasField(jsonData, 'menuArtEyesY')) json_menuArtEyesY = Reflect.field(jsonData, 'menuArtEyesY');
				if (Reflect.hasField(jsonData, 'menuArtEyesScale')) json_menuArtEyesScale = Reflect.field(jsonData, 'menuArtEyesScale');
				if (Reflect.hasField(jsonData, 'menuArtEyesAlpha')) json_menuArtEyesAlpha = Reflect.field(jsonData, 'menuArtEyesAlpha');
				if (Reflect.hasField(jsonData, 'menuArtEyesLayer')) json_menuArtEyesLayer = Reflect.field(jsonData, 'menuArtEyesLayer');
				if (Reflect.hasField(jsonData, 'menuArtEyesBlink')) json_menuArtEyesBlink = Reflect.field(jsonData, 'menuArtEyesBlink');
				trace('[JSON] menuArtEyes: X=' + json_menuArtEyesX + ' Y=' + json_menuArtEyesY + ' Scale=' + json_menuArtEyesScale + ' Blink=' + json_menuArtEyesBlink);					if (Reflect.hasField(jsonData, 'gfxScale')) json_gfScale = Reflect.field(jsonData, 'gfxScale');
					if (Reflect.hasField(jsonData, 'gfxAlpha')) json_gfAlpha = Reflect.field(jsonData, 'gfxAlpha');
					trace('[JSON] gf: Scale=' + json_gfScale + ' Alpha=' + json_gfAlpha);

					if (Reflect.hasField(jsonData, 'titleScale')) json_logoScale = Reflect.field(jsonData, 'titleScale');
					if (Reflect.hasField(jsonData, 'titleAlpha')) json_logoAlpha = Reflect.field(jsonData, 'titleAlpha');
					trace('[JSON] logo: Scale=' + json_logoScale + ' Alpha=' + json_logoAlpha);

					if (Reflect.hasField(jsonData, 'startScale')) json_titleScale = Reflect.field(jsonData, 'startScale');
					if (Reflect.hasField(jsonData, 'startAlpha')) json_titleAlpha = Reflect.field(jsonData, 'startAlpha');
					trace('[JSON] titleText: Scale=' + json_titleScale + ' Alpha=' + json_titleAlpha);

					if (Reflect.hasField(jsonData, 'waterWorldX')) json_waterX = Reflect.field(jsonData, 'waterWorldX');
					if (Reflect.hasField(jsonData, 'waterWorldY')) json_waterY = Reflect.field(jsonData, 'waterWorldY');
					if (Reflect.hasField(jsonData, 'waterScale')) json_waterScale = Reflect.field(jsonData, 'waterScale');
					if (Reflect.hasField(jsonData, 'waterAlpha')) json_waterAlpha = Reflect.field(jsonData, 'waterAlpha');
					if (Reflect.hasField(jsonData, 'waterBitmapX')) json_waterBitmapX = Reflect.field(jsonData, 'waterBitmapX');
					if (Reflect.hasField(jsonData, 'waterBitmapY')) json_waterBitmapY = Reflect.field(jsonData, 'waterBitmapY');
					if (Reflect.hasField(jsonData, 'waterContainerX')) json_waterContainerX = Reflect.field(jsonData, 'waterContainerX');
					if (Reflect.hasField(jsonData, 'waterContainerY')) json_waterContainerY = Reflect.field(jsonData, 'waterContainerY');
					if (Reflect.hasField(jsonData, 'waterLayer')) json_waterLayer = Reflect.field(jsonData, 'waterLayer');
					trace('[JSON] water: WorldX=' + json_waterX + ' WorldY=' + json_waterY + ' BitmapX=' + json_waterBitmapX + ' BitmapY=' + json_waterBitmapY);
					trace('[JSON] water: ContainerX=' + json_waterContainerX + ' ContainerY=' + json_waterContainerY + ' Scale=' + json_waterScale + ' Alpha=' + json_waterAlpha);
				}
				catch(e:haxe.Exception)
				{
					trace('[WARN] Title JSON might broken, ignoring issue...\n${e.details()}');
				}
			}
			else trace('[WARN] No Title JSON detected, using default values.');
		}
		else trace('[JSON] Archivo NO encontrado en images/Menuoldcords.json');
		//else trace('[WARN] No Title JSON detected, using default values.');
	}

	function easterEggData()
	{
		if (FlxG.save.data.psychDevsEasterEgg == null) FlxG.save.data.psychDevsEasterEgg = ''; //Crash prevention
		var easterEgg:String = FlxG.save.data.psychDevsEasterEgg;
		switch(easterEgg.toUpperCase())
		{
			case 'SHADOW':
				characterImage = 'ShadowBump';
				animationName = 'Shadow Title Bump';
				gfPosition.x += 210;
				gfPosition.y += 40;
				useIdle = true;
			case 'RIVEREN':
				characterImage = 'ZRiverBump';
				animationName = 'River Title Bump';
				gfPosition.x += 180;
				gfPosition.y += 40;
				useIdle = true;
			case 'BBPANZU':
				characterImage = 'BBBump';
				animationName = 'BB Title Bump';
				danceLeftFrames = [14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27];
				danceRightFrames = [27, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13];
				gfPosition.x += 45;
				gfPosition.y += 100;
			case 'PESSY':
				characterImage = 'PessyBump';
				animationName = 'Pessy Title Bump';
				gfPosition.x += 165;
				gfPosition.y += 60;
				danceLeftFrames = [29, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14];
				danceRightFrames = [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28];
		}
	}

	function getIntroTextShit():Array<Array<String>>
	{
		#if MODS_ALLOWED
		var firstArray:Array<String> = Mods.mergeAllTextsNamed('data/introText.txt');
		#else
		var fullText:String = Assets.getText(Paths.txt('introText'));
		var firstArray:Array<String> = fullText.split('\n');
		#end
		var swagGoodArray:Array<Array<String>> = [];

		for (i in firstArray)
		{
			swagGoodArray.push(i.split('--'));
		}

		return swagGoodArray;
	}

	var transitioning:Bool = false;
	private static var playJingle:Bool = false;
	
	var newTitle:Bool = false;
	var titleTimer:Float = 0;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;
		// FlxG.watch.addQuick('amp', FlxG.sound.music.amplitude);

		if (FlxG.keys.justPressed.ESCAPE && !transitioning)
		{
			transitioning = true;
			FlxG.sound.play(Paths.sound('cancelMenu'));
			if (FlxG.sound.music != null)
			{
				FlxTween.cancelTweensOf(FlxG.sound.music);
				FlxG.sound.music.stop();
			}
			MusicBeatState.switchState(new NoticesState());
			return;
		}

		var pressedEnter:Bool = FlxG.keys.justPressed.ENTER || controls.ACCEPT;

		#if mobile
		for (touch in FlxG.touches.list)
		{
			if (touch.justPressed)
			{
				pressedEnter = true;
			}
		}
		#end

		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		if (gamepad != null)
		{
			if (gamepad.justPressed.START)
				pressedEnter = true;

			#if switch
			if (gamepad.justPressed.B)
				pressedEnter = true;
			#end
		}
		
		if (newTitle) {
			titleTimer += FlxMath.bound(elapsed, 0, 1);
			if (titleTimer > 2) titleTimer -= 2;
		}

		// EASTER EGG

		if (initialized && !transitioning && skippedIntro)
		{
			if (newTitle && !pressedEnter)
			{
				var timer:Float = titleTimer;
				if (timer >= 1)
					timer = (-timer) + 2;
				
				timer = FlxEase.quadInOut(timer);
				
				titleText.color = FlxColor.interpolate(titleTextColors[0], titleTextColors[1], timer);
				titleText.alpha = FlxMath.lerp(titleTextAlphas[0], titleTextAlphas[1], timer);
			}
			
			if(pressedEnter)
			{
				titleText.color = FlxColor.WHITE;
				titleText.alpha = 1;
				
				if(titleText != null) titleText.animation.play('press');

				FlxG.camera.flash(ClientPrefs.data.flashing ? FlxColor.WHITE : 0x4CFFFFFF, 1);
				FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);

				transitioning = true;
				// FlxG.sound.music.stop();

				new FlxTimer().start(1, function(tmr:FlxTimer)
				{
					MusicBeatState.switchState(new MainMenuState_oldmenu());
					closedState = true;
				});
				// FlxG.sound.play(Paths.music('titleShoot'), 0.7);
			}
			#if TITLE_SCREEN_EASTER_EGG
			else if (FlxG.keys.firstJustPressed() != FlxKey.NONE)
			{
				var keyPressed:FlxKey = FlxG.keys.firstJustPressed();
				var keyName:String = Std.string(keyPressed);
				if(allowedKeys.contains(keyName)) {
					easterEggKeysBuffer += keyName;
					if(easterEggKeysBuffer.length >= 32) easterEggKeysBuffer = easterEggKeysBuffer.substring(1);
					//trace('Test! Allowed Key pressed!!! Buffer: ' + easterEggKeysBuffer);

					for (wordRaw in easterEggKeys)
					{
						var word:String = wordRaw.toUpperCase(); //just for being sure you're doing it right
						if (easterEggKeysBuffer.contains(word))
						{
							//trace('YOOO! ' + word);
							if (FlxG.save.data.psychDevsEasterEgg == word)
								FlxG.save.data.psychDevsEasterEgg = '';
							else
								FlxG.save.data.psychDevsEasterEgg = word;
							FlxG.save.flush();

							FlxG.sound.play(Paths.sound('secret'));

							var black:FlxSprite = new FlxSprite(0, 0).makeGraphic(1, 1, FlxColor.BLACK);
							black.scale.set(FlxG.width, FlxG.height);
							black.updateHitbox();
							black.alpha = 0;
							add(black);

							FlxTween.tween(black, {alpha: 1}, 1, {onComplete:
								function(twn:FlxTween) {
									FlxTransitionableState.skipNextTransIn = true;
									FlxTransitionableState.skipNextTransOut = true;
									MusicBeatState.switchState(new TitleState_oldmenu());
								}
							});
							FlxG.sound.music.fadeOut();
							if(FreeplayState.vocals != null)
							{
								FreeplayState.vocals.fadeOut();
							}
							closedState = true;
							transitioning = true;
							playJingle = true;
							easterEggKeysBuffer = '';
							break;
						}
					}
				}
			}
			#end
		}

		if (initialized && pressedEnter && !skippedIntro)
		{
			skipIntro();
		}

	// Dev Mode Controls
	if (FlxG.keys.justPressed.F5) {
		devMode = !devMode;
		devText.visible = devMode;
		
		// Al desactivar dev mode, restaurar todas las visibilidades originales
		if (!devMode) {
			for (i in 0...devObjects.length) {
				devObjects[i].visible = devObjectsOriginalVisible[i];
			}
		} else {
			// Al activar, hacer visible el primer objeto
			devObjects[devIndex].visible = true;
			trace('[DEV] Dev mode activado. N/M=Video Alpha, L=Cambiar capas, TAB=Objeto');
		}
	}		if (devMode && skippedIntro) {
		// Cambiar objeto seleccionado
		if (FlxG.keys.justPressed.TAB) {
			// Restaurar visibilidad del objeto anterior
			devObjects[devIndex].visible = devObjectsOriginalVisible[devIndex];
			
			devIndex = (devIndex + 1) % devObjects.length;
			
			// Hacer visible el nuevo objeto seleccionado temporalmente
			devObjects[devIndex].visible = true;
		}

		// CONTROLES DE VIDEO OPACIDAD Y MENUWATER
		#if VIDEOS_ALLOWED
		if (waterVideo != null) {
			if (FlxG.keys.justPressed.N) {
				waterVideo.alpha += 0.1;
				if (waterVideo.alpha > 1.0) waterVideo.alpha = 1.0;
				trace('[DEV] Video Alpha: ' + Math.round(waterVideo.alpha * 100) + '%');
			}
			if (FlxG.keys.justPressed.M) {
				waterVideo.alpha -= 0.1;
				if (waterVideo.alpha < 0.0) waterVideo.alpha = 0.0;
				trace('[DEV] Video Alpha: ' + Math.round(waterVideo.alpha * 100) + '%');
			}
		}
		// CONTROLES DE MENUWATER OPACIDAD
		if (menuWater != null) {
			if (FlxG.keys.justPressed.G) {
				menuWater.alpha += 0.1;
				if (menuWater.alpha > 1.0) menuWater.alpha = 1.0;
				trace('[DEV] MenuWater Alpha: ' + Math.round(menuWater.alpha * 100) + '%');
			}
			if (FlxG.keys.justPressed.H) {
				menuWater.alpha -= 0.1;
				if (menuWater.alpha < 0.0) menuWater.alpha = 0.0;
				trace('[DEV] MenuWater Alpha: ' + Math.round(menuWater.alpha * 100) + '%');
			}
		}
		#end
		
		// CAMBIAR ORDEN DE CAPAS
		if (FlxG.keys.justPressed.L) {
			#if VIDEOS_ALLOWED
			if (waterVideo != null && menuWater != null) {
				// Alternar entre: video delante del agua vs video detrás del agua
				var videoIndex = members.indexOf(waterVideo);
				var waterIndex = members.indexOf(menuWater);
				
				if (videoIndex > waterIndex) {
					// Video está delante, moverlo atrás
					remove(waterVideo);
					insert(waterIndex, waterVideo);
					trace('[DEV] Video movido DETRÁS del agua');
				} else {
					// Video está detrás, moverlo adelante
					remove(waterVideo);
					insert(waterIndex + 1, waterVideo);
					trace('[DEV] Video movido DELANTE del agua');
				}
			}
			#end
		}

		var obj:FlxSprite = devObjects[devIndex];
			var moveSpeed:Float = FlxG.keys.pressed.SHIFT ? 10 : 1;

			// Mover objeto
			if (FlxG.keys.pressed.LEFT) obj.x -= moveSpeed;
			if (FlxG.keys.pressed.RIGHT) obj.x += moveSpeed;
			if (FlxG.keys.pressed.UP) obj.y -= moveSpeed;
			if (FlxG.keys.pressed.DOWN) obj.y += moveSpeed;

			// Escalar
			if (FlxG.keys.pressed.CONTROL) {
				if (FlxG.keys.justPressed.UP) {
					obj.scale.x += 0.01;
					obj.scale.y += 0.01;
					obj.updateHitbox();
				}
				if (FlxG.keys.justPressed.DOWN) {
					obj.scale.x -= 0.01;
					obj.scale.y -= 0.01;
					obj.updateHitbox();
				}
			}

		// Zoom de cámara
		if (FlxG.keys.justPressed.Q) {
			FlxG.camera.zoom -= 0.1;
			if (FlxG.camera.zoom < 0.1) FlxG.camera.zoom = 0.1;
		}
		if (FlxG.keys.justPressed.E) {
			FlxG.camera.zoom += 0.1;
		}
		if (FlxG.keys.justPressed.R) {
			FlxG.camera.zoom = 1;
		}

		// Actualizar texto dev
		var videoAlphaText:String = "";
		var waterAlphaText:String = "";
		#if VIDEOS_ALLOWED
		if (waterVideo != null) {
			videoAlphaText = 'Video Alpha: ${Math.round(waterVideo.alpha * 100)}%\n';
		}
		if (menuWater != null) {
			waterAlphaText = 'Water Alpha: ${Math.round(menuWater.alpha * 100)}%\n';
		}
		#end
		
		devText.text = '[DEV MODE] Objeto: ${devNames[devIndex]} (${devIndex+1}/${devObjects.length})\n';
		devText.text += 'Pos: X=${Math.floor(obj.x)} Y=${Math.floor(obj.y)}\n';
		devText.text += 'Scale: ${Math.round(obj.scale.x * 100) / 100}\n';
		devText.text += 'Zoom: ${Math.round(FlxG.camera.zoom * 100) / 100}\n';
		devText.text += videoAlphaText;
		devText.text += waterAlphaText;
		devText.text += 'N/M=Video | G/H=Water | L=Capas';
		devText.text += 'Visible: ${obj.visible ? "SÍ" : "NO"} (original: ${devObjectsOriginalVisible[devIndex] ? "SÍ" : "NO"})\n';
		devText.text += 'TAB=Cambiar | Flechas=Mover | SHIFT+Flechas=Rápido\n';
		devText.text += 'CTRL+Arriba/Abajo=Escalar | Q/E=Zoom | R=Reset Zoom\n';
		devText.text += 'V=Toggle Visible | P=Guardar JSON';

		// Toggle visibility manualmente
		if (FlxG.keys.justPressed.V) {
			obj.visible = !obj.visible;
			devObjectsOriginalVisible[devIndex] = obj.visible; // Actualizar visibilidad original
		}

		// Guardar JSON
		if (FlxG.keys.justPressed.P) {
			saveDevJSON();
		}
	}

	if(swagShader != null)
	{
		if(controls.UI_LEFT) swagShader.hue -= elapsed * 0.1;
		if(controls.UI_RIGHT) swagShader.hue += elapsed * 0.1;
	}

	super.update(elapsed);
}

	function createCoolText(textArray:Array<String>, ?offset:Float = 0)
	{
		for (i in 0...textArray.length)
		{
			var money:Alphabet = new Alphabet(0, 0, textArray[i], true);
			money.screenCenter(X);
			money.y += (i * 60) + 200 + offset;
			if(credGroup != null && textGroup != null)
			{
				credGroup.add(money);
				textGroup.add(money);
			}
		}
	}

	function addMoreText(text:String, ?offset:Float = 0)
	{
		if(textGroup != null && credGroup != null) {
			var coolText:Alphabet = new Alphabet(0, 0, text, true);
			coolText.screenCenter(X);
			coolText.y += (textGroup.length * 60) + 200 + offset;
			credGroup.add(coolText);
			textGroup.add(coolText);
		}
	}

	function deleteCoolText()
	{
		while (textGroup.members.length > 0)
		{
			credGroup.remove(textGroup.members[0], true);
			textGroup.remove(textGroup.members[0], true);
		}
	}

	private var sickBeats:Int = 0; //Basically curBeat but won't be skipped if you hold the tab or resize the screen
	public static var closedState:Bool = false;

	function saveDevJSON():Void
	{
		var json:Dynamic = {
			gfx: Math.floor(gfDance.x),
			gfy: Math.floor(gfDance.y),
			gfxScale: Math.round(gfDance.scale.x * 100) / 100,
			gfxAlpha: Math.round(gfDance.alpha * 100) / 100,
			titlex: Math.floor(logoBl.x),
			titley: Math.floor(logoBl.y),
			titleScale: Math.round(logoBl.scale.x * 100) / 100,
			titleAlpha: Math.round(logoBl.alpha * 100) / 100,
			startx: Math.floor(titleText.x),
			starty: Math.floor(titleText.y),
			startScale: Math.round(titleText.scale.x * 100) / 100,
			startAlpha: Math.round(titleText.alpha * 100) / 100,
			menuBlackX: Math.floor(menuBlack.x),
			menuBlackY: Math.floor(menuBlack.y),
			menuBlackScale: Math.round(menuBlack.scale.x * 100) / 100,
			menuBlackAlpha: Math.round(menuBlack.alpha * 100) / 100,
			menuWaterX: Math.floor(menuWater.x),
			menuWaterY: Math.floor(menuWater.y),
			menuWaterScale: Math.round(menuWater.scale.x * 100) / 100,
			menuWaterAlpha: Math.round(menuWater.alpha * 100) / 100,
			memWterX: Math.floor(memWter.x),
			memWterY: Math.floor(memWter.y),
			memWterScale: Math.round(memWter.scale.x * 100) / 100,
			memWterAlpha: Math.round(memWter.alpha * 100) / 100,
			menuArtEyesX: Math.floor(menuArtEyes.x),
			menuArtEyesY: Math.floor(menuArtEyes.y),
			menuArtEyesScale: Math.round(menuArtEyes.scale.x * 100) / 100,
			menuArtEyesAlpha: Math.round(menuArtEyesTargetAlpha * 100) / 100,
			menuArtEyesBlink: json_menuArtEyesBlink,
			bpm: musicBPM,
			animation: animationName,
			backgroundSprite: ""
		};
		
		// Agregar información del video si existe
		#if VIDEOS_ALLOWED
		if (waterVideo != null) {
			json.waterAlpha = Math.round(waterVideo.alpha * 100) / 100;
			json.waterScale = Math.round(waterVideo.scale.x * 100) / 100;
			
			// Agregar coordenadas del video si es posible
			if (waterVideo.videoSprite != null && waterVideo.videoSprite.bitmap != null) {
				var vbmp = waterVideo.videoSprite.bitmap;
				json.waterWorldX = Math.floor(vbmp.x + waterVideo.x);
				json.waterWorldY = Math.floor(vbmp.y + waterVideo.y);
				json.waterBitmapX = Math.floor(vbmp.x);
				json.waterBitmapY = Math.floor(vbmp.y);
				json.waterContainerX = Math.floor(waterVideo.x);
				json.waterContainerY = Math.floor(waterVideo.y);
				
				// Agregar información de capas
				var videoIndex = members.indexOf(waterVideo);
				var waterIndex = members.indexOf(menuWater);
				json.waterLayer = videoIndex;
				json.menuBlackLayer = members.indexOf(menuBlack);
				json.memWterLayer = members.indexOf(memWter);
				json.menuArtEyesLayer = members.indexOf(menuArtEyes);
			}
		}
		#end

		var jsonString:String = haxe.Json.stringify(json, "\t");
		trace('[DEV] JSON generado con OPACIDADES:\n' + jsonString);
		
		#if sys
		try {
			sys.io.File.saveContent('Menuoldcords.json', jsonString);
			trace('[DEV] ✓ Guardado en Menuoldcords.json (raíz del proyecto)');
			trace('[DEV] Copia este archivo a: assets/shared/images/Menuoldcords.json');
			trace('[DEV] ✓ INCLUYE: Posiciones + Escalas + Opacidades + Configuración de video');
		} catch(e:Dynamic) {
			trace('[DEV] ✗ Error al guardar: ' + e);
		}
		#end
	}

	override function beatHit()
	{
		super.beatHit();

		// Logo y gfDance ahora son imágenes estáticas de MenuC, no tienen animaciones
		// if(logoBl != null)
		// 	logoBl.animation.play('bump', true);

		// if(gfDance != null)
		// {
		// 	danceLeft = !danceLeft;
		// 	if(!useIdle)
		// 	{
		// 		if (danceLeft)
		// 			gfDance.animation.play('danceRight');
		// 		else
		// 			gfDance.animation.play('danceLeft');
		// 	}
		// 	else if(curBeat % 2 == 0) gfDance.animation.play('idle', true);
		// }

		if(!closedState)
		{
			sickBeats++;
			switch (sickBeats)
			{
				case 1:
					//FlxG.sound.music.stop();
					FlxG.sound.playMusic(Paths.music('menusongold'), 0);
					FlxG.sound.music.fadeIn(4, 0, 0.7);
					// Saltar directamente al intro sin créditos
					skipIntro();
			}
		}
	}

	var skippedIntro:Bool = false;
	var increaseVolume:Bool = false;
	/**
	 * Starts the MenuArtEyes fading cycle (similar to friend's code).
	 * Only runs if json_menuArtEyesBlink is true/1 and not already started.
	 */
	function startMenuArtEyesCycle():Void
	{
		trace('[EYES BLINK] startMenuArtEyesCycle() called');
		trace('[EYES BLINK] menuArtEyes=' + menuArtEyes + ' menuArtEyesBlinkStarted=' + menuArtEyesBlinkStarted);
		trace('[EYES BLINK] json_menuArtEyesBlink=' + json_menuArtEyesBlink);
		
		if (menuArtEyes == null || menuArtEyesBlinkStarted) {
			trace('[EYES BLINK] Returning early: menuArtEyes null or already started');
			return;
		}
		
		// Only start if JSON has it enabled
		if (json_menuArtEyesBlink != true && json_menuArtEyesBlink != 1) {
			trace('[EYES BLINK] Returning early: JSON blink disabled');
			return;
		}
		
		trace('[EYES BLINK] Starting cycle! menuArtEyesTargetAlpha=' + menuArtEyesTargetAlpha);
		menuArtEyesBlinkStarted = true;
		menuArtEyes.visible = true;
		menuArtEyesTimer = new FlxTimer();
		
		function cycleStep(tm:FlxTimer):Void
		{
			trace('[EYES BLINK] Cycle step - Fading in from ' + menuArtEyes.alpha + ' to ' + menuArtEyesTargetAlpha);
			// Fade in to target alpha
			FlxTween.tween(menuArtEyes, {alpha: menuArtEyesTargetAlpha}, 0.5, {
				ease: FlxEase.linear,
				onComplete: function(tin:FlxTween)
				{
					trace('[EYES BLINK] Fade in complete, staying visible for 2s');
					// Stay visible for 2 seconds
					menuArtEyesTimer.start(2, function(t2:FlxTimer)
					{
						trace('[EYES BLINK] Starting fade out to 0 over 6s');
						// Fade out over 6 seconds
						FlxTween.tween(menuArtEyes, {alpha: 0}, 6, {
							ease: FlxEase.linear,
							onComplete: function(tout:FlxTween)
							{
								trace('[EYES BLINK] Fade out complete, staying hidden for 2s');
								// Stay hidden for 2 seconds, then restart cycle
								menuArtEyesTimer.start(2, function(t3:FlxTimer)
								{
									cycleStep(t3);
								});
							}
						});
					});
				}
			});
		}
		cycleStep(null);
	}

	function skipIntro():Void
	{
		if (!skippedIntro)
		{
			#if TITLE_SCREEN_EASTER_EGG
			if (playJingle) //Ignore deez
			{
				playJingle = false;
				var easteregg:String = FlxG.save.data.psychDevsEasterEgg;
				if (easteregg == null) easteregg = '';
				easteregg = easteregg.toUpperCase();

				var sound:FlxSound = null;
				switch(easteregg)
				{
					case 'RIVEREN':
						sound = FlxG.sound.play(Paths.sound('JingleRiver'));
					case 'SHADOW':
						FlxG.sound.play(Paths.sound('JingleShadow'));
					case 'BBPANZU':
						sound = FlxG.sound.play(Paths.sound('JingleBB'));
					case 'PESSY':
						sound = FlxG.sound.play(Paths.sound('JinglePessy'));

					default: //Go back to normal ugly ass boring GF
						remove(ngSpr);
						remove(credGroup);
						FlxG.camera.flash(FlxColor.WHITE, 2);
						skippedIntro = true;

						FlxG.sound.playMusic(Paths.music('menusongold'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						return;
				}

				transitioning = true;
				if(easteregg == 'SHADOW')
				{
					new FlxTimer().start(3.2, function(tmr:FlxTimer)
					{
						remove(ngSpr);
						remove(credGroup);
						FlxG.camera.flash(FlxColor.WHITE, 0.6);
						transitioning = false;
					});
				}
				else
				{
					remove(ngSpr);
					remove(credGroup);
					FlxG.camera.flash(FlxColor.WHITE, 3);
					sound.onComplete = function() {
						FlxG.sound.playMusic(Paths.music('menusongold'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						transitioning = false;
						#if ACHIEVEMENTS_ALLOWED
						if(easteregg == 'PESSY') Achievements.unlock('pessy_easter_egg');
						#end
					};
				}
			}
			else #end //Default! Edit this one!!
			{
				remove(ngSpr);
				remove(credGroup);
				FlxG.camera.flash(FlxColor.WHITE, 4);

				var easteregg:String = FlxG.save.data.psychDevsEasterEgg;
				if (easteregg == null) easteregg = '';
				easteregg = easteregg.toUpperCase();
				#if TITLE_SCREEN_EASTER_EGG
				if(easteregg == 'SHADOW')
				{
					FlxG.sound.music.fadeOut();
					if(FreeplayState.vocals != null)
					{
						FreeplayState.vocals.fadeOut();
					}
				}
				#end
			}
			skippedIntro = true;
			
			// Start menuArtEyes blinking cycle after intro is skipped
			startMenuArtEyesCycle();
		}
	}
}
