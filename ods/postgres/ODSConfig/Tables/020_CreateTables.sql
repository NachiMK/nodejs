-- DynamoDB, S3, JSON, CSV, postgres
CREATE TABLE IF NOT EXISTS ods."DataSource" 
(
     "DataSourceId"       INT PRIMARY KEY --INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY
    ,"DataSourceName"     VARCHAR(40) NOT NULL
    ,"ReadOnly"           BOOLEAN not null DEFAULT FALSE
    ,"CreatedDtTm"        timestamp not null DEFAULT CURRENT_TIMESTAMP
    ,"UpdatedDtTm"        timestamp not null DEFAULT CURRENT_TIMESTAMP
    ,CONSTRAINT UNQ_DataSourceType UNIQUE("DataSourceName")
);

CREATE TABLE IF NOT EXISTS ods."DataPipeLineMapping"
(
     "DataPipeLineMappingId"    INT PRIMARY KEY
    ,"SourceDataSourceId"       INT NOT NULL        REFERENCES ods."DataSource" ("DataSourceId")
    ,"TargetDataSourceId"       INT NOT NULL        REFERENCES ods."DataSource" ("DataSourceId")
    ,"CreatedDtTm"              timestamp not null DEFAULT CURRENT_TIMESTAMP
    ,"UpdatedDtTm"              timestamp not null DEFAULT CURRENT_TIMESTAMP
    ,CONSTRAINT UNQ_DataPipeLineMapping UNIQUE("SourceDataSourceId", "TargetDataSourceId")
);

CREATE TABLE IF NOT EXISTS ods."RangeType" 
(
     "RangeTypeId"   INT PRIMARY KEY--INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY
    ,"RangeTypeDesc" VARCHAR(40) NOT NULL
    ,"CreatedDtTm"   timestamp not null DEFAULT CURRENT_TIMESTAMP
    ,"UpdatedDtTm"   timestamp not null DEFAULT CURRENT_TIMESTAMP
    ,CONSTRAINT UNQ_RangeType UNIQUE("RangeTypeDesc")
);

CREATE TABLE IF NOT EXISTS ods."TaskStatus" 
(
    "TaskStatusId"      INT PRIMARY KEY--INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY
   ,"TaskStatusDesc"    VARCHAR(40) NOT NULL
   ,"CreatedDtTm"       timestamp not null DEFAULT CURRENT_TIMESTAMP
   ,"UpdatedDtTm"       timestamp not null DEFAULT CURRENT_TIMESTAMP
   ,CONSTRAINT UNQ_TaskStatus UNIQUE("TaskStatusDesc")
);

CREATE TABLE IF NOT EXISTS ods."IntervalType" 
(
    "IntervalTypeId"   INT PRIMARY KEY--INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY
   ,"IntervalTypeDesc" VARCHAR(40) NOT NULL
   ,"CreatedDtTm"      timestamp not null DEFAULT CURRENT_TIMESTAMP
   ,"UpdatedDtTm"      timestamp not null DEFAULT CURRENT_TIMESTAMP
   ,CONSTRAINT UNQ_IntervalType UNIQUE("IntervalTypeDesc")
);

CREATE TABLE IF NOT EXISTS ods."Attribute" 
(
    "AttributeId"   SERIAL PRIMARY KEY--INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY
   ,"AttributeName" VARCHAR(60) NOT NULL
   ,"CreatedDtTm"   timestamp not null DEFAULT CURRENT_TIMESTAMP
   ,"UpdatedDtTm"   timestamp not null DEFAULT CURRENT_TIMESTAMP
   ,CONSTRAINT UNQ_Attribute UNIQUE("AttributeName")
);

CREATE TABLE IF NOT EXISTS ods."TaskType"
(
    "TaskTypeId"    SERIAL PRIMARY KEY
   ,"TaskTypeDesc"  VARCHAR(40) NOT NULL UNIQUE
   ,"CreatedDtTm"   timestamp not null DEFAULT CURRENT_TIMESTAMP
   ,"UpdatedDtTm"   timestamp not null DEFAULT CURRENT_TIMESTAMP
);

