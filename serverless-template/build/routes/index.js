'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _examples = require('./examples');

Object.keys(_examples).forEach(function (key) {
  if (key === "default" || key === "__esModule") return;
  Object.defineProperty(exports, key, {
    enumerable: true,
    get: function () {
      return _examples[key];
    }
  });
});
//# sourceMappingURL=index.js.map