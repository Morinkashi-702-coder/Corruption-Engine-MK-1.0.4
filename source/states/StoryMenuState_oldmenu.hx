	package states;
	// here was APlayer


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

	class StoryMenuState_oldmenu extends MusicBeatState
	{
		public static var weekCompleted:Map<String, Bool> = new Map<String, Bool>();
		var firstChanged:Bool = true;

		var scoreText:FlxText;
		var jsonData:Dynamic;

		private static var lastDifficultyName:String = '';
		var curDifficulty:Int = 1;

		var txtWeekTitle:FlxText;

		private static var curWeek:Int = 0;

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

		var selectionArrowLEFT:FlxSprite;
		var selectionArrowRIGHT:FlxSprite;
		var playableTxt:FlxSprite;
		var watchableTxt:FlxSprite;
		var victim:FlxSprite;
		var video:FlxVideoSprite;

		var noise:FlxSprite;

		var blackImage:FlxSprite;

		var loadedWeeks:Array<WeekData> = [];

		var oldMusicPosition:Float;
		
		var currentPlayingMusic:String = ""; // Para no reiniciar la música si es la misma

		override function create()
		{
			try {
				createMenu();
			} catch (e:Dynamic) {
				trace('ERROR in StoryMenuState_oldmenu.create(): $e');
				// Crear un menú simple de emergencia si todo falla
				var bgBlack:FlxSprite = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
				add(bgBlack);
				
				var errorText:FlxText = new FlxText(0, FlxG.height / 2, FlxG.width, 'ERROR LOADING STORY MENU\nPress ESC to go back', 32);
				errorText.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, CENTER);
				errorText.scrollFactor.set();
				add(errorText);
			}
			super.create();
		}
		
		function createMenu()
		{

			PlayState.isStoryMode = true;
			WeekData.reloadWeekFiles(true);
			if(curWeek >= WeekData.weeksList.length) curWeek = 0;
			persistentUpdate = persistentDraw = true;

			var bgBlack:FlxSprite = new FlxSprite(0, 56).makeGraphic(FlxG.width, 386, FlxColor.BLACK); //bgYellow and menu characters are no longer needed

			video = new FlxVideoSprite(0, 0);
			video.antialiasing = false;

			// Preloading Videos Folder
			if (FileSystem.exists('assets/videos/story')) {
				var videoFolder = FileSystem.readDirectory('assets/videos/story');
				if (videoFolder != null){
					for (file in videoFolder) {
						video.load('assets/videos/story/' + file);
					}
					trace("Loaded videos: " + videoFolder);
				} else {
					trace('Videos folder is null');
				}
			} else {
				trace('Videos folder does not exist');
			}

			// Preloading Music Folder
			if (FileSystem.exists('assets/music/story')) {
				var musicFolder = FileSystem.readDirectory('assets/music/story');
				if (musicFolder != null) {
					for (file in musicFolder) {
						if (file.endsWith(".ogg")) {
							var filenameWithoutExt = file.substring(0, file.length - 4);
							FlxG.sound.load(Paths.music("story/" + filenameWithoutExt));
							trace(filenameWithoutExt + " was loaded");
						} else {
							trace("This isn't a music file " + file);
						}
					}
				} else {
					trace('Music folder is null');
				}
			} else {
				trace('Music folder does not exist');
			}

			// i thought width is 1920 and height is 555, lol
			noise = new FlxSprite(-385, -256.5).loadGraphic(Paths.image('WarningThisAssetIsLicenced'), true);
			noise.frames = Paths.getSparrowAtlas('WarningThisAssetIsLicenced');
			noise.setGraphicSize(2050);// in demo is 2050, not 2049, as in image
			noise.scale.y = 0.5;
			noise.animation.addByPrefix('idle', 'noising', 24);
			noise.animation.play('idle');
			noise.antialiasing = ClientPrefs.data.antialiasing;
			noise.alpha = 1;

			scoreText = new FlxText(11, 11, 0, "SCORE: 49324858", 36);
			scoreText.setFormat("VCR OSD Mono", 32);

			txtWeekTitle = new FlxText((FlxG.width * 0.7), 11, 0, "", 32);
			txtWeekTitle.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, RIGHT);
			txtWeekTitle.alpha = 0.7;

			var ui_tex = Paths.getSparrowAtlas('campaign_menu_UI_assets');

			#if desktop
			// Updating Discord Rich Presence
			DiscordClient.changePresence("In the Menus", null);
			#end

		

			// Create groups BEFORE the loop
			grpWeekText = new FlxTypedGroup<MenuItem>();
			grpLocks = new FlxTypedGroup<FlxSprite>();

			var num:Int = 0;
			for (i in 0...WeekData.weeksList.length)
			{
				var weekFile:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
				var isLocked:Bool;
				if (!weekFile.notPlayable){
					isLocked = weekIsLocked(WeekData.weeksList[i]); 
				} else {
					// It doesn't make sense to leave a week closed that you can't play.
					isLocked = false;
					weekFile.hiddenUntilUnlocked = false; 
				}
				// Load week if: (not locked) OR (locked but not hidden)
				var shouldLoad:Bool = !isLocked || (isLocked && !weekFile.hiddenUntilUnlocked);
				if(shouldLoad)
				{
					loadedWeeks.push(weekFile);
					WeekData.setDirectoryFromWeek(weekFile);
					
				var weekThing:MenuItem = new MenuItem(0, 0, WeekData.weeksList[i]);
				weekThing.x = 10;
				var baseY:Float = 480; // Position base - moved down 60 pixels total
				weekThing.y = baseY + ((weekThing.height + 20) * num);
				weekThing.ID = num;
				grpWeekText.add(weekThing);

				weekThing.antialiasing = ClientPrefs.data.antialiasing;
				weekThing.updateHitbox();

					// Needs an offset thingie
					if (isLocked)
					{
						var lock:FlxSprite = new FlxSprite(weekThing.width + 10 + weekThing.x);
						lock.ID = i;
						lock.antialiasing = ClientPrefs.data.antialiasing;
						grpLocks.add(lock);
					}
					num++;
				}
			}

			// Add groups to display after loop so MenuItems are populated
			add(grpWeekText);

			var blackBarThingie:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 56, FlxColor.BLACK);
			add(blackBarThingie);

			add(grpLocks);

			WeekData.setDirectoryFromWeek(loadedWeeks[0]);

			difficultySelectors = new FlxGroup();
			// NO agregar difficultySelectors aquí aún

			leftArrow = new FlxSprite(100, 500); // Fixed position for difficulty selector reference
			leftArrow.antialiasing = ClientPrefs.data.antialiasing;
			leftArrow.alpha = 0;
			difficultySelectors.add(leftArrow);

			selectionArrowLEFT = new FlxSprite(429, 469).loadGraphic(Paths.image('selectionArrowLEFT'));
			selectionArrowLEFT.scale.set(1, 0.8);
			selectionArrowLEFT.antialiasing = ClientPrefs.data.antialiasing;
			add(selectionArrowLEFT);

			selectionArrowRIGHT = new FlxSprite(805, 469).loadGraphic(Paths.image('selectionArrowRIGHT'));
			selectionArrowRIGHT.scale.set(1, 0.8);
			selectionArrowRIGHT.antialiasing = ClientPrefs.data.antialiasing;
			add(selectionArrowRIGHT);

			playableTxt = new FlxSprite(894, 480).loadGraphic(Paths.image('playable'));
			playableTxt.antialiasing = false;
			playableTxt.visible = false;
			add(playableTxt);

			watchableTxt = new FlxSprite(894, 480).loadGraphic(Paths.image('watchable'));
			watchableTxt.antialiasing = false;
			watchableTxt.visible = false;
			add(watchableTxt);

			// Updated for 1.0.4 Difficulty system
			Difficulty.resetList();
			if(lastDifficultyName == '')
			{
				lastDifficultyName = Difficulty.getDefault();
			}
			curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(lastDifficultyName)));
			
			sprDifficulty = new FlxSprite(500, 484);
			sprDifficulty.makeGraphic(150, 50, 0xFF333333); // Placeholder while loading
			sprDifficulty.antialiasing = false;
			sprDifficulty.visible = true;
			difficultySelectors.add(sprDifficulty);

			canonGlitchEffect = new FlxGlitchEffect();
			canonGlitchEffect.size = 5;
			canonGlitchEffect.delay = 0.1;
			canonGlitchEffect.strength = 5;

			safeInfo = new FlxSprite(519, 569).loadGraphic(Paths.image('safeInfo'));
			safeInfo.antialiasing = false;
			safeInfo.alpha = 0;

			canonInfo = new FlxSprite(519, 569).loadGraphic(Paths.image('canonInfo'));
			canonInfo.antialiasing = false;
			canonInfo.alpha = 0;

			canonGlitch = new FlxEffectSprite(sprDifficulty, [canonGlitchEffect]);
			canonGlitch.scale.x = 1.1;
			canonGlitch.scale.y = 1.1;
			canonGlitch.x = 509;
			canonGlitch.y = 484;
			canonGlitch.visible = false;
			difficultySelectors.add(canonGlitch);

			victim = new FlxSprite().loadGraphic(Paths.image('selectyourvictim'));
			victim.visible = false;
			victim.screenCenter();
			victim.antialiasing = ClientPrefs.data.antialiasing;

			var glitchEffect:FlxGlitchEffect = new FlxGlitchEffect();
			glitchEffect.size = 5;
			glitchEffect.delay = 0.1;
			glitchEffect.strength = 5;

			var Glitch = new FlxEffectSprite (victim, [glitchEffect]);
			Glitch.scale.x = 0.7;
			Glitch.scale.y = 0.7;
			Glitch.x = -325;
			Glitch.y = -180;		
			
			blackImage = new FlxSprite();
			blackImage.makeGraphic(1280, 720, FlxColor.BLACK);
			blackImage.screenCenter();
			blackImage.alpha = 1; // Start fully visible

			add(bgBlack);
			add(video);
			add(noise);
			add(scoreText);
			add(txtWeekTitle);
			add(difficultySelectors); // Add BEFORE blackImage so it's behind
			add(safeInfo);
			add(canonInfo);
			add(blackImage); // Add AFTER difficulty so black is on top
			add(victim);
			add(Glitch);

		
		


			new FlxTimer().start(2, function(tmr) {
				FlxTween.tween(victim, { alpha: 0 }, 1.5);
				FlxTween.tween(blackImage, { alpha: 0 }, 1.5);
			});

			changeWeek();
			changeDifficulty();
		}

		override function closeSubState() {
			persistentUpdate = true;
			changeWeek();
			super.closeSubState();
		}

		override function update(elapsed:Float)
		{		
			if (!loadedWeeks[curWeek].notPlayable){
				watchableTxt.visible = false;
				playableTxt.visible = true;
			} else {
				watchableTxt.visible = true;
				playableTxt.visible = false;
			}
			// scoreText.setFormat('VCR OSD Mono', 32);
			lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, FlxMath.bound(elapsed * 30, 0, 1)));
			if(Math.abs(intendedScore - lerpScore) < 10) lerpScore = intendedScore;
			if (!loadedWeeks[curWeek].notPlayable){
				scoreText.text = "WEEK SCORE:" + lerpScore;
			} else {
				scoreText.text = "WEEK SCORE:0";
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
				canonGlitch.setPosition(sprDifficulty.x, sprDifficulty.y);
				canonGlitch.alpha = sprDifficulty.alpha;
			}

			if (canonInfo.alpha > 0 && lastDifficultyName == "safe") {
				canonInfo.visible = false;
				safeInfo.visible = true;
			} else if (safeInfo.alpha > 0 && lastDifficultyName == "canon") {
				canonInfo.visible = true;
				safeInfo.visible = false;
			}

			if (!movedBack && !selectedWeek)
			{
				var upP = controls.UI_UP_P;
				var downP = controls.UI_DOWN_P;
				if (upP)
				{
					video.stop();
					video.alpha = 0;
					noise.alpha = 1;
					changeWeek(-1);
					FlxG.sound.play(Paths.sound('scrollMenu'));
				}

				if (downP)
				{
					video.stop();
					video.alpha = 0;
					noise.alpha = 1;
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
			// Transición de zoom acercándose al salir - ir directo al menú principal
			FlxTween.tween(FlxG.camera, {zoom: 1.3}, 0.5, {ease: FlxEase.backIn});
			// Bajar música suavemente al regresar
			FlxTween.tween(FlxG.sound.music, {volume: 0.7}, 0.5, {ease: FlxEase.expoOut});
			new FlxTimer().start(0.5, function(tmr:FlxTimer) {
				MusicBeatState.switchState(new MainMenuState_oldmenu());
			});
		}			super.update(elapsed);

			grpLocks.forEach(function(lock:FlxSprite)
			{
				lock.y = grpWeekText.members[lock.ID].y;
				lock.visible = (lock.y > FlxG.height / 2);
			});
		}

		var movedBack:Bool = false;
		var selectedWeek:Bool = false;
		var stopspamming:Bool = false;

		function selectWeek()
		{
			if (!loadedWeeks[curWeek].notPlayable){
				if (!weekIsLocked(loadedWeeks[curWeek].fileName))
				{
					if (stopspamming == false)
					{
						FlxG.sound.play(Paths.sound('confirmMenu'));
						stopspamming = true;
					}

					// We can't use Dynamic Array .copy() because that crashes HTML5, here's a workaround.
					var songArray:Array<String> = [];
					var leWeek:Array<Dynamic> = loadedWeeks[curWeek].songs;
					for (i in 0...leWeek.length) {
						songArray.push(leWeek[i][0]);
					}

					// Nevermind that's stupid lmao
					PlayState.storyPlaylist = songArray;
					PlayState.isStoryMode = true;
					selectedWeek = true;

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
				if (loadedWeeks[curWeek].playlist != null){
					var link = loadedWeeks[curWeek].playlist;
					if (link != null) {
						trace("Playlist isn't null: " + link);
					} else {
						loadedWeeks[curWeek].playlist = "None";
					}
				} else {
					loadedWeeks[curWeek].playlist = "None";
				}
				if (loadedWeeks[curWeek].links != null) {
					for (i in 0...10) {
						var link = loadedWeeks[curWeek].links[i];
						if (link != null) {
							// Remove the [] characters from the string so that it works correctly (after all, who would like just an open new browser, lol)
							loadedWeeks[curWeek].links[i] = link.split("[").join("").split("]").join("");
						} else {
							loadedWeeks[curWeek].links[i] = "None";
						}
					}
					trace("All links have been cleaned.");
				} else {
					loadedWeeks[curWeek].links = [];
					for (i in 0...10) {
						loadedWeeks[curWeek].links[i] = "None";
					}
				}
				
				// It's stupid, but I'm dumb to redo it
				// Diff day0 is playlist
				if (lastDifficultyName == 'day0'){
					CoolUtil.browserLoad(loadedWeeks[curWeek].playlist);
				} else if (lastDifficultyName == 'day1'){
					CoolUtil.browserLoad(loadedWeeks[curWeek].links[0]);
				} else if (lastDifficultyName == 'day2'){
					CoolUtil.browserLoad(loadedWeeks[curWeek].links[1]);
				} else if (lastDifficultyName == 'day3'){
					CoolUtil.browserLoad(loadedWeeks[curWeek].links[2]);
				} else if (lastDifficultyName == 'day4') {
					CoolUtil.browserLoad(loadedWeeks[curWeek].links[3]);
				} else if (lastDifficultyName == 'day5') {
					CoolUtil.browserLoad(loadedWeeks[curWeek].links[4]);
				} else if (lastDifficultyName == 'day6') {
					CoolUtil.browserLoad(loadedWeeks[curWeek].links[5]);
				} else if (lastDifficultyName == 'day7') {
					CoolUtil.browserLoad(loadedWeeks[curWeek].links[6]);
				} else if (lastDifficultyName == 'day8') {
					CoolUtil.browserLoad(loadedWeeks[curWeek].links[7]);
				} else if (lastDifficultyName == 'day9') {
					CoolUtil.browserLoad(loadedWeeks[curWeek].links[8]);
				} else {
					CoolUtil.browserLoad(loadedWeeks[curWeek].links[9]);
				}
				trace(loadedWeeks[curWeek].links);
			}
		}

		var tweenDifficulty:FlxTween;
		function changeDifficulty(change:Int = 0):Void
		{
			curDifficulty += change;

			if (curDifficulty < 0)
				curDifficulty = Difficulty.list.length-1;
			if (curDifficulty >= Difficulty.list.length)
				curDifficulty = 0;

			WeekData.setDirectoryFromWeek(loadedWeeks[curWeek]);

			var diff:String = Difficulty.getString(curDifficulty, false);
			var newImage:FlxGraphic = Paths.image('menudifficulties/' + Paths.formatToSongPath(diff));
			
			lastDifficultyName = diff;

			if(sprDifficulty.graphic != newImage)
			{
				try {
					sprDifficulty.loadGraphic(newImage);
				} catch (e:Dynamic) {
					trace("Error loading difficulty image: " + e);
				}

				if(tweenDifficulty != null) tweenDifficulty.cancel();

				// Set default position and scale for all difficulties
				sprDifficulty.x = 519;
				sprDifficulty.y = 484;
				sprDifficulty.scale.set(1.0, 1.0);
				sprDifficulty.antialiasing = true;
				canonGlitch.visible = false;

				// Handle special difficulties (canon/safe)
				if (lastDifficultyName == "canon") {
					sprDifficulty.antialiasing = false;	
					sprDifficulty.scale.set(1.1, 1.1);
					sprDifficulty.y = leftArrow.y - 15;
					canonGlitch.visible = true;
					safeInfo.alpha = 0;
					canonInfo.alpha = 1;

					tweenCanon = FlxTween.tween(canonInfo, { alpha: 0 }, 2);
					if (tweenSafe != null) {
						tweenSafe.cancel();
						canonInfo.alpha = 1; 
					}
				} 
				else if (lastDifficultyName == "safe") {
					sprDifficulty.antialiasing = false;	
					sprDifficulty.scale.set(1.1, 1.1);
					sprDifficulty.y = leftArrow.y - 15;
					canonGlitch.visible = false;
					safeInfo.alpha = 1;
					canonInfo.alpha = 0;

					tweenSafe = FlxTween.tween(safeInfo, { alpha: 0 }, 2);
					if (tweenCanon != null) {
						tweenCanon.cancel();
						safeInfo.alpha = 1; 
					}
				}
				// Day difficulties
				else if (lastDifficultyName.startsWith("day")) {
					sprDifficulty.antialiasing = ClientPrefs.data.antialiasing;
					sprDifficulty.scale.set(1.1, 1.1);
					sprDifficulty.y = leftArrow.y - 15;
					canonGlitch.visible = false;
				}

				sprDifficulty.alpha = 1;
				sprDifficulty.visible = true;
				// Start 40 pixels lower, then animate to final position
				var finalY:Float = leftArrow.y - 15; // Final position (485)
				sprDifficulty.y = finalY + 40; // Start 40 pixels below (525)
				if(tweenDifficulty != null) tweenDifficulty.cancel();
				tweenDifficulty = FlxTween.tween(sprDifficulty, {y: finalY, alpha: 1}, 0.07, {onComplete: function(twn:FlxTween)
				{
					tweenDifficulty = null;
				}});
			}
			
			// Ensure sprDifficulty is always visible
			sprDifficulty.alpha = 1;
			sprDifficulty.visible = true;

			#if !switch
			intendedScore = Highscore.getWeekScore(loadedWeeks[curWeek].fileName, curDifficulty);
			#end
		}

		var lerpScore:Int = 0;
		var intendedScore:Int = 0;

		function changeWeek(change:Int = 0):Void
		{
			// trace("=== CHANGEWEEK START ===");
			// trace("Change: " + change);
			curWeek += change;

			if (timerNoise != null) {
				timerNoise.cancel();
				timerNoise = null;
			}
			FlxTween.cancelTweensOf(video);
			FlxTween.cancelTweensOf(noise);

			if (noise.alpha < 1){
				noise.alpha = 1;
			}

			if (curWeek >= loadedWeeks.length)
				curWeek = 0;
			if (curWeek < 0)
				curWeek = loadedWeeks.length - 1;

			var leWeek:WeekData = loadedWeeks[curWeek];
			WeekData.setDirectoryFromWeek(leWeek);

			var leName:String = Language.getPhrase('storyname_${leWeek.fileName}', leWeek.storyName);
			txtWeekTitle.text = leName.toUpperCase();
			txtWeekTitle.x = FlxG.width - (txtWeekTitle.width + 9);

			var bullShit:Int = 0;

			var unlocked:Bool = !weekIsLocked(leWeek.fileName);
			if (leWeek.notPlayable){
				unlocked = true; // It doesn't make sense to leave a week closed that you can't play
			}
			for (num => item in grpWeekText.members)
			{
				item.alpha = 0.6;
				if (num - curWeek == 0 && unlocked)
					item.alpha = 1;
				
				// Animate position based on selection
				var baseY:Float = 480; // Moved down 60 pixels total
				var targetY:Float = baseY + ((item.height + 20) * (num - curWeek));
				FlxTween.tween(item, {y: targetY}, 0.6, {ease: FlxEase.cubeInOut});
			}

			if (firstChanged){	
				oldMusicPosition = 0.0;
				firstChanged = false;
			} else {
				oldMusicPosition = FlxG.sound.music != null ? FlxG.sound.music.time : 0.0;
				firstChanged = false;
			}

			// Música dinámica: usa menuMusic del JSON de la week actual
			var currentWeek:WeekData = loadedWeeks[curWeek];
			var menuMusic:String = 'menusongold'; // Por defecto
			
			if (currentWeek != null && currentWeek.menuMusic != null && currentWeek.menuMusic.length > 0) {
				var customMusic:String = currentWeek.menuMusic;
				
				// Quitar prefijos innecesarios
				if (StringTools.startsWith(customMusic, 'assets/')) {
					customMusic = customMusic.substr(7);
				}
				if (StringTools.startsWith(customMusic, 'shared/music/')) {
					customMusic = customMusic.substr(13);
				}
				
				// Verificar si el archivo existe antes de usarlo
				var musicFile:String = 'assets/shared/music/' + customMusic + '.ogg';
				if (FileSystem.exists(musicFile)) {
					menuMusic = customMusic;
				}
			}
			
			// Check si es una CMENU (0-9)
			var isCMENU:Bool = StringTools.startsWith(menuMusic, 'story/CMENU') || 
							(menuMusic.length >= 5 && menuMusic.length <= 6 && StringTools.startsWith(menuMusic, 'CMENU'));
			
		// Solo cambiar música si es diferente a la actual
		if (currentPlayingMusic != menuMusic) {
			currentPlayingMusic = menuMusic;
			FlxG.sound.playMusic(Paths.music(menuMusic));
			
			// Si es CMENU, mantener la posición
			if (isCMENU && FlxG.sound.music != null) {
				FlxG.sound.music.time = oldMusicPosition;
			}
		}			if (videoLoadTimer != null){
				videoLoadTimer.cancel();
				video.revive();
			}

			videoLoadTimer = new FlxTimer().start(2, function(tmr:FlxTimer)
			{
				video.bitmap.onFormatSetup.add(function():Void
				{
					if (video.bitmap != null && video.bitmap.bitmapData != null)
					{
						video.setGraphicSize(767, 430);
						video.x = 9.5;
						video.y = 35;
						noise.alpha = 1;
						video.alpha = 0;
						video.updateHitbox();
						video.screenCenter(X);
					}
				});

				// Video dinámico: usa menuVideo del JSON de la week
				var videoLoaded:Bool = false;
				
				if (currentWeek != null && currentWeek.menuVideo != null && currentWeek.menuVideo.length > 0) {
					var videoPath:String = '';
					var menuVideo:String = currentWeek.menuVideo;
					
					// Si ya empieza con "assets/" es ruta completa
					if (StringTools.startsWith(menuVideo, 'assets/')) {
						videoPath = menuVideo + '.mp4';
						if (FileSystem.exists(videoPath)) {
							videoLoaded = video.load(videoPath);
						}
					}
					// Si contiene "/" es ruta custom (sin assets/)
					else if (menuVideo.indexOf('/') != -1) {
						videoPath = 'assets/' + menuVideo + '.mp4';
						if (FileSystem.exists(videoPath)) {
							videoLoaded = video.load(videoPath);
						}
					} else {
						// Si no, busca primero en assets/videos/
						videoPath = 'assets/videos/' + menuVideo + '.mp4';
						if (FileSystem.exists(videoPath)) {
							videoLoaded = video.load(videoPath);
						} else {
							// Si no existe, busca en assets/videos/story/
							videoPath = 'assets/videos/story/' + menuVideo + '.mp4';
							if (FileSystem.exists(videoPath)) {
								videoLoaded = video.load(videoPath);
							}
						}
					}
				}
				
				if (videoLoaded){
					if (videoTimer != null){
						videoTimer.cancel();
					}
					videoTimer = new FlxTimer().start(0.001, function(tmr:FlxTimer)
					{
						video.play();
						if (noise.alpha == 1){
							new FlxTimer().start(2, function(tmr:FlxTimer)
							{
								tweenNoise = FlxTween.tween(noise, { alpha: 0 }, 1);
								tweenVideo = FlxTween.tween(video, { alpha: 1 }, 1);
							});
						}
					});

					video.bitmap.onEndReached.add(function():Void
					{
						video.stop();
						trace('Video stopped');
						timerNoise = new FlxTimer().start(1.5, function(tmr:FlxTimer)
						{
							tweenNoise = FlxTween.tween(noise, { alpha: 1 }, 1.5);
						});
					});
				}
			});

			PlayState.storyWeek = curWeek;

			// Updated for 1.0.4 Difficulty system
			Difficulty.loadFromWeek();
			var diffStr:String = WeekData.getCurrentWeek().difficulties;
			if(diffStr != null) diffStr = diffStr.trim();
			
			// Always show difficulty selectors (don't hide based on unlock status)
			difficultySelectors.visible = true;
			sprDifficulty.visible = true;

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
		}

		function weekIsLocked(name:String):Bool {
			var leWeek:WeekData = WeekData.weeksLoaded.get(name);
			if (leWeek == null) return true;
			return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!weekCompleted.exists(leWeek.weekBefore) || !weekCompleted.get(leWeek.weekBefore)));
		}

		function updateText()
		{
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
