'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _get = require('./get');

Object.keys(_get).forEach(function (key) {
  if (key === "default" || key === "__esModule") return;
  Object.defineProperty(exports, key, {
    enumerable: true,
    get: function () {
      return _get[key];
    }
  });
});

var _ping = require('./ping');

Object.keys(_ping).forEach(function (key) {
  if (key === "default" || key === "__esModule") return;
  Object.defineProperty(exports, key, {
    enumerable: true,
    get: function () {
      return _ping[key];
    }
  });
});

var _post = require('./post');

Object.keys(_post).forEach(function (key) {
  if (key === "default" || key === "__esModule") return;
  Object.defineProperty(exports, key, {
    enumerable: true,
    get: function () {
      return _post[key];
    }
  });
});

var _proxyRequest = require('./proxy-request');

Object.keys(_proxyRequest).forEach(function (key) {
  if (key === "default" || key === "__esModule") return;
  Object.defineProperty(exports, key, {
    enumerable: true,
    get: function () {
      return _proxyRequest[key];
    }
  });
});

var _schedule = require('./schedule');

Object.keys(_schedule).forEach(function (key) {
  if (key === "default" || key === "__esModule") return;
  Object.defineProperty(exports, key, {
    enumerable: true,
    get: function () {
      return _schedule[key];
    }
  });
});
//# sourceMappingURL=index.js.map