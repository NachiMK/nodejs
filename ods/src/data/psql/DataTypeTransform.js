//@ts-check
import isUndefined from 'lodash/isUndefined'
import { isNumber } from 'util'

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
 * @description : This enum defines all supported postgres
 * data types, and which type can be converted to what higer types
 * If higher types are supported and needs some minimum length
 * then it is defined as well.
 */
export const DataTypeTransferEnum = {
  int: {
    HigherTypes: ['bigint', 'real', 'double precision', 'numeric', 'integer'],
    FallbackHigherType: FallBackTypeEnum['character varying'],
    numeric: {
      precision: 32,
      scale: 0,
    },
    postgresType: 'int',
  },
  smallint: {
    HigherTypes: ['int', 'bigint', 'real', 'double precision', 'numeric'],
    FallbackHigherType: FallBackTypeEnum['character varying'],
    numeric: {
      precision: 16,
      scale: 0,
    },
    postgresType: 'smallint',
  },
  bigint: {
    HigherTypes: ['numeric'],
    FallbackHigherType: FallBackTypeEnum['character varying'],
    numeric: {
      precision: 64,
      scale: 0,
    },
    postgresType: 'bigint',
  },
  smallserial: {
    HigherTypes: ['numeric', 'serial', 'bigserail', 'int', 'bigint'],
    FallbackHigherType: FallBackTypeEnum['character varying'],
    numeric: {
      precision: 10,
      scale: 0,
    },
    postgresType: 'smallserial',
  },
  serial: {
    HigherTypes: ['bigserail', 'int', 'bigint', 'numeric'],
    FallbackHigherType: FallBackTypeEnum['character varying'],
    numeric: {
      precision: 32,
      scale: 0,
    },
    postgresType: 'serial',
  },
  bigserial: {
    HigherTypes: ['numeric', 'bigint'],
    FallbackHigherType: FallBackTypeEnum['character varying'],
    numeric: {
      precision: 64,
      scale: 0,
    },
    postgresType: 'bigserial',
  },
  real: {
    HigherTypes: ['double precision', 'float8', 'numeric'],
    FallbackHigherType: FallBackTypeEnum['character varying'],
    numeric: {
      precision: 24,
      scale: 6,
    },
    postgresType: 'real',
  },
  'double precision': {
    HigherTypes: ['numeric', 'decimal'],
    FallbackHigherType: FallBackTypeEnum['character varying'],
    numeric: {
      precision: 53,
      scale: 15,
    },
    postgresType: 'double precision',
  },
  numeric: {
    HigherTypes: ['numeric', 'decimal'],
    FallbackHigherType: FallBackTypeEnum['character varying'],
    postgresType: 'numeric',
  },
  decimal: {
    HigherTypes: ['decimal', 'numeric'],
    FallbackHigherType: FallBackTypeEnum['character varying'],
    postgresType: 'decimal',
  },
  date: {
    HigherTypes: [
      'timestamptz',
      'datetime',
      'timestamp',
      'character varying',
      'timestamp without time zone',
      'timestamp with time zone',
    ],
    FallbackHigherType: FallBackTypeEnum['character varying'],
    'character varying': {
      DataLength: 12,
    },
    postgresType: 'date',
  },
  timestamp: {
    HigherTypes: [
      'timestamptz',
      'character varying',
      'timestamp with time zone',
      'timestamp without time zone',
    ],
    FallbackHigherType: FallBackTypeEnum['character varying'],
    'character varying': {
      DataLength: 29,
    },
    postgresType: 'timestamp',
  },
  'timestamp without time zone': {
    HigherTypes: ['timestamptz', 'character varying', 'timestamp with time zone', 'timestamp'],
    FallbackHigherType: FallBackTypeEnum['character varying'],
    'character varying': {
      DataLength: 29,
    },
    postgresType: 'timestamp',
  },
  timestamptz: {
    HigherTypes: ['character varying', 'timestamp with time zone'],
    FallbackHigherType: FallBackTypeEnum['character varying'],
    'character varying': {
      DataLength: 29,
    },
    postgresType: 'timestamptz',
  },
  'timestamp with time zone': {
    HigherTypes: ['character varying', 'timestamptz'],
    FallbackHigherType: FallBackTypeEnum['character varying'],
    'character varying': {
      DataLength: 30,
    },
    postgresType: 'timestamptz',
  },
  time: {
    HigherTypes: ['timestamp', 'timestamptz', 'character varying'],
    FallbackHigherType: FallBackTypeEnum['character varying'],
    'character varying': {
      DataLength: 10,
    },
    postgresType: 'time',
  },
  char: {
    HigherTypes: ['text', 'character varying'],
    AllowHigerLength: true,
    FallbackHigherType: FallBackTypeEnum['character varying'],
    'character varying': {
      DataLength: 256,
    },
    postgresType: 'char',
    UseTextForLongerStrings: true,
  },
  character: {
    HigherTypes: ['text', 'character varying'],
    AllowHigerLength: true,
    FallbackHigherType: FallBackTypeEnum['character varying'],
    'character varying': {
      DataLength: 256,
    },
    postgresType: 'char',
    UseTextForLongerStrings: true,
  },
  text: {
    HigherTypes: ['text'],
    AllowHigerLength: true,
    FallbackHigherType: FallBackTypeEnum['character varying'],
    postgresType: 'text',
    UseTextForLongerStrings: true,
  },
  varchar: {
    HigherTypes: ['text', 'character varying'],
    AllowHigerLength: true,
    FallbackHigherType: FallBackTypeEnum['character varying'],
    'character varying': {
      DataLength: 512,
    },
    postgresType: 'character varying',
    UseTextForLongerStrings: true,
  },
  'character varying': {
    HigherTypes: ['text', 'character varying', 'varchar'],
    AllowHigerLength: true,
    FallbackHigherType: FallBackTypeEnum['character varying'],
    'character varying': {
      DataLength: 512,
    },
    postgresType: 'character varying',
    UseTextForLongerStrings: true,
  },
  uuid: {
    HigherTypes: ['text', 'character varying'],
    AllowHigerLength: false,
    FallbackHigherType: FallBackTypeEnum['character varying'],
    'character varying': {
      DataLength: 36,
    },
    postgresType: 'uuid',
  },
  integer: {
    HigherTypes: ['bigint', 'real', 'double precision', 'numeric', 'int'],
    FallbackHigherType: FallBackTypeEnum['character varying'],
    numeric: {
      precision: 32,
      scale: 0,
    },
    postgresType: 'int',
  },
  datetime: {
    HigherTypes: ['timestamp with time zone', 'timestamptz', 'character varying'],
    FallbackHigherType: FallBackTypeEnum['character varying'],
    'character varying': {
      DataLength: 29,
    },
    postgresType: 'timestamptz',
  },
  boolean: {
    HigherTypes: ['bool', 'character varying', 'smallint'],
    FallbackHigherType: FallBackTypeEnum['character varying'],
    'character varying': {
      DataLength: 5,
    },
    postgresType: 'boolean',
  },
  bool: {
    HigherTypes: ['boolean', 'character varying', 'smallint'],
    FallbackHigherType: FallBackTypeEnum['character varying'],
    'character varying': {
      DataLength: 5,
    },
    postgresType: 'bool',
  },
  json: {
    HigherTypes: ['jsonb', 'text'],
    FallbackHigherType: 'jsonb',
    postgresType: 'json',
  },
  jsonb: {
    HigherTypes: ['json', 'text'],
    FallbackHigherType: 'jsonb',
    postgresType: 'jsonb',
  },
}

