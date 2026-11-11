package options;

import flixel.text.FlxText;
import flixel.util.FlxColor;

class OptimizationSubState_oldmenu extends BaseOptionsMenu_oldmenu
{
	public function new()
	{
		title = Language.getPhrase('optimization_menu', 'Optimization');
		rpcTitle = 'Optimization Settings Menu'; //for Discord Rich Presence

		var option:Option = new Option('Disable Note Splashes',
			"If checked, disables note splash effects to save performance.",
			'noteSplashes',
			BOOL);
		addOption(option);

		var option:Option = new Option('Disable Menu Shaders',
			"If checked, disables menu shaders and effects (wave, glitch, etc.) for better performance.",
			'menuShaders',
			BOOL);
		addOption(option);

		var option:Option = new Option('Shader Quality',
			"Control the intensity of shader effects.\nUltra: Full intensity | High: 80% | Medium: 60% | Low: 40%",
			'shaderQuality',
			STRING,
			['Ultra', 'High', 'Medium', 'Low']);
		option.onChange = onChangeShaderQuality;
		addOption(option);

		var option:Option = new Option('Memory Management',
			"How aggressively the game manages memory.\nHigher = less memory usage but more loading.",
			'memoryManagement',
			INT);
		option.minValue = 0;
		option.maxValue = 2;
		option.displayFormat = '%v';
		option.onChange = onChangeMemoryManagement;
		addOption(option);

		var option:Option = new Option('Reduce Particles',
			"If checked, reduces particle effects for better performance.",
			'reduceParticles', BOOL);
		addOption(option);

		var option:Option = new Option('Disable Background Videos',
			"If checked, disables background videos to save performance.\nStatic images will be shown instead.",
			'backgroundVideos', BOOL);
		addOption(option);

		var option:Option = new Option('Simple Stage Graphics',
			"If checked, simplifies stage graphics and animations for better performance.",
			'simpleStageGraphics', BOOL);
		addOption(option);

		var option:Option = new Option('Disable Story Videos',
			"If checked, skips cutscene videos in Story Mode for faster loading.",
			'disableStoryVideos', BOOL);
		addOption(option);

		var option:Option = new Option('Skip Story Intros',
			"If checked, automatically skips long intro sequences in Story Mode.",
			'skipStoryIntros', BOOL);
		addOption(option);

		var option:Option = new Option('Fast Story Transitions',
			"If checked, speeds up transitions between songs in Story Mode.",
			'fastStoryTransitions', BOOL);
		addOption(option);

		var option:Option = new Option('Disable Story Dialogues',
			"If checked, skips dialogue sequences in Story Mode.",
			'disableStoryDialogues', BOOL);
		addOption(option);

		var option:Option = new Option('Story Auto Advance',
			"If checked, automatically advances to next song without waiting.",
			'storyAutoAdvance', BOOL);
		addOption(option);

		var option:Option = new Option('Simple Story Effects',
			"If checked, simplifies visual effects in Story Mode cutscenes.",
			'simpleStoryEffects', BOOL);
		addOption(option);

		super();

		var resetText:FlxText = new FlxText(0, 90, FlxG.width, 'Press R to reset all settings to defaults', 16);
		resetText.setFormat(Paths.font('vcr.ttf'), 16, FlxColor.GRAY, CENTER);
		resetText.scrollFactor.set();
		resetText.alpha = 0.7;
		add(resetText);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if(FlxG.keys.justPressed.R) resetToDefaults();
	}

	function onChangeMemoryManagement()
	{
		switch(ClientPrefs.data.memoryManagement)
		{
			case 0:
				#if !flash FlxG.bitmap.dumpCache(); #end
			case 1:
			case 2:
				#if !flash FlxG.bitmap.dumpCache(); #end
				Paths.clearUnusedMemory();
		}
	}

	function onChangeShaderQuality()
	{
		trace('[OPTIMIZATION] Shader Quality cambiado a: ' + ClientPrefs.data.shaderQuality);
		ClientPrefs.saveSettings();
		if (FlxG.state is states.SoftCodeMenuState)
		{
			var menuState:states.SoftCodeMenuState = cast FlxG.state;
			menuState.reloadShaderSettings();
		}
	}

	function resetToDefaults()
	{
		ClientPrefs.data.noteSplashes = false;
		ClientPrefs.data.memoryManagement = 1;
		ClientPrefs.data.reduceParticles = false;
		ClientPrefs.data.backgroundVideos = false;
		ClientPrefs.data.simpleStageGraphics = false;
		ClientPrefs.data.menuShaders = false;
		ClientPrefs.data.shaderQuality = 'Ultra';
		ClientPrefs.data.disableStoryVideos = false;
		ClientPrefs.data.skipStoryIntros = false;
		ClientPrefs.data.fastStoryTransitions = false;
		ClientPrefs.data.disableStoryDialogues = false;
		ClientPrefs.data.storyAutoAdvance = false;
		ClientPrefs.data.simpleStoryEffects = false;
		ClientPrefs.saveSettings();
		FlxG.sound.play(Paths.sound('confirmMenu'));
		reloadCheckboxes();
		trace('Optimization settings reset to defaults - Shaders set to ULTRA with full intensity');
	}
}
