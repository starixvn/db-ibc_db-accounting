ALTER PROCEDURE [dbo].[Acc_AllStatement_Full]
	@custid int,
	@fromdate datetime,
	@todate datetime,
	@BalanceUpDay datetime,
	@MoveBetDay		DATETIME,
	@IncludeAccBal bit = 1,
	@showExchangeRate bit = 1
 AS
 
 /*
	Created by: Henry
	Date: 2009 Oct 16
	Task: Get Statement report
	DB: DBEXT/BODB02 , DBACC/BODB02
	
	Revisions:
		- 20091016@Henry: Create New (Copy logic from Acc_AllStatement)
		- 20091223@Daniel: Fix sort issue of OPENNING BAL rows
		- 20100104@Daniel: Fix when @todate < @BUDate, the data always get to @BUDate (should get to @Todate)
		- 20100312@Daniel: If there are no OPENNING BALANCE row, insert an 'Accumulated Balance row' on top to relects the accumulated balance up to the date before "From Date"
		- 20100930@Jamie: Get isShow to check whether display Check box "Verify" or not 
		- 20101007@Anders: Declare local vairable to avoid paramater sniffing, change default checkername from '0' to ''
 		- 20101224@Lukas: Re-arrange bettype
 		- 20110713@TOM:Separate the statement by Betting Statement/Void cancelled/Outstanding Bet
 				Add new column transtypeid on data return :
					transtypeid =0-Others ;   
					transtypeid =1-Betting Statement; 
					transtypeid =2-VOID/Cancelled Bet; 
					transtypeid =3-Outstanding Bet
		- 20110720@TOM:Add parameter @MoveBetDay
				Remove case of Casino in Outstanding Bet
		- 20110725@Lukas: include refund tickets.
		- 20120405@Hurri: Add bettype 23102 (P2P Pending) into condition
		- 20120629@Lukas: expand range of date in case of @todate > @balanceupdate to avoid missing data
		- 20120701@Thien: fix the sorting, changing from CONVERT(VARCHAR(10),accdate,110) to CONVERT(VARCHAR(10),accdate,102)
 		- 20120701@Lukas: Remove unneed code ( convert to smalldatetime to order )
		- 20120723@Thien: Include Exchange rate into Remark field of Statement page
		- 20120817@Lukas: modify code to retrieve all transactions have accdate greater than balanceupdate
		- 20120918@Kiwi: change to use db052
		- 20130129@Dan: add param to show/hide exchange rate (use for external acc), change linked server DB06 to DBRPT
		- 20140214@Lukas: exclude bingo transfer & bingo pending transactions
		- 20140305@Dom: Update outstanding for keno
		- 20140929@Daniel: fix bug wrong Accu row in case cannot find any BU row before @fromDate
		- 20150706@Sophia: Do not check ticket running of Metric gaming at bettrans table, because of the translog [#38789]
		- 20150727@Sophia: Apply Bettrade, exclude ticket Bettrade Comm (903) for Void/reject [#36905]
		- 20150903@Sophia: Apply Colossus Bets [#42428]
		- 20150918@Sophia: Apply AG Casino - Add table BettransLC [#43810]
						   Apply MGC - RNG Casino - Add table BettransRNG [#43549]

 */
SET NOCOUNT ON


DECLARE @roleid INT

SELECT @roleid = roleid FROM customer (nolock) WHERE custid = @custid

DECLARE @bet TABLE (  
	winlostdate DATETIME, bettype SMALLINT, statusID TINYINT,  
	transdate DATETIME, transdesc NVARCHAR(300),  
	stake MONEY, actual_stake MONEY, winlost MONEY, playercomm MONEY) 

DECLARE @StatementTable TABLE(
	accdate datetime,
	refno bigint,
	totalamt money,
	transtype nvarchar(100),
	transdesc nvarchar(350),
	creator varchar(50),
	checkerID int null,
	checkerName varchar(50) null,
	checkTime datetime null,
	isAllowVeify bit default 0,-- display check box "Verify"   ,
	transtypeid tinyint default 0 
)

DECLARE @_ToDate AS SMALLDATETIME
SET @_ToDate = @todate

DECLARE @_FromDate AS SMALLDATETIME
SET @_FromDate = @fromdate

DECLARE @_BalanceUpDay AS SMALLDATETIME
SET @_BalanceUpDay = @BalanceUpDay

DECLARE @fromdate_bk SMALLDATETIME
SET @fromdate_bk = @_FromDate

DECLARE @_IncludeAccBal AS BIT
SET @_IncludeAccBal = @IncludeAccBal

----Get Sport Bettype Matrix------
	DECLARE @SportBettype TABLE(ProductID INT, Bettype INT,EventType INT,SubProduct VARCHAR(500))
	INSERT INTO @SportBettype
	EXEC bodb02.dbo.Acc_SportBettypeMatrix_Sel @mode = 5


