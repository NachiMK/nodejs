import ODSError from '../ODSErrors/ODSError';

export class CreatingDataPipeLineTaskError extends ODSError {
  constructor(message) {
    // Providing default message and overriding status code.
    super('Error Creating DataPipeLineTaskQueue Entry in database.' || message, 'Error');
  }
}
