package options;

import backend.Diagnostics;
import lime.system.Clipboard;
import openfl.net.FileReference;
import openfl.events.Event;
import openfl.events.IOErrorEvent;

/** Uses the same shared layout, scrolling, arrows and CRT as Graphics/Gameplay. */
class DebugSubState extends BaseOptionsMenu
{
	var saveDialog:FileReference;
	var reportActions:Array<Option> = [];
	var actionDescriptions:Array<String> = [];

	public function new(oldMenuStyle:Bool)
	{
		title = 'Debug';
		rpcTitle = 'Debug / Diagnostics';
		var automatic = new Option('Automatic Reports',
			'Save a local TXT in Reports when the engine closes or catches a crash.\nDisabled by default. Nothing is uploaded.',
			'automaticReports', BOOL);
		automatic.onChange = ClientPrefs.saveSettings;
		addOption(automatic);
		addAction('Copy Report', 'Copy system information and recent warnings to the clipboard.', copyReport);
		addAction('Save Report', 'Save a support report as a text file. Nothing is uploaded.', saveReport);
		addAction('Refresh Report', 'Refresh the diagnostic summary. This does not change your settings.', refreshReport);
		super(oldMenuStyle);
		addReportSectionHeader(oldMenuStyle);
	}

	function addReportSectionHeader(oldMenuStyle:Bool):Void
	{
		var color:FlxColor = oldMenuStyle ? 0xFF00FF00 : FlxColor.WHITE;
		var heading = new FlxText(oldMenuStyle ? 100 : 472, oldMenuStyle ? 79 : -125,
			oldMenuStyle ? FlxG.width - 200 : 900, 'ERROR REPORTS', oldMenuStyle ? 18 : 32);
		heading.setFormat(Paths.font(oldMenuStyle ? 'pixel.otf' : 'VollkornRegular-ZVJEZ.ttf'),
			oldMenuStyle ? 18 : 32, color, LEFT);
		var divider = new FlxSprite(oldMenuStyle ? 100 : 472, oldMenuStyle ? 103 : -75)
			.makeGraphic(oldMenuStyle ? FlxG.width - 200 : 900, 2, color);
		if (oldMenuStyle)
		{
			// Keep the section underneath the existing CRT glass/frame.
			insert(members.length - 1, heading);
			insert(members.length - 1, divider);
		}
		else
		{
			add(heading);
			add(divider);
		}
	}

	function addAction(name:String, description:String, callback:Void->Void):Void
	{
		var option = new Option(name, Diagnostics.summary() + '\n' + description, '', ACTION);
		option.onChange = callback;
		reportActions.push(option);
		actionDescriptions.push(description);
		addOption(option);
	}

	function status(message:String):Void
	{
		if (descText != null && descText.exists)
			descText.text = Diagnostics.summary() + '\n' + message;
	}

	function copyReport():Void
	{
		try
		{
			Clipboard.text = Diagnostics.report();
			status('Report copied. Review it before sharing.');
		}
		catch (_:Dynamic) status('Could not copy the report. Try Save Report.');
	}

	function saveReport():Void
	{
		if (saveDialog != null) return;
		try
		{
			saveDialog = new FileReference();
			saveDialog.addEventListener(Event.COMPLETE, onSaved);
			saveDialog.addEventListener(Event.CANCEL, onCancelled);
			saveDialog.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			saveDialog.save(Diagnostics.report(), 'CorruptionEngine-diagnostics.txt');
		}
		catch (_:Dynamic)
		{
			releaseDialog();
			status('Could not save the report. Try Copy Report.');
		}
	}

	function onSaved(_:Event):Void { releaseDialog(); status('Report saved. Nothing was uploaded.'); }
	function onCancelled(_:Event):Void { releaseDialog(); status('Save cancelled.'); }
	function onSaveError(_:IOErrorEvent):Void { releaseDialog(); status('Could not save the report.'); }

	function releaseDialog():Void
	{
		if (saveDialog == null) return;
		saveDialog.removeEventListener(Event.COMPLETE, onSaved);
		saveDialog.removeEventListener(Event.CANCEL, onCancelled);
		saveDialog.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		saveDialog = null;
	}

	function refreshReport():Void
	{
		for (i in 0...reportActions.length)
			reportActions[i].description = Diagnostics.summary() + '\n' + actionDescriptions[i];
		status('Diagnostic information refreshed.');
	}

	override function destroy():Void
	{
		releaseDialog();
		super.destroy();
	}
}
