//@ts-check
import isUndefined from 'lodash/isUndefined'
import { isNumber } from 'util'
import {
  addSmallInt,
  addBool,
  addDate,
  addDateTime,
  addInteger,
  addDecimal,
  addObject,
  addString,
  addText,
  addBigInteger,
  addReal,
  addNumeric,
  addDouble,
  addJson,
  addSerial,
  addBigSerial,
  addTime,
  addTimeStampTz,
  addArray,
} from './table/knexAddColumn'

export const FallBackTypeEnum = {
  'character varying': {
    DataLength: 512,
    precision: -1,
    scale: -1,
    postgresType: 'character varying',
  },
  numeric: {
    DataLength: -1,
    precision: 22,
    scale: 8,
    postgresType: 'numeric',
  },
}

/**
 * @enum DataTypeTransferEnum
 * @description : This enum defines all supported postgres
 * data types, and which type can be converted to what higer types
 * If higher types are supported and needs some minimum length
 * then it is defined as well.
 */
export const DataTypeTransferEnum = {
  int: {
    HigherTypes: ['bigint', 'real', 'double precision', 'numeric'],
    FallbackHigherType: FallBackTypeEnum['character varying'],
    numeric: {
      precision: 32,
      scale: 0,
    },
    AddColFunction: addInteger,
    postgresType: 'int',
  },
  smallint: {
    HigherTypes: ['int', 'bigint', 'real', 'double precision', 'numeric'],
    FallbackHigherType: FallBackTypeEnum['character varying'],
    numeric: {
      precision: 16,
      scale: 0,
    },
    AddColFunction: addSmallInt,
    postgresType: 'smallint',
  },
  bigint: {
    HigherTypes: ['numeric'],
    FallbackHigherType: FallBackTypeEnum['character varying'],
    numeric: {
      precision: 64,
      scale: 0,
    },
    AddColFunction: addBigInteger,
    postgresType: 'bigint',
  },
  smallserial: {
    HigherTypes: ['numeric', 'serial', 'bigserail', 'int', 'bigint'],
    FallbackHigherType: FallBackTypeEnum['character varying'],
    numeric: {
      precision: 10,
      scale: 0,
    },
    AddColFunction: addSerial,
    postgresType: 'smallserial',
  },
  serial: {
    HigherTypes: ['bigserail', 'int', 'bigint', 'numeric'],
    FallbackHigherType: FallBackTypeEnum['character varying'],
    numeric: {
      precision: 32,
      scale: 0,
    },
    AddColFunction: addSerial,
    postgresType: 'serial',
  },
  bigserial: {
    HigherTypes: ['numeric', 'bigint'],
    FallbackHigherType: FallBackTypeEnum['character varying'],
    numeric: {
      precision: 64,
      scale: 0,
    },
    AddColFunction: addBigSerial,
    postgresType: 'bigserial',
  },
  real: {
    HigherTypes: ['double precision', 'float8', 'numeric'],
    FallbackHigherType: FallBackTypeEnum['character varying'],
    numeric: {
      precision: 24,
      scale: 6,
    },
    AddColFunction: addReal,
    postgresType: 'real',
  },
  'double precision': {
    HigherTypes: ['numeric', 'decimal'],
    FallbackHigherType: FallBackTypeEnum['character varying'],
    numeric: {
      precision: 53,
      scale: 15,
    },
    AddColFunction: addDouble,
    postgresType: 'double precision',
  },
  numeric: {
    HigherTypes: ['numeric', 'decimal'],
    FallbackHigherType: FallBackTypeEnum['character varying'],
    AddColFunction: addNumeric,
    postgresType: 'numeric',
  },
  decimal: {
    HigherTypes: ['decimal', 'numeric'],
    FallbackHigherType: FallBackTypeEnum['character varying'],
    AddColFunction: addDecimal,
    postgresType: 'decimal',
  },
  date: {
    HigherTypes: ['timestamptz', 'datetime', 'timestamp', 'character varying'],
    FallbackHigherType: FallBackTypeEnum['character varying'],
    'character varying': {
      DataLength: 12,
    },
    AddColFunction: addDate,
    postgresType: 'date',
  },
  timestamp: {
    HigherTypes: ['timestamptz', 'character varying'],
    FallbackHigherType: FallBackTypeEnum['character varying'],
    'character varying': {
      DataLength: 29,
    },
    AddColFunction: addDateTime,
    postgresType: 'timestamp',
  },
  'timestamp without time zone': {
    HigherTypes: ['timestamptz', 'character varying'],
    FallbackHigherType: FallBackTypeEnum['character varying'],
    'character varying': {
      DataLength: 29,
    },
    AddColFunction: addDateTime,
    postgresType: 'timestamp',
  },
  timestamptz: {
    HigherTypes: ['character varying'],
    FallbackHigherType: FallBackTypeEnum['character varying'],
    'character varying': {
      DataLength: 29,
    },
    AddColFunction: addTimeStampTz,
    postgresType: 'timestamptz',
  },
  'timestamp with time zone': {
    HigherTypes: ['character varying'],
    FallbackHigherType: FallBackTypeEnum['character varying'],
    'character varying': {
      DataLength: 30,
    },
    AddColFunction: addTimeStampTz,
    postgresType: 'timestamptz',
  },
  time: {
    HigherTypes: ['timestamp', 'timestamptz', 'character varying'],
    FallbackHigherType: FallBackTypeEnum['character varying'],
    'character varying': {
      DataLength: 10,
    },
    AddColFunction: addTime,
    postgresType: 'time',
  },
  char: {
    HigherTypes: ['text', 'character varying'],
    AllowHigerLength: true,
    FallbackHigherType: FallBackTypeEnum['character varying'],
    AddColFunction: addString,
    'character varying': {
      DataLength: 256,
    },
    postgresType: 'char',
  },
  character: {
    HigherTypes: ['text', 'character varying'],
    AllowHigerLength: true,
    FallbackHigherType: FallBackTypeEnum['character varying'],
    AddColFunction: addString,
    'character varying': {
      DataLength: 256,
    },
    postgresType: 'char',
  },
  text: {
    HigherTypes: ['text'],
    AllowHigerLength: true,
    FallbackHigherType: FallBackTypeEnum['character varying'],
    AddColFunction: addText,
    postgresType: 'text',
  },
  varchar: {
    HigherTypes: ['text', 'character varying'],
    AllowHigerLength: true,
    FallbackHigherType: FallBackTypeEnum['character varying'],
    AddColFunction: addString,
    'character varying': {
      DataLength: 512,
    },
    postgresType: 'character varying',
  },
  'character varying': {
    HigherTypes: ['text', 'character varying'],
    AllowHigerLength: true,
    FallbackHigherType: FallBackTypeEnum['character varying'],
    AddColFunction: addString,
    'character varying': {
      DataLength: 512,
    },
    postgresType: 'character varying',
  },
  integer: {
    HigherTypes: ['bigint', 'real', 'double precision', 'numeric'],
    FallbackHigherType: FallBackTypeEnum['character varying'],
    numeric: {
      precision: 32,
      scale: 0,
    },
    AddColFunction: addInteger,
    postgresType: 'int',
  },
  datetime: {
    HigherTypes: ['character varying'],
    FallbackHigherType: FallBackTypeEnum['character varying'],
    'character varying': {
      DataLength: 29,
    },
    AddColFunction: addTimeStampTz,
    postgresType: 'timestamptz',
  },
  boolean: {
    HigherTypes: ['bool', 'character varying', 'smallint'],
    FallbackHigherType: FallBackTypeEnum['character varying'],
    'character varying': {
      DataLength: 5,
    },
    AddColFunction: addBool,
    postgresType: 'boolean',
  },
  bool: {
    HigherTypes: ['bool', 'character varying', 'smallint'],
    FallbackHigherType: FallBackTypeEnum['character varying'],
    'character varying': {
      DataLength: 5,
    },
    AddColFunction: addBool,
    postgresType: 'bool',
  },
  json: {
    HigherTypes: ['json', 'text'],
    FallbackHigherType: 'text',
    AddColFunction: addJson,
    postgresType: 'json',
  },
  jsonb: {
    HigherTypes: ['jsonb', 'text'],
    FallbackHigherType: 'text',
    AddColFunction: addObject,
    postgresType: 'jsonb',
  },
}

