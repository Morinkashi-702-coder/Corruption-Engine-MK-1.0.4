package states;

import backend.WeekData;
import backend.Highscore;
import backend.Song;

import objects.HealthIcon;
import objects.MusicPlayer;

import options.GameplayChangersSubstate;
import substates.ResetScoreSubState;

import flixel.math.FlxMath;
import flixel.util.FlxDestroyUtil;

import openfl.utils.Assets;

import haxe.Json;

class FreeplayState_oldmenu extends MusicBeatState
{
var songs:Array<SongMetadata_oldmenu> = [];

var selector:FlxText;
private static var curSelected:Int = 0;
var lerpSelected:Float = 0;
var curDifficulty:Int = -1;
private static var lastDifficultyName:String = Difficulty.getDefault();

var scoreBG:FlxSprite;
var scoreText:FlxText;
var diffText:FlxText;
var lerpScore:Int = 0;
var lerpRating:Float = 0;
var intendedScore:Int = 0;
var intendedRating:Float = 0;

private var grpSongs:FlxTypedGroup<Alphabet>;
private var curPlaying:Bool = false;

// DESACTIVADO: iconArray - causaba crashes en destrucción
// private var iconArray:Array<HealthIcon> = [];

var bg:FlxSprite;
var intendedColor:Int;

var menuFPSoul:FlxSprite;

var missingTextBG:FlxSprite;
var missingText:FlxText;

var bottomString:String;
var bottomText:FlxText;
var bottomBG:FlxSprite;

var player:MusicPlayer;

override function create()
{
persistentUpdate = true;
PlayState.isStoryMode = false;
WeekData.reloadWeekFiles(false);

// Cargar datos de Alphabet ANTES de usarlos
AlphaCharacter.loadAlphabetData();

#if DISCORD_ALLOWED
DiscordClient.changePresence("In the Menus", null);
#end

if(WeekData.weeksList.length < 1)
{
FlxTransitionableState.skipNextTransIn = true;
persistentUpdate = false;
MusicBeatState.switchState(new states.ErrorState("NO WEEKS ADDED FOR FREEPLAY\n\nPress ACCEPT to go to the Week Editor Menu.\nPress BACK to return to Main Menu.",
function() MusicBeatState.switchState(new states.editors.WeekEditorState()),
function() MusicBeatState.switchState(new states.MainMenuState_oldmenu())));
return;
}

for (i in 0...WeekData.weeksList.length)
{
if(weekIsLocked(WeekData.weeksList[i])) continue;

var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
if(leWeek == null || leWeek.songs == null) continue;
var leSongs:Array<String> = [];
var leChars:Array<String> = [];

for (j in 0...leWeek.songs.length)
{
leSongs.push(leWeek.songs[j][0]);
leChars.push(leWeek.songs[j][1]);
}

WeekData.setDirectoryFromWeek(leWeek);
for (song in leWeek.songs)
{
var colors:Array<Int> = song[2];
if(colors == null || colors.length < 3)
{
colors = [146, 113, 253];
}
addSong(song[0], i, song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2]));
}
}
Mods.loadTopMod();

// A week list can exist while every week is locked, invalid, or empty.
// Do not continue into selection code with an empty songs array.
if(songs.length < 1)
{
FlxTransitionableState.skipNextTransIn = true;
persistentUpdate = false;
MusicBeatState.switchState(new states.ErrorState("NO PLAYABLE SONGS FOUND IN FREEPLAY\n\nPress ACCEPT to go to the Week Editor Menu.\nPress BACK to return to Main Menu.",
function() MusicBeatState.switchState(new states.editors.WeekEditorState()),
function() MusicBeatState.switchState(new states.MainMenuState_oldmenu())));
return;
}

bg = new FlxSprite().loadGraphic(Paths.image('menus/freeplay/old/menuBlack'));
bg.antialiasing = ClientPrefs.data.antialiasing;
add(bg);
bg.screenCenter();

// Agregar imagen menuFPSoul con tween desde la derecha
menuFPSoul = new FlxSprite().loadGraphic(Paths.image('menus/freeplay/old/menuFPSoul'));
menuFPSoul.antialiasing = ClientPrefs.data.antialiasing;
menuFPSoul.scrollFactor.set();
menuFPSoul.screenCenter();

// Guardar la posición final
var finalXSoul:Float = menuFPSoul.x;

// Posicionar fuera de la pantalla (a la derecha)
menuFPSoul.x = finalXSoul + menuFPSoul.width;

add(menuFPSoul);

