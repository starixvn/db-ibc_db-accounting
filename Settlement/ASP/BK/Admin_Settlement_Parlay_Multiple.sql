set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go




alter PROCEDURE [dbo].[Admin_Settlement_Parlay_Multiple] 
	@matchids varchar(2000),
	@creator int,
	@action varchar(10) = 'CAL',
	@IP varchar(15) = '',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
WITH RECOMPILE
AS


/*	Creator: Viet Hoang
	Date: 2008-12-16
	Task: Main SP for Mix parly settlement
	DB: DBTRANS.bodb02

	History:
		- 20091225@Daniel: Add writelog table Userlog_settle
		- 20100209@Daniel: Prevent settle mix-parlay when tickets are being moved
		- 20091225@Daniel: Add writelog to table Userlog_settle	
		- 20100224@Daniel: Support settlement for GOLF (swap the score)
		- 20100305@Daniel: Add back writelog to table Userlog
		- 20100720@Henry: using SP Logfile to write log
		- 20100825@Lukas: Update last time modify (changetime column) for match table
		- 20110222@Joe : change @matchid to be varchar(2000) and create table @match to support multiple match calculate
		- 20110606@Lukas: replace update match statement by store procedure	
		- 20110624@Viet: 20110624@Viet: Offer 'Refund-HT'
	Param's Explanation:
		+ @betstatus: Used for score table, FGLG status, refund status
		
*/
SET NOCOUNT ON

Declare @start datetime, @stop datetime
SELECT	@start = CURRENT_TIMESTAMP,
		@ErrCode = 0,
		@ErrMsg = ''

IF EXISTS(SELECT 1 FROM DB06.bodb02.dbo.SystemSettings WITH (NOLOCK) WHERE VValue = 1 AND VName = 'isMovingBet')
BEGIN
	select @ErrCode = 101
	select @ErrMsg = 'System is not ready to calculate Mix Parlay for this match. Please try again after few minutes.'
	return
END

-- GET list of matchid(s)
Declare @match TABLE (rn int PRIMARY KEY IDENTITY(1,1), matchid int, eventdate smalldatetime, 
	fth smallint, fta smallint, hth smallint, hta smallint,
	SportType smallint, betstatus nvarchar(50), GoalRecord varchar(50) )
INSERT INTO @match
	(matchid, eventdate,
	fth, fta, hth, hta,
	SportType, betstatus, GoalRecord)
SELECT
	matchid, eventdate,
	finalhomescore, finalawayscore, hthomescore, htawayscore,
	SportType, betstatus, GoalRecord
FROM DB02.BODB02.dbo.Match
WHERE matchid IN (SELECT val FROM dbo.strSplit(@matchids,','))

if exists (select 1 from @match
			where fth is null or fta is null or hth is null or hta is null)
BEGIN
	select @ErrCode = 101
	select @ErrMsg = 'You have selected match which is not keyed score yet. Please check again.'
	return
END

declare @rn int 
declare @matchid int, @matchdate datetime
declare @finalhomescore int,@finalawayscore int
declare @hthomescore int, @htawayscore int, @GoalRecord varchar(50)
declare @sporttype tinyint, @betstatus nvarchar(50)
Declare @TennisTotal smallint, @T_Home smallint, @T_Away smallint
Declare @tmp int

SET @rn = 1
WHILE EXISTS (SELECT 1 FROM @match WHERE rn = @rn)
BEGIN

	select
		@matchid=matchid, @matchdate=eventdate,
		@finalhomescore=fth, @finalawayscore=fta, @hthomescore=hth, @htawayscore = hta,
		@sporttype=SportType, @betstatus=betstatus, @GoalRecord=GoalRecord
	from @match
	where rn = @rn

	IF (@SportType IN (5, 6, 9, 30)) and @action = 'CAL' and @betstatus <> 'Refund' -- Tennis/VolleyBall/Badminton/Squash: get TotalGamesPlayed
		EXEC dbo.Admin_Settlement_2
			@betstatus = @betstatus,
			@Total =  @TennisTotal OUTPUT,
			@TotalHome = @T_Home OUTPUT,
			@TotalAway = @T_Away OUTPUT

	IF @SportType = 10 -- Golf, using Stroke count, so swap the score to make it become normal stype
	Begin
		SELECT @tmp = @finalhomescore, @finalhomescore = @finalawayscore
		SELECT @finalawayscore = @tmp
	End

	-- CALCULATE RESULT of mixparlay for each match
	---------------------------------------------------------------
	BEGIN TRANSACTION
	IF @action IN ('REFUND-FT','REFUND-HT') -- if REFUND-FT or REFUND-HT called, do 'CAL' first, before do 'REFUND-FT'
		EXEC dbo.Admin_Calculate_9m @matchid, @finalhomescore,@finalawayscore,@hthomescore,@htawayscore, @matchdate, 'CAL', @TennisTotal
	COMMIT TRANSACTION
	BEGIN TRANSACTION
	EXEC dbo.Admin_Calculate_9m @matchid, @finalhomescore,@finalawayscore,@hthomescore,@htawayscore, @matchdate, @action, @TennisTotal
	COMMIT TRANSACTION

	SET @rn = @rn + 1
