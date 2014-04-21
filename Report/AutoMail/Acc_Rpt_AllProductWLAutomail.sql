ALTER PROCEDURE [dbo].[Acc_Rpt_AllProductWLAutomail]
	@totalrow INT = 0 OUTPUT
AS
/*
	Created: Dom
	Date: 20140418
	Task : Automail Win Loss reports for all products
	DB: DBACC.bodb02
	Original:

	Revisions:
		
	Param's Explanation:
	
*/

BEGIN

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
	UNION ALL SELECT	6913085	, 'Bingo'		---- DWLBingo
	UNION ALL SELECT	8158305	, 'Virtual Sports'	---- DWLVirtualSports
	UNION ALL SELECT	14054918, 'Keno'		---- DWLKeno



	DECLARE @_fromdate    DATETIME,
			@_todate      DATETIME
			
			
	SELECT @_todate = convert(varchar(10), getdate()-1, 120)
	SELECT @_fromdate = convert(varchar(10), DATEADD(DAY, -(DAY(GETDATE()) - 1), GETDATE()),120)

    CREATE TABLE #TempYesterday (CustId int, Winlostyesterday money)

	INSERT INTO #TempYesterday
	SELECT b.custid, 
		ISNULL(-SUM((winlost-actual_stake + awinlost + mwinlost + swinlost + scomm)*actualrate),0) AS winlostyesterday
	FROM bettrans b WITH(NOLOCK) 
	 WHERE b.winlostdate = @_todate
		AND	b.custid in( 6911909,6911911,6911913,6911914,6911916,6911917,6911918,6911919,6913085,7723121,8158305, 14054918)
		AND ruben = 1 
		AND statusid NOT IN (101,102,103,121)	
	GROUP BY b.custid
	ORDER BY b.custid

	SELECT @totalrow = COUNT(*) FROM #TempYesterday
	IF(@totalrow < 12) RETURN;


	CREATE TABLE #TempMonthToDate (CustId int, WinlostMonthToDate money)
    
    DECLARE @movebetdate datetime,
        @balanceupdate datetime,
        @f_date datetime,
        @t_date datetime
    
        SELECT 
            TOP 1 @balanceupdate = winlostdate
        FROM bodb02.dbo.Bettrans WITH(NOLOCK)
        WHERE bettype = 20000 and matchid = 0 and custid = 3
    
        SELECT         
            @movebetdate = max(eventdate) 
        FROM  bodb02.dbo.match14 WITH(NOLOCK)
            
        IF @_todate > @movebetdate -- get bettrans
        BEGIN
            IF @_fromdate < @movebetdate
                SELECT @f_date = @movebetdate
            ELSE
                SELECT @f_date = @_fromdate
            
            SELECT @t_date = @_todate
        
            INSERT INTO #TempMonthToDate
            SELECT b.custid, 
				ISNULL(-SUM((winlost-actual_stake + awinlost + mwinlost + swinlost + scomm)*actualrate),0) AS winlostyesterday
			FROM bettrans b WITH(NOLOCK) 
			 WHERE b.winlostdate BETWEEN @f_date AND @t_date
				AND	b.custid in( 6911909,6911911,6911913,6911914,6911916,6911917,6911918,6911919,6913085,7723121,8158305, 14054918)
				AND ruben = 1 
				AND statusid NOT IN (101,102,103,121)	
			GROUP BY b.custid
			ORDER BY b.custid
        END

        IF @_fromdate <=@movebetdate -- get bettrans14
        BEGIN
            IF @_todate < @movebetdate
                SELECT @t_date = @_todate
            ELSE
                SELECT @t_date = @movebetdate
            
            SELECT @f_date = @_fromdate

            INSERT INTO #TempMonthToDate
            SELECT b.custid, 
				ISNULL(-SUM((winlost-actual_stake + awinlost + mwinlost + swinlost + scomm)*actualrate),0) AS winlostyesterday
			FROM bettrans14 b WITH(NOLOCK) 
			 WHERE b.winlostdate BETWEEN @f_date AND @t_date
				AND	b.custid in( 6911909,6911911,6911913,6911914,6911916,6911917,6911918,6911919,6913085,7723121,8158305, 14054918)
				AND ruben = 1 
				AND statusid NOT IN (101,102,103,121)	
			GROUP BY b.custid
			ORDER BY b.custid
        END
        IF @_fromdate <@balanceupdate --get bettrans BK
        BEGIN
            IF @_todate < @balanceupdate
                SELECT @t_date = @_todate
            ELSE
                SELECT @t_date = @balanceupdate - 1
            
            SELECT @f_date = @_fromdate

            INSERT INTO #TempMonthToDate
            SELECT b.custid, 
				ISNULL(-SUM((winlost-actual_stake + awinlost + mwinlost + swinlost + scomm)*actualrate),0) AS winlostyesterday
			FROM bodb_archive.dbo.bettrans_bk b WITH(NOLOCK) 
			 WHERE b.winlostdate BETWEEN @f_date AND @t_date
				AND	b.custid in( 6911909,6911911,6911913,6911914,6911916,6911917,6911918,6911919,6913085,7723121,8158305, 14054918)
				AND ruben = 1 
				AND statusid NOT IN (101,102,103,121)	
			GROUP BY b.custid
			ORDER BY b.custid

        END


	SELECT b.custid, c.product, 
		SUM(b.Winlostyesterday) AS winlostyesterday,
		SUM(mb.WinlostMonthToDate) AS winlostmonthtodate
	FROM #TempYesterday b WITH(NOLOCK) 
	INNER JOIN #TempMonthToDate mb ON mb.CustId = b.CustId
	INNER JOIN @dummyBalance c ON c.custid = b.custid AND c.custid = mb.CustId
	GROUP BY b.custid, c.product
	ORDER BY b.custid
	
	DROP TABLE #TempYesterday
	DROP TABLE #TempMonthToDate
END


GO

GRANT EXECUTE ON [dbo].[Acc_Rpt_AllProductWLAutomail] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_AllProductWLAutomail] TO [vnteam] AS [dbo]
GO


