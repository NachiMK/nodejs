import { generateSchema } from './generateJsonSchema';

const name = 'clients';
const data = require('./clients.json');

generateSchema(name, data[0].Item)
  .then(res => console.log(res))
  .catch(res => console.log(res));
