package states.editors.content;

import backend.Song.SwagSong;
import flixel.group.FlxGroup;
import objects.Character;
import objects.Note;

class CharacterPreviewWindow extends FlxGroup
{
	var background:FlxSprite;
	var titleBar:FlxSprite;
	var title:FlxText;
	var grip:FlxText;
	var emptyLabel:FlxText;
	var closeButton:FlxSprite;
	var closeLabel:FlxText;
	var actor:Character;
	var characterId:String;
	final role:Int;
	var titleHovered:Bool = false;
	var closeHovered:Bool = false;
	var sourceWidth:Float;
	var sourceHeight:Float;
	var windowX:Float;
	var windowY:Float;
	var windowWidth:Float;
	var windowHeight:Float;
	var dragging:Bool = false;
	var resizeX:Int = 0;
	var resizeY:Int = 0;
	static inline final EDGE = 6;
	static inline final MIN_WIDTH = 160;
	static inline final TITLE_HEIGHT = 34;
	static inline final MIN_HEIGHT = 120;
	var grabX:Float;
	var grabY:Float;
	var previewCamera:FlxCamera;
	var lastBeat:Null<Int>;
	var singUntil:Float = -1;
	static final singAnimations = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];
	public static final roles = ['Boyfriend', 'Dad', 'Girlfriend', 'BF Extra 1', 'BF Extra 2', 'Dad Extra 1', 'Dad Extra 2'];

	public function new(camera:FlxCamera, role:Int)
	{
		super();
		this.role = role;
		previewCamera = camera;
		background = makePanel(0xFF171922);
		titleBar = makePanel(0xFFFFFFFF);
		grip = makeLabel(':::', 16);
		grip.color = 0xFFBFC4D4;
		title = makeLabel(roles[role], 13);
		closeButton = makePanel(0xFFFFFFFF);
		emptyLabel = makeLabel('No character assigned', 11);
		emptyLabel.alignment = CENTER;
		emptyLabel.color = 0xFFBFC4D4;
		closeLabel = makeLabel('X', 14);
		resetBounds();
		visible = active = false;
	}

	function makePanel(color:FlxColor):FlxSprite
	{
		var panel = new FlxSprite().makeGraphic(1, 1, color);
		panel.scrollFactor.set();
		panel.cameras = [previewCamera];
		add(panel);
		return panel;
	}

	function makeLabel(value:String, size:Int):FlxText
	{
		var label = new FlxText(0, 0, 0, value, size);
		label.scrollFactor.set();
		label.cameras = [previewCamera];
		add(label);
		return label;
	}

	public function resetBounds():Void
	{
		var opponentSide = role == 1 || role == 5 || role == 6;
		var upperRow = role == 2 || role == 4 || role == 5;
		windowWidth = 206;
		windowHeight = opponentSide ? 154 : 162;
		windowX = switch (role)
		{
			case 1, 5: 0;
			case 6: windowWidth;
			case 3, 4: FlxG.width - windowWidth * 2;
			default: FlxG.width - windowWidth;
		};
		windowY = FlxG.height - windowHeight * (upperRow ? 2 : 1);
	}

	public function setOpen(open:Bool):Void
	{
		visible = active = open;
		dragging = false;
		resizeX = resizeY = 0;
		resetSinging();
		if (!open) replaceActor(null);
	}

	public function handlePointer():Bool
	{
		if (!visible) return false;
		var mouse = FlxG.mouse.getScreenPosition(previewCamera);
		var x = mouse.x;
		var y = mouse.y;
		mouse.put();
		var right = windowX + windowWidth;
		var bottom = windowY + windowHeight;
		var inside = x >= windowX && x < right && y >= windowY && y < bottom;
		titleHovered = inside && y >= windowY + EDGE && y < windowY + TITLE_HEIGHT;
		closeHovered = titleHovered && x >= right - 32 && x < right - EDGE;
		var captured = dragging || resizeX != 0 || resizeY != 0;
		if (!FlxG.mouse.pressed)
		{
			dragging = false;
			resizeX = resizeY = 0;
		}
		if (FlxG.mouse.justPressed && inside)
		{
			if (closeHovered)
			{
				setOpen(false);
				return true;
			}
			resizeX = x < windowX + EDGE ? -1 : (x >= right - EDGE ? 1 : 0);
			resizeY = y < windowY + EDGE ? -1 : (y >= bottom - EDGE ? 1 : 0);
			dragging = resizeX == 0 && resizeY == 0 && titleHovered;
			grabX = x - (resizeX > 0 ? right : windowX);
			grabY = y - (resizeY > 0 ? bottom : windowY);
		}
		if (dragging)
		{
			windowX = FlxMath.bound(x - grabX, 0, FlxG.width - windowWidth);
			windowY = FlxMath.bound(y - grabY, 0, FlxG.height - windowHeight);
		}
		if (resizeX < 0)
		{
			windowX = FlxMath.bound(x - grabX, 0, right - MIN_WIDTH);
			windowWidth = right - windowX;
		}
		else if (resizeX > 0)
			windowWidth = FlxMath.bound(x - grabX - windowX, MIN_WIDTH, FlxG.width - windowX);
		if (resizeY < 0)
		{
			windowY = FlxMath.bound(y - grabY, 0, bottom - MIN_HEIGHT);
			windowHeight = bottom - windowY;
		}
		else if (resizeY > 0)
			windowHeight = FlxMath.bound(y - grabY - windowY, MIN_HEIGHT, FlxG.height - windowY);
		return inside || captured;
	}

	function replaceActor(id:String):Void
	{
		if (actor != null)
		{
			remove(actor, true);
			actor.destroy();
		}
		characterId = id;
		actor = null;
		singUntil = -1;
		if (id == null) return;

		actor = new Character(0, 0, id, role == 0 || role == 3 || role == 4);
		actor.debugMode = true;
		actor.scrollFactor.set();
		actor.cameras = [previewCamera];
		sourceWidth = Math.max(1, actor.frameWidth);
		sourceHeight = Math.max(1, actor.frameHeight);
		if (actor.frames != null)
			for (frame in actor.frames.frames)
			{
				sourceWidth = Math.max(sourceWidth, frame.sourceSize.x);
				sourceHeight = Math.max(sourceHeight, frame.sourceSize.y);
			}
		lastBeat = null;
		add(actor);
	}

	public function resetSinging():Void
	{
		singUntil = -1;
		lastBeat = null;
	}

	public static function characterIds(song:SwagSong):Array<String>
	{
		return [song.player1, song.player2, song.gfVersion, song.player3, song.player4, song.player5, song.player6];
	}

	public static function hasCharacter(id:String):Bool
	{
		return id != null && id != '' && id != 'none' && id != 'nogf';
	}

	public function noteHit(note:Note, stepDuration:Float):Void
	{
		if (!visible || actor == null || note.noAnimation || note.hitCausesMiss) return;
		var direction = singAnimations[note.noteData];
		if (direction == null) return;
		var animation = note.noteType == 'Hey!' ? (role == 2 ? 'cheer' : 'hey') : direction + note.animSuffix;
		if (!actor.hasAnimation(animation)) animation = direction;
		if (!actor.hasAnimation(animation)) return;
		actor.playAnim(animation, true);
		singUntil = note.strumTime + Math.max(note.sustainLength, stepDuration * actor.singDuration);
	}

	public function refresh(id:String, beat:Int, time:Float):Void
	{
		if (!visible) return;
		if (!hasCharacter(id)) id = null;
		if (id != characterId) replaceActor(id);

		background.setPosition(windowX, windowY);
		background.scale.set(windowWidth, windowHeight);
		background.origin.set();
		titleBar.color = dragging ? 0xFF535E85 : (titleHovered ? 0xFF444E6C : 0xFF323849);
		titleBar.setPosition(windowX + EDGE, windowY + EDGE);
		titleBar.scale.set(windowWidth - EDGE * 2, TITLE_HEIGHT - EDGE);
		titleBar.origin.set();
		grip.setPosition(windowX + 11, windowY + 8);
		title.setPosition(windowX + 35, windowY + 11);
		closeButton.color = closeHovered ? 0xFFB5445F : 0xFF202534;
		closeButton.setPosition(windowX + windowWidth - 31, windowY + 9);
		closeButton.origin.set();
		closeButton.scale.set(22, 22);
		closeLabel.setPosition(windowX + windowWidth - 25, windowY + 10);
		emptyLabel.visible = actor == null;
		if (actor == null)
		{
			emptyLabel.fieldWidth = windowWidth;
			emptyLabel.setPosition(windowX, windowY + (windowHeight + TITLE_HEIGHT) / 2 - 8);
			return;
		}
		if (time >= singUntil && (beat != lastBeat || singUntil >= 0))
		{
			singUntil = -1;
			actor.debugMode = false;
			actor.dance();
			actor.debugMode = true;
		}
		fitActor(actor, windowX + EDGE, windowY + TITLE_HEIGHT + 4, windowWidth - EDGE * 2, windowHeight - TITLE_HEIGHT - 10);
		lastBeat = beat;
	}

	function fitActor(actor:Character, x:Float, y:Float, width:Float, height:Float):Void
	{
		actor.origin.set();
		#if flxanimate
		if (actor.isAnimateAtlas)
		{
			var atlas = actor.atlas;
			var ratio = atlas.width > 0 && atlas.height > 0
				? Math.min((width - 8) / atlas.width, (height - 3) / atlas.height) : 1;
			var zoom = Math.min(2, actor.scale.x * ratio);
			ratio = zoom / actor.scale.x;
			actor.setPosition(x + (width - atlas.width * ratio) / 2 - atlas.relativeX * ratio,
				y + (height - atlas.height * ratio) / 2 - atlas.relativeY * ratio);
			actor.scale.set(zoom, zoom);
			return;
		}
		#end
		var frameWidth = Math.max(1, actor.frameWidth);
		var frameHeight = Math.max(1, actor.frameHeight);
		var zoom = Math.min((width - 8) / sourceWidth, (height - 3) / sourceHeight);
		actor.scale.set(zoom, zoom);
		actor.setPosition(x + (width - frameWidth * zoom) / 2 + actor.offset.x,
			y + (height - frameHeight * zoom) / 2 + actor.offset.y);
	}
}
