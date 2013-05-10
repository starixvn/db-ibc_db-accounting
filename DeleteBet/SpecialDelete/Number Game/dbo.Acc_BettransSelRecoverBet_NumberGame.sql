ALTER PROCEDURE [dbo].[Acc_BettransSelRecoverBet_NumberGame]
    @transid bigint,
    @ErrCode INT = 0 OUTPUT,
	@ErrMsg VARCHAR(1000) = '' OUTPUT
AS
/*
	Created: Elodie
	Task: Select deleted bet need to recover (Number Game)
	DB: DB053.bodb02
	Revisions: 	
	
	Param's Explanation:

*/

SET NOCOUNT ON
BEGIN
	--- Check transid
	DECLARE @bettype smallint
	SET @bettype = 0
	
	select @bettype = bettype from bettrans with (NOLOCK) where transid = @transid
	
	IF ISNULL(@bettype,0) = 0 		
	BEGIN 
		SET @ErrCode = 1
		SET @ErrMsg ='Invalid TransID.'   
		RETURN
	END
	
	IF @bettype not BETWEEN 81 AND 120
	BEGIN
		SET @ErrCode = 2  
		SET @ErrMsg ='This TransID doesn''t belong to number game.'  
		RETURN
	END	
	
	DECLARE @today SMALLDATETIME
	SET @today = convert(nvarchar(10), current_timestamp, 120)
	
    SELECT  DISTINCT z.transid AS refno, 
			z.transid, 
			z.matchid,
			z.custid, 
			b.username, 
			cust.username2, 
			b.transdate, 
			b.hdp1, 
			b.hdp2, 
			b.odds, 
			b.actual_stake,
			b.stake, 			
			z.winlost - b.actual_stake as winlost,			
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
    WHERE z.transid = @transid AND b.matchid > 0 
			and z.winlostdate = @today
    ORDER BY z.transid
END

GO
GRANT EXECUTE ON [dbo].[Acc_BettransSelRecoverBet_NumberGame] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_BettransSelRecoverBet_NumberGame] TO [vnteam]
GO
 