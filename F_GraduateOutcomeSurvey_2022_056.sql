/*
KM--2025/04/08 Line 146
--for the 2022 graduation fact only we use the imputed Ethnic code held in the source data set information only
--this should pick up about 25K records (mostly marked as 17 code which are 'White - Legacy'  





--Test to see if Foundation agrees with Staging
--This need to be run before EL Load to insure Cut 2 of GradExtract is held in FL and STG (NOT the first cut)
SELECT COUNT(1)

FROM GradOutcomes.T072_Core_STGCheck STG
LEFT OUTER JOIN GradOutcomes.C072_Core FL ON FL.GRADUATEKEY=STG.GRADUATEKEY
WHERE 
STG.DW_FromDate=20210801 AND 
FL.DW_FromDate=20210801 AND
(
ISNULL(STG.XWRK2007SIC,'')<>ISNULL(FL.XWRK2007SIC,'') OR
ISNULL(STG.XWRK2020SOC,'')<> ISNULL(FL.XWRK2020SOC,'') OR
ISNULL(STG.ZRESPSTATUS,'')<> ISNULL(FL.ZRESPSTATUS,'') OR
ISNULL(STG.XWRKHSKILL,'')<> ISNULL(FL.XWRKHSKILL,'') OR
ISNULL(STG.XWRKLOCUC,'')<> ISNULL(FL.XWRKLOCUC,'') OR
ISNULL(STG.XBUSLOCGR,'')<> ISNULL(FL.XBUSLOCGR,'') OR
ISNULL(STG.XEMPLOCUC,'')<> ISNULL(FL.XEMPLOCUC,'') 
)

*/
/*	
	SELECT gos.DW_FromDate, mod.ModeCode, gos.GRADUATEKEY FROM fact.F_GraduateOutcomeSurvey gos
JOIN Reference.D_ModeOfStudy mod
ON mod.S_Mode = gos.S_ModeOfStudy
WHERE gos.dw_fromdate>= 20210801
AND gos.DW_CollectionGroup <> 'FECs'
AND mod.ModeCode = 'NA'
--GROUP BY gos.DW_FromDate, mod.ModeCode
--ORDER BY gos.DW_FromDate, mod.ModeCode DESC

SELECT * FROM GradOutcomes.C072_Core WHERE GRADUATEKEY IN( 4631588,4964665
,4290629,
4744262,
4406395,
4922613) AND dw_fromdate = 20220801


SELECT Z_MODEGRP1 , S.SCSMODE, *
FROM Student.C056_StudentEngagement S
	--SELECT TOP 100 * 		FROM Student.C056_StudentEngagement S
			JOIN Student.[C056_DerivedEngagementSubject] SJ   --3,384,647
			ON SJ.[DK_StudentEngagement] = s.DK_StudentEngagement
			AND SJ.DW_FromDate =20220801
			AND s.DW_FromDate=20220801
			
WHERE S.DK_StudentEngagement in (2162227,
3187592,
1796817,
1391525,
42281,
2055046)--10007789

*/
--056

DECLARE @fromdater INT
DECLARE @todater INT
DECLARE @PCodeDate INT
DECLARE @loadid INT

SET @fromdater		=20220801
SET @todater		=99999999
SET @PCodeDate		=20240801  --latest August year
SET @loadid			= (SELECT CONVERT(INT,CONVERT(VARCHAR,CONVERT(DATE,GETDATE()),112)));


DELETE FROM Fact.F_GraduateOutcomeSurvey WHERE DW_CollectionGroup = '56' AND DW_FromDate = @fromdater
;


drop table if exists dbo.DESubj;

select * into dbo.DESubj 
from Student.[C056_DerivedEngagementSubject] 
where dw_fromdate = @fromdater


DROP TABLE IF EXISTS dbo.GOSub;
SELECT * INTO GOSub FROM [GradOutcomes].[C072_Core] G WHERE G.DW_FromDate = @fromdater
--HECOS not JAXCode from 2019
--F_XOBTNG01 
--g.XMLOCUC looks to have been removed resulting in S_CountyOfUK_GO -1
--HERE

DROP TABLE IF EXISTS dbo.DIS;

		SELECT DISTINCT   INSTID, SID, 
		CASE WHEN COUNT(DISABILITY) OVER (PARTITION BY INSTID, SID) > 1 THEN '1M' ELSE CASE WHEN DISABILITY = '' THEN '00' ELSE DISABILITY END END AS DISABILITY, 
		COUNT(DISABILITY) OVER (PARTITION BY INSTID, SID) Disability_Count, 'Y' AS MRK_DisabilityKnown 
		INTO dbo.DIS 
		FROM [Student].[V056_Disability]  
		--FROM HDP.[V_Disability] --526364
		WHERE DISABILITY NOT IN( '', '00', '95', '98', '99' )
		AND DW_FromDate = @fromdater
		;
--SELECT COUNT(*), dw_fromdate FROM Fact.F_GraduateOutcomeSurvey GROUP BY DW_FromDate

-- Added to deal with those who return Prefer not to say. In line with Student. #2025LP
DROP TABLE IF EXISTS dbo.DIS_98;
		SELECT INSTID,SID,DISABILITY 
		INTO dbo.DIS_98
		FROM [Student].[V056_Disability]  
		WHERE DISABILITY = '98'
		AND DW_FromDate = @fromdater

WHILE (SELECT COUNT(*) FROM sys.tables WHERE name LIKE 'postcodersub')>0 
BEGIN DROP TABLE postcodersub END 
;
SELECT p.S_PostCode, p.DW_PostCodeWithNoSpacing, MultipleDeprivationIndex, p.OutwardPostcode, p.InwardsPostcode, p.DW_ToDate,

p.Polar4, p.Polar4Label, p.RegionCode, p.Region, p.DomicileCode, p.Domicile, p.PostCode/*,p.DW_MultipleDeprivationIndex_Current_OpData*/,P.DW_MultipleDeprivationIndex_Current AS DW_MultipleDeprivationIndex_Current_OpData
INTO postcodersub
FROM reference.D_PostCode p 
WHERE (@PCodeDate BETWEEN p.dw_FromDate AND p.DW_ToDate AND S_PostCode<>3074117) OR P.S_PostCode=-6  --to class British forces (BF1)
;

Create INDEX idx_postCode on dbo.postcodersub (PostCode)
;

WHILE (SELECT COUNT(*) FROM sys.tables WHERE name LIKE 'C056_StuEngTemp')>0 
BEGIN DROP TABLE C056_StuEngTemp END 
--SELECT s.SK_C056_Main_FData, s.f_xdomuc01,s.f_xagej01,s.f_disable,
			--CASE WHEN s.F_NATION = '' AND s.ttpcode IS NOT NULL THEN 'GB' ELSE s.F_NATION END AS F_Nation