END

---------------------------------------------------------------
Declare @subMatchIDs varchar(2000)
Declare @Ev TABLE (rn int PRIMARY KEY IDENTITY (1,1), EventDate smalldatetime)
INSERT INTO @Ev (EventDate)
SELECT DISTINCT EventDate
FROM @match
ORDER BY EventDate

SET @rn = 1
WHILE EXISTS (SELECT 1 FROM @Ev WHERE rn = @rn)
BEGIN
	SELECT @matchdate = EventDate FROM @Ev WHERE rn = @rn

	SET @subMatchIDs = (
			SELECT CAST(matchid as varchar(20)) + ','
			FROM @match
			WHERE EventDate = @matchdate
			FOR XML PATH('')
		)
	SET @subMatchIDs = SUBSTRING(@subMatchIDs, 1, LEN(@subMatchIDs)-1)

	BEGIN TRANSACTION
	EXEC dbo.[Admin_Calculate_29] @matchids = @subMatchIDs, @matchdate = @matchdate
	COMMIT TRANSACTION

	SET @rn = @rn + 1
END

---------------------------------------------------------------
SET @rn = 1
WHILE EXISTS (SELECT 1 FROM @match WHERE rn = @rn)
BEGIN
	SELECT @matchid = matchid FROM @match WHERE rn = @rn

	IF @action = 'CAL'
		EXEC DB02.bodb02.dbo.UpdateMatch_Remark @matchid = @matchid, @command = 'M'
	ELSE IF @action = 'REFUND'
		EXEC DB02.bodb02.dbo.UpdateMatch_Remark @matchid = @matchid, @command = 'R'
	ELSE IF @action IN ('REFUND-FT','REFUND-HT')
		EXEC DB02.bodb02.dbo.UpdateMatch_Remark @matchid = @matchid, @command = 'F'

	---------------------------------------------------------------
	-- update match coz m88 project using DB02.dbo.match.tstamp to know match do parlay settle (vivi@2009-8-27)	
	EXEC DB02.bodb02.dbo.Admin_Match_Update @Command = 'Admin_Settlement_Parlay', @Matchid = @matchid, @creator = @creator 
	---------------------------------------------------------------

	SET @rn = @rn + 1
END

---------------------------------------------------------------
SELECT @stop = CURRENT_TIMESTAMP


Declare @LogData nvarchar(200)
DECLARE @ActionID varchar(30), @Remark varchar(50)

SET @rn = 1
WHILE EXISTS (SELECT 1 FROM @match WHERE rn = @rn)
BEGIN

	select
		@matchid=matchid, @matchdate=eventdate,
		@finalhomescore=fth, @finalawayscore=fta, @hthomescore=hth, @htawayscore = hta,
		@sporttype=SportType, @betstatus=betstatus, @GoalRecord=GoalRecord
	from @match
	where rn = @rn

	SELECT @LogData = 'Calculate Multiple (' + @action + ') for matchid:' + CAST(@matchid as nvarchar(10)) + ' (' + CAST(DATEDIFF(millisecond, @start, @stop) as nvarchar(50)) + ' ms)'
	EXEC dbo.WriteLog_UserLog @creator, @LogData

	--Write Log Settle
	SELECT @ActionID = CASE @Action 
			WHEN 'CAL' THEN 104
			WHEN 'UNDO' THEN 105
			WHEN 'REFUND-FT' THEN 106
			WHEN 'REFUND-HT' THEN 120
			WHEN 'REFUND' THEN 107
		END
	SELECT @Remark = 'Duration:' + CAST(DATEDIFF(millisecond, @start, @stop) as nvarchar(50)) + ' ms'

	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle
		@UserID = @creator,
		@Matchid = @matchid,
		@ActionID = @ActionID,
		@finalhomescore = @finalhomescore,
		@finalawayscore = @finalawayscore,  
		@hthomescore = @hthomescore,
		@htawayscore = @htawayscore,
		@GoalRecord = @goalrecord,
		@betstatus = @betstatus,
		@Remark = @Remark,    
		@IP = @IP

	SET @rn = @rn + 1

END



GO
GRANT EXECUTE ON [dbo].[Admin_Settlement_Parlay_Multiple] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Admin_Settlement_Parlay_Multiple] TO [vnteam]