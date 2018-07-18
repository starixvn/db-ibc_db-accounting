/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [bodb02]
GO

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
		- 20150619@Sophia: Add Gold Deluxe, AG Casino, Vegas Game [#38512]
		- 20150702@Sophia: Apply Metric Gaming, Microgaming and Bettrade [#36906]
		- 20150722@Sophia: Send mail for dummy account in case of testing
		- 20150928@Sophia: Apply Colosuss Bets and expand the range of AG Casino [#43352]
		- 20150930@Sophia: Fix winlostyesterday at table Transfer_bk [#44701]
		- 20151102@Sophia: Apply Microgaming LC and RNG [RedmineID: #46450]
		- 20151210@Sophia: Apply Cock Fighting [Redmine: #48602]
		- 20151217@Sophia: Apply Muay Thai [Redmine: #48667]
		- 20160114@Sophia: Apply OW RNG [Redmine: #48285]
		- 20160330@Sophia: Remove Bingo [Redmine: #54719]
		- 20160404@Sophia: Apply Allbet [Redmine: #50588]
		- 20160412@Percy: support Voidbridge single wallet [Redmine: #55258]
		- 20160815@Percy: Apply new bettype of Bettrade: 904 [RedmineID: #61786]
		- 20161013@Percy: Apply NG2 [RedmineID: #64117]
		- 20161222@Percy: Apply Fishing World [RedmineID: #65734]
		- 20161227@Percy: Clean up code Cockfighting [RedmineID: #69446]
		- 20170213@Percy: Remove SLI [RedmineID: #70036]
		- 20170323@Percy: Apply Cash Out [RedmineID: #72164]
		- 20170706@Percy: Apply Betradar VS and Keno Lottery [RedmineID: #79521]
		- 20170727@Percy: Expand bettype range of OneRNG Casino [RedmineID: #78424]
		- 20170915@Percy: Change testing dummy account of VS 2 and Lottery [RedmineID: #83298]
		- 20170915@Percy: Apply Lucky 3 [RedmineID: #83227]
		- 20180104@Sophia: Unable to send Automail due to FW winloss = 0 [RedmineID: #89069]
		- 20180116@Percy: Apply Exchange [RedmineID: #88810]
		- 20180313@Percy: Apply Bullfighting, Remove Racing [RedmineID: #84691]
		- 20180412@Percy: Apply OneRnG Jackpot [RedmineID: #90357]
		- 20180521@Percy: Apply PP - Pragmatic, update bettype range of Macau Games [RedmineID: #95529]
		- 20180718@Percy: Change checking rule before send mail [RedmineID: #97983]

	Param's Explanation:
	
*/

BEGIN

	DECLARE @dummyBalance TABLE ([group] varchar(10),orderby INT, custid INT, product VARCHAR(50))
	 
	DECLARE @isTest BIT,@SQL NVARCHAR(100) = OBJECT_NAME(@@PROCID)

	IF  (@SQL like '%_xtest%')
	BEGIN
		SELECT @isTest = 1
	END
	ELSE
	BEGIN
		SELECT @isTest = 0
	END
 
	IF @isTest = 0
	BEGIN 	
		INSERT INTO @dummyBalance ([group], orderby, custid, product )
		SELECT		CASE WHEN Product IN ('SPL','SPNL','Parlay','Outright') THEN 'SB' 
						 ELSE '3rd' END AS [Group]
					, Seq
					, Custid
					, CASE	WHEN Product = 'SPL' THEN 'Sportsbook Live' 
							WHEN Product = 'SPNL' THEN 'Sportsbook Non-Live' 
						 ELSE Product END AS Product
		FROM	bodb_ACC.dbo.Acc_DWLList WITH (NOLOCK)
		WHERE  	Product NOT IN ('Total Balance')
				AND IsDeleted = 0
	END
	ELSE 
	BEGIN 
		INSERT INTO @dummyBalance ([group], orderby, custid, product )
		SELECT		CASE WHEN Product IN ('SPL','SPNL','Parlay','Outright') THEN 'SB' 
						 ELSE '3rd' END AS [Group]
					, Seq
					, Custid
					, CASE	WHEN Product = 'SPL' THEN 'Sportsbook Live' 
							WHEN Product = 'SPNL' THEN 'Sportsbook Non-Live' 
						 ELSE Product END AS Product
		FROM 	bodb_ACC.dbo.Acc_DWLList_xtest WITH (NOLOCK)
		WHERE  	Product NOT IN ('Total Balance')
				AND IsDeleted = 0
	END

	DECLARE @_fromdate    DATETIME,
			@_todate      DATETIME,
			@totalrows 	  INT,
			@TotalDummy	  INT
			
			
	SELECT @_todate = convert(varchar(10), getdate()-1, 120)
	SELECT @_fromdate = convert(varchar(10), DATEADD(DAY, -(DAY(GETDATE()-1)), GETDATE()),120)

    CREATE TABLE #TempYesterday (CustId INT, Winlostyesterday MONEY)
	CREATE TABLE #TempMonthToDate (WinlostDate DATETIME,CustId int, WinlostMonthToDate money)
	
    
    DECLARE @movebetdate datetime,
        @balanceupdate datetime
    
        SELECT 
            TOP 1 @balanceupdate = winlostdate
        FROM bodb02.dbo.Bettrans WITH(NOLOCK)
        WHERE bettype = 20000 and matchid = 0 and custid = 3
            
        IF @_fromdate < @balanceupdate --get bettrans BK
        BEGIN
            INSERT INTO #TempMonthToDate
            SELECT b.winlostdate,
				b.custid, 
				ISNULL(-SUM(b.Credit - b.Debit),0) AS winlostyesterday
			FROM bodb_archive.dbo.transfer_bk b WITH(NOLOCK) 
			 WHERE b.winlostdate BETWEEN @_fromdate AND @balanceupdate - 1
				AND	b.custid in (Select CustId from @dummyBalance )
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



	INSERT INTO #TempYesterday
	SELECT d.custid,0 
	FROM @dummyBalance d
		LEFT JOIN #TempYesterday c ON d.custid = c.CustId
	WHERE c.CustId IS NULL
	 
	IF EXISTS (
		SELECT 1
		FROM #TempYesterday ty
			INNER JOIN @dummyBalance db ON ty.CustId = db.custid
		WHERE db.[group] = 'SB'
			AND ty.Winlostyesterday <> 0
	)
		SET @AllowSendEmail = 1
	ELSE
		SET @AllowSendEmail = 0
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
END
GO