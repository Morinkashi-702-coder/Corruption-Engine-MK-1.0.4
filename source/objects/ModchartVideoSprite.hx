package source.objects;

import source.objects.VideoSprite;
import source.psychlua.ModchartSprite;

class ModchartVideoSprite extends VideoSprite {
	public var animOffsets:Map<String, Array<Float>> = new Map<String, Array<Float>>();

	public function new(videoName:String, isWaiting:Bool = false, canSkip:Bool = false, shouldLoop:Dynamic = false) {
		super(videoName, isWaiting, canSkip, shouldLoop);
		antialiasing = ClientPrefs.data.antialiasing;
	}

	public function playAnim(name:String, forced:Bool = false, ?reverse:Bool = false, ?startFrame:Int = 0) {
		// No animation system for video, but keep for API parity
	}

	public function addOffset(name:String, x:Float, y:Float) {
		animOffsets.set(name, [x, y]);
	}
}
