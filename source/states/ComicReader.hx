package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.text.FlxText.FlxTextAlign;
import flixel.util.FlxColor;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.math.FlxMath;
import backend.ChapterStructs;
import backend.MusicBeatState;
import backend.Paths;
import openfl.Assets;

typedef ComicChapter = {
    var id:String;
    var title:String;
    var pages:Array<ChapterPage>;
}

class ComicReader extends MusicBeatState
{
    var chapters:Array<ComicChapter> = [];
    var currentChapter:Int = 0;
    var currentPage:ChapterPage;
    var currentPageIndex:Int = 0;
    var currentPageSprite:FlxSprite;
    var currentPageBaseScale:Float = 1;
    var pageGroup:FlxTypedGroup<FlxSprite>;
    var scrollOffset:Float = 0;
    var contentHeight:Float = 0;
    var zoom:Float = 1;
    var targetZoom:Float = 1;
    var minZoom:Float = 0.25;
    var maxZoom:Float = 2.5;
    var scrollVelocity:Float = 0;
    var pageChangeCooldown:Float = 0;
    var pageXOffset:Float = 0;
    var mouseDragging:Bool = false;
    var mousePreviousX:Float = 0;
    var mousePreviousY:Float = 0;
    var canControl:Bool = false;
    var chapterListOpen:Bool = false;
    var pageIndicator:FlxText;
    var previousButton:FlxText;
    var chapterListButton:FlxText;
    var nextButton:FlxText;
    var previousButtonBottom:FlxText;
    var chapterListButtonBottom:FlxText;
    var nextButtonBottom:FlxText;
    var footerInfo:FlxText;
    var chapterOptions:Array<FlxText> = [];
    var navigationNormalColor:Int = FlxColor.fromRGB(185, 185, 185);
    var navigationHoverColor:Int = FlxColor.BLUE;

    public function new(startPage:ChapterPage)
    {
        super();
        currentPage = startPage;
    }

    override public function create():Void
    {
        super.create();
        FlxG.mouse.visible = true;
        FlxG.camera.bgColor = FlxColor.fromRGB(8, 8, 9);
        buildChapters();
        findCurrentChapter();

        pageGroup = new FlxTypedGroup<FlxSprite>();
        add(pageGroup);
        loadCurrentPage();
        createChapterPanel();
        createNavigation();
        canControl = true;
    }

    function buildChapters():Void
    {
        for (chapterIndex in 1...4)
        {
            var chapter:ComicChapter = {id: 'chapter-' + chapterIndex, title: 'Chapter ' + chapterIndex, pages: []};
            var previous:ChapterPage = null;
            var pageIndex = 1;
            while (true)
            {
                var pageName = chapter.id + '-english-' + pageIndex;
                var path = Paths.getPath('images/cutscenes/' + pageName + '.png');
                if (!Assets.exists(path)) break;
                var page:ChapterPage = {visualName: 'Page ' + pageIndex, name: pageName, prevPage: previous};
                if (previous != null) previous.nextPage = page;
                chapter.pages.push(page);
                previous = page;
                pageIndex++;
            }
            if (chapter.pages.length > 0) chapters.push(chapter);
        }
    }

    function findCurrentChapter():Void
    {
        if (chapters.length == 0 || currentPage == null) return;
        var firstPage = currentPage;
        while (firstPage.prevPage != null) firstPage = firstPage.prevPage;
        for (index in 0...chapters.length)
        {
            if (chapters[index].pages[0].name == firstPage.name) {
                currentChapter = index;
                for (pageIndex in 0...chapters[index].pages.length)
                    if (chapters[index].pages[pageIndex].name == currentPage.name) currentPageIndex = pageIndex;
            }
        }
    }

