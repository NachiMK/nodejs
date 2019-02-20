import { format as _format, transports as _transports, createLogger } from 'winston';

const logger = createLogger({
  format: _format.combine(
    _format.timestamp({
      format: 'YYYY-MM-DD HH:mm:ss',
    }),
    _format.splat(),
    _format.prettyPrint()
  ),
});

// reference of this is in relates to the code being inside a class defintion.
// Please modify to what works for you
const consoleTransport = new _transports.Console();
consoleTransport.level = process && process.env ? process.env.LogLevel || 'warn' : 'warn'; // This is the parameter
logger.add(consoleTransport);

export const Logger = logger;

export function LogMsg(message, level = 'info') {
  logger.log(level, message);
}
