USE [bodb02]
GO
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
		- @Result = '<BetTypes>
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
			,@xmlData		XML
	
	DECLARE @tblResultDetail TABLE (
		bettype					SMALLINT
		,ResourceId				VARCHAR(20)
		,ResourceId_BetOption	VARCHAR(20)
		,Position				TINYINT
		,BetOption				TINYINT
	)
	 
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
			
	SET @xmlData = CONVERT(XML, @Results)
		
	;WITH TmpData AS (
		SELECT T.C.value('../@Id', 'SMALLINT') AS Bettype
			, T.C.value('./@Position', 'TINYINT') AS Position
			, T.C.value('./@Result', 'TINYINT') AS BetOption
		FROM @xmlData.nodes('/BetTypes/BetType/Item') AS T(C)
	)
	INSERT INTO @tblResultDetail (bettype, ResourceId, ResourceId_BetOption, Position, BetOption)
	SELECT	bettype
			,CAST(BetType * 100 AS VARCHAR(20)) AS ResourceId
			,CAST(BetType * 100 + 1 AS VARCHAR(20)) AS ResourceId_BetOption
			,Position
			,BetOption
	FROM TmpData
		
	IF @IsAuto = 1
	BEGIN		
		IF EXISTS (SELECT TOP 1 1 FROM @tblResultDetail WHERE bettype NOT IN (SELECT bettype FROM dbo.f_Set_GetGroupBettypes() WHERE GroupId = 9)) -- FM
		BEGIN
			SELECT	 @ErrCode	= 1001016
					,@ErrMsg	= 'There are some bettypes not belong to Fast Market' 

			RETURN
		END
		
		IF EXISTS (SELECT	TOP 1 1
					FROM	@tblResultDetail t
						CROSS APPLY (
							SELECT	TOP 1 r.ResourceId
							FROM	DBPRO.bodb02.dbo.ResultDetail r WITH(NOLOCK)
							WHERE	r.matchid = @matchid
									AND t.ResourceId = r.ResourceId
									AND	(SELECT TOP 1 [char] FROM dbo.f_Set_GetChar(CASE WHEN t.Position <=44 THEN r.HomeValue ELSE r.AwayValue END
																						 ,CASE WHEN t.Position <=44 THEN t.Position ELSE t.Position - 45 END 
																							)) IN ('3','5','6') -- UNDO, CAL (manually), REFUND
						) r
		)
		BEGIN
			SELECT	 @ErrCode	= 1001012
					,@ErrMsg	= 'The auto-settlement failed due to a result that has been settled or unsettled previously by manual.' 

			RETURN
		END
		
		UPDATE t
		SET	BetOption = (SELECT TOP 1 byte FROM dbo.f_Set_GetByte(CASE WHEN t.Position <=44 THEN r.HomeValue ELSE AwayValue END, t.Position))
		FROM	@tblResultDetail t
			INNER JOIN DBPRO.bodb02.dbo.ResultDetail r WITH (ROWLOCK)
				ON	r.matchId = @matchid
					AND r.ResourceId = t.ResourceId_BetOption	
	END
	
	SET @Results = CAST((
					SELECT bettype '@Id'
						,(SELECT Position '@p'
								,BetOption '@r'
							FROM @tblResultDetail WHERE r.bettype = bettype FOR XML PATH('r'), TYPE)
					FROM @tblResultDetail r
					GROUP BY r.bettype
					FOR XML PATH('b'), ROOT ('r'), TYPE
				) AS VARCHAR(MAX))		
	
	EXEC dbo.NAP_Admin_Settlement_Checking @MatchId = @MatchId
		,@xmlData = @Results
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