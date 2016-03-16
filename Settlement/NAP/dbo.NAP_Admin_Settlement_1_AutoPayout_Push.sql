USE bodb02
GO

ALTER PROCEDURE [dbo].[NAP_Admin_Settlement_1_AutoPayout_Push] @AdminId INT
    , @MatchId		INT
    , @FullTimeHome	SMALLINT        = NULL
    , @FullTimeAway	SMALLINT        = NULL
    , @HalfTimeHome SMALLINT        = NULL
    , @HalfTimeAway SMALLINT        = NULL 
    , @GoalRecord	VARCHAR(50)     = NULL
    , @BetStatus	NVARCHAR(50)    
    , @Action		VARCHAR(10)     = 'CAL'
    , @IP			VARCHAR(15)     = ''
    , @ErrCode		INT             = 0     OUTPUT
    , @ErrMsg		NVARCHAR(200)   = ''    OUTPUT
AS
/*    
	Creator: 20160311@Patrick
    Task: Auto Payout settlement
    DB: DBTXN/BODB02
	Original:
		NAP_Admin_Settlement_1_AutoPayout

    Revisions:        
    Param's Explanation:
        
*/
BEGIN
    SET NOCOUNT ON

    DECLARE	@matchcode NVARCHAR(50), @sporttype INT, @leagueid INT, @procName NVARCHAR(50), @sqlCommand VARCHAR(1024)
			
    SELECT @matchcode = m.matchcode
		, @sporttype  = m.sporttype
		, @leagueid   = m.leagueid
    FROM DBPRO.bodb02.dbo.match m WITH (NOLOCK)
    WHERE m.matchid = @MatchId

    IF @@ROWCOUNT = 0
    BEGIN
        SELECT @ErrCode = 1001001
			, @ErrMsg   = 'Match does not exist!'

        RETURN
    END

    --IF @action = 'CAL' AND @sporttype = 154 AND (@FullTimeHome = 0 OR @FullTimeHome IS NULL OR @FullTimeAway = 0 OR @FullTimeAway IS NULL)
    --BEGIN
    --    SELECT	@ErrCode = 1001002
				--,@ErrMsg    = 'Score is not valid.'

    --    RETURN
    --END

    IF EXISTS (SELECT TOP 1 1
				FROM dbo.Single_Calculate_Queue WITH (NOLOCK)
				WHERE matchid = @matchid
					AND IsCalculating IN (0, 1))
        OR EXISTS (SELECT TOP 1 1
					FROM dbo.Parlay_Calculate_Queue WITH (NOLOCK)
					WHERE matchid = @matchid
						AND IsCalculating IN (0, 1))
    BEGIN
        SELECT @ErrCode = 1001003
			, @ErrMsg = 'This match is being calculated, please wait a few seconds until the on-going process is completed and try again.'

        RETURN
    END
    
    -- check waiting ticket
	EXEC dbo.NAP_Admin_Settlement_Checking @MatchId	= @MatchId
        , @Action	= @Action
        , @Mode		= 'CAL'
        , @ErrCode	= @ErrCode OUTPUT
        , @ErrMsg	= @ErrMsg OUTPUT
        
    IF @ErrCode <> 0
    BEGIN
        SELECT	@ErrCode
				,@ErrMsg
        
        RETURN
    END

    SELECT @ErrCode = 0, @ErrMsg = '', @procName = OBJECT_NAME(@@PROCID)
		, @sqlCommand = 'EXEC [dbo].[NAP_Admin_Settlement_1_AutoPayout] @matchid = ' + CONVERT(NVARCHAR(50), @MatchId) 
                            + ', @creator = ' + CONVERT(NVARCHAR(50), @AdminId) 
                            + ', @fth = ' + ISNULL(CONVERT(NVARCHAR(50), @FullTimeHome), 'NULL') 
                            + ', @fta = ' + ISNULL(CONVERT(NVARCHAR(50), @FullTimeAway), 'NULL') 
                            + ', @hth = ' + ISNULL(CONVERT(NVARCHAR(50), @HalfTimeHome), 'NULL') 
                            + ', @hta = ' + ISNULL(CONVERT(NVARCHAR(50), @HalfTimeAway), 'NULL') 
                            + ', @goalrecord = ' + CASE WHEN @GoalRecord IS NULL THEN 'NULL'
                                                        ELSE '''' + CONVERT(NVARCHAR(50), @GoalRecord) + '''' END 
                            + ', @betstatus = ' + CASE WHEN @BetStatus IS NULL THEN 'NULL' 
                                                        ELSE 'N''' + CONVERT(NVARCHAR(50), @BetStatus) + '''' END 
                            + ', @action = ''' + CONVERT(NVARCHAR(50), @Action) + '''' 
                            + ', @IP = ''' + CONVERT(NVARCHAR(50), @IP) + '''' 
                            + ', @ErrCode = @ErrCode OUTPUT' 
                            + ', @ErrMsg = @ErrMsg OUTPUT'
                                                          
    IF LEN(@sqlCommand)> 1000 --Max Field 
    BEGIN
        SELECT @ErrCode = 1001010
			, @ErrMsg  = 'There are too many inputted results to proceed at one time. Please select each one to execute separately.'    
        RETURN 
    END

    IF @procName LIKE '%_xtest' OR @procName LIKE '%_xpre' OR @procName LIKE '%_UAT_' -- UAT1 -->UAT9
    BEGIN
        DECLARE	@ActionId INT

        BEGIN TRY
            EXEC sys.sp_executesql @sqlCommand, N'@ErrMsg VARCHAR(400) OUTPUT, @ErrCode int OUTPUT'
                , @ErrMsg	= @ErrMsg OUTPUT
                , @ErrCode	= @ErrCode OUTPUT
        END TRY

        BEGIN CATCH
            SELECT @ErrMsg = @ErrMsg + ISNULL(ERROR_MESSAGE(), ''), @ErrCode = @@ERROR

            RETURN
        END CATCH

    --    SELECT @ActionId = CASE WHEN @Action = 'CAL-HT' THEN 2
    --                            WHEN @Action = 'CAL-FT' THEN 3
    --                            WHEN @Action = 'CAL' THEN 4
    --                            WHEN @Action = 'UNDO' THEN 0
    --                            ELSE - 1
				--				END
				--,@FullTimeHome     = m.finalhomescore
				--,@FullTimeAway     = m.finalawayscore
				--,@HalfTimeHome     = m.hthomescore
				--,@HalfTimeAway     = m.htawayscore
				--,@GoalRecord    = m.GoalRecord
				--,@BetStatus        = m.betstatus
				--,@sporttype        = sporttype
    --    FROM	DBPRO.BODB02.dbo.match m WITH (NOLOCK)
    --    WHERE	m.matchid = @MatchId

        --IF @ActionId <> - 1
        --BEGIN
        --    EXEC Acc_Set_ConfirmedAction 
        --        @matchid		= @MatchId
        --        ,@action		= @ActionId
        --        ,@fth			= @FullTimeHome
        --        ,@fta			= @FullTimeAway
        --        ,@hth			= @HalfTimeHome
        --        ,@hta			= @HalfTimeAway
        --        ,@goalrecord	= @GoalRecord
        --        ,@betstatus		= @BetStatus
        --END --check for sure
    END
    ELSE
    BEGIN
        INSERT INTO dbo.Single_Calculate_Queue (matchid, matchcode, IsCalculating, LeagueID, SportType
			, AdminId, IP, Action, sqlCommand, execTime)
        SELECT @MatchId, @matchcode, 0 AS IsCalculating, @leagueid, @sporttype
			, @AdminId, @IP, @Action, @sqlCommand, NULL
    END
END

GO
GRANT EXECUTE ON [dbo].[NAP_Admin_Settlement_1_AutoPayout_Push] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Admin_Settlement_1_AutoPayout_Push] TO [vnteam] AS [dbo]
