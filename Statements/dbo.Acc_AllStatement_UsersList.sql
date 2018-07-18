/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [bodb02]
GO

ALTER PROCEDURE  [dbo].[Acc_AllStatement_UsersList]
    @UserList		VARCHAR(6000),
    @FromDate		SMALLDATETIME,
    @ToDate			SMALLDATETIME,
    @BalanceUpDay	SMALLDATETIME
AS

/*
	Created by: KhoaTran
    Date: 20100203
    Task: NAP Accounting - Others - Export Multi Statement - Select Statement by users list
    DB: DBACC.bodb02
   
    Revisions:     
		- 20100602@Khoa: put accounts' currency to the temp table #TEMP_USER_LIST 
		- 20101224@Lukas: Re-arrange bettype
		- 20180628@Percy: Fix issue duplicated data [RedmineID: #97316]
       
*/

BEGIN
	SET NOCOUNT ON

    DECLARE @tempUsername TABLE (username VARCHAR(50))
    CREATE TABLE #TEMP_USER_LIST (custid INT PRIMARY KEY, username VARCHAR(50), roleid INT, currency INT )

    INSERT INTO @tempUsername (username)
    SELECT  val AS username
    FROM dbo.strSplit(@userlist, ',')

    INSERT INTO #TEMP_USER_LIST (custid, username, roleid, currency)
    SELECT custid, username, roleid, currency
	FROM custinfo (NOLOCK)
	WHERE username IN (SELECT username FROM @tempUsername)

    CREATE TABLE #StatementTable
	(
		accdate		SMALLDATETIME,
		totalamt	MONEY,
		transtype	NVARCHAR(100),
		transdesc	NVARCHAR(300),   
		roleid		INT,
		username	VARCHAR(50),
		currency	INT
    )

	IF @ToDate >= @BalanceUpDay
	BEGIN
		--IF @roleid = 1
        IF EXISTS (SELECT 1 FROM #TEMP_USER_LIST (NOLOCK) WHERE roleId = 1)
        BEGIN
			INSERT INTO #StatementTable (accdate, totalamt, transtype, transdesc, roleid, username, currency)
            SELECT            
                winlostdate accdate,
                SUM(winlost-actual_stake) totalamt,
                'BET' AS transtype,
                'Betting' AS transdesc,
				1 AS roleid,
                username, currency
            FROM bettrans WITH (NOLOCK)
            WHERE
                bettype between 1 and 19999
                and custid IN (SELECT custid FROM #TEMP_USER_LIST WHERE roleid=1)
                and winlostdate between @fromdate and @todate
            GROUP BY winlostdate, username, currency
           
            INSERT INTO #StatementTable (accdate, totalamt, transtype, transdesc, roleid, username, currency)
            SELECT
                winlostdate accdate,
                SUM(playercomm) totalamt,
                'COM' transtype,
                'Commission' transdesc,
				1 AS roleid,
                t.username, t.currency
            FROM bettrans b WITH (NOLOCK) INNER JOIN #TEMP_USER_LIST t ON b.custid = t.custid AND t.roleid = 1
            WHERE
                bettype between 1 and 19999            
                and winlostdate between @fromdate and @todate
                and playercomm<>0
            GROUP BY winlostdate, t.username, t.currency

            INSERT INTO #StatementTable (accdate, totalamt, transtype, transdesc, roleid, username, currency)
            SELECT
                transdate accdate,
                SUM(winlost-actual_stake) totalamt,
                CONVERT(VARCHAR, bettype) transtype,
                transdesc,
				1 AS roleid,
                t.username, t.currency
            FROM bettrans b WITH (NOLOCK) INNER JOIN #TEMP_USER_LIST t ON b.custid = t.custid AND t.roleid = 1
            WHERE
                bettype >= 20000            
                and winlostdate between @fromdate and @todate
            GROUP BY bettype,transdesc,transdate,t.username,t.currency

            -- customer deleted/void ticket
            INSERT INTO #StatementTable (accdate, totalamt, transtype, transdesc, roleid, username, currency)
            SELECT DISTINCT
                eventdate accdate,
                0 totalamt,
                'BET' transtype,
                'Cancelled/Deleted Bets' transdesc,
				1 AS roleid,
                t. username,
                t. currency
            FROM zzzbettrans b WITH (NOLOCK)
                INNER join MATCH m (NOLOCK) ON b.matchid = m.matchid
                INNER join #TEMP_USER_LIST t ON b.custid = t.custid AND t.roleid = 1
            WHERE
                bettype between 1 and 19999
                and eventdate between @fromdate and @todate
            GROUP BY eventdate, t.username, t. currency
           
            --Remove All
            INSERT INTO #StatementTable (accdate, totalamt, transtype, transdesc, roleid, username, currency)
            SELECT DISTINCT
                eventdate accdate,
                0 totalamt,
                'BET' transtype,
                'Cancelled/Deleted Bets' transdesc,
				1 AS roleid,
                t.username,
                t.currency
            FROM zzzbettrans b WITH (NOLOCK)
                INNER join match14 m (NOLOCK) ON b.matchid = m.matchid
                INNER join #TEMP_USER_LIST t ON b.custid = t.custid AND t.roleid = 1
            WHERE
                bettype between 1 and 19999
                and eventdate between @fromdate and @todate
            GROUP BY eventdate, t.username, t. currency
        END

		--IF @roleid = 2
        IF EXISTS (SELECT 1 FROM #TEMP_USER_LIST (NOLOCK) WHERE roleId = 2)
        BEGIN
			INSERT INTO #StatementTable (accdate, totalamt, transtype, transdesc, roleid, username, currency)
            SELECT
                transdate accdate,
                SUM(winlost-actual_stake) totalamt ,
                CONVERT(VARCHAR, bettype) transtype,
                transdesc,
				2 AS roleid,
                username, currency
            FROM bettrans WITH (NOLOCK)        
            WHERE
                bettype >= 20000
                and custid IN (SELECT custid FROM #TEMP_USER_LIST WHERE roleid=2)
                and winlostdate between @fromdate and @todate
                GROUP BY bettype,transdesc,transdate,username,currency
               
            INSERT INTO #StatementTable (accdate, totalamt, transtype, transdesc, roleid, username, currency)
            SELECT
                winlostdate accdate,
                SUM(awinlost) totalamt,
                'POS' transtype,
                'Position' transdesc,
				2 AS roleid,
                t.username, t.currency
            FROM bettrans b WITH (NOLOCK) INNER JOIN #TEMP_USER_LIST t ON b.recommend = t.custid and roleid=2
            WHERE
                bettype between 1 and 19999
                and winlostdate between @fromdate and @todate
                GROUP BY winlostdate,  t.currency, t.username
            HAVING SUM(awinlost) <> 0
           
            INSERT INTO #StatementTable (accdate, totalamt, transtype, transdesc, roleid, username, currency)
            SELECT
                winlostdate accdate,
                SUM(comm-playercomm) totalamt,
                'COM' transtype,
                'Commission' transdesc,
				2 AS roleid,
                t.username, t.currency
            FROM bettrans b WITH (NOLOCK) INNER JOIN #TEMP_USER_LIST t ON b.recommend = t.custid and roleid=2
            WHERE
                bettype between 1 and 19999            
                and winlostdate between @fromdate and @todate
            GROUP BY winlostdate,  t.currency , t.username
            HAVING SUM(comm-playercomm) <> 0
        END

		--IF @roleid = 3
        IF EXISTS (SELECT 1 FROM #TEMP_USER_LIST (NOLOCK) WHERE roleId = 3)
        BEGIN
			INSERT INTO #StatementTable (accdate, totalamt, transtype, transdesc, roleid, username, currency)
            SELECT
                transdate accdate,
                SUM(winlost-actual_stake) totalamt ,
                CONVERT(VARCHAR, bettype) transtype,
                transdesc,
				3 AS roleid,
                username, currency
            FROM bettrans WITH (NOLOCK)        
            WHERE
                bettype >= 20000
                and bettrans.custid IN (SELECT custid FROM #TEMP_USER_LIST WHERE roleid=3)
                and winlostdate between @fromdate and @todate
                GROUP BY bettype,transdesc,transdate,username, currency
       
            INSERT INTO #StatementTable (accdate, totalamt, transtype, transdesc, roleid, username, currency)
            SELECT
                winlostdate accdate,
                SUM(mwinlost) totalamt,
                'POS' transtype,
                'Position' transdesc,
				3 AS roleid,
                t.username, t.currency
            FROM bettrans b WITH (NOLOCK) INNER JOIN #TEMP_USER_LIST t ON b.mrecommend = t.custid
            WHERE
                bettype between 1 and 19999
                and mrecommend IN (SELECT custid FROM #TEMP_USER_LIST WHERE roleid=3)
                and winlostdate between @fromdate and @todate
                GROUP BY winlostdate , t.currency, t.username
            HAVING SUM(mwinlost) <> 0
       
            INSERT INTO #StatementTable (accdate, totalamt, transtype, transdesc, roleid, username, currency)
            SELECT
                winlostdate accdate,
                SUM(acomm-comm) totalamt,
                'COM' transtype,
                'Commission' transdesc,
				3 AS roleid,
                t. username, t.currency
            FROM bettrans b WITH (NOLOCK) INNER JOIN #TEMP_USER_LIST t ON b.mrecommend = t.custid
            WHERE
                bettype between 1 and 19999
                and mrecommend IN (SELECT custid FROM #TEMP_USER_LIST WHERE roleid=3)
                and winlostdate between @fromdate and @todate
                GROUP BY winlostdate ,  t.currency, t.username
            HAVING SUM(acomm-comm) <> 0
        END
   
		--IF @roleid = 4
        IF EXISTS (SELECT 1 FROM #TEMP_USER_LIST (NOLOCK) WHERE roleId = 4)
        BEGIN       
            INSERT INTO #StatementTable (accdate, totalamt, transtype, transdesc, roleid, username, currency)
            SELECT
                transdate accdate,
                SUM(winlost-actual_stake) totalamt ,
                CONVERT(VARCHAR, bettype) transtype,
                transdesc,
				4 AS roleid,
                t.username, t.currency
            FROM bettrans b WITH (NOLOCK) INNER JOIN #TEMP_USER_LIST t ON b.srecommend = t.custid
            WHERE
            bettype >= 20000
            and  b.custid IN (SELECT custid FROM #TEMP_USER_LIST WHERE roleid=4)       
            and winlostdate between @fromdate and @todate
            GROUP BY bettype,transdesc,transdate, t.username, t.currency
       
            INSERT INTO #StatementTable (accdate, totalamt, transtype, transdesc, roleid, username, currency)
            SELECT
                winlostdate accdate,
                SUM(swinlost) totalamt,
                'POS' transtype,
                'Position' transdesc,
				4 AS roleid,
                t.username, t.currency
            FROM bettrans b WITH (NOLOCK) INNER JOIN #TEMP_USER_LIST t ON b.srecommend = t.custid
            WHERE
                bettype between 1 and 19999
                and srecommend IN (SELECT custid FROM #TEMP_USER_LIST WHERE roleid=4)       
                and winlostdate between @fromdate and @todate
                GROUP BY winlostdate, t.currency, t.username
                HAVING SUM(swinlost) <> 0
       
            INSERT INTO #StatementTable (accdate, totalamt, transtype, transdesc, roleid, username, currency)
            SELECT
                winlostdate accdate,
                SUM(scomm-acomm) totalamt,
                'COM' transtype,
                'Commission' transdesc,
				4 AS roleid,
                t.username, t.currency
            FROM bettrans b WITH (NOLOCK) INNER JOIN #TEMP_USER_LIST t ON b.srecommend = t.custid
            WHERE
                bettype between 1 and 19999
                and srecommend IN (SELECT custid FROM #TEMP_USER_LIST WHERE roleid=4)       
                and winlostdate between @fromdate and @todate
                GROUP BY winlostdate,  t.currency , t.username
            HAVING SUM(scomm-acomm) <> 0
        END
	END

	IF @FromDate < @BalanceUpDay
	BEGIN
		IF @ToDate >= DATEADD(DAY, -1, @BalanceUpDay)
			SELECT @ToDate = DATEADD(DAY, -1, @BalanceUpDay) + ' 23:59:59'

		INSERT INTO #StatementTable (accdate, totalamt, transtype, transdesc, roleid, username, currency)
		SELECT accdate, totalamt, transtype, transdesc, t.roleid, t.username, t.currency
		FROM bodb_Report.dbo.Statement s WITH (NOLOCK)
			INNER JOIN #TEMP_USER_LIST t ON s.custid = t.custid
		WHERE accdate between @fromdate and @todate
	END

	SELECT
		username,
		roleid ,
		accdate ,
		totalamt ,
		transtype ,
		transdesc ,       
		currency
	FROM #StatementTable
	ORDER BY username, accdate, transtype, transdesc, CASE WHEN transdesc like '%opening balance%' THEN 1 ELSE 2 END

	DROP TABLE #TEMP_USER_LIST
	DROP TABLE #StatementTable
END
GO