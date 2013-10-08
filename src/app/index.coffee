app = require('derby').createApp(module)
  .use(require 'derby-ui-boot')
  .use(require '../../ui/index.coffee')

# ROUTES #

# Derby routes are rendered on the client and the server
app.get '/', (page) ->
  page.render 'home'

app.get '/list', (page, model, params, next) ->
  # This value is set on the server in the `createUserId` middleware
  userId = model.get '_session.userId'

  # Create a scoped model, which sets the base path for all model methods
  user = model.at 'users.' + userId

  # Create a mongo query that gets the current user's items
  itemsQuery = model.query 'items', {userId}

  # Get the inital data and subscribe to any updates
  model.subscribe user, itemsQuery, (err) ->
    return next err if err

    # Create references that can be used in templates or controller methods
    model.ref '_page.user', user
    itemsQuery.ref '_page.items'

    user.increment 'visits'
    page.render 'list'

app.get '/editor', (page, model) ->
  page.render 'editor'
app.ready  (model) ->
  model.subscribe "code", ->
  window.editor = CodeMirror.fromTextArea document.getElementById "code",
    mode: "coffeescript"
    styleActiveLine: true
    lineNumbers: true
    lineWrapping: true
    height: "600px"
  #model.set '_page.editor', window.editor
  window.editor.setSize "800px", "600px"
  window.editor.on "change", (instance, chang) ->
    #model.stringRemove "code.now.code", chang.from, chang.to
    #model.stringInsert "code.now.code", chang.from, chang.text
    #console.log model.get()
    model.set "code.now.code", window.editor.getValue()
  model.on "change", "code.now.code", (captures, value) ->
    window.editor.setValue captures if captures isnt window.editor.getValue()

# CONTROLLER FUNCTIONS #

app.fn 'list.add', (e, el) ->
  newItem = @model.del '_page.newItem'
  return unless newItem
  newItem.userId = @model.get '_session.userId'
  @model.add 'items', newItem

app.fn 'list.remove', (e) ->
  item = e.get ':item'
  @model.del 'items.' + item.id

app.fn 'editor.run', (model)->
  app.onrun = !app.onrun
  if app.onrun then app.setupnrun() else app.stop()

app.setupnrun = (model)->
  $("#runbutton").removeClass "glyphicon-play-circle"
  $("#runbutton").addClass "glyphicon-stop"
  $(".canv").css "opacity", "1"
  $(".canv").css "z-index", "1"
  $("#ide").css "opacity", "0.5"
  roo1 = muu.addCanvas "canvas1", false
  roo2 = muu.addCanvas "canvas2", true
  mask = app.boilerplate()
  muu.addAtlas "img/balls.png", "img/balls.json"
  muu.addAtlas "img/platformer-character.png", "img/platformer-character.json"
  muu.addAtlas "img/platformer-hud.png", "img/platformer-hud.json"
  muu.addAtlas "img/platformer-items.png", "img/platformer-items.json"
  muu.addAtlas "img/platformer-tiles.png", "img/platformer-tiles.json"
  muu.addAtlas "img/puzzle.png", "img/puzzle.json"

  app.stopp = false
  render = (t)->
    if !app.stopp
      if app.first
        app.lt = t
        app.first = false
      mask.render t-app.lt
      muu.render()
      requestAnimationFrame render

  muu.whenReady ->
    mask = app.boilerplate()
    mask.roo1 = roo1
    mask.roo2 = roo2

    code = "with(this){"
    code += CoffeeScript.compile editor.getValue(), bare: true
    code += "}"
    (new Function code).call mask
    app.first = true
    requestAnimationFrame render

app.stop = (model)->
  muu.cleanAll()
  app.stopp = true
  $("#runbutton").removeClass "glyphicon-stop"
  $("#runbutton").addClass "glyphicon-play-circle"
  $(".canv").css "opacity", "0.5"
  $(".canv").css "z-index", "0"
  $("#ide").css "opacity", "1"

