package flump.core;

import luxe.Entity;
import luxe.Visual;
import luxe.Vector;
import luxe.Quaternion;
import luxe.utils.Maths;

using Std;


class FlumpContainer extends Visual implements IFlumpDisplayObject{


  public function new(){
    super({
      no_geometry: true
    });
    alpha = 1;
  }


  public function render(){
    for(child in this.children){
      if(child.is(IFlumpDisplayObject)){
        var displayObject:IFlumpDisplayObject = cast child;
        displayObject.render();
      }
    }
  }


  public var alpha(default, set):Float;
  public function get_alpha():Float{
    return alpha;
  }


  public function set_alpha(value:Float):Float{
    /*
    for(child in this.children){
      if(child.is(IFlumpDisplayObject)){
        var displayObject:IFlumpDisplayObject = cast child;
        displayObject.alpha = value;
      }
    }
    */
    return alpha = value;
  }

}
