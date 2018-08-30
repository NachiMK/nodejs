'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.post = undefined;

var _extends2 = require('babel-runtime/helpers/extends');

var _extends3 = _interopRequireDefault(_extends2);

var _warewolf = require('warewolf');

var _warewolf2 = _interopRequireDefault(_warewolf);

var _utils = require('../../../utils');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

const post = exports.post = (0, _warewolf2.default)(_utils.before, async event => {
  event.result = {
    message: 'Your function executed successfully!'
  };

  if (event.body.showEvent === true) {
    event.event = (0, _extends3.default)({}, event);
  }
}, _utils.after);
//# sourceMappingURL=index.js.map