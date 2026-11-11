package states;
// here was APlayer
// Uses the functionality of Psych 0.7 and some additions for the files of the week(BETA)
// All offsets must be accurate! Deleting and adding videos may not be accurate because it's too difficult for me to make them
// The values of glitches are 100 percent accuracy. I've been checking frame by frame with the senpai demo
// For support with regular 0.6.3, you will need to redo some things.
// This version has implemented link functionality

#if desktop
import backend.Discord;
import backend.Discord.DiscordClient;
#end

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.graphics.FlxGraphic;
import backend.WeekData;
import backend.Highscore;
import backend.Song;
import backend.StageData;
import backend.ClientPrefs;
import backend.CoolUtil;
import backend.Difficulty;
import backend.Paths;
import backend.Language;
import objects.MenuItem;
import objects.MenuCharacter;
import objects.Alphabet;
import states.PlayState;
import states.MainMenuState;
import states.LoadingState;
import states.FreeplayState;
import options.GameplayChangersSubstate;
import substates.ResetScoreSubState;
import sys.FileSystem;

import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxGlitchEffect;

#if VIDEOS_ALLOWED
import hxvlc.flixel.FlxVideoSprite;
#end

using StringTools;

class StoryMenuState extends MusicBeatState
{
	public static var weekCompleted:Map<String, Bool> = new Map<String, Bool>();
	var firstChanged:Bool = true;

	var scoreText:FlxText;
	var displayedWeekScore:Null<Int>;
	var jsonData:Dynamic;

	private static var lastDifficultyName:String = '';
	var curDifficulty:Int = 1;

	var txtWeekTitle:FlxText;

	private static var curWeek:Int = 0;
	
	var currentLoadedVideo:String = ""; // Track current video to avoid reloading same video
	var previewRequest:Int = 0;
	var previewPlaying:Bool = false;
	var musicLoadTimer:FlxTimer;
	var storyPreviewFiles:Dynamic = {};

	var grpWeekText:FlxTypedGroup<MenuItem>;

	var grpLocks:FlxTypedGroup<FlxSprite>;

	var difficultySelectors:FlxGroup;
	var sprDifficulty:FlxSprite;
	var safeInfo:FlxSprite;
	var canonInfo:FlxSprite;
	var canonGlitchEffect:FlxGlitchEffect;
	var canonGlitch:FlxEffectSprite;
	var leftArrow:FlxSprite;

	var tweenSafe:FlxTween;
	var tweenCanon:FlxTween;
	var tweenNoise:FlxTween;
	var timerNoise:FlxTimer;
	var tweenVideo:FlxTween;

	var videoTimer:FlxTimer;
	var videoLoadTimer:FlxTimer;
	var videoFadeTimer:FlxTimer;
	var videoCallbacksBound:Bool = false;
	var videoRevealPending:Bool = false;
	var videoFramesUntilReveal:Int = 0;
	// Estos clips solo son una previsualizacion del menu. La decodificacion por
	// hardware puede entregar buffers verdes con la salida custom de hxvlc;
	// usamos decoder estable por CPU y mantenemos la textura final en la GPU.
	static final STORY_VIDEO_OPTIONS:Array<String> = [
		':no-audio',
		':avcodec-hw=none',
		':drop-late-frames',
		':skip-frames',
		':file-caching=50'
	];

	var selectionArrowLEFT:FlxSprite;
	var selectionArrowRIGHT:FlxSprite;
	var playableTxt:FlxSprite;
	var watchableTxt:FlxSprite;
	var victim:FlxSprite;
	var video:FlxVideoSprite;
	var Glitch:FlxEffectSprite;

	var noise:FlxSprite;

	var blackImage:FlxSprite;
	var bgBlack:FlxSprite;

	var loadedWeeks:Array<WeekData> = [];

	
	var currentPlayingMusic:String = ""; // Para no reiniciar la música si es la misma

	override function create()
	{
		var previewIndex = 'assets/videos/story/previews/index.json';
		if (FileSystem.exists(previewIndex)) {
			try {
				storyPreviewFiles = haxe.Json.parse(sys.io.File.getContent(previewIndex));
			} catch (e:Dynamic) {
				trace("Error reading story preview index: " + e);
			}
		}

		// Create video sprite ONCE - NO precaching (avoid blocking UI)
		try {
			video = new FlxVideoSprite(0, 0);
			video.antialiasing = false;
			// El reproductor todavía no tiene bitmap durante sus primeros frames.
			// Mantenerlo fuera del draw hasta recibir onFormatSetup evita que Flixel
			// intente resolver un asset key vacío.
			video.visible = false;
			video.alpha = 0;
			trace("✓ FlxVideoSprite created");
		} catch (e:Dynamic) {
			trace("✗ Error creating FlxVideoSprite: " + e);
			video = null;
		}
		trace("✓ StoryMenuState.create() - INIT");
		
		try {
			// RESET variables estáticas PRIMERO
			loadedWeeks = [];
			curWeek = 0;
			lastDifficultyName = '';
			currentPlayingMusic = "";
			firstChanged = true;

			PlayState.isStoryMode = true;
			WeekData.reloadWeekFiles(true);
			persistentUpdate = persistentDraw = true;

			trace("✓ Variables reset OK");
		} catch (e:Dynamic) {
			trace("✗ ERROR in variable reset: " + e);
			return;
		}

		// AHORA sí llamamos super.create() con estado limpio
		try {
			super.create();
			trace("✓ super.create() OK");
		} catch (e:Dynamic) {
			trace("✗ ERROR in super.create(): " + e);
			return;
		}

		// A missing/corrupt weeks folder must not leave Story Mode half-created.
		if (WeekData.weeksList == null || WeekData.weeksList.length == 0) {
			persistentUpdate = false;
			MusicBeatState.switchState(new ErrorState("NO WEEKS ADDED FOR STORY MODE\n\nPress ACCEPT to go to the Week Editor Menu.\nPress BACK to return to Main Menu.",
				function() MusicBeatState.switchState(new states.editors.WeekEditorState()),
				function() {
					if (backend.MenuSelector.getMenu() == 'oldmenu')
						MusicBeatState.switchState(new MainMenuState_oldmenu());
					else
						MusicBeatState.switchState(new SoftCodeMenuState(true));
				}
			));
			return;
		}

		bgBlack = new FlxSprite(0, 56).makeGraphic(FlxG.width, 386, FlxColor.BLACK);
		trace("✓ bgBlack created");

		// Videos ya están precargados arriba en el inicio de create()

		// i thought width is 1920 and height is 555, lol
		try {
			noise = new FlxSprite(-385, -256.5);
			var atlasFrames = Paths.getSparrowAtlas('menus/menuObjects/WarningThisAssetIsLicenced');
			if (atlasFrames != null) {
				noise.frames = atlasFrames;
				noise.setGraphicSize(2050);
				noise.scale.y = 0.5;
				noise.animation.addByPrefix('idle', 'noising', 24);
				noise.animation.play('idle');
			} else {
				noise.makeGraphic(2050, 100, FlxColor.TRANSPARENT);
				noise.scale.y = 0.5;
				trace("WARNING: Sparrow atlas is null for noise sprite");
			}
			noise.antialiasing = ClientPrefs.data.antialiasing;
			noise.alpha = 1;
			trace("✓ Noise sprite created");
		} catch (e:Dynamic) {
			trace("✗ Error creating noise sprite: " + e);
			noise = new FlxSprite(-385, -256.5);
			noise.makeGraphic(2050, 100, FlxColor.TRANSPARENT);
			noise.scale.y = 0.5;
			noise.antialiasing = ClientPrefs.data.antialiasing;
			noise.alpha = 1;
		}

		scoreText = new FlxText(11, 11, 0, "SCORE: 49324858", 36);
		scoreText.setFormat("VCR OSD Mono", 32);

		txtWeekTitle = new FlxText((FlxG.width * 0.7), 11, 0, "", 32);
		txtWeekTitle.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, RIGHT);
		txtWeekTitle.alpha = 0.7;

