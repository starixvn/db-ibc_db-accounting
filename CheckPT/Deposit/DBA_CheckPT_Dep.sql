USE CheckResultDB
 
GO 

ALTER PROCEDURE [dbo].DBA_CheckPT_Dep
(
	@RestoreCustDB SmallDateTime,
	@sporttype INT=NULL,
	@srecommend VARCHAR(1000)=NULL,
	@site VARCHAR(100)=NULL
)
AS
/*
	Created: 20131015@Tom.Vo	
	Task :   Check PT rules (Credit)
	DB: DB052.CheckResultDB
	Original:

	Revisions:
		-2014.04.22@Tom.Vo: 
			1. Change source table : DBLIC.Licensee -> CheckLicenseeDB
			2. Add parameter @RestoreCustDB
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

	SELECT @RestoreCustDB=CONVERT(Varchar(10),@RestoreCustDB,101)

	IF @sporttype IS NULL 
		SET @sporttype = -1
	
	IF OBJECT_ID('tempdb..#tmpAgent') IS NOT NULL			DROP TABLE #tmpAgent
	IF OBJECT_ID('tempdb..#Member') IS NOT NULL 			DROP TABLE #Member
	IF OBJECT_ID('tempdb..#Licensee') IS NOT NULL 			DROP TABLE #Licensee
	IF OBJECT_ID('tempdb..#tmpSport_PT') IS NOT NULL 		DROP TABLE #tmpSport_PT
	IF OBJECT_ID('tempdb..#LicenseeBAHistory') IS NOT NULL 	DROP TABLE #LicenseeBAHistory
	IF OBJECT_ID('tempdb..#LicenseeBAConfig') IS NOT NULL 	DROP TABLE #LicenseeBAConfig

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
	CREATE TABLE #LicenseeBAConfig(
		[SiteID] INT,
		[Site] VARCHAR(100),
		[LicenseeID] [int] NOT NULL,
		[1x2Comm] [decimal](9, 8) NOT NULL,
		[OtherComm] [decimal](9, 8) NOT NULL,
		[EnableBA] [bit] NOT NULL,
		[groupa] [decimal](9, 8) NOT NULL,
		[groupb] [decimal](9, 8) NOT NULL,
		[groupc] [decimal](9, 8) NOT NULL,
		[groupd] [decimal](9, 8) NOT NULL) 

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
	FROM CheckLicenseeDB.dbo.LicenseeBAHistory BA WITH(NOLOCK) 
	WHERE BA.InsertDate = @RestoreCustDB AND BA.[Status] = 'running'
	
	INSERT INTO #LicenseeBAConfig
	SELECT [SiteID] ,LicenseeName [Site], lb.[LicenseeID],lb.[1x2Comm],lb.[OtherComm],lb.[EnableBA],lb.[groupa],lb.[groupb],lb.[groupc],lb.[groupd]
	FROM CheckLicenseeDB.dbo.LicenseeBAConfig lb WITH(NOLOCK)
		INNER JOIN CheckLicenseeDB.dbo.Licensees li WITH(NOLOCK)
			ON lb.LicenseeID = li.LicenseeID
		INNER JOIN bodb02.dbo.Site st WITH(NOLOCK)
			ON st.Site = li.LicenseeName
	WHERE lb.InsertDate = @RestoreCustDB AND (ISNULL(@site,'') ='' OR li.LicenseeName = @site)
	
	--GET List Member is violated 
	IF @sporttype IN (-1,0) OR @sporttype <=99 OR @sporttype =154--SportBook
	BEGIN
		INSERT INTO #Member (SiteID,CUSTID,SPORTID,BetType,PT,PT_spec,IsBA)
		SELECT  Sport_PT.siteID,
				co.custid,
				cs.SportType,
				cs.BetType,
				cs.apositiontaking + cs.mpositiontaking + cs.spositiontaking as PT,
				CASE WHEN BA.custid IS NULL THEN Sport_PT.PT ELSE 0.00 END PT_spec,
				CASE WHEN (BA.custid IS NOT NULL AND (cs.apositiontaking <> 0 OR cs.mpositiontaking <> 0)) THEN 1 ELSE 0 END IsBA
			FROM CheckCustDB.dbo.Customer co WITH(NOLOCK)
			INNER JOIN	#tmpAgent sup	ON sup.custid = co.recommend AND co.roleid =1
			INNER JOIN	#tmpSport_PT  Sport_PT 	ON sup.SiteID = Sport_PT.SiteID
			INNER JOIN	CheckCustDB.dbo.Dep_CustSetting cs WITH(NOLOCK)
					ON cs.custid = co.custid AND cs.sporttype = Sport_PT.Sportid
			LEFT JOIN 	#LicenseeBAHistory BA WITH(NOLOCK) 
					ON co.custid = BA.custid
			WHERE EXISTS(SELECT TOP 1 1 FROM CheckCustDB.dbo.CustInfo Info WITH(NOLOCK)
							WHERE Info.CustID = co.CustID AND ISNULL(Info.[reject],0) = 0 AND ISNULL(Info.[closed],0)= 0)
					AND(
						(BA.custid IS NULL AND (cs.apositiontaking + cs.mpositiontaking + cs.spositiontaking <> Sport_PT.PT)) 
							OR 
						(BA.custid IS NOT NULL AND (cs.apositiontaking <> 0 OR cs.mpositiontaking <> 0))
					)
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
				INNER JOIN	#tmpAgent sup
						ON sup.custid = co.recommend
				INNER JOIN	CheckCustDB.dbo.Dep_CustSetting3rd cs WITH(NOLOCK) 
						ON cs.custid = co.custid 
				INNER JOIN	#tmpSport_PT  Sport_PT 
					ON cs.sporttype = Sport_PT.Sportid AND sup.SiteID = Sport_PT.SiteID
				WHERE EXISTS(SELECT TOP 1 1 FROM CheckCustDB.dbo.CustInfo Info WITH(NOLOCK)
							WHERE Info.CustID = co.CustID AND ISNULL(Info.[reject],0) = 0 AND ISNULL(Info.[closed],0)= 0
								AND (Info.CustID = cs.CustID  
										AND ( (cs.sporttype = 161 AND Info.DisableNumber=0)										  
										  OR (cs.sporttype = 151 AND Info.Disable151_AU=0)
										  OR (cs.sporttype = 152 AND cs.bettype IN (41,42) AND Info.Disable152_UK=0)
										  OR (cs.sporttype = 152 AND cs.bettype IN (51,52) AND Info.Disable152_AU=0)
										  OR (cs.sporttype = 153 AND Info.Disable153_AU=0)
										  OR (cs.sporttype >= 180 AND cs.sporttype <=186  AND Info.[DisableVirtualSports]=0)
										  --OR (cs.sporttype NOT IN (151,152,153,161,162,180,181,182,183,184,185,186) )
										)
								)
							)
					AND co.roleid =1
					AND (cs.apositiontaking + cs.mpositiontaking + cs.spositiontaking <> Sport_PT.PT)

			IF @sporttype IN (-1,202)--+Live Casino(162)+ Keno(202) 
				INSERT INTO #Member (SiteID,CUSTID,SPORTID,BetType,PT,PT_spec)
				SELECT Sport_PT.SiteID,
					co.custid,
					cs.SportType,
					cs.BetType,
					cs.apositiontaking + cs.mpositiontaking + cs.spositiontaking as PT,
					Sport_PT.PT
				FROM CheckCustDB.dbo.Customer co WITH(NOLOCK)
				INNER JOIN	#tmpAgent sup
						ON sup.custid = co.recommend
				INNER JOIN	CheckCustDB.dbo.CustSettingGame cs WITH(NOLOCK) 
						ON cs.custid = co.custid 
				INNER JOIN	#tmpSport_PT  Sport_PT 
					ON cs.sporttype = Sport_PT.Sportid AND sup.SiteID = Sport_PT.SiteID
				WHERE EXISTS(SELECT TOP 1 1 FROM CheckCustDB.dbo.CustInfo Info WITH(NOLOCK)
							WHERE Info.CustID = co.CustID AND ISNULL(Info.[reject],0) = 0 AND ISNULL(Info.[closed],0)= 0 
								AND (Info.CustID = cs.CustID  
									AND ( (cs.sporttype = 162 AND Info.[SyncLiveCasino]=1) 
										OR  (cs.sporttype = 202 AND Info.HideKeNo = 0) 
									)
								)
							)
					AND co.roleid =1
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
			INNER JOIN	#tmpAgent sup ON sup.custid = co.recommend AND co.roleid =2
			INNER JOIN	#LicenseeBAConfig BAC ON BAC.[SiteID] = sup.[SiteID]
			INNER JOIN	CheckCustDB.dbo.Dep_CustSetting cs WITH(NOLOCK) 
					ON cs.custid = co.custid
			INNER JOIN	#tmpSport_PT  Sport_PT
					ON cs.sporttype = Sport_PT.Sportid AND sup.SiteID = Sport_PT.SiteID
			WHERE EXISTS(SELECT TOP 1 1 FROM CheckCustDB.dbo.CustInfo Info WITH(NOLOCK)
							WHERE Info.CustID = co.CustID AND ISNULL(Info.[reject],0) = 0 AND ISNULL(Info.[closed],0)= 0)
					AND cs.apositiontaking <> Sport_PT.PT 
	
	IF @sporttype IN (-1,151,161,162,180,202,251)--+ Racing(151) + NumberGame(161)+ Virtual Sport(180) + RnG Casino(251)
	BEGIN
		IF @sporttype IN (-1,151,161,180,251)
			INSERT INTO #Licensee (SiteID,CUSTID,SPORTID,BetType,PT,PT_spec)
			SELECT   
						Sport_PT.SiteID,
						 co.custid,
						 Sport_PT.Sportid,
						 BetType,
						 cs.apositiontaking as PT,
						 Sport_PT.PT
				FROM CheckCustDB.dbo.Customer co WITH(NOLOCK)
				INNER JOIN	#tmpAgent sup
						ON sup.custid = co.recommend
				INNER JOIN	CheckCustDB.dbo.Dep_CustSetting3rd cs WITH(NOLOCK) 
						ON cs.custid = co.custid
				INNER JOIN	#tmpSport_PT  Sport_PT
						ON cs.sporttype = Sport_PT.Sportid AND sup.SiteID = Sport_PT.SiteID
				WHERE EXISTS(SELECT TOP 1 1 FROM CheckCustDB.dbo.CustInfo Info WITH(NOLOCK)
							WHERE Info.CustID = co.CustID AND ISNULL(Info.[reject],0) = 0 AND ISNULL(Info.[closed],0)= 0
								AND (Info.CustID = cs.CustID  
										AND ( (cs.sporttype = 161 AND Info.DisableNumber=0)
										  OR (cs.sporttype = 151 AND Info.Disable151_AU=0)
										  OR (cs.sporttype = 152 AND cs.bettype IN (41,42) AND Info.Disable152_UK=0)
										  OR (cs.sporttype = 152 AND cs.bettype IN (51,52) AND Info.Disable152_AU=0)
										  OR (cs.sporttype = 153 AND Info.Disable153_AU=0)
										  OR (cs.sporttype >= 180 AND cs.sporttype <=186  AND Info.[DisableVirtualSports]=0)
										  --OR (cs.sporttype NOT IN (151,152,153,161,162,180,181,182,183,184,185,186) )
										)
								))
						AND co.roleid =2 
						AND cs.apositiontaking <> Sport_PT.PT

		IF @sporttype IN (-1,162,202)--+Live Casino(162)+ Keno(202) 
			INSERT INTO #Licensee (SiteID,CUSTID,SPORTID,BetType,PT,PT_spec)
				SELECT   
							Sport_PT.SiteID,
							 co.custid,
							 Sport_PT.Sportid,
							 BetType,
							 cs.apositiontaking as PT,
							 Sport_PT.PT
					FROM CheckCustDB.dbo.Customer co WITH(NOLOCK)
					INNER JOIN	#tmpAgent sup
							ON sup.custid = co.recommend
					INNER JOIN	CheckCustDB.dbo.CustSettingGame cs WITH(NOLOCK) 
							ON cs.custid = co.custid
					INNER JOIN	#tmpSport_PT  Sport_PT
							ON cs.sporttype = Sport_PT.Sportid AND sup.SiteID = Sport_PT.SiteID
					WHERE EXISTS(SELECT TOP 1 1 FROM CheckCustDB.dbo.CustInfo Info WITH(NOLOCK)
							WHERE Info.CustID = co.CustID AND ISNULL(Info.[reject],0) = 0 AND ISNULL(Info.[closed],0)= 0
								AND (Info.CustID = cs.CustID  
									AND ( (cs.sporttype = 162 AND Info.[SyncLiveCasino]=1) 
										OR  (cs.sporttype = 202 AND Info.HideKeNo = 0) 
									)
								)
							)
						AND	co.roleid =2 
						AND cs.apositiontaking <> Sport_PT.PT
	END	

	INSERT INTO CheckResultDB.[dbo].[CheckPTResult_Deposit]
		(SITEID, [BetType],[SportType],[CustId],[RoleID],PT_Invalid,PT_spec,IsBA)
	
	SELECT SiteID,BetType,SportID,CustID,1 [RoleID] ,PT,PT_spec,IsBA
	FROM #Member m


	INSERT INTO CheckResultDB.[dbo].[CheckPTResult_Deposit]
		(SITEID, [BetType],[SportType],[CustId],[RoleID],PT_Invalid,PT_spec,IsBA)
	
	SELECT SiteID,BetType,SportID,CustID,2 [RoleID] ,PT,PT_spec,0 IsBA
	FROM #Licensee m

	IF OBJECT_ID('tempdb..#tmpAgent') IS NOT NULL			DROP TABLE #tmpAgent
	IF OBJECT_ID('tempdb..#Member') IS NOT NULL 			DROP TABLE #Member
	IF OBJECT_ID('tempdb..#Licensee') IS NOT NULL 			DROP TABLE #Licensee
	IF OBJECT_ID('tempdb..#tmpSport_PT') IS NOT NULL 		DROP TABLE #tmpSport_PT
	IF OBJECT_ID('tempdb..#LicenseeBAHistory') IS NOT NULL 	DROP TABLE #LicenseeBAHistory
	IF OBJECT_ID('tempdb..#LicenseeBAConfig') IS NOT NULL 	DROP TABLE #LicenseeBAConfig