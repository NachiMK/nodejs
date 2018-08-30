import Knex from 'knex';
import { Model, QueryBuilder } from 'objection';
// import pg from 'pg';
import configs from '../../knexfile';

let knex;

// NOTE! - This was copied from health-plan-service but not sure if we need it.
// import knexDialect from 'knex/lib/dialects/postgres';
// pg.types.setTypeParser(20, 'text', parseInt);
// pg.types.setTypeParser(1700, parseFloat);

export async function initKnexAsync() {
  return initKnex();
}

export function initKnex() {
  const stage = process.env.STAGE;
  const config = configs[stage];

  // Initialize knex using the current stage
  knex = Knex(config);

  // knex.client = knexDialect;

  // Bind all Models to a knex instance. If you only have one database in
  // your server this is all you have to do. For multi database systems, see
  // the Model.bindKnex method.
  Model.knex(knex);

  // Add ability to set defaultSchema method on your models
  // https://github.com/Vincit/objection.js/issues/85
  class DefaultSchemaQueryBuilder extends QueryBuilder {
    constructor(modelClass) {
      super(modelClass);
      if (modelClass.defaultSchema) {
        this.withSchema(modelClass.defaultSchema);
      }
    }
  }

  Model.QueryBuilder = DefaultSchemaQueryBuilder;
  Model.RelatedQueryBuilder = DefaultSchemaQueryBuilder;

  return knex;
}

export function destroyKnex() {
  // Knex needs to be destroyed or it will continue to hang the thread.
  knex.destroy();
}

export async function destroyKnexAsync() {
  return destroyKnex();
}

// We should have all our Objection models extend from BaseModel to give us a place to set global properties
export class BaseModel extends Model {
  // TODO: Might be nice to have camelCase properties returned but keep the TitleCase column names in DB.
  // static get columnNameMappers() {
  //   return snakeCaseMappers({ upperCase: false });
  // }
}
