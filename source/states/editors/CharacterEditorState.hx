package states.editors;

import flixel.graphics.FlxGraphic;

import flixel.system.debug.interaction.tools.Pointer.GraphicCursorCross;
import flixel.util.FlxDestroyUtil;

import openfl.net.FileReference;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.utils.Assets;

import objects.Character;
import objects.HealthIcon;
import objects.Bar;
import backend.StageData;

import states.editors.content.Prompt;
import states.editors.content.PsychJsonPrinter;

class CharacterEditorState extends MusicBeatState implements PsychUIEventHandler.PsychUIEvent
{
	var character:Character;
	var ghost:FlxSprite;
	var animateGhost:FlxAnimate;
	var animateGhostImage:String;
	var toggleSilhouettesButton:PsychUIButton;
	var cameraFollowPointer:FlxSprite;
	var isAnimateSprite:Bool = false;

	var silhouettes:FlxSpriteGroup;
	var stagePreviewGroup:FlxSpriteGroup;
	var stageAssetsHeaderText:FlxText;
	var stageAssetsPageText:FlxText;
	var stageAssetsPrevButton:PsychUIButton;
	var stageAssetsNextButton:PsychUIButton;
	var stageAssetsRefreshButton:PsychUIButton;
	var stageAssetButtons:Array<PsychUIButton> = [];
	var stageAssetPlayButtons:Array<PsychUIButton> = [];
	var stageAssetPlayingIdx:Int = -1;
	var stageAssetEntries:Array<{name:String, spr:FlxSprite}> = [];
	var stageAssetsPage:Int = 0;
	static final STAGE_ASSET_ROWS:Int = 3;
	var dadSilhouette:FlxSprite;
	var boyfriendSilhouette:FlxSprite;
	var dadPosition = FlxPoint.weak();
	var bfPosition = FlxPoint.weak();

	var helpBg:FlxSprite;
	var helpTexts:FlxSpriteGroup;
	var cameraZoomText:FlxText;
	var frameAdvanceText:FlxText;

	var healthBar:Bar;
	var healthIcon:HealthIcon;

	var copiedOffset:Array<Float> = [0, 0];
	var _char:String = null;
	var _goToPlayState:Bool = true;

	var anims = null;
	var animsTxt:FlxText;
	var curAnim = 0;

	private var camEditor:FlxCamera;
	private var camHUD:FlxCamera;

	var UI_box:PsychUIBox;
	var UI_characterbox:PsychUIBox;

	var unsavedProgress:Bool = false;

	var selectedFormat:FlxTextFormat = new FlxTextFormat(FlxColor.LIME);

	public function new(char:String = null, goToPlayState:Bool = true)
	{
		this._char = char;
		this._goToPlayState = goToPlayState;
		if(this._char == null) this._char = Character.DEFAULT_CHARACTER;

		super();
	}

	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();
		initPreviewStage();

		// Verificación segura para detener música
		if (FlxG.sound.music != null) {
			FlxG.sound.music.stop();
		}
		
