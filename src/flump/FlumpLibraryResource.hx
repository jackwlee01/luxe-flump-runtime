package flump;

import luxe.resource.Resource;
import snow.api.Promise;
import flump.options.FlumpLibraryResourceOptions;


class FlumpLibraryResource extends Resource{

  public var path:String;
  public var resolution:Float;
  public var library:FlumpLibrary;


  private function new(path:String, resolution:Float){
      this.path = path;
      this.resolution = resolution;
      super({
        id: path
      });
  }


  public static function load(path:String, resolution:Float):Promise{
    return new FlumpLibraryResource(path, resolution).reload();
  }


  override function reload() : Promise {
    clear();

    return new Promise(function(resolve, reject){
      var toLoad:FlumpLibrary = null;
      toLoad = new FlumpLibrary(path, resolution, function(){
        this.library = toLoad;
        resolve(this);
      });
    });
  }


  override function clear() {
      if(library != null) FlumpLibrary.dispose(library);
  }


}
