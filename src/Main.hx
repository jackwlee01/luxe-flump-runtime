
import luxe.Input;
import luxe.Sprite;
import luxe.Text;
import luxe.Vector;
import luxe.Color;

import flump.*;


class Main extends luxe.Game{


  override function config( config:luxe.GameConfig ) {
      config.window.width = 479;
      config.window.height = 280;
      return config;
  }


  override function ready(){
    new FPS({});

    // Example 1
    flump.FlumpLibraryResource
      .load("assets/flump/monster/", 1)
      .then(function(resource:FlumpLibraryResource){
        var anim:FlumpMovie = new FlumpMovie({
          name: "walk"
        });
        anim.pos.x = Luxe.screen.w/2;
        anim.pos.y = 75 + Luxe.screen.h/2;
      });

    // Example 2
    /*
    flump.FlumpLibraryResource
      .load("assets/flump/dog/", 1)
      .then(function(resource:FlumpLibraryResource){
        var anim:FlumpMovie = new FlumpMovie({
          name: "TestScene"
        });
      });
    */




  }


}
