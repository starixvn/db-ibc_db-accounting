ALTER PROCEDURE [dbo].[Acc_BettransSelRecoverBet_LiveCS]
(
	@transid	BIGINT,
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg VARCHAR(1000) = '' OUTPUT
)
AS
/*
	Created: 20120210@Lukas	
	Task: Select deleted bet need to recover (Live Casino)
	DB: DB053.BODB02

	History:
		- 20121114@Elodie: Only recover today ticket
	Explanation's Param:

*/
BEGIN
	SET NOCOUNT ON
	
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
	
	IF @bettype not in (1101,1102)
	BEGIN
		SET @ErrCode = 2  
		SET @ErrMsg ='This TransID doesn''t belong to live casino.'  
		RETURN
	END	

	DECLARE @today SMALLDATETIME
	SET @today = convert(nvarchar(10), current_timestamp, 120)
	
	SELECT  
		z.refno, 
		z.transid, 
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
		b.playercomm as comm,
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
		z.matchid
    FROM zzzbettrans z WITH(NOLOCK)
		INNER JOIN bettrans b (nolock)ON b.custid = z.custid AND b.matchid = z.matchid and b.transid = z.transid
		INNER JOIN customer ag (nolock) ON b.recommend = ag.custid
		INNER JOIN customer cust (nolock) ON b.custid = cust.custid
		LEFT JOIN custinfo c (nolock) ON c.custid = z.creator
    WHERE b.transid = @transid AND b.matchid>0
			AND z.custid = b.custid AND z.matchid = b.matchid AND z.bettype = b.bettype
			and z.winlostdate = @today
    ORDER BY b.transid

	SELECT bg.refno, bg.odds, bg.stake, bg.status, bg.bettype, bg.betteam
	FROM bettransG bg WITH(NOLOCK)	
		INNER JOIN bettrans b WITH(NOLOCK) ON bg.refno = b.refno
	WHERE b.transid = @transid 
			and b.winlostdate = @today
END

GO
GRANT VIEW DEFINITION ON [Acc_BettransSelRecoverBet_LiveCS] TO vnteam
GO
GRANT EXECUTE ON [Acc_BettransSelRecoverBet_LiveCS] TO BodbAdminNet