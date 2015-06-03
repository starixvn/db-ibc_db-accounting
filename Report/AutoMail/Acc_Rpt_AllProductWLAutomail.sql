ALTER PROCEDURE [dbo].[Acc_Rpt_AllProductWLAutomail]
	@AllowSendEmail BIT = 0 OUTPUT
AS
/*
	Created: Dom
	Date: 20140418
	Task : Automail Win Loss reports for all products
	DB: DBACC.bodb02
	Original:

	Revisions:
		- 20150529@Jim: support Gold Deluxe & Metric Gaming (Feature #35359)
	Param's Explanation:
	
*/

BEGIN

	DECLARE @dummyBalance TABLE ([group] varchar(10),orderby INT, custid INT, product VARCHAR(50))
	
	INSERT INTO @dummyBalance 
			  SELECT	'SB',1, 6911909	, 'Sportsbook Live'			---- DWLSPL'
	UNION ALL SELECT	'SB',2, 6911911	, 'Sportsbook Non-Live'		---- DWLSPNL
	UNION ALL SELECT	'SB',3, 6911913	, 'Parlay'		---- DWLParlay
	UNION ALL SELECT	'SB',4, 6911914	, 'Outright'	---- DWLOutright
	UNION ALL SELECT	'3rd', 5, 6911916	, 'RNG Casino'		---- DWLCasino
	UNION ALL SELECT	'3rd', 6, 6911917	, 'Live Casino' ---- DWLLiveCasino
	UNION ALL SELECT	'3rd', 7, 18123445, 'Gold Deluxe'		---- DWLGoldDeluxe
	UNION ALL SELECT	'3rd', 8, 6911918	, 'Number Game' ---- DWLNumber	
	UNION ALL SELECT	'3rd', 9, 6911919	, 'Racing'		---- DWLRacing
	UNION ALL SELECT	'partners', 10, 7723121	, 'Racing (Due to Partners)'	----- VNM-Racing Partners MYR
	UNION ALL SELECT	'3rd', 11, 6913085	, 'Bingo'		---- DWLBingo
	UNION ALL SELECT	'3rd', 12, 8158305	, 'Virtual Sports'	---- DWLVirtualSports
	UNION ALL SELECT	'3rd', 13, 14054918, 'Keno'		---- DWLKeno
	UNION ALL SELECT	'3rd', 14, 18123442, 'Metric Gaming - Super Live'		---- DWLMetricGaming

	

	DECLARE @_fromdate    DATETIME,
			@_todate      DATETIME,
			@totalrows INT
			
			
	SELECT @_todate = convert(varchar(10), getdate()-1, 120)
	SELECT @_fromdate = convert(varchar(10), DATEADD(DAY, -(DAY(GETDATE()-1)), GETDATE()),120)

    CREATE TABLE #TempYesterday (CustId INT, Winlostyesterday MONEY)
	CREATE TABLE #TempMonthToDate (WinlostDate DATETIME,CustId int, WinlostMonthToDate money)
	CREATE TABLE #TempCustTrans (CustId INT)
	
    
    DECLARE @movebetdate datetime,
        @balanceupdate datetime
        --@f_date datetime,
        --@t_date datetime
    
        SELECT 
            TOP 1 @balanceupdate = winlostdate
        FROM bodb02.dbo.Bettrans WITH(NOLOCK)
        WHERE bettype = 20000 and matchid = 0 and custid = 3
            
		--SELECT @f_date = @balanceupdate
		--SELECT @t_date = @_todate
		/*
        INSERT INTO #TempMonthToDate
        SELECT b.winlostdate,
			b.custid, 
			ISNULL(-SUM(winlost-actual_stake),0) AS winlostyesterday
		FROM bettrans b WITH(NOLOCK) 
			WHERE b.winlostdate BETWEEN @f_date AND @t_date
			AND	b.custid in( SELECT custid FROM @dummyBalance )
			AND ruben = 1 
			AND statusid NOT IN (101,102,103,121,141)	
		GROUP BY b.custid,b.winlostdate
		ORDER BY b.custid
		*/
        IF @_fromdate < @balanceupdate --get bettrans BK
        BEGIN
            
			--SELECT @f_date = @_fromdate
            --SELECT @t_date = @balanceupdate - 1
            
            INSERT INTO #TempMonthToDate
            SELECT b.winlostdate,
				b.custid, 
				ISNULL(-SUM(b.Credit),0) AS winlostyesterday
			FROM bodb_archive.dbo.transfer_bk b WITH(NOLOCK) 
			 WHERE b.winlostdate BETWEEN @_fromdate AND @balanceupdate - 1
				AND	b.custid in( 6911909,6911911,6911913,6911914,6911916,6911917,6911918,6911919,6913085,7723121,8158305, 14054918,18123445,18123442 )
				AND b.bettype IN(21001,21002)
			GROUP BY b.custid,b.winlostdate
			ORDER BY b.custid

			INSERT INTO #TempMonthToDate
			SELECT b.winlostdate,
				b.custid, 
				ISNULL(-SUM(winlost-actual_stake),0) AS winlostyesterday
			FROM bettrans b WITH(NOLOCK) 
				WHERE b.winlostdate BETWEEN @balanceupdate AND @_todate
				AND	b.custid in( SELECT custid FROM @dummyBalance )
				AND ruben = 1 
				AND statusid NOT IN (101,102,103,121,141)	
				AND b.bettype IN(21001,21002)
			GROUP BY b.custid,b.winlostdate
			ORDER BY b.custid

			PRINT @balanceupdate;
			

        END
		ELSE IF(@_fromdate >= @balanceupdate)
		BEGIN
			INSERT INTO #TempMonthToDate
			SELECT b.winlostdate,
				b.custid, 
				ISNULL(-SUM(winlost-actual_stake),0) AS winlostyesterday
			FROM bettrans b WITH(NOLOCK) 
				WHERE b.winlostdate BETWEEN @_fromdate AND @_todate
				AND	b.custid in( SELECT custid FROM @dummyBalance )
				AND ruben = 1 
				AND statusid NOT IN (101,102,103,121,141)	
				AND b.bettype IN(21001,21002)
			GROUP BY b.custid,b.winlostdate
			ORDER BY b.custid

			PRINT @balanceupdate;

		END

		INSERT INTO #TempYesterday
		SELECT b.custid, 
			b.WinlostMonthToDate AS winlostyesterday
		FROM #TempMonthToDate b 
		WHERE b.winlostdate = @_todate
		ORDER BY b.custid

