import { BaseModel } from '@hixme/objection-init-middleware';
import { MemberSchema } from './member.schema.json';

export default class Member extends BaseModel {
  static tableName = 'Members';

  static idColumn = 'MemberID';

  static jsonSchema = MemberSchema;

  static get relationMappings() {
    /* eslint-disable global-require */
    // https://vincit.github.io/objection.js/#relations
    const Phone = require('./phone');

    // This object defines the relations to other models/tables.
    return {
      Phones: {
        relation: BaseModel.HasManyRelation,
        modelClass: Phone,
        join: {
          from: 'Members.MemberID',
          to: 'Phones.MemberID',
        },
      },

      Children: {
        relation: BaseModel.HasManyRelation,
        modelClass: Member,
        join: {
          from: 'Members.MemberID',
          to: 'Members.ParentID',
        },
      },

      Parent: {
        relation: BaseModel.BelongsToOneRelation,
        modelClass: Member,
        join: {
          from: 'Members.ParentID',
          to: 'Members.MemberID',
        },
      },
    };
  }
}
