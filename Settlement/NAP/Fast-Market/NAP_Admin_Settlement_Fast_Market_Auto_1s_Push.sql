USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[NAP_Admin_Settlement_Fast_Market_Auto_1s_Push]    Script Date: 10/25/2016 14:10:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[NAP_Admin_Settlement_Fast_Market_Auto_1s_Push] @MatchId INT
	,@Action	VARCHAR(20)
	,@Results	VARCHAR(MAX)

	,@IsAuto	BIT				= 0
	,@AdminId	INT				= 0
	,@Ip		VARCHAR(20)		= ''

	,@ErrCode	INT				= 0		OUTPUT
	,@ErrMsg	VARCHAR(200)	= ''	OUTPUT
AS
/*
	Created: 20160428@Patrick
	Task: Fast market - Auto/Manual settlement
	DB: DBTXN.BODB02
	Original:
	
	Revisions:

	Param's Explanation:
		- @ResultList = '<BetTypes>
							<BetType Id="">
								<Item Position="" Result="" />
								<Item Position="" Result="" />
							</BetType>
	
						</BetTypes>'
*/
BEGIN
	SET NOCOUNT ON 

	DECLARE @matchcode		NVARCHAR(50)
			,@sporttype		INT
			,@leagueid		INT
			,@sqlCommand	NVARCHAR(MAX)
			,@procName		NVARCHAR(128)

	SELECT	@matchcode = m.matchcode
			,@sporttype = m.sporttype
			,@leagueid = m.leagueid
	FROM	dbo.match m WITH(NOLOCK)
	WHERE	m.matchid = @MatchId

	IF @@ROWCOUNT = 0
	BEGIN
		SELECT	@ErrCode = 1001001
				,@ErrMsg = 'Match does not exist!'
				
		RETURN
	END

	IF EXISTS (SELECT	TOP 1 1 
				FROM	dbo.Single_Calculate_Queue s WITH (NOLOCK)
				WHERE	s.matchid = @matchid 
						AND s.IsCalculating IN (0, 1)) 
		OR EXISTS (SELECT	TOP 1 1
					FROM	dbo.Parlay_Calculate_Queue p WITH (NOLOCK)
					WHERE	p.matchid = @matchid 
							AND p.IsCalculating IN (0, 1)
				)
	BEGIN
		SELECT	@ErrCode = 1001003
				,@ErrMsg = 'This match is being calculated, please wait a few seconds until the on-going process is completed and try again.'
		
		RETURN
	END

	--check waiting ticket
	DECLARE @ResultDetail TABLE(BetType SMALLINT, Position TINYINT)
	DECLARE @XmlData		XML
			,@PositionList	VARCHAR(1204)
			,@BetType		SMALLINT
	
	SET @Results = REPLACE(
						REPLACE(
							REPLACE(
								REPLACE(
									REPLACE(@Results, 'BetTypes', 'r')
								, 'BetType', 'b')
							, 'Item', 'r')
						, 'Result', 'r')
					, 'Position', 'p')
					
	SET @XmlData =  CONVERT(XML, @Results)
	
	;WITH TmpData AS (
		SELECT T.C.value('../@Id', 'SMALLINT') AS Bettype
			, T.C.value('./@p', 'TINYINT') AS Position
		FROM @XmlData.nodes('/r/b/r') AS T(C)
	)
	INSERT INTO @ResultDetail (BetType, Position)
	SELECT	BetType, Position
	FROM	TmpData
	ORDER BY Bettype, Position

	DECLARE @BettypeIds TABLE (BetType SMALLINT, IsFinished BIT)
	INSERT INTO @BettypeIds(BetType, IsFinished)
	SELECT	BetType, 0
	FROM	@ResultDetail
	GROUP BY BetType

	WHILE 1 = 1
	BEGIN
		SET @PositionList = NULL
		
		UPDATE	TOP(1) @BettypeIds
		SET		IsFinished = 1
				,@BetType = BetType
		WHERE	IsFinished = 0
		
		IF @@ROWCOUNT = 0 BREAK

		SELECT	@PositionList = COALESCE(@PositionList + ',' + CAST(CONVERT(TINYINT, Position) AS VARCHAR), CAST(CONVERT(TINYINT, Position) AS VARCHAR))
		FROM	@ResultDetail
		WHERE	BetType = @BetType 
				AND Position IS NOT NULL

		EXEC dbo.NAP_Admin_Settlement_Checking @MatchId = @MatchId
			,@BetType = @BetType
			,@PositionList = @PositionList
			,@Action = @Action
			,@Mode = 'CAL-FM'
			,@ErrCode = @ErrCode OUTPUT
			,@ErrMsg = @ErrMsg OUTPUT
			
		IF @ErrCode <> 0
		BEGIN
			SELECT	@ErrCode
					,@ErrMsg
			
			RETURN
		END

	END

	SELECT	@ErrCode = 0
			,@ErrMsg = ''
			,@procName = OBJECT_NAME(@@PROCID)
			,@sqlCommand = 'EXEC [dbo].[NAP_Admin_Settlement_Fast_Market_Auto_1s] @Matchid = ' + CONVERT(NVARCHAR(50), @MatchId) 
															+ ', @AdminId = ' + CONVERT(NVARCHAR(50), @AdminId) 
															+ ', @Results = ''' + CONVERT(VARCHAR(MAX), @Results) + ''''
															+ ', @Action = ''' + CONVERT(NVARCHAR(50), @Action) + '''' 
															+ ', @IsAuto = ' + CONVERT(NVARCHAR(50), @IsAuto)
															+ ', @IP = ''' + CONVERT(VARCHAR(15), @IP) + ''''
															+ ', @ErrCode = @ErrCode OUTPUT' 
															+ ', @ErrMsg = @ErrMsg OUTPUT'
														
	IF (@procName LIKE '%_xtest' OR @procName LIKE '%_xpre' OR @procName LIKE '%_UAT_') -- UAT1 -->UAT9
	BEGIN
		BEGIN TRY
			EXEC sys.sp_executesql @sqlCommand
				,N'@ErrMsg VARCHAR(400) OUTPUT, @ErrCode INT OUTPUT'
				,@ErrMsg = @ErrMsg OUTPUT
				,@ErrCode = @ErrCode OUTPUT
		END TRY

		BEGIN CATCH
			SELECT	@ErrMsg	= @ErrMsg + ISNULL(ERROR_MESSAGE(), '')
					,@ErrCode= @ErrCode
				
			RETURN
		END CATCH
	END
	ELSE
	BEGIN
		INSERT INTO dbo.Single_Calculate_Queue (matchid, matchcode, IsCalculating, LeagueID, SportType, AdminId, IP, Action, sqlCommand)
		SELECT @MatchId, @matchcode, 0, @leagueid, @sporttype, @AdminId, @IP, 'CAL-FM', @sqlCommand
	END
END

GO
GRANT EXECUTE ON [dbo].[NAP_Admin_Settlement_Fast_Market_Auto_1s_Push] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Admin_Settlement_Fast_Market_Auto_1s_Push] TO [vnteam] AS [dbo]