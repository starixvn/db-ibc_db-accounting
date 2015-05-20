USE CheckResultDB
 
GO 

ALTER PROCEDURE [dbo].DBA_CheckComm_Dep
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
		Bettype 
			@GroupComm  (1,2,3,7,8)
			@OtherComm	(4,6,9,10,20,21,22)
			@1x2Comm	(5)

	
*/
SET NOCOUNT ON

	SELECT @RestoreCustDB=CONVERT(Varchar(10),@RestoreCustDB,101)

	IF @sporttype IS NULL 
		SET @sporttype = -1
	
	IF OBJECT_ID('tempdb..#tmpAgent') IS NOT NULL		DROP TABLE #tmpAgent
	IF OBJECT_ID('tempdb..#tmpSport') IS NOT NULL 	DROP TABLE #tmpSport
	
	CREATE TABLE #tmpAgent(CustID INT,SiteID INT)
	CREATE TABLE #tmpSport(Sportid INT)

	IF @site IS NOT NULL AND @srecommend IS NULL
	BEGIN
		EXEC  [dbo].[DBA_Get_List_Super_Licensee] @Site =@Site ,	@srecommend = @srecommend  OUTPUT
	END

	INSERT INTO  #tmpAgent (CustID,SiteID)
	EXEC [dbo].[DBA_Get_List_Agency_Licensee]
		@srecommend =@srecommend

	INSERT INTO #tmpSport(Sportid)
	SELECT Sportid FROM [dbo].f_GetComm_Dep_ByProduct (@sporttype )

	IF OBJECT_ID('tempdb..#LicenseeBAConfig') IS NOT NULL 		DROP TABLE #LicenseeBAConfig
	IF OBJECT_ID('tempdb..#LicenseeBAHistory') IS NOT NULL 		DROP TABLE #LicenseeBAHistory
	IF OBJECT_ID('tempdb..#LicenseeSpecialCust') IS NOT NULL 	DROP TABLE #LicenseeSpecialCust	
	IF OBJECT_ID('tempdb..#LicenseeGroupComm') IS NOT NULL 		DROP TABLE #LicenseeGroupComm
	IF OBJECT_ID('tempdb..#LicenseeCustComm') IS NOT NULL 		DROP TABLE #LicenseeCustComm
	
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
 
 	CREATE TABLE #LicenseeBAHistory([LicenseeID] [int] NOT NULL,[CustID] [int] NOT NULL,[OnDate] [datetime] NOT NULL,[OffDate] [datetime] NULL,	
					[OnBy] [int] NOT NULL,[OffBy] [int] NULL,[GroupComm] [decimal](9, 8) NOT NULL,[1x2Comm] [decimal](9, 8) NOT NULL,
					[OtherComm] [decimal](9, 8) NOT NULL,
					[Status] [varchar](50) NOT NULL,
					[Ugroup] [varchar](3) NULL
			)

	CREATE TABLE #LicenseeSpecialCust(
		[LicenseeID] [int] NOT NULL,
		[CustID] [int] NOT NULL,
		ugroup VARCHAR(5) NOT NULL,
		ugroup_old VARCHAR(5) NOT NULL) 

	CREATE TABLE #LicenseeGroupComm(
		[id] [int] NULL,
		[Licenseeid] [int] NOT NULL,
		[GroupName] [varchar](100) NOT NULL,
		[IsActive] [bit] NOT NULL,
		[SBComm] [decimal](9, 8) NOT NULL,
		[RacingComm] [decimal](9, 8) NOT NULL,
		[NGComm] [decimal](9, 8) NOT NULL,
		[color] [varchar](20) NULL,
		[IsDefault] [bit] NOT NULL,
		[LCComm] [decimal](9, 8) NOT NULL,
		[RNGComm] [decimal](9, 8) NOT NULL)

	CREATE TABLE #LicenseeCustComm(
		[LicenseeID] [int] NOT NULL,
		[CustID] [int] NOT NULL,
		[SBComm] [decimal](9, 8) NULL,
		[RacingComm] [decimal](9, 8) NULL,
		[NGComm] [decimal](9, 8) NULL,
		[GroupCommID] [int] NOT NULL,
		[LCComm] [decimal](9, 8) NOT NULL,
		[RNGComm] [decimal](9, 8) NOT NULL) 

	INSERT INTO #LicenseeBAConfig
	SELECT [SiteID] ,LicenseeName [Site], lb.[LicenseeID],lb.[1x2Comm],lb.[OtherComm],lb.[EnableBA],lb.[groupa],lb.[groupb],lb.[groupc],lb.[groupd]
	FROM CheckLicenseeDB.dbo.LicenseeBAConfig lb WITH(NOLOCK)
		INNER JOIN CheckLicenseeDB.dbo.Licensees li WITH(NOLOCK)
			ON lb.LicenseeID = li.LicenseeID
		INNER JOIN bodb02.dbo.Site st WITH(NOLOCK)
			ON st.Site = li.LicenseeName
	WHERE lb.InsertDate = @RestoreCustDB AND (ISNULL(@site,'') ='' OR li.LicenseeName = @site)

	INSERT INTO #LicenseeBAHistory([LicenseeID],[CustID],[OnDate],[OffDate],[OnBy],[OffBy],[GroupComm],[1x2Comm],[OtherComm],[Status],[Ugroup])
	SELECT BA.[LicenseeID],BA.[CustID],BA.[OnDate],BA.[OffDate],BA.[OnBy],BA.[OffBy],BA.[GroupComm],BA.[1x2Comm],BA.[OtherComm],BA.[Status],BA.[Ugroup]
	FROM CheckLicenseeDB.dbo.LicenseeBAHistory BA WITH(NOLOCK) 
	WHERE BA.InsertDate = @RestoreCustDB AND BA.[Status] = 'running' 
		AND EXISTS(SELECT TOP 1 1 FROM #LicenseeBAConfig BAC WITH(NOLOCK)
					WHERE BA.[LicenseeID] = BAC.[LicenseeID])

	INSERT INTO #LicenseeSpecialCust([LicenseeID],[CustID],ugroup,ugroup_old)
	SELECT LIC.[LicenseeID],LIC.[CustID],LIC.ugroup,LIC.ugroup_old		
	FROM CheckLicenseeDB.dbo.LicenseeSpecialCust LIC WITH (NOLOCK) 
	  WHERE LIC.InsertDate = @RestoreCustDB 
		AND EXISTS(SELECT TOP 1 1 FROM #LicenseeBAConfig BAC WITH(NOLOCK)
									WHERE LIC.[LicenseeID] = BAC.[LicenseeID])

	INSERT INTO #LicenseeGroupComm([id],[Licenseeid],[GroupName],[IsActive],[SBComm],[RacingComm],[NGComm],[color],[IsDefault],[LCComm],[RNGComm])
	SELECT LGC.[id],LGC.[Licenseeid],LGC.[GroupName],LGC.[IsActive],LGC.[SBComm],LGC.[RacingComm],LGC.[NGComm]
		  ,LGC.[color],LGC.[IsDefault],LGC.[LCComm],LGC.[RNGComm]
	  FROM CheckLicenseeDB.dbo.[LicenseeGroupComm] LGC WITH(NOLOCK)
	  WHERE LGC.InsertDate = @RestoreCustDB 
			AND EXISTS(SELECT TOP 1 1 FROM #LicenseeBAConfig BAC WITH(NOLOCK)
					WHERE LGC.[LicenseeID] = BAC.[LicenseeID])

	INSERT INTO #LicenseeCustComm([LicenseeID],[CustID],[SBComm],[RacingComm],[NGComm],[GroupCommID],[LCComm],[RNGComm])
	SELECT LCC.[LicenseeID],LCC.[CustID],LCC.[SBComm],LCC.[RacingComm],LCC.[NGComm],LCC.[GroupCommID],LCC.[LCComm],LCC.[RNGComm]
	FROM CheckLicenseeDB.dbo.[LicenseeCustComm] LCC WITH(NOLOCK)
	WHERE LCC.InsertDate = @RestoreCustDB 
		AND EXISTS(SELECT TOP 1 1 FROM #LicenseeBAConfig BAC WITH(NOLOCK)
					WHERE LCC.[LicenseeID] = BAC.[LicenseeID])

	IF OBJECT_ID('tempdb..#Member') IS NOT NULL 		DROP TABLE #Member
	CREATE TABLE #Member (SiteID INT,CustID INT,RoleID INT,Ugroup VARCHAR(5),
			BetType INT, SportID INT,
			CommP [decimal](9, 8),
			CommA [decimal](9, 8),
			CommM [decimal](9, 8),
			CommS [decimal](9, 8),
			Comm_P_Spec [decimal](9, 8),
			Comm_SMA_Spec [decimal](9, 8),
			IsBA BIT DEFAULT(0))

	IF @sporttype IN (-1,154) OR @sporttype<99 -- Sport Book
	BEGIN
		INSERT INTO #Member(SiteID,CustID,RoleID,Ugroup,BetType,SportID,CommP,CommA,CommM,CommS,Comm_P_Spec,Comm_SMA_Spec,IsBA)
		SELECT BA.SiteID,cs.CustID,me.Roleid ,RIGHT(me.ugroup,1) ugroup,
				cs.BetType,cs.sporttype,
				cs.playerdiscount CommP,
				cs.discount CommA,
				cs.adiscount CommM,
				cs.sdiscount CommS,
				ISNULL(LGC.[SBComm],0.00) Comm_P_Spec,
				CASE WHEN BAH.CustID IS NOT NULL THEN
					CASE WHEN cs.bettype IN (1,2,3,7,8) THEN 
						CASE WHEN me.ugroup IN ('a','dea','hka') THEN BA.[groupa]
							WHEN me.ugroup IN ('b','deb','hkb')  THEN BA.[groupb]
							WHEN me.ugroup IN ('c','dec','hkc')  THEN BA.[groupc]
							WHEN me.ugroup IN ('d','ded','hkd')  THEN BA.[groupd]
							ELSE 0 END
						WHEN cs.bettype IN (5) THEN BA.[1x2Comm]
						WHEN cs.bettype IN (4,6,9,10,20,21,22) THEN BA.OtherComm
					END
				ELSE
					0.00
				END Comm_SMA_Spec,
				CASE WHEN BAH.CustID IS NOT NULL THEN 1 ELSE 0 END IsBA
		FROM CheckCustDB.dbo.dep_custsetting cs WITH(NOLOCK)
		INNER JOIN CheckCustDB.dbo.Customer me WITH(NOLOCK)
			ON cs.custid = me.custid
		INNER JOIN	#tmpAgent sup WITH(NOLOCK)
			ON sup.custid = me.recommend
		LEFT JOIN #LicenseeBAConfig BA WITH(NOLOCK)
			ON BA.[SiteID] = sup.[SiteID]
		LEFT JOIN #LicenseeBAHistory BAH WITH(NOLOCK) 
			ON cs.custid = BAH.custid
		LEFT JOIN #LicenseeSpecialCust LIC WITH (NOLOCK)
			ON cs.custid = LIC.custid 
		LEFT JOIN #LicenseeCustComm LCC WITH (NOLOCK)
			ON cs.custid = LCC.custid
		LEFT JOIN #LicenseeGroupComm LGC WITH (NOLOCK)
			ON LCC.GroupCommID = LGC.[id]
		WHERE EXISTS(SELECT TOP 1 1 FROM #tmpSport tmpSport WITH(NOLOCK)
							WHERE tmpSport.Sportid = cs.sporttype)
			AND EXISTS(SELECT TOP 1 1 FROM CheckCustDB.dbo.CustInfo Info WITH(NOLOCK)
							WHERE Info.CustID = me.CustID AND ISNULL(Info.[reject],0) = 0 AND ISNULL(Info.[closed],0)= 0)
			AND (me.roleid = 1
				AND (--IS BA
						(BAH.CustID IS NOT NULL 
						AND CASE WHEN cs.bettype IN (1,2,3,7,8) THEN 
								CASE WHEN me.ugroup IN ('a','dea','hka') AND (cs.discount <> BA.[groupa] OR cs.adiscount <> BA.[groupa] OR cs.sdiscount<> BA.[groupa]) THEN 1
									WHEN me.ugroup IN ('b','deb','hkb')  AND (cs.discount <> BA.[groupb] OR cs.adiscount <> BA.[groupb] OR cs.sdiscount<> BA.[groupb]) THEN 1
									WHEN me.ugroup IN ('c','dec','hkc')  AND (cs.discount <> BA.[groupc] OR cs.adiscount <> BA.[groupc] OR cs.sdiscount<> BA.[groupc]) THEN 1
									WHEN me.ugroup IN ('d','ded','hkd')  AND (cs.discount <> BA.[groupd] OR cs.adiscount <> BA.[groupd] OR cs.sdiscount<> BA.[groupd]) THEN 1
									ELSE 0 END
								WHEN cs.bettype IN (5) AND (cs.discount <> BA.[1x2Comm] OR cs.adiscount <> BA.[1x2Comm] OR cs.sdiscount<> BA.[1x2Comm]) THEN 1
								WHEN cs.bettype IN (4,6,9,10,20,21,22) AND (cs.discount <> BA.OtherComm OR cs.adiscount <> BA.OtherComm OR cs.sdiscount<> BA.OtherComm) THEN 1
								ELSE 0
						END=1)
						OR
							(BAH.CustID IS NULL AND (cs.discount <> 0 OR cs.adiscount <> 0 OR cs.sdiscount<> 0))
						OR (LCC.custid IS NOT NULL  AND LGC.[id] IS NOT NULL 
							AND ((cs.sporttype<99 OR cs.sporttype=154) AND LCC.[SBComm] <> cs.playerdiscount)
							)					
						)
				)			
				OR (
					me.roleid = 2
					AND  cs.discount <> 0.00
				)
	END

	IF @sporttype IN (-1,151,161,162,180,202,251)--+ Racing(151) + NumberGame(161)+Live Casino(162)+ Virtual Sport(180) + Keno(202) + RnG Casino(251)
	BEGIN
		INSERT INTO #Member(SiteID,CustID,RoleID,Ugroup,BetType,SportID,CommP,CommA,CommM,CommS,Comm_P_Spec,Comm_SMA_Spec,IsBA)
		SELECT BA.SiteID,cs.CustID,me.Roleid ,RIGHT(me.ugroup,1) ugroup,
				cs.BetType,cs.sporttype,
				cs.playerdiscount CommP,
				cs.discount CommA,
				cs.adiscount CommM,
				cs.sdiscount CommS,
				CASE WHEN cs.sporttype IN (151,152,153) THEN ISNULL(LGC.[RacingComm],0.00)
					WHEN cs.sporttype IN (161) THEN ISNULL(LGC.[NGComm],0.00)
					WHEN cs.sporttype IN (162) THEN ISNULL(LGC.[LCComm],0.00)
					WHEN cs.sporttype IN (251) THEN ISNULL(LGC.[RNGComm],0.00)
					ELSE 0.00
				 END Comm_P_Spec,
				CASE WHEN cs.sporttype IN (151,152,153) THEN
					CASE WHEN cs.sporttype = 151 AND cs.bettype IN (31,32,41,42) THEN 0.04
						WHEN cs.sporttype = 151 AND cs.bettype IN (51,52) THEN 0.03
						WHEN cs.sporttype = 152 AND cs.bettype IN (41,42) THEN 0.04
						WHEN cs.sporttype = 152 AND cs.bettype IN (51,52) THEN 0.03
						WHEN cs.sporttype = 153 AND cs.bettype IN (51,52) THEN 0.03
						ELSE 0.00
					END 
				ELSE 0.00
				END	Comm_SMA_Spec,
				CASE WHEN BAH.CustID IS NOT NULL THEN 1 ELSE 0 END IsBA
		FROM CheckCustDB.dbo.Dep_CustSetting3rd cs WITH(NOLOCK)
		INNER JOIN CheckCustDB.dbo.Customer me WITH(NOLOCK)
			ON cs.custid = me.custid
		INNER JOIN	#tmpAgent sup WITH(NOLOCK)
			ON sup.custid = me.recommend
		LEFT JOIN #LicenseeBAConfig BA WITH(NOLOCK)
			ON BA.[SiteID] = sup.[SiteID]
		--INNER JOIN #tmpSport tmpSport WITH(NOLOCK)
		--	ON tmpSport.Sportid = cs.sporttype
		LEFT JOIN #LicenseeBAHistory BAH WITH(NOLOCK) 
			ON cs.custid = BAH.custid
		LEFT JOIN #LicenseeSpecialCust LIC WITH (NOLOCK)
			ON cs.custid = LIC.custid 
		LEFT JOIN #LicenseeCustComm LCC WITH (NOLOCK)
			ON cs.custid = LCC.custid
		LEFT JOIN #LicenseeGroupComm LGC WITH (NOLOCK)
			ON LCC.GroupCommID = LGC.[id] 
		WHERE EXISTS(SELECT TOP 1 1 FROM #tmpSport tmpSport WITH(NOLOCK)
							WHERE tmpSport.Sportid = cs.sporttype)
			AND EXISTS(SELECT TOP 1 1 FROM CheckCustDB.dbo.CustInfo Info WITH(NOLOCK)
							WHERE Info.CustID = me.CustID AND ISNULL(Info.[reject],0) = 0 AND ISNULL(Info.[closed],0)= 0
									AND (Info.CustID = cs.CustID  
										AND ((cs.sporttype = 161 AND Info.DisableNumber=0)										  
										  OR (cs.sporttype = 151 AND Info.Disable151_AU=0)
										  OR (cs.sporttype = 152 AND cs.bettype IN (41,42) AND Info.Disable152_UK=0)
										  OR (cs.sporttype = 152 AND cs.bettype IN (51,52) AND Info.Disable152_AU=0)
										  OR (cs.sporttype = 153 AND Info.Disable153_AU=0)
										  OR (cs.sporttype >= 180 AND cs.sporttype <=186  AND Info.[DisableVirtualSports]=0)
										  --OR (cs.sporttype NOT IN (151,152,153,161,162,180,181,182,183,184,185,186) )
										)
								))
			AND (me.roleid IN (1,2)
				AND cs.discount <> CASE WHEN cs.sporttype IN (151,152,153) THEN
										CASE WHEN cs.sporttype = 151 AND cs.bettype IN (31,32,41,42) THEN 0.04
											WHEN cs.sporttype = 151 AND cs.bettype IN (51,52) THEN 0.03
											WHEN cs.sporttype = 152 AND cs.bettype IN (41,42) THEN 0.04
											WHEN cs.sporttype = 152 AND cs.bettype IN (51,52) THEN 0.03
											WHEN cs.sporttype = 153 AND cs.bettype IN (51,52) THEN 0.03
											ELSE 0.00
										END 
										ELSE 0.00
									END
								)
			OR (LCC.custid IS NOT NULL AND LGC.[id] IS NOT NULL 
				AND
					CASE WHEN cs.sporttype IN (151,152,153) THEN ISNULL(LGC.[RacingComm],0.00)
							WHEN cs.sporttype IN (161) THEN ISNULL(LGC.[NGComm],0.00)
							WHEN cs.sporttype IN (162) THEN ISNULL(LGC.[LCComm],0.00)
							WHEN cs.sporttype IN (251) THEN ISNULL(LGC.[RNGComm],0.00)
							ELSE 0.00
						 END
						 <> cs.playerdiscount
			)


