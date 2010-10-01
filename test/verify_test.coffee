assert = require 'assert'
http   = require 'http'
url    = require 'url'
query  = require 'querystring'
nub    = require '../src/server'

port   = 9999
server = http.createServer (req, resp) ->
  req_url = url.parse req.url, true

  switch req_url.query.testing
    when 'yes'
      resp.writeHead 200
      resp.write req_url.query.hub.challenge
    when 'no'
      resp.writeHead 300
      resp.write req_url.query.hub.challenge
    when 'challenge'
      resp.writeHead 200
      resp.write 'nada'
  
  resp.end()

req = 
  'hub.callback':      'http://localhost:9999'
  'hub.mode':          'subscribe'
  'hub.topic':         'http://server.com/foo'
  'hub.verify':        'sync'
  'hub.lease_seconds': '1000'
sub = nub.subscribe(query.stringify(req))

client = sub.verify_client()
params = client.options.query

assert.equal req['hub.mode'],          params['hub.mode']
assert.equal req['hub.topic'],         params['hub.topic']
assert.equal req['hub.lease_seconds'], params['hub.lease_seconds']
assert.ok params['hub.challenge']
assert.equal null, params['hub.verify_token']
challenge = params['hub.challenge']

# test params with custom verify_token value
sub.verify_token = 'abc'
params2 = sub.verify_client().options.query
assert.equal 'abc', params2['hub.verify_token']
assert.notEqual challenge, params2['hub.challenge']

# test assembled url
assert.ok client.fullPath().match(/\?hub\./)

# test assembled url with existing url params
sub.callback += '?testing=yes'
assert.ok sub.verify_client().fullPath().match(/\?testing=yes&hub\./)

server.listen port

sub.check_verification (err, resp) ->
  assert.equal null, err
  assert.equal 200,  resp.statusCode

  sub.callback = 'http://localhost:9999?testing=no'
  sub.check_verification (err, resp) ->
    assert.ok err.error?
    assert.equal 300,  resp.statusCode

    sub.callback = 'http://localhost:9999?testing=challenge'
    sub.check_verification (err, resp) ->
      assert.ok err.error?
      assert.equal 200,  resp.statusCode

      server.close()
      console.log 'done'