// Animar la entrada desde la derecha hacia el centro
FlxTween.tween(menuFPSoul, {x: finalXSoul}, 1.0, {
	ease: FlxEase.expoOut,
	startDelay: 0.3
});

grpSongs = new FlxTypedGroup<Alphabet>();
add(grpSongs);

for (i in 0...songs.length)
{
var songText:Alphabet = new Alphabet(20, 320, songs[i].songName, true);
songText.distancePerItem.x = 0; // Lista vertical, alineada al margen izquierdo.
songText.targetY = i;
grpSongs.add(songText);

songText.scaleX = Math.min(1, 980 / songText.width);
songText.snapToPosition();

// DESACTIVADO: iconArray - causaba crashes en destrucción
/*
Mods.currentModDirectory = songs[i].folder;
var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
icon.sprTracker = songText;

songText.visible = songText.active = songText.isMenuItem = false;
icon.visible = icon.active = false;

iconArray.push(icon);
// NO agregar directamente a la state, solo guardar en array
// add(icon);
*/

songText.visible = songText.active = songText.isMenuItem = false;
}
WeekData.setDirectoryFromWeek();

		// HUD de score y dificultad - posición fija en esquina superior derecha
		scoreText = new FlxText(0, 5, 0, "", 32);
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);

		scoreBG = new FlxSprite(0, 0).makeGraphic(1, 66, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		diffText = new FlxText(0, 41, 0, "", 24);
		diffText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, RIGHT);
		add(diffText);

		add(scoreText);
missingTextBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
missingTextBG.alpha = 0.6;
missingTextBG.visible = false;
add(missingTextBG);

missingText = new FlxText(50, 0, FlxG.width - 100, '', 24);
missingText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
missingText.scrollFactor.set();
missingText.visible = false;
add(missingText);

if(curSelected >= songs.length) curSelected = 0;
intendedColor = FlxColor.WHITE;
lerpSelected = curSelected;

curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(lastDifficultyName)));

bottomBG = new FlxSprite(0, FlxG.height - 26).makeGraphic(FlxG.width, 26, 0xFF000000);
bottomBG.alpha = 0.6;
add(bottomBG);

var leText:String = Language.getPhrase("freeplay_tip", "Press SPACE to listen to the Song / Press CTRL to open the Gameplay Changers Menu / Press RESET to Reset your Score and Accuracy.");
bottomString = leText;
var size:Int = 16;
bottomText = new FlxText(bottomBG.x, bottomBG.y + 4, FlxG.width, leText, size);
bottomText.setFormat(Paths.font("vcr.ttf"), size, FlxColor.WHITE, CENTER);
bottomText.scrollFactor.set();
add(bottomText);

// player = new MusicPlayer(this); // MusicPlayer solo es compatible con FreeplayState, no con FreeplayState_oldmenu
// if(player != null)
//	add(player);

changeSelection();
updateTexts();

super.create();
}

override function closeSubState()
{
	changeSelection(0, false);
	persistentUpdate = true;
	super.closeSubState();
}

public function addSong(songName:String, weekNum:Int, songCharacter:String, color:Int)
{
songs.push(new SongMetadata_oldmenu(songName, weekNum, songCharacter, color));
}

