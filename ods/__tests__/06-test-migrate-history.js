import {migrateHistory} from '../src/service/dbadmin/index';

describe('Test Migrating history tables', () => {

    it('Migrate Single History table', async () => {
        console.log("Migrate Single History Table:");
        const resp = await migrateHistory("dev-cart-history", "dev-cart-history-v2");
        console.warn("Result of Migrating single History Table:" + JSON.stringify(resp,null,2));
        expect(resp.migration_status == "SUCCESS").toEqual(true);
    });
});
