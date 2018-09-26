import { orderBy } from 'lodash';
import uuid from 'uuid';
import table from '@hixme/tables';

export async function getService(id) {
  const serviceTable = createTable();

  return serviceTable.getById(id);
}

export async function getServicesByDomain(domain) {
  const serviceTable = createTable();

  const domains = await serviceTable.queryByKeys({ Domain: domain });

  return orderBy(domains.filter((f) => f.IsActive), 'Name');
}

export async function saveService(service) {
  const serviceTable = createTable();

  service.Id = service.Id || uuid.v4();
  service.UpdatedDate = new Date().toISOString();

  return serviceTable.put({ Item: service });
}

function createTable() {
  const stage = process.env.STAGE;

  table.config({
    tablePrefix: stage,
    debug: false,
  });

  return table.create('services', { indexName: 'Domain-index' });
}
