USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[NAP_VoidMetricGaming_Del]    Script Date: 09/08/2015 12:18:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[NAP_VoidMetricGaming_Del]
	@MatchId			INT,
	@BetTypes			VARCHAR(1000)	= '',		
	@Event801			VARCHAR(2000) 	= '',--801 
	@Event803			VARCHAR(2000) 	= '',--803 	
	@Event804			VARCHAR(2000) 	= '',--804 
	@Event805			VARCHAR(2000) 	= '',--805
	
    @UserName 				NVARCHAR(50),
    @UserPassword			NVARCHAR(50),
    @UserID					INT,
    @IP						VARCHAR(15)		= '',
    @Reason					NVARCHAR(500)	= '',	
	@SecondAcceptFlag		TINYINT			= 0 ,
    
	@TransIdsCredit			VARCHAR(MAX) 	= '',		-- for custom delete (Credit bets)
	@TransIdsDeposit		VARCHAR(MAX) 	= '',		-- for custom delete (Deposit bets)
    @TransIdsBetDaq			VARCHAR(MAX) 	= '',		-- for custom delete BetDaq
    @TransIds12EU			VARCHAR(MAX) 	= '',		-- for custom delete 12EU
    @TransIdsMHC			VARCHAR(MAX) 	= '',		-- for custom delete master MHC	   
	@TransIdsFB				VARCHAR(MAX) 	= '',		-- for custom delete Foobet	   
	@TransIdsBetFair		VARCHAR(MAX) 	= '',		-- for custom delete Betfair	  
	@TransIdsOneExchange	VARCHAR(MAX) 	= '',		-- for custom delete ONEEXCHANGE    	

	@ErrMsg					NVARCHAR(200)	= ''	OUTPUT,
    @ErrCode				INT				= 0		OUTPUT

