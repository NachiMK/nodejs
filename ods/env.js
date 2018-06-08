// eslint-disable-next-line import/no-extraneous-dependencies
const dotenv = require('dotenv');
const fs = require('fs');
const PATH = require('path');
// eslint-disable-next-line import/no-extraneous-dependencies
const { argv } = require('yargs');

const pkg = require('./package.json');

const DEFAULT_STAGE = pkg.config.stage;

const { stage = DEFAULT_STAGE } = argv;

module.exports.default = () => new Promise((resolve, reject) => {
  fs.readFile(PATH.join(__dirname, '.env'), (err, data) => {
    if (err) return reject(err);
    const envVars = dotenv.parse(data);

    // remove vars not related to the current STAGE.
    // the expectation is all env variables
    // begins with the stage name if not this will
    // delete all env variables !!!! CAUTION 
    Object.keys(envVars).forEach((key) => {
      if (!key.toUpperCase().startsWith(`${stage.toUpperCase()}_`)) {
        delete envVars[key];
      }
    });

    return resolve(Object.assign({}, envVars, { STAGE: stage }));
  });
});

module.exports.getDomainName = () => new Promise((resolve, reject) => {
  if (!stage || stage == null || stage.toLowerCase() === 'dev') {
    return resolve('dev-api.hixme.com');
  }

  if (stage.toLowerCase() === 'int') {
    return resolve('int-api.hixme.com');
  }

  if (stage.toLowerCase() === 'prod') {
    return resolve('api.hixme.com');
  }

  return reject();
});

module.exports.getAPIBasePath = () => new Promise((resolve, reject) => {
  // eslint-disable-next-line global-require
  const existingServiceName = require('./package.json').name;
  const apiServiceName = existingServiceName.replace(/-service/, '').trim();

  if (!apiServiceName || apiServiceName == null) {
    return reject();
  }

  return resolve(apiServiceName);
});
