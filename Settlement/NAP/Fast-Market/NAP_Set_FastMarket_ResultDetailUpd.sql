USE bodb02
GO

ALTER PROCEDURE dbo.NAP_Set_FastMarket_ResultDetailUpd @MatchId INT
	, @BetType SMALLINT
	, @Position TINYINT
	, @BetOption TINYINT
	, @ResultStatus TINYINT
	, @Action VARCHAR = 'CAL'

	, @ErrCode INT OUTPUT
	, @ErrMsg VARCHAR(200) OUTPUT
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
	IF @Action IN ('CAL', 'UNDO', 'REFUND')
	BEGIN
		IF @Position <= 44
		BEGIN
			--for result status - HT
			UPDATE bodb02.dbo.ResultDetail WITH(ROWLOCK, UPDLOCK)
			SET HomeValue = dbo.f_SetChar(CASE WHEN DATALENGTH(HomeValue) = 50 THEN HomeValue
												WHEN HomeValue IS NULL THEN REPLICATE('0', 50)
												ELSE HomeValue + REPLICATE('0', 50 - DATALENGTH(HomeValue)) END 
											, @Position
											, ISNULL(@ResultStatus, 0)
										)
			WHERE MatchId = @MatchId AND ResourceId = @bettype * 100

			--for betoption - HT
			UPDATE bodb02.dbo.ResultDetail WITH(ROWLOCK, UPDLOCK)
			SET HomeValue = dbo.f_SetByte(CASE WHEN DATALENGTH(HomeValue) = 50 THEN HomeValue
												WHEN HomeValue IS NULL THEN REPLICATE(CHAR('0'), 50)
												ELSE HomeValue + REPLICATE(CHAR('0'), 50 - DATALENGTH(HomeValue)) END
											, @Position
											, ISNULL(@BetOption, CHAR('0'))
										)
			WHERE MatchId = @MatchId AND ResourceId = (@bettype * 100) + 1
		END
		ELSE
		BEGIN
			--for result status - FT
			UPDATE bodb02.dbo.ResultDetail WITH(ROWLOCK, UPDLOCK)
			SET AwayValue = dbo.f_SetChar(CASE WHEN DATALENGTH(AwayValue) = 50 THEN AwayValue
												WHEN AwayValue IS NULL THEN REPLICATE('0', 50)
												ELSE AwayValue + REPLICATE('0', 50 - DATALENGTH(AwayValue)) END 
											, @Position
											, ISNULL(@ResultStatus, 0)
										)
			WHERE MatchId = @MatchId AND ResourceId = @bettype * 100

			--for betoption - FT
			UPDATE bodb02.dbo.ResultDetail WITH(ROWLOCK, UPDLOCK)
			SET AwayValue = dbo.f_SetByte(CASE WHEN DATALENGTH(AwayValue) = 50 THEN AwayValue
												WHEN AwayValue IS NULL THEN REPLICATE(CHAR('0'), 50)
												ELSE AwayValue + REPLICATE(CHAR('0'), 50 - DATALENGTH(AwayValue)) END
											, @Position
											, ISNULL(@BetOption, CHAR('0'))
										)
			WHERE MatchId = @MatchId AND ResourceId = (@bettype * 100) + 1
		END
	END
END

GO

GRANT EXECUTE ON [NAP_Set_FastMarket_ResultDetailUpd] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [NAP_Set_FastMarket_ResultDetailUpd] TO [vnteam] AS [dbo]
GO