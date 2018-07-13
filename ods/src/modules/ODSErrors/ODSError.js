export default class ODSError extends Error {
  constructor(message, status) {
    // Calling parent constructor of base Error class.
    super(message);

    // Saving class name in the property of our custom error as a shortcut.
    this.name = this.constructor.name;

    // Capturing stack trace, excluding constructor call from it.
    Error.captureStackTrace(this, this.constructor);

    // custom status
    this.status = status || 'Error';
  }
}

export class DataBaseError extends ODSError {
  constructor(message) {
    // Providing default message and overriding status code.
    super('Error working with database.' || message, 'Error');
  }
}
