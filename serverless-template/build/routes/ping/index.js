'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.ping = undefined;

var _warewolf = require('warewolf');

var _warewolf2 = _interopRequireDefault(_warewolf);

var _beforeAfterMiddleware = require('@hixme/before-after-middleware');

var _showEventMiddleware = require('../../modules/show-event-middleware');

var _serverlessUtils = require('../../modules/serverless-utils');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

const ping = exports.ping = (0, _warewolf2.default)(_beforeAfterMiddleware.before, async event => {
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

  const { showENV } = event.params;

  const eventHeadersHost = event.headers && event.headers.Host;
  const HTTPRequestPassingThroughHixmeDomain = eventHeadersHost && eventHeadersHost.includes('hixme.com');
  const serviceIsRuningLocally = !HTTPRequestPassingThroughHixmeDomain || event.isOffline;

  const isSafeToDisplayEnvVariables = !_serverlessUtils.isProd && serviceIsRuningLocally;

  if (isSafeToDisplayEnvVariables && (0, _serverlessUtils.queryStringIsTrue)(showENV)) {
    event.result.env = process.env;
  }
}, _showEventMiddleware.showEvent, _beforeAfterMiddleware.after);
//# sourceMappingURL=index.js.map