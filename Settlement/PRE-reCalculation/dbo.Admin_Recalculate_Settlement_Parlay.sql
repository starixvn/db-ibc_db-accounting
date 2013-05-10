


ALTER PROCEDURE [dbo].[Admin_Recalculate_Settlement_Parlay] 
(
	@matchid		INT,
	@betstatus		NVARCHAR(50),
	@finalhomescore SMALLINT,
	@finalawayscore SMALLINT, 
	@hthomescore	SMALLINT, 
	@htawayscore	SMALLINT,	
	@action			VARCHAR(10) = 'CAL',	
	@ErrCode		INT = 0 OUTPUT,
	@ErrMsg			NVARCHAR(200) = '' OUTPUT
)
WITH RECOMPILE
AS
/*	Creator: 20111116@Lukas
	Task: Main SP for Mix parly settlement
	DB: DB052.BODB_REVIEW

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
		- 20110815@Lukas: merge code from live ( settle for combination parlay)
		- 20110830@Joe: enhance logging, to add duration for each step.
		- 20110918@Lukas: include not keyscore match in error message.
	Param's Explanation:
		+ @betstatus: Used for score table, FGLG status, refund status
		
*/
BEGIN
	SET NOCOUNT ON

	
	DECLARE @matchdate DATETIME,
			@sporttype TINYINT, 			
			@TennisTotal SMALLINT, 
			@T_Home SMALLINT, 
			@T_Away SMALLINT,
			@tmp INT

	DECLARE @matchids VARCHAR(100)

	SET @matchids = CONVERT(VARCHAR(10),@matchid) + ','

	SELECT	@sporttype = sporttype,
			@matchdate = eventdate
	FROM DB02.bodb02.dbo.match WITH(NOLOCK)
	WHERE matchid = @matchid

	IF (@SportType IN (5, 6, 9, 30)) and @action = 'CAL' and @betstatus <> 'Refund' -- Tennis/VolleyBall/Badminton/Squash: get TotalGamesPlayed
		EXEC dbo.Admin_Recalculate_Settlement_2
				@betstatus	= @betstatus,
				@Total		= @TennisTotal OUTPUT,
				@TotalHome	= @T_Home OUTPUT,
				@TotalAway	= @T_Away OUTPUT

	IF @SportType = 10 -- Golf, using Stroke count, so swap the score to make it become normal stype
	BEGIN
		SELECT @tmp = @finalhomescore, @finalhomescore = @finalawayscore
		SELECT @finalawayscore = @tmp
	END
	
	-- CALCULATE RESULT of mixparlay
	
	BEGIN TRANSACTION
		IF @action IN ('REFUND-FT','REFUND-HT') -- if REFUND-FT or REFUND-HT called, do 'CAL' first, before do 'REFUND-FT'
			EXEC dbo.Admin_Recalculate_9m @matchid, @finalhomescore, @finalawayscore, @hthomescore, @htawayscore, @matchdate, 'CAL', @TennisTotal
	COMMIT TRANSACTION

	BEGIN TRANSACTION
			EXEC dbo.Admin_Recalculate_9m @matchid, @finalhomescore, @finalawayscore, @hthomescore, @htawayscore, @matchdate, @action, @TennisTotal
	COMMIT TRANSACTION



	-- Generate data for BetParlayDetail/Result	
	EXEC dbo.Admin_Recalculate_29_Precal @matchids
	
	
	BEGIN TRANSACTION
		EXEC dbo.Admin_Recalculate_9  @matchids = @matchids, @matchdate = @matchdate
	COMMIT TRANSACTION

	BEGIN TRANSACTION
		EXEC dbo.Admin_Recalculate_29 @matchids = @matchids, @matchdate = @matchdate
	COMMIT TRANSACTION

	--- insert sub-ticket into bettrans	
	EXEC dbo.Admin_Recalculate_29_Summary
	
END
