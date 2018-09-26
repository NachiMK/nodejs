import { transaction } from 'objection';
import Member from './models/member';

export async function upsertMemberGraph(member) {
  const upsertedGraph = await transaction(Member.knex(), (trx) =>
    Member.query(trx)
      .allowUpsert('[Phones, Children.[Phones], Parent]')
      .upsertGraph(member)
  );

  return upsertedGraph;
}

export async function getMember(memberID, eager) {
  const member = await Member.query()
    .eager(eager)
    .findById(memberID);

  return member;
}

export async function getParent(memberID) {
  const member = await Member.query().findById(memberID);
  const parent = await member.$relatedQuery('Parent');

  return parent;
}

export async function getChildren(memberID) {
  const member = await Member.query().findById(memberID);
  const children = await member.$relatedQuery('Children');

  return children;
}

export async function getMemberPhones(memberID) {
  const member = await Member.query().findById(memberID);
  const phones = await member.$relatedQuery('Phones');

  return phones;
}
