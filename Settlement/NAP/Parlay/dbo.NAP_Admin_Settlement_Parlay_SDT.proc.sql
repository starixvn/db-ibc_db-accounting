ALTER PROCEDURE [dbo].[NAP_Admin_Settlement_Parlay_SDT] (
	@matchId 			INT
	, @matchdate		SMALLDATETIME
	, @Mode 			VARCHAR(20)
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
	
	DECLARE 
		@hScore1H			TINYINT
		, @aScore1H			TINYINT
		, @hScore2H			TINYINT
		, @aScore2H			TINYINT
		, @FGNG				VARCHAR(50)
		, @IsHT				BIT
		
	--conners result
	DECLARE @hthCorners			TINYINT
		, @htaCorners			TINYINT
		, @fthCorners			TINYINT
		, @ftaCorners			TINYINT
		, @ftFCorner			VARCHAR(1)
		, @htFCorner			VARCHAR(1)
		
		, @totalConner			TINYINT
		, @totalConner1H 		TINYINT
	
	--BetRadar result
	DECLARE @NextGoal			NVARCHAR(MAX)
		, @GoalScorerAnytime	NVARCHAR(MAX)
	
	DECLARE @rsQuery			NVARCHAR(MAX)
	
	DECLARE @tempSDTBatch TABLE (transid BIGINT, statusId TINYINT)
	CREATE TABLE #tempSDTTickets (transid BIGINT PRIMARY KEY, statusId TINYINT)
	
	CREATE TABLE #tmpResultDetail (
		ResourceID 		VARCHAR(20)
		, HomeValue 	VARCHAR(50)
		, AwayValue 	VARCHAR(50)
	)	
	
	SELECT @IsHT			=  CASE WHEN @Mode = 'ABANDONED-1H' THEN 1 ELSE 0 END
		, @hScore1H 		= @hthomescore
		, @aScore1H 		= @htawayscore
		, @hScore2H			= CASE WHEN @Mode = 'ABANDONED-2H' THEN @fthomescore - @hthomescore ELSE NULL END
		, @aScore2H			= CASE WHEN @Mode = 'ABANDONED-2H' THEN @ftawayscore - @htawayscore ELSE NULL END
		, @GoalRecord		= CASE WHEN LEFT(@GoalRecord, 1) = ';' THEN SUBSTRING(@GoalRecord,2,LEN(@GoalRecord) - 1) ELSE @GoalRecord END
		, @FGNG				= CASE 	WHEN LEFT(@GoalRecord, 1) = 'H' THEN '1'  
									WHEN LEFT(@GoalRecord, 1) = 'A' THEN '2'  
									ELSE ''
								END 
		, @FGNG				= CASE WHEN @FGNG <> '' THEN @FGNG + ':1' ELSE '' END
		
		--conners--------------
		, @hthCorners		= 0
		, @htaCorners		= 0
		, @fthCorners		= 0
		, @ftaCorners		= 0
		, @ftFCorner		= ''
		, @htFCorner		= ''
	
	SET @rsQuery = '
		INSERT INTO #tmpResultDetail(ResourceID, HomeValue, AwayValue)	
		SELECT ResourceID, HomeValue, AwayValue
		FROM OPENQUERY([DBPRO],''SELECT ResourceID, HomeValue, AwayValue
		FROM bodb02.dbo.ResultDetail rs WITH(NOLOCK)
		WHERE matchid = '+CAST(@matchid AS VARCHAR(10))+' 
			AND SettlementStatusID = ' + 
			CASE WHEN @Mode = 'ABANDONED-1H' THEN '5' ELSE '6' END
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
	
	SELECT @totalConner			= CASE WHEN @Mode = 'ABANDONED-1H' THEN (@hthCorners + @htaCorners) ELSE (@fthCorners + @ftaCorners) END
		, @totalConner1H 		= (@hthCorners + @htaCorners)
	
	;WITH cteBettypes
	AS
	(
		SELECT f.BetType
		FROM dbo.f_Set_GetGroupBettypes() f
		WHERE f.IsDetermined = 1 -- support to settle determined tickets
				AND 1 = CASE 
							WHEN @Mode = 'ABANDONED-2H' AND f.GroupId IN (2,4,6)  THEN 1 -- FT, FT corner, HTFT-FGLG
							WHEN @Mode = 'ABANDONED-1H' THEN 1
							ELSE 0
						END
				AND f.GroupId <> 8 -- auto betradar
	)
	INSERT INTO #tempSDTTickets (transid, statusId)
	SELECT b.transid
		, b.statusId
	FROM
	(
		SELECT bm.transid, bm.bettype, odds.StatusId
		FROM dbo.bettransm bm WITH(NOLOCK)
			CROSS APPLY
			(
				SELECT modds, StatusId 
				FROM [dbo].[f_Set_Parlay_CalModds](
					bm.bettype
					, bm.betteam
					, bm.hdp1
					, bm.hdp2
					, @hScore1H
					, @aScore1H
					, @hScore2H
					, @aScore2H
					, @FGNG
					, bm.transdesc
					, @IsHT
				)
				WHERE modds IS NOT NULL
				UNION ALL
				SELECT modds, StatusId 
				FROM [dbo].[f_Set_Parlay_CalModds_Corner](
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
					, @Mode
				)
				WHERE modds IS NOT NULL
				UNION ALL
				SELECT modds, StatusId 
				FROM [dbo].[f_Set_Parlay_CalModds_BetRadar](
					bm.bettype
					, bm.betteam
					, bm.betcheck
					, @NextGoal
					, @GoalScorerAnytime
					, @Mode
				)
				WHERE modds IS NOT NULL
			)  AS odds
			
		WHERE bm.matchid = @matchid
			AND bm.statusID IN (0)
			AND odds.statusID IN (112,113)
	) AS b
	WHERE b.bettype IN (SELECT bettype FROM cteBettypes)
	
	DECLARE @batchNo		INT
		,@batchCount		INT
		,@strSDTTicket		VARCHAR(MAX)
	
	SELECT @batchNo			= 1000
		, @batchCount		= 0
		, @ticketCount		= 0
		
	--DO settle SDT parlay tickets
	WHILE (1 = 1)
	BEGIN
		
		DELETE @tempSDTBatch
		
		DELETE TOP(@batchNo) t
		OUTPUT DELETED.transid, DELETED.statusId 
		INTO @tempSDTBatch(transid, statusId)
		FROM #tempSDTTickets t
		
		SELECT @batchCount 		= @@ROWCOUNT
			, @ticketCount 		+= @batchCount
			, @strSDTTicket		= CAST((SELECT b.transid AS t
											,b.statusId AS s 
										FROM @tempSDTBatch b
										FOR XML AUTO) AS VARCHAR(MAX)
								)
		
		
		EXEC dbo.NAP_Admin_Calculate_MP_broker 
			@matchid 		= @matchid
			,@matchdate		= @matchdate
			,@mode 			= @Mode
			,@action 		= 'REFUND'
			,@strTransIds	= @strSDTTicket
			
		IF(@batchCount < @batchNo) BREAK
	END
	
	DROP TABLE #tmpResultDetail
	DROP TABLE #tempSDTTickets
	
	RETURN
	
END
GO

			