export const JsonPostgreTypeMappingEnum = {
  number: {
    Value: 10,
    postgres: {
      dataType: 'decimal',
      defaultPrecision: 22,
      defaultScale: 8,
    },
  },
  integer: {
    Value: 20,
    postgres: {
      dataType: 'int',
    },
  },
  string: {
    Value: 30,
    postgres: {
      dataType: 'character varying',
      defaultLength: 512,
    },
  },
  text: {
    Value: 40,
    postgres: {
      dataType: 'text',
    },
  },
  object: {
    Value: 50,
    postgres: {
      dataType: 'jsonb',
    },
  },
  array: {
    Value: 60,
    postgres: {
      dataType: 'jsonb',
    },
  },
  boolean: {
    Value: 70,
    postgres: {
      dataType: 'boolean',
    },
  },
  bool: {
    Value: 70,
    postgres: {
      dataType: 'boolean',
    },
  },
  date: {
    Value: 80,
    postgres: {
      dataType: 'datetime',
    },
  },
  datetime: {
    Value: 90,
    postgres: {
      dataType: 'timestamptz',
    },
  },
}

export function IsValidTypeObject(objToValidate) {
  let blnValid = false
  if (!isUndefined(objToValidate)) {
    if (
      !isUndefined(objToValidate.DataType) &&
      !isUndefined(objToValidate.DataLength) &&
      !isUndefined(objToValidate.precision) &&
      !isUndefined(objToValidate.scale)
    ) {
      blnValid = true
    }
  }
  return blnValid
}

