package flump.library;

import flump.DisplayObjectKey;
import flump.json.FlumpJSON.TextureGroupSpec;
import flump.json.FlumpJSON;
import flump.library.*;
using Lambda;



class FlumpLibrary{

	public var movieSymbols = new Map<String, MovieSymbol>();
	public var spriteSymbols = new Map<String, SpriteSymbol>();

	public var resolution:Float;
	public var textureGroupSpec:TextureGroupSpec;

	private var json:FlumpJSON;


	function new(){}


	private function init(flumpData:Dynamic, resolution:Float){
		this.resolution = resolution;
		json = cast flumpData;

		findBestScaleFactor();
		createSpriteSymbols();
		createMovieSymbols();
		setKeyframeSymbols();
		setupLayerKeyframeProps();
		linkKeyframeNextAndPrev();
		linkKeyframeNextAndPrevNonEmpty();
		setupDisplayKeys();
		setMovieTimes();
		setupLabels();
	}


	public function sprite_exists(id:String){
    return spriteSymbols.exists(id);
  }


  public function movie_exists(id:String){
    return movieSymbols.exists(id);
  }



	private function createSpriteSymbols(){
		for(atlasSpec in textureGroupSpec.atlases){
			for(textureSpec in atlasSpec.textures){
				var spriteSymbol = new SpriteSymbol();
				spriteSymbol.name = textureSpec.symbol;
				spriteSymbols[spriteSymbol.name] = spriteSymbol;
				spriteSymbol.textureSpec = textureSpec;
				spriteSymbol.atlasSpec = atlasSpec;
				spriteSymbol.origin = new Point(textureSpec.origin.x, textureSpec.origin.y);
			}
		}
	}


	private function createMovieSymbols(){
		for(movieSpec in json.movies){
			var movieSymbol = new MovieSymbol();
			movieSymbol.name = movieSpec.id;
			movieSymbols[movieSymbol.name] = movieSymbol;
			for(layerSpec in movieSpec.layers){
				var layer = new Layer();
				layer.movie = movieSymbol;
				layer.name = layerSpec.name;
				movieSymbol.layers.push(layer);
				for(keyframeSpec in layerSpec.keyframes){
					var keyframe = new Keyframe();
					layer.keyframes.push(keyframe);
					keyframe.layer = layer;
					keyframe.numFrames = keyframeSpec.duration;
					keyframe.durationMilli = keyframeSpec.duration * frame_time_milli;
					keyframe.frameStart = keyframeSpec.index;
					keyframe.frameEnd = keyframeSpec.index + keyframeSpec.duration;

					var time = keyframe.frameStart * frame_time_milli;
					time *= 10;
					time = Math.floor(time);
					time /= 10;
					keyframe.timeStartMilli = time;
					keyframe.timeEndMilli = time + keyframe.durationMilli;

					if(keyframeSpec.ref == null){
						keyframe.isEmpty = true;
					}else{
						keyframe.isEmpty = false;
						keyframe.symbolName = keyframeSpec.ref;
						keyframe.pivot = keyframeSpec.pivot == null ? new Point(0,0) : new Point( keyframeSpec.pivot.x * resolution, keyframeSpec.pivot.y * resolution);
						keyframe.location = keyframeSpec.loc == null ? new Point(0,0) : new Point( keyframeSpec.loc.x * resolution, keyframeSpec.loc.y * resolution);
						keyframe.tweened = keyframeSpec.tweened == false ? false : true;
						keyframe.symbol = null;
						keyframe.scale = keyframeSpec.scale == null ? new Point(1,1) : new Point(keyframeSpec.scale.x, keyframeSpec.scale.y);
						keyframe.skew = keyframeSpec.skew == null ? new Point(0,0) : new Point(keyframeSpec.skew.x, keyframeSpec.skew.y);
						keyframe.alpha = keyframeSpec.alpha == null ? 1 : keyframeSpec.alpha;
						keyframe.ease = keyframeSpec.ease == null ? 0 : keyframeSpec.ease;
					}
				}
			}
		}
	}


	private function setKeyframeSymbols(){
		for(movieSymbol in movieSymbols){
			for(layer in movieSymbol.layers){
				for(keyframe in layer.keyframes){
					if(movieSymbols.exists(keyframe.symbolName)) keyframe.symbol = movieSymbols[keyframe.symbolName];
					if(spriteSymbols.exists(keyframe.symbolName)) keyframe.symbol = spriteSymbols[keyframe.symbolName];
				}
			}
		}
	}


