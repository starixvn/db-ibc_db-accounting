 ALTER PROCEDURE [dbo].[DBA_DelBet_Custom] 
AS
/*
Created by: Daniel
Task : SP delete bet based on custom conditions
DB: DBTRANS.bodb02

*/
declare @matchid int
select @matchid = 886919

CREATE TABLE #BetDelete (transid BIGINT, custid INT, recommend INT, mrecommend INT, srecommend INT, betfrom NVARCHAR(1),statusID INT)
--CREATE TABLE #SpecialCust (custid int, username varchar(30))
DECLARE @12EUCust TABLE (custid INT, username VARCHAR(30))
DECLARE @Mansion88Cust TABLE (custid INT, username VARCHAR(30))
DECLARE @AlogCust TABLE (custid INT, username VARCHAR(30))


INSERT INTO #BetDelete (transid, custid, recommend, mrecommend, srecommend, betfrom, statusID)   
SELECT DISTINCT transid, custid, recommend, mrecommend, srecommend, betfrom, statusID
FROM bettrans b WITH (nolock)
WHERE--PUT CUSTOM CONDITIONS HERE--
	matchid = @matchid
	and status not in('void', 'reject')
	and liveindicator = 1
	and transdate > '2010-10-29 4:02:27'
	and livehomescore = 0 and liveawayscore = 0

--INSERT MANSION88 CUSTOMER
INSERT INTO @Mansion88Cust (custid,username)
SELECT custid, username FROM custinfo (nolock) WHERE srecommend in (
    SELECT custid FROM customer (nolock) WHERE UserName like 'MS88Super%' and roleid=4
) and roleid = 1

--INSERT Alog site CUSTOMER
INSERT INTO @AlogCust (custid,username)
SELECT custid, username FROM custinfo (nolock) WHERE srecommend in (
    SELECT custid FROM customer (nolock) WHERE username like 'ALogSuper%' and roleid=4
) and roleid = 1


--INSERT 12EU CUSTOMER
INSERT INTO @12EUCust (custid,username)
SELECT custid,username FROM customer WITH (nolock)
WHERE username = '12EU'

-- STEP 1 : BackUp
    INSERT INTO
        zzzbettrans
        (transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator , refno, winlostdate, betfrom, betcheck, checktime, matchid, bettype)
    SELECT
         transid, custid, CURRENT_TIMESTAMP, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator , refno, winlostdate, betfrom, betcheck, checktime, matchid, bettype
    FROM
        bettrans b WITH (nolock)
    WHERE --customer condition
		matchid = @matchid
		and status not in('void', 'reject')
		and liveindicator = 1
		and transdate > '2010-10-29 4:02:27'
		and livehomescore = 0 and liveawayscore = 0

