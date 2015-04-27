ALTER PROCEDURE [dbo].[NAP_Admin_Settlement_1_Push] 
	 @AdminId				INT
	,@Matchid				INT
	,@FullTimeHome			SMALLINT		= NULL
	,@FullTimeAway			SMALLINT		= NULL
	,@HalfTimeHome			SMALLINT		= NULL
	,@HalfTimeAway			SMALLINT		= NULL 
	,@GoalRecord			VARCHAR(50)		= NULL
	,@BetStatus				NVARCHAR(50)	
	,@SetResult				VARCHAR(50)		= NULL 
	,@GameResult1			VARCHAR(MAX)	= NULL
	,@GameResult2			VARCHAR(MAX)	= NULL
	,@GameResult3			VARCHAR(MAX)	= NULL
	,@GameResult4			VARCHAR(MAX)	= NULL
	,@GameResult5			VARCHAR(MAX)	= NULL
	,@SelectedSet			VARCHAR(50)		= NULL 
	,@SelectedSet1Game		VARCHAR(MAX)	= NULL 
	,@SelectedSet2Game		VARCHAR(MAX)	= NULL 
	,@SelectedSet3Game		VARCHAR(MAX)	= NULL 
	,@SelectedSet4Game		VARCHAR(MAX)	= NULL 
	,@SelectedSet5Game		VARCHAR(MAX)	= NULL 
	,@fthCorners			SMALLINT		= NULL
	,@ftaCorners			SMALLINT		= NULL
	,@hthCorners			SMALLINT		= NULL
	,@htaCorners			SMALLINT		= NULL 
	,@FTFCorner				VARCHAR(1)		= NULL
	,@FTLCorner				VARCHAR(1)		= NULL
	,@HTFCorner				VARCHAR(1)		= NULL
	,@HTLCorner				VARCHAR(1)		= NULL 	
	,@Action				VARCHAR(10)		= 'CAL'
	,@IP					VARCHAR(15)		= ''
	,@ErrCode				INT				= 0		OUTPUT
	,@ErrMsg				NVARCHAR(200)	= ''	OUTPUT
