-- DROP TABLE StageMelissaLocations;
CREATE TABLE IF NOT EXISTS StageMelissaLocations
(
    "StateProvince"             VARCHAR(2)
   ,"StateAndRatingAreaNumeric" VARCHAR(4)
   ,"County"                    VARCHAR(100)
   ,"RatingAreaNumeric"         VARCHAR(2)
   ,"CountyFipsCode"            VARCHAR(5)
   ,"ZipCode"	                VARCHAR(5)
   ,"Year"                      INT
);


-- DROP TABLE "MelissaLocations";
CREATE TABLE IF NOT EXISTS "MeilssaLocations"
(
    "LocationID"                uuid NOT NULL
   ,"StateProvince"             VARCHAR(2) NOT NULL
   ,"StateAndRatingAreaNumeric" VARCHAR(4)
   ,"County"                    VARCHAR(100)
   ,"RatingAreaNumeric"         VARCHAR(2)
   ,"CountyFipsCode"            VARCHAR(5)
   ,"ZipCode"	                VARCHAR(5)
   ,"Year"                      INT NOT NULL
   ,"CreatedDate"               TIMESTAMP DEFAULT CURRENT_TIMESTAMP
   ,"UpdatedDate"               TIMESTAMP DEFAULT CURRENT_TIMESTAMP
   ,CONSTRAINT UNQ_prodLocation UNIQUE("StateProvince", "Year", "County", "RatingAreaNumeric", "CountyFipsCode", "ZipCode")
);


SELECT * FROM StageMelissaLocations;
SELECT * FROM "MeilssaLocations";


/*
psql -h primary-01.cwoqm2lwdsxk.us-west-2.rds.amazonaws.com -p 5432 -U hixme_root -W -d plans_prod -c "\copy public.StageMelissaLocations 
from '/Users/Nachi/Documents/work/Projects/Locations/LocationsTable_rev4.18-1.csv'  WITH DELIMITER ',' null as '' CSV"
*/
