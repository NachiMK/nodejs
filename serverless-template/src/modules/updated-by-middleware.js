import table from '@hixme/tables';

export const addUpdatedByToBody = async (event) => {
  const authenticatedPersonPublicKey = event.requestContext.authorizer.claims['cognito:username'];

  if (!event.UpdatedBy && authenticatedPersonPublicKey) {
    const worker = await getPerson(authenticatedPersonPublicKey);
    event.body.UpdatedBy = `${worker.FirstName} ${worker.LastName}`;
  }
  return event;
};

export const addUpdatedDateToBody = async (event) => {
  event.body.UpdatedDate = new Date().toISOString();
  return event;
};

export const addUpdatedKeysBody = async (event) => {
  await addUpdatedByToBody(event);
  await addUpdatedDateToBody(event);
};

async function getPerson(id) {
  const stage = process.env.STAGE;

  table.config({
    tablePrefix: stage,
    debug: false,
  });

  const personTable = table.create('persons', { indexName: 'EmployeePublicKey-index' });

  return personTable.getById(id);
}
