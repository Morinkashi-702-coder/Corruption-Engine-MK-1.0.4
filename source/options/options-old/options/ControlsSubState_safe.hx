package options;

class ControlsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Controls Settings';
		rpcTitle = 'Controls Settings Menu';
		showBackground = false; // Desactivar el fondo para ControlsSubState

		// Por ahora solo opciones básicas sin KEYBIND para evitar crashes
		var option:Option = new Option('Ghost Tapping',
			"If checked, you won't get misses from pressing keys\nwhile there are no notes able to be hit.",
			'ghostTapping',
			BOOL);
		addOption(option);

		var option:Option = new Option('Downscroll',
			'If checked, notes go Down instead of Up, simple enough.',
			'downScroll',
			BOOL);
		addOption(option);

		var option:Option = new Option('Middlescroll',
			'If checked, your notes get centered.',
			'middleScroll',
			BOOL);
		addOption(option);

		super();
	}
}