/**
 *
 * @function AllowCast
 *
 * @param {object} existingType
 * @param {object} changeToType
 *
 * existingType/ChangType should be of this format:
 * "ColumnName" : {
 *    "Position": 1,      // position of column -- doesnt matter
 *    "IsNullable": true, // This function doesn't check for it.
 *    "DataType": "int",  // could be postgres data types, No Object/Array
 *    "DataLength" : 10,      // applicable only for string/similar types
 *    "precision": 10,    // applicable only for numeric/decimal types
 *    "scale": 2          // applicable only for numeric/decimal types
 *    "datetimePrecision": -1 // mostly -1 because we dont know the time precision
 *  }
 *
 * @returns { object } :
 * {
 *  AllowTypeChange: true/false - True if Data type can be changed
 *  AllowLengthChange : true/false -- True if new length is higer then old length
 *  AllowPrecisoinChange: true/false -- True if both Precision/Scale can be changed
 * }
 *
 * @throws InvalidParamError/TypeNotFoundError
 */
export function AllowCast(existingType, changeToType) {
  let output = {
    AllowTypeChange: false,
    AllowLengthChange: false,
    AllowPrecisionChange: false,
    FallbackToHigherType: false,
  }
  if (IsValidTypeObject(existingType) && IsValidTypeObject(changeToType)) {
    const dtExisting = existingType.DataType
    const dtNew = changeToType.DataType
    // different data type
    if (dtExisting !== dtNew) {
      // compatible types?
      // first check if we know the source type
      if (isUndefined(DataTypeTransferEnum[dtExisting])) {
        throw new Error(`DataTypeTransferEnum doesn't have defintion for DataType: ${dtExisting}`)
      } else if (DataTypeTransferEnum[dtExisting].HigherTypes.includes(dtNew)) {
        // allow type change
        output.AllowTypeChange = true
      } else {
        output.FallbackToHigherType = true
      }
    } else {
      // data type is same but length is different
      // higher length
      if (existingType.DataLength < changeToType.DataLength) {
        // allow length change
        output.AllowLengthChange = true
      } else if (
        // data type is same but precision or scale is different
        existingType.precision < changeToType.precision &&
        existingType.scale < changeToType.scale
      ) {
        // allow precision change
        output.AllowPrecisionChange = true
      }
    }
  } else {
    throw new Error(`Both Source and Target should be of Valid Objects.`)
  }
  return output
}

