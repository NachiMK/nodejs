exports.up = knex => knex.schema
  .dropTableIfExists('Phones')
  .dropTableIfExists('Members')
  .createSchema('family')
  .createTable('family.Members', (table) => {
    table.increments('MemberID').primary();
    table
      .integer('ParentID')
      .unsigned()
      .references('MemberID')
      .inTable('family.Members')
      .onDelete('SET NULL');
    table.string('FirstName');
    table.string('LastName');
    table.string('DateOfBirth');
  })
  .createTable('public.Phones', (table) => {
    table.increments('PhoneID').primary();
    table
      .integer('MemberID')
      .unsigned()
      .references('MemberID')
      .inTable('family.Members')
      .onDelete('CASCADE');
    table.string('PhoneNumber');
    table.string('Extension');
  });

exports.down = knex => knex.schema
  .dropTableIfExists('Public.Phones')
  .dropTableIfExists('Family.Members');