    function loadCurrentPage():Void
    {
        if (currentPageSprite != null) {
            pageGroup.remove(currentPageSprite, true);
            currentPageSprite.destroy();
            currentPageSprite = null;
        }
        pageGroup.clear();
        scrollOffset = 0;
        scrollVelocity = 0;
        pageXOffset = 0;
        mouseDragging = false;
        if (chapters.length == 0) return;

        currentPage = chapters[currentChapter].pages[currentPageIndex];
        if (pageIndicator != null)
            pageIndicator.text = 'Page ' + (currentPageIndex + 1);
        currentPageSprite = new FlxSprite();
        var path = Paths.getPath('images/cutscenes/' + currentPage.name + '.png');
        if (Assets.exists(path)) {
            currentPageSprite.loadGraphic(path);
            var maxWidth = Math.min(FlxG.width * 0.84, 900);
            currentPageBaseScale = maxWidth / currentPageSprite.width;
            currentPageSprite.scale.set(currentPageBaseScale, currentPageBaseScale);
            currentPageSprite.updateHitbox();
            pageGroup.add(currentPageSprite);
            contentHeight = currentPageSprite.height;
            applyPageTransform();
        } else {
            trace('Error: No se pudo cargar la imagen ' + path);
        }
    }

    function createNavigation():Void
    {
        pageIndicator = new FlxText(24, 20, FlxG.width - 48, 'Page 1');
        pageIndicator.setFormat(null, 14, FlxColor.fromRGB(185, 185, 185), CENTER);
        pageIndicator.scrollFactor.set();
        add(pageIndicator);
        if (pageIndicator != null)
            pageIndicator.text = 'Page ' + (currentPageIndex + 1);

        previousButton = createNavigationButton(24, '< PREVIOUS', 250, LEFT, 48);
        chapterListButton = createNavigationButton((FlxG.width - 300) * 0.5, 'CHAPTER LIST', 300, CENTER, 48);
        nextButton = createNavigationButton(FlxG.width - 274, 'NEXT >', 250, RIGHT, 48);
        add(previousButton);
        add(chapterListButton);
        add(nextButton);

        previousButtonBottom = createNavigationButton(24, '< PREVIOUS', 250, LEFT, FlxG.height - 78);
        chapterListButtonBottom = createNavigationButton((FlxG.width - 300) * 0.5, 'CHAPTER LIST', 300, CENTER, FlxG.height - 78);
        nextButtonBottom = createNavigationButton(FlxG.width - 274, 'NEXT >', 250, RIGHT, FlxG.height - 78);
        add(previousButtonBottom);
        add(chapterListButtonBottom);
        add(nextButtonBottom);

        footerInfo = new FlxText(0, FlxG.height - 42, FlxG.width, 'W/S or mouse: SCROLL    CTRL + WHEEL: ZOOM    ESC: EXIT');
        footerInfo.setFormat(null, 11, FlxColor.fromRGB(135, 135, 135), CENTER);
        footerInfo.scrollFactor.set();
        add(footerInfo);
    }

    function createChapterPanel():Void
    {
        for (index in 0...chapters.length)
        {
            var option = new FlxText(0, FlxG.height * 0.5 - 54 + index * 36, FlxG.width, chapters[index].title);
            option.setFormat(null, 18, FlxColor.fromRGB(190, 190, 190), CENTER);
            option.scrollFactor.set();
            option.visible = false;
            add(option);
            chapterOptions.push(option);
        }
    }

    function createNavigationButton(x:Float, label:String, width:Float, alignment:FlxTextAlign, y:Float = 38):FlxText
    {
        var button = new FlxText(x, y, width, label, 16);
        button.setFormat(null, 14, navigationNormalColor, alignment);
        button.scrollFactor.set();
        button.antialiasing = true;
        return button;
    }

