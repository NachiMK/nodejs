DROP FUNCTION IF EXISTS log."udf_InsertApiLog"(varchar(255), INT);

CREATE OR REPLACE FUNCTION log."udf_InsertApiLog"(apilog jsonb) 
RETURNS 
    INTEGER AS $$
DECLARE
    NewId INT;
    SourceURL             VARCHAR(500);
    LoggedInUser          VARCHAR(50);
    SessionId             VARCHAR(50);
    EntityPublicKey1      VARCHAR(50);
    EntityPublicKeyName1  VARCHAR(50);
    LambdaName            VARCHAR(255);
    CloudWatchRequestId   VARCHAR(50);
    APIStartTime          TIMESTAMP;
    APIEndTime            TIMESTAMP;
    Request               JSONB;
    ResponseEntities      JSONB;
    APIStatus             VARCHAR(20);
    ErrorMessage          VARCHAR(500);
    Error                 JSONB;

    msgText text;
    exceptionDetail text;
    exceptionHint text;
BEGIN

    BEGIN
        SourceURL             := CAST(apilog->>'SourceURL' as VARCHAR(500));
        LoggedInUser          := CAST(apilog->>'LoggedInUser' AS VARCHAR(50));
        SessionId             := CAST(apilog->>'SessionId' AS VARCHAR(50));
        EntityPublicKey1      := CAST(apilog->>'EntityPublicKey1' AS VARCHAR(50));
        EntityPublicKeyName1  := CAST(apilog->>'EntityPublicKeyName1' AS VARCHAR(50));
        LambdaName            := CAST(apilog->>'LambdaName' AS VARCHAR(255));
        CloudWatchRequestId   := CAST(apilog->>'CloudWatchRequestId' AS VARCHAR(50));
        APIStartTime          := CAST(apilog->>'APIStartTime' AS TIMESTAMP);
        APIEndTime            := CAST(apilog->>'APIEndTime' AS TIMESTAMP);
        Request               := CAST(apilog->>'Request' AS JSONB);
        ResponseEntities      := CAST(apilog->>'ResponseEntities' AS JSONB);
        APIStatus             := CAST(apilog->>'APIStatus' AS VARCHAR(20));
        ErrorMessage          := CAST(apilog->>'ErrorMessage' AS VARCHAR(500));
        Error                 := CAST(apilog->>'Error' AS JSONB);
    EXCEPTION WHEN OTHERS THEN
        -- ignore the exception
        GET STACKED DIAGNOSTICS msgText = MESSAGE_TEXT,
                          exceptionDetail = PG_EXCEPTION_DETAIL,
                          exceptionHint = PG_EXCEPTION_HINT;
        RAISE NOTICE 'Error in parsing apilog: %', apilog;
        RAISE NOTICE 'Error: Message: %  Exception Detail: % Exception Hint: %', msgText, exceptionDetail, exceptionHint;
    END;

    IF length(SourceURL) = 0 THEN
        RAISE EXCEPTION 'SourceURL Cannot be Empty, SourceURL: --> %', SourceURL
            USING HINT = 'Please check your SourceURL parameter';
    END IF;

    IF length(LoggedInUser) = 0 OR LoggedInUser IS NULL THEN
        RAISE EXCEPTION 'LoggedInUser Cannot be Empty, LoggedInUser: --> %', LoggedInUser
            USING HINT = 'Please check your LoggedInUser parameter';
    END IF;

    IF length(APIStatus) = 0 OR APIStatus IS NULL THEN
        RAISE EXCEPTION 'APIStatus Cannot be Empty, APIStatus: --> %', APIStatus
            USING HINT = 'Please check your APIStatus parameter';
    END IF;

    IF length(LambdaName) = 0 OR LambdaName IS NULL THEN
        RAISE EXCEPTION 'LambdaName Cannot be Empty, LambdaName: --> %', LambdaName
            USING HINT = 'Please check your LambdaName parameter';
    END IF;

    IF APIStartTime IS NULL THEN
        APIStartTime := CURRENT_TIMESTAMP;
    END IF;

    -- Insert a Row
    INSERT INTO log."ApiLog" 
    (
         "SourceURL"
        ,"LoggedInUser"
        ,"SessionId"
        ,"EntityPublicKey1"
        ,"EntityPublicKeyName1"
        ,"LambdaName"
        ,"CloudWatchRequestId"
        ,"APIStartTime"
        ,"APIEndTime"
        ,"Request"
        ,"ResponseEntities"
        ,"APIStatus"
        ,"ErrorMessage"
        ,"Error"
    )
    SELECT
         SourceURL
        ,LoggedInUser
        ,SessionId
        ,EntityPublicKey1
        ,EntityPublicKeyName1
        ,LambdaName
        ,CloudWatchRequestId
        ,APIStartTime
        ,APIEndTime
        ,Request
        ,ResponseEntities
        ,APIStatus
        ,ErrorMessage
        ,Error
    RETURNING   "ApiLogId"
    INTO        NewId;

    RETURN NewId;
END;
$$ LANGUAGE plpgsql;
/*
    SELECT * FROM log."udf_InsertApiLog"('{"SourceURL":"http://url.com","LoggedInUser":"Nachi"
    ,"APIStatus":"Start","LambdaName":"lll"
    ,"Request":"{\"Param\":\"Value\",\"Param2\":\"Value2\"}"
    ,"Error":"{\"err\":\"msg\"}"}'::jsonb);
*/