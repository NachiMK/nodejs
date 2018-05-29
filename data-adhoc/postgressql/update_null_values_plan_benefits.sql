UPDATE "PlanBenefits" SET "CopayDayLimit" = -1.0, "UpdatedDate" = NOW() WHERE "CopayDayLimit" = 0;
UPDATE "PlanBenefits" SET "CopayDays" = -1.0, "UpdatedDate" = NOW() WHERE "CopayDays" = 0;
UPDATE "PlanBenefits" SET "MemberServicePaidCap" = -1.0, "UpdatedDate" = NOW() WHERE "MemberServicePaidCap" = 0;
UPDATE "PlanBenefits" SET "CoverageVisitLimit" = -1.0, "UpdatedDate" = NOW() WHERE "CoverageVisitLimit" = 0;
UPDATE "PlanBenefits" SET "Sort" = -1.0, "UpdatedDate" = NOW() WHERE "Sort" = 0;
UPDATE "PlanBenefits" SET "FirstDollarVisits" = -1.0, "UpdatedDate" = NOW() WHERE "FirstDollarVisits" = 0;