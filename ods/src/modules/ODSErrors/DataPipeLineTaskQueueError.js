
export class CreatingDataPipeLineTaskError extends require('../ODSErrors/ODSError') {
    constructor(message) {
        // Providing default message and overriding status code.
        super('Error Creating DataPipeLineTaskQueue Entry in database.' || message, 'Error');
    }
};
