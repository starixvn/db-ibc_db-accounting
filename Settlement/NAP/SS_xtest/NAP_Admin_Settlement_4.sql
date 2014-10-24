ALTER PROCEDURE [dbo].[NAP_Admin_Settlement_4] 
	 @MatchID			INT 
	,@Action			VARCHAR(10)	= 'CAL-SET'
	,@Mode				VARCHAR(6)	= 'CAL'
	,@SelectedSet		VARCHAR(50)	= ''	
	
AS
/*
	Created by: Jamie
	Date: 20141015
	Task: Settlement for Tennis ( including Sporting Solution) 
	DB: DBTXN/bodb02

	Revisions:

	Param's Explanation: 

*/
BEGIN
	SET NOCOUNT ON 

	DECLARE	 @fth					INT
			,@fta					INT
			,@HomeValueMatch		INT
			,@AwayValueMatch		INT
			,@TotalGameHomeMatch	INT
			,@TotalGameAwayMatch	INT

			,@TotalGameHomeSet1		INT
			,@TotalGameHomeSet2		INT
			,@TotalGameHomeSet3		INT
			,@TotalGameHomeSet4		INT
			,@TotalGameHomeSet5		INT
			,@TotalGameAwaySet1		INT
			,@TotalGameAwaySet2		INT
			,@TotalGameAwaySet3		INT
			,@TotalGameAwaySet4		INT
			,@TotalGameAwaySet5		INT
			,@SetxGameyHomeWON		VARCHAR(MAX) = '' 
			,@SetxGameyAwayWON		VARCHAR(MAX) = ''
			,@SetxGameyDRAW			VARCHAR(MAX) = ''
			,@SetxGameyREFUND		VARCHAR(MAX) = ''

			,@TotalSetMatch			INT 
			,@TotalGameMatch		INT
			,@TotalGameSet1			INT
			,@TotalGameSet2			INT
			,@TotalGameSet3			INT
			,@TotalGameSet4			INT
			,@TotalGameSet5			INT
			,@GameDiffMatch			SMALLMONEY 
			,@GameDiffSet1			SMALLMONEY 
			,@GameDiffSet2			SMALLMONEY 
			,@GameDiffSet3			SMALLMONEY 
			,@GameDiffSet4			SMALLMONEY 
			,@GameDiffSet5			SMALLMONEY 

			,@CorrectScoreMatch		NVARCHAR(10) 
			,@CorrectScoreSet1		NVARCHAR(10)
			,@CorrectScoreSet2		NVARCHAR(10)
			,@CorrectScoreSet3		NVARCHAR(10)
			,@CorrectScoreSet4		NVARCHAR(10)
			,@CorrectScoreSet5		NVARCHAR(10)
			,@OddEvenGameMatch		SMALLMONEY
			,@OddEvenSetMatch		SMALLMONEY 
			,@OddEvenGameSet1		SMALLMONEY
			,@OddEvenGameSet2		SMALLMONEY
			,@OddEvenGameSet3		SMALLMONEY
			,@OddEvenGameSet4		SMALLMONEY
			,@OddEvenGameSet5		SMALLMONEY

			,@betCount_1			INT	= 0 
			,@betCount_2			INT = 0 
			,@betCount_3			INT = 0 
			,@betCount_20			INT = 0 
			,@betCount_153			INT = 0 
			,@betCount_154			INT = 0 
			,@betCount_155			INT = 0 
			,@betCount_156			INT = 0 
			,@betCount_1301			INT = 0 
			,@betCount_1302			INT = 0 
			,@betCount_1303			INT = 0 
			,@betCount_1305			INT = 0 
			,@betCount_1306			INT = 0 
			,@betCount_1308			INT = 0 
			,@betCount_1311			INT = 0 
			,@betCount_1312			INT = 0 
			,@betCount_1316			INT = 0 
			,@betCount_1317			INT = 0 
			,@betCount_1318			INT = 0 
			,@betCount_1324			INT = 0 

	/*START: Ticket Count*/
	IF @Action='CAL' AND @SelectedSet LIKE '%6%'  -- Match Scope 
	BEGIN
		SELECT	 @betCount_1		= ISNULL(SUM(CASE WHEN bettype = 1 THEN 1 ELSE 0 END),0)
				,@betCount_2		= ISNULL(SUM(CASE WHEN bettype = 2 THEN 1 ELSE 0 END),0)
				,@betCount_3		= ISNULL(SUM(CASE WHEN bettype = 3 THEN 1 ELSE 0 END),0)
				,@betCount_20		= ISNULL(SUM(CASE WHEN bettype = 20 THEN 1 ELSE 0 END),0)
				,@betCount_153		= ISNULL(SUM(CASE WHEN bettype = 153 THEN 1 ELSE 0 END),0)
				,@betCount_1301		= ISNULL(SUM(CASE WHEN bettype = 1301 THEN 1 ELSE 0 END),0)
				,@betCount_1302		= ISNULL(SUM(CASE WHEN bettype = 1302 THEN 1 ELSE 0 END),0)
				,@betCount_1303		= ISNULL(SUM(CASE WHEN bettype = 1303 THEN 1 ELSE 0 END),0)
				,@betCount_1305		= ISNULL(SUM(CASE WHEN bettype = 1305 THEN 1 ELSE 0 END),0)
				,@betCount_1306		= ISNULL(SUM(CASE WHEN bettype = 1306 THEN 1 ELSE 0 END),0)
				,@betCount_1308		= ISNULL(SUM(CASE WHEN bettype = 1308 THEN 1 ELSE 0 END),0)

		FROM	Bettrans WITH (NOLOCK)
		WHERE	MatchID = @MatchID		
				AND bettype IN (1,2,3,20,153,1301,1302,1303,1305,1306,1308)
	END 
	IF @Action='CAL' AND @SelectedSet LIKE '%[1-5]%'	-- Set scope 
	BEGIN
		SELECT	 @betCount_154		= ISNULL(SUM(CASE WHEN bettype = 154 THEN 1 ELSE 0 END),0)
				,@betCount_155		= ISNULL(SUM(CASE WHEN bettype = 155 THEN 1 ELSE 0 END),0)
				,@betCount_156		= ISNULL(SUM(CASE WHEN bettype = 156 THEN 1 ELSE 0 END),0)
				,@betCount_1311		= ISNULL(SUM(CASE WHEN bettype = 1311 THEN 1 ELSE 0 END),0)
				,@betCount_1312		= ISNULL(SUM(CASE WHEN bettype = 1312 THEN 1 ELSE 0 END),0)
				,@betCount_1316		= ISNULL(SUM(CASE WHEN bettype = 1316 THEN 1 ELSE 0 END),0)
				,@betCount_1317		= ISNULL(SUM(CASE WHEN bettype = 1317 THEN 1 ELSE 0 END),0)
				,@betCount_1318		= ISNULL(SUM(CASE WHEN bettype = 1318 THEN 1 ELSE 0 END),0)
				,@betCount_1324		= ISNULL(SUM(CASE WHEN bettype = 1324 THEN 1 ELSE 0 END),0)

		FROM	Bettrans WITH (NOLOCK)
		WHERE	MatchID = @MatchID		
				AND bettype IN (154,155,156,1311,1312,1316,1317,1318,1324)
	END 	
	/*END: Ticket Count*/

	
	SELECT	 @HomeValueMatch		= SUM(CASE WHEN ResourceID='00' THEN HomeValue ELSE 0 END)
			,@AwayValueMatch		= SUM(CASE WHEN ResourceID='00' THEN AwayValue ELSE 0 END)
			,@TotalGameHomeMatch	= SUM(CASE WHEN ResourceID LIKE '0[1-5]' THEN HomeValue ELSE 0 END)
			,@TotalGameAwayMatch	= SUM(CASE WHEN ResourceID LIKE '0[1-5]' THEN AwayValue ELSE 0 END)
			,@TotalGameHomeSet1		= SUM(CASE WHEN ResourceID ='01' THEN HomeValue ELSE 0 END)
			,@TotalGameHomeSet2		= SUM(CASE WHEN ResourceID ='02' THEN HomeValue ELSE 0 END)
			,@TotalGameHomeSet3		= SUM(CASE WHEN ResourceID ='03' THEN HomeValue ELSE 0 END)
			,@TotalGameHomeSet4		= SUM(CASE WHEN ResourceID ='04' THEN HomeValue ELSE 0 END)
			,@TotalGameHomeSet5		= SUM(CASE WHEN ResourceID ='05' THEN HomeValue ELSE 0 END)
			,@TotalGameAwaySet1		= SUM(CASE WHEN ResourceID ='01' THEN AwayValue ELSE 0 END)
			,@TotalGameAwaySet2		= SUM(CASE WHEN ResourceID ='02' THEN AwayValue ELSE 0 END)
			,@TotalGameAwaySet3		= SUM(CASE WHEN ResourceID ='03' THEN AwayValue ELSE 0 END)
			,@TotalGameAwaySet4		= SUM(CASE WHEN ResourceID ='04' THEN AwayValue ELSE 0 END)
			,@TotalGameAwaySet5		= SUM(CASE WHEN ResourceID ='05' THEN AwayValue ELSE 0 END)
	FROM	DBPRO.bodb02.dbo.ResultDetail WITH (NOLOCK)
	WHERE	MatchID = @MatchID
			AND SettlementStatusID = 4 --Completed 
			AND ResultStatusID = 5 -- Score from Settlement Site 

	SELECT   @SetxGameyHomeWON		= @SetxGameyHomeWON + CASE WHEN CAST((CASE WHEN HomeValue='A' THEN '65' ELSE HomeValue END) AS INT) - CAST((CASE WHEN AwayValue ='A' THEN '65' ELSE AwayValue END) AS INT) > 0 
																		AND SettlementStatusID = 4 THEN ResourceID +',' ELSE '' END
			,@SetxGameyAwayWON		= @SetxGameyAwayWON + CASE WHEN CAST((CASE WHEN HomeValue='A' THEN '65' ELSE HomeValue END) AS INT) - CAST((CASE WHEN AwayValue ='A' THEN '65' ELSE AwayValue END) AS INT) < 0 
																		AND SettlementStatusID = 4 THEN ResourceID +',' ELSE '' END
			,@SetxGameyDRAW			= @SetxGameyDRAW + CASE WHEN CAST((CASE WHEN HomeValue='A' THEN '65' ELSE HomeValue END) AS INT) - CAST((CASE WHEN AwayValue ='A' THEN '65' ELSE AwayValue END) AS INT) = 0 
																		AND SettlementStatusID = 4 THEN ResourceID +',' ELSE '' END
			,@SetxGameyREFUND		= @SetxGameyREFUND + CASE WHEN SettlementStatusID = 1 THEN ResourceID +',' ELSE '' END 
	FROM	DBPRO.bodb02.dbo.ResultDetail WITH (NOLOCK)
	WHERE	MatchID = @MatchID
			AND SettlementStatusID > 0
			AND ResultStatusID = 5 -- Score from Settlement Site 
			AND ResourceID LIKE '0[1-5][0-9][1-9]'

	SELECT	 @CorrectScoreMatch		= CAST(@HomeValueMatch AS NVARCHAR(5)) + CAST(@AwayValueMatch AS NVARCHAR(5)) 
			,@CorrectScoreSet1		= CAST(@TotalGameHomeSet1 AS NVARCHAR(5)) + CAST(@TotalGameAwaySet1 AS NVARCHAR(5)) 
			,@CorrectScoreSet2		= CAST(@TotalGameHomeSet2 AS NVARCHAR(5)) + CAST(@TotalGameAwaySet2 AS NVARCHAR(5)) 
			,@CorrectScoreSet3		= CAST(@TotalGameHomeSet3 AS NVARCHAR(5)) + CAST(@TotalGameAwaySet3 AS NVARCHAR(5)) 
			,@CorrectScoreSet4		= CAST(@TotalGameHomeSet4 AS NVARCHAR(5)) + CAST(@TotalGameAwaySet4 AS NVARCHAR(5)) 
			,@CorrectScoreSet5		= CAST(@TotalGameHomeSet5 AS NVARCHAR(5)) + CAST(@TotalGameAwaySet5 AS NVARCHAR(5)) 
			,@OddEvenGameMatch		= (@TotalGameHomeMatch + @TotalGameAwayMatch) % 2
			,@OddEvenSetMatch		= (@HomeValueMatch + @AwayValueMatch)%2 
			,@OddEvenGameSet1		= (@TotalGameHomeSet1 + @TotalGameAwaySet1) % 2 
			,@OddEvenGameSet2		= (@TotalGameHomeSet2 + @TotalGameAwaySet2) % 2 
			,@OddEvenGameSet3		= (@TotalGameHomeSet3 + @TotalGameAwaySet3) % 2 
			,@OddEvenGameSet4		= (@TotalGameHomeSet4 + @TotalGameAwaySet4) % 2 
			,@OddEvenGameSet5		= (@TotalGameHomeSet5 + @TotalGameAwaySet5) % 2 

			,@TotalSetMatch			= @HomeValueMatch + @AwayValueMatch
			,@TotalGameMatch		= @TotalGameHomeMatch + @TotalGameAwayMatch
			,@TotalGameSet1			= @TotalGameHomeSet1 + @TotalGameAwaySet1
			,@TotalGameSet2			= @TotalGameHomeSet2 + @TotalGameAwaySet2
			,@TotalGameSet3			= @TotalGameHomeSet3 + @TotalGameAwaySet3
			,@TotalGameSet4			= @TotalGameHomeSet4 + @TotalGameAwaySet4
			,@TotalGameSet5			= @TotalGameHomeSet5 + @TotalGameAwaySet5
			,@GameDiffMatch			= @TotalGameHomeMatch - @TotalGameAwayMatch

	--SELECT @CorrectScoreSet1 CorrectScoreSet1
	--		,@CorrectScoreMatch CorrectScoreMatch
	--		,@OddEvenGameMatch OddEvenGameMatch
	--		, @OddEvenGameSet1 OddEvenGameSet1
	--		, @TotalSetMatch TotalSetMatch
	--		,@TotalGameMatch TotalGameMatch
	--		, @TotalGameSet1 TotalGameSet1
	--		, @GameDiffMatch GameDiffMatch

	IF @Action = 'CAL'
	BEGIN
		EXEC dbo.NAP_Admin_Calculate_Main_xtest 
					 @matchid			= @matchid
					,@action			= 'CAL-SET'
					,@mode				= 'CAL'
					,@SelectedSet		= @SelectedSet
					,@fth				= @HomeValueMatch
					,@fta				= @AwayValueMatch
					,@correctscore		= @CorrectScoreMatch
					,@OddEven			= @OddEvenGameMatch
					,@totalgoal			= @TotalGameMatch
					,@scorediff			= @GameDiffMatch
					,@OddEvenSetMatch	= @OddEvenSetMatch
					,@OddEvenGameSet1	= @OddEvenGameSet1	
					,@OddEvenGameSet2	= @OddEvenGameSet2	
					,@OddEvenGameSet3	= @OddEvenGameSet3	
					,@OddEvenGameSet4	= @OddEvenGameSet4	
					,@OddEvenGameSet5	= @OddEvenGameSet5	
					,@CorrectScoreSet1	= @CorrectScoreSet1
					,@CorrectScoreSet2	= @CorrectScoreSet2
					,@CorrectScoreSet3	= @CorrectScoreSet3	
					,@CorrectScoreSet4	= @CorrectScoreSet4	
					,@CorrectScoreSet5	= @CorrectScoreSet5	
					,@TotalGameHomeMatch= @TotalGameHomeMatch
					,@TotalGameAwayMatch= @TotalGameAwayMatch
					,@TotalGameHomeSet1 = @TotalGameHomeSet1
					,@TotalGameHomeSet2 = @TotalGameHomeSet2
					,@TotalGameHomeSet3 = @TotalGameHomeSet3
					,@TotalGameHomeSet4 = @TotalGameHomeSet4
					,@TotalGameHomeSet5 = @TotalGameHomeSet5
					,@TotalGameAwaySet1	= @TotalGameAwaySet1
					,@TotalGameAwaySet2	= @TotalGameAwaySet2
					,@TotalGameAwaySet3	= @TotalGameAwaySet3
					,@TotalGameAwaySet4	= @TotalGameAwaySet4
					,@TotalGameAwaySet5	= @TotalGameAwaySet5
					,@TotalSetMatch		= @TotalSetMatch
					,@TotalGameSet1		= @TotalGameSet1
					,@TotalGameSet2		= @TotalGameSet2
					,@TotalGameSet3		= @TotalGameSet3
					,@TotalGameSet4		= @TotalGameSet4
					,@TotalGameSet5		= @TotalGameSet5
					,@GameDiffSet1		= @GameDiffSet1	
					,@GameDiffSet2		= @GameDiffSet2
					,@GameDiffSet3		= @GameDiffSet3	 
					,@GameDiffSet4		= @GameDiffSet4	 
					,@GameDiffSet5		= @GameDiffSet5	 
					,@SetxGameyHomeWON	= @SetxGameyHomeWON
					,@SetxGameyAwayWON  = @SetxGameyAwayWON
					,@SetxGameyDRAW		= @SetxGameyDRAW
					,@SetxGameyREFUND	= @SetxGameyREFUND
					,@betCount_1		= @betCount_1
					,@betCount_2		= @betCount_2
					,@betCount_3		= @betCount_3
					,@betCount_20		= @betCount_20
					,@betCount_153		= @betCount_153
					,@betCount_154		= @betCount_154
					,@betCount_155		= @betCount_155
					,@betCount_156		= @betCount_156
					,@betcount_1301		= @betCount_1301
					,@betcount_1302		= @betCount_1302
					,@betcount_1303		= @betCount_1303
					,@betcount_1305		= @betCount_1305
					,@betcount_1306		= @betCount_1306
					,@betcount_1308		= @betCount_1308
					,@betcount_1311		= @betCount_1311
					,@betcount_1312		= @betCount_1312
					,@betcount_1316		= @betCount_1316
					,@betcount_1317		= @betCount_1317
					,@betcount_1318		= @betCount_1318
					,@betcount_1324		= @betCount_1324
	END
END