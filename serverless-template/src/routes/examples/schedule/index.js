import ware from 'warewolf'
import { responseController } from '../../../utils'

export const schedule = ware(
  async (event) => {
    console.warn('the \'schedule\' function has executed!')

    event.result = {
      message: 'This is an example of how to execute a function on a schedule',
    }
  },
  responseController(),
)
