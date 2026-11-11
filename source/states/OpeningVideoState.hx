package states;

#if VIDEOS_ALLOWED
import objects.VideoSprite;
#end

#if MODS_ALLOWED
import sys.FileSystem;
#end

/**
 * Reproduce el vídeo de apertura una sola vez por ejecución y después vuelve
 * al flujo normal de TitleState (Notices o el menú configurado).
 */
class OpeningVideoState extends MusicBeatState
{
	public static var playedThisSession:Bool = false;

	var continuing:Bool = false;
	var afterOpening:Void->Void;

	public function new(?afterOpening:Void->Void)
	{
		super();
		this.afterOpening = afterOpening;
	}

	override public function create():Void
	{
		super.create();
		playedThisSession = true;

		#if VIDEOS_ALLOWED
		var videoPath:String = Paths.video('opening');

		#if MODS_ALLOWED
		if(!FileSystem.exists(videoPath))
		{
			trace('[OpeningVideo] opening.mp4 not found: ' + videoPath);
			continueToStartup();
			return;
		}
		#end

		try
		{
			var openingVideo:VideoSprite = new VideoSprite(videoPath, false, true);
			openingVideo.finishCallback = continueToStartup;
			openingVideo.onSkip = continueToStartup;
			add(openingVideo);
			openingVideo.play();
		}
		catch(e:Dynamic)
		{
			trace('[OpeningVideo] Could not start opening.mp4: ' + e);
			continueToStartup();
		}
		#else
		continueToStartup();
		#end
	}

	function continueToStartup():Void
	{
		if(continuing) return;
		continuing = true;
		if (afterOpening != null) afterOpening();
		else MusicBeatState.switchState(new TitleState());
	}
}
