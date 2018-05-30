'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.ping = undefined;

var _asyncToGenerator2 = require('babel-runtime/helpers/asyncToGenerator');

var _asyncToGenerator3 = _interopRequireDefault(_asyncToGenerator2);

var _warewolf = require('warewolf');

var _warewolf2 = _interopRequireDefault(_warewolf);

var _utils = require('../../../utils');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

const ping = exports.ping = (0, _warewolf2.default)(_utils.before, (() => {
  var _ref = (0, _asyncToGenerator3.default)(function* (event) {
    const {
      env: { npm_package_version, STAGE } = {},
      versions: { node } = {}
    } = process;

    const versions = { node, npm_package_version };

    event.result = {
      message: 'pong!',
      STAGE,
      versions
    };

    const { showENV, showEvent } = event.params;
    if ((0, _utils.queryStringIsTrue)(showEvent)) {
      event.result.event = event;
    }

    const eventHeadersHost = event.headers && event.headers.Host;
    const HTTPRequestPassingThroughHixmeDomain = eventHeadersHost && eventHeadersHost.includes('hixme.com');
    const serviceIsRuningLocally = !HTTPRequestPassingThroughHixmeDomain || event.isOffline;

    const isSafeToDisplayEnvVariables = !_utils.isProd && serviceIsRuningLocally;

    if (isSafeToDisplayEnvVariables && (0, _utils.queryStringIsTrue)(showENV)) {
      event.result.env = process.env;
    }
  });

  return function (_x) {
    return _ref.apply(this, arguments);
  };
})(), _utils.after);
//# sourceMappingURL=index.js.map