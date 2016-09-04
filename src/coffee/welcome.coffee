$ = jQuery     = require "./js/jquery.min"
electron       = require 'electron'
app            = electron.remote.app
BrowserWindow  = electron.remote.BrowserWindow
fs             = require 'fs'
userDataPath   = app.getPath "userData"
path           = require "path"
configFile     = path.join userDataPath, "config.json"
currentPage    = -1
$scroll        = $ "html, body"
$sections      = $ "section"
$nextButton    = $ "[name='next']"
$backButton    = $ "[name='back']"
$submitButton  = $ "[type='submit']"
vw             = window.innerWidth

configs = [
  {description: "名前（ペンネーム）", type: "text"}

  {description: "小説のフォルダ", type: "text"}

  {description: "テーマ", type: "select"}

  {description: "文字色" , type: "color"}
  
  {description: "背景色" , type: "color"}
]

movePage = (page)->
  currentPage = page
  page++
  if 1 >= page
    $backButton.addClass "hide"
  else
    $backButton.removeClass "hide"

  if page >= 3
    $nextButton.addClass "hide"
    $submitButton.removeClass "hide"
  else
    $nextButton.removeClass "hide"
    $submitButton.addClass "hide"

  $scroll.animate
    scrollLeft: page * vw,
    400,
    "swing"

$("#start-setting").on "click", ->
  movePage 0
  $("#move").css display: "block"

$nextButton.on "click", -> movePage currentPage + 1
$backButton.on "click", -> movePage currentPage - 1

$("form").on "submit", ->
  for config, i in do $ this
  .serializeArray
    $.extend configs[i], config
  fs.writeFileSync configFile, JSON.stringify(configs)
  $scroll.animate
    scrollLeft: 5 * vw,
    400,
    "swing"
  false
