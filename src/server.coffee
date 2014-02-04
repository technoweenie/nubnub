Query        = require 'querystring'
Url          = require 'url'
Crypto       = require 'crypto'
ScopedClient = require '../vendor/scoped-http-client/lib'

# Represents a single PubSubHubbub (PuSH) subscription.  It is able to verify
# subscription requests and publish new content to subscribers.
class Subscription
  constructor: (data) ->
    Subscription.allowed_keys.forEach (key) =>
      value  = data["hub."+key]
      @[key] = value if value?
    @lease_seconds = parseInt(@lease_seconds) || 0
    @bad_params    = null

  # Public: Publishes the given data to the Subscription callback.  If a 
  # format option is given, automatically format the data.
  #
  # data    - Either raw String data, or an Array of items to be formatted.
  # options - Hash of options.
  #           format: Specifies a built-in formatter.
  #           content_type: Specifies a content type for the request.  
  #                         Formatters specify their own content type.
  # cb      - Function callback to be called with (err, resp) when the 
  #           request is complete.
  #
  # Returns nothing.
  publish: (data, options, cb) ->
    format   = Subscription.formatters[options.format]
    data     = format data if format?
    data_len = data.length
    ctype    = format?.content_type || options.content_type
    client   = ScopedClient.create(@callback).
      headers(
        "content-type":    ctype
        "content-length":  data_len.toString()
      )
    if @secret
      hmac   = Crypto.createHmac 'sha1', @secret
      hmac.update data
      client = client.header 'x-hub-signature', hmac.digest('hex')
    client.post(data) (err, resp) =>
      @check_response_for_success err, resp, cb

  # Public: Checks verification of the Subscription by passing a challenge 
  # string and checking for the response.  
  #
  # cb - A Function callback that is called when the request is finished.
  #      err  - An exception object in case there are problems.
  #      resp - The http.ServerResponse instance.
  #
  # Returns nothing.
  check_verification: (cb) ->
    client = @verify_client()
    client.get() (err, resp, body) =>
      if body != client.options.query['hub.challenge']
        cb {error: "bad challenge"}, resp
      else
        @check_response_for_success err, resp, cb

  # Public: Checks whether this Subscription is valid according to the PuSH 
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

  # Creates a ScopedClient instance for making the verification request.
  #
  # Returns a ScopedClient instance.
  verify_client: ->
    client = ScopedClient.create(@callback).
      query(
        'hub.mode':          @mode
        'hub.topic':         @topic
        'hub.lease_seconds': @lease_seconds
        'hub.challenge':     @generate_challenge()
      )
    client.query('hub.verify_token', @verify_token) if @verify_token?
    client

  # Generates a unique challenge string by MD5ing the Subscription details
  # and the current time in milliseconds.
  #
  # Returns a String MD5 hash.
  generate_challenge: ->
    data = "#{@mode}#{@topic}#{@callback}#{@secret}#{@verify_token}#{(new Date()).getTime()}"
    Crypto.createHash('md5').update(data).digest("hex")

  # Checks whether this Subscription has the required fields for PuSH set.
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

  # Checks the given http.ClientResponse for a 200 status.
  #
  # err  - The Error object from an earlier http.Client request.
  # resp - The http.ClientResponse instance from an earlier request.
  # cb   - A Function callback that is called with (err, resp).
  check_response_for_success: (err, resp, cb) ->
    if resp.statusCode.toString().match(/^2\d\d/)
      cb err, resp
    else
      cb {error: "bad status"}, resp

Subscription.formatters    = {}
Subscription.valid_proto   = /^https?:$/
Subscription.valid_modes   = ['subscribe', 'unsubscribe']
Subscription.required_keys = ['callback', 'mode', 'topic', 'verify']
Subscription.allowed_keys  = [
    'callback', 'mode', 'topic', 'verify'
    'lease_seconds', 'secret', 'verify_token'
  ]

Subscription.formatters.json = (items) ->
  JSON.stringify items
Subscription.formatters.json.content_type = 'application/json'

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

# Public: Handles a PuSH subscription request.
#
# post_data - A raw String of the POST data.
#
# Returns a Subscription instance.
exports.subscribe = (post_data) ->
  data = Query.parse post_data
  exports.build data