package states;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import backend.ChapterStructs;
import backend.MusicBeatState;
import backend.Paths;
import openfl.Assets;

class SideStoryMenuState extends MusicBeatState
{
	var englishChapters:Array<Chapter> = [];
	var japaneseChapters:Array<Chapter> = [];
	var camFollow:FlxSprite;
	var camFollowPos:FlxObject;
	var blackTop:FlxSprite;
	var overlay:FlxSprite;
	var thumb1:FlxSprite;
	var thumb2:FlxSprite;
	var thumb3:FlxSprite;
	var c1:FlxSprite;
	var c2:FlxSprite;
	var c3:FlxSprite;
	var s1:FlxSprite;
	var s2:FlxSprite;
	var s3:FlxSprite;
	var jp:FlxSprite;
	var eng:FlxSprite;
	var jpText:FlxSprite;
	var engText:FlxSprite;
	var jpTextSelected:FlxSprite;
	var engTextSelected:FlxSprite;
	var curSelected:Int = 0;
	var curLang:Bool = true;
	var canSelect:Bool = true;
	var menuSection:String = 'main';
	var addY:Int = 800;
	var initialTween:FlxTween;
	var blackTween:FlxTween;
	var jpTween:FlxTween;
	var engTween:FlxTween;

	override public function create():Void
	{
		super.create();
		persistentUpdate = true;
		persistentDraw = true;
		FlxTransitionableState.defaultTransIn = new TransitionData(FADE, FlxColor.BLACK, 1);
		FlxTransitionableState.defaultTransOut = new TransitionData(FADE, FlxColor.BLACK, 1);
		FlxG.mouse.visible = false;
		FlxG.camera.bgColor = FlxColor.BLACK;

		camFollow = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		camFollow.alpha = 0;
		camFollow.setPosition(636, 392);
		camFollowPos = new FlxObject(636, 392, 1, 1);
		add(camFollow);
		add(camFollowPos);
		FlxG.camera.zoom = 0.593;
		FlxG.camera.follow(camFollowPos, null, 1);
		FlxG.sound.playMusic(Paths.music('menu4'), 1);

		var bg = new FlxSprite().loadGraphic(Paths.image('menus/sidestory/gradient'));
		bg.scrollFactor.set();
		bg.screenCenter();
		bg.scale.set(1.7, 1.7);
		bg.alpha = 0;
		add(bg);
		FlxTween.tween(bg, {alpha: 0.6}, 10, {ease: FlxEase.sineInOut, type: FlxTween.PINGPONG});

		var chains = new FlxSprite().loadGraphic(Paths.image('menus/sidestory/chains'));
		chains.scrollFactor.set();
		chains.screenCenter();
		chains.scale.set(1.7, 1.7);
		add(chains);

		thumb1 = addImage('menus/sidestory/1Thumbnail', -1313, -1819, 0.12, 1, 1);
		thumb2 = addImage('menus/sidestory/2Thumbnail', -932, -1889, 0.115, 1, 1);
		thumb3 = addImage('menus/sidestory/3Thumbnail', 183, -945.5, 0.2, 1, 1);
		c1 = addImage('menus/sidestory/c1', 0, 0, 1.7, 1, 1);
		c2 = addImage('menus/sidestory/c2', 0, 0, 1.7, 1, 1);
		c3 = addImage('menus/sidestory/c3', 0, 0, 1.7, 1, 1);
		s1 = addImage('menus/sidestory/s1', 0, 0, 1.7, 1, 1); s1.alpha = 0;
		s2 = addImage('menus/sidestory/s2', 0, 0, 1.7, 1, 1); s2.alpha = 0;
		s3 = addImage('menus/sidestory/s3', 0, 0, 1.7, 1, 1); s3.alpha = 0;
		overlay = addImage('menus/sidestory/overlay', 0, 0, 1, 0, 0);
		overlay.scale.set(1.6, 3.2);
		overlay.alpha = 0;
		jp = addImage('menus/sidestory/jp', 0, 195 + addY, 1.6, 1, 1); jp.alpha = 0;
		eng = addImage('menus/sidestory/eng', 0, 195 + addY, 1.7, 1, 1); eng.alpha = 0;
		jpText = addImage('menus/sidestory/l1', 0, addY, 1.7, 1, 1); jpText.alpha = 0;
		engText = addImage('menus/sidestory/l2', 0, addY, 1.7, 1, 1); engText.alpha = 0;
		jpTextSelected = addImage('menus/sidestory/ls1', -20, 6 + addY, 1.7, 1, 1); jpTextSelected.alpha = 0;
		engTextSelected = addImage('menus/sidestory/ls2', 18, 9 + addY, 1.7, 1, 1); engTextSelected.alpha = 0;

		blackTop = new FlxSprite(10, -20, Paths.image('menus/mainmenu/fullBlack'));
		blackTop.scrollFactor.set();
		blackTop.scale.set(1.7, 1.7);
		add(blackTop);
		blackTween = FlxTween.tween(blackTop, {alpha: 0}, 1, {ease: FlxEase.sineIn});
		loadChapters();
		updateSelected();
	}

	function addImage(path:String, x:Float, y:Float, scale:Float, scrollX:Float, scrollY:Float):FlxSprite
	{
		var sprite = new FlxSprite().loadGraphic(Paths.image(path));
		sprite.scrollFactor.set(scrollX, scrollY);
		sprite.screenCenter();
		sprite.scale.set(scale, scale);
		if (x != 0) sprite.x = x;
		if (y != 0) sprite.y = y;
		add(sprite);
		return sprite;
	}

	function loadChapters():Void
	{
		englishChapters = createChapterList('english');
		japaneseChapters = createChapterList('japanese');
	}