app.boilerplate = ->
  mask =
    rand: (start, end) ->
      if end?
        return start + Math.random()*(end-start)
      else if start?
        return Math.random()*start
      else
        return Math.random()
    randInt: (start, end) ->
      return Math.round @rand start, end
    arrow: (end, color) ->
      line = new Polygon [new v2, end]
      triangle = new Polygon [
        new v2(10,0), new v2(0,10), new v2(-10,0)
      ]
      triangle.moveTo end
      triangle.rotation -.5*Math.PI + Math.atan2 end.y, end.x
      line.stroke color
      triangle.fill color
      triangle.stroke "rgba(0,0,0,0)"
      arr = new Layer().add(line).add triangle
      mask.roo2.add arr
      arr.to = (end) ->
        mask.roo2.rem arr
        a = mask.arrow end, color
        a
      arr
    p1: new Actor
      def:
        sprite0: muu.getSprite('p1_stand')
        len: 1
        dt: 50
      walk:
        sprite0: muu.getSprite('p1_walk01')
        sprite1: muu.getSprite('p1_walk02')
        sprite2: muu.getSprite('p1_walk03')
        sprite3: muu.getSprite('p1_walk04')
        sprite4: muu.getSprite('p1_walk05')
        sprite5: muu.getSprite('p1_walk06')
        sprite6: muu.getSprite('p1_walk07')
        sprite7: muu.getSprite('p1_walk08')
        sprite8: muu.getSprite('p1_walk09')
        sprite9: muu.getSprite('p1_walk10')
        sprite10: muu.getSprite('p1_walk11')
        len: 10
        dt: 50
      jump:
        sprite0:muu.getSprite('p1_jump')
        len: 1
        dt: 50
      hurt:
        sprite0:muu.getSprite('p1_hurt')
        len: 1
        dt: 50
      duck:
        sprite0:muu.getSprite('p1_duck')
        len:1
        dt: 50
      front:
        sprite0: muu.getSprite('p1_front')
        len: 1
        dt: 50
    p2: new Actor
      def:
        sprite0: muu.getSprite('p2_stand')
        len: 1
        dt: 50
      walk:
        sprite0: muu.getSprite('p2_walk01')
        sprite1: muu.getSprite('p2_walk02')
        sprite2: muu.getSprite('p2_walk03')
        sprite3: muu.getSprite('p2_walk04')
        sprite4: muu.getSprite('p2_walk05')
        sprite5: muu.getSprite('p2_walk06')
        sprite6: muu.getSprite('p2_walk07')
        sprite7: muu.getSprite('p2_walk08')
        sprite8: muu.getSprite('p2_walk09')
        sprite9: muu.getSprite('p2_walk10')
        sprite10: muu.getSprite('p2_walk11')
        len: 10
        dt: 50
      jump:
        sprite0:muu.getSprite('p2_jump')
        len: 1
        dt: 50
      hurt:
        sprite0:muu.getSprite('p2_hurt')
        len: 1
        dt: 50
      duck:
        sprite0:muu.getSprite('p2_duck')
        len:1
        dt: 50
      front:
        sprite0: muu.getSprite('p2_front')
        len: 1
        dt: 50

    p3: new Actor
      def:
        sprite0: muu.getSprite('p3_stand')
        len: 1
        dt: 50
      walk:
        sprite0: muu.getSprite('p3_walk01')
        sprite1: muu.getSprite('p3_walk02')
        sprite2: muu.getSprite('p3_walk03')
        sprite3: muu.getSprite('p3_walk04')
        sprite4: muu.getSprite('p3_walk05')
        sprite5: muu.getSprite('p3_walk06')
        sprite6: muu.getSprite('p3_walk07')
        sprite7: muu.getSprite('p3_walk08')
        sprite8: muu.getSprite('p3_walk09')
        sprite9: muu.getSprite('p3_walk10')
        sprite10: muu.getSprite('p3_walk11')
        len: 10
        dt: 50
      jump:
        sprite0:muu.getSprite('p3_jump')
        len: 1
        dt: 50
      hurt:
        sprite0:muu.getSprite('p3_hurt')
        len: 1
        dt: 50
      duck:
        sprite0:muu.getSprite('p3_duck')
        len:1
        dt: 50
      front:
        sprite0: muu.getSprite('p3_front')
        len: 1
        dt: 50