IF @_ToDate >= @_BalanceUpDay
BEGIN
	--always Get all data from latest BUDate -> @todate for calculating ACCUMULATED BALANCE row
	IF (@_FromDate > @_BalanceUpDay)
	BEGIN
		SELECT @fromdate_bk = @_FromDate
		SELECT @_FromDate = @_BalanceUpDay
	END
	
	DECLARE @Today SMALLDATETIME 
	SELECT @Today = DATEADD(DAY, DATEDIFF(DAY,0,CURRENT_TIMESTAMP), 0)

	IF @roleid = 1
	BEGIN
		---- 1.1 bettrans
		INSERT INTO @bet(winlostdate, bettype, statusID, transdate, transdesc, stake, actual_stake, winlost, playercomm )			 
			SELECT winlostdate, b.bettype, 
				CASE
					WHEN statusID IN (102,101) THEN 102 --'VOID','REJECT'
					WHEN statusID IN (0,1) THEN 0 --'running', 'waiting'
				ELSE 131 END,
				CASE WHEN b.bettype <= 19999 THEN NULL ELSE transdate END,
				CASE WHEN b.bettype <= 19999 THEN '' ELSE transdesc END,
				SUM(CASE WHEN b.bettype IN(33,43) AND b.liveawayscore = 0 AND b.livehomescore <> 0 AND ruben = 1
					THEN b.stake/2 ELSE b.stake END),
				SUM(actual_stake), SUM(winlost), SUM(playercomm)
			FROM bettrans b (NOLOCK)
			LEFT JOIN @SportBettype s ON s.bettype = b.bettype 
			WHERE custid = @custid
				AND winlostdate between @_FromDate and @_ToDate
				AND CASE WHEN s.productId = 1 AND s.SubProduct = 'MG-SuperLive' AND StatusID IN (0,1) THEN 0 ELSE 1 END = 1 
				AND CASE WHEN (s.productId = 11 OR (s.productId = 13 AND s.SubProduct = 'MGC-RNG')) AND Winlostdate = @Today THEN 0 ELSE 1 END = 1
				--AND statusID <> 103
			GROUP BY winlostdate, b.bettype,
				CASE
					WHEN statusID IN (102,101) THEN 102--'VOID','REJECT'
					WHEN statusID IN (0,1) THEN 0--'running', 'waiting'
				ELSE 131 END,
				CASE WHEN b.bettype <= 19999 THEN NULL ELSE transdate END,
				CASE WHEN b.bettype <= 19999 THEN '' ELSE transdesc END			
			
			---- 1.2 TransLog
			UNION ALL
			SELECT  winlostdate, 
					GameId as bettype, 
					0 StatusID,
					NULL transdate,
					'' transdesc,
					SUM(stake),
					SUM(actual_stake),
					0,
					0
			FROM translog(NOLOCK)
			WHERE custid = @custid
				AND winlostdate BETWEEN @_FromDate and @_ToDate
				AND statusID = 0
			GROUP BY GameId, winlostdate

			----1.3 Get data today from BettransLC for AS Casino  
			IF @Today <= @todate
			BEGIN 
				INSERT INTO @bet(winlostdate, bettype, statusID, transdate, transdesc, stake, actual_stake, winlost, playercomm )
				SELECT winlostdate, GameId, 
					CASE
					WHEN statusID IN (102,101) THEN 102 --'VOID','REJECT'
					WHEN statusID IN (0,1) THEN 0 --'running', 'waiting'
						ELSE 131 END,
					NULL transdate,
					'' transdesc,
					SUM(stake),
					SUM(actual_stake), 
					SUM(winlost), 
					SUM(playercomm)
				FROM bettransLC (NOLOCK)
				WHERE custid = @custid
					AND winlostdate = @Today
				GROUP BY winlostdate, GameId,
					CASE
						WHEN statusID IN (102,101) THEN 102--'VOID','REJECT'
						WHEN statusID IN (0,1) THEN 0--'running', 'waiting'
					ELSE 131 END	
				
				----1.4 Get data today from BettransRNG for Microgaming
				UNION ALL 
				SELECT winlostdate, GameId, 
					CASE
					WHEN statusID IN (102,101) THEN 102 --'VOID','REJECT'
					WHEN statusID IN (0,1) THEN 0 --'running', 'waiting'
						ELSE 131 END,
					NULL transdate,
					'' transdesc,
					SUM(stake),
					SUM(actual_stake), 
					SUM(winlost), 
					SUM(playercomm)
				FROM bettransRNG (NOLOCK)
				WHERE custid = @custid
					AND winlostdate = @Today
				GROUP BY winlostdate, GameId,
					CASE
						WHEN statusID IN (102,101) THEN 102--'VOID','REJECT'
						WHEN statusID IN (0,1) THEN 0--'running', 'waiting'
					ELSE 131 END					 
			END

		
		---------------------

		INSERT INTO @StatementTable(accdate, refno, totalamt,transtype,transtypeid,transdesc,creator,checkerID, checkerName, checkTime, isAllowVeify)
		SELECT winlostdate, 0,SUM(winlost-actual_stake) totalamt , 
				'BET' transtype,1, 'Betting Statement' transdesc,  
				'' Creator,	 NULL,'', NULL,0
		FROM	@bet
		WHERE	bettype <= 19999 
				AND statusID = 131
		GROUP BY winlostdate  

		UNION ALL
		SELECT winlostdate, 0, 0 as totalamt,
			--SUM(stake) totalamt , 
				'BET' transtype,2, 'Void/Cancelled Bet' transdesc,  
				'' Creator,	 NULL,   '', NULL,	   0
		FROM	@bet  
		WHERE	statusID = 102
				AND Bettype <> 903
		GROUP BY winlostdate  

		UNION ALL
		SELECT winlostdate, 0,0 as totalamt ,
			--SUM(stake) totalamt , 
				'BET' transtype,3, 'Outstanding Bet' transdesc,  
				'' Creator,	 NULL,   '', NULL,	   0
		FROM	@bet  
		WHERE	statusID = 0  AND bettype NOT IN (23001,23002,23101,23102,23201,23202) -- 20120405@Hurri
		GROUP BY winlostdate 

		-----------Grand Prize of Colossus bets
		IF @_Todate >= @MoveBetDay
		BEGIN 
			INSERT INTO @StatementTable(accdate, refno, totalamt,transtype,transtypeid,transdesc,creator,checkerID, checkerName, checkTime, isAllowVeify)
			SELECT b.winlostdate AS accdate
				,0 refno
				,sum(bm.winlost - bm.stake) AS totalamt
				,'GP' transtype
				,4 transtypeid
				,'Grand Prize' transdesc
				,'' Creator
				,NULL checkerID
				,'' checkerName
				,NULL checkTime
				,0 isAllowVeify
			FROM bettrans b WITH (NOLOCK)
				INNER JOIN BettransM bm WITH (NOLOCK)
					ON b.RefNo = bm.RefNo
			WHERE b.bettype = 18000
				AND b.custid = @custid
				AND b.winlostdate BETWEEN @MoveBetDay AND @_ToDate
				AND b.Ruben = 1
				AND bm.statuswinlost <> 0
			GROUP BY b.winlostdate
		END
		
		IF @_FromDate <= @MoveBetDay
		BEGIN 
			INSERT INTO @StatementTable(accdate, refno, totalamt,transtype,transtypeid,transdesc,creator,checkerID, checkerName, checkTime, isAllowVeify)
			SELECT b.winlostdate AS accdate
				,0 refno
				,sum(bm.winlost - bm.stake) AS totalamt
				,'GP' transtype
				, 4 transtypeid
				,'Grand Prize' transdesc
				,'' Creator
				,NULL checkerID
				,'' checkerName
				,NULL checkTime
				,0 isAllowVeify
			FROM bettrans14 b WITH (NOLOCK)
				INNER JOIN BettransM14 bm WITH (NOLOCK)
					ON b.RefNo = bm.RefNo
			WHERE b.bettype = 18000
				AND b.custid = @custid
				AND b.winlostdate BETWEEN @_FromDate AND @MoveBetDay
				AND b.Ruben = 1
				AND bm.statuswinlost <> 0
			GROUP BY b.winlostdate
		END

		-----------Grand Prize of Microgaming RNG Casino				
			INSERT INTO @StatementTable(accdate, refno, totalamt,transtype,transtypeid,transdesc,creator,checkerID, checkerName, checkTime, isAllowVeify)
			SELECT winlostdate AS accdate
				,0 refno
				,SUM (winlost) AS totalamt
				,'GP' transtype
				, 4 transtypeid
				,'Grand Prize' transdesc
				,'' Creator
				,NULL checkerID
				,'' checkerName
				,NULL checkTime
				,0 isAllowVeify
			FROM dbo.JackpotWin WITH(NOLOCK) 
			WHERE	winlostdate BETWEEN @fromdate AND @todate
					AND custid = @custid
					AND statusID NOT IN (102,101) -- 'VOID','REJECT'				
			GROUP BY winlostdate, custid
						 

		--------------------------------------------------------------
		INSERT INTO @StatementTable(accdate, refno, totalamt,transtype,transdesc,creator,checkerID, checkerName, 
					checkTime, isAllowVeify)