--			,s.f_xqmode01,s.f_xstudis01,s.F_ETHNIC ,s.F_XOBTNG01,s.F_XQOBTN01,s.f_sexid,s.f_xagrpj01
--			,s.f_xclassf01,s.f_xdomgr01 ,s.f_xdomgr401 ,s.f_xdomreg01,s.f_xinstid01,s.f_xinstg01,s.f_xinstc01,S.F_CAMPID
--			,s.f_instancekey,s.f_husid,s.f_ukprn,s.f_numhus,s.DK_Instance,s.f_enddate,s.f_xethnic01,s.f_xhoos01,s.ttpcode
--			,s.DK_SubjectCourse, s.dw_fromdate, s.dw_todate,s.F_XPGO01, s.f_XELSP01, s.F_MODE, s.F_PARED, s.F_SEC

			
			SELECT s.SK_C056_StudentEngagement, S.Z_PERMADDUC--xdomuc01
			,s.Z_AGEJUL --f_xagej01
			,S.NATION 
			,Z_MODEGRP1 -- f_xqmode01
			-- Prefer not to say
			,CASE WHEN DIS_98.INSTID IS NULL THEN ISNULL(DIS.DISABILITY,'95') ELSE '98' END DISABILITY --#2025LP
			--,dis.DISABILITY --f_xstudis01
			,S.ETHNIC
			,S.Z_QLEVEL_CYC AS XOBTNG01
			,s.Z_QLEVEL_CYC --F_XQOBTN01
			,S.SEXID
			,s.Z_AGEJULGRP1 --f_xagrpj01
			,s.Z_QCLASS_CYC --f_xclassf01
			,s.Z_PERMADDREGION --s.f_xdomgr01
			,NULL AS f_xdomgr401
			,NULL AS f_xdomreg01
			,s.INSTID -- f_xinstid01
			,NULL AS f_xinstg01
			,NULL AS f_xinstc01
			,NULL AS F_CAMPID
			,NULL AS f_instancekey
			,s.SID AS f_husid
			,s.ukprn
			,s.numhus
			,s.DK_StudentEngagement
			,CASE WHEN S.ENGENDDATE IS NULL THEN  s.ENGEXPECTEDENDDATE ELSE s.ENGEXPECTEDENDDATE END AS enddate
			,NULL AS xethnic01
			,s.STUDYABROAD -- f_xhoos01
			,S.TTPCODE -- s.ttpcode
			,sj.DK_DerivedEngagementSubject --instead of DK_SubjectCourse
			, s.dw_fromdate
			, s.dw_todate
			,s.Z_POPGO_CYC -- F_XPGO01
			,NULL AS f_XELSP01
			,s.SCSMODE --s.F_MODE
			,s.PARED
			,s.SEC
			,s.PERMADDPOSTCODE
			,s.PERMADDCOUNTRY
			,s.Z_EXPECTLENGRP1
			INTO dbo.C056_StuEngTemp
			FROM Student.C056_StudentEngagement S
	--SELECT TOP 100 * 		FROM Student.C056_StudentEngagement S
			JOIN Student.[C056_DerivedEngagementSubject] SJ   --3,384,647
			ON SJ.[DK_StudentEngagement] = s.DK_StudentEngagement
			AND SJ.DW_FromDate =@Fromdater
			AND s.DW_FromDate=@Fromdater
			LEFT OUTER JOIN dbo.DIS
			ON DIS.INSTID = s.INSTID AND DIS.SID = s.SID
	--List Student that said 98 Prefer not to say in one record #2025LP
			LEFT OUTER JOIN dbo.DIS_98 
			ON DIS_98.INSTID = S.INSTID AND DIS_98.SID = S.SID 
			WHERE s.dw_fromdate =@fromdater AND S.Z_POPGO_CYC='1' 
