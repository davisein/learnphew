express = require 'express'
derby = require 'derby'
racerBrowserChannel = require 'racer-browserchannel'
liveDbMongo = require 'livedb-mongo'
mongoskin = require 'mongoskin' 
coffeeify = require 'coffeeify'
MongoStore = require('connect-mongo')(express)
app = require '../app/index.coffee'
error = require './error.coffee'
#conf = require 'nconf'
#conf.env().argv().file('devel.json')

expressApp = module.exports = express()

# Get Redis configuration
if process.env.REDIS_HOST
  redis = require('redis').createClient process.env.REDIS_PORT, process.env.REDIS_HOST
  redis.auth process.env.REDIS_PASSWORD
else if process.env.REDISCLOUD_URL
  redisUrl = require('url').parse process.env.REDISCLOUD_URL
  redis = require('redis').createClient redisUrl.port, redisUrl.hostname
  redis.auth redisUrl.auth.split(":")[1]
else
  redis = require('redis').createClient()
redis.select process.env.REDIS_DB || 1
# Get Mongo configuration 
mongoUrl = process.env.MONGO_URL || process.env.MONGOHQ_URL ||
  'mongodb://localhost:27017/project'
mongo = mongoskin.db "#{mongoUrl}?auto_reconnect=true", {safe: true}

# The store creates models and syncs data
store = derby.createStore
  db: liveDbMongo(mongo)
  redis: redis

store.on 'bundle', (browserify) ->
  # Add support for directly requiring coffeescript in browserify bundles
  browserify.transform coffeeify

### Auth support
(1)
Setup a hash of strategies you'll use - strategy objects and their configurations
Note, API keys should be stored as environment variables (eg, process.env.FACEBOOK_KEY) or you can use nconf to store
them in config.json, which we're doing here
###
auth = require("derby-auth") # change to `require('derby-auth')` in your project
strategies =
  facebook:
    strategy: require("passport-facebook").Strategy
    conf:
      clientID: process.env.FACEBOOK_API_ID || 'YOUR_ID'
      clientSecret: process.env.FACEBOOK_API_SECRET || 'YOUR_SECRET'

  #linkedin:
    #strategy: require("passport-linkedin").Strategy
    #conf:
      #consumerKey: conf.get('linkedin:apiKey')
      #consumerSecret: conf.get('linkedin:apiSecret')

  #github:
    #strategy: require("passport-github").Strategy
    #conf:
      #clientID: conf.get('github:appId')
      #clientSecret: conf.get('github:appSecret')
      ## You can optionally pass in per-strategy configuration options (consult Passport documentation)
      #callbackURL: "http://127.0.0.1:3000/auth/github/callback"

  #twitter:
    #strategy: require("passport-twitter").Strategy
    #conf:
      #consumerKey: conf.get('twit:consumerKey')
      #consumerSecret: conf.get('twit:consumerSecret')
      #callbackURL: "http://127.0.0.1:3000/auth/twitter/callback"

###
(1.5)
Optional parameters passed into auth.middleware(). Most of these will get sane defaults, so it's not entirely necessary
to pass in this object - but I want to show you here to give you a feel. @see derby-auth/middeware.coffee for options
###
options =
  passport:
    failureRedirect: '/'
    successRedirect: '/'
    #usernameField: 'email'
  site:
    domain: 'http://localhost:3000'
    name: 'My Site'
    email: 'admin@mysite.com'
  smtp:
    service: 'Gmail'
    user: 'admin@mysite.com'
    pass: 'abc'

###
(2)
Initialize the store. This will add utility accessControl functions (see store.coffee for more details), as well
as the basic specific accessControl for the `auth` collection, which you can use as boilerplate for your own `users`
collection or what have you.
###
auth.store(store, mongo, strategies)


createUserId = (req, res, next) ->
  model = req.getModel()
  userId = req.session.userId ||= model.id()
  model.set '_session.userId', userId
  next()

expressApp
  .use(express.favicon())
  # Gzip dynamically
  .use(express.compress())
  # Respond to requests for application script bundles
  .use(app.scripts store)
  # Serve static files from the public directory
  .use(express.static __dirname + '/../../public')

  # Add browserchannel client-side scripts to model bundles created by store,
  # and return middleware for responding to remote client messages
  .use(racerBrowserChannel store)
  # Add req.getModel() method
  .use(store.modelMiddleware())

  # Parse form data
   .use(express.bodyParser())
   .use(express.methodOverride())

  # Session middleware
  .use(express.cookieParser())
  .use(express.session
    secret: process.env.SESSION_SECRET || 'YOUR SECRET HERE'
    store: new MongoStore(url: mongoUrl, safe: true)
  )
  .use(createUserId)
  # (3)
  # derbyAuth.middleware is inserted after modelMiddleware and before the app router to pass server accessible data to a model
  # Pass in {store} (sets up accessControl & queries), {strategies} (see above), and options
  .use(auth.middleware(strategies, options))
  # Create an express middleware from the app's routes
  .use(app.router())
  .use(expressApp.router)
  .use(error())


# SERVER-SIDE ROUTES #

expressApp.all '*', (req, res, next) ->
  next '404: ' + req.url