--		select 
--			winlostdate accdate,
--			0,
--			sum(winlost-actual_stake) totalamt,
--			'BET' transtype, 
--			'Betting' transdesc, 
--			'' Creator,
--			NULL,
--			'',
--			NULL,
--			0 
--		from bettrans with (nolock) 
--		where 
--			bettype between 1 and 19999 
--			and custid=@custid 
--			and winlostdate between @_FromDate and @_ToDate 
--		group by winlostdate

		select 
			winlostdate accdate,
			0,
			sum(playercomm) totalamt,
			'COM' transtype, 
			'Commission' transdesc ,
			'' Creator,
			NULL,
			'',
			NULL,
			0  
		from bettrans with (nolock)  
		where 
			bettype between 1 and 19999 
			and custid=@custid 
			and winlostdate between @_FromDate and @_ToDate 
			AND CASE WHEN bettype BETWEEN 1800 AND 1899 AND Winlostdate = @Today THEN 0 ELSE 1 END = 1
			and playercomm<>0 
		group by winlostdate

		UNION ALL
		select 
			transdate accdate,
			refno,
			sum(winlost-actual_stake) totalamt,
			typenamee transtype,
			transdesc + case when @showExchangeRate = 1 then ' - Ex.Rate: ' + cast(actualrate as varchar(10)) else '' end as transdesc, 
			isnull(c.username,'') Creator,
			case when bettype.typeid IN (20000,23001,23002,23101,23102,23201,23202) then NULL else bettrans.betid end, --BalanceUP AND Transfer to Casino/Bingo/P2P
			case when bettype.typeid IN (20000,23001,23002,23101,23102,23201,23202) then '0' else bettrans.betcheck end,
			case when bettype.typeid IN (20000,23001,23002,23101,23102,23201,23202) then NULL else bettrans.checkTime end,
			case when bettype.typeid IN (20000,23001,23002,23101,23102,23201,23202) then 0 else 1 end   
		from bettrans  with (nolock) inner join bettype with (nolock) on bettype.typeid=bettrans.bettype 
		left join customer c with (nolock) on bettrans.creator = c.custid 
		where 
			bettype >= 20000 
			and bettrans.custid=@custid 
			and bettype.typeid NOT IN (23001,23002,23101,23102,23201,23202) AND (winlost-actual_stake) <> 0 
			and winlostdate between @_FromDate and @_ToDate 
		group by typenamee,
				transdesc + case when @showExchangeRate = 1 then ' - Ex.Rate: ' + cast(actualrate as varchar(10)) else '' end
				,transdate,transid, bettype.typeid,c.username
				,bettrans.betid, bettrans.betcheck, bettrans.checkTime, bettrans.refno 


	
		IF @Today <= @todate
		BEGIN 
			----# Get data today from BettransLC for AG Casino
			INSERT INTO @StatementTable(accdate, refno, totalamt,transtype,transdesc,creator,checkerID, checkerName, checkTime, isAllowVeify)
			SELECT winlostdate as accdate
				,0
				,sum(playercomm) totalamt
				,'COM' transtype
				,'Commission' transdesc
				,'' Creator
				,NULL
				,''
				,NULL
				,0
			FROM bettransLC WITH (NOLOCK)
			WHERE custid = @custid
				AND winlostdate = @Today
				AND playercomm <> 0
			GROUP BY winlostdate

			----# Get data today from BettransRNG for Microgaming RNG Casino
			UNION ALL 
			SELECT winlostdate as accdate
				,0
				,sum(playercomm) totalamt
				,'COM' transtype
				,'Commission' transdesc
				,'' Creator
				,NULL
				,''
				,NULL
				,0
			FROM bettransRNG WITH (NOLOCK)
			WHERE custid = @custid
				AND winlostdate = @Today
				AND playercomm <> 0
			GROUP BY winlostdate

		END 


		-- customer deleted/void ticket
		IF @_FromDate <= @MoveBetDay
			INSERT INTO @StatementTable(accdate, refno, totalamt,transtype,transtypeid,transdesc,creator,checkerID, checkerName, 
							checkTime, isAllowVeify)
			select distinct 
				eventdate accdate,
				0,
				0 totalamt, 
				'BET' transtype, 2,
				'Cancelled/Deleted Bets' transdesc, 
				'' Creator,
				NULL,
				'',
				NULL,
				0 
			from zzzbettrans with (nolock), match (nolock)
			where 
				zzzbettrans.matchid = match.matchid 
				and bettype between 1 and 19999 
				AND Bettype <> 903
				and custid=@custid 
				--and eventdate between @_FromDate and @_ToDate 
				and eventdate between @_FromDate and @MoveBetDay 
			group by eventdate
			
			--Remove All
			UNION ALL
			select distinct 
				eventdate accdate,
				0,
				0 totalamt,
				'BET' transtype, 2, 
				'Cancelled/Deleted Bets' transdesc, 
				'' Creator,
				NULL,
				'',
				NULL,
				0 
			from zzzbettrans with (nolock), match14 match (nolock)
			where 
				zzzbettrans.matchid = match.matchid 
				and bettype between 1 and 19999 
				AND Bettype <> 903
				and custid=@custid 
				--and eventdate between @_FromDate and @_ToDate 
				and eventdate between @_FromDate and @MoveBetDay 
		group by eventdate

	END

	-- AGENT
	IF @roleid = 2 
	BEGIN
		INSERT INTO @StatementTable(accdate, refno, totalamt,transtype,transdesc,creator,checkerID, checkerName, checkTime, isAllowVeify)	
		select 
			transdate accdate,
			refno,
			sum(winlost-actual_stake) totalamt ,
			typenamee transtype,
			transdesc + case when @showExchangeRate = 1 then ' - Ex.Rate: ' + cast(actualrate as varchar(10)) else '' end as transdesc , 			
			isnull(c.username,'') Creator,
			case when bettype.typeid IN (20000,23001,23002,23101,23102,23201,23202) then NULL else bettrans.betid end,
			case when bettype.typeid IN (20000,23001,23002,23101,23102,23201,23202) then '0' else bettrans.betcheck end,
			case when bettype.typeid IN (20000,23001,23002,23101,23102,23201,23202) then NULL else bettrans.checkTime end,
			case when bettype.typeid IN (20000,23001,23002,23101,23102,23201,23202) then 0 else 1 end   
		from bettrans with (nolock) 
		inner join bettype with (nolock) on bettype.typeid=bettrans.bettype 
		left join customer c with (nolock) on bettrans.creator = c.custid 
		where 
			bettype >= 20000 
			and bettrans.custid=@custid 
			and winlostdate between @_FromDate and @_ToDate 
			group by typenamee,
				transdesc + case when @showExchangeRate = 1 then ' - Ex.Rate: ' + cast(actualrate as varchar(10)) else '' end
				,transdate,transid, bettype.typeid, c.username
				, bettrans.betid, bettrans.betcheck, bettrans.checkTime, bettrans.refno
			
		UNION ALL
		select 
			winlostdate accdate,
			0,
			sum(awinlost) totalamt,
			'POS' transtype, 
			'Position' transdesc, 
			'' Creator,
			NULL,
			'',
			NULL,
			0 
		from bettrans b with (nolock) 
			LEFT JOIN @SportBettype s ON s.bettype = b.bettype 
		where 
			b.bettype between 1 and 19999 
			and recommend=@custid 
			and winlostdate between @_FromDate and @_ToDate 
			AND CASE WHEN (s.productId = 11 OR (s.productId = 13 AND s.SubProduct = 'MGC-RNG'))	AND Winlostdate >= @Today THEN 0 ELSE 1 END = 1
		group by winlostdate 
		having sum(awinlost) <> 0
		
		UNION ALL
		select 
			winlostdate accdate,
			0,
			sum(comm-playercomm) totalamt,
			'COM' transtype, 
			'Commission' transdesc, 
			'' Creator,
			NULL,
			'',
			NULL,
			0 
		from bettrans b with (nolock)  
			LEFT JOIN @SportBettype s ON s.bettype = b.bettype 
		where 
			b.bettype between 1 and 19999 
			and recommend=@custid 
			and winlostdate between @_FromDate and @_ToDate 
			AND CASE WHEN (s.productId = 11 OR (s.productId = 13 AND s.SubProduct = 'MGC-RNG'))	AND Winlostdate >= @Today THEN 0 ELSE 1 END = 1
		group by winlostdate 
		having sum(comm-playercomm) <> 0		

		----# Get data today from BettransLC for AG Casino and BettransRNG of Metricgaming
		IF @Today <= @todate
		BEGIN 
			INSERT INTO @StatementTable(accdate, refno, totalamt,transtype,transdesc,creator,checkerID, checkerName, checkTime, isAllowVeify)
			SELECT winlostdate accdate
				,0
				,sum(awinlost) totalamt
				,'POS' transtype
				,'Position' transdesc
				,'' Creator
				,NULL
				,''
				,NULL
				,0
			FROM bettransLC WITH (NOLOCK)
			WHERE recommend = @custid
				AND winlostdate = @Today
			GROUP BY winlostdate
			
			UNION ALL
			SELECT winlostdate accdate
				,0
				,sum(comm - playercomm) totalamt
				,'COM' transtype
				,'Commission' transdesc
				,'' Creator
				,NULL
				,''
				,NULL
				,0
			FROM bettransLC WITH (NOLOCK)
			WHERE recommend = @custid
				AND winlostdate = @Today
			GROUP BY winlostdate
			HAVING sum(comm - playercomm) <> 0

			UNION ALL 
			SELECT winlostdate accdate
				,0
				,sum(awinlost) totalamt
				,'POS' transtype
				,'Position' transdesc
				,'' Creator
				,NULL
				,''
				,NULL
				,0
			FROM bettransRNG WITH (NOLOCK)
			WHERE recommend = @custid
				AND winlostdate = @Today
			GROUP BY winlostdate
			HAVING sum(awinlost) <> 0

			UNION ALL
			SELECT winlostdate accdate
				,0
				,sum(comm - playercomm) totalamt
				,'COM' transtype
				,'Commission' transdesc
				,'' Creator
				,NULL
				,''
				,NULL
				,0
			FROM bettransRNG WITH (NOLOCK)
			WHERE recommend = @custid
				AND winlostdate = @Today
			GROUP BY winlostdate
			HAVING sum(comm - playercomm) <> 0


		END 
	END

	-- MASTER
	IF @roleid = 3
	BEGIN
		INSERT INTO @StatementTable(accdate, refno, totalamt,transtype,transdesc,creator,checkerID, checkerName, checkTime, isAllowVeify)
		select 
			transdate accdate,
			refno,
			sum(winlost-actual_stake) totalamt ,
			typenamee transtype,
			transdesc + case when @showExchangeRate = 1 then ' - Ex.Rate: ' + cast(actualrate as varchar(10)) else '' end as transdesc, 
			isnull(c.username,'') Creator,
			case when bettype.typeid IN (20000,23001,23002,23101,23102,23201,23202) then NULL else bettrans.betid end,
			case when bettype.typeid IN (20000,23001,23002,23101,23102,23201,23202) then '0' else bettrans.betcheck end,
			case when bettype.typeid IN (20000,23001,23002,23101,23102,23201,23202) then NULL else bettrans.checkTime end,
			case when bettype.typeid IN (20000,23001,23002,23101,23102,23201,23202) then 0 else 1 end    
		from bettrans with (nolock) 
		inner join bettype  with (nolock) on bettype.typeid=bettrans.bettype 
		left join customer c with (nolock) on bettrans.creator = c.custid 
		where 
			bettype >= 20000 
			and bettrans.custid=@custid 
			and winlostdate between @_FromDate and @_ToDate 
		group by typenamee,
				transdesc + case when @showExchangeRate = 1 then ' - Ex.Rate: ' + cast(actualrate as varchar(10)) else '' end				
				,transdate,transid, bettype.typeid, c.username
				 , bettrans.betid, bettrans.betcheck, bettrans.checkTime, bettrans.refno 				
	
		UNION ALL
		select 
			winlostdate accdate,
			0,
			sum(mwinlost) totalamt,
			'POS' transtype, 
			'Position' transdesc, 
			'' Creator,
			NULL,
			'',
			NULL,
			0 
		from bettrans b with (nolock) 
			LEFT JOIN @SportBettype s ON s.bettype = b.bettype 
		where 
			b.bettype between 1 and 19999 
			and mrecommend=@custid 
			and winlostdate between @_FromDate and @_ToDate 
			AND CASE WHEN (s.productId = 11 OR (s.productId = 13 AND s.SubProduct = 'MGC-RNG'))	AND Winlostdate >= @Today THEN 0 ELSE 1 END = 1
		group by winlostdate 
		having sum(mwinlost) <> 0	
	
		UNION ALL
		select 
			winlostdate accdate,
			0,
			sum(acomm-comm) totalamt,
			'COM' transtype, 
			'Commission' transdesc, '' Creator,
			NULL,
			'',
			NULL,
			0  
		from bettrans b with (nolock)  
			LEFT JOIN @SportBettype s ON s.bettype = b.bettype 
		where 
			b.bettype between 1 and 19999 
			and mrecommend=@custid 
			and winlostdate between @_FromDate and @_ToDate 
			AND CASE WHEN (s.productId = 11 OR (s.productId = 13 AND s.SubProduct = 'MGC-RNG'))	AND Winlostdate >= @Today THEN 0 ELSE 1 END = 1
		group by winlostdate 
		having sum(acomm-comm) <> 0

		
		----# Get data today from BettransLC for AG Casino and BettransRNG of Metricgaming
		IF @Today <= @todate
		BEGIN 
			INSERT INTO @StatementTable(accdate, refno, totalamt,transtype,transdesc,creator,checkerID, checkerName, checkTime, isAllowVeify)
			select 
				winlostdate accdate,
				0,
				sum(mwinlost) totalamt,
				'POS' transtype, 
				'Position' transdesc, 
				'' Creator,
				NULL,
				'',
				NULL,
				0 
			from bettransLC with (nolock) 
			where  
				mrecommend=@custid 
				and winlostdate = @Today
			group by winlostdate 
			having sum(mwinlost) <> 0

			UNION ALL
			select 
				winlostdate accdate,
				0,
				sum(acomm-comm) totalamt,
				'COM' transtype, 
				'Commission' transdesc, '' Creator,
				NULL,
				'',
				NULL,
				0  
			from bettransLC  with (nolock)  
			where 
				mrecommend=@custid 
				and winlostdate = @Today
			group by winlostdate 
			having sum(acomm-comm) <> 0

			UNION ALL
			select 
				winlostdate accdate,
				0,
				sum(mwinlost) totalamt,
				'POS' transtype, 
				'Position' transdesc, 
				'' Creator,
				NULL,
				'',
				NULL,
				0 
			from bettransRNG with (nolock) 
			where  
				mrecommend=@custid 
				and winlostdate = @Today
			group by winlostdate 
			having sum(mwinlost) <> 0

			UNION ALL
			select 
				winlostdate accdate,
				0,
				sum(acomm-comm) totalamt,
				'COM' transtype, 
				'Commission' transdesc, '' Creator,
				NULL,
				'',
				NULL,
				0  
			from bettransRNG with (nolock)  
			where 
				mrecommend=@custid 
				and winlostdate = @Today
			group by winlostdate 
			having sum(acomm-comm) <> 0
		END
	END

	-- SUPER
	IF @roleid = 4
	BEGIN
		INSERT INTO @StatementTable(accdate, refno, totalamt,transtype,transdesc,creator,checkerID, checkerName, checkTime, isAllowVeify)
		select 
			transdate accdate,
			refno,
			sum(winlost-actual_stake) totalamt ,
			typenamee transtype, 
			transdesc + case when @showExchangeRate = 1 then ' - Ex.Rate: ' + cast(actualrate as varchar(10)) else '' end as transdesc, 
			isnull(c.username,'') as Creator,
			case when bettype.typeid IN (20000,23001,23002,23101,23102,23201,23202) then NULL else bettrans.betid end,
			case when bettype.typeid IN (20000,23001,23002,23101,23102,23201,23202) then '0' else bettrans.betcheck end,
			case when bettype.typeid IN (20000,23001,23002,23101,23102,23201,23202) then NULL else bettrans.checkTime end,
			case when bettype.typeid IN (20000,23001,23002,23101,23102,23201,23202) then 0 else 1 end  
		from bettrans with (nolock) 
		inner join  bettype  with (nolock) on bettype.typeid=bettrans.bettype  
		left join customer c with (nolock) on bettrans.creator = c.custid  
		where 
		bettype >= 20000 
		and  bettrans.custid=@custid 
		and bettype.typeid=bettrans.bettype  
		and winlostdate between @_FromDate and @_ToDate 
		group by typenamee,
				transdesc + case when @showExchangeRate = 1 then ' - Ex.Rate: ' + cast(actualrate as varchar(10)) else '' end			
				,transdate,transid, bettype.typeid, c.username
				 , bettrans.betid, bettrans.betcheck, bettrans.checkTime , bettrans.refno
	
		UNION ALL
		select 
			winlostdate accdate,
			0,
			sum(swinlost) totalamt,
			'POS' transtype, 
			'Position' transdesc, 
			'' as Creator,
			NULL,
			'',
			NULL,
			0 
		from bettrans b with (nolock) 
			LEFT JOIN @SportBettype s ON s.bettype = b.bettype 
		where 
			b.bettype between 1 and 19999 
			and srecommend=@custid 
			and winlostdate between @_FromDate and @_ToDate 
			AND CASE WHEN (s.productId = 11 OR (s.productId = 13 AND s.SubProduct = 'MGC-RNG'))	AND Winlostdate >= @Today THEN 0 ELSE 1 END = 1
		group by winlostdate 
		having sum(swinlost) <> 0
	
		UNION ALL
		select 
			winlostdate accdate,
			0,
			sum(scomm-acomm) totalamt,
			'COM' transtype, 
			'Commission' transdesc, 
			'' as Creator,
			NULL,
			'',
			NULL,
			0 
		from bettrans b with (nolock)  
			LEFT JOIN @SportBettype s ON s.bettype = b.bettype 
		where 
			b.bettype between 1 and 19999 
			and srecommend=@custid 
			and winlostdate between @_FromDate and @_ToDate 
			AND CASE WHEN (s.productId = 11 OR (s.productId = 13 AND s.SubProduct = 'MGC-RNG'))	AND Winlostdate >= @Today THEN 0 ELSE 1 END = 1
		group by winlostdate 
		having sum(scomm-acomm) <> 0


		----# Get data today from BettransLC for AG Casino and BettransRNG of Metricgaming
		IF @Today <= @todate
		BEGIN 
			INSERT INTO @StatementTable(accdate, refno, totalamt,transtype,transdesc,creator,checkerID, checkerName, checkTime, isAllowVeify)
			select 
				winlostdate accdate,
				0,
				sum(swinlost) totalamt,
				'POS' transtype, 
				'Position' transdesc, 
				'' as Creator,
				NULL,
				'',
				NULL,
				0 
			from bettransLC with (nolock) 
			where  srecommend=@custid 
				and winlostdate = @Today
			group by winlostdate 
			having sum(swinlost) <> 0

			UNION ALL
			select 
				winlostdate accdate,
				0,
				sum(scomm-acomm) totalamt,
				'COM' transtype, 
				'Commission' transdesc, 
				'' as Creator,
				NULL,
				'',
				NULL,
				0 
			from bettransLC  with (nolock)  
			where 
				srecommend=@custid 
				and winlostdate = @Today
			group by winlostdate 
			having sum(scomm-acomm) <> 0

			UNION ALL
			select 
				winlostdate accdate,
				0,
				sum(swinlost) totalamt,
				'POS' transtype, 
				'Position' transdesc, 
				'' as Creator,
				NULL,
				'',
				NULL,
				0 
			from bettransRNG with (nolock) 
			where  srecommend=@custid 
				and winlostdate = @Today
			group by winlostdate 
			having sum(swinlost) <> 0

			UNION ALL
			select 
				winlostdate accdate,
				0,
				sum(scomm-acomm) totalamt,
				'COM' transtype, 
				'Commission' transdesc, 
				'' as Creator,
				NULL,
				'',
				NULL,
				0 
			from bettransRNG with (nolock)  
			where 
				srecommend=@custid 
				and winlostdate = @Today
			group by winlostdate 
			having sum(scomm-acomm) <> 0
		END
	END