function weekIsLocked(name:String):Bool
{
var leWeek:WeekData = WeekData.weeksLoaded.get(name);
if(leWeek == null) return true;
return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
}

	var instPlaying:Int = -1;
	public static var vocals:FlxSound = null;
	public static var opponentVocals:FlxSound = null;
	var holdTime:Float = 0;

	var stopMusicPlay:Bool = false;
	
	override function update(elapsed:Float)
	{
		if(WeekData.weeksList.length < 1)
			return;

		if (FlxG.sound.music != null && FlxG.sound.music.volume < 0.7)
			FlxG.sound.music.volume += 0.5 * elapsed;

		lerpScore = Math.floor(FlxMath.lerp(intendedScore, lerpScore, Math.exp(-elapsed * 24)));
		lerpRating = FlxMath.lerp(intendedRating, lerpRating, Math.exp(-elapsed * 12));

if (Math.abs(lerpScore - intendedScore) <= 10)
lerpScore = intendedScore;
if (Math.abs(lerpRating - intendedRating) <= 0.01)
lerpRating = intendedRating;

var ratingSplit:Array<String> = Std.string(CoolUtil.floorDecimal(lerpRating * 100, 2)).split('.');
if(ratingSplit.length < 2)
ratingSplit.push('');

while(ratingSplit[1].length < 2)
ratingSplit[1] += '0';

		var shiftMult:Int = 1;
		if(FlxG.keys.pressed.SHIFT) shiftMult = 3;

		// Actualizar texto de puntaje siempre (sin depender de player)
		scoreText.text = Language.getPhrase('personal_best', 'PERSONAL BEST: {1} ({2}%)', [lerpScore, ratingSplit.join('.')]);
		positionHighscore();

		// Controles de navegación (sin depender de player)
		if(songs.length > 1)
		{
			if(FlxG.keys.justPressed.HOME)
			{
				curSelected = 0;
				changeSelection();
				holdTime = 0;
			}
			else if(FlxG.keys.justPressed.END)
			{
				curSelected = songs.length - 1;
				changeSelection();
				holdTime = 0;
			}
			if (controls.UI_UP_P)
			{
				changeSelection(-shiftMult);
				holdTime = 0;
			}
			if (controls.UI_DOWN_P)
			{
				changeSelection(shiftMult);
				holdTime = 0;
			}

			if(controls.UI_DOWN || controls.UI_UP)
			{
				var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
				holdTime += elapsed;
				var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

				if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
					changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
			}

			if(FlxG.mouse.wheel != 0)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
				changeSelection(-shiftMult * FlxG.mouse.wheel, false);
			}
		}

		// Controles de dificultad (sin depender de player)
		if (controls.UI_LEFT_P)
		{
			changeDiff(-1);
			_updateSongLastDifficulty();
		}
		else if (controls.UI_RIGHT_P)
		{
			changeDiff(1);
			_updateSongLastDifficulty();
		}

		// Botón BACK para regresar al menú principal
		if (controls.BACK)
		{
			persistentUpdate = false;
			FlxG.sound.play(Paths.sound('cancelMenu'));
			// Bajar música suavemente al regresar
			FlxTween.tween(FlxG.sound.music, {volume: 0.7}, 0.5, {ease: FlxEase.expoOut});
			// Hacer que menuFPSoul salga hacia la derecha
			if (menuFPSoul != null)
			{
				var finalXSoulExit:Float = menuFPSoul.x + menuFPSoul.width;
				FlxTween.tween(menuFPSoul, {x: finalXSoulExit}, 0.5, {ease: FlxEase.expoIn});
			}
			new FlxTimer().start(0.5, function(tmr:FlxTimer) {
				MusicBeatState.switchState(new MainMenuState_oldmenu());
			});
		}

		// Menú de Gameplay Changers (CTRL)
		if(FlxG.keys.justPressed.CONTROL)
		{
			persistentUpdate = false;
			openSubState(new GameplayChangersSubstate());
		}
		// Reproducir música de preview (SPACE) - simplificado sin player
		else if(FlxG.keys.justPressed.SPACE)
		{
			if(instPlaying != curSelected)
			{
				destroyFreeplayVocals();
				FlxG.sound.music.volume = 0;

Mods.currentModDirectory = songs[curSelected].folder;
var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty);
Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
if (PlayState.SONG.needsVoices)
{
vocals = new FlxSound();
try
{
var playerVocals:String = getVocalFromCharacter(PlayState.SONG.player1);
var loadedVocals = Paths.voices(PlayState.SONG.song, (playerVocals != null && playerVocals.length > 0) ? playerVocals : 'Player');
if(loadedVocals == null) loadedVocals = Paths.voices(PlayState.SONG.song);

if(loadedVocals != null && loadedVocals.length > 0)
{
vocals.loadEmbedded(loadedVocals);
FlxG.sound.list.add(vocals);
vocals.persist = vocals.looped = true;
vocals.volume = 0.8;
vocals.play();
vocals.pause();
}
else vocals = FlxDestroyUtil.destroy(vocals);
}
catch(e:Dynamic)
{
vocals = FlxDestroyUtil.destroy(vocals);
}

opponentVocals = new FlxSound();
try
{
var oppVocals:String = getVocalFromCharacter(PlayState.SONG.player2);
var loadedVocals = Paths.voices(PlayState.SONG.song, (oppVocals != null && oppVocals.length > 0) ? oppVocals : 'Opponent');

if(loadedVocals != null && loadedVocals.length > 0)
{
opponentVocals.loadEmbedded(loadedVocals);
FlxG.sound.list.add(opponentVocals);
opponentVocals.persist = opponentVocals.looped = true;
opponentVocals.volume = 0.8;
opponentVocals.play();
opponentVocals.pause();
}
else opponentVocals = FlxDestroyUtil.destroy(opponentVocals);
}
catch(e:Dynamic)
{
opponentVocals = FlxDestroyUtil.destroy(opponentVocals);
}
}

			FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 0.8);
			instPlaying = curSelected;
		}
		else if (instPlaying == curSelected)
		{
			// Pausar/reanudar música si ya está sonando esta canción
			if(FlxG.sound.music.playing)
				FlxG.sound.music.pause();
			else
				FlxG.sound.music.resume();
		}
	}
	// Botón ACCEPT para seleccionar canción
	else if (controls.ACCEPT)
	{
		persistentUpdate = false;
		var songLowercase:String = Paths.formatToSongPath(songs[curSelected].songName);
		var poop:String = Highscore.formatSong(songLowercase, curDifficulty);

try
{
Song.loadFromJson(poop, songLowercase);
PlayState.isStoryMode = false;
PlayState.storyDifficulty = curDifficulty;

trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
}
catch(e:haxe.Exception)
{
trace('ERROR! ${e.message}');

var errorStr:String = e.message;
if(errorStr.contains('There is no TEXT asset with an ID of')) errorStr = 'Missing file: ' + errorStr.substring(errorStr.indexOf(songLowercase), errorStr.length-1);
else errorStr += '\n\n' + e.stack;

missingText.text = 'ERROR WHILE LOADING CHART:\n$errorStr';
missingText.screenCenter(Y);
missingText.visible = true;
missingTextBG.visible = true;
FlxG.sound.play(Paths.sound('cancelMenu'));

updateTexts(elapsed);
super.update(elapsed);
return;
}

@:privateAccess
if(PlayState._lastLoadedModDirectory != Mods.currentModDirectory)
{
trace('CHANGED MOD DIRECTORY, RELOADING STUFF');
Paths.freeGraphicsFromMemory();
}
LoadingState.prepareToSong();
LoadingState.loadAndSwitchState(new PlayState());
#if !SHOW_LOADING_SCREEN FlxG.sound.music.stop(); #end
stopMusicPlay = true;

destroyFreeplayVocals();
#if (MODS_ALLOWED && DISCORD_ALLOWED)
DiscordClient.loadModRPC();
#end
	}
	// Botón RESET para borrar puntaje
	else if(controls.RESET)
	{
		persistentUpdate = false;
		openSubState(new ResetScoreSubState(songs[curSelected].songName, curDifficulty, songs[curSelected].songCharacter));
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

updateTexts(elapsed);
super.update(elapsed);
}

