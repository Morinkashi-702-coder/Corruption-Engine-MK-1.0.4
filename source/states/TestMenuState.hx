package states;

import flixel.FlxG;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.util.FlxColor;

/**
 * TestMenuState - Menú de prueba para testear cambios sin recompilar
 * Útil para testing rápido de nuevas características
 */
class TestMenuState extends FlxState
{
	private var title:FlxText;
	private var instructionText:FlxText;

	override public function create():Void
	{
		super.create();
		
		bgColor = 0xFF1a1a2e;

		// Título
		title = new FlxText(0, 100, FlxG.width, "TEST MENU");
		title.setFormat("VCR OSD Mono", 64, FlxColor.CYAN, CENTER);
		add(title);

		// Instrucciones
		var instructions:String = "Este es el menú de TEST para experimentar\n\n";
		instructions += "Presiona:\n";
		instructions += "← → para cambiar de menú\n";
		instructions += "ENTER para ir al menú principal\n";
		instructions += "ESC para ir a NoticesState\n";

		instructionText = new FlxText(0, 300, FlxG.width, instructions);
		instructionText.setFormat("VCR OSD Mono", 24, FlxColor.WHITE, CENTER);
		add(instructionText);

		// Info del menú activo
		var currentMenuText = new FlxText(0, 650, FlxG.width, "Menú Actual: " + backend.MenuSelector.currentMenu);
		currentMenuText.setFormat("VCR OSD Mono", 20, FlxColor.LIME, CENTER);
		add(currentMenuText);

		trace('[TEST MENU] Menú de prueba cargado');
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (FlxG.keys.justPressed.LEFT)
		{
			backend.MenuSelector.previousMenu();
			FlxG.switchState(new TestMenuState());
		}

		if (FlxG.keys.justPressed.RIGHT)
		{
			backend.MenuSelector.nextMenu();
			FlxG.switchState(new TestMenuState());
		}

		if (FlxG.keys.justPressed.ENTER)
		{
			// Ir al menú correspondiente según la selección
			var current = backend.MenuSelector.getMenu();
			switch(current)
			{
				case "oldmenu":
					FlxG.switchState(new MenuDemoSempai());
				default:
					FlxG.switchState(new SoftCodeMenuState());
			}
		}

		if (FlxG.keys.justPressed.ESCAPE)
		{
			FlxG.switchState(new NoticesState());
		}
	}
}
