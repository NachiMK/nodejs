exports.up = knex => knex.schema
  .createTable('Members', (table) => {
    table.increments('MemberID').primary();
    table
      .integer('ParentID')
      .unsigned()
      .references('MemberID')
      .inTable('Members')
      .onDelete('SET NULL');
    table.string('FirstName');
    table.string('LastName');
    table.string('DateOfBirth');
  })
  .createTable('Phones', (table) => {
    table.increments('PhoneID').primary();
    table
      .integer('MemberID')
      .unsigned()
      .references('MemberID')
      .inTable('Members')
      .onDelete('CASCADE');
    table.string('PhoneNumber');
    table.string('Extension');
  });

exports.down = knex => knex.schema
  .dropTableIfExists('Phones')
  .dropTableIfExists('Members');
