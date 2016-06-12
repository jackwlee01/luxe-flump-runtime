package flump;

import luxe.Vector;
import luxe.Entity;
import luxe.Visual;

import flump.options.FlumpMovieOptions;
import flump.core.*;

using Std;


class FlumpMovie extends FlumpContainer{


  private var position(default, set):Float = 0; // The current playhead position
  private var previous:Float = 0; // The previous playhead position
  private var advanced:Float = 0; // How far the playhead has advanced

  private var durationMilli(get, null):Float; // Timeline duration in milliseconds

  private var symbol:MovieSymbol;
  private var master:FlumpMovie;
  private var library:FlumpLibrary;

  private var containers = new Map<Layer, FlumpContainer>(); // Containers associated with layers
  private var currentKeys = new Map<Layer, DisplayObjectKey>(); // Current keyframes that are displayed
  private var displayObjects = new Map<DisplayObjectKey, Visual>(); // All of the displayobjects required for all of the keyframes


  public function new(options:FlumpMovieOptions){
    super();

    library = options.library == null ? findLibrary(options.name) : options.library;
    this.master = options.master == null ? this : options.master;

    symbol = library.movieSymbols[options.name];
    for(layer in symbol.layers){
      containers[layer] = new FlumpContainer();
      containers[layer].parent = this;
    }

    update(0);
  }


  private function findLibrary(name:String){
    for(library in FlumpLibrary.libraries){
      if(library.movie_exists(name)) return library;
    }
    if(library == null) throw("Cannot find FlumpMovie: " + name);
    return library;
  }


  public function get_durationMilli():Float{
    return symbol.durationMilli;
  }


  public function set_position(value:Float){
    return position = value % durationMilli;
  }


  override function update(dt:Float){
    if(master != this) return;
    advance(dt * 1000);
    render();
  }


  private function advance(milli:Float){
    advanced = milli;
    position += advanced;

    for(layer in symbol.layers){
      var keyframe = layer.getKeyframeForTime(position);

      removeDisplayIfNessessary(layer, keyframe);
      createDisplayIfNessessary(keyframe);
      addDisplayIfNessessary(layer, keyframe);

      if(keyframe.isEmpty == false){
        if(keyframe.symbol.is(MovieSymbol)){
          var childMovie:FlumpMovie = cast displayObjects[keyframe.displayKey];
          var keyframeAdvancement = (position - keyframe.timeStartMilli);
          keyframeAdvancement = childMovie.position == 0 && keyframeAdvancement < advanced ? keyframeAdvancement : advanced;
          childMovie.advance(keyframeAdvancement);
        }
      }
    }

    previous = position;
    if(master == this) render();
  }


  override public function render(){
    for(layer in symbol.layers){
      var keyframe = layer.getKeyframeForTime(position);
      if(keyframe.isEmpty == false){
        var next = keyframe.tweened ? keyframe.next : keyframe;
        if(next.isEmpty) next = keyframe;

        var interped = getInterpolation(keyframe, position);
        var container:FlumpContainer = containers[keyframe.layer];

        var new_pos_x =  (keyframe.location.x + (next.location.x - keyframe.location.x) * interped);
        var new_pos_y = (keyframe.location.y + (next.location.y - keyframe.location.y) * interped);
        var new_scale_x = (keyframe.scale.x + (next.scale.x - keyframe.scale.x) * interped);
        var new_scale_y = (keyframe.scale.y + (next.scale.y - keyframe.scale.y) * interped);
        var new_rotation = (keyframe.skew.x + (next.skew.x - keyframe.skew.x) * interped) / (Math.PI / 180);
        var new_alpha = (keyframe.alpha + (next.alpha - keyframe.alpha) * interped);

        container.pos.x = new_pos_x;
        container.pos.y = new_pos_y;
        container.scale.x = new_scale_x;
        container.scale.y = new_scale_y;
        container.rotation_z = new_rotation;
        container.alpha = new_alpha;


        if(keyframe.symbol.is(MovieSymbol)){
          var childMovie:FlumpMovie = cast displayObjects[keyframe.displayKey];
          childMovie.render();
        }
      }
    }

    super.render();

    for(layer in symbol.layers){
      var keyframe = layer.getKeyframeForTime(position);
      if(keyframe.isEmpty == false){
        if(keyframe.symbol.is(MovieSymbol)){
          var childMovie:FlumpMovie = cast displayObjects[keyframe.displayKey];
          childMovie.render();
        }
      }
    }
  }


  private function getInterpolation(keyframe:Keyframe, time:Float){
		if(keyframe.tweened == false) return 0.0;

		var interped = (time - keyframe.timeStartMilli) / keyframe.durationMilli;
		var ease:Float = keyframe.ease;
		if (ease != 0) {
			var t :Float;
			if (ease < 0) {
				// Ease in
				var inv:Float = 1 - interped;
				t = 1 - inv * inv;
				ease = -ease;
			} else {
				// Ease out
				t = interped * interped;
			}
			interped = ease * t + (1 - ease) * interped;
		}
		return interped;
	}



  private function addDisplayIfNessessary(layer:Layer, keyframe:Keyframe){
    if(keyframe.isEmpty) return;
    if(currentKeys[layer] == keyframe.displayKey) return;

    var entity:Visual = displayObjects[keyframe.displayKey];
    var container:FlumpContainer = containers[keyframe.layer];
    currentKeys[keyframe.layer] = keyframe.displayKey;

    if(entity.is(FlumpMovie)){
      var addedEntity:FlumpMovie = cast entity;
      addedEntity.position = 0;
    }

    if(symbol.name == "PlanetDestroy"){
      trace("ADD: " + keyframe.layer.name + " " + keyframe.symbol.name);
    }

    entity.parent = container;
    entity.visible = true;
  }


