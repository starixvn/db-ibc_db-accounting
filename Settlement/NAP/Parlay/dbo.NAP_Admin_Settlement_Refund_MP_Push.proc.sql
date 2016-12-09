ALTER PROCEDURE [dbo].[NAP_Admin_Settlement_Refund_MP_Push] (
	@AdminId 						INT
	,@MatchId 						INT
	,@Action 						VARCHAR(20) = 'REFUND'
	,@IsSettleAbandonedMatchIBC     BIT	= 0
	,@IP 							VARCHAR(15) = ''
	,@ErrCode 						INT = 0 OUTPUT
	,@ErrMsg NVARCHAR(200) 			= '' OUTPUT
)
AS
/*	Creator: 20161205@Bobby
	Task: #61352 - Implement SDT for parlay tickets
	DB: DBTXN/BODB02
	ORIGINAL:

	Revisions:		

	Param's Explanation:		
		- @Action: [Refund, Refund-FT]
*/
BEGIN
	SET NOCOUNT ON

    DECLARE @matchcode			NVARCHAR(50)
		,@sporttype     		INT
		,@leagueid      		INT		
		,@IsNested      		BIT
		,@ActionId        		INT
		,@procName      		NVARCHAR(50)
		,@sqlCommand			NVARCHAR(1000)
		,@IsExistNetPosition	BIT = 0
		,@Mode					VARCHAR(20)

	SELECT @ActionId		= CASE WHEN @Action = 'REFUND' THEN 107 ELSE 106 END
		, @Mode				= CASE 
								WHEN @Action = 'REFUND' AND @IsSettleAbandonedMatchIBC =  1 THEN 'ABANDONED-1H'
								WHEN @Action = 'REFUND-FT' AND @IsSettleAbandonedMatchIBC =  1 THEN 'ABANDONED-2H'
								ELSE @Action
							END
	
    SELECT	@matchcode    	= m.matchcode
			,@sporttype   	= m.sporttype
			,@leagueid    	= m.leagueid
    FROM	DBPRO.bodb02.dbo.match m WITH (NOLOCK)
    WHERE	m.matchid = @MatchId

    -- CHECK supported actions & sport type
	IF(@Mode NOT IN ('REFUND', 'REFUND-HT','REFUND-FT','ABANDONED-1H','ABANDONED-2H') OR @sporttype IS NULL)
    BEGIN
        SELECT	@ErrCode = 1001001
				,@ErrMsg    = 'The match or action is invalid!'

        RETURN
    END

    IF EXISTS (
            SELECT	1
            FROM	dbo.Single_Calculate_Queue WITH (NOLOCK)
            WHERE	matchid = @matchid
					AND IsCalculating IN (0, 1)
            )

        OR EXISTS (
            SELECT	1
            FROM	dbo.Parlay_Calculate_Queue WITH (NOLOCK)
            WHERE	matchid = @matchid
					AND IsCalculating IN (0, 1)
            )
    BEGIN
        SELECT @ErrCode = 1001003
            ,@ErrMsg    = 'This match is being calculated, please wait a few seconds until the on-going process is completed and try again.'

        RETURN
    END
	
	IF @procName LIKE '%_xtest' or @procName LIKE '%_xpre' OR @procName LIKE '%_UAT_' -- UAT1 -->UAT9
	BEGIN
		BEGIN TRY
			EXEC [NAP_Admin_Settlement_Refund_MP] @matchid = @matchid
				,@creator 	= @AdminId
				,@action 	= @mode
				,@IP 		= @IP
				,@ErrCode 	= @ErrCode OUTPUT
				,@ErrMsg 	= @ErrMsg OUTPUT
		END TRY

		BEGIN CATCH
			SET @ErrMsg = ERROR_MESSAGE()
		END CATCH
	END
	ELSE
	BEGIN		
		INSERT INTO dbo.Parlay_Calculate_Queue (matchid, isCalculating, creator, ip, starttime, action, ActionId)
		SELECT @matchid, 0, @AdminId, @IP, CURRENT_TIMESTAMP, @mode, @ActionId
	END
END
GO 
 GRANT EXECUTE ON [dbo].[NAP_Admin_Settlement_Refund_MP_Push] TO [bodbAdminNet]
GO 
 GRANT VIEW DEFINITION ON [dbo].[NAP_Admin_Settlement_Refund_MP_Push] TO [vnteam]
GO 
