package states;

import flixel.FlxG;
import flixel.FlxState;

/**
 * MenuDemoSempai - Transición al menú clásico oldmenu
 */
class MenuDemoSempai extends FlxState
{
	override public function create():Void
	{
		super.create();
		trace('[MENU DEMO SEMPAI] Transitioning to classic menu...');
		FlxG.switchState(new MainMenuState_oldmenu());
	}
}