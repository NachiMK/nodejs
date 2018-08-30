'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.get = undefined;

var _warewolf = require('warewolf');

var _warewolf2 = _interopRequireDefault(_warewolf);

var _beforeAfterMiddleware = require('@hixme/before-after-middleware');

var _roleAuthorizerMiddleware = require('@hixme/role-authorizer-middleware');

var _validatorMiddleware = require('@hixme/validator-middleware');

var _rolePolicy = require('@hixme/role-policy');

var _members = require('../../../controllers/members');

var _objectionUtils = require('../../../modules/objection-utils');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

const get = exports.get = (0, _warewolf2.default)(_beforeAfterMiddleware.before, (0, _validatorMiddleware.validateParams)(require('./request.schema.json')), (0, _roleAuthorizerMiddleware.isRoleAuthorized)([_rolePolicy.ROLE_PLATFORM_HIXME_ADMIN]), _objectionUtils.initKnexAsync, async event => {
  const memberGraph = {
    FirstName: 'John',
    LastName: 'Doe',
    DateOfBirth: '1980-01-01',
    Phones: [{
      PhoneNumber: '800-111-2222'
    }, {
      PhoneNumber: '310-123-3333'
    }],
    Children: [{
      FirstName: 'Danny',
      LastName: 'Doe',
      DateOfBirth: '2000-10-01'
    }, {
      FirstName: 'Jenny',
      Phones: [{
        PhoneNumber: '310-0910-1237'
      }]
    }]
  };

  await (0, _members.upsertMemberGraph)(memberGraph);

  const member = await (0, _members.getMemberGraph)(event.pathParameters.MemberID);

  event.result = member;
}, _objectionUtils.destroyKnexAsync, _beforeAfterMiddleware.after);
//# sourceMappingURL=index.js.map