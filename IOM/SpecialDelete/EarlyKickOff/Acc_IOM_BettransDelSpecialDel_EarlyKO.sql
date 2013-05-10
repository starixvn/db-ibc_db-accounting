 ALTER PROCEDURE [dbo].[Acc_IOM_BettransDelSpecialDel_EarlyKO]
    @matchid INT,
    @DelOption TINYINT = 0,
    @KickOffDate datetime,
    @transids VARCHAR(4000) = 'All',-- for custom delete (Deposit bets)
    @bettypes VARCHAR(128) = 'All',
    @betteam1378 NVARCHAR(10),
    @betteam515 NVARCHAR(10),    
    @betteam430 varchar(120) = '',
	@betteam6 varchar(120) = '',
	@betteam14 varchar(120) = '',
	@betteam16 varchar(120) = '',
    @hdp SMALLMONEY,
    @UserName NVARCHAR(50),
    @UserPwd NVARCHAR(50),
    @UserID INT,
    @ErrMsg NVARCHAR(200) = '' OUTPUT,
    @ErrCode INT = 0 OUTPUT,    
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
Task : Delete ticket information for early kickoff
DB: DBTRANS.bodb02
Original: Acc_BettransDelSpecialDel_EarlyKO

Revisions:
   
Param's Explanation: Special bet delete option
	@@betteam4: bettype =4: Correct Score; bettype =30: 1st Correct Score
	@@betteam6: bettype=6: Total Goal
	@@betteam14: bettype=14: First Goal/Last Goal
	@@betteam16: bettype=16: Half Time/Full Time
	
	@@DelOption = 0: No Delete (need to remove normal bets out of #BetDelete)
    @@DelOption = 1: Delete All 
    @@DelOption = 2: Optional Delete (remove DepositBets with option)
 
    - @SAFilter: 
      + 0: All tickets
      + 1: Normal tickets only
      + 2: SA tickets only
*/
BEGIN
	SET NOCOUNT ON
	--Check permission for account site: @phuc20080213
	EXEC db03.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[SpecialDeleteEarlyKickOff]',@ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
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
		FROM dbo.customer WITH (NOLOCK)
		WHERE   customer.userpwd = @UserPwd
			AND custid = @UserID
			AND roleid>=5)
	BEGIN
		SELECT @LogData ='fail to delete bet for matchid ' + CONVERT(VARCHAR(20), @matchid) + ' because of early kick off at '+CAST(@KickOffDate as varchar(30))
		EXEC WriteLog_UserLog @UserID = @UserID, @Doing = @LogData

		SELECT @ErrMsg = 'Sorry. You can not process delete bet due to either wrong password or insufficient permission!', @ErrCode = 101   
		RETURN
	END
			
	IF EXISTS(SELECT 1 FROM dbo.match WITH(NOLOCK) WHERE matchid=@matchid AND eventstatus='completed')
	BEGIN
		SELECT @ErrCode = 100, @ErrMsg = 'You can not delete completed match.'
		RETURN
	END
	
		CREATE TABLE #BetDelete (transid BIGINT,refno bigint,custid INT, recommend INT, mrecommend INT, srecommend INT, betfrom NVARCHAR(1),statusID INT)
		CREATE TABLE #BetmDelete (transid BIGINT,refno bigint,custid INT, recommend INT, mrecommend INT, srecommend INT, betfrom NVARCHAR(1),statusID INT)
			
		DECLARE @DepositCust TABLE (custid INT, username VARCHAR(30))
		DECLARE @UUSCust TABLE (custid INT, username VARCHAR(30))
		DECLARE @RealCurrCust TABLE (custid INT, username VARCHAR(30))
		DECLARE @Status TABLE (statusID TINYINT)
		 
		INSERT INTO @Status
		SELECT 102 UNION ALL --Void
		SELECT 101 UNION ALL --Reject
		SELECT 112 UNION ALL --Won
		SELECT 113 UNION ALL --Lose
		SELECT 111			 --Draw
		
		------------------***** Insert all data into #BetDelete,#BetmDelete *****------------------	
		--bettype <> 4
		INSERT INTO #BetDelete (transid,refno,custid, recommend, mrecommend, srecommend, betfrom, statusID)   
		SELECT DISTINCT transid,refno,custid, recommend, mrecommend, srecommend, betfrom, statusID
		FROM dbo.bettrans b WITH (nolock)
			INNER JOIN dbo.strSplit(@bettypes,'^') AS fb ON b.bettype=fb.val
		WHERE
			b.matchid=@matchid	
			AND b.transdate>=@KickOffDate	
			AND b.liveindicator=0		
			AND CASE
				WHEN b.bettype in (1,3,7,8,2,12) THEN CASE WHEN @betteam1378 = 'ALL' THEN betteam ELSE @betteam1378 END
				WHEN b.bettype in (5,15) THEN CASE WHEN @betteam515 = 'ALL' THEN betteam ELSE @betteam515 END               
				ELSE betteam 
			END = betteam
			AND CASE WHEN b.bettype in (1,3,7,8) THEN CASE
												WHEN @hdp = 9999 THEN 1
												WHEN @hdp = (hdp1 + hdp2) THEN 1
												ELSE 0
											  END
				ELSE 1 END = 1
			AND b.bettype NOT IN(4,6,14,16,30)			
			AND ISNULL(SecAcceptFlag,0) = CASE @SAFilter WHEN 0 then ISNULL(SecAcceptFlag,0) WHEN 1 THEN 0 WHEN 2 THEN 1 END

		--bettype = 4
		INSERT INTO #BetDelete (transid,refno,custid, recommend, mrecommend, srecommend, betfrom, statusID)   
		SELECT DISTINCT transid,refno,custid, recommend, mrecommend, srecommend, betfrom, statusID
		FROM bettrans b WITH (nolock)
		WHERE
			b.matchid=@matchid	
			AND b.transdate>=@KickOffDate	
			AND b.liveindicator=0		
			AND betteam  in (SELECT CONVERT(VARCHAR,val) FROM dbo.strSplit(CASE WHEN @betteam430 = 'All' THEN betteam ELSE @betteam430 END,'^'))
			AND b.bettype in (4,30)
			AND ISNULL(SecAcceptFlag,0) = CASE @SAFilter WHEN 0 then ISNULL(SecAcceptFlag,0) WHEN 1 THEN 0 WHEN 2 THEN 1 END
					
		INSERT INTO #BetDelete (transid,refno,custid, recommend, mrecommend, srecommend, betfrom, statusID)   
		SELECT DISTINCT transid,refno,custid, recommend, mrecommend, srecommend, betfrom, statusID
		FROM bettrans b WITH (nolock)
		WHERE
			b.matchid=@matchid	
			AND b.transdate>=@KickOffDate	
			AND b.liveindicator=0		
			AND betteam  in (SELECT CONVERT(VARCHAR,val) FROM dbo.strSplit(CASE WHEN @betteam6 = 'All' THEN betteam ELSE @betteam6 END,'^'))
			AND b.bettype = 6
			AND ISNULL(SecAcceptFlag,0) = CASE @SAFilter WHEN 0 then ISNULL(SecAcceptFlag,0) WHEN 1 THEN 0 WHEN 2 THEN 1 END
					
		INSERT INTO #BetDelete (transid,refno,custid, recommend, mrecommend, srecommend, betfrom, statusID)   
		SELECT DISTINCT transid,refno,custid, recommend, mrecommend, srecommend, betfrom, statusID
		FROM bettrans b WITH (nolock)
			LEFT JOIN dbo.strSplit(@betteam14,'^') AS goal ON goal.val=b.betteam --dbo.Acc_SplitIndex(b.betteam,':',2)
		WHERE
			b.matchid=@matchid	
			AND b.transdate>=@KickOffDate	
			AND b.liveindicator=0		
			AND b.bettype = 14
			AND (@betteam14 = 'All' OR goal.val IS NOT NULL)
			AND ISNULL(SecAcceptFlag,0) = CASE @SAFilter WHEN 0 then ISNULL(SecAcceptFlag,0) WHEN 1 THEN 0 WHEN 2 THEN 1 END
		
		INSERT INTO #BetDelete (transid,refno,custid, recommend, mrecommend, srecommend, betfrom, statusID)   
		SELECT DISTINCT transid,refno,custid, recommend, mrecommend, srecommend, betfrom, statusID
		FROM bettrans b WITH (nolock)
		WHERE
			b.matchid=@matchid	
			AND b.transdate>=@KickOffDate	
			AND b.liveindicator=0		
			AND betteam  in (SELECT CONVERT(VARCHAR,val) FROM dbo.strSplit(CASE WHEN @betteam16 = 'All' THEN betteam ELSE @betteam16 END,'^'))
			AND b.bettype = 16			
			AND ISNULL(SecAcceptFlag,0) = CASE @SAFilter WHEN 0 then ISNULL(SecAcceptFlag,0) WHEN 1 THEN 0 WHEN 2 THEN 1 END
					
		--GET sub ticket of the matchid for mix parlay
		IF EXISTS (SELECT 1 FROM dbo.strSplit(@bettypes,'^') WHERE val IN (9,29))	
			AND EXISTS (SELECT 1 FROM dbo.bettransm AS b WITH(NOLOCK) WHERE b.matchid=@matchid  AND b.transdate>=@KickOffDate AND b.statusID NOT IN (101,102) AND b.liveindicator=0 AND betfrom <>'P')
		BEGIN	
			INSERT INTO #BetmDelete (transid,refno,custid, recommend, mrecommend, srecommend, betfrom, statusID)   
			SELECT DISTINCT b.transid,b.refno,b.custid, c.recommend, c.mrecommend, c.srecommend, b.betfrom, b.statusID
			FROM dbo.bettransm AS b with (NOLOCK)
				INNER JOIN dbo.customer AS c WITH(NOLOCK) ON c.custid=b.custid		
				INNER JOIN dbo.bettrans bt WITH(NOLOCK) ON b.refno = bt.refno 
				INNER JOIN (SELECT CONVERT(SMALLINT,val) AS bettype FROM dbo.strSplit(@bettypes,'^') WHERE val IN (9,29)) t ON t.bettype = bt.bettype	
			WHERE	b.matchid=@matchid   
				AND b.transdate>=@KickOffDate		
				AND b.liveindicator=0			
				AND bt.matchid IN (9,29) AND bt.bettype IN (9,29)
				AND CASE when @SAFilter = 2 then 0 else 1 END = 1
				AND (bt.betid = 0 OR bt.betid IS NULL)	
		END
			------------------***** End of insert all data into #BetDelete,#BetmDelete *****------------------	
			
		IF EXISTS (SELECT 1 FROM #BetDelete WHERE statusID IN (111,112,113)
				UNION ALL 
				SELECT 1 FROM #BetmDelete WHERE statusID IN (111,112,113))
		BEGIN
			SELECT @ErrCode = 100, @ErrMsg = 'You can only delete the unsettled or refunded tickets.'
			RETURN
		END
		ELSE
		BEGIN
			DELETE FROM #BetDelete WHERE statusID IN (SELECT * FROM @Status)
			DELETE FROM #BetmDelete WHERE statusID IN (SELECT * FROM @Status)
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
			UNION ALL
				SELECT INF.Custid, INF.username 
				FROM custinfo INF WITH(nolock) 
					INNER JOIN #BetmDelete BMD ON INF.Custid = BMD.Custid 
				WHERE INF.srecommend in (SELECT custid FROM Dep_CustSuper WITH (NOLOCK))
						AND INF.ROLEID = 1
		END		
			
		--INSERT UUS  CUSTOMER
		Insert into @UUSCust(custid,username)
		SELECT INF.custid, INF.username 
		FROM custinfo INF (nolock) 
			INNER JOIN #BetDelete BD ON INF.Custid = BD.Custid 
			WHERE INF.srecommend IN(
					SELECT custid FROM customer (nolock) Where CURRENCY = 20 AND roleid = 4
				) AND INF.roleid = 1
		UNION ALL
		SELECT INF.custid, INF.username 
		FROM custinfo INF (nolock) 
			INNER JOIN #BetmDelete BMD ON INF.Custid = BMD.Custid 
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
		UNION ALL
		SELECT		INF.custid, INF.username 
		FROM		custinfo INF WITH (NOLOCK) 
		INNER JOIN	#BetmDelete BMD ON INF.Custid = BMD.Custid 
		WHERE		INF.srecommend IN( SELECT custid FROM customer WITH(NOLOCK) Where CURRENCY <> 20 AND roleid = 4)	
					AND INF.roleid = 1 
					AND ( @Username LIKE 'dba%' OR @Username LIKE 'pgm%' OR @Username ='vndbateam' OR @Username = 'vnQaTeam')		
				------------------***** End of insert Custid of each type into its temp table  *****------------------		
				
				------------------***** Remove data no need to special delete out of #BetDelete *****------------------	
		--FOR Delete Deposit
		IF @DelOption = 0 or (@DelOption=2 AND @transids='')
		BEGIN
			DELETE FROM #BetDelete			
			DELETE FROM #BetmDelete
		END
		IF @DelOption = 2 AND @transids <> ''
		BEGIN
			DELETE FROM #BetDelete
			WHERE transid NOT IN (SELECT CONVERT(BIGINT, val) FROM dbo.strSplit(@transids, ','))
			
			DELETE FROM #BetmDelete
			WHERE transid NOT IN (SELECT CONVERT(BIGINT, val) FROM dbo.strSplit(@transids, ','))
		END
		------------------***** End of Remove data no need to special delete out of #BetDelete  *****------------------

		------------------***** Begin special delete early kickoff *****------------------

		-- STEP 1 : BackUp of bettrans and bettransm
		INSERT INTO	zzzbettrans
			(transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator , refno, winlostdate, betfrom, betcheck, checktime, matchid, bettype)
		SELECT
			b.transid, b.custid, CURRENT_TIMESTAMP, b.oddsid, b.hdp1, b.hdp2, b.odds, b.stake, b.status, b.winlost, b.livehomescore, b.liveawayscore, b.liveindicator, b.betteam, b.creator , b.refno, b.winlostdate, b.betfrom, b.betcheck, b.checktime, b.matchid, b.bettype
		FROM	dbo.bettrans AS b WITH (nolock)
			INNER JOIN #BetDelete AS d WITH(NOLOCK) ON d.transid=b.transid AND d.refno=b.refno
		WHERE		
			b.bettype in (SELECT CONVERT(INT,val) FROM dbo.strSplit(@bettypes,'^'))
			AND b.matchid = @matchid
			AND b.liveindicator = 0
			AND b.transdate>=@KickOffDate
			AND CASE
			WHEN b.bettype in (1,3,7,8) THEN CASE WHEN @betteam1378 = 'ALL' THEN betteam ELSE @betteam1378 END
			WHEN b.bettype in (5,15) THEN CASE WHEN @betteam515 = 'ALL' THEN betteam ELSE @betteam515 END
			ELSE betteam
			END = betteam

		-- BackUp bettransm tickets into zzzbettrans
		/***
			Date: 20120112@Lukas
			Temporary solution
			ADD MORE LOG IN ZZZBETTRANS FOR VIEWING LOG TW SITE
		***/
		INSERT INTO	zzzbettrans
			(transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator , refno, winlostdate, betfrom, betcheck, checktime, matchid, bettype)
		SELECT
			b.transid, b.custid, CURRENT_TIMESTAMP, b.oddsid, b.hdp1, b.hdp2, b.odds, b.stake, b.status, b.winlost, b.livehomescore, b.liveawayscore, b.liveindicator, b.betteam, b.creator , b.refno, b.winlostdate, b.betfrom, b.betcheck, b.checktime, b.matchid, b.bettype
		FROM	bettransm AS b WITH (nolock)
			INNER JOIN #BetmDelete AS d WITH(NOLOCK) ON d.transid=b.transid AND d.refno=b.refno
		WHERE
			b.matchid = @matchid
			AND b.liveindicator = 0
			AND b.transdate>=@KickOffDate	
		/*
			END -  ADD MORE LOG IN ZZZBETTRANS FOR VIEWING LOG TW SITE
		*/

		INSERT INTO	zzzbettransm
			(transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator , refno, winlostdate, betfrom, betcheck, checktime, matchid, bettype)
		SELECT
			b.transid, b.custid, CURRENT_TIMESTAMP, b.oddsid, b.hdp1, b.hdp2, b.odds, b.stake, b.status, b.winlost, b.livehomescore, b.liveawayscore, b.liveindicator, b.betteam, b.creator , b.refno, b.winlostdate, b.betfrom, b.betcheck, b.checktime, b.matchid, b.bettype
		FROM	bettransm AS b WITH (nolock)
			INNER JOIN #BetmDelete AS d WITH(NOLOCK) ON d.transid=b.transid AND d.refno=b.refno
		WHERE
			b.matchid = @matchid
			AND b.liveindicator = 0
			AND b.transdate>=@KickOffDate		
			
		declare @matchdate datetime
		select @matchdate = eventdate from match with(nolock) where matchid = @matchid
		
		-- Create temp table to calculate balance
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
		INNER JOIN #BetDelete d WITH(NOLOCK) ON d.transid=b.transid AND d.refno=b.refno
		GROUP BY b.CustID
		
		-- STEP 2 : Update
		--update void single ticket in bettrans
		UPDATE b 
		SET winlost=b.actual_stake,ruben=1,statuswinlost=6, status = 'Void', creator = @UserID,
			awinlost = 0, mwinlost = 0, swinlost = 0, playercomm = 0, comm  = 0, acomm = 0, scomm = 0, statusID = 102       
		FROM dbo.bettrans AS b WITH (ROWLOCK, UPDLOCK)
			INNER JOIN #BetDelete AS d WITH(NOLOCK) ON d.transid=b.transid AND d.refno=b.refno
		
		--Get data after update
		INSERT INTO #AfterUpd (custid, balance)
		SELECT	b.custid, SUM (b.winlost - b.actual_stake + b.playercomm) balance
		FROM	bettrans b WITH (NOLOCK)
		INNER JOIN #BetDelete AS d WITH(NOLOCK) ON d.transid=b.transid AND d.refno=b.refno
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
		
		--update void mix parlay ticket in bettrans			
		CREATE TABLE #Currency (TransID bigint, Refno bigint, CurrencyID tinyint,oddstype tinyint, ParlayType smallint)
		
		IF EXISTS (SELECT 1 FROM #BetmDelete)
		BEGIN	
			declare @match_tmp varchar(20), @rowcount INT, @step INT, @transid_tmp VARCHAR(2000)

			select	@match_tmp = CONVERT(VARCHAR(20),@matchid),
					@step = 0
			
			DECLARE @transtbl TABLE (id INT IDENTITY, transid BIGINT)
			INSERT INTO @transtbl (transid)
						SELECT transid
						FROM #BetmDelete
			SELECT @rowcount = @@ROWCOUNT

			WHILE @step < @rowcount
			BEGIN
				SET @transid_tmp = ''
				SELECT @transid_tmp  = @transid_tmp + CONVERT(VARCHAR(20),transid)  + ','	
				FROM @transtbl
				WHERE id > @step AND id <= @step + 100
				
				SET @step = @step + 100

				EXEC Admin_Calculate_9m 
						@matchid	= @MatchID,
						@fth		= 0, 
						@fta		= 0,
						@hth		= 0,  
						@hta		= 0,
						@matchdate	= @matchdate,
						@action		= 'VOID',
						@VoidTransID= @transid_tmp,
						@UserID		= @UserID
			END

			--***********System parlay*********---
			IF EXISTS (	SELECT TOP 1 1
						FROM bettrans b WITH(NOLOCK) 
							INNER JOIN #BetmDelete r ON b.refno = r.refno
						WHERE b.matchid = 29 AND b.bettype = 29
					   ) 
			BEGIN
				EXEC dbo.Admin_Calculate_29_PreCal @matchids = @match_tmp
				EXEC dbo.Admin_Calculate_29 @matchids = @match_tmp, @matchdate = @matchdate
			---********* Calculate balance for system parlay********---
				CREATE TABLE #BeforeUpdSP (
							custid		 INT,
							balance		 MONEY)
						
				CREATE TABLE #AfterUpdSP(
								custid		 INT,
								balance		 MONEY)
								
				--Get data before update
				INSERT INTO #BeforeUpdSP (custid, balance)
				SELECT	b.custid, SUM (b.winlost - b.actual_stake + b.playercomm) balance
				FROM	bettrans b WITH (NOLOCK)
					INNER JOIN #BetmDelete r ON b.refno = r.refno
				WHERE b.matchid = 29 AND b.bettype = 29
				GROUP BY b.CustID		

				--Settlement System parlay (changed balance)		
				EXEC dbo.Admin_Calculate_29_Summary 
				
				--Get data after update
				INSERT INTO #AfterUpdSP (custid, balance)
				SELECT	b.custid, SUM (b.winlost - b.actual_stake + b.playercomm) balance
				FROM	bettrans b WITH (NOLOCK)
					INNER JOIN #BetmDelete r ON b.refno = r.refno
				WHERE b.matchid = 29 AND b.bettype = 29
				GROUP BY b.CustID

				--insert data into pending balance table 
				INSERT INTO BalancePendingCredit (custid,Balance)
				SELECT		a.custid, (a.balance - b.balance) as Balance
				FROM		#BeforeUpdSP b
				INNER JOIN	#AfterUpdSP a 	
						ON	a.custid = b.custid
				WHERE	    (a.balance - b.balance) > 0

				INSERT INTO BalancePendingDebit (custid,Balance)
				SELECT		a.custid, ABS(a.balance - b.balance) as Balance
				FROM		#BeforeUpdSP b
				INNER JOIN	#AfterUpdSP a 	
						ON	a.custid = b.custid
				WHERE	    (a.balance - b.balance) < 0
				
				DROP TABLE #BeforeUpdSP
				DROP TABLE #AfterUpdSP
			---********* End of calculate balance for system parlay********---

			END

			INSERT INTO #Currency
			SELECT b2.transid,b2.Refno,b2.Currency,b2.oddstype, b2.bettype
			FROM dbo.bettrans AS b2 WITH(NOLOCK)
				INNER JOIN #BetmDelete AS d WITH(NOLOCK) ON b2.refno=d.refno
			WHERE matchid IN (9,29) AND bettype IN (9,29) --mix parlay
				AND liveindicator=0
				AND transdate>=@KickOffDate		
				AND (b2.betid = 0 OR b2.betid IS NULL) 				
		END
		
		SELECT @LogData ='delete bet for matchid ' + CONVERT(VARCHAR(20), @matchid) + ' because of early kick off at '+CONVERT(varchar(23),@KickOffDate,121) + ' IP=' + COALESCE(CAST(@IP AS VARCHAR(15)),SPACE(1))
		EXEC WriteLog_UserLog @UserID = @UserID, @Doing = @LogData

		--after delete, return all deleted deposit bets with additional information for mailing
		IF exists(
			SELECT 1 
			FROM #BetDelete AS d WITH(NOLOCK) 
			WHERE  d.custid in (SELECT custid FROM @DepositCust)
				or d.custid IN (SELECT custid FROM @UUSCust)
				or d.custid IN (SELECT custid FROM @RealCurrCust)
			UNION ALL
			SELECT 1 
			FROM #BetmDelete AS d WITH(NOLOCK) 
				INNER JOIN dbo.bettransm AS b WITH(NOLOCK) ON D.transid = b.transid
			WHERE  d.custid in (SELECT custid FROM @DepositCust)
				or d.custid IN (SELECT custid FROM @UUSCust)
				or d.custid IN (SELECT custid FROM @RealCurrCust)
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
					c.username,
					c.username2,
					b.odds,  
					b.OddsType, 
					b.transdate,
					b.bettype,
					b.transid,
					b.transid AS SubTransID,
					b.refno,
					b.betteam,
					b.hdp1,
					b.hdp2,
					b.betfrom,
					b.livehomescore,
					b.liveawayscore,
					cr.username creator,
					b.stake AS StakePositiontaking,           
					b.currency,
					ag.site,
					--b.status,
					0 AS IsMP,
					0 as ParlayType
				FROM
					dbo.bettrans b WITH (NOLOCK)
					INNER JOIN dbo.customer cr WITH (NOLOCK) ON cr.custid = b.creator
					INNER JOIN dbo.customer AS c WITH (NOLOCK) ON c.custid=b.custid				
					INNER JOIN dbo.customer ag WITH (NOLOCK) ON ag.custid=c.recommend
					INNER JOIN #BetDelete AS d WITH(NOLOCK) ON d.transid=b.transid --AND d.refno=b.refno
				WHERE matchid=@matchid
					AND b.transdate>=@KickOffDate				
					AND b.liveindicator=0		
					AND c.custid IN (SELECT custid FROM @DepositCust)
				
				UNION ALL
				SELECT
					customer.username,
					customer.username2,
					b.odds,  
					cy.OddsType, 
					b.transdate,
					b.bettype,
					cy.transid,
					b.transid AS SubTransID,
					b.refno,
					b.betteam,
					b.hdp1,
					b.hdp2,
					b.betfrom,
					b.livehomescore,
					b.liveawayscore,
					cr.username creator,
					b.stake AS StakePositiontaking,           
					cy.CurrencyID AS currency,
					ag.site,
					--b.status,
					1 AS IsMP,
					cy.ParlayType as ParlayType
				FROM
					dbo.bettransm b WITH (NOLOCK)
					INNER JOIN dbo.customer  WITH (NOLOCK) ON customer.custid=b.custid
					INNER JOIN dbo.customer cr WITH (NOLOCK) ON cr.custid = b.creator
					INNER JOIN dbo.customer ag WITH (NOLOCK) ON customer.recommend = ag.custid				
					INNER JOIN #BetmDelete AS d WITH(NOLOCK) ON d.transid=b.transid --AND d.refno=b.refno
					INNER JOIN #Currency AS cy WITH(NOLOCK) ON cy.refno=b.refno
				WHERE matchid=@matchid
					AND b.transdate>=@KickOffDate				
					AND b.liveindicator=0		
					AND customer.custid IN (SELECT custid FROM @DepositCust)
				ORDER BY IsMP, b.transid						
		END
		
		
		SELECT bd.transid,
			bd.custid, mem.UserName     AS CustUserName,
			bd.recommend, ag.UserName   AS AgUserName,
			bd.mrecommend, mag.UserName AS MagUserName,
			bd.srecommend, sag.Username AS SagUserName
		FROM #BetDelete bd (nolock)
			INNER JOIN dbo.custinfo mem (nolock) ON bd.custid     = mem.custid
			INNER JOIN dbo.custinfo ag  (nolock) ON bd.recommend  = ag.custid
			INNER JOIN dbo.custinfo mag (nolock) ON bd.mrecommend = mag.custid
			INNER JOIN dbo.custinfo sag (nolock) ON bd.srecommend = sag.custid
		UNION ALL
		SELECT b.transid,
				bd.custid, mem.UserName        AS CustUserName,
				bd.recommend, ag.UserName    AS AgUserName,
				bd.mrecommend, mag.UserName AS MagUserName,
				bd.srecommend, sag.Username AS SagUserName
		FROM dbo.bettrans b WITH (NOLOCK) 
			INNER JOIN #BetmDelete AS bd with(nolock) ON bd.refno=b.refno AND b.matchid=9 AND b.bettype=9
			INNER JOIN dbo.custinfo mem (nolock) ON bd.custid     = mem.custid
			INNER JOIN dbo.custinfo ag  (nolock) ON bd.recommend  = ag.custid
			INNER JOIN dbo.custinfo mag (nolock) ON bd.mrecommend = mag.custid
			INNER JOIN dbo.custinfo sag (nolock) ON bd.srecommend = sag.custid
		
	-----BEGIN : Send mail Internal when delete real currencies and creator username like 'dba%' or 'pgm%' or 'vndbateam',  'VnQaTeam'	/OR UUS Currency
	IF exists(
			SELECT 1 
			FROM #BetDelete AS d WITH(NOLOCK) 
				INNER JOIN dbo.bettrans b ON D.transid = b.transid
			WHERE  d.custid IN (SELECT custid FROM @UUSCust)
				or d.custid IN (SELECT custid FROM @RealCurrCust)
			UNION ALL
			SELECT 1 
			FROM #BetmDelete AS d WITH(NOLOCK) 
				INNER JOIN dbo.bettransm AS b WITH(NOLOCK) ON D.transid = b.transid
			WHERE  d.custid IN (SELECT custid FROM @UUSCust)
				or d.custid IN (SELECT custid FROM @RealCurrCust)
		)
		BEGIN
				SELECT
					c.username,
					c.username2,
					b.odds,  
					b.OddsType, 
					b.transdate,
					b.bettype,
					b.transid,
					b.transid AS SubTransID,
					b.refno,
					b.betteam,
					b.hdp1,
					b.hdp2,
					b.betfrom,
					b.livehomescore,
					b.liveawayscore,
					cr.username creator,
					b.stake AS StakePositiontaking,           
					b.currency,
					ag.site,
					--b.status,
					0 AS IsMP,
					1 as isInternalMail,
					0 as ParlayType
				FROM
					dbo.bettrans b WITH (NOLOCK)
					INNER JOIN dbo.customer cr WITH (NOLOCK) ON cr.custid = b.creator
					INNER JOIN dbo.customer AS c WITH (NOLOCK) ON c.custid=b.custid				
					INNER JOIN dbo.customer ag WITH (NOLOCK) ON ag.custid=c.recommend
					INNER JOIN #BetDelete AS d WITH(NOLOCK) ON d.transid=b.transid --AND d.refno=b.refno
				WHERE matchid= @matchid
					AND b.transdate>= @KickOffDate				
					AND b.liveindicator=0		
					AND ( c.custid IN (SELECT custid FROM @UUSCust)
						  or c.custid IN (SELECT custid FROM @RealCurrCust)
						)	
				UNION ALL
				SELECT
					customer.username,
					customer.username2,
					b.odds,  
					cy.OddsType, 
					b.transdate,
					b.bettype,
					cy.transid,
					b.transid AS SubTransID,
					b.refno,
					b.betteam,
					b.hdp1,
					b.hdp2,
					b.betfrom,
					b.livehomescore,
					b.liveawayscore,
					cr.username creator,
					b.stake AS StakePositiontaking,           
					cy.CurrencyID AS currency,
					ag.site,
					--b.status,
					1 AS IsMP,
					1 as isInternalMail,
					cy.ParlayType as ParlayType
				FROM
					dbo.bettransm b WITH (NOLOCK)
					INNER JOIN dbo.customer  WITH (NOLOCK) ON customer.custid=b.custid
					INNER JOIN dbo.customer cr WITH (NOLOCK) ON cr.custid = b.creator
					INNER JOIN dbo.customer ag WITH (NOLOCK) ON customer.recommend = ag.custid				
					INNER JOIN #BetmDelete AS d WITH(NOLOCK) ON d.transid=b.transid --AND d.refno=b.refno
					INNER JOIN #Currency AS cy WITH(NOLOCK) ON cy.refno=b.refno
				WHERE matchid=@matchid
					AND b.transdate>=@KickOffDate				
					AND b.liveindicator=0		
					AND (customer.custid IN (SELECT custid FROM @UUSCust)
						 or customer.custid IN (SELECT custid FROM @RealCurrCust)
						)	
				ORDER BY IsMP, b.transid	
		END
	----END : Send mail Internal when delete real currencies and creator username like 'dba%' or 'pgm%' or 'vndbateam',  'VnQaTeam'/ OR UUS Currency
				
							
		DROP TABLE #BetDelete	
		DROP TABLE #BetmDelete
		DROP TABLE #Currency
		
		DROP TABLE #BeforeUpd
		DROP TABLE #AfterUpd
			
		SET NOCOUNT OFF
	END	

GO
GRANT EXECUTE ON [dbo].[Acc_IOM_BettransDelSpecialDel_EarlyKO] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_IOM_BettransDelSpecialDel_EarlyKO] TO [vnteam]