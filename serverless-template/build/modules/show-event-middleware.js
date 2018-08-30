'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.showEvent = undefined;

var _lodash = require('lodash');

const showEvent = exports.showEvent = async event => {
  if (event.body.showEvent || event.queryAndParams.showEvent) {
    event.result.event = (0, _lodash.omit)(event, 'result');
  }
};
//# sourceMappingURL=show-event-middleware.js.map