import ware from 'warewolf';
import { before, after } from '@hixme/before-after-middleware';
import { isRoleAuthorized } from '@hixme/role-authorizer-middleware';
import { validateBody } from '@hixme/validator-middleware';
import { inactivateDynamoItem } from '@hixme/dynamo-middleware';
import { ROLE_PLATFORM_HIXME_ADMIN } from '@hixme/role-policy';

export const deleteService = ware(
  before,
  validateBody(require('./request.schema.json')), // eslint-disable-line
  isRoleAuthorized([ROLE_PLATFORM_HIXME_ADMIN]),
  inactivateDynamoItem({ tableName: 'services', key: (event) => event.body.ServicePublicKey }),
  after
);
