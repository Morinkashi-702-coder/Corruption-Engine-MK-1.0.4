package options;

import objects.Note;
import objects.StrumNote;
import objects.NoteSplash;

class VisualsSettingsSubState extends BaseOptionsMenu
{
	var noteOptionID:Int = -1;
	var notes:FlxTypedGroup<StrumNote>;
	var splashes:FlxTypedGroup<NoteSplash>;
	var noteY:Float = -202;
	var noteHideY:Float = FlxG.height + 200;

	public function new()
	{
		title = 'Visuals Settings';
		rpcTitle = 'Visuals Settings Menu';

		//I'd suggest using "Downscroll" as an example for making your own option since it is the simplest here
		var option:Option = new Option('Note Splashes',
			"If unchecked, hitting \"Sick!\" notes won't show particles.",
			'noteSplashes',
			BOOL);
		addOption(option);

		var option:Option = new Option('Hide HUD',
			'If checked, hides most HUD elements.',
			'hideHud',
			BOOL);
		addOption(option);
		
		var option:Option = new Option('Time Bar:',
			"What should the Time Bar display?",
			'timeBarType',
			STRING,
			['Time Left', 'Time Elapsed', 'Song Name', 'Disabled']);
		addOption(option);

		var option:Option = new Option('Flashing Lights',
			"Uncheck this if you're sensitive to flashing lights!",
			'flashing',
			BOOL);
		addOption(option);

		var option:Option = new Option('Camera Zooms',
			"If unchecked, the camera won't zoom in on a beat hit.",
			'camZooms',
			BOOL);
		addOption(option);

		var option:Option = new Option('Score Text Zoom on Hit',
			"If unchecked, disables the Score text zooming\neverytime you hit a note.",
			'scoreZoom',
			BOOL);
		addOption(option);

		var option:Option = new Option('Health Bar Transparency',
			'How much transparent should the health bar and icons be.',
			'healthBarAlpha',
			PERCENT);
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		addOption(option);

		var option:Option = new Option('Opponent Notes',
			'If unchecked, opponent notes get hidden.',
			'opponentStrums',
			BOOL);
		addOption(option);

		var option:Option = new Option('Results Screen',
			'If unchecked, Results Screen is disabled.',
			'resultsScreen',
			BOOL);
		addOption(option);

		var option:Option = new Option('Pause Screen Song:',
			"What song do you prefer for the Pause Screen?",
			'pauseMusic',
			STRING,
			['None', 'Breakfast', 'Tea Time']);
		addOption(option);
		noteOptionID = optionsArray.length;

		var option:Option = new Option('Check for Updates',
			'On Release builds, turn this on to check for updates when you start the game.',
			'checkForUpdates',
			BOOL);
		addOption(option);

		var option:Option = new Option('Combo Stacking',
			"If unchecked, Ratings and Combo won't stack, saving on System Memory and making them easier to read",
			'comboStacking',
			BOOL);
		addOption(option);

		super();

		// for note skins and splash skins
		notes = new FlxTypedGroup<StrumNote>();
		splashes = new FlxTypedGroup<NoteSplash>();
		add(notes);
		add(splashes);

		for (i in 0...4)
		{
			var note:StrumNote = new StrumNote(776 + (177 * i), -202, i, 0);
			note.centerOffsets();
			note.centerOrigin();
			note.playAnim('static');
			notes.add(note);

			var splash:NoteSplash = new NoteSplash();
			splash.noteData = i;
			splash.setPosition(note.x, note.y);
			splash.loadSplash();
			splash.visible = false;
			splash.alpha = ClientPrefs.data.splashAlpha;
			splashes.add(splash);
		}
		changeSelection();
	}

	override function changeSelection(change:Int = 0)
	{
		super.changeSelection(change);
		
		if(noteOptionID < 0) return;
		
		if(curSelected == noteOptionID) {
			for (i in 0...notes.length)
			{
				var note = notes.members[i];
				if(note != null)
				{
					FlxTween.cancelTweensOf(note);
					FlxTween.tween(note, {y: noteY}, 0.3, {ease: FlxEase.quadOut});
				}
			}
		} else {
			for (i in 0...notes.length)
			{
				var note = notes.members[i];
				if(note != null)
				{
					FlxTween.cancelTweensOf(note);
					FlxTween.tween(note, {y: noteHideY}, 0.3, {ease: FlxEase.quadIn});
				}
			}
		}
	}
}