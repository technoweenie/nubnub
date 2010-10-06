var Crypto, Query, ScopedClient, Subscription, Url;
var __bind = function(func, context) {
    return function(){ return func.apply(context, arguments); };
  }, __hasProp = Object.prototype.hasOwnProperty;
Query = require('querystring');
Url = require('url');
Crypto = require('crypto');
ScopedClient = require('../vendor/scoped-http-client/lib');
Subscription = function(data) {
  Subscription.allowed_keys.forEach(__bind(function(key) {
    var value;
    value = data.hub[key];
    if (typeof value !== "undefined" && value !== null) {
      return (this[key] = value);
    }
  }, this));
  this.lease_seconds = parseInt(this.lease_seconds) || 0;
  this.bad_params = null;
  return this;
};
Subscription.prototype.publish = function(data, options, cb) {
  var client, ctype, data_len, format, hmac;
  format = Subscription.formatters[options.format];
  if (typeof format !== "undefined" && format !== null) {
    data = format(data);
  }
  data_len = data.length;
  ctype = ((typeof format === "undefined" || format === null) ? undefined : format.content_type) || options.content_type;
  client = ScopedClient.create(this.callback).headers({
    "content-type": ctype,
    "content-length": data_len.toString()
  });
  if (this.secret) {
    hmac = Crypto.createHmac('sha1', this.secret);
    hmac.update(data);
    client = client.header('x-hub-signature', hmac.digest('hex'));
  }
  return client.post(data)(__bind(function(err, resp) {
    return this.check_response_for_success(err, resp, cb);
  }, this));
};
Subscription.prototype.check_verification = function(cb) {
  var client;
  client = this.verify_client();
  return client.get()(__bind(function(err, resp, body) {
    return body !== client.options.query['hub.challenge'] ? cb({
      error: "bad challenge"
    }, resp) : this.check_response_for_success(err, resp, cb);
  }, this));
};
Subscription.prototype.is_valid = function(refresh) {
  var _a, _b, _c, key;
  if (!this.bad_params || refresh) {
    this.bad_params = {};
    this.check_required_keys();
    this.check_hub_mode();
    this.check_urls('topic');
    this.check_urls('callback');
    this.bad_params = (function() {
      _b = []; _c = this.bad_params;
      for (key in _c) {
        if (!__hasProp.call(_c, key)) continue;
        _a = _c[key];
        _b.push(key);
      }
      return _b;
    }).call(this);
  }
  return this.bad_params.length === 0;
};
Subscription.prototype.verify_client = function() {
  var _a, client;
  client = ScopedClient.create(this.callback).query({
    'hub.mode': this.mode,
    'hub.topic': this.topic,
    'hub.lease_seconds': this.lease_seconds,
    'hub.challenge': this.generate_challenge()
  });
  if (typeof (_a = this.verify_token) !== "undefined" && _a !== null) {
    client.query('hub.verify_token', this.verify_token);
  }
  return client;
};
Subscription.prototype.generate_challenge = function() {
  var data;
  data = ("" + (this.mode) + (this.topic) + (this.callback) + (this.secret) + (this.verify_token) + ((new Date()).getTime()));
  return Crypto.createHash('md5').update(data).digest("hex");
};
Subscription.prototype.check_required_keys = function() {
  return Subscription.required_keys.forEach(__bind(function(key) {
    var _a;
    return !(typeof (_a = this[key]) !== "undefined" && _a !== null) ? (this.bad_params[("hub." + (key))] = true) : null;
  }, this));
};
Subscription.prototype.check_hub_mode = function() {
  return Subscription.valid_modes.indexOf(this.mode) < 0 ? (this.bad_params["hub.mode"] = true) : null;
};
Subscription.prototype.check_urls = function(key) {
  var _a, _b, url, value;
  if (value = this[key]) {
    url = Url.parse(value);
    return !((typeof (_a = url.hostname) !== "undefined" && _a !== null) && (typeof (_b = url.protocol) !== "undefined" && _b !== null) && url.protocol.match(/^https?:$/i)) ? (this.bad_params[("hub." + (key))] = true) : null;
  } else {
    return (this.bad_params[("hub." + (key))] = true);
  }
};
Subscription.prototype.check_response_for_success = function(err, resp, cb) {
  return resp.statusCode.toString().match(/^2\d\d/) ? cb(err, resp) : cb({
    error: "bad status"
  }, resp);
};
Subscription.formatters = {};
Subscription.valid_proto = /^https?:$/;
Subscription.valid_modes = ['subscribe', 'unsubscribe'];
Subscription.required_keys = ['callback', 'mode', 'topic', 'verify'];
Subscription.allowed_keys = ['callback', 'mode', 'topic', 'verify', 'lease_seconds', 'secret', 'verify_token'];
Subscription.formatters.json = function(items) {
  return JSON.stringify(items);
};
Subscription.formatters.json.content_type = 'application/json';
exports.Subscription = Subscription;
exports.build = function(data) {
  return new exports.Subscription(data);
};
exports.subscribe = function(post_data) {
  var data;
  data = Query.parse(post_data);
  return exports.build(data);
};