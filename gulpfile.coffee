module.exports = gulp = require 'gulp'

$           = do require 'gulp-load-plugins'
config      =    require './package.json'
del         =    require 'del'
packager    =    require 'electron-packager'
runSequence =    require 'run-sequence'
Path        =    require 'path'
extend      =    require 'extend'
mkdirp      =    require 'mkdirp'
bower       =    require 'main-bower-files'
electron    = do require 'electron-connect'
  .server.create

isMainJSEdited = yes
isFirstComplie = yes

packageOpts =
  asar: true
  dir: 'dist'
  out: 'packages'
  name: config.name
  version: config.dependencies['electron-prebuilt']
  prune: true
  overwrite: true
  'app-version': config.version
  'version-string':
    ProductName: config.name
    InternalName: config.name
    FileDescription: config.name
    CompanyName: 'Shibafu'
    LegalCopyright: ''
    OriginalFilename: "#{config.name}.exe"

packageElectron = (opts = {}, done) ->
  packager extend(packageOpts, opts), (err) ->
    if err
      if err.syscall == 'spawn wine'
        $.util.log 'Packaging failed. Please install wine.'
      else
        throw err

    done() if done?

globFolders = (pattern, func, callback) ->
  doneTasks = 0
  g = new (require("glob").Glob) pattern, (err, pathes) ->
    throw err if err
    done = ->
      doneTasks++
      callback() if callback? and doneTasks >= pathes.length

    if pathes.length > 0
      func(path, done) for path in pathes
    else
      callback()

gulp.task 'clean', ['clean:js', 'clean:css', 'clean:dist', 'clean:packages']
gulp.task 'clean:js', -> del ['js/**/*', 'js']
gulp.task 'clean:css', -> del ['css/**/*', 'css']
gulp.task 'clean:dist', -> del ['dist/**/*', 'dist']
gulp.task 'clean:packages', -> del ['packages/**/*', 'packages']
gulp.task 'clean:releases', -> del ['releases/**/*', 'releases']

gulp.task 'compile', ['compile:coffee', 'compile:scss']
gulp.task 'compile:production', ['compile:coffee:production', 'compile:scss:production']

gulp.task 'compile:coffee', ->
  target = if isFirstCompile
    "src/coffee/**/*.coffee"
  else if isMainJSEdied
    "src/coffee/main.coffee"
  else
    ["src/coffee/**/*.coffee", "!src/coffee/main.coffee"]

  isFirstCompile = no

  gulp.src target
    .pipe $.plumber()
    .pipe $.coffee
      bare: true
    .pipe gulp.dest('js')

gulp.task 'compile:scss', ->
  gulp.src 'src/scss/**/*.scss'
    .pipe $.plumber()
    .pipe $.sourcemaps.init()
    .pipe $.sass()
    .pipe $.sourcemaps.write()
    .pipe gulp.dest('css')

gulp.task 'compile:coffee:production', ['clean:js'], ->
  gulp.src 'src/coffee/**/*.coffee'
    .pipe $.coffee
      bare: true
    .pipe $.uglify()
    .pipe gulp.dest('js')

gulp.task 'compile:scss:production', ['clean:css'], ->
  gulp.src 'src/scss/**/*.scss'
    .pipe $.sass()
    .pipe $.cssnano
      zindex: false
    .pipe gulp.dest('css')

gulp.task 'bower', ['bower:css', 'bower:js']

gulp.task 'bower:css', ->
  cssFilter = $.filter '**/*.css', restore: true
  gulp.src bower paths: bowerJson: 'bower.json'
    .pipe cssFilter
    .pipe $.concat 'bower_components.css'
    .pipe gulp.dest 'css'
    .pipe cssFilter.restore

gulp.task 'bower:js', ->
  jsFilter     = $.filter ['**/*.js', "!**/jquery.js"], restore: true
  jQueryFilter = $.filter '**/jquery.js', restore: true
  gulp.src bower paths: bowerJson: 'bower.json'
    .pipe jsFilter
    .pipe $.uglify preserveComments: 'some'
    .pipe $.concat 'bower_components.js'
    .pipe gulp.dest 'js'
    .pipe jsFilter.restore
    .pipe jQueryFilter
    #.pipe $.uglify preserveComments: 'some'
    .pipe $.rename extname: ".min.js"
    .pipe gulp.dest 'js'
    .pipe jQueryFilter.restore

