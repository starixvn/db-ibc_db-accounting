ALTER PROCEDURE [dbo].[Acc_IOM_BettransDelSpecial]
    @matchid INT,
    @DelOption TINYINT = 0,
    @f_transid BIGINT,
    @t_transid BIGINT,
    @transids VARCHAR(4000) = '',-- for custom delete (Deposit bets)
    @bettypes VARCHAR(128) = '',
    @betteam1378 NVARCHAR(10),
    @betteam515 NVARCHAR(10),
    @betteam430 VARCHAR(120) = '',
    @betteam6 varchar(120) = '',
	@betteam14 varchar(120) = '',
	@betteam16 varchar(120) = '',
    @hdp SMALLMONEY,
    @UserName NVARCHAR(50),
    @UserPwd NVARCHAR(50),
    @UserID INT,
    @ErrMsg NVARCHAR(200) = '' OUTPUT,
    @ErrCode INT = 0 OUTPUT,
    @liveindicator SMALLINT = 0,
    @livehomescore smallint = NULL,
    @liveawayscore smallint = NULL,
    @FromTransdate Datetime = NULL,
	@ToTransdate Datetime = NULL,
	@IP VARCHAR(15) = '',
	@SAFilter tinyint = 0,
    @DelOption_BD TINYINT = 0,        --unused
    @transids_BD VARCHAR(4000) = '',  --unused
    @DelOption_12EU TINYINT = 0,      --unused
    @transids_12EU VARCHAR(4000) = '',--unused    
    @DelOption_MHC TINYINT = 0,       --unused  
    @transids_MHC VARCHAR(4000) = ''  --unused    
