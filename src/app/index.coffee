app = require('derby').createApp(module)
  .use(require 'derby-ui-boot')
  .use(require '../../ui/index.coffee')
  .use(require "derby-auth/components/index.coffee")


# ROUTES #

# Derby routes are rendered on the client and the server
app.get '/', (page) ->
  page.render 'home'

app.get '/login', (page, model, params, next) ->
  $user = model.at "auths.#{model.get("_session.userId")}"
  $user.subscribe (err) ->
    throw err if err
    model.ref "_page.user", $user
    page.render 'login'
  #page.render 'login'

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

app.get '/worlds', (page, model, params, next) ->
  # This value is set on the server in the `createUserId` middleware
  userId = model.get '_session.userId'

  # Create a scoped model, which sets the base path for all model methods
  user = model.at 'users.' + userId

  # Create a mongo query that gets the current user's items
  myWorldsQuery = model.query 'world', {userId}
  otherWorldsQuery = model.query 'world', {'*', $limit: 50}

  # Get the inital data and subscribe to any updates
  model.subscribe user, myWorldsQuery, (err) ->
    return next err if err
    model.subscribe user, otherWorldsQuery, (err) ->
        # Create references that can be used in templates or controller methods
        model.ref '_page.user', user
        myWorldsQuery.ref '_page.worlds'
        otherWorldsQuery.ref '_page.other_worlds'
        page.render 'worlds'


app.get '/editor', (page, model) ->
  page.render 'editor'
app.ready  (model) ->
  model.subscribe "code", ->
    console.log model.get()
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
    window.editor.setValue value if value isnt window.editor.getValue()
  console.log model.get()


# CONTROLLER FUNCTIONS #
app.fn 'world.add', (e, el) ->
  newWorld = @model.del '_page.newworld'
  return unless newworld
  newWorld.userId = @model.get '_session.userId'
  @model.add 'items', newWorld

app.fn 'world.remove', (e) ->
  world = e.get ':world'
  @model.del 'world.' + world.id


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
  muu.addAtlas "img/atlas2.png", "img/atlas2.js"
  mask = roo1:roo1, roo2:roo2
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
