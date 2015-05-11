ALTER PROCEDURE [dbo].[NAP_Set_MatchGetResultDetail]
	@MatchID	INT 
AS
/*
	Created by: Jamie  
	Date: 2014-1114
	Task: Match results - Get info match in detail   
	DB: DBPRO/BODB02  

	Revisions:  	
		- 20150406@Jamie: Settlement Betradar phase 2 [Redmine: #27212]
*/
BEGIN
	SET NOCOUNT ON

	SELECT	 m.MatchID
			,m.matchcode
			,m.sporttype
			,m.leagueid
			,m.homeid
			,m.awayid
			,m.kickofftime
			,m.hthomescore
			,m.htawayscore
			,m.finalhomescore
			,m.finalawayscore
			,m.eventstatus
			,CASE 
					WHEN m.betstatus LIKE 'Refund FT%' THEN 'Refund FT'
					WHEN m.betstatus LIKE 'Refund HT%' THEN 'Refund HT'
					WHEN m.betstatus LIKE 'Refund%' THEN 'Refund'
					ELSE m.eventstatus
					END AS eventstatus
			,m.betstatus
			,m.GoalRecord
			,ISNULL(mr.IsHTCal, 0) AS IsHTCal
			,ISNULL(mr.calculate, 0) AS calculate
			,ISNULL(mr.isPending, 0) AS isPending
	FROM	dbo.Match m WITH (NOLOCK)
			LEFT JOIN dbo.match_remark mr WITH (NOLOCK) ON m.MatchID = mr.MatchID 
	WHERE	m.MatchID = @MatchID 

	SELECT	 MatchId
			,ResourceID 
			,HomeValue 
			,AwayValue 
			,OtherInfo
			,SettlementStatusID
	FROM	dbo.[ResultDetail] WITH (NOLOCK) 
	WHERE	MatchID = @MatchID 
			AND ResultStatusID > 0 
	ORDER BY ResourceID 
END
GO
GRANT EXECUTE ON [NAP_Set_MatchGetResultDetail] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [NAP_Set_MatchGetResultDetail] TO [vnteam] AS [dbo]
GO