		var ui_tex:FlxAtlasFrames = null;
		try {
			ui_tex = Paths.getSparrowAtlas('campaign_menu_UI_assets');
			trace("✓ campaign_menu_UI_assets loaded");
		} catch (e:Dynamic) {
			trace("✗ Error loading campaign_menu_UI_assets: " + e);
			ui_tex = null;
		}

		#if desktop
		DiscordClient.changePresence("In the Menus", null);
		#end

		// Create groups BEFORE the loop
		grpWeekText = new FlxTypedGroup<MenuItem>();
		grpLocks = new FlxTypedGroup<FlxSprite>();

		if (grpWeekText == null || grpLocks == null) {
			trace("ERROR: Groups not initialized!");
			return;
		}

		var num:Int = 0;
		try {
			trace("✓ Starting week loop, total weeks: " + WeekData.weeksList.length);
			for (i in 0...WeekData.weeksList.length)
			{
				var weekFile:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
				if (weekFile == null) continue;
				
				var isLocked:Bool;
				if (!weekFile.notPlayable){
					isLocked = weekIsLocked(WeekData.weeksList[i]); 
				} else {
					isLocked = false;
					weekFile.hiddenUntilUnlocked = false; 
				}
				var shouldLoad:Bool = !isLocked || (isLocked && !weekFile.hiddenUntilUnlocked);
				if(shouldLoad)
				{
					WeekData.setDirectoryFromWeek(weekFile);
					var weekName:String = WeekData.weeksList[i];
					var storyImage:String = 'images/storymenu/' + weekName + '.png';
					if (!Paths.fileExists(storyImage, IMAGE))
					{
						trace('⊘ Skipping non-story week without campaign art: ' + weekName);
						continue;
					}
					loadedWeeks.push(weekFile);
					
					try {
						var weekThing:MenuItem = new MenuItem(0, 0, weekName);
						if (weekThing == null) {
							trace("WARNING: MenuItem is null for week " + WeekData.weeksList[i]);
							continue;
						}
						trace("✓ MenuItem created for: " + WeekData.weeksList[i]);
						
						weekThing.x = 10;
						var baseY:Float = 480;
						weekThing.y = baseY + ((weekThing.height + 20) * num);
						weekThing.ID = num;
						
						if (grpWeekText != null) {
							grpWeekText.add(weekThing);
							trace("✓ MenuItem added to grpWeekText");
						}

						weekThing.antialiasing = ClientPrefs.data.antialiasing;
						weekThing.updateHitbox();

						if (isLocked)
						{
							var lock:FlxSprite = new FlxSprite(weekThing.width + 10 + weekThing.x);
							try {
								lock.loadGraphic(Paths.image('campaign_menu_UI_assets'));
							} catch (e:Dynamic) {
								lock.makeGraphic(50, 50, FlxColor.RED);
							}
							lock.ID = num;
							lock.antialiasing = ClientPrefs.data.antialiasing;
							if (grpLocks != null) grpLocks.add(lock);
						}
						num++;
					} catch (e:Dynamic) {
						trace("✗ Error creating/adding MenuItem for week " + WeekData.weeksList[i] + ": " + e);
						continue;
					}
				}
			}
			trace("✓ Week loop completed, loaded weeks: " + num);
		} catch (e:Dynamic) {
			trace("ERROR in week loop: " + e);
		}

		// Add groups to display after loop
		trace("✓ About to add grpWeekText");
		if (grpWeekText != null) add(grpWeekText);
		trace("✓ grpWeekText added");

