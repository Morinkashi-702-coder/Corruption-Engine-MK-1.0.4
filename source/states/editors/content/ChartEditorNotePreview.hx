package states.editors.content;

import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flash.geom.Rectangle;

/**
 * Adapted from FunkinCrew's ChartEditorNotePreview (Apache 2.0).
 * Copyright 2020-2024 The Funkin' Crew Inc.
 * https://github.com/FunkinCrew/Funkin/blob/94ee0f2a9386d80e445be39ee2ed4b4a630cfbac/source/funkin/ui/debug/charting/components/ChartEditorNotePreview.hx
 */
class ChartEditorNotePreview extends FlxSprite
{
	static inline final NOTE_WIDTH = 5;
	public static inline final WIDTH = NOTE_WIDTH * 9;

	static inline final BG_COLOR:FlxColor = 0xFF606060;
	static inline final LEFT_COLOR:FlxColor = 0xFFFF22AA;
	static inline final DOWN_COLOR:FlxColor = 0xFF00EEFF;
	static inline final UP_COLOR:FlxColor = 0xFF00CC00;
	static inline final RIGHT_COLOR:FlxColor = 0xFFCC1111;
	static inline final EVENT_COLOR:FlxColor = 0xFF111111;
	static inline final SELECTED_COLOR:FlxColor = 0xFFFFFF00;
	static inline final OVERLAPPING_COLOR:FlxColor = 0xFF640000;

	final mark = new Rectangle(0, 0, NOTE_WIDTH, 1);

	public function beginDraw(height:Int):Void
	{
		if (frameHeight != height) makeGraphic(WIDTH, height, BG_COLOR, true);
		pixels.lock();
		pixels.fillRect(pixels.rect, BG_COLOR);
	}

	public function drawNote(dir:Int, mustHit:Bool, progress:Float, selected:Bool = false, overlapping:Bool = false):Void
	{
		var color:FlxColor = switch (dir)
		{
			case 0: LEFT_COLOR;
			case 1: DOWN_COLOR;
			case 2: UP_COLOR;
			case 3: RIGHT_COLOR;
			default: EVENT_COLOR;
		};

		var noteHeight = 1;
		if (selected)
		{
			color = SELECTED_COLOR;
			noteHeight = 2;
		}
		else if (overlapping)
		{
			color = OVERLAPPING_COLOR;
			noteHeight = 3;
		}

		mark.x = NOTE_WIDTH * (dir == -1 ? 8 : dir + (mustHit ? 4 : 0));
		mark.y = Math.floor(FlxMath.bound(progress, 0, 1) * (frameHeight - 1));
		mark.height = noteHeight;
		pixels.fillRect(mark, color);
	}

	public function endDraw():Void
	{
		pixels.unlock();
		dirty = true;
	}
}
