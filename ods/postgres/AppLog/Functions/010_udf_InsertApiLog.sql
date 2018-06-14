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
            -- LoggedInUser          VARCHAR(50);
            -- SessionId             VARCHAR(50);
            -- EntityPublicKey1      VARCHAR(50);
            -- EntityPublicKeyName1  VARCHAR(50);
            -- LambdaName            VARCHAR(255);
            -- CloudWatchRequestId   VARCHAR(50);
            -- APIStartTime          TIMESTAMP;
            -- APIEndTime            TIMESTAMP;
            -- Request               JSONB;
            -- ResponseEntities      JSONB;
            -- APIStatus             VARCHAR(20);
            -- ErrorMessage          VARCHAR(500);
            -- Error                 JSONB;
    EXCEPTION
        -- ignore the exception
        GET STACKED DIAGNOSTICS msgText = MESSAGE_TEXT,
                          exceptionDetail = PG_EXCEPTION_DETAIL,
                          exceptionHint = PG_EXCEPTION_HINT;
        RAISE NOTICE 'Error in parsing apilog: %', apilog
        RAISE NOTICE 'Error: Message: %  Exception Detail: % Exception Hint: %', msgText, exceptionDetail, exceptionHint 
    END;

    IF length(SourceURL) = 0 THEN
        RAISE EXCEPTION 'SourceURL Cannot be Empty, SourceURL: --> %', SourceURL
            USING HINT = 'Please check your SourceURL parameter';
    END IF;

    IF length(LoggedInUser) = 0 THEN
        RAISE EXCEPTION 'LoggedInUser Cannot be Empty, LoggedInUser: --> %', LoggedInUser
            USING HINT = 'Please check your LoggedInUser parameter';
    END IF;

    IF length(APIStatus) = 0 THEN
        RAISE EXCEPTION 'APIStatus Cannot be Empty, APIStatus: --> %', APIStatus
            USING HINT = 'Please check your APIStatus parameter';
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
    RETURNING   NewId;
    RETURN;
END;
$$ LANGUAGE plpgsql;
/*
    SELECT * FROM log."udf_InsertApiLog"('"SourceURL":"http://url.com"');
*/