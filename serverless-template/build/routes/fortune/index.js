'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.get = undefined;

var _warewolf = require('warewolf');

var _warewolf2 = _interopRequireDefault(_warewolf);

var _beforeAfterMiddleware = require('@hixme/before-after-middleware');

var _roleAuthorizerMiddleware = require('@hixme/role-authorizer-middleware');

var _fortune = require('../../controllers/fortune');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

const get = exports.get = (0, _warewolf2.default)(_beforeAfterMiddleware.before, (0, _roleAuthorizerMiddleware.isRoleAuthorized)(['PlatformHixmeAdmin']), async event => {
  const fortune = (0, _fortune.getFortune)();

  event.result = fortune;
}, _beforeAfterMiddleware.after);
//# sourceMappingURL=index.js.map