var ScopedClient, extend, http, path, qs, sys, url;
var __bind = function(func, context) {
    return function(){ return func.apply(context, arguments); };
  };
path = require('path');
http = require('http');
sys = require('sys');
url = require('url');
qs = require('querystring');
ScopedClient = function(url, options) {
  this.options = this.buildOptions(url, options);
  return this;
};
ScopedClient.prototype.request = function(method, reqBody, callback) {
  var client, err, headers, port, req, sendingData;
  if (typeof (reqBody) === 'function') {
    callback = reqBody;
    reqBody = null;
  }
  try {
    headers = extend({}, this.options.headers);
    sendingData = method.match(/^P/) && reqBody && reqBody.length > 0;
    headers.Host = this.options.hostname;
    if (sendingData) {
      headers['Content-Length'] = reqBody.length;
    }
    port = this.options.port || ScopedClient.defaultPort[this.options.protocol] || 80;
    client = http.createClient(port, this.options.hostname);
    req = client.request(method, this.fullPath(), headers);
    if (sendingData) {
      req.write(reqBody, 'utf-8');
    }
    if (callback) {
      callback(null, req);
    }
  } catch (err) {
    if (callback) {
      callback(err, req);
    }
    err = e;
  }
  return __bind(function(callback) {
    if (callback) {
      err = null;
      req.on('response', function(resp) {
        var body;
        try {
          resp.setEncoding('utf8');
          body = '';
          resp.on('data', function(chunk) {
            return body += chunk;
          });
          return resp.on('end', function() {
            return callback(err, resp, body);
          });
        } catch (e) {
          return (err = e);
        }
      });
    }
    req.end();
    return this;
  }, this);
};
ScopedClient.prototype.fullPath = function(p) {
  var full, search;
  search = qs.stringify(this.options.query);
  full = this.join(p);
  if (search.length > 0) {
    full += ("?" + (search));
  }
  return full;
};
ScopedClient.prototype.scope = function(url, options, callback) {
  var override, scoped;
  override = this.buildOptions(url, options);
  scoped = new ScopedClient(this.options).protocol(override.protocol).host(override.hostname).path(override.pathname);
  if (typeof (url) === 'function') {
    callback = url;
  } else if (typeof (options) === 'function') {
    callback = options;
  }
  if (callback) {
    callback(scoped);
  }
  return scoped;
};
ScopedClient.prototype.join = function(suffix) {
  var p;
  p = this.options.pathname || '/';
  return suffix && suffix.length > 0 ? (suffix.match(/^\//) ? suffix : path.join(p, suffix)) : p;
};
ScopedClient.prototype.path = function(p) {
  this.options.pathname = this.join(p);
  return this;
};
ScopedClient.prototype.query = function(key, value) {
  this.options.query || (this.options.query = {});
  if (typeof (key) === 'string') {
    if (value) {
      this.options.query[key] = value;
    } else {
      delete this.options.query[key];
    }
  } else {
    extend(this.options.query, key);
  }
  return this;
};
ScopedClient.prototype.host = function(h) {
  if (h && h.length > 0) {
    this.options.hostname = h;
  }
  return this;
};
ScopedClient.prototype.port = function(p) {
  if (p && (typeof (p) === 'number' || p.length > 0)) {
    this.options.port = p;
  }
  return this;
};
ScopedClient.prototype.protocol = function(p) {
  if (p && p.length > 0) {
    this.options.protocol = p;
  }
  return this;
};
ScopedClient.prototype.auth = function(user, pass) {
  if (!user) {
    this.options.auth = null;
  } else if (!pass && user.match(/:/)) {
    this.options.auth = user;
  } else {
    this.options.auth = ("" + (user) + ":" + (pass));
  }
  return this;
};
ScopedClient.prototype.header = function(name, value) {
  this.options.headers[name] = value;
  return this;
};
ScopedClient.prototype.headers = function(h) {
  extend(this.options.headers, h);
  return this;
};
ScopedClient.prototype.buildOptions = function() {
  var i, options, ty;
  options = {};
  i = 0;
  while (arguments[i]) {
    ty = typeof arguments[i];
    if (ty === 'string') {
      options.url = arguments[i];
    } else if (ty !== 'function') {
      extend(options, arguments[i]);
    }
    i += 1;
  }
  if (options.url) {
    extend(options, url.parse(options.url, true));
    delete options.url;
    delete options.href;
    delete options.search;
  }
  options.headers || (options.headers = {});
  return options;
};
ScopedClient.methods = ["GET", "POST", "PUT", "DELETE", "HEAD"];
ScopedClient.methods.forEach(function(method) {
  return (ScopedClient.prototype[method.toLowerCase()] = function(body, callback) {
    return this.request(method, body, callback);
  });
});
ScopedClient.prototype.del = ScopedClient.prototype['delete'];
ScopedClient.defaultPort = {
  'http:': 80,
  'https:': 443,
  http: 80,
  https: 443
};
extend = function(a, b) {
  var prop;
  prop = null;
  Object.keys(b).forEach(function(prop) {
    return (a[prop] = b[prop]);
  });
  return a;
};
exports.create = function(url, options) {
  return new ScopedClient(url, options);
};