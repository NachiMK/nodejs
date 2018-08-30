import { Model } from 'objection';
import { BaseModel } from '../../modules/objection-utils';
import { MemberSchema } from './member.schema.json';

export default class Member extends BaseModel {
  static defaultSchema = 'family';

  static tableName = 'Members';

  static idColumn = 'MemberID';

  static jsonSchema = MemberSchema;

  // This object defines the relations to other models/tables.
  static relationMappings = {
    Phones: {
      relation: Model.HasManyRelation,
      modelClass: `${__dirname}/phone`, // This is a convention used by objection.js to create relationships without require loops.
      join: {
        from: 'Members.MemberID',
        to: 'Phones.MemberID',
      },
    },

    Children: {
      relation: Model.HasManyRelation,
      modelClass: `${__dirname}/member`,
      join: {
        from: 'Members.MemberID',
        to: 'Members.ParentID',
      },
    },

    Parent: {
      relation: Model.BelongsToOneRelation,
      modelClass: `${__dirname}/member`,
      join: {
        from: 'Members.ParentID',
        to: 'Members.MemberID',
      },
    },
  };
}
