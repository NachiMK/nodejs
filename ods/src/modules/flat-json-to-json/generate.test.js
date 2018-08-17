import { JsonToJsonFlattner } from './JsonToJsonFlattner';
import event from './event.json';

describe('JsonToJson Flattner - Process ANY DATA', () => {
  it('should Process one or Zero tasks successfully', async () => {
    console.log('event:', JSON.stringify(event, null, 2));
    const jsonFlatner = new JsonToJsonFlattner(event);
    await jsonFlatner.getNormalizedDataset();
    expect(jsonFlatner.Output.Status).toBe('success');
    expect(jsonFlatner.Output.NormalizedDataSet).toBeDefined();
    // console.log(JSON.stringify(jsonFlatner.Output.NormalizedDataSet, null, 2));
  });
});