		trace("✓ About to add blackBarThingie");
		var blackBarThingie:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 56, FlxColor.BLACK);
		if (blackBarThingie != null) add(blackBarThingie);
		trace("✓ blackBarThingie added");

		trace("✓ About to add grpLocks");
		if (grpLocks != null) add(grpLocks);
		trace("✓ grpLocks added");

		// VERIFICACIÓN CRÍTICA
		if (loadedWeeks == null || loadedWeeks.length == 0) {
			trace("CRITICAL ERROR: No playable weeks loaded!");
			persistentUpdate = false;
			MusicBeatState.switchState(new ErrorState("NO PLAYABLE WEEKS FOUND IN STORY MODE\n\nPress ACCEPT to go to the Week Editor Menu.\nPress BACK to return to Main Menu.",
				function() MusicBeatState.switchState(new states.editors.WeekEditorState()),
				function() {
					if (backend.MenuSelector.getMenu() == 'oldmenu')
						MusicBeatState.switchState(new MainMenuState_oldmenu());
					else
						MusicBeatState.switchState(new SoftCodeMenuState(true));
				}
			));
			return;
		}

		trace("✓ About to setDirectoryFromWeek(loadedWeeks[0])");
		try {
			WeekData.setDirectoryFromWeek(loadedWeeks[0]);
			trace("✓ setDirectoryFromWeek OK");
		} catch (e:Dynamic) {
			trace("✗ Error in setDirectoryFromWeek: " + e);
		}

		trace("✓ About to create difficultySelectors");
		try {
			difficultySelectors = new FlxGroup();
			trace("✓ difficultySelectors created");
		} catch (e:Dynamic) {
			trace("✗ Error creating difficultySelectors: " + e);
			difficultySelectors = null;
		}

		trace("✓ About to create leftArrow");
		try {
			leftArrow = new FlxSprite(100, 500);
			// Este objeto solo funciona como ancla para la Y de la dificultad.
			// Necesita un frame real porque FlxSprite.checkEmptyFrame() se ejecuta
			// antes de comprobar alpha y trataría de cargar el logo por defecto.
			leftArrow.makeGraphic(1, 1, FlxColor.TRANSPARENT);
			leftArrow.antialiasing = ClientPrefs.data.antialiasing;
			leftArrow.alpha = 0;
			if (leftArrow != null) difficultySelectors.add(leftArrow);
			trace("✓ leftArrow created and added");
		} catch (e:Dynamic) {
			trace("✗ Error creating leftArrow: " + e);
			leftArrow = null;
		}

		trace("✓ About to create selectionArrowLEFT");
		try {
			selectionArrowLEFT = new FlxSprite(429, 469);
			selectionArrowLEFT.loadGraphic(Paths.image('menus/menuObjects/selectionArrowLEFT'));
			selectionArrowLEFT.scale.set(1, 0.8);
			selectionArrowLEFT.antialiasing = ClientPrefs.data.antialiasing;
			if (selectionArrowLEFT != null) add(selectionArrowLEFT);
			trace("✓ selectionArrowLEFT created and added");
		} catch (e:Dynamic) {
			trace("✗ Error creating selectionArrowLEFT: " + e);
			selectionArrowLEFT = new FlxSprite(429, 469);
			selectionArrowLEFT.makeGraphic(50, 50, FlxColor.TRANSPARENT);
			selectionArrowLEFT.scale.set(1, 0.8);
			selectionArrowLEFT.antialiasing = ClientPrefs.data.antialiasing;
			selectionArrowLEFT.alpha = 0;
			if (selectionArrowLEFT != null) add(selectionArrowLEFT);
		}

		trace("✓ About to create selectionArrowRIGHT");
		try {
			selectionArrowRIGHT = new FlxSprite(805, 469);
			selectionArrowRIGHT.loadGraphic(Paths.image('menus/menuObjects/selectionArrowRIGHT'));
			selectionArrowRIGHT.scale.set(1, 0.8);
			selectionArrowRIGHT.antialiasing = ClientPrefs.data.antialiasing;
			if (selectionArrowRIGHT != null) add(selectionArrowRIGHT);
			trace("✓ selectionArrowRIGHT created and added");
		} catch (e:Dynamic) {
			trace("✗ Error creating selectionArrowRIGHT: " + e);
			selectionArrowRIGHT = new FlxSprite(805, 469);
			selectionArrowRIGHT.makeGraphic(50, 50, FlxColor.TRANSPARENT);
			selectionArrowRIGHT.scale.set(1, 0.8);
			selectionArrowRIGHT.antialiasing = ClientPrefs.data.antialiasing;
			selectionArrowRIGHT.alpha = 0;
			if (selectionArrowRIGHT != null) add(selectionArrowRIGHT);
		}

		trace("✓ About to create playableTxt");
		try {
			playableTxt = new FlxSprite(894, 480);
			playableTxt.loadGraphic(Paths.image('menus/menuObjects/playable'));
			playableTxt.antialiasing = false;
			playableTxt.visible = false;
			if (playableTxt != null) add(playableTxt);
			trace("✓ playableTxt created and added");
		} catch (e:Dynamic) {
			trace("✗ Error creating playableTxt: " + e);
			playableTxt = new FlxSprite(894, 480);
			playableTxt.makeGraphic(50, 50, FlxColor.TRANSPARENT);
			playableTxt.antialiasing = false;
			playableTxt.visible = false;
			playableTxt.alpha = 0;
			if (playableTxt != null) add(playableTxt);
		}

		trace("✓ About to create watchableTxt");
		try {
			watchableTxt = new FlxSprite(894, 480);
			watchableTxt.loadGraphic(Paths.image('menus/menuObjects/watchable'));
			watchableTxt.antialiasing = false;
			watchableTxt.visible = false;
			if (watchableTxt != null) add(watchableTxt);
			trace("✓ watchableTxt created and added");
		} catch (e:Dynamic) {
			trace("✗ Error creating watchableTxt: " + e);
			watchableTxt = new FlxSprite(894, 480);
			watchableTxt.makeGraphic(50, 50, FlxColor.TRANSPARENT);
			watchableTxt.antialiasing = false;
			watchableTxt.visible = false;
			watchableTxt.alpha = 0;
			if (watchableTxt != null) add(watchableTxt);
		}

		// Updated for 1.0.4 Difficulty system
		trace("✓ About to call Difficulty.resetList()");
		try {
			Difficulty.resetList();
			trace("✓ Difficulty.resetList() OK");
		} catch (e:Dynamic) {
			trace("✗ Error in Difficulty.resetList(): " + e);
		}
		if(lastDifficultyName == '')
		{
			lastDifficultyName = Difficulty.getDefault();
		}
		curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(lastDifficultyName)));
		
		trace("✓ About to create sprDifficulty");
		try {
			sprDifficulty = new FlxSprite(500, 484);
			sprDifficulty.makeGraphic(150, 50, 0xFF333333);
			sprDifficulty.antialiasing = false;
			sprDifficulty.visible = true;
			if (sprDifficulty != null && difficultySelectors != null) {
				difficultySelectors.add(sprDifficulty);
				trace("✓ sprDifficulty created and added");
			}
		} catch (e:Dynamic) {
			trace("✗ Error creating sprDifficulty: " + e);
			sprDifficulty = new FlxSprite(500, 484);
			sprDifficulty.makeGraphic(150, 50, 0xFF333333);
			sprDifficulty.antialiasing = false;
			sprDifficulty.visible = true;
			if (sprDifficulty != null && difficultySelectors != null) difficultySelectors.add(sprDifficulty);
		}

		trace("✓ About to create canonGlitchEffect");
		try {
			canonGlitchEffect = new FlxGlitchEffect();
			canonGlitchEffect.size = 5;
			canonGlitchEffect.delay = 0.1;
			canonGlitchEffect.strength = 5;
			trace("✓ canonGlitchEffect created");
		} catch (e:Dynamic) {
			trace("✗ Error creating canonGlitchEffect: " + e);
			canonGlitchEffect = null;
		}

		trace("✓ About to create safeInfo");
		try {
			safeInfo = new FlxSprite(519, 569);
			safeInfo.loadGraphic(Paths.image('menus/menuObjects/safeInfo'));
			safeInfo.antialiasing = false;
			safeInfo.alpha = 0;
			trace("✓ safeInfo created");
		} catch (e:Dynamic) {
			trace("✗ Error creating safeInfo: " + e);
			safeInfo = new FlxSprite(519, 569);
			safeInfo.makeGraphic(100, 100, FlxColor.TRANSPARENT);
			safeInfo.antialiasing = false;
			safeInfo.alpha = 0;
		}

		trace("✓ About to create canonInfo");
		try {
			canonInfo = new FlxSprite(519, 569);
			canonInfo.loadGraphic(Paths.image('menus/menuObjects/canonInfo'));
			canonInfo.antialiasing = false;
			canonInfo.alpha = 0;
			trace("✓ canonInfo created");
		} catch (e:Dynamic) {
			trace("✗ Error creating canonInfo: " + e);
			canonInfo = new FlxSprite(519, 569);
			canonInfo.makeGraphic(100, 100, FlxColor.TRANSPARENT);
			canonInfo.antialiasing = false;
			canonInfo.alpha = 0;
		}

		trace("✓ About to create canonGlitch");
		try {
			if (canonGlitchEffect != null && sprDifficulty != null) {
				canonGlitch = new FlxEffectSprite(sprDifficulty, [canonGlitchEffect]);
				canonGlitch.scale.x = 1.1;
				canonGlitch.scale.y = 1.1;
				canonGlitch.x = 509;
				canonGlitch.y = 484;
				canonGlitch.visible = false;
				if (canonGlitch != null && difficultySelectors != null) {
					difficultySelectors.add(canonGlitch);
					trace("✓ canonGlitch created and added");
				}
			}
		} catch (e:Dynamic) {
			trace("✗ Error creating canonGlitch: " + e);
			canonGlitch = null;
		}

		trace("✓ About to create victim");
		try {
			victim = new FlxSprite();
			victim.loadGraphic(Paths.image('menus/menuObjects/selectyourvictim'));
			victim.scale.x = 0.7;
			victim.scale.y = 0.7;
			victim.visible = true;
			victim.screenCenter();
			victim.antialiasing = ClientPrefs.data.antialiasing;
			trace("✓ victim created");
		} catch (e:Dynamic) {
			trace("✗ Error creating victim: " + e);
			victim = new FlxSprite();
			victim.makeGraphic(100, 100, FlxColor.TRANSPARENT);
			victim.scale.x = 0.7;
			victim.scale.y = 0.7;
			victim.visible = true;
			victim.screenCenter();
			victim.antialiasing = ClientPrefs.data.antialiasing;
			victim.alpha = 0;
		}

		trace("✓ About to create Glitch effect");
		try {
			var glitchEffect:FlxGlitchEffect = new FlxGlitchEffect();
			glitchEffect.size = 5;
			glitchEffect.delay = 0.1;
			glitchEffect.strength = 5;

			if (victim != null) {
				Glitch = new FlxEffectSprite(victim, [glitchEffect]);
				Glitch.scale.x = 0.7;
				Glitch.scale.y = 0.7;
				Glitch.x = -325;
				Glitch.y = -180;
				Glitch.visible = true;
				trace("✓ Glitch created");
			}
		} catch (e:Dynamic) {
			trace("✗ Error creating Glitch: " + e);
			Glitch = null;
		}
		
		trace("✓ About to create blackImage");
		try {
			blackImage = new FlxSprite();
			blackImage.makeGraphic(1280, 720, FlxColor.BLACK);
			blackImage.screenCenter();
			blackImage.alpha = 1;
			trace("✓ blackImage created");
		} catch (e:Dynamic) {
			trace("✗ Error creating blackImage: " + e);
			blackImage = null;
		}

		trace("✓ About to add all sprites to state");
		try {
			if (bgBlack != null) add(bgBlack);
			trace("✓ bgBlack added");
		} catch (e:Dynamic) {
			trace("✗ Error adding bgBlack: " + e);
		}

        try {
			if (video != null) add(video);
			trace("✓ video added");
		} catch (e:Dynamic) {
			trace("✗ Error adding video: " + e);
		}

		try {
			if (noise != null) add(noise);
			trace("✓ noise added");
		} catch (e:Dynamic) {
			trace("✗ Error adding noise: " + e);
		}

		try {
			if (scoreText != null) add(scoreText);
			trace("✓ scoreText added");
		} catch (e:Dynamic) {
			trace("✗ Error adding scoreText: " + e);
		}

		try {
			if (txtWeekTitle != null) add(txtWeekTitle);
			trace("✓ txtWeekTitle added");
		} catch (e:Dynamic) {
			trace("✗ Error adding txtWeekTitle: " + e);
		}

		try {
			if (difficultySelectors != null) add(difficultySelectors);
			trace("✓ difficultySelectors added");
		} catch (e:Dynamic) {
			trace("✗ Error adding difficultySelectors: " + e);
		}

		try {
			if (safeInfo != null) add(safeInfo);
			trace("✓ safeInfo added");
		} catch (e:Dynamic) {
			trace("✗ Error adding safeInfo: " + e);
		}

		try {
			if (canonInfo != null) add(canonInfo);
			trace("✓ canonInfo added");
		} catch (e:Dynamic) {
			trace("✗ Error adding canonInfo: " + e);
		}

		try {
			if (blackImage != null) add(blackImage);
			trace("✓ blackImage added");
		} catch (e:Dynamic) {
			trace("✗ Error adding blackImage: " + e);
		}

		try {
			if (victim != null) add(victim);
			trace("✓ victim added");
		} catch (e:Dynamic) {
			trace("✗ Error adding victim: " + e);
		}

		try {
			if (Glitch != null) add(Glitch);
			trace("✓ Glitch added");
		} catch (e:Dynamic) {
			trace("✗ Error adding Glitch: " + e);
		}

		// Add Glitch at the end so it appears on top of everything
		try {
			if (Glitch != null) {
				remove(Glitch);
				add(Glitch);
				trace("✓ Glitch re-added to front layer");
			}
		} catch (e:Dynamic) {
			trace("✗ Error re-adding Glitch: " + e);
		}

		// Add bgBlack again at the end so it appears on top of victim
		try {
			if (bgBlack != null) {
				remove(bgBlack);
				add(bgBlack);
				trace("✓ bgBlack re-added to top layer");
			}
		} catch (e:Dynamic) {
			trace("✗ Error re-adding bgBlack: " + e);
		}

		trace("✓ About to create animation timer");
		try {
			// Animation: fade out victim, Glitch effect and blackImage after 2 seconds, keep them invisible
			new FlxTimer().start(2, function(tmr) {
				if (victim != null) {
					FlxTween.tween(victim, { alpha: 0 }, 1.5);
				}
				if (Glitch != null) {
					FlxTween.tween(Glitch, { alpha: 0 }, 1.5, {
						onComplete: function(_) {
							Glitch.visible = false;
							Glitch.active = false;
						}
					});
				}
				if (blackImage != null) {
					FlxTween.tween(blackImage, { alpha: 0 }, 1.5);
				}
			});
			trace("✓ Animation timer started");
		} catch (e:Dynamic) {
			trace("✗ Error creating animation timer: " + e);
		}

		// CRITICAL: Validate all members before calling changeWeek and changeDifficulty
		trace("✓ Performing pre-change validation");
		try {
			// Verify all critical sprites exist and have valid graphics
			if (sprDifficulty != null && sprDifficulty.graphic == null) {
				trace("WARNING: sprDifficulty has null graphic, creating fallback");
				sprDifficulty.makeGraphic(150, 50, 0xFF333333);
			}
			if (grpWeekText != null) {
				for (member in grpWeekText.members) {
					if (member != null && member.graphic == null) {
						trace("WARNING: MenuItem has null graphic");
						member.makeGraphic(300, 150, FlxColor.fromInt(0xFF333333));
					}
				}
			}
			trace("✓ Pre-change validation complete");
		} catch (e:Dynamic) {
			trace("✗ Error in validation: " + e);
		}

		trace("✓ About to call changeWeek()");
		try {
			changeWeek();
			trace("✓ changeWeek() OK");
		} catch (e:Dynamic) {
			trace("✗ Error in changeWeek(): " + e);
		}

		trace("✓ About to call changeDifficulty()");
		try {
			changeDifficulty();
			trace("✓ changeDifficulty() OK");
		} catch (e:Dynamic) {
			trace("✗ Error in changeDifficulty(): " + e);
		}

		trace("✓✓✓ StoryMenuState.create() COMPLETED SUCCESSFULLY ✓✓✓");

		// FINAL SAFETY CHECK - Wrap everything in try-catch to catch framework errors
		try {
			// Force a delay before returning to allow framework to initialize
			new FlxTimer().start(0.1, function(tmr:FlxTimer) {
				trace("✓✓✓ StoryMenuState fully initialized and ready");
			});
		} catch (e:Dynamic) {
			trace("✗ ERROR in final initialization: " + e);
		}
	}

	override function openSubState(SubState:FlxSubState):Void
	{
		trace("✓ openSubState() called with SubState: " + (SubState != null ? Type.getClassName(Type.getClass(SubState)) : "null"));
		try {
			// Check if SubState is null before trying to use it
			if (SubState == null) {
				trace("WARNING: Attempting to open null SubState!");
				return;
			}
			
			// MEGA PROTECTION: Wrap super call in multiple layers
			try {
				trace("✓ About to call super.openSubState()");
				cancelStoryPreview();
				if (musicLoadTimer != null) musicLoadTimer.cancel();
				super.openSubState(SubState);
				trace("✓ openSubState() super call completed successfully");
			} catch (e:Dynamic) {
				trace("✗ CRITICAL ERROR in openSubState super call: " + e);
				trace("Stack: " + e);
				// DO NOT try to recover - just fail silently and let game continue
				return;
			}
		} catch (e:Dynamic) {
			trace("✗ CRITICAL ERROR in openSubState wrapper: " + e);
			return;
		}
	}
	
	private function validateAllMemberGraphics():Void
	{
		try {
			// ONLY LOG and detect issues, do NOT modify graphics
			if (members != null) {
				for (member in members) {
					if (member != null) {
						try {
							if (Std.isOfType(member, FlxSprite)) {
								var sprite:FlxSprite = cast(member, FlxSprite);
								if (sprite.graphic == null) {
									trace("WARNING: Found sprite with null graphic, type: " + Type.getClassName(Type.getClass(sprite)));
								}
							}
						} catch (e:Dynamic) {
							trace("Could not validate sprite: " + e);
						}
					}
				}
			}
			trace("✓ Member validation complete (read-only)");
		} catch (e:Dynamic) {
			trace("✗ Error validating members: " + e);
		}
	}

	override function closeSubState():Void
	{
		trace("✓ closeSubState() called");
		try {
			persistentUpdate = true;
			changeWeek();
			super.closeSubState();
		} catch (e:Dynamic) {
			trace("✗ ERROR in closeSubState(): " + e);
		}
	}

	// Flixel ya evita dibujar miembros inexistentes. La validacion recursiva que
	// habia aqui recorria todo el arbol de objetos cada frame y era uno de los
	// mayores costes de CPU del menu.
	override function draw():Void
	{
		super.draw();
	}

	override function update(elapsed:Float)
	{
		try {
			if (loadedWeeks != null && loadedWeeks.length > curWeek && loadedWeeks[curWeek] != null) {
				if (!loadedWeeks[curWeek].notPlayable){
					if (watchableTxt != null) watchableTxt.visible = false;
					if (playableTxt != null) playableTxt.visible = true;
				} else {
					if (watchableTxt != null) watchableTxt.visible = true;
					if (playableTxt != null) playableTxt.visible = false;
				}
			}
			// scoreText.setFormat('VCR OSD Mono', 32);
			lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, FlxMath.bound(elapsed * 30, 0, 1)));
			if(Math.abs(intendedScore - lerpScore) < 10) lerpScore = intendedScore;
			if (scoreText != null && loadedWeeks != null && loadedWeeks.length > curWeek && loadedWeeks[curWeek] != null) {
				var weekScore = loadedWeeks[curWeek].notPlayable ? 0 : lerpScore;
				if (displayedWeekScore != weekScore) {
					displayedWeekScore = weekScore;
					scoreText.text = "WEEK SCORE:" + weekScore;
				}
			}

		if (FlxG.keys.justPressed.F11)
		{
		   FlxG.fullscreen = !FlxG.fullscreen;
		}

		// DEV ZOOM KEYS
		if (FlxG.keys.justPressed.MINUS)
		{
			FlxG.camera.zoom -= 0.05;
		}
		if (FlxG.keys.justPressed.PLUS)
		{
			FlxG.camera.zoom += 0.05;
		}
		if (FlxG.keys.justPressed.ZERO)
		{
			FlxG.camera.zoom = 1.0;
		}

		// DEV ZOOM WITH Q E R
		if (FlxG.keys.justPressed.Q)
		{
			FlxG.camera.zoom -= 0.1;
			trace("ZOOM OUT: " + FlxG.camera.zoom);
		}
		if (FlxG.keys.justPressed.E)
		{
			FlxG.camera.zoom += 0.1;
			trace("ZOOM IN: " + FlxG.camera.zoom);
		}
		if (FlxG.keys.justPressed.R)
		{
			FlxG.camera.zoom = 1.0;
			trace("ZOOM RESET: 1.0");
		}

		if (sprDifficulty != null){
			if (canonGlitch != null) {
				canonGlitch.setPosition(sprDifficulty.x, sprDifficulty.y);
				canonGlitch.alpha = sprDifficulty.alpha;
			}
		}

		if (canonInfo != null && safeInfo != null) {
			if (canonInfo.alpha > 0 && lastDifficultyName == "safe") {
				canonInfo.visible = false;
				safeInfo.visible = true;
			} else if (safeInfo.alpha > 0 && lastDifficultyName == "canon") {
				canonInfo.visible = true;
				safeInfo.visible = false;
			}
		}

		if (!movedBack && !selectedWeek)
		{
			var upP = controls.UI_UP_P;
			var downP = controls.UI_DOWN_P;
			if (upP)
			{
				changeWeek(-1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}

			if (downP)
			{
				changeWeek(1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}

			if(FlxG.mouse.wheel != 0)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
				changeWeek(-FlxG.mouse.wheel);
				changeDifficulty();
			}

			if (controls.UI_RIGHT_P)
				changeDifficulty(1);
			else if (controls.UI_LEFT_P)
				changeDifficulty(-1);
			else if (upP || downP)
				changeDifficulty();

			if(FlxG.keys.justPressed.CONTROL)
			{
				persistentUpdate = false;
				openSubState(new GameplayChangersSubstate());
			}
			else if(controls.RESET)
			{
				persistentUpdate = false;
				openSubState(new ResetScoreSubState('', curDifficulty, '', curWeek));
				//FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			else if (controls.ACCEPT)
			{
				selectWeek();
			}
		}

		if (controls.BACK && !movedBack && !selectedWeek)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			movedBack = true;
			cancelStoryPreview();
			if (musicLoadTimer != null) musicLoadTimer.cancel();
			FlxG.sound.music.stop();
			// Return to the menu selected in the external menu preview.
			FlxTween.tween(FlxG.camera, {zoom: 1.3}, 0.5, {ease: FlxEase.backIn});
			if (backend.MenuSelector.getMenu() == 'oldmenu')
				MusicBeatState.switchState(new MainMenuState_oldmenu());
			else
				MusicBeatState.switchState(new SoftCodeMenuState(true));
		}

		if (noise != null) noise.active = noise.visible && noise.alpha > 0;
		if (canonGlitch != null) canonGlitch.active = canonGlitch.visible && canonGlitch.alpha > 0;
		super.update(elapsed);

		// Animación suave de las semanas (como Alphabet en Freeplay)
		if (grpWeekText != null) {
			for (num => item in grpWeekText.members) {
				if (item != null) {
					var baseY:Float = 480;
					var targetYPos:Float = baseY + ((item.height + 20) * (num - curWeek));
					item.y = FlxMath.lerp(targetYPos, item.y, Math.exp(-elapsed * 9.6));
				}
			}
		}

		if (grpLocks != null && grpWeekText != null) {
			grpLocks.forEach(function(lock:FlxSprite)
			{
				if (lock != null && lock.ID < grpWeekText.members.length) {
					lock.y = grpWeekText.members[lock.ID].y;
					lock.visible = (lock.y > FlxG.height / 2);
				}
			});
		}
		} catch (e:Dynamic) {
			trace("✗ ERROR in update(): " + e);
		}
	}

	var movedBack:Bool = false;
	var selectedWeek:Bool = false;
	var stopspamming:Bool = false;

	function selectWeek()
	{
		// Verificación exhaustiva antes de acceder a loadedWeeks
		if (loadedWeeks == null || loadedWeeks.length == 0 || curWeek < 0 || curWeek >= loadedWeeks.length) {
			trace("WARNING: selectWeek() called pero loadedWeeks no está listo!");
			return;
		}

		var currentWeekData:WeekData = loadedWeeks[curWeek];
		if (currentWeekData == null) {
			trace("WARNING: loadedWeeks[curWeek] es null!");
			return;
		}

		if (!currentWeekData.notPlayable){
			if (!weekIsLocked(currentWeekData.fileName))
			{
				if (stopspamming == false)
				{
					FlxG.sound.play(Paths.sound('confirmMenu'));
					stopspamming = true;
				}

				// We can't use Dynamic Array .copy() because that crashes HTML5, here's a workaround.
				var songArray:Array<String> = [];
				var leWeek:Array<Dynamic> = currentWeekData.songs;
				if (leWeek != null) {
					for (i in 0...leWeek.length) {
						songArray.push(leWeek[i][0]);
					}
				}

				// Nevermind that's stupid lmao
				PlayState.storyPlaylist = songArray;
				PlayState.isStoryMode = true;
				selectedWeek = true;
				cancelStoryPreview();
				if (musicLoadTimer != null) musicLoadTimer.cancel();

				var diffic = Difficulty.getFilePath(curDifficulty);
				if(diffic == null) diffic = '';

				PlayState.storyDifficulty = curDifficulty;

				PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase() + diffic, PlayState.storyPlaylist[0].toLowerCase());
				PlayState.campaignScore = 0;
				PlayState.campaignMisses = 0;
				new FlxTimer().start(1, function(tmr:FlxTimer)
				{
					LoadingState.loadAndSwitchState(new PlayState(), true);
					FreeplayState.destroyFreeplayVocals();
				});
			} else {
				FlxG.sound.play(Paths.sound('cancelMenu'));
			}
		} else {
			if (currentWeekData.playlist != null){
				var link = currentWeekData.playlist;
				if (link != null) {
					trace("Playlist isn't null: " + link);
				} else {
					currentWeekData.playlist = "None";
				}
			} else {
				currentWeekData.playlist = "None";
			}
			if (currentWeekData.links != null) {
				for (i in 0...10) {
					var link = currentWeekData.links[i];
					if (link != null) {
						// Remove the [] characters from the string so that it works correctly (after all, who would like just an open new browser, lol)
						currentWeekData.links[i] = link.split("[").join("").split("]").join("");
					} else {
						currentWeekData.links[i] = "None";
					}
				}
				trace("All links have been cleaned.");
			} else {
				currentWeekData.links = [];
				for (i in 0...10) {
					currentWeekData.links[i] = "None";
				}
			}
			
			// It's stupid, but I'm dumb to redo it
			// Diff day0 is playlist
			if (lastDifficultyName == 'day0'){
				CoolUtil.browserLoad(currentWeekData.playlist);
			} else if (lastDifficultyName == 'day1'){
				CoolUtil.browserLoad(currentWeekData.links[0]);
			} else if (lastDifficultyName == 'day2'){
				CoolUtil.browserLoad(currentWeekData.links[1]);
			} else if (lastDifficultyName == 'day3'){
				CoolUtil.browserLoad(currentWeekData.links[2]);
			} else if (lastDifficultyName == 'day4') {
				CoolUtil.browserLoad(currentWeekData.links[3]);
			} else if (lastDifficultyName == 'day5') {
				CoolUtil.browserLoad(currentWeekData.links[4]);
			} else if (lastDifficultyName == 'day6') {
				CoolUtil.browserLoad(currentWeekData.links[5]);
			} else if (lastDifficultyName == 'day7') {
				CoolUtil.browserLoad(currentWeekData.links[6]);
			} else if (lastDifficultyName == 'day8') {
				CoolUtil.browserLoad(currentWeekData.links[7]);
			} else if (lastDifficultyName == 'day9') {
				CoolUtil.browserLoad(currentWeekData.links[8]);
			} else {
				CoolUtil.browserLoad(currentWeekData.links[9]);
			}
			trace(currentWeekData.links);
		}
	}

	var tweenDifficulty:FlxTween;
	function changeDifficulty(change:Int = 0):Void
	{
		if (loadedWeeks == null || loadedWeeks.length == 0 || curWeek >= loadedWeeks.length) {
			return;
		}

		try {
			if (tweenSafe != null) tweenSafe.cancel();
			if (tweenCanon != null) tweenCanon.cancel();
			curDifficulty += change;

			if (curDifficulty < 0)
				curDifficulty = Difficulty.list.length-1;
			if (curDifficulty >= Difficulty.list.length)
				curDifficulty = 0;

			WeekData.setDirectoryFromWeek(loadedWeeks[curWeek]);

			var diff:String = Difficulty.getString(curDifficulty, false);
			var newImage:FlxGraphic = null;
			
			// Use safe wrapper to load image
			var imagePath:String = 'menudifficulties/' + Paths.formatToSongPath(diff);
			newImage = safeLoadImage(imagePath);
			
			lastDifficultyName = diff;

			// ENSURE sprDifficulty always has valid graphics
			if (sprDifficulty != null) {
				if (newImage != null && sprDifficulty.graphic != newImage) {
					try {
						sprDifficulty.loadGraphic(newImage);
					} catch (e:Dynamic) {
						trace("✗ Error loading graphic into sprDifficulty: " + e);
						sprDifficulty.makeGraphic(150, 50, 0xFF333333);
					}
				} else if (newImage == null && sprDifficulty.graphic == null) {
					// Fallback: if no image loaded and sprite has no graphic
					trace("WARNING: sprDifficulty has null graphic, creating fallback");
					sprDifficulty.makeGraphic(150, 50, 0xFF333333);
				}

				if(tweenDifficulty != null) tweenDifficulty.cancel();

				sprDifficulty.x = 519;
				sprDifficulty.y = 484;
				sprDifficulty.scale.set(1.0, 1.0);
				sprDifficulty.antialiasing = true;
				if (canonGlitch != null) canonGlitch.visible = false;

				if (lastDifficultyName == "canon") {
					sprDifficulty.antialiasing = false;	
					sprDifficulty.scale.set(1.1, 1.1);
					if (leftArrow != null) sprDifficulty.y = leftArrow.y - 15;
					if (canonGlitch != null) canonGlitch.visible = true;
					if (safeInfo != null) safeInfo.alpha = 0;
					if (canonInfo != null) canonInfo.alpha = 1;

					if (canonInfo != null) tweenCanon = FlxTween.tween(canonInfo, { alpha: 0 }, 2);
					if (tweenSafe != null) {
						tweenSafe.cancel();
						if (canonInfo != null) canonInfo.alpha = 1; 
					}
				} 
				else if (lastDifficultyName == "safe") {
					sprDifficulty.antialiasing = false;	
					sprDifficulty.scale.set(1.1, 1.1);
					if (leftArrow != null) sprDifficulty.y = leftArrow.y - 15;
					if (canonGlitch != null) canonGlitch.visible = false;
					if (safeInfo != null) safeInfo.alpha = 1;
					if (canonInfo != null) canonInfo.alpha = 0;

					if (safeInfo != null) tweenSafe = FlxTween.tween(safeInfo, { alpha: 0 }, 2);
					if (tweenCanon != null) {
						tweenCanon.cancel();
						if (safeInfo != null) safeInfo.alpha = 1; 
					}
				}
				else if (lastDifficultyName.startsWith("day")) {
					sprDifficulty.antialiasing = ClientPrefs.data.antialiasing;
					sprDifficulty.scale.set(1.1, 1.1);
					if (leftArrow != null) sprDifficulty.y = leftArrow.y - 15;
					if (canonGlitch != null) canonGlitch.visible = false;
				}

				sprDifficulty.alpha = 1;
				sprDifficulty.visible = true;
				var finalY:Float = (leftArrow != null) ? (leftArrow.y - 15) : 484;
				sprDifficulty.y = finalY + 40;
				if(tweenDifficulty != null) tweenDifficulty.cancel();
				tweenDifficulty = FlxTween.tween(sprDifficulty, {y: finalY, alpha: 1}, 0.07, {onComplete: function(twn:FlxTween)
				{
					tweenDifficulty = null;
				}});
			}
			
			if (sprDifficulty != null) {
				sprDifficulty.alpha = 1;
				sprDifficulty.visible = true;
			}

			#if !switch
			if (loadedWeeks != null && loadedWeeks.length > curWeek) {
				intendedScore = Highscore.getWeekScore(loadedWeeks[curWeek].fileName, curDifficulty);
			}
			#end
		} catch (e:Dynamic) {
			trace("✗ ERROR in changeDifficulty(): " + e);
		}
	}

	var lerpScore:Int = 0;
	var intendedScore:Int = 0;

	// SAFE ASSET LOADING WRAPPER
	private function safeLoadImage(path:String):FlxGraphic
	{
		try {
			trace("Attempting to load image: " + path);
			// Evitar placeholders con una asset key inexistente: algunos targets
			// intentan resolverla otra vez durante draw() y producen Null Object.
			if (!Paths.fileExists('images/' + path + '.png', IMAGE))
			{
				trace("⚠ Optional image missing: " + path);
				return null;
			}
			var graphic = Paths.image(path);
			if (graphic != null) {
				trace("✓ Successfully loaded: " + path);
				return graphic;
			} else {
				trace("✗ Image is null: " + path);
				return null;
			}
		} catch (e:Dynamic) {
			trace("✗ Error loading image " + path + ": " + e);
			return null;
		}
	}

	function changeWeek(change:Int = 0):Void
	{
		if (loadedWeeks == null || loadedWeeks.length == 0) {
			return;
		}

		try {
			curWeek += change;
			cancelStoryPreview();
			if (musicLoadTimer != null) musicLoadTimer.cancel();

			if (curWeek >= loadedWeeks.length)
				curWeek = 0;
			if (curWeek < 0)
				curWeek = loadedWeeks.length - 1;

			var leWeek:WeekData = loadedWeeks[curWeek];
			WeekData.setDirectoryFromWeek(leWeek);

			var leName:String = Language.getPhrase('storyname_${leWeek.fileName}', leWeek.storyName);
			if (txtWeekTitle != null) {
				txtWeekTitle.text = leName.toUpperCase();
				txtWeekTitle.x = FlxG.width - (txtWeekTitle.width + 9);
			}

			var unlocked:Bool = !weekIsLocked(leWeek.fileName);
			if (leWeek.notPlayable){
				unlocked = true;
			}
			if (grpWeekText != null) {
				for (num => item in grpWeekText.members)
				{
					item.alpha = 0.6;
					if (num - curWeek == 0 && unlocked)
						item.alpha = 1;
				}
			}


			var currentWeek:WeekData = loadedWeeks[curWeek];
			var menuMusic:String = 'menusongold';
			
			if (currentWeek != null && currentWeek.menuMusic != null && currentWeek.menuMusic.length > 0) {
				var customMusic:String = currentWeek.menuMusic;
				
				if (StringTools.startsWith(customMusic, 'assets/')) {
					customMusic = customMusic.substr(7);
				}
				if (StringTools.startsWith(customMusic, 'shared/music/')) {
					customMusic = customMusic.substr(13);
				}
				
				var musicFile:String = 'assets/shared/music/' + customMusic + '.ogg';
				if (FileSystem.exists(musicFile)) {
					menuMusic = customMusic;
				}
			}
			
			var immediateMusic = firstChanged;
			firstChanged = false;
			if (currentPlayingMusic != menuMusic) {
				var selectedMusic = menuMusic;
				var selectedFolder = Mods.currentModDirectory;
				var selection = previewRequest;
				function playSelectedMusic():Void {
					if (movedBack || selectedWeek || selection != previewRequest) return;
					var position = immediateMusic || FlxG.sound.music == null ? 0 : FlxG.sound.music.time;
					var previousFolder = Mods.currentModDirectory;
					Mods.currentModDirectory = selectedFolder;
					try {
						FlxG.sound.playMusic(Paths.music(selectedMusic));
						currentPlayingMusic = selectedMusic;
						var isCMENU = selectedMusic.startsWith('story/CMENU')
							|| (selectedMusic.length >= 5 && selectedMusic.length <= 6 && selectedMusic.startsWith('CMENU'));
						if (isCMENU && FlxG.sound.music != null && position < FlxG.sound.music.length)
							FlxG.sound.music.time = position;
					} catch (e:Dynamic) {
						trace("Error loading story music " + selectedMusic + ": " + e);
					}
					Mods.currentModDirectory = previousFolder;
				}
				if (immediateMusic) playSelectedMusic();
				else musicLoadTimer = new FlxTimer().start(0.15, _ -> playSelectedMusic());
			}

			if (video != null) {
				var request = previewRequest;
				videoLoadTimer = new FlxTimer().start(2, function(_) {
					if (request != previewRequest || movedBack || selectedWeek) return;
					var videoPath = storyVideoPath(currentWeek);
					if (videoPath == '') return;
					bindStoryVideoCallbacks();
					var rewind = currentLoadedVideo == videoPath;
					if (!rewind && !loadStoryVideo(videoPath)) return;
					videoTimer = new FlxTimer().start(0.1, function(_) {
						if (request != previewRequest || movedBack || selectedWeek || video == null) return;
						videoRevealPending = true;
						videoFramesUntilReveal = 5;
						if (rewind && video.bitmap != null) video.bitmap.time = 0;
						previewPlaying = video.play();
						if (!previewPlaying) videoRevealPending = false;
					});
				});
			}

		PlayState.storyWeek = curWeek;

		try {
			Difficulty.loadFromWeek();
			trace("✓ Difficulty.loadFromWeek() OK");
		} catch (e:Dynamic) {
			trace("✗ Error in Difficulty.loadFromWeek(): " + e);
		}
		
		var diffStr:String = '';
		try {
			var currentWeekData = WeekData.getCurrentWeek();
			if (currentWeekData != null) {
				diffStr = currentWeekData.difficulties;
			}
		} catch (e:Dynamic) {
			trace("✗ Error getting week difficulties: " + e);
			diffStr = '';
		}
		if(diffStr != null) diffStr = diffStr.trim();
		
		if (difficultySelectors != null) {
			difficultySelectors.visible = true;
		}
		if (sprDifficulty != null) {
			sprDifficulty.visible = true;
		}

		if(diffStr != null && diffStr.length > 0)
		{
			var diffs:Array<String> = diffStr.split(',');
			var i:Int = diffs.length - 1;
			while (i > 0)
			{
				if(diffs[i] != null)
				{
					diffs[i] = diffs[i].trim();
					if(diffs[i].length < 1) diffs.remove(diffs[i]);
				}
				--i;
			}

			if(diffs.length > 0 && diffs[0].length > 0)
			{
				Difficulty.list = diffs;
			}
		}
		
		if(Difficulty.list.contains(Difficulty.getDefault()))
		{
			curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(Difficulty.getDefault())));
		}
		else
		{
			curDifficulty = 0;
		}

		var newPos:Int = Difficulty.list.indexOf(lastDifficultyName);
		if(newPos > -1)
		{
			curDifficulty = newPos;
		}
		updateText();
		} catch (e:Dynamic) {
			trace("✗ ERROR in changeWeek(): " + e);
		}
	}

	function weekIsLocked(name:String):Bool {
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		if (leWeek == null) return true;
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!weekCompleted.exists(leWeek.weekBefore) || !weekCompleted.get(leWeek.weekBefore)));
	}

	function updateText()
	{
		if (loadedWeeks != null && loadedWeeks.length > curWeek && loadedWeeks[curWeek] != null) {
			if (!loadedWeeks[curWeek].notPlayable){
				var weekArray:Array<String> = loadedWeeks[curWeek].weekCharacters;

				var leWeek:WeekData = loadedWeeks[curWeek];
				var stringThing:Array<String> = [];
				for (i in 0...leWeek.songs.length) {
					stringThing.push(leWeek.songs[i][0]);
				}

				#if !switch
					intendedScore = Highscore.getWeekScore(loadedWeeks[curWeek].fileName, curDifficulty);
				#end
			}
		}
	}

	function cancelStoryPreview():Void {
		previewRequest++;
		previewPlaying = false;
		videoRevealPending = false;
		videoFramesUntilReveal = 0;
		if (videoLoadTimer != null) videoLoadTimer.cancel();
		if (videoTimer != null) videoTimer.cancel();
		if (videoFadeTimer != null) videoFadeTimer.cancel();
		if (timerNoise != null) timerNoise.cancel();
		if (tweenVideo != null) tweenVideo.cancel();
		if (tweenNoise != null) tweenNoise.cancel();
		if (video != null) {
			video.pause();
			video.alpha = 0;
		}
		if (noise != null) noise.alpha = 1;
	}

	function storyVideoPath(week:WeekData):String {
		if (week == null || week.menuVideo == null || week.menuVideo.length == 0) return '';
		var name = week.menuVideo;
		var path = name.startsWith('assets/') ? name + '.mp4'
			: (name.indexOf('/') != -1 ? 'assets/' + name + '.mp4' : 'assets/videos/' + name + '.mp4');
		if (!FileSystem.exists(path) && name.indexOf('/') == -1)
			path = 'assets/videos/story/' + name + '.mp4';
		if (!FileSystem.exists(path)) return '';
		var entry:Dynamic = Reflect.field(storyPreviewFiles, path);
		if (entry != null) {
			var preview:String = entry.preview;
			if (preview != null && FileSystem.exists(preview)) {
				var originalInfo = FileSystem.stat(path);
				var previewInfo = FileSystem.stat(preview);
				if (originalInfo.size == entry.sourceSize && originalInfo.mtime.getTime() <= previewInfo.mtime.getTime())
					return preview;
			}
		}
		return path;
	}

	function bindStoryVideoCallbacks():Void {
		if (videoCallbacksBound || video == null || video.bitmap == null) return;
		video.bitmap.onFormatSetup.add(function() {
			if (video == null || video.bitmap == null || video.bitmap.bitmapData == null || movedBack || selectedWeek) return;
			video.setGraphicSize(767, 430);
			video.updateHitbox();
			video.y = 35;
			video.screenCenter(X);
			video.visible = true;
		});
		video.bitmap.onEndReached.add(function() {
			if (!previewPlaying || video == null) return;
			previewPlaying = false;
			videoRevealPending = false;
			video.pause();
			if (videoFadeTimer != null) videoFadeTimer.cancel();
			if (timerNoise != null) timerNoise.cancel();
			var request = previewRequest;
			timerNoise = new FlxTimer().start(1.5, function(_) {
				if (request == previewRequest && !movedBack && !selectedWeek && noise != null)
					tweenNoise = FlxTween.tween(noise, {alpha: 1}, 1.5);
			});
		});
		video.bitmap.onDisplay.add(function() {
			if (!videoRevealPending || !previewPlaying || movedBack || selectedWeek) return;
			if (videoFramesUntilReveal > 0) {
				videoFramesUntilReveal--;
				return;
			}
			videoRevealPending = false;
			if (videoFadeTimer != null) videoFadeTimer.cancel();
			var request = previewRequest;
			// Leave VLC's frame callback before pausing the decoder.
			videoFadeTimer = new FlxTimer().start(0.001, function(_) {
				if (request != previewRequest || movedBack || selectedWeek || video == null || !previewPlaying) return;
				video.pause();
				videoFadeTimer = new FlxTimer().start(2, function(_) {
					if (request != previewRequest || movedBack || selectedWeek || video == null || !previewPlaying) return;
					video.resume();
					if (noise != null) tweenNoise = FlxTween.tween(noise, {alpha: 0}, 1);
					tweenVideo = FlxTween.tween(video, {alpha: 1}, 1);
				});
			});
		});
		videoCallbacksBound = true;
	}

	function loadStoryVideo(videoPath:String):Bool {
		if (video == null) return false;
		try {
			var loaded = video.load(videoPath, STORY_VIDEO_OPTIONS);
			currentLoadedVideo = loaded ? videoPath : '';
			return loaded;
		} catch (e:Dynamic) {
			currentLoadedVideo = '';
			trace("Error loading story preview: " + e);
			return false;
		}
	}

	override function destroy():Void
	{
		cancelStoryPreview();
		if (musicLoadTimer != null) musicLoadTimer.cancel();
		if (tweenSafe != null) tweenSafe.cancel();
		if (tweenCanon != null) tweenCanon.cancel();
		if (tweenNoise != null) tweenNoise.cancel();
		if (tweenVideo != null) tweenVideo.cancel();
		if (tweenDifficulty != null) tweenDifficulty.cancel();

		currentLoadedVideo = '';
		videoRevealPending = false;
		videoFramesUntilReveal = 0;
		if (video != null)
		{
			video.stop();
			remove(video, true);
			video.destroy();
			video = null;
		}

		super.destroy();
	}
}
