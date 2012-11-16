Reads direct messages from Twitter, and publishes as tweets using the config template.

Uses mongo to persist the last DM id (because I couldn't find another way to persist that on Heroku)

# Settings
Read from environment variables. The following settings are used:

- INTERVAL - Intervals between pooling DM from Twitter (seconds). Defaults to 600
- TEMPLATE - Tweet message template, to build the tweet message from the DM. Defaults to "@{user}: {text}"
- TWITTER_CONSUMER_KEY, TWITTER_CONSUMER_SECRET, TWITTER_ACCESS_TOKEN, TWITTER_ACCESS_SECRET - For twitter authentication
- MONGO_URI - The mongo server to connect to in URI format (mongo://user:pass@host/db). If not supplied, the last id is not persisted.

# Setup
- Create an app on twitter with the "Read, write, and direct messages" access level
- git clone git://github.com/shesek/openhack-twitter-notify.git && cd openhack-twitter-notify
- local setup (assuming node and npm are installed):
  - npm install
  - Set environment variables
  - ./node_modules/.bin/coffee index.coffee

- Heroku setup:
  - heroku create
  - heroku addons:add mongolab
  - heroku config:set MONGO_URI=`heroku config:get MONGOLAB_URI`
  - Set settings with: heroku config:set NAME=VAL
  - git push heroku
  - heroku ps:scale worker=1 # enable the worker dyno (not enabled by default). since no web is configured in Procfile, the free dyno will be used