export function GetNewLength(oldType, newType) {
  // get old length
  const oldDataLength = isNumber(oldType.DataLength) ? oldType.DataLength : 0
  const newDataLength = isNumber(newType.DataLength) ? newType.DataLength : 0
  const enumLength =
    !isUndefined(DataTypeTransferEnum[oldType.DataType][newType.DataType]) &&
    DataTypeTransferEnum[oldType.DataType][newType.DataType].DataLength
      ? DataTypeTransferEnum[oldType.DataType][newType.DataType].DataLength
      : -1
  return Math.max(oldDataLength, newDataLength, enumLength)
}

export function GetNewPrecision(oldType, newType) {
  const retPrec = { precision: -1, scale: -1 }

  const oldTypePrec = !isUndefined(oldType.precision) ? oldType.precision : -1
  const newTypePrec = !isUndefined(newType.precision) ? newType.precision : -1
  const higherType = DataTypeTransferEnum[oldType.DataType][newType.DataType]
  const higherTypePrec =
    !isUndefined(higherType) && !isUndefined(higherType.precision) ? higherType.precision : -1

  if (oldTypePrec > newTypePrec) {
    if (oldTypePrec >= higherTypePrec) {
      retPrec.precision = oldTypePrec
      retPrec.scale = oldType.scale ? oldType.scale : 0
    } else {
      retPrec.precision = higherTypePrec
      retPrec.scale = higherType.scale ? higherType.scale : 0
    }
  } else {
    if (newTypePrec >= higherTypePrec) {
      retPrec.precision = newTypePrec
      retPrec.scale = newType.scale ? newType.scale : 0
    } else {
      retPrec.precision = higherTypePrec
      retPrec.scale = higherType.scale ? higherType.scale : 0
    }
  }

  return retPrec
}

export function GetNewType(existingType, changeToType) {
  let retNewType = {}
  Object.assign(retNewType, existingType)
  // check if we can change type
  const allowChange = AllowCast(existingType, changeToType)
  if (allowChange.AllowTypeChange) {
    // change old type to new type
    retNewType.DataType = changeToType.DataType
    // set length to appropriate values if type changed
    retNewType.DataLength = GetNewLength(existingType, changeToType)
    // set precision and scale
    const prec = GetNewPrecision(existingType, changeToType)
    retNewType.precision = prec.precision
    retNewType.scale = prec.scale
  } else if (allowChange.AllowLengthChange) {
    // update length
    retNewType.DataLength = changeToType.DataLength
  } else if (allowChange.AllowPrecisionChange) {
    // update precision
    retNewType.precision = changeToType.precision
    retNewType.scale = changeToType.scale
  } else if (allowChange.FallbackToHigherType) {
    // new type is not compatible with old type.
    // fall back to varchar??
    retNewType.DataType =
      DataTypeTransferEnum[existingType.DataType].FallbackHigherType.postgresType
    // set length to fall back types default length
    retNewType.DataLength =
      DataTypeTransferEnum[existingType.DataType][retNewType.DataType].DataLength || -1
    retNewType.precision =
      DataTypeTransferEnum[existingType.DataType][retNewType.DataType].precision || -1
    retNewType.scale = DataTypeTransferEnum[existingType.DataType][retNewType.DataType].scale || -1
  } else {
    return {}
  }
  // return it
  return retNewType
}
