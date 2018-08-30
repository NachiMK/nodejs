'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.schedule = undefined;

var _warewolf = require('warewolf');

var _warewolf2 = _interopRequireDefault(_warewolf);

var _beforeAfterMiddleware = require('@hixme/before-after-middleware');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

const schedule = exports.schedule = (0, _warewolf2.default)(_beforeAfterMiddleware.before, async event => {
  console.warn('the \'schedule\' function has executed!');

  event.result = {
    message: 'This is an example of how to execute a function on a schedule'
  };
});
//# sourceMappingURL=index.js.map