'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.Logger = undefined;
exports.LogMsg = LogMsg;

var _winston = require('winston');

const logger = (0, _winston.createLogger)({
  format: _winston.format.combine(_winston.format.timestamp({
    format: 'YYYY-MM-DD HH:mm:ss'
  }), _winston.format.splat(), _winston.format.prettyPrint())
});

const consoleTransport = new _winston.transports.Console();
consoleTransport.level = process && process.env ? process.env.LogLevel || 'warn' : 'warn';
logger.add(consoleTransport);

const Logger = exports.Logger = logger;

function LogMsg(message, level = 'info') {
  logger.log(level, message);
}
//# sourceMappingURL=logger.js.map