	private function setupLayerKeyframeProps(){
		for(movieSymbol in movieSymbols){
			for(layer in movieSymbol.layers){
				if(layer.keyframes.length > 0){
					layer.firstKeyframe = layer.keyframes[0];
					layer.lastKeyframe = layer.keyframes[layer.keyframes.length-1];
					layer.duration = layer.lastKeyframe.timeEndMilli;
					layer.numFrames = layer.lastKeyframe.frameEnd;
				}else{
					layer.numFrames = 0;
					layer.duration = 0;
				}
			}
		}
	}


	private function linkKeyframeNextAndPrev(){
		for(movieSymbol in movieSymbols){
			for(layer in movieSymbol.layers){
				for(i in 0...layer.keyframes.length-1){
					layer.keyframes[i].next = layer.keyframes[i+1];
				}
				for(i in 1...layer.keyframes.length){
					layer.keyframes[i].prev = layer.keyframes[i-1];
				}
				if(layer.keyframes.length > 0){
					layer.firstKeyframe.prev = layer.lastKeyframe;
					layer.lastKeyframe.next = layer.firstKeyframe;
					trace("Set first and last:", layer.firstKeyframe.prev.frameStart, layer.lastKeyframe.next.frameStart);
				}
			}
		}
	}


	private function linkKeyframeNextAndPrevNonEmpty(){
		for(movieSymbol in movieSymbols){
			for(layer in movieSymbol.layers){
				for(keyframe in layer.keyframes){
					keyframe.nextNonEmptyKeyframe = getNextNonEmpty(keyframe);
					keyframe.prevNonEmptyKeyframe = getPrevNonEmpty(keyframe);
				}
			}
		}
	}


	private function getPrevNonEmpty(keyframe:Keyframe){
		var firstChecked = keyframe;
		while(keyframe.prev != firstChecked){
			if(keyframe.prev.isEmpty == false) return keyframe.prev;
			else keyframe = keyframe.prev;
		}
		if(firstChecked.isEmpty) return null;
		return firstChecked;
	}


	private function setupDisplayKeys(){
		for(movieSymbol in movieSymbols){
			for(layer in movieSymbol.layers){
				var displayKey:DisplayObjectKey = null;
				for(keyframe in layer.keyframes){
					if(keyframe.isEmpty == false){
						if(displayKey == null || displayKey.symbolName != keyframe.symbolName){
							displayKey = new DisplayObjectKey(keyframe.symbolName);
						}
						keyframe.displayKey = displayKey;
					}
				}
			}
		}
	}


	private function setMovieTimes(){
		for(movieSymbol in movieSymbols){
			if(movieSymbol.layers.length == 0){
				movieSymbol.totalFrames = 0;
			}else{
				movieSymbol.totalFrames = movieSymbol.layers[0].numFrames;
				for(layer in movieSymbol.layers){
					if(layer.numFrames > movieSymbol.totalFrames) movieSymbol.totalFrames = layer.numFrames;
				}
			}
			movieSymbol.durationMilli = movieSymbol.totalFrames * frame_time_milli;
		}
	}


	private function setupLabels(){

	}


	private function getNextNonEmpty(keyframe:Keyframe){
		var firstChecked = keyframe;
		while(keyframe.next != firstChecked){
			if(keyframe.next.isEmpty == false) return keyframe.next;
			else keyframe = keyframe.next;
		}
		if(firstChecked.isEmpty) return null;
		return firstChecked;
	}

	private function getFirstNonEmpty(layer:Layer){
		if(layer.keyframes.length == 0) return null;
		var toCheck = layer.firstKeyframe;
		if(toCheck.isEmpty) return toCheck;
		while(toCheck.next != layer.firstKeyframe){
			if(toCheck.next.isEmpty == false) return toCheck.next;
			toCheck = toCheck.next;
		}
		return null;
	}


	public var md5(get, null):String;
	public function get_md5(){
		return json.md5;
	}


	public var fps(get, null):Float;
	public function get_fps(){
		return json.frameRate;
	}


	public var frame_time_milli(get, null):Float;
	public function get_frame_time_milli(){
			return (1000.0 / json.frameRate);
	}


