assert = require 'assert'
query  = require 'querystring'
nub    = require '../src'

req = 
  'hub.callback': 'cb'
  'hub.mode':     'subscribe'
  'hub.topic':    'http://server.com/foo'
  'hub.verify':   'sync'

sub = nub.subscribe(query.stringify(req))

# check valid request
assert.equal false,                   sub.is_verified()
assert.equal 'cb',                    sub.callback
assert.equal 'subscribe',             sub.mode
assert.equal 'http://server.com/foo', sub.topic
assert.equal 'sync',                  sub.verify
assert.equal 0,                       sub.lease_seconds
assert.equal undefined,               sub.secret
assert.equal undefined,               sub.verify_token
assert.equal true,                    sub.is_valid()

console.log 'done'