AS
/*
Created by: Elodie
Task : SP delete bet
DB: DBTRANS.bodb02
Original: Acc_BettransDelSpecial

Revisions:

   
Param's Explanation: Special bet delete option
	@@DelOption = 0: No Delete (need to remove normal bets out of #BetDelete)
    @@DelOption = 1: Delete All (no need to remove DepositBets out of #BetDelete)
    @@DelOption = 2: Optional Delete (remove DepositBets with option)

    - @SAFilter: 
      + 0: All tickets
      + 1: Normal tickets only
      + 2: SA tickets only
     
    -@liveindicator:
	 + 0: Dead
	 + 1: Live
	 + 2: All
*/
BEGIN
	SET NOCOUNT ON

	--Check permission for account site: @phuc20080213
	EXEC db03.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[SpecialDelete]',@ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
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
	SELECT @ErrCode = 0

	IF not exists (SELECT 1
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
	
	--Only steven can delete bet of "complete" match
	IF(@username = 'steven' OR @username = 'joe')
	BEGIN		
		INSERT INTO @Status
		SELECT 102 UNION ALL --Void
		SELECT 101           --Reject
	END
	ELSE   
	BEGIN -- Other Admin		
		INSERT INTO @Status
		SELECT 102 UNION ALL --Void
		SELECT 101 UNION ALL --Reject
		SELECT 112 UNION ALL --Won
		SELECT 113 UNION ALL --Lose
		SELECT 111           --Draw		
	END

------------------***** Insert all data into #BetDelete *****------------------
	--bettype <> 4
	INSERT INTO #BetDelete (transid, custid, recommend, mrecommend, srecommend, betfrom, statusID)   
	SELECT DISTINCT transid, custid, recommend, mrecommend, srecommend, betfrom, statusID
	FROM bettrans b WITH (nolock)
		INNER JOIN dbo.strSplit(@bettypes,'^') AS bt ON bt.val=b.bettype
	WHERE
		b.matchid=@matchid 
		AND b.transid between @f_transid and @t_transid
		AND CASE WHEN @liveindicator = 2 THEN @liveindicator ELSE b.liveindicator END = @liveindicator
		AND b.livehomescore = CASE WHEN @livehomescore IS NOT NULL AND @liveindicator = 1 THEN @livehomescore ELSE b.livehomescore END
		AND b.liveawayscore = CASE WHEN @liveawayscore IS NOT NULL AND @liveindicator = 1 THEN @liveawayscore ELSE b.liveawayscore END
		AND b.transdate BETWEEN CASE WHEN @FromTransdate IS NOT NULL AND @liveindicator = 1 THEN @FromTransdate ELSE b.transdate END 
						AND		CASE WHEN @ToTransdate IS NOT NULL AND @liveindicator = 1 THEN @ToTransdate ELSE b.transdate END 		
		and CASE
			WHEN b.bettype in (1,3,7,8,2,12) THEN CASE WHEN @betteam1378 = 'ALL' THEN betteam ELSE @betteam1378 END
			WHEN b.bettype in (5,15) THEN CASE WHEN @betteam515 = 'ALL' THEN betteam ELSE @betteam515 END               
			ELSE betteam 
		END = betteam    
		AND b.bettype NOT IN(4,6,14,16,30)
		AND CASE WHEN b.bettype in (1,3,7,8) THEN CASE
													WHEN @hdp = 9999 THEN 1
													WHEN @hdp = (hdp1 + hdp2) THEN 1
													ELSE 0
												  END
		ELSE 1 END = 1
		AND ISNULL(SecAcceptFlag,0) = CASE @SAFilter WHEN 0 then ISNULL(SecAcceptFlag,0) WHEN 1 THEN 0 WHEN 2 THEN 1 END
        
	--bettype = 4
	INSERT INTO #BetDelete (transid, custid, recommend, mrecommend, srecommend, betfrom, statusID)   
	SELECT DISTINCT transid, custid, recommend, mrecommend, srecommend, betfrom, statusID
	FROM bettrans b WITH (nolock)
		LEFT JOIN dbo.strSplit(@betteam430,'^') AS bt ON b.betteam=CONVERT(varchar(3),bt.val)
	WHERE
		b.matchid=@matchid and           
		b.transid between @f_transid and @t_transid
		AND CASE WHEN @liveindicator = 2 THEN @liveindicator ELSE b.liveindicator END = @liveindicator
		AND b.livehomescore = CASE WHEN @livehomescore IS NOT NULL AND @liveindicator = 1 THEN @livehomescore ELSE b.livehomescore END
		AND b.liveawayscore = CASE WHEN @liveawayscore IS NOT NULL AND @liveindicator = 1 THEN @liveawayscore ELSE b.liveawayscore END
		AND b.transdate BETWEEN CASE WHEN @FromTransdate IS NOT NULL AND @liveindicator = 1 THEN @FromTransdate ELSE b.transdate END 
						AND		CASE WHEN @ToTransdate IS NOT NULL AND @liveindicator = 1 THEN @ToTransdate ELSE b.transdate END 
		and b.bettype in (4,30)
		AND (@betteam430='All' OR bt.val IS NOT NULL)
		AND ISNULL(SecAcceptFlag,0) = CASE @SAFilter WHEN 0 then ISNULL(SecAcceptFlag,0) WHEN 1 THEN 0 WHEN 2 THEN 1 END
			
	INSERT INTO #BetDelete (transid, custid, recommend, mrecommend, srecommend, betfrom, statusID)   
	SELECT DISTINCT transid, custid, recommend, mrecommend, srecommend, betfrom, statusID
	FROM dbo.bettrans AS b WITH (nolock)
		LEFT JOIN dbo.strSplit(@betteam6,'^') AS bt ON bt.val=b.betteam
	WHERE
		b.matchid=@matchid and           
		b.transid between @f_transid and @t_transid		
		AND CASE WHEN @liveindicator = 2 THEN @liveindicator ELSE b.liveindicator END = @liveindicator
		AND b.livehomescore = CASE WHEN @livehomescore IS NOT NULL AND @liveindicator = 1 THEN @livehomescore ELSE b.livehomescore END
		AND b.liveawayscore = CASE WHEN @liveawayscore IS NOT NULL AND @liveindicator = 1 THEN @liveawayscore ELSE b.liveawayscore END	
		AND b.transdate BETWEEN CASE WHEN @FromTransdate IS NOT NULL AND @liveindicator = 1 THEN @FromTransdate ELSE b.transdate END 
						AND		CASE WHEN @ToTransdate IS NOT NULL AND @liveindicator = 1 THEN @ToTransdate ELSE b.transdate END 	
		and b.bettype = 6
		AND (@betteam6='All' OR bt.val IS NOT NULL)
		AND ISNULL(SecAcceptFlag,0) = CASE @SAFilter WHEN 0 then ISNULL(SecAcceptFlag,0) WHEN 1 THEN 0 WHEN 2 THEN 1 END		
	
	INSERT INTO #BetDelete (transid, custid, recommend, mrecommend, srecommend, betfrom, statusID)   
	SELECT DISTINCT transid, custid, recommend, mrecommend, srecommend, betfrom, statusID
	FROM bettrans b WITH (nolock)
		LEFT JOIN dbo.strSplit(@betteam14,'^') AS bt ON b.betteam=CONVERT(varchar(3),bt.val)
	WHERE
		b.matchid=@matchid and           
		b.transid between @f_transid and @t_transid
		AND CASE WHEN @liveindicator = 2 THEN @liveindicator ELSE b.liveindicator END = @liveindicator
		AND b.livehomescore = CASE WHEN @livehomescore IS NOT NULL AND @liveindicator = 1 THEN @livehomescore ELSE b.livehomescore END
		AND b.liveawayscore = CASE WHEN @liveawayscore IS NOT NULL AND @liveindicator = 1 THEN @liveawayscore ELSE b.liveawayscore END
		AND b.transdate BETWEEN CASE WHEN @FromTransdate IS NOT NULL AND @liveindicator = 1 THEN @FromTransdate ELSE b.transdate END 
						AND		CASE WHEN @ToTransdate IS NOT NULL AND @liveindicator = 1 THEN @ToTransdate ELSE b.transdate END 
		and b.bettype = 14
		AND (@betteam14='All' OR bt.val IS NOT NULL)
		AND ISNULL(SecAcceptFlag,0) = CASE @SAFilter WHEN 0 then ISNULL(SecAcceptFlag,0) WHEN 1 THEN 0 WHEN 2 THEN 1 END
					
	INSERT INTO #BetDelete (transid, custid, recommend, mrecommend, srecommend, betfrom, statusID)   
	SELECT DISTINCT transid, custid, recommend, mrecommend, srecommend, betfrom, statusID
	FROM dbo.bettrans AS b WITH (nolock)
		LEFT JOIN dbo.strSplit(@betteam16,'^') AS bt ON bt.val=b.betteam
	WHERE
		b.matchid=@matchid and           
		b.transid between @f_transid and @t_transid		
		AND CASE WHEN @liveindicator = 2 THEN @liveindicator ELSE b.liveindicator END = @liveindicator	
		AND b.livehomescore = CASE WHEN @livehomescore IS NOT NULL AND @liveindicator = 1 THEN @livehomescore ELSE b.livehomescore END
		AND b.liveawayscore = CASE WHEN @liveawayscore IS NOT NULL AND @liveindicator = 1 THEN @liveawayscore ELSE b.liveawayscore END	
		AND b.transdate BETWEEN CASE WHEN @FromTransdate IS NOT NULL AND @liveindicator = 1 THEN @FromTransdate ELSE b.transdate END 
						AND		CASE WHEN @ToTransdate IS NOT NULL AND @liveindicator = 1 THEN @ToTransdate ELSE b.transdate END 
		and b.bettype = 16
		AND (@betteam16='All' OR bt.val IS NOT NULL)
		AND ISNULL(SecAcceptFlag,0) = CASE @SAFilter WHEN 0 then ISNULL(SecAcceptFlag,0) WHEN 1 THEN 0 WHEN 2 THEN 1 END
		
		------------------***** End of insert all data into #BetDelete *****------------------		
		
	IF EXISTS (SELECT 1 FROM #BetDelete WHERE statusID IN (111,112,113) AND @username NOT IN ('steven','joe'))
	BEGIN
		SELECT @ErrCode = 100, @ErrMsg = 'You can only delete the unsettled or refunded tickets.'
		RETURN
	END
	ELSE
	BEGIN
		DELETE FROM #BetDelete WHERE statusID IN (SELECT * FROM @Status)
	END
	
	--INSERT Deposit CUSTOMER
	IF NOT (@DelOption = 0 OR (@DelOption=2 AND @transids='')) -- in case of deleting ticket of deposit customer
	BEGIN
		INSERT INTO @DepositCust (custid, username) -- Deposit customer list who are deleted ticket
			SELECT INF.Custid, INF.username 
			FROM custinfo INF WITH(nolock) 
				INNER JOIN #BetDelete BD ON INF.Custid = BD.Custid 
			WHERE INF.srecommend in (SELECT custid FROM Dep_CustSuper WITH (NOLOCK))
					AND INF.ROLEID = 1					
	END
	
	--INSERT UUS CUSTOMER
	Insert into @UUSCust(custid,username)
	SELECT INF.custid, INF.username 
	FROM custinfo INF (nolock) 
		INNER JOIN #BetDelete BD ON INF.Custid = BD.Custid 
	WHERE INF.srecommend IN (SELECT custid FROM customer (nolock) Where CURRENCY = 20 AND roleid = 4) 
			AND INF.roleid = 1
		
	--INSERT CUSTOMER HAVE REAL CURRENCIES AND CREATE USERNAME LIKE 'dba%' or 'pgm%' or 'vndbateam',  'VnQaTeam'		
	INSERT INTO @RealCurrCust (CustID, username)
	SELECT		INF.custid, INF.username 
	FROM		custinfo INF WITH (NOLOCK) 
	INNER JOIN	#BetDelete BD ON INF.Custid = BD.Custid 
	WHERE		INF.srecommend IN( SELECT custid FROM customer WITH(NOLOCK) Where CURRENCY <> 20 AND roleid = 4)	
				AND INF.roleid = 1 
				AND ( @Username LIKE 'dba%' OR @Username LIKE 'pgm%' OR @Username ='vndbateam' OR @Username = 'vnQaTeam')					

	--FOR Delete Deposit
	IF @DelOption = 0 or (@DelOption = 2 and @transids='')
		BEGIN
			DELETE FROM #BetDelete			
		END
	IF @DelOption = 2 and  @transids <> ''
		BEGIN
			DELETE FROM #BetDelete
			WHERE transid NOT IN (SELECT CONVERT(BIGINT, val) FROM dbo.strSplit(@transids, ','))		
		END
	
	-- STEP 1 : BackUp
	INSERT INTO zzzbettrans
		(transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator , refno, winlostdate, betfrom, betcheck, checktime, matchid, bettype)
	SELECT
		 transid, custid, CURRENT_TIMESTAMP, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator , refno, winlostdate, betfrom, betcheck, checktime, matchid, bettype
	FROM
		bettrans b WITH (nolock)
	WHERE
		b.transid IN (SELECT transid FROM #BetDelete)
		AND b.bettype in (SELECT CONVERT(INT,val) FROM dbo.strSplit(@bettypes,'^'))
		AND b.matchid = @matchid
		AND CASE
			WHEN b.bettype in (1,3,7,8) THEN CASE WHEN @betteam1378 = 'ALL' THEN betteam ELSE @betteam1378 END
			WHEN b.bettype in (5,15) THEN CASE WHEN @betteam515 = 'ALL' THEN betteam ELSE @betteam515 END
			ELSE betteam
		END = betteam   

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
	--  begin tran
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
	IF exists(
		SELECT 1 FROM #BetDelete INNER join bettrans b ON #BetDelete.transid = b.transid
		WHERE  #BetDelete.custid IN (SELECT custid FROM @DepositCust)
			or #BetDelete.custid IN (SELECT custid FROM @UUSCust)
			or #BetDelete.custid IN (SELECT custid FROM @RealCurrCust)	    
		)
	BEGIN
		IF EXISTS(SELECT CONVERT(INT,val) FROM dbo.strSplit(@bettypes,'^') WHERE CONVERT(INT, val) = 10)  --@bettype = 10
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
			ag.site
		FROM
			bettrans b WITH (NOLOCK)
			INNER JOIN customer  WITH (NOLOCK) ON customer.custid=b.custid
			INNER JOIN customer cr WITH (NOLOCK) ON cr.custid = b.creator
			INNER JOIN customer ag WITH (NOLOCK) ON customer.recommend = ag.custid
		WHERE b.transid IN(SELECT transid FROM #BetDelete)
			and customer.custid IN (SELECT custid FROM @DepositCust) 						      
		ORDER BY transid
	END

	SELECT  transid,
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
		WHERE	#BetDelete.custid IN (SELECT custid FROM @RealCurrCust)
				OR #BetDelete.custid IN (SELECT custid FROM @UUSCust)
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
				ag.site
			FROM
				bettrans b WITH (NOLOCK)
				INNER JOIN customer  WITH (NOLOCK) ON customer.custid=b.custid
				INNER JOIN customer cr WITH (NOLOCK) ON cr.custid = b.creator
				INNER JOIN customer ag WITH (NOLOCK) ON customer.recommend = ag.custid
			WHERE	b.transid IN(SELECT transid FROM #BetDelete)
					and (customer.custid IN (SELECT custid FROM @RealCurrCust)
							or customer.custid IN (SELECT custid FROM @UUSCust)
						)	     					   
			ORDER BY transid    	   
	END
	-----End : Send mail when delete real currencies and creator username like 'dba%' or 'pgm%' or 'vndbateam',  'VnQaTeam'/ OR Currency is UUS

	DROP TABLE #BetDelete
	DROP TABLE #BeforeUpd
	DROP TABLE #AfterUpd

	SET NOCOUNT OFF
END

GO
GRANT EXECUTE ON [dbo].[Acc_IOM_BettransDelSpecial] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_IOM_BettransDelSpecial] TO [vnteam] 