INSERT INTO #Member(SiteID,CustID,RoleID,Ugroup,BetType,SportID,CommP,CommA,CommM,CommS,Comm_P_Spec,Comm_SMA_Spec,IsBA)
		SELECT BA.SiteID,cs.CustID,me.Roleid ,RIGHT(me.ugroup,1) ugroup,
				cs.BetType,cs.sporttype,
				cs.playerdiscount CommP,
				cs.discount CommA,
				cs.adiscount CommM,
				cs.sdiscount CommS,
				CASE WHEN cs.sporttype IN (151,152,153) THEN ISNULL(LGC.[RacingComm],0.00)
					WHEN cs.sporttype IN (161) THEN ISNULL(LGC.[NGComm],0.00)
					WHEN cs.sporttype IN (162) THEN ISNULL(LGC.[LCComm],0.00)
					WHEN cs.sporttype IN (251) THEN ISNULL(LGC.[RNGComm],0.00)
					ELSE 0.00
				 END Comm_P_Spec,
				CASE WHEN cs.sporttype IN (151,152,153) THEN
					CASE WHEN cs.sporttype = 151 AND cs.bettype IN (31,32,41,42) THEN 0.04
						WHEN cs.sporttype = 151 AND cs.bettype IN (51,52) THEN 0.03
						WHEN cs.sporttype = 152 AND cs.bettype IN (41,42) THEN 0.04
						WHEN cs.sporttype = 152 AND cs.bettype IN (51,52) THEN 0.03
						WHEN cs.sporttype = 153 AND cs.bettype IN (51,52) THEN 0.03
						ELSE 0.00
					END 
				ELSE 0.00
				END	Comm_SMA_Spec,
				CASE WHEN BAH.CustID IS NOT NULL THEN 1 ELSE 0 END IsBA
		FROM CheckCustDB.dbo.CustSettingGame cs WITH(NOLOCK)
		INNER JOIN CheckCustDB.dbo.Customer me WITH(NOLOCK)
			ON cs.custid = me.custid
		INNER JOIN	#tmpAgent sup WITH(NOLOCK)
			ON sup.custid = me.recommend
		LEFT JOIN #LicenseeBAConfig BA WITH(NOLOCK)
			ON BA.[SiteID] = sup.[SiteID]
		--INNER JOIN #tmpSport tmpSport WITH(NOLOCK)
		--	ON tmpSport.Sportid = cs.sporttype
		LEFT JOIN #LicenseeBAHistory BAH WITH(NOLOCK) 
			ON cs.custid = BAH.custid
		LEFT JOIN #LicenseeSpecialCust LIC WITH (NOLOCK)
			ON cs.custid = LIC.custid 
		LEFT JOIN #LicenseeCustComm LCC WITH (NOLOCK)
			ON cs.custid = LCC.custid
		LEFT JOIN #LicenseeGroupComm LGC WITH (NOLOCK)
			ON LCC.GroupCommID = LGC.[id] 
		WHERE EXISTS(SELECT TOP 1 1 FROM #tmpSport tmpSport WITH(NOLOCK)
							WHERE tmpSport.Sportid = cs.sporttype)
			AND EXISTS(SELECT TOP 1 1 FROM CheckCustDB.dbo.CustInfo Info WITH(NOLOCK)
							WHERE Info.CustID = me.CustID AND ISNULL(Info.[reject],0) = 0 AND ISNULL(Info.[closed],0)= 0
									AND (Info.CustID = cs.CustID  
									AND ( (cs.sporttype = 162 AND Info.[SyncLiveCasino]=1) 
										OR  (cs.sporttype = 202 AND Info.HideKeNo = 0) 
									)
								))
			AND (me.roleid IN (1,2) AND cs.discount <> 0.00	)
			OR (LCC.custid IS NOT NULL AND LGC.[id] IS NOT NULL 
				AND cs.playerdiscount<> 
					CASE WHEN cs.sporttype IN (151,152,153) THEN ISNULL(LGC.[RacingComm],0.00)
							WHEN cs.sporttype IN (161) THEN ISNULL(LGC.[NGComm],0.00)
							WHEN cs.sporttype IN (162) THEN ISNULL(LGC.[LCComm],0.00)
							WHEN cs.sporttype IN (251) THEN ISNULL(LGC.[RNGComm],0.00)
							ELSE 0.00
						 END
			)

	END

	INSERT INTO CheckResultDB.dbo.CheckCommResult_Deposit(SiteID,CustID,RoleID,Ugroup,BetType,[SportType],CommP,CommA,CommM,CommS,Comm_P_Spec,Comm_SMA_Spec,IsBA)
	SELECT DISTINCT
	 SiteID,CustID,RoleID,Ugroup,BetType,SportID,CommP,CommA,CommM,CommS,Comm_P_Spec,Comm_SMA_Spec,IsBA
	FROM #Member