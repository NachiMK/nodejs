import ware from 'warewolf'
import { before, after } from '../../../utils'

export const post = ware(
  before,

  async (event) => {
    event.result = {
      message: 'Your function executed successfully!',
    }

    // in the incoming body object, if there's 'showEvent' set to 'true'...
    if (event.body.showEvent === true) {
      event.event = { ...event }
    }
  },

  after,
)
