ALTER PROCEDURE [dbo].[NAP_Admin_Settlement_Refund_All_Push] 
	@Matchid						INT
	,@AdminId						INT
	,@IsExcludeBetdaq				BIT				= 0
	,@IsSettleAbandonedMatch		BIT				= 0
	,@IsExcludeBetfair				BIT				= 0
	,@IsSettleAbandonedMatchBetFair BIT 			= 0
	,@IsSettleAbandonedMatchIBC		BIT 			= 0
	,@HalfTimeHome					INT 			= NULL
	,@HalfTimeAway					INT 			= NULL
	,@FullTimeHome					INT 			= NULL
	,@FullTimeAway					INT 			= NULL
	,@BetStatus						NVARCHAR(50)	= NULL
	,@SetResult						VARCHAR(50)		= NULL 
	,@GameResult1					VARCHAR(500)	= NULL
	,@GameResult2					VARCHAR(500)	= NULL
	,@GameResult3					VARCHAR(500)	= NULL
	,@GameResult4					VARCHAR(500)	= NULL
	,@GameResult5					VARCHAR(500)	= NULL
	,@SelectedSet					VARCHAR(50)		= NULL 
	,@SelectedSet1Game				VARCHAR(500)	= NULL 
	,@SelectedSet2Game				VARCHAR(500)	= NULL 
	,@SelectedSet3Game				VARCHAR(500)	= NULL 
	,@SelectedSet4Game				VARCHAR(500)	= NULL 
	,@SelectedSet5Game				VARCHAR(500)	= NULL
	,@SelectedSettleFinishedGame	VARCHAR(50)		= NULL 
	,@IP							VARCHAR(15)		= ''
	,@ErrCode						INT				= 0		OUTPUT
	,@ErrMsg						NVARCHAR(200)	= ''	OUTPUT
