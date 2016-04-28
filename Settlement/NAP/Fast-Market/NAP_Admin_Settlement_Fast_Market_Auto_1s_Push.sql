USE bodb02
GO

ALTER PROCEDURE dbo.NAP_Admin_Settlement_Fast_Market_Auto_1s_Push @MatchId INT
	, @Action VARCHAR(20)
	, @Results VARCHAR(MAX)

	, @IsAuto BIT = 0
	, @AdminId INT = 0
	, @Ip VARCHAR(20) = ''

	, @ErrCode INT OUTPUT
	, @ErrMsg VARCHAR(200) OUTPUT
AS
/*
	Created: 20160428@Patrick
	Task: Fast market - Auto/Manual settlement
	DB: DBTXN.BODB02
	Original:
	
	Revisions:

	Param's Explanation:
		- @ResultList = '<bettypes>
							<bettype id="">
								<item position="" result="" />
								<item position="" result="" />
							</bettype>
	
						</bettypes>'
*/
BEGIN
	SET NOCOUNT ON 

	DECLARE @matchcode NVARCHAR(50), @sporttype INT, @leagueid INT, @sqlCommand NVARCHAR(MAX), @procName NVARCHAR(50)

	SELECT @matchcode = m.matchcode
		, @sporttype = m.sporttype
		, @leagueid = m.leagueid
	FROM DBPRO.bodb02.dbo.match m WITH(NOLOCK)
	WHERE m.matchid = @MatchId

	IF @@ROWCOUNT = 0
	BEGIN
		SELECT @ErrCode	= 1001001, @ErrMsg = 'Match does not exist!'
		RETURN
	END

	IF EXISTS (SELECT 1	FROM dbo.Single_Calculate_Queue s WITH (NOLOCK)
				WHERE s.matchid = @matchid 
					AND s.IsCalculating IN (0, 1)) 
		OR EXISTS (SELECT 1
					FROM Parlay_Calculate_Queue p WITH (NOLOCK)
					WHERE p.matchid = @matchid 
						AND p.IsCalculating IN (0, 1))
	BEGIN
		SELECT @ErrCode = 1001003
			, @ErrMsg = 'This match is being calculated, please wait a few seconds until the on-going process is completed and try again.'
		RETURN
	END

	--check waiting ticket --TODO
	EXEC dbo.NAP_Admin_Settlement_Checking @MatchId = @MatchId
		, @Action = @Action
		, @Mode = 'CAL-FM'
		, @ErrCode = @ErrCode OUTPUT
		, @ErrMsg = @ErrMsg OUTPUT
	IF @ErrCode <> 0
	BEGIN
		SELECT @ErrCode, @ErrMsg
		RETURN
	END

	SELECT @ErrCode = 0, @ErrMsg = '', @procName = OBJECT_NAME(@@PROCID)
		, @sqlCommand = 'EXEC [dbo].[NAP_Admin_Settlement_Fast_Market_Auto_1s] @Matchid = ' + CONVERT(NVARCHAR(50), @MatchId) 
															+ ', @AdminId = ' + CONVERT(NVARCHAR(50), @AdminId) 
															+ ', @Results = ''' + CONVERT(VARCHAR(MAX), @Results) + ''''
															+ ', @Action = ''' + CONVERT(NVARCHAR(50), @Action) + '''' 
															+ ', @IsAuto = ' + CONVERT(NVARCHAR(50), @IsAuto)
															+ ', @IP = ''' + CONVERT(VARCHAR(15), @IP) + ''''
															+ ', @ErrCode = @ErrCode OUTPUT' 
															+ ', @ErrMsg = @ErrMsg OUTPUT'
														
	IF LEN(@sqlCommand)> 1000 --Max Field 
	BEGIN
		SELECT @ErrCode = 1001010
			, @ErrMsg = 'There are too many inputted results to proceed at one time. Please select each one to execute separately.'	
		RETURN
	END
	
	IF (@procName LIKE '%_xtest' OR @procName LIKE '%_xpre' OR @procName LIKE '%_UAT_') -- UAT1 -->UAT9
	BEGIN
		BEGIN TRY
			EXEC sys.sp_executesql @sqlCommand
				, N'@ErrMsg VARCHAR(400) OUTPUT, @ErrCode INT OUTPUT'
				, @ErrMsg = @ErrMsg OUTPUT
				, @ErrCode = @ErrCode OUTPUT
		END TRY

		BEGIN CATCH
			SELECT @ErrMsg	= @ErrMsg + ISNULL(ERROR_MESSAGE(), '')
				, @ErrCode= @ErrCode
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

GRANT EXECUTE ON [NAP_Admin_Settlement_Fast_Market_Auto_1s_Push] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [NAP_Admin_Settlement_Fast_Market_Auto_1s_Push] TO [vnteam] AS [dbo]
GO