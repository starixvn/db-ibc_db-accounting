/****** Object:  StoredProcedure [dbo].[NAP_Admin_Settlement_1_Push]    Script Date: 09/11/2014 16:54:44 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[NAP_Admin_Settlement_1_Push] 
	@AdminId		INT
	,@Matchid		INT
	,@FullTimeHome	SMALLINT		= NULL
	,@FullTimeAway	SMALLINT		= NULL
	,@HalfTimeHome	SMALLINT
	,@HalfTimeAway	SMALLINT
	,@GoalRecord	VARCHAR(50)		= NULL
	,@BetStatus		NVARCHAR(50)
	,@Action		VARCHAR(10)		= 'CAL'
	,@IP			VARCHAR(15)		= ''
	,@ErrCode		INT				= 0		OUTPUT
	,@ErrMsg		NVARCHAR(200)	= ''	OUTPUT
AS
/*	Creator: Kathy
	Date: 20140213
	Task: SP for settlement
	DB: DBTXN/BODB02

	Revisions:		
		- 20140506@Kathy: Don't allow to calculate exists matches in queue
		- 20140825@Kathy: Support 1H FGLG (127) for Apollo [Redmine:#16276]
		
	Param's Explanation:

		
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @matchcode			NVARCHAR(50)
		,@sporttype				INT
		,@leagueid				INT
		,@sqlCommand			NVARCHAR(500)
		,@NextAllowSettleTime	DATETIME
		,@procName				NVARCHAR(50)

	SELECT @matchcode	= m.matchcode
		,@sporttype		= m.sporttype
		,@leagueid		= m.leagueid
	FROM DBPRO.bodb02.dbo.match m WITH (NOLOCK)
	WHERE m.matchid = @MatchId

	IF @@ROWCOUNT = 0
	BEGIN
		SELECT @ErrCode = 1000001
			,@ErrMsg	= 'Match does not exist!'

		RETURN
	END

	IF @action = 'CAL' AND @sporttype = 154 AND (@FullTimeHome = 0 OR @FullTimeHome IS NULL OR @FullTimeAway = 0 OR @FullTimeAway IS NULL)
	BEGIN
		SELECT @ErrCode = 1000002
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
		SELECT @ErrCode = 1000000
			,@ErrMsg	= 'This match is being calculated, please wait a few seconds until the on-going process is completed and try again.'

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
														  + ', @goalrecord = ' + CASE 
																					WHEN @GoalRecord IS NULL THEN 'NULL'
																					ELSE '''' + CONVERT(NVARCHAR(50), @GoalRecord) + ''''
																					END 
														  + ', @betstatus = ' + CASE 
																					WHEN @BetStatus IS NULL THEN 'NULL'
																					ELSE 'N''' + CONVERT(NVARCHAR(50), @BetStatus) + ''''
																				 END 
														  + ', @action = ''' + CONVERT(NVARCHAR(50), @Action) + '''' 
														  + ', @IP = ''' + CONVERT(NVARCHAR(50), @IP) + '''' 
														  + ', @ErrCode = @ErrCode OUTPUT' 
														  + ', @ErrMsg = @ErrMsg OUTPUT'

	IF @procName LIKE '%_xtest' OR @procName LIKE '%_xpre'
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
