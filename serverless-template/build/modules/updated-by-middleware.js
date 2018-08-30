'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.addUpdatedKeysBody = exports.addUpdatedDateToBody = exports.addUpdatedByToBody = undefined;

var _tables = require('@hixme/tables');

var _tables2 = _interopRequireDefault(_tables);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

const addUpdatedByToBody = exports.addUpdatedByToBody = async event => {
  const authenticatedPersonPublicKey = event.requestContext.authorizer.claims['cognito:username'];

  if (!event.UpdatedBy && authenticatedPersonPublicKey) {
    const worker = await getPerson(authenticatedPersonPublicKey);
    event.body.UpdatedBy = `${worker.FirstName} ${worker.LastName}`;
  }
  return event;
};

const addUpdatedDateToBody = exports.addUpdatedDateToBody = async event => {
  event.body.UpdatedDate = new Date().toISOString();
  return event;
};

const addUpdatedKeysBody = exports.addUpdatedKeysBody = async event => {
  await addUpdatedByToBody(event);
  await addUpdatedDateToBody(event);
};

async function getPerson(id) {
  const stage = process.env.STAGE;

  _tables2.default.config({
    tablePrefix: stage,
    debug: false
  });

  const personTable = _tables2.default.create('persons', { indexName: 'EmployeePublicKey-index' });

  return personTable.getById(id);
}
//# sourceMappingURL=updated-by-middleware.js.map