// import ware from 'warewolf';
// import path from 'path';
// import fs from 'fs';
// import { isEmployee } from '@hixme/person-utils';
// // import { validateAjv, validateParams } from '../../../utils/validator';
// import { isPersonAuthorized } from '@hixme/role-authorizer-middleware';
// import { removeNullOrEmptyString } from '@hixme/sanitizer-middleware';
// import { before, after } from '@hixme/before-after-middleware';
// import { savePerson } from '../../../service/persons';

// export const post = ware(
//   before,
//   isPersonAuthorized(event => event.body.Id),
//   removeNullOrEmptyString(event => event.body),
//   async (event) => {
//     const person = event.body;
//     await savePerson(person, { schema: getModelSchema(person) });

//     event.result = person;
//   },
//   after,
// );

// function getModelSchema(person) {
//   const schema = JSON.parse(fs.readFileSync(path.join(__dirname, `../../../${isEmployee(person) ? 'employee' : 'dependent'}.schema.json`), 'utf8'));
//   schema.additionalProperties = false;
//   return schema;
// }
