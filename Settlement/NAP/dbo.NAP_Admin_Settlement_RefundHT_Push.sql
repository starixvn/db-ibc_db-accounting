/****** Object:  StoredProcedure [dbo].[NAP_Admin_Settlement_RefundHT_Push_xtest]    Script Date: 09/11/2014 17:19:28 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[NAP_Admin_Settlement_RefundHT_Push] 
	@MatchId						INT
	,@AdminId						INT
	,@IsExcludeBetdaq				BIT 			= 0
	,@IsSettleAbandonedMatch		BIT 			= 0
	,@IsExcludeBetfair				BIT 			= 0
	,@IsSettleAbandonedMatchBetFair BIT 			= 0
	,@HalfTimeHome					INT 			= NULL
	,@HalfTimeAway					INT 			= NULL
	,@IP							VARCHAR(15)		= ''
	,@ErrCode						INT				= 0		OUTPUT
	,@ErrMsg						NVARCHAR(200)	= ''	OUTPUT
AS
/*
	Created: 20130213@Kathy
	Task : Refund Half-time in case there are HT tickets bet on special matches that have 3 sets
	DB: DBTXN/BODB02

	Revisions:
		- 20140506@Kathy: Don't allow to calculate exists matches in queue
		- 20140825@Kathy: Support 1H FGLG (127) for Apollo [Redmine:#16276]
	
	Param's Explanation:
	• @matchid: matchid of match to Refund HT
	• @IsExcludeBetdaq: Is Exclude betdaq tickets or not
	• @IsSettleAbandonedMatch: Is Settlement for Betdaq ticket of Abandoned/postponed match or not
	• @IsExcludeBetfair: Is Exclude betfair tickets or not
	• @IsSettleAbandonedMatchBetFair: Is Settlement for Betfair ticket of Abandoned/postponed match or not

*/
BEGIN
	SET NOCOUNT ON

	DECLARE @matchcode	NVARCHAR(50)
		,@sporttype		INT
		,@leagueid		INT
		,@sqlCommand	NVARCHAR(500)
		,@procName		NVARCHAR(50)

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
		,@sqlCommand	= 'EXEC [dbo].[NAP_Admin_Settlement_RefundHT] @matchid = ' + CONVERT(NVARCHAR(50), @MatchId) 
																 + ', @adminid = ' + CONVERT(NVARCHAR(50), @AdminId) 
																 + ', @IsExcludeBetdaq = ' + CONVERT(NVARCHAR(1), @IsExcludeBetdaq) 
																 + ', @IsSettleAbandonedMatch = ' + CONVERT(NVARCHAR(1), @IsSettleAbandonedMatch) 
																 + ', @IsExcludeBetfair = ' + CONVERT(NVARCHAR(1), @IsExcludeBetfair) 
																 + ', @IsSettleAbandonedMatchBetFair = ' + CONVERT(NVARCHAR(1), @IsSettleAbandonedMatchBetFair) 
																 + ', @hth = ' + ISNULL(CONVERT(NVARCHAR(50), @HalfTimeHome), 'NULL') 
																 + ', @hta = ' + ISNULL(CONVERT(NVARCHAR(50), @HalfTimeAway), 'NULL') 
																 + ', @IP = ''' + CONVERT(NVARCHAR(50), @IP) + '''' 
																 + ', @ErrCode = @ErrCode OUTPUT' 
																 + ', @ErrMsg = @ErrMsg OUTPUT'

	IF @procName LIKE '%_xtest'	OR @procName LIKE '%_xpre'
	BEGIN
		DECLARE @fth		SMALLINT
			,@fta			SMALLINT
			,@hth			SMALLINT
			,@hta			SMALLINT
			,@GoalRecord	VARCHAR(50)
			,@BetStatus		NVARCHAR(50)

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

		SELECT @fth			= m.finalhomescore
			,@fta 			= m.finalawayscore
			,@hth 			= m.hthomescore
			,@hta 			= m.htawayscore
			,@GoalRecord	= m.GoalRecord
			,@BetStatus		= m.betstatus
		FROM DBPRO.BODB02.dbo.match m WITH (NOLOCK)
		WHERE m.matchid = @MatchId

		EXEC Acc_Set_ConfirmedAction 
			@matchid 		= @MatchId
			,@action 		= 11
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
			,'Refund-HT'
			,@sqlCommand
	END
END
GO

GRANT EXECUTE ON [dbo].[NAP_Admin_Settlement_RefundHT_Push_xtest] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[NAP_Admin_Settlement_RefundHT_Push_xtest] TO [vnteam] AS [dbo]
