import ware from 'warewolf';
import { before, after } from '@hixme/before-after-middleware';
import { isRoleAuthorized } from '@hixme/role-authorizer-middleware';
import { validateParams } from '@hixme/validator-middleware';
import { ROLE_PLATFORM_HIXME_ADMIN } from '@hixme/role-policy';
import { getMemberGraph, upsertMemberGraph } from '../../../controllers/members';
import { initKnexAsync, destroyKnexAsync } from '../../../modules/objection-utils';

export const get = ware(
  before,
  validateParams(require('./request.schema.json')), // eslint-disable-line
  isRoleAuthorized([ROLE_PLATFORM_HIXME_ADMIN]),
  initKnexAsync,
  async (event) => {
    const memberGraph = {
      FirstName: 'John',
      LastName: 'Doe',
      DateOfBirth: '1980-01-01',
      Phones: [
        {
          PhoneNumber: '800-111-2222',
        },
        {
          PhoneNumber: '310-123-3333',
        },
      ],
      Children: [
        {
          FirstName: 'Danny',
          LastName: 'Doe',
          DateOfBirth: '2000-10-01',
        },
        {
          FirstName: 'Jenny',
          Phones: [
            {
              PhoneNumber: '310-0910-1237',
            },
          ],
        },
      ],
    };

    await upsertMemberGraph(memberGraph);

    const member = await getMemberGraph(event.pathParameters.MemberID);

    event.result = member;
  },
  destroyKnexAsync,
  after
);
