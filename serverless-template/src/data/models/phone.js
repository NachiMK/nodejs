import { BaseModel } from '@hixme/objection-init-middleware';
import { PhoneSchema } from './phone.schema.json';

export default class Phone extends BaseModel {
  static tableName = 'Phones';

  static idColumn = 'PhoneID';

  static jsonSchema = PhoneSchema;

  static get relationMappings() {
    /* eslint-disable global-require */
    // https://vincit.github.io/objection.js/#relations
    const Member = require('./member');

    // This object defines the relations to other models.
    return {
      Member: {
        relation: BaseModel.BelongsToOneRelation,
        modelClass: Member,
        join: {
          from: 'Phones.MemberID',
          to: 'Members.MemberID',
        },
      },
    };
  }
}
