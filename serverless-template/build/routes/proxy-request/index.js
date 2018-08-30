'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.proxy = undefined;

var _warewolf = require('warewolf');

var _warewolf2 = _interopRequireDefault(_warewolf);

var _nodeFetch = require('node-fetch');

var _nodeFetch2 = _interopRequireDefault(_nodeFetch);

var _beforeAfterMiddleware = require('@hixme/before-after-middleware');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

const proxy = exports.proxy = (0, _warewolf2.default)(_beforeAfterMiddleware.before, async event => {
  const { acronym } = event.params;

  const response = await (0, _nodeFetch2.default)(`http://www.nactem.ac.uk/software/acromine/dictionary.py?sf=${acronym}`, {
    headers: {
      Accept: 'text/plain',
      'Content-type': 'application/json'
    },
    method: 'GET'
  });
  const json = response.json();
  event.response = formatAcronymResult(json);
}, _beforeAfterMiddleware.after);

const formatAcronymResult = acronymAPIResult => {
  if (!acronymAPIResult || acronymAPIResult == null || !(acronymAPIResult.length > 0)) {
    return {};
  }

  const input = acronymAPIResult[0].sf;
  const acronyms = acronymAPIResult[0].lfs.map(acronym => acronym.lf);

  return {
    input,
    acronyms
  };
};
//# sourceMappingURL=index.js.map