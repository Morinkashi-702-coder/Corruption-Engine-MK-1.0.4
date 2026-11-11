package options;

class ControlsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Controls Settings';
		rpcTitle = 'Controls Settings Menu';

		//I'd suggest using "Low Quality" as an example for making your own option since it is the simplest here
		var option:Option = new Option('Control Mode',
			'Choose what you want your control mode to be.\nEither Keyboard, Gamepad or Both.',
			'controllerMode',
			INT);
		option.minValue = 0;
		option.maxValue = 2;
		option.displayFormat = '%v';
		option.changeValue = 1;
		option.curOption = ClientPrefs.data.controllerMode;
		option.options = ['Keyboard', 'Gamepad', 'Both'];
		addOption(option);

		//Keyboard binds
		var option:Option = new Option('UI_LEFT',
			'The keybind to move left on the menus.',
			'keyBinds',
			KEYBIND);
		addOption(option);

		var option:Option = new Option('UI_DOWN',
			'The keybind to move down on the menus.',
			'keyBinds',
			KEYBIND);
		addOption(option);

		var option:Option = new Option('UI_UP',
			'The keybind to move up on the menus.',
			'keyBinds',
			KEYBIND);
		addOption(option);

		var option:Option = new Option('UI_RIGHT',
			'The keybind to move right on the menus.',
			'keyBinds',
			KEYBIND);
		addOption(option);

		var option:Option = new Option('NOTE_LEFT',
			'The keybind for the Left note.',
			'keyBinds',
			KEYBIND);
		addOption(option);

		var option:Option = new Option('NOTE_DOWN',
			'The keybind for the Down note.',
			'keyBinds',
			KEYBIND);
		addOption(option);

		var option:Option = new Option('NOTE_UP',
			'The keybind for the Up note.',
			'keyBinds',
			KEYBIND);
		addOption(option);

		var option:Option = new Option('NOTE_RIGHT',
			'The keybind for the Right note.',
			'keyBinds',
			KEYBIND);
		addOption(option);

		var option:Option = new Option('ACCEPT',
			'The keybind to accept/confirm something.',
			'keyBinds',
			KEYBIND);
		addOption(option);

		var option:Option = new Option('BACK',
			'The keybind to go back or exit.',
			'keyBinds',
			KEYBIND);
		addOption(option);

		var option:Option = new Option('PAUSE',
			'The keybind to pause the game.',
			'keyBinds',
			KEYBIND);
		addOption(option);

		var option:Option = new Option('RESET',
			'The keybind to reset current progress.',
			'keyBinds',
			KEYBIND);
		addOption(option);

		super();
	}
}