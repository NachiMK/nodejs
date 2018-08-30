'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.drawInitialNewline = exports.centerText = exports.isSetToTrue = exports.stripNonAlphaNumericChars = exports.isTrue = exports.isComplete = exports.getStatus = exports.isProd = undefined;
exports.queryStringIsTrue = queryStringIsTrue;
exports.horizontalRule = horizontalRule;
exports.newline = newline;
exports.centerContent = centerContent;
exports.getSubdomainPrefix = getSubdomainPrefix;

var _stripAnsi = require('strip-ansi');

var _stripAnsi2 = _interopRequireDefault(_stripAnsi);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

const { STAGE } = process.env;
const isProd = exports.isProd = /^prod(?:uction)?$/gim.test(STAGE);
const getStatus = exports.getStatus = thing => text => !!thing.match(new RegExp(`^${text}$`, 'i'));
const isComplete = exports.isComplete = getStatus('completed');

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
//# sourceMappingURL=serverless-utils.js.map