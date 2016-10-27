USE bodb02
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE dbo.NAP_Set_MatchSelInfo_Auto_1s
	@MatchID		INT

AS
/*	Creator: 20160516@Patrick
	Task: Auto Settlement - Select match info
	DB: DBPRO/BODB02
	Original: 
	
	Revisions:

	Param's Explanation:
*/
BEGIN
	SET NOCOUNT ON 

	-- Match Info 
	SELECT	m.LeagueID
			,m.MatchID
			,m.matchcode
			,m.kickofftime
			,playTime = datediff(minute, m.kickofftime, CURRENT_TIMESTAMP) 
			,m.homeid
			,m.awayid
			,m.hthomescore AS HalfTimeHomeScore
			,m.htawayscore AS HalfTimeAwayScore
			,m.finalhomescore
			,m.finalawayscore
	FROM	dbo.Match m WITH (NOLOCK)
	WHERE	MatchID = @MatchID

END
GO
GRANT EXECUTE ON [dbo].[NAP_Set_MatchSelInfo_Auto_1s] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Set_MatchSelInfo_Auto_1s] TO [vnteam] AS [dbo]
GO
