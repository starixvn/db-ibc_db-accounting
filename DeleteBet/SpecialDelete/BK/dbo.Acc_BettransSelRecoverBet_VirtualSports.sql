CREATE PROCEDURE [dbo].[Acc_BettransSelRecoverBet_VirtualSports]
    @transid bigint
AS
/*
Created: 20120815@Elodie
Original: Acc_BettransSelRecoverBet
DB: DB053.bodb02
Task: select bets of Virtual Sports to recover bet
Revisions: 
	
Param's Explanation:

*/

SET NOCOUNT ON
BEGIN

    SELECT DISTINCT z.transid AS refno, 
    z.transid, 
    z.custid, 
    b.username, 
    cust.username2, 
    b.transdate, 
    b.hdp1, 
    b.hdp2, 
    b.odds, 
    b.stake AS StakePositiontaking, 
    z.STATUS, 
    b.bettype, 
    c.username AS creator,
    b.betteam, 
	b.currency, 
	ag.site, 
	b.betfrom
    FROM zzzbettrans (nolock) z
    INNER JOIN bettrans b (nolock)ON b.custid = z.custid AND b.matchid = z.matchid and b.transid = z.transid
    INNER JOIN customer ag (nolock) ON b.recommend = ag.custid
    INNER JOIN customer cust (nolock) ON b.custid = cust.custid
    LEFT JOIN custinfo c (nolock) ON c.custid = z.creator
    WHERE z.transid = @transid AND b.matchid>0
    ORDER BY z.transid
END

GO
GRANT EXECUTE ON [dbo].[Acc_BettransSelRecoverBet_VirtualSports] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_BettransSelRecoverBet_VirtualSports] TO [vnteam]
GO
 