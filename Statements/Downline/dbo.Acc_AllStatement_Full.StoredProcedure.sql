USE [bodb02]
GO

ALTER PROCEDURE [dbo].[Acc_AllStatement_Full]
	@custid				INT,
	@Fromdate			DATETIME,
	@todate				DATETIME,
	@BalanceUpDay		DATETIME,
	@MoveBetDay			DATETIME,
	@IncludeAccBal		BIT = 1,
	@showExchangeRate	BIT = 1
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
		- 20160121@Sophia: Apply MBC One RNG Casino [Redmine: #48285]
		- 20160215@Sophia: Change datatype to datetime instead of Smalldatetime [Redmine: #52130]
		- 20160328@Sophia: Check status Of PayOutTrans, get status Completed and Expired [Redmine: #54643]
		- 20160216@Sophia: Apply Allbet [Redmine: #50588]
		- 20160404@Sophia: Exclude GrandPrize out of ACCUMULATED BALANCE [Redmine: #55397]
		- 20160328@Sophia: Check status Of PayOutTrans, get status Completed and Expired [Redmine: #54643]
		- 20160412@Percy: support Voidbridge single wallet [Redmine: #55258]
		
	Param explanation : 
		- Transtypeid = 4 - GrandPrize

 */
SET NOCOUNT ON

DECLARE @roleid INT
SELECT  @roleid = roleid FROM customer WITH (NOLOCK) WHERE custid = @custid

DECLARE @StatementTable TABLE
(
	accdate			DATETIME,
	refno			BIGINT,
	totalamt		MONEY,
	transtype		NVARCHAR(100),
	transtypeid		TINYINT DEFAULT 0,
	transdesc		NVARCHAR(350),
	creator			VARCHAR(50),
	checkerID		INT NULL,
	checkerName		VARCHAR(50) NULL,
	checkTime		DATETIME NULL,
	isAllowVeify	BIT DEFAULT 0-- display check box "Verify"
)

DECLARE @_FromDate DATETIME, @_ToDate DATETIME, @_BalanceUpDay DATETIME, @Fromdate_bk DATETIME, @_IncludeAccBal BIT
SELECT  @_FromDate = @Fromdate, @_ToDate = @todate, @_BalanceUpDay = @BalanceUpDay, @Fromdate_bk = @Fromdate, @_IncludeAccBal = @IncludeAccBal

DECLARE @Yesterday DATETIME 
SELECT  @Yesterday = CONVERT(DATE, DATEADD(DD, -1, GETDATE()))
		
----Get Sport Bettype Matrix------
DECLARE @isTest BIT = 0
SELECT  @isTest = dbo.f_CheckSPVersion(@@PROCID)

CREATE TABLE #SportBettype (ProductID INT, Bettype INT, RefTable TINYINT)
INSERT INTO #SportBettype (ProductID, Bettype, RefTable)
SELECT ProductID, Bettype, RefTable FROM dbo.f_SportBettypeMatrix_Sel(0, 0, 0, 2, '', '', @isTest)
-- RefTable: 0-bettrans, 1-bettransRnG, 2-bettransLC, 3-translog

IF @_ToDate >= @_BalanceUpDay
BEGIN
	-- always get all data from latest BUDate -> @todate for calculating ACCUMULATED BALANCE row
	IF (@_FromDate > @_BalanceUpDay)
	BEGIN
		SELECT @Fromdate_bk = @_FromDate
		SELECT @_FromDate = @_BalanceUpDay
	END	

	-- Customer
	IF @roleid = 1
	BEGIN
		------------1. Betting, Void/Reject, Outstanding
		;WITH cte_bet (winlostdate, bettype, statusID, transdate, transdesc, stake, actual_stake, winlost, playercomm) AS
		(
			---- 1.1 bettrans
			SELECT
				winlostdate,
				b.bettype,
				CASE
					WHEN statusID IN (102, 101) THEN 102 -- 'VOID', 'REJECT'
					WHEN statusID IN (0, 1) THEN 0 -- 'running', 'waiting'
					ELSE 131 END AS statusID,
				CASE WHEN b.bettype <= 19999 THEN NULL ELSE transdate END AS transdate,
				CASE WHEN b.bettype <= 19999 THEN '' ELSE transdesc END AS transdesc,
				SUM(CASE WHEN b.bettype IN (33, 43) AND liveawayscore = 0 AND livehomescore <> 0 AND ruben = 1 THEN b.stake/2 ELSE b.stake END) AS stake,
				SUM(actual_stake) AS actual_stake,
				SUM(winlost) AS winlost,
				SUM(playercomm) AS playercomm
			FROM
				bettrans b WITH (NOLOCK)
				LEFT JOIN #SportBettype s ON s.bettype = b.bettype 
			WHERE
				custid = @custid
				AND winlostdate BETWEEN @_FromDate AND @_ToDate
				AND (
					winlostdate < @Yesterday
					OR (winlostdate >= @Yesterday AND ISNULL(s.RefTable, 0) NOT IN (1, 2))
				)
				AND (
					statusID NOT IN (0, 1)
					OR (statusID IN (0, 1) AND ISNULL(s.RefTable, 0) NOT IN (1, 2, 3))
				)
			GROUP BY winlostdate, b.bettype,
				CASE
					WHEN statusID IN (102,101) THEN 102
					WHEN statusID IN (0,1) THEN 0
					ELSE 131 END,
				CASE WHEN b.bettype <= 19999 THEN NULL ELSE transdate END,
				CASE WHEN b.bettype <= 19999 THEN '' ELSE transdesc END			
			
			---- 1.2 translog
			UNION ALL
			SELECT
				winlostdate, 
				GameId, 
				0 AS StatusID,
				NULL AS transdate,
				'' AS transdesc,
				SUM(stake),
				SUM(actual_stake),
				0 AS winlost,
				0 AS playercomm
			FROM translog WITH (NOLOCK)
			WHERE
				custid = @custid
				AND winlostdate BETWEEN @_FromDate AND @_ToDate
				AND statusID = 0
			GROUP BY GameId, winlostdate

			---- 1.3 bettransLC
			UNION ALL
			SELECT
				winlostdate,
				GameId,
				CASE WHEN statusID IN (0,1) THEN 0 ELSE 131 END,
				NULL transdate,
				'' transdesc,
				SUM(stake),
				SUM(actual_stake),
				SUM(winlost),
				SUM(playercomm)
			FROM bettransLC WITH (NOLOCK)
			WHERE
				custid = @custid
				AND winlostdate BETWEEN @_FromDate AND @_ToDate
				AND (
					winlostdate >= @Yesterday 
					OR StatusID IN (0, 1)
				)
				AND statusID NOT IN (101, 102) -- exclude Void/Reject
			GROUP BY winlostdate, GameId,
				CASE WHEN statusID IN (0, 1) THEN 0 ELSE 131 END
				
			---- 1.4 bettransRnG
			UNION ALL 
			SELECT
				winlostdate,
				GameId,
				CASE WHEN statusID IN (0, 1) THEN 0 ELSE 131 END,
				NULL transdate,
				'' transdesc,
				SUM(stake),
				SUM(actual_stake),
				SUM(winlost),
				SUM(playercomm)
			FROM bettransRNG (NOLOCK)
			WHERE
				custid = @custid
				AND winlostdate BETWEEN @_FromDate and @_ToDate
				AND (
					winlostdate >= @Yesterday
					OR StatusID IN (0, 1) 
				)
				AND statusID NOT IN (101, 102) -- exclude Void/Reject
			GROUP BY winlostdate, GameId,
				CASE WHEN statusID IN (0,1) THEN 0 ELSE 131 END			 
		)
		INSERT INTO @StatementTable
		SELECT
			winlostdate accdate,
			0 refno,
			SUM(CASE WHEN statusID = 131 THEN winlost-actual_stake ELSE 0 END) totalamt, 
			'BET' transtype,
			CASE statusID
				WHEN 131 THEN 1
				WHEN 102 THEN 2
				ELSE 3 END transtypeid, -- statusID = 0
			CASE statusID
				WHEN 131 THEN 'Betting Statement'
				WHEN 102 THEN 'Void/Cancelled Bet'
				ELSE 'Outstanding Bet' END transdesc,  
			'' Creator,
			NULL checkerID,
			'' checkerName, 
			NULL checkTime,
			0 isAllowVeify
		FROM cte_bet
		WHERE
			(statusID = 131 AND bettype <= 19999)
			OR (statusID = 102 AND bettype <> 903)
			OR (statusID = 0 AND bettype NOT IN (23001,23002,23101,23102,23201,23202))
		GROUP BY winlostdate

		--------------2.Grand Prize			
		INSERT INTO @StatementTable
		SELECT
			winlostdate accdate
			,0 refno
			,SUM (WinAmount) totalamt
			,'GP' transtype
			, 4 transtypeid
			,'Grand Prize' transdesc
			,'' Creator
			,NULL checkerID
			,'' checkerName
			,NULL checkTime
			,0 isAllowVeify
		FROM dbo.PayoutTrans WITH (NOLOCK) 
		WHERE
			winlostdate BETWEEN @Fromdate AND @todate
			AND WinlostDate > @_BalanceUpDay
			AND custid = @custid 
			AND PayoutStatusId IN (4, 5)  ----- 'Completed', 'Expired'
		GROUP BY winlostdate, custid

		---------------3. Comm, Transfer
		---- 3.1 bettrans
		INSERT INTO @StatementTable
		SELECT 
			winlostdate accdate,
			0,
			SUM(playercomm) totalamt,
			'COM' transtype, 
			'Commission' transdesc,
			'' Creator,
			NULL,
			'',
			NULL,
			0  
		FROM bettrans b WITH (NOLOCK)  
			LEFT JOIN #SportBettype s ON s.bettype = b.bettype 
		WHERE 
			b.bettype <= 19999 
			AND custid = @custid 
			AND winlostdate BETWEEN @_FromDate AND @_ToDate
			AND playercomm <> 0 
			AND (
				winlostdate < @Yesterday 
				OR (winlostdate >= @Yesterday AND ISNULL(RefTable, 0) NOT IN (1, 2))
			)
		GROUP BY winlostdate

		UNION ALL
		SELECT 
			transdate accdate,
			refno,
			SUM(winlost-actual_stake) totalamt,
			bt.typenamee transtype,
			transdesc + CASE WHEN @showExchangeRate = 1 THEN ' - Ex.Rate: ' + CAST(actualrate AS VARCHAR(10)) ELSE '' END transdesc, 
			ISNULL(c.username,'') Creator,
			CASE WHEN bt.typeid IN (20000,23001,23002,23101,23102,23201,23202) THEN NULL ELSE b.betid END, --BalanceUP AND Transfer to Casino/Bingo/P2P
			CASE WHEN bt.typeid IN (20000,23001,23002,23101,23102,23201,23202) THEN '0' ELSE b.betcheck END,
			CASE WHEN bt.typeid IN (20000,23001,23002,23101,23102,23201,23202) THEN NULL ELSE b.checkTime END,
			CASE WHEN bt.typeid IN (20000,23001,23002,23101,23102,23201,23202) THEN 0 ELSE 1 END   
		FROM
			bettrans b WITH (NOLOCK)
			INNER JOIN bettype bt WITH (NOLOCK) ON bt.typeid = b.bettype 
			LEFT JOIN customer c WITH (NOLOCK) on b.creator = c.custid 
		WHERE 
			bettype >= 20000 
			AND b.custid=@custid 
			AND bt.typeid NOT IN (23001,23002,23101,23102,23201,23202)
			AND (winlost-actual_stake) <> 0 
			AND winlostdate BETWEEN @_FromDate and @_ToDate 
		GROUP BY
			transdate,
			refno,
			bt.typenamee,
			transdesc + CASE WHEN @showExchangeRate = 1 THEN ' - Ex.Rate: ' + CAST(actualrate AS VARCHAR(10)) ELSE '' END,
			transid,
			bt.typeid,
			c.username,
			b.betid,
			b.betcheck,
			b.checkTime

		---- 3.2 bettransLC
		INSERT INTO @StatementTable
		SELECT
			winlostdate AS accdate
			,0
			,SUM(playercomm) totalamt
			,'COM' transtype
			,'Commission' transdesc
			,'' Creator
			,NULL
			,''
			,NULL
			,0
		FROM bettransLC WITH (NOLOCK)
		WHERE
			custid = @custid
			AND winlostdate BETWEEN @_FromDate AND @_ToDate
			AND playercomm <> 0
			AND Winlostdate >= @Yesterday
		GROUP BY winlostdate

		---- 3.3 bettransRNG
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
		WHERE
			custid = @custid
			AND winlostdate BETWEEN @_FromDate AND @_ToDate
			AND playercomm <> 0
			AND Winlostdate >= @Yesterday
		GROUP BY winlostdate

		-------------4. Cancelled/Deleted Bets
		IF @_FromDate <= @MoveBetDay
			INSERT INTO @StatementTable
			SELECT DISTINCT
				eventdate accdate,
				0,
				0 totalamt, 
				'BET' transtype,
				2,
				'Cancelled/Deleted Bets' transdesc, 
				'' Creator,
				NULL,
				'',
				NULL,
				0 
			FROM
				zzzbettrans b WITH (NOLOCK)
				INNER JOIN Match m  WITH (NOLOCK) ON m.matchid = b.matchid
			WHERE 
				bettype <= 19999 
				AND bettype <> 903
				AND custid = @custid 
				AND eventdate BETWEEN @_FromDate AND @MoveBetDay 
			GROUP BY eventdate
			
			--Remove All
			UNION ALL
			SELECT DISTINCT
				eventdate accdate,
				0,
				0 totalamt,
				'BET' transtype,
				2, 
				'Cancelled/Deleted Bets' transdesc, 
				'' Creator,
				NULL,
				'',
				NULL,
				0 
			FROM
				zzzbettrans b WITH (NOLOCK)
				INNER JOIN match14 m WITH (NOLOCK) ON m.matchid = b.matchid
			WHERE 
				bettype <= 19999 
				AND bettype <> 903
				AND custid = @custid 
				AND eventdate BETWEEN @_FromDate AND @MoveBetDay 
			GROUP BY eventdate
	END
	-- end Customer --

	-- Agent --
	IF @roleid = 2 
	BEGIN
		---------------1. Transfer	
		INSERT INTO @StatementTable
		SELECT 
			transdate accdate,
			refno,
			SUM(winlost-actual_stake) totalamt ,
			typenamee transtype,
			transdesc + CASE WHEN @showExchangeRate = 1 THEN ' - Ex.Rate: ' + CAST(actualrate AS VARCHAR(10)) ELSE '' END transdesc, 			
			ISNULL(c.username,'') Creator,
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
			LEFT JOIN #SportBettype s ON s.bettype = b.bettype 
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
			LEFT JOIN #SportBettype s ON s.bettype = b.bettype 
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
			LEFT JOIN #SportBettype s ON s.bettype = b.bettype 
		WHERE 
			b.bettype between 1 and 19999 
			and mrecommend=@custid 
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
			LEFT JOIN #SportBettype s ON s.bettype = b.bettype 
		WHERE 
			b.bettype between 1 and 19999 
			and mrecommend=@custid 
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
				mrecommend=@custid 
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
				mrecommend=@custid 
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
				mrecommend=@custid 
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
				mrecommend=@custid 
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
			LEFT JOIN #SportBettype s ON s.bettype = b.bettype 
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
			LEFT JOIN #SportBettype s ON s.bettype = b.bettype 
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
				  AND transtype <> 'GP'
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
				AND transtype <> 'GP'
		END

		IF EXISTS(SELECT 1 FROM @StatementTable WHERE accdate >= @Fromdate_bk AND @AccBal <>0) 
			INSERT INTO @StatementTable(accdate, refno, totalamt,transtype,transdesc,creator,checkerID, checkerName, checkTime, isAllowVeify)
			SELECT '', 0, @AccBal, 'BAL', 'ACCUMULATED BALANCE', NULL,NULL,0, NULL,0

	END
END

SELECT	accdate, refno,SUM(totalamt) as totalamt,transtype,transtypeid,transdesc,creator
		,checkerID ,checkerName, checkTime ,isAllowVeify			
FROM @StatementTable
WHERE (accdate >= @Fromdate_bk OR transdesc = 'ACCUMULATED BALANCE')
GROUP BY accdate, refno, transtype,transtypeid,transdesc,creator
		,checkerID ,checkerName, checkTime ,isAllowVeify			
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
