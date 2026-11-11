package backend;

import haxe.io.Path;
#if sys
import sys.io.File;
import sys.FileSystem;
#end
import openfl.utils.Assets;

/**
 * Clase para manejar la configuración del juego desde gameData.ini
 */
class GameConfig
{
	// Instancia singleton
	private static var instance:GameConfig = null;
	
	// Datos almacenados
	private var configData:Map<String, Map<String, String>> = new Map();
	private var configPath:String = "assets/data/gameData.ini";
	private var configLoaded:Bool = false;
	
	public function new()
	{
		loadConfig();
	}
	
	/**
	 * Obtener la instancia singleton
	 */
	public static function getInstance():GameConfig
	{
		if(instance == null)
		{
			instance = new GameConfig();
		}
		return instance;
	}

	/** Save the startup answers together, preserving unrelated INI settings. */
	public function saveStartupMenu(menu:String, showNotices:Bool, showOpening:Bool):Bool
	{
		#if sys
		var base = Path.directory(Sys.programPath());
		var candidates = [Path.join([base, 'assets/shared/data/gameData.ini']),
			Path.join([base, 'assets/data/gameData.ini']), configPath];
		for (path in candidates)
		{
			if (!FileSystem.exists(path) || FileSystem.isDirectory(path)) continue;
			try
			{
				var content = File.getContent(path);
				var newline = content.indexOf('\r\n') >= 0 ? '\r\n' : '\n';
				var lines = content.split('\n');
				var inMenu = false;
				var found = false;
				var noticesFound = false;
				var openingFound = false;
				var insertAt = -1;
				for (i in 0...lines.length)
				{
					var line = lines[i].trim();
					if (line.startsWith('[') && line.endsWith(']'))
					{
						inMenu = line.toLowerCase() == '[menu]';
						if (inMenu) insertAt = i + 1;
					}
					else if (inMenu && line.indexOf('=') >= 0
						&& line.substr(0, line.indexOf('=')).trim().toLowerCase() == 'mainmenustyle')
					{
						lines[i] = 'mainMenuStyle = ' + menu;
						found = true;
					}
					else if (inMenu && line.indexOf('=') >= 0
						&& line.substr(0, line.indexOf('=')).trim().toLowerCase() == 'shownoticesonstartup')
					{
						lines[i] = 'showNoticesOnStartup = ' + (showNotices ? 'true' : 'false');
						noticesFound = true;
					}
					else if (inMenu && line.indexOf('=') >= 0
						&& line.substr(0, line.indexOf('=')).trim().toLowerCase() == 'showopeningvideo')
					{
						lines[i] = 'showOpeningVideo = ' + (showOpening ? 'true' : 'false');
						openingFound = true;
					}
				}
				if (!found)
				{
					if (insertAt < 0) { lines.push('[menu]'); insertAt = lines.length; }
					lines.insert(insertAt, 'mainMenuStyle = ' + menu);
				}
				if (!noticesFound)
					lines.insert(insertAt, 'showNoticesOnStartup = ' + (showNotices ? 'true' : 'false'));
				if (!openingFound)
					lines.insert(insertAt, 'showOpeningVideo = ' + (showOpening ? 'true' : 'false'));
				var output = [for (line in lines) StringTools.endsWith(line, '\r') ? line.substr(0, line.length - 1) : line].join(newline);
				File.saveContent(path, output);
				if (File.getContent(path) != output) return false;
				parseConfig(output);
				configPath = path;
				return true;
			}
			catch (e:Dynamic)
			{
				trace('[Startup setup] Could not save menu: ' + e);
				return false;
			}
		}
		#end
		return false;
	}
	
