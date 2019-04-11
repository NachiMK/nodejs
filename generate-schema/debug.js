const generateSchema = require("./index");
const persons = [
  {
    Id: "363f1eec-a814-4518-a738-6cb844b6cf92",
    FirstName: "John",
    Gender: "Male",
    BirthDate: "2000-04-01",
    DivisionCode: "PRP",
    NumberAndString: "test",
    BooleanAndString: true,
    JustBoolean: true,
    Salary: 10023.456787,
    DateUpdated: "2018-01-16T23:33:01+00:00"
  },
  {
    Id: "474f1eec-a814-4518-a738-6cb844b6cf92",
    FirstName: "Negate",
    Gender: "Male",
    BirthDate: "1999-05-01",
    DivisionCode: "SFW",
    NumberAndString: "test",
    BooleanAndString: false,
    JustBoolean: false,
    Salary: -10023.5,
    DateUpdated: "2018-01-16T23:33:01+00:00"
  },
  {
    Id: "363f1eec-a814-4518-a738-6cb844b6cf92",
    FirstName: "Rani",
    Gender: "Female",
    BirthDate: "2002-04-01",
    DivisionCode: "HDW",
    NumberAndString: "one",
    BooleanAndString: "false",
    JustBoolean: true,
    Salary: 10023.7,
    DateUpdated: "2018-01-16T23:33:01+00:00"
  },
  {
    Id: "abaa80cc-e0eb-4a33-8292-ec937ffe773b_INACTIVE",
    FirstName: "Cindy",
    Gender: "Female",
    BirthDate: "March 10",
    DivisionCode: "2018-01-16T23:33:44+00:00",
    NumberAndString: 10,
    BooleanAndString: true,
    JustBoolean: true,
    Salary: 10023.4501,
    DateUpdated: "2018-01-16T23:33:44+00:00"
  }
];

const schema = generateSchema.json("Person", persons);
console.log("Without enums", JSON.stringify(schema, null, 2));

const schemaWithPopFormat = generateSchema.json("Person", persons, {
  pickPopularFormat: true
});
console.log(
  "Without enums but with Popular Format",
  JSON.stringify(schemaWithPopFormat, null, 2)
);

// test adding format counts
const schemaWithCounts = generateSchema.json("Person", persons, {
  addFormatCounts: true
});
console.log(
  "Without enums but with Format Counts",
  JSON.stringify(schemaWithCounts, null, 2)
);

const schemaWithEnums = generateSchema.json("Person", persons, {
  generateEnums: true,
  maxEnumValues: 2,
  generateLengths: true
});
console.log("With enums and lengths", JSON.stringify(schemaWithEnums, null, 2));
