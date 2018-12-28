CREATE TABLE IF NOT EXISTS arch."DataPipeLineTaskQueueArchive"
(
     "ArchiveId"                SERIAL PRIMARY KEY
    ,"ArchiveDtTm"              timestamp not null  default CURRENT_TIMESTAMP
    ,"DataPipeLineTaskQueueId"  INT NOT NULL
    ,"DataPipeLineTaskId"       INT NOT NULL
    ,"ParentTaskId"             INT
    ,"RunSequence"              INT NOT NULL
    ,"TaskStatusId"             INT NOT NULL
    ,"StartDtTm"                timestamp null
    ,"EndDtTm"                  timestamp null
    ,"Error"                    jsonb null
    ,"CreatedDtTm"              timestamp not null
    ,"UpdatedDtTm"              timestamp not null
    ,CONSTRAINT UNQ_DataPipeLineTaskQueueArchive UNIQUE("DataPipeLineTaskQueueId")
);

CREATE TABLE IF NOT EXISTS arch."TaskQueueAttributeLogArchive"
(
     "ArchiveId"                SERIAL PRIMARY KEY
    ,"ArchiveDtTm"              timestamp not null  default CURRENT_TIMESTAMP
    ,"TaskQueueAttributeLogId"  INT
    ,"DataPipeLineTaskQueueId"  INT NOT NULL
    ,"AttributeName"            VARCHAR(60) NOT NULL
    ,"AttributeValue"           VARCHAR(500) NOT NULL
    ,"CreatedDtTm"              timestamp not null
    ,"UpdatedDtTm"              timestamp not null
    ,CONSTRAINT UNQ_TaskQueueAttributeLogArchive UNIQUE("TaskQueueAttributeLogId")
);