	/**
	 * Cargar el archivo gameData.ini
	 */
	private function loadConfig():Void
	{
		var content:String = "";
		
		// Intentar cargar desde OpenFL Assets primero (funciona en builds compilados)
		var assetPaths = [
			"data/gameData.ini",                          // OpenFL mapped path
			"assets/shared/data/gameData.ini",            // Ruta correcta en export
			"assets/data/gameData.ini"                    // Alternativa
		];
		
		for(assetPath in assetPaths)
		{
			try
			{
				if(Assets.exists(assetPath))
				{
					content = Assets.getText(assetPath);
					trace("✓ gameData.ini loaded from OpenFL Assets: " + assetPath);
					break;
				}
			}
			catch(e:Dynamic)
			{
				trace("⚠ Could not load " + assetPath + " from OpenFL Assets: " + e);
			}
		}
		
		// Si no funcionó con Assets, intentar con File system
		#if sys
		if(content.length == 0)
		{
			var possiblePaths = [
				"assets/data/gameData.ini",
				"./assets/data/gameData.ini",
				"../assets/data/gameData.ini",
				"assets/shared/data/gameData.ini",
				"export/release/windows/bin/assets/shared/data/gameData.ini"
			];
			
			for(path in possiblePaths)
			{
				if(FileSystem.exists(path))
				{
					try
					{
						content = File.getContent(path);
						configPath = path;
						trace("✓ gameData.ini loaded from file system: " + path);
						break;
					}
					catch(e:Dynamic)
					{
						trace("⚠ Error reading config file at " + path + ": " + e);
					}
				}
			}
		}
		#end
		
		// Parsear si encontramos contenido
		if(content.length > 0)
		{
			try
			{
				parseConfig(content);
				configLoaded = true;
			}
			catch(e:Dynamic)
			{
				trace("⚠ Error parsing gameData.ini: " + e);
				createDefaultConfig();
			}
		}
		else
		{
			trace("⚠ gameData.ini not found, using defaults");
			createDefaultConfig();
		}
	}
	
	/**
	 * Parsear el contenido del archivo INI
	 */
	private function parseConfig(content:String):Void
	{
		var currentSection:String = "";
		var lines:Array<String> = content.split("\n");
		
		for(line in lines)
		{
			line = line.trim();
			
			// Ignorar comentarios y líneas vacías
			if(line.length == 0 || line.charAt(0) == ';')
				continue;
			
			// Detectar secciones [section]
			if(line.charAt(0) == '[' && line.charAt(line.length - 1) == ']')
			{
				currentSection = line.substring(1, line.length - 1).toLowerCase();
				if(!configData.exists(currentSection))
				{
					configData.set(currentSection, new Map());
				}
			}
			// Parsear key = value
			else if(line.indexOf('=') > -1 && currentSection.length > 0)
			{
				var parts:Array<String> = line.split('=');
				if(parts.length == 2)
				{
					var key:String = parts[0].trim().toLowerCase();
					var value:String = parts[1].trim();
					configData.get(currentSection).set(key, value);
				}
			}
		}
	}
	
	/**
	 * Crear configuración por defecto
	 */
	private function createDefaultConfig():Void
	{
		// Menu settings
		var menu = new Map<String, String>();
		menu.set("storymodeenabled", "true");
		menu.set("freeplayenabled", "true");
		menu.set("creditsenabled", "true");
		menu.set("optionsenabled", "true");
		menu.set("debugmenuenabled", "true");
		menu.set("shownoticesonstartup", "true");
		menu.set("showopeningvideo", "true");
		menu.set("firsttimemode", "false");
		configData.set("menu", menu);

		// Gameplay settings
		var gameplay = new Map<String, String>();
		gameplay.set("botplayavailable", "true");
		gameplay.set("practicemodeavailable", "true");
		gameplay.set("autopause", "true");
		gameplay.set("showscripterrors", "true");
		configData.set("gameplay", gameplay);
		
		// Engine info - USAR LOS VALORES DEL INI SI ESTÁN DISPONIBLES
		var engine = new Map<String, String>();
		engine.set("enginename", "Corruption Engine MK psych engine port 2.0 (restored)");
		engine.set("engineversion", "1.0.4");
		engine.set("gametitle", "Friday Night Funkin'");
		engine.set("modname", "Corruption Engine MK");
		engine.set("modversion", "2.0 (Restored)");
		configData.set("engine", engine);
	}
	
