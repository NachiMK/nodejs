'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _members = require('../data/members');

Object.keys(_members).forEach(function (key) {
  if (key === "default" || key === "__esModule") return;
  Object.defineProperty(exports, key, {
    enumerable: true,
    get: function () {
      return _members[key];
    }
  });
});
exports.getMemberGraph = getMemberGraph;
exports.upsertGraph = upsertGraph;
async function getMemberGraph(memberID) {
  const memberGraph = await (0, _members.getMember)(memberID, '[Parent, Phones, Children]');

  return memberGraph;
}

async function upsertGraph(memberGraph) {
  return (0, _members.upsertMemberGraph)(memberGraph);
}
//# sourceMappingURL=members.js.map