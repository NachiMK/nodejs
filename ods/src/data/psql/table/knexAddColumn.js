export function addDecimal(knexTable, colName, opts = { precision: 22, scale: 8 }) {
  knexTable.decimal(colName, opts.precision, opts.scale)
}

export function addNumeric(knexTable, colName, opts = { precision: 22, scale: 8 }) {
  knexTable.decimal(colName, opts.precision, opts.scale)
}

export function addReal(knexTable, colName, opts = { precision: 24, scale: 6 }) {
  knexTable.decimal(colName, opts.precision, opts.scale)
}

export function addDouble(knexTable, colName, opts = { precision: 53, scale: 15 }) {
  knexTable.decimal(colName, opts.precision, opts.scale)
}

export function addSmallInt(knexTable, colName) {
  knexTable.specificType(colName, 'smallint')
}

export function addInteger(knexTable, colName) {
  knexTable.integer(colName)
}

export function addBigInteger(knexTable, colName) {
  knexTable.bigInteger(colName)
}

export function addSerial(knexTable, colName) {
  knexTable.increments(colName)
}

export function addBigSerial(knexTable, colName) {
  knexTable.specificType(colName, 'bigserial')
}

export function addString(knexTable, colName, opts = { length: 510 }) {
  knexTable.string(colName, opts.length)
}

export function addBool(knexTable, colName) {
  knexTable.boolean(colName)
}

export function addDate(knexTable, colName) {
  knexTable.date(colName, true)
}

export function addDateTime(knexTable, colName) {
  knexTable.timestamp(colName, true)
}

export function addTimeStampTz(knexTable, colName) {
  knexTable.timestamp(colName)
}

export function addTime(knexTable, colName) {
  knexTable.time(colName)
}

export function addArray(knexTable, colName) {
  knexTable.jsonb(colName)
}

export function addJson(knexTable, colName) {
  knexTable.json(colName)
}

export function addObject(knexTable, colName) {
  knexTable.jsonb(colName)
}

export function addText(knexTable, colName) {
  knexTable.text(colName)
}
