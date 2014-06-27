gulp-wrap-amd-infer
==================

Gulp plugin to automatically wrap and optionally compile files for testing AMD

```
gulp = require 'gulp'
wrapAMD = require 'gulp-wrap-amd-infer'

SHIMS =
  underscore: {exports: '_'}
  backbone: {exports: 'Backbone', deps: ['underscore']}

gulp.task 'build', ->
  gulp.src('test/some_test.coffee')
    .pipe(wrapAMD({
      files: ['./node_modules/jquery/jquery.js', './node_modules/underscore/underscore.js', './node_modules/backbone/backbone.js']
      shims: SHIMS
      karma: true
    ))
    .pipe(gulp.dest('test/build'))
```

Output:

```
(function() {
  var _start = window.__karma__.start, _config; window.__karma__.start = function(config) { _config = config; };

  require.config({
  "paths": {
    "jquery": "/base/node_modules/jquery/jquery",
    "underscore": "/node_modules/underscore/underscore",
    "backbone": "/node_modules/backbone/backbone"
  },
  "shim": {
    "underscore": {
      "exports": "_"
    },
    "backbone": {
      "exports": "Backbone",
      "deps": [
        "underscore"
      ]
    }
  }
});

  require(["jquery","underscore","backbone"], function(){
    // test/some_test.coffee compiled to JavaScript

    _start(_config);
  });
}).call(this);
```