-- STEP 2 : Update
--    begin tran
        UPDATE 
            bettrans WITH (ROWLOCK, UPDLOCK)
        SET winlost=actual_stake,ruben=1,statuswinlost=6, status = 'Void', creator = 1060606,
            awinlost = 0, mwinlost = 0, swinlost = 0, playercomm = 0, comm  = 0, acomm = 0, scomm = 0, statusID = 102       
        WHERE
            transid in (SELECT transid FROM #BetDelete)

-- update totalbets
DECLARE @Total TABLE (oddsid INT, HomeTotal MONEY, AwayTotal MONEY)

INSERT INTO @Total
SELECT
    oddsid,
    SUM(CASE WHEN betteam='h' THEN (CASE WHEN ABS(odds) > 1 THEN ABS(odds) ELSE 1 END * b.stake * e.actualrate * (1-b.tpositiontaking)) ELSE 0 END) homeTotal,
    SUM(CASE WHEN betteam='a' THEN (CASE WHEN ABS(odds) > 1 THEN ABS(odds) ELSE 1 END * b.stake * e.actualrate * (1-b.tpositiontaking)) ELSE 0 END) awayTotal
FROM bettrans b WITH (nolock)
    INNER JOIN exchange e WITH (nolock) ON b.currency = e.exchangeid
WHERE bettype in (1,3,7,8) AND ruben = 0 AND oddsid <> 0 and matchid = @matchid
GROUP BY oddsid

UPDATE odds WITH (rowlock, updlock)
SET hometotal = t.HomeTotal, awaytotal = t.AwayTotal
FROM @Total t WHERE odds.oddsid = t.oddsid AND odds.matchid = @matchid

--after delete, return all deleted deposit bets with additional information for mailing
IF exists(
    SELECT 1 FROM #BetDelete INNER join bettrans b ON #BetDelete.transid = b.transid
    WHERE b.betfrom  IN ('D', 'M', 'E')
    --or  #BetDelete.custid in (SELECT custid FROM #SpecialCust WHERE username = '12EU')  
    or  #BetDelete.custid in (SELECT custid FROM @12EUCust)  
    or #BetDelete.custid in (SELECT custid FROM @Mansion88Cust)
    or #BetDelete.custid in (SELECT custid FROM @AlogCust))
BEGIN

    SELECT
        MATCH.homeid,
        MATCH.awayid,
        MATCH.matchcode,
        MATCH.eventdate,
        MATCH.leagueid,
        GETDATE() AS DATETIME,
        isnull(MATCH.isNeutral, CONVERT(BIT,0)) AS IsNeutral
    FROM
        MATCH WITH (NOLOCK)
    WHERE 
        MATCH.matchid = @matchID

    SELECT
        customer.username,
        customer.username2,
        dbo.f_ShowOddsByBettype(b.bettype, b.oddsType) + b.odds AS odds,  
        CASE dbo.f_ShowOddsByBettype(b.bettype,1) WHEN 1 THEN b.OddsType ELSE 0 END OddsType, 
        b.transdate,
        b.bettype,
        b.transid AS refno,
        betteam,
        hdp1,
        hdp2,
        betfrom,
        livehomescore,
        liveawayscore,
        cr.username creator,
        stake AS StakePositiontaking,           
        b.currency,
        ag.site
    FROM
        bettrans b WITH (NOLOCK)
        INNER JOIN customer  WITH (NOLOCK) ON customer.custid=b.custid
        INNER JOIN customer cr WITH (NOLOCK) ON cr.custid = b.creator
        INNER JOIN customer ag WITH (NOLOCK) ON customer.recommend = ag.custid
    WHERE b.transid IN(SELECT transid FROM #BetDelete)
        and (b.betfrom  IN ('D', 'M', 'E')
        --or  customer.custid IN (SELECT custid FROM #SpecialCust WHERE username = '12EU') --Email 12EU if delete
        or  customer.custid IN (SELECT custid FROM @12EUCust) --Email 12EU if delete
        or customer.custid in (SELECT custid FROM @Mansion88Cust) --Email Mansion88 if delete                
        or customer.custid in (SELECT custid FROM @AlogCust)) --Email Alog site if delete                
    ORDER BY transid
   
END

SELECT transid,
bd.custid, mem.UserName        AS CustUserName,
bd.recommend, ag.UserName    AS AgUserName,
bd.mrecommend, mag.UserName AS MagUserName,
bd.srecommend, sag.Username AS SagUserName
FROM
#BetDelete bd (nolock)
INNER JOIN custinfo mem (nolock) ON bd.custid     = mem.custid
INNER JOIN custinfo ag  (nolock) ON bd.recommend  = ag.custid
INNER JOIN custinfo mag (nolock) ON bd.mrecommend = mag.custid
INNER JOIN custinfo sag (nolock) ON bd.srecommend = sag.custid

DROP TABLE #BetDelete
--DROP TABLE #SpecialCust

GO
GRANT EXECUTE ON [dbo].[DBA_DelBet_Custom] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[DBA_DelBet_Custom] TO [vnteam]