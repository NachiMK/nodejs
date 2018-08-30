'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _objection = require('objection');

var _objectionUtils = require('../../modules/objection-utils');

var _phoneSchema = require('./phone.schema.json');

class Phone extends _objectionUtils.BaseModel {}
exports.default = Phone;
Phone.defaultSchema = 'public';
Phone.tableName = 'Phones';
Phone.idColumn = 'PhoneID';
Phone.jsonSchema = _phoneSchema.PhoneSchema;
Phone.relationMappings = {
  Member: {
    relation: _objection.Model.BelongsToOneRelation,
    modelClass: `${__dirname}/member`,
    join: {
      from: 'Phones.MemberID',
      to: 'Members.MemberID'
    }
  }
};
module.exports = exports['default'];
//# sourceMappingURL=phone.js.map