CREATE TABLE public."CastFunctionMapping"(
     "CastFunctionMappingId" SERIAL
    ,"SourceType" VARCHAR(75) NOT NULL
    ,"TargetType" VARCHAR(75) NOT NULL
    ,"CastFunction" VARCHAR(256) NOT NULL
);