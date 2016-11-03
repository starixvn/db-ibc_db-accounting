USE bodb02
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE dbo.NAP_Set_FastMarket_ResultDetailUpd @MatchId INT
	,@Results		VARCHAR(MAX)
	,@Action		VARCHAR(20) = 'CAL'
	,@IsAuto		BIT = 0
	,@AdminId		INT = 0
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
	
	DECLARE @xmlData XML
			,@ResultStatus TINYINT
			
	SET @xmlData = CONVERT(XML, @Results)
	SET @ResultStatus = CASE 
							WHEN @Action = 'CAL' AND @IsAuto = 0 THEN 5
							WHEN @Action = 'CAL' AND @IsAuto = 1 THEN 4
							WHEN @Action = 'REFUND' THEN 6
							WHEN @Action = 'UNDO' THEN 2
							ELSE 0
						END	
	
	DECLARE @tblResults TABLE (
		ResourceId				VARCHAR(20) -- 22X00
		,ResourceId_BetOption	VARCHAR(20) -- 22X01
		,position				TINYINT
		,betOption				TINYINT
	)
	
	;WITH TmpData AS (
		SELECT T.C.value('../@Id', 'SMALLINT') AS Bettype
			, T.C.value('./@p', 'TINYINT') AS Position
			, T.C.value('./@r', 'TINYINT') AS BetOption
		FROM @xmlData.nodes('/r/b/r') AS T(C)
	)
	INSERT INTO @tblResults (ResourceId, ResourceId_BetOption, position, betOption)
	SELECT	CAST(bettype * 100 AS VARCHAR(20)) ResourceId -- 22X00
			,CAST(bettype * 100 + 1 AS VARCHAR(20)) ResourceId -- 22X01
			,Position
			,betOption
	FROM	TmpData
		
	-- result status
	INSERT INTO dbo.ResultDetail (MatchId, ResourceId, HomeValue, AwayValue, CreateBy, CreateDate, LastModifyBy, LastModifyDate)
	SELECT	@matchId, t.ResourceId, REPLICATE('0', 50), REPLICATE('0', 50), @AdminId, GETDATE(), @AdminId, GETDATE()
	FROM	@tblResults t
	WHERE	NOT EXISTS (SELECT TOP 1 1 FROM dbo.ResultDetail WITH(NOLOCK) WHERE MatchId = @matchid AND t.ResourceId = ResourceId)
	GROUP BY t.ResourceId
	
	-- betoption
	INSERT INTO dbo.ResultDetail (MatchId, ResourceId, HomeValue, AwayValue, CreateBy, CreateDate, LastModifyBy, LastModifyDate)
	SELECT	@matchId, t.ResourceId_BetOption, REPLICATE(CHAR('0'), 50), REPLICATE(CHAR('0'), 50), @AdminId, GETDATE(), @AdminId, GETDATE()
	FROM	@tblResults t
	WHERE	NOT EXISTS (SELECT TOP 1 1 FROM dbo.ResultDetail WITH(NOLOCK) WHERE MatchId = @matchid AND t.ResourceId_BetOption = ResourceId)
	GROUP BY t.ResourceId_BetOption
	
	UPDATE	r
		SET	HomeValue = CASE 
							WHEN t.Position <=44 THEN (SELECT TOP 1 data FROM dbo.f_Set_SetChar(r.HomeValue, t.Position, @ResultStatus)) 
							ELSE HomeValue 
						END
			,AwayValue =CASE 
							WHEN t.Position >44 THEN (SELECT TOP 1 data FROM dbo.f_Set_SetChar(r.AwayValue, t.Position - 45, @ResultStatus)) 
							ELSE AwayValue 
						END
			,LastModifyBy = @AdminId
			,LastModifyDate = GETDATE()
	FROM	dbo.ResultDetail r WITH(ROWLOCK, UPDLOCK)
		INNER JOIN @tblResults t
			ON	r.MatchId = @matchid
				AND r.ResourceId = t.ResourceId
				
	IF @Action IN ('CAL', 'UNDO')
	BEGIN
		UPDATE	r
			SET	HomeValue = CASE
								WHEN t.Position <=44 THEN (SELECT TOP 1 data FROM dbo.f_Set_SetByte(r.HomeValue, t.Position, t.betOption))
								ELSE HomeValue
							END
				,AwayValue = CASE
								WHEN t.Position >44 THEN (SELECT TOP 1 data FROM dbo.f_Set_SetByte(r.AwayValue, t.Position - 45, t.betOption))
								ELSE HomeValue
							END
				,LastModifyBy = @AdminId
				,LastModifyDate = GETDATE()
		FROM	dbo.ResultDetail r WITH(ROWLOCK, UPDLOCK)
			INNER JOIN @tblResults t
				ON r.MatchId = @matchid
					AND r.ResourceId = t.ResourceId_BetOption
	END
END

GO

GRANT EXECUTE ON [NAP_Set_FastMarket_ResultDetailUpd] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [NAP_Set_FastMarket_ResultDetailUpd] TO [vnteam] AS [dbo]
GO