aws s3 rm s3://int-ods-data/dynamodb/benefit-change-events/ --exclude "initial/*.json" --recursive &&
aws s3 rm s3://int-ods-data/dynamodb/benefits/ --exclude "initial/*.json" --recursive &&
aws s3 rm s3://int-ods-data/dynamodb/bundle-event-offers-log/ --exclude "initial/*.json" --recursive &&
aws s3 rm s3://int-ods-data/dynamodb/bundle-event-offers/ --exclude "initial/*.json" --recursive &&
aws s3 rm s3://int-ods-data/dynamodb/bundle-events/ --exclude "initial/*.json" --recursive &&
aws s3 rm s3://int-ods-data/dynamodb/carrier-messages/ --exclude "initial/*.json" --recursive &&
aws s3 rm s3://int-ods-data/dynamodb/client-benefits/ --exclude "initial/*.json" --recursive &&
aws s3 rm s3://int-ods-data/dynamodb/client-census/ --exclude "initial/*.json" --recursive &&
aws s3 rm s3://int-ods-data/dynamodb/client-price-points/ --exclude "initial/*.json" --recursive &&
aws s3 rm s3://int-ods-data/dynamodb/clients/ --exclude "initial/*.json" --recursive &&
aws s3 rm s3://int-ods-data/dynamodb/enrollment-events/ --exclude "initial/*.json" --recursive &&
aws s3 rm s3://int-ods-data/dynamodb/enrollment-questions/ --exclude "initial/*.json" --recursive &&
aws s3 rm s3://int-ods-data/dynamodb/enrollment-responses/ --exclude "initial/*.json" --recursive &&
aws s3 rm s3://int-ods-data/dynamodb/enrollments/ --exclude "initial/*.json" --recursive &&
aws s3 rm s3://int-ods-data/dynamodb/locations/ --exclude "initial/*.json" --recursive &&
aws s3 rm s3://int-ods-data/dynamodb/modeling-census/ --exclude "initial/*.json" --recursive &&
aws s3 rm s3://int-ods-data/dynamodb/modeling-configuration/ --exclude "initial/*.json" --recursive &&
aws s3 rm s3://int-ods-data/dynamodb/modeling-group-plans/ --exclude "initial/*.json" --recursive &&
aws s3 rm s3://int-ods-data/dynamodb/modeling-price-points/ --exclude "initial/*.json" --recursive &&
aws s3 rm s3://int-ods-data/dynamodb/modeling-scenarios/ --exclude "initial/*.json" --recursive &&
aws s3 rm s3://int-ods-data/dynamodb/modeling-validation/ --exclude "initial/*.json" --recursive &&
aws s3 rm s3://int-ods-data/dynamodb/models/ --exclude "initial/*.json" --recursive &&
aws s3 rm s3://int-ods-data/dynamodb/notes/ --exclude "initial/*.json" --recursive &&
aws s3 rm s3://int-ods-data/dynamodb/ods-testtable-1/ --exclude "initial/*.json" --recursive &&
aws s3 rm s3://int-ods-data/dynamodb/persons/ --exclude "initial/*.json" --recursive &&
aws s3 rm s3://int-ods-data/dynamodb/platform-authorization-events/ --exclude "initial/*.json" --recursive &&
aws s3 rm s3://int-ods-data/dynamodb/prospect-census-models/ --exclude "initial/*.json" --recursive &&
aws s3 rm s3://int-ods-data/dynamodb/prospect-census-profiles/ --exclude "initial/*.json" --recursive &&
aws s3 rm s3://int-ods-data/dynamodb/prospects/ --exclude "initial/*.json" --recursive &&
aws s3 rm s3://int-ods-data/dynamodb/tags/ --exclude "initial/*.json" --recursive &&
aws s3 rm s3://int-ods-data/dynamodb/waived-benefits/ --exclude "initial/*.json" --recursive
