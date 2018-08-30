'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.post = undefined;

var _warewolf = require('warewolf');

var _warewolf2 = _interopRequireDefault(_warewolf);

var _beforeAfterMiddleware = require('@hixme/before-after-middleware');

var _roleAuthorizerMiddleware = require('@hixme/role-authorizer-middleware');

var _validatorMiddleware = require('@hixme/validator-middleware');

var _dynamoMiddleware = require('@hixme/dynamo-middleware');

var _rolePolicy = require('@hixme/role-policy');

var _updatedByMiddleware = require('../../../modules/updated-by-middleware');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

const post = exports.post = (0, _warewolf2.default)(_beforeAfterMiddleware.before, (0, _validatorMiddleware.validateBody)(require('./request.schema.json')), (0, _roleAuthorizerMiddleware.isRoleAuthorized)([_rolePolicy.ROLE_PLATFORM_HIXME_ADMIN]), _updatedByMiddleware.addUpdatedByToBody, (0, _dynamoMiddleware.saveDynamoItem)({
  tableName: 'services',
  item: event => event.body,
  key: event => event.body.Id,
  schema: 'request.schema.json'
}), _beforeAfterMiddleware.after);
//# sourceMappingURL=index.js.map