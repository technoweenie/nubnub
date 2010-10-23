# This is the client endpoint that receives requests from hub servers from
# around the world.  This needs to be running on a public server on one of
# these ports: 
# 8084,8085,8086,8087,8080,8081,8082,8083,443,8990,8088,8089,8444,4443,80,8188
# Pass the URL as the callback option in client.coffee

http   = require 'http'
Url    = require 'url'
Events = require('events').EventEmitter
events = new Events
port   = 4012

server = http.createServer (req, resp) ->
  body    = ''
  req.on 'data', (chunk) -> body += chunk
  req.on 'end', ->
    # receiving verification challenge from the hub
    if req.method == 'GET'
      resp.writeHead 200
      resp.write Url.parse(req.url, true).query.hub.challenge
    # receiving push from the hub
    else
      resp.writeHead 200
      events.emit 'publish', req.headers['content-type'], body
    resp.end()

server.listen port, ->
  console.log "Listening on port #{port}"

events.on 'publish', (contentType, data) ->
  console.log "Received #{contentType} (#{data.length})"
  # do something when data is pushed