function getVocalFromCharacter(char:String)
{
try
{
var path:String = Paths.getPath('characters/$char.json', TEXT);
#if MODS_ALLOWED
var character:Dynamic = Json.parse(File.getContent(path));
#else
var character:Dynamic = Json.parse(Assets.getText(path));
#end
return character.vocals_file;
}
catch (e:Dynamic) {}
return null;
}

public static function destroyFreeplayVocals() {
if(vocals != null) vocals.stop();
vocals = FlxDestroyUtil.destroy(vocals);

if(opponentVocals != null) opponentVocals.stop();
opponentVocals = FlxDestroyUtil.destroy(opponentVocals);
}

function changeDiff(change:Int = 0)
{
	curDifficulty = FlxMath.wrap(curDifficulty + change, 0, Difficulty.list.length-1);
#if !switch
intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
#end

lastDifficultyName = Difficulty.getString(curDifficulty, false);
var displayDiff:String = Difficulty.getString(curDifficulty);
if (Difficulty.list.length > 1)
diffText.text = '< ' + displayDiff.toUpperCase() + ' >';
else
diffText.text = displayDiff.toUpperCase();

positionHighscore();
missingText.visible = false;
missingTextBG.visible = false;
}

function changeSelection(change:Int = 0, playSound:Bool = true)
{
	curSelected = FlxMath.wrap(curSelected + change, 0, songs.length-1);
	_updateSongLastDifficulty();
	if(playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

	if(grpSongs != null && grpSongs.members != null)
	{
		for (num => item in grpSongs.members)
		{
			// DESACTIVADO: iconArray
			/*
			if(num < iconArray.length && item != null)
			{
				var icon:HealthIcon = iconArray[num];
				item.alpha = 0.6;
				if(icon != null) icon.alpha = 0.6;
				if (item.targetY == curSelected)
				{
					item.alpha = 1;
					if(icon != null) icon.alpha = 1;
				}
			}
			*/
			if(item != null)
			{
				item.alpha = 0.6;
				if (item.targetY == curSelected)
				{
					item.alpha = 1;
				}
			}
		}
	}

	Mods.currentModDirectory = songs[curSelected].folder;
	PlayState.storyWeek = songs[curSelected].week;
	Difficulty.loadFromWeek();

	var savedDiff:String = songs[curSelected].lastDifficulty;
	var lastDiff:Int = Difficulty.list.indexOf(lastDifficultyName);
	if(savedDiff != null && !Difficulty.list.contains(savedDiff) && Difficulty.list.contains(savedDiff))
		curDifficulty = Math.round(Math.max(0, Difficulty.list.indexOf(savedDiff)));
	else if(lastDiff > -1)
		curDifficulty = lastDiff;
	else if(Difficulty.list.contains(Difficulty.getDefault()))
		curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(Difficulty.getDefault())));
	else
		curDifficulty = 0;

	changeDiff();
	_updateSongLastDifficulty();
}

