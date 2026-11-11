package states;

#if desktop
import backend.Discord;
import sys.thread.Thread;
#end
import flixel.FlxG;
import states.SoftCodeMenuState;
import states.NoticesState;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.input.keyboard.FlxKey;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import haxe.Json;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#end
import options.GraphicsSettingsSubState;
//import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFrame;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.system.ui.FlxSoundTray;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.app.Application;
import openfl.Assets;

using StringTools;
typedef TitleData =
{

	titlex:Float,
	titley:Float,
	startx:Float,
	starty:Float,
	gfx:Float,
	gfy:Float,
	backgroundSprite:String,
	bpm:Int
}
class TitleState extends MusicBeatState
{
	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];
	 public static var closedState:Bool = false;

	public static var initialized:Bool = false;
	 var mustUpdate:Bool = false;

	var blackScreen:FlxSprite;

	var titleTextColors:Array<FlxColor> = [0xFF33FFFF, 0xFF3333CC];
	var titleTextAlphas:Array<Float> = [1, .64];

	var titleJSON:TitleData;

	public static var updateVersion:String = '';

	override public function create():Void
	{
		var gameConfig = backend.GameConfig.getInstance();
		var showOpeningVideo:Bool = gameConfig.getBool('menu', 'showopeningvideo', true);

		// En la primera configuración, esperar a la respuesta sobre el opening.
		// En los siguientes arranques se conserva el orden habitual.
		if(showOpeningVideo && !OpeningVideoState.playedThisSession && !StartupSetupState.isNeeded())
		{
			MusicBeatState.switchState(new OpeningVideoState());
			return;
		}

		var showNoticesOnStartup:Bool = gameConfig.getBool('menu', 'shownoticesonstartup', true);

		if (showNoticesOnStartup || (StartupSetupState.isTestMode() && StartupSetupState.isNeeded()))
		{
			MusicBeatState.switchState(new NoticesState());
			return;
		}

		// Con los avisos desactivados, completar primero la configuración pendiente.
		if (StartupSetupState.isNeeded())
		{
			MusicBeatState.switchState(new StartupSetupState());
			return;
		}

		// Entrar al título del menú elegido en gameData.ini.
		backend.MenuSelector.init();
		switch (backend.MenuSelector.getMenu())
		{
			// MenuDemoSempai entra directamente al Main Menu y se salta el título.
			// Al arrancar sin Notices queremos conservar la presentación clásica.
			case 'oldmenu': MusicBeatState.switchState(new TitleState_oldmenu());
			default: MusicBeatState.switchState(new SoftCodeMenuState());
		}
	}


	override function beatHit()
	{
		super.beatHit();
		// Solo animar el logo si existe
		// if(titleText != null) titleText.animation.play('idle');
	}

	// TitleState reducido: solo puente a SoftCodeMenuState
}
