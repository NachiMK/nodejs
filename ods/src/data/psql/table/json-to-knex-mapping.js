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
} from './knexAddColumn'

export const JsonToKnexDataTypeEnum = {
  number: {
    Value: 10,
    knexType: 'decimal',
    opts: { precision: 22, scale: 8 },
    AddColFunction: addDecimal,
    postgresType: 'decimal',
  },
  integer: { Value: 20, knexType: 'integer', AddColFunction: addInteger, postgresType: 'int' },
  string: {
    Value: 30,
    knexType: 'string',
    opts: { length: 512 },
    AddColFunction: addString,
    postgresType: 'character varying',
  },
  text: { Value: 40, knexType: 'text', AddColFunction: addText, postgresType: 'text' },
  object: { Value: 50, knexType: 'jsonb', AddColFunction: addObject, postgresType: 'jsonb' },
  array: { Value: 60, knexType: 'jsonb', AddColFunction: addArray, postgresType: 'jsonb' },
  boolean: { Value: 70, knexType: 'boolean', AddColFunction: addBool, postgresType: 'boolean' },
  bool: { Value: 70, knexType: 'boolean', AddColFunction: addBool, postgresType: 'boolean' },
  date: { Value: 80, knexType: 'timestamp', AddColFunction: addDate, postgresType: 'timestamp' },
  datetime: {
    Value: 90,
    knexType: 'timestamp',
    AddColFunction: addDateTime,
    postgresType: 'timestamptz',
  },
}