-- Dynamo to S3, Process History...
CREATE TABLE IF NOT EXISTS ods."DataPipeLineTaskConfig"
(
    "DataPipeLineTaskConfigId"  SERIAL NOT NULL PRIMARY KEY
   ,"TaskName"                  VARCHAR(200) NOT NULL
   ,"DataPipeLineMappingId"     INT NOT NULL REFERENCES ods."DataPipeLineMapping" ("DataPipeLineMappingId")
   ,"TaskTypeId"                INT NOT NULL REFERENCES ods."TaskType" ("TaskTypeId")
   ,"ParentId"                  INT REFERENCES ods."DataPipeLineTaskConfig" ("DataPipeLineTaskConfigId")
   ,"RunSequence"               INT NOT NULL
   ,"OnErrorGotoNext"           BOOLEAN DEFAULT false
   ,"DeletedFlag"               BOOLEAN NOT NULL DEFAULT false
   ,"CreatedDtTm"               timestamp not null  default CURRENT_TIMESTAMP
   ,"UpdatedDtTm"               timestamp not null  default CURRENT_TIMESTAMP
   ,CONSTRAINT UNQ_DataPipeLineTaskConfig_1 UNIQUE ("DataPipeLineMappingId", "RunSequence", "ParentId")
   ,CONSTRAINT UNQ_DataPipeLineTaskConfig_2 UNIQUE ("DataPipeLineMappingId", "TaskName", "ParentId")
   ,CONSTRAINT CHCK_MappingTask_RunSeq    CHECK ("RunSequence" > 0)
);

-- Examples: What attributes are allowed for each Task Config
CREATE TABLE IF NOT EXISTS ods."TaskConfigAttribute"
(
     "TaskConfigAttributeId"        SERIAL NOT NULL
    ,"DataPipeLineTaskConfigId"     INT NOT NULL REFERENCES ods."DataPipeLineTaskConfig" ("DataPipeLineTaskConfigId")
    ,"AttributeId"                  INT NOT NULL REFERENCES ods."Attribute"("AttributeId")
    ,"Required"                     BOOLEAN NOT NULL DEFAULT true
    ,"DefaultValue"                 VARCHAR(500) NULL 
    ,"CreatedDtTm"                  timestamp not null DEFAULT CURRENT_TIMESTAMP
    ,"UpdatedDtTm"                  timestamp not null DEFAULT CURRENT_TIMESTAMP
    ,CONSTRAINT UNQ_TaskConfigAttribute UNIQUE("DataPipeLineTaskConfigId", "AttributeId")
);

-- One Entry per Table for what to do for that table.
CREATE TABLE IF NOT EXISTS ods."DataPipeLineTask"(
     "DataPipeLineTaskId"       SERIAL NOT NULL PRIMARY KEY
    ,"TaskName"                 VARCHAR(200) NOT NULL
    ,"SourceEntity"             VARCHAR(100) NOT NULL
    ,"DataPipeLineTaskConfigId" INT NULL REFERENCES ods."DataPipeLineTaskConfig" ("DataPipeLineTaskConfigId")
    ,"DataPipeLineMappingId"    INT NULL REFERENCES ods."DataPipeLineMapping" ("DataPipeLineMappingId")
    ,"TaskTypeId"               INT NOT NULL REFERENCES ods."TaskType" ("TaskTypeId")
    ,"ParentTaskId"             INT REFERENCES ods."DataPipeLineTask" ("DataPipeLineTaskId")
    ,"RunSequence"              INT NOT NULL
    ,"OnErrorGotoNext"          BOOLEAN DEFAULT false
    ,"DeletedFlag"              BOOLEAN NOT NULL DEFAULT false
    ,"CreatedDtTm"              timestamp not null DEFAULT CURRENT_TIMESTAMP
    ,"UpdatedDtTm"              timestamp not null DEFAULT CURRENT_TIMESTAMP
    ,CONSTRAINT UNQ_DataPiplelineTask UNIQUE("DataPipeLineTaskConfigId", "DataPipeLineMappingId", "SourceEntity", "ParentTaskId")
    ,CONSTRAINT UNQ_DataPiplelineTask_RunSequence UNIQUE("DataPipeLineTaskConfigId", "DataPipeLineMappingId", "RunSequence", "ParentTaskId")
    ,CONSTRAINT CHCK_DataPipeLineTask_RunSeq    CHECK ("RunSequence" > 0)
);

-- Examples: dynamoDB URL, Base S3 bucket URL, Dynamo Table Name
CREATE TABLE IF NOT EXISTS ods."TaskAttribute"
(
     "TaskAttributeId"      SERIAL NOT NULL
    ,"DataPipeLineTaskId"   INT NOT NULL REFERENCES ods."DataPipeLineTask" ("DataPipeLineTaskId")
    ,"AttributeId"          INT NOT NULL REFERENCES ods."Attribute"("AttributeId")
    ,"AttributeValue"       VARCHAR(300) NOT NULL
    ,"CreatedDtTm"          timestamp not null DEFAULT CURRENT_TIMESTAMP
    ,"UpdatedDtTm"          timestamp not null DEFAULT CURRENT_TIMESTAMP
    ,CONSTRAINT UNQ_TaskAttribute UNIQUE("DataPipeLineTaskId", "AttributeId")
);

