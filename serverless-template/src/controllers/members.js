import { getMember, upsertMemberGraph } from '../data/members';

export * from '../data/members';

export async function getMemberGraph(memberID) {
  const memberGraph = await getMember(memberID, '[Parent, Phones, Children]');

  return memberGraph;
}

export async function upsertGraph(memberGraph) {
  return upsertMemberGraph(memberGraph);
}
