/****** Object:  StoredProcedure [dbo].[NAP_Admin_Settlement_Refund_All_Push]    Script Date: 08/15/2014 13:56:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[NAP_Admin_Settlement_Refund_All_Push]
	@Matchid int,
	@AdminId int, 	
	@IsExcludeBetdaq bit = 0,
	@IsSettleAbandonedMatch bit = 0,
	@IsExcludeBetfair bit = 0,
	@IsSettleAbandonedMatchBetFair bit = 0,
	@IsSettleAbandonedMatchIBC bit = 0,
	@HalfTimeHome int = NULL,
	@HalfTimeAway int = NULL,
	@FullTimeHome int = NULL,
	@FullTimeAway int = NULL,
	@BetStatus nvarchar(50) = NULL,
	@IP varchar(15) = '',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
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

	Param's Explanation:
	• @matchid: matchid need to refund
	• @IsExcludeBetdaq: Is Exclude betdaq tickets or not
	• @IsSettleAbandonedMatch: Is Settlement for Abandoned/postponed match or not
	• @IsExcludeBetfair: Is Exclude betfair tickets or not
	• @IsSettleAbandonedMatchBetFair: Is Settlement for Betfair ticket of Abandoned/postponed match or not
	* List of BetDaq Customers 
				custid	--- username	-	roleid
				50057	---	BQUS888		-	1
				879241	---	BQUSMLB		-	1
				103873	---	BQUSNBA		-	1
				78761	---	ITibc101	-	1
				1688156	---	MTEST0101	-	2
				851668  --- BDUS01      -   1
				878902  --- BDUS016     -   1
	* List of Betfair Customers 
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
			,@IsNested BIT
			,@Action varchar(20)
			,@procName nvarchar(50)	

	SELECT   @matchcode = m.matchcode
			,@sporttype = m.sporttype
			,@leagueid = m.leagueid
			,@IsNested = 0
			,@Action = 'CAL'
	FROM match m with(NOLOCK)
	where m.matchid = @MatchId

	IF @@ROWCOUNT = 0 
	BEGIN
		SELECT	 @ErrCode	= 1000001
				,@ErrMsg	= 'Match does not exist!'	
		RETURN 
	END 

	IF EXISTS (SELECT 1 from Single_Calculate_Queue with(NOLOCK) WHERE matchid = @matchid AND IsCalculating IN (0,1) )
		OR EXISTS (SELECT 1 from Parlay_Calculate_Queue with(NOLOCK) WHERE matchid = @matchid AND IsCalculating IN (0,1))
	BEGIN 
		SELECT	 @ErrCode	= 1000000
				,@ErrMsg	= 'This match is being calculated, please wait a few seconds until the on-going process is completed and try again.'	
		RETURN
	END 
	
	SELECT   @ErrCode = 0
			,@ErrMsg = ''
			,@procName = OBJECT_NAME(@@procid)
			,@sqlCommand = 'EXEC [dbo].[NAP_Admin_Settlement_Refund_All] @Matchid = ' + CONVERT(NVARCHAR(50),@MatchId) +
								 ', @creator = ' + CONVERT(NVARCHAR(50),@AdminId) + 
								 ', @IsExcludeBetdaq = ' + CONVERT(NVARCHAR(1),@IsExcludeBetdaq) + 
								 ', @IsSettleAbandonedMatch = ' + CONVERT(NVARCHAR(1),@IsSettleAbandonedMatch) +
								 ', @IsExcludeBetfair = ' + CONVERT(NVARCHAR(1),@IsExcludeBetfair) + 
								 ', @IsSettleAbandonedMatchBetFair = ' + CONVERT(NVARCHAR(1),@IsSettleAbandonedMatchBetFair) + 
								 ', @IsSettleAbandonedMatchIBC = ' + CONVERT(NVARCHAR(1),@IsSettleAbandonedMatchIBC) + 
								 ', @betstatus = ' + CASE when @BetStatus IS NULL THEN 'NULL' ELSE 'N''' + CONVERT(nvarchar(20),@BetStatus)+ '''' END +
								 ', @fth = ' + ISNULL(CONVERT(NVARCHAR(50),@FullTimeHome),'NULL') +
								 ', @fta = ' + ISNULL(CONVERT(NVARCHAR(50),@FullTimeAway),'NULL') +
								 ', @hth = ' + ISNULL(CONVERT(NVARCHAR(50),@HalfTimeHome),'NULL') +
								 ', @hta = ' + ISNULL(CONVERT(NVARCHAR(50),@HalfTimeAway),'NULL') +
								 ', @Action = ''' + CONVERT(NVARCHAR(20),@Action) + '''' +
								 ', @IsNested = ''' + CONVERT(NVARCHAR(1),@IsNested) + '''' +
								 ', @IP = ''' + CONVERT(NVARCHAR(50),@IP) + '''' +
								 ', @ErrCode = @ErrCode OUTPUT' +
								 ', @ErrMsg = @ErrMsg OUTPUT' 
								 
	IF @procName LIKE '%_xtest' or @procName LIKE '%_xpre'
	BEGIN
		DECLARE @GoalRecord VARCHAR(50)

		BEGIN TRY
			EXEC sys.sp_executesql @sqlCommand
				,N'@ErrMsg VARCHAR(400) OUTPUT, @ErrCode int OUTPUT'
				,@ErrMsg = @ErrMsg OUTPUT
				,@ErrCode = @ErrCode OUTPUT
		END TRY

		BEGIN CATCH
			SELECT @ErrMsg = @ErrMsg + ISNULL(ERROR_MESSAGE(),'')
				  ,@ErrCode = @@error
			RETURN
		END CATCH

		SELECT	 @FullTimeHome = m.finalhomescore
				,@FullTimeAway = m.finalawayscore
				,@HalfTimeHome = m.hthomescore
				,@HalfTimeAway = m.htawayscore
				,@GoalRecord = m.GoalRecord
				,@BetStatus = m.betstatus
		FROM DBPRO.BODB02.dbo.match m WITH (NOLOCK)
		WHERE m.matchid = @MatchId

		IF @sporttype = 1
		BEGIN
			SELECT @GoalRecord = CASE when CHARINDEX(';',@GoalRecord) > 0 THEN REPLACE(@GoalRecord,';','')
									  ELSE @GoalRecord
								 END ,
					@BetStatus = CASE when CHARINDEX('1FL:',@BetStatus) > 0 THEN REPLACE(@BetStatus,SUBSTRING(@BetStatus,CHARINDEX('1FL:',@BetStatus),8),'')
									  ELSE @BetStatus
								 END 
		END

		EXEC Acc_Set_ConfirmedAction @matchid = @MatchId
				,@action = 13
				,@fth = @FullTimeHome
				,@fta = @FullTimeAway
				,@hth = @HalfTimeHome
				,@hta = @HalfTimeAway
				,@goalrecord = @GoalRecord
				,@betstatus = @BetStatus
	END 
	ELSE
	BEGIN
		INSERT INTO Single_Calculate_Queue(matchid, matchcode, IsCalculating, LeagueID, SportType, AdminId, IP, Action, sqlCommand)
		SELECT @MatchId, @matchcode, 0, @leagueid, @sporttype, @AdminId, @IP, 'Refund', @sqlCommand
	END
END


GO
GRANT EXECUTE ON [dbo].[NAP_Admin_Settlement_Refund_All_Push] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Admin_Settlement_Refund_All_Push] TO [vnteam] AS [dbo]