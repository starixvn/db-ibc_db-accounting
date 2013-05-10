ALTER PROCEDURE [dbo].[Acc_BettransSelRecoverSpecialBets]
    @transid bigint,
    @Type SMALLINT = 0,
    @ErrCode INT = 0 OUTPUT,
	@ErrMsg VARCHAR(1000) = '' OUTPUT
AS
/*
Created: Robert
DB: DB053.bodb02
Revisions: 
	- 20110408@Amy: Change function to get Odds value and odds type
	- 20120629@Sophia: Remove function f_GetOddsByBettype, f_ShowOddsByBettype, f_GetChoice for odds, Oddstype, betteam
	- 20120821@Elodie: Check sport type of input transid to list out appropriate ticket
					   Change DB053 server instead of DB052 server					   
	- 20121115@Elodie: Move recover function of Number Game to new SP
	
Param's Explanation:
	- @Type: sports type
		0: Sportsbook
		1: Virtual sports
*/

SET NOCOUNT ON
BEGIN
	--- Check transid
	DECLARE @bettype smallint
	SET @bettype = 0
	
	select @bettype = bettype from bettrans with (NOLOCK) where transid = @transid
	
	IF ISNULL(@bettype,0) = 0 
		OR NOT (					
					@bettype < 31  or @bettype between 121 AND 999 --sportbook
					OR @bettype BETWEEN 1201 AND 1299 --virtual sports
			    )
	BEGIN 
		SET @ErrCode = 1
		SET @ErrMsg ='Invalid TransID.'   
		RETURN
	END
	
	IF NOT (@bettype < 31  or @bettype between 121 AND 999) AND @Type = 0  
	BEGIN
		SET @ErrCode = 2  
		SET @ErrMsg ='This TransID doesn''t belong to sportsbook.'  
		RETURN
	END	
	
	IF @bettype not between 1201 and 1299 AND @Type = 1
	BEGIN 
		SET @ErrCode = 3
		SET @ErrMsg ='This TransID doesn''t belong to virtual sports.' 
		RETURN
	END 
	
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
GRANT EXECUTE ON [dbo].[Acc_BettransSelRecoverSpecialBets] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_BettransSelRecoverSpecialBets] TO [vnteam]
GO
