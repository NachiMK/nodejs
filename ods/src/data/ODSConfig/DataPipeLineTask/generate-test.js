import {
        createDynamoDBToS3PipeLineTask, 
        UpdatePipeLineTaskStatus } from './index';

createDynamoDBToS3PipeLineTask("clients", 10)
.then(res => console.log('res', res))
.catch(e => console.log('error', e));

