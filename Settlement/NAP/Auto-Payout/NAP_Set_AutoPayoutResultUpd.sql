USE bodb02
GO

ALTER PROCEDURE dbo.NAP_Set_AutoPayoutResultUpd @MatchId INT
	, @Action VARCHAR(10)
	, @StatusId TINYINT
AS
/*
	Creator: 20160310@Patrick
	Task: Update status of auto payout result
	DB: DBPRO/bodb02
	Revisions:
	Param's Explanation:
		- @StatusId: 0: New
					 1: Waiting
					 2: Completed
					 3: Failed
*/
BEGIN
	SET NOCOUNT ON

	UPDATE dbo.AutoPayoutResult WITH(ROWLOCK, UPDLOCK)
	SET StatusId = @StatusId 
		, ModifiedDate = GETDATE()
	WHERE MatchId = @MatchId AND CalculationType = CASE @Action WHEN 'CAL-HT' THEN 1
																WHEN 'CAL-FT' THEN 2
													ELSE -1	END --not support

	UPDATE dbo.match WITH(UPDLOCK, ROWLOCK)
	SET IsAutoPayout = 1
	WHERE matchid = @MatchId

END
GO
GRANT EXECUTE ON [dbo].[NAP_Set_AutoPayoutResultUpd] TO [bodbAdminNet] AS [dbo]
GO
