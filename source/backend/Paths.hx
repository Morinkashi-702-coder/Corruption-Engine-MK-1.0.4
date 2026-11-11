package backend;

import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxRect;
import flixel.system.FlxAssets;

import openfl.display.BitmapData;
import openfl.display3D.textures.RectangleTexture;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import openfl.system.System;
import openfl.geom.Rectangle;

import lime.utils.Assets;
import flash.media.Sound;

import haxe.Json;


#if MODS_ALLOWED
import backend.Mods;
#end

@:access(openfl.display.BitmapData)
class Paths
{
	inline public static var SOUND_EXT = #if web "mp3" #else "ogg" #end;
	inline public static var VIDEO_EXT = "mp4";

	public static function excludeAsset(key:String) {
		if (!dumpExclusions.contains(key))
			dumpExclusions.push(key);
	}

	// Desactivado: Corruption usa su propia musica de menu, no freakyMenu de Psych Engine.
	// public static var dumpExclusions:Array<String> = ['assets/shared/music/freakyMenu.$SOUND_EXT'];
	public static var dumpExclusions:Array<String> = [];
	// haya I love you for the base cache dump I took to the max
	public static function clearUnusedMemory()
	{
		// clear non local assets in the tracked assets list
		for (key in currentTrackedAssets.keys())
		{
			// if it is not currently contained within the used local assets
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key))
			{
				destroyGraphic(currentTrackedAssets.get(key)); // get rid of the graphic
				currentTrackedAssets.remove(key); // and remove the key from local cache map
			}
		}

		// run the garbage collector for good measure lmfao
		System.gc();
	}

	// define the locally tracked assets
	public static var localTrackedAssets:Array<String> = [];

	/** Marks an asset as used by the active loading/state scope without
	 * growing the tracking array with thousands of duplicate keys. */
	public static inline function trackLocalAsset(key:String):Void
	{
		if (key != null && key.length > 0 && !localTrackedAssets.contains(key))
			localTrackedAssets.push(key);
	}

	private static function countMap<T>(map:Map<String, T>):Int
	{
		var count:Int = 0;
		for (_ in map.keys()) count++;
		return count;
	}

	/**
	 * Song/state boundary cleanup inspired by V-Slice's scoped asset lifetime:
	 * forget the finished scope, release sounds and graphics, then collect once.
	 */
	public static function releaseUnusedMemory(?reason:String = 'state'):Void
	{
		var graphicsBefore:Int = countMap(currentTrackedAssets);
		var soundsBefore:Int = countMap(currentTrackedSounds);

		localTrackedAssets = [];
		clearStoredMemory();
		clearUnusedMemory();

		var graphicsFreed:Int = graphicsBefore - countMap(currentTrackedAssets);
		var soundsFreed:Int = soundsBefore - countMap(currentTrackedSounds);
		trace('[Memory] Released scope "$reason": $graphicsFreed graphics, $soundsFreed sounds');
	}

	/** Keeps only the assets explicitly tracked for the newly activated scope. */
	@:access(flixel.system.frontEnds.BitmapFrontEnd._cache)
	public static function sweepCurrentMemoryScope(?reason:String = 'state'):Void
	{
		var graphicsBefore:Int = countMap(currentTrackedAssets);
		var soundsBefore:Int = countMap(currentTrackedSounds);

		for (key in currentTrackedAssets.keys())
		{
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key))
			{
				destroyGraphic(currentTrackedAssets.get(key));
				currentTrackedAssets.remove(key);
			}
		}

		for (key => asset in currentTrackedSounds)
		{
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key) && asset != null)
			{
				Assets.cache.clear(key);
				currentTrackedSounds.remove(key);
			}
		}

		for (key in FlxG.bitmap._cache.keys())
			if (!currentTrackedAssets.exists(key))
				destroyGraphic(FlxG.bitmap.get(key));

		System.gc();
		trace('[Memory] Activated scope "$reason": '
			+ (graphicsBefore - countMap(currentTrackedAssets)) + ' old graphics, '
			+ (soundsBefore - countMap(currentTrackedSounds)) + ' old sounds released');
	}

	@:access(flixel.system.frontEnds.BitmapFrontEnd._cache)
	public static function clearStoredMemory()
	{
		// clear anything not in the tracked assets list
		for (key in FlxG.bitmap._cache.keys())
		{
			if (!currentTrackedAssets.exists(key))
				destroyGraphic(FlxG.bitmap.get(key));
		}

		// clear all sounds that are cached
		for (key => asset in currentTrackedSounds)
		{
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key) && asset != null)
			{
				Assets.cache.clear(key);
				currentTrackedSounds.remove(key);
			}
		}
		// flags everything to be cleared out next unused memory clear
		localTrackedAssets = [];
		#if !html5 openfl.Assets.cache.clear("songs"); #end
	}

	public static function freeGraphicsFromMemory()
	{
		var protectedGfx:Array<FlxGraphic> = [];
		function checkForGraphics(spr:Dynamic)
		{
			try
			{
				var grp:Array<Dynamic> = Reflect.getProperty(spr, 'members');
				if(grp != null)
				{
					//trace('is actually a group');
					for (member in grp)
					{
						checkForGraphics(member);
					}
					return;
				}
			}

			//trace('check...');
			try
			{
				var gfx:FlxGraphic = Reflect.getProperty(spr, 'graphic');
				if(gfx != null)
				{
					protectedGfx.push(gfx);
					//trace('gfx added to the list successfully!');
				}
			}
			//catch(haxe.Exception) {}
		}

		for (member in FlxG.state.members)
			checkForGraphics(member);

		if(FlxG.state.subState != null)
			for (member in FlxG.state.subState.members)
				checkForGraphics(member);

		for (key in currentTrackedAssets.keys())
		{
			// if it is not currently contained within the used local assets
			if (!dumpExclusions.contains(key))
			{
				var graphic:FlxGraphic = currentTrackedAssets.get(key);
				if(!protectedGfx.contains(graphic))
				{
					destroyGraphic(graphic); // get rid of the graphic
					currentTrackedAssets.remove(key); // and remove the key from local cache map
					//trace('deleted $key');
				}
			}
		}
	}

	inline static function destroyGraphic(graphic:FlxGraphic)
	{
		// free some gpu memory
		if (graphic != null && graphic.bitmap != null && graphic.bitmap.__texture != null)
			graphic.bitmap.__texture.dispose();
		FlxG.bitmap.remove(graphic);
	}

	static public var currentLevel:String;
	static public function setCurrentLevel(name:String)
		currentLevel = name.toLowerCase();

	public static function getPath(file:String, ?type:AssetType = TEXT, ?parentfolder:String, ?modsAllowed:Bool = true):String
	{
		#if MODS_ALLOWED
		if(modsAllowed)
		{
			var customFile:String = file;
			if (parentfolder != null) customFile = '$parentfolder/$file';

			var modded:String = modFolders(customFile);
			if(FileSystem.exists(modded)) return modded;
		}
		#end

		if (parentfolder != null)
			return getFolderPath(file, parentfolder);

		if (currentLevel != null && currentLevel != 'shared')
		{
			var levelPath = getFolderPath(file, currentLevel);
			if (OpenFlAssets.exists(levelPath, type))
				return levelPath;
		}
		return getSharedPath(file);
	}

	inline static public function getFolderPath(file:String, folder = "shared")
		return 'assets/$folder/$file';

	inline public static function getSharedPath(file:String = '')
		return 'assets/shared/$file';

	inline static public function txt(key:String, ?folder:String)
		return getPath('data/$key.txt', TEXT, folder, true);

	inline static public function xml(key:String, ?folder:String)
		return getPath('data/$key.xml', TEXT, folder, true);

	inline static public function json(key:String, ?folder:String)
		return getPath('data/$key.json', TEXT, folder, true);

	inline static public function shaderFragment(key:String, ?folder:String)
		return getPath('shaders/$key.frag', TEXT, folder, true);

	inline static public function shaderVertex(key:String, ?folder:String)
		return getPath('shaders/$key.vert', TEXT, folder, true);

	inline static public function lua(key:String, ?folder:String)
		return getPath('$key.lua', TEXT, folder, true);

	static public function video(key:String)
	{
		#if MODS_ALLOWED
		var file:String = modsVideo(key);
		if(FileSystem.exists(file)) return file;
		#end
		return 'assets/videos/$key.$VIDEO_EXT';
	}

	inline static public function sound(key:String, ?modsAllowed:Bool = true):Sound
		return returnSound('sounds/$key', modsAllowed);

	inline static public function music(key:String, ?modsAllowed:Bool = true):Sound
		return returnSound('music/$key', modsAllowed);

	inline static public function inst(song:String, ?modsAllowed:Bool = true):Sound
		return returnSound('${formatToSongPath(song)}/Inst', 'songs', modsAllowed);

	inline static public function voices(song:String, postfix:String = null, ?modsAllowed:Bool = true):Sound
	{
		var songKey:String = '${formatToSongPath(song)}/Voices';
		if(postfix != null) songKey += '-' + postfix;
		//trace('songKey test: $songKey');
		return returnSound(songKey, 'songs', modsAllowed, false);
	}

	inline static public function soundRandom(key:String, min:Int, max:Int, ?modsAllowed:Bool = true)
		return sound(key + FlxG.random.int(min, max), modsAllowed);

	/**
	 * Crea un bitmap placeholder para evitar crashes cuando faltan texturas
	 */
	private static function createPlaceholderGraphic(key:String):FlxGraphic
	{
		try {
			var width:Int = 100;
			var height:Int = 100;
			var bitmap:BitmapData = new BitmapData(width, height, true, 0x00000000); // Transparent instead of gray
			
			var uniqueKey = key + "_placeholder_" + Math.random();
			// A placeholder must not reuse a stale entry from Flixel's bitmap cache.
			var graphic = FlxGraphic.fromBitmapData(bitmap, false, uniqueKey, false);
			if (graphic != null) {
				// Build the frame now, so an invalid placeholder is caught here,
				// rather than crashing later in FlxSprite.loadGraphic().
				if (graphic.imageFrame == null || graphic.imageFrame.frame == null)
					throw 'Invalid placeholder frame';
				graphic.persist = true;
				graphic.destroyOnNoUse = false;
				
				currentTrackedAssets.set(key, graphic);
				trackLocalAsset(key);
				
				trace('Created transparent placeholder graphic for: $key');
				return graphic;
			} else {
				trace('WARNING: FlxGraphic.fromBitmapData returned null for $key, trying smaller fallback');
				// Try with smaller size as fallback - also transparent
				var smallerBitmap = new BitmapData(50, 50, true, 0x00000000);
				var fallbackGraphic = FlxGraphic.fromBitmapData(smallerBitmap, false, key + "_fallback");
				if (fallbackGraphic != null) {
					fallbackGraphic.persist = true;
					fallbackGraphic.destroyOnNoUse = false;
					currentTrackedAssets.set(key, fallbackGraphic);
					return fallbackGraphic;
				}
			}
		} catch (e:Dynamic) {
			trace('ERROR creating placeholder for $key: $e');
		}
		
		// Este nunca debería ejecutarse, pero por si acaso
		return null;
	}

	public static var currentTrackedAssets:Map<String, FlxGraphic> = [];

	/** Safe static-image loader for optional menu artwork. */
	public static function loadImageSafe(sprite:FlxSprite, key:String):FlxSprite
	{
		try
		{
			var graphic = image(key);
			if (graphic == null || graphic.bitmap == null) throw 'Unavailable image graphic';
			sprite.loadGraphic(graphic);
			if (sprite.frames == null || sprite.frame == null) throw 'Unavailable image frame';
			return sprite;
		}
		catch (e:Dynamic)
		{
			trace('WARNING: Cannot load optional image "$key": $e. Using transparent sprite.');
			return sprite.makeGraphic(100, 100, FlxColor.TRANSPARENT, true);
		}
	}
	static public function image(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxGraphic
	{
		try {
			var finalKey:String = Language.getFileTranslation('images/$key') + '.png';
			
			// Check cache first
			if (currentTrackedAssets.exists(finalKey)) {
				trackLocalAsset(finalKey);
				var cachedGraphic = currentTrackedAssets.get(finalKey);
				if (cachedGraphic != null && cachedGraphic.bitmap != null
					&& cachedGraphic.width > 0 && cachedGraphic.height > 0
					&& @:privateAccess cachedGraphic.frameCollections != null)
					return cachedGraphic;
				// Do not hand destroyed graphics back to callers.
				currentTrackedAssets.remove(finalKey);
			}

			var file:String = getPath(finalKey, IMAGE, parentFolder, true);
			var bitmap:BitmapData = null;

			#if sys
			if (FileSystem.exists(file))
				bitmap = BitmapData.fromFile(file);
			#else
			if (OpenFlAssets.exists(file, IMAGE))
				bitmap = OpenFlAssets.getBitmapData(file);
			#end

			// If bitmap is null, create placeholder
			if (bitmap == null) {
				trace('Bitmap not found for key: $finalKey. Creating placeholder.');
				var placeholder = createPlaceholderGraphic(finalKey);
				if (placeholder != null) {
					return placeholder;
				}
				// If createPlaceholderGraphic fails, create small fallback inline
				trace('WARNING: Creating inline fallback for $finalKey');
				var fallbackBitmap = new BitmapData(50, 50, true, 0x00000000); // Transparent instead of gray
				var fallbackGraphic = FlxGraphic.fromBitmapData(fallbackBitmap, false, finalKey + "_inline");
				if (fallbackGraphic != null) {
					fallbackGraphic.persist = true;
					currentTrackedAssets.set(finalKey, fallbackGraphic);
					return fallbackGraphic;
				}
				// If even that fails, this is critical but we return null as last resort
				trace('CRITICAL: Cannot create placeholder or fallback for $finalKey');
				return null;
			}

			// Process bitmap if caching on GPU
			if (allowGPU && ClientPrefs.data.cacheOnGPU && bitmap.image != null) {
				bitmap.lock();
				if (bitmap.__texture == null) {
					bitmap.image.premultiplied = true;
					bitmap.getTexture(FlxG.stage.context3D);
				}
				bitmap.getSurface();
				bitmap.disposeImage();
				bitmap.image.data = null;
				bitmap.image = null;
				bitmap.readable = true;
			}

			// Create graphic from bitmap
			var graph:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, finalKey);
			if (graph != null) {
				graph.persist = true;
				graph.destroyOnNoUse = false;
				currentTrackedAssets.set(finalKey, graph);
				trackLocalAsset(finalKey);
				return graph;
			} else {
				trace('WARNING: FlxGraphic.fromBitmapData returned null for $finalKey');
				// Create emergency placeholder
				var emergencyBitmap = new BitmapData(30, 30, true, 0xFFFF00FF);
				var emergencyGraphic = FlxGraphic.fromBitmapData(emergencyBitmap, false, finalKey + "_emergency");
				if (emergencyGraphic != null) {
					emergencyGraphic.persist = true;
					currentTrackedAssets.set(finalKey, emergencyGraphic);
					return emergencyGraphic;
				}
			}
		} catch (e:Dynamic) {
			trace('EXCEPTION in image() for key $key: $e');
		}
		
		// Ultimate fallback - should rarely reach here
		trace('ULTIMATE FALLBACK: Creating tiny graphic for $key');
		try {
			var ultimateBitmap = new BitmapData(10, 10, true, 0xFF000000);
			var ultimateGraphic = FlxGraphic.fromBitmapData(ultimateBitmap, false, key + "_ultimate_" + Math.floor(Math.random() * 999999));
			if (ultimateGraphic != null) {
				ultimateGraphic.persist = true;
				currentTrackedAssets.set(key, ultimateGraphic);
				return ultimateGraphic;
			}
		} catch (e:Dynamic) {
			trace('FAILED ultimate fallback: $e');
		}
		
		return null;
	}

	public static function cacheBitmap(key:String, ?parentFolder:String = null, ?bitmap:BitmapData, ?allowGPU:Bool = true):FlxGraphic
	{
		if (bitmap == null)
		{
			var graphicKey = key.replace('.png', '');
			return image(graphicKey, parentFolder, allowGPU);
		}

		if (currentTrackedAssets.exists(key))
		{
			trackLocalAsset(key);
			var cached:FlxGraphic = currentTrackedAssets.get(key);
			// A worker may have decoded this bitmap while the main thread loaded
			// the same key. Dispose the redundant CPU copy immediately.
			if (cached != null && bitmap != cached.bitmap) bitmap.dispose();
			return cached;
		}

		if (allowGPU && ClientPrefs.data.cacheOnGPU && bitmap.image != null)
		{
			bitmap.lock();
			if (bitmap.__texture == null)
			{
				bitmap.image.premultiplied = true;
				bitmap.getTexture(FlxG.stage.context3D);
			}
			bitmap.getSurface();
			bitmap.disposeImage();
			bitmap.image.data = null;
			bitmap.image = null;
			bitmap.readable = true;
		}

		var graphic:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, key);
		if (graphic != null)
		{
			graphic.persist = true;
			graphic.destroyOnNoUse = false;
			currentTrackedAssets.set(key, graphic);
			trackLocalAsset(key);
		}
		else bitmap.dispose();
		return graphic;
	}

	inline static public function getTextFromFile(key:String, ?ignoreMods:Bool = false):String
	{
		var path:String = getPath(key, TEXT, !ignoreMods);
		#if sys
		return (FileSystem.exists(path)) ? File.getContent(path) : null;
		#else
		return (OpenFlAssets.exists(path, TEXT)) ? Assets.getText(path) : null;
		#end
	}

	inline static public function font(key:String)
	{
		var folderKey:String = Language.getFileTranslation('fonts/$key');
		#if MODS_ALLOWED
		var file:String = modFolders(folderKey);
		if(FileSystem.exists(file)) return file;
		#end
		return 'assets/$folderKey';
	}

	public static function fileExists(key:String, type:AssetType, ?ignoreMods:Bool = false, ?parentFolder:String = null)
	{
		#if MODS_ALLOWED
		if(!ignoreMods)
		{
			var modKey:String = key;
			if(parentFolder == 'songs') modKey = 'songs/$key';

			for(mod in Mods.getGlobalMods())
				if (FileSystem.exists(mods('$mod/$modKey')))
					return true;

			if (FileSystem.exists(mods(Mods.currentModDirectory + '/' + modKey)) || FileSystem.exists(mods(modKey)))
				return true;
		}
		#end
		return (OpenFlAssets.exists(getPath(key, type, parentFolder, false)));
	}

	static public function getAtlas(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		var useMod = false;
		var imageLoaded:FlxGraphic = image(key, parentFolder, allowGPU); // Esto ahora nunca es null

		var myXml:Dynamic = getPath('images/$key.xml', TEXT, parentFolder, true);
		if(OpenFlAssets.exists(myXml) #if MODS_ALLOWED || (FileSystem.exists(myXml) && (useMod = true)) #end )
		{
			#if MODS_ALLOWED
			return FlxAtlasFrames.fromSparrow(imageLoaded, (useMod ? File.getContent(myXml) : myXml));
			#else
			return FlxAtlasFrames.fromSparrow(imageLoaded, myXml);
			#end
		}
		else
		{
			var myJson:Dynamic = getPath('images/$key.json', TEXT, parentFolder, true);
			if(OpenFlAssets.exists(myJson) #if MODS_ALLOWED || (FileSystem.exists(myJson) && (useMod = true)) #end )
			{
				#if MODS_ALLOWED
				return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, (useMod ? File.getContent(myJson) : myJson));
				#else
				return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, myJson);
				#end
			}
		}
		return getPackerAtlas(key, parentFolder);
	}
	
	static public function getMultiAtlas(keys:Array<String>, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		
		var parentFrames:FlxAtlasFrames = Paths.getAtlas(keys[0].trim());
		// Ya no es necesario chequear si es null, pero lo dejamos por si getAtlas falla por otra razón (XML/JSON malformado)
		if (parentFrames == null)
		{
			trace('WARNING: Could not load multi atlas for key: ${keys[0]}');
			return null;
		}

		if(keys.length > 1)
		{
			var original:FlxAtlasFrames = parentFrames;
			parentFrames = new FlxAtlasFrames(parentFrames.parent);
			parentFrames.addAtlas(original, true);
			for (i in 1...keys.length)
			{
				var extraFrames:FlxAtlasFrames = Paths.getAtlas(keys[i].trim(), parentFolder, allowGPU);
				if(extraFrames != null)
					parentFrames.addAtlas(extraFrames, true);
				else
					trace('WARNING: Could not load atlas for key: ${keys[i]} in multi atlas');
			}
		}
		return parentFrames;
	}

	inline static public function getSparrowAtlas(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		if(key.contains('psychic')) trace(key, parentFolder, allowGPU);
		var imageLoaded:FlxGraphic = image(key, parentFolder, allowGPU); // Esto ahora nunca es null

		#if MODS_ALLOWED
		var xmlExists:Bool = false;

		var xml:String = modsXml(key);
		if(FileSystem.exists(xml)) xmlExists = true;

		var xmlPath:String = (xmlExists ? xml : getPath(Language.getFileTranslation('images/$key') + '.xml', TEXT, parentFolder));
		var xmlContent:String = null;
		
		if (xmlExists) {
			xmlContent = File.getContent(xmlPath);
		} else if (OpenFlAssets.exists(xmlPath, TEXT)) {
			xmlContent = OpenFlAssets.getText(xmlPath);
		}
		
		if (xmlContent == null) {
			trace('WARNING: XML not found for Sparrow atlas: $key - returning null');
			return null;
		}
		
		return FlxAtlasFrames.fromSparrow(imageLoaded, xmlContent);
		#else
		var xmlPath:String = getPath(Language.getFileTranslation('images/$key') + '.xml', TEXT, parentFolder);
		var xmlContent:String = null;
		
		if (OpenFlAssets.exists(xmlPath, TEXT)) {
			xmlContent = OpenFlAssets.getText(xmlPath);
		}
		
		if (xmlContent == null) {
			trace('WARNING: XML not found for Sparrow atlas: $key - returning null');
			return null;
		}
		
		return FlxAtlasFrames.fromSparrow(imageLoaded, xmlContent);
		#end
	}

	inline static public function getPackerAtlas(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		var imageLoaded:FlxGraphic = image(key, parentFolder, allowGPU); // Esto ahora nunca es null

		#if MODS_ALLOWED
		var txtExists:Bool = false;
		
		var txt:String = modsTxt(key);
		if(FileSystem.exists(txt)) txtExists = true;

		return FlxAtlasFrames.fromSpriteSheetPacker(imageLoaded, (txtExists ? File.getContent(txt) : getPath(Language.getFileTranslation('images/$key') + '.txt', TEXT, parentFolder)));
		#else
		return FlxAtlasFrames.fromSpriteSheetPacker(imageLoaded, getPath(Language.getFileTranslation('images/$key') + '.txt', TEXT, parentFolder));
		#end
	}

	inline static public function getAsepriteAtlas(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		var imageLoaded:FlxGraphic = image(key, parentFolder, allowGPU); // Esto ahora nunca es null

		#if MODS_ALLOWED
		var jsonExists:Bool = false;

		var json:String = modsImagesJson(key);
		if(FileSystem.exists(json)) jsonExists = true;

		return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, (jsonExists ? File.getContent(json) : getPath(Language.getFileTranslation('images/$key') + '.json', TEXT, parentFolder)));
		#else
		return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, getPath(Language.getFileTranslation('images/$key') + '.json', TEXT, parentFolder));
		#end
	}

	inline static public function formatToSongPath(path:String) {
		final invalidChars = ~/[~&;:<>#\s]/g;
		final hideChars = ~/[.,'"%?!]/g;

		return hideChars.replace(invalidChars.replace(path, '-'), '').trim().toLowerCase();
	}

	public static var currentTrackedSounds:Map<String, Sound> = [];
	public static function returnSound(key:String, ?path:String, ?modsAllowed:Bool = true, ?beepOnNull:Bool = true)
	{
		var file:String = getPath(Language.getFileTranslation(key) + '.$SOUND_EXT', SOUND, path, modsAllowed);

		//trace('precaching sound: $file');
		if(!currentTrackedSounds.exists(file))
		{
			#if sys
			if(FileSystem.exists(file))
				currentTrackedSounds.set(file, Sound.fromFile(file));
			#else
			if(OpenFlAssets.exists(file, SOUND))
				currentTrackedSounds.set(file, OpenFlAssets.getSound(file));
			#end
			else if(beepOnNull)
			{
				trace('SOUND NOT FOUND: $key, PATH: $path');
				FlxG.log.error('SOUND NOT FOUND: $key, PATH: $path');
				return FlxAssets.getSound('flixel/sounds/beep');
			}
		}
		trackLocalAsset(file);
		return currentTrackedSounds.get(file);
	}

	#if MODS_ALLOWED
	inline static public function mods(key:String = '')
		return 'mods/' + key;

	inline static public function modsJson(key:String)
		return modFolders('data/' + key + '.json');

	inline static public function modsVideo(key:String)
		return modFolders('videos/' + key + '.' + VIDEO_EXT);

	inline static public function modsSounds(path:String, key:String)
		return modFolders(path + '/' + key + '.' + SOUND_EXT);

	inline static public function modsImages(key:String)
		return modFolders('images/' + key + '.png');

	inline static public function modsXml(key:String)
		return modFolders('images/' + key + '.xml');

	inline static public function modsTxt(key:String)
		return modFolders('images/' + key + '.txt');

	inline static public function modsImagesJson(key:String)
		return modFolders('images/' + key + '.json');

	static public function modFolders(key:String)
	{
		if(Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
		{
			var fileToCheck:String = mods(Mods.currentModDirectory + '/' + key);
			if(FileSystem.exists(fileToCheck))
				return fileToCheck;
		}

		for(mod in Mods.getGlobalMods())
		{
			var fileToCheck:String = mods(mod + '/' + key);
			if(FileSystem.exists(fileToCheck))
				return fileToCheck;
		}
		return 'mods/' + key;
	}
	#end

	#if flxanimate
	public static function loadAnimateAtlas(spr:FlxAnimate, folderOrImg:Dynamic, spriteJson:Dynamic = null, animationJson:Dynamic = null)
	{
		var changedAnimJson = false;
		var changedAtlasJson = false;
		var changedImage = false;
		
		if(spriteJson != null)
		{
			changedAtlasJson = true;
			spriteJson = File.getContent(spriteJson);
		}

		if(animationJson != null) 
		{
			changedAnimJson = true;
			animationJson = File.getContent(animationJson);
		}

		// is folder or image path
		if(Std.isOfType(folderOrImg, String))
		{
			var originalPath:String = folderOrImg;
			for (i in 0...10)
			{
				var st:String = '$i';
				if(i == 0) st = '';

				if(!changedAtlasJson)
				{
					spriteJson = getTextFromFile('images/$originalPath/spritemap$st.json');
					if(spriteJson != null)
					{
						//trace('found Sprite Json');
						changedImage = true;
						changedAtlasJson = true;
						folderOrImg = image('$originalPath/spritemap$st');
						break;
					}
				}
				else if(fileExists('images/$originalPath/spritemap$st.png', IMAGE))
				{
					//trace('found Sprite PNG');
					changedImage = true;
					folderOrImg = image('$originalPath/spritemap$st');
					break;
				}
			}

			if(!changedImage)
			{
				//trace('Changing folderOrImg to FlxGraphic');
				changedImage = true;
				folderOrImg = image(originalPath);
			}

			if(!changedAnimJson)
			{
				//trace('found Animation Json');
				changedAnimJson = true;
				animationJson = getTextFromFile('images/$originalPath/Animation.json');
			}
		}

		//trace(folderOrImg);
		//trace(spriteJson);
		//trace(animationJson);
		spr.loadAtlasEx(folderOrImg, spriteJson, animationJson);
	}
	#end

	/**
	 * Asigna frames de forma segura a un sprite, evitando crashes si el atlas es null
	 */
	public static function safeAssignFrames(sprite:FlxSprite, atlas:FlxAtlasFrames, ?key:String = "unknown"):Void
	{
		if (atlas != null)
		{
			sprite.frames = atlas;
		}
		else
		{
			trace('WARNING: Atlas is null for key: $key - sprite frames will not be updated');
		}
	}

	/**
	 * DEPRECATED: La lógica ahora está en createPlaceholderGraphic
	 */
	private static function createPlaceholderBitmap(key:String):BitmapData
	{
		// Esta función ya no debería ser llamada directamente.
		// La nueva función createPlaceholderGraphic se encarga de todo.
		trace('DEPRECATED CALL to createPlaceholderBitmap for: $key');
		var width:Int = 128;
		var height:Int = 128;
		return new BitmapData(width, height, true, 0xFF808080);
	}
}
