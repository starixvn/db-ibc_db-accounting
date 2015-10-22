USE [bodb02]
GO

ALTER PROCEDURE [dbo].[NAP_Admin_Settlement_Refund_All_Push] 
    @Matchid                        INT
    ,@AdminId                        INT
    ,@IsExcludeBetdaq                BIT                = 0
    ,@IsSettleAbandonedMatch        BIT                = 0
    ,@IsExcludeBetfair                BIT                = 0
    ,@IsSettleAbandonedMatchBetFair BIT             = 0
    ,@IsSettleAbandonedMatchIBC        BIT             = 0
    ,@HalfTimeHome                    INT             = NULL
    ,@HalfTimeAway                    INT             = NULL
    ,@FullTimeHome                    INT             = NULL
    ,@FullTimeAway                    INT             = NULL
    ,@GoalSequence                    VARCHAR(50)        = NULL 
    ,@fthCorners                    SMALLINT        = NULL
    ,@ftaCorners                    SMALLINT        = NULL
    ,@hthCorners                    SMALLINT        = NULL
    ,@htaCorners                    SMALLINT        = NULL 
    ,@FTFCorner                        VARCHAR(1)        = NULL
    ,@HTFCorner                        VARCHAR(1)        = NULL
    ,@BetStatus                        NVARCHAR(50)    = NULL
    ,@SetResult                        VARCHAR(50)        = NULL 
    ,@GameResult1                    VARCHAR(MAX)    = NULL
    ,@GameResult2                    VARCHAR(MAX)    = NULL
    ,@GameResult3                    VARCHAR(MAX)    = NULL
    ,@GameResult4                    VARCHAR(MAX)    = NULL
    ,@GameResult5                    VARCHAR(MAX)    = NULL
    ,@SelectedSet                    VARCHAR(50)        = NULL 
    ,@SelectedSet1Game                VARCHAR(MAX)    = NULL 
    ,@SelectedSet2Game                VARCHAR(MAX)    = NULL 
    ,@SelectedSet3Game                VARCHAR(MAX)    = NULL 
    ,@SelectedSet4Game                VARCHAR(MAX)    = NULL 
    ,@SelectedSet5Game                VARCHAR(MAX)    = NULL
    ,@SelectedSettleFinishedGame    VARCHAR(50)        = NULL 
    ,@isExistTotalCorner            BIT                = 0 
    ,@isExistHTFCorner                BIT                = 0 
    ,@isExistHTLCorner                BIT                = 0 
    ,@isExistFTFCorner                BIT                = 0 
    ,@isExistFTLCorner                BIT                = 0 
    ,@IP                            VARCHAR(15)        = ''
    ,@ErrCode                        INT                = 0        OUTPUT
    ,@ErrMsg                        NVARCHAR(200)    = ''    OUTPUT
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
        - 20150401@Kathy: Add checking ticket status before performing settlement [Redmine:#33493]
        - 20150414@Jamie: Manual Settlement Betradar phase 2 [Redmine: #27212]
        - 20151005@Kathy: add more UAT version for testing (UAT1,UAT2,UAT3,UAT4)

    Param's Explanation:
    • @matchid: matchid need to refund
    • @IsExcludeBetdaq: Is Exclude betdaq tickets or not
    • @IsSettleAbandonedMatch: Is Settlement for Abandoned/postponed match or not
    • @IsExcludeBetfair: Is Exclude betfair tickets or not
    • @IsSettleAbandonedMatchBetFair: Is Settlement for Betfair ticket of Abandoned/postponed match or not
    * List of BetDaq Customers 
                custid    --- username    -    roleid
                50057    ---    BQUS888        -    1
                879241    ---    BQUSMLB        -    1
                103873    ---    BQUSNBA        -    1
                78761    ---    ITibc101    -    1
                1688156    ---    MTEST0101    -    2
                851668  --- BDUS01      -   1
                878902  --- BDUS016     -   1
    * List of Betfair Customers 
                custid    --- username    -    roleid
                2331    ---    BF            -    1
                1077687    ---    BFOS        -    1
    * @isExistTotalCorner: = 1 When existing tickets or result details of corners bettypes 

*/
BEGIN
    SET NOCOUNT ON

    DECLARE @matchcode    NVARCHAR(50)
        ,@sporttype        INT
        ,@leagueid        INT
        ,@sqlCommand    NVARCHAR(MAX)
        ,@IsNested        BIT
        ,@Action        VARCHAR(20)
        ,@procName        NVARCHAR(50)

    SELECT @matchcode    = m.matchcode
        ,@sporttype        = m.sporttype
        ,@leagueid        = m.leagueid
        ,@IsNested        = 0
        ,@Action        = 'CAL'
    FROM DBPRO.bodb02.dbo.match m WITH (NOLOCK)
    WHERE m.matchid = @MatchId

    IF @@ROWCOUNT = 0
    BEGIN
        SELECT @ErrCode = 1001001
            ,@ErrMsg    = 'Match does not exist!'

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
            ,@ErrMsg    = 'This match is being calculated, please wait a few seconds until the on-going process is completed and try again.'

        RETURN
    END

    -- check waiting ticket
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                EXEC NAP_Admin_Settlement_Checking
        @MatchId = @MatchId
        ,@Action = 'REFUND'
        ,@Mode = 'REFUND'
        ,@ErrCode = @ErrCode OUTPUT
        ,@ErrMsg = @ErrMsg OUTPUT
    IF @ErrCode <> 0
    BEGIN
        SELECT @ErrCode
            ,@ErrMsg
        
        RETURN
    END
    
    SELECT @ErrCode        = 0
        ,@ErrMsg        = ''
        ,@procName        = OBJECT_NAME(@@procid)
        ,@sqlCommand    = 'EXEC [dbo].[NAP_Admin_Settlement_Refund_All] @Matchid = ' + CONVERT(NVARCHAR(50), @MatchId) 
                                                                  + ', @creator = ' + CONVERT(NVARCHAR(50), @AdminId) 
                                                                  + ', @IsExcludeBetdaq = ' + CONVERT(NVARCHAR(1), @IsExcludeBetdaq) 
                                                                  + ', @IsSettleAbandonedMatch = ' + CONVERT(NVARCHAR(1), @IsSettleAbandonedMatch) 
                                                                  + ', @IsExcludeBetfair = ' + CONVERT(NVARCHAR(1), @IsExcludeBetfair) 
                                                                  + ', @IsSettleAbandonedMatchBetFair = ' + CONVERT(NVARCHAR(1), @IsSettleAbandonedMatchBetFair) 
                                                                  + ', @IsSettleAbandonedMatchIBC = ' + CONVERT(NVARCHAR(1), @IsSettleAbandonedMatchIBC) 
                                                                 
                                                                  + ', @betstatus = ' + CASE WHEN @BetStatus IS NULL THEN 'NULL' ELSE 'N''' + CONVERT(NVARCHAR(20), @BetStatus) + '''' END 
                                                                  + ', @SetResult = ' + CASE WHEN @SetResult IS NULL THEN 'NULL' ELSE '''' + @SetResult + '''' END
                                                                  + ', @GameResult1 = ' + CASE WHEN @GameResult1 IS NULL THEN 'NULL' ELSE '''' + @GameResult1 + '''' END
                                                                  + ', @GameResult2 = ' + CASE WHEN @GameResult2 IS NULL THEN 'NULL' ELSE '''' + @GameResult2 + '''' END
                                                                  + ', @GameResult3 = ' + CASE WHEN @GameResult3 IS NULL THEN 'NULL' ELSE '''' + @GameResult3 + '''' END
                                                                  + ', @GameResult4 = ' + CASE WHEN @GameResult4 IS NULL THEN 'NULL' ELSE '''' + @GameResult4 + '''' END
                                                                  + ', @GameResult5 = ' + CASE WHEN @GameResult5 IS NULL THEN 'NULL' ELSE '''' + @GameResult5 + '''' END
                                                                  + ', @SelectedSet = ' + CASE WHEN @SelectedSet IS NULL THEN 'NULL' ELSE '''' + @SelectedSet + '''' END
                                                                  + ', @SelectedSet1Game = ' + CASE WHEN @SelectedSet1Game IS NULL THEN 'NULL' ELSE '''' + @SelectedSet1Game + '''' END
                                                                  + ', @SelectedSet2Game = ' + CASE WHEN @SelectedSet2Game IS NULL THEN 'NULL' ELSE '''' + @SelectedSet2Game + '''' END
                                                                  + ', @SelectedSet3Game = ' + CASE WHEN @SelectedSet3Game IS NULL THEN 'NULL' ELSE '''' + @SelectedSet3Game + '''' END
                                                                  + ', @SelectedSet4Game = ' + CASE WHEN @SelectedSet4Game IS NULL THEN 'NULL' ELSE '''' + @SelectedSet4Game + '''' END
                                                                  + ', @SelectedSet5Game = ' + CASE WHEN @SelectedSet5Game IS NULL THEN 'NULL' ELSE '''' + @SelectedSet5Game + '''' END
                                                                  + ', @SelectedSettleFinishedGame = ' + CASE WHEN @SelectedSettleFinishedGame IS NULL THEN 'NULL' ELSE '''' + @SelectedSettleFinishedGame + '''' END
                                                                  + ', @fth = ' + ISNULL(CONVERT(NVARCHAR(50), @FullTimeHome), 'NULL') 
                                                                  + ', @fta = ' + ISNULL(CONVERT(NVARCHAR(50), @FullTimeAway), 'NULL') 
                                                                  + ', @hth = ' + ISNULL(CONVERT(NVARCHAR(50), @HalfTimeHome), 'NULL') 
                                                                  + ', @hta = ' + ISNULL(CONVERT(NVARCHAR(50), @HalfTimeAway), 'NULL')
                                                                  + ', @GoalSequence = ' + CASE WHEN @GoalSequence IS NULL THEN 'NULL' ELSE '''' + @GoalSequence + '''' END
                                                                  + ', @fthCorners = ' + ISNULL(CONVERT(NVARCHAR(50), @fthCorners), 'NULL')  
                                                                  + ', @ftaCorners = ' + ISNULL(CONVERT(NVARCHAR(50), @ftaCorners), 'NULL') 
                                                                  + ', @hthCorners = ' + ISNULL(CONVERT(NVARCHAR(50), @hthCorners), 'NULL') 
                                                                  + ', @htaCorners = ' + ISNULL(CONVERT(NVARCHAR(50), @htaCorners), 'NULL') 
                                                                  
                                                                  + ', @FTFCorner = ' + CASE WHEN @HTFCorner IS NULL THEN 'NULL' ELSE '''' + @HTFCorner + '''' END
                                                                  + ', @HTFCorner = ' + CASE WHEN @HTFCorner IS NULL THEN 'NULL' ELSE '''' + @HTFCorner + '''' END
                                                                  + ', @isExistTotalCorner = ' + CONVERT(NVARCHAR(1), @isExistTotalCorner)
                                                                  + ', @isExistHTFCorner = ' + CONVERT(NVARCHAR(1), @isExistHTFCorner)
                                                                  + ', @isExistHTLCorner = ' + CONVERT(NVARCHAR(1), @isExistHTLCorner)
                                                                  + ', @isExistFTFCorner = ' + CONVERT(NVARCHAR(1), @isExistFTFCorner)
                                                                  + ', @isExistFTLCorner = ' + CONVERT(NVARCHAR(1), @isExistFTLCorner)

                                                                  + ', @Action = ''' + CONVERT(NVARCHAR(20), @Action) + '''' 
                                                                  + ', @IsNested = ''' + CONVERT(NVARCHAR(1), @IsNested) + '''' 
                                                                  + ', @IP = ''' + CONVERT(NVARCHAR(50), @IP) + '''' 
                                                                  + ', @ErrCode = @ErrCode OUTPUT' 
                                                                  + ', @ErrMsg = @ErrMsg OUTPUT'

    IF LEN(@sqlCommand)> 1000 --Max Field 
    BEGIN
        SELECT   @ErrCode = 1001010
                ,@ErrMsg  = 'There are too many inputted results to proceed at one time. Please select each one to execute separately.'    
        RETURN 
    END

    SELECT    @Action = 'Refund'  -- ALL SPORTS

    IF (@SelectedSet IS NOT NULL AND @SelectedSet NOT LIKE '%6%')   -- Tennis 
    BEGIN
        SELECT @Action='Refund-SET'    -- Refund per SET of Tennis         
    END 

    IF (@procName LIKE '%_xtest' OR @procName LIKE '%_xpre' OR @procName LIKE '%_UAT_') -- UAT1 -->UAT9
    BEGIN
        DECLARE @GoalRecord VARCHAR(50)
        DECLARE @ActionId INT

        BEGIN TRY
            EXEC sys.sp_executesql @sqlCommand
                ,N'@ErrMsg VARCHAR(400) OUTPUT, @ErrCode int OUTPUT'
                ,@ErrMsg    = @ErrMsg    OUTPUT
                ,@ErrCode    = @ErrCode    OUTPUT
        END TRY

        BEGIN CATCH
            SELECT @ErrMsg    = @ErrMsg + ISNULL(ERROR_MESSAGE(), '')
                ,@ErrCode    = @@error

            RETURN
        END CATCH

        SELECT   @ActionId            = CASE WHEN @Action = 'Refund' THEN 13 
                                           ELSE -1 
                                           END
                ,@FullTimeHome        = m.finalhomescore
                ,@FullTimeAway        = m.finalawayscore
                ,@HalfTimeHome        = m.hthomescore
                ,@HalfTimeAway        = m.htawayscore
                ,@GoalRecord        = m.GoalRecord
                ,@BetStatus            = m.betstatus
        FROM DBPRO.BODB02.dbo.match m WITH (NOLOCK)
        WHERE m.matchid = @MatchId

        IF @ActionId <> -1 
        BEGIN
            EXEC Acc_Set_ConfirmedAction 
                @matchid        = @MatchId
                ,@action        = @ActionId
                ,@fth             = @FullTimeHome
                ,@fta             = @FullTimeAway
                ,@hth             = @HalfTimeHome
                ,@hta             = @HalfTimeAway
                ,@goalrecord    = @GoalRecord
                ,@betstatus        = @BetStatus
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
            ,@Action            --'Refund'
            ,@sqlCommand
    END
END
GO
GRANT EXECUTE ON [dbo].[NAP_Admin_Settlement_Refund_All_Push] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Admin_Settlement_Refund_All_Push] TO [vnteam] AS [dbo]