CREATE TABLE IF NOT EXISTS ods."DataPipeLineTaskParam" 
(
     "DataPipeLineTaskParamId" SERIAL PRIMARY KEY--INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY
    ,"DataPipeLineTaskId"    INT NOT NULL REFERENCES ods."DataPipeLineTask"("DataPipeLineTaskId")
    ,"RangeTypeId"           INT NOT NULL REFERENCES ods."RangeType"("RangeTypeId")
    ,"AltRangeTypeId"        INT NULL     REFERENCES ods."RangeType"("RangeTypeId")
    ,"BatchSize"             INT NOT NULL DEFAULT -1 -- No of Rows within the interval
    ,"InitialRangeValue"     VARCHAR(40) NULL
    ,"InitialAltRangeValue"  VARCHAR(40) NULL   
    ,"Interval"              INT NOT NULL
    ,"IntervalTypeId"        INT NOT NULL REFERENCES ods."IntervalType"("IntervalTypeId")
    ,"LastDataPipeLineTaskQueueId"   INT NULL
    ,"DeletedFlag"           BOOLEAN NOT NULL DEFAULT false
    ,"CreatedDtTm"           timestamp not null DEFAULT CURRENT_TIMESTAMP
    ,"UpdatedDtTm"           timestamp not null DEFAULT CURRENT_TIMESTAMP
    ,CONSTRAINT UNQ_DataPipeLineTaskParam UNIQUE("DataPipeLineTaskId")
);

CREATE TABLE IF NOT EXISTS ods."DataPipeLineTaskQueue"
(
     "DataPipeLineTaskQueueId"  SERIAL PRIMARY KEY
    ,"DataPipeLineTaskId"       INT NOT NULL REFERENCES ods."DataPipeLineTask"("DataPipeLineTaskId")
    ,"ParentTaskId"             INT
    ,"RunSequence"              INT NOT NULL
    ,"TaskStatusId"             INT NOT NULL REFERENCES ods."TaskStatus"("TaskStatusId")
    ,"StartDtTm"                timestamp null
    ,"EndDtTm"                  timestamp null
    ,"Error"                    jsonb null
    ,"CreatedDtTm"              timestamp not null  default CURRENT_TIMESTAMP
    ,"UpdatedDtTm"              timestamp not null  default CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS ods."DataPipeLineTaskQueueParam"
(
     "DataPipeLineTaskQueueId"  INT PRIMARY KEY REFERENCES ods."DataPipeLineTaskQueue"("DataPipeLineTaskQueueId")
    ,"StartRange"               VARCHAR(20) NOT NULL
    ,"EndRange"                 VARCHAR(20) NOT NULL
    ,"AltStartRange"            VARCHAR(20) NULL
    ,"AltEndRange"              VARCHAR(20) NULL
    ,"CreatedDtTm"              timestamp not null  default CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS ods."TaskQueueAttributeLog"
(
     "TaskQueueAttributeLogId"  SERIAL PRIMARY KEY
    ,"DataPipeLineTaskQueueId"  INT NOT NULL REFERENCES ods."DataPipeLineTaskQueue"("DataPipeLineTaskQueueId")
    ,"AttributeName"            VARCHAR(60) NOT NULL
    ,"AttributeValue"           VARCHAR(500) NOT NULL
    ,"CreatedDtTm"              timestamp not null  default CURRENT_TIMESTAMP
    ,"UpdatedDtTm"              timestamp not null  default CURRENT_TIMESTAMP
    ,CONSTRAINT UNQ_TaskQueueAttributeLog UNIQUE("DataPipeLineTaskQueueId", "AttributeName")
);

/*
CREATE TABLE "TaskDependency"
(
   "TaskDependencyId"       SERIAL PRIMARY KEY
   ,"TaskId"                INT NOT NULL REFERENCES "BatchConfig"("BatchConfigId")
   ,"RelatedTaskId"         INT NOT NULL REFERENCES "BatchConfig"("BatchConfigId")
   ,"RelationshipTypeId"    INT NOT NULL REFERENCES "RelationShipType"("RelationShipTypeId")
   ,"DeletedFlag"           BOOLEAN NOT NULL DEFAULT false
   ,"CreatedDtTm"           timestamp not null
   ,"UpdatedDtTm"           timestamp not null
);
*/