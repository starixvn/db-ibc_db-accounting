ALTER PROCEDURE [NAP_BettransSpecialDelBetID_Del]
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
		
	Param's Explanation: 
*/
BEGIN 
	SET NOCOUNT ON

	--Check permission for account site
	EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[DeleteBets]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
	If @ErrCode <> 0
		RETURN

	DECLARE @LogData		NVARCHAR(500)	
			,@isITAdmin		BIT

	SELECT	@isITAdmin		= 0 

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

	If NOT EXISTS (select 1 from CustDB.dbo.customer c with (nolock) where userpwd = @password and custid = @userid and roleid >= 5)
	BEGIN
		SELECT	 @ErrMsg = 'Wrong username/password or You do not have permission to delete this bet!!'
				,@ErrCode = 101

		SELECT	@LogData = 'Try to delete transaction for custid: ' + cast(@UserID AS VARCHAR(10)) + ' betlist: ' + cast(@strtransid AS VARCHAR(8000)) + ' - Username: ' + @username + ' - reason: ' + @reason

		EXEC WriteLog_UserLog @UserID = @UserID ,@Doing = @LogData
		RETURN
	END

	DECLARE @tmpListTransID TABLE (
		 TransID		BIGINT
		,MatchID		INT
		,Bettype		INT
		,Refno			BIGINT
		,Betfrom		NVARCHAR(10)
		,KeyID			INT 
	)

	INSERT INTO @tmpListTransID(
		 TransID
		,MatchID
		,Bettype
		,Refno
		,Betfrom
		,KeyID
	)
	SELECT	 TransID
			,MatchID
			,Bettype
			,Refno
			,Betfrom
			,CASE Bettype WHEN 9 THEN -1	-- isCalculatingParlay in SystemSettings OR 1 (Single match)
						  WHEN 10 THEN 2    -- Outright 
						  ELSE 1 END		-- SB, NG, LiveCS 
	FROM	Bettrans WITH (NOLOCK)
	WHERE	TransID IN (SELECT CONVERT(BIGINT,Val) FROM dbo.strSplit(@strTransID,','))


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

	SELECT	@winlostdate	= MIN(winlostdate)
			,@CustID		= MIN(CustID)
			,@Balance		= SUM(winlost - actual_stake + playercomm) 
			,@isExistMatch	= MAX(CASE WHEN Bettype NOT IN (9,10) THEN 1 ELSE 0 END)
			,@isExistParlay = MAX(CASE WHEN Bettype = 9 THEN 1 ELSE 0 END)
			,@isExistOutright = MAX(CASE WHEN Bettype = 10 THEN 1 ELSE 0 END)
	FROM	Bettrans WITH (NOLOCK)
	WHERE	TransID IN (SELECT TransID FROM @tmpListTransID)

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
		
		))
		BEGIN
			SELECT  @ErrCode = 206,
					@ErrMsg = 'A match is being calculated or some tickets of this match are being deleted, please wait a few seconds until the on-going process is completed and try again.'
			RETURN
		END
		ELSE
		BEGIN
			INSERT INTO dbo.TempVariableNumber (KeyID, KeyValue) 
			SELECT	KeyID, MatchID 
			FROM	@tmpListTransID
			WHERE	Bettype <> 9  
		END
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

	SELECT	@EmailGroup = CASE	WHEN @CustUsername = '12EU' THEN 'Group12EU'
								WHEN @isCustDeposit = 1 THEN 'GroupDeposit' 
								WHEN @Recommend = 11196380 THEN 'GroupFoobet'		-- FB
								WHEN @CustID IN (1077687, 2331, 115770, 15523642) THEN 'GroupBetfair'  -- Betfair: BFOS, BF, ITibc102, BF3
								WHEN @CustID = 13423967 THEN 'GroupOneExchange'  --1E
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
				WHERE	Bettype <> 9
			)

	SELECT	@totalbalance = SUM(winlost - actual_stake + playercomm)
	FROM	bettrans with (nolock)
	WHERE	custid = @CustID
		
	SELECT  @isNegativeBalance = CASE WHEN @Balance > 0 AND (credit + @totalbalance - @Balance) < 0 THEN 1 ELSE 0 END
	FROM	CustDB.dbo.custinfo WITH(NOLOCK)
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
			b.currency
	FROM	bettrans b WITH (NOLOCK)
			INNER JOIN Match m WITH (NOLOCK) ON b.matchID = m.matchid
			INNER JOIN CustDB.dbo.customer cr WITH (NOLOCK) ON cr.custid = b.creator
	WHERE	b.transid IN (SELECT TransID FROM @tmpListTransID WHERE bettype NOT IN (10,9))
			AND @isExistMatch = 1 
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
			b.currency
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
			b.currency
	FROM
			bettrans b WITH (NOLOCK)
			INNER JOIN Outright m WITH (NOLOCK) ON b.matchID = m.orid
			INNER JOIN CustDB.dbo.customer cr WITH (NOLOCK) ON cr.custid = b.creator
	WHERE	b.transid IN (SELECT TransID FROM @tmpListTransID WHERE bettype = 10)
			AND @isExistOutright = 1 
		
			
	--check for live casino
	IF (@isExistMatch = 1 AND EXISTS(SELECT TOP 1 1 FROM @tmpListTransID WHERE Bettype BETWEEN 1101 AND 1102))
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
		WHERE	t.Bettype  BETWEEN 1101 AND 1102 
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
			
	---- Mix Parlay 
	--IF(@isExistParlay =1)
	--BEGIN
	--	SELECT	bm.transid,
	--			bm.bettype,
	--			bm.betteam,
	--			bm.odds,
	--			bm.hdp1,
	--			bm.hdp2,
	--			bm.livehomescore,
	--			bm.liveawayscore,
	--			bm.liveindicator,
	--			m.matchid,
	--			m.homeid,
	--			m.awayid,
	--			m.leagueid,
	--			m.sporttype,	
	--			isnull(isNeutral, CONVERT(BIT,0)) AS IsNeutral,
	--			bm.refno	
	--	FROM	bettransm bm WITH(NOLOCK)
	--			INNER JOIN match m WITH(NOLOCK) ON bm.matchid = m.matchid
	--	WHERE	bm.refno IN (SELECT Refno FROM @tmpListTransID WHERE bettype = 9)
	--	UNION ALL 
	--	SELECT	bm.transid,
	--			bm.bettype,
	--			bm.betteam,
	--			bm.odds,
	--			bm.hdp1,
	--			bm.hdp2,
	--			bm.livehomescore,
	--			bm.liveawayscore,
	--			bm.liveindicator,
	--			m.matchid,
	--			m.homeid,
	--			m.awayid,
	--			m.leagueid,
	--			m.sporttype,	
	--			isnull(isNeutral, CONVERT(BIT,0)) AS IsNeutral,
	--			bm.refno	
	--	FROM	bettransm14 bm WITH(NOLOCK)
	--			INNER JOIN match14 m WITH(NOLOCK) ON bm.matchid = m.matchid
	--	WHERE	bm.refno IN (SELECT Refno FROM @tmpListTransID WHERE bettype = 9)
	--	ORDER BY bm.transid
	--END

	INSERT INTO zzzbettrans
		(transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator , refno, winlostdate, betfrom, betcheck, checktime, matchid, bettype)
	SELECT	transid, custid, CURRENT_TIMESTAMP, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator , refno, winlostdate, betfrom, betcheck, checktime, matchid, bettype
	FROM	bettrans with (nolock)
	WHERE	transid IN (SELECT TransID FROM @tmpListTransID)  

	--update balance debit
	IF @balance > 0
	BEGIN			
		EXEC Dot_BalanceUpdDebit @custid = @custid, @balance = @balance
	END
	
	--update bettrans
	UPDATE	bettrans WITH (UPDLOCK,ROWLOCK) 
	SET		winlost=actual_stake,ruben=1,statuswinlost=6, status = 'Void', creator = @UserID,
			awinlost = 0, mwinlost = 0, swinlost = 0, playercomm = 0, comm  = 0, acomm = 0, scomm = 0,statusID = 102
	WHERE transid IN (SELECT TransID FROM @tmpListTransID)  
		
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
END 
GO
GRANT EXECUTE ON [dbo].[NAP_BettransSpecialDelBetID_Del] TO [bodbAdminNet] AS [dbo]
GO