gulp.task 'dist', ['clean:dist'], ->
  gulp.src([
    'js/**/*'
    'css/**/*'
    'assets/**/*'
    'はじめよう/**/*'
    'extensions/**/*'
    '*.html'
    '*.js'
    '!gulpfile.js'
    'menu.yml'
    '*.json'
  ], { base: '.' })
    .pipe gulp.dest('dist')
    .pipe $.install
      production: true

gulp.task 'package', ['clean:packages', 'dist'], (done) ->
  runSequence 'package:win32', 'package:darwin', 'package:linux', done

gulp.task 'package:win32', (done) ->
  packageElectron {
    platform: 'win32'
    arch: 'ia32,x64'
    icon: Path.join(__dirname, '')
  }, done
gulp.task 'package:linux', (done) ->
  packageElectron {
    platform: 'linux'
    arch: 'ia32,x64'
  }, done
gulp.task 'package:darwin', (done) ->
  packageElectron {
    platform: 'darwin'
    arch: 'x64'
    icon: Path.join(__dirname, '')
  }, ->
    gulp.src ["packages/*-darwin-*/#{config.name}.app/Contents/Info.plist"], { base: '.' }
      .pipe $.plist
        CFBundleDocumentTypes: [
          {
            CFBundleTypeExtensions: ''
            CFBundleTypeIconFile: ''
            CFBundleTypeName: ''
            CFBundleTypeRole: 'Editor'
            LSHandlerRank: 'Owner'
          }
        ]
      .pipe gulp.dest('.')
      .on 'end', done

gulp.task 'build',        (done) -> runSequence 'compile:production', 'bower', 'package', done
gulp.task 'build:win32',  (done) -> runSequence 'compile:production', 'bower', 'dist', 'package:win32', done
gulp.task 'build:linux',  (done) -> runSequence 'compile:production', 'bower', 'dist', 'package:linux', done
gulp.task 'build:darwin', (done) -> runSequence 'compile:production', 'bower' , 'dist', 'package:darwin', done

gulp.task 'archive', ['archive:win32', 'archive:darwin', 'archive:linux']

gulp.task 'archive:win32', (done) ->
  globFolders 'packages/*-win32-*', (path, globDone) ->
    gulp.src ["#{path}/**/*"]
      .pipe $.zip("#{config.version}-#{Path.basename(path, '.*')}.zip")
      .pipe gulp.dest('releases')
      .on 'end', globDone
  , done

gulp.task 'archive:darwin', (done) ->
  appdmg = try
    require('appdmg')
  catch err
    null

  unless appdmg
    $.util.log 'Archiving for darwin is supported only OSX.'
    $.util.log 'In OSX, please install appdmg (`npm install appdmg`)'
    return done()

  globFolders 'packages/*-darwin-*', (path, globDone) ->
    release_to = Path.join(__dirname, "releases/#{config.version}-#{Path.basename(path, '.*')}.dmg")

    mkdirp Path.dirname(release_to), (err) ->
      del(release_to)
        .then ->
          running_appdmg = appdmg {
            target: release_to
            basepath: Path.join(__dirname, path)
            specification:
              title: config.name
              background: Path.join(__dirname, "resources/darwin/dmg-background.png")
              'icon-size': 80
              window: {
                position: { x: 90, y: 90 }
                size: { width: 624, height: 412 }
              }
              contents: [
                { x: 210, y: 300, type: 'file', path: "#{config.name}.app" }
                { x: 410, y: 300, type: 'link', path: '/Applications' }
              ]
          }
          running_appdmg.on 'finish', globDone
  , done

gulp.task 'archive:linux', (done) ->
  globFolders 'packages/*-linux-*', (path, globDone) ->
    gulp.src ["#{path}/**/*"]
      .pipe $.tar("#{config.version}-#{Path.basename(path, '.*')}.tar")
      .pipe $.gzip()
      .pipe gulp.dest('releases')
      .on 'end', globDone
  , done

gulp.task 'release', (done) -> runSequence 'build', 'archive', 'clean', done

gulp.task 'run', ['compile', 'bower'], ->
  do electron.start

  $.watch "./src/coffee/**/*.coffee", -> gulp.start "compile:coffee"
  $.watch "./src/scss/**/*.scss",     -> gulp.start "compile:scss"
  $.watch "./bower.json",             -> gulp.start "bower"

  $.watch ["./css/**/*.css", "./js/**/*.js", "./*.html"], -> do electron.reload
  $.watch "./js/main.js", -> do electron.restart
  @
