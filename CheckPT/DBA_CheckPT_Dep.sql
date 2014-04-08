USE CheckResultDB
 
GO 

ALTER PROCEDURE [dbo].DBA_CheckPT_Dep
(
	@sporttype INT=NULL,
	@srecommend VARCHAR(1000)=NULL,
	@site VARCHAR(100)=NULL,
	@ShowDetail BIT = 1
)
AS
/*
	Created: 20131015@Tom.Vo	
	Task :   Check PT rules (Credit)
	DB: DB052.CheckResultDB
	Original:

	Revisions:
		
	Param's Explanation:
		@sporttype: Product Id
			-1 : All
			0  : SB
			151: Racing
			161: NumberGame
			162: Live Casino
			180: Virtual Sport
			202: Keno
			251: RnG Casino
*/
SET NOCOUNT ON

	IF @sporttype IS NULL 
		SET @sporttype = -1
	
	IF OBJECT_ID('tempdb..#tmpAgent') IS NOT NULL		DROP TABLE #tmpAgent
	IF OBJECT_ID('tempdb..#Member') IS NOT NULL 		DROP TABLE #Member
	IF OBJECT_ID('tempdb..#Licensee') IS NOT NULL 		DROP TABLE #Licensee
	IF OBJECT_ID('tempdb..#tmpSport_PT') IS NOT NULL 	DROP TABLE #tmpSport_PT
	IF OBJECT_ID('tempdb..#LicenseeBAHistory') IS NOT NULL 	DROP TABLE #LicenseeBAHistory

	CREATE TABLE #tmpAgent(CustID INT,SiteID INT)
	CREATE TABLE #tmpSport_PT (Sportid INT,	PT SmallMoney,Site varchar(100),SiteID INT)
	CREATE TABLE #Member (SiteID INT,CustID INT,BetType INT, SportID INT,PT SmallMoney,PT_spec SmallMoney,IsBA BIT DEFAULT(0))
	CREATE TABLE #Licensee (SiteID INT,CustID INT,SportID INT,BetType INT, PT SmallMoney,PT_spec SmallMoney)
	CREATE TABLE #LicenseeBAHistory([LicenseeID] [int] NOT NULL,[CustID] [int] NOT NULL,[OnDate] [datetime] NOT NULL,[OffDate] [datetime] NULL,	
					[OnBy] [int] NOT NULL,[OffBy] [int] NULL,[GroupComm] [decimal](9, 8) NOT NULL,[1x2Comm] [decimal](9, 8) NOT NULL,
					[OtherComm] [decimal](9, 8) NOT NULL,
					[Status] [varchar](50) NOT NULL,
					[Ugroup] [varchar](3) NULL
			) 
	INSERT INTO #tmpSport_PT (SportId,PT,Site,SiteID)
	Select SportId,PT,Site,SiteID FROM [dbo].[f_GetPT_Dep_ByProduct] (@sporttype,@site)

	IF @site IS NOT NULL AND @srecommend IS NULL
	BEGIN
		EXEC  [dbo].[DBA_Get_List_Super_Licensee] @Site =@Site ,	@srecommend = @srecommend  OUTPUT
	END

	INSERT INTO  #tmpAgent (CustID,SiteID)
	EXEC [dbo].[DBA_Get_List_Agency_Licensee]
		@srecommend =@srecommend

	INSERT INTO #LicenseeBAHistory([LicenseeID],[CustID],[OnDate],[OffDate],[OnBy],[OffBy],[GroupComm],[1x2Comm],[OtherComm],[Status],[Ugroup])
	SELECT [LicenseeID],[CustID],[OnDate],[OffDate],[OnBy],[OffBy],[GroupComm],[1x2Comm],[OtherComm],[Status],[Ugroup]
	FROM DBLIC.bodb_licensee.dbo.LicenseeBAHistory BA WITH(NOLOCK) 
	WHERE BA.[Status] = 'running'
	
	--GET List Member is violated 
	IF @sporttype IN (-1,0) OR @sporttype <=99 OR @sporttype =154--SportBook
	BEGIN
		INSERT INTO #Member (SiteID,CUSTID,SPORTID,BetType,PT,PT_spec,IsBA)
		SELECT  Sport_PT.siteID,
				co.custid,
				cs.SportType,
				cs.BetType,
				cs.apositiontaking + cs.mpositiontaking + cs.spositiontaking as PT,
				Sport_PT.PT,
				CASE WHEN (BA.custid IS NOT NULL AND (cs.apositiontaking <> 0 OR cs.mpositiontaking <> 0)) THEN 1 ELSE 0 END IsBA
			FROM CheckCustDB.dbo.Customer co WITH(NOLOCK)
			INNER JOIN
				#tmpAgent sup
					ON sup.custid = co.recommend AND co.roleid =1
			INNER JOIN
				#tmpSport_PT  Sport_PT 
					ON sup.SiteID = Sport_PT.SiteID
			INNER JOIN
				CheckCustDB.dbo.Dep_CustSetting cs WITH(NOLOCK)
					ON cs.custid = co.custid AND cs.sporttype = Sport_PT.Sportid
			LEFT JOIN 
				#LicenseeBAHistory BA WITH(NOLOCK) 
					ON co.custid = BA.custid --AND BA.[Status] = 'running'
			WHERE
					(BA.custid IS NULL AND (cs.apositiontaking + cs.mpositiontaking + cs.spositiontaking <> Sport_PT.PT)) 
						OR 
					(BA.custid IS NOT NULL AND (cs.apositiontaking <> 0 OR cs.mpositiontaking <> 0))
	END
	
	IF @sporttype IN (-1,151,161,162,180,202,251)--+ Racing(151) + NumberGame(161)+Live Casino(162)+ Virtual Sport(180) + Keno(202) + RnG Casino(251)
	BEGIN
			IF @sporttype IN (-1,151,161,162,180,251)
				INSERT INTO #Member (SiteID,CUSTID,SPORTID,BetType,PT,PT_spec)
				SELECT Sport_PT.SiteID,
					co.custid ,		 
					cs.SportType,
					cs.BetType,
					cs.apositiontaking + cs.mpositiontaking + cs.spositiontaking as PT,
					Sport_PT.PT 	 
				FROM CheckCustDB.dbo.Customer co WITH(NOLOCK)
				INNER JOIN
					#tmpAgent sup
						ON sup.custid = co.recommend
				INNER JOIN
					CheckCustDB.dbo.Dep_CustSetting3rd cs WITH(NOLOCK) 
						ON cs.custid = co.custid 
				INNER JOIN
					#tmpSport_PT  Sport_PT 
					ON cs.sporttype = Sport_PT.Sportid AND sup.SiteID = Sport_PT.SiteID
				WHERE co.roleid =1
					AND (cs.apositiontaking + cs.mpositiontaking + cs.spositiontaking <> Sport_PT.PT)

			IF @sporttype IN (-1,202)
				INSERT INTO #Member (SiteID,CUSTID,SPORTID,BetType,PT,PT_spec)
				SELECT Sport_PT.SiteID,
					co.custid,
					cs.SportType,
					cs.BetType,
					cs.apositiontaking + cs.mpositiontaking + cs.spositiontaking as PT,
					Sport_PT.PT
				FROM CheckCustDB.dbo.Customer co WITH(NOLOCK)
				INNER JOIN
					#tmpAgent sup
						ON sup.custid = co.recommend
				INNER JOIN
					CheckCustDB.dbo.CustSettingGame cs WITH(NOLOCK) 
						ON cs.custid = co.custid 
				INNER JOIN
					#tmpSport_PT  Sport_PT 
					ON cs.sporttype = Sport_PT.Sportid AND sup.SiteID = Sport_PT.SiteID
				WHERE co.roleid =1
					AND (cs.apositiontaking + cs.mpositiontaking + cs.spositiontaking <> Sport_PT.PT) 

	END

	--GET Lisencee is violated
	IF @sporttype IN (-1,0) OR @sporttype <=99 OR @sporttype =154--SportBook
		INSERT INTO #Licensee (SiteID,CUSTID,SPORTID,BetType,PT,PT_spec)
		SELECT  Sport_PT.SiteID,
					 co.custid,
					 Sport_PT.Sportid,
					 BetType,
					 cs.apositiontaking as PT,
					 Sport_PT.PT
			FROM CheckCustDB.dbo.Customer co WITH(NOLOCK)
			INNER JOIN
				#tmpAgent sup
					ON sup.custid = co.recommend
			INNER JOIN
				CheckCustDB.dbo.Dep_CustSetting cs WITH(NOLOCK) 
					ON cs.custid = co.custid AND co.roleid =2
			INNER JOIN
				#tmpSport_PT  Sport_PT
					ON cs.sporttype = Sport_PT.Sportid AND sup.SiteID = Sport_PT.SiteID
			WHERE cs.apositiontaking <> Sport_PT.PT 
	
	IF @sporttype IN (-1,151,161,162,180,202,251)--+ Racing(151) + NumberGame(161)+Live Casino(162)+ Virtual Sport(180) + Keno(202) + RnG Casino(251)
	BEGIN
		IF @sporttype IN (-1,151,161,162,180,251)
			INSERT INTO #Licensee (SiteID,CUSTID,SPORTID,BetType,PT,PT_spec)
			SELECT   
						Sport_PT.SiteID,
						 co.custid,
						 Sport_PT.Sportid,
						 BetType,
						 cs.apositiontaking as PT,
						 Sport_PT.PT
				FROM CheckCustDB.dbo.Customer co WITH(NOLOCK)
				INNER JOIN
					#tmpAgent sup
						ON sup.custid = co.recommend
				INNER JOIN
					CheckCustDB.dbo.Dep_CustSetting3rd cs WITH(NOLOCK) 
						ON cs.custid = co.custid
				INNER JOIN
					#tmpSport_PT  Sport_PT
						ON cs.sporttype = Sport_PT.Sportid AND sup.SiteID = Sport_PT.SiteID
				WHERE co.roleid =2 AND cs.apositiontaking <> Sport_PT.PT

		IF @sporttype IN (-1,202)
			INSERT INTO #Licensee (SiteID,CUSTID,SPORTID,BetType,PT,PT_spec)
				SELECT   
							Sport_PT.SiteID,
							 co.custid,
							 Sport_PT.Sportid,
							 BetType,
							 cs.apositiontaking as PT,
							 Sport_PT.PT
					FROM CheckCustDB.dbo.Customer co WITH(NOLOCK)
					INNER JOIN
						#tmpAgent sup
							ON sup.custid = co.recommend
					INNER JOIN
						CheckCustDB.dbo.CustSettingGame cs WITH(NOLOCK) 
							ON cs.custid = co.custid
					INNER JOIN
						#tmpSport_PT  Sport_PT
							ON cs.sporttype = Sport_PT.Sportid AND sup.SiteID = Sport_PT.SiteID
					WHERE co.roleid =2 AND cs.apositiontaking <> Sport_PT.PT
	END

	--IF @ShowDetail = 1 
	--	BEGIN
	--		SELECT DISTINCT data.Sportid, sp.SportName
	--			,tblSport.SiteID LicenseeID, tblSport.Site Licensee
	--			,e.exchangeid CurrencyCode,e.Code Currency
	--			,co.Custid ,co.Username 
	--			,data.PT AS PT_Invaild ,data.PT_spec
	--		FROM #Member data
	--		INNER JOIN CheckCustDB.dbo.Customer co WITH(NOLOCK)
	--			ON data.Custid = co.Custid
	--		INNER JOIN CheckCustDB.dbo.exchange e WITH(NOLOCK) 
	--			ON co.currency = e.exchangeid
	--		LEFT JOIN CheckCustDB.dbo.Sports sp WITH(NOLOCK)
	--			ON data.SportID = sp.SportType
	--		LEFT JOIN #tmpSport_PT  tblSport 
	--			ON data.SiteID = tblSport.SiteID AND data.Sportid = tblSport.Sportid
	--		ORDER BY 1,2,3,4

	--		SELECT DISTINCT data.Sportid, sp.SportName
	--			,tblSport.SiteID LicenseeID, tblSport.Site AS Licensee
	--			,e.exchangeid CurrencyCode,e.Code Currency
	--			,co.Custid ,co.Username 
	--			,data.PT AS PT_Invaild ,data.PT_spec
	--		FROM #Licensee data
	--		INNER JOIN CheckCustDB.dbo.Customer co WITH(NOLOCK)
	--			ON data.Custid = co.Custid
	--		INNER JOIN CheckCustDB.dbo.exchange e WITH(NOLOCK) 
	--			ON co.currency = e.exchangeid
	--		LEFT JOIN CheckCustDB.dbo.Sports sp WITH(NOLOCK)
	--			ON data.SportID = sp.SportType
	--		LEFT JOIN #tmpSport_PT  tblSport 
	--			ON data.SiteID = tblSport.SiteID AND data.Sportid = tblSport.Sportid
	--		ORDER BY 1,2,3,4
	--	END
	--ELSE
	--	BEGIN
	--		SELECT DISTINCT CASE WHEN data.Sportid <=99 THEN 'Sports Book' 
	--				WHEN data.Sportid IN (161)  THEN 'Number Game' 
	--				WHEN data.Sportid IN (162)  THEN 'Live Casino'
	--				WHEN data.Sportid IN (151,152,153)  THEN 'Racing'			
	--				WHEN data.Sportid BETWEEN 180 AND 186  THEN 'Virtual Sports'
	--				WHEN data.Sportid IN (202)  THEN 'Keno'
	--				WHEN data.Sportid IN (251)  THEN 'RNG Casino'					
	--			END SportName
	--			,tblSport.SiteID LicenseeID, tblSport.Site  AS Licensee
	--			,e.exchangeid CurrencyCode,e.Code Currency
	--			,co.Custid ,co.Username 
	--			,data.PT AS PT_Invaild ,data.PT_spec
	--			,IsBA
	--		FROM #Member data
	--		INNER JOIN CheckCustDB.dbo.Customer co WITH(NOLOCK)
	--			ON data.Custid = co.Custid
	--		INNER JOIN CheckCustDB.dbo.exchange e WITH(NOLOCK) 
	--			ON co.currency = e.exchangeid
	--		LEFT JOIN bodb02.dbo.Sports sp WITH(NOLOCK)
	--			ON data.SportID = sp.SportType
	--		LEFT JOIN #tmpSport_PT  tblSport 
	--			ON data.SiteID = tblSport.SiteID AND data.Sportid = tblSport.Sportid 
	--		ORDER BY 1,2,3,4

	--		SELECT DISTINCT CASE WHEN data.Sportid <=99 THEN 'Sports Book' 
	--				WHEN data.Sportid IN (151,152,153)  THEN 'Racing'
	--				WHEN data.Sportid IN (161)  THEN 'Number Game' 
	--				WHEN data.Sportid IN (162)  THEN 'Live Casino'				
	--				WHEN data.Sportid BETWEEN 180 AND 186  THEN 'Virtual Sports'
	--				WHEN data.Sportid IN (202)  THEN 'Keno'
	--				WHEN data.Sportid IN (251)  THEN 'RNG Casino'
	--			END SportName
	--			,tblSport.SiteID LicenseeID,  tblSport.Site   AS Licensee
	--			,e.exchangeid CurrencyCode,e.Code Currency
	--			,co.Custid ,co.Username 
	--			,data.PT AS PT_Invaild ,data.PT_spec
	--		FROM #Licensee data
	--		INNER JOIN CheckCustDB.dbo.Customer co WITH(NOLOCK)
	--			ON data.Custid = co.Custid
	--		INNER JOIN CheckCustDB.dbo.exchange e WITH(NOLOCK) 
	--			ON co.currency = e.exchangeid
	--		LEFT JOIN bodb02.dbo.Sports sp WITH(NOLOCK)
	--			ON data.SportID = sp.SportType
	--		LEFT JOIN #tmpSport_PT  tblSport 
	--			ON data.SiteID = tblSport.SiteID AND data.Sportid = tblSport.Sportid 
	--		ORDER BY 1,2,3,4
	--	END

	INSERT INTO CheckResultDB.[dbo].[CheckPTResult_Deposit]
		(SITEID, [BetType],[SportType],[CustId],[RoleID],PT_Invalid,PT_spec,IsBA)
	
	SELECT Distinct SiteID,BetType,SportID,CustID,1 [RoleID] ,PT,PT_spec,IsBA
	FROM #Member m


	INSERT INTO CheckResultDB.[dbo].[CheckPTResult_Deposit]
		(SITEID, [BetType],[SportType],[CustId],[RoleID],PT_Invalid,PT_spec,IsBA)
	
	SELECT Distinct SiteID,BetType,SportID,CustID,2 [RoleID] ,PT,PT_spec,0 IsBA
	FROM #Licensee m
