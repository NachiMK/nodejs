const generateSchema = require("./index");

const persons = [{
  Id: "363f1eec-a814-4518-a738-6cb844b6cf92",
  PublicKey: "363f1eec-a814-4518-a738-6cb844b6cf92",
  FirstName: "John",
  LastName: "Doe",
  Gender: "Male",
  BirthDate: "2000-04-01",
  DateUpdated: "2018-01-16T23:33:01+00:00"
}, {
  Id: "abaa80cc-e0eb-4a33-8292-ec937ffe773b_INACTIVE",
  PublicKey: "abaa80cc-e0eb-4a33-8292-ec937ffe773b_INACTIVE",
  FirstName: "Cindy",
  LastName: "Kline",
  Gender: "Female",
  BirthDate: "1974-10-25",
  DateUpdated: "2018-01-16T23:33:44+00:00"
}];

const schema = generateSchema.json("Person", persons);
console.log("Without enums", JSON.stringify(schema, null, 2));

const schemaWithEnums = generateSchema.json("Person", persons, {
  generateEnums: true,
  maxEnumValues: 2,
  generateLengths: true
});
console.log("With enums and lengths", JSON.stringify(schemaWithEnums, null, 2));
//# sourceMappingURL=test.js.map