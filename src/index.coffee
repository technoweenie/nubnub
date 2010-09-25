query = require 'querystring'

class Subscription
  constructor: (data) ->
    Subscription.allowed_keys.forEach (key) =>
      value  = data.hub[key]
      @[key] = value if value?
    @lease_seconds ||= 0

  is_valid: ->
    valid = true
    Subscription.required_keys.forEach (key) =>
      valid = @[key]? if valid
    valid

  is_verified: ->
    false

Subscription.required_keys = ['callback', 'mode', 'topic', 'verify']
Subscription.allowed_keys  = [
    'callback', 'mode', 'topic', 'verify'
    'lease_seconds', 'secret', 'verify_token'
  ]

exports.Subscription = Subscription

exports.build = (data) ->
  new exports.Subscription data

exports.subscribe = (post_data) ->
  data = query.parse post_data
  exports.build data