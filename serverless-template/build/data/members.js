'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.upsertMemberGraph = upsertMemberGraph;
exports.getMember = getMember;
exports.getParent = getParent;
exports.getChildren = getChildren;
exports.getMemberPhones = getMemberPhones;

var _objection = require('objection');

var _member = require('./models/member');

var _member2 = _interopRequireDefault(_member);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

async function upsertMemberGraph(member) {
  const upsertedGraph = await (0, _objection.transaction)(_member2.default.knex(), trx => _member2.default.query(trx).allowUpsert('[Phones, Children.[Phones], Parent]').upsertGraph(member));

  return upsertedGraph;
}

async function getMember(memberID, eager) {
  const member = await _member2.default.query().eager(eager).findById(memberID);

  return member;
}

async function getParent(memberID) {
  const member = await _member2.default.query().findById(memberID);
  const parent = await member.$relatedQuery('Parent');

  return parent;
}

async function getChildren(memberID) {
  const member = await _member2.default.query().findById(memberID);
  const children = await member.$relatedQuery('Children');

  return children;
}

async function getMemberPhones(memberID) {
  const member = await _member2.default.query().findById(memberID);
  const phones = await member.$relatedQuery('Phones');

  return phones;
}
//# sourceMappingURL=members.js.map