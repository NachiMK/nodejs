import { format as _format, transports as _transports, createLogger } from 'winston'

const odsLogger = createLogger({
  format: _format.combine(
    _format.timestamp({
      format: 'YYYY-MM-DD HH:mm:ss',
    }),
    _format.splat(),
    _format.prettyPrint()
  ),
  transports: [
    new _transports.Console({
      level: process.env.odsloglevel,
    }),
  ],
})

export default odsLogger

/*
const winston = require('winston');
const moment = require('moment');

// create formatter for dates used as timestamps
//const tsFormat = () => (new Date()).toLocaleTimeString();
const tsFormat = () => moment().format('YYYY-MM-DD hh:mm:ss').trim();

// define a logger with 2 transports - console and a file
const logger = new (winston.Logger)({
  transports: [
    // colorize the output to the console
    new (winston.transports.Console)({
      timestamp: tsFormat,
      colorize: true
    }),
    new winston.transports.File({
      filename: './logs/ttracker.log',
      timestamp: tsFormat,// makes timestamp 'pretty'
      json: false,// makes log format just like console output
  })
  ]
});

// set logging level one of { error: 0, warn: 1, info: 2, verbose: 3, debug: 4, silly: 5 }
logger.level = 'debug';

module.exports = logger;
*/
