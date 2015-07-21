USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Acc_CustomerSelStatus]    Script Date: 07/17/2015 12:31:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Acc_CustomerSelStatus    Script Date: 6/24/2015 10:04:49 AM ******/
ALTER PROCEDURE [dbo].[Acc_CustomerSelStatus]
	@CustID		INT,
	@AdminID	INT			= 0,
	@system		VARCHAR(30)	='NAP',
	@username	VARCHAR(50)	= ''
AS 
/*
Created: 20090125@nqminh
Task : Select customer's status
DB: DBACC.bodb02
Original:

Revisions:
    - 20090411@PhuongDoan: Add casino status    
    - 20090731@nqminh: Add outright status    
	- 20090806@huynguyen: Add closed, autosuspend, isautopositiontaking
	- 20090829@[Shifu]: Add IsInternal
	- 20100223@[Ryan]: Add IsAdminCanViewVNIP
	- 20100227@Jamie: Change the way to check permission 
	- 20100402@Lee: Add mrecommend, arecommend 
	- 20100504@Huynguyen: Add DisableOpenTote
	- 20100828@SonPhan: Add DisableBingo, DisableNumber, SyncBingo
	- 20101015@Ethan: Get Limited Per IP value @LimitPerIP + SelectedBetting
	- 20110914@Tom: Add column DisableP2P
	- 20120131@Johnson: - Add Parameter @username support get by username
						- Add DisableLiveCasino, SyncLiveCasino
	- 20120808@Sophia: Add DisableVirtualSports, HideVirtualSports	
	- 20120927@Sophia: Get DoubleCommLosing	
	- 20130723@Jamie: Change Alias DB03 to DBPOLICY
	- 20131011@Elodie: Add HR Fixed Odds [Redmine:#6505]
	- 20140303@Kathy: Get HideKeno [Redmine:#12691]
	- 20140407@Elodie: Get DisableKeno [Redmine:#13156]
	- 20140825@Logan:   Get status of E-Sports [Redmine: #20531]
	- 20150210@Johnson: use param @system to check permission on ViewIPVN function from NAP or NAP EXT internal login [Redmine: #30860]
	- 20150422@Elodie: Add Gold Deluxe product [Redmine:#34486]
	- 20150610@Kos: Separate CustDB to DBCUST server (Move SP to DBCUST.CustDB)
	- 20150717@Kiwi: Move SP to DB06.bodb02 to solve the performance issue for temporary
	
Param's Explanation:
• @system: = NAP : internal login from NAP
			NAPEXT:internal login from NAP EXT
• @CustID: customer id.   
*/

SET NOCOUNT ON

----- 20150610@Kos -------------------
--DECLARE @tmp_GameType TABLE (GameTypeID INT, GameTypeName NVARCHAR(50), IsDisabled BIT, IBCBettypeID INT)	

--BEGIN TRY
	--INSERT INTO @tmp_GameType (GameTypeID, GameTypeName, IsDisabled, IBCBettypeID)
	--SELECT GameTypeID, GameTypeName, IsDisabled, IBCBettypeID FROM dbo.GameType WITH (NOLOCK)
--END TRY
--BEGIN CATCH
--	INSERT INTO @tmp_GameType (GameTypeID, GameTypeName, IsDisabled, IBCBettypeID)
--	SELECT GameTypeID, GameTypeName, IsDisabled, IBCBettypeID FROM DBTXN.bodb02.dbo.GameType WITH (NOLOCK)
--END CATCH
----- 20150610@Kos -------------------

DECLARE @agentid INT, @roleid TINYINT, @IsInternal BIT, @IsAdminCanViewVNIP BIT,  @LimitPerIP tinyint, @SelectedBetting bit

IF ISNULL(@username,'') <> ''
	SELECT @roleid = roleid, @agentid = recommend, @custid = custid
	FROM custinfo WITH (NOLOCK)
	WHERE username = @username
ELSE 
	SELECT @roleid = roleid, @agentid = recommend
	FROM custinfo WITH (NOLOCK)
	WHERE custid = @CustID
	
SET @LimitPerIP = 0
SET @SelectedBetting = 0
SET @IsInternal = 0

IF @roleid = 4 --super
BEGIN
	SELECT 
		@IsInternal = isnull(IsInternal, 0) ,
		@LimitPerIP =  isnull(LimitPerIP, 0),
		@SelectedBetting =  isnull(SelectedBetting, 0)
	FROM custSuper WITH (NOLOCK) WHERE custid = @custid
END
ELSE IF @roleid = 3 --master
BEGIN
	SELECT 
		@IsInternal = isnull(IsInternal, 0) ,
		@LimitPerIP =  isnull(LimitPerIP, 0),
		@SelectedBetting =  isnull(SelectedBetting, 0)
	FROM custMaster WITH (NOLOCK) WHERE custid = @custid
END
ELSE IF @roleid = 2 --agent
BEGIN
	SELECT 
		@IsInternal = isnull(IsInternal, 0) ,
		@LimitPerIP =  isnull(LimitPerIP, 0),
		@SelectedBetting =  isnull(SelectedBetting, 0)
	FROM custAgent WITH (NOLOCK) WHERE custid = @custid
END
ELSE IF @roleid = 1 --member
BEGIN
	SELECT 
		@IsInternal = isnull(IsInternal, 0) 
	FROM custAgent WITH (NOLOCK) WHERE custid = @agentid
