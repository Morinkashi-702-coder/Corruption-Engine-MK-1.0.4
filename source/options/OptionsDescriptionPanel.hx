package options;

import flixel.FlxCamera;

/** Shared modern options description, fixed to screen space regardless of menu zoom. */
class OptionsDescriptionPanel extends FlxSpriteGroup
{
	public var background:FlxSprite;
	public var label:FlxText;
	var panelCamera:FlxCamera;

	public function new(description:String = '')
	{
		super();
		panelCamera = new FlxCamera();
		panelCamera.bgColor.alpha = 0;
		FlxG.cameras.add(panelCamera, false);
		background = new FlxSprite(24, 24).makeGraphic(420, 210, 0xFF101018);
		background.alpha = 0.9;
		background.scrollFactor.set();
		add(background);
		label = new FlxText(42, 38, 384, description, 20);
		label.setFormat(Paths.font('VollkornRegular-ZVJEZ.ttf'), 20, FlxColor.WHITE, LEFT);
		label.scrollFactor.set();
		add(label);
		cameras = [panelCamera];
	}

	override function destroy():Void
	{
		super.destroy();
		if (panelCamera != null)
		{
			FlxG.cameras.remove(panelCamera, true);
			panelCamera = null;
		}
	}
}
