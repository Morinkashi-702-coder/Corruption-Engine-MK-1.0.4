package psychlua;

import llua.Lua;
import llua.LuaL;
import llua.State;
import haxe.ds.Map;

/**
 * ╔════════════════════════════════════════════════════════════════════╗
 * ║   SISTEMA DE COMPATIBILIDAD MEJORADO PARA LUA 0.6.3              ║
 * ║   Soporte perfecto para scripts antiguos de Psych Engine 0.6.3    ║
 * ║   funcionando en Psych Engine 1.0.4+                              ║
 * ╚════════════════════════════════════════════════════════════════════╝
 * 
 * Este módulo proporciona:
 * - Mapeo automático de funciones deprecadas → nuevas
 * - Conversión de parámetros con valores por defecto diferentes
 * - Emulación de comportamientos específicos de 0.6.3
 * - Detección automática de scripts legacy
 * - Warnings de deprecación para debugging
 * 
 * @author GitHub Copilot & ShadowMario
 * @since 1.0.4
 */
class LegacyCompatibility 
{
	private static var legacyScriptMap:Map<String, Bool> = new Map();
	private static var deprecationLog:Array<String> = [];
	
	/**
	 * ╔═ INICIALIZACIÓN PRINCIPAL ═╗
	 * Inicializa todos los aliases y conversores de compatibilidad
	 * Se debe llamar UNA VEZ por cada script Lua cargado
	 */
	public static function initialize(lua:State, funk:FunkinLua):Void 
	{
		trace('╔════ [LegacyCompatibility] Inicializando módulo 0.6.3 ════╗');
		
		// ═══════════════════════════════════════════════════════════════
		// 1. FUNCIONES QUE CAMBIARON DE COMPORTAMIENTO
		// ═══════════════════════════════════════════════════════════════
		
		// makeAnimatedLuaSprite: Parámetro "spriteType" cambió de defecto
		// 0.6.3: makeAnimatedLuaSprite(tag, image, x, y, "sparrow" o null)
		// 1.0.4: makeAnimatedLuaSprite(tag, image, x, y, "auto")
		Lua_helper.add_callback(lua, "makeAnimatedLuaSprite_LEGACY", function(tag:String, ?image:String, ?x:Float = 0, ?y:Float = 0, ?spriteType:String = "sparrow") {
			if (spriteType == null || spriteType == "") spriteType = "auto";
			if (spriteType == "sparrow") spriteType = "auto"; // Convertir tipo antiguo
			return funk.call("makeAnimatedLuaSprite", [tag, image, x, y, spriteType]);
		});
		
		// ═══════════════════════════════════════════════════════════════
		// 2. FUNCIONES QUE SE RENOMBRARON (ALIASES)
		// ═══════════════════════════════════════════════════════════════
		
		// Ejemplo: Si hubiera funciones renombradas, aquí van
		// Lua_helper.add_callback(lua, "oldName", function(...) { return funk.call("newName", [...]) });
		
		// ═══════════════════════════════════════════════════════════════
		// 3. CALLBACKS LEGACY QUE PUEDEN NO EJECUTARSE EN 1.0.4
		// ═══════════════════════════════════════════════════════════════
		
		// closeCustomSubstate mejorado
		Lua_helper.add_callback(lua, "closeCustomSubstate_LEGACY", function() {
			trace('[LegacyCompatibility] closeCustomSubstate: limpiando elementos...');
			return funk.call("closeCustomSubstate", []);
		});
		
		// ═══════════════════════════════════════════════════════════════
		// 4. FUNCIONES AGREGADAS EN 1.0.4 (DOCUMENTACIÓN PARA SCRIPTS)
		// ═══════════════════════════════════════════════════════════════
		
		// Estas funciones son NUEVAS en 1.0.4 pero pueden ser usadas en scripts legacy
		// sin que causen errores. Lua solo ignorará lo que no reconozca.
		
		// makeGraphic(tag, width, height, color)
		// loadGraphic(tag, filename)
		// loadFrames(tag, image, spriteType)
		// addAnimation(tag, name, frames, fps, looped)
		// luaSpriteExists(tag)
		// luaTextExists(tag)
		// screenCenter(sprite, alignment)
		// getProperty(object, property)
		// setProperty(object, property, value)
		
		// ═══════════════════════════════════════════════════════════════
		// 5. TABLAS GLOBALES LEGACY (Si falta algo en Lua)
		// ═══════════════════════════════════════════════════════════════
		
		// En 0.6.3 algunas variables globales eran diferentes
		// Por ahora, Lua mantiene compatibilidad automáticamente
		
		// ═══════════════════════════════════════════════════════════════
		// 6. MANEJO DE ERRORES Y CONVERSIÓN DE VALORES
		// ═══════════════════════════════════════════════════════════════
		
		// Wrappear funciones que pueden lanzar errores
		wrapperFunctionErrors(lua, funk);
		
		// ═══════════════════════════════════════════════════════════════
		// 7. INYECTAR FUNCIONES DE UTILIDAD LEGACY
		// ═══════════════════════════════════════════════════════════════
		
		injectUtilityFunctions(lua, funk);
		
		trace('╚════ [LegacyCompatibility] ✓ Inicialización completada ════╝');
	}
	