/****************************This Section is to check there is no ticklet and no key in action**************************/
	/*
	
		Find product that has no ticket and then identify accounts don't need to transfer. If there is no ticket, transfer account should have winlost amount = 0
	
	*/
	INSERT INTO #TempCustTrans
	SELECT DISTINCT custid = CASE 
						WHEN ((bettype <= 999 AND bettype NOT IN (9,10,29,31,32,33,71,72,73) AND bettype NOT BETWEEN 81 AND 120) OR bettype BETWEEN 1301 AND 1334) AND liveindicator =1 THEN 6911909
						WHEN ((bettype <= 999 AND bettype NOT IN (9,10,29,31,32,33,71,72,73) AND bettype NOT BETWEEN 81 AND 120) OR bettype BETWEEN 1301 AND 1334) AND liveindicator =0 THEN 6911911
						WHEN bettype IN(9,29 ) THEN 6911913
						WHEN bettype = 10 THEN 6911914
						WHEN bettype IN (71,72) THEN 6911916
						WHEN bettype BETWEEN 1101 AND 1199 THEN 6911917
						WHEN bettype BETWEEN 81 AND 120 THEN 6911918
						WHEN bettype IN (31,32,33) THEN 6911919
						WHEN bettype = 73 THEN 6913085
						WHEN bettype BETWEEN 1201 AND 1299 THEN 8158305
						WHEN bettype BETWEEN 1501 AND 1599 THEN 14054918
						WHEN bettype IN (31,32,33) THEN 7723121
						WHEN bettype IN (1701,1702,1703) THEN 18123445
						WHEN bettype IN (1701,1702,1703) THEN 18123445
						WHEN bettype IN  (801,802,803,804,805,806,807,808) THEN 18123442
					END
	FROM bodb_report.dbo.rptWinLost b WITH(NOLOCK)
	WHERE b.winlostdate = @_todate

	INSERT INTO #TempYesterday
	SELECT d.custid,0 
	FROM @dummyBalance d LEFT JOIN #TempCustTrans c ON d.custid = c.CustId
	WHERE c.CustId IS NULL AND d.CustId NOT IN(SELECT custid FROM #TempYesterday)
	

	/****************************End**************************/
	
	SELECT @totalrows = COUNT(*) FROM #TempYesterday
	IF(@totalrows=12) SET @AllowSendEmail = 1 ELSE SET @AllowSendEmail = 0
---------------------------------------------------------------------------------------


	SELECT [group], c.custid, c.product,
		b.winlostyesterday,
		ISNULL(mb.winlostmonthtodate,0) winlostmonthtodate
	FROM @dummyBalance c
	INNER JOIN #TempYesterday b ON b.CustId = c.custid
	LEFT JOIN 
	(
		SELECT custid ,SUM(WinlostMonthToDate) WinlostMonthToDate FROM #TempMonthToDate GROUP BY CustId
	)  mb
	ON c.CustId = mb.CustId
	ORDER BY c.orderby 


	DROP TABLE #TempYesterday
	DROP TABLE #TempMonthToDate
	DROP TABLE #TempCustTrans

END


GO

GRANT EXECUTE ON [dbo].[Acc_Rpt_AllProductWLAutomail] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_AllProductWLAutomail] TO [vnteam] AS [dbo]
GO