inline private function _updateSongLastDifficulty()
songs[curSelected].lastDifficulty = Difficulty.getString(curDifficulty, false);

private function positionHighscore()
{
	// Posicionar HUD en la esquina superior derecha
	scoreText.x = FlxG.width - scoreText.textField.textWidth - 20;
	scoreText.y = 5;
	
	diffText.x = FlxG.width - diffText.textField.textWidth - 20;
	diffText.y = 41;
	
	// Recuadro negro detrás del récord y la dificultad, con margen para ambos.
	var totalWidth:Float = Math.max(scoreText.width, diffText.width) + 32;
	scoreBG.setGraphicSize(Math.ceil(totalWidth), 66);
	scoreBG.updateHitbox();
	scoreBG.x = FlxG.width - scoreBG.width + 10;
	scoreBG.y = 0;
}var _drawDistance:Int = 4;
var _lastVisibles:Array<Int> = [];
public function updateTexts(elapsed:Float = 0.0)
{
	if(grpSongs == null) return;
	
	lerpSelected = FlxMath.lerp(curSelected, lerpSelected, Math.exp(-elapsed * 9.6));
	for (i in _lastVisibles)
	{
		if(i < grpSongs.members.length && grpSongs.members[i] != null)
		{
			grpSongs.members[i].visible = grpSongs.members[i].active = false;
		}
		// DESACTIVADO: iconArray
		/*
		if(i < iconArray.length && iconArray[i] != null)
		{
			iconArray[i].visible = iconArray[i].active = false;
		}
		*/
	}
	_lastVisibles = [];

	var min:Int = Math.round(Math.max(0, Math.min(songs.length, lerpSelected - _drawDistance)));
	var max:Int = Math.round(Math.max(0, Math.min(songs.length, lerpSelected + _drawDistance)));
	for (i in min...max)
	{
		if(i < grpSongs.members.length && grpSongs.members[i] != null)
		{
			var item:Alphabet = grpSongs.members[i];
			item.visible = item.active = true;
			item.x = ((item.targetY - lerpSelected) * item.distancePerItem.x) + item.startPosition.x;
			item.y = ((item.targetY - lerpSelected) * 1.3 * item.distancePerItem.y) + item.startPosition.y;
			_lastVisibles.push(i);
		}

		// DESACTIVADO: iconArray
		/*
		if(i < iconArray.length && iconArray[i] != null)
		{
			var icon:HealthIcon = iconArray[i];
			icon.visible = icon.active = true;
			_lastVisibles.push(i);
		}
		*/
	}
}

override function destroy():Void
{
	grpSongs = null;
	// DESACTIVADO: iconArray - causaba crashes
	// iconArray = null;
	
	// DESACTIVADO: player no se agrega a la state
	// player = null;
	
	super.destroy();

	FlxG.autoPause = ClientPrefs.data.autoPause;
	// if (FlxG.sound.music != null && !FlxG.sound.music.playing && !stopMusicPlay)
	// 	FlxG.sound.playMusic(Paths.music('freakyMenu'));
}
}


class SongMetadata_oldmenu
{
public var songName:String = "";
public var week:Int = 0;
public var songCharacter:String = "";
public var color:Int = -7179779;
public var folder:String = "";
public var lastDifficulty:String = null;

public function new(song:String, week:Int, songCharacter:String, color:Int)
{
this.songName = song;
this.week = week;
this.songCharacter = songCharacter;
this.color = color;
this.folder = Mods.currentModDirectory;
if(this.folder == null) this.folder = '';
}
}
