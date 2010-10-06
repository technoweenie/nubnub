http   = require 'http'
Url    = require 'url'
nub    = require '../src'

debugging = process.env.DEBUG

port   = 4011
subscribers  = {}
server = http.createServer (req, resp) ->
  body    = ''
  req.on 'data', (chunk) -> body += chunk

  req.on 'end', ->
    sub = nub.handleSubscription body
    resp.writeHead 200
    resp.write(' ')
    resp.end()

    console.log "SERVER: Checking verification..." if debugging
    sub.check_verification (err, resp) ->
      if err
        console.log "SERVER: Error with validation:"
        console.log err
        server.close()
        client.close()
      else
        console.log "SERVER: Verification successful.  Publishing..." if debugging
        sub.publish [{abc: 1}], {format: 'json'}, (err, resp) ->
          if err
            console.log "SERVER: Error with publishing:"
            console.log err
          else
            console.log "SERVER: Publishing successful!" if debugging
          server.close()
          client.close()

client = http.createServer (req, resp) ->
  body    = ''
  req.on 'data', (chunk) -> body += chunk

  req.on 'end', ->
    if req.method == 'GET'
      console.log "CLIENT: Receiving verification challenge..." if debugging
      resp.writeHead 200
      resp.write Url.parse(req.url, true).query.hub.challenge
    else
      console.log "CLIENT: Receiving published data..." if debugging
      resp.writeHead 200
      resp.write 'booya'
    resp.end()

client.listen port+1

client_instance = nub.client(
    hub:      "http://localhost:#{port}/hub"
    topic:    "http://server.com/topic"
    callback: "http://localhost:#{port+1}/callback"
  )

server.listen port, ->
  console.log "CLIENT: Sending subscription request..." if debugging
  client_instance.subscribe (err, resp) ->
    if err
      console.log "CLIENT: Error with subscription:"
      console.log err
      server.close()
      client.close()
    else
      console.log "CLIENT: Subscription successful!" if debugging

process.on 'exit', ->
  console.log 'done'