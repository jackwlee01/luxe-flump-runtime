package flump.options;

import flump.FlumpLibrary;


typedef FlumpMovieOptions = {
  var name: String;
  @:optional var master:FlumpMovie;
  @:optional var library:FlumpLibrary;
}
