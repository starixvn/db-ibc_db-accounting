ALTER PROCEDURE [dbo].Acc_BettransSelSpecialDel_MixParlay  	 
	@Refno bigint,	
	@Transid bigint,
	@CurrencyID tinyint,
	@Language NVARCHAR(2) = 'E'
AS  
/*  
 Created by: Elly  
 Date:20110720
 Original:
 Task: get tickets of mix parlay (for early kickoff) by Refno
 DB: DB052.BODB02  
  
 History:  
	- 20110825@Elly: get more information (from match)
	- 20111007@Johnson: Get statusid into betlist
	- 20120703@Sophia: Remove function f_GetChoice
	
 Explanation's Param:  
	
  
*/
BEGIN
	SET NOCOUNT ON 
	DECLARE @CurrencyName nvarchar(50)
	
	SELECT @CurrencyName=currency 
	FROM dbo.exchange WITH(NOLOCK) 
	WHERE exchangeid=@CurrencyID
			
	SELECT
		b.transid,		
		b.bettype,
		m.homeid,
		m.awayid,
		b.hdp1, 
		b.hdp2, 
		b.odds,
		b.betteam,
		b.livehomescore, 
		b.liveawayscore, 
		b.liveindicator, 
		m.leagueid,
		m.sporttype,
		m.isNeutral as IsNeutral,
		m.matchid,
		m.matchcode
		,b.stake AS StakePositionTaking
		,@CurrencyName AS currency
		,CASE WHEN transid=@Transid THEN 1 ELSE 0 END AS IsDeleted
		,b.statusid
	FROM dbo.BettransM AS b with (nolock)		
		INNER JOIN match AS m with (nolock) ON b.matchid=m.matchid
			AND refno=@refno
	ORDER BY b.transid
	
	SET NOCOUNT OFF
END
/*-----EXAMPLE

select * from match where matchcode='5080'
exec Acc_BettransSelSpecialDel_MixParlay @Refno=100123019066,@transid=255687196,@CurrencyID=5

exec Acc_BettransSelSpecialDel_MixParlay @Refno=100119986558,@transid=243724212,@CurrencyID=1

*/
GO
GRANT EXECUTE ON [dbo].Acc_BettransSelSpecialDel_MixParlay TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].Acc_BettransSelSpecialDel_MixParlay TO [vnteam]
GO 