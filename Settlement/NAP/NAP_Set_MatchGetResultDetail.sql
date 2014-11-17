ALTER PROCEDURE [dbo].[NAP_Set_MatchGetResultDetail]
	@MatchID	INT 
AS
/*
	Created by: Jamie  
	Date: 2014-1114
	Task: Match results - Get info match in detail   
	DB: DBPRO/BODB02  

	Revisions:  	
*/
BEGIN
	SET NOCOUNT ON

	SELECT	MatchID
			,homeid
			,awayid
			,kickofftime
			,finalhomescore
			,finalawayscore
			,eventstatus
	FROM	dbo.Match WITH (NOLOCK)
	WHERE	MatchID = @MatchID 

	SELECT	 MatchId
			,ResourceID 
			,HomeValue 
			,AwayValue 
			,SettlementStatusID
	FROM	dbo.[ResultDetail] WITH (NOLOCK) 
	WHERE	MatchID = @MatchID 
	ORDER BY ResourceID 
END
GO
GRANT EXECUTE ON [NAP_Set_MatchGetResultDetail] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [NAP_Set_MatchGetResultDetail] TO [vnteam] AS [dbo]
GO
