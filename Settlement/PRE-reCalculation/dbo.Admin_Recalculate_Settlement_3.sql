

ALTER PROCEDURE [dbo].[Admin_Recalculate_Settlement_3]
	@creator	INT,
	@matchid	INT,
	@fth		SMALLINT = NULL,
	@fta		SMALLINT = NULL,
	@hth		SMALLINT,
	@hta		SMALLINT,
	@goalrecord VARCHAR(50)= NULL,
	@betstatus	NVARCHAR(50),
	@mode		VARCHAR(6) = 'CAL'
AS
/*
	Created: 20111116@Lukas
	Task : Covered SP for settlement
	DB: DB052.BODB_REVIEW

	Revisions:
		- 20090204@Thien: Add description and add the section for Next Goal(22)
		- 20090210@Vinh: Add check Goal Record before calculating
		- 20090214@Thien:
				+only check GoalRecord when it's in use by adding "... and @GoalRecord <> ''"
				+and only check if this match is not hedging one
		- 20090215@Joe: Change the check of Next Goal to "Check ticket exists"
		- 20091124@Daniel: Add count tickets and pass value Rep SPs to check remote replication
		- 20100121@Daniel: Add check total game played for Squash settlement
		- 20100626@Peter : Add count tickets for all bettypes and just call Admin_Calculate sp when count ticket >0 
		- 20100818@Henry : Allow to calculate bettype 21 (1st half moneyline)
		- 20110620@Jamie: Retrieve Match on DB02 instead of DBTrans
		- 20110912@Tom: Add new bettypes 30
					apply new bet type 1st correct score on Sport Books		

	Param's Explanation:
	• @Mode:
		CAL : All BetTypes
		CAL-HT : HT Only
		CAL-FT : FT Only (All Except HT)
*/
BEGIN
	SET NOCOUNT ON 

	DECLARE
		@sporttype tinyint,		
		@matchCode nvarchar(50)

	SELECT	@sporttype = SportType,			
			@matchCode = IsNull(matchCode, '')
	FROM	DB02.BODB02.dbo.Match WITH(NOLOCK) 
	WHERE	matchid = @matchid

	DECLARE @TennisTotal SMALLINT, 
			@T_Home SMALLINT, 
			@T_Away SMALLINT

	IF @SportType IN (5, 6, 9, 30) -- Tennis/VolleyBall/Badminton/Squash : get TotalGamesPlayed
		EXEC dbo.Admin_Recalculate_Settlement_2
				@betstatus	= @betstatus,
				@Total		=  @TennisTotal OUTPUT,
				@TotalHome	= @T_Home OUTPUT,
				@TotalAway	= @T_Away OUTPUT

	IF @SportType = 10 -- Golf, using Stroke count, so swap the score to make it become normal stype
	BEGIN
		DECLARE @tmp INT
		SELECT @tmp = @fth, @fth = @fta
		SELECT @fta = @tmp
	END

	DECLARE @oddeven			SMALLMONEY, 
			@oddevenht			SMALLMONEY,
			@totalgoal			SMALLMONEY, 
			@totalht			SMALLMONEY,
			@scorediff			SMALLMONEY, 
			@scorediff_ht		SMALLMONEY,
			@correctscore		NVARCHAR(10),
			@correctscore_ht	NVARCHAR(10), 
			@HTFT				NVARCHAR(10)

	SELECT
		@oddeven	= CASE WHEN @sporttype IN (5, 6, 9, 30) and @TennisTotal > 0 THEN @TennisTotal % 2 ELSE ((@fth + @fta) % 2) END,
		@oddevenht	= ((@hth + @hta) % 2),
		@totalgoal	= CASE WHEN @sporttype IN (5, 6, 9, 30) and @TennisTotal > 0 THEN @TennisTotal ELSE (@fth + @fta) END,
		@totalht	= (@hth + @hta),
		@scorediff	= (@fth - @fta),
		@scorediff_ht	= (@hth - @hta),
		@correctscore	= CAST(@fth AS NVARCHAR(3)) + ':' + CAST(@fta AS NVARCHAR(3)),
		@correctscore_ht	= CAST(@hth AS NVARCHAR(3)) + ':' + CAST(@hta AS NVARCHAR(3)),
		@HTFT	=	CASE WHEN @hth = @hta THEN '0' WHEN @hth > @hta THEN '1' ELSE '2' END + ':' +
					CASE WHEN @fth = @fta THEN '0' WHEN @fth > @fta THEN '1' ELSE '2' END
	
	--2008-06-10: (Michael) Set back to Set handicap (Thien)
	/*
	IF @sporttype = 6 -- VolleyBall, Handicap using "Score" : 20080511 (Farn)(Joe)
		SELECT @fth = @T_Home, @fta = @T_Away
	*/
	
	--2009-02-10: Check goal record (Vinh)--------------
	DECLARE @ErrMsg nvarchar(200)

	--IF (@sporttype = 1 and @mode <> 'CAL-HT' AND len(@GoalRecord) <> @totalgoal and @GoalRecord <> '' and @matchCode not like '%hedge%') 
	IF EXISTS(SELECT transid FROM dbo.bettrans with (nolock) WHERE matchid = @matchid AND bettype = 22)
		IF LEN(@GoalRecord) <> @TotalGoal
		BEGIN
			select @ErrMsg = 'Goal record is not consistent with the score, please correct Goal record before calculating.'
			RaisError (@ErrMsg, 16, 1)
			return
		END

	
	----------------------------------------------------
	
	IF @Mode IN ('CAL-FT', 'CAL')
	BEGIN
	    
	    --------count HDP tickets for checking remote rep (Daniel)---------
		DECLARE @betcount_1 int, @betcount_2 int, @betcount_3 int, @betcount_4 int, 
				@betcount_5 int, @betcount_6 int, @betcount_16 int, @betcount_20 int, @betcount_22 int,
				@betcount_13 int, 
				@betcount_24 int, @betcount_25 int, @betcount_26 int, @betcount_27 int, @betcount_28 int

		SELECT 
			@betcount_1 = ISNULL(SUM(case bettype when 1 then 1 else 0 end), 0),
			@betcount_2 = ISNULL(SUM(case bettype when 2 then 1 else 0 end), 0),
			@betcount_3 = ISNULL(SUM(case bettype when 3 then 1 else 0 end), 0),
			@betcount_4 = ISNULL(SUM(case bettype when 4 then 1 else 0 end), 0),
			@betcount_5 = ISNULL(SUM(case bettype when 5 then 1 else 0 end), 0),
			@betcount_6 = ISNULL(SUM(case bettype when 6 then 1 else 0 end), 0),
			@betcount_13 = ISNULL(SUM(case bettype when 13 then 1 else 0 end), 0),
			@betcount_16 = ISNULL(SUM(case bettype when 16 then 1 else 0 end), 0), 
			@betcount_20 = ISNULL(SUM(case bettype when 20 then 1 else 0 end), 0),
			@betcount_22 = ISNULL(SUM(case bettype when 22 then 1 else 0 end), 0),
			@betcount_24 = ISNULL(SUM(case bettype when 24 then 1 else 0 end), 0),
 			@betcount_25 = ISNULL(SUM(case bettype when 25 then 1 else 0 end), 0),
			@betcount_26 = ISNULL(SUM(case bettype when 26 then 1 else 0 end), 0),
			@betcount_27 = ISNULL(SUM(case bettype when 27 then 1 else 0 end), 0),
			@betcount_28 = ISNULL(SUM(case bettype when 28 then 1 else 0 end), 0)
		FROM bettrans WITH(NOLOCK) 
		WHERE  matchid = @matchid
			   and bettype in (1,2,3,4,5,6,13,16,20,22,24,25,26,27,28)
		
		-- bettype 1 : Handicap
		 IF @betcount_1 > 0
			EXEC dbo.Admin_Recalculate_1 @matchid, 1, @fth, @fta, @betcount_1
		
		-- bettype 20 : Money Line
		 IF @betcount_20 > 0 
			EXEC dbo.Admin_Recalculate_1 @matchid, 20, @fth, @fta

		-- bettype 2 : Odd/Even
		 IF @betcount_2 > 0  
			EXEC dbo.Admin_Recalculate_2 @matchid, 2, @oddeven
		
		-- bettype 3 : Over/Under
		IF @betcount_3 > 0
			EXEC dbo.Admin_Recalculate_3 @matchid, 3, @totalgoal
		
		-- bettype 4, 16 : Correct Score
		IF @betcount_4 > 0
			EXEC dbo.Admin_Recalculate_4 @matchid,  4, @correctscore, @scorediff
				
		-- bettype 5 : 1x2
		IF @betcount_5 > 0
			EXEC dbo.Admin_Recalculate_5 @matchid,  5, @scorediff
		
		-- bettype 6 : Total Goal
		IF @betcount_6 > 0
			EXEC dbo.Admin_Recalculate_6 @matchid, 6, @totalgoal

		-- bettype 13 : Clean Sheet 
		IF @betcount_13 > 0 
			EXEC dbo.Admin_Recalculate_13 @matchid = @matchid, @bettype = 13, @fth = @fth, @fta = @fta 

		-- bettype 16 : HT/FT		
		IF @betcount_16 > 0	
			EXEC dbo.Admin_Recalculate_4 @matchid, 16, @HTFT, @scorediff  --reuse 

		-- bettype 22 : Next Goal	
		IF @betcount_22 > 0
			EXEC dbo.Admin_Recalculate_22 @matchid, 22, @GoalRecord

		-- bettype 24 : Double Chance 
		IF @betcount_24 > 0
			EXEC dbo.Admin_Recalculate_24 @matchid = @matchid,  @bettype = 24, @scorediff = @scorediff

		-- bettype 25 : Draw no bet 
		IF @betcount_25 > 0
			EXEC dbo.Admin_Recalculate_25 @matchid = @matchid,  @bettype = 25, @scorediff = @scorediff
	
		-- bettype 26 : Both/One/Neither team to score  
		IF @betcount_26 > 0 
			EXEC dbo.Admin_Recalculate_26 @matchid = @matchid, @bettype = 26, @fth = @fth, @fta = @fta 	

		-- bettype 27 : To win to nil 
		IF @betcount_27 > 0 
			EXEC dbo.Admin_Recalculate_27 @matchid = @matchid, @bettype = 27, @fth = @fth, @fta = @fta 	
		
		-- bettype 28 : 3-way handicap
		IF @betcount_28 > 0 
			EXEC dbo.Admin_Recalculate_28 @matchid = @matchid, @bettype = 28, @fth = @fth, @fta = @fta 	
				
	END

	IF @Mode IN ('CAL-HT', 'CAL')
	BEGIN
	    DECLARE @betcount_7 int, @betcount_8 int, @betcount_12 int, @betcount_15 int, @betcount_21 int, @betcount_30 int
	    SELECT 
			@betcount_7 = ISNULL(SUM(case bettype when 7 then 1 else 0 end), 0),
			@betcount_8 = ISNULL(SUM(case bettype when 8 then 1 else 0 end), 0),
			@betcount_12 = ISNULL(SUM(case bettype when 12 then 1 else 0 end), 0),
			@betcount_15 = ISNULL(SUM(case bettype when 15 then 1 else 0 end), 0),
			@betcount_21 = ISNULL(SUM(case bettype when 21 then 1 else 0 end), 0),
			@betcount_30 = ISNULL(SUM(case bettype when 30 then 1 else 0 end), 0)
		FROM bettrans WITH(NOLOCK) 
		WHERE  matchid = @matchid
			   and bettype in (7,8,12,15,21,30)
			   
		-- exec in all cases, both 'FT' and 'HT'
		-- bettype 7 : 1st Handicap
		IF @betcount_7 > 0
			EXEC dbo.Admin_Recalculate_7 @matchid, 7, @hth, @hta, @betcount_7
		
		-- bettype 8 : 1st Over/Under
		IF @betcount_8 > 0
			EXEC dbo.Admin_Recalculate_8 @matchid, 8, @totalht
		
		-- bettype 12 : 1st Odd/Even
		IF @betcount_12 > 0
			EXEC dbo.Admin_Recalculate_2 @matchid, 12, @oddevenht
		
		-- bettype 15 : 1st 1x2
		IF @betcount_15 > 0
			EXEC dbo.Admin_Recalculate_5 @matchid, 15, @scorediff_ht
			
		-- bettype 21: 1st moneyline
		IF @betcount_21 > 0
			EXEC dbo.Admin_Recalculate_7 @matchid, 21, @hth, @hta
		
		-- bettype 30: 1st Correct Score (Reuse with bettype 4)
		IF @betcount_30 > 0
			EXEC dbo.Admin_Recalculate_4 @matchid,  30, @correctscore_ht, @scorediff_ht
			
	END

END


