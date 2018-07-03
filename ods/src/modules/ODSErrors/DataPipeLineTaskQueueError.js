import ODSError from '../ODSErrors/ODSError';

export class CreatingDataPipeLineTaskError extends ODSError {
  constructor(message) {
    // Providing default message and overriding status code.
    super('Error Creating DataPipeLineTaskQueue Entry in database.' || message, 'Error');
  }
}

export class GettingPendingTaskError extends ODSError {
  constructor(message) {
    // Providing default message and overriding status code.
    super('Error getting Pending DataPipeLineTaskQueue Entry in database.' || message, 'Error');
  }
}
