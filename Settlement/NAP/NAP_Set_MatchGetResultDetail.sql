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

	SELECT	MatchID
			,matchcode
			,sporttype
			,leagueid
			,homeid
			,awayid
			,kickofftime
			,hthomescore
			,htawayscore
			,finalhomescore
			,finalawayscore
			,eventstatus
			,betstatus
			,GoalRecord
	FROM	dbo.Match WITH (NOLOCK)
	WHERE	MatchID = @MatchID 

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
