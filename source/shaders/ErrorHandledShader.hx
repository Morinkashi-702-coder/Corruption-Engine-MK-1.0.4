package shaders;

import flixel.system.FlxAssets.FlxShader;
import flixel.addons.display.FlxRuntimeShader;
import lime.graphics.opengl.GLProgram;
import openfl.display.Shader;
import openfl.filters.ShaderFilter;

class ErrorHandledShader extends FlxShader implements IErrorHandler
{
	public var shaderName:String = '';
	public var failed(default, null):Bool = false;
	static var reportedErrors:Map<String, Bool> = [];
	public dynamic function onError(error:Dynamic):Void {}
	public function new(?shaderName:String)
	{
		this.shaderName = shaderName;
		super();
	}

	override function __createGLProgram(vertexSource:String, fragmentSource:String):GLProgram
	{
		try
		{
			final res = super.__createGLProgram(vertexSource, fragmentSource);
			var gl = @:privateAccess __context.gl;
			if (res == null || gl.getProgramParameter(res, gl.LINK_STATUS) == 0)
				throw 'Shader program could not be linked';
			return res;
		}
		catch (error)
		{
			failed = true;
			recover(this, shaderName, error, onError);
			// Finish the current draw with Flixel's ordinary texture shader.
			// Returning null here leaves OpenFL with an unusable GL program.
			var fallback = new FlxShader();
			return super.__createGLProgram(fallback.glVertexSource, fallback.glFragmentSource);
		}
	}

	public static function recover(shader:Shader, name:String, error:Dynamic, callback:Dynamic):Void
	{
		// Filters can be in use during this call. Remove only this shader's
		// camera filters after rendering, preserving the other effects.
		FlxG.signals.postDraw.addOnce(function()
		{
			for (camera in FlxG.cameras.list)
			{
				if (camera == null || camera.filters == null) continue;
				camera.filters = camera.filters.filter(function(filter)
				{
					return !Std.isOfType(filter, ShaderFilter) || (cast filter:ShaderFilter).shader != shader;
				});
			}
		});
		crashSave(name, error, callback);
	}
	
	public static function crashSave(shaderName:String, error:Dynamic, onError:Dynamic) // prevent the app from dying immediately
	{
		if(shaderName == null) shaderName = 'unnamed';
		if (!reportedErrors.exists(shaderName))
		{
			reportedErrors.set(shaderName, true);
			trace('Shader "$shaderName" failed; using ordinary rendering: ' + Std.string(error));
			#if sys
			try
			{
				var dateNow = Date.now().toString().replace(" ", "_").replace(":", "-");
				var safeName = ~/[^a-zA-Z0-9_-]/g.replace(shaderName, '_');
				if (!FileSystem.exists('./crash/')) FileSystem.createDirectory('./crash/');
				File.saveContent('./crash/shader_${safeName}_${dateNow}.txt', Std.string(error));
			}
			catch (logError:Dynamic) trace('Could not save shader error: ' + Std.string(logError));
			#end
		}
		try { onError(error); }
		catch (callbackError:Dynamic) trace('Shader error callback failed: ' + Std.string(callbackError));
	}
}

class ErrorHandledRuntimeShader extends FlxRuntimeShader implements IErrorHandler
{
	public var shaderName:String = '';
	public var failed(default, null):Bool = false;
	public dynamic function onError(error:Dynamic):Void {}
	public function new(?shaderName:String, ?fragmentSource:String, ?vertexSource:String)
	{
		this.shaderName = shaderName;
		super(fragmentSource, vertexSource);
	}

	override function __createGLProgram(vertexSource:String, fragmentSource:String):GLProgram
	{
		try
		{
			final res = super.__createGLProgram(vertexSource, fragmentSource);
			var gl = @:privateAccess __context.gl;
			if (res == null || gl.getProgramParameter(res, gl.LINK_STATUS) == 0)
				throw 'Shader program could not be linked';
			return res;
		}
		catch (error)
		{
			failed = true;
			ErrorHandledShader.recover(this, shaderName, error, onError);
			var fallback = new FlxShader();
			return super.__createGLProgram(fallback.glVertexSource, fallback.glFragmentSource);
		}
	}
}

interface IErrorHandler
{
	public var shaderName:String;
	public dynamic function onError(error:Dynamic):Void;
}
