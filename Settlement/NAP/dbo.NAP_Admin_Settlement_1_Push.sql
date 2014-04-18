CREATE PROCEDURE [NAP_Admin_Settlement_1_Push]
	@AdminId int,
	@Matchid int,
	@FullTimeHome smallint = NULL,
	@FullTimeAway smallint = NULL,
	@HalfTimeHome smallint,
	@HalfTimeAway smallint,
	@GoalRecord varchar(50)= NULL,
	@BetStatus nvarchar(50),
	@Action varchar(10) = 'CAL',
	@IP varchar(15) = '',

	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@DelayTime int = 0 OUTPUT
AS

/*	Creator: Kathy
	Date: 20140213
	Task: SP for settlement
	DB: DBTXN/BODB02
	History:
		
	Param's Explanation:

		
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @matchcode nvarchar(50),@sporttype int, @leagueid int, @sqlCommand NVARCHAR(500), @NextAllowSettleTime datetime	

	SELECT @ErrCode = 0, @ErrMsg = '', @DelayTime = 0
	
	SELECT @matchcode = m.matchcode, @sporttype = m.sporttype, @leagueid = m.leagueid
	FROM match m with(NOLOCK)
	where m.matchid = @MatchId

	IF @@ROWCOUNT = 0 
	BEGIN
		SELECT	 @ErrCode	= 1000001
				,@ErrMsg	= 'Match does not exist!'	
		RETURN
	END 

	IF @action = 'CAL' AND @sporttype = 154 AND (@FullTimeHome = 0 OR @FullTimeHome IS NULL OR @FullTimeAway = 0 OR @FullTimeAway IS NULL)
	BEGIN
		SELECT	 @ErrCode	= 1000002
				,@ErrMsg	= 'Score is not valid.'	
		RETURN
	END

	--check whether it's at weekend peak-hour, from 7PM - 2AM (GMT+8)
	if datename(weekday, getdate()) in ('Saturday','Sunday') and datepart(hour, getdate()) between 7 and 14  AND @matchcode NOT LIKE '%hedge%'
	BEGIN
		select @NextAllowSettleTime = VValue from SystemSettings with (nolock) where VName = 'NextAllowSettleTime' 

		select @DelayTime = CASE WHEN DATEDIFF(ss, getdate(), @NextAllowSettleTime) < 0 THEN 0
								ELSE DATEDIFF(ss, getdate(), @NextAllowSettleTime) END

		if @DelayTime > 0
		BEGIN
			SELECT  @ErrCode = 1000003,
					@ErrMsg = 'We prevent the frequent calculations during peak hour at weekend, please hold on and try again in ' + cast(@DelayTime as varchar(3)) + ' seconds. Thanks!'
				
			RETURN
		END
	END

	SELECT @sqlCommand = 'EXEC [dbo].[NAP_Admin_Settlement_1] @matchid = ' + CONVERT(NVARCHAR(10),@MatchId) +
								 ', @creator = ' + CONVERT(NVARCHAR(10),@AdminId) + 
								 ', @fth = ' + ISNULL(CONVERT(NVARCHAR(10),@FullTimeHome),'NULL') +
								 ', @fta = ' + ISNULL(CONVERT(NVARCHAR(10),@FullTimeAway),'NULL') +
								 ', @hth = ' + ISNULL(CONVERT(NVARCHAR(10),@HalfTimeHome),'NULL') +
								 ', @hta = ' + ISNULL(CONVERT(NVARCHAR(10),@HalfTimeAway),'NULL') +
								 ', @goalrecord = '+ CASE when @GoalRecord IS NULL THEN 'NULL' ELSE '''' + CONVERT(nvarchar(50),@GoalRecord)+ '''' END +
								 ', @betstatus = ' + CASE when @BetStatus IS NULL THEN 'NULL' ELSE 'N''' + CONVERT(nvarchar(50),@BetStatus)+ '''' END +
								 ', @action = ''' + CONVERT(NVARCHAR(20),@Action) + '''' +
								 ', @IP = ''' + CONVERT(NVARCHAR(10),@IP) + '''' +
								 ', @ErrCode = @ErrCode OUTPUT' +
								 ', @ErrMsg = @ErrMsg OUTPUT' 
	
	INSERT INTO Single_Calculate_Queue(matchid, matchcode, IsCalculating, LeagueID, SportType, AdminId, IP, Action, sqlCommand)
	SELECT @MatchId, @matchcode, 0, @leagueid, @sporttype, @AdminId, @IP, @Action, @sqlCommand
END



GO

GRANT EXECUTE ON [NAP_Admin_Settlement_1_Push] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [NAP_Admin_Settlement_1_Push] TO [vnteam] AS [dbo]
GO


