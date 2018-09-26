import ware from 'warewolf';
import { before, after } from '@hixme/before-after-middleware';
import { isRoleAuthorized } from '@hixme/role-authorizer-middleware';
import { getFortune } from '../../controllers/fortune';

export const get = ware(
  before,
  isRoleAuthorized(['PlatformHixmeAdmin']),
  async (event) => {
    // grab a random fortune from the 'fortune-cookie' module
    const fortune = getFortune();

    event.result = fortune;
  },
  after
);
