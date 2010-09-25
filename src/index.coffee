Query = require 'querystring'
Url   = require 'url'

# Represents a single PubSubHubbub (PSHb) subscription.  It is able to verify
# subscription requests and publish new content to subscribers.
class Subscription
  constructor: (data) ->
    Subscription.allowed_keys.forEach (key) =>
      value  = data.hub[key]
      @[key] = value if value?
    @lease_seconds = parseInt(@lease_seconds) || 0
    @bad_params    = null

  # Public: Checks whether this Subscription is valid according to the PSHb 
  # spec.  If the Subscription is invalid, check @bad_params for an Array of
  # bad hub parameters.
  #
  # refresh - Optional truthy value that that determines whether to reset 
  #           @bad_params and re-check validation.  Default: true.
  #
  # Returns true if the Subscription is valid, or false.
  is_valid: (refresh) ->
    if !@bad_params || refresh
      @bad_params = {}
      @check_required_keys()
      @check_hub_mode()
      @check_urls 'topic'
      @check_urls 'callback'
      @bad_params = for key of @bad_params
        key
    @bad_params.length == 0

  # Public: Checks whether this Subscription has been verified by the
  # subscriber.
  #
  # Returns true or false.
  is_verified: ->
    false

  # Checks whether this Subscription has the required fields for PSHb set.
  #
  # Returns nothing.
  check_required_keys: ->
    Subscription.required_keys.forEach (key) =>
      if !@[key]?
        @bad_params["hub.#{key}"] = true

  # Checks whether this Subscription specified a valid hub request mode.
  #
  # Returns nothing.
  check_hub_mode: ->
    if Subscription.valid_modes.indexOf(@mode) < 0
      @bad_params["hub.mode"] = true

  # Checks whether the callback and topic parameters are valid URLs.
  #
  # Returns nothing.
  check_urls: (key) ->
    if value = @[key]
      url = Url.parse value
      if !(url.hostname? && url.protocol? && url.protocol.match(/^https?:$/i))
        @bad_params["hub.#{key}"] = true
    else
      @bad_params["hub.#{key}"] = true

Subscription.valid_proto   = /^https?:$/
Subscription.valid_modes   = ['subscribe', 'unsubscribe']
Subscription.required_keys = ['callback', 'mode', 'topic', 'verify']
Subscription.allowed_keys  = [
    'callback', 'mode', 'topic', 'verify'
    'lease_seconds', 'secret', 'verify_token'
  ]

# Public: Points to a Subscription object.  You can change this if you want 
# to subclass Subscription with custom logic.
exports.Subscription = Subscription

# Public: Assembles a new Subscription instance.
#
# data - A parsed QueryString object.
#
# Returns a Subscription instance.
exports.build = (data) ->
  new exports.Subscription data

# Public: Handles a PSHb subscription request.
#
# post_data - A raw String of the POST data.
#
# Returns a Subscription instance.
exports.subscribe = (post_data) ->
  data = Query.parse post_data
  exports.build data