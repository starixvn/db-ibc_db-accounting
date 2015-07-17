ALTER PROCEDURE [dbo].[NAP_BettransSpecialDelBetID_Del]
	@strTransID		VARCHAR(MAX) = '',
	@CustID			int = 0,
	@username		varchar(30),
	@password		varchar(50),
	@UserID			int = 0, --custid of Admin,
	@IP				varchar(15) = '',
	@reason			nvarchar(500)= '',
	@ErrCode		int = 0 OUTPUT,
	@ErrMsg			nvarchar(200) = '' OUTPUT
AS
/*	Created by: Jamie
	Task:  VOID BY BET ID (Running & Settled tickets)
	DB: DBTXN/bodb02
	Original: 
	
	Revisions:
		- 20141125@Kathy: Add betid column [Redmine:##26489]
		- 20150402@Dominic: Add new 60 bettypes [Redmine:#27214]
		- 20150615@Dominic: BetTrade Integration 	[Redmine:#36964]
	Param's Explanation: 
*/
BEGIN 
	SET NOCOUNT ON

	-- As confirmed by BA, No need to check permission inside SP
	----Check permission for account site
	--EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[DeleteBets]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
	--If @ErrCode <> 0
	--	RETURN

	DECLARE @LogData		NVARCHAR(500)	
			,@isITAdmin		BIT

	SELECT	@isITAdmin		= 0 

	If NOT EXISTS (select 1 from CustDB.dbo.customer c with (nolock) where userpwd = @password and custid = @userid and roleid >= 5)
	BEGIN
		SELECT	 @ErrMsg = 'Sorry. You cannot process void bets due to either wrong password or insufficient permission!'
				,@ErrCode = 101

		SELECT	@LogData = 'Try to delete transaction for custid: ' + cast(@UserID AS VARCHAR(10)) + ' betlist: ' + cast(@strtransid AS VARCHAR(8000)) + ' - Username: ' + @username + ' - reason: ' + @reason

		EXEC WriteLog_UserLog @UserID = @UserID ,@Doing = @LogData
		RETURN
	END
	
	CREATE TABLE #BeforeUpd (
			custid		 INT,
			balance		 MONEY)
		
	CREATE TABLE #AfterUpd(
				custid		 INT,
				balance		 MONEY)
				
	DECLARE @tmpListTransID TABLE (
		 TransID		BIGINT
		,MatchID		INT
		,Bettype		INT
		,betid			BIGINT
		,Refno			BIGINT
		,Betfrom		NVARCHAR(10)
		,StatusID		TINYINT
		,KeyID			INT 
	)

	INSERT INTO @tmpListTransID(
		 TransID
		,MatchID
		,Bettype
		,betid
		,Refno
		,Betfrom
		,StatusID
		,KeyID
	)
	SELECT	 TransID
			,MatchID
			,Bettype
			,betid
			,Refno
			,Betfrom
			,StatusID
			,CASE Bettype WHEN 9 THEN -1	-- isCalculatingParlay in SystemSettings OR 1 (Single match)
						  WHEN 10 THEN 2    -- Outright 
						  ELSE 1 END		-- SB, NG, LiveCS 
	FROM	Bettrans WITH (NOLOCK)
	WHERE	TransID IN (SELECT CONVERT(BIGINT,Val) FROM dbo.strSplit(@strTransID,','))
			AND StatusID NOT IN (101, 102)	-- REJECT, VOID
	
	--Update 901.betid=main.bettype
	UPDATE main
	SET main.betid = b.bettype
	FROM @tmpListTransID main
	INNER JOIN Bettrans b WITH (NOLOCK) ON b.transid = main.refno
	WHERE main.bettype = 901
	
	IF EXISTS(SELECT TOP 1 1 FROM @tmpListTransID WHERE Bettype = 9 AND StatusID BETWEEN 111 AND 113)  -- DRAW, WON, LOSE 
	BEGIN
		DELETE FROM @tmpListTransID WHERE Bettype = 9 AND StatusID BETWEEN 111 AND 113
		AND Bettype NOT IN (901,902,903)	-- Not allowed to delete settled(DRAW, WON, LOSE ) Mix Parlay 
	END

	IF EXISTS(SELECT TOP 1 1 FROM @tmpListTransID WHERE Bettype BETWEEN 1101 AND 1199 AND StatusID BETWEEN 0 AND 1)
	BEGIN
		DELETE FROM @tmpListTransID WHERE Bettype BETWEEN 1101 AND 1199 AND StatusID BETWEEN 0 AND 1 
		AND Bettype NOT IN (901,902,903)-- Not allowed to settle the running Live CS bet 
	END

	DECLARE	@Recommend			INT
			,@MRecommend		INT
			,@Srecommend		INT
			,@Site				VARCHAR(10)
			,@Username2			VARCHAR(30)
			,@isExistMatch		BIT
			,@isExistParlay		BIT
			,@isExistOutright	BIT
			,@isCustDeposit		BIT
			,@CustUsername		VARCHAR(30)
			,@AgUsername		VARCHAR(30)
			,@MAgUsername		VARCHAR(30)
			,@SAgUsername		VARCHAR(30)
			,@EmailGroup		VARCHAR(30)
			,@isNegativeBalance BIT
			,@totalbalance		MONEY
			,@balance			MONEY
			,@winlostdate		DATETIME
			,@currency			INT
	
	DECLARE @ErrorTransID		TABLE(transid BIGINT PRIMARY KEY)

	SELECT	@winlostdate	= MIN(winlostdate)
			,@CustID		= MIN(CustID)
			,@Balance		= SUM(winlost - actual_stake + playercomm) 
			,@isExistMatch	= MAX(CASE WHEN Bettype NOT IN (9,10) THEN 1 ELSE 0 END)
			,@isExistParlay = MAX(CASE WHEN Bettype = 9 THEN 1 ELSE 0 END)
			,@isExistOutright = MAX(CASE WHEN Bettype = 10 THEN 1 ELSE 0 END)
	FROM	Bettrans WITH (NOLOCK)
	WHERE	TransID IN (SELECT TransID FROM @tmpListTransID WHERE Bettype NOT IN (901,902,903))
			

	SELECT	 @Username2		= Username2
			,@CustUsername	= username
			,@Recommend		= recommend
			,@MRecommend	= mrecommend
			,@Srecommend	= srecommend
	FROM	CustDB.dbo.Customer WITH (NOLOCK)
	WHERE	CustID = @CustID

	--Check settled Date
	EXEC dbo.Acc_CheckSettledDate @winlostdate = @winlostdate, @UserID = @UserID, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT
	If @ErrCode <> 0
		RETURN
	
	--- CHECKING SETTLEMENT PROCESS IN PROGRESS OR NOT ?????
	IF(@isExistParlay = 1)
	BEGIN
		IF EXISTS(SELECT 1 FROM SystemSettings WITH (NOLOCK) WHERE VValue = 1 AND VName = 'isCalculatingParlay')
		BEGIN
			SELECT @ErrCode = 201
			SELECT @ErrMsg = 'Another parlay settlement is in progress or some parlay tickets are being deleted, please wait a few seconds until the on-going process has finished and try again.'
			RETURN
		END
		ELSE 
		BEGIN
			UPDATE systemSettings WITH (ROWLOCK, UPDLOCK)
			SET VValue = '1'
			WHERE VName = 'isCalculatingParlay'
		END	
	END

	IF(@isExistMatch = 1 OR @isExistOutright = 1)
	BEGIN
		IF(EXISTS(
			SELECT TOP 1 1 
			FROM	dbo.TempVariableNumber t WITH (NOLOCK)
					INNER JOIN @tmpListTransID l ON t.KeyID = t.KeyID AND t.KeyValue = l.MatchID 
			WHERE	Bettype <> 9  --- EXCLUDE MIX PARLAY 
					AND Bettype NOT IN (901,902,903)
		
		))
		BEGIN
			SELECT  @ErrCode = 206,
					@ErrMsg = 'The selected tickets are not ready to be voided now, please wait a few seconds until the on-going process is completed and try again.'
			RETURN
		END
		ELSE
		BEGIN
			INSERT INTO dbo.TempVariableNumber (KeyID, KeyValue) 
			SELECT	DISTINCT KeyID, MatchID 
			FROM	@tmpListTransID
			WHERE	Bettype <> 9   AND Bettype NOT IN (901,902,903)
		END
	END

	-- CHECK IT GROUP or NOT ? 
	EXEC DBPOLICY.bodb02.dbo.Acc_Con_GroupInfoSel 
		 @GroupID = 1								-- 'IT' GROUP 
		,@UserID = @UserID
		,@ShowInternalGroup = 0
		,@System = 'ACCOUNTING'
	IF @@ROWCOUNT <> 0 
	BEGIN
		SELECT	@isITAdmin = 1 
	END

	SELECT	@Site = Site
			,@AgUsername	= username
			,@currency		= Currency 
	FROM	CustDB.dbo.Customer WITH (NOLOCK)
	WHERE	CustID = @Recommend
	
	SELECT	@MAgUsername	= Username 
	FROM	CustDB.dbo.CustInfo WITH (NOLOCK)
	WHERE	CustID = @MRecommend

	SELECT	@SAgUsername	= Username 
	FROM	CustDB.dbo.CustInfo WITH (NOLOCK)
	WHERE	CustID = @SRecommend

	IF (EXISTS(SELECT TOP 1 1 from CustDB.dbo.Dep_CustSuper WITH (NOLOCK) WHERE CustID =@SRecommend ))
	BEGIN
		SELECT @isCustDeposit = 1 
	END

	SELECT	@EmailGroup = CASE	WHEN @CustUsername = '12EU' THEN '12EU'
								WHEN @isCustDeposit = 1 THEN 'Deposit' 
								WHEN @Recommend = 11196380 THEN 'Foobet'		-- FB
								WHEN @CustID IN (1077687, 2331, 115770, 15523642) THEN 'Betfair'  -- Betfair: BFOS, BF, ITibc102, BF3
								WHEN @Recommend = 13423967 THEN 'OneExchange'  --1E
								ELSE '' END 
	-- SINGLE BET 
	UPDATE odds
	SET hometotal = hometotal - (CASE WHEN b.betteam = 'h' THEN CASE	WHEN abs(b.odds) > 1 THEN b.stake * e.actualrate * abs(b.odds) * (1 - b.tpositiontaking)
																		ELSE b.stake * e.actualrate * (1 - b.tpositiontaking) END
									  ELSE 0 END )
		,awaytotal = awaytotal - (CASE WHEN b.betteam = 'a' THEN CASE	WHEN abs(b.odds) > 1 THEN b.stake * e.actualrate * abs(b.odds) * (1 - b.tpositiontaking)
																		ELSE b.stake * e.actualrate * (1 - b.tpositiontaking) END
									   ELSE 0 END)
	FROM odds o WITH (ROWLOCK,UPDLOCK)
		INNER JOIN bettrans b WITH (NOLOCK) ON o.oddsid = b.oddsid
		INNER JOIN CustDB.dbo.customer c WITH (NOLOCK) ON c.custid = b.custid
		INNER JOIN CustDB.dbo.exchange e WITH (NOLOCK) ON c.currency = e.exchangeid
	WHERE b.transid IN (
				SELECT	TransID
				FROM	@tmpListTransID
				WHERE	Bettype <> 9 AND Bettype NOT IN (901,902,903)
			)

	SELECT	@totalbalance = SUM(winlost - actual_stake + playercomm)
	FROM	bettrans with (nolock)
	WHERE	custid = @CustID

	
	
	-- Get Upline info 

	SELECT	 @CustID			AS CustID 
			,@CustUsername		AS CustUsername
			,@Username2			AS Username2
			,@AgUsername		AS AgUsername
			,@Recommend			AS Recommend
			,@MAgUsername		AS MAgUsername
			,@MRecommend		AS Mrecommend
			,@SAgUsername		AS SAgUsername
			,@Srecommend		AS SRecommend 
			,@currency			AS Currency 
			,@isNegativeBalance AS isNegativeBalance
			,@Site				AS [Site]
			,@EmailGroup		AS EmailGroup 
			,@isITAdmin			AS isITAdmin 

		
	--- BETS: return all additional information for mailing
	SELECT	m.homeid,
			m.awayid,
			m.matchcode,
			m.eventdate,
			m.leagueid,
			GETDATE() AS DATETIME,
			isnull(m.isNeutral, CONVERT(BIT,0)) AS IsNeutral,
			showtime AS GameEvent,
			b.bettype,
			b.odds,  
			b.OddsType, 
			b.transdate,
			b.bettype,
			b.transid,
			b.refno,
			b.betteam,
			b.betcheck,
			b.hdp1,
			b.hdp2,
			b.betfrom,
			b.livehomescore,
			b.liveawayscore,
			b.liveindicator,
			cr.username creator,
			b.stake,     
			b.status,
			b.winlost - actual_stake as winlost,
			b.playercomm as comm,      
			b.currency,
			tpl.betid
	FROM	bettrans b WITH (NOLOCK)
			INNER JOIN @tmpListTransID tpl ON tpl.transid = b.transid
			INNER JOIN Match m WITH (NOLOCK) ON b.matchID = m.matchid
			INNER JOIN CustDB.dbo.customer cr WITH (NOLOCK) ON cr.custid = b.creator
	WHERE	@isExistMatch = 1 
			AND tpl.bettype NOT IN (10,9)
	UNION ALL 
	SELECT	
			0 AS homeid,
			0 AS awayid,
			'' AS matchcode,
			'' AS eventdate,
			0 AS leagueid,
			GETDATE() AS DATETIME,
			CONVERT(BIT,0) AS IsNeutral,
			''  AS GameEvent,
			b.bettype,
			b.odds,  
			b.OddsType, 
			b.transdate,
			b.bettype,
			b.transid,
			b.refno,
			'' AS betteam,
			'' AS betcheck,
			0 AS hdp1,
			0 AS hdp2,
			'' AS betfrom,
			0 AS livehomescore,
			0 AS liveawayscore,
			0 AS liveindicator,
			cr.username creator,
			b.stake,     
			b.status,
			b.winlost - actual_stake as winlost,
			b.playercomm as comm,      
			b.currency,
			b.betid
	FROM	bettrans b WITH(NOLOCK) 
			INNER JOIN CustDB.dbo.customer AS cr with (NOLOCK) ON cr.custid = b.creator
	WHERE	b.transid IN (SELECT TransID FROM @tmpListTransID WHERE bettype = 9)
			AND @isExistParlay = 1 
	UNION ALL 
	SELECT	m.teamid AS homeid,
			0 AS awayid,
			m.matchcode,
			m.eventdate,
			m.leagueid,
			GETDATE() AS DATETIME,
			CONVERT(BIT,0) AS IsNeutral,
			'' AS GameEvent,				-- N/A 
			b.bettype,
			b.odds,  
			b.OddsType, 
			b.transdate,
			b.bettype,
			b.transid,
			b.refno,
			b.betteam,
			b.betcheck,
			b.hdp1,
			b.hdp2,
			b.betfrom,
			b.livehomescore,
			b.liveawayscore,
			b.liveindicator,
			cr.username creator,
			b.stake,     
			b.status,
			b.winlost - actual_stake as winlost,
			b.playercomm as comm,      
			b.currency,
			b.betid
	FROM
			bettrans b WITH (NOLOCK)
			INNER JOIN Outright m WITH (NOLOCK) ON b.matchID = m.orid
			INNER JOIN CustDB.dbo.customer cr WITH (NOLOCK) ON cr.custid = b.creator
	WHERE	b.transid IN (SELECT TransID FROM @tmpListTransID WHERE bettype = 10)
			AND @isExistOutright = 1 
		
			
	--check for live casino
	IF (@isExistMatch = 1 AND EXISTS(SELECT TOP 1 1 FROM @tmpListTransID WHERE Bettype BETWEEN 1101 AND 1199))
	BEGIN		
		SELECT 	 t.TransID 
				,bg.odds
				,bg.stake
				,bg.STATUS
				,bg.bettype
				,bg.betteam
				,bg.refno
		FROM	bettransG bg WITH (NOLOCK)
				INNER JOIN @tmpListTransID t ON bg.refno = t.Refno 
		WHERE	t.Bettype  BETWEEN 1101 AND 1199
	END
	ELSE	--- Get structure for web 
	BEGIN
		SELECT	 0 AS TransID 
				,0 AS Odds
				,0 AS Stake
				,NULL AS Status 
				,0 AS Bettype
				,NULL AS betteam 
				,0 AS refno
	END
	
	INSERT INTO zzzbettrans
		(transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator , refno, winlostdate, betfrom, betcheck, checktime, matchid, bettype)
	SELECT	transid, custid, CURRENT_TIMESTAMP, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator , refno, winlostdate, betfrom, betcheck, checktime, matchid, bettype
	FROM	bettrans with (nolock)
	WHERE	transid IN (SELECT TransID FROM @tmpListTransID WHERE Bettype NOT IN (901,902,903))  
	
	--Back up BetTrade's subtickets (901,902,903)  
	INSERT INTO zzzbettrans
		(transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator , refno, winlostdate, betfrom, betcheck, checktime, matchid, bettype)
	SELECT	sb.transid, sb.custid, CURRENT_TIMESTAMP, sb.oddsid, sb.hdp1, sb.hdp2, sb.odds, sb.awinlost, sb.status, sb.winlost, sb.livehomescore, sb.liveawayscore, sb.liveindicator, sb.betteam, sb.creator , sb.refno, sb.winlostdate, sb.betfrom, sb.betcheck, sb.checktime, sb.matchid, sb.bettype
	FROM	bettrans b with (nolock)
		INNER JOIN bettrans sb WITH (nolock) ON b.transid = sb.refno AND b.matchid = sb.matchid AND sb.BetType IN (901,902,903)
	WHERE	b.transid IN (SELECT TransID FROM @tmpListTransID WHERE Bettype NOT IN (901,902,903)) 
	
	UPDATE 
		bettrans WITH (ROWLOCK, UPDLOCK)
	SET [status]			= 'Void'     
	WHERE
		transid IN (SELECT TransID FROM @tmpListTransID WHERE Bettype NOT IN (901,902,903))
		
	-- Update BetTrade's subtickets (901,902,903) 
	UPDATE 
		bettrans WITH (ROWLOCK, UPDLOCK)
	SET [status]			= 'Void'      
	WHERE
		refno IN (SELECT TransID FROM @tmpListTransID WHERE Bettype NOT IN (901,902,903))
		AND Bettype IN (901, 902, 903)

	
	-- Control concurrency problems - start		
		--Get error TransID
		INSERT INTO @ErrorTransID(TransID)
		SELECT DISTINCT t.TransID
		FROM @tmpListTransID t
			INNER JOIN zzzbettrans z WITH(NOLOCK) ON t.TransID = z.refno AND z.Bettype = 901
			LEFT JOIN @tmpListTransID t2 ON t2.TransID = z.TransID
		WHERE t2.TransID IS NULL
		UNION
		SELECT DISTINCT t.TransID
		FROM @tmpListTransID t
			INNER JOIN bettrans b WITH(NOLOCK) ON t.TransID = b.TransID AND b.betdaqid = 0
			LEFT JOIN zzzbettrans z WITH(NOLOCK) ON t.TransID = z.refno AND z.Bettype = 901
		WHERE z.TransID IS NULL
		UNION
		SELECT DISTINCT t.TransID
		FROM @tmpListTransID t
			INNER JOIN bettrans b WITH(NOLOCK) ON t.TransID = b.TransID AND b.betdaqid = 0
			INNER JOIN zzzbettrans z WITH(NOLOCK) ON t.TransID = z.TransID
		WHERE z.CustID <> b.CustID
		
		-- Rollback BetTrade's main tickets
		UPDATE  b
		SET b.status	= z.Status
		FROM bettrans b WITH (ROWLOCK, UPDLOCK) 
			INNER JOIN zzzbettrans z  WITH (ROWLOCK, UPDLOCK) ON b.TransID = z.TransID   
		WHERE
			b.TransID IN (SELECT transid FROM @ErrorTransID)
			
		-- Rollback BetTrade's subtickets (901,902,903) 
		UPDATE  b
		SET b.status	= z.Status
		FROM bettrans b WITH (ROWLOCK, UPDLOCK) 
			INNER JOIN zzzbettrans z  WITH (ROWLOCK, UPDLOCK) ON b.TransID = z.TransID   
		WHERE
			b.refno IN (SELECT transid FROM @ErrorTransID)
			AND b.Bettype IN (901, 902, 903)
		
		-- DELETE balance/backup/delete data	
		DELETE FROM zzzbettrans 
		WHERE TransID IN (SELECT transid FROM @ErrorTransID)
			OR (Refno IN (SELECT transid FROM @ErrorTransID) AND Bettype IN(901,902,903))
			
		DELETE db
		FROM @tmpListTransID db
		INNER JOIN bettrans b WITH (ROWLOCK, UPDLOCK) ON db.TransID = b.TransID
		WHERE db.TransID IN (SELECT transid FROM @ErrorTransID)
			OR 
				( b.refno IN (SELECT transid FROM @ErrorTransID) AND b.Bettype IN (901,902,903))
	
	-- Control concurrency problems - end
	
	INSERT INTO #BeforeUpd (custid, balance)
	SELECT	b.custid, SUM (b.winlost - b.actual_stake + b.playercomm) balance
	FROM	bettrans b WITH (NOLOCK)
	WHERE	b.transid IN (SELECT transid FROM @tmpListTransID)
	GROUP BY b.CustID
	
	--update bettrans
	UPDATE	bettrans WITH (UPDLOCK,ROWLOCK) 
	SET		winlost=actual_stake,ruben=1,statuswinlost=6, creator = @UserID,
			awinlost = 0, mwinlost = 0, swinlost = 0, playercomm = 0, comm  = 0, acomm = 0, scomm = 0,statusID = 102
	WHERE transid IN (SELECT TransID FROM @tmpListTransID WHERE bettype NOT IN (901,902,903)) 
	
	--update bettrans
	UPDATE	bettrans WITH (UPDLOCK,ROWLOCK) 
	SET		winlost=actual_stake,ruben=1,statuswinlost=6, creator = @UserID,
			awinlost = 0, mwinlost = 0, swinlost = 0, playercomm = 0, comm  = 0, acomm = 0, scomm = 0,statusID = 102
	WHERE refno IN (SELECT TransID FROM @tmpListTransID WHERE Bettype NOT IN (901,902,903))
		AND Bettype IN (901, 902, 903)
		
	
	--Update BetTrade selling information			
		-- Update BetTradeSelling
		UPDATE [dbo].[BetTradeSelling] WITH (ROWLOCK, UPDLOCK)
		SET
			[Status] = 'Cancel',
			[ChangeDate]  = GETDATE()
		WHERE
			TicketID IN (SELECT transid FROM @tmpListTransID WHERE Bettype NOT IN (901,902,903))
			
		-- Insert BetTradeSellingCancel
		INSERT INTO [dbo].[BetTradeSellingCancelled]
			   ([TicketID]
			   ,[Remark]
			   ,[BTBuyBack]
			   ,[BTCommission]
			   ,[AfterBalance]
			   ,[Owner]
			   ,[Cancelled]
			   ,[ChangeDate]
			   ,[CreateDate])
		 SELECT zb.refno
				, 'SB void ticket due to ' + @Reason
				,zb.Stake
				,0
				,0
				,'SB'
				,1
				,GETDATE()
				,GETDATE()
		 FROM @tmpListTransID t
		 INNER JOIN zzzbettrans zb WITH(NOLOCK)
			ON zb.Refno = t.TransID AND zb.BetType = 901
		 LEFT JOIN [dbo].[BetTradeSellingCancelled] c WITH(NOLOCK) 
			ON c.[TicketID] = zb.TransID
		WHERE c.[BTBuyBack] IS NULL AND t.Bettype NOT IN(901,902,903)
		
		--Update
		UPDATE main
		SET
			[Remark] = 'SB void ticket due to ' + @Reason,
			[BTBuyBack] = zb.Stake,
			[BTCommission] = 0,
			[Owner] = 'SB',
			[Cancelled] = 1,
			[ChangeDate] = GETDATE(),
			[CreateDate] = GETDATE(),
			AfterBalance = (SELECT ISNULL(SUM(CASE 
								WHEN ruben = 1
									THEN winlost - actual_stake + playercomm
								ELSE 0
								END), 0)
								FROM dbo.bettrans WITH (NOLOCK)
								WHERE custid = zb.custid
								)
		FROM [dbo].[BetTradeSellingCancelled] main WITH (ROWLOCK, UPDLOCK)
		INNER JOIN zzzbettrans zb WITH(NOLOCK)
			ON zb.Refno = main.[TicketID] AND zb.BetType = 901	
		WHERE main.[TicketID] IN (SELECT transid FROM @tmpListTransID WHERE Bettype NOT IN(901,902,903))
		
	
	--Get data after update
	INSERT INTO #AfterUpd (custid, balance)
	SELECT	b.custid, SUM (b.winlost - b.actual_stake + b.playercomm) balance
	FROM	bettrans b WITH (NOLOCK)
	WHERE	b.transid IN (SELECT transid FROM @tmpListTransID)
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
	
	DROP TABLE #BeforeUpd
	DROP TABLE #AfterUpd
	
		
	--update balance debit
	IF @balance > 0
	BEGIN			
		EXEC Dot_BalanceUpdDebit @custid = @custid, @balance = @balance
	END 
		
	--update balance debit	
	IF @balance < 0
	BEGIN
		SELECT @balance = ABS(@balance)
		EXEC Dot_BalanceUpdCredit @custid = @custid, @balance = @balance
	END		
			
	SELECT @LogData = 'Delete transaction for custid:' +cast(@custid as varchar(10))+' transid:' + cast(@strTransID as varchar(8000))+ ' by_login:' + @username + 'IP:' + cast(@IP as varchar(15)) + ' reason: ' + @reason
	EXEC WriteLog_UserLog @UserID = @UserID, @Doing = @LogData
		
	-----
	IF (@isExistMatch = 1 OR @isExistOutright = 1)
	BEGIN
		DELETE  t
		FROM	dbo.TempVariableNumber t WITH (ROWLOCK,UPDLOCK)
				INNER JOIN @tmpListTransID l ON t.KeyID = l.KeyID AND t.KeyValue = l.MatchID	
		WHERE	l.Bettype <> 9 
	END
	IF (@isExistParlay = 1)
	BEGIN
		UPDATE	systemSettings WITH (ROWLOCK,UPDLOCK)
		SET		VValue = '0'
		WHERE	VName = 'isCalculatingParlay'	
	END 
	
	--Return Error TransIDs
	SELECT * FROM @ErrorTransID
END
GO
GRANT EXECUTE ON [dbo].[NAP_BettransSpecialDelBetID_Del] TO [bodbAdminNet] AS [dbo]