AS
/*	Creator: Kathy
	Date: 20140213
	Task: SP for settlement
	DB: DBTXN/BODB02

	Revisions:		
		- 20140506@Kathy: Don't allow to calculate exists matches in queue
		- 20140825@Kathy: Support 1H FGLG (127) for Apollo [Redmine:#16276]
		- 20141013@Jamie: Sporting Solution for Tennis [Redmine:#23034]
		- 20150401@Kathy: Add checking ticket status before performing settlement [Redmine:#33493]
		- 20150406@Jamie: Manual Settlement Betradar phase 2 [Redmine: #27212]
		
	Param's Explanation:

		
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @matchcode			NVARCHAR(50)
		,@sporttype				INT
		,@leagueid				INT
		,@sqlCommand			NVARCHAR(MAX) 
		,@procName				NVARCHAR(50)

	SELECT @matchcode	= m.matchcode
		,@sporttype		= m.sporttype
		,@leagueid		= m.leagueid
		
	FROM DBPRO.bodb02.dbo.match m WITH (NOLOCK)
	WHERE m.matchid = @MatchId

	IF @@ROWCOUNT = 0
	BEGIN
		SELECT @ErrCode = 1001001
			,@ErrMsg	= 'Match does not exist!'

		RETURN
	END

	IF @action = 'CAL' AND @sporttype = 154 AND (@FullTimeHome = 0 OR @FullTimeHome IS NULL OR @FullTimeAway = 0 OR @FullTimeAway IS NULL)
	BEGIN
		SELECT @ErrCode = 1001002
			,@ErrMsg	= 'Score is not valid.'

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
		SELECT @ErrCode = 1001003
			,@ErrMsg	= 'This match is being calculated, please wait a few seconds until the on-going process is completed and try again.'

		RETURN
	END
	
	-- check waiting ticket
	EXEC NAP_Admin_Settlement_Checking
		@MatchId = @MatchId
		,@Action = @Action
		,@Mode = 'CAL'
		,@ErrCode = @ErrCode OUTPUT
		,@ErrMsg = @ErrMsg OUTPUT
	IF @ErrCode <> 0
	BEGIN
		SELECT @ErrCode
			,@ErrMsg
		
		RETURN
	END

	SELECT @ErrCode		= 0
		,@ErrMsg		= ''
		,@procName		= OBJECT_NAME(@@procid)
		,@sqlCommand	= 'EXEC [dbo].[NAP_Admin_Settlement_1] @matchid = ' + CONVERT(NVARCHAR(50), @MatchId) 
														  + ', @creator = ' + CONVERT(NVARCHAR(50), @AdminId) 
														  + ', @fth = ' + ISNULL(CONVERT(NVARCHAR(50), @FullTimeHome), 'NULL') 
														  + ', @fta = ' + ISNULL(CONVERT(NVARCHAR(50), @FullTimeAway), 'NULL') 
														  + ', @hth = ' + ISNULL(CONVERT(NVARCHAR(50), @HalfTimeHome), 'NULL') 
														  + ', @hta = ' + ISNULL(CONVERT(NVARCHAR(50), @HalfTimeAway), 'NULL') 
														  + ', @goalrecord = ' + CASE WHEN @GoalRecord IS NULL THEN 'NULL'
																					  ELSE '''' + CONVERT(NVARCHAR(50), @GoalRecord) + '''' END 
														  + ', @betstatus = ' + CASE WHEN @BetStatus IS NULL THEN 'NULL' 
																					 ELSE 'N''' + CONVERT(NVARCHAR(50), @BetStatus) + '''' END 
														  + ', @SetResult = ' + CASE WHEN @SetResult IS NULL THEN 'NULL'
																					 ELSE '''' + @SetResult + '''' END 
														  + ', @GameResult1 = ' + CASE WHEN @GameResult1 IS NULL THEN 'NULL'
																					   ELSE '''' + @GameResult1 + '''' END 
														  + ', @GameResult2 = ' + CASE WHEN @GameResult2 IS NULL THEN 'NULL'	
																					   ELSE '''' + @GameResult2+ '''' END 
														  + ', @GameResult3 = ' + CASE WHEN @GameResult3 IS NULL THEN 'NULL'	
																					   ELSE '''' + @GameResult3+ '''' END  
														  + ', @GameResult4 = ' + CASE WHEN @GameResult4 IS NULL THEN 'NULL'	
																					   ELSE '''' + @GameResult4+ '''' END 
														  + ', @GameResult5 = ' + CASE WHEN @GameResult5 IS NULL THEN 'NULL'	
																					   ELSE '''' + @GameResult5+ '''' END 
														  + ', @SelectedSet = ' + CASE WHEN @SelectedSet IS NULL THEN 'NULL'	
																					   ELSE '''' + @SelectedSet+ '''' END 
														  + ', @SelectedSet1Game = ' + CASE WHEN @SelectedSet1Game IS NULL THEN 'NULL'	
																					   ELSE '''' + @SelectedSet1Game+ '''' END 
														  + ', @SelectedSet2Game = ' + CASE WHEN @SelectedSet2Game IS NULL THEN 'NULL'	
																					   ELSE '''' + @SelectedSet2Game+ '''' END
														  + ', @SelectedSet3Game = ' + CASE WHEN @SelectedSet3Game IS NULL THEN 'NULL'	
																					   ELSE '''' + @SelectedSet3Game+ '''' END 
														  + ', @SelectedSet4Game = ' + CASE WHEN @SelectedSet4Game IS NULL THEN 'NULL'	
																					   ELSE '''' + @SelectedSet4Game+ '''' END 
														  + ', @SelectedSet5Game = ' + CASE WHEN @SelectedSet5Game IS NULL THEN 'NULL'	
																					   ELSE '''' + @SelectedSet5Game+ '''' END  

														  + ', @fthCorners = ' + ISNULL(CONVERT(NVARCHAR(50), @fthCorners), 'NULL') 
														  + ', @ftaCorners = ' + ISNULL(CONVERT(NVARCHAR(50), @ftaCorners), 'NULL') 
														  + ', @hthCorners = ' + ISNULL(CONVERT(NVARCHAR(50), @hthCorners), 'NULL') 
														  + ', @htaCorners = ' + ISNULL(CONVERT(NVARCHAR(50), @htaCorners), 'NULL') 
														  + ', @FTFCorner = ' + CASE WHEN @FTFCorner IS NULL THEN 'NULL'	
																					   ELSE '''' + @FTFCorner + '''' END 
														  + ', @FTLCorner = ' + CASE WHEN @FTLCorner IS NULL THEN 'NULL'	
																						   ELSE '''' + @FTLCorner + '''' END 
														  + ', @HTFCorner = ' + CASE WHEN @HTFCorner IS NULL THEN 'NULL'	
																						   ELSE '''' + @HTFCorner + '''' END 
														  + ', @HTLCorner = ' + CASE WHEN @HTLCorner IS NULL THEN 'NULL'	
																						   ELSE '''' + @HTLCorner+ '''' END 

														  + ', @action = ''' + CONVERT(NVARCHAR(50), @Action) + '''' 
														  + ', @IP = ''' + CONVERT(NVARCHAR(50), @IP) + '''' 
														  + ', @ErrCode = @ErrCode OUTPUT' 
														  + ', @ErrMsg = @ErrMsg OUTPUT'
														  
	IF LEN(@sqlCommand)> 1000 --Max Field 
	BEGIN
		SELECT   @ErrCode = 1001010
				,@ErrMsg  = 'There are too many inputted results to proceed at one time. Please select each one to execute separately.'	
		RETURN 
	END

	IF (@SelectedSet IS NOT NULL AND @SelectedSet NOT LIKE '%6%')   -- Tennis 
	BEGIN
		SELECT @Action='CAL-SET'	-- CAL per SET of Tennis 		
	END 

	IF (@procName LIKE '%_xtest' OR @procName LIKE '%_xpre') 
	BEGIN
		DECLARE @ActionId INT

		BEGIN TRY
			EXEC sys.sp_executesql @sqlCommand
				,N'@ErrMsg VARCHAR(400) OUTPUT, @ErrCode int OUTPUT'
				,@ErrMsg	= @ErrMsg OUTPUT
				,@ErrCode	= @ErrCode OUTPUT
		END TRY

		BEGIN CATCH
			SELECT @ErrMsg	= @ErrMsg + ISNULL(ERROR_MESSAGE(), '')
				,@ErrCode	= @@error

			RETURN
		END CATCH

		SELECT @ActionId = CASE 
								WHEN @Action = 'CAL-HT' THEN 2
								WHEN @Action = 'CAL-FT' THEN 3
								WHEN @Action = 'CAL' THEN 4
								WHEN @Action = 'UNDO' THEN 0
								ELSE - 1
						   END
			,@FullTimeHome 	= m.finalhomescore
			,@FullTimeAway 	= m.finalawayscore
			,@HalfTimeHome 	= m.hthomescore
			,@HalfTimeAway 	= m.htawayscore
			,@GoalRecord	= m.GoalRecord
			,@BetStatus		= m.betstatus
			,@sporttype		= sporttype
		FROM DBPRO.BODB02.dbo.match m WITH (NOLOCK)
		WHERE m.matchid = @MatchId

		IF @ActionId <> - 1
		BEGIN
			EXEC Acc_Set_ConfirmedAction 
				@matchid 		= @MatchId
				,@action 		= @ActionId
				,@fth 			= @FullTimeHome
				,@fta 			= @FullTimeAway
				,@hth 			= @HalfTimeHome
				,@hta 			= @HalfTimeAway
				,@goalrecord	= @GoalRecord
				,@betstatus		= @BetStatus
		END
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
			,@Action
			,@sqlCommand
	END
END

GO
GRANT EXECUTE ON [dbo].[NAP_Admin_Settlement_1_Push] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Admin_Settlement_1_Push] TO [vnteam] AS [dbo]