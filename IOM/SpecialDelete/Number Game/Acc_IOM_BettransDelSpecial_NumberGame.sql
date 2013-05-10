ALTER PROCEDURE [dbo].[Acc_IOM_BettransDelSpecial_NumberGame]
    @matchid		INT,
    @DelOption		TINYINT			= 0,
    @f_transid		BIGINT,
    @t_transid		BIGINT,
    @transids		VARCHAR(4000)	= '',-- for custom delete (Deposit bets)
    @Dead			VARCHAR(100)	= '', -- bettype for dead-ball
	@Live			VARCHAR(100)	= '', -- bettype for live-ball
    @UserName		NVARCHAR(50),
    @UserPwd		NVARCHAR(50),
    @UserID			INT,
    @ErrMsg			NVARCHAR(200)	= '' OUTPUT,
    @ErrCode		INT				= 0 OUTPUT,
    @liveindicator	SMALLINT		= 0,
    @IP				VARCHAR(15)		= '',
    
    @DelOption_BD	TINYINT			= 0,  --unused
    @transids_BD	VARCHAR(4000)	= '', --unused
    @DelOption_12EU TINYINT			= 0,  --unused
    @transids_12EU	VARCHAR(4000)	= '', --unused 
    @DelOption_MHC	TINYINT			= 0,  --unused
    @transids_MHC	VARCHAR(4000)	= ''  --unused   
