'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.validateAll = exports.validateQueryAndParams = exports.validateParams = exports.validateQuery = exports.validateBody = exports.validateAjv = undefined;

var _asyncToGenerator2 = require('babel-runtime/helpers/asyncToGenerator');

var _asyncToGenerator3 = _interopRequireDefault(_asyncToGenerator2);

var _ajv = require('ajv');

var _ajv2 = _interopRequireDefault(_ajv);

var _fs = require('fs');

var _fs2 = _interopRequireDefault(_fs);

var _lodash = require('lodash');

var _nodeFetch = require('node-fetch');

var _nodeFetch2 = _interopRequireDefault(_nodeFetch);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

const validateAjv = exports.validateAjv = getPayload => getJsonSchema => (() => {
  var _ref = (0, _asyncToGenerator3.default)(function* (event) {
    const ajv = new _ajv2.default({
      coerceTypes: true,
      allErrors: true,
      verbose: true,
      format: 'full',
      removeAdditional: true
    });

    let schema = null;
    let data = null;

    if ((0, _lodash.isFunction)(getJsonSchema)) {
      schema = yield getJsonSchema(event);
    } else {
      schema = getJsonSchema;
    }

    if ((0, _lodash.isString)(schema)) {
      const exists = _fs2.default.existsSync(schema);
      if (exists) {
        schema = JSON.parse(_fs2.default.readFileSync(schema, 'utf8'));
      } else {
        const res = yield (0, _nodeFetch2.default)(getJsonSchema);
        schema = yield res.json();
      }
    }

    const validate = ajv.compile(schema);

    if ((0, _lodash.isFunction)(getPayload)) {
      data = yield getPayload(event);
    } else {
      data = getPayload;
    }

    const valid = validate(data);

    if (!valid) {
      const validationErrors = validate.errors.map(function (item) {
        return {
          message: `${item.dataPath} ${item.message}${Array.isArray(item.schema) ? item.schema : ''}`
        };
      });
      const err = new Error('Request is not valid');
      err.errors = validationErrors;
      err.statusCode = 400;
      throw err;
    }
  });

  return function (_x) {
    return _ref.apply(this, arguments);
  };
})();

const validateBody = exports.validateBody = validateAjv(event => event.body);
const validateQuery = exports.validateQuery = validateAjv(event => event.query);
const validateParams = exports.validateParams = validateAjv(event => event.params);
const validateQueryAndParams = exports.validateQueryAndParams = validateAjv(({
  query = {},
  params = {}
}) => Object.assign({}, query, params));
const validateAll = exports.validateAll = validateAjv(({
  body = {},
  query = {},
  params = {}
}) => Object.assign({}, body, query, params));
//# sourceMappingURL=index.js.map