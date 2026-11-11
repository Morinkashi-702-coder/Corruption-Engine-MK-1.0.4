package backend;

// Keep compile-time macros separate from classes that depend on game states.
class DiagnosticBuildInfo
{
	public static macro function libraryVersion(name:String):haxe.macro.Expr
	{
		var version = haxe.macro.Context.definedValue(name);
		return macro $v{version != null ? version : 'unknown'};
	}
}