    function updateNavigationMouse():Void
    {
        if (chapterListOpen) return;

        var previousHover = FlxG.mouse.overlaps(previousButton);
        var chapterListHover = FlxG.mouse.overlaps(chapterListButton);
        var nextHover = FlxG.mouse.overlaps(nextButton);
        var previousBottomHover = FlxG.mouse.overlaps(previousButtonBottom);
        var chapterListBottomHover = FlxG.mouse.overlaps(chapterListButtonBottom);
        var nextBottomHover = FlxG.mouse.overlaps(nextButtonBottom);
        previousButton.color = previousHover ? navigationHoverColor : navigationNormalColor;
        chapterListButton.color = chapterListHover ? navigationHoverColor : navigationNormalColor;
        nextButton.color = nextHover ? navigationHoverColor : navigationNormalColor;
        previousButtonBottom.color = previousBottomHover ? navigationHoverColor : navigationNormalColor;
        chapterListButtonBottom.color = chapterListBottomHover ? navigationHoverColor : navigationNormalColor;
        nextButtonBottom.color = nextBottomHover ? navigationHoverColor : navigationNormalColor;

        if (!FlxG.mouse.justPressed) return;
        if (previousHover || previousBottomHover) changeChapter(-1);
        else if (chapterListHover || chapterListBottomHover) exitToSideStoryMenu();
        else if (nextHover || nextBottomHover) changeChapter(1);
    }

    function setScroll(value:Float):Void
    {
        scrollOffset = value;
        applyPageTransform();
    }

    function applyPageTransform():Void
    {
        if (currentPageSprite == null) return;
        currentPageSprite.scale.set(currentPageBaseScale * zoom, currentPageBaseScale * zoom);
        currentPageSprite.updateHitbox();
        currentPageSprite.x = (FlxG.width - currentPageSprite.width) * 0.5 + pageXOffset;
        currentPageSprite.y = 76 - scrollOffset;
    }

    function changeZoom(nextZoom:Float, mouseX:Float, mouseY:Float):Void
    {
        var oldZoom = zoom;
        var oldPageX = currentPageSprite == null ? FlxG.width * 0.5 : currentPageSprite.x;
        zoom = FlxMath.bound(nextZoom, minZoom, maxZoom);
        if (oldZoom == zoom) return;

        var contentAtCursorY = scrollOffset + (mouseY - 76) / oldZoom;
        scrollOffset = contentAtCursorY - (mouseY - 76) / zoom;
        if (currentPageSprite != null) {
            var contentAtCursorX = (mouseX - oldPageX) / oldZoom;
            var newWidth = currentPageSprite.width / oldZoom * zoom;
            var centeredX = (FlxG.width - newWidth) * 0.5;
            pageXOffset = mouseX - contentAtCursorX * zoom - centeredX;
        }
        setScroll(scrollOffset);
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);
        if (!canControl) return;
        if (pageChangeCooldown > 0) pageChangeCooldown -= elapsed;
        updateNavigationMouse();

        if (chapterListOpen)
        {
            updateChapterListMouse();
            updateChapterListInput();
            return;
        }

        updatePageDrag();

        var wheel = FlxG.mouse.wheel;
        if (wheel != 0) {
            if (FlxG.keys.pressed.CONTROL)
                targetZoom = FlxMath.bound(targetZoom + wheel * 0.12, minZoom, maxZoom);
            else
                setScroll(scrollOffset - wheel * 110);
        }

        if (Math.abs(targetZoom - zoom) > 0.001) {
            var smoothZoom = zoom + (targetZoom - zoom) * Math.min(1, elapsed * 10);
            changeZoom(smoothZoom, FlxG.mouse.x, FlxG.mouse.y);
        }

