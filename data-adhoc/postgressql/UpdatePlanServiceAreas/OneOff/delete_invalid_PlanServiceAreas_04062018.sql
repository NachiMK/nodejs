CREATE TABLE IF NOT EXISTS "PlanServiceAreas_BAK_EmptyHios" AS 
SELECT * FROM public."PlanServiceAreas" WHERE "HiosPlanID" IS NULL;

SELECT * FROM "PlanServiceAreas_BAK_EmptyHios"

BEGIN;
DELETE FROM public."PlanServiceAreas" WHERE "HiosPlanID" IS NULL;
--ROLLBACK
COMMIT;

-- Delete the Dental ones that we know for sure has another
-- Plan Service Area entry
BEGIN;
DELETE 
FROM  "PlanServiceAreas" as psa
WHERE "Year" = 2018 
AND   "ServiceAreaName" LIKE '%Dental%'
AND   EXISTS ( SELECT 1 FROM "PlanServiceAreas" as T 
                WHERE 
                   T."Year"             = psa."Year"
               AND T."HiosPlanID"       = psa."HiosPlanID"
               AND T."IssuerID"         = psa."IssuerID"
               AND T."State"            = psa."State"
               AND T."ServiceAreaID"    = psa."ServiceAreaID"
               AND T."CountyCode"       = psa."CountyCode"
               AND COALESCE(T."Zipcode", '0') = COALESCE(psa."Zipcode", '0')
               AND T."ServiceAreaName" NOT LIKE '%Dental%'
               )
;
-- ROLLBACK;               
COMMIT;

DROP TABLE IF EXISTS "PlanServiceAreaDups";
CREATE TEMP TABLE "PlanServiceAreaDups" AS 
SELECT 
        "Year"
        ,"State"
        ,"IssuerID"
        ,"HiosPlanID"
        ,"ServiceAreaID"
        ,"CountyCode"
        ,"Zipcode"
        ,COUNT(*) AS Cnt
FROM   public."PlanServiceAreas"
WHERE  1 = 1
AND    "Year" = 2018
--AND    "State" = 'CA'
--AND    "IsActive" = true
GROUP BY
        "Year"
       ,"State"
       ,"IssuerID"
       ,"HiosPlanID"
       ,"ServiceAreaID"
       ,"CountyCode"
       ,"Zipcode"
HAVING COUNT(*) > 1;

-- Find Dups
DROP TABLE IF EXISTS "PlanServiceAreaDupsAndOrig";
CREATE TEMP TABLE "PlanServiceAreaDupsAndOrig" AS 
SELECT 
         "PlanServiceAreaID"
        ,"Year"
        ,"State"
        ,"IssuerID"
        ,"SourceName"
        ,"HiosPlanID"
        ,"ServiceAreaID"
        ,"ServiceAreaName"
        ,"CoverEntireState"
        ,"CountyCode"
        ,"PartialCounty"
        ,"Zipcode"
        ,"IsActive"
        ,ROW_NUMBER() OVER (PARTITION BY "Year", "State", "IssuerID", "HiosPlanID", "ServiceAreaID", "CountyCode", "Zipcode" ORDER BY "IsActive" DESC, "PlanServiceAreaID" DESC)
FROM   public."PlanServiceAreas" as psa
WHERE  1 = 1
AND    "Year" = 2018
--AND    "State" = 'CA'
--AND    "IsActive" = true
AND    EXISTS ( SELECT 1 FROM "PlanServiceAreaDups" as T 
                WHERE 
                   T."Year"             = psa."Year"
               AND T."HiosPlanID"       = psa."HiosPlanID"
               AND T."IssuerID"         = psa."IssuerID"
               AND T."State"            = psa."State"
               AND T."ServiceAreaID"    = psa."ServiceAreaID"
               AND COALESCE(T."CountyCode", '0')   = COALESCE(psa."CountyCode", '0')
               AND COALESCE(T."Zipcode", '0') = COALESCE(psa."Zipcode", '0')
               )
ORDER BY
        "Year"
       ,"State"
       ,"IssuerID"
       ,"HiosPlanID"
       ,"ServiceAreaID"
       ,"CountyCode"
       ,"Zipcode";


-- Dups to delete
SELECT * FROM "PlanServiceAreaDupsAndOrig" WHERE "row_number" >= 2;

CREATE TABLE IF NOT EXISTS public."PlanServicesArea_BAK_Deleted" AS 
SELECT * FROM public."PlanServiceAreas" as psa
WHERE  EXISTS (SELECT 1 FROM "PlanServiceAreaDupsAndOrig" as T WHERE T."PlanServiceAreaID" = psa."PlanServiceAreaID" AND T."row_number" >= 2); 

