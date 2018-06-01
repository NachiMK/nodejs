import ware from 'warewolf';
import { before } from '@hixme/before-after-middleware';

export const schedule = ware(
  before,
  async (event) => {
    console.warn('the \'schedule\' function has executed!');

    event.result = {
      message: 'This is an example of how to execute a function on a schedule',
    };
  },
);
