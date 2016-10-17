USE [bodb02]
GO

ALTER PROCEDURE dbo.NAP_Settlement_InstantCalculation_PushScore
	@MatchId 		INT
	, @HomeScore 	TINYINT
	, @AwayScore 	TINYINT
	, @IsHTScore 	BIT
AS
/*
	Creator: 20160930@Bobby
	Task: Update or insert new score result for Instant Calculation.
	DB: DBPRO/bodb02
	Revisions:
		- 20160930@Bobby: #65001 - Integrate with admin site to gather score value once being confirmed.
		
	Param's Explanation:
		- @IsHTScore: [0:FT, 1:HT]

*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @TypeId 	TINYINT
		, @SourceId		TINYINT
		
	SELECT @TypeId 		=  CASE WHEN @IsHTScore = 1 THEN 101 
								WHEN @IsHTScore = 0 THEN 102
								ELSE 0 
							END
		, @SourceId		= 100 -- internal source type
	
	IF ( 
		EXISTS (
			SELECT TOP 1 1
			FROM dbo.[match] m WITH (NOLOCK)
			WHERE matchid = @MatchId
		)
		AND @TypeId IN (101, 102)
		AND (ISNULL(@HomeScore, 0) + ISNULL(@AwayScore, 0)) > 0
	)
	BEGIN
		INSERT INTO dbo.ProviderResultDetail (
			MatchId
			, SourceId
			, TypeId
			, HomeValue
			, AwayValue
			, CreatedDate
		)
		VALUES ( 
			@MatchId
			, @SourceId
			, @TypeId
			, @HomeScore
			, @AwayScore
			, GETDATE()
		)
	END
	RETURN	
END
GO

