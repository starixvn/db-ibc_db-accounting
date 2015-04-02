USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[NAP_Admin_Settlement_Refund_BetFair_Push]    Script Date: 04/01/2015 17:07:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[NAP_Admin_Settlement_Refund_BetFair_Push]
	@MatchId int,
	@AdminId int, 	
	@IP varchar(15) = '',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS

	/*
	Created: 20140218@Kathy 
	Task : Refund Running BetFair
	Original: Admin_Settlement_Refund_BetFair
	DB: DBTXN/BODB02

	Revisions: 
		- 20140506@Kathy: Don't allow to calculate exists matches in queue
		- 20150401@Kathy: Add checking ticket status before performing settlement [Redmine:#33493]
	

	Param's Explanation:
	• @matchid: matchid need to refund
	• @IsExcludeBetfair: Is Exclude betdaq tickets or not
	• @IsSettleAbandonedMatchBetFair: Is Settlement for Abandoned/postponed match or not
	BetFair account: 
				custid	--- username	-	roleid
				2331	---	BF		    -	1
				1077687	---	BFOS		-	1
	*/
BEGIN
	SET NOCOUNT ON
	DECLARE  @matchcode nvarchar(50)
			,@sporttype int
			,@leagueid int
			,@sqlCommand NVARCHAR(500)
			,@procName nvarchar(50)	

	SELECT   @matchcode = m.matchcode
			,@sporttype = m.sporttype
			,@leagueid = m.leagueid
	FROM match m with(NOLOCK)
	where m.matchid = @MatchId

	IF @@ROWCOUNT = 0 
	BEGIN
		SELECT	 @ErrCode	= 1001001
				,@ErrMsg	= 'Match does not exist!'	
		RETURN
	END 
	
	IF EXISTS (SELECT 1 from Single_Calculate_Queue with(NOLOCK) WHERE matchid = @matchid AND IsCalculating IN (0,1) )
		OR EXISTS (SELECT 1 from Parlay_Calculate_Queue with(NOLOCK) WHERE matchid = @matchid AND IsCalculating IN (0,1))
	BEGIN 
		SELECT	 @ErrCode	= 1001003
				,@ErrMsg	= 'This match is being calculated, please wait a few seconds until the on-going process is completed and try again.'	
		RETURN
	END 
	
	IF EXISTS (SELECT TOP 1 1 
				FROM dbo.bettrans b WITH(NOLOCK)
				WHERE b.matchid = @matchid
				AND b.statusID = 1 -- waiting status
				AND bettype NOT IN (14, 127) --Exclude FGLG, 1H FGLG
				AND bettype NOT IN (10, 31, 32, 33, 1231, 1232, 1233, 1237, 1238) -- Outright, VSRacing
				AND bettype NOT BETWEEN 1301 AND 1399 -- exclude sporting solution product
				AND bettype NOT BETWEEN 153 AND 156   -- New bettype of Tennis
				AND bettype NOT BETWEEN 1501 and 1599 -- Keno
				AND custid IN (2331, 1077687, 115770, 15523642)
			)
	BEGIN
		SELECT @ErrCode = 1001013
			,@ErrMsg = 'Cannot proceed as there exists some PENDING tickets in this match. Please contact admin for help.'
			
		RETURN
	END
	
	SELECT   @ErrCode = 0
			,@ErrMsg = ''
			,@procName = OBJECT_NAME(@@procid)
		    ,@sqlCommand = 'EXEC [dbo].[NAP_Admin_Settlement_Refund_BetFair] @matchid = ' + CONVERT(NVARCHAR(50),@MatchId) +
								 ', @creator = ' + CONVERT(NVARCHAR(50),@AdminId) + 
								 ', @IP = ''' + CONVERT(NVARCHAR(50),@IP) + '''' +
								 ', @ErrCode = @ErrCode OUTPUT' +
								 ', @ErrMsg = @ErrMsg OUTPUT' 

	IF @procName LIKE '%_xtest' or @procName LIKE '%_xpre'
	BEGIN
		BEGIN TRY
		EXEC sys.sp_executesql @sqlCommand
			,N'@ErrMsg VARCHAR(400) OUTPUT, @ErrCode int OUTPUT'
			,@ErrMsg = @ErrMsg OUTPUT
			,@ErrCode = @ErrCode OUTPUT
		END TRY

		BEGIN CATCH
			SELECT @ErrMsg = @ErrMsg + ISNULL(ERROR_MESSAGE(),''),
				@ErrCode = @ErrCode
			RETURN
		END CATCH

	END 
	ELSE
	BEGIN
		INSERT INTO Single_Calculate_Queue(matchid, matchcode, IsCalculating, LeagueID, SportType, AdminId, IP, Action, sqlCommand)
		SELECT @MatchId, @matchcode, 0, @leagueid, @sporttype, @AdminId, @IP, 'Refund-BetFair', @sqlCommand
	END 
END


GO
GRANT EXECUTE ON [dbo].[NAP_Admin_Settlement_Refund_BetFair_Push] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Admin_Settlement_Refund_BetFair_Push] TO [vnteam] AS [dbo]