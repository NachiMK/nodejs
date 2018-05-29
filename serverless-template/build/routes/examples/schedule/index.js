'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.schedule = undefined;

var _asyncToGenerator2 = require('babel-runtime/helpers/asyncToGenerator');

var _asyncToGenerator3 = _interopRequireDefault(_asyncToGenerator2);

var _warewolf = require('warewolf');

var _warewolf2 = _interopRequireDefault(_warewolf);

var _utils = require('../../../utils');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

const schedule = exports.schedule = (0, _warewolf2.default)((() => {
  var _ref = (0, _asyncToGenerator3.default)(function* (event) {
    console.warn('the \'schedule\' function has executed!');

    event.result = {
      message: 'This is an example of how to execute a function on a schedule'
    };
  });

  return function (_x) {
    return _ref.apply(this, arguments);
  };
})(), (0, _utils.responseController)());
//# sourceMappingURL=index.js.map