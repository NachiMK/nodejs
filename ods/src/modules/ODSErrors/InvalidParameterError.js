
module.exports = class InvalidParameterError extends require('../ODSErrors/ODSError') {
    constructor(message) {
        // Providing default message and overriding status code.
        super(message || 'Parameter Values are invalid.', 'Error');
    }
};
