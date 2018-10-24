DROP TABLE IF EXISTS "PlanBenefitLookup";
CREATE TABLE public."PlanBenefitLookup" (
     "PlanBenefitLookupId" SERIAL PRIMARY KEY
    ,"Year" SMALLINT NOT NULL
    ,"Benefit" VARCHAR(150) NOT NULL
    ,"Sort" SMALLINT NOT NULL
    ,"ColorCode" VARCHAR(30) NULL
    ,"IsActive" BOOLEAN NOT NULL
    ,"ExcludeDuplicateBenefit" BOOLEAN NOT NULL
    ,"CreatedDtTm" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    ,"UpdatedDtTm" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE UNIQUE INDEX UNQ_PlanBenefitLookup ON "PlanBenefitLookup" ("Year", "Benefit");

WITH CTEBenefits
AS 
(
SELECT 'IndividualMedicalDeductible' as "Benefit", 1 as "Sort", 'None' as "ColorCode", FALSE as "Exclude" UNION
SELECT 'FamilyMedicalDeductible' as "Benefit", 2 as "Sort", 'None' as "ColorCode", FALSE as "Exclude" UNION
SELECT 'IndividualOutOfPocketMax' as "Benefit", 3 as "Sort", 'None' as "ColorCode", FALSE as "Exclude" UNION
SELECT 'FamilyOutOfPocketMax' as "Benefit", 4 as "Sort", 'None' as "ColorCode", FALSE as "Exclude" UNION
SELECT 'IndividualDrugDeductible' as "Benefit", 5 as "Sort", 'None' as "ColorCode", FALSE as "Exclude" UNION
SELECT 'FamilyDrugDeductible' as "Benefit", 6 as "Sort", 'None' as "ColorCode", FALSE as "Exclude" UNION
SELECT 'PrimaryCarePhysicianOfficeVisit' as "Benefit", 7 as "Sort", 'Orange' as "ColorCode", FALSE as "Exclude" UNION
SELECT 'SpecialistVisit' as "Benefit", 8 as "Sort", 'Orange' as "ColorCode", FALSE as "Exclude" UNION
SELECT 'LaboratoryTests' as "Benefit", 9 as "Sort", 'None' as "ColorCode", FALSE as "Exclude" UNION
SELECT 'DiagnosticImaging' as "Benefit", 10 as "Sort", 'None' as "ColorCode", FALSE as "Exclude" UNION
SELECT 'Imaging' as "Benefit", 11 as "Sort", 'None' as "ColorCode", FALSE as "Exclude" UNION
SELECT 'GenericDrugs' as "Benefit", 12 as "Sort", 'Blue' as "ColorCode", FALSE as "Exclude" UNION
SELECT 'GenericDrugsMailOrder' as "Benefit", 13 as "Sort", 'Blue' as "ColorCode", FALSE as "Exclude" UNION
SELECT 'PreferredBrandDrugs' as "Benefit", 14 as "Sort", 'Blue' as "ColorCode", FALSE as "Exclude" UNION
SELECT 'PreferredBrandDrugsMailOrder' as "Benefit", 15 as "Sort", 'Blue' as "ColorCode", FALSE as "Exclude" UNION
SELECT 'NonPreferredBrandDrugs' as "Benefit", 16 as "Sort", 'Blue' as "ColorCode", FALSE as "Exclude" UNION
SELECT 'NonPreferredBrandDrugsMailOrder' as "Benefit", 17 as "Sort", 'Blue' as "ColorCode", FALSE as "Exclude" UNION
SELECT 'SpecialtyDrugs' as "Benefit", 18 as "Sort", 'Blue' as "ColorCode", FALSE as "Exclude" UNION
SELECT 'SpecialtyDrugsMailOrder' as "Benefit", 19 as "Sort", 'Blue' as "ColorCode", FALSE as "Exclude" UNION
SELECT 'OutpatientFacilityFee' as "Benefit", 20 as "Sort", 'None' as "ColorCode", FALSE as "Exclude" UNION
SELECT 'OutpatientSurgeryPhysicianSurgicalServices' as "Benefit", 21 as "Sort", 'None' as "ColorCode", FALSE as "Exclude" UNION
SELECT 'EmergencyRoomFacility' as "Benefit", 22 as "Sort", 'Green' as "ColorCode", FALSE as "Exclude" UNION
SELECT 'EmergencyRoomProfessional' as "Benefit", 23 as "Sort", 'Green' as "ColorCode", FALSE as "Exclude" UNION
SELECT 'Ambulance' as "Benefit", 24 as "Sort", 'Green' as "ColorCode", FALSE as "Exclude" UNION
SELECT 'UrgentCare' as "Benefit", 25 as "Sort", 'Green' as "ColorCode", FALSE as "Exclude" UNION
SELECT 'InpatientHospitalServices' as "Benefit", 26 as "Sort", 'None' as "ColorCode", FALSE as "Exclude" UNION
SELECT 'InpatientPhysicianAndSurgicalServices' as "Benefit", 27 as "Sort", 'None' as "ColorCode", FALSE as "Exclude" UNION
SELECT 'MentalHealthOutpatient' as "Benefit", 28 as "Sort", 'Yellow' as "ColorCode", FALSE as "Exclude" UNION
SELECT 'MentalHealthInpatient' as "Benefit", 29 as "Sort", 'Yellow' as "ColorCode", FALSE as "Exclude" UNION
SELECT 'MentalHealthProfessionalInpatient' as "Benefit", 30 as "Sort", 'Yellow' as "ColorCode", FALSE as "Exclude" UNION
SELECT 'HomeHealthCare' as "Benefit", 31 as "Sort", 'Yellow' as "ColorCode", FALSE as "Exclude" UNION
SELECT 'RehabilitationServices' as "Benefit", 32 as "Sort", 'None' as "ColorCode", FALSE as "Exclude" UNION
SELECT 'SkilledNursing' as "Benefit", 33 as "Sort", 'None' as "ColorCode", FALSE as "Exclude" UNION
SELECT 'DurableMedicalEquipment' as "Benefit", 34 as "Sort", 'None' as "ColorCode", FALSE as "Exclude" UNION
SELECT 'Hospice' as "Benefit", 35 as "Sort", 'None' as "ColorCode", FALSE as "Exclude" UNION
SELECT 'Acupuncture' as "Benefit", 36 as "Sort", 'Grey' as "ColorCode", FALSE as "Exclude" UNION
SELECT 'Chiropractic' as "Benefit", 37 as "Sort", 'Grey' as "ColorCode", FALSE as "Exclude" UNION
SELECT 'Telemedicine' as "Benefit", 38 as "Sort", 'Grey' as "ColorCode", FALSE as "Exclude" UNION
SELECT 'PediatricDental' as "Benefit", 39 as "Sort", 'None' as "ColorCode", FALSE as "Exclude" UNION
SELECT 'PediatricGlasses' as "Benefit", 40 as "Sort", 'None' as "ColorCode", FALSE as "Exclude" UNION
SELECT 'PediatricVision' as "Benefit", 41 as "Sort", 'None' as "ColorCode", FALSE as "Exclude" UNION
SELECT 'MentalHealthProfessionalOutpatient' as "Benefit", -1 as "Sort", 'None' as "ColorCode", TRUE as "Exclude" UNION
SELECT 'HabilitationServices' as "Benefit", -1 as "Sort", 'None' as "ColorCode", TRUE as "Exclude" UNION
SELECT 'OtherPractitionerOfficeVisit' as "Benefit", -1 as "Sort", 'None' as "ColorCode", TRUE as "Exclude" UNION
SELECT 'OutpatientRehabilitationServices' as "Benefit", -1 as "Sort", 'None' as "ColorCode", TRUE as "Exclude" UNION
SELECT 'PreventiveCare' as "Benefit", -1 as "Sort", 'None' as "ColorCode", TRUE as "Exclude"
),
CTEYears
AS
(
    SELECT 2017 as "Year" UNION
    SELECT 2018 as "Year" UNION
    SELECT 2019 as "Year" UNION
    SELECT 2020 as "Year"
)
INSERT INTO "PlanBenefitLookup"
    (
        "Year"
       ,"Benefit"
       ,"Sort"
       ,"ColorCode"
       ,"IsActive"
       ,"ExcludeDuplicateBenefit"
       ,"CreatedDtTm"
    )
SELECT 
     Y."Year" AS "Year" 
    ,C."Benefit"  as "Benefit"
    ,C."Sort" as "Sort"
    ,C."ColorCode" as "ColorCode"
    ,true as "IsActive"
    ,C."Exclude"  as "ExcludeDuplicateBenefit"
    ,CURRENT_TIMESTAMP "CreatedDtTm"
FROM CTEBenefits C, CTEYears Y
WHERE NOT EXISTS (SELECT 1 FROM "PlanBenefitLookup" AS PL WHERE PL."Year" = Y."Year" AND PL."Benefit" = C."Benefit")
ORDER BY Y."Year", C."Sort";

SELECT * FROM public."PlanBenefitLookup";
