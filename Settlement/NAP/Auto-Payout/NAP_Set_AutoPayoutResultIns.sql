USE [bodb02]
GO

ALTER PROCEDURE dbo.NAP_Set_AutoPayoutResultIns 
	@MatchId INT
	, @SourceId TINYINT
	, @TypeId TINYINT
	, @HomeValue VARCHAR(50)
	, @AwayValue VARCHAR(50)
	, @StatusId TINYINT
	, @ErrCode INT = 0 OUTPUT
	, @ErrMsg NVARCHAR(200) = '' OUTPUT
	
AS
/*
	Creator: 20160315@Patrick
	Task: Auto payout - Insert result
	DB: DBPRO/bodb02
	Revisions:
*/
BEGIN
	SET NOCOUNT ON

	IF EXISTS (SELECT TOP 1 1 
				FROM dbo.AutoPayoutResult WITH(NOLOCK) 
				WHERE MatchId = @MatchId 
					AND CalculationType = @TypeId
					AND 1 = CASE 
								WHEN @TypeId IN (1, 2) THEN 1
								WHEN @TypeId IN (101, 102) THEN 
									CASE WHEN HomeValue = @HomeValue AND AwayValue = @AwayValue THEN 1 ELSE 0 END
								ELSE 0 
							END
	)
	BEGIN
		SELECT @ErrCode = 1001021, @ErrMsg = 'Failed to insert result detail (duplicate data).'
		RETURN
	END

	INSERT INTO dbo.AutoPayoutResult (MatchId, SourceId, CalculationType, HomeValue, AwayValue, StatusId, TryCount, CreatedDate, ModifiedDate)
	VALUES(@MatchId, @SourceId, @TypeId, @HomeValue, @AwayValue, @StatusId, 0, GETDATE(), GETDATE())

	IF @@ERROR <> 0
	BEGIN
		SELECT @ErrCode = 1001022, @ErrMsg = 'Failed to insert result detail.'
		RETURN
	END
		
END
GO
GRANT EXECUTE ON [dbo].[NAP_Set_AutoPayoutResultIns] TO [bodbAdminNet] AS [dbo]
GO
