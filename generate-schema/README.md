# Hixme Generate Schema

**Generate [JSON Schema] from JSON data with added date, UUID, enum, and length detection**

This package extends [generate-schema] to detect ISO dates, datetimes, enums, minLength, maxLength and UUIDs from the JSON and add appropriate format and size limits.

# Installation

```bash
npm install --save @hixme/generate-schema
```
# Usage

```js
const generateSchema = require('@hixme/generate-schema')
```

## Example

Generate JSON Schema with UUID and format detection (date, date-time)

```js
const persons = [{
  Id: '363f1eec-a814-4518-a738-6cb844b6cf92',
  FirstName: 'John',
  LastName: 'Doe',
  Gender: 'Male',
  BirthDate: '2000-04-01',
  DateUpdated: '2018-01-16T23:33:01+00:00'
},
{
  Id: 'abaa80cc-e0eb-4a33-8292-ec937ffe773b',
  FirstName: 'Cindy',
  LastName: 'Kline',
  Gender: 'Female',
  BirthDate: '1974-10-25',
  DateUpdated: '2018-01-16T23:33:44+00:00'
}]

const schema = generateSchema.json('Person', persons)
```

### Outputs

```js
{
  "$schema": "http://json-schema.org/draft-04/schema#",
  "title": "Person Set",
  "type": "array",
  "items": {
    "type": "object",
    "properties": {
      "Id": {
        "type": "string",
        "minLength": 36,
        "maxLength": 36
      },
      "FirstName": {
        "type": "string"
      },
      "LastName": {
        "type": "string"
      },
      "Gender": {
        "type": "string"
      },
      "BirthDate": {
        "type": "string",
        "format": "date"
      },
      "DateUpdated": {
        "type": "string",
        "format": "date-time"
      }
    },
    "required": [
      "Id",
      "FirstName",
      "LastName",
      "BirthDate",
      "DateUpdated"
    ],
    "title": "Person"
  }
}
```


## Example

Generate JSON Schema with enums and lengths

```js
const schema = generateSchema.json('Person', persons,{
  generateEnums: true,
  maxEnumValues: 2,
  generateLengths: true 
})
```

### Outputs (With enums and lengths)

```js
{
  "$schema": "http://json-schema.org/draft-04/schema#",
  "title": "Person Set",
  "type": "array",
  "items": {
    "type": "object",
    "properties": {
      "Id": {
        "type": "string",
        "minLength": 36,
        "maxLength": 36,
        "enum": [
          "363f1eec-a814-4518-a738-6cb844b6cf92",
          "abaa80cc-e0eb-4a33-8292-ec937ffe773b"
        ]
      },
      "FirstName": {
        "type": "string",
        "enum": [
          "John",
          "Cindy"
        ],
        "minLength": 4,
        "maxLength": 5
      },
      "LastName": {
        "type": "string",
        "enum": [
          "Doe",
          "Kline"
        ],
        "minLength": 3,
        "maxLength": 5
      },
      "Gender": {
        "type": "string",
        "enum": [
          "Male",
          "Female"
        ],
        "minLength": 4,
        "maxLength": 6
      },
      "BirthDate": {
        "type": "string",
        "format": "date",
        "enum": [
          "2000-04-01",
          "1974-10-25"
        ],
        "minLength": 10,
        "maxLength": 10
      },
      "DateUpdated": {
        "type": "string",
        "format": "date-time",
        "enum": [
          "2018-01-16T23:33:01+00:00",
          "2018-01-16T23:33:44+00:00"
        ],
        "minLength": 25,
        "maxLength": 25
      }
    },
    "required": [
      "Id",
      "FirstName",
      "LastName",
      "Gender",
      "BirthDate",
      "DateUpdated"
    ],
    "title": "Person"
  }
}

```

## Methods

#### `generateSchema.json(String title, Mixed object, [Object options])`
Generates JSON Schema from an Object or Array

- title of JSON Schema
- object must be of type Object or Array
- options is optional

## Options

- `generateEnums` flag is used to add enum list to schema for string types and defaults to false
- `maxEnumValues` is used to limit the number of enum values detected and defaults to 20
- `generateLengths` flag to generate minLength and maxLength attributes based on values in json and defaults to false 


[JSON Schema]: http://json-schema.org
[generate-schema]: https://www.npmjs.com/package/generate-schema