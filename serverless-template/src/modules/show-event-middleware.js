import { omit } from 'lodash';

export const showEvent = async (event) => {
  // in the incoming body object, if there's 'showEvent' set to 'true'...
  // TODO: This could be moved into the after middleware
  if (event.body.showEvent || event.queryAndParams.showEvent) {
    event.result.event = omit(event, 'result');
  }
};
