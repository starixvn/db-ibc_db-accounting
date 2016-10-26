USE [bodb02]
GO

ALTER PROCEDURE dbo.NAP_Settlement_InstantCalculation_Checking
	@MatchId			INT
    , @HomeScore		VARCHAR(50)
	, @AwayScore		VARCHAR(50)
    , @Action			VARCHAR(10)
	, @ErrCode 			INT = 0 OUTPUT
	, @ErrMsg 			VARCHAR(250) = '' OUTPUT
AS
/*
	Creator: 20160930@Bobby
	Task: Update or insert new score result for Instant Calculation.
	DB: DBTXN/bodb02
	Revisions:
		- 20160930@Bobby: #65003 - Check validation of instant process 
		
	Param's Explanation:
		- @Action: ['INST-HT', 'INST-FT']

*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @matchcode		VARCHAR(30)
		, @leagueid			INT
		, @totalGoal		TINYINT
		, @totalGoalCheck	TINYINT
		, @isPending		BIT
		, @isUnDecided		BIT
		, @comparedValue 	SMALLMONEY
		, @instantCheck		BIT
		, @CalculationType	TINYINT
		, @hScore			TINYINT
		, @aScore			TINYINT
	
	CREATE TABLE #instantBettype (bettype SMALLINT)
	
	SELECT @ErrCode			= 0
		, @ErrMsg			= ''
		, @instantCheck		= 0
		, @CalculationType	= CASE 
								WHEN @Action = 'INST-HT' THEN 101
								WHEN @Action = 'INST-FT' THEN 102
								ELSE 0
							END
		, @hScore			= CAST(@HomeScore AS INT)
		, @aScore			= CAST(@AwayScore AS INT)
		, @totalGoal		= @hScore + @aScore
		, @comparedValue	= @totalGoal - 0.5
	
	INSERT INTO #instantBettype (bettype)
	SELECT 3 AS bettype
	WHERE @CalculationType IN (101, 102)
	UNION ALL
	SELECT 8 AS bettype
	WHERE @CalculationType IN (101)
	
	-- checking for instant match status
    SELECT 
		@matchcode 			= m.matchcode
		, @leagueid   		= m.leagueid
		, @isPending		= ISNULL(mr.isPending, 0)
		, @isUnDecided		= ISNULL(mr.isUnDecided, 0)
    FROM DBPRO.bodb02.dbo.match m WITH (NOLOCK)
		INNER JOIN DBPRO.bodb02.dbo.match_remark mr WITH (NOLOCK)
		ON m.matchid 		= mr.matchid
    WHERE m.matchid 			= @MatchId
		AND m.sporttype			= 1
		AND 2 & m.AutoSetting 	= 2
	
	IF (@matchcode 		IS NULL --does not exist match
		OR @isPending 	= 1
		OR @isUnDecided = 1
	)
    BEGIN
        SELECT @ErrCode = 1001001
			, @ErrMsg   = 'This match is invalid or disabled instant calculation setting!'

        RETURN
    END
	
	BEGIN TRY
		;WITH InstMatchResult AS (
			SELECT TOP 1 
				CAST(HomeValue AS TINYINT) AS HomeScore
				,CAST(AwayValue AS TINYINT) AS AwayScore
			FROM DBPRO.bodb02.dbo.AutoPayoutResult aps WITH (NOLOCK)
			WHERE matchid 			= @matchid
				AND CalculationType = @CalculationType
				AND StatusId		= 2 -- completed
			ORDER BY CreatedDate DESC
		) 
		SELECT @totalGoalCheck = HomeScore + AwayScore
		FROM InstMatchResult
		
		IF(
			ISNULL(@totalGoalCheck, 0) > 0 -- check is first instant calculation or not
			AND @totalGoal < @totalGoalCheck
		)
		BEGIN			
			--select instant bettype
			;WITH instantTicketCheck AS (
				SELECT transid
					, statusID
					, CASE 
						WHEN ods.modds >= 0.5 THEN 112 --WON
						WHEN ods.modds <= - 0.5 THEN 113 --LOSE    
						ELSE 0
					END AS statusCheck
				FROM dbo.bettrans b WITH(NOLOCK)
					CROSS APPLY (
						SELECT 
							CASE 
								WHEN betteam IN ('h') THEN @totalgoal - hdp1
								WHEN betteam IN ('a') THEN hdp1 - @totalgoal
								ELSE NULL 
							END AS modds
					) AS ods
				WHERE matchid 	= @matchid 
					AND EXISTS (SELECT TOP 1 1 FROM #instantBettype ib WHERE ib.bettype = b.bettype)
					AND b.statusId IN (112, 113)
			)
			SELECT @instantCheck = SUM(1)
			FROM instantTicketCheck
			WHERE statusCheck 	<> statusID
			
			IF(@instantCheck > 0)
			BEGIN
				SELECT @ErrCode = 1001002
					, @ErrMsg   = 'The previous instant calculation was wrong. It dues to the difference between the current and previous instant score!'

				RETURN
			END
		END
		
	END TRY
	BEGIN CATCH 
		SELECT @ErrCode = 1001003
			, @ErrMsg   = ERROR_MESSAGE()

		RETURN
	END CATCH
	
END
GO
GRANT EXECUTE ON [dbo].[NAP_Settlement_InstantCalculation_Checking] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Settlement_InstantCalculation_Checking] TO [vnteam] AS [dbo]
GO