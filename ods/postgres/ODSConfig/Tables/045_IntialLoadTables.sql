CREATE TABLE ods."DataPipeLineInitialImport" (
     "DataPipeLineInitialImportId" SERIAL PRIMARY KEY
    ,"SourceEntity"                VARCHAR(100) NOT NULL
    ,"StartIndex"                  INT NOT NULL CHECK ("StartIndex" > 0)
    ,"EndIndex"                    INT NOT NULL CHECK ("EndIndex" > 0)
    ,"RowCountInBatch"             INT NOT NULL CHECK ("RowCountInBatch" >= 0)
    ,"ImportSequence"              INT NOT NULL CHECK ("ImportSequence" >= 0)
    ,"S3File"                      VARCHAR(500) NOT NULL
    ,"DataPipeLineTaskQueueId"     INT NOT NULL DEFAULT -1
    ,"QueuingError"                TEXT
    ,"QueuedDtTm"                  TIMESTAMP
    ,"CreatedDtTm"                 TIMESTAMP not null DEFAULT CURRENT_TIMESTAMP
    ,CONSTRAINT UNQ_DataPiplelineInitialImport_S3File UNIQUE("SourceEntity", "S3File")
    ,CONSTRAINT UNQ_DataPiplelineInitialImport_Seq UNIQUE("SourceEntity", "ImportSequence")
);
