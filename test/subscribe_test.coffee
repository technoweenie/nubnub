assert = require 'assert'
query  = require 'querystring'
nub    = require '../src/server'

req = 
  'hub.callback': 'http://server.com/foo'
  'hub.mode':     'subscribe'
  'hub.topic':    'http://server.com/foo'
  'hub.verify':   'sync'

sub = nub.subscribe(query.stringify(req))

# check valid request
assert.equal 'http://server.com/foo', sub.callback
assert.equal 'subscribe',             sub.mode
assert.equal 'http://server.com/foo', sub.topic
assert.equal 'sync',                  sub.verify
assert.equal 0,                       sub.lease_seconds
assert.equal undefined,               sub.secret
assert.equal undefined,               sub.verify_token
assert.equal true,                    sub.is_valid()

# check lease_seconds
req['hub.lease_seconds'] = '55'
sub = nub.subscribe(query.stringify(req))
assert.equal 55,   sub.lease_seconds
assert.equal true, sub.is_valid()

# missing required value
req = 
  'hub.callback': 'http://server.com/foo'
  #'hub.mode':     'subscribe'
  'hub.topic':    'http://server.com/foo'
  'hub.verify':   'sync'
sub = nub.subscribe(query.stringify(req))
assert.equal false, sub.is_valid()
assert.deepEqual ['hub.mode'], sub.bad_params

# check invalid mode
req['hub.mode'] = 'foo'
sub = nub.subscribe(query.stringify(req))
assert.equal false, sub.is_valid()
assert.deepEqual ['hub.mode'], sub.bad_params

# check invalid callback and topic urls
req['hub.mode'] = 'unsubscribe'
['callback', 'topic'].forEach (key) ->
  req["hub.#{key}"] = 'foo'
  sub = nub.subscribe(query.stringify(req))
  assert.equal false, sub.is_valid()
  assert.equal true,  sub.bad_params.indexOf("hub.#{key}") > -1

# refresh validation
sub.callback = sub.topic = 'http://server.com/foo'
assert.equal false, sub.is_valid()
assert.equal true,  sub.is_valid('refresh')

console.log 'done'