END		   

IF @_FromDate < @_BalanceUpDay
BEGIN
	DECLARE @lateTransaction BIT

	IF @_ToDate >= DATEADD(dd, -1, @_BalanceUpDay)
	BEGIN
		SELECT	@_ToDate = DATEADD(dd, -1, @_BalanceUpDay) + ' 23:59:59',
				@lateTransaction = 1		
	END
	
	SELECT	TOP 1 @_FromDate = ISNULL(accdate,@FromDate)
	FROM	DBRPT.bodb_Report.dbo.Statement with (NOLOCK)
	WHERE	custid = @custid AND transdesc = 'OPENING BALANCE' AND accdate <= @fromdate
	ORDER BY accdate DESC
 
	INSERT INTO @StatementTable(accdate, refno, totalamt,transtype,transtypeid,transdesc,creator,checkerID, checkerName, checkTime, isAllowVeify)
	select 
		accdate,
		0,
		totalamt,
		transtype,
		CASE transtype WHEN 'BET' THEN 1 ELSE 0 END transtypeid,
		CASE WHEN transtype='BET' AND transdesc='Betting' THEN 'Betting Statement'ELSE transdesc END transdesc , 
		'' creator,
		NULL,
		'',
		NULL,
		0 
	from DBRPT.bodb_Report.dbo.Statement with (nolock) 
	WHERE custid = @custid AND accdate between @_FromDate and @_ToDate
	union all --- @Lukas add missing transaction
	select 		 
		accdate,
		0,
		totalamt,
		transtype,
		CASE transtype WHEN 'BET' THEN 1 ELSE 0 END transtypeid,
		CASE WHEN transtype='BET' AND transdesc='Betting' THEN 'Betting Statement'ELSE transdesc END transdesc , 
		'' creator,
		NULL,
		'',
		NULL,
		0 
	from DBRPT.bodb_Report.dbo.Statement with (nolock) 
	WHERE custid = @custid AND accdate > @_ToDate and accdate <= dateadd(day,2,@_ToDate)
			and @lateTransaction = 1 and transtype in ('Dep','Wit')

