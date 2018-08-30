'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.BaseModel = undefined;
exports.initKnexAsync = initKnexAsync;
exports.initKnex = initKnex;
exports.destroyKnex = destroyKnex;
exports.destroyKnexAsync = destroyKnexAsync;

var _knex = require('knex');

var _knex2 = _interopRequireDefault(_knex);

var _objection = require('objection');

var _knexfile = require('../../knexfile');

var _knexfile2 = _interopRequireDefault(_knexfile);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

let knex;

async function initKnexAsync() {
  return initKnex();
}

function initKnex() {
  const stage = process.env.STAGE;
  const config = _knexfile2.default[stage];

  knex = (0, _knex2.default)(config);

  _objection.Model.knex(knex);

  class DefaultSchemaQueryBuilder extends _objection.QueryBuilder {
    constructor(modelClass) {
      super(modelClass);
      if (modelClass.defaultSchema) {
        this.withSchema(modelClass.defaultSchema);
      }
    }
  }

  _objection.Model.QueryBuilder = DefaultSchemaQueryBuilder;
  _objection.Model.RelatedQueryBuilder = DefaultSchemaQueryBuilder;

  return knex;
}

function destroyKnex() {
  knex.destroy();
}

async function destroyKnexAsync() {
  return destroyKnex();
}

class BaseModel extends _objection.Model {}
exports.BaseModel = BaseModel;
//# sourceMappingURL=objection-utils.js.map