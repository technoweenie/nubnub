# This is a minimal script to subscribe to a topic's updates on a remote hub.
# By default, it goes out to the demo hub on http://pubsubhubbub.appspot.com/.

Client = require '../src/client'
cli = Client.build(
  hub:   "http://pubsubhubbub.appspot.com/subscribe" # the hub url
  topic: 'http://pubsubhubbub.appspot.com'           # the feed/topic url
  callback: "path/to/client_app"                      # your running client app
)

console.log "subscribing..."
cli.subscribe (err, resp, body) ->
  if err
    console.log err
  console.log "#{resp.statusCode}: #{body}"