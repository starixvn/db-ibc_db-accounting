/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView,bodbExtAccNet" isFunction="0" isNested="0"></info>*/
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
		- 20160216@Sophia: Apply Allbet [Redmine: #50588]
		- 20160404@Sophia: Exclude GrandPrize out of ACCUMULATED BALANCE [Redmine: #55397]
		- 20160328@Sophia: Check status Of PayOutTrans, get status Completed and Expired [Redmine: #54643]
		- 20160412@Percy: support Voidbridge single wallet [Redmine: #55258]
		- 20160620@Percy:
			1. recalculate Void/Reject for Casino game products [RedmineID: #59366]
			2. enhance performance: using right index on bettrans, bettransRnG/LC, translog
		- 20160809@Percy: Change Void tickets label [RedmineID: #62192]
		- 20170323@Percy: Apply Cash Out [RedmineID: #72164]
		- 20171020@Percy: Get both waiting and running tickets on translog [RedmineID: #84692]
		- 20180731@Percy: Expand column transdesc [RedmineID: #92841]
		- 20181107@Louis: Credit Collection [Redmine: #98621]
		- 20190917@Bobby: Implement headline - Statement [Redmine: #119289]
		
	Param explanation : 
		- Transtypeid = 4 - GrandPrize

 */
BEGIN
	SET NOCOUNT ON

	DECLARE @CID INT -- to prevent bad parameter sniffing
	SELECT  @CID = @custid

	DECLARE @roleid INT
	SELECT  @roleid = roleid FROM customer WITH (NOLOCK) WHERE custid = @CID

	DECLARE @tblCustid TABLE (custid INT) -- using index on custid for bettrans level SMA
	DECLARE @tblRecommend TABLE (recommend INT) -- using index on recommend for bettransLC/RnG level master, super

	IF @roleid = 2 -- agent
	BEGIN
		INSERT INTO @tblCustid (custid)
		SELECT custid FROM dbo.Customer WITH (NOLOCK) WHERE recommend = @CID AND roleid = 1
	END
	ELSE IF @roleid = 3 -- master
	BEGIN
		INSERT INTO @tblCustid (custid)
		SELECT custid FROM dbo.Customer WITH (NOLOCK) WHERE mrecommend = @CID AND roleid = 1

		INSERT INTO @tblRecommend (recommend)
		SELECT custid FROM dbo.Customer WITH (NOLOCK) WHERE mrecommend = @CID AND roleid = 2
	END
	ELSE IF @roleid = 4 -- super
	BEGIN
		INSERT INTO @tblCustid (custid)
		SELECT custid FROM dbo.Customer WITH (NOLOCK) WHERE srecommend = @CID AND roleid = 1

		INSERT INTO @tblRecommend (recommend)
		SELECT custid FROM dbo.Customer WITH (NOLOCK) WHERE srecommend = @CID AND roleid = 2
	END
	ELSE IF @roleid = 0 --headline
	BEGIN
		-- GET transfer only
		INSERT INTO @tblCustid (custid)
		SELECT @CID AS custid
	END

	DECLARE @Pos_Com TABLE (accdate DATETIME, pos_totalamt MONEY, com_totalamt MONEY) -- for position, commission

	DECLARE @StatementTable TABLE
	(
		accdate			DATETIME,
		refno			BIGINT,
		totalamt		MONEY,
		transtype		NVARCHAR(100),
		transtypeid		TINYINT DEFAULT 0,
		transdesc		NVARCHAR(1000),
		creator			VARCHAR(50),
		checkerID		INT NULL,
		checkerName		VARCHAR(50) NULL,
		checkTime		DATETIME NULL,
		isAllowVeify	BIT DEFAULT 0-- display check box "Verify"
	)

	DECLARE @_FromDate DATETIME, @_ToDate DATETIME, @_BalanceUpDay DATETIME, @Fromdate_bk DATETIME, @_IncludeAccBal BIT
	SELECT  @_FromDate = @Fromdate, @_ToDate = @todate, @_BalanceUpDay = @BalanceUpDay, @Fromdate_bk = @Fromdate, @_IncludeAccBal = @IncludeAccBal

	DECLARE @Yesterday DATETIME 
	SELECT  @Yesterday = CONVERT(DATE, DATEADD(DAY, -1, GETDATE()))
		
	----Get Sport Bettype Matrix------
	DECLARE @isTest BIT = 0
	SELECT  @isTest = dbo.f_CheckSPVersion(@@PROCID)

	CREATE TABLE #SportBettype (ProductID INT, Bettype INT, RefTable TINYINT, VoidRejectGroup TINYINT) -- VoidRejectGroup for get data from zzzbettrans
	INSERT INTO  #SportBettype (ProductID, Bettype, RefTable)
	SELECT ProductID, Bettype, RefTable FROM dbo.f_SportBettypeMatrix_Sel(0, 0, 0, 2, '', '', @isTest)
	WHERE RefTable <> 0 -- get bettype in translog, bettransRnG, bettransLC (exclude bettype on bettrans)
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
			;WITH cte_bet (winlostdate, bettype, statusID, transdate, transdesc, actual_stake, winlost) AS
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
					CASE 
						WHEN b.bettype <= 19999 THEN '' 
						WHEN b.oddsId = 0 THEN transdesc 						
						ELSE 'Coll' 
					END transdesc,
					SUM(actual_stake) AS actual_stake,
					SUM(winlost) AS winlost
				FROM
					bettrans b WITH (NOLOCK)
					LEFT JOIN #SportBettype s ON s.bettype = b.bettype 
				WHERE
					custid = @CID
					AND winlostdate BETWEEN @_FromDate AND @_ToDate
					AND (
						winlostdate < @Yesterday
						OR (winlostdate >= @Yesterday AND (s.RefTable IS NULL OR s.RefTable = 3)) -- exclude settle ticket on bettransRnG/LC today, yesterday
					)
					AND (
						statusID NOT IN (0, 1)
						OR (statusID IN (0, 1) AND s.RefTable IS NULL) -- exclude running ticket on bettransRnG/LC, translog
					)
				GROUP BY winlostdate, b.bettype,
					CASE
						WHEN statusID IN (102, 101) THEN 102
						WHEN statusID IN (0, 1) THEN 0
						ELSE 131 END,
					CASE WHEN b.bettype <= 19999 THEN NULL ELSE transdate END,
					CASE 
						WHEN b.bettype <= 19999 THEN '' 
						WHEN b.oddsId = 0 THEN transdesc
						ELSE 'Coll' 
					END			
			
				---- 1.2 translog
				UNION ALL
				SELECT
					winlostdate, 
					GameId, 
					0 AS StatusID,
					NULL AS transdate,
					'' AS transdesc,
					SUM(actual_stake),
					0 AS winlost
				FROM translog WITH (NOLOCK)
				WHERE
					custid = @CID
					AND winlostdate BETWEEN @_FromDate AND @_ToDate
					AND statusID IN (0, 1)
				GROUP BY GameId, winlostdate

				---- 1.3 bettransLC
				UNION ALL
				SELECT
					winlostdate,
					GameId,
					CASE WHEN statusID IN (0,1) THEN 0 ELSE 131 END,
					NULL transdate,
					'' transdesc,
					SUM(actual_stake),
					SUM(winlost)
				FROM bettransLC WITH (NOLOCK)
				WHERE
					custid = @CID
					AND winlostdate BETWEEN @_FromDate AND @_ToDate
					AND (
						winlostdate >= @Yesterday 
						OR StatusID IN (0, 1)
					)
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
					SUM(actual_stake),
					SUM(winlost)
				FROM bettransRNG (NOLOCK)
				WHERE
					custid = @CID
					AND winlostdate BETWEEN @_FromDate and @_ToDate
					AND (
						winlostdate >= @Yesterday
						OR StatusID IN (0, 1) 
					)
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
				OR (statusID = 102 AND bettype NOT IN (500, 903, 913, 914))
				OR (statusID = 0 AND bettype NOT IN (23001,23002,23101,23102,23201,23202))
			GROUP BY
				winlostdate,
				CASE statusID
					WHEN 131 THEN 1
					WHEN 102 THEN 2
					ELSE 3 END,
				CASE statusID
					WHEN 131 THEN 'Betting Statement'
					WHEN 102 THEN 'Void/Cancelled Bet'
					ELSE 'Outstanding Bet' END

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
				winlostdate BETWEEN @_Fromdate AND @_ToDate
				AND WinlostDate > @_BalanceUpDay
				AND custid = @CID 
				AND PayoutStatusId IN (4, 5)  ----- 'Completed', 'Expired'
			GROUP BY winlostdate

			---------------3. Comm, Transfer
			---- 3.1 bettrans
			INSERT INTO @StatementTable -- comm
			SELECT
				winlostdate accdate,
				0,
				SUM(playercomm) totalamt,
				'COM' transtype,
				0,
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
				AND custid = @CID 
				AND winlostdate BETWEEN @_FromDate AND @_ToDate
				AND playercomm <> 0 
				AND (
					winlostdate < @Yesterday 
					OR (winlostdate >= @Yesterday AND (s.RefTable IS NULL OR s.RefTable = 3)) -- exclude ticket on bettransRnG/LC today, yesterday
				)
			GROUP BY winlostdate

			INSERT INTO @StatementTable -- transfer
			SELECT 
				transdate accdate,
				refno,
				SUM(winlost-actual_stake) totalamt,
				CASE WHEN b.oddsId = 0 THEN bt.typenamee ELSE 'Coll' END transtype,
				0,
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
				AND b.custid=@CID 
				AND bt.typeid NOT IN (23001,23002,23101,23102,23201,23202)
				AND (winlost-actual_stake) <> 0 
				AND winlostdate BETWEEN @_FromDate and @_ToDate 
			GROUP BY
				transdate,
				refno,
				bt.typenamee,
				oddsId,
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
				,0
				,'Commission' transdesc
				,'' Creator
				,NULL
				,''
				,NULL
				,0
			FROM bettransLC WITH (NOLOCK)
			WHERE
				custid = @CID
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
				,0
				,'Commission' transdesc
				,'' Creator
				,NULL
				,''
				,NULL
				,0
			FROM bettransRNG WITH (NOLOCK)
			WHERE
				custid = @CID
				AND winlostdate BETWEEN @_FromDate AND @_ToDate
				AND playercomm <> 0
				AND Winlostdate >= @Yesterday
			GROUP BY winlostdate

			-------------4. Cancelled/Deleted Bets
			IF @_FromDate <= @MoveBetDay
			BEGIN
			---- 4.1 zzzbettrans

				-- For get data on zzzbettrans table --
					/* VoidRejectGroup:
						1. exclude zzzbettrans
						2. zzzbettrans only
						3. zzzbettrans inner join match/match14
					*/
				UPDATE #SportBettype
				SET VoidRejectGroup = 3 -- default: zzzbettrans inner join match/match14

				UPDATE #SportBettype
				SET VoidRejectGroup = 1 -- exclude zzzbettrans
				WHERE RefTable IN (1, 2) -- bettype in Casino Games (bettransRnG/LC)

				UPDATE #SportBettype
				SET VoidRejectGroup = 2 -- zzzbettrans only
				WHERE ProductID IN (8, 12, 13, 15) -- Keno, Gold Deluxe, MGC-Live Casino, Colossus Bet
						-- (ProductID = 11 AND bettype = 1800) -- need to add AG Casino  (#SportBettype no have)

				--- zzzbettrans only
				INSERT INTO @StatementTable
				SELECT DISTINCT
					b.winlostdate accdate,
					0,
					0 totalamt,
					'BET' transtype,
					2,
					'Void/Cancelled Bet' transdesc,
					'' Creator,
					NULL,
					'',
					NULL,
					0
				FROM
					zzzbettrans b WITH (NOLOCK)
					INNER JOIN
						(SELECT bettype FROM #SportBettype WHERE VoidRejectGroup = 2 --- zzzbettrans only
						 UNION SELECT 1800 -- AG Casino
						) s ON s.Bettype = b.bettype
				WHERE
					custid = @CID
					AND winlostdate BETWEEN @_Fromdate AND @MoveBetDay
					AND winlostdate >= @_BalanceUpDay
				GROUP BY winlostdate

				--- zzzbettrans inner join match/match14
				INSERT INTO @StatementTable
				SELECT DISTINCT
					m.eventdate accdate,
					0,
					0 totalamt,
					'BET' transtype,
					2,
					'Void/Cancelled Bet' transdesc,
					'' Creator,
					NULL,
					'',
					NULL,
					0 
				FROM
					zzzbettrans b WITH (NOLOCK)
					INNER JOIN match m WITH (NOLOCK) ON m.matchid = b.matchid
					LEFT JOIN #SportBettype s ON b.bettype = s.Bettype
				WHERE
					b.bettype <= 19999
					AND b.bettype NOT IN (500, 903, 913, 914) -- exclude 500, 903, 913, 914 (1800 for AG Casino: no need)
					AND eventdate BETWEEN @_Fromdate AND @MoveBetDay
					AND (s.VoidRejectGroup IS NULL OR s.VoidRejectGroup = 3) -- zzzbettrans inner join match/match14
					AND custid = @CID
				GROUP BY eventdate
				UNION ALL
				SELECT DISTINCT
					m.eventdate accdate,
					0,
					0 totalamt,
					'BET' transtype,
					2,
					'Void/Cancelled Bet' transdesc,
					'' Creator,
					NULL,
					'',
					NULL,
					0 
				FROM
					zzzbettrans b WITH (NOLOCK)
					INNER JOIN match14 m WITH (NOLOCK) ON m.matchid = b.matchid
					LEFT JOIN #SportBettype s ON b.bettype = s.Bettype
				WHERE
					b.bettype <= 19999
					AND b.bettype NOT IN (500, 903, 913, 914) -- exclude 500, 903, 913, 914 (1800 for AG Casino: no need)
					AND eventdate BETWEEN @_Fromdate AND @MoveBetDay
					AND (s.VoidRejectGroup IS NULL OR s.VoidRejectGroup = 3) -- zzzbettrans inner join match/match14
					AND custid = @CID
				GROUP BY eventdate
			END
		END
		-- End Customer --

		-- Agent --
		IF @roleid = 2 
		BEGIN
			---------------1. Transfer	
			INSERT INTO @StatementTable
			SELECT 
				transdate accdate,
				refno,
				SUM(winlost-actual_stake) totalamt,
				CASE WHEN oddsId = 0 THEN typenamee ELSE 'Coll' END transtype,
				0,
				transdesc + CASE WHEN @showExchangeRate = 1 THEN ' - Ex.Rate: ' + CAST(actualrate AS VARCHAR(10)) ELSE '' END transdesc, 			
				ISNULL(c.username,'') Creator,
				CASE WHEN bt.typeid IN (20000,23001,23002,23101,23102,23201,23202) THEN NULL ELSE b.betid END,
				CASE WHEN bt.typeid IN (20000,23001,23002,23101,23102,23201,23202) THEN '0' ELSE b.betcheck END,
				CASE WHEN bt.typeid IN (20000,23001,23002,23101,23102,23201,23202) THEN NULL ELSE b.checkTime END,
				CASE WHEN bt.typeid IN (20000,23001,23002,23101,23102,23201,23202) THEN 0 ELSE 1 END   
			FROM
				bettrans b WITH (NOLOCK) 
				INNER JOIN bettype bt WITH (NOLOCK) ON bt.typeid = b.bettype 
				LEFT JOIN customer c WITH (NOLOCK) ON b.creator = c.custid 
			WHERE 
				bettype >= 20000
				AND b.custid = @CID
				AND winlostdate BETWEEN @_FromDate AND @_ToDate 
				GROUP BY
					transdate,
					b.refno,
					typenamee,
					oddsId,
					transdesc + CASE WHEN @showExchangeRate = 1 THEN ' - Ex.Rate: ' + CAST(actualrate AS VARCHAR(10)) ELSE '' END,
					transid,
					bt.typeid,
					c.username,
					b.betid,
					b.betcheck,
					b.checkTime
			
			---------------2. POS, COM
			INSERT INTO @Pos_Com
				--- 2.1. Bettrans
			SELECT
				winlostdate accdate,
				SUM(awinlost) pos_totalamt,
				SUM(comm-playercomm) com_totalamt
			FROM
				dbo.bettrans b WITH (NOLOCK)
				LEFT JOIN #SportBettype s ON b.bettype = s.Bettype
			WHERE
				b.bettype <= 19999
				AND custid IN (SELECT * FROM @tblCustid) -- using index on custid
				AND winlostdate BETWEEN @_FromDate AND @_ToDate
				AND (
					winlostdate < @Yesterday
					OR (winlostdate >= @Yesterday AND (s.RefTable IS NULL OR s.RefTable = 3)) -- exclude ticket on bettransRnG/LC today, yesterday
				)
			GROUP BY winlostdate

				---- 2.2 bettransLC
			UNION ALL
			SELECT
				winlostdate accdate,
				SUM(awinlost) pos_totalamt,
				SUM(comm-playercomm) com_totalamt
			FROM dbo.bettransLC WITH (NOLOCK)
			WHERE recommend = @CID
				AND winlostdate BETWEEN @_FromDate AND @_ToDate
				AND winlostdate >= @Yesterday
			GROUP BY winlostdate

			---- 2.2 bettransRnG
			UNION ALL
			SELECT
				winlostdate accdate,
				SUM(awinlost) pos_totalamt,
				SUM(comm-playercomm) com_totalamt
			FROM dbo.bettransRnG WITH (NOLOCK)
			WHERE recommend = @CID
				AND winlostdate BETWEEN @_FromDate AND @_ToDate
				AND winlostdate >= @Yesterday
			GROUP BY winlostdate
		
			INSERT INTO @StatementTable -- position
			SELECT
				accdate,
				0 refno,
				SUM(pos_totalamt) totalamt,
				'POS' transtype,
				0,
				'Position' transdesc,
				'' Creator,
				NULL,
				'',
				NULL,
				0
			FROM @Pos_Com
			GROUP BY accdate
			HAVING SUM(pos_totalamt) <> 0

			UNION ALL -- commission
			SELECT
				accdate,
				0 refno,
				SUM(com_totalamt) totalamt,
				'COM' transtype,
				0,
				'Commission' transdesc,
				'' Creator,
				NULL,
				'',
				NULL,
				0
			FROM @Pos_Com
			GROUP BY accdate
			HAVING SUM(com_totalamt) <> 0
		END
		-- End Agent --

		-- Master --
		IF @roleid = 3
		BEGIN
			--------1. Transfer
			INSERT INTO @StatementTable
			SELECT 
				transdate accdate,
				refno,
				SUM(winlost-actual_stake) totalamt,
				CASE WHEN oddsId = 0 THEN typenamee ELSE 'Coll' END transtype,
				0,
				transdesc + CASE WHEN @showExchangeRate = 1 THEN ' - Ex.Rate: ' + CAST(actualrate AS VARCHAR(10)) ELSE '' END transdesc, 
				ISNULL(c.username,'') Creator,
				CASE WHEN bt.typeid IN (20000,23001,23002,23101,23102,23201,23202) THEN NULL ELSE b.betid END,
				CASE WHEN bt.typeid IN (20000,23001,23002,23101,23102,23201,23202) THEN '0' ELSE b.betcheck END,
				CASE WHEN bt.typeid IN (20000,23001,23002,23101,23102,23201,23202) THEN NULL ELSE b.checkTime END,
				CASE WHEN bt.typeid IN (20000,23001,23002,23101,23102,23201,23202) THEN 0 ELSE 1 END    
			FROM
				bettrans b WITH (NOLOCK) 
				INNER JOIN bettype bt WITH (NOLOCK) ON bt.typeid = b.bettype 
				LEFT JOIN customer c WITH (NOLOCK) ON b.creator = c.custid 
			WHERE 
				bettype >= 20000 
				AND b.custid = @CID 
				AND winlostdate BETWEEN @_FromDate AND @_ToDate 
			GROUP BY
				transdate,
				b.refno,
				typenamee,
				oddsId,
				transdesc + CASE WHEN @showExchangeRate = 1 THEN ' - Ex.Rate: ' + CAST(actualrate AS VARCHAR(10)) ELSE '' END,		
				transid,
				bt.typeid,
				c.username,
				b.betid,
				b.betcheck,
				b.checkTime			
	
			---------------2. POS, COM
			INSERT INTO @Pos_Com
				--- 2.1. Bettrans
			SELECT
				winlostdate accdate,
				SUM(mwinlost) pos_totalamt,
				SUM(acomm-comm) com_totalamt
			FROM
				dbo.bettrans b WITH (NOLOCK)
				LEFT JOIN #SportBettype s ON b.bettype = s.Bettype
			WHERE
				b.bettype <= 19999
				AND custid IN (SELECT custid FROM @tblCustid) -- using index on custid
				AND winlostdate BETWEEN @_FromDate AND @_ToDate
				AND (
					winlostdate < @Yesterday
					OR (winlostdate >= @Yesterday AND (s.RefTable IS NULL OR s.RefTable = 3)) -- exclude ticket on bettransRnG/LC today, yesterday
				)
			GROUP BY winlostdate

				---- 2.2 bettransLC
			UNION ALL
			SELECT
				winlostdate accdate,
				SUM(mwinlost) pos_totalamt,
				SUM(acomm-comm) com_totalamt
			FROM dbo.bettransLC WITH (NOLOCK)
			WHERE
				recommend IN (SELECT recommend FROM @tblRecommend) -- using index on recommend
				AND winlostdate BETWEEN @_FromDate AND @_ToDate
				AND winlostdate >= @Yesterday
			GROUP BY winlostdate

				---- 2.2 bettransRnG
			UNION ALL
			SELECT
				winlostdate accdate,
				SUM(mwinlost) pos_totalamt,
				SUM(acomm-comm) com_totalamt
			FROM dbo.bettransRnG WITH (NOLOCK)
			WHERE
				recommend IN (SELECT recommend FROM @tblRecommend) -- using index on recommend
				AND winlostdate BETWEEN @_FromDate AND @_ToDate
				AND winlostdate >= @Yesterday
			GROUP BY winlostdate
		
			INSERT INTO @StatementTable -- position
			SELECT
				accdate,
				0 refno,
				SUM(pos_totalamt) totalamt,
				'POS' transtype,
				0,
				'Position' transdesc,
				'' Creator,
				NULL,
				'',
				NULL,
				0
			FROM @Pos_Com
			GROUP BY accdate
			HAVING SUM(pos_totalamt) <> 0

			UNION ALL -- commission
			SELECT
				accdate,
				0 refno,
				SUM(com_totalamt) totalamt,
				'COM' transtype,
				0,
				'Commission' transdesc,
				'' Creator,
				NULL,
				'',
				NULL,
				0
			FROM @Pos_Com
			GROUP BY accdate
			HAVING SUM(com_totalamt) <> 0
		END
		-- End Master --

		-- Super 
		IF @roleid = 4
		BEGIN
			--------1.Transfer
			INSERT INTO @StatementTable
			SELECT 
				transdate accdate,
				refno,
				SUM(winlost-actual_stake) totalamt,
				CASE WHEN oddsId = 0 THEN typenamee ELSE 'Coll' END transtype,
				0,
				transdesc + CASE WHEN @showExchangeRate = 1 THEN ' - Ex.Rate: ' + CAST(actualrate AS VARCHAR(10)) ELSE '' END transdesc,
				ISNULL(c.username,'') as Creator,
				CASE WHEN bt.typeid IN (20000,23001,23002,23101,23102,23201,23202) THEN NULL ELSE b.betid END,
				CASE WHEN bt.typeid IN (20000,23001,23002,23101,23102,23201,23202) THEN '0' ELSE b.betcheck END,
				CASE WHEN bt.typeid IN (20000,23001,23002,23101,23102,23201,23202) THEN NULL ELSE b.checkTime END,
				CASE WHEN bt.typeid IN (20000,23001,23002,23101,23102,23201,23202) THEN 0 ELSE 1 END  
			FROM
				bettrans b WITH (NOLOCK) 
				INNER JOIN bettype bt WITH (NOLOCK) ON bt.typeid=b.bettype  
				LEFT JOIN customer c WITH (NOLOCK) ON b.creator = c.custid  
			WHERE 
				bettype >= 20000 
				AND b.custid=@CID 
				AND bt.typeid=b.bettype  
				AND winlostdate BETWEEN @_FromDate AND @_ToDate
			GROUP BY
				transdate,
				b.refno,
				typenamee,
				oddsId,
				transdesc + CASE WHEN @showExchangeRate = 1 THEN ' - Ex.Rate: ' + CAST(actualrate AS VARCHAR(10)) ELSE '' END,		
				transid,
				bt.typeid,
				c.username,
				b.betid,
				b.betcheck,
				b.checkTime

			--------2. POS, COM
			INSERT INTO @Pos_Com
			--- 2.1. Bettrans
			SELECT
				winlostdate accdate,
				SUM(swinlost) pos_totalamt,
				SUM(scomm-acomm) com_totalamt
			FROM
				dbo.bettrans b WITH (NOLOCK)
				LEFT JOIN #SportBettype s ON b.bettype = s.Bettype
			WHERE b.bettype <= 19999
				AND EXISTS (SELECT TOP 1 1 FROM @tblCustid c WHERE c.custid = b.custid) -- using index on custid
				AND winlostdate BETWEEN @_FromDate AND @_ToDate
				AND (
					winlostdate < @Yesterday
					OR (winlostdate >= @Yesterday AND (s.RefTable IS NULL OR s.RefTable = 3)) -- exclude ticket on bettransRnG/LC today, yesterday
				)
			GROUP BY winlostdate

				---- 2.2 bettransLC
			UNION ALL
			SELECT
				winlostdate accdate,
				SUM(swinlost) pos_totalamt,
				SUM(scomm-acomm) com_totalamt
			FROM dbo.bettransLC WITH (NOLOCK)
			WHERE
				recommend IN (SELECT recommend FROM @tblRecommend) -- using index on recommend
				AND winlostdate BETWEEN @_FromDate AND @_ToDate
				AND winlostdate >= @Yesterday
			GROUP BY winlostdate

				---- 2.2 bettransRnG
			UNION ALL
			SELECT
				winlostdate accdate,
				SUM(swinlost) pos_totalamt,
				SUM(scomm-acomm) com_totalamt
			FROM dbo.bettransRnG WITH (NOLOCK)
			WHERE
				recommend IN (SELECT recommend FROM @tblRecommend) -- using index on recommend
				AND winlostdate BETWEEN @_FromDate AND @_ToDate
				AND winlostdate >= @Yesterday
			GROUP BY winlostdate
		
			INSERT INTO @StatementTable -- position
			SELECT
				accdate,
				0 refno,
				SUM(pos_totalamt) totalamt,
				'POS' transtype,
				0,
				'Position' transdesc,
				'' Creator,
				NULL,
				'',
				NULL,
				0
			FROM @Pos_Com
			GROUP BY accdate
			HAVING SUM(pos_totalamt) <> 0

			UNION ALL -- commission
			SELECT
				accdate,
				0 refno,
				SUM(com_totalamt) totalamt,
				'COM' transtype,
				0,
				'Commission' transdesc,
				'' Creator,
				NULL,
				'',
				NULL,
				0
			FROM @Pos_Com
			GROUP BY accdate
			HAVING SUM(com_totalamt) <> 0
		END
		-- End Super 

		-- Headline --
		IF @roleid = 0
		BEGIN
			--------1.Transfer only
			INSERT INTO @StatementTable
			SELECT 
				transdate accdate,
				refno,
				SUM(winlost-actual_stake) totalamt,
				CASE WHEN oddsId = 0 THEN typenamee ELSE 'Coll' END transtype,
				0,
				transdesc + CASE WHEN @showExchangeRate = 1 THEN ' - Ex.Rate: ' + CAST(actualrate AS VARCHAR(10)) ELSE '' END transdesc,
				ISNULL(c.username,'') as Creator,
				CASE WHEN bt.typeid IN (20000,23001,23002,23101,23102,23201,23202) THEN NULL ELSE b.betid END,
				CASE WHEN bt.typeid IN (20000,23001,23002,23101,23102,23201,23202) THEN '0' ELSE b.betcheck END,
				CASE WHEN bt.typeid IN (20000,23001,23002,23101,23102,23201,23202) THEN NULL ELSE b.checkTime END,
				CASE WHEN bt.typeid IN (20000,23001,23002,23101,23102,23201,23202) THEN 0 ELSE 1 END  
			FROM
				bettrans b WITH (NOLOCK) 
				INNER JOIN bettype bt WITH (NOLOCK) ON bt.typeid=b.bettype  
				LEFT JOIN customer c WITH (NOLOCK) ON b.creator = c.custid  
			WHERE 
				bettype >= 20000 
				AND b.custid=@CID 
				AND bt.typeid=b.bettype  
				AND winlostdate BETWEEN @_FromDate AND @_ToDate
			GROUP BY
				transdate,
				b.refno,
				typenamee,
				oddsId,
				transdesc + CASE WHEN @showExchangeRate = 1 THEN ' - Ex.Rate: ' + CAST(actualrate AS VARCHAR(10)) ELSE '' END,		
				transid,
				bt.typeid,
				c.username,
				b.betid,
				b.betcheck,
				b.checkTime
		END
		-- End Headline

	END		   

	IF @_FromDate < @_BalanceUpDay
	BEGIN
		DECLARE @lateTransaction BIT

		IF @_ToDate >= DATEADD(dd, -1, @_BalanceUpDay)
		BEGIN
			SELECT	@_ToDate = DATEADD(dd, -1, @_BalanceUpDay) + ' 23:59:59',
					@lateTransaction = 1		
		END
	
		SELECT	TOP 1 @_FromDate = ISNULL(accdate, @Fromdate_bk)
		FROM	bodb_Report.dbo.[Statement] WITH (NOLOCK)
		WHERE	custid = @CID AND transdesc = 'OPENING BALANCE' AND accdate <= @Fromdate_bk
		ORDER BY accdate DESC
 
		INSERT INTO @StatementTable
		SELECT
			accdate,
			0,
			totalamt,
			transtype,
			CASE transtype
				WHEN 'BET' THEN 1
				WHEN  'GP' THEN 4
				ELSE 0 END transtypeid,
			CASE WHEN transtype = 'BET' AND transdesc = 'Betting' THEN 'Betting Statement' ELSE transdesc END transdesc, 
			'' creator,
			NULL,
			'',
			NULL,
			0
		FROM bodb_Report.dbo.[Statement] WITH (NOLOCK) 
		WHERE
			custid = @CID
			AND accdate BETWEEN @_FromDate AND @_ToDate
	
		UNION ALL --- @Lukas add missing transaction
		SELECT 		 
			accdate,
			0,
			totalamt,
			transtype,
			0 transtypeid,
			transdesc , 
			'' creator,
			NULL,
			'',
			NULL,
			0 
		FROM bodb_Report.dbo.[Statement] WITH (NOLOCK) 
		WHERE
			custid = @CID
			AND accdate > @_ToDate AND accdate <= DATEADD(DAY, 2, @_ToDate)
			AND @lateTransaction = 1
			AND transtype IN ('Dep','Wit')
	END

	IF (@_IncludeAccBal = 1)
	BEGIN
		DECLARE @AccBal MONEY, @BUDate DATETIME
	
		IF (@Fromdate_bk <> @_BalanceUpDay)
		BEGIN
		
			IF (@Fromdate_bk > @_BalanceUpDay)
			BEGIN
				--get acc bal FROM current (bettrans)
				SELECT @AccBal = ISNULL(SUM(totalamt),0)
				FROM @StatementTable
				WHERE accdate < @Fromdate_bk AND transtype <> 'GP'
			END
			ELSE 
			BEGIN
				--get latest old BUDate
				SELECT TOP 1 @BUDate = accdate
				FROM bodb_Report.dbo.[Statement] WITH (NOLOCK)
				WHERE custid = @CID AND transdesc = 'OPENING BALANCE' AND accdate <= @Fromdate_bk
				ORDER BY accdate DESC
			
				--if cannot find any old BU row, get BUDate FROM last BUDate before @Fromdate
				IF (@BUDate IS NULL) 
				BEGIN
					SET @BUDate = @Fromdate_bk
					WHILE(DATEPART(WEEKDAY, @BUDate) <> 7) SET @BUDate = DATEADD(dd, -1, @BUDate)  
				END
			
				--get acc bal FROM statement old (Statement):		
				SELECT @AccBal = ISNULL(SUM(totalamt),0)
				FROM bodb_Report.dbo.[Statement] WITH (NOLOCK) 
				WHERE custid = @CID AND accdate >= @BUDate AND accdate < @Fromdate_bk AND transtype <> 'GP'
			END

			IF EXISTS(SELECT 1 FROM @StatementTable WHERE accdate >= @Fromdate_bk AND @AccBal <> 0) 
				INSERT INTO @StatementTable
				SELECT '', 0, @AccBal, 'BAL', 0, 'ACCUMULATED BALANCE', NULL, NULL, 0, NULL, 0

		END
	END

	SELECT accdate, refno, SUM(totalamt) AS totalamt, transtype, transtypeid, transdesc, creator, checkerID, checkerName, checkTime, isAllowVeify			
	FROM @StatementTable
	WHERE
		accdate >= @Fromdate_bk
		OR transdesc = 'ACCUMULATED BALANCE'
	GROUP BY accdate, refno, transtype, transtypeid, transdesc, creator, checkerID, checkerName, checkTime, isAllowVeify			
	ORDER BY accdate, CASE WHEN transdesc LIKE '%OPENING BALANCE%' THEN 1 ELSE 2 END, transtypeid, transdesc

	DROP TABLE #SportBettype
END
GO