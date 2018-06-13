for serialno in {1..2000}
do
aws dynamodb put-item --table-name dev-ods-persons --region us-west-1 --item '{ "primarykey" : {"N":"'$serialno'"}, "text1" : {"S": 
"}}'
done&

# Read from the DynamoDB table
for i in {1..1000}
do
  aws dynamodb scan --table-name dev-ods-persons --region us-west-1 > /dev/null
  aws dynamodb get-item --table-name SatishTestTable --key '{ "primarykey" : {"N" : "'$((RANDOM%2000))'"} }' --region us-west-1 >/dev/null
  sleep 1
done&

{
  "Benefits": [
    {
      "BenefitName": "HealthPlan",
      "BenefitType": "Health",
      "EffectiveDate": "2017-10-10",
      "IsActive": "1",
      "PBId": 7001,
      "PersonId": 7,
      "ReadableId": 7001
    }
  ],
  "DateOfBirth": "1986-01-01",
  "FirstName": "Ram",
  "Gender": "M",
  "Id": 7,
  "IsActive": false,
  "LastName": "Smith_TestS3SaveTrogger",
  "PhoneNumber": "8188188007",
  "ReadableId": 7,
  "Salary": 1017
}