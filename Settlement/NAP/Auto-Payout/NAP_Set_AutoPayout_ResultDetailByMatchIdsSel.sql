USE [bodb02]
GO

ALTER PROCEDURE dbo.NAP_Set_AutoPayout_ResultDetailByMatchIdsSel @MatchIds VARCHAR(1204)
AS
/*
	Creator: 20160311@Patrick
	Task: Get result score for AutoPayout.
	DB: DBPRO/bodb02
	Revisions:
*/
BEGIN
	SET NOCOUNT ON

	SELECT MatchId, SourceId, TypeId, HomeValue, AwayValue
	FROM dbo.ProviderResultDetail WITH (NOLOCK)
	WHERE  MatchId IN (SELECT val FROM dbo.strSplit(@MatchIds, ','))
END
GO
GRANT EXECUTE ON [dbo].[NAP_Set_AutoPayout_ResultDetailByMatchIdsSel] TO [bodbAdminNet] AS [dbo]
GO