	function createChapterList(language:String):Array<Chapter>
	{
		var result:Array<Chapter> = [];
		for (chapterIndex in 1...4) {
			var chapter:Chapter = {name: 'chapter-' + chapterIndex, pages: []};
			var previous:ChapterPage = null;
			var pageIndex = 1;
			while (true) {
				var pageName = chapter.name + '-' + language + '-' + pageIndex;
				if (!Assets.exists(Paths.getPath('images/cutscenes/' + pageName + '.png'))) break;
				var page:ChapterPage = {visualName: 'Page ' + pageIndex, name: pageName, prevPage: previous};
				if (previous != null) previous.nextPage = page;
				chapter.pages.push(page);
				previous = page;
				pageIndex++;
			}
			result.push(chapter);
		}
		return result;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (menuSection == 'lang') inputShitLang(); else inputShit();
	}

	function updateSelected():Void
	{
		var thumbs = [thumb1, thumb2, thumb3];
		var selected = [s1, s2, s3];
		var chapters = [c1, c2, c3];
		var selectedScale = [0.13, 0.125, 0.21];
		var normalScale = [0.12, 0.115, 0.2];
		for (index in 0...3) {
			var size = index == curSelected ? selectedScale[index] : normalScale[index];
			thumbs[index].scale.set(size, size);
			thumbs[index].alpha = index == curSelected ? 1 : 0.4;
			selected[index].alpha = index == curSelected ? 1 : 0;
			chapters[index].alpha = index == curSelected ? 0 : 1;
		}
	}

	function inputShit():Void
	{
		if (!canSelect) return;
		if (FlxG.keys.justPressed.SPACE || FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.Z) {
			FlxG.sound.play(Paths.sound('confirmMenu'));
			menuSection = 'lang';
			canSelect = false;
			overlay.alpha = 1;
			initialTween = FlxTween.tween(camFollowPos, {y: 951}, 0.6, {ease: FlxEase.circInOut});
			updateLang();
			new FlxTimer().start(0.7, function(timer) { canSelect = true; timer.destroy(); });
		}
		if (FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.BACKSPACE || FlxG.keys.justPressed.X) {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			canSelect = false;
			backOut();
		}
		if (FlxG.keys.justPressed.A || FlxG.keys.justPressed.LEFT) {
			FlxG.sound.play(Paths.sound('scrollMenu'));
			curSelected = (curSelected + 2) % 3;
			updateSelected();
		}
		if (FlxG.keys.justPressed.D || FlxG.keys.justPressed.RIGHT) {
			FlxG.sound.play(Paths.sound('scrollMenu'));
			curSelected = (curSelected + 1) % 3;
			updateSelected();
		}
	}

	function inputShitLang():Void
	{
		if (!canSelect) return;
		if (FlxG.keys.justPressed.SPACE || FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.Z) startComic();
		if (FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.BACKSPACE || FlxG.keys.justPressed.X) {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			backToMain();
			canSelect = false;
			new FlxTimer().start(0.7, function(timer) { canSelect = true; timer.destroy(); });
		}
		if (FlxG.keys.justPressed.A || FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.D || FlxG.keys.justPressed.RIGHT) {
			FlxG.sound.play(Paths.sound('scrollMenu'));
			curLang = !curLang;
			updateLang();
		}
	}

	function updateLang():Void
	{
		if (jpTween != null) jpTween.cancel();
		if (engTween != null) engTween.cancel();
		if (menuSection == 'main') {
			jpText.alpha = 0; engText.alpha = 0; jpTextSelected.alpha = 0; engTextSelected.alpha = 0;
			jpTween = FlxTween.tween(jp, {alpha: 0}, 0.6, {ease: FlxEase.circInOut});
			engTween = FlxTween.tween(eng, {alpha: 0}, 0.6, {ease: FlxEase.circInOut});
			return;
		}
		if (curLang) {
			jp.scale.set(1.6, 1.6); eng.scale.set(1.7, 1.7);
			jpTween = FlxTween.tween(jp, {alpha: 0.4}, 0.6, {ease: FlxEase.circInOut});
			engTween = FlxTween.tween(eng, {alpha: 1}, 0.6, {ease: FlxEase.circInOut});
			jpText.alpha = 0.4; engText.alpha = 0; jpTextSelected.alpha = 0; engTextSelected.alpha = 1;
		} else {
			jp.scale.set(1.7, 1.7); eng.scale.set(1.6, 1.6);
			jpTween = FlxTween.tween(jp, {alpha: 1}, 0.6, {ease: FlxEase.circInOut});
			engTween = FlxTween.tween(eng, {alpha: 0.4}, 0.6, {ease: FlxEase.circInOut});
			jpText.alpha = 0; engText.alpha = 0.4; jpTextSelected.alpha = 1; engTextSelected.alpha = 0;
		}
	}

	function startComic():Void
	{
		var chapters = curLang ? englishChapters : japaneseChapters;
		if (chapters[curSelected].pages.length == 0) return;
		FlxG.sound.play(Paths.sound('confirmMenu'));
		canSelect = false;
		MusicBeatState.switchState(new ComicReader(chapters[curSelected].pages[0]));
	}

	function backToMain():Void
	{
		menuSection = 'main';
		overlay.alpha = 0;
		initialTween = FlxTween.tween(camFollowPos, {y: 392}, 0.6, {ease: FlxEase.circInOut});
		updateLang();
	}

	function backOut():Void
	{
		if (blackTween != null) blackTween.cancel();
		blackTween = FlxTween.tween(blackTop, {alpha: 1}, 1, {ease: FlxEase.sineOut, onComplete: function(tween) leaveScene()});
	}

	function leaveScene():Void
	{
		MusicBeatState.switchState(new SoftCodeMenuState(true));
	}
}