	public var scale_factor(get, null):UInt;
	public function get_scale_factor(){
		return textureGroupSpec.scaleFactor;
	}


	private function findBestScaleFactor() {
		if(textureGroupSpec != null) throw("Already called findBestScaleFactor");
		for(textureGroupSpec in json.textureGroups){
			if(textureGroupSpec.scaleFactor >= resolution){
				this.textureGroupSpec = textureGroupSpec;
				return;
			}
		}
	}



	/*
	public static function create(flumpData:Dynamic, resolution:Float):FlumpLibrary{
		var lib:FlumpJSON = cast flumpData;

		var spriteSymbols = new Map<String, SpriteSymbol>();
		var movieSymbols = new Map<String, MovieSymbol>();

		var flumpLibrary = new FlumpLibrary(resolution);
		flumpLibrary.sprites = spriteSymbols;
		flumpLibrary.movies = movieSymbols;
		flumpLibrary.framerate = lib.frameRate;
		flumpLibrary.frameTime = 1000/flumpLibrary.framerate;
		flumpLibrary.md5 = lib.md5;

		var atlasSpecs = new Array<flump.json.FlumpJSON.AtlasSpec>();
		var textureGroup = null;

		// Find best suited resolution from available textures
		for(tg in lib.textureGroups){
			if(tg.scaleFactor >= resolution && textureGroup == null) textureGroup = tg;
		}
		if(textureGroup == null) textureGroup =  lib.textureGroups[lib.textureGroups.length-1];


		for(atlas in textureGroup.atlases){
			flumpLibrary.atlases.push(atlas);
			atlasSpecs.push(atlas);
		}


		for(spec in atlasSpecs){
			for(textureSpec in spec.textures){
				var frame = new Rectangle(textureSpec.rect.x, textureSpec.rect.y, textureSpec.rect.width, textureSpec.rect.height);
				var origin = new Point(textureSpec.origin.x, textureSpec.origin.y);

				var symbol = new SpriteSymbol();
				symbol.name = textureSpec.symbol;
				symbol.atlas = spec.file;
				symbol.origin = origin;
				symbol.texture = textureSpec.symbol;
				spriteSymbols[symbol.name] = symbol;
			}
		}

		var pendingSymbolAttachments = new Map<Keyframe, String>();
		for(movieSpec in lib.movies){
			var symbol = new MovieSymbol();
			symbol.name = movieSpec.id;
			symbol.library = flumpLibrary;
			for(layerSpec in movieSpec.layers){
				var layer = new Layer(layerSpec.name);
				layer.movie = symbol;
				var layerDuration:Float = 0;
				var previousKeyframe:Keyframe = null;
				for(keyframeSpec in layerSpec.keyframes){
					var keyframe = new Keyframe();
					keyframe.prev = previousKeyframe;
					if(previousKeyframe != null) previousKeyframe.next = keyframe;
					keyframe.layer = layer;
					keyframe.numFrames = keyframeSpec.duration;
					keyframe.duration = keyframeSpec.duration * flumpLibrary.frameTime;
					keyframe.index = keyframeSpec.index;

					var time = keyframe.index * flumpLibrary.frameTime;
					time *= 10;
					time = Math.floor(time);
					time /= 10;
					keyframe.time = time;

					if(keyframeSpec.ref == null){
						keyframe.isEmpty = true;
					}else{
						keyframe.isEmpty = false;
						keyframe.symbolId = keyframeSpec.ref;
						keyframe.pivot = keyframeSpec.pivot == null ? new Point(0,0) : new Point( keyframeSpec.pivot.x * resolution, keyframeSpec.pivot.y * resolution);
						keyframe.location = keyframeSpec.loc == null ? new Point(0,0) : new Point( keyframeSpec.loc.x * resolution, keyframeSpec.loc.y * resolution);
						keyframe.tweened = keyframeSpec.tweened == false ? false : true;
						keyframe.symbol = null;
						keyframe.scale = keyframeSpec.scale == null ? new Point(1,1) : new Point(keyframeSpec.scale.x, keyframeSpec.scale.y);
						keyframe.skew = keyframeSpec.skew == null ? new Point(0,0) : new Point(keyframeSpec.skew.x, keyframeSpec.skew.y);
						keyframe.alpha = keyframeSpec.alpha == null ? 1 : keyframeSpec.alpha;
						keyframe.ease = keyframeSpec.ease == null ? 0 : keyframeSpec.ease;
					}

					if(layer.keyframes.length == 0) layer.firstKeyframe = keyframe;

					if(keyframeSpec.label != null){
						keyframe.label = new Label();
						keyframe.label.keyframe = keyframe;
						keyframe.label.name = keyframeSpec.label;
						symbol.labels.set(keyframe.label.name, keyframe.label);
					}

					if(keyframe.time + keyframe.duration > layer.duration){
						layerDuration = keyframe.time + keyframe.duration;
					}

					pendingSymbolAttachments[keyframe] = keyframeSpec.ref;
					layer.keyframes.push(keyframe);
					previousKeyframe = keyframe;
				}

				layer.lastKeyframe = layer.keyframes[layer.keyframes.length - 1];
				layer.keyframes[0].prev = layer.lastKeyframe;
				layer.lastKeyframe.next = layer.keyframes[0];
				symbol.layers.push(layer);

				var allAreEmpty = layer.keyframes.foreach(function(keyframe) return keyframe.isEmpty);

				if(allAreEmpty){

				}else{
					for(keyframe in layer.keyframes){
						var hasNonEmptySibling = layer.keyframes.exists(function(checkedKeyframe) return checkedKeyframe.isEmpty == false && checkedKeyframe != keyframe);
						if(hasNonEmptySibling){
							var checked = keyframe.prev;
							while(checked.isEmpty) checked = checked.prev;
							keyframe.prevNonEmptyKeyframe = checked;

							checked = keyframe.next;
							while(checked.isEmpty) checked = checked.next;
							keyframe.nextNonEmptyKeyframe = checked;
						}else{
							keyframe.prevNonEmptyKeyframe = keyframe;
							keyframe.nextNonEmptyKeyframe = keyframe;
						}
					}

					// Set up diplay keys
					var firstNonEmpty = layer.keyframes.find(function(checkedKeyframe) return checkedKeyframe.isEmpty == false);
					if(firstNonEmpty != null) firstNonEmpty.displayKey = new DisplayObjectKey(firstNonEmpty.symbolId);
					var checked = firstNonEmpty.nextNonEmptyKeyframe;
					while(checked != firstNonEmpty){
						if(checked.symbolId == checked.prevNonEmptyKeyframe.symbolId) checked.displayKey = checked.prevNonEmptyKeyframe.displayKey;
						else checked.displayKey = new DisplayObjectKey(checked.symbolId);
						checked = checked.nextNonEmptyKeyframe;
					}
				}
			}

			function getHighestFrameNumber(layer:Layer, accum:UInt){
				var layerLength = layer.lastKeyframe.index + layer.lastKeyframe.numFrames;
				return layerLength > accum
					? layerLength
					: accum;
			}

			symbol.totalFrames = symbol.layers.fold( getHighestFrameNumber, 0 );
			symbol.duration = symbol.totalFrames * flumpLibrary.frameTime;

			var labels = new Array<Label>();
			for(layer in symbol.layers){
				for(keyframe in layer.keyframes){
					if(keyframe.label != null){
						labels.push(keyframe.label);
					}
				}
			}
			haxe.ds.ArraySort.sort(labels, sortLabel);
			for(i in 0...labels.length){
				var nextIndex = i+1;
				if(nextIndex >= labels.length) nextIndex = 0;

				var label = labels[i];
				var nextLabel = labels[nextIndex];
				label.next = nextLabel;
				nextLabel.prev = label;
			}
			symbol.firstLabel = labels[0];
			symbol.lastLabel = labels[labels.length-1];

			movieSymbols[symbol.name] = symbol;
		}

		for(keyframe in pendingSymbolAttachments.keys()){
			var symbolId = pendingSymbolAttachments[keyframe];
			keyframe.symbol = spriteSymbols[symbolId] != null ? spriteSymbols[symbolId] : movieSymbols[symbolId];
		}

		return flumpLibrary;
	}


	private static function sortLabel(a:Label, b:Label):Int{
		if(a.keyframe.index < b.keyframe.index) return -1;
		else if(a.keyframe.index > b.keyframe.index) return 1;
		return 0;
	}
	*/



}
