import { sum } from './index';

describe('Adder', () => {
  test('expect sum(1,2) to equal 3', () => {
    const summed = sum(1, 2);
    expect(summed).toEqual(3);
  });
});