        if (FlxG.keys.pressed.DOWN || FlxG.keys.pressed.S) setScroll(scrollOffset + elapsed * 520);
        if (FlxG.keys.pressed.UP || FlxG.keys.pressed.W) setScroll(scrollOffset - elapsed * 520);
        if (FlxG.keys.justPressed.PAGEUP) setScroll(scrollOffset - FlxG.height * 0.8);
        if (FlxG.keys.justPressed.PAGEDOWN) setScroll(scrollOffset + FlxG.height * 0.8);
        if (FlxG.keys.justPressed.C) openChapterList();
        if (FlxG.keys.justPressed.LEFT) changeChapter(-1);
        if (FlxG.keys.justPressed.RIGHT) changeChapter(1);
        if (FlxG.keys.justPressed.ESCAPE) exitReader();
    }

    function updatePageDrag():Void
    {
        var mouseInViewport = FlxG.mouse.x >= 0
            && FlxG.mouse.x <= FlxG.width
            && FlxG.mouse.y >= 0
            && FlxG.mouse.y <= FlxG.height;

        if (FlxG.mouse.justPressed && mouseInViewport && currentPageSprite != null) {
            mouseDragging = true;
            mousePreviousX = FlxG.mouse.x;
            mousePreviousY = FlxG.mouse.y;
        }

        if (!FlxG.mouse.pressed) {
            mouseDragging = false;
            return;
        }

        if (!mouseDragging) return;

        var deltaX = FlxG.mouse.x - mousePreviousX;
        var deltaY = FlxG.mouse.y - mousePreviousY;
        pageXOffset += deltaX;
        setScroll(scrollOffset - deltaY);
        mousePreviousX = FlxG.mouse.x;
        mousePreviousY = FlxG.mouse.y;
    }

    function openChapterList():Void
    {
        chapterListOpen = true;
        for (index in 0...chapterOptions.length)
        {
            chapterOptions[index].visible = true;
            chapterOptions[index].color = index == currentChapter ? FlxColor.WHITE : FlxColor.fromRGB(150, 150, 150);
            chapterOptions[index].text = (index == currentChapter ? '> ' : '  ') + chapters[index].title;
        }
    }

    function updateChapterListInput():Void
    {
        if (FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.C) closeChapterList();
        if (FlxG.keys.justPressed.UP || FlxG.keys.justPressed.W) changeChapter(-1);
        if (FlxG.keys.justPressed.DOWN || FlxG.keys.justPressed.S) changeChapter(1);
        if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.SPACE) closeChapterList();
    }

    function updateChapterListMouse():Void
    {
        for (index in 0...chapterOptions.length) {
            var hovered = FlxG.mouse.overlaps(chapterOptions[index]);
            chapterOptions[index].color = hovered || index == currentChapter ? FlxColor.BLUE : FlxColor.fromRGB(190, 190, 190);
            if (hovered && FlxG.mouse.justPressed) {
                currentChapter = index;
                currentPageIndex = 0;
                currentPage = chapters[currentChapter].pages[0];
                loadCurrentPage();
                closeChapterList();
                break;
            }
        }
    }

    function closeChapterList():Void
    {
        chapterListOpen = false;
        for (option in chapterOptions) option.visible = false;
    }

    function changeChapter(direction:Int):Void
    {
        if (chapters.length == 0) return;
        var next = currentChapter + direction;
        if (next < 0 || next >= chapters.length) return;
        currentChapter = next;
        currentPageIndex = 0;
        currentPage = chapters[currentChapter].pages[0];
        loadCurrentPage();
        if (chapterListOpen) openChapterList();
    }

    function changePage(direction:Int):Void
    {
        if (chapters.length == 0 || pageChangeCooldown > 0) return;
        var nextPage = currentPageIndex + direction;
        if (nextPage < 0 || nextPage >= chapters[currentChapter].pages.length) {
            pageChangeCooldown = 0.35;
            return;
        }
        currentPageIndex = nextPage;
        currentPage = chapters[currentChapter].pages[currentPageIndex];
        pageChangeCooldown = 0.45;
        loadCurrentPage();
    }

    function exitReader():Void
    {
        canControl = false;
        FlxG.sound.play(Paths.sound('cancelMenu'));
        MusicBeatState.switchState(new SideStoryMenuState());
    }

    function exitToSideStoryMenu():Void
    {
        canControl = false;
        FlxG.sound.play(Paths.sound('cancelMenu'));
        MusicBeatState.switchState(new SideStoryMenuState());
    }
}
