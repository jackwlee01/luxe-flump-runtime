package flump;

import luxe.Sprite;
import luxe.Rectangle;
import luxe.Vector;
import luxe.Entity;

import flump.core.FlumpJSON;
import flump.options.FlumpSpriteOptions;
import flump.core.*;


class FlumpSprite extends Sprite implements IFlumpDisplayObject{


  public function new(options:FlumpSpriteOptions){
      var library = options.library;
      if(library == null){
        for(toCheck in FlumpLibrary.libraries){
          if(toCheck.sprite_exists(options.name)){
            library = toCheck;
            break;
          }
        }
      }

      if(library == null) throw("Cannot find FlumpSprite with id: " + options.name);

      var symbol = library.spriteSymbols[options.name];
      super({
        texture: library.getTextureForSpriteSymbol(symbol),
        size: library.getSizeForSpriteSymbol(symbol),
        uv: library.getUVForSpriteSymbol(symbol)
      });

      alpha = 1;

      this.origin.x = symbol.origin.x;
      this.origin.y = symbol.origin.y;
  }


  public function render(){
    var alphaValue:Float = alpha;
    var checked:Entity = this.parent;
    while(Std.is(checked, IFlumpDisplayObject)){
      var parentDisplayObject:IFlumpDisplayObject = cast checked;
      alphaValue *= parentDisplayObject.alpha;
      checked = checked.parent;
    }
    color.a = alphaValue;
  }



  public var alpha(default, set):Float;
  public function get_alpha():Float{
    return alpha;
  }

  public function set_alpha(value:Float):Float{
    return alpha = value;
  }


}
