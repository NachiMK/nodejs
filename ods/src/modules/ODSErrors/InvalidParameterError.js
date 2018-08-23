import ODSError from '../ODSErrors/ODSError'

module.exports = class InvalidParameterError extends ODSError {
  constructor(message) {
    // Providing default message and overriding status code.
    super(message || 'Parameter Values are invalid.', 'Error')
  }
}
