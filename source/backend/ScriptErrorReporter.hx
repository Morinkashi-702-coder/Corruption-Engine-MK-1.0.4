package backend;

class ScriptErrorReporter
{
	public static var pendingErrors:Array<Dynamic> = [];

	public static function reportLua(scriptName:String, funcName:String, rawError:String, ?stackTrace:String = null):Void
	{
		var info:Dynamic = buildInfo('Lua', scriptName, funcName, rawError, stackTrace);
		enqueue(info);
	}

	public static function reportHScript(fileName:String, funcName:String, rawError:String, ?stackTrace:String = null):Void
	{
		var info:Dynamic = buildInfo('HScript', fileName, funcName, rawError, stackTrace);
		enqueue(info);
	}

	public static function flushToPlayState():Void
	{
		if(pendingErrors.length < 1) return;

		var playStateClass:Class<Dynamic> = Type.resolveClass('states.PlayState');
		if(playStateClass == null) return;

		var instance:Dynamic = Reflect.field(playStateClass, 'instance');
		if(instance == null) return;

		while(pendingErrors.length > 0)
		{
			Reflect.callMethod(instance, Reflect.field(instance, 'pushScriptError'), [pendingErrors.shift()]);
		}
	}

	public static function clearPending():Void
	{
		pendingErrors = [];
	}

	static function enqueue(info:Dynamic):Void
	{
		pendingErrors.push(info);
		flushToPlayState();
	}

	static function buildInfo(source:String, script:String, func:String, rawError:String, stackTrace:String):Dynamic
	{
		if(script == null) script = 'unknown';
		if(func == null || func.length < 1) func = 'unknown';
		if(rawError == null) rawError = 'Unknown error';

		var line:Int = -1;
		var message:String = rawError;

		var rx = ~/^(.*?):([0-9]+):\s*(.*)$/;
		if(rx.match(rawError))
		{
			script = rx.matched(1);
			line = Std.parseInt(rx.matched(2));
			message = rx.matched(3);
		}

		return {
			source: source,
			script: script,
			line: line,
			func: func,
			message: message,
			stack: stackTrace,
			time: Date.now().toString()
		};
	}
}