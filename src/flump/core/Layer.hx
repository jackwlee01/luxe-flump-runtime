package flump.core;

class Layer{

	public var keyframes = new Array<Keyframe>();
	public var duration:Float;
	public var name:String;
	public var movie:MovieSymbol;
	public var numFrames:UInt;

	public var firstKeyframe:Keyframe;
	public var lastKeyframe:Keyframe;


	public function new(){}


	public function getKeyframeForFrame(index:UInt):Keyframe{
		for(keyframe in keyframes){
			if(keyframe.frameStart <= index && keyframe.frameEnd > index){
				return keyframe;
			}
		}
		return null;
	}


	public function getKeyframeForTime(timeMilli:Float){
		var keyframe = lastKeyframe;
		while(keyframe.timeStartMilli > timeMilli % movie.durationMilli) keyframe = keyframe.prev;
		return keyframe;
	}

}
