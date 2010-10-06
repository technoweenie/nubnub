Crypto       = require 'crypto'
Query        = require 'querystring'
ScopedClient = require '../vendor/scoped-http-client/lib'

# Public: Checks if the given signature is a valid HMAC hash.
#
# sig    - String signature to verify.
# secret - String Hmac secret.
# data   - The request data that the signature was created with.
#
# Returns a Boolean specifying whether the signature is valid.
exports.is_valid_signature = (sig, secret, data) ->
  hmac = Crypto.createHmac 'sha1', secret
  hmac.update data
  hmac.digest('hex') == sig

class Subscription
  constructor: (options) ->
    Subscription.allowed_keys.forEach (key) =>
      value  = options[key]
      @[key] = value if value?
    @verify      ||= 'sync'

  subscribe: (cb) ->
    @post_to_hub 'subscribe', cb
    @

  unsubscribe: (cb) ->
    @post_to_hub 'unsubscribe', cb
    @

  is_valid_signature: (sig, body) ->
    exports.is_valid_signature sig, @secret, body

  post_to_hub: (mode, cb) ->
    params = @build_hub_params(mode)
    data   = Query.stringify params
    ScopedClient.create(@hub).
      header("content-type", "application/x-www-form-urlencoded").
      post(data) cb

  build_hub_params: (mode) ->
    params = 
      'hub.mode':          mode || 'subscribe'
      'hub.topic':         @topic
      'hub.callback':      @callback
      'hub.verify':        @verify
    params['hub.lease_seconds'] = @lease_seconds if @lease_seconds?
    params['hub.secret']        = @secret        if @secret?
    params['hub.verify_token']  = @verify_token  if @verify_token?
    params

Subscription.allowed_keys  = [
    'callback', 'topic', 'verify', 'hub'
    'lease_seconds', 'secret', 'verify_token'
  ]

exports.build = (options) ->
  new Subscription options

exports.create = (hub, topic, callback, options) ->
  options        ||= {}
  options.hub      = hub
  options.topic    = topic
  options.callback = callback
  exports.build options