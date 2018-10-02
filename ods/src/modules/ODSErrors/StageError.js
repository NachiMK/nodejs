import ODSError from '../ODSErrors/ODSError'

export class InvalidPreStageDataError extends ODSError {
  constructor(message) {
    // Providing default message and overriding status code.
    super(`PreStage to Stage error, some rows have invalid values. ${message}`, 'Error')
  }
}

export class InvalidStageTableError extends ODSError {
  constructor(message) {
    // Providing default message and overriding status code.
    super(`Stage Table missing. ${message}`, 'Error')
  }
}

export class StageSchemaUpdateError extends ODSError {
  constructor(message) {
    // Providing default message and overriding status code.
    super(`Error updating Stage Table Schema. ${message}`, 'Error')
  }
}
