USE bodb02
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE dbo.NAP_Set_FastMarket_ResultDetailUpd @MatchId INT
	,@BetType			SMALLINT
	,@Position			TINYINT
	,@BetOption			TINYINT
	,@ResultStatus		TINYINT
	,@Action			VARCHAR(20) = 'CAL'

	,@AdminId			INT = 0
AS
/*
	Created: 20160427@Patrick
	Task: Fast market - Select match detail
	DB: DBPRO.BODB02
	Original:
	
	Revisions:

	Param's Explanation:
		
*/
BEGIN
	
	SET NOCOUNT ON
	
	DECLARE @ResourceId_BetOption		VARCHAR(50)
			,@ResourceId_ResultStatus	VARCHAR(50)
			,@ResourceId				INT
	
	SELECT	@ResourceId = @bettype * 100
			,@ResourceId_BetOption = CAST((@ResourceId) + 1 AS VARCHAR)
			,@ResourceId_ResultStatus = CAST(@ResourceId AS VARCHAR)

	--betoptions
	IF NOT EXISTS (SELECT	TOP 1 1 
					FROM	dbo.ResultDetail WITH(NOLOCK) 
					WHERE	MatchId = @MatchId 
							AND ResourceId = @ResourceId_BetOption
						)
	BEGIN
		INSERT INTO dbo.ResultDetail(MatchId, ResourceId, HomeValue, AwayValue, CreateBy, CreateDate, LastModifyBy, LastModifyDate)
		VALUES(@MatchId, @ResourceId_BetOption, REPLICATE(CHAR('0'), 50), REPLICATE(CHAR('0'), 50), @AdminId, GETDATE(), @AdminId, GETDATE())
	END

	--result status
	IF NOT EXISTS (SELECT	TOP 1 1 
					FROM	dbo.ResultDetail WITH(NOLOCK) 
					WHERE	MatchId = @MatchId 
							AND ResourceId = @ResourceId_ResultStatus
						)
	BEGIN
		INSERT INTO bodb02.dbo.ResultDetail(MatchId, ResourceId, HomeValue, AwayValue, CreateBy, CreateDate, LastModifyBy, LastModifyDate)
		VALUES(@MatchId, @ResourceId_ResultStatus, REPLICATE('0', 50), REPLICATE('0', 50), @AdminId, GETDATE(), @AdminId, GETDATE())
	END

	IF @Position <= 44
	BEGIN
		--for result status - HT
		UPDATE	dbo.ResultDetail WITH(ROWLOCK, UPDLOCK)
		SET		HomeValue = dbo.f_SetChar(HomeValue, @Position, ISNULL(@ResultStatus, 0))
				,LastModifyBy = @AdminId
				,LastModifyDate = GETDATE()
		WHERE	MatchId = @MatchId 
				AND ResourceId = @ResourceId_ResultStatus

		IF @Action IN ('CAL', 'UNDO')
		BEGIN
			--for betoption - HT
			UPDATE	dbo.ResultDetail WITH(ROWLOCK, UPDLOCK)
			SET		HomeValue = dbo.f_SetByte(HomeValue, @Position, ISNULL(@BetOption, CHAR('0')))
					,LastModifyBy = @AdminId
					,LastModifyDate = GETDATE()
			WHERE	MatchId = @MatchId 
					AND ResourceId = @ResourceId_BetOption
		END
	END
	ELSE
	BEGIN
		--for result status - FT
		UPDATE	dbo.ResultDetail WITH(ROWLOCK, UPDLOCK)
		SET		AwayValue = dbo.f_SetChar(AwayValue, @Position, ISNULL(@ResultStatus, 0))
				,LastModifyBy = @AdminId
				,LastModifyDate = GETDATE()
		WHERE	MatchId = @MatchId 
				AND ResourceId = @ResourceId_ResultStatus

		IF @Action IN ('CAL', 'UNDO')
		BEGIN
			--for betoption - FT
			UPDATE	dbo.ResultDetail WITH(ROWLOCK, UPDLOCK)
			SET		AwayValue = dbo.f_SetByte(AwayValue, @Position, ISNULL(@BetOption, CHAR('0')))
					,LastModifyBy = @AdminId
					,LastModifyDate = GETDATE()
			WHERE	MatchId = @MatchId 
					AND ResourceId = @ResourceId_BetOption
		END
	END
END

GO

GRANT EXECUTE ON [NAP_Set_FastMarket_ResultDetailUpd] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [NAP_Set_FastMarket_ResultDetailUpd] TO [vnteam] AS [dbo]
GO