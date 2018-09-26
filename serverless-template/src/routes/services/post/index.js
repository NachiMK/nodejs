import ware from 'warewolf';
import { before, after } from '@hixme/before-after-middleware';
import { isRoleAuthorized } from '@hixme/role-authorizer-middleware';
import { validateBody } from '@hixme/validator-middleware';
import { saveDynamoItem } from '@hixme/dynamo-middleware';
import { ROLE_PLATFORM_HIXME_ADMIN } from '@hixme/role-policy';
import { addUpdatedByToBody } from '../../../modules/updated-by-middleware';

export const post = ware(
  before,
  validateBody(require('./request.schema.json')), // eslint-disable-line
  isRoleAuthorized([ROLE_PLATFORM_HIXME_ADMIN]),
  addUpdatedByToBody,
  saveDynamoItem({
    tableName: 'services',
    item: (event) => event.body,
    key: (event) => event.body.Id,
    schema: 'request.schema.json',
  }),
  after
);
