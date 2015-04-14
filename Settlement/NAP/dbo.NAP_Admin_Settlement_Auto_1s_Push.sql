ALTER PROCEDURE [dbo].[NAP_Admin_Settlement_Auto_1s_Push]
	 @AdminId			INT				= 148		-- calculated by system (default)
	,@MatchId			INT
	,@ResourceIDs		VARCHAR(MAX)	= '' 
	,@Results			VARCHAR(MAX)	= '' 
	,@IsSettleAbandonedMatchIBC			BIT = 0 
	,@Action			VARCHAR(10)		= 'CAL'
	,@IsAuto			BIT				= 1
	,@IP				VARCHAR(15)		= ''
	,@ErrCode			INT				= 0		OUTPUT
	,@ErrMsg			NVARCHAR(200)	= ''	OUTPUT
AS
/*	Creator: Jamie
	Date: 20150113
	Task: BetRadar Auto/Manual Settlement
	DB: DBTXN/BODB02
	Original: 
	
	Revisions:

	Param's Explanation:
*/		
BEGIN
	SET NOCOUNT ON 

	DECLARE	 @matchcode		NVARCHAR(50)
			,@sporttype		INT
			,@leagueid		INT
			,@sqlCommand	NVARCHAR(500)
			,@procName		NVARCHAR(50)
			,@betstatus		NVARCHAR(50)

	SELECT	 @matchcode		= m.matchcode
			,@sporttype		= m.sporttype
			,@leagueid		= m.leagueid
			,@betstatus		= m.betstatus
	FROM	DBPRO.bodb02.dbo.match m WITH(NOLOCK)
	WHERE	m.matchid = @MatchId

	IF @@ROWCOUNT = 0
	BEGIN
		SELECT	 @ErrCode	= 1001001
				,@ErrMsg	= 'Match does not exist!'

		RETURN
	END

	IF @isAuto = 1 AND( EXISTS(	SELECT	TOP 1 1 
								FROM	DBPRO.bodb02.dbo.ResultDetail WITH (NOLOCK) 
								WHERE	MatchID = @MatchID 
										AND ResourceID IN( SELECT Val FROM dbo.strSplit(@ResourceIDs,',') WHERE ISNULL(@ResourceIDs,'')<>'')	
										AND ResultStatusID = 5				
							)
						OR ISNULL(@ResourceIDs,'')=''
					)
	BEGIN
		SELECT	 @ErrCode	= 1001012
				,@ErrMsg	= 'The auto-settlement failed due to a result that has been settled previously by manual.'

		RETURN
	END

	IF EXISTS (
			SELECT 1
			FROM Single_Calculate_Queue s WITH (NOLOCK)
			WHERE s.matchid = @matchid 
			AND s.IsCalculating IN (0, 1)
			) OR EXISTS (
			SELECT 1
			FROM Parlay_Calculate_Queue p WITH (NOLOCK)
			WHERE p.matchid = @matchid 
			AND p.IsCalculating IN (0, 1)
			)
	BEGIN
		SELECT	 @ErrCode = 1001003
				,@ErrMsg	= 'This match is being calculated, please wait a few seconds until the on-going process is completed and try again.'

		RETURN
	END

	SELECT	 @ErrCode		= 0
			,@ErrMsg		= ''
			,@procName		= OBJECT_NAME(@@procid)
			,@sqlCommand	= 'EXEC [dbo].[NAP_Admin_Settlement_Auto_1s] @Matchid = ' + CONVERT(NVARCHAR(50), @MatchId) 
															+ ', @AdminId = ' + CONVERT(NVARCHAR(50), @AdminId) 
															+ ', @ResourceIDs = ''' + CONVERT(VARCHAR(MAX), @ResourceIDs) + ''''
															+ ', @Results = ''' + CONVERT(VARCHAR(MAX), @Results) + ''''
															+ ', @IsSettleAbandonedMatchIBC = ' + CONVERT(NVARCHAR(50), @IsSettleAbandonedMatchIBC) 	
															+ ', @Action = ''' + CONVERT(NVARCHAR(50), @Action) + '''' 
															+ ', @isAuto = ' + CONVERT(NVARCHAR(50), @isAuto) 														
															+ ', @IP = ''' + CONVERT(VARCHAR(15), @IP) + '''' 
															+ ', @ErrCode = @ErrCode OUTPUT' 
															+ ', @ErrMsg = @ErrMsg OUTPUT'
														
	IF LEN(@sqlCommand)> 1000 --Max Field 
	BEGIN
		SELECT   @ErrCode = 1001010
				,@ErrMsg  = 'There are too many inputted results to proceed at one time. Please select each one to execute separately.'	
		RETURN 
	END
	
	IF @procName LIKE '%_xtest' or @procName LIKE '%_xpre'
	BEGIN
		BEGIN TRY
			EXEC sys.sp_executesql @sqlCommand
				,N'@ErrMsg VARCHAR(400) OUTPUT, @ErrCode int OUTPUT'
				,@ErrMsg	= @ErrMsg OUTPUT
				,@ErrCode	= @ErrCode OUTPUT
		END TRY

		BEGIN CATCH
			SELECT  @ErrMsg	= @ErrMsg + ISNULL(ERROR_MESSAGE(),'')
				   ,@ErrCode= @ErrCode
			RETURN
		END CATCH
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
			,'CAL-AUTO'
			,@sqlCommand
	END

END
GO
GRANT EXECUTE ON [dbo].[NAP_Admin_Settlement_Auto_1s_Push] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Admin_Settlement_Auto_1s_Push] TO [vnteam] AS [dbo]