'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.get = undefined;

var _extends2 = require('babel-runtime/helpers/extends');

var _extends3 = _interopRequireDefault(_extends2);

var _asyncToGenerator2 = require('babel-runtime/helpers/asyncToGenerator');

var _asyncToGenerator3 = _interopRequireDefault(_asyncToGenerator2);

var _fortuneCookie = require('fortune-cookie');

var _fortuneCookie2 = _interopRequireDefault(_fortuneCookie);

var _warewolf = require('warewolf');

var _warewolf2 = _interopRequireDefault(_warewolf);

var _utils = require('../../../utils');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

const get = exports.get = (0, _warewolf2.default)(_utils.before, (() => {
  var _ref = (0, _asyncToGenerator3.default)(function* (event) {
    const fortune = _fortuneCookie2.default[Math.floor(Math.random() * 250) + 1];
    const message = 'success!';
    const nodeVersion = process.versions.node;

    event.result = {
      fortune,
      message,
      'node version': nodeVersion
    };

    if ((0, _utils.queryStringIsTrue)(event.query.showEvent)) {
      event.result.event = (0, _extends3.default)({}, event);
    }
  });

  return function (_x) {
    return _ref.apply(this, arguments);
  };
})(), _utils.after);
//# sourceMappingURL=index.js.map