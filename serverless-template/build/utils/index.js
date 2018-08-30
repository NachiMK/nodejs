'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.drawInitialNewline = exports.centerText = exports.isSetToTrue = exports.stripNonAlphaNumericChars = exports.isTrue = exports.after = exports.before = exports.isComplete = exports.getStatus = exports.isProd = undefined;

var _extends2 = require('babel-runtime/helpers/extends');

var _extends3 = _interopRequireDefault(_extends2);

exports.queryStringIsTrue = queryStringIsTrue;
exports.horizontalRule = horizontalRule;
exports.newline = newline;
exports.centerContent = centerContent;
exports.getSubdomainPrefix = getSubdomainPrefix;

var _lodash = require('lodash');

var _circularJson = require('circular-json');

var _circularJson2 = _interopRequireDefault(_circularJson);

var _http = require('http');

var _http2 = _interopRequireDefault(_http);

var _stripAnsi = require('strip-ansi');

var _stripAnsi2 = _interopRequireDefault(_stripAnsi);

var _warewolf = require('warewolf');

var _warewolf2 = _interopRequireDefault(_warewolf);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

const { STAGE } = process.env;
const isProd = exports.isProd = /^prod(?:uction)?$/gim.test(STAGE);
const getStatus = exports.getStatus = thing => text => !!thing.match(new RegExp(`^${text}$`, 'i'));
const isComplete = exports.isComplete = getStatus('completed');

const defaultResponseConfig = {
  headers: {
    'Access-Control-Allow-Credentials': true,
    'Access-Control-Allow-Origin': '*',
    'Content-Type': 'text/html;charset=utf-8'
  },
  isBase64Encoded: false,
  statusCode: 200
};

function responseController(getResults = ({ result }) => {
  switch (typeof result) {
    case 'string':
      return { result };
    case 'object':
      return Array.isArray(result) ? [...result] : (0, _extends3.default)({}, result);
    case 'undefined':
      return {};
    default:
      return (0, _extends3.default)({}, result);
  }
}) {
  return (event, context, done) => {
    const result = getResults(event);
    const response = (0, _extends3.default)({}, defaultResponseConfig, event, {
      headers: (0, _extends3.default)({}, defaultResponseConfig.headers, event.headers),
      body: Array.isArray(result) ? _circularJson2.default.stringify([...result]) : _circularJson2.default.stringify((0, _extends3.default)({}, result))
    });
    done(null, response);
  };
}

const errorHandler = (error, event, context, done) => {
  if ((0, _lodash.isError)(error)) {
    const { statusCode, type, message } = getFormattedError(error, event);
    const isInDebugMode = /^\*$/.test(process.env.SLS_DEBUG);
    const isDevOrInt = /^(?:int|dev)$/i.test(process.env.STAGE);
    const shouldPrintStack = isInDebugMode && isDevOrInt;

    const stack = shouldPrintStack ? error.stack : undefined;

    done(null, (0, _extends3.default)({}, defaultResponseConfig, {
      headers: (0, _extends3.default)({}, defaultResponseConfig.headers),
      statusCode,
      body: JSON.stringify({
        status: statusCode,
        type,
        message,
        stack
      })
    }));
    return;
  }
  done();
};

function getFormattedError(error = {}, event = {}) {
  let { statusCode = 500 } = event;
  if (error.statusCode) {
    ({ statusCode } = error);
  }
  if (Number.isInteger(error)) {
    statusCode = error;
  }
  statusCode = Number.parseInt(statusCode, 10);
  const type = _http2.default.STATUS_CODES[statusCode] || 'An Error Has Occurred';
  const message = error.message ? error.message : `${statusCode}: ${type}`;

  return { statusCode, type, message };
}

const before = exports.before = (0, _warewolf2.default)(async (event = {}) => {
  const {
    body = {},
    pathParameters = {},
    query = {},
    queryStringParameters = {}
  } = event;

  event.stage = process.env.STAGE;
  event.params = (0, _extends3.default)({}, queryStringParameters, pathParameters, query);
  event.body = (0, _lodash.isString)(body) ? JSON.parse(body) : body;
});

const after = exports.after = (0, _warewolf2.default)(async event => {
  event.body = event.result || event.results || {};
}, responseController(), errorHandler);

const isTrue = exports.isTrue = value => value && value != null && [true, 'true', 1, '1', 'yes'].includes(value);

const stripNonAlphaNumericChars = exports.stripNonAlphaNumericChars = value => `${value}`.replace(/[^\w\s]*/gi, '');

const isSetToTrue = exports.isSetToTrue = queryStringIsTrue;
function queryStringIsTrue(queryString) {
  return isTrue(stripNonAlphaNumericChars(queryString));
}

const logLevel = 'info';

function horizontalRule(width = 78, character = '—', shouldConsoleLog = false) {
  if (shouldConsoleLog) {
    return character.repeat(width);
  }
  return console[logLevel](`|${character.repeat(width)}|`);
}
function newline() {
  console[logLevel](horizontalRule(1, '', true));
}

const centerText = exports.centerText = centerContent;
function centerContent(content = '', maxWidth = 78, spacing = Math.floor((maxWidth - (0, _stripAnsi2.default)(content).length) / 2)) {
  const repeatAmount = maxWidth - `${horizontalRule(spacing, ' ', true)}${(0, _stripAnsi2.default)(content)}${horizontalRule(spacing, ' ', true)}`.length < 0 ? 0 : maxWidth - `${horizontalRule(spacing, ' ', true)}${(0, _stripAnsi2.default)(content)}${horizontalRule(spacing, ' ', true)}`.length;
  console[logLevel](`|${horizontalRule(spacing, ' ', true)}${content}${horizontalRule(spacing, ' ', true)}${' '.repeat(repeatAmount)}|`);
}

let initialLineHasBeenDrawn = false;
const drawInitialNewline = exports.drawInitialNewline = () => {
  if (initialLineHasBeenDrawn) {
    return false;
  }

  initialLineHasBeenDrawn = true;
  newline();
  horizontalRule();
  return true;
};

function getSubdomainPrefix(apiRootName = 'api', stage) {
  if (stage === 'prod') return `${apiRootName}`;
  if (stage === 'int') return `int-${apiRootName}`;
  if (stage === 'dev') return `dev-${apiRootName}`;

  centerText('WARNING: Couldn\'t detect STAGE');
  return `dev-${apiRootName}`;
}
//# sourceMappingURL=index.js.map