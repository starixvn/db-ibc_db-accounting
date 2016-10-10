USE [bodb02];
GO
IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[NAP_Winlimit_UserByIPSel]')
          AND type IN(N'P', N'PC')
)
    DROP PROCEDURE [dbo].[NAP_Winlimit_UserByIPSel];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE [dbo].[NAP_Winlimit_UserByIPSel] @IP NVARCHAR(50)
AS

/*
Created: Franklin	
Date: 2016-06-22
Task: #57722 - Implement Game Win Limit Control phase2

DB: DBCUST/CustDB

Revisions:
20160923@Jacob: Risk & Control - Phase 3 [#61220].

Parameters Explanation:
Eample:
EXEC [NAP_Winlimit_UserByIPSel] @IP = '127.0.0.1'
*/

     SET NOCOUNT ON;

     ----Get Sport Bettype Matrix------
     DECLARE @SportBettype TABLE
     (ProductID TINYINT,
      Bettype   SMALLINT,
      EventType TINYINT
     );
     INSERT INTO @SportBettype
     EXEC dbo.Acc_SportBettypeMatrix_Sel
          @mode = 4;
     DECLARE @min_date SMALLDATETIME, @max_date SMALLDATETIME, @min_date14 SMALLDATETIME, @max_date14 SMALLDATETIME;
     SELECT @min_date = MIN(winlostdate),
            @max_date = MAX(winlostdate)
     FROM dbo.bettrans WITH (NOLOCK)
     WHERE bettype < 19001;
     SELECT @min_date14 = MIN(winlostdate),
            @max_date14 = MAX(winlostdate)
     FROM dbo.bettrans14 WITH (NOLOCK);
     DECLARE @UserTicketTmp TABLE
     (custid   INT,
      totalBet INT,
      Type     TINYINT
     ); --Type: 1: Ticket in bettrans, 2: Ticket in translog (for Keno)

     INSERT INTO @UserTicketTmp
     (custid,
      totalBet,
      Type
     )
            SELECT custid,
                   COUNT(custid),
                   1
            FROM dbo.bettrans AS b WITH (NOLOCK)
            WHERE winlostdate = @fromdate
                  AND bettype < 19001
                  AND bettype <> 903
                  AND ip = @ip
                  --exclude metric gaming running ticket
                  AND (b.bettype NOT BETWEEN 801 AND 806
                       OR (b.bettype BETWEEN 801 AND 806
                           AND b.statusID NOT IN(0, 1)))
            GROUP BY custid
            UNION ALL
            SELECT tl.custid,
                   COUNT(tl.custid),
                   2
            FROM dbo.translog tl WITH (NOLOCK)
                 INNER JOIN @SportBettype sp ON tl.gameid = sp.BetType
                                                AND (sp.ProductID IN(8, 12, 13, 15, 19)
                 OR tl.gameid BETWEEN 801 AND 899)
            WHERE winlostdate = @fromdate 
                  --AND gameid between 1501 and 1599
                  AND ip = @ip
                  AND statusid = 0
            GROUP BY custid;
     CREATE TABLE #tmpUserBet
     (custid    INT,
      soccerBet INT DEFAULT 0,
      totalBet  INT DEFAULT 0,
      is14      BIT DEFAULT 0,
      PRIMARY KEY(CustID, is14)
     );
     IF @fromdate >= @min_date
        AND @fromdate <= @max_date
         BEGIN
             INSERT INTO #tmpUserBet
             (custid,
              totalBet
             )
                    SELECT custid,
                           SUM(totalBet)
                    FROM @UserTicketTmp
                    GROUP BY custid;
             UPDATE #tmpUserBet
               SET
                   soccerBet = tmpSoccerBet.totalSoccer
             FROM #tmpUserBet u
                  INNER JOIN
             (
                 SELECT custid,
                        COUNT(custid) AS totalSoccer
                 FROM
                 (
                     SELECT b.custid
                     FROM dbo.bettrans b WITH (NOLOCK)
                          INNER JOIN
                     (
                         SELECT matchid,
                                leagueid,
                                'match' AS type
                         FROM dbo.match WITH (NOLOCK)
                         UNION ALL
                         SELECT orid,
                                leagueid,
                                'outright' AS type
                         FROM dbo.outright WITH (NOLOCK)
                     ) m ON b.matchid = m.matchid
                          INNER JOIN league l WITH (NOLOCK) ON m.leagueid = l.leagueid
                          INNER JOIN sports s WITH (NOLOCK) ON l.sporttype = s.sporttype
                     WHERE b.winlostdate = @fromdate
                           AND s.SportType = 1
                           AND b.bettype <> 903
                           AND b.ip = @ip
                           AND m.type = CASE
                                            WHEN b.bettype = 10
                                            THEN 'outright'
                                            ELSE 'match'
                                        END
                           --exclude metric gaming running ticket
                           AND (b.bettype NOT BETWEEN 801 AND 806
                                OR (b.bettype BETWEEN 801 AND 806
                                    AND b.statusID NOT IN(0, 1)))
                     UNION ALL
                     SELECT b.custid
                     FROM bettrans b WITH (NOLOCK)
                     WHERE 1 = CASE
                                   WHEN b.bettype = 9
                                        AND b.matchid = 9
                                   THEN 1
                                   WHEN b.bettype = 29
                                        AND b.matchid = 29
                                   THEN 1
                                   ELSE 0
                               END
                           AND b.winlostdate = @fromdate
                           AND b.ip = @ip
                           AND b.refno IN
                     (
                         SELECT refno
                         FROM dbo.bettransm bm WITH (NOLOCK)
                              INNER JOIN dbo.match m WITH (NOLOCK) ON bm.matchid = m.matchid
                         WHERE m.sporttype = 1
                     )
                     --COUNT MG ticket as soccer
                     UNION ALL
                     SELECT tl.custid
                     FROM dbo.translog tl WITH (NOLOCK)
                     WHERE winlostdate = @fromdate
                           AND tl.gameid BETWEEN 801 AND 899
                           AND ip = @ip
                           AND statusid = 0
                 ) Bet
                 GROUP BY custid
             ) tmpSoccerBet ON tmpSoccerBet.custid = u.custid;
         END;
     IF @fromdate >= @min_date14
        AND @fromdate <= @max_date14
         BEGIN
             INSERT INTO #tmpUserBet
             (custid,
              totalBet,
              is14
             )
                    SELECT custid,
                           COUNT(custid),
                           1
                    FROM dbo.bettrans14 WITH (NOLOCK)
                    WHERE winlostdate = @fromdate
                          AND ip = @ip
                    GROUP BY custid;
             UPDATE #tmpUserBet
               SET
                   soccerBet = tmpSoccerBet.totalSoccer
             FROM #tmpUserBet u
                  INNER JOIN
             (
                 SELECT custid,
                        COUNT(custid) AS totalSoccer
                 FROM
                 (
                     SELECT b.custid
                     FROM dbo.bettrans14 b WITH (NOLOCK)
                          INNER JOIN
                     (
                         SELECT matchid,
                                leagueid,
                                'match' AS type
                         FROM dbo.match14 WITH (NOLOCK)
                         UNION ALL
                         SELECT orid,
                                leagueid,
                                'outright' AS type
                         FROM dbo.outright14 WITH (NOLOCK)
                     ) m ON b.matchid = m.matchid
                          INNER JOIN league l WITH (NOLOCK) ON m.leagueid = l.leagueid
                          INNER JOIN sports s WITH (NOLOCK) ON l.sporttype = s.sporttype
                     WHERE b.winlostdate = @fromdate
                           AND s.SportType = 1
                           AND b.bettype <> 903
                           AND b.ip = @ip
                           AND m.type = CASE
                                            WHEN b.bettype = 10
                                            THEN 'outright'
                                            ELSE 'match'
                                        END
                     UNION ALL
                     SELECT b.custid
                     FROM bettrans14 b WITH (NOLOCK)
                     WHERE 1 = CASE
                                   WHEN b.bettype = 9
                                        AND b.matchid = 9
                                   THEN 1
                                   WHEN b.bettype = 29
                                        AND b.matchid = 29
                                   THEN 1
                                   ELSE 0
                               END
                           AND b.winlostdate = @fromdate
                           AND b.ip = @ip
                           AND b.refno IN
                     (
                         SELECT refno
                         FROM dbo.bettransm14 bm WITH (NOLOCK)
                              INNER JOIN dbo.match14 m WITH (NOLOCK) ON bm.matchid = m.matchid
                         WHERE m.sporttype = 1
                     )
                 ) Bet
                 GROUP BY custid
             ) tmpSoccerBet ON tmpSoccerBet.custid = u.custid
                               AND u.is14 = 1;
         END;
     SELECT c.custid,
            c.username,
            SUM(soccerBet) soccerBet,
            SUM(totalBet) - SUM(soccerBet) otherBet,
            SUM(totalBet) totalBet
     FROM #tmpUserBet u
          INNER JOIN dbo.customer c WITH (NOLOCK) ON u.custid = c.custid
     GROUP BY c.custid,
              c.username
     ORDER BY c.username;
     DROP TABLE #tmpUserBet;
GO
GRANT EXECUTE ON [dbo].[NAP_Winlimit_UserByIPSel] TO [bodbAdminNet];
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Winlimit_UserByIPSel] TO [vnteam];
GO