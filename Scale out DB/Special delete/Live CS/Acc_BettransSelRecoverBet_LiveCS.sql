create PROCEDURE [dbo].[Acc_BettransSelRecoverBet_LiveCS_xtest]
(
	@transid	BIGINT
)
AS
/*
	Created: 20120210@Lukas	
	Task: Select deleted bet need to recover (Live Casino)
	DB: DB053.BODB02

	History:
		
	Explanation's Param:

*/
BEGIN
	SET NOCOUNT ON

	SELECT  z.refno AS refno, 
		z.transid, 
		z.custid, 
		b.username, 
		cust.username2, 
		b.transdate, 
		b.hdp1, 
		b.hdp2, 
		b.odds, 
		b.actual_stake as stake,
		b.stake AS StakePositiontaking, 
		b.spositiontaking,
		b.mpositiontaking,
		b.apositiontaking,
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
		b.betfrom,
		z.matchid,
		b.transid2
    FROM zzzbettrans z WITH(NOLOCK)
		INNER JOIN bettrans b (nolock)ON b.custid = z.custid AND b.matchid = z.matchid and b.transid = z.transid
		INNER JOIN customer ag (nolock) ON b.recommend = ag.custid
		INNER JOIN customer cust (nolock) ON b.custid = cust.custid
		LEFT JOIN custinfo c (nolock) ON c.custid = z.creator
    WHERE b.transid = @transid AND b.matchid>0
			AND z.custid = b.custid AND z.matchid = b.matchid AND z.bettype = b.bettype
    ORDER BY b.transid


	SELECT bg.refno, bg.odds, bg.stake, bg.status, bg.bettype, bg.betteam
	FROM bettransG bg WITH(NOLOCK)	
		INNER JOIN bettrans b WITH(NOLOCK) ON bg.refno = b.refno
	WHERE b.transid = @transid
END

GO
GRANT EXECUTE ON [Acc_BettransSelRecoverBet_LiveCS_xtest] TO BodbAdminNet