export const JsonPostgreTypeMappingEnum = {
  number: {
    Value: 10,
    postgres: {
      dataType: 'numeric',
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
  int: {
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
  'date-time': {
    Value: 100,
    postgres: {
      dataType: 'timestamptz',
    },
  },
  null: {
    Value: 110,
    postgres: {
      dataType: 'character varying',
      defaultLength: 512,
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
      } else {
        // IF existing type is big enough then leave it
        // we are doing the above check, by
        // seeing if new type is not part of a higher type of the existing type
        if (!DataTypeTransferEnum[dtNew].HigherTypes.includes(dtExisting)) {
          // or else check if we new type is better
          if (DataTypeTransferEnum[dtExisting].HigherTypes.includes(dtNew)) {
            // if so allow type change
            output.AllowTypeChange = true
            // or else fallback
          } else {
            output.FallbackToHigherType = true
          }
        }
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
  // for text we dont need a length
  if (newType.DataType === 'text') {
    return -1
  }
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
      DataTypeTransferEnum[existingType.DataType].FallbackHigherType.DataLength || -1
    retNewType.precision =
      DataTypeTransferEnum[existingType.DataType].FallbackHigherType.precision || -1
    retNewType.scale = DataTypeTransferEnum[existingType.DataType].FallbackHigherType.scale || -1
  } else {
    return {}
  }
  // return it
  return retNewType
}

/**
 * Replaces any characters that is NOT one of the following with hypen
 *  a-z
 *  A-Z
 *  0-9
 *  _ (underscore)
 *  - (hypen)
 *  ' '(blank space)
 *
 * Also if there are
 *  two or more hypens, it replaces with just single one
 *  tow or more blanks, it replaces with just single one
 *  Replaces any column that starts with a blank space to hypen (or else Knex removes it)
 *  Replaces any column that end with a blank space to hypen (or else Knex removes it)
 */
export function GetCleanColumnName(colName) {
  return colName
    .replace(/^ /gi, '-')
    .replace(/[^a-zA-Z0-9_ -]/gi, '-')
    .replace(/-{2,}/gi, '-')
    .replace(/ {2,}/gi, ' ')
    .replace(/ $/gi, '-')
}
