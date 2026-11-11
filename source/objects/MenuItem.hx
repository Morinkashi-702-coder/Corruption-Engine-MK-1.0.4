package objects;

import flixel.FlxSprite;
import flixel.util.FlxColor;
import backend.ClientPrefs;
import backend.Paths;

class MenuItem extends FlxSprite
{
	public var targetY:Float = 0;

	public function new(x:Float, y:Float, weekName:String = '')
	{
		super(x, y);
		
		trace("✓ MenuItem constructor called with weekName: " + weekName);
		
		// Intentar cargar la imagen de la semana
		if (weekName != '' && weekName != null) {
			try {
				// Intentar ruta primaria: storymenu/weekName
				var imagePath:String = 'storymenu/' + weekName;
				trace("  Attempting to load image from path: " + imagePath);
				// No pedirle un placeholder global a Paths.image(): algunos targets
				// intentan resolver su key como asset durante draw() y pueden crashear.
				if (Paths.fileExists('images/' + imagePath + '.png', IMAGE)) {
					var graphic = Paths.image(imagePath);
					if (graphic != null)
					{
						loadGraphic(graphic);
						trace("✓ MenuItem loaded image successfully: " + imagePath);
					}
					else
					{
						makeGraphic(300, 150, FlxColor.TRANSPARENT);
						alpha = 0;
					}
				} else {
					trace("⚠ MenuItem image missing, using safe in-memory graphic: " + imagePath);
					makeGraphic(300, 150, FlxColor.TRANSPARENT);
					alpha = 0;
				}
			} catch (e:Dynamic) {
				trace("✗ Error loading MenuItem image for " + weekName + ": " + e);
				// Crear sprite transparente
				makeGraphic(300, 150, FlxColor.TRANSPARENT);
				alpha = 0;
				trace("  Exception: created transparent placeholder");
			}
		} else {
			// Si no hay weekName, crear placeholder transparente
			trace("  No weekName provided, creating transparent placeholder");
			makeGraphic(300, 150, FlxColor.TRANSPARENT);
			alpha = 0;
		}
		
		antialiasing = ClientPrefs.data.antialiasing;
		trace("✓ MenuItem constructor completed");
	}

	public var isFlashing(default, set):Bool = false;
	private var _flashingElapsed:Float = 0;
	final _flashColor = 0xFF33FFFF;
	final flashes_ps:Int = 6;

	public function set_isFlashing(value:Bool = true):Bool
	{
		isFlashing = value;
		_flashingElapsed = 0;
		color = (isFlashing) ? _flashColor : FlxColor.WHITE;
		return isFlashing;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (isFlashing)
		{
			_flashingElapsed += elapsed;
			color = (Math.floor(_flashingElapsed * FlxG.updateFramerate * flashes_ps) % 2 == 0) ? _flashColor : FlxColor.WHITE;
		}
	}
}