AS
/*
Created by: Elodie
Task : SP delete bet (Number Game)
DB: DBTRANS.bodb02
Original: Acc_BettransDelSpecial_NumberGame

Revisions:

Param's Explanation: Special bet delete option
    @@DelOption = 1: Delete All 
    @@DelOption = 2: Optional Delete (remove DepositBets with option)   
*/
BEGIN
	SET NOCOUNT ON

	--Check permission for account site: @phuc20080213
	EXEC db03.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[SpecialDeleteNumberGame]',@ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
	IF @ErrCode <> 0
		RETURN
	--end

	--Check settled Date
	DECLARE @eventdate Datetime 
	SELECT	@eventdate = eventdate
	FROM	match WITH (NOLOCK)
	WHERE	matchid = @matchid
			
	EXEC dbo.Acc_CheckSettledDate @winlostdate = @eventdate, @UserID = @UserID, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT
	If @ErrCode <> 0
		RETURN
	--end
	
	DECLARE @LogData NVARCHAR(500)
	SELECT	@ErrCode = 0

	IF NOT EXISTS (	SELECT 1
					FROM customer WITH (NOLOCK)
					WHERE   customer.userpwd = @UserPwd
						and custid = @UserID
						and roleid>=5)
	BEGIN
		SELECT @LogData ='fail to delete bet for matchid ' + CONVERT(VARCHAR(20), @matchid) + ' from ' + CONVERT(VARCHAR(20), @f_transid) + ' to ' + CONVERT(VARCHAR(20), @t_transid)
		EXEC WriteLog_UserLog @UserID = @UserID, @Doing = @LogData

		SELECT @ErrMsg = 'Sorry. You can not process delete bet due to either wrong password or insufficient permission!', @ErrCode = 101   
		RETURN
	END

	CREATE TABLE #BetDelete (transid BIGINT, custid INT, recommend INT, mrecommend INT, srecommend INT, betfrom NVARCHAR(1),statusID INT)
	
	DECLARE @DepositCust TABLE (custid INT, username VARCHAR(30))
	DECLARE @UUSCust TABLE (custid INT, username VARCHAR(30))
	DECLARE @RealCurrCust TABLE (custid INT, username VARCHAR(30))
	DECLARE @Status TABLE (statusID TINYINT)
	DECLARE @MasterMHC TABLE (custid INT)

	--Only steven can delete bet of "complete" match
	IF(@username = 'steven' OR @username = 'joe')
	BEGIN	
		INSERT INTO @Status
		SELECT 102 UNION ALL --Void
		SELECT 101 UNION ALL --Reject
		SELECT 121			 --Dummy ticket
	END
	ELSE   
	BEGIN -- Other Admin
		INSERT INTO @Status
		SELECT 102 UNION ALL --Void
		SELECT 101 UNION ALL --Reject
		SELECT 121 UNION ALL --Dummy ticket
		SELECT 112 UNION ALL --Won
		SELECT 113 UNION ALL --Lose
		SELECT 111           --Draw	
	END
	
	INSERT INTO #BetDelete (transid, custid, recommend, mrecommend, srecommend, betfrom, statusID)			
		SELECT DISTINCT transid, custid, recommend, mrecommend, srecommend, betfrom, statusID
		FROM bettrans b WITH (nolock)
		WHERE
			b.matchid=@matchid 						
			AND
			b.transid BETWEEN @f_transid AND @t_transid						
			AND
			(   
				(
					b.bettype IN (SELECT CONVERT(INT,val) FROM dbo.strSplit(@Dead,'^'))
					AND 
					b.liveindicator = 0 
				)
				 OR
				(
					b.bettype IN (SELECT CONVERT(INT,val) FROM dbo.strSplit(@Live,'^'))
					AND 
					b.liveindicator = 1 
				)
			) 							


	IF EXISTS (SELECT 1 FROM #BetDelete WHERE statusID IN (111,112,113) AND @username NOT IN ('steven','joe'))
	BEGIN
		SELECT @ErrCode = 100, @ErrMsg = 'You can only delete the unsettled or refunded tickets.'
		RETURN
	END
	ELSE
	BEGIN
		DELETE FROM #BetDelete WHERE statusID IN (SELECT * FROM @Status)
	END

	IF NOT (@DelOption = 0 OR (@DelOption=2 AND @transids=''))
		INSERT INTO @DepositCust (custid, username)
			SELECT INF.custid, INF.username 
			FROM custinfo INF WITH(nolock) 
				INNER JOIN #BetDelete BD ON INF.Custid = BD.Custid 
			WHERE INF.srecommend in ( SELECT custid FROM Dep_CustSuper WITH (NOLOCK) WHERE site IN ('Alog'))
					AND INF.roleid = 1	

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
			
	--FOR Delete Deposit
	IF @DelOption = 0 or (@DelOption=2 and @transids='')
	BEGIN
		DELETE FROM #BetDelete
	END
	IF @DelOption = 2 and  @transids <> ''
	BEGIN
		DELETE FROM #BetDelete
		WHERE transid NOT IN (SELECT CONVERT(BIGINT, val) FROM dbo.strSplit(@transids, ','))
	END

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
		AND b.bettype in (SELECT CONVERT(INT,val) FROM dbo.strSplit(@Dead + '^' + @Live,'^'))
		AND b.matchid = @matchid	 

	CREATE TABLE #BeforeUpd (
			custid		 INT,
			balance		 MONEY)
		
	CREATE TABLE #AfterUpd(
				custid		 INT,
				balance		 MONEY)
				
	--Get data before update
	INSERT INTO #BeforeUpd (custid, balance)
	SELECT	b.custid, SUM (b.winlost - b.actual_stake + b.playercomm) balance
	FROM	bettrans b WITH (NOLOCK)
	WHERE	b.transid in (SELECT transid FROM #BetDelete)
	GROUP BY b.CustID

	-- STEP 2 : Update
	--    begin tran
			UPDATE 
				bettrans WITH (ROWLOCK, UPDLOCK)
			SET winlost=actual_stake,ruben=1,statuswinlost=6, status = 'Void', creator = @UserID,
				awinlost = 0, mwinlost = 0, swinlost = 0, playercomm = 0, comm  = 0, acomm = 0, scomm = 0, statusID = 102       
			WHERE
				transid in (SELECT transid FROM #BetDelete)

	--Get data after update
	INSERT INTO #AfterUpd (custid, balance)
	SELECT	b.custid, SUM (b.winlost - b.actual_stake + b.playercomm) balance
	FROM	bettrans b WITH (NOLOCK)
	WHERE	b.transid in (SELECT transid FROM #BetDelete)
	GROUP BY b.CustID

	---insert data into pending balance table 
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


	SELECT @LogData ='delete bet for matchid ' + CONVERT(VARCHAR(20), @matchid) + ' from ' + CONVERT(VARCHAR(20), @f_transid) + ' to ' + CONVERT(VARCHAR(20), @t_transid) + ' IP=' + COALESCE(CAST(@IP AS VARCHAR(15)),SPACE(1))
	EXEC WriteLog_UserLog @UserID = @UserID, @Doing = @LogData

	--after delete, return all deleted deposit bets with additional information for mailing
	IF exists(SELECT 1 FROM #BetDelete INNER join bettrans b ON #BetDelete.transid = b.transid)
	BEGIN
		IF EXISTS(SELECT CONVERT(INT,val) FROM dbo.strSplit(@Dead + '^' + @Live,'^') WHERE CONVERT(INT, val) = 10)  --@bettype = 10
		BEGIN
			SELECT
				MATCH.teamid AS homeid,
				0 AS awayid,
				MATCH.matchcode,
				MATCH.eventdate,
				MATCH.leagueid,
				GETDATE() AS DATETIME,
				CONVERT(BIT,0) AS IsNeutral
			FROM
				Outright AS MATCH WITH (NOLOCK)
			WHERE 
				MATCH.orid = @matchID
		END   
		ELSE
		BEGIN
			SELECT
				MATCH.homeid,
				MATCH.awayid,
				MATCH.matchcode,
				MATCH.eventdate,
				MATCH.leagueid,
				GETDATE() AS DATETIME,
				isnull(MATCH.isNeutral, CONVERT(BIT,0)) AS IsNeutral
			FROM
				MATCH WITH (NOLOCK)
			WHERE 
				MATCH.matchid = @matchID
		END
		   
		SELECT
			customer.username,
			customer.username2,
			b.odds,  
			b.OddsType, 
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
			stake AS StakePositiontaking,           
			b.currency,
			ag.site,
			b.liveindicator
		FROM
			bettrans b WITH (NOLOCK)
			INNER JOIN customer  WITH (NOLOCK) ON customer.custid=b.custid
			INNER JOIN customer cr WITH (NOLOCK) ON cr.custid = b.creator
			INNER JOIN customer ag WITH (NOLOCK) ON customer.recommend = ag.custid
		WHERE b.transid IN(SELECT transid FROM #BetDelete)
				and customer.custid IN (SELECT custid FROM @DepositCust)		  
		ORDER BY transid  
	END	

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

-----Begin : Send mail when delete real currencies and creator username like 'dba%' or 'pgm%' or 'vndbateam',  'VnQaTeam'/ OR Currency is UUS
	IF exists(
	SELECT 1 FROM #BetDelete INNER join bettrans b ON #BetDelete.transid = b.transid
	WHERE	#BetDelete.custid IN (SELECT custid FROM @UUSCust)
			or #BetDelete.custid IN (SELECT custid FROM @RealCurrCust)
	    	)
	BEGIN
		SELECT
			customer.username,
			customer.username2,
			b.odds,  
			b.OddsType, 
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
	END
	-----End : Send mail when delete real currencies and creator username like 'dba%' or 'pgm%' or 'vndbateam',  'VnQaTeam'/ OR Currency is UUS

	DROP TABLE #BetDelete
	DROP TABLE #BeforeUpd
	DROP TABLE #AfterUpd
END

GO
GRANT EXECUTE ON [dbo].[Acc_IOM_BettransDelSpecial_NumberGame] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_IOM_BettransDelSpecial_NumberGame] TO [VNTeam] 