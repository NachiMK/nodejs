import {enableHistory, LinkTableToTrigger} from '../src/service/dbadmin/index';

describe('Test Enabling History Streaming and Triggers', () => {

    it('Enable History Streaming and Triggers', async () => {
        console.log("Enable History:");
        const resp = await enableHistory("dev-ods-persons");
        console.warn("Result of Enabling History:" + JSON.stringify(resp,null,2));
        expect(resp.length === 0).toEqual(false);
    });

    it('Link Table to Trigger', async () => {
        console.log("Link Table to Trigger:");
        const resp = await LinkTableToTrigger("dev-ods-persons");
        console.warn("Result of Link Table to Trigger:" + JSON.stringify(resp,null,2));
        expect(resp.length === 0).toEqual(false);
    });

});
