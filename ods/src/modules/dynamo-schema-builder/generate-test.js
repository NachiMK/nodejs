import { GetDynamoTableSchema } from './index';

GetDynamoTableSchema({ TableName: 'prod-clients' })
  .then(res => console.log('res:', res))
  .catch(err => console.log('error:', JSON.stringify(err, null, 2)));