AS
/*
	Created: Kathy
	Date: 20140213
	Task : refund tickets 
	Original: 
	DB: DBTXN/BODB02

	Revisions: 
		- 20140304@Kathy: Execute settlement for abandoned/postponed matches- Clean Sheet, Both/One/Neither team to score, To Win To Nil 
		- 20140506@Kathy: Don't allow to calculate exists matches in queue
		- 20140825@Kathy: Support 1H FGLG (127) for Apollo [Redmine:#16276]
		- 20141024@Jamie: Sportting Solution Tennis Settlement [Redmine:#23034]

	Param's Explanation:
	• @matchid: matchid need to refund
	• @IsExcludeBetdaq: Is Exclude betdaq tickets or not
	• @IsSettleAbandonedMatch: Is Settlement for Abandoned/postponed match or not
	• @IsExcludeBetfair: Is Exclude betfair tickets or not
	• @IsSettleAbandonedMatchBetFair: Is Settlement for Betfair ticket of Abandoned/postponed match or not
	* List of BetDaq Customers 
				custid	--- username	-	roleid
				50057	---	BQUS888		-	1
				879241	---	BQUSMLB		-	1
				103873	---	BQUSNBA		-	1
				78761	---	ITibc101	-	1
				1688156	---	MTEST0101	-	2
				851668  --- BDUS01      -   1
				878902  --- BDUS016     -   1
	* List of Betfair Customers 
				custid	--- username	-	roleid
				2331	---	BF		    -	1
				1077687	---	BFOS		-	1

*/
BEGIN
	SET NOCOUNT ON

	DECLARE @matchcode	NVARCHAR(50)
		,@sporttype		INT
		,@leagueid		INT
		,@sqlCommand	NVARCHAR(1000)
		,@IsNested		BIT
		,@Action		VARCHAR(20)
		,@procName		NVARCHAR(50)

	SELECT @matchcode	= m.matchcode
		,@sporttype		= m.sporttype
		,@leagueid		= m.leagueid
		,@IsNested		= 0
		,@Action		= 'CAL'
	FROM DBPRO.bodb02.dbo.match m WITH (NOLOCK)
	WHERE m.matchid = @MatchId

	IF @@ROWCOUNT = 0
	BEGIN
		SELECT @ErrCode = 1000001
			,@ErrMsg	= 'Match does not exist!'

		RETURN
	END

	IF EXISTS (
			SELECT 1
			FROM Single_Calculate_Queue WITH (NOLOCK)
			WHERE matchid = @matchid
				AND IsCalculating IN (0, 1)
			)
		OR EXISTS (
			SELECT 1
			FROM Parlay_Calculate_Queue WITH (NOLOCK)
			WHERE matchid = @matchid
				AND IsCalculating IN (0, 1)
			)
	BEGIN
		SELECT @ErrCode = 1000000
			,@ErrMsg	= 'This match is being calculated, please wait a few seconds until the on-going process is completed and try again.'

		RETURN
	END

	SELECT @ErrCode		= 0
		,@ErrMsg		= ''
		,@procName		= OBJECT_NAME(@@procid)
		,@sqlCommand	= 'EXEC [dbo].[NAP_Admin_Settlement_Refund_All] @Matchid = ' + CONVERT(NVARCHAR(50), @MatchId) 
																  + ', @creator = ' + CONVERT(NVARCHAR(50), @AdminId) 
																  + ', @IsExcludeBetdaq = ' + CONVERT(NVARCHAR(1), @IsExcludeBetdaq) 
																  + ', @IsSettleAbandonedMatch = ' + CONVERT(NVARCHAR(1), @IsSettleAbandonedMatch) 
																  + ', @IsExcludeBetfair = ' + CONVERT(NVARCHAR(1), @IsExcludeBetfair) 
																  + ', @IsSettleAbandonedMatchBetFair = ' + CONVERT(NVARCHAR(1), @IsSettleAbandonedMatchBetFair) 
																  + ', @IsSettleAbandonedMatchIBC = ' + CONVERT(NVARCHAR(1), @IsSettleAbandonedMatchIBC) 
																  + ', @betstatus = ' + CASE WHEN @BetStatus IS NULL THEN 'NULL' ELSE 'N''' + CONVERT(NVARCHAR(20), @BetStatus) + '''' END 
																  + ', @SetResult = ' + CASE WHEN @SetResult IS NULL THEN 'NULL' ELSE '''' + CONVERT(VARCHAR(50),@SetResult) + '''' END
																  + ', @GameResult1 = ' + CASE WHEN @GameResult1 IS NULL THEN 'NULL' ELSE '''' + CONVERT(VARCHAR(500),@GameResult1) + '''' END
																  + ', @GameResult2 = ' + CASE WHEN @GameResult2 IS NULL THEN 'NULL' ELSE '''' + CONVERT(VARCHAR(500),@GameResult2) + '''' END
																  + ', @GameResult3 = ' + CASE WHEN @GameResult3 IS NULL THEN 'NULL' ELSE '''' + CONVERT(VARCHAR(500),@GameResult3) + '''' END
																  + ', @GameResult4 = ' + CASE WHEN @GameResult4 IS NULL THEN 'NULL' ELSE '''' + CONVERT(VARCHAR(500),@GameResult4) + '''' END
																  + ', @GameResult5 = ' + CASE WHEN @GameResult5 IS NULL THEN 'NULL' ELSE '''' + CONVERT(VARCHAR(500),@GameResult5) + '''' END
																  + ', @SelectedSet = ' + CASE WHEN @SelectedSet IS NULL THEN 'NULL' ELSE '''' + CONVERT(VARCHAR(50),@SelectedSet) + '''' END
																  + ', @SelectedSet1Game = ' + CASE WHEN @SelectedSet1Game IS NULL THEN 'NULL' ELSE '''' + CONVERT(VARCHAR(500),@SelectedSet1Game) + '''' END
																  + ', @SelectedSet2Game = ' + CASE WHEN @SelectedSet2Game IS NULL THEN 'NULL' ELSE '''' + CONVERT(VARCHAR(500),@SelectedSet2Game) + '''' END
																  + ', @SelectedSet3Game = ' + CASE WHEN @SelectedSet3Game IS NULL THEN 'NULL' ELSE '''' + CONVERT(VARCHAR(500),@SelectedSet3Game) + '''' END
																  + ', @SelectedSet4Game = ' + CASE WHEN @SelectedSet4Game IS NULL THEN 'NULL' ELSE '''' + CONVERT(VARCHAR(500),@SelectedSet4Game) + '''' END
																  + ', @SelectedSet5Game = ' + CASE WHEN @SelectedSet5Game IS NULL THEN 'NULL' ELSE '''' + CONVERT(VARCHAR(500),@SelectedSet5Game) + '''' END
																  + ', @SelectedSettleFinishedGame = ' + CASE WHEN @SelectedSettleFinishedGame IS NULL THEN 'NULL' ELSE '''' + CONVERT(VARCHAR(50),@SelectedSettleFinishedGame) + '''' END
																  + ', @fth = ' + ISNULL(CONVERT(NVARCHAR(50), @FullTimeHome), 'NULL') 
																  + ', @fta = ' + ISNULL(CONVERT(NVARCHAR(50), @FullTimeAway), 'NULL') 
																  + ', @hth = ' + ISNULL(CONVERT(NVARCHAR(50), @HalfTimeHome), 'NULL') 
																  + ', @hta = ' + ISNULL(CONVERT(NVARCHAR(50), @HalfTimeAway), 'NULL') 
																  + ', @Action = ''' + CONVERT(NVARCHAR(20), @Action) + '''' 
																  + ', @IsNested = ''' + CONVERT(NVARCHAR(1), @IsNested) + '''' 
																  + ', @IP = ''' + CONVERT(NVARCHAR(50), @IP) + '''' 
																  + ', @ErrCode = @ErrCode OUTPUT' 
																  + ', @ErrMsg = @ErrMsg OUTPUT'


	IF @procName LIKE '%_xtest' OR @procName LIKE '%_xpre'
	BEGIN
		DECLARE @GoalRecord VARCHAR(50)

		BEGIN TRY
			EXEC sys.sp_executesql @sqlCommand
				,N'@ErrMsg VARCHAR(400) OUTPUT, @ErrCode int OUTPUT'
				,@ErrMsg	= @ErrMsg	OUTPUT
				,@ErrCode	= @ErrCode	OUTPUT
		END TRY

		BEGIN CATCH
			SELECT @ErrMsg	= @ErrMsg + ISNULL(ERROR_MESSAGE(), '')
				,@ErrCode	= @@error

			RETURN
		END CATCH

		SELECT @FullTimeHome	= m.finalhomescore
			,@FullTimeAway		= m.finalawayscore
			,@HalfTimeHome		= m.hthomescore
			,@HalfTimeAway		= m.htawayscore
			,@GoalRecord		= m.GoalRecord
			,@BetStatus			= m.betstatus
		FROM DBPRO.BODB02.dbo.match m WITH (NOLOCK)
		WHERE m.matchid = @MatchId

		EXEC Acc_Set_ConfirmedAction 
			@matchid		= @MatchId
			,@action		= 13
			,@fth 			= @FullTimeHome
			,@fta 			= @FullTimeAway
			,@hth 			= @HalfTimeHome
			,@hta 			= @HalfTimeAway
			,@goalrecord	= @GoalRecord
			,@betstatus		= @BetStatus
	END
	ELSE
	BEGIN
		INSERT INTO Single_Calculate_Queue (
			matchid
			,matchcode
			,IsCalculating
			,LeagueID
			,SportType
			,AdminId
			,IP
			,Action
			,sqlCommand
			)
		SELECT @MatchId
			,@matchcode
			,0
			,@leagueid
			,@sporttype
			,@AdminId
			,@IP
			,'Refund'
			,@sqlCommand
	END
END
GO
GRANT EXECUTE ON [dbo].[NAP_Admin_Settlement_Refund_All_Push] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Admin_Settlement_Refund_All_Push] TO [vnteam] AS [dbo]