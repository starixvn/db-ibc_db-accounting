
ALTER PROCEDURE [dbo].[Acc_ResetWinning_SelByDate14_Original]
	@winlostdate	DATETIME,	
	@totalBalance	MONEY = 0 OUTPUT
AS

/*	
	Created: 20120612@Lukas
	Task: Reset Winning - Get data by Date
	DB: DB054.BODB02
	
	Revision:
		- 20120723@Lukas: Excluding transfered transactions of dummy balance accounts
		- 20120821@Sophia: define IBC racing net income instead of gross income
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
	UNION ALL SELECT	7723121 , 'Racing (Due to Partners)' ---- VNM-Racing Partners MYR
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

	---- get total balance
	SELECT @totalBalance = ISNULL(SUM(winlost),0)
	FROM #source
	WHERE custid NOT IN (SELECT custid FROM @dummyBalance) and bettype <> 20000

	IF EXISTS (SELECT 1 FROM #source WHERE bettype = 20000) --- openning balance
	BEGIN
		INSERT INTO @Winning(product,winlost)		
		SELECT 'Openning Balance', SUM(ISNULL(winlost,0))
		FROM #source 
		WHERE bettype = 20000
	END

	INSERT INTO @Winning(product,winlost)
	--- all product
	SELECT 'All products', SUM(ISNULL(winlost,0)) as winlost
	FROM #source
	WHERE bettype = 19999 AND custid NOT IN (SELECT custid FROM @dummyBalance)
	

	----- calculate reset
	;WITH rs AS
	(
		SELECT 'All products' AS product,SUM(ISNULL(winlost,0)) AS reset
		FROM #source b			
		WHERE custid IN (SELECT custid FROM @dummyBalance) AND bettype <> 20000
	) 	
	SELECT  w.product, ISNULL(w.winlost,0) AS winlost, ISNULL(rs.reset,0) AS reset
	FROM @winning w	
		LEFT JOIN rs rs ON w.product = rs.product

	DROP TABLE #source	
END



GO 
GRANT VIEW DEFINITION ON [Acc_ResetWinning_SelByDate14_Original] TO vnteam