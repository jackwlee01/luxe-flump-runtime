package flump;


import luxe.resource.Resource;
import snow.api.Promise;
import snow.systems.assets.Asset;
import phoenix.Texture;
import phoenix.Texture;
import luxe.Rectangle;
import luxe.Vector;

import flump.core.FlumpJSON;
import flump.core.*;



class FlumpLibrary extends Library{

  private var cb:Void->Void;
  private var path:String;

  private var sizeLookup = new Map<SpriteSymbol, Vector>();
  private var uvLookup = new Map<SpriteSymbol, Rectangle>();
  private var textures = new Map<AtlasSpec, Texture>();


  public static var libraries = new Array<FlumpLibrary>();


  public function new(path:String, resolution:Float, cb:Void->Void){
      super();
      this.cb = cb;
      this.resolution = resolution;

      if(path.charAt(path.length-1) != "/") throw("FlumpLibrary path MUST end with a /");

      this.path = path;
      var load = Luxe.resources.load_json(path + "library.json");
      load.then(onJsonLoaded);
  }


  public static function dispose(library:FlumpLibrary){
    if(libraries.remove(library) == false) throw("Library at path " + library.path + " has already been disposed!");
  }


  private function onJsonLoaded(resource:JSONResource){
      init(resource.asset.json, resolution);

      for(spriteSymbol in spriteSymbols){
        var textureSpec = spriteSymbol.textureSpec;
        uvLookup[spriteSymbol] = new Rectangle(textureSpec.rect.x, textureSpec.rect.y, textureSpec.rect.width, textureSpec.rect.height);
        sizeLookup[spriteSymbol] = new Vector(textureSpec.rect.width, textureSpec.rect.height);
      }

      loadTextures();
  }


  private function loadTextures(){
    var toLoad = new Array<Promise>();

    for(atlasSpec in textureGroupSpec.atlases){
      var filePath = path + atlasSpec.file;
      toLoad.push(Luxe.resources.load_texture(filePath));
      Luxe.resources.load_texture(filePath);
    }

    var load = Promise.all(toLoad);
    load.then(onTexturesLoaded);
  }


  public function getTextureForSpriteSymbol(spriteSymbol:SpriteSymbol){
    return Luxe.resources.texture(path + spriteSymbol.atlasSpec.file);
  }


  public function getUVForSpriteSymbol(spriteSymbol:SpriteSymbol){
    return uvLookup[spriteSymbol];
  }


  public function getSizeForSpriteSymbol(spriteSymbol:SpriteSymbol){
    return sizeLookup[spriteSymbol];
  }


  private function onTexturesLoaded(textures:Array<phoenix.Texture>){
    trace("Textures loaded");
    libraries.push(this);
    cb();
  }


}
