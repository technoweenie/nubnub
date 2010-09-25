Query = require 'querystring'
Url   = require 'url'

class Subscription
  constructor: (data) ->
    Subscription.allowed_keys.forEach (key) =>
      value  = data.hub[key]
      @[key] = value if value?
    @lease_seconds = parseInt(@lease_seconds) || 0
    @bad_params    = []

  is_valid: ->
    @bad_params = {}
    @check_required_keys()
    @check_hub_mode()
    @check_urls 'topic'
    @check_urls 'callback'
    @bad_params = for key of @bad_params
      key
    @bad_params.length == 0

  is_verified: ->
    false

  check_required_keys: ->
    Subscription.required_keys.forEach (key) =>
      if !@[key]?
        @bad_params["hub.#{key}"] = true

  check_hub_mode: ->
    if Subscription.valid_modes.indexOf(@mode) < 0
      @bad_params["hub.mode"] = true

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

exports.Subscription = Subscription

exports.build = (data) ->
  new exports.Subscription data

exports.subscribe = (post_data) ->
  data = Query.parse post_data
  exports.build data