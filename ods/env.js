#!/usr/bin/env node

// NOTE: This file is intentionally written in ES5/6, as it's NOT transpiled
/* eslint-disable import/no-extraneous-dependencies, no-console */

const { argv } = require('yargs')
const { get } = require('delver')
const { green, reset } = require('chalk')
const dotenv = require('dotenv')

const {
  centerText,
  drawInitialNewline,
  getSubdomainPrefix,
  horizontalRule,
} = require('./lib/modules/serverless-utils')
const pkg = require('./package.json')

// if this microservice is initiated with an argument named, "STAGE", then that
// value will overwrite the "STAGE" of the app. If no args, it defaults to "int",
// since that's the value in "package.json:config.stage".
const { stage: STAGE = get(pkg, 'config.stage') } = argv

function success(description = '', information = '') {
  drawInitialNewline()
  centerText(`${description}: ${information}${reset('.')}`)
  horizontalRule()
  return true
}

function pluralize(count = 0) {
  if (count > 1 || count === 0) return 's'
  return ''
}

module.exports.getAndSetVarsFromEnvFile = (shouldPrint = true) =>
  new Promise((resolve) => {
    const taskDescription = 'Locating ".env" Config File'
    const { parsed: environmentVariables = {} } = dotenv.config()
    const envVariableCount = Object.keys(environmentVariables).length
    // in this case, if we don't have any env variables, we don't want to reject;
    // instead, we want to resolve with a single environment variable: "STAGE"
    const taskSuccessInfo = `Exported ${green(envVariableCount)} Variable${pluralize(
      envVariableCount
    )}`
    if (shouldPrint) success(taskDescription, taskSuccessInfo)
    // remove vars not related to the current STAGE.
    // the expectation is all env variables
    // begins with the stage name if not this will
    // delete all env variables !!!! CAUTION
    Object.keys(environmentVariables).forEach((key) => {
      if (!key.toUpperCase().startsWith(`${STAGE.toUpperCase()}_`)) {
        if (shouldPrint) success('removed var', key)
        delete environmentVariables[key]
      }
    })
    resolve(Object.assign({}, environmentVariables, { STAGE }))
  })

module.exports.getStage = (shouldPrint = true) =>
  new Promise((resolve, reject) => {
    const taskDescription = 'Setting API / Service Stage'
    // check for "STAGE" having been set; rejects if not
    if (typeof STAGE === 'undefined' || STAGE == null) reject(new (Error(taskDescription))())
    // print success message(s) and resolve value to caller
    const taskSuccessInfo = `${green(STAGE)}`
    if (shouldPrint) success(taskDescription, taskSuccessInfo)
    resolve(STAGE)
  })

module.exports.getStageUppercase = (shouldPrint = true) =>
  new Promise((resolve, reject) => {
    const taskDescription = 'Setting API / Service Stage'
    // check for "STAGE" having been set; rejects if not
    if (typeof STAGE === 'undefined' || STAGE == null) reject(new (Error(taskDescription))())
    // print success message(s) and resolve value to caller
    const taskSuccessInfo = `${green(STAGE.toUpperCase())}`
    if (shouldPrint) success(taskDescription, taskSuccessInfo)
    resolve(STAGE.toUpperCase())
  })

module.exports.getAPIBasePath = (shouldPrint = true) =>
  new Promise((resolve) => {
    const taskDescription = 'Setting API Path'
    const serviceNameFromPackageJSONFile = get(pkg, 'name', 'untitled-project')
    // removes the "service" text at the end, if any!
    const apiBasePath = serviceNameFromPackageJSONFile.replace(/-service/gim, '').trim()
    const taskSuccessInfo = `Path: "${green(`/${apiBasePath}`)}"`
    if (shouldPrint) success(taskDescription, taskSuccessInfo)
    resolve(apiBasePath)
  })

module.exports.getHostname = (shouldPrint = true) =>
  new Promise((resolve) => {
    const taskDescription = 'Setting API Hostname'
    const hostname = `${getSubdomainPrefix('api', STAGE)}.hixme.com`
    // the function "getSubdomainPrefix()" will ALWAYS return a value;
    // as such, we only ever need to resolve
    const taskSuccessInfo = `${green(hostname)}`
    if (shouldPrint) success(taskDescription, taskSuccessInfo)
    resolve(hostname)
  })