	/**
	 * Obtener un valor de configuración
	 * @param section Sección del INI
	 * @param key Clave del valor
	 * @param defaultValue Valor por defecto si no existe
	 */
	public function getValue(section:String, key:String, ?defaultValue:String = ""):String
	{
		section = section.toLowerCase();
		key = key.toLowerCase();
		
		if(configData.exists(section) && configData.get(section).exists(key))
		{
			return configData.get(section).get(key);
		}
		
		return defaultValue;
	}
	
	/**
	 * Obtener un valor como booleano
	 */
	public function getBool(section:String, key:String, ?defaultValue:Bool = false):Bool
	{
		var value:String = getValue(section, key, defaultValue ? "true" : "false").toLowerCase();
		return value == "true" || value == "1" || value == "yes";
	}
	
	/**
	 * Obtener un valor como número entero
	 */
	public function getInt(section:String, key:String, ?defaultValue:Int = 0):Int
	{
		var value:String = getValue(section, key, Std.string(defaultValue));
		var intValue = Std.parseInt(value);
		if(intValue != null) {
			return intValue;
		}
		return defaultValue;
	}
	
	/**
	 * Obtener un valor como número decimal
	 */
	public function getFloat(section:String, key:String, ?defaultValue:Float = 0.0):Float
	{
		var value:String = getValue(section, key, Std.string(defaultValue));
		var floatValue = Std.parseFloat(value);
		if(!Math.isNaN(floatValue)) {
			return floatValue;
		}
		return defaultValue;
	}
	
	/**
	 * Obtener todos los valores de una sección
	 */
	public function getSection(section:String):Map<String, String>
	{
		section = section.toLowerCase();
		if(configData.exists(section))
		{
			return configData.get(section);
		}
		return new Map();
	}
	
	/**
	 * Listar todas las secciones
	 */
	public function getSections():Array<String>
	{
		var sections:Array<String> = [];
		for(section in configData.keys())
		{
			sections.push(section);
		}
		return sections;
	}
	
	/**
	 * Mostrar toda la configuración en traces
	 */
	public function printConfig():Void
	{
		trace("=== GAME CONFIGURATION ===");
		for(section in configData.keys())
		{
			trace("[" + section + "]");
			for(key in configData.get(section).keys())
			{
				var value = configData.get(section).get(key);
				trace("  " + key + " = " + value);
			}
		}
		
		// Debug específico de autoPause
		trace("=== DEBUG: AutoPause ===");
		trace("autoPause value: " + getValue("gameplay", "autopause", "NOT_FOUND"));
		trace("autoPause bool: " + getBool("gameplay", "autopause", false));
	}
	
	/**
	 * Actualizar el título de la ventana
	 */
	public function updateWindowTitle():Void
	{
		#if desktop
		try
		{
			var engineName:String = getValue("engine", "engineName", "Corruption Engine MK");
			var engineVersion:String = getValue("engine", "engineVersion", "1.0.4");
			
			var windowTitle:String = engineName + " - Version " + engineVersion;
			
			lime.app.Application.current.window.title = windowTitle;
			trace("✓ Window title set to: " + windowTitle);
		}
		catch(e:Dynamic)
		{
			trace("⚠ Error updating window title: " + e);
		}
		#end
	}
	
	/**
	 * Obtener el título de la ventana formateado
	 */
	public function getWindowTitle():String
	{
		var engineName:String = getValue("engine", "engineName", "Corruption Engine MK");
		var engineVersion:String = getValue("engine", "engineVersion", "1.0.4");
		return engineName + " - Version " + engineVersion;
	}
	
	/**
	 * Obtener información completa del engine
	 */
	public function getEngineInfo():String
	{
		var engineName:String = getValue("engine", "engineName", "");
		var engineVersion:String = getValue("engine", "engineVersion", "");
		var modName:String = getValue("engine", "modName", "");
		var modVersion:String = getValue("engine", "modVersion", "");
		
		return engineName + " v" + engineVersion + " - " + modName + " v" + modVersion;
	}
}
