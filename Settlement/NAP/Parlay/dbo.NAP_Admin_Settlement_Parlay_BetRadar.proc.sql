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
	
	CREATE TABLE #autoBettypes (bettype SMALLINT, ResourceId VARCHAR(20)) 
	
	SELECT @IsHT			= CASE WHEN @Mode IN ('ABANDONED-1H', 'REFUND') THEN 1 ELSE 0 END
		,@ticketCount		= 0
	
	INSERT INTO #autoBettypes (bettype, ResourceId)
	SELECT bettype
		,CAST(bm.bettype AS VARCHAR(20)) + '%' ResourceId
	FROM dbo.bettransm bm (NOLOCK)
	WHERE matchid = @matchId
		AND statusID NOT IN(101, 102)
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
	SELECT rs.MatchID
		,rs.ResourceID
		,rs.HomeValue
		,rs.AwayValue
		,rs.SettlementStatusID
	FROM DBPRO.bodb02.dbo.ResultDetail rs WITH (NOLOCK)
		INNER JOIN #autoBettypes AS f 
		ON rs.ResourceId LIKE f.ResourceId
		
	WHERE rs.MatchID = @MatchID 
		AND rs.SettlementStatusID = 4 -- Completed
	
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
	
	
	DECLARE @tempBatch TABLE (transid BIGINT, refno BIGINT, statusId TINYINT)
	CREATE TABLE #tempTickets (transid BIGINT, refno BIGINT, statusId TINYINT)
	
	INSERT INTO #tempTickets (transid, refno, statusId)
	SELECT t.transid
		, t.refno
		, t.statusId
	FROM
	(
		SELECT bm.transid, bm.refno
			, CASE 
				WHEN odds.modds IS NULL THEN 103 --REFUND
				ELSE odds.StatusId --settle determined
			END AS StatusId
		FROM dbo.bettransm bm WITH(NOLOCK)
			INNER JOIN #autoBettypes t ON bm.bettype = t.bettype	
			CROSS APPLY [dbo].[f_Set_Parlay_SDT_CalModds_BetRadar](
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
			AND bm.statusID NOT IN (101,102)
	) AS t
	
	SET @ticketCount 		= @@ROWCOUNT
	
	IF(@ticketCount  > 0)
	BEGIN
		DECLARE @batchNo		INT
			,@batchCount		INT
			,@strTicket			VARCHAR(MAX)
		
		SELECT @batchNo			= 2000
			, @batchCount		= 0
			
		--DO settle SDT parlay tickets
		WHILE (1 = 1)
		BEGIN
			
			DELETE @tempBatch
			
			DELETE TOP(@batchNo) t
			OUTPUT DELETED.transid, DELETED.refno, DELETED.statusId 
			INTO @tempBatch(transid, refno, statusId)
			FROM #tempTickets t
			
			SELECT @batchCount 		= @@ROWCOUNT
				, @strTicket		= CAST((SELECT b.transid AS t
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
			
			IF(@batchCount < @batchNo) BREAK
		END
	END
	DROP TABLE #tempTickets
	
	RETURN
	
END
GO

			