;
------------------------------2022 ONLY-----------------------------------------------------
--for the 2022 graduation fact only we use the imputed Ethnic code held in the source data set information only
--this should pick up about 25K records (mostly marked as 17 code which are 'White - Legacy'  

UPDATE S SET
S.ETHNIC=EP.ethnic_impute
			FROM dbo.C056_StuEngTemp S
			--Student.C056_StudentEngagement S
			JOIN [GradOutcomes].[C22056_2503_StudentEngagement_ethnic_impute] EP ON EP.INSTID=S.INSTID AND EP.NUMHUS=S.NUMHUS AND EP.sid=S.f_husid AND EP.Z_POPGO_CYC='1' 
			WHERE s.dw_fromdate =@fromdater AND S.Z_POPGO_CYC='1' 
			AND S.ETHNIC<>EP.ethnic_impute;
-------------------------------------------------------------------------------------------------


--			ALTER TABLE fact.F_GraduateOutcomeSurvey ALTER COLUMN S_Nationality INT null
INSERT INTO fact.F_GraduateOutcomeSurvey
(--GOPopulatedMarker
 s_postcode
,s_Disability
,S_Domicile
,S_County
,S_Age
,S_Nationality
,S_Ethnicity
,S_EthnicityAnalytical
,s_subject
,S_CourseLevel--,S_Qualification
,S_CourseLevel_GO--,S_QualificationGO
,S_Gender
,S_QualificationResult
,S_LengthOfStudy
,S_ModeOfStudy--S_Mode
,s_provider
,S_Date
,S_StandardOccClass
,S_StandardOccClassSelfEmployed
,S_StandardOccClassEmployed
,S_StandardIndClass
,S_StandardIndClassSelfEmployed
,S_StandardIndClassEmployed
,S_CountyOfUK_GO
,S_CountyOfUKSelfEmployedIn_GO
,S_CountyOfUKEmployedIn_GO
,S_Domicile_GO
,S_DomicileSelfEmployedIn_GO
,S_DomicileEmployedIn_GO
,S_CountryOfStudy_GO
,S_CountryDomiciled
,[S_BusinessSelfEmploymentOrPortfolioIntesity]
,[S_EmploymentBasis]
,[S_EmploymentIntensity]
,S_StudyIntensity
,[S_ActivityMeaningful]
,[S_StudyMeaningful]
,[S_WorkMeaningful]
,[S_ActivityOnTrack]
,[S_StudyOnTrack]
,[S_WorkOnTrack]
,[S_ActivitySkills]
,S_StudySkills
,S_WorkSkills
,[S_BusinessSelfEmploymentOrPortfolioMainReasonForTakingTheJob]
,S_MainReasonForTakingTheJob
,[S_QUALREQ]
,S_LifeSatisfaction
,[S_LifeWorthwhile]
,[S_AnxiousYesterday]
,S_HappyYesterday
,[S_mimpact]
,[S_TYPEQUAL]
,[S_xactivity]
,[S_xcurrloc]
,[S_zrespstatus]
,SK_Main_FData
,[DK_SubjectCourse]
,[DK_Instance]
,[DK_Provider]
,DW_CollectionGroup
,[FEPUSID]
,[ParentalEducation]
,[SocioEconomicClassification]
--,[DerivedPolar4]
--,[StateSchoolMarker]
,[GRADUATEKEY]
,[FurtherStudySinceGraduating]
,[PreviousNumberOfJobs]
,[SalaryAnnually]
,[EmploymentMonthsWorked]
,[EmploymentLength]
,[FirstJobSinceGraduating]
,[PreviousNumberOfCourses]
,[SalaryCurrency]
,[FullPersonEquivalent]
, FullPersonEquivalentWeighted
,DW_FromDate
,DW_ToDate
,DW_LoadID
,StudentHomeOverseas
,S_xEmploymentMarker
,S_xActivityOnTrack	
,S_xSalaryMarker
,S_xWorkForEmployerMarker
,S_xEmploymentBasis
,S_xQualificationRequired
,S_xInterimStudy
,S_xPaidVolunteerMarker
,S_xSalary
,S_xActivitySkills	
,S_xCurrencyLocation
,S_xHighSkills		
,S_xEmploymentMode			
,S_xMainReasonTakingJob		
,S_xActivityMeaningful
,S_xSelfEmploymentMarker
,S_xBusinessFunded
,S_xStudyMarker
,S_xModeOfStudy
,S_xTypeOfQualification

,S_xLocationOfWork
,S_LocationOfWorkRegion
,S_StandardOccClassWork
,S_StandardIndClassWork
,S_LocationOfWorkCountry_UAuthority
,S_xWorkSalary

)


SELECT  

 --ISNULL(ISNULL(pc.S_PostCode,ISNULL(pc2.S_Postcode,pc3.S_Postcode)),-1) S_Postcode		
 ISNULL(ISNULL(pc.S_PostCode,ISNULL(pc2.S_Postcode,'')),-1) S_Postcode		
,ISNULL(di.S_Disability,-1) AS S_Disability
,ISNULL(do.S_LocationRegion,0) AS S_Domicile
--,ISNULL(couk.S_County,-1) AS S_County
,-2 AS S_County
,ISNULL(ag.S_Age,-3) AS S_Age
/*No longer required. Not used by OS and DACT join to F_FullPersonEquivalent. Unsure on exact origins of this caveat...*/
--,CASE WHEN s.F_NATION='' THEN 73 ELSE ISNULL(na.S_Nationality,0) END AS S_Nationality  --This is what was ran at Luks request in 2018 year but I think below is better
--,CASE WHEN s.NATION='' AND  STUDYABROAD = ''    THEN 73 ELSE ISNULL(na.S_Nationality,0) END AS S_Nationality 
,CAST(ISNULL(Na.S_Nationality,-1) AS INT) AS S_Nationality --#2025LP
,ISNULL(et.S_Ethnicity,99) AS S_Ethnicity
--,ISNULL(et01.s_ethnicity,99) AS S_EthnicityAnalytical
,99 AS S_EthnicityAnalytical
,ISNULL(subj.S_Subject,-3) AS S_Subject
,ISNULL(qul.S_Qualification,-2) AS S_CourseLevel
--,ISNULL(qulGO.S_Qualification,-2) AS S_CourseLevel_GO
,-2 AS S_CourseLevel_GO
,ISNULL(ge.S_Gender,-1) AS S_Gender
,ISNULL(qr.S_QualificationResult,-1) AS S_QualificationResult
--,ISNULL(los.S_LengthOfStudy,-2) 
,-2 AS S_LengthOfStudy 
,ISNULL(mos.S_mode,-5) AS S_ModeOfStudy -- changed mode default to use RDS and align with Student. #2025LP
,CASE WHEN g.ukprn=10007773 THEN provou.s_provider ELSE ISNULL(ISNULL(prov.S_Provider,prov2.s_provider),2719662) END AS s_provider
,ISNULL(cal.s_date,19000101) AS s_date
,REPLACE(ISNULL(socM.S_StandardOccClass,0),'$$$$',0) AS S_StandardOccClass
,REPLACE(ISNULL(socB.S_StandardOccClass,0),'$$$$',0) AS S_StandardOccClassSelfEmployed
,REPLACE(ISNULL(socE.S_StandardOccClass,0),'$$$$',0) AS S_StandardOccClassEmployed
--,REPLACE(ISNULL(sicm.S_StandardIndClass,0),'$$$$',0) as S_StandardIndClass
,S_StandardIndClass							=REPLACE(ISNULL(M2007SIC.S_StandardIndClass,0),'$$$$',0) 
,REPLACE(ISNULL(sicb.S_StandardIndClass,0),'$$$$',0) AS S_StandardIndClassSelfEmployed
,REPLACE(ISNULL(sice.S_StandardIndClass,0),'$$$$',0) AS S_StandardIndClassEmployed
,ISNULL(coum.S_County,-1) AS S_CountyOfUK_GO
--,ISNULL(coubus.S_County,-1) AS S_CountyOfUKSelfEmployedIn_GO
,S_CountyOfUKSelfEmployedIn_GO			=ISNULL(XBUSLOCUC.S_UKCountyOrCountry,99999)
--,ISNULL(couemp.S_County,-1) AS S_CountyOfUKEmployedIn_GO
,S_CountyOfUKEmployedIn_GO				=ISNULL(XempLOCUC.S_UKCountyOrCountry,99999)
,ISNULL(domM.S_Domicile,0) AS S_Domicile_GO
--,ISNULL(domBus.S_Domicile,0) AS S_DomicileSelfEmployedIn_GO
,S_DomicileSelfEmployedIn_GO			=ISNULL(XBUSLOCGR.S_UKCountyOrCountry,99999) 
,ISNULL(domempLoc.S_UKCountyOrCountry,99999) AS S_DomicileEmployedIn_GO
--,ISNULL(con_GO.S_Country,-1) AS S_CountryOfStudy_GO
,S_CountryOfStudy_GO						=ISNULL(XSTULOCUC.S_UKCountyOrCountry,99999) 
,ISNULL(con.S_Country,332) AS S_countryDomiciled -- #2025LP ammended to align to RDS default.
,S_BusinessSelfEmploymentOrPortfolioIntesity =ISNULL((SELECT BSEOPI.S_Label FROM Reference.D_zJunkLabels BSEOPI WHERE BSEOPI.Field = 'intensity' AND BSEOPI.Entry = g.busempintensity AND (BSEOPI.dw_todate>=s.dw_fromdate AND BSEOPI.dw_fromdate<=s.dw_Fromdate)),3)
,S_EmploymentBasis  =ISNULL((SELECT EmpBas.S_Label FROM Reference.D_zJunkLabels EmpBas WHERE EmpBas.Field = 'empbasis' AND EmpBas.Entry = CASE WHEN g.empbasis='' THEN -1 ELSE g.empbasis END AND (EmpBas.dw_todate>=s.dw_fromdate AND EmpBas.dw_fromdate<=s.dw_Fromdate)),0)
,S_EmploymentIntensity  =ISNULL((SELECT EmpInt.S_Label FROM Reference.D_zJunkLabels EmpInt WHERE EmpInt.Field = 'intensity' AND EmpInt.Entry = g.empintensity AND (EmpInt.dw_todate>=s.dw_fromdate AND EmpInt.dw_fromdate<=s.dw_Fromdate)),3)
,S_StudyIntensity=ISNULL((SELECT StuInt.S_Label FROM Reference.D_zJunkLabels StuInt WHERE StuInt.Field = 'intensity' AND StuInt.Entry = g.stuintensity AND (StuInt.dw_todate>=s.dw_fromdate AND StuInt.dw_fromdate<=s.dw_Fromdate)),3)
,S_ActivityMeaningful = ISNULL((SELECT ActMean.S_Label FROM Reference.D_zJunkLabels ActMean WHERE ActMean.Field = 'MEAN' AND ActMean.Entry = CASE WHEN g.ACTMEAN='' THEN -1 ELSE g.ACTMEAN END AND (ActMean.dw_todate>=s.dw_fromdate AND ActMean.dw_fromdate<=s.dw_Fromdate)),0)
,[S_StudyMeaningful]  = ISNULL((SELECT StuMean.S_Label FROM Reference.D_zJunkLabels StuMean WHERE StuMean.Field = 'MEAN' AND StuMean.Entry = CASE WHEN g.STUMEAN ='' THEN -1 ELSE g.STUMEAN END AND (StuMean.dw_todate>=s.dw_fromdate AND StuMean.dw_fromdate<=s.dw_Fromdate)),0)
,[S_WorkMeaningful]  = ISNULL((SELECT WrkMean.S_Label FROM Reference.D_zJunkLabels WrkMean WHERE WrkMean.Field = 'MEAN' AND WrkMean.Entry = CASE WHEN g.WRKMEAN='' THEN -1 ELSE g.WRKMEAN END AND (WrkMean.dw_todate>=s.dw_fromdate AND WrkMean.dw_fromdate<=s.dw_Fromdate)),0)
,S_ActivityOnTrack = ISNULL((SELECT AOT.S_Label FROM Reference.D_zJunkLabels AOT WHERE AOT.Field = 'ONTRACK' AND AOT.Entry = CASE WHEN g.ACTONTRACK='' THEN -1 ELSE g.ACTONTRACK END AND (AOT.dw_todate>=s.dw_fromdate AND AOT.dw_fromdate<=s.dw_Fromdate)),0)
,[S_StudyOnTrack]=ISNULL((SELECT SOT.S_Label FROM Reference.D_zJunkLabels SOT WHERE SOT.Field = 'ONTRACK' AND SOT.Entry = CASE WHEN g.stuONTRACK='' THEN -1 ELSE g.stuONTRACK END AND (SOT.dw_todate>=s.dw_fromdate AND SOT.dw_fromdate<=s.dw_Fromdate)),0)
,[S_WorkOnTrack]=ISNULL((SELECT WOT.S_Label FROM Reference.D_zJunkLabels WOT WHERE WOT.Field = 'ONTRACK' AND WOT.Entry = CASE WHEN g.wrkONTRACK='' THEN -1 ELSE g.wrkONTRACK END AND (WOT.dw_todate>=s.dw_fromdate AND WOT.dw_fromdate<=s.dw_Fromdate)),0)
,S_ActivitySkills = ISNULL((SELECT ActSk.S_Label FROM Reference.D_zJunkLabels ActSk WHERE ActSk.Field = 'SKILLS' AND ActSk.Entry = CASE WHEN g.ACTskills='' THEN -1 ELSE g.ACTskills END AND (ActSk.dw_todate>=s.dw_fromdate AND ActSk.dw_fromdate<=s.dw_Fromdate)),0)
,S_StudySkills= ISNULL((SELECT StuSk.S_Label FROM Reference.D_zJunkLabels StuSk WHERE StuSk.Field = 'SKILLS' AND StuSk.Entry = CASE WHEN g.stuskills='' THEN -1 ELSE g.stuskills END AND (StuSk.dw_todate>=s.dw_fromdate AND StuSk.dw_fromdate<=s.dw_Fromdate)),0)
,S_WorkSkills= ISNULL((SELECT WrkSk.S_Label FROM Reference.D_zJunkLabels WrkSk WHERE WrkSk.Field = 'SKILLS' AND WrkSk.Entry = CASE WHEN g.wrkskills='' THEN -1 ELSE g.wrkskills END AND (WrkSk.dw_todate>=s.dw_fromdate AND WrkSk.dw_fromdate<=s.dw_Fromdate)),0)
,S_BusinessSelfEmploymentOrPortfolioMainReasonForTakingTheJob = ISNULL((SELECT BSEOPMRFTTJ.S_Label FROM Reference.D_zJunkLabels BSEOPMRFTTJ WHERE BSEOPMRFTTJ.Field = 'JOBRSNMAIN' AND BSEOPMRFTTJ.Entry = CASE WHEN g.BUSJOBRSNMAIN='' THEN -1 ELSE g.BUSJOBRSNMAIN END AND (BSEOPMRFTTJ.dw_todate>=s.dw_fromdate AND BSEOPMRFTTJ.dw_fromdate<=s.dw_Fromdate)),0)
,S_MainReasonForTakingTheJob = ISNULL((SELECT MRFTTJ.S_Label FROM Reference.D_zJunkLabels MRFTTJ WHERE MRFTTJ.Field = 'JOBRSNMAIN' AND MRFTTJ.Entry = CASE WHEN g.JOBRSNMAIN='' THEN -1 ELSE g.JOBRSNMAIN END AND (MRFTTJ.dw_todate>=s.dw_fromdate AND MRFTTJ.dw_fromdate<=s.dw_Fromdate)),0)
,S_QUALREQ=ISNULL((SELECT QR.S_Label FROM Reference.D_zJunkLabels QR WHERE QR.Field = 'QUALREQ' AND QR.Entry = CASE WHEN g.QUALREQ='' THEN -1 ELSE g.QUALREQ END AND (QR.dw_todate>=s.dw_fromdate AND QR.dw_fromdate<=s.dw_Fromdate)),0)
,S_LifeSatisfaction = ISNULL((SELECT LfSat.S_Label FROM Reference.D_zJunkLabels LfSat WHERE LfSat.Field = 'SATLIFE' AND LfSat.Entry = CASE WHEN SWB.SATLIFE='' THEN -1 ELSE SWB.SATLIFE END AND (LfSat.dw_todate>=s.dw_fromdate AND LfSat.dw_fromdate<=s.dw_Fromdate)),-2)
,S_LifeWorthwhile = ISNULL((SELECT LfWth.S_Label FROM Reference.D_zJunkLabels LfWth WHERE LfWth.Field = 'LIFEWORTH' AND LfWth.Entry = CASE WHEN SWB.LIFEWORTH ='' THEN -1 ELSE SWB.LIFEWORTH END AND (LfWth.dw_todate>=s.dw_fromdate AND LfWth.dw_fromdate<=s.dw_Fromdate)),-2)
,S_AnxiousYesterday = ISNULL((SELECT AnYe.S_Label FROM Reference.D_zJunkLabels AnYe WHERE AnYe.Field = 'ANXYEST' AND AnYe.Entry = CASE WHEN SWB.ANXYEST ='' THEN -1 ELSE SWB.ANXYEST END AND (AnYe.dw_todate>=s.dw_fromdate AND AnYe.dw_fromdate<=s.dw_Fromdate)),-2)
,S_HappyYesterday = ISNULL((SELECT HaYe.S_Label FROM Reference.D_zJunkLabels HaYe WHERE HaYe.Field = 'HAPYEST' AND HaYe.Entry = CASE WHEN SWB.HAPYEST ='' THEN -1 ELSE SWB.HAPYEST END AND (HaYe.dw_todate>=s.dw_fromdate AND HaYe.dw_fromdate<=s.dw_Fromdate)),-2)
,S_mimpact = ISNULL((SELECT Mim.S_Label FROM Reference.D_zJunkLabels Mim WHERE Mim.Field = 'MIMPACT' AND Mim.Entry =  CASE WHEN g.mimpact='' THEN '-1' ELSE g.mimpact END AND (Mim.dw_todate>=s.dw_fromdate AND Mim.dw_fromdate<=s.dw_Fromdate)),'0')
,S_TYPEQUAL = ISNULL((SELECT TQ.S_Label FROM Reference.D_zJunkLabels TQ WHERE TQ.Field = 'TYPEQUAL' AND TQ.Entry =  CASE WHEN g.typequal='' THEN '-1' ELSE g.typequal END AND (TQ.dw_todate>=s.dw_fromdate AND TQ.dw_fromdate<=s.dw_Fromdate)),'0')
,s_xactivity = ISNULL((SELECT XACT.S_Label FROM Reference.D_zJunkLabels XACT WHERE XACT.Field = 'XACTIVITY' AND XACT.Entry =  CASE WHEN g.XACTIVITY='' THEN '-1' ELSE g.XACTIVITY END AND (XACT.dw_todate>=s.dw_fromdate AND XACT.dw_fromdate<=s.dw_Fromdate)),'0')
,s_xcurrloc = ISNULL((SELECT XCL.S_Label FROM Reference.D_zJunkLabels XCL WHERE XCL.Field = 'xcurrloc' AND XCL.Entry = CASE WHEN g.xcurrloc='' THEN 9 ELSE g.xcurrloc END AND (XCL.dw_todate>=s.dw_fromdate AND XCL.dw_fromdate<=s.dw_Fromdate)),0)
,S_zrespstatus = ISNULL((SELECT XRS.S_Label FROM Reference.D_zJunkLabels XRS WHERE XRS.Field = 'ZRESPSTATUS' AND XRS.Entry = CASE WHEN g.zrespstatus='' THEN 0 ELSE g.zrespstatus END AND (XRS.dw_todate>=s.dw_fromdate AND XRS.dw_fromdate<=s.dw_Fromdate)),0)
,s.SK_C056_StudentEngagement
--dk keys
,sj.DK_DerivedEngagementSubject
,s.DK_StudentEngagement
,DK_Provider	=ISNULL(prov.[DK_Provider],prov2.DK_Provider)
--dk keys end
,'56' DW_CollectionGroup
,'' AS FEPUSID
,CASE WHEN ISNULL(s.pared,9)=-1 THEN 9 ELSE ISNULL(s.pared,9) END AS ParentalEducation --f_pared
,CASE WHEN s.sec=-1 THEN NULL ELSE s.sec END AS SocioEconomicClassification --F_Sec
--,CASE WHEN d.F_ZPOLAR4='U' THEN NULL ELSE d.F_ZPOLAR4 END AS DerivedPolar4 --F_ZPOLAR4
--,CASE WHEN d.F_ZSTATE_MARKER='U' THEN NULL ELSE d.F_ZSTATE_MARKER END AS StateSchoolMarker --f_zstate_marker
,g.GRADUATEKEY
,CAST(g.furstu AS INTEGER) AS FurtherStudySinceGraduating 
,g.prevjobnum AS PreviousNumberOfJobs
--,g.salary AS SalaryAnnually --a small number of respondence entered valuers on 9,999,999 (a handyman) or over
,CAST (SUBSTRING(g.salary,1,15) AS BIGINT) AS SalaryAnnually
,CASE WHEN g.EMPMONTH='-3' THEN NULL ELSE CAST(g.EMPMONTH AS TINYINT) END   AS EmploymentMonthsWorked  --2020 change
,CAST(g.EMPYEAr AS INTEGER) AS EmploymentLength
,CASE WHEN g.FIRSTJOB='-3'THEN  NULL ELSE CAST(g.FIRSTJOB AS TINYINT) END  AS FirstJobSinceGraduating  --2020 change
,g.PREVCOURSENUM AS PreviousNumberOfCourses
-- Derived Fields 
,g.ZCURRENCY AS SalaryCurrency
,sj.Z_SUBJFPE/100 FullPersonEquivalent 
,(sj.Z_SUBJFPE/100)*ISNULL(g.XWEIGHT01,0) FullPersonEquivalentWeighted
,@fromdater DW_FromDate
,@todater	DW_ToDate
,@loadid	DW_LoadID
--832445 in 56
--crap, need to tweak RLS
,CASE WHEN s.STUDYABROAD = '' THEN 1 WHEN s.STUDYABROAD = '01' THEN 2 WHEN s.STUDYABROAD = '02' THEN 3 END AS f_xhoos01
,S_xEmploymentMarker					=CASE WHEN ISNULL(G.XWRKMARKER,'NA') ='NA' THEN -2 ELSE CAST(XWRKMARKER AS INT)  END							--1
,S_xActivityOnTrack						=CASE WHEN ISNULL(G.XACTONTRACK,'NA') IN ('NA','NR','UN','')   THEN -2 ELSE CAST(G.XACTONTRACK AS INT) END			--1
,S_xSalaryMarker						=CASE WHEN ISNULL(G.XSALMARKER,'NA') ='NA' THEN -2 ELSE CAST(XSALMARKER AS INT) END								--1  
,S_xWorkForEmployerMarker				=CASE WHEN ISNULL(G.XEMPLOYERMARKER,'NA') ='NA' THEN -2 ELSE CAST(XEMPLOYERMARKER AS INT) END					--1  
,S_xEmploymentBasis						=CASE WHEN ISNULL(G.XEMPBASIS,'NA') ='NA' THEN -2 ELSE CAST(XEMPBASIS AS INT) END								--1  
,S_xQualificationRequired				=CASE WHEN ISNULL(G.XWRKQUALREQ,'NA') ='NA' THEN -2 ELSE CAST(XWRKQUALREQ AS INT) END							--1  
,S_xInterimStudy						=CASE WHEN ISNULL(G.XINTSTUDY,'NA') IN ('NA','NR','UN','')  THEN -2 ELSE CAST(G.XINTSTUDY AS INT) END				--1  
,S_xPaidVolunteerMarker					=CASE WHEN ISNULL(G.XMPAIDMARKER,'NA')  ='NA' THEN -2 ELSE CAST(XMPAIDMARKER AS INT) END						--1  
,S_xSalary								=CASE WHEN ISNULL(G.SALARY,'')='' THEN 0 ELSE  CAST(SUBSTRING(G.SALARY,1,18) AS BIGINT) END						--1  
,S_xActivitySkills						=CASE WHEN ISNULL(G.XACTSKILLS,'NA') IN ('NA','NR','UN','')   THEN -2 ELSE CAST(G.XACTSKILLS AS INT) END			--1
--,S_xCurrencyLocation					=CASE WHEN ISNULL(G.XWRKCURRLOC,'NA') ='NA' THEN -2 ELSE CAST(XWRKCURRLOC AS INT) END							--1
,S_xCurrencyLocation					=CASE WHEN ISNULL(G.EMPCURRENCY,'')='' THEN -2 ELSE CAST(G.EMPCURRENCY AS INT) END								--2021 Source redirected as orig source deprecated
,S_xHighSkills							=CASE WHEN ISNULL(G.XWRKHSKILL,'NA') IN ('NA','NR','UN','')   THEN -2 ELSE CAST(G.XWRKHSKILL AS INT) END			--1
,S_xEmploymentMode						=CASE WHEN ISNULL(G.XWRKINTENSITY,'NA') IN ('NA','NR','UN','')   THEN -2 ELSE CAST(G.XWRKINTENSITY AS INT) END		--1
,S_xMainReasonTakingJob					=CASE WHEN ISNULL(G.XWRKJOBRSN,'NA') IN ('NA','NR','UN','')   THEN -2 ELSE CAST(G.XWRKJOBRSN AS INT) END			--1
,S_xActivityMeaningful					=CASE WHEN ISNULL(G.XACTMEAN,'NA') IN ('NA','NR','UN','') THEN -2 ELSE CAST(G.XACTMEAN AS INT) END					--1
,S_xSelfEmploymentMarker				=CASE WHEN ISNULL(G.XBUSMARKER,'NA') IN ('NA','') THEN -2 ELSE CAST(XBUSMARKER AS INT) END						--1
,S_xBusinessFunded						=CASE WHEN ISNULL(G.XBUSCOMPFUND,'NA') ='NA' THEN -2 ELSE CAST(XBUSCOMPFUND AS INT) END							--1
,S_xStudyMarker							=CASE WHEN ISNULL(G.XSTUMARKER,'NA') ='NA' THEN -2 ELSE CAST(XSTUMARKER AS INT) END								--1
,S_xModeOfStudy							=CASE WHEN ISNULL(G.XSTUINTENSITY,'NA') IN ('NA','UN','') THEN -2 ELSE CAST(XSTUINTENSITY AS INT) END				--1
,S_xTypeOfQualification					=CASE WHEN ISNULL(G.XSTUTYPEQUAL,'NA') IN ('NA','UN','') THEN -2 ELSE CAST(XSTUTYPEQUAL AS INT) END				--1
, S_xLocationOfWork						=CASE WHEN ISNULL(G.XWRKLOCN,'NA') IN ('NA','NR','UN','99','')   THEN -2 ELSE CAST(G.XWRKLOCN AS INT) END			--1
--,S_LocationOfWorkRegion					=ISNULL(LOCGR.S_Domicile,-2)	
,S_LocationOfWorkRegion					=CASE WHEN G.XWRKLOCUC ='$$$$' THEN 99998 ELSE  ISNULL(XWRKLOCGR.S_UKCountyOrCountry ,99999) END																				--1
,S_StandardOccClassWork					=ISNULL(W2010SOC.S_StandardOccClass,-2)
,S_StandardIndClassWork					=ISNULL(W2007SIC.S_StandardIndClass,-2)
,S_LocationOfWorkCountry_UAuthority		=ISNULL(WLOCUC.S_UKCountyOrCountry,99999)

,S_xWorkSalary =CASE WHEN ISNULL(G.XWRKSALARY,'')='' THEN 0 ELSE  CAST(SUBSTRING(G.XWRKSALARY,1,18) AS BIGINT) END


--SELECT sum(sj.Z_SUBJFPE/100) --1034157
FROM	dbo.GOSub g


JOIN	 dbo.C056_StuEngTemp s 
            
--ON		g.INSTANCEKEY = s.F_INSTANCEKEY
ON s.DK_StudentEngagement = G.DK_Instance
--AND g.DW_FromDate = @fromdater
			JOIN dbo.DESubj SJ   --3,384,647
			ON SJ.[DK_StudentEngagement] = s.DK_StudentEngagement
			AND s.DK_DerivedEngagementSubject = sj.DK_DerivedEngagementSubject
			AND SJ.DW_FromDate =@Fromdater
			AND s.DW_FromDate=@Fromdater

--LEFT OUTER JOIN [Reference].[D056_Instance_Derived] D 
--ON		d.F_INSTANCEKEY = s.F_INSTANCEKEY

LEFT OUTER JOIN	[GradOutcomes].[C072_SubjectWellbeing_Individualised] SWB 
ON		SWB.GRADUATEKEY = g.GRADUATEKEY
AND		SWB.DW_FromDate = g.DW_FromDate
 
LEFT OUTER JOIN 	dbo.PostCoderSub pc
ON CAST (REPLACE(CASE WHEN SUBSTRING (s.PERMADDPOSTCODE,1,3)='BF1' THEN 'BF1' ELSE s.PERMADDPOSTCODE END  ,' ','') AS VARCHAR (8))=pc.DW_PostCodeWithNoSpacing --1
LEFT OUTER JOIN		dbo.postcodersub pc2
ON		CONVERT(VARCHAR,CASE WHEN CHARINDEX(' ',s.PERMADDPOSTCODE,0)>0 
							THEN CHARINDEX(' ',s.PERMADDPOSTCODE,0) -1 
							ELSE CHARINDEX(' ',s.PERMADDPOSTCODE,0) 
							END)=CONVERT(VARCHAR,pc2.OutwardPostcode)

-- LEFT OUTER JOIN (SELECT [S_PostCode],[PostCode] FROM [Reference].[D_PostCode] WHERE InwardsPostcode=''AND DW_ToDate=@PCodeDate
-- ) pc3 ON pc3.PostCode=RTRIM(SUBSTRING(s.ttpcode,1,4))


LEFT OUTER JOIN Reference.D_Disability di
ON	di.Disabilitycode = s.DISABILITY
AND di.Source = 'RDS'
AND (di.dw_todate>=s.dw_fromdate AND di.dw_fromdate<=s.dw_Fromdate)

/* 
--replaced by do
LEFT OUTER JOIN reference.D_Domicile do
ON do.DomicileGroupCode = s.F_XDOMGR401
AND do.DomicileCode = s.F_XDOMGR01
AND (do.dw_todate>=s.dw_fromdate AND do.dw_fromdate<=s.dw_Fromdate)
*/
 LEFT OUTER JOIN Reference.[D_LocationRegion] do
			ON do.LocationRegionCode=s.Z_PERMADDREGION AND do.GRP_LocationRegion5<>'' 
			AND @fromdater>=do.DW_FromDate AND @fromdater<=do.DW_ToDate	
			
--gone??
--LEFT OUTER JOIN Reference.D_CountyOfUK couk
--ON couk.CountyCode=s.F_XDOMUC01
--AND (couk.dw_todate>=s.dw_fromdate AND couk.dw_fromdate<=s.dw_Fromdate)

LEFT OUTER JOIN Reference.D_Age ag
ON ag.age = CONVERT(VARCHAR,s.Z_AGEJUL)
AND (ag.dw_todate>=s.dw_fromdate AND ag.dw_fromdate<=s.dw_Fromdate)




LEFT OUTER JOIN Reference.D_Nationality na
ON na.NationalityCode = s.Nation
AND na.Source = 'RDS'
AND (na.dw_todate>=s.dw_fromdate and na.dw_fromdate<=s.dw_Fromdate)

LEFT OUTER JOIN Reference.D_Ethnicity et
on (et.dw_todate>=s.dw_fromdate and et.dw_fromdate<=s.dw_Fromdate)
and et.Ethnicitycode = s.ETHNIC
AND et.Source = 'RDS'
--and et.EthnicityCategory not in ('-2','-6') --sorts out 16 issue

--removed for now, no xhoos equivalent?
--LEFT OUTER JOIN Reference.D_Ethnicity et01
--ON et01.dw_fromdate > 19000000
--AND (et01.dw_todate>=s.dw_fromdate and et01.dw_fromdate<=s.dw_Fromdate)
--and et01.EthnicityCategory not in ('-2','-6')
--AND et01.EthnicityID= CASE WHEN s.F_XHOOS01 = 2 THEN -2
--					WHEN s.F_XHOOS01=3 THEN 0
--					ELSE  s.F_ETHNIC END 
LEFT OUTER JOIN Reference.D_StandardOccupationalClassification socM
ON REPLACE(socm.StandardOccClassID,'$$$$$',0) = g.XWRK2020SOC--XM2010SOC
AND (socm.dw_todate>=s.dw_fromdate and socm.dw_fromdate<=s.dw_Fromdate)

LEFT OUTER JOIN Reference.D_StandardOccupationalClassification socB
ON REPLACE(socb.StandardOccClassID,'$$$$$',0) = g.XBUS2020SOC--XBUS2010SOC
AND (socb.dw_todate>=s.dw_fromdate and socb.dw_fromdate<=s.dw_Fromdate)

LEFT OUTER JOIN Reference.D_StandardOccupationalClassification socE
ON REPLACE(soce.StandardOccClassID,'$$$$$',0) = g.XEMP2020SOC--XEMP2010SOC
AND (soce.dw_todate>=s.dw_fromdate and soce.dw_fromdate<=s.dw_Fromdate)

LEFT OUTER JOIN Reference.D_StandardIndustrialClassification sicm
ON REPLACE(sicm.StandardIndClasscode,'$$$$',0) = g.XWRK2007SIC--XM2007SIC
AND (sicm.dw_todate>=s.dw_fromdate and sicm.dw_fromdate<=s.dw_Fromdate)

LEFT OUTER JOIN Reference.D_StandardIndustrialClassification sicb
ON REPLACE(sicb.StandardIndClasscode,'$$$$',0)=g.XBUS2007SIC
AND (sicb.dw_todate>=s.dw_fromdate and sicb.dw_fromdate<=s.dw_Fromdate)

LEFT OUTER JOIN Reference.D_StandardIndustrialClassification sicE
ON REPLACE(sice.StandardIndClasscode,'$$$$',0) = g.XEMP2007SIC
AND (sice.dw_todate>=s.dw_fromdate and sice.dw_fromdate<=s.dw_Fromdate)

LEFT OUTER JOIN reference.D_Subject subj
ON CAST(sj.Z_SUBJHECOS AS VARCHAR(6))= subj.subjectcode
and sj.DW_FromDate>=subj.DW_FromDate and sj.DW_FromDate<=subj.DW_ToDate
AND subj.Source='RDS'


--F_XOBTNG01 equivalent
LEFT OUTER JOIN reference.D_Qualification qul
ON qul.QualCode = s.Z_QLEVEL_CYC--F_XQOBTN01
AND qul.Source = 'RDS'
AND (qul.dw_todate>=s.dw_fromdate and qul.dw_fromdate<=s.dw_Fromdate)

--see above
--LEFT OUTER JOIN reference.D_Qualification qulGO
--ON qulGO.QualCode = s.F_XOBTNG01 
--AND (qulGO.dw_todate>=s.dw_fromdate and qulGO.dw_fromdate<=s.dw_Fromdate)

LEFT OUTER JOIN [Reference].[D_Gender] ge
ON ge.GenderCode = s.SEXID
AND ge.SOURCE = 'RDS'
AND (ge.dw_todate>=s.dw_fromdate and ge.dw_fromdate<=s.dw_Fromdate)

LEFT OUTER JOIN Reference.D_QualificationResult qr
ON qr.QualificationResultCode=CONVERT(VARCHAR(4),Z_QCLASS_CYC)--CASE WHEN s.f_xclassf01='-3' THEN 'NOTK' ELSE s.f_xclassf01 end
AND (qr.dw_todate>=s.dw_fromdate and qr.dw_fromdate<=s.dw_Fromdate)
AND qr.Source = 'RDS'

--dodgy A stuff HERE!!!
LEFT OUTER JOIN Reference.D_LengthOfStudy LS 
ON LS.LengthOfStudyCode=CAST(s.Z_EXPECTLENGRP1 AS VARCHAR (4)) 
AND LS.Source='RDS' 
AND @fromdater>=LS.DW_FromDate and @fromdater<=LS.DW_ToDate	

/*
--completely changed
LEFT OUTER JOIN Reference.D_ModeOfStudy mos 
ON CASE WHEN LEN(mos.Modeid)<2 AND ISNUMERIC(mos.Modeid)=1 
	THEN '0'+CONVERT(varchar,mos.Modeid) 
	ELSE mos.Modeid 
	END = CASE WHEN s.F_MODE = '02' AND los.LengthOfStudyCode IN('1','2') THEN '2002'
				WHEN s.F_MODE = '13' AND los.LengthOfStudyCode IN('1','2') THEN '13002'
				WHEN s.F_MODE='25' AND los.LengthOfStudyCode IN('1','2') THEN '25002'
				ELSE s.f_mode
				END
AND (mos.dw_todate>=s.dw_fromdate and mos.dw_fromdate<=s.dw_Fromdate)
*/
/*LEFT OUTER JOIN  Reference.D_ModeOfStudy MOS	
	ON  ModeCode=  CAST(s.SCSMODE AS VARCHAR (2)) 
	AND  CASE WHEN CAST(s.SCSMODE AS VARCHAR (2)) ='02' 
		THEN s.Z_MODEGRP1 
		ELSE MOS.Mode3WayCategoryCode  
		END = MOS.Mode3WayCategoryCode 
	AND MOS.Source='RDS' 
	AND @fromdater>=MOS.DW_FromDate AND @fromdater<=MOS.DW_ToDate  --Z_Mode
	*/
	LEFT OUTER JOIN  Reference.D_ModeOfStudy MOS	
	ON  ModeCode=  CAST(s.SCSMODE AS VARCHAR (2)) 
	AND  CASE WHEN CAST(s.SCSMODE AS VARCHAR (2)) ='02' 
		THEN s.Z_MODEGRP1 
		WHEN s.SCSMODE = ''
		THEN s.Z_MODEGRP1 
		ELSE MOS.Mode3WayCategoryCode  
		END = MOS.Mode3WayCategoryCode 
	AND MOS.Source='RDS' 
	AND @fromdater>=MOS.DW_FromDate AND @fromdater<=MOS.DW_ToDate  --Z_Mode



LEFT OUTER JOIN (SELECT * 
				FROM Provider.D_Provider prov
				WHERE prov.DW_AdminCenter = 1
				AND prov.dw_todate>=@fromdater and prov.dw_fromdate<=@fromdater) prov
ON prov.INSTID=s.INSTID
AND prov.UKPRN=s.UKPRN

LEFT OUTER JOIN (SELECT * 
				FROM Provider.D_Provider prov2
				WHERE prov2.DW_AdminCenter = 1
				AND prov2.dw_todate=99999999) prov2
ON prov2.INSTID=s.INSTID
AND prov2.UKPRN=s.UKPRN

LEFT OUTER JOIN (SELECT * 
				FROM Provider.D_Provider provOU
				WHERE provOU.ukprn = 10007773
				AND (provOU.dw_todate>=@fromdater and provOU.dw_fromdate<=@fromdater)
				) provOU
ON provOU.INSTID=s.INSTID
AND provOU.UKPRN=s.UKPRN
--AND provOU.CampusCode=s.F_CAMPID

LEFT OUTER JOIN Reference.D_CountyOfUK couM
ON coum.CountyCode=g.XMLOCUC
AND (coum.dw_todate>=s.dw_fromdate and coum.dw_fromdate<=s.dw_Fromdate)

LEFT OUTER JOIN Reference.D_CountyOfUK couBus
ON couBus.CountyCode=g.XbusLOCUC
AND (couBus.dw_todate>=s.dw_fromdate and couBus.dw_fromdate<=s.dw_Fromdate)

LEFT OUTER JOIN Reference.D_CountyOfUK couEmp
ON couEmp.CountyCode=g.XempLOCUC
AND (couEmp.dw_todate>=s.dw_fromdate and couEmp.dw_fromdate<=s.dw_Fromdate)

LEFT OUTER JOIN Reference.D_Domicile domemp
ON g.[XEMPLOCGR] = domemp.DomicileCode
AND (domemp.dw_todate>=s.dw_fromdate and domemp.dw_fromdate<=s.dw_Fromdate)

LEFT OUTER JOIN Reference.D_Domicile domM
ON g.[XMLOCGR] = domM.DomicileCode
AND (domm.dw_todate>=s.dw_fromdate and domm.dw_fromdate<=s.dw_Fromdate)

LEFT OUTER JOIN Reference.D_Domicile domBus
ON g.[XbusLOCGR] = dombus.DomicileCode
AND (domBus.dw_todate>=s.dw_fromdate and domBus.dw_fromdate<=s.dw_Fromdate)

LEFT OUTER JOIN Reference.D_Country con
ON s.PERMADDCOUNTRY=con.CountryCode
--AND con.Source = 'MD'
AND con.Source = 'RDS' -- #2025LP
AND (con.dw_todate>=s.dw_fromdate and con.dw_fromdate<=s.dw_Fromdate)

--might not need?
--LEFT OUTER JOIN Reference.D_Country con_GO--for some reason GR codes in GO are different
--ON g.XSTULOCGR=con_GO.GeographicGroupCode
--AND g.XSTULOCUC=con_GO.CountryCode
--AND (con_GO.dw_todate>=s.dw_fromdate and con_GO.dw_fromdate<=s.dw_Fromdate)

LEFT OUTER JOIN Reference.D_Calendar cal
ON cal.Date = s.enddate

LEFT OUTER JOIN Reference.[D_Domicile] LOCGR ON LOCGR.DomicileCode=G.XWRKLOCGR AND LOCGR.DW_FromDate <= @fromdater AND LOCGR.DW_ToDate >= @fromdater 

--LEFT OUTER JOIN Reference.D_StandardOccupationalClassification W2010SOC ON W2010SOC.StandardOccClassCode=G.XWRK2010SOC AND  W2010SOC.DW_FromDate <= @fromdater AND W2010SOC.DW_ToDate >= @fromdater
LEFT OUTER JOIN Reference.D_StandardOccupationalClassification W2010SOC ON W2010SOC.StandardOccClassCode=ISNULL(G.XWRK2020SOC,'_____') AND  W2010SOC.DW_FromDate <= @fromdater AND W2010SOC.DW_ToDate >= @fromdater
LEFT OUTER JOIN Reference.D_StandardIndustrialClassification W2007SIC ON W2007SIC.StandardIndClassCode=G.XWRK2007SIC AND  W2007SIC.DW_FromDate <= @fromdater AND W2007SIC.DW_ToDate >= @fromdater

LEFT OUTER JOIN Reference.[B_UKCountyOrCountry] WLOCUC ON WLOCUC.CountyCode=G.XWRKLOCUC  AND WLOCUC.DW_FromDate <= @fromdater AND WLOCUC.DW_ToDate >= @fromdater
LEFT OUTER JOIN [Reference].[B_UKCountyOrCountry] domempLoc ON g.[XEMPLOCGR] = domempLoc.CountyCode AND domempLoc.DW_FromDate<=g.dw_fromdate and domempLoc.DW_ToDate>=g.dw_Fromdate



--added in as new join
LEFT OUTER JOIN Reference.B_UKCountyOrCountry XWRKLOCGR ON G.XWRKLOCGR=XWRKLOCGR.CountyCode AND XWRKLOCGR.DW_FromDate<=G.DW_FromDate AND XWRKLOCGR.DW_ToDate>=G.DW_FromDate
LEFT OUTER JOIN Reference.B_UKCountyOrCountry XEMPLOCUC  ON G.XEMPLOCUC=XEMPLOCUC.CountyCode AND XEMPLOCUC.DW_FromDate<=G.DW_FromDate AND XEMPLOCUC.DW_ToDate>=G.DW_FromDate
LEFT OUTER JOIN Reference.B_UKCountyOrCountry XBUSLOCUC  ON g.XBUSLOCUC=XBUSLOCUC.CountyCode AND XBUSLOCUC.DW_FromDate<=g.DW_FromDate AND XBUSLOCUC.DW_ToDate>=g.DW_FromDate


LEFT OUTER JOIN Reference.B_UKCountyOrCountry XSTULOCUC ON g.XSTULOCUC=XSTULOCUC.CountyCode AND XSTULOCUC.DW_FromDate<=s.DW_FromDate AND XSTULOCUC.DW_ToDate>=g.DW_FromDate
LEFT OUTER JOIN Reference.B_UKCountyOrCountry XBUSLOCGR ON g.XBUSLOCGR=XBUSLOCGR.CountyCode AND XBUSLOCGR.DW_FromDate<=s.DW_FromDate AND XBUSLOCGR.DW_ToDate>=g.DW_FromDate
LEFT OUTER JOIN Reference.D_StandardIndustrialClassification M2007SIC ON M2007SIC.StandardIndClassCode=G.XWRK2007SIC AND  M2007SIC.DW_FromDate <= @fromdater AND M2007SIC.DW_ToDate >= @fromdater



WHERE	g.DW_FromDate = @fromdater 
AND		s.dw_fromdate = @fromdater
--AND		d.DW_FromDate = @fromdater --already filtered
--END
/*
SELECT COUNT(*), dw_fromdate
FROM fact.F_GraduateOutcomeSurvey g
GROUP BY g.DW_FromDate
ORDER BY g.DW_FromDate

SELECT SUM(s.FullPersonEquivalent), SUM(s.FullPersonEquivalentWeighted) FROM Fact.F_GraduateOutcomeSurvey s
WHERE dw_fromdate = 20220801
AND s.DW_CollectionGroup NOT LIKE 'FECs'

SELECT SUM(sj.Z_SUBJFPE)/100
FROM	dbo.GOSub g
JOIN	 dbo.C056_StuEngTemp s 
            --ON		g.INSTANCEKEY = s.F_INSTANCEKEY
ON s.DK_StudentEngagement = G.DK_Instance
--AND g.DW_FromDate = @fromdater
			JOIN Student.[C056_DerivedEngagementSubject]  SJ   --3,384,647
			ON SJ.[DK_StudentEngagement] = s.DK_StudentEngagement
			AND s.DK_DerivedEngagementSubject = sj.DK_DerivedEngagementSubject
			AND SJ.DW_FromDate =20220801
			AND s.DW_FromDate=20220801
WHERE S.Z_POPGO_CYC='1'
*/

--ethnic impute 2022 only
--ALTER TABLE [Fact].[F_GraduateOutcomeSurvey] DROP CONSTRAINT [FK_F_GraduateOutcomeSurvey_D_Ethnicity]
--GO

/*--not correct
UPDATE gos
SET gos.S_Ethnicity = e.S_Ethnicity
--SELECT COUNT(*)
FROM fact.F_GraduateOutcomeSurvey gos --1,104,402
JOIN student.C056_StudentEngagement se
ON se.DW_FromDate = gos.DW_FromDate
AND se.DK_StudentEngagement = gos.DK_Instance
JOIN HDP.C22056_StudentEngagement  a
ON a.NUMHUS = se.NUMHUS
AND a.INSTID = se.INSTID
AND a.[SID] = se.SID
JOIN Reference.D_Ethnicity e
ON CASE WHEN a.ETHNIC='' THEN a.ethnic_impute ELSE a.ETHNIC END = e.EthnicityCode
WHERE gos.dw_fromdate = 20220801
AND gos.DW_CollectionGroup = '56'
--a.ETHNIC<>a.ethnic_impute
*/

--SSM and polar 4
UPDATE gos
SET gos.DerivedPolar4 = CASE WHEN dse.Z_POLAR4='U' THEN NULL ELSE dse.Z_POLAR4 END --F_ZPOLAR4
,gos.StateSchoolMarker = CASE WHEN dse.Z_STATEMRK='U' THEN NULL ELSE dse.Z_STATEMRK END --f_zstate_marker
--SELECT COUNT(*)
FROM fact.F_GraduateOutcomeSurvey gos --1,104,
JOIN [Reference].[D056_Derive_StuEng] dse
ON dse.DW_FromDate = gos.DW_FromDate
AND dse.DK_StudentEngagement = gos.DK_Instance
WHERE gos.DW_FromDate = 20220801
AND gos.DW_CollectionGroup = '56'


SELECT sum(FullPersonEquivalent)  FROM Fact.F_GraduateOutcomeSurvey WHERE DW_FromDate = 20220801
SELECT S_Ethnicity FROM Fact.F_GraduateOutcomeSurvey WHERE DW_FromDate = 20220801 AND dk_instance = 2413648
