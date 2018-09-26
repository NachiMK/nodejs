import ware from 'warewolf';
import { before, after } from '@hixme/before-after-middleware';
import { isRoleAuthorized } from '@hixme/role-authorizer-middleware';
import { validateParams } from '@hixme/validator-middleware';
import { getDynamoItem } from '@hixme/dynamo-middleware';
import { ROLE_PLATFORM_HIXME_ADMIN } from '@hixme/role-policy';

export const get = ware(
  before,
  validateParams(require('./request.schema.json')), // eslint-disable-line
  isRoleAuthorized([ROLE_PLATFORM_HIXME_ADMIN]),
  getDynamoItem({
    tableName: 'services',
    key: (event) => event.pathParameters.ServicePublicKey,
  }),
  after
);
