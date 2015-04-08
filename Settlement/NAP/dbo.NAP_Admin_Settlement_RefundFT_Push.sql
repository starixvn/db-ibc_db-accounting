USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[NAP_Admin_Settlement_RefundFT_Push]    Script Date: 04/02/2015 13:33:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[NAP_Admin_Settlement_RefundFT_Push] 
	@MatchId						INT
	,@AdminId						INT
	,@IsExcludeBetdaq				BIT 			= 0
	,@IsSettleAbandonedMatch		BIT 			= 0
	,@IsExcludeBetfair				BIT 			= 0
	,@IsSettleAbandonedMatchBetFair BIT 			= 0
	,@IsSettleAbandonedMatchIBC		BIT 			= 0
	,@FullTimeHome					INT 			= NULL
	,@FullTimeAway					INT 			= NULL
	,@BetStatus						NVARCHAR(50)	= NULL
	,@IP							VARCHAR(15)		= ''
	,@ErrCode						INT				= 0		OUTPUT
	,@ErrMsg						NVARCHAR(200)	= ''	OUTPUT
AS
/*
	Created: 20140213@Kathy
	Task : Refund Full-time tickets
	DB: DBTXN/BODB02
	Original: 
	
	Revisions:
		- 20140304@Kathy: Execute settlement for abandoned/postponed matches- Clean Sheet, Both/One/Neither team to score, To Win To Nil 
		- 20140506@Kathy: Don't allow to calculate exists matches in queue
		- 20140825@Kathy: Support 1H FGLG (127) for Apollo [Redmine:#16276]
		- 20150401@Kathy: Add checking ticket status before performing settlement [Redmine:#33493]

	Param's Explanation:
	• @matchid: matchid of match to Refund HT
	• @IsSettleAbandonedMatch: Is Settlement for Abandoned/postponed match or not
	• @IsSettleAbandonedMatchBetFair: Is Settlement for Betfair ticket of Abandoned/postponed match or not

*/
BEGIN
	SET NOCOUNT ON

	DECLARE @matchcode	NVARCHAR(50)
		,@sporttype		INT
		,@leagueid		INT
		,@sqlCommand	NVARCHAR(500)
		,@procName		NVARCHAR(50)
		,@Action		VARCHAR(10)

	SELECT @matchcode	= m.matchcode
		,@sporttype		= m.sporttype
		,@leagueid		= m.leagueid
		,@Action		= 'REFUND-FT'
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
		SELECT @ErrCode = 1000003
			,@ErrMsg	= 'This match is being calculated, please wait a few seconds until the on-going process is completed and try again.'

		RETURN
	END
	
	-- check waiting ticket
	EXEC NAP_Admin_Settlement_Checking
		@MatchId = @MatchId
		,@Action = @Action
		,@Mode = 'REFUND'
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
		,@sqlCommand	= 'EXEC [dbo].[NAP_Admin_Settlement_RefundFT] @matchid = ' + CONVERT(NVARCHAR(50), @MatchId) 
																 + ', @adminid = ' + CONVERT(NVARCHAR(50), @AdminId) 
																 + ', @IsExcludeBetdaq = ' + CONVERT(NVARCHAR(1), @IsExcludeBetdaq) 
																 + ', @IsSettleAbandonedMatch = ' + CONVERT(NVARCHAR(1), @IsSettleAbandonedMatch) 
																 + ', @IsExcludeBetfair = ' + CONVERT(NVARCHAR(1), @IsExcludeBetfair) 
																 + ', @IsSettleAbandonedMatchBetFair = ' + CONVERT(NVARCHAR(1), @IsSettleAbandonedMatchBetFair) 
																 + ', @IsSettleAbandonedMatchIBC = ' + CONVERT(NVARCHAR(1), @IsSettleAbandonedMatchIBC) 
																 + ', @fth = ' + ISNULL(CONVERT(NVARCHAR(50), @FullTimeHome), 'NULL') 
																 + ', @fta = ' + ISNULL(CONVERT(NVARCHAR(50), @FullTimeAway), 'NULL') 
																 + ', @betstatus = ' + CASE 
																							WHEN @BetStatus IS NULL THEN 'NULL'
																							ELSE 'N''' + CONVERT(NVARCHAR(20), @BetStatus) + ''''
																					    END 
																 + ', @IP = ''' + CONVERT(NVARCHAR(50), @IP) + '''' 
																 + ', @ErrCode = @ErrCode OUTPUT' 
																 + ', @ErrMsg = @ErrMsg OUTPUT'

	IF @procName LIKE '%_xtest' OR @procName LIKE '%_xpre'
	BEGIN
		DECLARE @fth		SMALLINT
			,@fta 			SMALLINT
			,@hth 			SMALLINT
			,@hta 			SMALLINT
			,@GoalRecord	VARCHAR(50)

		BEGIN TRY
			EXEC sys.sp_executesql @sqlCommand
				,N'@ErrMsg VARCHAR(400) OUTPUT, @ErrCode int OUTPUT'
				,@ErrMsg	= @ErrMsg	OUTPUT
				,@ErrCode	= @ErrCode	OUTPUT
		END TRY

		BEGIN CATCH
			SELECT @ErrMsg	= @ErrMsg + ERROR_MESSAGE()
				,@ErrCode	= @@error


			RETURN
		END CATCH

		SELECT @fth			= m.finalhomescore
			,@fta			= m.finalawayscore
			,@hth			= m.hthomescore
			,@hta			= m.htawayscore
			,@GoalRecord	= m.GoalRecord
			,@BetStatus		= m.betstatus
			,@sporttype		= sporttype
		FROM DBPRO.BODB02.dbo.match m WITH (NOLOCK)
		WHERE m.matchid = @MatchId

		EXEC Acc_Set_ConfirmedAction 
			@matchid 		= @MatchId
			,@action 		= 12
			,@fth 			= @fth
			,@fta 			= @fta
			,@hth 			= @hth
			,@hta 			= @hta
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
			,@Action
			,@sqlCommand
	END
END




GO
GRANT EXECUTE ON [dbo].[NAP_Admin_Settlement_RefundFT_Push] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Admin_Settlement_RefundFT_Push] TO [vnteam] AS [dbo]