'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.deleteService = undefined;

var _warewolf = require('warewolf');

var _warewolf2 = _interopRequireDefault(_warewolf);

var _beforeAfterMiddleware = require('@hixme/before-after-middleware');

var _roleAuthorizerMiddleware = require('@hixme/role-authorizer-middleware');

var _validatorMiddleware = require('@hixme/validator-middleware');

var _dynamoMiddleware = require('@hixme/dynamo-middleware');

var _rolePolicy = require('@hixme/role-policy');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

const deleteService = exports.deleteService = (0, _warewolf2.default)(_beforeAfterMiddleware.before, (0, _validatorMiddleware.validateBody)(require('./request.schema.json')), (0, _roleAuthorizerMiddleware.isRoleAuthorized)([_rolePolicy.ROLE_PLATFORM_HIXME_ADMIN]), (0, _dynamoMiddleware.inactivateDynamoItem)({ tableName: 'services', key: event => event.body.ServicePublicKey }), _beforeAfterMiddleware.after);
//# sourceMappingURL=index.js.map