  private function removeDisplayIfNessessary(layer:Layer, keyframe:Keyframe){
    if(currentKeys.exists(layer) == false) return;
    if(keyframe.isEmpty == false) if(currentKeys[layer] == keyframe.displayKey) return;

    var displayKey = currentKeys[layer];
    var entity = displayObjects[displayKey];
    entity.parent = null;
    entity.visible = false;
    currentKeys.remove(layer);

    if(symbol.name == "PlanetDestroy"){
      trace("REM: ", layer.name, displayKey.symbolName);
    }
  }


  private function createDisplayIfNessessary(keyframe:Keyframe){
    if(keyframe.isEmpty) return;
    if(displayObjects.exists(keyframe.displayKey)) return;

    var entity:Visual;
    if(keyframe.symbol.is(MovieSymbol)){
      entity = new FlumpMovie({
        name: keyframe.symbolName,
        master: master
      });
    }else if(keyframe.symbol.is(SpriteSymbol)){
      entity = new FlumpSprite({
        name: keyframe.symbolName
      });
    }else{
      throw("FlumpMovie.createDisplay error");
    }

    /*
    if(symbol.name == "PlanetDestroy"){
      trace("CRE: " + keyframe.layer.name + " " + keyframe.symbol.name);
    }
    */

    displayObjects[keyframe.displayKey] = entity;
  }


}


/*
import luxe.Vector;
import luxe.Entity;
import flump.DisplayObjectKey;
import flump.IFlumpMovie;
import flump.library.*;
import flump.DisplayObjectKey;
import flump.MoviePlayer;



typedef FlumpMovieOptions = {
  var name: String;
  @:optional var library:Library;
}



class FlumpMovie extends FlumpContainer implements IFlumpMovie{


  private var layers = new Map<Layer, FlumpContainer>();
  private var childrenDisplays = new Map<DisplayObjectKey, Dynamic>();
  private var library:Library;
  private var player:MoviePlayer;
  private var master:Bool;


  public function new(options:FlumpMovieOptions, master = true){
    library = options.library;
    this.master = master;

    if(library == null){
      for(toCheck in Library.libraries){
        if(toCheck.movieExists(options.name)) library = toCheck;
      }
    }


    if(library == null) throw("Cannot find FlumpMovie: " + options.name);

    super();

    var movieName = library.library.movies[options.name];
    player = new MoviePlayer(movieName, this, 1);
  }


  override function update(dt:Float){
    if(master){
      player.advanceTime(dt * 1000);
    }
  }


  private function createLayer(layer:Layer):Void{
    var container = new FlumpContainer();
    container.parent = this;
    layers[layer] = container;
  }


  private function createFlumpChild(layer:Layer, displayKey:DisplayObjectKey):Void{
  if(library.movieExists(displayKey.symbolId)){
      var movie = new FlumpMovie({
        name: displayKey.symbolId,
        library: library
      }, false);
      childrenDisplays[displayKey] = movie;
    }else if(library.spriteExists(displayKey.symbolId)){
      var sprite = new FlumpSprite({
        name: displayKey.symbolId
      });
      childrenDisplays[displayKey] = sprite;
    }else{
      throw("createFlumpChild error. This shouldn't happen.");
    }
  }


  private function removeFlumpChild(layer:Layer, displayKey:DisplayObjectKey):Void{
    var child:Dynamic = childrenDisplays[displayKey];
    var layer:FlumpContainer = layers[layer];
    if(Std.is(child, FlumpMovie)){
      var movie:FlumpMovie = cast child;
      movie.parent = null;
      movie.active = false;
    }else if(Std.is(child, FlumpSprite)){
      var sprite:FlumpSprite = cast child;
      sprite.parent = null;
      sprite.active = false;
    }else{
      throw("removeFlumpChild error. This shouldn't happen.");
    }
  }


  private function addFlumpChild(layer:Layer, displayKey:DisplayObjectKey):Void{
    var child:Dynamic = childrenDisplays[displayKey];
    var container:FlumpContainer = layers[layer];
    if(Std.is(child, FlumpMovie)){
      var movie:FlumpMovie = cast child;
      movie.parent = container;
      movie.active = true;
    }else if(Std.is(child, FlumpSprite)){
      var sprite:FlumpSprite = cast child;
      sprite.parent = container;
      sprite.active = true;
    }else{
      throw("addFlumpChild error. This shouldn't happen.");
    }
  }


  private function renderFrame(keyframe:Keyframe, x:Float, y:Float, scaleX:Float, scaleY:Float, skewX:Float, skewY:Float, pivotX:Float, pivotY:Float, alpha:Float):Void{
      var layer:FlumpContainer = layers[keyframe.layer];
      layer.pos.x = x;
      layer.pos.y = y;
      layer.scale.x = scaleX;
      layer.scale.y = scaleY;
      layer.rotation_z = skewX / (Math.PI / 180);
  }


  private function getChildPlayer(keyframe:Keyframe):MoviePlayer{
    var movie:FlumpMovie = cast childrenDisplays[keyframe.displayKey];
    return movie.player;
  }


  private function onAnimationComplete():Void{}
  private function labelPassed(label:Label):Void{}
  private function labelHit(label:Label):Void{}


}

*/
