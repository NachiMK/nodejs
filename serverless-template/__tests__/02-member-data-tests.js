import dotenv from 'dotenv';
import { initKnex, destroyKnex } from '@hixme/objection-init-middleware';
import { getMemberGraph, upsertMemberGraph } from '../src/controllers/members';

// Required to load environment variables from .env for jest
dotenv.config();

// Jest callback that runs before any of the tests run
beforeAll(() => {
  initKnex();
});

// Jest callback that runs after all the tests have completed
afterAll(() => {
  // If we don't destroy knex, it hangs the thread
  destroyKnex();
});

// Skip from running in bitbucket pipeline since it relies on being in VPC
describe('Member data tests', () => {
  it.skip('expect getMember() to return member graph', async () => {
    await upsertMemberGraph({
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
    });

    const member = await getMemberGraph(1);

    expect(member).toMatchObject({
      MemberID: 1,
      ParentID: null,
      FirstName: 'John',
      LastName: 'Doe',
      DateOfBirth: '1980-01-01',
      Parent: null,
      Phones: [
        {
          MemberID: 1,
          PhoneNumber: '800-111-2222',
          Extension: null,
        },
        {
          MemberID: 1,
          PhoneNumber: '310-123-3333',
          Extension: null,
        },
      ],
      Children: [
        {
          ParentID: 1,
          FirstName: 'Danny',
          LastName: 'Doe',
          DateOfBirth: '2000-10-01',
        },
        {
          ParentID: 1,
          FirstName: 'Jenny',
          LastName: null,
          DateOfBirth: null,
        },
      ],
    });
  });
});
