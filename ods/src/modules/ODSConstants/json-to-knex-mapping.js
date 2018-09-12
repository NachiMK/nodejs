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
} from '../../data/psql/table'

export const JsonToKnexDataTypeEnum = {
  number: { Value: 10, knexType: 'decimal', opts: { precision: 22, scale: 8 }, dbFunc: addDecimal },
  integer: { Value: 20, knexType: 'integer', dbFunc: addInteger },
  string: { Value: 30, knexType: 'string', opts: { length: 510 }, dbFunc: addString },
  text: { Value: 40, knexType: 'text', dbFunc: addText },
  object: { Value: 50, knexType: 'jsonb', dbFunc: addObject },
  array: { Value: 60, knexType: 'jsonb', dbFunc: addArray },
  bool: { Value: 70, knexType: 'boolean', dbFunc: addBool },
  date: { Value: 80, knexType: 'timestamp', dbFunc: addDate },
  datetime: { Value: 90, knexType: 'timestamp', dbFunc: addDateTime },
}
