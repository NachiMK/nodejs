DROP TYPE IF EXISTS ods."ReturnTypePipeLineAttributes";
CREATE TYPE ods."ReturnTypePipeLineAttributes" as ("DataPipeLineTaskQueueId" INT, "AttributeName" VARCHAR(60), "AttributeValue" VARCHAR(500));

