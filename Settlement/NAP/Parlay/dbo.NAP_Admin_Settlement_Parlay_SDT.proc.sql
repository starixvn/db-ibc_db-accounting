ALTER PROCEDURE [dbo].[NAP_Admin_Settlement_Parlay_SDT] (
	@matchId 			INT
	, @matchdate		SMALLDATETIME
	, @Mode				VARCHAR(20)
	, @fthomescore		SMALLINT
	, @ftawayscore		SMALLINT
	, @hthomescore		SMALLINT
	, @htawayscore		SMALLINT
	, @sportType		SMALLINT
	, @betstatus		NVARCHAR(50)
	, @goalRecord		VARCHAR(50)	
	, @ticketCount		INT = 0 OUTPUT
	, @ErrCode 			INT = 0 OUTPUT
	, @ErrMsg 			NVARCHAR(200) = '' OUTPUT
)
AS
/*	Creator: 20161206@Bobby
	Task: #61352 - Apply settle determined for parlay bet types
	DB: DBTXN/BODB02
	ORIGINAL: 

	Revisions:		
		

	Param's Explanation:		
		- @Mode: ['ABANDONED-1H', 'ABANDONED-2H']
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @IsHT 			BIT
		, @hScore1H			TINYINT
		, @aScore1H			TINYINT
		, @hScore2H			TINYINT
		, @aScore2H			TINYINT
		
	--conners result
		, @hthCorners		TINYINT
		, @htaCorners		TINYINT
		, @fthCorners		TINYINT
		, @ftaCorners		TINYINT
		, @ftFCorner		VARCHAR(1)
		, @htFCorner		VARCHAR(1)
		
		, @totalConner		TINYINT
		, @totalConner1H 	TINYINT
	
	DECLARE @rsQuery			NVARCHAR(MAX)
	
	CREATE TABLE #SDTBettypes (bettype SMALLINT PRIMARY KEY, IsDetermined BIT)
	CREATE TABLE #tmpResultDetail (
		ResourceID 			VARCHAR(20)
		, HomeValue 		VARCHAR(50)
		, AwayValue 		VARCHAR(50)
	)	
	
	SELECT @IsHT			= CASE WHEN @Mode IN ('ABANDONED-1H') THEN 1 ELSE 0 END 
		, @hScore1H 		= @hthomescore
		, @aScore1H 		= @htawayscore
		, @hScore2H			= CASE WHEN @IsHT = 0 THEN @fthomescore - @hthomescore ELSE 0 END
		, @aScore2H			= CASE WHEN @IsHT = 0 THEN @ftawayscore - @htawayscore ELSE 0 END
								
		--conners--------------
		, @hthCorners		= 0
		, @htaCorners		= 0
		, @fthCorners		= 0
		, @ftaCorners		= 0
		, @ftFCorner		= ''
		, @htFCorner		= ''
		, @ticketCount		= 0
	
	SET @rsQuery = '
		INSERT INTO #tmpResultDetail(ResourceID, HomeValue, AwayValue)	
		SELECT ResourceID, HomeValue, AwayValue
		FROM OPENQUERY([DBPRO],''SELECT ResourceID, HomeValue, AwayValue
		FROM bodb02.dbo.ResultDetail rs WITH(NOLOCK)
		WHERE matchid = '+CAST(@matchid AS VARCHAR(10))+' 
			AND SettlementStatusID = ' + 
			CASE WHEN @IsHT = 1 THEN '5' ELSE '6' END
			+ ''') AS rs'
	
	EXEC sp_executesql @rsQuery
	
	IF(@@ROWCOUNT > 0)
	BEGIN
		SELECT @hthCorners		= CASE WHEN ResourceID = '05' THEN CAST(HomeValue AS TINYINT) ELSE @hthCorners END
			, @htaCorners		= CASE WHEN ResourceID = '05' THEN CAST(AwayValue AS TINYINT) ELSE @htaCorners END
			, @fthCorners		= CASE WHEN ResourceID = '04' THEN CAST(HomeValue AS TINYINT) ELSE @fthCorners END
			, @ftaCorners		= CASE WHEN ResourceID = '04' THEN CAST(AwayValue AS TINYINT) ELSE @ftaCorners END
			, @ftFCorner		= CASE WHEN ResourceID = '206' THEN HomeValue ELSE @ftFCorner END
			, @htFCorner		= CASE WHEN ResourceID = '207' THEN HomeValue ELSE @htFCorner END
			
		FROM #tmpResultDetail
	END
	
	SELECT @totalConner			= CASE WHEN @IsHT = 1 THEN (@hthCorners + @htaCorners) ELSE (@fthCorners + @ftaCorners) END
		, @totalConner1H 		= (@hthCorners + @htaCorners)

	
	INSERT INTO #SDTBettypes (bettype, IsDetermined)
	SELECT f.BetType
		, f.IsDetermined
	FROM dbo.f_Set_GetGroupBettypes() f
	WHERE 1 = CASE 
				WHEN @IsHT = 0 AND f.GroupId IN (2,4,6)  THEN 1 -- FT, FT corner, HTFT-FGLG
				WHEN @IsHT = 1 THEN 1
				ELSE 0
			END
		AND f.IsAuto = 0 --Exclude BetRadar, FM
	
	BEGIN --SDT Process
		DECLARE @tempBatch TABLE (transid BIGINT, refno BIGINT, StatusId TINYINT)
		DECLARE @minTransId		BIGINT
			,@maxTransId		BIGINT
			,@fromTransId		BIGINT
			,@batchNo			INT
			,@batchCount		INT
			,@loopCount			INT
			,@strTicket			VARCHAR(MAX)


		SELECT  @minTransId 	= MIN(transid)
			, @maxTransId 		= MAX(transid)
			, @ticketCount		= COUNT(1)
			
		FROM dbo.bettransm bm WITH(NOLOCK)
			INNER JOIN #SDTBettypes t 
			ON bm.bettype		= t.bettype
		
		WHERE bm.matchId		= @matchId
			AND bm.statusID		NOT IN (101, 102)	
		
		SELECT @batchNo			= 2000
			, @batchCount		= 0
			, @fromTransId		= @minTransId
		
		WHILE (1 = 1)
		BEGIN
		
			DELETE @tempBatch
		
			INSERT INTO @tempBatch(transid, refno, StatusId)
			SELECT TOP(@batchNo) 
				bm.transid
				, bm.refno
				, CASE 
					WHEN t.IsDetermined = 1 AND odds.modds IS NOT NULL THEN odds.StatusId 
					ELSE 103 
				END AS StatusId
			FROM dbo.bettransm bm WITH(NOLOCK)
				INNER JOIN #SDTBettypes t ON bm.bettype = t.bettype
				OUTER APPLY
				(
					SELECT modds, StatusId 
					FROM [dbo].[f_Set_Parlay_SDT_CalModds](
						bm.bettype
						, bm.betteam
						, bm.hdp1
						, bm.hdp2
						, @hScore1H
						, @aScore1H
						, @hScore2H
						, @aScore2H
						, bm.transdesc
						, @IsHT
					)
					WHERE StatusId IN (112,113)
					UNION ALL
					SELECT modds, StatusId 
					FROM [dbo].[f_Set_Parlay_SDT_CalModds_Corner](
						bm.bettype
						, bm.betteam
						, bm.hdp1
						, bm.hdp2
						, @totalConner
						, @totalConner1H
						, @ftFCorner
						, @htFCorner
						, @hthCorners
						, @htaCorners
						, @fthCorners
						, @ftaCorners
						, @IsHT
					)
					WHERE StatusId IN (112,113)
					UNION ALL
					SELECT modds, StatusId 
					FROM [dbo].[f_Set_Parlay_SDT_CalModds_GoalRecord](
						bm.bettype
						, bm.betteam
						, @GoalRecord
						, @IsHT
					)
					WHERE StatusId IN (112,113)
				
				)  AS odds
			WHERE bm.matchId = @matchId
				AND bm.statusID NOT IN (101,102)
				AND bm.transid BETWEEN @fromTransId AND @maxTransId

			ORDER BY bm.transid
		
			SELECT @batchCount 	= @@ROWCOUNT
				, @loopCount	+=  @batchCount
				, @strTicket	= CAST((SELECT b.transid AS t
											,b.refno AS r
											,b.statusId AS s
										FROM @tempBatch b
										FOR XML AUTO) AS VARCHAR(MAX)
									)
			
			select @matchid
				,@matchdate
				,@mode AS mode
				,'REFUND' AS [action] 		
				,@strTicket AS strTransIds
			
			IF(@strTicket IS NOT NULL)
			BEGIN
				EXEC dbo.NAP_Admin_Calculate_MP_broker 
					@matchid 		= @matchid
					,@matchdate		= @matchdate
					,@mode 			= 'ABANDONED'
					,@action 		= 'REFUND'
					,@strTransIds	= @strTicket
			END
			
			SELECT @fromTransId = MAX(transid) + 1
			FROM @tempBatch
			
			IF(@batchCount < @batchNo OR @fromTransId = @maxTransId) BREAK
		
		END
		select @loopCount AS LoopCount_SDT
	END
	
	
	DROP TABLE #SDTBettypes
	DROP TABLE #tmpResultDetail
	
	RETURN
END
GO

			