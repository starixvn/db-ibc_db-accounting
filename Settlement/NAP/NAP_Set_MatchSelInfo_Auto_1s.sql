USE bodb02
GO

ALTER PROCEDURE dbo.NAP_Set_MatchSelInfo_Auto_1s
	@MatchID		INT

AS
/*	Creator: 20160516@Patrick
	Task: Auto Settlement - Select match info
	DB: DBTXN/BODB02
	Original: 
	
	Revisions:

	Param's Explanation:
*/
BEGIN
	SET NOCOUNT ON 

	DECLARE	@IsSettleAbandonedMatchIBC	BIT = 0 

	IF EXISTS (SELECT 1
				FROM dbo.bettrans WITH (NOLOCK)
				WHERE bettype = 216 
					AND matchid = @matchid AND statusID NOT IN (101, 102, 103) 
					AND ruben = 0 
			)
	BEGIN
		SELECT @IsSettleAbandonedMatchIBC = 1
	END

	-- Match Info 
	SELECT	m.LeagueID
			, m.MatchID
			, m.matchcode
			, m.kickofftime
			, playTime = datediff(minute, m.kickofftime, CURRENT_TIMESTAMP) 
			, m.homeid
			, m.awayid
			, m.hthomescore AS HalfTimeHomeScore
			, m.htawayscore AS HalfTimeAwayScore
			, m.finalhomescore
			, m.finalawayscore
			, IsSettleAbandonedMatchIBC = @IsSettleAbandonedMatchIBC 
	FROM DBPRO.bodb02.dbo.Match m WITH (NOLOCK)
	WHERE MatchID = @MatchID

END
GO
GRANT EXECUTE ON [dbo].[NAP_Set_MatchSelInfo_Auto_1s] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Set_MatchSelInfo_Auto_1s] TO [vnteam] AS [dbo]
GO
