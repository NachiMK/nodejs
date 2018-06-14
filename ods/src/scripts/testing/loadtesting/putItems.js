import moment from 'moment';

const AWS = require('aws-sdk');

AWS.config.update({
  region: 'us-west-2',
});

export async function addODSPersons(NumberOfRecords, BatchId) {
  const docClient = new AWS.DynamoDB.DocumentClient();
  console.log('Importing Persons into DynamoDB. Please wait.');

  const arrayOfPersons = await getArrayOfPersons(NumberOfRecords, BatchId);
  arrayOfPersons.forEach((person) => {
    const params = {
      TableName: 'dev-ods-persons',
      Item: person,
    };
    // console.log(`Adding Person:${JSON.stringify(person, null, 2)}`);
    docClient.put(params, (err, data) => {
      if (err) {
        console.error('Unable to add person', data, '. Error JSON:', JSON.stringify(err, null, 2));
      } else {
        console.log('Adding Person succeeded:', data);
      }
    });
  });
}

function getArrayOfPersons(len, batchid) {
  const emptyArray = [...Array(len).keys()];
  const retArray = emptyArray.map((idx) => {
    const addBenefit = ((idx % 3) === 0);
    // const p = getPerson(getUniqueId() + idx, idx, addBenefit);
    // console.log(`${idx} of ${len} is : ${JSON.stringify(p, null, 2)}`);
    return getPerson(getUniqueId(idx), idx, addBenefit, batchid);
  });
  console.log('Array', JSON.stringify(retArray, null, 2));
  return retArray;
}

function getUniqueId(idx) {
  let retVal = parseInt((moment().format('x')), 10);
  retVal += idx;
  // console.log(`idx:${idx} , retVal: ${retVal}, retVal-idx: ${retVal - idx}`);
  return retVal;
}

function getPerson(uniqueid, id, addBenefit, batchid) {
  const devodsperson = {
    DateOfBirth: randomDate(new Date(1990, (id % 12), (id % 28)), new Date()),
    FirstName: `${batchid}_FirstName_${id}`,
    Gender: getGender(id),
    Id: uniqueid,
    IsActive: false,
    LastName: `${batchid}_LastName_${id}`,
    PhoneNumber: '8188188007',
    ReadableId: uniqueid,
    Salary: 1000 * id,
  };
  if (addBenefit) {
    devodsperson.Benefit = getBenefit(uniqueid, id, batchid);
  }
  // console.log(`Person:${id}: value: ${JSON.stringify(devodsperson, null, 2)}`);
  return devodsperson;
}

function getGender(id) {
  if ((id % 2) === 0) {
    return 'M';
  }
  return 'F';
}

function randomDate(start, end) {
  return new Date(start.getTime() + (Math.random() * (end.getTime() - start.getTime())));
}

function getBenefit(uniqueid, id, batchid) {
  const arrBenefit = [];
  const benefit = {
    BenefitName: 'HealthPlan',
    BenefitType: 'Health',
    EffectiveDate: '2017-10-10',
    IsActive: '1',
    PBId: `${batchid}${id}001`,
    PersonId: uniqueid,
    ReadableId: `${batchid}${id}001`,
  };
  arrBenefit.push(benefit);
  return arrBenefit;
}

// function addition(a, b, acc = '', carry = 0) {
//   if (!(a.length || b.length || carry)) return acc.replace(/^0+/, '');

//   carry = carry + (~~a.pop() + ~~b.pop());
//   acc = carry % 10 + acc;
//   carry = carry > 9;

//   return addition(a, b, acc, carry);
// }

// function sumStrings(a, b) {
//   if (a === '0' && b === '0') return '0';
//   return addition(a.split(''), b.split(''));
// }
