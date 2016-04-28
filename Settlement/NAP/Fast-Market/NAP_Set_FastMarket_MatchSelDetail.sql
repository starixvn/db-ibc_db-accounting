USE bodb02
GO

ALTER PROCEDURE dbo.NAP_Set_FastMarket_MatchSelDetail @MatchId INT
AS
/*
	Created: 20160427@Patrick
	Task: Fast market - Select match detail
	DB: DBTXN.BODB02
	Original:
	
	Revisions:

	Param's Explanation:
		
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @RowIndex TINYINT, @bettype SMALLINT, @ResultHT VARCHAR(50), @ResultFT VARCHAR(50)
		, @ResultStatusHT VARCHAR(50), @ResultStatusFT VARCHAR(50)

	DECLARE @BetTypeIds TABLE (RowIndex TINYINT IDENTITY(1,1), Bettype SMALLINT)
	INSERT INTO @BetTypeIds(bettype)
	VALUES(221), (222), (223), (224)

	DECLARE @ResultDetail TABLE(BetType SMALLINT, Position TINYINT, BetStatus TINYINT, BetOption TINYINT, ResultStatus TINYINT)

	SELECT @RowIndex = 1  
	WHILE EXISTS (SELECT TOP 1 1 FROM @BetTypeIds WHERE RowIndex = @RowIndex)
	BEGIN
		SELECT @bettype = bettype FROM @BetTypeIds WHERE RowIndex = @RowIndex
		SET @RowIndex = @RowIndex + 1

		--for result
		SELECT @ResultHT = HomeValue, @ResultFT = AwayValue
		FROM DBPRO.bodb02.dbo.ResultDetail WITH (NOLOCK)
		WHERE MatchId = @MatchId AND ResourceID = (@bettype * 100) + 1

		SELECT @ResultStatusHT = HomeValue, @ResultStatusFT = AwayValue
		FROM DBPRO.bodb02.dbo.ResultDetail WITH (NOLOCK)
		WHERE MatchId = @MatchId AND ResourceID = (@bettype * 100)

		--for HT
		IF ISNULL(@ResultHT, '') = ''
		BEGIN
			SET @ResultHT = REPLICATE(CHAR('0'), 50) --set default value
		END

		IF ISNULL(@ResultStatusHT, '') = ''
		BEGIN
			SET @ResultStatusHT = REPLICATE('0', 50) --set default value
		END
		
		INSERT INTO @ResultDetail(BetType, Position, BetOption, ResultStatus, BetStatus)
		SELECT @bettype, f.pos, f.bitmap AS BetOption, ff.ResultStatus, 0 AS BetStatus
		FROM dbo.f_GetBytes(@ResultHT) f
			INNER JOIN dbo.f_GetChars(@ResultStatusHT) ff ON f.pos = ff.pos
		WHERE f.pos < 45

		--for FT
		IF ISNULL(@ResultFT, '') = ''
		BEGIN
			SET @ResultFT = REPLICATE(CHAR('0'), 50)
		END

		IF ISNULL(@ResultStatusFT, '') = ''
		BEGIN
			SET @ResultStatusFT = REPLICATE('0', 50)
		END
		
		INSERT INTO @ResultDetail(BetType, Position, BetOption, ResultStatus, BetStatus)
		SELECT @bettype, f.pos + 45, f.bitmap AS BetOption, ff.ResultStatus, 0 AS BetStatus
		FROM dbo.f_GetBytes(@ResultFT) f
			INNER JOIN dbo.f_GetChars(@ResultStatusFT) ff ON f.pos = ff.pos
		WHERE f.pos < 45
	END

	DELETE FROM @ResultDetail WHERE BetType IN (222,224) AND Position > 85
	
	;WITH BetStatus AS (
		SELECT b.bettype
			, hdp1 AS Position
		FROM dbo.bettrans b WITH(NOLOCK)
		WHERE matchid = @MatchId
			AND bettype IN (SELECT bettype FROM @BetTypeIds)
			AND StatusId NOT IN (101, 102, 103)
		GROUP BY bettype, hdp1
	)

	UPDATE rs
	SET BetStatus = 1
	FROM @ResultDetail rs
	INNER JOIN BetStatus b ON rs.bettype = b.bettype AND rs.Position = b.Position

	SELECT BetType
		, Position
		, BetOption AS Result
		, ResultStatus
		, BetStatus AS TicketStatus
	FROM @ResultDetail

END


GO

GRANT EXECUTE ON [NAP_Set_FastMarket_MatchSelDetail] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [NAP_Set_FastMarket_MatchSelDetail] TO [vnteam] AS [dbo]
GO