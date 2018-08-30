import { Model } from 'objection';
import { BaseModel } from '../../modules/objection-utils';
import { PhoneSchema } from './phone.schema.json';

export default class Phone extends BaseModel {
  static defaultSchema = 'public';

  static tableName = 'Phones';

  static idColumn = 'PhoneID';

  static jsonSchema = PhoneSchema;

  // This object defines the relations to other models.
  static relationMappings = {
    Member: {
      relation: Model.BelongsToOneRelation,
      modelClass: `${__dirname}/member`,
      join: {
        from: 'Phones.MemberID',
        to: 'Members.MemberID',
      },
    },
  };
}
