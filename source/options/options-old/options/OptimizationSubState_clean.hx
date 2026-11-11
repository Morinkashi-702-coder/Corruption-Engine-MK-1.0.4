wpackage options;

import flixel.text.FlxText;
import flixel.util.FlxColor;

class OptimizationSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = Language.getPhrase('optimization_menu', 'Optimization');
		rpcTitle = 'Optimization Settings Menu'; //for Discord Rich Presence

		var option:Option = new Option('Disable Menu Shaders',
			"If checked, disables menu shaders and effects (wave, glitch, etc.) for better performance.",
			'menuShaders',
			BOOL);
		option.onChange = onChangeMenuShaders;
		addOption(option);

		super();
	}

	function onChangeMenuShaders()
	{
		if(ClientPrefs.data.menuShaders) {
			// Aplicar shaders cuando esté habilitado
		} else {
			// Remover shaders cuando esté deshabilitado
		}
	}
}