package backend;

/** Bounded support log with local reports on normal exit or a handled crash. */
class Diagnostics
{
	static var installed:Bool = false;
	static var recent:Array<String> = [];
	static inline var LIMIT:Int = 40;
	static var exitReportSaved:Bool = false;
	static var crashDetected:Bool = false;

	static function isProblem(message:String):Bool
	{
		// Match whole words: "showscripterrors" is a setting, not an error.
		// Phrase boundaries also prevent "interno existe" from matching "no existe".
		return ~/\b(errors?|warnings?|failed|missing)\b|\bnot\s+found\b|\bno\s+existen?\b/i.match(message);
	}

	public static function install():Void
	{
		if (installed) return;
		installed = true;
		#if sys
		if (lime.app.Application.current != null)
			lime.app.Application.current.onExit.add(function(code:Int):Void {
				if (!crashDetected) saveAutomatic('exit', 'Application exit code: ' + code);
			});
		#end
		var previous = haxe.Log.trace;
		haxe.Log.trace = function(value:Dynamic, ?position:haxe.PosInfos):Void
		{
			try
			{
				var message = Std.string(value);
				if (isProblem(message))
				{
					message = sanitize(message).substr(0, 500);
					if (recent.length == 0 || recent[recent.length - 1] != message)
					{
						recent.push(message);
						if (recent.length > LIMIT) recent.shift();
					}
				}
			}
			catch (_:Dynamic) {} // Diagnostics must never interrupt the original trace.
			previous(value, position);
		};
	}

	/** Best effort: a reporting failure must not prevent the engine from exiting. */
	public static function saveAutomatic(reason:String, details:String = ''):String
	{
		#if sys
		if (reason == 'crash') crashDetected = true;
		else if (exitReportSaved || crashDetected) return null;
		try
		{
			if (ClientPrefs.data == null || !ClientPrefs.data.automaticReports) return null;
			var directory = haxe.io.Path.join([haxe.io.Path.directory(Sys.programPath()), 'Reports']);
			if (!sys.FileSystem.exists(directory)) sys.FileSystem.createDirectory(directory);
			var stamp = DateTools.format(Date.now(), '%Y-%m-%d_%H-%M-%S');
			var base = haxe.io.Path.join([directory, 'Report-' + (reason == 'crash' ? 'crash' : 'exit') + '-' + stamp]);
			var path = base + '.txt';
			var suffix = 1;
			while (sys.FileSystem.exists(path)) path = base + '-' + suffix++ + '.txt';
			var body:String;
			try { body = report(); }
			catch (_:Dynamic)
			{
				// A crash may happen before preferences or game configuration exist.
				body = 'CORRUPTION ENGINE - SUPPORT REPORT\nGenerated: ' + Date.now().toString()
					+ '\nPartial report: full diagnostic information was unavailable.\n'
					+ recent.join('\n');
			}
			body += '\n\nAUTOMATIC REPORT: ' + reason.toUpperCase() + '\n' + sanitize(details).substr(0, 32000);
			sys.io.File.saveContent(path, body + '\n');
			if (reason != 'crash') exitReportSaved = true;
			return path;
		}
		catch (_:Dynamic) return null;
		#else
		return null;
		#end
	}

	public static function sanitize(value:String):String
	{
		var result = value;
		#if sys
		var folder = Sys.getCwd();
		result = StringTools.replace(result, folder, '[game]/');
		result = StringTools.replace(result, StringTools.replace(folder, '\\', '/'), '[game]/');
		result = StringTools.replace(result, StringTools.replace(folder, '/', '\\'), '[game]\\');
		for (key in ['USERPROFILE', 'HOME'])
		{
			var personal = Sys.getEnv(key);
			if (personal != null && personal.length > 0)
			{
				result = StringTools.replace(result, personal, '[user]');
				result = StringTools.replace(result, StringTools.replace(personal, '\\', '/'), '[user]');
			}
		}
		#end
		// Also hide user folders belonging to another Windows account.
		result = ~/[A-Za-z]:[\\\/]Users[\\\/][^\\\/\r\n]+/gi.replace(result, '[user]');
		return result;
	}

	public static function summary():String
	{
		return 'Psych ' + states.MainMenuState.psychEngineVersion
			+ ' | OpenFL ' + DiagnosticBuildInfo.libraryVersion('openfl') + ' | Lime ' + DiagnosticBuildInfo.libraryVersion('lime')
			+ '\nMenu: ' + MenuSelector.getMenu() + ' | Shaders: ' + enabled(ClientPrefs.data.shaders)
			+ '\nRecent warnings/errors: ' + recent.length;
	}

	static inline function enabled(value:Bool):String return value ? 'ON' : 'OFF';

	public static function report():String
	{
		var lines = ['CORRUPTION ENGINE - SUPPORT REPORT', 'Generated: ' + Date.now().toString(), summary()];
		var config = GameConfig.getInstance();
		lines.push('Build: ' + sanitize(config.getWindowTitle()));
		#if sys
		lines.push('OS: ' + Sys.systemName());
		#end
		lines.push('Framerate setting: ' + ClientPrefs.data.framerate);
		lines.push('Low quality: ' + enabled(ClientPrefs.data.lowQuality));
		lines.push('Antialiasing: ' + enabled(ClientPrefs.data.antialiasing));
		lines.push('Disable menu shaders: ' + enabled(ClientPrefs.data.menuShaders));
		lines.push('GPU caching: ' + enabled(ClientPrefs.data.cacheOnGPU));
		lines.push('Automatic reports: ' + enabled(ClientPrefs.data.automaticReports));
		lines.push('GPU / driver: not collected');
		if (states.PlayState.SONG != null)
		{
			lines.push('Last loaded song: ' + sanitize(states.PlayState.SONG.song));
			lines.push('Difficulty index: ' + states.PlayState.storyDifficulty);
		}
		lines.push('\nRECENT WARNINGS / ERRORS (current session, maximum ' + LIMIT + ')');
		lines.push(recent.length > 0 ? recent.join('\n') : 'No matching warnings/errors recorded.');
		lines.push('\nThis report is not sent automatically. Review it before sharing.');
		return lines.join('\n');
	}
}
