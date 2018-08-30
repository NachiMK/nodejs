'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _objection = require('objection');

var _objectionUtils = require('../../modules/objection-utils');

var _memberSchema = require('./member.schema.json');

class Member extends _objectionUtils.BaseModel {}
exports.default = Member;
Member.defaultSchema = 'family';
Member.tableName = 'Members';
Member.idColumn = 'MemberID';
Member.jsonSchema = _memberSchema.MemberSchema;
Member.relationMappings = {
  Phones: {
    relation: _objection.Model.HasManyRelation,
    modelClass: `${__dirname}/phone`,
    join: {
      from: 'Members.MemberID',
      to: 'Phones.MemberID'
    }
  },

  Children: {
    relation: _objection.Model.HasManyRelation,
    modelClass: `${__dirname}/member`,
    join: {
      from: 'Members.MemberID',
      to: 'Members.ParentID'
    }
  },

  Parent: {
    relation: _objection.Model.BelongsToOneRelation,
    modelClass: `${__dirname}/member`,
    join: {
      from: 'Members.ParentID',
      to: 'Members.MemberID'
    }
  }
};
module.exports = exports['default'];
//# sourceMappingURL=member.js.map