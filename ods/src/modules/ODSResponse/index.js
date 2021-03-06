import moment from 'moment'

const _ = require('lodash')

export async function GetDefaultOdsResponse() {
  return {
    Status: 'Ready',
    error: {},
    StartTime: moment().format('MM/DD/YYYY HH:mm:ss.SSS'),
    EndTime: undefined,
    Input: {},
    // add additional response here as per your needs.
  }
}

export async function SetOdsResponseStatusToSuccess(ODSResponse) {
  if (ODSResponse) {
    ODSResponse.Status = 'Completed'
    ODSResponse.EndTime = moment().format('MM/DD/YYYY HH:mm:ss.SSS')
  }
  return ODSResponse
}

export function IsResponseSuccess(ODSResponse) {
  if (!_.isUndefined(ODSResponse) && !_.isUndefined(ODSResponse.Status)) {
    if (ODSResponse.Status === 'Completed') {
      return true
    }
  }
  return false
}

export async function SetOdsResponseStatusToError(ODSResponse, err) {
  if (ODSResponse) {
    ODSResponse.Status = 'Error'
    ODSResponse.error = !_.isUndefined(err) ? err : 'No Error was provided'
    ODSResponse.EndTime = moment().format('MM/DD/YYYY HH:mm:ss.SSS')
  }
  return ODSResponse
}

export async function SetOdsResponseStatusToProcessing(ODSResponse) {
  if (ODSResponse) {
    ODSResponse.Status = 'Processing'
  }
  return ODSResponse
}

export async function SetOdsResponseStatusEndTime(ODSResponse) {
  if (ODSResponse) {
    ODSResponse.EndTime = moment().format('MM/DD/YYYY HH:mm:ss.SSS')
  }
  return ODSResponse
}
