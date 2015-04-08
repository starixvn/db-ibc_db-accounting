ALTER PROCEDURE [dbo].[NAP_BettransDelSpecial]
	@MatchId				INT,
	
	@FromTransId			BIGINT, 
	@ToTransId				BIGINT, 
		
	@Handicap 				SMALLMONEY		= 9999,		-- 1, 3, 7, 8, 17, 153, 183, 1303, 1306, 1308
	@Handicap155			SMALLMONEY		= 9999,		-- 155, 1316 
	@Handicap178			SMALLMONEY		= 9999,		-- 178,197,198,204,205
	@OverUnder156			SMALLMONEY		= 9999,		-- 156, 1312 
	
	@LiveIndicator 			SMALLINT 		= 0,
    @LiveHomeScore 			SMALLINT 		= NULL,
    @LiveAwayScore 			SMALLINT 		= NULL,
    
    @FromTransdate			DATETIME 		= NULL,
	@ToTransdate			DATETIME 		= NULL,
	
    @BetTypes				VARCHAR(1000)	= '',
	
	@BetTeam1378			NVARCHAR(10)	= 'ALL',	-- 1, 2, 3, 7, 8, 12, 17, 20, 153,157,168,183,185,191, 1301, 1303, 1305, 1306, 1308 
	@BetTeam515				NVARCHAR(10)	= 'ALL',	-- 5,15,160,164,167,176,177,180
	@BetTeam430				VARCHAR(120) 	= '',
    @BetTeam6				VARCHAR(120) 	= '',		-- 6, 126, 131, 132
	@BetTeam14				VARCHAR(120) 	= '',
	@BetTeam16				VARCHAR(120) 	= '',
	@BetTeam128 			VARCHAR(120) 	= '',
	@BetTeam129 			VARCHAR(120) 	= '',		-- 129, 130
	@BetTeam136 			VARCHAR(10)		= 'ALL',	-- 136, 137, 138, 139, 184,194,203
	@BetTeam143 			VARCHAR(120)	= '',		-- 143, 144, 163
	@BetTeam154				VARCHAR(3)		= 'ALL', 	-- 154, 155, 1311, 1316 
	@BetTeam156				VARCHAR(3)		= 'ALL', 	-- 156, 1312 
	@BetTeam1302			VARCHAR(120)	= 'ALL', 	-- 1302 
	@BetTeam1317			VARCHAR(120)	= 'ALL', 	-- 1317 
	@BetTeam1318			VARCHAR(3)		= 'ALL', 	-- 1318 	
	@BetTeam1324			VARCHAR(3)		= 'ALL', 	-- 1324
	@BetTeam178				VARCHAR(10)		= 'ALL',	-- 178,197,198,204,205
	@BetTeam165				VARCHAR(120)	= 'ALL',	-- 165,166
	@BetTeam159				VARCHAR(120)	= 'ALL',	-- 159,179
	@BetTeam161				VARCHAR(120)	= 'ALL',	-- 161,162,181,182
	@BetTeam199				VARCHAR(120)	= 'ALL',	-- 199
	@BetTeam202				VARCHAR(120)	= 'ALL',	-- 202
	@BetTeam195				VARCHAR(120)	= 'ALL',	-- 195,196
	@BetTeam200				VARCHAR(120)	= 'ALL',	-- 200,201
	@BetTeam169				VARCHAR(120)	= 'ALL',	-- 169,193
	@BetTeam210				VARCHAR(10)		= 'ALL',	-- 210,173,174,188,189,190,211,212,123,214,215,133,134,135,145,146,147,148,149,150
	@BetTeam216				VARCHAR(120)	= 'ALL',	-- 216,217
	
	@Set154					VARCHAR(3)		= 'ALL', 	-- 154, 155, 1311, 1316 
	@Set156					VARCHAR(3)		= 'ALL', 	-- 156, 1312 
	@Set1317				VARCHAR(3)		= 'ALL', 	-- 1317
	@Set1318				VARCHAR(3)		= 'ALL', 	-- 1318 
	@Set1324				VARCHAR(3)		= 'ALL', 	-- 1324 
	
	@Game1324				VARCHAR(3)		= 'ALL', 	-- 1324 
	
	@BetID160				TINYINT			= 100,		--160,164,180
	
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
	Created by: Kathy
	Task : Special Delete
	DB: DBTXN/bodb02
	Original:

	Revisions:
		- 20140102@Kathy: Add username2 column [Redmine:#10270]
		- 20140121@Elodie: Apply LAS system for special delete function [Redmine:#10701]
		- 20140411@Kathy: - Separate tickets of Bet Fair, OneExchange 3rd parties [Redmine:#10128]
						  - Add 2 new bettypes 1H Total Goal and 1H First Goal/ Last Goal (126, 127) [Redmine:#14749]
		- 20140701@Kathy: Apply BetRadar - change @BetTypes to varchar(1000) [Redmine:#18219]
		- 20140729@Kathy: Add one more account(BF3) into BetFair's group [Redmine:#19665]		
		- 20140806@Kathy: Support new 11 bettypes [Redmine:#19955]
		- 20140929@Kathy: - Offer new bettypes from Sportting Solutions and new IBC bettypes [Redmine:#23129]
						  - Add moneyline in filter
		- 20141125@Kathy: Add betid column [Redmine:##26489]
		- 20141204@Kathy: Remove codes which are used in checking permission on DBPolicy [Redmine:#27058]	
		- 20150402@Dominic: Add new 60 bettypes [Redmine:#27214]				  
	Param's Explanation: Special bet delete option
		- @SecondAcceptFlag: 
		  + 0: All tickets
		  + 1: Normal tickets only
		  + 2: SA tickets only
     
		-@LiveIndicator:
		 + 0: Dead
		 + 1: Live
		 + 2: All

	*/
BEGIN
	SET NOCOUNT ON;
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
			@MatchId) + ' from ' + CONVERT(VARCHAR(20), @FromTransId) + ' to ' + CONVERT(VARCHAR(20), @ToTransId) + ' reason: ' + @Reason
			
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

	IF EXISTS(SELECT CONVERT(INT,val) FROM dbo.strSplit(@bettypes,'^') WHERE CONVERT(INT, val) = 10) -- bettype 10: outright
	BEGIN 	
		SET @KeyID = 2
	END
	ELSE
	BEGIN 	
		SET @KeyID = 1
	END
	
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
			@Remark		= 'ADD SUCCESS SPName=NAP_BettransDelSpecial'
	END TRY
	BEGIN CATCH
		SELECT @Remark = 'ADD SUCCESS SPName=NAP_BettransDelSpecial ErrMsg=' + LEFT(error_message(), 400)
		
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
			@UserID		= @UserID, 
			@MatchId	= @MatchId, 
			@KeyID		= @KeyID,
			@ActionID	= 0, 
			@Remark		= @Remark
	END CATCH
	ELSE 
	BEGIN
		SELECT @ErrCode = 100, 
			@ErrMsg		= 'This match is being calculated or some tickets of this match are being voided, please wait a few seconds until the on-going process is completed and try again.'
			
		RETURN
	END
	-------------------		
	CREATE TABLE #BetDelete (
		transid				BIGINT PRIMARY KEY, 
		custid				INT, 
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
		odds				SMALLMONEY, 
		OddsType			INT,
		transdate			DATETIME,
		IsLiveIndicator		BIT,
		livehomescore 		SMALLINT, 
		liveawayscore 		SMALLINT,
		Stake				MONEY,
		CurrencyName		VARCHAR(10),
		betid				BIGINT
		)

	DECLARE @12EUCust			TABLE (custid INT)
	DECLARE @DepositCust		TABLE (custid INT)	
	DECLARE @UUSCust			TABLE (custid INT)
	DECLARE @RealCurrCust		TABLE (custid INT)
	DECLARE @FoobetCust			TABLE (custid INT)
	DECLARE @BetFairCust		TABLE (custid INT)
	DECLARE @OneExchangeCust	TABLE (custid INT)

	DECLARE @Status				TABLE (statusID TINYINT)
	
	INSERT INTO @Status
	SELECT 102 UNION ALL -- Void
	SELECT 101 UNION ALL -- Reject
	SELECT 112 UNION ALL -- Won
	SELECT 113 UNION ALL -- Lose
	SELECT 111 -- Draw


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
					@Remark		= 'VOID FAILED SPName=NAP_BettransDelSpecial'
		END TRY
		BEGIN CATCH
			SELECT @Remark = 'VOID FAILED SPName=NAP_BettransDelSpecial ErrMsg=' + LEFT(error_message(), 400)
			
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

 -- bettype <> 4 - Handicap(1), Over/Under(3), 1st Handicap(7), 1st Over/Under(8) - FT.1X2(5)/ 1st 1X2(15)
 INSERT INTO #BetDelete
	SELECT DISTINCT transid, custid, recommend, mrecommend, srecommend, betfrom, statusID, status, SecAcceptFlag, 
		b.Username, b.creator, b.hdp1, b.hdp2, b.bettype, b.betteam, b.odds, b.oddstype, b.transdate, b.liveindicator, b.livehomescore, 
		b.liveawayscore, b.stake, b.CurrencyName, b.betid
	FROM dbo.bettrans b WITH (NOLOCK)
		INNER JOIN dbo.strSplit(@bettypes,'^') AS bt ON bt.val=b.bettype
	WHERE b.matchid=@matchid 
		AND b.transid between @FromTransId AND @ToTransId
		AND (b.transid IN (SELECT transid FROM @tblTransCredit)
			OR b.transid IN (SELECT transid FROM @tblTransDeposit )
			OR b.transid IN (SELECT transid FROM @tblTransBetDaq )
			OR b.transid IN (SELECT transid FROM @tblTrans12EU )
			OR b.transid IN (SELECT transid FROM @tblTransMHC )
			OR b.transid IN (SELECT transid FROM @tblTransFB )
			OR b.transid IN (SELECT transid FROM @tblTransBetFair )
			OR b.transid IN (SELECT transid FROM @tblTransOneExchange )
			)
		AND CASE WHEN @LiveIndicator = 2 THEN @LiveIndicator ELSE b.liveindicator END = @LiveIndicator
		AND b.livehomescore = CASE WHEN @LiveHomeScore IS NOT NULL AND @LiveIndicator = 1 THEN @LiveHomeScore ELSE b.livehomescore END 
		AND b.liveawayscore = CASE WHEN @LiveAwayScore IS NOT NULL AND @LiveIndicator = 1 THEN @LiveAwayScore ELSE b.liveawayscore END 
		AND b.transdate between CASE WHEN @FromTransdate IS NOT NULL AND @LiveIndicator = 1 THEN @FromTransdate ELSE b.transdate END
							AND CASE WHEN @ToTransdate IS NOT NULL AND @LiveIndicator = 1 THEN @ToTransdate ELSE b.transdate END 
		AND b.betteam = CASE WHEN b.bettype IN (1,2, 3,7,8,12, 17, 20, 153, 157, 168, 183, 185, 191, 1301, 1303, 1305, 1306, 1308) THEN CASE WHEN @BetTeam1378 = 'ALL' THEN b.betteam ELSE @BetTeam1378 END
							WHEN b.bettype IN (5,15,160,164,167,176,177,180) THEN CASE WHEN @BetTeam515 = 'ALL' THEN b.betteam ELSE @BetTeam515 END
							ELSE b.betteam END 
		AND CASE WHEN b.bettype IN (160,164,180) 
						THEN CASE WHEN @BetID160=100 THEN b.betID 
						ELSE 
							CASE WHEN b.bettype = 160 THEN (816000 + @BetID160) 
								 WHEN b.bettype = 164 THEN (816400 + @BetID160)
								 WHEN b.bettype = 180 THEN (818000 + @BetID160)
							END
						END
				ELSE b.betID
			END = b.betID
		AND b.bettype NOT IN(4,6,14,16,30, 126, 127, 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 
								143, 144, 145, 146, 147, 148, 149, 150,
								154, 155, 156, 159, 161, 162, 163, 165, 166, 169, 
								173, 174, 178, 179, 181, 182, 184, 188, 189, 
								190, 193, 194, 195, 196, 197, 198, 199,
								200, 201, 202, 203, 204, 205, 210, 211, 212, 213, 214, 215, 216, 217,
								1302, 1311, 1312, 1316, 1317, 1318, 1324)
		AND CASE WHEN b.bettype IN (1,3,7,8, 17, 153, 183, 1303, 1306, 1308) THEN CASE WHEN @Handicap = 9999 THEN 1
														WHEN @Handicap = (hdp1 + hdp2) THEN 1
													ELSE 0 END 
			ELSE 1 END = 1
		AND ISNULL(b.SecAcceptFlag, 0)  = CASE @SecondAcceptFlag WHEN 0 THEN ISNULL(b.SecAcceptFlag, 0)  
														 WHEN 1 THEN 0 
														 WHEN 2 THEN 1 END
					 
 -- bettype = 4 -- Correct score
 INSERT INTO #BetDelete
	SELECT DISTINCT transid, custid, recommend, mrecommend, srecommend, betfrom, statusID, status, SecAcceptFlag, 
		Username, creator, hdp1,hdp2, bettype, betteam, b.odds, b.oddstype, b.transdate, b.liveindicator, b.livehomescore, 
		b.liveawayscore, b.stake, b.CurrencyName, b.betid
	FROM dbo.bettrans b WITH (NOLOCK)
		INNER JOIN dbo.strSplit(@BetTypes,'^') s ON s.val = b.bettype
		LEFT JOIN dbo.strSplit(@betteam430,'^') AS bt ON bt.val=b.betteam
	WHERE b.matchid=@matchid
		AND b.transid between @FromTransId AND @ToTransId
		AND (b.transid IN (SELECT transid FROM @tblTransCredit)
			OR b.transid IN (SELECT transid FROM @tblTransDeposit )
			OR b.transid IN (SELECT transid FROM @tblTransBetDaq )
			OR b.transid IN (SELECT transid FROM @tblTrans12EU )
			OR b.transid IN (SELECT transid FROM @tblTransMHC )
			OR b.transid IN (SELECT transid FROM @tblTransFB  )
			OR b.transid IN (SELECT transid FROM @tblTransBetFair )
			OR b.transid IN (SELECT transid FROM @tblTransOneExchange )
			)
		AND CASE WHEN @LiveIndicator = 2 THEN @LiveIndicator ELSE b.liveindicator END = @LiveIndicator
		AND b.livehomescore = CASE WHEN @LiveHomeScore IS NOT NULL AND @LiveIndicator = 1 THEN @LiveHomeScore ELSE b.livehomescore END
		AND b.liveawayscore = CASE WHEN @LiveAwayScore IS NOT NULL AND @LiveIndicator = 1 THEN @LiveAwayScore ELSE b.liveawayscore END
		AND b.transdate BETWEEN CASE WHEN @FromTransdate IS NOT NULL AND @LiveIndicator = 1 THEN @FromTransdate ELSE b.transdate END 
						AND		CASE WHEN @ToTransdate IS NOT NULL AND @LiveIndicator = 1 THEN @ToTransdate ELSE b.transdate END 
		AND b.bettype in (4,30)
		AND (@betteam430='All' OR bt.val IS NOT NULL)
		AND ISNULL(SecAcceptFlag,0) = CASE @SecondAcceptFlag WHEN 0 THEN ISNULL(SecAcceptFlag,0) 
													 WHEN 1 THEN 0 
													 WHEN 2 THEN 1 END


-- bettype = 6: Total Goal; 126: 1st Total Goal, 131: Home Team Total Goal; 132:  Away Team Total Goal
 INSERT INTO #BetDelete 
	SELECT DISTINCT transid, custid, recommend, mrecommend, srecommend, betfrom, statusID, status, SecAcceptFlag,
		Username, creator, hdp1,hdp2, bettype, betteam, b.odds, b.oddstype, b.transdate, b.liveindicator, b.livehomescore, 
		b.liveawayscore, b.stake, b.CurrencyName, b.betid
	FROM dbo.bettrans AS b WITH (NOLOCK)
		INNER JOIN dbo.strSplit(@BetTypes,'^') s ON s.val = b.bettype
		LEFT JOIN dbo.strSplit(@betteam6,'^') AS bt ON bt.val=b.betteam
	WHERE b.matchid=@matchid
		AND b.transid between @FromTransId AND @ToTransId	
		AND (b.transid IN (SELECT transid FROM @tblTransCredit)
			OR b.transid IN (SELECT transid FROM @tblTransDeposit )
			OR b.transid IN (SELECT transid FROM @tblTransBetDaq )
			OR b.transid IN (SELECT transid FROM @tblTrans12EU )
			OR b.transid IN (SELECT transid FROM @tblTransMHC)
			OR b.transid IN (SELECT transid FROM @tblTransFB )
			OR b.transid IN (SELECT transid FROM @tblTransBetFair )
			OR b.transid IN (SELECT transid FROM @tblTransOneExchange )
			)
		AND CASE WHEN @LiveIndicator = 2 THEN @LiveIndicator ELSE b.liveindicator END = @LiveIndicator
		AND b.livehomescore = CASE WHEN @LiveHomeScore IS NOT NULL AND @LiveIndicator = 1 THEN @LiveHomeScore ELSE b.livehomescore END
		AND b.liveawayscore = CASE WHEN @LiveAwayScore IS NOT NULL AND @LiveIndicator = 1 THEN @LiveAwayScore ELSE b.liveawayscore END	
		AND b.transdate BETWEEN CASE WHEN @FromTransdate IS NOT NULL AND @LiveIndicator = 1 THEN @FromTransdate ELSE b.transdate END 
						AND		CASE WHEN @ToTransdate IS NOT NULL AND @LiveIndicator = 1 THEN @ToTransdate ELSE b.transdate END 	
		AND b.bettype IN (6, 126, 131, 132)
		AND (@betteam6='All' OR bt.val IS NOT NULL)
		AND ISNULL(SecAcceptFlag,0) = CASE @SecondAcceptFlag WHEN 0 THEN ISNULL(SecAcceptFlag,0) 
													 WHEN 1 THEN 0 
													 WHEN 2 THEN 1 END

-- bettype = 14: First Goal/Last Goal; 127: 1st FGLG
 INSERT INTO #BetDelete  
	SELECT DISTINCT transid, custid, recommend, mrecommend, srecommend, betfrom, statusID, status, SecAcceptFlag,
		Username, creator, hdp1,hdp2, bettype, betteam, b.odds, b.oddstype, b.transdate,b.liveindicator, b.livehomescore, 
		b.liveawayscore, b.stake, b.CurrencyName, b.betid
	FROM bettrans b WITH (NOLOCK)
		INNER JOIN dbo.strSplit(@BetTypes,'^') s ON s.val = b.bettype
		LEFT JOIN dbo.strSplit(@betteam14,'^') AS bt ON b.betteam=CONVERT(VARCHAR(3),bt.val)
	WHERE b.matchid=@matchid AND           
		b.transid between @FromTransId AND @ToTransId
		AND (b.transid IN (SELECT transid FROM @tblTransCredit)
			OR b.transid IN (SELECT transid FROM @tblTransDeposit )
			OR b.transid IN (SELECT transid FROM @tblTransBetDaq )
			OR b.transid IN (SELECT transid FROM @tblTrans12EU )
			OR b.transid IN (SELECT transid FROM @tblTransMHC )
			OR b.transid IN (SELECT transid FROM @tblTransFB )
			OR b.transid IN (SELECT transid FROM @tblTransBetFair )
			OR b.transid IN (SELECT transid FROM @tblTransOneExchange )
			)
		AND CASE WHEN @LiveIndicator = 2 THEN @LiveIndicator ELSE b.liveindicator END = @LiveIndicator
		AND b.livehomescore = CASE WHEN @LiveHomeScore IS NOT NULL AND @LiveIndicator = 1 THEN @LiveHomeScore ELSE b.livehomescore END
		AND b.liveawayscore = CASE WHEN @LiveAwayScore IS NOT NULL AND @LiveIndicator = 1 THEN @LiveAwayScore ELSE b.liveawayscore END
		AND b.transdate BETWEEN CASE WHEN @FromTransdate IS NOT NULL AND @LiveIndicator = 1 THEN @FromTransdate ELSE b.transdate END 
						AND		CASE WHEN @ToTransdate IS NOT NULL AND @LiveIndicator = 1 THEN @ToTransdate ELSE b.transdate END 
		AND b.bettype IN (14, 127)
		AND (@betteam14='All' OR bt.val IS NOT NULL)
		AND ISNULL(SecAcceptFlag,0) = CASE @SecondAcceptFlag WHEN 0 THEN ISNULL(SecAcceptFlag,0) WHEN 1 THEN 0 WHEN 2 THEN 1 END

-- bettype = 16: HT/FT
	INSERT INTO #BetDelete 
	SELECT DISTINCT transid, custid, recommend, mrecommend, srecommend, betfrom, statusID, status, SecAcceptFlag,
		Username, creator, hdp1,hdp2, bettype, betteam, b.odds, b.oddstype, b.transdate, b.liveindicator,b.livehomescore, 
		b.liveawayscore, b.stake, b.CurrencyName, b.betid
	FROM dbo.bettrans AS b WITH (NOLOCK)
		INNER JOIN dbo.strSplit(@BetTypes,'^') s ON s.val = b.bettype
		LEFT JOIN dbo.strSplit(@betteam16,'^') AS bt ON bt.val=b.betteam
	WHERE b.matchid=@matchid AND           
		b.transid between @FromTransId AND @ToTransId		
		AND (b.transid IN (SELECT transid FROM @tblTransCredit)
			OR b.transid IN (SELECT transid FROM @tblTransDeposit )
			OR b.transid IN (SELECT transid FROM @tblTransBetDaq )
			OR b.transid IN (SELECT transid FROM @tblTrans12EU )
			OR b.transid IN (SELECT transid FROM @tblTransMHC )
			OR b.transid IN (SELECT transid FROM @tblTransFB )
			OR b.transid IN (SELECT transid FROM @tblTransBetFair )
			OR b.transid IN (SELECT transid FROM @tblTransOneExchange )
			)
		AND CASE WHEN @LiveIndicator = 2 THEN @LiveIndicator ELSE b.liveindicator END = @LiveIndicator	
		AND b.livehomescore = CASE WHEN @LiveHomeScore IS NOT NULL AND @LiveIndicator = 1 THEN @LiveHomeScore ELSE b.livehomescore END
		AND b.liveawayscore = CASE WHEN @LiveAwayScore IS NOT NULL AND @LiveIndicator = 1 THEN @LiveAwayScore ELSE b.liveawayscore END	
		AND b.transdate BETWEEN CASE WHEN @FromTransdate IS NOT NULL AND @LiveIndicator = 1 THEN @FromTransdate ELSE b.transdate END 
						AND		CASE WHEN @ToTransdate IS NOT NULL AND @LiveIndicator = 1 THEN @ToTransdate ELSE b.transdate END 
		AND b.bettype = 16
		AND (@betteam16='All' OR bt.val IS NOT NULL)
		AND ISNULL(SecAcceptFlag,0) = CASE @SecondAcceptFlag WHEN 0 then ISNULL(SecAcceptFlag,0) 
													WHEN 1 THEN 0 
													WHEN 2 THEN 1 END					
					
										 									
	-- bettype = 128, 129, 130, 136, 137, 138, 139, 143, 144, 163, 184,194,203
	INSERT INTO #BetDelete 
	SELECT DISTINCT transid, custid, recommend, mrecommend, srecommend, betfrom, statusID, status, SecAcceptFlag,
		Username, creator, hdp1,hdp2, bettype, betteam, b.odds, b.oddstype, b.transdate, b.liveindicator,b.livehomescore, 
		b.liveawayscore, b.stake, b.CurrencyName, b.betid
	FROM dbo.bettrans AS b WITH (NOLOCK)
		INNER JOIN dbo.strSplit(@BetTypes,'^') s ON s.val = b.bettype
	WHERE b.matchid=@matchid AND           
		b.transid between @FromTransId AND @ToTransId		
		AND (b.transid IN (SELECT transid FROM @tblTransCredit)
			OR b.transid IN (SELECT transid FROM @tblTransDeposit )
			OR b.transid IN (SELECT transid FROM @tblTransBetDaq )
			OR b.transid IN (SELECT transid FROM @tblTrans12EU )
			OR b.transid IN (SELECT transid FROM @tblTransMHC )
			OR b.transid IN (SELECT transid FROM @tblTransFB )
			OR b.transid IN (SELECT transid FROM @tblTransBetFair )
			OR b.transid IN (SELECT transid FROM @tblTransOneExchange )
			)
		AND CASE WHEN @LiveIndicator = 2 THEN @LiveIndicator ELSE b.liveindicator END = @LiveIndicator	
		AND b.livehomescore = CASE WHEN @LiveHomeScore IS NOT NULL AND @LiveIndicator = 1 THEN @LiveHomeScore ELSE b.livehomescore END
		AND b.liveawayscore = CASE WHEN @LiveAwayScore IS NOT NULL AND @LiveIndicator = 1 THEN @LiveAwayScore ELSE b.liveawayscore END	
		AND b.transdate BETWEEN CASE WHEN @FromTransdate IS NOT NULL AND @LiveIndicator = 1 THEN @FromTransdate ELSE b.transdate END 
						AND		CASE WHEN @ToTransdate IS NOT NULL AND @LiveIndicator = 1 THEN @ToTransdate ELSE b.transdate END 
		AND b.bettype in (128, 129, 130, 136, 137, 138, 139, 143, 144, 163, 184,194,203)
		AND(
			(
			  b.bettype IN(128)
			  AND b.betteam  IN (SELECT CONVERT(VARCHAR,val) FROM dbo.strSplit(CASE WHEN @BetTeam128 = 'All' THEN betteam ELSE @BetTeam128 END,'^'))  
			)			
			OR
			(
			  b.bettype IN (129, 130) 
			  AND b.betteam  IN (SELECT CONVERT(VARCHAR,val) FROM dbo.strSplit(CASE WHEN @BetTeam129 = 'All' THEN betteam ELSE @BetTeam129 END,'^'))  
			)
			OR
			(
			  b.bettype IN (136, 137, 138, 139, 184,194,203) 
			  AND b.betteam  IN (SELECT CONVERT(VARCHAR,val) FROM dbo.strSplit(CASE WHEN @BetTeam136 = 'All' THEN betteam ELSE @BetTeam136 END,'^'))  
			)
			OR
			(
			  b.bettype IN (143, 144, 163) 
			  AND b.betteam  IN (SELECT CONVERT(VARCHAR,val) FROM dbo.strSplit(CASE WHEN @BetTeam143 = 'All' THEN betteam ELSE @BetTeam143 END,'^'))  
			)
		)
		AND ISNULL(SecAcceptFlag,0) = CASE @SecondAcceptFlag WHEN 0 then ISNULL(SecAcceptFlag,0) 
													WHEN 1 THEN 0 
													WHEN 2 THEN 1 END	
										
	-- bettype = 154, 155, 156, 1302, 1311, 1312, 1316, 1317, 1318, 1324
	INSERT INTO #BetDelete 
	SELECT DISTINCT transid as transtest, custid, recommend, mrecommend, srecommend, betfrom, statusID, status, SecAcceptFlag,
		Username, creator, hdp1,hdp2, bettype, betteam, b.odds, b.oddstype, b.transdate, b.liveindicator,b.livehomescore, 
		b.liveawayscore, b.stake, b.CurrencyName, b.betid
	FROM dbo.bettrans AS b WITH (NOLOCK)
		INNER JOIN dbo.strSplit(@BetTypes,'^') s ON s.val = b.bettype
	WHERE b.matchid=@matchid AND           
		b.transid between @FromTransId AND @ToTransId		
		AND (b.transid IN (SELECT transid FROM @tblTransCredit)
			OR b.transid IN (SELECT transid FROM @tblTransDeposit )
			OR b.transid IN (SELECT transid FROM @tblTransBetDaq )
			OR b.transid IN (SELECT transid FROM @tblTrans12EU )
			OR b.transid IN (SELECT transid FROM @tblTransMHC )
			OR b.transid IN (SELECT transid FROM @tblTransFB )
			OR b.transid IN (SELECT transid FROM @tblTransBetFair )
			OR b.transid IN (SELECT transid FROM @tblTransOneExchange )
			)
		AND CASE WHEN @LiveIndicator = 2 THEN @LiveIndicator ELSE b.liveindicator END = @LiveIndicator	
		AND b.livehomescore = CASE WHEN @LiveHomeScore IS NOT NULL AND @LiveIndicator = 1 THEN @LiveHomeScore ELSE b.livehomescore END
		AND b.liveawayscore = CASE WHEN @LiveAwayScore IS NOT NULL AND @LiveIndicator = 1 THEN @LiveAwayScore ELSE b.liveawayscore END	
		AND b.transdate BETWEEN CASE WHEN @FromTransdate IS NOT NULL AND @LiveIndicator = 1 THEN @FromTransdate ELSE b.transdate END 
						AND		CASE WHEN @ToTransdate IS NOT NULL AND @LiveIndicator = 1 THEN @ToTransdate ELSE b.transdate END 
		AND b.bettype IN (154, 155, 156, 1302, 1311, 1312, 1316, 1317, 1318, 1324)
		AND (
			(
			  b.bettype IN (154, 155, 1311, 1316)	
			  AND b.betid = CASE WHEN @Set154 = 'ALL' THEN b.betid ELSE @Set154 END
			  AND (@BetTeam154 = 'ALL' OR b.betteam = @BetTeam154)
			)
			OR
			(
			  b.bettype IN (156, 1312)
			  AND b.betid = CASE WHEN @Set156 = 'ALL' THEN b.betid ELSE @Set156 END
			  AND (@BetTeam156 = 'ALL' OR b.betteam = @BetTeam156)
			)
			OR
			(
			  b.bettype = 1302 
			  AND b.betteam IN (SELECT CONVERT(VARCHAR, val) FROM dbo.strSplit(CASE WHEN @BetTeam1302 = 'ALL' THEN b.betteam ELSE @BetTeam1302 END, '^'))
			)
			OR
			(
			  b.bettype = 1318
			  AND b.betid = CASE WHEN @Set1318 = 'ALL' THEN b.betid ELSE @Set1318 END
			  AND (@BetTeam1318 = 'ALL' OR b.betteam = @BetTeam1318)
			)
			OR
			(
			  b.bettype = 1317
			  AND b.betid = CASE WHEN @Set1317 = 'ALL' THEN b.betid ELSE @Set1317 END
			  AND b.betteam IN (SELECT CONVERT(VARCHAR, val) FROM dbo.strSplit(CASE WHEN @BetTeam1317 = 'ALL' THEN b.betteam ELSE @BetTeam1317 END, '^'))
			)
			OR
			(
			  b.bettype = 1324
			  AND LEFT(b.betid, 3) = CASE WHEN @Set1324 = 'ALL' THEN LEFT(betid, 3) ELSE @Set1324 END -- Set
			  AND ((@Game1324 = 'ALL') OR (@Game1324 = '13' AND RIGHT(betid,2) >=13) OR (RIGHT(betid, 2) = @Game1324)) -- Game	
			  AND (@BetTeam1324 = 'ALL' OR b.betteam = @BetTeam1324)
			)
		)
		AND 1 = CASE WHEN b.bettype IN (155, 1316) THEN CASE 
													WHEN @Handicap155 = 9999 THEN 1
													WHEN @Handicap155 = (hdp1 + hdp2) THEN 1
													ELSE 0 
											 END
					WHEN b.bettype IN (156, 1312) THEN CASE
													WHEN @OverUnder156 = 9999 THEN 1
													WHEN @OverUnder156 = hdp1 THEN 1
													ELSE 0
											 END
					ELSE 1 
			END
		AND ISNULL(SecAcceptFlag,0) = CASE @SecondAcceptFlag WHEN 0 THEN ISNULL(SecAcceptFlag,0) WHEN 1 THEN 0 WHEN 2 THEN 1 END	
		
		--178,197,198,204,205
		INSERT INTO #BetDelete 
	SELECT DISTINCT transid, custid, recommend, mrecommend, srecommend, betfrom, statusID, status, SecAcceptFlag,
		Username, creator, hdp1,hdp2, bettype, betteam, b.odds, b.oddstype, b.transdate, b.liveindicator, b.livehomescore, 
		b.liveawayscore, b.stake, b.CurrencyName, b.betid
	FROM dbo.bettrans AS b WITH (NOLOCK)
		INNER JOIN dbo.strSplit(@BetTypes,'^') s ON s.val = b.bettype
		LEFT JOIN dbo.strSplit(@betteam6,'^') AS bt ON bt.val=b.betteam
	WHERE b.matchid=@matchid
		AND b.transid between @FromTransId AND @ToTransId	
		AND (b.transid IN (SELECT transid FROM @tblTransCredit)
			OR b.transid IN (SELECT transid FROM @tblTransDeposit )
			OR b.transid IN (SELECT transid FROM @tblTransBetDaq )
			OR b.transid IN (SELECT transid FROM @tblTrans12EU )
			OR b.transid IN (SELECT transid FROM @tblTransMHC)
			OR b.transid IN (SELECT transid FROM @tblTransFB )
			OR b.transid IN (SELECT transid FROM @tblTransBetFair )
			OR b.transid IN (SELECT transid FROM @tblTransOneExchange )
			)
		AND CASE WHEN @LiveIndicator = 2 THEN @LiveIndicator ELSE b.liveindicator END = @LiveIndicator
		AND b.livehomescore = CASE WHEN @LiveHomeScore IS NOT NULL AND @LiveIndicator = 1 THEN @LiveHomeScore ELSE b.livehomescore END
		AND b.liveawayscore = CASE WHEN @LiveAwayScore IS NOT NULL AND @LiveIndicator = 1 THEN @LiveAwayScore ELSE b.liveawayscore END	
		AND b.transdate BETWEEN CASE WHEN @FromTransdate IS NOT NULL AND @LiveIndicator = 1 THEN @FromTransdate ELSE b.transdate END 
						AND		CASE WHEN @ToTransdate IS NOT NULL AND @LiveIndicator = 1 THEN @ToTransdate ELSE b.transdate END 	
		AND b.bettype IN (178,197,198,204,205)
		AND (
			  (b.bettype IN (178,197,198,204,205)	
				AND (@BetTeam178 = 'ALL' OR b.betteam = @BetTeam178)
			  )
			)
		AND 1 = CASE WHEN b.bettype IN (178,197,198,204,205) THEN CASE
													WHEN @Handicap178 = 9999 THEN 1
													WHEN @Handicap178 = hdp1 THEN 1
													ELSE 0
											 END
					ELSE 1 
			END
		AND ISNULL(SecAcceptFlag,0) = CASE @SecondAcceptFlag WHEN 0 THEN ISNULL(SecAcceptFlag,0) 
													 WHEN 1 THEN 0 
													 WHEN 2 THEN 1 END				 
	
		--133,134,135,145,146,147,148,149,150,159,161,162,165,166,169,173,174,179,181,182,188,189,190,193,195,196,199,200,201,202,210,211,212,213,214,215,216,217
		INSERT INTO #BetDelete 
	SELECT DISTINCT transid, custid, recommend, mrecommend, srecommend, betfrom, statusID, status, SecAcceptFlag,
		Username, creator, hdp1,hdp2, bettype, betteam, b.odds, b.oddstype, b.transdate, b.liveindicator, b.livehomescore, 
		b.liveawayscore, b.stake, b.CurrencyName, b.betid
	FROM dbo.bettrans AS b WITH (NOLOCK)
		INNER JOIN dbo.strSplit(@BetTypes,'^') s ON s.val = b.bettype
		LEFT JOIN dbo.strSplit(@betteam6,'^') AS bt ON bt.val=b.betteam
	WHERE b.matchid=@matchid
		AND b.transid between @FromTransId AND @ToTransId	
		AND (b.transid IN (SELECT transid FROM @tblTransCredit)
			OR b.transid IN (SELECT transid FROM @tblTransDeposit )
			OR b.transid IN (SELECT transid FROM @tblTransBetDaq )
			OR b.transid IN (SELECT transid FROM @tblTrans12EU )
			OR b.transid IN (SELECT transid FROM @tblTransMHC)
			OR b.transid IN (SELECT transid FROM @tblTransFB )
			OR b.transid IN (SELECT transid FROM @tblTransBetFair )
			OR b.transid IN (SELECT transid FROM @tblTransOneExchange )
			)
		AND CASE WHEN @LiveIndicator = 2 THEN @LiveIndicator ELSE b.liveindicator END = @LiveIndicator
		AND b.livehomescore = CASE WHEN @LiveHomeScore IS NOT NULL AND @LiveIndicator = 1 THEN @LiveHomeScore ELSE b.livehomescore END
		AND b.liveawayscore = CASE WHEN @LiveAwayScore IS NOT NULL AND @LiveIndicator = 1 THEN @LiveAwayScore ELSE b.liveawayscore END	
		AND b.transdate BETWEEN CASE WHEN @FromTransdate IS NOT NULL AND @LiveIndicator = 1 THEN @FromTransdate ELSE b.transdate END 
						AND		CASE WHEN @ToTransdate IS NOT NULL AND @LiveIndicator = 1 THEN @ToTransdate ELSE b.transdate END 	
		AND b.bettype IN (133,134,135,145,146,147,148,149,150,159,161,162,165,166,169,173,174,179,181,182,188,189,190,193,195,196,199,200,201,202,210,211,212,213,214,215,216,217)
		AND (
				(
				  b.bettype IN (165,166)
				  AND b.betteam IN (SELECT CONVERT(VARCHAR, val) FROM dbo.strSplit(CASE WHEN @BetTeam165 = 'ALL' THEN b.betteam ELSE @BetTeam165 END, '^'))
				)
				OR
				(
				  b.bettype IN (159)
				  AND b.betteam IN (SELECT CONVERT(VARCHAR, val) FROM dbo.strSplit(CASE WHEN @BetTeam159 = 'ALL' THEN b.betteam ELSE @BetTeam159 END, '^'))
				)
				OR
				(
				  b.bettype IN (179)
				  AND 
				  (
					(b.betteam IN (SELECT CONVERT(VARCHAR, val) FROM dbo.strSplit(CASE WHEN @BetTeam159 = 'ALL' THEN b.betteam ELSE @BetTeam159 END, '^')))
					OR
					(
						b.betteam = 'G4'
						AND
						'G4&Over' IN (SELECT CONVERT(VARCHAR, val) FROM dbo.strSplit(CASE WHEN @BetTeam159 = 'ALL' THEN 'G4&Over' ELSE @BetTeam159 END, '^'))
					)
				  )
				)
				OR
				(
				  b.bettype IN (161,162,181,182)
				  AND b.betteam IN (SELECT CONVERT(VARCHAR, val) FROM dbo.strSplit(CASE WHEN @BetTeam161 = 'ALL' THEN b.betteam ELSE @BetTeam161 END, '^'))
				)
				OR
				(
				  b.bettype IN (199)
				  AND b.betteam IN (SELECT CONVERT(VARCHAR, val) FROM dbo.strSplit(CASE WHEN @BetTeam199 = 'ALL' THEN b.betteam ELSE @BetTeam199 END, '^'))
				)
				OR
				(
				  b.bettype IN (202)
				  AND b.betteam IN (SELECT CONVERT(VARCHAR, val) FROM dbo.strSplit(CASE WHEN @BetTeam202 = 'ALL' THEN b.betteam ELSE @BetTeam202 END, '^'))
				)
				OR
				(
				  b.bettype IN (195,196)
				  AND b.betteam IN (SELECT CONVERT(VARCHAR, val) FROM dbo.strSplit(CASE WHEN @BetTeam195 = 'ALL' THEN b.betteam ELSE @BetTeam195 END, '^'))
				)
				OR
				(
				  b.bettype IN (200,201)
				  AND b.betteam IN (SELECT CONVERT(VARCHAR, val) FROM dbo.strSplit(CASE WHEN @BetTeam200 = 'ALL' THEN b.betteam ELSE @BetTeam200 END, '^'))
				)
				OR
				(
				  b.bettype IN (169,193)
				  AND b.betteam IN (SELECT CONVERT(VARCHAR, val) FROM dbo.strSplit(CASE WHEN @BetTeam169 = 'ALL' THEN b.betteam ELSE @BetTeam169 END, '^'))
				)
				OR
				(
				  b.bettype IN (210,173,174,188,189,190,211,212,213,214,215,133,134,135,145,146,147,148,149,150)
				  AND b.betteam IN (SELECT CONVERT(VARCHAR, val) FROM dbo.strSplit(CASE WHEN @BetTeam210 = 'ALL' THEN b.betteam ELSE @BetTeam210 END, '^'))
				)
				OR
				(
				  b.bettype IN (216,217)
				  AND b.betteam IN (SELECT CONVERT(VARCHAR, val) FROM dbo.strSplit(CASE WHEN @BetTeam216 = 'ALL' THEN b.betteam ELSE @BetTeam216 END, '^'))
				)
			)
		AND ISNULL(SecAcceptFlag,0) = CASE @SecondAcceptFlag WHEN 0 THEN ISNULL(SecAcceptFlag,0) 
													 WHEN 1 THEN 0 
													 WHEN 2 THEN 1 END			 								 
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


	IF EXISTS (SELECT 1 FROM #BetDelete WHERE statusID IN (111,112,113))
	BEGIN
		SELECT @ErrCode = 100, @ErrMsg = 'You can only void the unsettled or refunded tickets.'
		-----
		DELETE FROM dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK)
		WHERE KeyID = @KeyID AND KeyValue = @MatchId	
		IF (@@Error = 0)
		BEGIN TRY
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID = @UserID, 
				@MatchId = @MatchId, 
				@KeyID = @KeyID,
				@ActionID = 0, 
				@Remark = 'VOID SUCCESS SPName=NAP_BettransDelSpecial'
		END TRY
		BEGIN CATCH
			SELECT @Remark = 'VOID SUCCESS SPName=NAP_BettransDelSpecial ErrMsg=' + LEFT(error_message(), 400)
			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
				@UserID = @UserID, 
				@MatchId = @MatchId, 
				@KeyID = @KeyID,
				@ActionID = 0, 
				@Remark = @Remark
		END CATCH
		ELSE
		BEGIN
			BEGIN TRY
				EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
					@UserID = @UserID, 
					@MatchId = @MatchId, 
					@KeyID = @KeyID,
					@ActionID = 0, 
					@Remark = 'VOID FAILED SPName=NAP_BettransDelSpecial'
			END TRY
			BEGIN CATCH
				SELECT @Remark = 'VOID FAILED SPName=NAP_BettransDelSpecial ErrMsg=' + LEFT(error_message(), 400)
				EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
					@UserID = @UserID, 
					@MatchId = @MatchId, 
					@KeyID = @KeyID,
					@ActionID = 0, 
					@Remark = @Remark
			END CATCH
		END
		RETURN
	END
	ELSE
	BEGIN
		DELETE FROM #BetDelete WHERE statusID IN (SELECT * FROM @Status)
	END
	------------------***** Begin Special Delete *****------------------
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
			AND CASE
				WHEN b.bettype IN (1,3,7,8) THEN CASE WHEN @BetTeam1378 = 'ALL' THEN betteam ELSE @BetTeam1378 END
				WHEN b.bettype IN (5,15) THEN CASE WHEN @BetTeam515 = 'ALL' THEN betteam ELSE @BetTeam515 END
				ELSE betteam
			END = betteam    

	CREATE TABLE #BeforeUpd (
			custid		 INT,
			balance		 MONEY)
		
	CREATE TABLE #AfterUpd(
				custid		 INT,
				balance		 MONEY)

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

	-- update totalbets
	DECLARE @Total TABLE (oddsid INT, HomeTotal MONEY, AwayTotal MONEY)
	INSERT INTO @Total
		SELECT oddsid,
			SUM(CASE WHEN betteam='h' THEN (CASE WHEN ABS(odds) > 1 THEN ABS(odds) 
					 ELSE 1 END * b.stake * e.actualrate * (1-b.tpositiontaking)) ELSE 0 END) homeTotal,
			SUM(CASE WHEN betteam='a' THEN (CASE WHEN ABS(odds) > 1 THEN ABS(odds) 
					 ELSE 1 END * b.stake * e.actualrate * (1-b.tpositiontaking)) ELSE 0 END) awayTotal
		FROM bettrans b WITH (nolock)
			INNER JOIN custDB.dbo.exchange e WITH (nolock) ON b.currency = e.exchangeid
		WHERE bettype IN (1,3,7,8) AND ruben = 0 AND oddsid <> 0 AND matchid = @MatchId
		GROUP BY oddsid

	UPDATE odds WITH (rowlock, updlock)
	SET hometotal = t.HomeTotal, awaytotal = t.AwayTotal
	FROM @Total t WHERE odds.oddsid = t.oddsid AND odds.matchid = @MatchId

	--Get data after update
	INSERT INTO #AfterUpd (custid, balance)
	SELECT	b.custid, SUM (b.winlost - b.actual_stake + b.playercomm) balance
	FROM	bettrans b WITH (NOLOCK)
	WHERE	b.transid IN (SELECT transid FROM #BetDelete)
	GROUP BY b.CustID

	---INSERT data into pending balance table 
	INSERT INTO BalancePendingCredit (custid,Balance)
	SELECT		a.custid, (a.balance - b.balance) as Balance
	FROM		#BeforeUpd b
	INNER JOIN	#AfterUpd a 	
			ON	a.custid = b.custid
	WHERE	    (a.balance - b.balance) > 0

	INSERT INTO BalancePendingDebit (custid,Balance)
	SELECT		a.custid, ABS(a.balance - b.balance) as Balance
	FROM		#BeforeUpd b
	INNER JOIN	#AfterUpd a 	
			ON	a.custid = b.custid
	WHERE	    (a.balance - b.balance) < 0
------------------***** End of Special Delete *****------------------

	SELECT @LogData ='void bet for matchid ' + CONVERT(VARCHAR(20), @MatchId) 
			+ ' from ' + CONVERT(VARCHAR(20), @FromTransId) + ' to ' 
			+ CONVERT(VARCHAR(20), @ToTransId) + ' IP=' + COALESCE(CAST(@IP AS VARCHAR(15)),SPACE(1)) 
			+ ' reason: ' + @Reason
			
	EXEC WriteLog_UserLog 
		@UserID = @UserID
		,@Doing = @LogData

	-- Match info
	IF EXISTS(SELECT CONVERT(INT,val) FROM dbo.strSplit(@bettypes,'^') WHERE CONVERT(INT, val) = 10)  --@bettype = 10
	BEGIN
		SELECT MATCH.teamid AS homeid,
			0 AS awayid,
			MATCH.matchcode,
			MATCH.eventdate,
			MATCH.leagueid,
			GETDATE() AS DATETIME,
			CONVERT(BIT,0) AS IsNeutral,
			1 AS IsOutright
		FROM
			Outright AS MATCH WITH (NOLOCK)
		WHERE 
			MATCH.orid = @MatchId
	END   
	ELSE
	BEGIN
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
	END

	-- All ticket voided
	SELECT transid, 
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
	SELECT c.username, c.username2, b.odds, b.OddsType, b.transdate, b.bettype, b.betfrom,
		b.transid AS refno, betteam, hdp1, hdp2, betfrom, b.isLiveIndicator, livehomescore, liveawayscore, cr.username creator,
		stake, b.CurrencyName, ag.site, b.status, b.SecAcceptFlag, b.betid
	FROM
		#BetDelete b WITH (NOLOCK)
		INNER JOIN custDB.dbo.customer c  WITH (NOLOCK) ON c.custid=b.custid
		INNER JOIN custDB.dbo.customer cr WITH (NOLOCK) ON cr.custid = b.creator
		INNER JOIN custDB.dbo.customer ag WITH (NOLOCK) ON c.recommend = ag.custid
	WHERE c.custid IN (SELECT custid FROM @DepositCust) -- Email deposit if voided		
	ORDER BY transid

	-- Send mail when void 12EU tickets 
		SELECT c.username, c.username2, b.odds, b.OddsType, b.transdate, b.bettype, b.betfrom,
		b.transid AS refno, betteam, hdp1, hdp2, betfrom, b.isLiveIndicator,livehomescore, liveawayscore, cr.username creator,
		stake, b.CurrencyName, '12EU' as site, b.status, b.SecAcceptFlag, b.betid
	FROM
		#BetDelete b WITH (NOLOCK)
		INNER JOIN custDB.dbo.customer c WITH (NOLOCK) ON c.custid=b.custid
		INNER JOIN custDB.dbo.customer cr WITH (NOLOCK) ON cr.custid = b.creator
		INNER JOIN custDB.dbo.customer ag WITH (NOLOCK) ON c.recommend = ag.custid
	WHERE b.custid IN (SELECT [@12EUCust].custid FROM @12EUCust) -- Email 12EU if voided			
	ORDER BY transid

	
	-----Send mail when void any real tickets by IT
	SELECT c.username,c.username2, b.odds, b.OddsType, b.transdate, b.bettype, b.betfrom,
		b.transid AS refno, betteam, hdp1, hdp2, betfrom, b.isLiveIndicator,livehomescore, liveawayscore,
		cr.username creator, stake, b.CurrencyName, ag.site,
		b.status, b.SecAcceptFlag, b.betid
	FROM #BetDelete b WITH (NOLOCK)
		INNER JOIN custDB.dbo.customer c WITH (NOLOCK) ON c.custid=b.custid
		INNER JOIN custDB.dbo.customer cr WITH (NOLOCK) ON cr.custid = b.creator
		INNER JOIN custDB.dbo.customer ag WITH (NOLOCK) ON c.recommend = ag.custid
	WHERE c.custid IN (SELECT custid FROM @RealCurrCust)			     					   
	ORDER BY transid    	   

	-- Send mail when void UUS tickets
		SELECT c.username,c.username2, b.odds, b.OddsType, b.transdate, b.bettype, b.betfrom,
		b.transid AS refno, betteam, hdp1, hdp2, betfrom, b.isLiveIndicator,livehomescore, liveawayscore,
		cr.username creator, stake, b.CurrencyName, ag.site,
		b.status, b.SecAcceptFlag, b.betid
	FROM #BetDelete b WITH (NOLOCK)
		INNER JOIN custDB.dbo.customer c WITH (NOLOCK) ON c.custid=b.custid
		INNER JOIN custDB.dbo.customer cr WITH (NOLOCK) ON cr.custid = b.creator
		INNER JOIN custDB.dbo.customer ag WITH (NOLOCK) ON c.recommend = ag.custid
	WHERE c.custid IN (SELECT custid FROM @UUSCust)				     					   
	ORDER BY transid    

	-----Send mail when void Foobet tickets
	SELECT c.username, c.username2, b.odds, b.OddsType, b.transdate, b.bettype, b.betfrom,
		b.transid AS refno, betteam, hdp1, hdp2, betfrom, b.isLiveIndicator,livehomescore, liveawayscore,
		cr.username creator, stake, b.CurrencyName, 'Foobet' as site,
		b.status, b.SecAcceptFlag, b.betid
	FROM #BetDelete b WITH (NOLOCK)
		INNER JOIN custDB.dbo.customer c WITH (NOLOCK) ON c.custid=b.custid
		INNER JOIN custDB.dbo.customer cr WITH (NOLOCK) ON cr.custid = b.creator
		INNER JOIN custDB.dbo.customer ag WITH (NOLOCK) ON c.recommend = ag.custid
	WHERE c.custid IN (SELECT custid FROM @FoobetCust)			     					   
	ORDER BY transid  
	
	-----Send mail when void Betfair tickets
	SELECT c.username, c.username2, b.odds, b.OddsType, b.transdate, b.bettype, b.betfrom,
		b.transid AS refno, betteam, hdp1, hdp2, betfrom, b.isLiveIndicator,livehomescore, liveawayscore,
		cr.username creator, stake, b.CurrencyName, 'BetFair' as site,
		b.status, b.SecAcceptFlag, b.betid
	FROM #BetDelete b WITH (NOLOCK)
		INNER JOIN custDB.dbo.customer c WITH (NOLOCK) ON c.custid=b.custid
		INNER JOIN custDB.dbo.customer cr WITH (NOLOCK) ON cr.custid = b.creator
		INNER JOIN custDB.dbo.customer ag WITH (NOLOCK) ON c.recommend = ag.custid
	WHERE c.custid IN (SELECT custid FROM @BetFairCust)			     					   
	ORDER BY transid    

	-----Send mail when void OneExchange tickets
	SELECT c.username, c.username2, b.odds, b.OddsType, b.transdate, b.bettype, b.betfrom,
		b.transid AS refno, betteam, hdp1, hdp2, betfrom, b.isLiveIndicator,livehomescore, liveawayscore,
		cr.username creator, stake, b.CurrencyName, 'OneExchange' as site,
		b.status, b.SecAcceptFlag, b.betid
	FROM #BetDelete b WITH (NOLOCK)
		INNER JOIN custDB.dbo.customer c WITH (NOLOCK) ON c.custid=b.custid
		INNER JOIN custDB.dbo.customer cr WITH (NOLOCK) ON cr.custid = b.creator
		INNER JOIN custDB.dbo.customer ag WITH (NOLOCK) ON c.recommend = ag.custid
	WHERE c.custid IN (SELECT custid FROM @OneExchangeCust)			     					   
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
				@Remark		= 'VOID SUCCESS SPName=NAP_BettransDelSpecial'
		END TRY
		BEGIN CATCH
			SELECT @Remark	= 'VOID SUCCESS SPName=NAP_BettransDelSpecial ErrMsg=' + LEFT(error_message(), 400)
			
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
					@Remark		= 'VOID FAILED SPName=NAP_BettransDelSpecial'
			END TRY
			BEGIN CATCH
				SELECT @Remark = 'VOID FAILED SPName=NAP_BettransDelSpecial ErrMsg=' + LEFT(error_message(), 400)
				
				EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking 
					@UserID		= @UserID, 
					@MatchId	= @MatchId, 
					@KeyID		= @KeyID,
					@ActionID	= 0, 
					@Remark		= @Remark
			END CATCH
		END	

	--20140121@Elodie: Apply LAS system for special delete function [Redmine:#10701]
	DECLARE @TransIdsLAS VARCHAR(MAX), @strLASAgent VARCHAR(500)
	DECLARE @tblTransLAS TABLE(transid VARCHAR(20))
	DECLARE @LASCust TABLE (custid INT)
	DECLARE @AgentUpline TABLE (TransID BIGINT,TargetID INT,TargetName VARCHAR(50),IsAgent BIT)

	EXEC DBLAS.LASDB.dbo.Las_Get_recommend @StringRec = @strLASAgent output

	INSERT INTO @LASCust
	SELECT CONVERT(INT, val) FROM dbo.strSplit(ISNULL(@strLASAgent, ''), '^')
	
	INSERT INTO @tblTransLAS(transid)
	SELECT cast(b.transid as varchar(20))
	FROM #BetDelete b 
	WHERE b.recommend IN (SELECT custid FROM @LASCust)
		AND b.transid IN (SELECT transid FROM @tblTransDeposit)

	;WITH tmp AS
	(SELECT stuff(
			(
			SELECT '^ ' + T2.transid
			FROM @tblTransLAS AS T2
			ORDER BY T2.transid
			FOR XML PATH(''), type
			).value('.', 'varchar(max)'), 1, 2, '') AS val
	FROM @tblTransLAS AS T1
	)
	SELECT @TransIdsLAS = val + '^' FROM tmp
	IF @TransIdsLAS IS NOT NULL
	BEGIN
		BEGIN TRY
			DECLARE @ErrMsgLAS NVARCHAR(200), @ErrCodeLAS INT
			EXEC DBLAS.LASDB.dbo.LAS_BettransDelSpecial @UserID = @UserID, @MatchID = @MatchID, @TransID = @TransIdsLAS, @IP = @IP, @ErrCode = @ErrCodeLAS OUTPUT, @ErrMsg = @ErrMsgLAS OUTPUT		
			IF @ErrCodeLAS > 50000 -- error from LAS_BettransDelSpecial
			BEGIN
				SELECT @Remark = 'RUN FAILED SPName=LAS_BettransDelSpecial ErrCode=' + cast(@ErrCodeLAS as varchar(10)) + ' ErrMsg=' + @ErrMsgLAS
				BEGIN TRY
					EXEC DBLOG.bodb_CustomerLog.dbo.LAS_WriteLog_UserLog_RunSP
									@UserID = @UserID, 
									@Matchid = @matchid, 
									@ActionID = 2902, 
									@Remark = @Remark
				END TRY
				BEGIN CATCH
					EXEC bodb_CustomerLog.dbo.LAS_WriteLog_UserLog_RunSP
									@UserID = @UserID, 
									@Matchid = @matchid, 
									@ActionID = 2902, 
									@Remark = @Remark
				END CATCH
			END
			ELSE -- no error
				BEGIN TRY
					EXEC DBLOG.bodb_CustomerLog.dbo.LAS_WriteLog_UserLog_RunSP
									@UserID = @UserID, 
									@Matchid = @matchid, 
									@ActionID = 2902, 
									@Remark = 'CALL SUCCESS SPName=LAS_BettransDelSpecial'
				END TRY
				BEGIN CATCH
					EXEC bodb_CustomerLog.dbo.LAS_WriteLog_UserLog_RunSP
									@UserID = @UserID, 
									@Matchid = @matchid, 
									@ActionID = 2902, 
									@Remark = 'CALL SUCCESS SPName=LAS_BettransDelSpecial'
				END CATCH			
		END TRY
		BEGIN CATCH -- exception			
			SELECT TransID, TargetID, TargetName, IsAgent FROM @AgentUpline

			SELECT @Remark = 'CALL FAILED SPName=LAS_BettransDelSpecial ErrCode=' + cast(ERROR_NUMBER() as varchar(10)) + ' ErrMsg=' + LEFT(error_message(), 400)
			BEGIN TRY			
				EXEC DBLOG.bodb_CustomerLog.dbo.LAS_WriteLog_UserLog_RunSP
								@UserID = @UserID, 
								@Matchid = @matchid, 
								@ActionID = 2902, 
								@Remark = @Remark
			END TRY
			BEGIN CATCH
				EXEC bodb_CustomerLog.dbo.LAS_WriteLog_UserLog_RunSP
								@UserID = @UserID, 
								@Matchid = @matchid, 
								@ActionID = 2902, 
								@Remark = @Remark
			END CATCH
		END CATCH
	END
	ELSE
	BEGIN
		SELECT TransID, TargetID, TargetName, IsAgent FROM @AgentUpline
	END

	DROP TABLE #BetDelete

	SET NOCOUNT OFF
END



GO
GRANT EXECUTE ON [dbo].[NAP_BettransDelSpecial] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_BettransDelSpecial] TO [vnteam] AS [dbo]