AS
	/*
	Created by: 20150629@Dominic
	Task : Special Delete
	DB: DBTXN/bodb02
	Original:

	Revisions:
			  - 20150806@Kathy: Using new balance table (BalCreditSportsPending,BalDebitSportsPending) [Redmine:#40125]
			  
	Param's Explanation:


	*/
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @FromDate	DATETIME
	SELECT	@FromDate =  CONVERT(VARCHAR(10),CURRENT_TIMESTAMP,120)
	
	--Remove checking permission codes on DBPolicy [Redmine:#27058]	
	--Check permission for account site:	
	--EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission 
	--	@custid		= @UserID,
	--	@funcname	= '[SpecialDelete]',
	--	@ErrCode	= @ErrCode OUTPUT,
	--	@ErrMsg		= @ErrMsg OUTPUT
		
	--IF @ErrCode <> 0
	--	RETURN
	--end remove code

	--Check settled Date
	DECLARE @eventdate DATETIME 
	
	SELECT @eventdate = eventdate
	FROM match WITH(NOLOCK)
	WHERE matchid = @MatchId
			
	EXEC dbo.Acc_CheckSettledDate
		@winlostdate	= @eventdate, 
		@UserID			= @UserID, 
		@ErrCode		= @ErrCode OUTPUT, 
		@ErrMsg			= @ErrMsg OUTPUT
		
	If @ErrCode <> 0
		RETURN
	--end	

	-- Check password
	DECLARE @LogData NVARCHAR(500)
	
	IF NOT EXISTS (SELECT 1
					FROM custDB.dbo.customer WITH(NOLOCK)
					WHERE userpwd = @UserPassword
						AND custid = @UserID
						AND roleid>=5)
	BEGIN
		SELECT @LogData ='fail to void bet for matchid ' + CONVERT(VARCHAR(20), 
			@MatchId) 
			+ ' Event801= ' + @Event801 
			+ ' Event803= ' + @Event803
			+ ' Event804= ' + @Event804
			+ ' Event805= ' + @Event805
			+ ' reason: ' + @Reason
			
		EXEC WriteLog_UserLog 
			@UserID = @UserID, 
			@Doing	= @LogData
			
		SELECT @ErrMsg = 'Sorry. You can not process void bet due to either wrong password or insufficient permission!'
			,@ErrCode  = 101   
		
		RETURN
	END
	
	---- check AND not allow attempt to delete same game while it's still not finish
	DECLARE @Remark VARCHAR(500)
			,@KeyID INT


	SET @KeyID = 3

	
	IF EXISTS (SELECT 1 FROM dbo.TempVariableNumber WHERE KeyID = @KeyID AND KeyValue = @MatchId)
	BEGIN
		SELECT  @ErrCode = 101,
				@ErrMsg = 'This match is being calculated or some tickets of this match are being voided, please wait a few seconds until the on-going process is completed and try again.'
		RETURN
	END
	
	INSERT INTO dbo.TempVariableNumber (KeyID, KeyValue) VALUES (@KeyID, @MatchId)
	
	IF (@@Error = 0)
	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
			@UserID		= @UserID, 
			@MatchId	= @MatchId, 
			@KeyID		= @KeyID,
			@ActionID	= 0, 
			@Remark		= 'ADD SUCCESS SPName=NAP_VoidMetricGaming_Del'
	END TRY
	BEGIN CATCH
		SELECT @Remark = 'ADD SUCCESS SPName=NAP_VoidMetricGaming_Del ErrMsg=' + LEFT(error_message(), 400)
		
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
			@UserID		= @UserID, 
			@MatchId	= @MatchId, 
			@KeyID		= @KeyID,
			@ActionID	= 0, 
			@Remark		= @Remark
	END CATCH
	ELSE 
	BEGIN
		BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
			@UserID		= @UserID, 
			@MatchId	= @MatchId, 
			@KeyID		= @KeyID,
			@ActionID	= 0, 
			@Remark		= 'ADD FAILED SPName=NAP_VoidMetricGaming_Del'
	END TRY
	BEGIN CATCH
		SELECT @Remark = 'ADD FAILED SPName=NAP_VoidMetricGaming_Del ErrMsg=' + LEFT(error_message(), 400)
		
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
			@UserID		= @UserID, 
			@MatchId	= @MatchId, 
			@KeyID		= @KeyID,
			@ActionID	= 0, 
			@Remark		= @Remark
	END CATCH
	
		SELECT @ErrCode = 100, 
			@ErrMsg		= 'This match is being calculated or some tickets of this match are being voided, please wait a few seconds until the on-going process is completed and try again.'
			
		RETURN
	END
	-------------------		
	CREATE TABLE #BetDelete (
		transid				BIGINT PRIMARY KEY, 
		refno				BIGINT,
		custid				INT, 
		actual_stake		MONEY,
		recommend			INT, 
		mrecommend			INT, 
		srecommend			INT, 
		betfrom				NVARCHAR(1),
		statusID			INT, 
		status				NVARCHAR(10), 
		SecAcceptFlag		BIT, 
		username			VARCHAR(30),
		creator				VARCHAR(30), 
		hdp1 				SMALLMONEY,  
		hdp2 				SMALLMONEY,
		bettype 			SMALLINT, 
		betteam 			NVARCHAR(10),
		betcheck			NVARCHAR(50),
		odds				SMALLMONEY, 
		OddsType			INT,
		transdate			DATETIME,
		IsLiveIndicator		BIT,
		livehomescore 		SMALLINT, 
		liveawayscore 		SMALLINT,
		Stake				MONEY,
		CurrencyName		VARCHAR(10),
		betid				BIGINT,
		transdesc			NVARCHAR(300),
		TicketType			TINYINT --1:From Bettrans, 2:From translog
		)

	DECLARE @Event801Tbl TABLE(Custom1 VARCHAR(50))
	INSERT @Event801Tbl(Custom1)
	SELECT val FROM dbo.strSplit(@Event801, '^')
	
	DECLARE @Event803Tbl TABLE(Custom1 VARCHAR(50))
	INSERT @Event803Tbl(Custom1)
	SELECT val FROM dbo.strSplit(@Event803, '^')
	
	DECLARE @Event804Tbl TABLE(Custom1 VARCHAR(50))
	INSERT @Event804Tbl(Custom1)
	SELECT val FROM dbo.strSplit(@Event804, '^')
	
	DECLARE @Event805Tbl TABLE(Custom1 VARCHAR(50))
	INSERT @Event805Tbl(Custom1)
	SELECT val FROM dbo.strSplit(@Event805, '^')
	
	
	DECLARE @12EUCust			TABLE (custid INT)
	DECLARE @DepositCust		TABLE (custid INT)	
	DECLARE @UUSCust			TABLE (custid INT)
	DECLARE @RealCurrCust		TABLE (custid INT)
	DECLARE @FoobetCust			TABLE (custid INT)
	DECLARE @BetFairCust		TABLE (custid INT)
	DECLARE @OneExchangeCust	TABLE (custid INT)



	DECLARE @tblTransCredit			TABLE(transid BIGINT PRIMARY KEY)
	DECLARE @tblTransDeposit		TABLE(transid BIGINT PRIMARY KEY)
	DECLARE @tblTransBetDaq			TABLE(transid BIGINT PRIMARY KEY)
	DECLARE @tblTrans12EU			TABLE(transid BIGINT PRIMARY KEY)
	DECLARE @tblTransMHC			TABLE(transid BIGINT PRIMARY KEY)
	DECLARE @tblTransFB				TABLE(transid BIGINT PRIMARY KEY)
	DECLARE @tblTransBetFair		TABLE(transid BIGINT PRIMARY KEY)
	DECLARE @tblTransOneExchange	TABLE(transid BIGINT PRIMARY KEY)

	BEGIN TRY
		INSERT INTO @tblTransCredit
		SELECT CONVERT(BIGINT, val) FROM dbo.strSplit(ISNULL(@TransIdsCredit, ''), ',')
		
		INSERT INTO @tblTransDeposit
		SELECT CONVERT(BIGINT, val) FROM dbo.strSplit( ISNULL(@TransIdsDeposit,''), ',')

		INSERT INTO @tblTransBetDaq
		SELECT CONVERT(BIGINT, val) FROM dbo.strSplit(ISNULL(@TransIdsBetDaq,''), ',')
	
		INSERT INTO @tblTrans12EU
		SELECT CONVERT(BIGINT, val) FROM dbo.strSplit(ISNULL(@TransIds12EU,''), ',')
	
		INSERT INTO @tblTransMHC
		SELECT CONVERT(BIGINT, val) FROM dbo.strSplit(ISNULL(@TransIdsMHC,''), ',')

		INSERT INTO @tblTransFB
		SELECT CONVERT(BIGINT, val) FROM dbo.strSplit(ISNULL(@TransIdsFB,''), ',')

		INSERT INTO @tblTransBetFair
		SELECT CONVERT(BIGINT, val) FROM dbo.strSplit(ISNULL(@TransIdsBetFair,''), ',')

		INSERT INTO @tblTransOneExchange
		SELECT CONVERT(BIGINT, val) FROM dbo.strSplit(ISNULL(@TransIdsOneExchange,''), ',')
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 101, @ErrMsg = 'Invalid TransIds.'
		
		DELETE FROM dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK)
		WHERE KeyID = @KeyID AND KeyValue = @MatchId
		
		BEGIN TRY
				EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
					@UserID		= @UserID, 
					@MatchId	= @MatchId, 
					@KeyID		= @KeyID,
					@ActionID	= 0, 
					@Remark		= 'VOID FAILED SPName=NAP_VoidMetricGaming_Del'
		END TRY
		BEGIN CATCH
			SELECT @Remark = 'VOID FAILED SPName=NAP_VoidMetricGaming_Del ErrMsg=' + LEFT(error_message(), 400)
			
			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID		= @UserID, 
				@MatchId	= @MatchId, 
				@KeyID		= @KeyID,
				@ActionID	= 0, 
				@Remark		= @Remark
		END CATCH
			RETURN
	END CATCH
	------------------***** Insert all data into #BetDelete *****------------------
	INSERT INTO #BetDelete
	SELECT DISTINCT transid, b.refno, custid, b.actual_stake, recommend, mrecommend, srecommend, betfrom, statusID, status, SecAcceptFlag, 
		b.Username, b.creator, b.hdp1, b.hdp2, b.bettype, b.betteam, b.betcheck, b.odds, b.oddstype, b.transdate, b.liveindicator, b.livehomescore, 
		b.liveawayscore, b.stake, b.CurrencyName, b.betid, b.transdesc, 1 --TicketType
	FROM dbo.bettrans b WITH (NOLOCK)
		INNER JOIN dbo.strSplit(@bettypes,'^') AS bt ON bt.val=b.bettype
		INNER JOIN dbo.match mat WITH(NOLOCK) ON mat.matchid = b.matchid
	WHERE b.matchid=@matchid 
		AND (b.refno IN (SELECT transid FROM @tblTransCredit)
			OR b.refno IN (SELECT transid FROM @tblTransDeposit )
			OR b.refno IN (SELECT transid FROM @tblTransBetDaq )
			OR b.refno IN (SELECT transid FROM @tblTrans12EU )
			OR b.refno IN (SELECT transid FROM @tblTransMHC )
			OR b.refno IN (SELECT transid FROM @tblTransFB )
			OR b.refno IN (SELECT transid FROM @tblTransBetFair )
			OR b.refno IN (SELECT transid FROM @tblTransOneExchange )
			)
		AND statusID NOT IN (101,102 ) -- reject, void
		AND mat.eventdate >=@FromDate
		AND 1 = CASE WHEN b.Bettype IN (801,803,804,805) THEN CASE 
								WHEN b.Bettype = 801
									AND EXISTS(
											SELECT TOP 1 1
											FROM @Event801Tbl rs
											WHERE ISNULL(rs.Custom1,'') <> '' AND CHARINDEX('BettypeTime='+ rs.Custom1, b.transdesc,0) <> 0
										)
									THEN 1
								WHEN b.Bettype = 803
									AND EXISTS(
											SELECT TOP 1 1
											FROM @Event803Tbl rs
											WHERE ISNULL(rs.Custom1,'') <> '' AND CHARINDEX('BettypeTime='+ rs.Custom1, b.transdesc,0) <> 0
										)
									THEN 1
								WHEN b.Bettype = 804
									AND EXISTS(
											SELECT TOP 1 1
											FROM @Event804Tbl rs
											WHERE ISNULL(rs.Custom1,'') <> '' AND CHARINDEX('BettypeTime='+ rs.Custom1, b.transdesc,0) <> 0
										)
									THEN 1
								WHEN b.Bettype = 805
									AND EXISTS(
											SELECT TOP 1 1
											FROM @Event805Tbl rs
											WHERE ISNULL(rs.Custom1,'') <> '' AND CHARINDEX('BettypeTime='+ rs.Custom1, b.transdesc,0) <> 0
										)
									THEN 1
								ELSE 0
								END
					ELSE 1
					END
	UNION ALL
	SELECT DISTINCT b.translogid transid, b.translogid refno, b.custid,  b.actual_stake, b.recommend, b.mrecommend, b.srecommend, b.betfrom, b.statusID, b.status, NULL SecAcceptFlag, 
		b.Username, b.creator, 0 hdp1, 0 hdp2, b.gameid, NULL betteam, NULL betcheck, b.odds, b.custom1 oddstype, b.transdate, b.liveindicator, NULL livehomescore, 
		NULL liveawayscore, b.stake, b.CurrencyName, NULL betid, b.transdesc, 2 --TicketType
	FROM 
		translog b WITH (NOLOCK)
		INNER JOIN custDB.dbo.Customer c WITH (NOLOCK) ON b.custid = c.custid
		INNER JOIN custDB.dbo.customer ag WITH (NOLOCK) ON b.recommend = ag.custid
		INNER JOIN custDB.dbo.customer cr WITH (NOLOCK) ON cr.custid = b.creator
		INNER JOIN dbo.strSplit(@BetTypes,'^') s ON s.val = b.gameID
		INNER JOIN dbo.match mat WITH(NOLOCK) ON mat.matchid = b.EventID
		LEFT JOIN bettrans bs WITH(NOLOCK) ON b.gameid = bs.bettype AND bs.matchid = b.eventid AND bs.custid = b.Custid AND b.translogid = bs.refno
	WHERE
		b.EventID=@MatchId 
		AND (b.translogid IN (SELECT transid FROM @tblTransCredit)
			OR b.translogid IN (SELECT transid FROM @tblTransDeposit )
			OR b.translogid IN (SELECT transid FROM @tblTransBetDaq )
			OR b.translogid IN (SELECT transid FROM @tblTrans12EU )
			OR b.translogid IN (SELECT transid FROM @tblTransMHC )
			OR b.translogid IN (SELECT transid FROM @tblTransFB )
			OR b.translogid IN (SELECT transid FROM @tblTransBetFair )
			OR b.translogid IN (SELECT transid FROM @tblTransOneExchange )
			)
		AND b.gameid IN (801,803,804,805,806) AND bs.refno IS NULL	
		AND b.statusID NOT IN (101,102 ) -- reject, void
		AND mat.eventdate >=@FromDate
		AND 1 = CASE WHEN b.GameID IN (801,803,804,805) THEN CASE 
								WHEN b.GameID = 801
									AND EXISTS(
											SELECT TOP 1 1
											FROM @Event801Tbl rs
											WHERE ISNULL(rs.Custom1,'') <> '' AND CHARINDEX('BettypeTime='+ rs.Custom1, b.transdesc,0) <> 0
										)
									THEN 1
								WHEN b.GameID = 803
									AND EXISTS(
											SELECT TOP 1 1
											FROM @Event803Tbl rs
											WHERE ISNULL(rs.Custom1,'') <> '' AND CHARINDEX('BettypeTime='+ rs.Custom1, b.transdesc,0) <> 0
										)
									THEN 1
								WHEN b.GameID = 804
									AND EXISTS(
											SELECT TOP 1 1
											FROM @Event804Tbl rs
											WHERE ISNULL(rs.Custom1,'') <> '' AND CHARINDEX('BettypeTime='+ rs.Custom1, b.transdesc,0) <> 0
										)
									THEN 1
								WHEN b.GameID = 805
									AND EXISTS(
											SELECT TOP 1 1
											FROM @Event805Tbl rs
											WHERE ISNULL(rs.Custom1,'') <> '' AND CHARINDEX('BettypeTime='+ rs.Custom1, b.transdesc,0) <> 0
										)
									THEN 1
								ELSE 0
								END
					ELSE 1
					END	 
	------------------***** End of insert all data into #BetDelete *****------------------

	------------------***** Insert Custid of each type into its temp table *****------------------	
	
	 -- get deposit tickets voided 
	 INSERT INTO @DepositCust(custid)
		SELECT c.custid
		FROM custDB.dbo.custInfo c WITH (NOLOCK)
		INNER JOIN #BetDelete b ON b.custid = c.custid
		WHERE c.srecommend IN (SELECT custid FROM custDB.dbo.Dep_CustSuper WITH(NOLOCK))
		AND c.roleid = 1
		
	 ---- get 12EU tickets voided 
	 INSERT INTO @12EUCust (custid)
		SELECT INF.custid 
		FROM custDB.dbo.customer INF WITH (nolock)
		INNER JOIN #BetDelete BD ON INF.custid = BD.custid 
		WHERE INF.UserName = '12EU'
		
	 ---- get UUS tickets 
	 INSERT INTO @UUSCust(custid)
		SELECT INF.custid 
		FROM custDB.dbo.custinfo INF WITH(nolock) 
		INNER JOIN #BetDelete BD ON INF.Custid = BD.custid 
		WHERE INF.srecommend IN( SELECT custid FROM custDB.dbo.customer WITH(nolock) WHERE CURRENCY = 20 AND roleid = 4 ) 
		AND INF.roleid = 1

	 ---- get any real tickets voided by IT
	 INSERT INTO @RealCurrCust (CustID)
		SELECT INF.custid 
		FROM custDB.dbo.custInfo INF WITH (NOLOCK) 
		INNER JOIN #BetDelete BD ON INF.Custid = BD.Custid 
		WHERE INF.srecommend IN( SELECT custid FROM custDB.dbo.customer WITH(NOLOCK) WHERE CURRENCY <> 20 AND roleid = 4)	
		AND INF.roleid = 1 
		AND @UserID IN (SELECT a.custid FROM DBPOLICY.bodb02.dbo.accCustomer_1 a WHERE a.GroupID = 1) -- Check UserID in IT group

	-- get Foobet tickets
	INSERT INTO @FoobetCust (custid)
		SELECT bd.custid
		FROM custDB.dbo.custInfo ci with(NOLOCK)
		INNER JOIN #BetDelete bd ON bd.custid = ci.custid
		where bd.recommend = 11196380
		and ci.roleid = 1 

	-- get Betfair tickets
	INSERT INTO @BetFairCust (custid)
		SELECT bd.custid
		FROM custDB.dbo.custInfo ci with(NOLOCK)
		INNER JOIN #BetDelete bd ON bd.custid = ci.custid
		where bd.custid IN (1077687, 2331, 115770, 15523642) -- Betfair: BFOS, BF, ITibc102, BF3
		and ci.roleid = 1 

	-- get OneExchange tickets
	INSERT INTO @OneExchangeCust (custid)
		SELECT bd.custid
		FROM custDB.dbo.custInfo ci with(NOLOCK)
		INNER JOIN #BetDelete bd ON bd.custid = ci.custid
		where bd.recommend = 13423967
		and ci.roleid = 1

	------------------***** Begin Special Delete *****------------------
	--*****MGSL PROCESS - START
		--Insert ticket of MGSL in translog: 801,803,804,805,806
		INSERT INTO [dbo].[bettrans]
			   ([custid]
			   ,[transdate]
			   ,[oddsid]
			   ,[hdp1]
			   ,[hdp2]
			   ,[odds]
			   ,[stake]
			   ,[status]
			   ,[winlost]
			   ,[awinlost]
			   ,[mwinlost]
			   ,[playercomm]
			   ,[comm]
			   ,[acomm]
			   ,[apositiontaking]
			   ,[mpositiontaking]
			   ,[tpositiontaking]
			   ,[playerdiscount]
			   ,[discount]
			   ,[adiscount]
			   ,[livehomescore]
			   ,[liveawayscore]
			   ,[liveindicator]
			   ,[betteam]
			   ,[creator]
			   ,[refno]
			   ,[comstatus]
			   ,[winlostdate]
			   ,[betfrom]
			   ,[betcheck]
			   ,[checktime]
			   ,[oddsspread]
			   ,[actualrate]
			   ,[matchid]
			   ,[recommend]
			   ,[mrecommend]
			   ,[ruben]
			   ,[betid]
			   ,[statuswinlost]
			   ,[modds]
			   ,[bettype]
			   ,[betdaqid]
			   ,[actual_stake]
			   ,[currency]
			   ,[ip]
			   ,[transdesc]
			   ,[sdiscount]
			   ,[scomm]
			   ,[spositiontaking]
			   ,[swinlost]
			   ,[srecommend]
			   ,[Username]
			   ,[CurrencyName]
			   ,[virtualrate]
			   ,[oddstype]
			   ,[statusID]
			   ,[currency2]
			   ,[balance]
			   ,[SecAcceptFlag]
			   ,[transid2]
			   ,[RecommDate])
		SELECT  b.[custid]
			   ,b.[transdate]
			   ,0 [oddsid]
			   ,0 [hdp1]
			   ,0 [hdp2]
			   ,b.[odds]
			   ,b.[stake]
			   ,b.[status]
			   ,0 [winlost]
			   ,0 [awinlost]
			   ,0 [mwinlost]
			   ,0 [playercomm]
			   ,0 [comm]
			   ,0 [acomm]
			   ,b.[apositiontaking]
			   ,b.[mpositiontaking]
			   ,b.[tpositiontaking]
			   ,b.[playerdiscount]
			   ,b.[discount]
			   ,b.[adiscount]
			   ,0 [livehomescore]
			   ,0 [liveawayscore]
			   ,b.[liveindicator]
			   ,SUBSTRING(b.[transdesc],11,CHARINDEX(';BettypeTime',b.[transdesc],0) - 11) [betteam]
			   ,b.[creator]
			   ,b.translogid [refno]
			   ,b.custom2 [comstatus]
			   ,b.[winlostdate]
			   ,b.[betfrom]
			   ,b.transdate [betcheck]
			   ,NULL [checktime]
			   ,0 [oddsspread]
			   ,b.[actualrate]
			   ,b.EventID
			   ,b.[recommend]
			   ,b.[mrecommend]
			   ,1 [ruben]
			   ,CASE WHEN ISNULL(b.custom3,'') = '' THEN NULL ELSE CAST(b.custom3 AS BIGINT) END [betid]
			   ,NULL [statuswinlost]
			   ,0 [modds]
			   ,b.GameID [bettype]
			   ,NULL [betdaqid]
			   ,b.[actual_stake]
			   ,b.[currency]
			   ,b.[ip]
			   ,b.[transdesc]
			   ,b.[sdiscount]
			   ,0 [scomm]
			   ,b.[spositiontaking]
			   ,0 [swinlost]
			   ,b.[srecommend]
			   ,b.[Username]
			   ,b.[CurrencyName]
			   ,b.[virtualrate]
			   ,b.custom1 [oddstype]
			   ,b.[statusID]
			   ,NULL [currency2]
			   ,b.[balance]
			   ,0 [SecAcceptFlag]
			   ,0 [transid2]
			   ,NULL [RecommDate]
		FROM dbo.translog b WITH(NOLOCK)
		WHERE b.translogid IN (SELECT TransID FROM #BetDelete WHERE TicketType=2)
		AND b.GameID IN (801,803,804,805,806)
		
		--Update resultID in translog for MGSL
		UPDATE tl
		SET
			tl.Status = 'Void',
			tl.StatusID = 102,
			tl.creator = @UserID
		FROM dbo.translog tl WITH(ROWLOCK,UPDLOCK)
		WHERE (tl.translogid IN (SELECT TransID FROM #BetDelete WHERE TicketType=2)
		OR tl.translogid IN (SELECT refno FROM #BetDelete WHERE TicketType=1))
		AND tl.GameID IN (801,803,804,805,806)
		
		--Update resultID in translog for MGSL
		UPDATE tl
		SET
			tl.custom3 = (	
							SELECT rs.ResultID 
							FROM DBPRO.bodb02.dbo.ResultDetail3rd rs WITH(NOLOCK) 
							WHERE (
									(ISNULL(rs.Custom1,'') <> '' AND CHARINDEX('BettypeTime='+ rs.Custom1, tl.transdesc,0) <> 0)
									OR
									tl.GameID = 806
								)
								AND rs.GameID = tl.GameID	
								AND rs.VendorID = 5		
								AND rs.MatchID = tl.EventID			
						)
		FROM dbo.translog tl WITH(ROWLOCK,UPDLOCK)
		WHERE (tl.translogid IN (SELECT TransID FROM #BetDelete WHERE TicketType=2)
		OR tl.translogid IN (SELECT refno FROM #BetDelete WHERE TicketType=1))
		AND tl.GameID IN (801,803,804,805,806) AND ISNULL(tl.Custom3,'') = ''
		
		--Update resultID in bettrans for MGSL
		UPDATE b
		SET b.betid = (	
							SELECT rs.ResultID 
							FROM DBPRO.bodb02.dbo.ResultDetail3rd rs WITH(NOLOCK) 
							WHERE (
									(ISNULL(rs.Custom1,'') <> '' AND CHARINDEX('BettypeTime='+ rs.Custom1, b.transdesc,0) <> 0)
									OR
									b.bettype = 806
								)
								AND rs.GameID = b.bettype	
								AND rs.VendorID = 5		
								AND rs.MatchID = b.matchid			
						)
		FROM dbo.bettrans b WITH(ROWLOCK,UPDLOCK)
		WHERE b.refno IN (SELECT TransID FROM #BetDelete WHERE TicketType=2)
		AND b.Bettype IN (801,803,804,805,806) AND b.BetID IS NULL
		
		--Update new transid
		UPDATE main
		SET main.TransID = b.TransID
		FROM #BetDelete main
			INNER JOIN dbo.bettrans b WITH(NOLOCK) ON main.refno = b.refno AND main.Bettype = b.Bettype
		WHERE main.TicketType=2 AND b.Bettype IN (801,803,804,805,806)
	
	--*****MGSL PROCESS - END	
	-- Step 1: backup
	INSERT INTO zzzbettrans (transid,custid,transdate,oddsid,hdp1,hdp2,odds,stake,status,
				winlost,livehomescore,liveawayscore,liveindicator,betteam,creator, refno, 
				winlostdate,betfrom,betcheck,checktime,matchid, bettype)
		SELECT  transid, custid, CURRENT_TIMESTAMP, oddsid, hdp1, hdp2, odds, stake, status, 
				winlost, livehomescore, liveawayscore, liveindicator, betteam, creator , refno, 
				winlostdate, betfrom, betcheck, checktime, matchid, bettype
		FROM
			bettrans b WITH (nolock)
		WHERE
			b.transid IN (SELECT transid FROM #BetDelete)
			AND b.bettype IN (SELECT CONVERT(INT,val) FROM dbo.strSplit(@bettypes,'^'))
			AND b.matchid = @MatchId
			--AND b.liveindicator = @LiveIndicator

	CREATE TABLE #BeforeUpd (
			custid		 INT,
			balance		 MONEY)
		
	CREATE TABLE #AfterUpd(
				custid		 INT,
				balance		 MONEY)

	DECLARE @tblDebitPending TVP_BalanceList
	DECLARE @tblCreditPending TVP_BalanceList
	
	INSERT INTO #BeforeUpd (custid, balance)
	SELECT	b.custid, SUM (b.winlost - b.actual_stake + b.playercomm) balance
	FROM	bettrans b WITH (NOLOCK)
	WHERE	b.transid IN (SELECT transid FROM #BetDelete)
	GROUP BY b.CustID
	
	-- STEP 2 : Update
	--  begin tran
	UPDATE 
		bettrans WITH (ROWLOCK, UPDLOCK)
	SET winlost			= actual_stake
		,ruben			= 1
		,statuswinlost	= 6
		,status			= 'Void'
		,creator		= @UserID
		,awinlost		= 0
		,mwinlost		= 0
		,swinlost		= 0
		,playercomm		= 0
		,comm			= 0
		,acomm			= 0
		,scomm			= 0
		,statusID		= 102       
	WHERE
		transid IN (SELECT transid FROM #BetDelete)

	---- update totalbets
	--DECLARE @Total TABLE (oddsid INT, HomeTotal MONEY, AwayTotal MONEY)
	--INSERT INTO @Total
	--	SELECT oddsid,
	--		SUM(CASE WHEN betteam='h' THEN (CASE WHEN ABS(odds) > 1 THEN ABS(odds) 
	--				 ELSE 1 END * b.stake * e.actualrate * (1-b.tpositiontaking)) ELSE 0 END) homeTotal,
	--		SUM(CASE WHEN betteam='a' THEN (CASE WHEN ABS(odds) > 1 THEN ABS(odds) 
	--				 ELSE 1 END * b.stake * e.actualrate * (1-b.tpositiontaking)) ELSE 0 END) awayTotal
	--	FROM bettrans b WITH (nolock)
	--		INNER JOIN custDB.dbo.exchange e WITH (nolock) ON b.currency = e.exchangeid
	--	WHERE bettype IN (1,3,7,8) AND ruben = 0 AND oddsid <> 0 AND matchid = @MatchId
	--	GROUP BY oddsid

	--UPDATE odds WITH (rowlock, updlock)
	--SET hometotal = t.HomeTotal, awaytotal = t.AwayTotal
	--FROM @Total t WHERE odds.oddsid = t.oddsid AND odds.matchid = @MatchId

	--Get data after update
	INSERT INTO #AfterUpd (custid, balance)
	SELECT	b.custid, SUM (b.winlost - b.actual_stake + b.playercomm) balance
	FROM	bettrans b WITH (NOLOCK)
	WHERE	b.transid IN (SELECT transid FROM #BetDelete)
	GROUP BY b.CustID

	---INSERT data into pending balance table 
	--INSERT INTO BalancePendingCredit (custid,Balance)
	--SELECT		a.custid, (a.balance - b.balance) as Balance
	--FROM		#BeforeUpd b
	--INNER JOIN	#AfterUpd a 	
	--		ON	a.custid = b.custid
	--WHERE	    (a.balance - b.balance) > 0
	
	INSERT INTO @tblCreditPending (custID, balance)
	SELECT		a.custid, (a.balance - b.balance) as Balance
	FROM		#BeforeUpd b
	INNER JOIN	#AfterUpd a 	
			ON	a.custid = b.custid
	WHERE	    (a.balance - b.balance) > 0	
	
	IF @@rowcount <> 0
		EXEC dbo.Dot_BalancePendingCreditIns 
			@BalancePending = @tblCreditPending
			,@Type			= 1 -- Sports

	--INSERT INTO BalancePendingDebit (custid,Balance)
	--SELECT		a.custid, ABS(a.balance - b.balance) as Balance
	--FROM		#BeforeUpd b
	--INNER JOIN	#AfterUpd a 	
	--		ON	a.custid = b.custid
	--WHERE	    (a.balance - b.balance) < 0
	
	INSERT INTO @tblDebitPending (custID, balance)
	SELECT		a.custid, ABS(a.balance - b.balance) as Balance
	FROM		#BeforeUpd b
	INNER JOIN	#AfterUpd a 	
			ON	a.custid = b.custid
	WHERE	    (a.balance - b.balance) < 0
	
	IF @@rowcount <> 0
		EXEC dbo.Dot_BalancePendingDebitIns 
			@BalancePending = @tblDebitPending
			,@Type			= 1 -- Sports
			
------------------***** End of Special Delete *****------------------

	SELECT @LogData ='void bet for matchid ' + CONVERT(VARCHAR(20), @MatchId) 
			+ ' Event801= ' + @Event801 
			+ ' Event803= ' + @Event803
			+ ' Event804= ' + @Event804
			+ ' Event805= ' + @Event805
			+ ' IP=' + COALESCE(CAST(@IP AS VARCHAR(15)),SPACE(1)) 
			+ ' reason: ' + @Reason
			
	EXEC WriteLog_UserLog 
		@UserID = @UserID
		,@Doing = @LogData

	-- Match info
	SELECT MATCH.homeid,
		MATCH.awayid,
		MATCH.matchcode,
		MATCH.eventdate,
		MATCH.leagueid,
		GETDATE() AS DATETIME,
		ISNULL(MATCH.isNeutral, CONVERT(BIT,0)) AS IsNeutral,
		0 AS IsOutright
	FROM
		MATCH WITH (NOLOCK)
	WHERE 
		MATCH.matchid = @MatchId


	-- All ticket voided
	SELECT CASE WHEN bd.bettype IN (801,803,804,805,806) THEN bd.refno ELSE transid END transid, 
			bd.custid, 
			mem.username AS CustUserName,
			mem.username2 as CustUserName2,
			bd.recommend, 
			ag.UserName AS AgUserName,
			bd.mrecommend, 
			mag.UserName AS MagUserName, 
			bd.srecommend, 
			sag.Username AS SagUserName,
	bd.status, bd.SecAcceptFlag
	FROM #BetDelete bd (nolock)
	INNER JOIN custDB.dbo.Customer mem (nolock) ON bd.custid     = mem.custid
	INNER JOIN custDB.dbo.custinfo ag  (nolock) ON bd.recommend  = ag.custid
	INNER JOIN custDB.dbo.custinfo mag (nolock) ON bd.mrecommend = mag.custid
	INNER JOIN custDB.dbo.custinfo sag (nolock) ON bd.srecommend = sag.custid
	
	-- Send mail when void deposit
	SELECT c.custid, b.actual_stake winlost, c.username, c.username2, b.odds, b.OddsType, b.transdate, b.bettype, b.betfrom,
		b.transid, b.refno, betteam, betcheck, hdp1, hdp2, betfrom, b.isLiveIndicator, livehomescore, liveawayscore, cr.username creator,
		stake, b.CurrencyName, ag.site, b.status, b.SecAcceptFlag, b.betid, b.transdesc
	FROM
		#BetDelete b WITH (NOLOCK)
		INNER JOIN custDB.dbo.customer c  WITH (NOLOCK) ON c.custid=b.custid
		INNER JOIN custDB.dbo.customer cr WITH (NOLOCK) ON cr.custid = b.creator
		INNER JOIN custDB.dbo.customer ag WITH (NOLOCK) ON c.recommend = ag.custid
	WHERE c.custid IN (SELECT custid FROM @DepositCust) -- Email deposit if voided		
	ORDER BY transid

	-- Send mail when void 12EU tickets 
		SELECT c.custid, b.actual_stake winlost, c.username, c.username2, b.odds, b.OddsType, b.transdate, b.bettype, b.betfrom,
		b.transid, b.refno, betteam, betcheck, hdp1, hdp2, betfrom, b.isLiveIndicator,livehomescore, liveawayscore, cr.username creator,
		stake, b.CurrencyName, '12EU' as site, b.status, b.SecAcceptFlag, b.betid, b.transdesc
	FROM
		#BetDelete b WITH (NOLOCK)
		INNER JOIN custDB.dbo.customer c WITH (NOLOCK) ON c.custid=b.custid
		INNER JOIN custDB.dbo.customer cr WITH (NOLOCK) ON cr.custid = b.creator
		INNER JOIN custDB.dbo.customer ag WITH (NOLOCK) ON c.recommend = ag.custid
	WHERE b.custid IN (SELECT [@12EUCust].custid FROM @12EUCust) -- Email 12EU if voided			
	ORDER BY transid

	
	-----Send mail when void any real tickets by IT
	SELECT c.custid, b.actual_stake winlost, c.username,c.username2, b.odds, b.OddsType, b.transdate, b.bettype, b.betfrom,
		b.transid, b.refno, betteam, betcheck, hdp1, hdp2, betfrom, b.isLiveIndicator,livehomescore, liveawayscore,
		cr.username creator, stake, b.CurrencyName, ag.site,
		b.status, b.SecAcceptFlag, b.betid,b.transdesc
	FROM #BetDelete b WITH (NOLOCK)
		INNER JOIN custDB.dbo.customer c WITH (NOLOCK) ON c.custid=b.custid
		INNER JOIN custDB.dbo.customer cr WITH (NOLOCK) ON cr.custid = b.creator
		INNER JOIN custDB.dbo.customer ag WITH (NOLOCK) ON c.recommend = ag.custid
	WHERE c.custid IN (SELECT custid FROM @RealCurrCust)			     					   
	ORDER BY transid    	   

	-- Send mail when void UUS tickets
		SELECT c.custid, b.actual_stake winlost, c.username,c.username2, b.odds, b.OddsType, b.transdate, b.bettype, b.betfrom,
		b.transid, b.refno, betteam, betcheck, hdp1, hdp2, betfrom, b.isLiveIndicator,livehomescore, liveawayscore,
		cr.username creator, stake, b.CurrencyName, ag.site,
		b.status, b.SecAcceptFlag, b.betid,b.transdesc
	FROM #BetDelete b WITH (NOLOCK)
		INNER JOIN custDB.dbo.customer c WITH (NOLOCK) ON c.custid=b.custid
		INNER JOIN custDB.dbo.customer cr WITH (NOLOCK) ON cr.custid = b.creator
		INNER JOIN custDB.dbo.customer ag WITH (NOLOCK) ON c.recommend = ag.custid
	WHERE c.custid IN (SELECT custid FROM @UUSCust)				     					   
	ORDER BY transid    

	-----Send mail when void Foobet tickets
	SELECT c.custid, b.actual_stake winlost, c.username, c.username2, b.odds, b.OddsType, b.transdate, b.bettype, b.betfrom,
		b.transid, b.refno, betteam, betcheck, hdp1, hdp2, betfrom, b.isLiveIndicator,livehomescore, liveawayscore,
		cr.username creator, stake, b.CurrencyName, 'Foobet' as site,
		b.status, b.SecAcceptFlag, b.betid,b.transdesc
	FROM #BetDelete b WITH (NOLOCK)
		INNER JOIN custDB.dbo.customer c WITH (NOLOCK) ON c.custid=b.custid
		INNER JOIN custDB.dbo.customer cr WITH (NOLOCK) ON cr.custid = b.creator
		INNER JOIN custDB.dbo.customer ag WITH (NOLOCK) ON c.recommend = ag.custid
	WHERE c.custid IN (SELECT custid FROM @FoobetCust)			     					   
	ORDER BY transid  
	
	-----Send mail when void Betfair tickets
	SELECT c.custid, b.actual_stake winlost, c.username, c.username2, b.odds, b.OddsType, b.transdate, b.bettype, b.betfrom,
		b.transid, b.refno, betteam, betcheck, hdp1, hdp2, betfrom, b.isLiveIndicator,livehomescore, liveawayscore,
		cr.username creator, stake, b.CurrencyName, 'BetFair' as site,
		b.status, b.SecAcceptFlag, b.betid,b.transdesc
	FROM #BetDelete b WITH (NOLOCK)
		INNER JOIN custDB.dbo.customer c WITH (NOLOCK) ON c.custid=b.custid
		INNER JOIN custDB.dbo.customer cr WITH (NOLOCK) ON cr.custid = b.creator
		INNER JOIN custDB.dbo.customer ag WITH (NOLOCK) ON c.recommend = ag.custid
	WHERE c.custid IN (SELECT custid FROM @BetFairCust)			     					   
	ORDER BY transid    

	-----Send mail when void OneExchange tickets
	SELECT c.custid, b.actual_stake winlost, c.username, c.username2, b.odds, b.OddsType, b.transdate, b.bettype, b.betfrom,
		b.transid, b.refno, betteam, betcheck, hdp1, hdp2, betfrom, b.isLiveIndicator,livehomescore, liveawayscore,
		cr.username creator, stake, b.CurrencyName, 'OneExchange' as site,
		b.status, b.SecAcceptFlag, b.betid,b.transdesc
	FROM #BetDelete b WITH (NOLOCK)
		INNER JOIN custDB.dbo.customer c WITH (NOLOCK) ON c.custid=b.custid
		INNER JOIN custDB.dbo.customer cr WITH (NOLOCK) ON cr.custid = b.creator
		INNER JOIN custDB.dbo.customer ag WITH (NOLOCK) ON c.recommend = ag.custid
	WHERE c.custid IN (SELECT custid FROM @OneExchangeCust)			     					   
	ORDER BY transid    
	
	-- Metric API Calling
	SELECT c.custid, b.actual_stake winlost, c.username, c.username2, b.odds, b.OddsType, b.transdate, b.bettype, b.betfrom,
		b.transid, b.refno, betteam, betcheck, hdp1, hdp2, betfrom, b.isLiveIndicator, livehomescore, liveawayscore, cr.username creator,
		stake, b.CurrencyName, ag.site, b.status, b.SecAcceptFlag, b.betid, b.transdesc
	FROM
		#BetDelete b WITH (NOLOCK)
		INNER JOIN custDB.dbo.customer c  WITH (NOLOCK) ON c.custid=b.custid
		INNER JOIN custDB.dbo.customer cr WITH (NOLOCK) ON cr.custid = b.creator
		INNER JOIN custDB.dbo.customer ag WITH (NOLOCK) ON c.recommend = ag.custid
	WHERE b.bettype BETWEEN 801 AND 806	
	ORDER BY transid
	
	DROP TABLE #BeforeUpd
	DROP TABLE #AfterUpd

	DELETE FROM dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK)
	WHERE KeyID = @KeyID AND KeyValue = @MatchId	
	
	IF (@@Error = 0)
		BEGIN TRY
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID		= @UserID, 
				@MatchId	= @MatchId, 
				@KeyID		= @KeyID,
				@ActionID	= 0, 
				@Remark		= 'DEL SUCCESS SPName=NAP_VoidMetricGaming_Del'
		END TRY
		BEGIN CATCH
			SELECT @Remark	= 'DEL SUCCESS SPName=NAP_VoidMetricGaming_Del ErrMsg=' + LEFT(error_message(), 400)
			
			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID		= @UserID, 
				@MatchId	= @MatchId, 
				@KeyID		= @KeyID,
				@ActionID	= 0, 
				@Remark		= @Remark
		END CATCH
		ELSE
		BEGIN
			BEGIN TRY
				EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
					@UserID		= @UserID, 
					@MatchId	= @MatchId, 
					@KeyID		= @KeyID,
					@ActionID	= 0, 
					@Remark		= 'DEL FAILED SPName=NAP_VoidMetricGaming_Del'
			END TRY
			BEGIN CATCH
				SELECT @Remark = 'DEL FAILED SPName=NAP_VoidMetricGaming_Del ErrMsg=' + LEFT(error_message(), 400)
				
				EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
					@UserID		= @UserID, 
					@MatchId	= @MatchId, 
					@KeyID		= @KeyID,
					@ActionID	= 0, 
					@Remark		= @Remark
			END CATCH
		END	


	DROP TABLE #BetDelete

	SET NOCOUNT OFF
END

GO
GRANT EXECUTE ON [dbo].[NAP_VoidMetricGaming_Del] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_VoidMetricGaming_Del] TO [vnteam] AS [dbo]