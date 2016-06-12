package flump.core;


class Keyframe{

	public var layer:Layer;
	public var symbolName:String;
	public var pivot:Point;

	public var location:Point;
	public var tweened:Bool;

	public var frameStart:UInt;				// The start of the keyframe measured in frames
	public var frameEnd:UInt;					// The end of the keyframe measured in frames
	public var numFrames:UInt;

	public var timeStartMilli:Float;	// Time the keyframe starts in milliseconds
	public var timeEndMilli:Float;		// Time the keyframe ends in milliseconds
	public var durationMilli:Float;		// Duration of the keyframe in milliseconds

	public var symbol:Symbol;
	public var scale:Point;
	public var skew:Point;
	public var ease:Float;
	public var label:Label;
	public var isEmpty:Bool;
	public var alpha:Float;

	public var next:Keyframe;
	public var prev:Keyframe;
	public var nextNonEmptyKeyframe:Keyframe;
	public var prevNonEmptyKeyframe:Keyframe;
	public var displayKey:DisplayObjectKey;

	public function new(){}

	// Does the time fall inside of the the keyframe frames
	public function timeInside(time:Float):Bool{
		return (timeStartMilli <= time) && (timeEndMilli) > time;
	}

	// Does the range fit inside of the keyframe frames
	public function rangeInside(from:Float, to:Float):Bool{
		return timeInside(from) && timeInside(to);
	}

	// Does the range intersect with the keyframe frames
	public function rangeIntersect(from:Float, to:Float):Bool{
		return timeInside(from) || timeInside(to);
	}

	// Does the start of the keyframe frames fall inside the range. (Checks for a range that wraps around)
	public function insideRangeStart(from:Float, to:Float):Bool{
		//if(from > to && to == time) return true;
		return from <= to
			? timeStartMilli > from && timeStartMilli <= to
			: timeStartMilli > from || timeStartMilli <= to;
	}

	// Does the end of the keyframe frames fall inside the range. (Checks for a range that wraps around, and assuming backward playback);
	public function insideRangeEnd(from:Float, to:Float):Bool{
		if(from == to && to == timeEndMilli) return true;
		return from > to
			? to <= timeEndMilli && from > timeEndMilli
			: to <= timeEndMilli || from > timeEndMilli;
	}

}
