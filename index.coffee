path = require 'path'
fs = require 'fs'
_ = require 'underscore'
es = require 'event-stream'
semver = require 'semver'

gulp = require 'gulp'
File = require('gulp-util').File

extractAMDOptions = (options) ->
  path_files = options.path_files or []
  shims = options.shims or {}
  aliases = options.aliases or {}
  amd_options = {paths: {}, shim:{}}

  for file in path_files
    name = file.split('/').pop()
    name = name.replace('.js', '').replace('.min', '').replace('-min', '')
    name = name.split('-').slice(0, -1).join('-') if semver.valid(name.split('-').slice(-1)[0]) # remove semver
    name = aliases[name] if aliases.hasOwnProperty(name)
    name = options.name(name) if options.name
    amd_options.paths[name] = path.join(options.base or '/base', file.replace('.js', ''))

  amd_options.shim[key] = value for key, value of shims when amd_options.paths.hasOwnProperty(key)
  return amd_options

toText = (callback) ->
  text = ''
  es.through ((data) => text += data), (-> callback(text))

# TODO: report errors for missing options like files
module.exports = (options={}) ->
  es.map((file, callback) ->
    amd_options = extractAMDOptions(options)
    params = (key.replace(/-/g, '_') for key in _.keys(amd_options.paths))

    es.readArray([file])
      .pipe es.map (file, wrap_callback) ->
        file.pipe toText (text) ->

          contents = """
            (function() {
              #{'var _start = window.__karma__.start, _config; window.__karma__.start = function(config) { _config = config; };' if options.karma}

              require.config(#{JSON.stringify(amd_options,null,2)});

              require(#{JSON.stringify(_.keys(amd_options.paths))}, function(#{params.join(', ')}){
                #{options.post_load or ''}
                #{text}

                #{'_start(_config);' if options.karma}
              });
            }).call(this);
          """

          wrap_callback(); callback(null, new File(_.extend(_.pick(file, 'cwd', 'base', 'path'), {contents: new Buffer(contents)})))
      )
