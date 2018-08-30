'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.getService = getService;
exports.getServicesByDomain = getServicesByDomain;
exports.saveService = saveService;

var _lodash = require('lodash');

var _uuid = require('uuid');

var _uuid2 = _interopRequireDefault(_uuid);

var _tables = require('@hixme/tables');

var _tables2 = _interopRequireDefault(_tables);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

async function getService(id) {
  const serviceTable = createTable();

  return serviceTable.getById(id);
}

async function getServicesByDomain(domain) {
  const serviceTable = createTable();

  const domains = await serviceTable.queryByKeys({ Domain: domain });

  return (0, _lodash.orderBy)(domains.filter(f => f.IsActive), 'Name');
}

async function saveService(service) {
  const serviceTable = createTable();

  service.Id = service.Id || _uuid2.default.v4();
  service.UpdatedDate = new Date().toISOString();

  return serviceTable.put({ Item: service });
}

function createTable() {
  const stage = process.env.STAGE;

  _tables2.default.config({
    tablePrefix: stage,
    debug: false
  });

  return _tables2.default.create('services', { indexName: 'Domain-index' });
}
//# sourceMappingURL=services.js.map