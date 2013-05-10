

alter PROCEDURE [dbo].[Acc_BettransDelSpecial_LiveCS_xtest]
    @matchid		INT,    
    @f_transid		BIGINT,
    @t_transid		BIGINT,
    @transids		VARCHAR(4000)	= '',   
    @UserName		NVARCHAR(50),
    @UserPwd		NVARCHAR(50),
    @UserID			INT,
	@IP				VARCHAR(15)		= '',
    @ErrMsg			NVARCHAR(200)	= '' OUTPUT,
    @ErrCode		INT				= 0 OUTPUT
AS
/*
	Created by: 20120208@Lukas
	Task : SP delete bet (Live Casino)
	DB: DBTRANS.bodb02
		(not locate on DBTP)
	Revisions:
		- 20120703@Sophia: Remove function f_GetOddsByBettype, f_ShowOddsByBettype for odds, Oddstype 
		- 20120914@Sophia: Add table TempVariableNumber to check and not to allow attempt to proceed on same game while it's still not finish
		- 20120927@Lukas: put servername to control SP execution (CCS)
	Param's Explanation: Special bet delete option

*/
BEGIN
	SET NOCOUNT ON
	
	
	DECLARE @LogData NVARCHAR(500)
	SELECT	@ErrCode = 0

	---- check and not allow attempt to delete same game while it's still not finish
	IF EXISTS (SELECT 1 FROM dbo.TempVariableNumber WHERE KeyID = 1 AND KeyValue = @matchid)
	BEGIN
		SELECT  @ErrCode = 101,
				@ErrMsg = 'This match is being calculated or some tickets of this match are being deleted, please wait a few seconds until the on-going process is completed and try again.'
		RETURN
	END

	INSERT INTO dbo.TempVariableNumber (KeyID, KeyValue) VALUES (1, @matchid)
	-----------	
	
	CREATE TABLE #BetDelete (transid BIGINT, custid INT, recommend INT, mrecommend INT, srecommend INT, betfrom NVARCHAR(1),statusID INT)
	DECLARE @UUSCust TABLE (custid INT, username VARCHAR(30))
	DECLARE @RealCurrCust TABLE (custid INT, username VARCHAR(30))

	DECLARE @Status TABLE (statusID TINYINT)
	
	/*
	INSERT INTO @Status
	SELECT 'Void' UNION ALL
	SELECT 'Reject' UNION ALL
	SELECT 'WON' UNION ALL
	SELECT 'LOSE' UNION ALL
	SELECT 'DRAW'
	*/
	INSERT INTO @Status
	SELECT 102 UNION ALL
	SELECT 101 UNION ALL
	SELECT 121 UNION ALL    ---- dummy ticket
	SELECT 112 UNION ALL
	SELECT 113 UNION ALL
	SELECT 111	
	
	
	INSERT INTO #BetDelete (transid, custid, recommend, mrecommend, srecommend, betfrom, statusID)			
			SELECT DISTINCT transid, custid, recommend, mrecommend, srecommend, betfrom, statusID
			FROM bettrans b WITH (nolock)
			WHERE
				b.matchid=@matchid 						
				AND
				b.transid BETWEEN @f_transid AND @t_transid						
				AND 
				b.bettype = 1101						


	IF EXISTS (SELECT 1 FROM #BetDelete WHERE statusID IN (0, 111,112,113))
	BEGIN
		SELECT @ErrCode = 100, @ErrMsg = 'You can only delete the refunded tickets.'
		
		DELETE FROM dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK)
		WHERE KeyID = 1 AND KeyValue = @matchid
		
		RETURN
	END
	ELSE
	BEGIN
		DELETE FROM #BetDelete WHERE statusID IN (SELECT * FROM @Status)
	END

	--INSERT UUS CUSTOMER
	Insert into @UUSCust(custid,username)
	SELECT INF.custid, INF.username 
	FROM custinfo INF (nolock) 
		INNER JOIN #BetDelete BD ON INF.Custid = BD.Custid 
		WHERE INF.srecommend IN(
				SELECT custid FROM customer (nolock) Where CURRENCY = 20 AND roleid = 4
			) AND INF.roleid = 1

	--INSERT CUSTOMER HAVE REAL CURRENCIES AND CREATE USERNAME LIKE 'dba%' or 'pgm%' or 'vndbateam',  'VnQaTeam'		
	INSERT INTO @RealCurrCust (CustID, username)
	SELECT		INF.custid, INF.username 
	FROM		custinfo INF WITH (NOLOCK) 
	INNER JOIN	#BetDelete BD ON INF.Custid = BD.Custid 
	WHERE		INF.srecommend IN( SELECT custid FROM customer WITH(NOLOCK) Where CURRENCY <> 20 AND roleid = 4)	
				AND INF.roleid = 1 
				AND ( @Username LIKE 'dba%' OR @Username LIKE 'pgm%' OR @Username ='vndbateam' OR @Username = 'vnQaTeam')	
			
	DELETE FROM #BetDelete
	WHERE transid NOT IN (SELECT CONVERT(BIGINT, val) FROM dbo.strSplit(@transids, ','))

	-- STEP 1 : BackUp
		INSERT INTO
			zzzbettrans
			(transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator , refno, winlostdate, betfrom, betcheck, checktime, matchid, bettype)
		SELECT
			 transid, custid, CURRENT_TIMESTAMP, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator , refno, winlostdate, betfrom, betcheck, checktime, matchid, bettype
		FROM
			bettrans b WITH (nolock)
		WHERE
			b.transid IN (SELECT transid FROM #BetDelete)
			AND b.bettype = 1101
			AND b.matchid = @matchid	 

	--- only refund tickets were deleted --> no need to update balance

	-- STEP 2 : Update
	--    begin tran
	UPDATE 
		bettrans WITH (ROWLOCK, UPDLOCK)
	SET winlost=actual_stake,ruben=1,statuswinlost=6, status = 'Void', creator = @UserID,
		awinlost = 0, mwinlost = 0, swinlost = 0, playercomm = 0, comm  = 0, acomm = 0, scomm = 0, statusID = 102       
	WHERE
		transid in (SELECT transid FROM #BetDelete)


	IF @@SERVERNAME IN ('DBTRANS','DB206')
	BEGIN
		SELECT @LogData ='delete bet for matchid ' + CONVERT(VARCHAR(20), @matchid) + ' from ' + CONVERT(VARCHAR(20), @f_transid) + ' to ' + CONVERT(VARCHAR(20), @t_transid) + ' IP=' + COALESCE(CAST(@IP AS VARCHAR(15)),SPACE(1))
		EXEC WriteLog_UserLog @UserID = @UserID, @Doing = @LogData
	END
	
	-- event info
	SELECT
		homeid,
		awayid,
		matchcode,
		eventdate,
		leagueid,
		betstatus,
		eventstatus,
		GETDATE() AS [DATETIME],
		0 IsNeutral,
		showtime AS GameEvent
	FROM
		match WITH (NOLOCK)
	WHERE 
		matchid = @matchID


	--- not offer deposit site yet
	SELECT
			b.transid,
			0 AS SubTransID,
			b.refno,
			b.username,
			b.custid,
			b.transdate,			
			'' as creator,	
			b.actual_stake as stake,
			b.stake as StakePositiontaking,
			b.winlost-b.actual_stake AS winlost,
			b.odds,   
			b.OddsType, 	
			b.bettype,
			b.status,
			b.spositiontaking,
			b.mpositiontaking,
			b.apositiontaking,				
			b.currency,			
			b.mrecommend,			
			--case when betfrom IN ('D', 'M', 'E') then 1 else 0 end as IsDeposit
			0 AS choice_bettype
			,0 as homeid
			,0 as awayid
			,b.hdp1 AS choice_hdp1
			,b.hdp2 AS choice_hdp2
			,b.odds AS choice_odds
			,b.betteam
			,b.livehomescore
			,b.liveawayscore
			,b.liveindicator
			,0 as leagueid
			,0 as sporttype
			,0 as isNeutral
			,b.matchID
			,'' as matchCode
			,'' as site
	FROM bettrans b WITH(NOLOCK)
	WHERE matchid = -1 AND custid = -1 AND bettype = -1 


	SELECT	transid,
			bd.custid, mem.UserName     AS CustUserName,
			bd.recommend, ag.UserName   AS AgUserName,
			bd.mrecommend, mag.UserName AS MagUserName,
			bd.srecommend, sag.Username AS SagUserName
	FROM #BetDelete bd (nolock)
			INNER JOIN custinfo mem (nolock) ON bd.custid     = mem.custid
			INNER JOIN custinfo ag  (nolock) ON bd.recommend  = ag.custid
			INNER JOIN custinfo mag (nolock) ON bd.mrecommend = mag.custid
			INNER JOIN custinfo sag (nolock) ON bd.srecommend = sag.custid


	----Begin : Send mail when delete real currencies and creator username like 'dba%' or 'pgm%' or 'vndbateam',  'VnQaTeam'/ OR Currency is UUS
	SELECT
		customer.username,
		customer.username2,
		odds,  
		OddsType, 
		b.transdate,
		b.bettype,
		b.transid AS refno,
		betteam,
		hdp1,
		hdp2,
		betfrom,
		livehomescore,
		liveawayscore,
		cr.username creator,
		b.status,
		b.spositiontaking,
		b.mpositiontaking,
		b.apositiontaking,
		b.actual_stake as stake,
		stake AS StakePositiontaking, 		          
		b.currency,
		ag.site,
		b.liveindicator
	FROM
		bettrans b WITH (NOLOCK)
		INNER JOIN customer  WITH (NOLOCK) ON customer.custid=b.custid
		INNER JOIN customer cr WITH (NOLOCK) ON cr.custid = b.creator
		INNER JOIN customer ag WITH (NOLOCK) ON customer.recommend = ag.custid
	WHERE	b.transid IN(SELECT transid FROM #BetDelete)
			AND ( customer.custid IN (SELECT custid FROM @UUSCust)
				  or customer.custid IN (SELECT custid FROM @RealCurrCust) 
			     )
	ORDER BY transid
	
	SELECT b.transid as refno, bg.odds, bg.stake, bg.status, bg.bettype, bg.betteam
	FROM bettransG bg WITH(NOLOCK)	
		INNER JOIN bettrans b WITH(NOLOCK) ON bg.refno = b.refno
	WHERE b.transid IN(SELECT transid FROM #BetDelete)	
	-----End : Send mail when delete real currencies and creator username like 'dba%' or 'pgm%' or 'vndbateam',  'VnQaTeam'/ OR Currency is UUS


	DROP TABLE #BetDelete	
	
	-----
	DELETE FROM dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK)
	WHERE KeyID = 1 AND KeyValue = @matchid	

END

GO
GRANT EXECUTE ON [Acc_BettransDelSpecial_LiveCS_xtest] TO bodbAdminNet


