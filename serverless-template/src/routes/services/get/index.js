import ware from 'warewolf';
import { before, after } from '@hixme/before-after-middleware';
import { isRoleAuthorized } from '@hixme/role-authorizer-middleware';
import { validateQuery } from '@hixme/validator-middleware';
import { queryDynamo } from '@hixme/dynamo-middleware';
import { ROLE_PLATFORM_HIXME_ADMIN } from '@hixme/role-policy';

export const get = ware(
  before,
  validateQuery(require('./request.schema.json')), // eslint-disable-line
  isRoleAuthorized([ROLE_PLATFORM_HIXME_ADMIN]),
  queryDynamo({
    tableName: 'services',
    key: event => ({ Domain: event.queryStringParameters.Domain }),
    indexName: 'Domain-index',
  }),
  after,
);
