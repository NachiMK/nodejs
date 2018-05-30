import ware from 'warewolf';
import { before, after } from '@hixme/before-after-middleware';
import { enableHistory as svcEnableHistory } from '../../../../service/dbadmin/index';

// require('../history/EnableHistory.json');

export const EnableHistory = ware(
  before,
  // validateParams(path.join(__dirname, 'EnableHistory.json')),
  async (event) => {
    const dynamotablename = event.queryAndParams.DynamoTableName;
    const resp = await svcEnableHistory(dynamotablename);

    event.result = resp;
  },
  after,
);