END

IF (@_IncludeAccBal = 1)
BEGIN
	DECLARE @AccBal money, @BUDate datetime
	
	if (@fromdate_bk <> @_BalanceUpDay)
	BEGIN
		
		IF (@fromdate_bk > @_BalanceUpDay)
		BEGIN
			--get acc bal from current (bettrans)
			SELECT @AccBal = isnull(SUM(totalamt),0)
			FROM @StatementTable
			where accdate < @fromdate_bk
		END
		ELSE 
		BEGIN
			--get latest old BUDate
			select top 1 @BUDate = accdate
			from DBRPT.bodb_Report.dbo.Statement with (NOLOCK)
			where custid = @custid AND transdesc = 'OPENING BALANCE' AND accdate <= @fromdate_bk
			order by accdate desc
			
			--if cannot find any old BU row, get BUDate from last BUDate before @fromdate
			if (@BUDate is NULL) 
			BEGIN
				SET @BUDate = @fromdate_bk
				WHILE(DATEPART(WEEKDAY, @BUDate) <> 7) SET @BUDate = DATEADD(dd, -1, @BUDate)  
			END
			
			--get acc bal from statement old (Statement):		
			SELECT @AccBal = isnull(SUM(totalamt),0)
			FROM DBRPT.bodb_Report.dbo.Statement WITH (NOLOCK) 
			where custid = @custid 
				AND accdate >= @BUDate AND accdate < @fromdate_bk
		END

		IF EXISTS(select 1 from @StatementTable where accdate >= @fromdate_bk AND @AccBal <>0) 
			INSERT INTO @StatementTable(accdate, refno, totalamt,transtype,transdesc,creator,checkerID, checkerName, checkTime, isAllowVeify)
			SELECT '', 0, @AccBal, 'BAL', 'ACCUMULATED BALANCE', NULL,NULL,0, NULL,0

	END
END

SELECT	accdate, refno,totalamt,transtype,transtypeid,transdesc,creator
		,checkerID ,checkerName, checkTime ,isAllowVeify			
FROM @StatementTable
where (accdate >= @fromdate_bk OR transdesc = 'ACCUMULATED BALANCE')
order by accdate, case when transdesc like '%opening balance%' then 1 else 2 end, transtypeid, transdesc


GO 
GRANT EXECUTE ON [Acc_AllStatement_Full] TO  [bodbAdminNet]
GO 
GRANT EXECUTE ON [Acc_AllStatement_Full] TO  [bodbDownlineNet]
GO 
GRANT EXECUTE ON [Acc_AllStatement_Full] TO  [bodbDownlineNetView]
GO 
GRANT EXECUTE ON [Acc_AllStatement_Full] TO  [bodbExtAccNet]
GO 
