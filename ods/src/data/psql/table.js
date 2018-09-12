export function addDecimal(knexTable, colName, opts = { precision: 22, scale: 8 }) {
  knexTable.decimal(colName, opts.precision, opts.scale)
}

export function addInteger(knexTable, colName) {
  knexTable.integer(colName)
}

export function addString(knexTable, colName, opts = { length: 510 }) {
  knexTable.string(colName, opts.length)
}

export function addBool(knexTable, colName) {
  knexTable.boolean(colName)
}

export function addDate(knexTable, colName) {
  knexTable.timestamp(colName)
}

export function addDateTime(knexTable, colName) {
  knexTable.timestamp(colName)
}

export function addArray(knexTable, colName) {
  knexTable.jsonb(colName)
}

export function addObject(knexTable, colName) {
  knexTable.jsonb(colName)
}

export function addText(knexTable, colName) {
  knexTable.text(colName)
}