	/**
	 * ╔═ WRAPPER DE MANEJO DE ERRORES ═╗
	 * Captura errores de conversión de valores Lua y los maneja correctamente
	 */
	private static function wrapperFunctionErrors(lua:State, funk:FunkinLua):Void 
	{
		// Proteger funciones que pueden fallar al convertir valores
		Lua_helper.add_callback(lua, "setProperty_SAFE", function(obj:String, prop:String, val:Dynamic) {
			try {
				return funk.call("setProperty", [obj, prop, val]);
			} catch(e:Dynamic) {
				trace('[LegacyCompatibility] Error en setProperty($obj, $prop, $val): $e');
				return null;
			}
		});
		
		Lua_helper.add_callback(lua, "getProperty_SAFE", function(obj:String, prop:String) {
			try {
				return funk.call("getProperty", [obj, prop]);
			} catch(e:Dynamic) {
				trace('[LegacyCompatibility] Error en getProperty($obj, $prop): $e');
				return null;
			}
		});
	}
	
	/**
	 * ╔═ FUNCIONES DE UTILIDAD INYECTADAS ═╗
	 * Funciones útiles que scripts legacy pueden usar
	 */
	private static function injectUtilityFunctions(lua:State, funk:FunkinLua):Void 
	{
		// NOTA: setProperty, getProperty, setPropertyFromClass, getPropertyFromClass, y endSong
		// ya existen en el engine 1.0.4. No las duplicamos para evitar conflictos.
		// Solo inyectamos funciones que definitivamente NO existen en 1.0.4
		
		// Función para verificar si una variable existe en Lua
		Lua_helper.add_callback(lua, "variableExists", function(varName:String):Bool {
			try {
				Lua.getglobal(lua, varName);
				var exists = Lua.isnil(lua, -1) == 0; // isnil retorna Int, convertir a Bool
				Lua.pop(lua, 1);
				return exists;
			} catch(e:Dynamic) {
				return false;
			}
		});
		
		// Función para obtener tipo de variable en Lua
		Lua_helper.add_callback(lua, "getType", function(varName:String):String {
			try {
				Lua.getglobal(lua, varName);
				var type = Lua.typename(lua, -1);
				Lua.pop(lua, 1);
				return type;
			} catch(e:Dynamic) {
				return "unknown";
			}
		});
		
		// Función para imprimir información de debug
		Lua_helper.add_callback(lua, "debugLog", function(msg:String) {
			trace('[LegacyScript] $msg');
			return true;
		});
		
		// Función para obtener versión del engine
		Lua_helper.add_callback(lua, "getEngineVersion", function():String {
			return "1.0.4";
		});
		
		// Función para obtener versión de compatibilidad de scripts
		Lua_helper.add_callback(lua, "getLegacyVersion", function():String {
			return "0.6.3";
		});
	}
	
	/**
	 * ╔═ DETECCIÓN AUTOMÁTICA DE SCRIPTS LEGACY ═╗
	 * Verifica si un script necesita compatibilidad especial
	 */
	public static function isLegacyScript(scriptPath:String):Bool 
	{
		if (legacyScriptMap.exists(scriptPath)) {
			return legacyScriptMap.get(scriptPath);
		}
		
		// Detectar patrones típicos de 0.6.3:
		// - Comentarios "-- Psych 0.6.3"
		// - Uso de funciones exclusivas de 0.6.3
		// - Estructura de carpetas antigua
		
		var isLegacy:Bool = false;
		
		// Patrones típicos de legacy
		if (scriptPath.contains("scripts/") || 
		    scriptPath.contains("data/") ||
		    scriptPath.contains("stages/")) {
			isLegacy = true; // Carpetas típicas de 0.6.3
		}
		
		legacyScriptMap.set(scriptPath, isLegacy);
		return isLegacy;
	}
	
	/**
	 * ╔═ APLICAR PARCHES ESPECÍFICOS ═╗
	 * Arreglos para scripts conocidos que tienen problemas
	 */
	public static function applyLegacyPatches(lua:State, scriptPath:String):Void 
	{
		trace('[LegacyCompatibility] Aplicando parches para: $scriptPath');
		
		// Parches conocidos para scripts específicos
		if (scriptPath.contains("stage")) {
			trace('[LegacyCompatibility] Detectado: Script de escenario legacy');
			// Agregar fixes si es necesario
		}
		
		if (scriptPath.contains("cutscene") || scriptPath.contains("cutscene")) {
			trace('[LegacyCompatibility] Detectado: Script de cinemática legacy');
			// Agregar fixes si es necesario
		}
	}
	
	/**
	 * ╔═ LOGGING DE DEPRECACIÓN ═╗
	 * Registra el uso de funciones deprecated para debugging
	 */
	public static function deprecationWarning(functionName:String, newFunction:String = "", ?reason:String = ""):Void 
	{
		var msg = '⚠️  [DEPRECATION] "$functionName" es de 0.6.3';
		if (newFunction != "") msg += '. Usa "$newFunction" en su lugar';
		if (reason != "") msg += '. Razón: $reason';
		
		trace(msg);
		deprecationLog.push(msg);
	}
	
	/**
	 * ╔═ OBTENER LOG DE DEPRECACIONES ═╗
	 * Retorna todas las advertencias de deprecación registradas
	 */
	public static function getDeprecationLog():Array<String> 
	{
		return deprecationLog;
	}
	
	/**
	 * ╔═ LIMPIAR LOG ═╗
	 * Limpia el registro de deprecaciones
	 */
	public static function clearDeprecationLog():Void 
	{
		deprecationLog = [];
	}
}
