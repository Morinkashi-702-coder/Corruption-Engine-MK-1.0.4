package backend.ui;

import flixel.util.FlxDestroyUtil;
import flixel.math.FlxPoint;

class PsychUITab extends FlxSprite
{
	public var name(default, set):String;
	public var text:FlxText;
	public var menu:FlxSpriteGroup = new FlxSpriteGroup();

	public function new(name:String)
	{
		super();
		makeGraphic(1, 1, FlxColor.WHITE);
		color = FlxColor.BLACK;
		alpha = 0.6;

		@:bypassAccessor this.name = name;
		text = new FlxText(0, 0, 100, name);
		text.alignment = CENTER;
	}

	override function draw()
	{
		super.draw();

		if(visible && text != null && text.exists && text.visible)
		{
			text.x = x;
			text.y = y + height/2 - text.height/2;
			text.draw();
		}
	}

	override function destroy()
	{
		text = FlxDestroyUtil.destroy(text);
		menu = FlxDestroyUtil.destroy(menu);
		super.destroy();
	}
	
	public function updateMenu(parent:PsychUIBox, elapsed:Float)
	{
		if(menu != null && menu.exists && menu.active)
		{
			menu.scrollFactor.set(parent.scrollFactor.x, parent.scrollFactor.y);
			menu.update(elapsed);
			bringOpenDropDownToFront();
		}
	}

	// evita que un dropdown abierto quede tapado por controles agregados después que él
	function bringOpenDropDownToFront()
	{
		if(menu == null || menu.members == null) return;

		var openDropDown:PsychUIDropDownMenu = null;
		for (member in menu.members)
		{
			if(member != null && Std.isOfType(member, PsychUIDropDownMenu) && PsychUIInputText.focusOn == member)
				openDropDown = cast member;
		}

		if(openDropDown != null)
		{
			var idx:Int = menu.members.indexOf(openDropDown);
			if(idx >= 0 && idx != menu.members.length - 1)
			{
				menu.members.splice(idx, 1);
				menu.members.push(openDropDown);
			}
		}
	}

	public function drawMenu(parent:PsychUIBox)
	{
		if(menu != null && menu.exists && menu.visible)
		{
			menu.x = parent.x;
			menu.y = parent.y + parent.tabHeight;
			menu.draw();
		}
	}

	public function resize(width:Int, height:Int)
	{
		setGraphicSize(width, height);
		updateHitbox();
		text.fieldWidth = width;
	}

	function set_name(v:String)
	{
		text.text = v;
		return (name = v);
	}


	override function set_cameras(v:Array<FlxCamera>)
	{
		text.cameras = v;
		menu.cameras = v;
		return super.set_cameras(v);
	}

	override function set_camera(v:FlxCamera)
	{
		text.camera = v;
		menu.camera = v;
		return super.set_camera(v);
	}
}