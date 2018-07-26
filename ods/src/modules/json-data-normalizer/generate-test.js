import { JsonDataNormalizer } from './index';

const event = require('./event.json');

function testJsonDataNormalizer() {
  try {
    return JsonDataNormalizer(event);
  } catch (err) {
    console.log(`Error in Json data normalizer: ${err.message}`);
  }
  return undefined;
}

testJsonDataNormalizer();
