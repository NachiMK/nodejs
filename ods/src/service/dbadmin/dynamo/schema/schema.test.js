import { testlambdaToCreateSchema } from './testLambda';

describe('ods - generate schema test', () => {
  it('should create schema and returns success', async () => {
    const resp = await testlambdaToCreateSchema();
    const expected = /REFRESH/;
    expect(resp).stringMatching(expected);
  });
});
