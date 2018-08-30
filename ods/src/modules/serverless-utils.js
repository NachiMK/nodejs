import stripAnsiColors from 'strip-ansi';

const { STAGE } = process.env;
export const isProd = /^prod(?:uction)?$/gim.test(STAGE);
export const getStatus = thing => text => !!thing.match(new RegExp(`^${text}$`, 'i'));
export const isComplete = getStatus('completed');

export const isTrue = value =>
  value && value != null && [true, 'true', 1, '1', 'yes'].includes(value);

export const stripNonAlphaNumericChars = value => `${value}`.replace(/[^\w\s]*/gi, '');

export const isSetToTrue = queryStringIsTrue;
export function queryStringIsTrue(queryString) {
  return isTrue(stripNonAlphaNumericChars(queryString));
}

const logLevel = 'info';

/* eslint-disable no-console */
export function horizontalRule(width = 78, character = '—', shouldConsoleLog = false) {
  if (shouldConsoleLog) {
    return character.repeat(width);
  }
  return console[logLevel](`|${character.repeat(width)}|`);
}
export function newline() { console[logLevel](horizontalRule(1, '', true)); }

export const centerText = centerContent;
export function centerContent(content = '', maxWidth = 78, spacing = Math.floor((maxWidth - stripAnsiColors(content).length) / 2)) {
  const repeatAmount = (maxWidth - (`${horizontalRule(spacing, ' ', true)}${stripAnsiColors(content)}${horizontalRule(spacing, ' ', true)}`).length) < 0 ? 0 : (maxWidth - (`${horizontalRule(spacing, ' ', true)}${stripAnsiColors(content)}${horizontalRule(spacing, ' ', true)}`).length);
  console[logLevel](`|${horizontalRule(spacing, ' ', true)}${content}${horizontalRule(spacing, ' ', true)}${' '.repeat(repeatAmount)}|`);
}

let initialLineHasBeenDrawn = false;
export const drawInitialNewline = () => {
  if (initialLineHasBeenDrawn) {
    return false;
  }

  initialLineHasBeenDrawn = true;
  newline();
  horizontalRule();
  return true;
};

export function getSubdomainPrefix(apiRootName = 'api', stage) {
  if (stage === 'prod') return `${apiRootName}`;
  if (stage === 'int') return `int-${apiRootName}`;
  if (stage === 'dev') return `dev-${apiRootName}`;

  // if none of the above trigger, then return a default of dev"
  centerText('WARNING: Couldn\'t detect STAGE');
  return `dev-${apiRootName}`;
}