/* -- Rows deleted in Prod. Based on email approval from Lori on 4/9/2018
(
37324
,37325
,37326
,39339
,39305
,39330
,39351
,39368
,39142
,39170
,39212
,39217
,39231
,39246
,39299
,39090
,39328
,39062
,39093
,39120
,39162
,39178
,39185
,39187
,39112
,39303
,39325
,39331
,39335
,39347
,39359
,39370
,39071
,39076
,39079
,39095
,39114
,39122
,39135
,39183
,39190
,39200
,39216
,39225
,39272
,39311
,39104
,39109
,39302
,39343
,39063
,39084
,39125
,39128
,39146
,39153
,39213
,39236
,39277
,39296
,39317
,39220
,39308
,39316
,39085
,39158
,39195
,39274
,39282
,39314
,39353
,39270
,39322
,39105
,39160
,39163
,39165
,39182
,39207
,39229
,39233
,39239
,39257
,39268
,39284
,39069
,39179
,39292
,39068
,39356
,39078
,39097
,39100
,39107
,39152
,39210
,39228
,39254
,39266
,39290
,39275
,39337
,39123
,39129
,39140
,39174
,39243
,39251
,39256
,39285
,39175
,39198
,39350
,39363
,39365
,39116
,39132
,39171
,39192
,39203
,39206
,39262
,39293
,39324
,39074
,39082
,39088
,39194
,39201
,39056
,39264
,39287
,39310
,39320
,39060
,39066
,39144
,39148
,39222
,39238
,39134
,39156
,39241
,39334
,39342
,39345
,39357
,39372
,39057
,39092
,39118
,39138
,39150
,39168
,39223
,39248
,39250
,39259
,39361
,39101
,39279
,39298
,39332
,39360
,39080
,39096
,39113
,39214
,39181
,39176
,39115
,39319
,39055
,39276
,39318
,39340
,39362
,39067
,39089
,39111
,39133
,39155
,39197
,39219
,39242
,39263
,39288
,39301
,39304
,39306
,39307
,39309
,39312
,39313
,39315
,39321
,39323
,39326
,39327
,39329
,39333
,39336
,39338
,39341
,39344
,39346
,39348
,39349
,39352
,39354
,39355
,39358
,39364
,39366
,39367
,39369
,39371
,39058
,39059
,39061
,39064
,39065
,39070
,39072
,39073
,39075
,39077
,39081
,39083
,39086
,39087
,39091
,39094
,39098
,39099
,39102
,39103
,39106
,39108
,39110
,39117
,39119
,39121
,39124
,39126
,39127
,39130
,39131
,39136
,39137
,39139
,39141
,39143
,39145
,39147
,39149
,39151
,39154
,39157
,39159
,39161
,39164
,39166
,39167
,39169
,39172
,39173
,39177
,39180
,39184
,39186
,39188
,39189
,39191
,39193
,39196
,39199
,39202
,39204
,39205
,39208
,39209
,39211
,39215
,39218
,39221
,39224
,39226
,39227
,39230
,39232
,39234
,39235
,39237
,39240
,39244
,39245
,39247
,39249
,39252
,39253
,39255
,39258
,39260
,39261
,39265
,39267
,39269
,39271
,39273
,39278
,39280
,39281
,39283
,39286
,39289
,39291
,39294
,39295
,39297
,39300
,39035
,7550
,39045
,7551
,39046
,7552
,39047
,7554
,39049
,7556
,39051
,7557
,39052
,7559
,39054
,7560
,39373
,39029
,7561
,39030
,7562
,39031
,7564
,39033
,7566
,39036
,7568
,39038
,7569
,39039
,7570
,39040
,7571
,39041
,7572
,39042
,7573
,39043
,7574
,39044
,7575
,39048
,7553
,39050
,7555
,39053
,7558
,39032
,7563
,39034
,7565
,39037
,7567
,8005
,38257
,38173
,38089
,10663
,11579
,11578
,11574
,11570
,11572
,11582
,11583
,11577
,11571
,11575
,11580
,11573
,11581
,11576
,10658
,10727
,10677
,10703
,10733
,10678
,10704
,10734
,10674
,10679
,10705
,10730
,10735
,10616
,10623
,10664
,10667
,10684
,10687
,10694
,10700
,10710
,10716
,10617
,10620
,10624
,10627
,11593
,11592
,11588
,11584
,11586
,11596
,11597
,11591
,11585
,11589
,11594
,11587
,11595
,11590
,10635
,10637
,10641
,10644
,10648
,10659
,10661
,10665
,10668
,10671
,10675
,10680
,10682
,10685
,10688
,10691
,10695
,10697
,10701
,10706
,10711
,10714
,10717
,10728
,10731
,10736
,10738
,11627
,11633
,11634
,11635
,11636
,11637
,11638
,11628
,11629
,11691
,11692
,11693
,11694
,11695
,11696
,11697
,11698
,11699
,38763
,38764
,38765
,38766
,38767
,27276
,27277
,27279
,27280
,27282
,27283
,27284
,27285
,27286
,27287
,27288
,27290
,27291
,27292
,27293
,27294
,27295
,27296
,27297
,27298
,27300
,27302
,27303
,27304
,27305
,27308
,27309
,27311
,27313
,27318
,27314
,27315
,27316
,27317
,27319
,27320
,27321
,27322
,27323
,27324
,27325
,27327
,27328
,27329
,27330
,27331
,27332
,27333
,27334
,27335
,27336
,27337
,27338
,27339
,27340
,27346
,27347
,27348
,27349
,27350
,27351
,27352
,27353
,27354
,27355
,27358
,27359
,27360
,36760
,38657
,12227
,11556
,11557
,11566
,11558
,11559
,11560
,11561
,11564
,16713
,36622
,38957
,36623
,36624
,36625
,36626
,36627
,36628
,36629
,36630
,18651
,37290
,19674
,19676
,19677
,19681
,19683
,19684
,38745
,19691
,19673
,19675
,19678
,19679
,19682
,19685
,19686
,38742
,19687
,19688
,19692
,19693
,19695
,38885
,19690
,19694
,19680
,19911
,19912
,19913
,19914
,19915
,19916
,19917
,19918
,19919
,19920
,19921
,19922
,19923
);
*/

BEGIN;
DELETE 
FROM   "PlanServiceAreas" as pa
WHERE   EXISTS (SELECT 1 FROM public."PlanServicesArea_BAK_Deleted" as T WHERE T."PlanServiceAreaID" = pa."PlanServiceAreaID");
--ROLLBACK;
COMMIT;

