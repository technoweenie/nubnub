var Crypto, Query, ScopedClient, Subscriber;
var __bind = function(func, context) {
    return function(){ return func.apply(context, arguments); };
  };
Crypto = require('crypto');
Query = require('querystring');
ScopedClient = require('../vendor/scoped-http-client/lib');
exports.is_valid_signature = function(sig, secret, data) {
  var hmac;
  hmac = Crypto.createHmac('sha1', secret);
  hmac.update(data);
  return hmac.digest('hex') === sig;
};
Subscriber = function(options) {
  Subscriber.allowed_keys.forEach(__bind(function(key) {
    var value;
    value = options[key];
    if (typeof value !== "undefined" && value !== null) {
      return (this[key] = value);
    }
  }, this));
  this.verify || (this.verify = 'sync');
  return this;
};
Subscriber.prototype.subscribe = function(cb) {
  this.post_to_hub('subscribe', cb);
  return this;
};
Subscriber.prototype.unsubscribe = function(cb) {
  this.post_to_hub('unsubscribe', cb);
  return this;
};
Subscriber.prototype.is_valid_signature = function(sig, body) {
  return exports.is_valid_signature(sig, this.secret, body);
};
Subscriber.prototype.post_to_hub = function(mode, cb) {
  var data, params;
  params = this.build_hub_params(mode);
  data = Query.stringify(params);
  return ScopedClient.create(this.hub).header("content-type", "application/x-www-form-urlencoded").post(data)(cb);
};
Subscriber.prototype.build_hub_params = function(mode) {
  var _a, _b, _c, params;
  params = {
    'hub.mode': mode || 'subscribe',
    'hub.topic': this.topic,
    'hub.callback': this.callback,
    'hub.verify': this.verify
  };
  if (typeof (_a = this.lease_seconds) !== "undefined" && _a !== null) {
    params['hub.lease_seconds'] = this.lease_seconds;
  }
  if (typeof (_b = this.secret) !== "undefined" && _b !== null) {
    params['hub.secret'] = this.secret;
  }
  if (typeof (_c = this.verify_token) !== "undefined" && _c !== null) {
    params['hub.verify_token'] = this.verify_token;
  }
  return params;
};
Subscriber.allowed_keys = ['callback', 'topic', 'verify', 'hub', 'lease_seconds', 'secret', 'verify_token'];
exports.build = function(options) {
  return new Subscriber(options);
};