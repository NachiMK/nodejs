import dbAdmin, { EnableStreaming, getTablesWithNoStreams, DisableStreaming } from '../src/service/dbadmin/dynamo/stream';

describe('Test DB Admin Functions', () => {
  it('Delete Streaming on a table', async () => {
    const resp = await DisableStreaming('dev-fundings');
    console.log(`Delete Resp:${JSON.stringify(resp, null, 2)}`);
    expect(resp).toEqual(true);
  });

  it('Get Tables with No Streams', async () => {
    console.log('Tables with No Streams:');
    const resp = await getTablesWithNoStreams('dev');
    console.log(`return list in test:${JSON.stringify(resp, null, 2)}`);
    expect(resp.length === 0).toEqual(false);
  });

  it('Test Enable Streaming', async () => {
    console.log('Testing Enabling Streams:');
    const resp = await EnableStreaming('dev-fundings');
    console.log(`return list in test:${JSON.stringify(resp, null, 2)}`);
    expect(resp).toEqual(true);
  });

  it('Test Streaming Details of all Tables', async () => {
    const tbls = await dbAdmin('prod');
    console.log(`return list in test:${JSON.stringify(tbls, null, 2)}`);
    expect(true).toEqual(true);
  });
});
