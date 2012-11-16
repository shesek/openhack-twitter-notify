Twit = require 'twit'
mongoose = require 'mongoose'

interval = (process.env.INTERVAL || 600) * 1000
template = process.env.TEMPLATE || "@{user}: {text}"

client = new Twit
  consumer_key: process.env.TWITTER_CONSUMER_KEY
  consumer_secret: process.env.TWITTER_CONSUMER_SECRET
  access_token: process.env.TWITTER_ACCESS_TOKEN
  access_token_secret: process.env.TWITTER_ACCESS_SECRET

since_id = 0

# Twitter handling

get_new_dm = (cb) ->
  client.get 'direct_messages', { since_id, count: 200 }, (err, messages) ->
    return cb err if err?
    update_since_id messages[0].id_str if messages.length
    cb null, messages

publish = (dm, cb) ->
  status = template.replace('{user}', dm.sender_screen_name).replace('{text}', dm.text)
  client.post 'statuses/update', { status }, cb

update_since_id = (id) ->
  since_id = id
  persist 'since_id', id, (err) -> console.warn 'Error updating since_id:', err if err?

pull = ->
  console.log "Looking for new direct messages..."
  get_new_dm (err, messages) ->
    return console.warn 'Error while getting new DMs:', err if err?
    for dm in messages
      console.log "Processing dm ##{dm.id_str} from @#{dm.sender_screen_name}: #{dm.text}"
      publish dm, (err, tweet) ->
        return console.warn 'Error while publishing tweet:', err if err?
        console.log "Published ##{tweet.id_str}: #{tweet.text}"

# MongoDB for for storing persisted values
# Expose the `persist` and `read` functions, keep the rest in the private scope
{ persist, read } = do ->
  unless process.env.MONGO_URI
    # Return mock persist/read that do nothing if no MONGO_URI is not supplied
    # (for local testing)
    return persist: (->), read: (_id, cb) -> cb null, 0

  db = mongoose.createConnection process.env.MONGO_URI
  Store = db.model 'Store', new mongoose.Schema _id: String, value: {}

  persist: (_id, value, cb) -> Store.update { _id }, { value }, { upsert: true }, cb
  read: (_id, cb) -> Store.findById _id, (err, item) -> cb err, item?.value

  # using Mongo to store a single integer value is quite an over-kill,
  # but I couldn't think of a better way to persist that value on Heroku


# Run!
read 'since_id', (err, id) ->
  return console.warn err if err?
  since_id = id || 0
  do pull
  setInterval pull, interval
