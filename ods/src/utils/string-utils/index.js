import trim from 'lodash/trim'
import isUndefined from 'lodash/isUndefined'

export function IsValidString(str) {
  if (!isUndefined(str)) {
    if (trim(str).length > 0) return true
  }
  return false
}

export function CleanUpString(str, defaultValue) {
  if (!IsValidString(str)) return defaultValue
  return str
}

export function StringLength(str) {
  let retVal = 0
  if (!isUndefined(str)) {
    retVal = trim(str).length
  }
  return retVal
}
