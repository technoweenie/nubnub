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

# Represents a single PubSubHubbub (PuSH) subscriber.  It is able to subscribe
# to topics on a hub and verify the subscription intent.
class Subscriber
  constructor: (options) ->
    Subscriber.allowed_keys.forEach (key) =>
      value  = options[key]
      @[key] = value if value?
    @verify      ||= 'sync'

  # Public: Subscribes to a topic on a given hub.
  #
  # cb - A Function callback.
  #      err  - An optional error object.
  #      resp - A http.ClientResponse instance.
  #
  # Returns nothing.
  subscribe: (cb) ->
    @post_to_hub 'subscribe', cb
    @

  # Public: Unsubscribes from a topic on a given hub.
  #
  # cb - A Function callback.
  #      err  - An optional error object.
  #      resp - A http.ClientResponse instance.
  #
  # Returns nothing.
  unsubscribe: (cb) ->
    @post_to_hub 'unsubscribe', cb
    @

  # Public: Checks if the given signature is a valid HMAC hash using the set
  # @secret property on this Subscriber.
  #
  # sig    - String signature to verify.
  # data   - The request data that the signature was created with.
  #
  # Returns a Boolean specifying whether the signature is valid.
  is_valid_signature: (sig, body) ->
    exports.is_valid_signature sig, @secret, body

  # Creates a POST request to a PuSH hub.
  #
  # mode - The String hub.mode value: "subscribe" or "unsubscribe".
  # cb   - A Function callback.
  #        err  - An optional error object.
  #        resp - A http.ClientResponse instance.
  #
  # Returns nothing.
  post_to_hub: (mode, cb) ->
    params = @build_hub_params(mode)
    data   = Query.stringify params
    ScopedClient.create(@hub).
      header("content-type", "application/x-www-form-urlencoded").
      post(data) cb

  # Assembles a Hash of params that get passed to a Hub as POST data.
  #
  # mode - The String hub.mode value: "subscribe" or "unsubscribe"
  #
  # Returns an Object with hub.* keys.
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

Subscriber.allowed_keys  = [
    'callback', 'topic', 'verify', 'hub'
    'lease_seconds', 'secret', 'verify_token'
  ]

# Public: Assembles a new Subscriber instance.
#
# options - A property Object.
#
# Returns a Subscriber instance.
exports.build = (options) ->
  new Subscriber options