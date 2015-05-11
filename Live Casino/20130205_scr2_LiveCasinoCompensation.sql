 declare 
	@MatchID INT	


SET @MatchID = 
	
	/*
		1. Insert into bettransG
		2. Check balance for insert bet
		3. Insert into bettrans
		4. check balance before settle
		5. settle
		6. check balance after settle & update balance table
	*/
	
	
	DECLARE @refcnt INT
	CREATE TABLE #refno (ID INT IDENTITY, refno BIGINT, newRefno BIGINT)
	
	INSERT INTO #refno(refno)
	SELECT DISTINCT refno
	FROM bettrans WITH(NOLOCK)
	WHERE matchid = @MatchID
		AND srecommend NOT IN (SELECT custid FROM f_depsuper_1('ALL'))  --- exclude all licensee supers
	ORDER BY refno ASC
	SET @refcnt = @@ROWCOUNT
	
	DECLARE @refn INT
	BEGIN TRANSACTION		
		UPDATE ref with (rowlock,updlock) SET @refn=refno=refno+@refcnt  WHERE  refid='refno'
		--set @refno = @refn + 100000000000
	COMMIT TRANSACTION
	
	UPDATE #refno
	SET newRefno = 100000000000 + @refn - @refcnt + ID
	
		
	-- 1. Insert into bettransG
	INSERT INTO bettransG(custid, transdate, oddsid, odds, stake, status, winlost, betteam, creator, refno, winlostdate, betfrom, checktime, apositiontaking, mpositiontaking, tpositiontaking, awinlost, mwinlost, playerdiscount, discount, adiscount, playercomm, comm, acomm, actualrate, matchid, matchdate, statuswinlost, ruben, bettype, spositiontaking, swinlost, sdiscount, scomm, statusID, virtualrate, SiteID)
	SELECT custid, GETDATE(), oddsid, odds, stake, 'running' as status, 0 as winlost, betteam, creator, r.newRefno, winlostdate, betfrom, checktime, 0 AS apositiontaking, 0 AS mpositiontaking, 0 AS tpositiontaking, 0 AS awinlost, 0 AS mwinlost, 0 AS playerdiscount, 0 AS discount, 0 AS adiscount, 0 AS playercomm, 0 AS comm, 0 AS acomm, actualrate, matchid, matchdate, statuswinlost, ruben, bettype, 0 AS spositiontaking, 0 AS swinlost, 0 AS sdiscount, 0 AS scomm, 0 AS statusID, virtualrate, SiteID
	FROM bettransG bg WITH(NOLOCK)
		INNER JOIN #refno r ON bg.refno = r.refno
	WHERE matchid = @MatchID
	
	
	
	-- 2. Check balance before inserting bet
	INSERT INTO dbo.BalancePendingDebit (custid, balance)
	SELECT custid, actual_stake
	FROM bettrans b WITH(NOLOCK)
	WHERE b.matchid = @MatchID
	
	
	-- 3. Insert bet
	INSERT INTO bettrans(custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, awinlost, mwinlost, playercomm, comm, acomm, apositiontaking, mpositiontaking, tpositiontaking, playerdiscount, discount, adiscount, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, comstatus, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, recommend, mrecommend, ruben, betid, statuswinlost, modds, bettype, betdaqid, actual_stake, currency, ip, transdesc, sdiscount, scomm, spositiontaking, swinlost, srecommend, Username, CurrencyName, virtualrate, oddstype, statusID, currency2, balance, SecAcceptFlag, transid2, RecommDate)
	SELECT DISTINCT b.custid, bg.transdate, b.oddsid, b.hdp1, b.hdp2, b.odds, b.stake, 'running' status, 0 AS winlost, 0 AS awinlost, 0 AS mwinlost, 0 AS playercomm, 0 AS comm, 0 AS acomm, 0 AS apositiontaking, 0 AS mpositiontaking, 0 AS tpositiontaking, 0 AS playerdiscount, 0 AS discount, 0 AS adiscount, livehomescore, liveawayscore, liveindicator, b.betteam, b.creator, R.newRefno, comstatus, b.winlostdate, b.betfrom, betcheck, b.checktime, oddsspread, b.actualrate, b.MatchID, recommend, mrecommend, 0 as ruben, betid, b.statuswinlost, modds, b.bettype, betdaqid, actual_stake, currency, ip, transdesc, 0 as sdiscount, 0 AS scomm, 0 AS spositiontaking, 0 AS swinlost, srecommend, Username, CurrencyName, b.virtualrate, oddstype, 0 AS statusID, currency2, balance, SecAcceptFlag, transid2, b.RecommDate
	FROM bettrans b WITH(NOLOCK)
		INNER JOIN #refno r ON b.refno = r.refno
		INNER JOIN bettransg bg ON bg.refno = r.refno
	WHERE b.matchid = @MatchID
	
		
	
	
	-- 4. check balance before settle
	-------------------------------------------------------------
	---        CAPTURE value BALANCE before settlement        ---
	---------------------------VVVV------------------------------
	CREATE TABLE #BalanceBefore (custid int PRIMARY KEY, balance money, winlost money)
	Declare @TotalAccount int, @TotalAccount_BalanceUpdate int
		
	INSERT INTO #BalanceBefore
	SELECT custid, SUM(winlost-actual_stake+playercomm), SUM(CASE WHEN ruben = 1 THEN winlost-actual_stake+playercomm ELSE 0 END)
	FROM dbo.bettrans with (rowlock)
	WHERE matchid = @matchid --AND bettype = @Bettype
	GROUP BY custid

	SET @TotalAccount = @@ROWCOUNT	
	
	
	
	-- 5. Settle bettransG 
	
	DECLARE @modds SMALLMONEY,
			@CommRate money 
	SELECT	@modds = 1,
			@CommRate = 0.05
			
			
	UPDATE dbo.bettransG with (ROWLOCK, UPDLOCK)
	SET
	WinLost = CASE
		WHEN betteam='1' and @modds >  0.25	THEN stake + stake * (case when odds<0 then 1 else odds end) * (1-@CommRate)
		WHEN @modds >  0.25	THEN stake + stake * (case when odds<0 then 1 else odds end)
		WHEN @modds =  0	THEN stake
		WHEN @modds < -0.25	THEN 0
		END,
	Status	= CASE
		WHEN @modds > 0 THEN N'WON'
		WHEN @modds = 0 THEN N'DRAW'
		WHEN @modds < 0 THEN N'LOSE'
		END,
	StatusID = CASE
		WHEN @modds > 0 THEN 112 --WON
		WHEN @modds = 0 THEN 111 --DRAW
		WHEN @modds < 0 THEN 113 --LOSE
		END,
	ruben=1
	WHERE
		matchid=@MatchID
		AND statusID = 0
				
					
	---exec [Admin_Calculate_1101] @newMatchID	
	DECLARE @bettransG TABLE (
		[refno] [bigint] NOT NULL ,  
		[matchid] [int] NULL , 
		[winlost] [money] NULL , 
		[awinlost] [money] NULL ,  
		[mwinlost] [money] NULL ,  
		[swinlost] [money] NULL , 
		[statusID] [tinyint] NULL,
		[stake] [money] NOT NULL,
		[playercomm] [money] NULL,
		[comm] [money] NULL,
		[acomm] [money] NULL,
		[scomm] [money] NULL
	)   

	DECLARE @bettrans TABLE (
		[transid] [bigint] NOT NULL ,  
		[refno] [bigint] NOT NULL ,  
		[discount] [decimal](9, 8) NULL, 
		[adiscount] [decimal](9, 8) NULL, 
		[sdiscount] [decimal](9, 8) NULL, 
		[playerdiscount] [decimal](9, 8) NULL,  
		[apositiontaking] [smallmoney] NULL ,  
		[mpositiontaking] [smallmoney] NULL , 
		[spositiontaking] [smallmoney] NULL
	)   

	DECLARE @Temp_bettrans TABLE(
		[transid] [bigint] NOT NULL ,  
		[refno] [bigint] NOT NULL ,  
		[winlost] [money] NULL , 
		[awinlost] [money] NULL ,  
		[mwinlost] [money] NULL ,  
		[swinlost] [money] NULL , 
		[playercomm] [money] NULL ,
		[comm] [money] NULL ,
		[acomm] [money] NULL ,
		[scomm] [money] NULL 
	) 

	INSERT INTO @bettransG ([refno],[matchid],[winlost],[awinlost],[mwinlost],[swinlost],[statusID],[stake],[playercomm],[comm],[acomm],[scomm])
	SELECT refno, matchid, WinLost, aWinLost, mWinLost, sWinLost, statusID, stake, playercomm, comm, acomm, scomm
	FROM bettransG WITH(NOLOCK)
	WHERE matchid=@MatchID 

	INSERT INTO @bettrans ([transid],[refno],[discount],[adiscount],[sdiscount],[playerdiscount],[apositiontaking],[mpositiontaking],[spositiontaking])
	SELECT transid ,refno, discount, adiscount, sdiscount, playerdiscount, apositiontaking, mpositiontaking, spositiontaking
	from bettrans WITH(NOLOCK)
	WHERE matchid=@MatchID AND statusID NOT IN (101,102,103)

	INSERT INTO @Temp_bettrans ([transid],[refno],[winlost],[awinlost],[mwinlost],[swinlost],[PlayerComm],[comm],[acomm],[scomm])
	SELECT S.transid ,S.refno,
		sum(G.WinLost) as WinLost ,
		sum(G.aWinLost) as aWinLost ,
		sum(G.mWinLost) as mWinLost ,
		sum(G.sWinLost) as sWinLost ,
		sum(G.playercomm) as PlayerComm ,
		sum(G.comm) as comm ,
		sum(G.acomm) as acomm ,
		sum(G.scomm) as scomm
	FROM @bettrans S 
		INNER JOIN @bettransG G on G.refno = S.refno
	WHERE G.statusID NOT IN (101,102,103)
	GROUP BY S.transid ,S.refno

	UPDATE bettrans WITH(ROWLOCK, UPDLOCK)
	SET
		winlost = a.winlost
		,awinlost = a.awinlost
		,mwinlost = a.mwinlost
		,swinlost = a.swinlost
		,playercomm = a.playercomm
		,comm = a.comm
		,acomm = a.acomm
		,scomm = a.scomm
		, status = CASE WHEN a.winlost = bettrans.stake THEN 'DRAW'
						WHEN a.winlost > bettrans.stake THEN 'WON'
						WHEN a.winlost < bettrans.stake THEN 'LOSE'
				   END
		,statusid = CASE WHEN a.winlost = bettrans.stake THEN '111'
						WHEN a.winlost > bettrans.stake THEN '112'
						WHEN a.winlost < bettrans.stake THEN '113'
				   END
		,ruben = 1
	FROM @Temp_bettrans a
	WHERE a.transid  = bettrans.transid  and
	a.refno = bettrans.refno
		
		
	-- 6. Check balance after settle		
	-------------------------------------------------------------
	---         CAPTURE value BALANCE after settlement        ---
	---------------------------VVVV------------------------------
	CREATE TABLE #BalanceAfter (custid int PRIMARY KEY, balance money, winlost money)
	
	INSERT INTO #BalanceAfter
	SELECT custid, SUM(winlost-actual_stake+playercomm), SUM(CASE WHEN ruben = 1 THEN winlost-actual_stake+playercomm ELSE 0 END)
	FROM dbo.bettrans with (rowlock)
	WHERE matchid = @matchid --AND bettype = @Bettype
	GROUP BY custid
	

	-------------------------------------------------------------
	---                   compare BALANCE                     ---
	---------------------------VVVV------------------------------
	CREATE TABLE #Balance (custid int PRIMARY KEY, balance money, Increased bit)
	CREATE INDEX IX_Balance_Increased ON #Balance (Increased)

	INSERT INTO #Balance
	SELECT b.custid, a.balance - b.balance, CASE WHEN a.balance > b.balance THEN 1 ELSE 0 END
	FROM #BalanceBefore b
		INNER JOIN #BalanceAfter a ON b.custid = a.custid
	WHERE b.balance <> a.balance

	SET @TotalAccount_BalanceUpdate = @@ROWCOUNT


	INSERT INTO dbo.BalancePendingDebit (custid, balance)
	SELECT custid, ABS(balance)
	FROM #Balance
	WHERE Increased = 0

	INSERT INTO dbo.BalancePendingCredit (custid, balance)
	SELECT custid, balance
	FROM #Balance
	WHERE Increased = 1
	
	-------------------------------------------------------------
	---                   compare BALANCE for LCS Balance     ---
	---------------------------VVVV------------------------------
	DECLARE @eventdate SMALLDATETIME	
	SET @eventdate = CONVERT(VARCHAR(10),GETDATE(),112)
	
	CREATE TABLE #BalanceGame (custid int PRIMARY KEY, balance money, Increased bit)
	CREATE INDEX IX_BalanceGame_Increased ON #BalanceGame (Increased)

	INSERT INTO #BalanceGame 
	SELECT b.custid, a.winlost - b.winlost, CASE WHEN a.winlost > b.winlost THEN 1 ELSE 0 END
	FROM #BalanceBefore b
		INNER JOIN #BalanceAfter a ON b.custid = a.custid
	WHERE b.winlost <> a.winlost
	
	
	INSERT INTO dbo.BalancePendingDebitGame (custid, winlostdate, balance)
	SELECT custid, @eventdate, ABS(balance)
	FROM #BalanceGame
	WHERE Increased = 0

	INSERT INTO dbo.BalancePendingCreditGame (custid, winlostdate, balance)
	SELECT custid, @eventdate, balance
	FROM #BalanceGame
	WHERE Increased = 1

	DROP TABLE #Balance
	DROP TABLE #BalanceGame
	DROP TABLE #BalanceBefore
	DROP TABLE #BalanceAfter
	




