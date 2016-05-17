wl.commands =
  open_novel: ->
    wl.novel.open()
  open_chapter: ->
    wl.novel.chapter.open()
  command_palette: ->
    wl.command.palette()
  add_chapter: ->
    wl.novel.chapter.add()
  editmode_def: ->
    wl.editor.mode.defaultMode()
  editmode_int: ->
    wl.editor.mode.IntensiveMode()
  toggle_editmode: ->
    wl.editor.mode.toggleIntensiveMode()
  toggle_devtools: ->
    browserWindow.getFocusedWindow().toggleDevTools()
  reload_window: ->
    browserWindow.getFocusedWindow().reload()
  toggle_direction: ->
    wl.editor.direction.toggle()
