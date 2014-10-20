ALTER PROCEDURE [dbo].[NAP_BetTypeSel] 
	@Mode		SMALLINT = 0
	,@MatchId	INT = 0 -- defaul value for NG, VS, LC
	,@ErrMsg NVARCHAR(200) = '' OUTPUT
    ,@ErrCode INT = 0 OUTPUT
AS
/*  
	Created: 20130610@Elodie  
	Task : Select bettypes for NAP's special delete  
	DB: DBAGE/bodb02  
	Original: Acc_BetTypeSel  
	  
	Revisions:      
		- 20130813@Elodie: Add new bettype Live Bacarat and Live Roulette (1103,1104)  
		- 20141015@Kathy: exclude the testing bettypes (Sportting Solution & BetRadar) [Redmine:#24391]
		- 20140926@Kathy: Get list bettype belong to matchid [Redmine:#23129]
	      
	Param's Explanation:  
	@Mode:   
		 0: Single bet  
		 1: Number game  
		 2: Early Kick-Off  
		 3: TicketListing  
		 4: Mix Parlay   
		 5: Virtual sports  
*/
BEGIN
	SET NOCOUNT ON
	
	
	IF @mode in (0, 2, 4) OR (@matchid <> 0 AND @mode = 3) 
	BEGIN	
		DECLARE @Sporttype INT	
		
		SET @Sporttype = 0
		
		SELECT @Sporttype = sporttype
		FROM match WITH (NOLOCK)
		WHERE matchid = @MatchID
		
		IF (@Sporttype NOT BETWEEN 1 AND 99) AND (@Sporttype <> 154)
		BEGIN 
			SET @ErrCode = 100
			SET @ErrMsg ='Invalid match' 
			RETURN
		END 
	END
	
	CREATE TABLE #TmpBettype (
		typeid			INT
		,type			INT -- 0:Sport Book, 1:Number Game, 2:Virtual Sports, 3:Live Casino  
		,liveindicator  BIT
		)
		
	DECLARE @tmpConsolidatedBettypes TABLE (
		parentid		INT
		,typeid			INT
	)
	
	INSERT INTO @tmpConsolidatedBettypes
		SELECT 153, 1308 -- Game Handicap
		UNION ALL
		SELECT 154, 1311 -- Set x Winner
		UNION ALL
		SELECT 155, 1316 -- Set x Game Handicap
		UNION ALL
		SELECT 156, 1312 -- Set x Total Games
		UNION ALL
		SELECT 1, 1303 -- Handicap
		UNION ALL
		SELECT 2, 1305 -- Odd/Even
		UNION ALL
		SELECT 3, 1306 -- Over/Under
		UNION ALL
		SELECT 20, 1301 -- Moneyline
	
	-- @mode = 0: Single bet, 2: Early kick-off, 3: Ticket listing, 4: Mix Parlay   
	-- type = 0: Sport Book
	IF @Mode IN (0, 2, 3, 4)
	BEGIN
		
		INSERT INTO #TmpBettype (
			typeid
			,type
			,liveindicator
			)
		SELECT ISNULL( tb.parentid, b.typeid)
			, 0					
			, 0	
		FROM dbo.bettype b WITH(NOLOCK) 
		INNER JOIN dbo.odds o WITH(NOLOCK) ON b.typeid = o.bettype
		INNER JOIN dbo.match m WITH(NOLOCK) ON m.matchid = o.matchid
		LEFT JOIN @tmpConsolidatedBettypes tb ON tb.typeid = b.typeid
		WHERE m.matchid = @matchid
		AND (m.sporttype BETWEEN 1 AND 99 OR m.sporttype = 154)
		
		IF (EXISTS(SELECT TOP 1 1 FROM #TmpBettype)) AND (@mode IN (2,3))
		BEGIN
			INSERT INTO #TmpBettype (
				typeid
				,type
				,liveindicator
				)
			SELECT b.typeid		
				, 0				
				, 0				
			FROM dbo.bettype b WITH(NOLOCK)
			WHERE b.typeid IN (9, 29)
		END
	END
	
	 -- 3: TicketListing  
	IF @Mode = 3
	BEGIN
		INSERT INTO #TmpBettype (
				typeid
				,type
				,liveindicator
				)
		SELECT b.typeid
			,3 AS type -- type = 3: Live Casino
			,0 AS liveindicator
		FROM dbo.bettype b WITH(NOLOCK)
		WHERE b.typeid BETWEEN 1101 AND 1199
		AND @matchid = 0
	END
	
	----- number game  
	IF @Mode IN (1, 3)
	BEGIN
		INSERT INTO #TmpBettype (
			typeid
			,type
			,liveindicator
			)
		SELECT typeid
			,1 AS type -- type = 1: NG
			,0 AS liveindicator
		FROM bettype WITH (NOLOCK)
		WHERE typeid IN (81, 82, 83, 84, 86, 88, 90)
		AND @matchid = 0
		UNION
		SELECT typeid
			,1 AS type -- type = 1: NG
			,1 AS liveindicator
		FROM bettype WITH (NOLOCK)
		WHERE typeid IN (85, 86, 87, 89, 90)
		AND @matchid = 0
		
	END

	----- virtual sports  
	IF @Mode IN (5, 3)
	BEGIN
		INSERT INTO #TmpBettype (
			typeid
			,type
			,liveindicator
			)
		SELECT typeid
			,2 AS type -- type = 2: VS
			,0 AS liveindicator
		FROM bettype WITH (NOLOCK)
		WHERE typeid BETWEEN 1201 AND 1299
		AND @matchid = 0
	END
	
	SELECT tb.typeid
		,b.typenamee AS bettypename
		,tb.type
		,tb.liveindicator
	FROM #TmpBettype tb
	INNER JOIN bettype b WITH(NOLOCK) ON tb.typeid = b.typeid
	GROUP BY tb.typeid, b.typenamee, type, liveindicator
	ORDER BY tb.typeid
END
GO
GRANT EXECUTE ON [dbo].[NAP_BetTypeSel] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_BetTypeSel] TO [vnteam] AS [dbo]