END

--Get Internal status
/*
SELECT @IsInternal = CASE @roleid WHEN 4 THEN (SELECT isnull(IsInternal, 0) FROM custSuper WITH (NOLOCK) WHERE custid = @custid)
								  WHEN 3 THEN (SELECT isnull(IsInternal, 0) FROM custMaster WITH (NOLOCK) WHERE custid = @custid)
								  WHEN 2 THEN (SELECT isnull(IsInternal, 0) FROM custAgent WITH (NOLOCK) WHERE custid = @custid)
								  WHEN 1 THEN (SELECT isnull(IsInternal, 0) FROM custAgent WITH (NOLOCK) WHERE custid = @agentid)
								  ELSE 0 END 
*/								  
		

SELECT @IsAdminCanViewVNIP = 1
IF (@AdminID > 0) 
BEGIN
	DECLARE @ErrCode INT
	IF @system = 'NAP'
	BEGIN
		EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission_All @custid=@AdminID,@funcname='[ViewIPVN]',@ErrCode=@ErrCode OUTPUT
	END
	ELSE IF @system = 'NAPEXT'
	BEGIN
		EXEC DBEAS.bodb_EAS.dbo.EAS_UserCheckPermission_All @userid=@AdminID,@FuncKey='ViewVNIP',@ErrCode=@ErrCode OUTPUT
	END
	
	IF @ErrCode<> 0 SELECT @IsAdminCanViewVNIP = 0 ELSE SELECT @IsAdminCanViewVNIP = 1     
END

SELECT	ISNULL(reject,0) AS Suspend,
		ISNULL (closed,0) As Closed,
		ISNULL (autosuspend,0) As AutoSuspend,	
		ISNULL (cm.DisableAutoMPT ,0) As DisableAutoMPT,	
		ISNULL(DisableHorseracing,0) AS DisableHorseracing,
		ISNULL(DisableOpenTote,0) AS DisableOpenTote,
		ISNULL(DisableFinancial,0) AS DisableFI,
		ISNULL(SyncCasino,0) AS SyncCasino,
		ISNULL(DisableCasino,0) AS DisableCasino,
		ISNULL(DisableOutright,0) AS DisableOutright,
		ISNULL(DisableBingo,0) AS DisableBingo,
		ISNULL(DisableNumber,0) AS DisableNumber,
		ISNULL(DisableP2P,0) AS DisableP2P,	   
		ISNULL(SyncBingo,0) AS SyncBingo,
		ISNULL(DisableLiveCasino,0) AS DisableLiveCasino,
		ISNULL(SyncLiveCasino,0) AS SyncLiveCasino,
		ISNULL(srecommend, 0) AS SRecommend,
		ISNULL(mrecommend, 0) AS MRecommend,
		ISNULL(recommend, 0) as ARecommend,
		ISNULL(@IsAdminCanViewVNIP,1) AS IsAdminCanViewVNIP,
		@LimitPerIP as LimitPerIP,
		@SelectedBetting as SelectedBetting,
		@IsInternal AS IsInternal,
		ISNULL(DisableVirtualSports,0) as DisableVirtualSports,
		ISNULL(HideVirtualSports,0) as HideVirtualSports,
		ISNULL(DoubleCommLosing,0) as DoubleCommLosing,
		ISNULL(DisableHRFixedOdds,0) AS DisableHRFixedOdds,
		ISNULL(ci.DisableEsports, 0) AS DisableEsports,

		ISNULL(ci.HideKeno,0) as HideKeno, 
		min(case when g.IBCBetTypeID in (1501,1503,1504,1505,1507,1508,1509,1511,1513) then cg.IsDisabled else 1 end) as DisableKeno,
		ISNULL(DisableGoldDeluxe,1) as DisableGoldDeluxe,
		ISNULL(HideGoldDeluxe,1) as HideGoldDeluxe
FROM custinfo AS ci WITH (nolock)
	LEFT JOIN CustMaster AS cm WITH (NOLOCK) ON ci.CustID = cm.custid
	LEFT JOIN CustGameType cg with(nolock) on ci.custid = cg.custid
	LEFT JOIN dbo.GameType g on cg.GameTypeID = g.GameTypeID and g.IBCBetTypeID in (1501,1503,1504,1505,1507,1508,1509,1511,1513)		
WHERE ci.CustID = @CustID
group by
		ci.reject,
		ci.closed,
		ci.autosuspend,
		cm.DisableAutoMPT,
		ci.DisableHorseracing, 
		ci.DisableOpenTote, 
		ci.DisableFinancial, 
		ci.SyncCasino, 
		ci.DisableCasino, 
		ci.DisableOutright, 
		ci.DisableBingo, 
		ci.DisableNumber, 
		ci.DisableP2P, 
		ci.SyncBingo, 
		ci.DisableLiveCasino, 
		ci.SyncLiveCasino, 
		ci.srecommend, 
		ci.mrecommend, 
		ci.recommend, 
		ci.DisableVirtualSports, 
		ci.HideVirtualSports, 
		ci.DoubleCommLosing, 
		ci.DisableHRFixedOdds,
		ci.DisableEsports,
		ci.HideKeno,
		ci.DisableGoldDeluxe, 
		ci.HideGoldDeluxe

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelStatus] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelStatus] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelStatus] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelStatus] TO [bodbExtAccNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerSelStatus] TO [vnteam] AS [dbo]