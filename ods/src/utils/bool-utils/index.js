import isBoolean from 'lodash/isBoolean'
import isUndefined from 'lodash/isUndefined'

export function IsValidBoolean(val) {
  if (!isUndefined(val) && isBoolean(val)) {
    return true
  }
  return false
}

export function CleanUpBool(val, defaultValue) {
  if (!IsValidBoolean(val)) return defaultValue
  return val
}
