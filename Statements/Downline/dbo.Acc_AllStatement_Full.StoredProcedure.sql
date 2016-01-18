ALTER PROCEDURE [dbo].[Acc_AllStatement_Full]
	@custid int,
	@Fromdate datetime,
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
	DB: DBACC/BODB02
	
	Revisions:
		- 20091016@Henry: Create New (Copy logic FROM Acc_AllStatement)
		- 20091223@Daniel: Fix sort issue of OPENNING BAL rows
		- 20100104@Daniel: Fix WHEN @todate < @BUDate, the data always get to @BUDate (should get to @Todate)
		- 20100312@Daniel: If there are no OPENNING BALANCE row, insert an 'Accumulated Balance row' on top to relects the accumulated balance up to the date before "From Date"
		- 20100930@Jamie: Get isShow to check whether display Check box "Verify" or not 
		- 20101007@Anders: Declare local vairable to avoid paramater sniffing, change default checkername FROM '0' to ''
 		- 20101224@Lukas: Re-arrange bettype
 		- 20110713@TOM:Separate the statement by Betting Statement/Void cancelled/Outstanding Bet
 				Add new column transtypeid on data return :
					transtypeid =0-Others ;   
					transtypeid =1-Betting Statement; 
					transtypeid =2-VOID/Cancelled Bet; 
					transtypeid =3-Outstanding Bet
		- 20110720@TOM:Add parameter @MoveBetDay
				Remove CASE of Casino in Outstanding Bet
		- 20110725@Lukas: include refund tickets.
		- 20120405@Hurri: Add bettype 23102 (P2P PENDing) into condition
		- 20120629@Lukas: expand range of date in CASE of @todate > @balanceupdate to avoid missing data
		- 20120701@Thien: fix the sorting, changing FROM CONVERT(VARCHAR(10),accdate,110) to CONVERT(VARCHAR(10),accdate,102)
 		- 20120701@Lukas: Remove unneed code ( convert to smalldatetime to order )
		- 20120723@Thien: Include Exchange rate into Remark field of Statement page
		- 20120817@Lukas: modify code to retrieve all transactions have accdate greater than balanceupdate
		- 20120918@Kiwi: change to use db052
		- 20130129@Dan: add param to show/hide exchange rate (use for external acc), change linked server DB06 to DBRPT
		- 20140214@Lukas: exclude bingo transfer & bingo pENDing transactions
		- 20140305@Dom: Update outstanding for keno
		- 20140929@Daniel: fix bug wrong Accu row in CASE cannot find any BU row before @Fromdate
		- 20150706@Sophia: Do not check ticket running of Metric gaming at bettrans table, because of the translog [#38789]
		- 20150727@Sophia: Apply Bettrade, exclude ticket Bettrade Comm (903) for Void/reject [#36905]
		- 20150903@Sophia: Apply Colossus Bets [#42428]
		- 20151019@Sophia: Apply AG Casino - Add table BettransLC [#43810]
						   Apply MGC - RNG Casino - Add table BettransRNG [#43549]						 
		- 20151113@Sophia: Change Sporttype of Microgaming RNG Casino [RedmineId: #46450] 
		- 20151221@Sophia: Exclude Cockfighting from bettrans table in case there is running ticket on bettrans [Redmine: #48602]
		- 20160108@Sophia: Change request for Colossus bet [Redmin: #49967]
		- 20160108@Sophia: Apply MBC One RNG Casino [Redmine: #48285]

	Param explanation : 
		- Transtypeid = 4 - GrandPrize

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
SET @_FromDate = @Fromdate

DECLARE @_BalanceUpDay AS SMALLDATETIME
SET @_BalanceUpDay = @BalanceUpDay

DECLARE @Fromdate_bk SMALLDATETIME
SET @Fromdate_bk = @_FromDate

DECLARE @_IncludeAccBal AS BIT
SET @_IncludeAccBal = @IncludeAccBal

DECLARE @Yesterday SMALLDATETIME 
SELECT @Yesterday =  CONVERT(Date,DATEADD(DD, -1, GETDATE()))
		
----Get Sport Bettype Matrix------

		DECLARE @SportBettype TABLE(ProductID INT, Bettype INT,EventType INT, SubProduct VARCHAR(500), IsUsedBettrans BIT DEFAULT 0, IsRunningTranslog BIT DEFAULT 0)
		INSERT INTO @SportBettype (ProductID, Bettype, EventType, SubProduct)
		EXEC bodb02.dbo.Acc_SportBettypeMatrix_Sel @mode = 5 
	
		DELETE @SportBettype WHERE	ProductID NOT IN (11, 13, 17, 19, 1, 6) -- AG-Casino, MGC-LC, MGC-RNG, Cockfighting
									OR (ProductId = 1 AND SubProduct <> 'MG-Superlive') --MG-Superlive
									OR (ProductID = 6 AND SubProduct = '') --- Old RNG Casino 

		-- Tickets not check in bettrans on Yesterday and Today: AG-Casino, MGC-RNG, MBC-OneRnG
		UPDATE @SportBettype
		SET IsUsedBettrans = 1
		WHERE ProductID NOT IN (11, 17, 6)
	
		-- Tickets running in translog and exlude from bettrans: MG-Superlive, MGC-LC, Cock Fighting
		UPDATE @SportBettype
		SET IsRunningTranslog = 1
		WHERE ProductId IN (1, 13, 19)

		 
--------------------------------------

IF @_ToDate >= @_BalanceUpDay
BEGIN
	--always Get all data FROM latest BUDate -> @todate for calculating ACCUMULATED BALANCE row
	IF (@_FromDate > @_BalanceUpDay)
	BEGIN
		SELECT @Fromdate_bk = @_FromDate
		SELECT @_FromDate = @_BalanceUpDay
	END	
 
	IF @roleid = 1
	BEGIN
		------------1. Betting, Void/Reject, Outstanding  
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
				--AND CASE WHEN ((s.productId = 1 AND s.SubProduct = 'MG-SuperLive' ) OR (s.productId = 19)) AND StatusID IN (0,1) THEN 0 ELSE 1 END = 1 
				--AND CASE WHEN (s.productId = 11 OR s.productId = 17) THEN 0 ELSE 1 END = 1
				------AND statusID <> 103
				AND (Winlostdate < @Yesterday 
					 OR (Winlostdate >= @Yesterday AND (s.IsUsedBettrans IS NULL 
														OR s.IsUsedBettrans = 1 														
														)
						)
					 OR (s.IsUsedBettrans = 1 AND s.IsRunningTranslog = 0 AND StatusID IN (0,1))
					)	
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

			----1.3 Get data FROM BettransLC for AG Casino  			
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
					AND winlostdate BETWEEN @_FromDate and @_ToDate
					AND (winlostdate >= @Yesterday 
						 OR StatusID IN (0,1) 
						 )
				GROUP BY winlostdate, GameId,
					CASE
						WHEN statusID IN (102,101) THEN 102--'VOID','REJECT'
						WHEN statusID IN (0,1) THEN 0--'running', 'waiting'
					ELSE 131 END	
				
				----1.4 Get data today FROM BettransRNG for Microgaming
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
					AND winlostdate BETWEEN @_FromDate and @_ToDate
					AND (winlostdate >= @Yesterday
						OR StatusID IN (0,1) 
						)
				GROUP BY winlostdate, GameId,
					CASE
						WHEN statusID IN (102,101) THEN 102--'VOID','REJECT'
						WHEN statusID IN (0,1) THEN 0--'running', 'waiting'
					ELSE 131 END					 
			
		
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

		  
		--------------2.Grand Prize 
		----2.1 bettrans
		--IF @_Todate >= @MoveBetDay
		--BEGIN 
		--	INSERT INTO @StatementTable(accdate, refno, totalamt,transtype,transtypeid,transdesc,creator,checkerID, checkerName, checkTime, isAllowVeify)
		--	SELECT b.winlostdate AS accdate
		--		,b.RefNo as refno
		--		,sum(bm.winlost - bm.stake) AS totalamt
		--		,'GP' transtype
		--		,4 transtypeid
		--		,'Grand Prize' transdesc
		--		,'' Creator
		--		,NULL checkerID
		--		,'' checkerName
		--		,NULL checkTime
		--		,0 isAllowVeify
		--	FROM bettrans b WITH (NOLOCK)
		--		INNER JOIN BettransM bm WITH (NOLOCK)
		--			ON b.RefNo = bm.RefNo
		--	WHERE b.bettype = 18000
		--		AND b.custid = @custid
		--		AND b.winlostdate BETWEEN @MoveBetDay AND @_ToDate
		--		AND b.Ruben = 1
		--		AND bm.statuswinlost <> 0
		--	GROUP BY b.RefNo, b.winlostdate
		--END
		
		--IF @_FromDate <= @MoveBetDay
		--BEGIN 
		--	INSERT INTO @StatementTable(accdate, refno, totalamt,transtype,transtypeid,transdesc,creator,checkerID, checkerName, checkTime, isAllowVeify)
		--	SELECT b.winlostdate AS accdate
		--		,b.RefNo as  refno
		--		,sum(bm.winlost - bm.stake) AS totalamt
		--		,'GP' transtype
		--		, 4 transtypeid
		--		,'Grand Prize' transdesc
		--		,'' Creator
		--		,NULL checkerID
		--		,'' checkerName
		--		,NULL checkTime
		--		,0 isAllowVeify
		--	FROM bettrans14 b WITH (NOLOCK)
		--		INNER JOIN BettransM14 bm WITH (NOLOCK)
		--			ON b.RefNo = bm.RefNo
		--	WHERE b.bettype = 18000
		--		AND b.custid = @custid
		--		AND b.winlostdate BETWEEN @_FromDate AND @MoveBetDay
		--		AND b.Ruben = 1
		--		AND bm.statuswinlost <> 0
		--	GROUP BY b.RefNo, b.winlostdate
		--END

		
		---2.2 PayoutTrans - Grand Prize of Microgaming RNG Casino	 			
		INSERT INTO @StatementTable(accdate, refno, totalamt,transtype,transtypeid,transdesc,creator,checkerID, checkerName, checkTime, isAllowVeify)
		SELECT winlostdate AS accdate
			,refno as refno
			,SUM (WinAmount) AS totalamt
			,'GP' transtype
			, 4 transtypeid
			,'Grand Prize' transdesc
			,'' Creator
			,NULL checkerID
			,'' checkerName
			,NULL checkTime
			,0 isAllowVeify
		FROM dbo.PayoutTrans WITH(NOLOCK) 
		WHERE	winlostdate BETWEEN @Fromdate AND @todate
				AND custid = @custid 
				AND PayoutStatusId = 4 ---Completed	 		
		GROUP BY refno, winlostdate, custid				
			 

		--------------------------------------------------------------
		INSERT INTO @StatementTable(accdate, refno, totalamt,transtype,transdesc,creator,checkerID, checkerName, 
					checkTime, isAllowVeify)
	
		---------------3. Comm, Transfer
		---3.1 bettrans
		SELECT 
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
		FROM bettrans b WITH (NOLOCK)  
			LEFT JOIN @SportBettype s ON s.bettype = b.bettype 
		WHERE 
			b.bettype between 1 and 19999 
			and custid=@custid 
			and winlostdate between @_FromDate and @_ToDate 
			---AND CASE WHEN (s.productId = 11 OR s.productId = 17) THEN 0 ELSE 1 END = 1
			and playercomm<>0 
			AND (Winlostdate < @Yesterday 
				 OR (Winlostdate >= @Yesterday AND (s.IsUsedBettrans IS NULL OR s.IsUsedBettrans = 1))
				)
		GROUP BY winlostdate

		UNION ALL
		SELECT 
			transdate accdate,
			refno,
			sum(winlost-actual_stake) totalamt,
			typenamee transtype,
			transdesc + CASE WHEN @showExchangeRate = 1 THEN ' - Ex.Rate: ' + cast(actualrate as varchar(10)) ELSE '' END as transdesc, 
			isnull(c.username,'') Creator,
			CASE WHEN bettype.typeid IN (20000,23001,23002,23101,23102,23201,23202) THEN NULL ELSE bettrans.betid END, --BalanceUP AND Transfer to Casino/Bingo/P2P
			CASE WHEN bettype.typeid IN (20000,23001,23002,23101,23102,23201,23202) THEN '0' ELSE bettrans.betcheck END,
			CASE WHEN bettype.typeid IN (20000,23001,23002,23101,23102,23201,23202) THEN NULL ELSE bettrans.checkTime END,
			CASE WHEN bettype.typeid IN (20000,23001,23002,23101,23102,23201,23202) THEN 0 ELSE 1 END   
		FROM bettrans  WITH (NOLOCK) inner join bettype WITH (NOLOCK) on bettype.typeid=bettrans.bettype 
		left join customer c WITH (NOLOCK) on bettrans.creator = c.custid 
		WHERE 
			bettype >= 20000 
			and bettrans.custid=@custid 
			and bettype.typeid NOT IN (23001,23002,23101,23102,23201,23202) AND (winlost-actual_stake) <> 0 
			and winlostdate between @_FromDate and @_ToDate 
		GROUP BY typenamee,
				transdesc + CASE WHEN @showExchangeRate = 1 THEN ' - Ex.Rate: ' + cast(actualrate as varchar(10)) ELSE '' END
				,transdate,transid, bettype.typeid,c.username
				,bettrans.betid, bettrans.betcheck, bettrans.checkTime, bettrans.refno 


		---3.2 BettransLC for AG Casino
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
			AND winlostdate BETWEEN @_FromDate and @_ToDate
			AND playercomm <> 0
			AND Winlostdate >= @Yesterday
		GROUP BY winlostdate

		----3.3 BettransRNG for Microgaming RNG Casino
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
			AND winlostdate BETWEEN @_FromDate and @_ToDate
			AND playercomm <> 0
			AND Winlostdate >= @Yesterday
		GROUP BY winlostdate


		-------------4. Cancelled/Deleted Bets
		IF @_FromDate <= @MoveBetDay
			INSERT INTO @StatementTable(accdate, refno, totalamt,transtype,transtypeid,transdesc,creator,checkerID, checkerName, 
							checkTime, isAllowVeify)
			SELECT DISTINCT
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
			FROM zzzbettrans b WITH (NOLOCK)
				INNER JOIN Match m  WITH (NOLOCK)
					ON m.matchid = b.matchid
			WHERE 
				bettype between 1 and 19999 
				AND Bettype <> 903
				and custid=@custid 
				and eventdate between @_FromDate and @MoveBetDay 
			GROUP BY eventdate
			
			--Remove All
			UNION ALL
			SELECT DISTINCT
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
			FROM zzzbettrans b WITH (NOLOCK)
				INNER JOIN match14 m WITH (NOLOCK)
					ON m.matchid = b.matchid
			WHERE 
				bettype between 1 and 19999 
				AND Bettype <> 903
				and custid=@custid 
				and eventdate between @_FromDate and @MoveBetDay 
		GROUP BY eventdate

	END

	-- AGENT
	IF @roleid = 2 
	BEGIN
		---------------1. Transfer	
		INSERT INTO @StatementTable(accdate, refno, totalamt,transtype,transdesc,creator,checkerID, checkerName, checkTime, isAllowVeify)	
		SELECT 
			transdate accdate,
			refno,
			sum(winlost-actual_stake) totalamt ,
			typenamee transtype,
			transdesc + CASE WHEN @showExchangeRate = 1 THEN ' - Ex.Rate: ' + cast(actualrate as varchar(10)) ELSE '' END as transdesc , 			
			isnull(c.username,'') Creator,
			CASE WHEN bettype.typeid IN (20000,23001,23002,23101,23102,23201,23202) THEN NULL ELSE bettrans.betid END,
			CASE WHEN bettype.typeid IN (20000,23001,23002,23101,23102,23201,23202) THEN '0' ELSE bettrans.betcheck END,
			CASE WHEN bettype.typeid IN (20000,23001,23002,23101,23102,23201,23202) THEN NULL ELSE bettrans.checkTime END,
			CASE WHEN bettype.typeid IN (20000,23001,23002,23101,23102,23201,23202) THEN 0 ELSE 1 END   
		FROM bettrans WITH (NOLOCK) 
		inner join bettype WITH (NOLOCK) on bettype.typeid=bettrans.bettype 
		left join customer c WITH (NOLOCK) on bettrans.creator = c.custid 
		WHERE 
			bettype >= 20000 
			and bettrans.custid=@custid 
			and winlostdate between @_FromDate and @_ToDate 
			GROUP BY typenamee,
				transdesc + CASE WHEN @showExchangeRate = 1 THEN ' - Ex.Rate: ' + cast(actualrate as varchar(10)) ELSE '' END
				,transdate,transid, bettype.typeid, c.username
				, bettrans.betid, bettrans.betcheck, bettrans.checkTime, bettrans.refno
			
		---------------2. POS, COM
		--- 2.1. Bettrans
		UNION ALL
		SELECT 
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
		FROM bettrans b WITH (NOLOCK) 
			LEFT JOIN @SportBettype s ON s.bettype = b.bettype 
		WHERE 
			b.bettype between 1 and 19999 
			and recommend=@custid 
			and winlostdate between @_FromDate and @_ToDate 
			---AND CASE WHEN (s.productId = 11 OR s.productId = 17)	THEN 0 ELSE 1 END = 1
			AND (Winlostdate < @Yesterday 
				 OR (Winlostdate >= @Yesterday AND (s.IsUsedBettrans IS NULL OR s.IsUsedBettrans = 1))
				)

		GROUP BY winlostdate 
		HAVING sum(awinlost) <> 0
		
		UNION ALL
		SELECT 
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
		FROM bettrans b WITH (NOLOCK)  
			LEFT JOIN @SportBettype s ON s.bettype = b.bettype 
		WHERE 
			b.bettype between 1 and 19999 
			and recommend=@custid 
			and winlostdate between @_FromDate and @_ToDate 
			---AND CASE WHEN (s.productId = 11 OR s.productId = 17) THEN 0 ELSE 1 END = 1
			AND (Winlostdate < @Yesterday 
				 OR (Winlostdate >= @Yesterday AND (s.IsUsedBettrans IS NULL OR s.IsUsedBettrans = 1))
				)
		GROUP BY winlostdate 
		HAVING sum(comm-playercomm) <> 0		

		---2.2 BettransLC
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
		FROM bettransLC WITH (NOLOCK)
		WHERE recommend = @custid
			AND winlostdate BETWEEN @_FromDate and @_ToDate
			AND winlostdate >= @Yesterday
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
			AND winlostdate BETWEEN @_FromDate and @_ToDate
			AND winlostdate >= @Yesterday
		GROUP BY winlostdate
		HAVING sum(comm - playercomm) <> 0

		----2.3 BettransRNG
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
			AND winlostdate BETWEEN @_FromDate and @_ToDate
			AND winlostdate >= @Yesterday
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
		WHERE recommEND = @custid
			AND winlostdate BETWEEN @_FromDate and @_ToDate
			AND winlostdate >= @Yesterday
		GROUP BY winlostdate
		HAVING sum(comm - playercomm) <> 0
		 
	END

	-- MASTER
	IF @roleid = 3
	BEGIN
		--------1. Transfer
		INSERT INTO @StatementTable(accdate, refno, totalamt,transtype,transdesc,creator,checkerID, checkerName, checkTime, isAllowVeify)
		SELECT 
			transdate accdate,
			refno,
			sum(winlost-actual_stake) totalamt ,
			typenamee transtype,
			transdesc + CASE WHEN @showExchangeRate = 1 THEN ' - Ex.Rate: ' + cast(actualrate as varchar(10)) ELSE '' END as transdesc, 
			isnull(c.username,'') Creator,
			CASE WHEN bettype.typeid IN (20000,23001,23002,23101,23102,23201,23202) THEN NULL ELSE bettrans.betid END,
			CASE WHEN bettype.typeid IN (20000,23001,23002,23101,23102,23201,23202) THEN '0' ELSE bettrans.betcheck END,
			CASE WHEN bettype.typeid IN (20000,23001,23002,23101,23102,23201,23202) THEN NULL ELSE bettrans.checkTime END,
			CASE WHEN bettype.typeid IN (20000,23001,23002,23101,23102,23201,23202) THEN 0 ELSE 1 END    
		FROM bettrans WITH (NOLOCK) 
		inner join bettype  WITH (NOLOCK) on bettype.typeid=bettrans.bettype 
		left join customer c WITH (NOLOCK) on bettrans.creator = c.custid 
		WHERE 
			bettype >= 20000 
			and bettrans.custid=@custid 
			and winlostdate between @_FromDate and @_ToDate 
		GROUP BY typenamee,
				transdesc + CASE WHEN @showExchangeRate = 1 THEN ' - Ex.Rate: ' + cast(actualrate as varchar(10)) ELSE '' END				
				,transdate,transid, bettype.typeid, c.username
				 , bettrans.betid, bettrans.betcheck, bettrans.checkTime, bettrans.refno 				
	
		---------------2. POS, COM
		--- 2.1. Bettrans
		UNION ALL
		SELECT 
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
		FROM bettrans b WITH (NOLOCK) 
			LEFT JOIN @SportBettype s ON s.bettype = b.bettype 
		WHERE 
			b.bettype between 1 and 19999 
			and mrecommEND=@custid 
			and winlostdate between @_FromDate and @_ToDate 
			---AND CASE WHEN (s.productId = 11 OR s.productId = 17) THEN 0 ELSE 1 END = 1
			AND (Winlostdate < @Yesterday 
				 OR (Winlostdate >= @Yesterday AND (s.IsUsedBettrans IS NULL OR s.IsUsedBettrans = 1))
				)
		GROUP BY winlostdate 
		HAVING sum(mwinlost) <> 0	
	
		UNION ALL
		SELECT 
			winlostdate accdate,
			0,
			sum(acomm-comm) totalamt,
			'COM' transtype, 
			'Commission' transdesc, '' Creator,
			NULL,
			'',
			NULL,
			0  
		FROM bettrans b WITH (NOLOCK)  
			LEFT JOIN @SportBettype s ON s.bettype = b.bettype 
		WHERE 
			b.bettype between 1 and 19999 
			and mrecommEND=@custid 
			and winlostdate between @_FromDate and @_ToDate 
			---AND CASE WHEN (s.productId = 11 OR s.productId = 17) THEN 0 ELSE 1 END = 1
			AND (Winlostdate < @Yesterday 
				 OR (Winlostdate >= @Yesterday AND (s.IsUsedBettrans IS NULL OR s.IsUsedBettrans = 1))
				)
		GROUP BY winlostdate 
		HAVING sum(acomm-comm) <> 0

		
		---2.2 BettransLC
			UNION ALL
			SELECT 
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
			FROM bettransLC WITH (NOLOCK) 
			WHERE  
				mrecommEND=@custid 
				and winlostdate BETWEEN @_FromDate and @_ToDate
				AND winlostdate >= @Yesterday
			GROUP BY winlostdate 
			HAVING sum(mwinlost) <> 0

			UNION ALL
			SELECT 
				winlostdate accdate,
				0,
				sum(acomm-comm) totalamt,
				'COM' transtype, 
				'Commission' transdesc, '' Creator,
				NULL,
				'',
				NULL,
				0  
			FROM bettransLC  WITH (NOLOCK)  
			WHERE 
				mrecommEND=@custid 
				and winlostdate BETWEEN @_FromDate and @_ToDate
				AND winlostdate >= @Yesterday
			GROUP BY winlostdate 
			HAVING sum(acomm-comm) <> 0

			---2.3 BettransRNG
			UNION ALL
			SELECT 
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
			FROM bettransRNG WITH (NOLOCK) 
			WHERE  
				mrecommEND=@custid 
				and winlostdate BETWEEN @_FromDate and @_ToDate
				AND winlostdate >= @Yesterday
			GROUP BY winlostdate 
			HAVING sum(mwinlost) <> 0

			UNION ALL
			SELECT 
				winlostdate accdate,
				0,
				sum(acomm-comm) totalamt,
				'COM' transtype, 
				'Commission' transdesc, '' Creator,
				NULL,
				'',
				NULL,
				0  
			FROM bettransRNG WITH (NOLOCK)  
			WHERE 
				mrecommEND=@custid 
				and winlostdate BETWEEN @_FromDate and @_ToDate
				AND winlostdate >= @Yesterday
			GROUP BY winlostdate 
			HAVING sum(acomm-comm) <> 0
	END

	-- SUPER
	IF @roleid = 4
	BEGIN
		--------1.Transfer
		INSERT INTO @StatementTable(accdate, refno, totalamt,transtype,transdesc,creator,checkerID, checkerName, checkTime, isAllowVeify)
		SELECT 
			transdate accdate,
			refno,
			sum(winlost-actual_stake) totalamt ,
			typenamee transtype, 
			transdesc + CASE WHEN @showExchangeRate = 1 THEN ' - Ex.Rate: ' + cast(actualrate as varchar(10)) ELSE '' END as transdesc, 
			isnull(c.username,'') as Creator,
			CASE WHEN bettype.typeid IN (20000,23001,23002,23101,23102,23201,23202) THEN NULL ELSE bettrans.betid END,
			CASE WHEN bettype.typeid IN (20000,23001,23002,23101,23102,23201,23202) THEN '0' ELSE bettrans.betcheck END,
			CASE WHEN bettype.typeid IN (20000,23001,23002,23101,23102,23201,23202) THEN NULL ELSE bettrans.checkTime END,
			CASE WHEN bettype.typeid IN (20000,23001,23002,23101,23102,23201,23202) THEN 0 ELSE 1 END  
		FROM bettrans WITH (NOLOCK) 
		inner join  bettype  WITH (NOLOCK) on bettype.typeid=bettrans.bettype  
		left join customer c WITH (NOLOCK) on bettrans.creator = c.custid  
		WHERE 
		bettype >= 20000 
		and  bettrans.custid=@custid 
		and bettype.typeid=bettrans.bettype  
		and winlostdate between @_FromDate and @_ToDate 
		GROUP BY typenamee,
				transdesc + CASE WHEN @showExchangeRate = 1 THEN ' - Ex.Rate: ' + cast(actualrate as varchar(10)) ELSE '' END			
				,transdate,transid, bettype.typeid, c.username
				 , bettrans.betid, bettrans.betcheck, bettrans.checkTime , bettrans.refno
	
		--------2. POS, COM
		---2.1.bettrans
		UNION ALL
		SELECT 
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
		FROM bettrans b WITH (NOLOCK) 
			LEFT JOIN @SportBettype s ON s.bettype = b.bettype 
		WHERE 
			b.bettype between 1 and 19999 
			and srecommend=@custid 
			and winlostdate between @_FromDate and @_ToDate 
			---AND CASE WHEN (s.productId = 11 OR s.productId = 17)	THEN 0 ELSE 1 END = 1
			AND (Winlostdate < @Yesterday 
				 OR (Winlostdate >= @Yesterday AND (s.IsUsedBettrans IS NULL OR s.IsUsedBettrans = 1))
				)
		GROUP BY winlostdate 
		HAVING sum(swinlost) <> 0
	
		UNION ALL
		SELECT 
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
		FROM bettrans b WITH (NOLOCK)  
			LEFT JOIN @SportBettype s ON s.bettype = b.bettype 
		WHERE 
			b.bettype between 1 and 19999 
			and srecommend=@custid 
			and winlostdate between @_FromDate and @_ToDate 
			--AND CASE WHEN (s.productId = 11 OR s.productId = 17)	THEN 0 ELSE 1 END = 1
			AND (Winlostdate < @Yesterday 
				 OR (Winlostdate >= @Yesterday AND (s.IsUsedBettrans IS NULL OR s.IsUsedBettrans = 1))
				)
		GROUP BY winlostdate 
		HAVING sum(scomm-acomm) <> 0


		----2.2.bettransLC
		UNION ALL
		Select 
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
		FROM bettransLC WITH (NOLOCK) 
		WHERE  srecommend=@custid 
			and winlostdate BETWEEN @_FromDate and @_ToDate
			AND winlostdate >= @Yesterday
		GROUP BY winlostdate 
		HAVING sum(swinlost) <> 0

		UNION ALL
		SELECT 
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
		FROM bettransLC  WITH (NOLOCK)  
		WHERE 
			srecommend=@custid 
			and winlostdate BETWEEN @_FromDate and @_ToDate
			AND winlostdate >= @Yesterday
		GROUP BY winlostdate 
		HAVING sum(scomm-acomm) <> 0

		---2.3.BettransRNG
		UNION ALL
		SELECT 
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
		FROM bettransRNG WITH (NOLOCK) 
		WHERE  srecommend=@custid 
			and winlostdate BETWEEN @_FromDate and @_ToDate
			AND winlostdate >= @Yesterday
		GROUP BY winlostdate 
		HAVING sum(swinlost) <> 0

		UNION ALL
		SELECT 
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
		FROM bettransRNG WITH (NOLOCK)  
		WHERE 
			srecommend=@custid 
			and winlostdate BETWEEN @_FromDate and @_ToDate
			AND winlostdate >= @Yesterday
		GROUP BY winlostdate 
		HAVING sum(scomm-acomm) <> 0
		
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
	
	SELECT	TOP 1 @_FromDate = ISNULL(accdate,@Fromdate)
	FROM	DBRPT.bodb_Report.dbo.Statement with (NOLOCK)
	WHERE	custid = @custid AND transdesc = 'OPENING BALANCE' AND accdate <= @Fromdate
	ORDER BY accdate DESC
 
	INSERT INTO @StatementTable(accdate, refno, totalamt,transtype,transtypeid,transdesc,creator,checkerID, checkerName, checkTime, isAllowVeify)
	SELECT 
		accdate,
		0,
		totalamt,
		transtype,
		CASE transtype  
			WHEN 'BET' THEN 1 
			WHEN  'GP' THEN 4 
			ELSE 0 END transtypeid,
		CASE WHEN transtype='BET' AND transdesc='Betting' THEN 'Betting Statement'ELSE transdesc END transdesc , 
		'' creator,
		NULL,
		'',
		NULL,
		0 
	FROM DBRPT.bodb_Report.dbo.Statement WITH (NOLOCK) 
	WHERE custid = @custid AND accdate between @_FromDate and @_ToDate
	
	UNION ALL --- @Lukas add missing transaction
	SELECT 		 
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
	FROM DBRPT.bodb_Report.dbo.Statement WITH (NOLOCK) 
	WHERE custid = @custid AND accdate > @_ToDate and accdate <= dateadd(day,2,@_ToDate)
			and @lateTransaction = 1 and transtype in ('Dep','Wit')

END

IF (@_IncludeAccBal = 1)
BEGIN
	DECLARE @AccBal money, @BUDate datetime
	
	if (@Fromdate_bk <> @_BalanceUpDay)
	BEGIN
		
		IF (@Fromdate_bk > @_BalanceUpDay)
		BEGIN
			--get acc bal FROM current (bettrans)
			SELECT @AccBal = isnull(SUM(totalamt),0)
			FROM @StatementTable
			WHERE accdate < @Fromdate_bk
		END
		ELSE 
		BEGIN
			--get latest old BUDate
			SELECT top 1 @BUDate = accdate
			FROM DBRPT.bodb_Report.dbo.Statement with (NOLOCK)
			WHERE custid = @custid AND transdesc = 'OPENING BALANCE' AND accdate <= @Fromdate_bk
			order by accdate desc
			
			--if cannot find any old BU row, get BUDate FROM last BUDate before @Fromdate
			if (@BUDate is NULL) 
			BEGIN
				SET @BUDate = @Fromdate_bk
				WHILE(DATEPART(WEEKDAY, @BUDate) <> 7) SET @BUDate = DATEADD(dd, -1, @BUDate)  
			END
			
			--get acc bal FROM statement old (Statement):		
			SELECT @AccBal = isnull(SUM(totalamt),0)
			FROM DBRPT.bodb_Report.dbo.Statement WITH (NOLOCK) 
			WHERE custid = @custid 
				AND accdate >= @BUDate AND accdate < @Fromdate_bk
		END

		IF EXISTS(SELECT 1 FROM @StatementTable WHERE accdate >= @Fromdate_bk AND @AccBal <>0) 
			INSERT INTO @StatementTable(accdate, refno, totalamt,transtype,transdesc,creator,checkerID, checkerName, checkTime, isAllowVeify)
			SELECT '', 0, @AccBal, 'BAL', 'ACCUMULATED BALANCE', NULL,NULL,0, NULL,0

	END
END

SELECT	accdate, refno,totalamt,transtype,transtypeid,transdesc,creator
		,checkerID ,checkerName, checkTime ,isAllowVeify			
FROM @StatementTable
WHERE (accdate >= @Fromdate_bk OR transdesc = 'ACCUMULATED BALANCE')
ORDER BY accdate, CASE WHEN transdesc like '%opening balance%' THEN 1 ELSE 2 END, transtypeid, transdesc


GO 
GRANT EXECUTE ON [Acc_AllStatement_Full] TO  [bodbAdminNet]
GO 
GRANT EXECUTE ON [Acc_AllStatement_Full] TO  [bodbDownlineNet]
GO 
GRANT EXECUTE ON [Acc_AllStatement_Full] TO  [bodbDownlineNetView]
GO 
GRANT EXECUTE ON [Acc_AllStatement_Full] TO  [bodbExtAccNet]
GO 