		camEditor = initPsychCamera();

		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD, false);

		loadBG();

		silhouettes = new FlxSpriteGroup();
		add(silhouettes);

		dadSilhouette = new FlxSprite(dadPosition.x, dadPosition.y).loadGraphic(Paths.image('editors/silhouetteDad'));
		dadSilhouette.antialiasing = ClientPrefs.data.antialiasing;
		dadSilhouette.active = false;
		dadSilhouette.offset.set(-4, 1);
		silhouettes.add(dadSilhouette);

		boyfriendSilhouette = new FlxSprite(bfPosition.x, bfPosition.y + 350).loadGraphic(Paths.image('editors/silhouetteBF'));
		boyfriendSilhouette.antialiasing = ClientPrefs.data.antialiasing;
		boyfriendSilhouette.active = false;
		boyfriendSilhouette.offset.set(-6, 2);
		silhouettes.add(boyfriendSilhouette);

		silhouettes.alpha = 0.25;

		ghost = new FlxSprite();
		ghost.visible = false;
		ghost.alpha = ghostAlpha;
		add(ghost);
		
		animsTxt = new FlxText(10, 32, 400, '');
		animsTxt.setFormat(null, 16, FlxColor.WHITE, LEFT, OUTLINE_FAST, FlxColor.BLACK);
		animsTxt.scrollFactor.set();
		animsTxt.borderSize = 1;
		animsTxt.cameras = [camHUD];

		addCharacter();

		cameraFollowPointer = new FlxSprite().loadGraphic(FlxGraphic.fromClass(GraphicCursorCross));
		cameraFollowPointer.setGraphicSize(40, 40);
		cameraFollowPointer.updateHitbox();

		healthBar = new Bar(30, FlxG.height - 75);
		healthBar.scrollFactor.set();
		healthBar.cameras = [camHUD];

		healthIcon = new HealthIcon(character.healthIcon, false, false);
		healthIcon.y = FlxG.height - 150;
		healthIcon.cameras = [camHUD];

		add(cameraFollowPointer);
		add(healthBar);
		add(healthIcon);
		add(animsTxt);

		var tipText:FlxText = new FlxText(FlxG.width - 300, FlxG.height - 24, 300, "Press F1 for Help", 20);
		tipText.cameras = [camHUD];
		tipText.setFormat(null, 16, FlxColor.WHITE, RIGHT, OUTLINE_FAST, FlxColor.BLACK);
		tipText.borderColor = FlxColor.BLACK;
		tipText.scrollFactor.set();
		tipText.borderSize = 1;
		tipText.active = false;
		add(tipText);

		cameraZoomText = new FlxText(0, 50, 200, 'Zoom: 1x');
		cameraZoomText.setFormat(null, 16, FlxColor.WHITE, CENTER, OUTLINE_FAST, FlxColor.BLACK);
		cameraZoomText.scrollFactor.set();
		cameraZoomText.borderSize = 1;
		cameraZoomText.screenCenter(X);
		cameraZoomText.cameras = [camHUD];
		add(cameraZoomText);

		frameAdvanceText = new FlxText(0, 75, 380, '');
		frameAdvanceText.setFormat(null, 16, FlxColor.WHITE, CENTER, OUTLINE_FAST, FlxColor.BLACK);
		frameAdvanceText.scrollFactor.set();
		frameAdvanceText.borderSize = 1;
		frameAdvanceText.screenCenter(X);
		frameAdvanceText.cameras = [camHUD];
		add(frameAdvanceText);

		addHelpScreen();
		FlxG.mouse.visible = true;
		FlxG.camera.zoom = 1;

		makeUIMenu();
		applyStagePreviewData(selectedStage, false);

		updatePointerPos();
		updateHealthBar();
		character.finishAnimation();

		if(ClientPrefs.data.cacheOnGPU) Paths.clearUnusedMemory();

		super.create();
	}

	function addHelpScreen()
	{
		var str:Array<String> = ["CAMERA",
		"E/Q - Camera Zoom In/Out",
		"J/K/L/I - Move Camera",
		"R - Reset Camera Zoom",
		"",
		"CHARACTER",
		"Ctrl + R - Reset Current Offset",
		"Ctrl + C - Copy Current Offset",
		"Ctrl + V - Paste Copied Offset on Current Animation",
		"Ctrl + Z - Undo Last Paste or Reset",
		"W/S - Previous/Next Animation",
		"Space - Replay Animation",
		"Arrow Keys/Mouse & Right Click - Move Offset",
		"A/D - Frame Advance (Back/Forward)",
		"",
		"OTHER",
		"F12 - Toggle Silhouettes",
		"Hold Shift - Move Offsets 10x faster and Camera 4x faster",
		"Hold Control - Move camera 4x slower"];

		helpBg = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		helpBg.scale.set(FlxG.width, FlxG.height);
		helpBg.updateHitbox();
		helpBg.alpha = 0.6;
		helpBg.cameras = [camHUD];
		helpBg.active = helpBg.visible = false;
		add(helpBg);

		helpTexts = new FlxSpriteGroup();
		helpTexts.cameras = [camHUD];
		for (i => txt in str)
		{
			if(txt.length < 1) continue;

			var helpText:FlxText = new FlxText(0, 0, 600, txt, 16);
			helpText.setFormat(null, 16, FlxColor.WHITE, CENTER, OUTLINE_FAST, FlxColor.BLACK);
			helpText.borderColor = FlxColor.BLACK;
			helpText.scrollFactor.set();
			helpText.borderSize = 1;
			helpText.screenCenter();
			add(helpText);
			helpText.y += ((i - str.length/2) * 32) + 16;
			helpText.active = false;
			helpTexts.add(helpText);
		}
		helpTexts.active = helpTexts.visible = false;
		add(helpTexts);
	}

	function addCharacter(reload:Bool = false)
	{
		var pos:Int = -1;
		if(character != null)
		{
			pos = members.indexOf(character);
			remove(character);
			character.destroy();
		}

		var isPlayer = (reload ? character.isPlayer : !predictCharacterIsNotPlayer(_char));
		character = new Character(0, 0, _char, isPlayer);
		if(!reload && character.editorIsPlayer != null && isPlayer != character.editorIsPlayer)
		{
			character.isPlayer = !character.isPlayer;
			character.flipX = (character.originalFlipX != character.isPlayer);
			if(check_player != null) check_player.checked = character.isPlayer;
		}
		character.debugMode = true;
		character.missingCharacter = false;

		if(pos > -1) insert(pos, character);
		else add(character);
		updateCharacterPositions();
		reloadAnimList();
		if(healthBar != null && healthIcon != null) updateHealthBar();
	}

	function makeUIMenu()
	{
		UI_box = new PsychUIBox(FlxG.width - 275, 25, 250, 160, ['Ghost', 'Settings', 'Stage Assets']);
		UI_box.scrollFactor.set();
		UI_box.cameras = [camHUD];

		UI_characterbox = new PsychUIBox(UI_box.x - 100, UI_box.y + UI_box.height + 10, 350, 280, ['Animations', 'Character']);
		UI_characterbox.scrollFactor.set();
		UI_characterbox.cameras = [camHUD];
		add(UI_characterbox);
		add(UI_box);

		addGhostUI();
		addSettingsUI();
		addStageAssetsUI();
		addAnimationsUI();
		addCharacterUI();

		UI_box.selectedName = 'Settings';
		UI_characterbox.selectedName = 'Character';

	}

	inline function shortenStageAssetName(name:String, maxLen:Int = 22):String
	{
		if(name == null) return 'unknown';
		if(name.length <= maxLen) return name;
		return name.substr(0, maxLen - 3) + '...';
	}

	function buildStageAssetName(spr:FlxSprite, index:Int):String
	{
		var base:String = 'Asset ' + (index + 1);
		if(spr != null && spr.graphic != null && spr.graphic.key != null && spr.graphic.key.length > 0)
		{
			var key:String = spr.graphic.key;
			var fileName:String = haxe.io.Path.withoutDirectory(key);
			if(fileName != null && fileName.length > 0)
				return fileName;
		}

		if(spr != null)
		{
			var clsName:String = Type.getClassName(Type.getClass(spr));
			if(clsName != null)
			{
				var split:Array<String> = clsName.split('.');
				if(split.length > 0) base = split[split.length - 1] + ' #' + (index + 1);
			}
		}
		return base;
	}

	function refreshStageAssetEntries()
	{
		stageAssetEntries = [];
		if(stagePreviewGroup != null && stagePreviewGroup.members != null)
		{
			for (i in 0...stagePreviewGroup.members.length)
			{
				var basic = stagePreviewGroup.members[i];
				if(basic == null || !Std.isOfType(basic, FlxSprite)) continue;

				var spr:FlxSprite = cast basic;
				stageAssetEntries.push({
					name: buildStageAssetName(spr, i),
					spr: spr
				});
			}
		}

		if(stageAssetPlayingIdx >= stageAssetEntries.length)
			stageAssetPlayingIdx = -1;

		var maxPage:Int = Std.int(Math.max(0, Math.ceil(stageAssetEntries.length / STAGE_ASSET_ROWS) - 1));
		if(stageAssetsPage > maxPage) stageAssetsPage = maxPage;
		if(stageAssetsPage < 0) stageAssetsPage = 0;
	}

	function refreshStageAssetsTableUI()
	{
		if(stageAssetsHeaderText == null || stageAssetsPageText == null) return;

		refreshStageAssetEntries();
		stageAssetsHeaderText.text = 'Detected Stage: ' + selectedStage;

		var maxPage:Int = Std.int(Math.max(0, Math.ceil(stageAssetEntries.length / STAGE_ASSET_ROWS) - 1));
		stageAssetsPageText.text = 'Assets: ' + stageAssetEntries.length + ' | Page ' + (stageAssetsPage + 1) + '/' + (maxPage + 1);

		for (row in 0...stageAssetButtons.length)
		{
			var idx:Int = stageAssetsPage * STAGE_ASSET_ROWS + row;
			var btn:PsychUIButton = stageAssetButtons[row];
			var playBtn:PsychUIButton = (stageAssetPlayButtons.length > row) ? stageAssetPlayButtons[row] : null;
			if(btn == null) continue;

			if(idx < stageAssetEntries.length)
			{
				var entry = stageAssetEntries[idx];
				var stateTxt:String = (entry.spr != null && entry.spr.visible) ? 'Hide' : 'Show';
				btn.label = stateTxt + ' ' + shortenStageAssetName(entry.name);
				btn.visible = true;
				btn.active = true;

				if(playBtn != null)
				{
					var hasAtlas:Bool = entry.spr != null && entry.spr.frames != null
						&& entry.spr.frames.frames != null && entry.spr.frames.frames.length > 0;
					if(hasAtlas)
					{
						playBtn.label = (stageAssetPlayingIdx == idx) ? '\u23F9 Stop' : '\u25B6 Play';
						playBtn.visible = true;
						playBtn.active = true;
					}
					else
					{
						playBtn.visible = false;
						playBtn.active = false;
					}
				}
			}
			else
			{
				btn.label = '-';
				btn.visible = false;
				btn.active = false;
				if(playBtn != null) { playBtn.visible = false; playBtn.active = false; }
			}
		}

		if(stageAssetsPrevButton != null)
			stageAssetsPrevButton.active = stageAssetsPage > 0;
		if(stageAssetsNextButton != null)
			stageAssetsNextButton.active = stageAssetsPage < maxPage;
		if(stageAssetsPrevButton != null)
			stageAssetsPrevButton.alpha = stageAssetsPrevButton.active ? 1 : 0.5;
		if(stageAssetsNextButton != null)
			stageAssetsNextButton.alpha = stageAssetsNextButton.active ? 1 : 0.5;
	}

	function toggleStageAssetAt(index:Int)
	{
		if(index < 0 || index >= stageAssetEntries.length) return;
		var entry = stageAssetEntries[index];
		if(entry == null || entry.spr == null) return;

		entry.spr.visible = !entry.spr.visible;
		refreshStageAssetsTableUI();
	}

	function toggleStageAssetPlayAt(index:Int)
	{
		if(index < 0 || index >= stageAssetEntries.length) return;
		var entry = stageAssetEntries[index];
		if(entry == null || entry.spr == null) return;

		var spr = entry.spr;
		if(spr.frames == null || spr.frames.frames == null || spr.frames.frames.length == 0) return;

		if(stageAssetPlayingIdx == index)
		{
			// Detener
			spr.active = false;
			spr.animation.stop();
			stageAssetPlayingIdx = -1;
		}
		else
		{
			// Detener el anterior si había uno
			if(stageAssetPlayingIdx >= 0 && stageAssetPlayingIdx < stageAssetEntries.length)
			{
				var prev = stageAssetEntries[stageAssetPlayingIdx];
				if(prev != null && prev.spr != null)
				{
					prev.spr.active = false;
					prev.spr.animation.stop();
				}
			}

			// Reproducir este — forzar visible primero
			stageAssetPlayingIdx = index;
			spr.visible = true;
			spr.active = true;
			var nameList = spr.animation.getNameList();
			if(nameList != null && nameList.length > 0)
			{
				spr.animation.play(nameList[0]);
			}
			else
			{
				// Sin animaciones nombradas: crear una de todos los frames
				var frameCount:Int = spr.frames.frames.length;
				spr.animation.add('__preview__', [for (fi in 0...frameCount) fi], 24, true);
				spr.animation.play('__preview__');
			}
		}

		refreshStageAssetsTableUI();
	}

	function addStageAssetsUI()
	{
		var tab_group = UI_box.getTab('Stage Assets').menu;

		stageAssetsHeaderText = new FlxText(10, 10, 230, 'Detected Stage: ' + selectedStage, 12);
		stageAssetsPageText = new FlxText(10, 26, 230, 'Assets: 0 | Page 1/1', 12);

		stageAssetsPrevButton = new PsychUIButton(10, 45, '< Prev', function()
		{
			stageAssetsPage--;
			refreshStageAssetsTableUI();
		}, 70);

		stageAssetsNextButton = new PsychUIButton(90, 45, 'Next >', function()
		{
			stageAssetsPage++;
			refreshStageAssetsTableUI();
		}, 70);

		stageAssetsRefreshButton = new PsychUIButton(170, 45, 'Refresh', function()
		{
			refreshStageAssetsTableUI();
		}, 70);

		stageAssetButtons = [];
		stageAssetPlayButtons = [];
		for (i in 0...STAGE_ASSET_ROWS)
		{
			var btnY:Float = 72 + (i * 24);
			var btnIndex:Int = i;
			var btn:PsychUIButton = new PsychUIButton(10, btnY, '-', function()
			{
				var idx:Int = stageAssetsPage * STAGE_ASSET_ROWS + btnIndex;
				toggleStageAssetAt(idx);
			}, 160);
			stageAssetButtons.push(btn);
			tab_group.add(btn);

			var playBtn:PsychUIButton = new PsychUIButton(175, btnY, '\u25B6 Play', function()
			{
				var idx:Int = stageAssetsPage * STAGE_ASSET_ROWS + btnIndex;
				toggleStageAssetPlayAt(idx);
			}, 65);
			playBtn.visible = false;
			playBtn.active = false;
			stageAssetPlayButtons.push(playBtn);
			tab_group.add(playBtn);
		}

		tab_group.add(stageAssetsHeaderText);
		tab_group.add(stageAssetsPageText);
		tab_group.add(stageAssetsPrevButton);
		tab_group.add(stageAssetsNextButton);
		tab_group.add(stageAssetsRefreshButton);

		refreshStageAssetsTableUI();
	}

	var ghostAlpha:Float = 0.6;
	inline function updateSilhouetteButtonText()
	{
		if(toggleSilhouettesButton != null)
			toggleSilhouettesButton.label = silhouettes.visible ? 'Hide Dad/BF Holograms' : 'Show Dad/BF Holograms';
	}

	inline function toggleSilhouettesVisibility()
	{
		silhouettes.visible = !silhouettes.visible;
		updateSilhouetteButtonText();
	}

	function addGhostUI()
	{
		var tab_group = UI_box.getTab('Ghost').menu;

		//var hideGhostButton:PsychUIButton = null;
		var makeGhostButton:PsychUIButton = new PsychUIButton(25, 15, "Make Ghost", function() {
			var anim = anims[curAnim];
			if(!character.isAnimationNull())
			{
				var myAnim = anims[curAnim];
				if(!character.isAnimateAtlas)
				{
					ghost.loadGraphic(character.graphic);
					ghost.frames.frames = character.frames.frames;
					ghost.animation.copyFrom(character.animation);
					ghost.animation.play(character.animation.curAnim.name, true, false, character.animation.curAnim.curFrame);
					ghost.animation.pause();
				}
				else if(myAnim != null) //This is VERY unoptimized and bad, I hope to find a better replacement that loads only a specific frame as bitmap in the future.
				{
					if(animateGhost == null) //If I created the animateGhost on create() and you didn't load an atlas, it would crash the game on destroy, so we create it here
					{
						animateGhost = new FlxAnimate(ghost.x, ghost.y);
						animateGhost.showPivot = false;
						insert(members.indexOf(ghost), animateGhost);
						animateGhost.active = false;
					}

					if(animateGhost == null || animateGhostImage != character.imageFile)
						Paths.loadAnimateAtlas(animateGhost, character.imageFile);
					
					if(myAnim.indices != null && myAnim.indices.length > 0)
						animateGhost.anim.addBySymbolIndices('anim', myAnim.name, myAnim.indices, 0, false);
					else
						animateGhost.anim.addBySymbol('anim', myAnim.name, 0, false);

					animateGhost.anim.play('anim', true, false, character.atlas.anim.curFrame);
					animateGhost.anim.pause();

					animateGhostImage = character.imageFile;
				}
				
				var spr:FlxSprite = !character.isAnimateAtlas ? ghost : animateGhost;
				if(spr != null)
				{
					spr.setPosition(character.x, character.y);
					spr.antialiasing = character.antialiasing;
					spr.flipX = character.flipX;
					spr.alpha = ghostAlpha;

					spr.scale.set(character.scale.x, character.scale.y);
					spr.updateHitbox();

					spr.offset.set(character.offset.x, character.offset.y);
					spr.visible = true;

					var otherSpr:FlxSprite = (spr == animateGhost) ? ghost : animateGhost;
					if(otherSpr != null) otherSpr.visible = false;
				}
				/*hideGhostButton.active = true;
				hideGhostButton.alpha = 1;*/
				trace('created ghost image');
			}
		});

		/*hideGhostButton = new PsychUIButton(20 + makeGhostButton.width, makeGhostButton.y, "Hide Ghost", function() {
			ghost.visible = false;
			hideGhostButton.active = false;
			hideGhostButton.alpha = 0.6;
		});
		hideGhostButton.active = false;
		hideGhostButton.alpha = 0.6;*/

		var highlightGhost:PsychUICheckBox = new PsychUICheckBox(20 + makeGhostButton.x + makeGhostButton.width, makeGhostButton.y, "Highlight Ghost", 100);
		highlightGhost.onClick = function()
		{
			var value = highlightGhost.checked ? 125 : 0;
			ghost.colorTransform.redOffset = value;
			ghost.colorTransform.greenOffset = value;
			ghost.colorTransform.blueOffset = value;
			if(animateGhost != null)
			{
				animateGhost.colorTransform.redOffset = value;
				animateGhost.colorTransform.greenOffset = value;
				animateGhost.colorTransform.blueOffset = value;
			}
		};

		toggleSilhouettesButton = new PsychUIButton(15, makeGhostButton.y + 45, '', function()
		{
			toggleSilhouettesVisibility();
		}, 150);
		updateSilhouetteButtonText();

		var ghostAlphaSlider:PsychUISlider = new PsychUISlider(15, makeGhostButton.y + 75, function(v:Float)
		{
			ghostAlpha = v;
			ghost.alpha = ghostAlpha;
			if(animateGhost != null) animateGhost.alpha = ghostAlpha;

		}, ghostAlpha, 0, 1);
		ghostAlphaSlider.label = 'Opacity:';

		tab_group.add(makeGhostButton);
		//tab_group.add(hideGhostButton);
		tab_group.add(highlightGhost);
		tab_group.add(toggleSilhouettesButton);
		tab_group.add(ghostAlphaSlider);
	}

	var check_player:PsychUICheckBox;
	var charDropDown:PsychUIDropDownMenu;
	var stageDropDown:PsychUIDropDownMenu;
	var stageList:Array<String> = [];
	var selectedStage:String = 'stage';
	var previewStageDirectory:String = 'shared';
	function addSettingsUI()
	{
		var tab_group = UI_box.getTab('Settings').menu;

		check_player = new PsychUICheckBox(10, 60, "Playable Character", 100);
		check_player.checked = character.isPlayer;
		check_player.onClick = function()
		{
			character.isPlayer = !character.isPlayer;
			character.flipX = !character.flipX;
			updateCharacterPositions();
			updatePointerPos(false);
		};

		var reloadCharacter:PsychUIButton = new PsychUIButton(140, 20, "Reload Char", function()
		{
			addCharacter(true);
			updatePointerPos();
			reloadCharacterOptions();
			reloadCharacterDropDown();
		});

		var templateCharacter:PsychUIButton = new PsychUIButton(140, 50, "Load Template", function()
		{
			final _template:CharacterFile =
			{
				animations: [
					newAnim('idle', 'BF idle dance'),
					newAnim('singLEFT', 'BF NOTE LEFT0'),
					newAnim('singDOWN', 'BF NOTE DOWN0'),
					newAnim('singUP', 'BF NOTE UP0'),
					newAnim('singRIGHT', 'BF NOTE RIGHT0')
				],
				no_antialiasing: false,
				flip_x: false,
				healthicon: 'face',
				image: 'characters/BOYFRIEND',
				sing_duration: 4,
				scale: 1,
				healthbar_colors: [161, 161, 161],
				camera_position: [0, 0],
				position: [0, 0],
				vocals_file: null
			};

			character.loadCharacterFile(_template);
			character.missingCharacter = false;
			character.color = FlxColor.WHITE;
			character.alpha = 1;
			reloadAnimList();
			reloadCharacterOptions();
			updateCharacterPositions();
			updatePointerPos();
			reloadCharacterDropDown();
			updateHealthBar();
		});
		templateCharacter.normalStyle.bgColor = FlxColor.RED;
		templateCharacter.normalStyle.textColor = FlxColor.WHITE;


		charDropDown = new PsychUIDropDownMenu(10, 30, [''], function(index:Int, intended:String)
		{
			if(intended == null || intended.length < 1) return;

			var characterPath:String = 'characters/$intended.json';
			var path:String = Paths.getPath(characterPath, TEXT, null, true);
			#if MODS_ALLOWED
			if (FileSystem.exists(path))
			#else
			if (Assets.exists(path))
			#end
			{
				_char = intended;
				check_player.checked = character.isPlayer;
				addCharacter();
				reloadCharacterOptions();
				reloadCharacterDropDown();
				updatePointerPos();
			}
			else
			{
				reloadCharacterDropDown();
				FlxG.sound.play(Paths.sound('cancelMenu'));
			}
		});
		reloadCharacterDropDown();
		charDropDown.selectedLabel = _char;

		stageDropDown = new PsychUIDropDownMenu(10, 95, [''], function(index:Int, stage:String)
		{
			if(stage == null || stage.length < 1) return;
			applyStagePreviewData(stage);
		});
		reloadStageDropDown();

		tab_group.add(new FlxText(charDropDown.x, charDropDown.y - 18, 80, 'Character:'));
		tab_group.add(new FlxText(stageDropDown.x, stageDropDown.y - 18, 120, 'Preview Stage:'));
		tab_group.add(check_player);
		tab_group.add(reloadCharacter);
		tab_group.add(templateCharacter);
		tab_group.add(charDropDown);
		tab_group.add(stageDropDown);
	}

	var animationDropDown:PsychUIDropDownMenu;
	var animationInputText:PsychUIInputText;
	var animationNameInputText:PsychUIInputText;
	var animationIndicesInputText:PsychUIInputText;
	var animationFramerate:PsychUINumericStepper;
	var animationLoopCheckBox:PsychUICheckBox;
	function addAnimationsUI()
	{
		var tab_group = UI_characterbox.getTab('Animations').menu;

		animationInputText = new PsychUIInputText(15, 85, 80, '', 8);
		animationNameInputText = new PsychUIInputText(animationInputText.x, animationInputText.y + 35, 150, '', 8);
		animationIndicesInputText = new PsychUIInputText(animationNameInputText.x, animationNameInputText.y + 40, 250, '', 8);
		animationFramerate = new PsychUINumericStepper(animationInputText.x + 170, animationInputText.y, 1, 24, 0, 240, 0);
		animationLoopCheckBox = new PsychUICheckBox(animationNameInputText.x + 170, animationNameInputText.y - 1, "Should it Loop?", 100);

		animationDropDown = new PsychUIDropDownMenu(15, animationInputText.y - 55, [''], function(selectedAnimation:Int, pressed:String) {
			var anim:AnimArray = character.animationsArray[selectedAnimation];
			animationInputText.text = anim.anim;
			animationNameInputText.text = anim.name;
			animationLoopCheckBox.checked = anim.loop;
			animationFramerate.value = anim.fps;

			var indicesStr:String = anim.indices.toString();
			animationIndicesInputText.text = indicesStr.substr(1, indicesStr.length - 2);
		});

		var addUpdateButton:PsychUIButton = new PsychUIButton(70, animationIndicesInputText.y + 60, "Add/Update", function() {
			var indicesText:String = animationIndicesInputText.text.trim();
			var indices:Array<Int> = [];
			if(indicesText.length > 0)
			{
				var indicesStr:Array<String> = animationIndicesInputText.text.trim().split(',');
				if(indicesStr.length > 0)
				{
					for (ind in indicesStr)
					{
						if(ind.contains('-'))
						{
							var splitIndices:Array<String> = ind.split('-');
							var indexStart:Int = Std.parseInt(splitIndices[0]);
							if(Math.isNaN(indexStart) || indexStart < 0) indexStart = 0;
	
							var indexEnd:Int = Std.parseInt(splitIndices[1]);
							if(Math.isNaN(indexEnd) || indexEnd < indexStart) indexEnd = indexStart;
	
							for (index in indexStart...indexEnd+1)
								indices.push(index);
						}
						else
						{
							var index:Int = Std.parseInt(ind);
							if(!Math.isNaN(index) && index > -1)
								indices.push(index);
						}
					}
				}
			}

			var lastAnim:String = (character.animationsArray[curAnim] != null) ? character.animationsArray[curAnim].anim : '';
			var lastOffsets:Array<Int> = [0, 0];
			for (anim in character.animationsArray)
				if(animationInputText.text == anim.anim) {
					lastOffsets = anim.offsets;
					if(character.hasAnimation(animationInputText.text))
					{
						if(!character.isAnimateAtlas) character.animation.remove(animationInputText.text);
						else @:privateAccess character.atlas.anim.animsMap.remove(animationInputText.text);
					}
					character.animationsArray.remove(anim);
				}

			var addedAnim:AnimArray = newAnim(animationInputText.text, animationNameInputText.text);
			addedAnim.fps = Math.round(animationFramerate.value);
			addedAnim.loop = animationLoopCheckBox.checked;
			addedAnim.indices = indices;
			addedAnim.offsets = lastOffsets;
			addAnimation(addedAnim.anim, addedAnim.name, addedAnim.fps, addedAnim.loop, addedAnim.indices);
			character.animationsArray.push(addedAnim);

			reloadAnimList();
			@:arrayAccess curAnim = Std.int(Math.max(0, character.animationsArray.indexOf(addedAnim)));
			character.playAnim(addedAnim.anim, true);
			trace('Added/Updated animation: ' + animationInputText.text);
		});

		var removeButton:PsychUIButton = new PsychUIButton(180, animationIndicesInputText.y + 60, "Remove", function() {
			for (anim in character.animationsArray)
				if(animationInputText.text == anim.anim)
				{
					var resetAnim:Bool = false;
					if(anim.anim == character.getAnimationName()) resetAnim = true;
					if(character.hasAnimation(anim.anim))
					{
						if(!character.isAnimateAtlas) character.animation.remove(anim.anim);
						else @:privateAccess character.atlas.anim.animsMap.remove(anim.anim);
						character.animOffsets.remove(anim.anim);
						character.animationsArray.remove(anim);
					}

					if(resetAnim && character.animationsArray.length > 0) {
						curAnim = FlxMath.wrap(curAnim, 0, anims.length-1);
						character.playAnim(anims[curAnim].anim, true);
					}
					reloadAnimList();
					trace('Removed animation: ' + animationInputText.text);
					break;
				}
		});
		reloadAnimList();
		animationDropDown.selectedLabel = anims[0] != null ? anims[0].anim : '';

		tab_group.add(new FlxText(animationDropDown.x, animationDropDown.y - 18, 100, 'Animations:'));
		tab_group.add(new FlxText(animationInputText.x, animationInputText.y - 18, 100, 'Animation name:'));
		tab_group.add(new FlxText(animationFramerate.x, animationFramerate.y - 18, 100, 'Framerate:'));
		tab_group.add(new FlxText(animationNameInputText.x, animationNameInputText.y - 18, 150, 'Animation Symbol Name/Tag:'));
		tab_group.add(new FlxText(animationIndicesInputText.x, animationIndicesInputText.y - 18, 170, 'ADVANCED - Animation Indices:'));

		tab_group.add(animationInputText);
		tab_group.add(animationNameInputText);
		tab_group.add(animationIndicesInputText);
		tab_group.add(animationFramerate);
		tab_group.add(animationLoopCheckBox);
		tab_group.add(addUpdateButton);
		tab_group.add(removeButton);
		tab_group.add(animationDropDown);
	}

	var imageInputText:PsychUIInputText;
	var healthIconInputText:PsychUIInputText;
	var vocalsInputText:PsychUIInputText;

	var singDurationStepper:PsychUINumericStepper;
	var scaleStepper:PsychUINumericStepper;
	var positionXStepper:PsychUINumericStepper;
	var positionYStepper:PsychUINumericStepper;
	var positionCameraXStepper:PsychUINumericStepper;
	var positionCameraYStepper:PsychUINumericStepper;

	var flipXCheckBox:PsychUICheckBox;
	var noAntialiasingCheckBox:PsychUICheckBox;

	var healthColorStepperR:PsychUINumericStepper;
	var healthColorStepperG:PsychUINumericStepper;
	var healthColorStepperB:PsychUINumericStepper;
	function addCharacterUI()
	{
		var tab_group = UI_characterbox.getTab('Character').menu;

		imageInputText = new PsychUIInputText(15, 30, 200, character.imageFile, 8);
		var reloadImage:PsychUIButton = new PsychUIButton(imageInputText.x + 210, imageInputText.y - 3, "Reload Image", function()
		{
			var lastAnim = character.getAnimationName();
			character.imageFile = imageInputText.text;
			reloadCharacterImage();
			if(!character.isAnimationNull()) {
				character.playAnim(lastAnim, true);
			}
		});

		var decideIconColor:PsychUIButton = new PsychUIButton(reloadImage.x, reloadImage.y + 30, "Get Icon Color", function()
			{
				var coolColor:FlxColor = FlxColor.fromInt(CoolUtil.dominantColor(healthIcon));
				character.healthColorArray[0] = coolColor.red;
				character.healthColorArray[1] = coolColor.green;
				character.healthColorArray[2] = coolColor.blue;
				updateHealthBar();
			});

		healthIconInputText = new PsychUIInputText(15, imageInputText.y + 35, 75, healthIcon.getCharacter(), 8);

		vocalsInputText = new PsychUIInputText(15, healthIconInputText.y + 35, 75, character.vocalsFile != null ? character.vocalsFile : '', 8);

		singDurationStepper = new PsychUINumericStepper(15, vocalsInputText.y + 45, 0.1, 4, 0, 999, 1);

		scaleStepper = new PsychUINumericStepper(15, singDurationStepper.y + 40, 0.1, 1, 0.05, 10, 2);

		flipXCheckBox = new PsychUICheckBox(singDurationStepper.x + 80, singDurationStepper.y, "Flip X", 50);
		flipXCheckBox.checked = character.flipX;
		if(character.isPlayer) flipXCheckBox.checked = !flipXCheckBox.checked;
		flipXCheckBox.onClick = function() {
			character.originalFlipX = !character.originalFlipX;
			character.flipX = (character.originalFlipX != character.isPlayer);
		};

		noAntialiasingCheckBox = new PsychUICheckBox(flipXCheckBox.x, flipXCheckBox.y + 40, "No Antialiasing", 80);
		noAntialiasingCheckBox.checked = character.noAntialiasing;
		noAntialiasingCheckBox.onClick = function() {
			character.antialiasing = false;
			if(!noAntialiasingCheckBox.checked && ClientPrefs.data.antialiasing) {
				character.antialiasing = true;
			}
			character.noAntialiasing = noAntialiasingCheckBox.checked;
		};

		positionXStepper = new PsychUINumericStepper(flipXCheckBox.x + 110, flipXCheckBox.y, 10, character.positionArray[0], -9000, 9000, 0);
		positionYStepper = new PsychUINumericStepper(positionXStepper.x + 70, positionXStepper.y, 10, character.positionArray[1], -9000, 9000, 0);

		positionCameraXStepper = new PsychUINumericStepper(positionXStepper.x, positionXStepper.y + 40, 10, character.cameraPosition[0], -9000, 9000, 0);
		positionCameraYStepper = new PsychUINumericStepper(positionYStepper.x, positionYStepper.y + 40, 10, character.cameraPosition[1], -9000, 9000, 0);

		var saveCharacterButton:PsychUIButton = new PsychUIButton(reloadImage.x, noAntialiasingCheckBox.y + 40, "Save Character", function() {
			saveCharacter();
		});

		healthColorStepperR = new PsychUINumericStepper(singDurationStepper.x, saveCharacterButton.y, 20, character.healthColorArray[0], 0, 255, 0);
		healthColorStepperG = new PsychUINumericStepper(singDurationStepper.x + 65, saveCharacterButton.y, 20, character.healthColorArray[1], 0, 255, 0);
		healthColorStepperB = new PsychUINumericStepper(singDurationStepper.x + 130, saveCharacterButton.y, 20, character.healthColorArray[2], 0, 255, 0);

		tab_group.add(new FlxText(15, imageInputText.y - 18, 100, 'Image file name:'));
		tab_group.add(new FlxText(15, healthIconInputText.y - 18, 100, 'Health icon name:'));
		tab_group.add(new FlxText(15, vocalsInputText.y - 18, 100, 'Vocals File Postfix:'));
		tab_group.add(new FlxText(15, singDurationStepper.y - 18, 120, 'Sing Animation length:'));
		tab_group.add(new FlxText(15, scaleStepper.y - 18, 100, 'Scale:'));
		tab_group.add(new FlxText(positionXStepper.x, positionXStepper.y - 18, 100, 'Character X/Y:'));
		tab_group.add(new FlxText(positionCameraXStepper.x, positionCameraXStepper.y - 18, 100, 'Camera X/Y:'));
		tab_group.add(new FlxText(healthColorStepperR.x, healthColorStepperR.y - 18, 100, 'Health Bar R/G/B:'));
		tab_group.add(imageInputText);
		tab_group.add(reloadImage);
		tab_group.add(decideIconColor);
		tab_group.add(healthIconInputText);
		tab_group.add(vocalsInputText);
		tab_group.add(singDurationStepper);
		tab_group.add(scaleStepper);
		tab_group.add(flipXCheckBox);
		tab_group.add(noAntialiasingCheckBox);
		tab_group.add(positionXStepper);
		tab_group.add(positionYStepper);
		tab_group.add(positionCameraXStepper);
		tab_group.add(positionCameraYStepper);
		tab_group.add(healthColorStepperR);
		tab_group.add(healthColorStepperG);
		tab_group.add(healthColorStepperB);
		tab_group.add(saveCharacterButton);
	}

	public function UIEvent(id:String, sender:Dynamic) {
		//trace(id, sender);
		if(id == PsychUICheckBox.CLICK_EVENT)
			unsavedProgress = true;

		if(id == PsychUIInputText.CHANGE_EVENT)
		{
			if(sender == healthIconInputText) {
				var lastIcon = healthIcon.getCharacter();
				healthIcon.changeIcon(healthIconInputText.text, false);
				character.healthIcon = healthIconInputText.text;
				if(lastIcon != healthIcon.getCharacter()) updatePresence();
				unsavedProgress = true;
			}
			else if(sender == vocalsInputText)
			{
				character.vocalsFile = vocalsInputText.text;
				unsavedProgress = true;
			}
			else if(sender == imageInputText)
			{
				character.imageFile = imageInputText.text;
				unsavedProgress = true;
			}
		}
		else if(id == PsychUINumericStepper.CHANGE_EVENT)
		{
			if (sender == scaleStepper)
			{
				reloadCharacterImage();
				character.jsonScale = sender.value;
				character.scale.set(character.jsonScale, character.jsonScale);
				character.updateHitbox();
				updatePointerPos(false);
				unsavedProgress = true;
			}
			else if(sender == positionXStepper)
			{
				character.positionArray[0] = positionXStepper.value;
				updateCharacterPositions();
				unsavedProgress = true;
			}
			else if(sender == positionYStepper)
			{
				character.positionArray[1] = positionYStepper.value;
				updateCharacterPositions();
				unsavedProgress = true;
			}
			else if(sender == singDurationStepper)
			{
				character.singDuration = singDurationStepper.value;
				unsavedProgress = true;
			}
			else if(sender == positionCameraXStepper)
			{
				character.cameraPosition[0] = positionCameraXStepper.value;
				updatePointerPos();
				unsavedProgress = true;
			}
			else if(sender == positionCameraYStepper)
			{
				character.cameraPosition[1] = positionCameraYStepper.value;
				updatePointerPos();
				unsavedProgress = true;
			}
			else if(sender == healthColorStepperR)
			{
				character.healthColorArray[0] = Math.round(healthColorStepperR.value);
				updateHealthBar();
				unsavedProgress = true;
			}
			else if(sender == healthColorStepperG)
			{
				character.healthColorArray[1] = Math.round(healthColorStepperG.value);
				updateHealthBar();
				unsavedProgress = true;
			}
			else if(sender == healthColorStepperB)
			{
				character.healthColorArray[2] = Math.round(healthColorStepperB.value);
				updateHealthBar();
				unsavedProgress = true;
			}
		}
	}

	function reloadCharacterImage()
	{
		var lastAnim:String = character.getAnimationName();
		var anims:Array<AnimArray> = character.animationsArray.copy();

		character.atlas = FlxDestroyUtil.destroy(character.atlas);
		character.isAnimateAtlas = false;
		character.color = FlxColor.WHITE;
		character.alpha = 1;

		if(Paths.fileExists('images/' + character.imageFile + '/Animation.json', TEXT))
		{
			character.atlas = new FlxAnimate();
			character.atlas.showPivot = false;
			try
			{
				Paths.loadAnimateAtlas(character.atlas, character.imageFile);
			}
			catch(e:Dynamic)
			{
				FlxG.log.warn('Could not load atlas ${character.imageFile}: $e');
			}
			character.isAnimateAtlas = true;
		}
		else
		{
			character.frames = Paths.getMultiAtlas(character.imageFile.split(','));
		}

		for (anim in anims) {
			var animAnim:String = '' + anim.anim;
			var animName:String = '' + anim.name;
			var animFps:Int = anim.fps;
			var animLoop:Bool = !!anim.loop; //Bruh
			var animIndices:Array<Int> = anim.indices;
			addAnimation(animAnim, animName, animFps, animLoop, animIndices);
		}

		if(anims.length > 0)
		{
			if(lastAnim != '') character.playAnim(lastAnim, true);
			else character.dance();
		}
	}

	function reloadCharacterOptions() {
		if(UI_characterbox == null) return;

		check_player.checked = character.isPlayer;
		imageInputText.text = character.imageFile;
		healthIconInputText.text = character.healthIcon;
		vocalsInputText.text = character.vocalsFile != null ? character.vocalsFile : '';
		singDurationStepper.value = character.singDuration;
		scaleStepper.value = character.jsonScale;
		flipXCheckBox.checked = character.originalFlipX;
		noAntialiasingCheckBox.checked = character.noAntialiasing;
		positionXStepper.value = character.positionArray[0];
		positionYStepper.value = character.positionArray[1];
		positionCameraXStepper.value = character.cameraPosition[0];
		positionCameraYStepper.value = character.cameraPosition[1];
		reloadAnimationDropDown();
		updateHealthBar();
	}

	var holdingArrowsTime:Float = 0;
	var holdingArrowsElapsed:Float = 0;
	var holdingFrameTime:Float = 0;
	var holdingFrameElapsed:Float = 0;
	var undoOffsets:Array<Float> = null;
	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if(PsychUIInputText.focusOn != null)
		{
			ClientPrefs.toggleVolumeKeys(false);
			return;
		}
		ClientPrefs.toggleVolumeKeys(true);

		var shiftMult:Float = 1;
		var ctrlMult:Float = 1;
		var shiftMultBig:Float = 1;
		if(FlxG.keys.pressed.SHIFT)
		{
			shiftMult = 4;
			shiftMultBig = 10;
		}
		if(FlxG.keys.pressed.CONTROL) ctrlMult = 0.25;

		// CAMERA CONTROLS
		if (FlxG.keys.pressed.J) FlxG.camera.scroll.x -= elapsed * 500 * shiftMult * ctrlMult;
		if (FlxG.keys.pressed.K) FlxG.camera.scroll.y += elapsed * 500 * shiftMult * ctrlMult;
		if (FlxG.keys.pressed.L) FlxG.camera.scroll.x += elapsed * 500 * shiftMult * ctrlMult;
		if (FlxG.keys.pressed.I) FlxG.camera.scroll.y -= elapsed * 500 * shiftMult * ctrlMult;

		var lastZoom = FlxG.camera.zoom;
		if(FlxG.keys.justPressed.R && !FlxG.keys.pressed.CONTROL) FlxG.camera.zoom = 1;
		else if (FlxG.keys.pressed.E && FlxG.camera.zoom < 3) {
			FlxG.camera.zoom += elapsed * FlxG.camera.zoom * shiftMult * ctrlMult;
			if(FlxG.camera.zoom > 3) FlxG.camera.zoom = 3;
		}
		else if (FlxG.keys.pressed.Q && FlxG.camera.zoom > 0.1) {
			FlxG.camera.zoom -= elapsed * FlxG.camera.zoom * shiftMult * ctrlMult;
			if(FlxG.camera.zoom < 0.1) FlxG.camera.zoom = 0.1;
		}

		if(lastZoom != FlxG.camera.zoom) cameraZoomText.text = 'Zoom: ' + FlxMath.roundDecimal(FlxG.camera.zoom, 2) + 'x';

		// CHARACTER CONTROLS
		var changedAnim:Bool = false;
		if(anims.length > 1)
		{
			if(FlxG.keys.justPressed.W && (changedAnim = true)) curAnim--;
			else if(FlxG.keys.justPressed.S && (changedAnim = true)) curAnim++;

			if(changedAnim)
			{
				undoOffsets = null;
				curAnim = FlxMath.wrap(curAnim, 0, anims.length-1);
				character.playAnim(anims[curAnim].anim, true);
				updateText();
			}
		}

		var changedOffset = false;
		var moveKeysP = [FlxG.keys.justPressed.LEFT, FlxG.keys.justPressed.RIGHT, FlxG.keys.justPressed.UP, FlxG.keys.justPressed.DOWN];
		var moveKeys = [FlxG.keys.pressed.LEFT, FlxG.keys.pressed.RIGHT, FlxG.keys.pressed.UP, FlxG.keys.pressed.DOWN];
		if(moveKeysP.contains(true))
		{
			character.offset.x += ((moveKeysP[0] ? 1 : 0) - (moveKeysP[1] ? 1 : 0)) * shiftMultBig;
			character.offset.y += ((moveKeysP[2] ? 1 : 0) - (moveKeysP[3] ? 1 : 0)) * shiftMultBig;
			changedOffset = true;
		}

		if(moveKeys.contains(true))
		{
			holdingArrowsTime += elapsed;
			if(holdingArrowsTime > 0.6)
			{
				holdingArrowsElapsed += elapsed;
				while(holdingArrowsElapsed > (1/60))
				{
					character.offset.x += ((moveKeys[0] ? 1 : 0) - (moveKeys[1] ? 1 : 0)) * shiftMultBig;
					character.offset.y += ((moveKeys[2] ? 1 : 0) - (moveKeys[3] ? 1 : 0)) * shiftMultBig;
					holdingArrowsElapsed -= (1/60);
					changedOffset = true;
				}
			}
		}
		else holdingArrowsTime = 0;

		if(FlxG.mouse.pressedRight && (FlxG.mouse.deltaScreenX != 0 || FlxG.mouse.deltaScreenY != 0))
		{
			character.offset.x -= FlxG.mouse.deltaScreenX;
			character.offset.y -= FlxG.mouse.deltaScreenY;
			changedOffset = true;
		}

		if(FlxG.keys.pressed.CONTROL)
		{
			if(FlxG.keys.justPressed.C)
			{
				copiedOffset[0] = character.offset.x;
				copiedOffset[1] = character.offset.y;
				changedOffset = true;
			}
			else if(FlxG.keys.justPressed.V)
			{
				undoOffsets = [character.offset.x, character.offset.y];
				character.offset.x = copiedOffset[0];
				character.offset.y = copiedOffset[1];
				changedOffset = true;
			}
			else if(FlxG.keys.justPressed.R)
			{
				undoOffsets = [character.offset.x, character.offset.y];
				character.offset.set(0, 0);
				changedOffset = true;
			}
			else if(FlxG.keys.justPressed.Z && undoOffsets != null)
			{
				character.offset.x = undoOffsets[0];
				character.offset.y = undoOffsets[1];
				changedOffset = true;
			}
		}

		var anim = anims[curAnim];
		if(changedOffset && anim != null && anim.offsets != null)
		{
			anim.offsets[0] = Std.int(character.offset.x);
			anim.offsets[1] = Std.int(character.offset.y);

			character.addOffset(anim.anim, character.offset.x, character.offset.y);
			updateText();
		}

		var txt = 'ERROR: No Animation Found';
		var clr = FlxColor.RED;
		if(!character.isAnimationNull())
		{
			if(FlxG.keys.pressed.A || FlxG.keys.pressed.D)
			{
				holdingFrameTime += elapsed;
				if(holdingFrameTime > 0.5) holdingFrameElapsed += elapsed;
			}
			else holdingFrameTime = 0;

			if(FlxG.keys.justPressed.SPACE)
				character.playAnim(character.getAnimationName(), true);

			var frames:Int = -1;
			var length:Int = -1;
			if(!character.isAnimateAtlas && character.animation.curAnim != null)
			{
				frames = character.animation.curAnim.curFrame;
				length = character.animation.curAnim.numFrames;
			}
			else if(character.isAnimateAtlas && character.atlas.anim != null)
			{
				frames = character.atlas.anim.curFrame;
				length = character.atlas.anim.length;
			}

			if(length >= 0)
			{
				if(FlxG.keys.justPressed.A || FlxG.keys.justPressed.D || holdingFrameTime > 0.5)
				{
					var isLeft = false;
					if((holdingFrameTime > 0.5 && FlxG.keys.pressed.A) || FlxG.keys.justPressed.A) isLeft = true;
					character.animPaused = true;
	
					if(holdingFrameTime <= 0.5 || holdingFrameElapsed > 0.1)
					{
						frames = FlxMath.wrap(frames + Std.int(isLeft ? -shiftMult : shiftMult), 0, length-1);
						if(!character.isAnimateAtlas) character.animation.curAnim.curFrame = frames;
						else character.atlas.anim.curFrame = frames;
						holdingFrameElapsed -= 0.1;
					}
				}
	
				txt = 'Frames: ' + frames + ' / ' + (length - 1);
				//if(character.animation.curAnim.paused) txt += ' - PAUSED';
				clr = FlxColor.WHITE;
			}
		}
		if(txt != frameAdvanceText.text) frameAdvanceText.text = txt;
		frameAdvanceText.color = clr;

		// OTHER CONTROLS
		if(FlxG.keys.justPressed.F12)
			toggleSilhouettesVisibility();

		if(FlxG.keys.justPressed.F1 || (helpBg.visible && FlxG.keys.justPressed.ESCAPE))
		{
			helpBg.visible = !helpBg.visible;
			helpTexts.visible = helpBg.visible;
		}
		else if(FlxG.keys.justPressed.ESCAPE)
		{
			if(!_goToPlayState)
			{
				if(!unsavedProgress)
				{
					MusicBeatState.switchState(new states.editors.MasterEditorMenu());
					
				}
				else openSubState(new ExitConfirmationPrompt());
			}
			else
			{
				FlxG.mouse.visible = false;
				MusicBeatState.switchState(new PlayState());
			}
			return;
		}
	}

	function initPreviewStage()
	{
		selectedStage = 'stage';
		if(PlayState.SONG != null && PlayState.SONG.stage != null && PlayState.SONG.stage.length > 0)
			selectedStage = PlayState.SONG.stage;
	}

	inline function updateSilhouettePositions()
	{
		if(dadSilhouette != null)
			dadSilhouette.setPosition(dadPosition.x, dadPosition.y);

		if(boyfriendSilhouette != null)
			boyfriendSilhouette.setPosition(bfPosition.x, bfPosition.y + 350);
	}

	function applyStagePreviewData(stage:String, ?snapCamera:Bool = true)
	{
		if(stage == null || stage.length < 1) stage = 'stage';
		selectedStage = stage;
		previewStageDirectory = 'shared';

		dadPosition.set(100, 100);
		bfPosition.set(770, 100);

		var stagePath:String = Paths.getPath('stages/$stage.json', TEXT, null, true);
		var stageLuaPath:String = Paths.getPath('stages/$stage.lua', TEXT, null, true);
		var stageExists:Bool = false;
		var luaStageExists:Bool = false;
		#if MODS_ALLOWED
		stageExists = FileSystem.exists(stagePath);
		luaStageExists = FileSystem.exists(stageLuaPath);
		#else
		stageExists = Assets.exists(stagePath);
		luaStageExists = Assets.exists(stageLuaPath);
		#end

		var stageData:StageFile = null;
		if(stageExists)
		{
			stageData = StageData.getStageFile(stage);
			if(stageData != null)
			{
				if(stageData.directory != null && stageData.directory.length > 0)
					previewStageDirectory = stageData.directory;

				if(stageData.opponent != null && stageData.opponent.length > 1)
					dadPosition.set(stageData.opponent[0], stageData.opponent[1]);

				if(stageData.boyfriend != null && stageData.boyfriend.length > 1)
					bfPosition.set(stageData.boyfriend[0], stageData.boyfriend[1]);

				if(stageData.defaultZoom > 0)
				{
					FlxG.camera.zoom = stageData.defaultZoom;
					if(cameraZoomText != null)
						cameraZoomText.text = 'Zoom: ' + FlxMath.roundDecimal(FlxG.camera.zoom, 2) + 'x';
				}
			}
		}

		reloadStagePreviewVisuals(stageData, luaStageExists);

		if(character != null)
			updateCharacterPositions();
		updateSilhouettePositions();
		updatePointerPos(snapCamera);

		if(stageDropDown != null)
			stageDropDown.selectedLabel = selectedStage;

		refreshStageAssetsTableUI();
	}


	inline function loadBG()
	{
		if(stagePreviewGroup == null)
		{
			stagePreviewGroup = new FlxSpriteGroup();
			add(stagePreviewGroup);
		}

		camEditor.bgColor = 0xFF666666;
	}

	function clearStagePreviewVisuals()
	{
		if(stagePreviewGroup == null) return;
		if(stagePreviewGroup.members == null) return;

		for (spr in stagePreviewGroup.members)
			if(spr != null)
				spr.destroy();

		stagePreviewGroup.clear();
	}

	function addDefaultPreviewBackdrop(stageName:String)
	{
		try
		{
			switch(stageName)
			{
				case 'spooky':
					stagePreviewGroup.add(new BGSprite('halloween_bg', -200, -100));

				case 'philly':
					stagePreviewGroup.add(new BGSprite('philly/sky', -100, 0, 0.1, 0.1));
					stagePreviewGroup.add(new BGSprite('philly/city', -10, 0, 0.3, 0.3));
					stagePreviewGroup.add(new BGSprite('philly/street', -40, 50));

				case 'limo':
					stagePreviewGroup.add(new BGSprite('limo/limoSunset', -120, -50, 0.1, 0.1));
					stagePreviewGroup.add(new BGSprite('limo/limoDrive', -120, 550));

				case 'mall':
					stagePreviewGroup.add(new BGSprite('christmas/bgWalls', -1000, -500, 0.2, 0.2));
					stagePreviewGroup.add(new BGSprite('christmas/christmasTree', 370, -250, 0.40, 0.40));
					stagePreviewGroup.add(new BGSprite('christmas/fgSnow', -600, 700));

				case 'mallEvil':
					stagePreviewGroup.add(new BGSprite('christmas/evilBG', -400, -500, 0.2, 0.2));
					stagePreviewGroup.add(new BGSprite('christmas/evilTree', 300, -300, 0.2, 0.2));
					stagePreviewGroup.add(new BGSprite('christmas/evilSnow', -200, 700));

				case 'school':
					stagePreviewGroup.add(new BGSprite('weeb/weebSky', 0, 0, 0.1, 0.1));
					stagePreviewGroup.add(new BGSprite('weeb/weebSchool', -200, 0, 0.6, 0.9));
					stagePreviewGroup.add(new BGSprite('weeb/weebStreet', -200, 0, 0.95, 0.95));

				case 'schoolEvil':
					stagePreviewGroup.add(new BGSprite('weeb/animatedEvilSchool_low', 400, 200, 0.8, 0.9));

				case 'tank':
					stagePreviewGroup.add(new BGSprite('tankSky', -400, -400, 0, 0));
					stagePreviewGroup.add(new BGSprite('tankGround', -420, -150));

				case 'phillyStreets':
					stagePreviewGroup.add(new BGSprite('phillyStreets/phillySkybox', -650, -375));

				case 'phillyBlazin':
					stagePreviewGroup.add(new BGSprite('phillyBlazin/streetBlur', -600, -175, 0.0, 0.0));

				default:
					var bg:BGSprite = new BGSprite('stageback', -600, -200, 0.9, 0.9);
					stagePreviewGroup.add(bg);

					var stageFront:BGSprite = new BGSprite('stagefront', -650, 600, 0.9, 0.9);
					stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
					stageFront.updateHitbox();
					stagePreviewGroup.add(stageFront);
			}

			camEditor.bgColor = 0xFF000000;
		}
		catch(e:Dynamic)
		{
			camEditor.bgColor = 0xFF666666;
		}
	}

	function reloadStagePreviewVisuals(stageData:StageFile, hasLuaStage:Bool)
	{
		if(stagePreviewGroup == null) return;

		var lastLoadedLevel = Paths.currentLevel;
		if(previewStageDirectory != null && previewStageDirectory.length > 0)
			Paths.currentLevel = previewStageDirectory;

		clearStagePreviewVisuals();
		camEditor.bgColor = 0xFF666666;

		var loadedFromJson:Bool = false;
		if(stageData != null && stageData.objects != null && stageData.objects.length > 0)
		{
			StageData.addObjectsToState(stageData.objects, null, null, null, stagePreviewGroup, true);
			if(stagePreviewGroup.members != null && stagePreviewGroup.members.length > 0)
			{
				loadedFromJson = true;
				camEditor.bgColor = 0xFF000000;
			}
		}

		var loadedFromLua:Bool = false;
		if(!loadedFromJson && hasLuaStage)
			loadedFromLua = reloadLuaStagePreviewVisuals(selectedStage);

		if(!loadedFromJson && !loadedFromLua)
			addDefaultPreviewBackdrop(selectedStage);

		Paths.currentLevel = lastLoadedLevel;
	}

	inline function stageNameHash(stageName:String):Int
	{
		var hash:Int = 0;
		for (i in 0...stageName.length)
		{
			var rawCode:Null<Int> = stageName.charCodeAt(i);
			var code:Int = (rawCode != null && rawCode >= 0) ? rawCode : 0;
			hash = Std.int((hash * 31 + code) % 0x01000000);
		}
		return hash;
	}

	function addLuaStageMarker(stageName:String, message:String)
	{
		var stageColor:Int = stageNameHash(stageName);
		var red:Int = Std.int(stageColor / 0x10000) % 0x100;
		var green:Int = Std.int(stageColor / 0x100) % 0x100;
		var blue:Int = stageColor % 0x100;
		var tintColor:FlxColor = FlxColor.fromRGB(red, green, blue, 255);
		var overlay:FlxSprite = new FlxSprite(-3000, -3000).makeGraphic(6000, 6000, tintColor);
		overlay.alpha = 0.20;
		stagePreviewGroup.add(overlay);

		var marker:FlxText = new FlxText(-200, -120, 1600, 'LUA STAGE PREVIEW: ' + stageName + '\n' + message, 24);
		marker.setFormat(null, 24, FlxColor.WHITE, CENTER, OUTLINE_FAST, FlxColor.BLACK);
		marker.borderSize = 1;
		stagePreviewGroup.add(marker);
		camEditor.bgColor = 0xFF111111;
	}

	function reloadLuaStagePreviewVisuals(stageName:String):Bool
	{
		var luaPath:String = Paths.getPath('stages/$stageName.lua', TEXT, null, true);
		var existsLua:Bool = false;
		#if MODS_ALLOWED
		existsLua = FileSystem.exists(luaPath);
		#else
		existsLua = Assets.exists(luaPath);
		#end
		if(!existsLua) return false;

		var luaText:String = null;
		try
		{
			#if MODS_ALLOWED
			luaText = File.getContent(luaPath);
			#else
			luaText = Assets.getText(luaPath);
			#end
		}
		catch(e:Dynamic)
		{
			addLuaStageMarker(stageName, 'Script no se pudo leer');
			return true;
		}

		if(luaText == null || luaText.trim().length < 1)
		{
			addLuaStageMarker(stageName, 'Script vacío');
			return true;
		}

		var spriteMap:Map<String, FlxSprite> = [];
		var creationOrder:Array<String> = [];
		var addCalls:Array<{tag:String, front:Bool}> = [];

		var spriteRegex:EReg = ~/make(?:Animated)?LuaSprite\s*\(\s*['"]([^'"]+)['"]\s*,\s*['"]([^'"]+)['"]\s*,\s*([-0-9\.]+)\s*,\s*([-0-9\.]+)/g;
		var pos:Int = 0;
		while(spriteRegex.matchSub(luaText, pos))
		{
			var tag:String = spriteRegex.matched(1);
			var imagePath:String = spriteRegex.matched(2);
			var xVal:Float = Std.parseFloat(spriteRegex.matched(3));
			var yVal:Float = Std.parseFloat(spriteRegex.matched(4));

			var imageExists:Bool = Paths.fileExists('images/$imagePath.png', IMAGE);
			if(imageExists)
			{
				var spr:FlxSprite = new FlxSprite(xVal, yVal);
				var hasAtlas:Bool = Paths.fileExists('images/$imagePath.xml', TEXT)
					|| Paths.fileExists('images/$imagePath.txt', TEXT)
					|| Paths.fileExists('images/$imagePath.json', TEXT);

				if(hasAtlas)
				{
					try
					{
						spr.frames = Paths.getAtlas(imagePath);
						if(spr.frames != null && spr.frames.frames != null && spr.frames.frames.length > 0)
							spr.frame = spr.frames.frames[0];
						else
							spr.loadGraphic(Paths.image(imagePath));
					}
					catch(e:Dynamic)
					{
						spr.loadGraphic(Paths.image(imagePath));
					}
				}
				else
				{
					spr.loadGraphic(Paths.image(imagePath));
				}

				spr.antialiasing = ClientPrefs.data.antialiasing;
				spr.updateHitbox();
				spriteMap.set(tag, spr);
				creationOrder.push(tag);
			}

			var matchedPos = spriteRegex.matchedPos();
			pos = matchedPos.pos + matchedPos.len;
		}

		if(creationOrder.length < 1)
		{
			addLuaStageMarker(stageName, 'Lua sin makeLuaSprite/makeAnimatedLuaSprite');
			trace('[CharacterEditor] Lua stage "$stageName" has no previewable sprite constructors.');
			return true;
		}

		// scaleObject(tag, scaleX, scaleY)
		var scaleRegex:EReg = ~/scaleObject\s*\(\s*['"]([^'"]+)['"]\s*,\s*([-0-9\.]+)\s*,\s*([-0-9\.]+)\s*\)/g;
		pos = 0;
		while(scaleRegex.matchSub(luaText, pos))
		{
			var tag:String = scaleRegex.matched(1);
			var spr = spriteMap.get(tag);
			if(spr != null)
			{
				spr.scale.set(Std.parseFloat(scaleRegex.matched(2)), Std.parseFloat(scaleRegex.matched(3)));
				spr.updateHitbox();
			}
			var mp = scaleRegex.matchedPos();
			pos = mp.pos + mp.len;
		}

		// setScrollFactor(tag, x, y)
		var scrollRegex:EReg = ~/setScrollFactor\s*\(\s*['"]([^'"]+)['"]\s*,\s*([-0-9\.]+)\s*,\s*([-0-9\.]+)\s*\)/g;
		pos = 0;
		while(scrollRegex.matchSub(luaText, pos))
		{
			var tag:String = scrollRegex.matched(1);
			var spr = spriteMap.get(tag);
			if(spr != null)
				spr.scrollFactor.set(Std.parseFloat(scrollRegex.matched(2)), Std.parseFloat(scrollRegex.matched(3)));
			var mp = scrollRegex.matchedPos();
			pos = mp.pos + mp.len;
		}

		// setProperty('tag.field', value)
		var propertyRegex:EReg = ~/setProperty\s*\(\s*['"]([^'"]+)['"]\s*,\s*([^\)]+)\)/g;
		pos = 0;
		while(propertyRegex.matchSub(luaText, pos))
		{
			var propertyPath:String = propertyRegex.matched(1);
			var rawValue:String = propertyRegex.matched(2).trim();

			var dot:Int = propertyPath.indexOf('.');
			if(dot > 0)
			{
				var tag:String = propertyPath.substr(0, dot);
				var fieldPath:String = propertyPath.substr(dot + 1);
				var spr = spriteMap.get(tag);
				if(spr != null)
				{
					if(rawValue.endsWith(',')) rawValue = rawValue.substr(0, rawValue.length - 1).trim();
					if((rawValue.startsWith('"') && rawValue.endsWith('"')) || (rawValue.startsWith("'") && rawValue.endsWith("'")))
						rawValue = rawValue.substr(1, rawValue.length - 2);

					var floatValue:Float = Std.parseFloat(rawValue);
					var boolValue:Null<Bool> = null;
					switch(rawValue.toLowerCase())
					{
						case 'true': boolValue = true;
						case 'false': boolValue = false;
						default:
					}

					switch(fieldPath)
					{
						case 'x': if(!Math.isNaN(floatValue)) spr.x = floatValue;
						case 'y': if(!Math.isNaN(floatValue)) spr.y = floatValue;
						case 'alpha': if(!Math.isNaN(floatValue)) spr.alpha = floatValue;
						case 'angle': if(!Math.isNaN(floatValue)) spr.angle = floatValue;
						case 'visible': if(boolValue != null) spr.visible = boolValue;
						case 'scale.x': if(!Math.isNaN(floatValue)) { spr.scale.x = floatValue; spr.updateHitbox(); }
						case 'scale.y': if(!Math.isNaN(floatValue)) { spr.scale.y = floatValue; spr.updateHitbox(); }
						case 'offset.x': if(!Math.isNaN(floatValue)) spr.offset.x = floatValue;
						case 'offset.y': if(!Math.isNaN(floatValue)) spr.offset.y = floatValue;
						default:
					}
				}
			}

			var mp = propertyRegex.matchedPos();
			pos = mp.pos + mp.len;
		}

		// addLuaSprite(tag, front)
		var addRegex:EReg = ~/addLuaSprite\s*\(\s*['"]([^'"]+)['"]\s*,\s*(true|false)\s*\)/g;
		var hasAddCalls:Bool = false;
		pos = 0;
		while(addRegex.matchSub(luaText, pos))
		{
			hasAddCalls = true;
			addCalls.push({
				tag: addRegex.matched(1),
				front: addRegex.matched(2).toLowerCase() == 'true'
			});
			var mp = addRegex.matchedPos();
			pos = mp.pos + mp.len;
		}

		var loaded:Int = 0;
		var addedMap:Map<String, Bool> = [];
		if(hasAddCalls)
		{
			for (call in addCalls)
			{
				var spr = spriteMap.get(call.tag);
				if(spr == null) continue;

				if(!addedMap.exists(call.tag))
				{
					stagePreviewGroup.add(spr);
					addedMap.set(call.tag, true);
					loaded++;
				}
				else if(call.front)
				{
					stagePreviewGroup.remove(spr, true);
					stagePreviewGroup.add(spr);
				}
			}
		}
		else
		{
			for (tag in creationOrder)
			{
				var spr = spriteMap.get(tag);
				if(spr != null)
				{
					stagePreviewGroup.add(spr);
					loaded++;
				}
			}
		}

		if(loaded > 0)
		{
			camEditor.bgColor = 0xFF000000;
			trace('[CharacterEditor] Lua stage "$stageName" loaded with $loaded sprite(s), properties applied.');
			return true;
		}

		addLuaStageMarker(stageName, 'Sin makeLuaSprite usable (solo lógica/scripts)');
		trace('[CharacterEditor] Lua stage "$stageName" has no previewable sprites.');
		return true;
	}

	inline function updatePointerPos(?snap:Bool = true)
	{
		if(character == null || cameraFollowPointer == null) return;

		var offX:Float = 0;
		var offY:Float = 0;
		if(!character.isPlayer)
		{
			offX = character.getMidpoint().x + 150 + character.cameraPosition[0];
			offY = character.getMidpoint().y - 100 + character.cameraPosition[1];
		}
		else
		{
			offX = character.getMidpoint().x - 100 - character.cameraPosition[0];
			offY = character.getMidpoint().y - 100 + character.cameraPosition[1];
		}
		cameraFollowPointer.setPosition(offX, offY);

		if(snap)
		{
			FlxG.camera.scroll.x = cameraFollowPointer.getMidpoint().x - FlxG.width/2;
			FlxG.camera.scroll.y = cameraFollowPointer.getMidpoint().y - FlxG.height/2;
		}
	}

	inline function updateHealthBar()
	{
		healthColorStepperR.value = character.healthColorArray[0];
		healthColorStepperG.value = character.healthColorArray[1];
		healthColorStepperB.value = character.healthColorArray[2];
		healthBar.leftBar.color = healthBar.rightBar.color = FlxColor.fromRGB(character.healthColorArray[0], character.healthColorArray[1], character.healthColorArray[2]);
		healthIcon.changeIcon(character.healthIcon, false);
		updatePresence();
	}

	inline function updatePresence() {
		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Character Editor", "Character: " + _char, healthIcon.getCharacter());
		#end
	}

	inline function reloadAnimList()
	{
		anims = character.animationsArray;
		if(anims.length > 0) character.playAnim(anims[0].anim, true);
		curAnim = 0;

		updateText();
		if(animationDropDown != null) reloadAnimationDropDown();
	}

	inline function updateText()
	{
		animsTxt.removeFormat(selectedFormat);

		var intendText:String = '';
		for (num => anim in anims)
		{
			if(num > 0) intendText += '\n';

			if(num == curAnim)
			{
				var n:Int = intendText.length;
				intendText += anim.anim + ": " + anim.offsets;
				animsTxt.addFormat(selectedFormat, n, intendText.length);
			}
			else intendText += anim.anim + ": " + anim.offsets;
		}
		animsTxt.text = intendText;
	}

	inline function updateCharacterPositions()
	{
		if((character != null && !character.isPlayer) || (character == null && predictCharacterIsNotPlayer(_char))) character.setPosition(dadPosition.x, dadPosition.y);
		else character.setPosition(bfPosition.x, bfPosition.y);

		character.x += character.positionArray[0];
		character.y += character.positionArray[1];
		updatePointerPos(false);
	}

	inline function predictCharacterIsNotPlayer(name:String)
	{
		return (name != 'bf' && !name.startsWith('bf-') && !name.endsWith('-player') && !name.endsWith('-playable') && !name.endsWith('-dead')) ||
				name.endsWith('-opponent') || name.startsWith('gf-') || name.endsWith('-gf') || name == 'gf';
	}

	function addAnimation(anim:String, name:String, fps:Float, loop:Bool, indices:Array<Int>)
	{
		if(!character.isAnimateAtlas)
		{
			if(indices != null && indices.length > 0)
				character.animation.addByIndices(anim, name, indices, "", fps, loop);
			else
				character.animation.addByPrefix(anim, name, fps, loop);
		}
		else
		{
			if(indices != null && indices.length > 0)
				character.atlas.anim.addBySymbolIndices(anim, name, indices, fps, loop);
			else
				character.atlas.anim.addBySymbol(anim, name, fps, loop);
		}

		if(!character.hasAnimation(anim))
			character.addOffset(anim, 0, 0);
	}

	inline function newAnim(anim:String, name:String):AnimArray
	{
		return {
			offsets: [0, 0],
			loop: false,
			fps: 24,
			anim: anim,
			indices: [],
			name: name
		};
	}

	var characterList:Array<String> = [];
	function reloadCharacterDropDown() {
		characterList = Mods.mergeAllTextsNamed('data/characterList.txt');
		var foldersToCheck:Array<String> = Mods.directoriesWithFile(Paths.getSharedPath(), 'characters/');
		for (folder in foldersToCheck)
			for (file in FileSystem.readDirectory(folder))
				if(file.toLowerCase().endsWith('.json'))
				{
					var charToCheck:String = file.substr(0, file.length - 5);
					if(!characterList.contains(charToCheck))
						characterList.push(charToCheck);
				}

		if(characterList.length < 1) characterList.push('');
		charDropDown.list = characterList;
		charDropDown.selectedLabel = _char;
	}

	function reloadStageDropDown()
	{
		stageList = Mods.mergeAllTextsNamed('data/stageList.txt');
		for (directory in Mods.directoriesWithFile(Paths.getSharedPath(), 'stages/'))
		{
			for (file in FileSystem.readDirectory(directory))
			{
				var lower:String = file.toLowerCase();
				if(lower.endsWith('.json') || lower.endsWith('.lua'))
				{
					var extLength:Int = lower.endsWith('.json') ? '.json'.length : '.lua'.length;
					var stageToCheck:String = file.substr(0, file.length - extLength);
					if(stageToCheck.length > 0 && !stageList.contains(stageToCheck))
						stageList.push(stageToCheck);
				}
			}
		}

		if(!stageList.contains(selectedStage))
			stageList.push(selectedStage);

		if(stageList.length < 1) stageList.push('stage');
		stageList.sort(Reflect.compare);

		stageDropDown.list = stageList;
		stageDropDown.selectedLabel = selectedStage;
	}

	function reloadAnimationDropDown() {
		var animList:Array<String> = [];
		for (anim in anims) animList.push(anim.anim);
		if(animList.length < 1) animList.push('NO ANIMATIONS'); //Prevents crash

		animationDropDown.list = animList;
	}

	// save
	var _file:FileReference;
	function onSaveComplete(_):Void
	{
		if(_file == null) return;
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved file.");
	}

	/**
		* Called when the save file dialog is cancelled.
		*/
	function onSaveCancel(_):Void
	{
		if(_file == null) return;
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	/**
		* Called if there is an error while saving the gameplay recording.
		*/
	function onSaveError(_):Void
	{
		if(_file == null) return;
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving file");
	}

	function saveCharacter() {
		if(_file != null) return;

		var json:Dynamic = {
			"animations": character.animationsArray,
			"image": character.imageFile,
			"scale": character.jsonScale,
			"sing_duration": character.singDuration,
			"healthicon": character.healthIcon,

			"position":	character.positionArray,
			"camera_position": character.cameraPosition,

			"flip_x": character.originalFlipX,
			"no_antialiasing": character.noAntialiasing,
			"healthbar_colors": character.healthColorArray,
			"vocals_file": character.vocalsFile,
			"_editor_isPlayer": character.isPlayer
		};

		var data:String = PsychJsonPrinter.print(json, ['offsets', 'position', 'healthbar_colors', 'camera_position', 'indices']);

		if (data.length > 0)
		{
			_file = new FileReference();
			_file.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data, '$_char.json');
		}
	}
}
