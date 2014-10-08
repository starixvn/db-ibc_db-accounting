ALTER PROCEDURE [dbo].[NAP_BetTypeSel] 
	@Mode		SMALLINT = 0
	,@MatchId	INT = 0 -- remove default value when web is done for testing
AS
/*  
	Created: 20130610@Elodie  
	Task : Select bettypes for NAP's special delete  
	DB: DBAGE/bodb02  
	Original: Acc_BetTypeSel  
	  
	Revisions:      
		- 20130813@Elodie: Add new bettype Live Bacarat and Live Roulette (1103,1104)  
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
	
	CREATE TABLE #TmpBettype (
		typeid			INT
		,bettypename	NVARCHAR(50)
		,type			INT -- 0:Sport Book, 1:Number Game, 2:Virtual Sports, 3:Live Casino  
		,liveindicator  BIT
		)
		
	-- 1: Single bet, 2: Early kick-off, 3: Ticket listing, 4: Mix Parlay   
	IF @Mode IN (0, 2, 3, 4)
	BEGIN
		INSERT INTO #TmpBettype (
			typeid
			,bettypename
			,type
			,liveindicator
			)
		SELECT b.typeid	AS typeid
			, b.typenamee	AS bettypename
			, 0				AS type
			, 0				AS liveindicator
		FROM dbo.bettype b WITH(NOLOCK) 
		INNER JOIN dbo.odds o WITH(NOLOCK) ON b.typeid = o.bettype
		INNER JOIN dbo.match m WITH(NOLOCK) ON m.matchid = o.matchid
		WHERE o.matchid = @matchid
		AND (m.sporttype BETWEEN 1 AND 99 OR m.sporttype = 154)
	END

	 -- 2: Early Kick-Off  
	IF @Mode = 2
	BEGIN
		INSERT INTO #TmpBettype (
			typeid
			,bettypename
			,type
			,liveindicator
			)
		SELECT b.typeid
			, b.typenamee
			, 0
			, 0
		FROM dbo.bettype b WITH(NOLOCK)
		WHERE b.typeid IN (9, 29)
	END

	 -- 3: TicketListing  
	IF @Mode = 3
	BEGIN
		INSERT INTO #TmpBettype (
			typeid
			,bettypename
			,type
			,liveindicator
			)
		SELECT b.typeid
			, b.typenamee
			, 0 -- SportBook
			, 0
		FROM dbo.bettype b WITH(NOLOCK)
		WHERE b.typeid IN (9, 29)
		UNION ALL
		SELECT b.typeid
			,b.typenamee AS bettypename
			,3 AS type -- Live Casino
			,0 AS liveindicator
		FROM dbo.bettype b WITH(NOLOCK)
		WHERE b.typeid BETWEEN 1101
				AND 1199
	END
	
	----- number game  
	IF @Mode IN (1, 3)
	BEGIN
		INSERT INTO #TmpBettype (
			typeid
			,bettypename
			,type
			,liveindicator
			)
		SELECT typeid
			,typenamee AS bettypename
			,1 AS type
			,0 AS liveindicator
		FROM bettype WITH (NOLOCK)
		WHERE typeid IN (81, 82, 83, 84, 86, 88, 90)
		
		UNION
		SELECT typeid
			,typenamee AS bettypename
			,1 AS type
			,1 AS liveindicator
		FROM bettype WITH (NOLOCK)
		WHERE typeid IN (85, 86, 87, 89, 90)
	END

	----- virtual sports  
	IF @Mode IN (5, 3)
	BEGIN
		INSERT INTO #TmpBettype (
			typeid
			,bettypename
			,type
			,liveindicator
			)
		SELECT typeid
			,typenamee AS bettypename
			,2 AS type
			,0 AS liveindicator
		FROM bettype WITH (NOLOCK)
		WHERE typeid BETWEEN 1201
				AND 1299
	END

	SELECT *
	FROM #TmpBettype
	GROUP BY typeid, bettypename, type, liveindicator
	ORDER BY typeid
END



GO
GRANT EXECUTE ON [dbo].[NAP_BetTypeSel] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_BetTypeSel] TO [vnteam] AS [dbo]