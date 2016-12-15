ALTER PROCEDURE [dbo].[NAP_Admin_Settlement_Parlay_BetRadar] (
	@matchId 			INT
	, @matchdate		SMALLDATETIME
	, @Mode 			VARCHAR(20)
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
	
	--BetRadar result
	DECLARE @IsHT 				BIT
		,@PenaltyShootout		VARCHAR(10)	=''
		,@MatchDecidedMethod	VARCHAR(10)	=''
		,@First10Min1x2			VARCHAR(10)	=''
		,@FirstGoalTime10Min	VARCHAR(10)	=''
		,@FirstGoalTime15Min	VARCHAR(10)	=''
		,@WhoAdvancesNextRound	VARCHAR(10) =''
		,@ExtraTimeandGoal		VARCHAR(10)	=''
		,@ExtraTimeYN			VARCHAR(10) =''	

		,@PlayerSentOff			VARCHAR(10) =''
		,@PlayerSentOff1H		VARCHAR(10) =''
		,@PlayerSentOffHome		VARCHAR(10) =''
		,@PlayerSentOffHome1H	VARCHAR(10) =''
		,@PlayerSentOffAway		VARCHAR(10) =''
		,@PlayerSentOffAway1H	VARCHAR(10) =''
		,@GoalScorerFirst		VARCHAR(10) =''		
			
		,@NextGoal1H			VARCHAR(MAX)=''
		,@NextGoal				VARCHAR(MAX)=''
		,@NextGoalTime15Min		VARCHAR(MAX)=''
		,@ExtraNextGoal			VARCHAR(MAX)=''
		,@GoalScorerAnytime		VARCHAR(MAX)=''
		
		,@FirstGoalMethod		VARCHAR(2) =''
			
	DECLARE	@tmpResultDetail TABLE(
		 MatchID				INT
		,ResourceID				VARCHAR(20)
		,HomeValue				VARCHAR(20)
		,AwayValue				VARCHAR(20)
		,SettlementStatusID		TINYINT
	)
	CREATE TABLE #autoBettypes (bettype SMALLINT) 
	
	SELECT @IsHT			= CASE WHEN @Mode IN ('ABANDONED-1H', 'REFUND') THEN 1 ELSE 0 END 
	
	INSERT INTO #autoBettypes (bettype)
	SELECT bettype
	FROM dbo.bettransm bm (NOLOCK)
	WHERE matchid = @matchId
		AND EXISTS (
			SELECT TOP 1 1 
			FROM dbo.f_Set_GetGroupBettypes() AS f 
			WHERE f.GroupId 	= 8 
			AND f.bettype 		= bm.bettype
		)
	GROUP BY bettype
		
	INSERT INTO @tmpResultDetail(
		MatchID
		,ResourceID
		,HomeValue
		,AwayValue
		,SettlementStatusID
	)
	SELECT	 MatchID
			,ResourceID
			,HomeValue
			,AwayValue
			,SettlementStatusID
	FROM DBPRO.bodb02.dbo.ResultDetail rs WITH (NOLOCK)
		INNER JOIN #autoBettypes AS f 
		ON rs.ResourceId LIKE CAST(f.BetType AS VARCHAR(20)) + '%'
		
	WHERE MatchID = @MatchID 
		AND SettlementStatusID = 4 -- Completed
	
	SELECT	 @PenaltyShootout		= ISNULL(MAX(CASE WHEN ResourceID='135' THEN HomeValue ELSE '' END),'')
			,@WhoAdvancesNextRound	= ISNULL(MAX(CASE WHEN ResourceID='168' THEN HomeValue ELSE '' END),'')
			,@ExtraTimeYN			= ISNULL(MAX(CASE WHEN ResourceID='173' THEN HomeValue ELSE '' END),'')
			,@ExtraTimeandGoal		= ISNULL(MAX(CASE WHEN ResourceID='174' THEN HomeValue ELSE '' END),'')
			,@MatchDecidedMethod	= ISNULL(MAX(CASE WHEN ResourceID='175' THEN HomeValue ELSE '' END),'')  
			,@First10Min1x2			= ISNULL(MAX(CASE WHEN ResourceID='176' THEN HomeValue ELSE '' END),'') 
			,@FirstGoalTime10Min	= ISNULL(MAX(CASE WHEN ResourceID='192' THEN HomeValue ELSE '' END),'') 
			,@FirstGoalTime15Min	= ISNULL(MAX(CASE WHEN ResourceID='193' THEN HomeValue ELSE '' END),'')

			,@PlayerSentOff			= ISNULL(MAX(CASE WHEN ResourceID='210' THEN HomeValue ELSE '' END),'')
			,@PlayerSentOff1H		= ISNULL(MAX(CASE WHEN ResourceID='211' THEN HomeValue ELSE '' END),'')
			,@PlayerSentOffHome		= ISNULL(MAX(CASE WHEN ResourceID='212' THEN HomeValue ELSE '' END),'')
			,@PlayerSentOffHome1H	= ISNULL(MAX(CASE WHEN ResourceID='213' THEN HomeValue ELSE '' END),'')
			,@PlayerSentOffAway		= ISNULL(MAX(CASE WHEN ResourceID='214' THEN AwayValue ELSE '' END),'')	--AwayValue 
			,@PlayerSentOffAway1H	= ISNULL(MAX(CASE WHEN ResourceID='215' THEN AwayValue ELSE '' END),'') --AwayValue

			,@GoalScorerFirst		= ISNULL(MAX(CASE WHEN ResourceID='217' THEN HomeValue ELSE '' END),'')
			,@FirstGoalMethod		= ISNULL(MAX(CASE WHEN ResourceID='424' THEN HomeValue ELSE '' END),'')
	FROM	@tmpResultDetail
	
	
	DECLARE @tempSDTBatch TABLE (transid BIGINT, statusId TINYINT)
	CREATE TABLE #tempSDTTickets (transid BIGINT PRIMARY KEY, statusId TINYINT)
	
	INSERT INTO #tempSDTTickets (transid, statusId)
	SELECT t.transid
		, t.statusId
	FROM
	(
		SELECT bm.transid, bm.bettype
			, CASE 
				WHEN odds.modds IS NULL THEN 103 --REFUND
				ELSE odds.StatusId --settle determined
			END AS StatusId
		FROM dbo.bettransm bm WITH(NOLOCK)
			CROSS APPLY [dbo].[f_Set_Parlay_CalModds_BetRadar](
					bm.bettype
					, bm.betteam
					, bm.betcheck
					, @PenaltyShootout
					, @MatchDecidedMethod
					, @First10Min1x2
					, @FirstGoalTime10Min
					, @FirstGoalTime15Min
					, @WhoAdvancesNextRound
					, @ExtraTimeandGoal
					, @ExtraTimeYN

					, @PlayerSentOff
					, @PlayerSentOff1H
					, @PlayerSentOffHome
					, @PlayerSentOffHome1H
					, @PlayerSentOffAway
					, @PlayerSentOffAway1H
					, @GoalScorerFirst
						
					, @NextGoal1H
					, @NextGoal
					, @NextGoalTime15Min
					, @ExtraNextGoal
					, @GoalScorerAnytime
					
					, @FirstGoalMethod
					, @IsHT
				)  AS odds
			
		WHERE bm.matchid = @matchid
			AND bm.statusID IN (0)
			AND EXISTS(SELECT 1 FROM #autoBettypes WHERE bettype = bm.bettype)
	) AS t
	
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
			,@mode 			= 'ABANDONED'
			,@action 		= 'REFUND'
			,@strTransIds	= @strSDTTicket
			
		IF(@batchCount < @batchNo) BREAK
	END
	
	DROP TABLE #tempSDTTickets
	
	RETURN
	
END
GO

			