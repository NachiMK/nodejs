import {
  addArray,
  addBool,
  addDate,
  addDateTime,
  addInteger,
  addDecimal,
  addObject,
  addString,
  addText,
} from './table'

export const JsonToKnexDataTypeEnum = {
  number: {
    Value: 10,
    knexType: 'decimal',
    opts: { precision: 22, scale: 8 },
    AddColFunction: addDecimal,
  },
  integer: { Value: 20, knexType: 'integer', AddColFunction: addInteger },
  string: { Value: 30, knexType: 'string', opts: { length: 510 }, AddColFunction: addString },
  text: { Value: 40, knexType: 'text', AddColFunction: addText },
  object: { Value: 50, knexType: 'jsonb', AddColFunction: addObject },
  array: { Value: 60, knexType: 'jsonb', AddColFunction: addArray },
  bool: { Value: 70, knexType: 'boolean', AddColFunction: addBool },
  date: { Value: 80, knexType: 'timestamp', AddColFunction: addDate },
  datetime: { Value: 90, knexType: 'timestamp', AddColFunction: addDateTime },
}
