#!/usr/bin/env node

// NOTE: This file is intentionally written in ES5/6, as it's NOT transpiled
/* eslint-disable import/no-extraneous-dependencies, no-console */

const { argv } = require('yargs');
const { get } = require('delver');
const { green, reset } = require('chalk');
const dotenv = require('dotenv');
const fs = require('fs');
const path = require('path');

const {
  centerText,
  drawInitialNewline,
  getSubdomainPrefix,
  horizontalRule,
} = require('./build/modules/serverless-utils');
const pkg = require('./package.json');

// if this microservice is initiated with an argument named, "STAGE", then that
// value will overwrite the "STAGE" of the app. If no args, it defaults to "int",
// since that's the value in "package.json:config.stage".
const { stage: STAGE = get(pkg, 'config.stage') } = argv;

function success(description = '', information = '') {
  drawInitialNewline();
  centerText(`${description}: ${information}${reset('.')}`);
  horizontalRule();
  return true;
}

function pluralize(count = 0) {
  if (count > 1 || count === 0) return 's';
  return '';
}

module.exports.getAndSetVarsFromEnvFile = (shouldPrint = true) =>
  new Promise((resolve) => {
    const taskDescription = 'Locating ".env" Config File';
    let environmentVariables = {};
    if (fs.existsSync(path.join(__dirname, '.env'))) {
      const { parsed } = dotenv.config();
      environmentVariables = parsed || {};
    } else {
      // in this case, if we don't have any env variables, we don't want to reject;
      // instead, we want to resolve with the db and stage environment variables
      const { DEV_CORE_PG, INT_CORE_PG, PROD_CORE_PG, DEFAULT_DATABASE_PG } = process.env;
      environmentVariables = { DEV_CORE_PG, INT_CORE_PG, PROD_CORE_PG, DEFAULT_DATABASE_PG };
    }

    // CAUTION! - Will remove environment variables that are not the current stage
    const stages = ['dev', 'int', 'prod'];
    const stagesToRemove = stages.filter((s) => s !== STAGE.toLowerCase());

    Object.keys(environmentVariables).forEach((key) => {
      if (
        stagesToRemove.some((stageToRemove) =>
          key.toUpperCase().startsWith(`${stageToRemove.toUpperCase()}_`)
        )
      ) {
        delete environmentVariables[key];
      }
    });

    const envVariableCount = Object.keys(environmentVariables).length;

    const taskSuccessInfo = `Exported ${green(envVariableCount)} Variable${pluralize(
      envVariableCount
    )}`;
    if (shouldPrint) success(taskDescription, taskSuccessInfo);
    resolve(Object.assign({}, environmentVariables, { STAGE }));
  });

module.exports.getStage = (shouldPrint = true) =>
  new Promise((resolve, reject) => {
    const taskDescription = 'Setting API / Service Stage';
    // check for "STAGE" having been set; rejects if not
    if (typeof STAGE === 'undefined' || STAGE == null) {
      reject(new (Error(taskDescription))());
    }
    // print success message(s) and resolve value to caller
    const taskSuccessInfo = `${green(STAGE)}`;
    if (shouldPrint) success(taskDescription, taskSuccessInfo);
    resolve(STAGE);
  });

module.exports.getStageUppercase = (shouldPrint = true) =>
  new Promise((resolve, reject) => {
    const taskDescription = 'Setting API / Service Stage';
    // check for "STAGE" having been set; rejects if not
    if (typeof STAGE === 'undefined' || STAGE == null) {
      reject(new (Error(taskDescription))());
    }
    // print success message(s) and resolve value to caller
    const taskSuccessInfo = `${green(STAGE.toUpperCase())}`;
    if (shouldPrint) success(taskDescription, taskSuccessInfo);
    resolve(STAGE.toUpperCase());
  });

module.exports.getAPIBasePath = (shouldPrint = true) =>
  new Promise((resolve) => {
    const taskDescription = 'Setting API Path';
    const serviceNameFromPackageJSONFile = get(pkg, 'name', 'untitled-project');
    // removes the "service" text at the end, if any!
    const apiBasePath = serviceNameFromPackageJSONFile.replace(/-service/gim, '').trim();
    const taskSuccessInfo = `Path: "${green(`/${apiBasePath}`)}"`;
    if (shouldPrint) success(taskDescription, taskSuccessInfo);
    resolve(apiBasePath);
  });

module.exports.getHostname = (shouldPrint = true) =>
  new Promise((resolve) => {
    const taskDescription = 'Setting API Hostname';
    const hostname = `${getSubdomainPrefix('api', STAGE)}.hixme.com`;
    // the function "getSubdomainPrefix()" will ALWAYS return a value;
    // as such, we only ever need to resolve
    const taskSuccessInfo = `${green(hostname)}`;
    if (shouldPrint) success(taskDescription, taskSuccessInfo);
    resolve(hostname);
  });
