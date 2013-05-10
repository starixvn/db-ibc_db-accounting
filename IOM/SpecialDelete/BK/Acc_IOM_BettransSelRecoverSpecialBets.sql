ALTER PROCEDURE [dbo].[Acc_IOM_BettransSelRecoverSpecialBets]
    @transid bigint
AS
/*
Created: Elodie
Date: 20120705
DB: DB053.bodb02
Origional: [Acc_BettransSelRecoverSpecialBets]
Revisions: 

Param's Explanation:

*/
SET NOCOUNT ON
BEGIN
    SELECT  DISTINCT z.transid AS refno, 
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
    b.livehomescore, 
    b.liveawayscore, 
    b.bettype, 
    c.username AS creator,
    b.liveindicator, 
    b.betteam, 
    b.OddsType, 
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
GRANT EXECUTE ON [dbo].[Acc_IOM_BettransSelRecoverSpecialBets] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_IOM_BettransSelRecoverSpecialBets] TO [vnteam]

 