/*insert into match( leagueid, homeid, awayid, eventdate, eventstatus, betstatus, livehomescore, liveawayscore, finalhomescore, finalawayscore, creator, matchcode, kickofftime, closedtime, showtime, hthomescore, htawayscore, ruben, multiple, yenbet, exrisk, sporttype, homeid2, awayid2, DisplayMode, LeaguePatternID, HomeDisplayPatternID, AwayDisplayPatternID, IsNeutral, InjuryTime, GoalRecord, ParentID, ChildMatchType, GlobalShowTime, HasLive, changetime, settletime)
select leagueid, homeid, awayid, eventdate, eventstatus, betstatus, livehomescore, liveawayscore, finalhomescore, finalawayscore, creator, matchcode, kickofftime, closedtime, showtime, hthomescore, htawayscore, ruben, multiple, yenbet, exrisk, sporttype, homeid2, awayid2, DisplayMode, LeaguePatternID, HomeDisplayPatternID, AwayDisplayPatternID, IsNeutral, InjuryTime, GoalRecord, ParentID, ChildMatchType, GlobalShowTime, HasLive, changetime, settletime
from match
where matchid = 2779450
select @@IDENTITY
2800496


exec [dbo].[DBA_SpecialLCSTask]
	@OldMatchID =2779450,;
	@newMatchID	=2800496*/