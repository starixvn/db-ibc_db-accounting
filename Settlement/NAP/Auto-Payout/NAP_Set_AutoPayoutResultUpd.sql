USE bodb02
GO

ALTER PROCEDURE dbo.NAP_Set_AutoPayoutResultUpd @MatchId INT
	, @TypeId TINYINT
	, @StatusId TINYINT
	, @IsIncludedUpdateMatch BIT = 0
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
	WHERE MatchId = @MatchId 
		AND CalculationType = @TypeId
		AND StatusId <> @StatusId

	IF @IsIncludedUpdateMatch = 1
		AND EXISTS (SELECT TOP 1 1 FROM dbo.match WITH(NOLOCK) WHERE matchid = @MatchId AND ISNULL(IsAutoPayout, 0) = 0)
	BEGIN
		UPDATE dbo.match WITH(UPDLOCK, ROWLOCK)
		SET IsAutoPayout = 1
		WHERE matchid = @MatchId
	END
END
GO
GRANT EXECUTE ON [dbo].[NAP_Set_AutoPayoutResultUpd] TO [bodbAdminNet] AS [dbo]
GO
