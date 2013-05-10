ALTER PROCEDURE [dbo].[Acc_ResetWinning_SelByDate_Original]
	@winlostdate	DATETIME,	
	@totalBalance	MONEY = 0 OUTPUT
AS

/*	
	Created: 20120514@Lukas
	Task: Reset Winning - Get data by Date
	DB: DB053.BODB02
	
	Revision:
		- 20120605@Jamie: Exclude VOID, REJECT, REFUND, DONE
		- 20120723@Lukas: Excluding transfered transactions of dummy balance accounts
		- 20120822@Sophia: define IBC racing net income instead of gross income
	Explanation's Param:

*/

BEGIN	
	SET NOCOUNT ON		
	

	DECLARE @dummyBalance TABLE (custid INT, product VARCHAR(50))
	
	INSERT INTO @dummyBalance 
			  SELECT	6911909	, 'SPL'			---- DWLSPL
	UNION ALL SELECT	6911911	, 'SPNL'		---- DWLSPNL
	UNION ALL SELECT	6911913	, 'Parlay'		---- DWLParlay
	UNION ALL SELECT	6911914	, 'Outright'	---- DWLOutright
	UNION ALL SELECT	6911916	, 'Casino'		---- DWLCasino
	UNION ALL SELECT	6911917	, 'Live Casino' ---- DWLLiveCasino
	UNION ALL SELECT	6911918	, 'Number Game' ---- DWLNumber	
	UNION ALL SELECT	6911919	, 'Racing'		---- DWLRacing
	UNION ALL SELECT	7723121	, 'Racing (Due to Partners)'	----- VNM-Racing Partners MYR
	UNION ALL SELECT	6911920	, 'P2P'			---- DWLP2P
	UNION ALL SELECT	6913085	, 'Bingo'		---- DWLBingo

	DECLARE @Winning TABLE 
			(
				product VARCHAR(50),
				winlost MONEY					
			)	
	
	
	CREATE TABLE #source (custid int, bettype INT, liveindicator BIT, winlost MONEY)
	INSERT INTO #source
	SELECT CASE WHEN custid IN (6911909,6911911,6911913,6911914,6911916,6911917,6911918,
									6911919,6911920,6913085,7723121
								) THEN custid
				ELSE 0 END AS custid, bettype, liveindicator,
		SUM(winlost) AS winlost
	FROM (
			SELECT MIN(custid) AS custid, bettype, liveindicator,refno,
				ISNULL(SUM((winlost-actual_stake + awinlost + mwinlost + swinlost + scomm)*actualrate),0) AS winlost
			FROM bettrans WITH(READPAST)
			WHERE winlostdate = @winlostdate  and ruben = 1 
					AND statusid NOT IN (101,102,103,121)					
			GROUP BY bettype, statusid, liveindicator,refno				
			having ISNULL(SUM((winlost-actual_stake + awinlost + mwinlost + swinlost + scomm)*actualrate),0) <> 0
		) t 
	GROUP BY bettype, liveindicator,
		CASE WHEN custid IN (6911909,6911911,6911913,6911914,6911916,6911917,6911918,
								6911919,6911920,6913085,7723121	
							)THEN custid 
			ELSE 0 END
			

	DECLARE @RB_LineTotal	money
			
	/*calculating racing net income*/
	--insert company's comm setting that is recieved from Phumelela into this temp table.
	DECLARE @tmpIBCFee TABLE(partnerID int,IBCFee bit)

	DECLARE @CommSetting TABLE
	(	MatchID			int,
		IBCFee			bit,
		ToteCommWin		smallmoney,
		ToteCommPlace	smallmoney,
		ToteCommWP		smallmoney,
		ToteFee			smallmoney	
	)

	INSERT INTO @tmpIBCFee (partnerID, IBCFee)
		SELECT 1,1 --RACE-PHU
	UNION ALL
		SELECT 2,0 --RACE-ATRUK
	UNION ALL
		SELECT 3,0 --RACE-ATRIRL
	UNION ALL
		SELECT 4,0 --RACE-RUK
	UNION ALL
		SELECT 5,1 --RACE-TABCORP
	UNION ALL
		SELECT 101,1 --GREY-DTOTEUK
	UNION ALL
		SELECT 102,1 --GREY-DTOTEIRL
	UNION ALL
		SELECT 103,1 --GREY-TABCORP
	UNION ALL
		SELECT 201,1 --HAR-TABCORP
		
	INSERT INTO @CommSetting (MatchID, IBCFee, ToteCommWin, ToteCommPlace, ToteCommWP, ToteFee)
	SELECT	DISTINCT o.orid as matchid, t.IBCFee, p.ToteCommWin, p.ToteCommPlace, (p.ToteCommWin + p.ToteCommPlace)/2 ToteCommWP, p.ToteFee 
	FROM	outright o WITH (NOLOCK)
			INNER JOIN LeagueDetail p WITH (NOLOCK) ON o.leagueID = p.LeagueID AND p.programDate = o.programDate
			INNER JOIN RacingMeeting r WITH(NOLOCK) ON r.meetingID = p.leagueid
			INNER JOIN @tmpIBCFee t ON r.partnerID = t.partnerID
	WHERE	o.eventdate = @winlostdate 
	
	---- get Racing line total
	SELECT	@RB_LineTotal	= -(SUM((CASE WHEN bettype = 33 THEN bm.WLIBC ELSE -(b.winlost -b.actual_stake)*ISNULL(b.oddsspread,0) END)*b.actualrate) 
								- SUM( CASE WHEN cs.IBCFee = 0 THEN 0 ELSE (CASE WHEN b.bettype = 33 THEN bm.TOPhum WHEN bettype in (31,32) THEN b.actual_stake*(1 -b.tpositiontaking - ISNULL(b.oddsspread,0)) ELSE 0 END)*b.actualrate*cs.ToteFee END) --FeeDue2 
								+ SUM((CASE bettype WHEN 31 THEN b.actual_stake*cs.ToteCommWin*(1 - b.tpositiontaking - ISNULL(oddsspread,0))
													WHEN 32 THEN b.actual_stake*cs.ToteCommPlace*(1 - b.tpositiontaking - ISNULL(oddsspread,0))
													WHEN 33 THEN bm.TOPhum*cs.ToteCommWP  
													ELSE 0 END)*b.actualrate) --commIncomeIBC
								- SUM(b.scomm*b.actualrate)) 
	FROM	bettrans b WITH(NOLOCK)
			INNER JOIN @CommSetting AS cs ON b.matchid = cs.matchid 
			 left join (
				SELECT	refno,
						SUM(CASE WHEN bettype = 32 and liveawayscore =0 THEN 0 ELSE stake*ISNULL(oddsspread,0) END) TOIBC,
						-SUM((winlost - stake)*ISNULL(oddsspread,0)) WLIBC,
						SUM(CASE WHEN bettype = 32 and liveawayscore = 0 THEN 0 WHEN bettype = 31 or (bettype = 32 and liveawayscore <> 0) THEN stake*(1 -tpositiontaking - ISNULL(oddsspread,0)) ELSE 0 END) TOPhum
				FROM	bettransm WITH(NOLOCK)
				GROUP BY refno
			 )bm ON b.transid = bm.refno 
	WHERE	b.ruben =1 
			and b.bettype in (31,32,33)
			and b.matchid >0
			and b.winlostdate = @winlostdate			
			and b.statusID not in (101,102,103,121)	
	/*end calculating racing net income*/
	
	---- get total balance
	SELECT @totalBalance = ISNULL(SUM(winlost),0)
	FROM #source
	WHERE custid NOT IN (SELECT custid FROM @dummyBalance)		

	INSERT INTO @Winning(product,winlost)

	---- sportsbook live & non-live
	SELECT CASE WHEN liveindicator = 1 THEN 'SPL'
				WHEN liveindicator = 0 THEN 'SPNL'
				ELSE '' ---- what the hell is it ?
			END AS Product,
			ISNULL(SUM(winlost),0) as winlost
	FROM #source
	WHERE bettype <= 999 AND bettype NOT IN (9,10,29,31,32,33,71,73) AND bettype NOT BETWEEN 81 AND 120		
	GROUP BY liveindicator 
	
	UNION ALL	
	SELECT CASE	WHEN bettype BETWEEN 31 AND 33 THEN 'Racing gross income'
				WHEN bettype BETWEEN 81 AND 120 THEN 'Number Game'	
				WHEN bettype BETWEEN 1101 AND 1199 THEN 'Live Casino'
				WHEN bettype = 71 THEN 'Casino'
				WHEN bettype = 73 THEN 'Bingo'
				WHEN bettype = 1000 THEN 'P2P'
				WHEN bettype = 10 THEN 'Outright'
				WHEN bettype IN (9,29) THEN 'Parlay'
			END AS Product,
			ISNULL(SUM(winlost),0) as winlost
	FROM #source
	WHERE ( bettype BETWEEN 1101 AND 1199
			OR bettype BETWEEN 31 AND 33
			OR bettype BETWEEN 80 AND 120
			OR bettype IN (71,73,10,1000,9,29)			
			)			
	GROUP BY CASE	WHEN bettype BETWEEN 31 AND 33 THEN 'Racing gross income'
				WHEN bettype BETWEEN 81 AND 120 THEN 'Number Game'	
				WHEN bettype BETWEEN 1101 AND 1199 THEN 'Live Casino'
				WHEN bettype = 71 THEN 'Casino'
				WHEN bettype = 73 THEN 'Bingo'
				WHEN bettype = 1000 THEN 'P2P'
				WHEN bettype = 10 THEN 'Outright'
				WHEN bettype IN (9,29) THEN 'Parlay'
			END	
	UNION ALL
	SELECT 'Racing' AS Prodcut, @RB_LineTotal AS winlost

	UPDATE @Winning
	SET Product = 'Racing (Due to Partners)',
		winlost = winlost - @RB_LineTotal
	WHERE Product = 'Racing gross income' 

	----- calculate reset
	;WITH rs AS
	(
		SELECT dm.Product,ISNULL(SUM(winlost),0) AS reset
		FROM #source b
			INNER JOIN @dummyBalance dm ON b.custid = dm.custid
		WHERE bettype > 20000
		GROUP BY b.custid, dm.product
	) 	
	SELECT  dm.product, ISNULL(w.winlost,0) AS winlost, ISNULL(rs.reset,0) AS reset
	FROM @winning w	
		FULL OUTER JOIN rs rs ON w.product = rs.product
		RIGHT JOIN @dummyBalance dm ON dm.product = ISNULL(w.product, rs.product)

	DROP TABLE #source
END



GO 
GRANT VIEW DEFINITION ON [Acc_ResetWinning_SelByDate_Original] TO vnteam