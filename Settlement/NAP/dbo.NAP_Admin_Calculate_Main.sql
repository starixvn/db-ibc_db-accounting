ALTER PROCEDURE [dbo].[NAP_Admin_Calculate_Main] @matchid INT
	,@mode							VARCHAR(15)	= 'CAL'
	,@action						VARCHAR(20)	= 'CAL'
	,@fth							INT			= NULL
	,@fta							INT			= NULL
	,@hth							INT			= NULL
	,@hta							INT			= NULL
	,@sporttype						TINYINT		= NULL
	,@betstatus						NVARCHAR(50)= NULL
	,@GoalRecord					VARCHAR(50)	= NULL
	,@matchCode						NVARCHAR(50)= NULL
	,@oddeven						SMALLMONEY	= NULL
	,@oddevenht						SMALLMONEY	= NULL
	,@oddevenhome					SMALLMONEY	= NULL
	,@oddevenhome_ht				SMALLMONEY	= NULL
	,@oddevenaway					SMALLMONEY	= NULL
	,@oddevenaway_ht				SMALLMONEY	= NULL
	,@totalgoal						SMALLMONEY	= NULL
	,@totalht						SMALLMONEY	= NULL
	,@totalhome 					SMALLMONEY 	= NULL
	,@totalaway 					SMALLMONEY 	= NULL
	,@goaldiff  					SMALLMONEY 	= NULL
	,@scorediff 					SMALLMONEY 	= NULL
	,@scorediff_ht 					SMALLMONEY 	= NULL
	,@correctscore 					NVARCHAR(10)= NULL
	,@correctscore_ht				NVARCHAR(10)= NULL
	,@HTFT							NVARCHAR(10)= NULL
	,@FGLG1 						VARCHAR(10) = NULL
	,@FGLG2 						VARCHAR(10) = NULL
	,@HT_FGLG1 						VARCHAR(10) = NULL
	,@HT_FGLG2 						VARCHAR(10) = NULL
	,@TennisTotal					SMALLINT 	= NULL
	,@T_Home 						SMALLINT 	= NULL
	,@T_Away 						SMALLINT 	= NULL
	,@SelectedSet					VARCHAR(50) = NULL 
	,@SelectedSettleFinishedGame	VARCHAR(50)	= NULL 
	,@TotalGameHomeMatch			INT			= NULL
	,@TotalGameAwayMatch			INT			= NULL
	,@TotalGameHomeSet1				INT			= NULL 
	,@TotalGameHomeSet2				INT			= NULL 
	,@TotalGameHomeSet3				INT			= NULL 
	,@TotalGameHomeSet4				INT			= NULL
	,@TotalGameHomeSet5				INT			= NULL 
	,@TotalGameAwaySet1				INT			= NULL 
	,@TotalGameAwaySet2				INT			= NULL
	,@TotalGameAwaySet3				INT			= NULL
	,@TotalGameAwaySet4				INT			= NULL 
	,@TotalGameAwaySet5				INT			= NULL 
	,@TotalSetMatch					INT			= NULL
	,@TotalGameSet1					INT			= NULL
	,@TotalGameSet2					INT			= NULL
	,@TotalGameSet3					INT			= NULL
	,@TotalGameSet4					INT			= NULL
	,@TotalGameSet5					INT			= NULL
	,@OddEvenSetMatch				SMALLMONEY  = NULL 
	,@OddEvenGameSet1				SMALLMONEY	= NULL
	,@OddEvenGameSet2				SMALLMONEY	= NULL
	,@OddEvenGameSet3				SMALLMONEY	= NULL
	,@OddEvenGameSet4				SMALLMONEY	= NULL
	,@OddEvenGameSet5				SMALLMONEY	= NULL
	,@GameDiffSet1					SMALLMONEY	= NULL 
	,@GameDiffSet2					SMALLMONEY	= NULL 
	,@GameDiffSet3					SMALLMONEY	= NULL 
	,@GameDiffSet4					SMALLMONEY	= NULL 
	,@GameDiffSet5					SMALLMONEY	= NULL 
	,@CorrectScoreSet1				NVARCHAR(10)= NULL 
	,@CorrectScoreSet2				NVARCHAR(10)= NULL 
	,@CorrectScoreSet3				NVARCHAR(10)= NULL 
	,@CorrectScoreSet4				NVARCHAR(10)= NULL 
	,@CorrectScoreSet5				NVARCHAR(10)= NULL 
	,@SetxGameyHomeWON				VARCHAR(MAX)= NULL
	,@SetxGameyAwayWON				VARCHAR(MAX)= NULL 
	,@SetxGameyDRAW					VARCHAR(MAX)= NULL 
	,@SetxGameyREFUND				VARCHAR(MAX)= NULL
	,@SetxGameyFinishedGame			VARCHAR(MAX)= NULL 
	,@isRefundHT					BIT 		= NULL
	,@IsHTCal						BIT 		= NULL
	,@betcount_1 					INT 		= NULL
	,@betcount_2 					INT 		= NULL
	,@betcount_3 					INT 		= NULL
	,@betcount_4 					INT 		= NULL
	,@betcount_5 					INT 		= NULL
	,@betcount_6 					INT 		= NULL
	,@betcount_16 					INT 		= NULL
	,@betcount_20 					INT 		= NULL
	,@betcount_22 					INT 		= NULL
	,@betcount_13 					INT 		= NULL
	,@betcount_24 					INT 		= NULL
	,@betcount_25 					INT 		= NULL
	,@betcount_26 					INT 		= NULL
	,@betcount_27 					INT 		= NULL
	,@betcount_28 					INT 		= NULL
	,@betcount_121 					INT 		= NULL
	,@betcount_122 					INT 		= NULL
	,@betcount_123 					INT 		= NULL
	,@betcount_124 					INT 		= NULL
	,@betcount_128 					INT 		= NULL	
	,@betcount_130 					INT 		= NULL
	,@betcount_131 					INT 		= NULL
	,@betcount_132 					INT 		= NULL
	,@betcount_133 					INT 		= NULL
	,@betcount_134 					INT 		= NULL
	,@betcount_135 					INT 		= NULL	
	,@betcount_137 					INT 		= NULL	
	,@betcount_139 					INT 		= NULL
	,@betcount_140 					INT 		= NULL
	,@betcount_141 					INT 		= NULL
	,@betcount_142 					INT 		= NULL
	,@betcount_144 					INT 		= NULL
	,@betcount_145 					INT 		= NULL
	,@betcount_146 					INT 		= NULL
	,@betcount_147 					INT 		= NULL
	,@betcount_148 					INT 		= NULL
	,@betcount_149 					INT 		= NULL
	,@betcount_150 					INT 		= NULL
	,@betcount_152 					INT 		= NULL
	,@betcount_1201					INT 		= NULL
	,@betcount_1203					INT 		= NULL
	,@betcount_1204					INT 		= NULL
	,@betcount_1205					INT 		= NULL
	,@betcount_1206					INT 		= NULL
	,@betcount_1224					INT 		= NULL
	,@betcount_7 					INT 		= NULL
	,@betcount_8 					INT 		= NULL
	,@betcount_12 					INT 		= NULL
	,@betcount_15 					INT 		= NULL
	,@betcount_21 					INT 		= NULL
	,@betcount_30 					INT 		= NULL
	,@betcount_125 					INT 		= NULL
	,@betcount_126 					INT 		= NULL
	,@betcount_129 					INT 		= NULL
	,@betcount_136 					INT 		= NULL
	,@betcount_138 					INT 		= NULL
	,@betcount_143 					INT 		= NULL
	,@betcount_151 					INT 		= NULL
	,@betcount_14					INT 		= NULL
	,@betcount_127					INT 		= NULL
	,@betCount_153					INT 		= NULL
	,@betCount_154					INT 		= NULL
	,@betCount_155					INT 		= NULL
	,@betCount_156					INT 		= NULL
	,@betcount_1301					INT			= NULL		-- Tennis SS 
	,@betCount_1302					INT			= NULL	
	,@betCount_1303					INT			= NULL	
	,@betCount_1305					INT			= NULL	
	,@betCount_1306					INT			= NULL	
	,@betCount_1308					INT			= NULL	
	,@betCount_1311					INT			= NULL	
	,@betCount_1312					INT			= NULL	
	,@betCount_1316					INT			= NULL	
	,@betCount_1317					INT			= NULL	
	,@betCount_1318					INT			= NULL	
	,@betCount_1324					INT			= NULL	
	,@row_count						INT 		= NULL
	,@IsSettleAbandonedMatch		BIT 		= 0
	,@IsSettleAbandonedMatchBetFair BIT 		= 0
	,@IsExcludeBetdaq				BIT 		= 0
	,@IsExcludeBetfair				BIT 		= 0
	,@IsSettleAbandonedMatchIBC		BIT 		= 0
	,@LGOnly						BIT 		= NULL
	,@IncludeLG						BIT 		= NULL
	,@matchdate						DATETIME	= NULL
	,@CalledByBrokerService			BIT			= 0
AS
/*
	Created: Viet
	Task : Covered SP for settlement
	Original SP: Admin_Settlement_3
	DB: EXECREP SP (DBTrans_Bet)

	Revisions:
		- 20140304@Kathy: Execute settlement for abandoned/postponed matches- Clean Sheet, Both/One/Neither team to score, To Win To Nil 
		- 20140424@Lukas: add DBTP server 
		- 20140426@Kathy: Add 1H Total Goal and 1H FGLG bettypes (126, 127) [Redmine:#14449]
		- 20140617@Kathy: Apply BetRadar [Redmine:#17142]
		- 20140710@Kathy: Apply BetRadar - PenaltyShootout(135) [Redmine:#17142]
		- 20140728@Kathy: Settle determined tickets for Correct Score(4,30), Total Goal (6,126) [Redmine:#19310]
		- 20140807@Kathy: Support new 11 bettypes [Redmine:#19667]
		- 20141016@Jamie: Sporting Solution for Tennis [Redmine:#23034]
		
	Param's Explanation:
		@action			@mode
		 CAL			 CAL, CAL-HT, CAL-FT, UNDO, 
		 CAL-FGLG		 CAL, CAL-HT, CAL-FT
		 REFUND			 ALL, HT, FT, BetDaq, BetFair
		 REFUND-FGLG	 REFUND-FT, REFUND-HT
		 CAL-PS			 CAL
		 CAL-SET		 CAL		--Tennis 

*/
BEGIN
	SET NOCOUNT ON;

	IF @@SERVERNAME IN ('DB052', 'DB053', 'DB054', 'DB06', 'DBTP', 'DB231', 'DB232','DB215')
		AND @CalledByBrokerService = 0
	BEGIN
		-- DB052/DB053/DB054/DB06: got servicebroker, then just send a message to service broker and then let it to handle the rest.
		DECLARE @sMessage NVARCHAR(MAX)

		SET @sMessage = '
			EXEC dbo.NAP_Admin_Calculate_Main @matchid = ' + CONVERT(NVARCHAR(50), @matchid) + '
			,@mode = ' + CASE 
				WHEN @mode IS NULL THEN 'NULL'
				ELSE '''' + CONVERT(NVARCHAR(50), @mode) + ''''
				END + '
			,@action = ' + CASE 
				WHEN @action IS NULL THEN 'NULL'
				ELSE '''' + CONVERT(NVARCHAR(50), @action) + ''''
				END + '
			,@fth = ' + CASE 
				WHEN @fth IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @fth)
				END + '
			,@fta = ' + CASE 
				WHEN @fta IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @fta)
				END + '
			,@hth = ' + CASE 
				WHEN @hth IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @hth)
				END + '
			,@hta = ' + CASE 
				WHEN @hta IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @hta)
				END + '
			,@sporttype = ' + CASE 
				WHEN @sporttype IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @sporttype)
				END + '
			,@betstatus = ' + CASE 
				WHEN @betstatus IS NULL THEN 'NULL'
				ELSE '''' + CONVERT(NVARCHAR(50), @betstatus) + ''''
				END + '
			,@GoalRecord = ' + CASE 
				WHEN @GoalRecord IS NULL THEN 'NULL'
				ELSE '''' + CONVERT(NVARCHAR(50), @GoalRecord) + ''''
				END + '
			,@matchCode = ' + CASE 
				WHEN @matchCode IS NULL THEN 'NULL'
				ELSE '''' + CONVERT(NVARCHAR(50), @matchCode) + ''''
				END + '
			,@oddeven = ' + CASE 
				WHEN @oddeven IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @oddeven)
				END + '
			,@oddevenht = ' + CASE 
				WHEN @oddevenht IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @oddevenht)
				END + '
			,@oddevenhome = ' + CASE 
				WHEN @oddevenhome IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @oddevenhome)
				END + '
			,@oddevenhome_ht = ' + CASE 
				WHEN @oddevenhome_ht IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @oddevenhome_ht)
				END + '
			,@oddevenaway = ' + CASE 
				WHEN @oddevenaway IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @oddevenaway)
				END + '
			,@oddevenaway_ht = ' + CASE 
				WHEN @oddevenaway_ht IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @oddevenaway_ht)
				END + '
			,@totalgoal = ' + CASE 
				WHEN @totalgoal IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @totalgoal)
				END + '
			,@totalht = ' + CASE 
				WHEN @totalht IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @totalht)
				END + '
			,@totalhome = ' + CASE 
				WHEN @totalhome IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @totalhome)
				END + '
			,@totalaway = ' + CASE 
				WHEN @totalaway IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @totalaway)
				END + '
			,@goaldiff = ' + CASE 
				WHEN @goaldiff IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @goaldiff)
				END + '
			,@scorediff = ' + CASE 
				WHEN @scorediff IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @scorediff)
				END + '
			,@scorediff_ht = ' + CASE 
				WHEN @scorediff_ht IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @scorediff_ht)
				END + '
			,@correctscore = ' + CASE 
				WHEN @correctscore IS NULL THEN 'NULL'
				ELSE '''' + CONVERT(NVARCHAR(50), @correctscore) + ''''
				END + '
			,@correctscore_ht = ' + CASE 
				WHEN @correctscore_ht IS NULL THEN 'NULL'
				ELSE '''' + CONVERT(NVARCHAR(50), @correctscore_ht) + ''''
				END + '
			,@HTFT = ' + CASE 
				WHEN @HTFT IS NULL THEN 'NULL'
				ELSE '''' + CONVERT(NVARCHAR(50), @HTFT) + ''''
				END + '
			,@FGLG1 = ' + CASE 
				WHEN @FGLG1 IS NULL THEN 'NULL'
				ELSE '''' + CONVERT(NVARCHAR(50), @FGLG1) + ''''
				END + '
			,@FGLG2 = ' + CASE 
				WHEN @FGLG2 IS NULL THEN 'NULL'
				ELSE '''' + CONVERT(NVARCHAR(50), @FGLG2) + ''''
				END + '
			,@HT_FGLG1 = ' + CASE 
				WHEN @HT_FGLG1 IS NULL THEN 'NULL'
				ELSE '''' + CONVERT(NVARCHAR(50), @HT_FGLG1) + ''''
				END + '
			,@HT_FGLG2 = ' + CASE 
				WHEN @HT_FGLG2 IS NULL THEN 'NULL'
				ELSE '''' + CONVERT(NVARCHAR(50), @HT_FGLG2) + ''''
				END + '
			,@TennisTotal = ' + CASE 
				WHEN @TennisTotal IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @TennisTotal)
				END + '
			,@T_Home = ' + CASE 
				WHEN @T_Home IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @T_Home)
				END + '
			,@T_Away = ' + CASE 
				WHEN @T_Away IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @T_Away)
				END + '
			,@SelectedSet = ' + CASE WHEN @SelectedSet IS NULL THEN 'NULL' ELSE '''' + CONVERT(NVARCHAR(50),@SelectedSet)+ '''' END + ' 
			,@SelectedSettleFinishedGame = ' + CASE WHEN @SelectedSettleFinishedGame IS NULL THEN 'NULL' ELSE '''' + CONVERT(NVARCHAR(50),@SelectedSettleFinishedGame)+ '''' END + ' 
			,@TotalGameHomeMatch = ' + CASE WHEN @TotalGameHomeMatch IS NULL THEN 'NULL' ELSE CONVERT(NVARCHAR(50),@TotalGameHomeMatch,0) END + ' 
			,@TotalGameAwayMatch = ' + CASE WHEN @TotalGameAwayMatch IS NULL THEN 'NULL' ELSE CONVERT(NVARCHAR(50),@TotalGameAwayMatch,0) END + ' 
			,@TotalGameHomeSet1 = ' + CASE WHEN @TotalGameHomeSet1 IS NULL THEN 'NULL' ELSE  CONVERT(NVARCHAR(50),@TotalGameHomeSet1,0) END + ' 
			,@TotalGameHomeSet2 = ' + CASE WHEN @TotalGameHomeSet2 IS NULL THEN 'NULL' ELSE  CONVERT(NVARCHAR(50),@TotalGameHomeSet2,0) END + '
			,@TotalGameHomeSet3 = ' + CASE WHEN @TotalGameHomeSet3 IS NULL THEN 'NULL' ELSE  CONVERT(NVARCHAR(50),@TotalGameHomeSet3,0) END + '
			,@TotalGameHomeSet4 = ' + CASE WHEN @TotalGameHomeSet4 IS NULL THEN 'NULL' ELSE  CONVERT(NVARCHAR(50),@TotalGameHomeSet4,0) END + '
			,@TotalGameHomeSet5 = ' + CASE WHEN @TotalGameHomeSet5 IS NULL THEN 'NULL' ELSE  CONVERT(NVARCHAR(50),@TotalGameHomeSet5,0) END + '
			,@TotalGameAwaySet1 = ' + CASE WHEN @TotalGameAwaySet1 IS NULL THEN 'NULL' ELSE  CONVERT(NVARCHAR(50),@TotalGameAwaySet1,0) END + '
			,@TotalGameAwaySet2 = ' + CASE WHEN @TotalGameAwaySet2 IS NULL THEN 'NULL' ELSE  CONVERT(NVARCHAR(50),@TotalGameAwaySet2,0) END + '
			,@TotalGameAwaySet3 = ' + CASE WHEN @TotalGameAwaySet3 IS NULL THEN 'NULL' ELSE  CONVERT(NVARCHAR(50),@TotalGameAwaySet3,0) END + '
			,@TotalGameAwaySet4 = ' + CASE WHEN @TotalGameAwaySet4 IS NULL THEN 'NULL' ELSE  CONVERT(NVARCHAR(50),@TotalGameAwaySet4,0) END + '
			,@TotalGameAwaySet5 = ' + CASE WHEN @TotalGameAwaySet5 IS NULL THEN 'NULL' ELSE  CONVERT(NVARCHAR(50),@TotalGameAwaySet5,0) END + '
			,@TotalSetMatch = ' + CASE WHEN @TotalSetMatch IS NULL THEN 'NULL' ELSE  CONVERT(NVARCHAR(50),@TotalSetMatch,0) END + '
			,@TotalGameSet1 = ' + CASE WHEN @TotalGameSet1 IS NULL THEN 'NULL' ELSE  CONVERT(NVARCHAR(50),@TotalGameSet1,0) END + '
			,@TotalGameSet2 = ' + CASE WHEN @TotalGameSet2 IS NULL THEN 'NULL' ELSE  CONVERT(NVARCHAR(50),@TotalGameSet2,0) END + '
			,@TotalGameSet3 = ' + CASE WHEN @TotalGameSet3 IS NULL THEN 'NULL' ELSE  CONVERT(NVARCHAR(50),@TotalGameSet3,0) END + '
			,@TotalGameSet4 = ' + CASE WHEN @TotalGameSet4 IS NULL THEN 'NULL' ELSE  CONVERT(NVARCHAR(50),@TotalGameSet4,0) END + '
			,@TotalGameSet5 = ' + CASE WHEN @TotalGameSet5 IS NULL THEN 'NULL' ELSE  CONVERT(NVARCHAR(50),@TotalGameSet5,0) END + '
			,@OddEvenSetMatch = ' + CASE WHEN @OddEvenSetMatch IS NULL THEN 'NULL' ELSE  CONVERT(NVARCHAR(50),@OddEvenSetMatch,0) END + '
			,@OddEvenGameSet1 = ' + CASE WHEN @OddEvenGameSet1 IS NULL THEN 'NULL' ELSE  CONVERT(NVARCHAR(50),@OddEvenGameSet1,0) END + '
			,@OddEvenGameSet2 = ' + CASE WHEN @OddEvenGameSet2 IS NULL THEN 'NULL' ELSE  CONVERT(NVARCHAR(50),@OddEvenGameSet2,0) END + '
			,@OddEvenGameSet3 = ' + CASE WHEN @OddEvenGameSet3 IS NULL THEN 'NULL' ELSE  CONVERT(NVARCHAR(50),@OddEvenGameSet3,0) END + '
			,@OddEvenGameSet4 = ' + CASE WHEN @OddEvenGameSet4 IS NULL THEN 'NULL' ELSE  CONVERT(NVARCHAR(50),@OddEvenGameSet4,0) END + '
			,@OddEvenGameSet5 = ' + CASE WHEN @OddEvenGameSet5 IS NULL THEN 'NULL' ELSE  CONVERT(NVARCHAR(50),@OddEvenGameSet5,0) END + '
			,@GameDiffSet1 = ' + CASE WHEN @GameDiffSet1 IS NULL THEN 'NULL' ELSE  CONVERT(NVARCHAR(50),@GameDiffSet1,0) END + '
			,@GameDiffSet2 = ' + CASE WHEN @GameDiffSet2 IS NULL THEN 'NULL' ELSE  CONVERT(NVARCHAR(50),@GameDiffSet2,0) END + '
			,@GameDiffSet3 = ' + CASE WHEN @GameDiffSet3 IS NULL THEN 'NULL' ELSE  CONVERT(NVARCHAR(50),@GameDiffSet3,0) END + '
			,@GameDiffSet4 = ' + CASE WHEN @GameDiffSet4 IS NULL THEN 'NULL' ELSE  CONVERT(NVARCHAR(50),@GameDiffSet4,0) END + '
			,@GameDiffSet5 = ' + CASE WHEN @GameDiffSet5 IS NULL THEN 'NULL' ELSE  CONVERT(NVARCHAR(50),@GameDiffSet5,0) END + '
			,@CorrectScoreSet1 = ' + CASE WHEN @CorrectScoreSet1 IS NULL THEN 'NULL' ELSE '''' + @CorrectScoreSet1 + '''' END + '
			,@CorrectScoreSet2 = ' + CASE WHEN @CorrectScoreSet2 IS NULL THEN 'NULL' ELSE '''' + @CorrectScoreSet2 + '''' END + '
			,@CorrectScoreSet3 = ' + CASE WHEN @CorrectScoreSet3 IS NULL THEN 'NULL' ELSE '''' + @CorrectScoreSet3 + '''' END + '
			,@CorrectScoreSet4 = ' + CASE WHEN @CorrectScoreSet4 IS NULL THEN 'NULL' ELSE '''' + @CorrectScoreSet4 + '''' END + '
			,@CorrectScoreSet5 = ' + CASE WHEN @CorrectScoreSet5 IS NULL THEN 'NULL' ELSE '''' + @CorrectScoreSet5 + '''' END + '
			,@SetxGameyHomeWON = ' + CASE WHEN @SetxGameyHomeWON IS NULL THEN 'NULL' ELSE '''' + @SetxGameyHomeWON + '''' END + '
			,@SetxGameyAwayWON = ' + CASE WHEN @SetxGameyAwayWON IS NULL THEN 'NULL' ELSE '''' + @SetxGameyAwayWON + '''' END + '
			,@SetxGameyDRAW = ' + CASE WHEN @SetxGameyDRAW IS NULL THEN 'NULL' ELSE '''' + @SetxGameyDRAW + '''' END + '
			,@SetxGameyREFUND = ' + CASE WHEN @SetxGameyREFUND IS NULL THEN 'NULL' ELSE '''' + @SetxGameyREFUND + '''' END + '
			,@SetxGameyFinishedGame = ' + CASE WHEN @SetxGameyFinishedGame IS NULL THEN 'NULL' ELSE '''' + @SetxGameyFinishedGame + '''' END + '
			,@isRefundHT = ' + CASE 
				WHEN @isRefundHT IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @isRefundHT)
				END + '
			,@IsHTCal = ' + CASE 
				WHEN @IsHTCal IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @IsHTCal)
				END + '
			,@betcount_1 = ' + CASE 
				WHEN @betcount_1 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @betcount_1)
				END + '
			,@betcount_2 = ' + CASE 
				WHEN @betcount_2 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @betcount_2)
				END + '
			,@betcount_3 = ' + CASE 
				WHEN @betcount_3 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @betcount_3)
				END + '
			,@betcount_4 = ' + CASE 
				WHEN @betcount_4 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @betcount_4)
				END + '
			,@betcount_5 = ' + CASE 
				WHEN @betcount_5 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @betcount_5)
				END + '
			,@betcount_6 = ' + CASE 
				WHEN @betcount_6 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @betcount_6)
				END + '
			,@betcount_16 = ' + CASE 
				WHEN @betcount_16 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @betcount_16)
				END + '
			,@betcount_20 = ' + CASE 
				WHEN @betcount_20 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @betcount_20)
				END + '
			,@betcount_22 = ' + CASE 
				WHEN @betcount_22 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @betcount_22)
				END + '
			,@betcount_13 = ' + CASE 
				WHEN @betcount_13 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @betcount_13)
				END + '
			,@betcount_24 = ' + CASE 
				WHEN @betcount_24 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @betcount_24)
				END + '
			,@betcount_25 = ' + CASE 
				WHEN @betcount_25 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @betcount_25)
				END + '
			,@betcount_26 = ' + CASE 
				WHEN @betcount_26 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @betcount_26)
				END + '
			,@betcount_27 = ' + CASE 
				WHEN @betcount_27 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @betcount_27)
				END + '
			,@betcount_28 = ' + CASE 
				WHEN @betcount_28 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @betcount_28)
				END + '
			,@betcount_121 = ' + CASE 
				WHEN @betcount_121 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @betcount_121)
				END + '
			,@betcount_122 = ' + CASE 
				WHEN @betcount_122 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @betcount_122)
				END + '
			,@betcount_123 = ' + CASE 
				WHEN @betcount_123 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @betcount_123)
				END + '
			,@betcount_124 = ' + CASE 
				WHEN @betcount_124 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @betcount_124)
				END + '
			,@betcount_128 = ' + CASE 
				WHEN @betcount_128 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @betcount_128)
				END + '
			,@betcount_130 = ' + CASE 
				WHEN @betcount_130 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @betcount_130)
				END + '
			,@betcount_131 = ' + CASE 
				WHEN @betcount_131 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @betcount_131)
				END + '
			,@betcount_132 = ' + CASE 
				WHEN @betcount_132 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @betcount_132)
				END + '
			,@betcount_133 = ' + CASE 
				WHEN @betcount_133 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @betcount_133)
				END + '
			,@betcount_134 = ' + CASE 
				WHEN @betcount_134 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @betcount_134)
				END + '
			,@betcount_135 = ' + CASE 
				WHEN @betcount_135 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @betcount_135)
				END + '
			,@betcount_137 = ' + CASE 
				WHEN @betcount_137 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @betcount_137)
				END + '
			,@betcount_139 = ' + CASE 
				WHEN @betcount_139 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @betcount_139)
				END + '
			,@betcount_140 = ' + CASE 
				WHEN @betcount_140 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @betcount_140)
				END + '
			,@betcount_141 = ' + CASE 
				WHEN @betcount_141 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @betcount_141)
				END + '
			,@betcount_142 = ' + CASE 
				WHEN @betcount_142 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @betcount_142)
				END + '
			,@betcount_144 = ' + CASE 
				WHEN @betcount_144 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @betcount_144)
				END + '
			,@betcount_145 = ' + CASE 
				WHEN @betcount_145 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @betcount_145)
				END + '
			,@betcount_146 = ' + CASE 
				WHEN @betcount_146 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @betcount_146)
				END + '
			,@betcount_147 = ' + CASE 
				WHEN @betcount_147 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @betcount_147)
				END + '
			,@betcount_148 = ' + CASE 
				WHEN @betcount_148 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @betcount_148)
				END + '
			,@betcount_149 = ' + CASE 
				WHEN @betcount_149 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @betcount_149)
				END + '
			,@betcount_150 = ' + CASE 
				WHEN @betcount_150 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @betcount_150)
				END + '
			,@betcount_152 = ' + CASE 
				WHEN @betcount_152 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @betcount_152)
				END + '		
			,@betcount_1201 = ' + CASE 
				WHEN @betcount_1201 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @betcount_1201)
				END + '
			,@betcount_1203 = ' + CASE 
				WHEN @betcount_1203 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @betcount_1203)
				END + '
			,@betcount_1204 = ' + CASE 
				WHEN @betcount_1204 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @betcount_1204)
				END + '
			,@betcount_1205 = ' + CASE 
				WHEN @betcount_1205 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @betcount_1205)
				END + '
			,@betcount_1206 = ' + CASE 
				WHEN @betcount_1206 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @betcount_1206)
				END + '
			,@betcount_1224 = ' + CASE 
				WHEN @betcount_1224 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @betcount_1224)
				END + '
			,@betcount_7 = ' + CASE 
				WHEN @betcount_7 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @betcount_7)
				END + '
			,@betcount_8 = ' + CASE 
				WHEN @betcount_8 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @betcount_8)

				END + '
			,@betcount_12 = ' + CASE 
				WHEN @betcount_12 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @betcount_12)
				END + '
			,@betcount_15 = ' + CASE 
				WHEN @betcount_15 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @betcount_15)
				END + '
			,@betcount_21 = ' + CASE 
				WHEN @betcount_21 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @betcount_21)
				END + '
			,@betcount_30 = ' + CASE 
				WHEN @betcount_30 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @betcount_30)
				END + '
			,@betcount_125 = ' + CASE 
				WHEN @betcount_125 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @betcount_125)
				END + '
			,@betcount_126 = ' + CASE 
				WHEN @betcount_126 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @betcount_126)
				END + '
			,@betcount_129 = ' + CASE 
				WHEN @betcount_129 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @betcount_129)
				END + '
			,@betcount_136 = ' + CASE 
				WHEN @betcount_136 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @betcount_136)
				END + '
			,@betcount_138 = ' + CASE 
				WHEN @betcount_138 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @betcount_138)
				END + '
			,@betcount_143 = ' + CASE 
				WHEN @betcount_143 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @betcount_143)
				END + '
			,@betcount_151 = ' + CASE 
				WHEN @betcount_151 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @betcount_151)
				END + '	
			,@betcount_14 = ' + CASE 
				WHEN @betcount_14 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @betcount_14)
				END + '
			,@betcount_127 = ' + CASE 
				WHEN @betcount_127 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @betcount_127)
				END + '
			,@betCount_153 = ' + CASE WHEN @betCount_153 IS NULL THEN 'NULL' ELSE CONVERT(NVARCHAR(50), @betCount_153) END + ' 
			,@betCount_154 = ' + CASE WHEN @betCount_154 IS NULL THEN 'NULL' ELSE CONVERT(NVARCHAR(50), @betCount_154) END + '
			,@betCount_155 = ' + CASE WHEN @betCount_155 IS NULL THEN 'NULL' ELSE CONVERT(NVARCHAR(50), @betCount_155) END + '
			,@betCount_156 = ' + CASE WHEN @betCount_156 IS NULL THEN 'NULL' ELSE CONVERT(NVARCHAR(50), @betCount_156) END + '
			,@betCount_1301 = ' + CASE WHEN @betCount_1301 IS NULL THEN 'NULL' ELSE CONVERT(NVARCHAR(50), @betCount_1301) END + '
			,@betCount_1302 = ' + CASE WHEN @betCount_1302 IS NULL THEN 'NULL' ELSE CONVERT(NVARCHAR(50), @betCount_1302) END + '
			,@betCount_1303 = ' + CASE WHEN @betCount_1303 IS NULL THEN 'NULL' ELSE CONVERT(NVARCHAR(50), @betCount_1303) END + '
			,@betCount_1305 = ' + CASE WHEN @betCount_1305 IS NULL THEN 'NULL' ELSE CONVERT(NVARCHAR(50), @betCount_1305) END + '
			,@betCount_1306 = ' + CASE WHEN @betCount_1306 IS NULL THEN 'NULL' ELSE CONVERT(NVARCHAR(50), @betCount_1306) END + '
			,@betCount_1308 = ' + CASE WHEN @betCount_1308 IS NULL THEN 'NULL' ELSE CONVERT(NVARCHAR(50), @betCount_1308) END + '
			,@betCount_1311 = ' + CASE WHEN @betCount_1311 IS NULL THEN 'NULL' ELSE CONVERT(NVARCHAR(50), @betCount_1311) END + '
			,@betCount_1312 = ' + CASE WHEN @betCount_1312 IS NULL THEN 'NULL' ELSE CONVERT(NVARCHAR(50), @betCount_1312) END + '
			,@betCount_1316 = ' + CASE WHEN @betCount_1316 IS NULL THEN 'NULL' ELSE CONVERT(NVARCHAR(50), @betCount_1316) END + '
			,@betCount_1317 = ' + CASE WHEN @betCount_1317 IS NULL THEN 'NULL' ELSE CONVERT(NVARCHAR(50), @betCount_1317) END + '
			,@betCount_1318 = ' + CASE WHEN @betCount_1318 IS NULL THEN 'NULL' ELSE CONVERT(NVARCHAR(50), @betCount_1318) END + '
			,@betCount_1324 = ' + CASE WHEN @betCount_1324 IS NULL THEN 'NULL' ELSE CONVERT(NVARCHAR(50), @betCount_1324) END + '
			,@row_count = ' + CASE 
				WHEN @row_count IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @row_count)
				END + '			
			,@IsSettleAbandonedMatch = ' + CASE 
				WHEN @IsSettleAbandonedMatch IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @IsSettleAbandonedMatch)
				END + '
			,@IsSettleAbandonedMatchBetFair = ' + CASE 
				WHEN @IsSettleAbandonedMatchBetFair IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @IsSettleAbandonedMatchBetFair)
				END + '
			,@IsExcludeBetdaq = ' + CASE 
				WHEN @IsExcludeBetdaq IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @IsExcludeBetdaq)
				END + '
			,@IsExcludeBetfair = ' + CASE 
				WHEN @IsExcludeBetfair IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @IsExcludeBetfair)
				END + '
			,@IsSettleAbandonedMatchIBC = ' + CASE 
				WHEN @IsSettleAbandonedMatchIBC IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @IsSettleAbandonedMatchIBC)
				END + '
			,@LGOnly = ' + CASE 
				WHEN @LGOnly IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @LGOnly)
				END + '
			,@IncludeLG = ' + CASE 
				WHEN @IncludeLG IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @IncludeLG)
				END + '
			,@matchdate = ' + CASE 
				WHEN @matchdate IS NULL THEN 'NULL'
				ELSE '''' + CONVERT(NVARCHAR(50), @matchdate) + ''''
				END + '
			,@CalledByBrokerService = 1'
		EXEC [sb].[SBInputMessage] @fromService = N'//Service/Calculation_send'
			,@toService = N'//Service/Calculation_receive'
			,@onContract = N'//Contract/Calculation'
			,@messageType = N'//Message/Calculation'
			,@messageBody = @sMessage

		RETURN
	END
	ELSE
	BEGIN
		IF @action = 'CAL'
		BEGIN
			IF @Mode IN ('CAL-FT', 'CAL')
			BEGIN
				IF @SportType IN (180, 181, 182, 183, 184, 185, 186)
				BEGIN
					-- bettype 1201 : Virtual Handicap
					EXEC dbo.NAP_Admin_Calculate_1 @matchid = @matchid
						,@bettype = 1201
						,@fth = @fth
						,@fta = @fta
						,@betcount = @betcount_1201

					-- bettype 1203 : Virtual Over/Under
					EXEC dbo.NAP_Admin_Calculate_3 @matchid = @matchid
						,@bettype = 1203
						,@totalgoal = @totalgoal
						,@betcount = @betcount_1203

					-- bettype 1204 : Virtual Correct Score
					EXEC dbo.NAP_Admin_Calculate_4 @matchid = @matchid
						,@bettype = 1204
						,@correctscore = @correctscore
						,@goaldiff = @scorediff
						,@FGLG2 = NULL
						,@betcount = @betcount_1204

					-- bettype 1205 : Virtual 1x2
					EXEC dbo.NAP_Admin_Calculate_5 @matchid = @matchid
						,@bettype = 1205
						,@whowin = @scorediff
						,@betcount = @betcount_1205

					-- bettype 1206 : Virtual Total Goal
					EXEC dbo.NAP_Admin_Calculate_6 @matchid = @matchid
						,@bettype = 1206
						,@totalgoal = @totalgoal
						,@betcount = @betcount_1206

					-- bettype 1224 : Virtual Double Chance 
					EXEC dbo.NAP_Admin_Calculate_24 @matchid = @matchid
						,@bettype = 1224
						,@scorediff = @scorediff
						,@betcount = @betcount_1224
				END
				ELSE
				BEGIN
					-- bettype 1 : Handicap
					-- IF @betcount_1 > 0
					EXEC dbo.NAP_Admin_Calculate_1 @matchid = @matchid
						,@bettype = 1
						,@fth = @fth
						,@fta = @fta
						,@betcount = @betcount_1

					-- bettype 20 : Money Line
					-- IF @betcount_20 > 0 
					IF @SportType = 154
						-- for horse racing fixodds swap win positions to resuse calculating SP 
						EXEC dbo.NAP_Admin_Calculate_1 @matchid = @matchid
							,@bettype = 20
							,@fth = @fta
							,@fta = @fth
							,@betcount = @betcount_20
					ELSE
						EXEC dbo.NAP_Admin_Calculate_1 @matchid = @matchid
							,@bettype = 20
							,@fth = @fth
							,@fta = @fta
							,@betcount = @betcount_20

					-- bettype 124: FT 1x2 HDP 
					EXEC dbo.NAP_Admin_Calculate_1 @matchid = @matchid
						,@bettype = 124
						,@fth = @fth
						,@fta = @fta
						,@betcount = @betcount_124 ---parametter @betcount has not used, will be removed later

					-- bettype 2 : Odd/Even
					-- IF @betcount_2 > 0  
					EXEC dbo.NAP_Admin_Calculate_2 @matchid = @matchid
						,@bettype = 2
						,@oddeven = @oddeven
						,@betcount = @betcount_2

					-- bettype 3 : Over/Under
					-- IF @betcount_3 > 0
					EXEC dbo.NAP_Admin_Calculate_3 @matchid = @matchid
						,@bettype = 3
						,@totalgoal = @totalgoal
						,@betcount = @betcount_3

					-- bettype 4, 16 : Correct Score
					-- IF @betcount_4 > 0
					EXEC dbo.NAP_Admin_Calculate_4 @matchid = @matchid
						,@bettype = 4
						,@correctscore = @correctscore
						,@goaldiff = @scorediff
						,@FGLG2 = NULL
						,@betcount = @betcount_4

					-- bettype 5 : 1x2
					-- IF @betcount_5 > 0
					EXEC dbo.NAP_Admin_Calculate_5 @matchid = @matchid
						,@bettype = 5
						,@whowin = @scorediff
						,@betcount = @betcount_5

					-- bettype 6 : Total Goal
					-- IF @betcount_6 > 0
					EXEC dbo.NAP_Admin_Calculate_6 @matchid = @matchid
						,@bettype = 6
						,@totalgoal = @totalgoal
						,@betcount = @betcount_6

					-- bettype 13 : Clean Sheet 
					-- IF @betcount_13 > 0 
					EXEC dbo.NAP_Admin_Calculate_13 @matchid = @matchid
						,@bettype = 13
						,@fth = @fth
						,@fta = @fta
						,@betcount = @betcount_13

					-- bettype 16 : HT/FT		
					-- IF @betcount_16 > 0	
					EXEC dbo.NAP_Admin_Calculate_4 @matchid = @matchid
						,@bettype = 16
						,@correctscore = @HTFT
						,@goaldiff = @scorediff
						,@FGLG2 = NULL
						,@betcount = @betcount_16 --reuse 

					-- bettype 22 : Next Goal	
					-- IF @betcount_22 > 0
					EXEC dbo.NAP_Admin_Calculate_22 @matchid = @matchid
						,@bettype = 22
						,@ResultString = @GoalRecord
						,@betcount = @betcount_22

					-- bettype 24 : Double Chance 
					-- IF @betcount_24 > 0
					EXEC dbo.NAP_Admin_Calculate_24 @matchid = @matchid
						,@bettype = 24
						,@scorediff = @scorediff
						,@betcount = @betcount_24

					-- bettype 25 : Draw no bet 
					-- IF @betcount_25 > 0
					EXEC dbo.NAP_Admin_Calculate_25 @matchid = @matchid
						,@bettype = 25
						,@scorediff = @scorediff
						,@betcount = @betcount_25

					-- bettype 26 : Both/One/Neither team to score  
					-- IF @betcount_26 > 0 
					EXEC dbo.NAP_Admin_Calculate_26 @matchid = @matchid
						,@bettype = 26
						,@fth = @fth
						,@fta = @fta
						,@betcount = @betcount_26

					-- bettype 27 : To win to nil 
					-- IF @betcount_27 > 0 
					EXEC dbo.NAP_Admin_Calculate_27 @matchid = @matchid
						,@bettype = 27
						,@fth = @fth
						,@fta = @fta
						,@betcount = @betcount_27

					-- bettype 28 : 3-way handicap
					-- IF @betcount_28 > 0 
					EXEC dbo.NAP_Admin_Calculate_28 @matchid = @matchid
						,@bettype = 28
						,@fth = @fth
						,@fta = @fta
						,@betcount = @betcount_28

					-- bettype 121 : Home no bet 
					-- IF @betcount_121 > 0
					EXEC dbo.NAP_Admin_Calculate_25 @matchid = @matchid
						,@bettype = 121
						,@scorediff = @scorediff
						,@betcount = @betcount_121

					-- bettype 122 : Away no bet 
					-- IF @betcount_121 > 0
					EXEC dbo.NAP_Admin_Calculate_25 @matchid = @matchid
						,@bettype = 122
						,@scorediff = @scorediff
						,@betcount = @betcount_122

					-- bettype 123 : Draw/No Draw
					-- IF @betcount_123 > 0
					EXEC dbo.NAP_Admin_Calculate_25 @matchid = @matchid
						,@bettype = 123
						,@scorediff = @scorediff
						,@betcount = @betcount_123

					-- bettype 133 : Home To Win Both Halves
					EXEC dbo.NAP_Admin_Calculate_9999 @matchid = @matchid
						,@bettype = 133
						,@fth = @fth
						,@fta = @fta
						,@hth = @hth
						,@hta = @hta
						,@betcount = @betcount_133
						,@isRefundHT = @isRefundHT

					-- bettype 134 : Away To win Both halves
					EXEC dbo.NAP_Admin_Calculate_9999 @matchid = @matchid
						,@bettype = 134
						,@fth = @fth
						,@fta = @fta
						,@hth = @hth
						,@hta = @hta
						,@betcount = @betcount_134
						,@isRefundHT = @isRefundHT

					-- bettype 140 : Highest scoring half
					EXEC dbo.NAP_Admin_Calculate_9999 @matchid = @matchid
						,@bettype = 140
						,@fth = @fth
						,@fta = @fta
						,@hth = @hth
						,@hta = @hta
						,@betcount = @betcount_140
						,@isRefundHT = @isRefundHT

					-- bettype 141 : Highest Scoring Half Home Team
					EXEC dbo.NAP_Admin_Calculate_9999 @matchid = @matchid
						,@bettype = 141
						,@fth = @fth
						,@fta = @fta
						,@hth = @hth
						,@hta = @hta
						,@betcount = @betcount_141
						,@isRefundHT = @isRefundHT

					-- bettype 142 : Highest Scoring Half Away Team
					EXEC dbo.NAP_Admin_Calculate_9999 @matchid = @matchid
						,@bettype = 142
						,@fth = @fth
						,@fta = @fta
						,@hth = @hth
						,@hta = @hta
						,@betcount = @betcount_142
						,@isRefundHT = @isRefundHT

					-- bettype 145 : Both Teams To Score
					EXEC dbo.NAP_Admin_Calculate_9999 @matchid = @matchid
						,@bettype = 145
						,@fth = @fth
						,@fta = @fta
						,@hth = @hth
						,@hta = @hta
						,@betcount = @betcount_145
						,@isRefundHT = @isRefundHT

					-- bettype 146 : 2nd Half Both Teams To Score
					EXEC dbo.NAP_Admin_Calculate_9999 @matchid = @matchid
						,@bettype = 146
						,@fth = @fth
						,@fta = @fta
						,@hth = @hth
						,@hta = @hta
						,@betcount = @betcount_146
						,@isRefundHT = @isRefundHT

					-- bettype 147 : Home To Score In Both Halves
					EXEC dbo.NAP_Admin_Calculate_9999 @matchid = @matchid
						,@bettype = 147
						,@fth = @fth
						,@fta = @fta
						,@hth = @hth
						,@hta = @hta
						,@betcount = @betcount_147
						,@isRefundHT = @isRefundHT

					-- bettype 148 : Away To Score In Both Halves
					EXEC dbo.NAP_Admin_Calculate_9999 @matchid = @matchid
						,@bettype = 148
						,@fth = @fth
						,@fta = @fta
						,@hth = @hth
						,@hta = @hta
						,@betcount = @betcount_148
						,@isRefundHT = @isRefundHT

					-- bettype 149 : Home To Win Either Half
					EXEC dbo.NAP_Admin_Calculate_9999 @matchid = @matchid
						,@bettype = 149
						,@fth = @fth
						,@fta = @fta
						,@hth = @hth
						,@hta = @hta
						,@betcount = @betcount_149
						,@isRefundHT = @isRefundHT

					-- bettype 150 : Away To Win Either Half
					EXEC dbo.NAP_Admin_Calculate_9999 @matchid = @matchid
						,@bettype = 150
						,@fth = @fth
						,@fta = @fta
						,@hth = @hth
						,@hta = @hta
						,@betcount = @betcount_150
						,@isRefundHT = @isRefundHT

					-- bettype 152 : Half time/Fulltime Correct Score
					EXEC dbo.NAP_Admin_Calculate_9999 @matchid = @matchid
						,@bettype = 152
						,@fth = @fth
						,@fta = @fta
						,@hth = @hth
						,@hta = @hta
						,@betcount = @betcount_152
						,@isRefundHT = @isRefundHT

					-- bettype 128 : HT/FT Odd/Even
					EXEC dbo.NAP_Admin_Calculate_2 @matchid = @matchid
						,@bettype = 128
						,@oddeven = @oddeven
						,@oddevenht = @oddevenht
						,@betcount = @betcount_128
						,@isRefundHT = @isRefundHT

					-- bettype 130 : Exact Goal
					EXEC dbo.NAP_Admin_Calculate_6 @matchid = @matchid
						,@bettype = 130
						,@totalgoal = @totalgoal
						,@betcount = @betcount_130

					-- bettype 131 : Home Team Total Goal
					EXEC dbo.NAP_Admin_Calculate_6 @matchid = @matchid
						,@bettype = 131
						,@totalgoal = @totalhome
						,@betcount = @betcount_131

					-- bettype 132 : Away Team Total Goal
					EXEC dbo.NAP_Admin_Calculate_6 @matchid = @matchid
						,@bettype = 132
						,@totalgoal = @totalaway
						,@betcount = @betcount_132
						
					-- bettype 137 : Home Team Odd/Even
					EXEC dbo.NAP_Admin_Calculate_2 @matchid = @matchid
						,@bettype = 137
						,@oddeven = @oddevenhome
						,@betcount = @betcount_137
						
					-- bettype 139 : Away Team Odd/Even
					EXEC dbo.NAP_Admin_Calculate_2 @matchid = @matchid
						,@bettype = 139
						,@oddeven = @oddevenaway
						,@betcount = @betcount_139
						
					-- bettype 144 : Result/Total Goals
					EXEC dbo.NAP_Admin_Calculate_3 @matchid = @matchid
						,@bettype = 144
						,@totalgoal = @totalgoal
						,@scorediff = @scorediff
						,@betcount = @betcount_144
				END
			END

			IF @Mode IN ('CAL-HT', 'CAL')
				AND @SportType NOT IN (180, 181, 182, 183, 184, 185, 186)
			BEGIN
				-- exec in all cases, both 'FT' and 'HT'
				-- bettype 7 : 1st Handicap
				-- IF @betcount_7 > 0
				EXEC dbo.NAP_Admin_Calculate_7 @matchid = @matchid
					,@bettype = 7
					,@hth = @hth
					,@hta = @hta
					,@betcount = @betcount_7

				-- bettype 21: 1st moneyline
				-- IF @betcount_21 > 0
				EXEC dbo.NAP_Admin_Calculate_7 @matchid = @matchid
					,@bettype = 21
					,@hth = @hth
					,@hta = @hta
					,@betcount = @betcount_21

				-- bettype 125 : 1st 1x2 Handicap
				EXEC dbo.NAP_Admin_Calculate_7 @matchid = @matchid
					,@bettype = 125
					,@hth = @hth
					,@hta = @hta
					,@betcount = @betcount_125 ---parametter @betcount has not used, will be removed later

				-- bettype 8 : 1st Over/Under
				-- IF @betcount_8 > 0
				EXEC dbo.NAP_Admin_Calculate_8 @matchid = @matchid
					,@bettype = 8
					,@totalht = @totalht
					,@betcount = @betcount_8

				-- bettype 12 : 1st Odd/Even
				-- IF @betcount_12 > 0
				EXEC dbo.NAP_Admin_Calculate_2 @matchid = @matchid
					,@bettype = 12
					,@oddeven = @oddevenht
					,@betcount = @betcount_12

				-- bettype 15 : 1st 1x2
				-- IF @betcount_15 > 0
				EXEC dbo.NAP_Admin_Calculate_5 @matchid = @matchid
					,@bettype = 15
					,@whowin = @scorediff_ht
					,@betcount = @betcount_15

				-- bettype 30: 1st Correct Score (Reuse with bettype 4)
				-- IF @betcount_30 > 0
				EXEC dbo.NAP_Admin_Calculate_4 @matchid = @matchid
					,@bettype = 30
					,@correctscore = @correctscore_ht
					,@goaldiff = @scorediff_ht
					,@FGLG2 = NULL
					,@betcount = @betcount_30

				-- bettype 126 : 1H Total Goal
				EXEC dbo.NAP_Admin_Calculate_6 @matchid = @matchid
					,@bettype = 126
					,@totalgoal = @totalht
					,@betcount = @betcount_126

				-- bettype 151 : 1st Half Double Chance
				EXEC dbo.NAP_Admin_Calculate_24 @matchid = @matchid
					,@bettype = 151
					,@scorediff = @scorediff_ht
					,@betcount = @betcount_151

				-- bettype 129 : 1H Exact Goal
				EXEC dbo.NAP_Admin_Calculate_6 @matchid = @matchid
					,@bettype = 129
					,@totalgoal = @totalht
					,@betcount = @betcount_129
				
				-- bettype 136 : 1H Home Team Odd/Even
				EXEC dbo.NAP_Admin_Calculate_2 @matchid = @matchid
					,@bettype = 136
					,@oddevenht = @oddevenhome_ht
					,@betcount = @betcount_136
				
				-- bettype 138 : 1H Away Team Odd/Even
				EXEC dbo.NAP_Admin_Calculate_2 @matchid = @matchid
					,@bettype = 138
					,@oddevenht = @oddevenaway_ht
					,@betcount = @betcount_138
					
				-- bettype 143 : 1H Result/Total Goals
				EXEC dbo.NAP_Admin_Calculate_8 @matchid = @matchid
					,@bettype = 143
					,@totalht = @totalht
					,@scorediff_ht = @scorediff_ht
					,@betcount = @betcount_143
			END

			IF @Mode = 'UNDO'
			BEGIN
				EXEC dbo.NAP_Admin_Calculate_Undo 
					 @matchid	  = @matchid
					,@SelectedSet = @SelectedSet
			END
		END

		IF @action = 'CAL-FGLG'
		BEGIN
			IF @Mode = 'CAL-HT'
			BEGIN
				EXEC dbo.NAP_Admin_Calculate_4 @matchid = @matchid
					,@bettype = 127
					,@correctscore = @HT_FGLG1
					,@goaldiff = @goaldiff
					,@FGLG2 = @HT_FGLG2
					,@betcount = @betcount_127
			END

			IF @mode = 'CAL-FT'
			BEGIN
				EXEC dbo.NAP_Admin_Calculate_4 @matchid = @matchid
					,@bettype = 14
					,@correctscore = @FGLG1
					,@goaldiff = @goaldiff
					,@FGLG2 = @FGLG2
					,@betcount = @betcount_14

				IF @IncludeLG = 0
				BEGIN
					EXEC dbo.NAP_Admin_Calculate_4 @matchid = @matchid
						,@bettype = 14
						,@correctscore = @FGLG1
						,@goaldiff = @goaldiff
						,@FGLG2 = @FGLG2
						,@betcount = @betcount_14
				END
			END
		END

		IF @action = 'CAL-PS'
		BEGIN
			IF @betcount_135 > 0
				EXEC dbo.NAP_Admin_Calculate_135 @matchid = @matchid
					,@bettype = 135
					,@betcount = @betcount_135
					,@result = @betstatus
		END

		IF @action ='CAL-SET'  --Tennis including Sportting Solution
		BEGIN
			IF @SelectedSet LIKE '%6%' -- Match Scope 
			BEGIN 
				IF @betcount_1 > 0  -- Handicap ~ Set Handicap 	
					EXEC dbo.NAP_Admin_Calculate_1 
						 @matchid = @matchid
						,@bettype = 1
						,@fth = @fth
						,@fta = @fta
						,@betcount = @betcount_1
				IF @betCount_2 > 0 -- Odd/Even 
					EXEC dbo.NAP_Admin_Calculate_2 
						 @matchid			= @matchid
						,@bettype			= 2
						,@oddeven			= @oddeven
						,@OddEvenSetMatch	= @OddEvenSetMatch
						,@totalgoal			= @totalgoal
						,@betcount			= @betCount_2
				IF @betCount_3 > 0 -- Match Total Games Over/Under
					EXEC dbo.NAP_Admin_Calculate_3 
						 @matchid		= @matchid
						,@bettype		= 3
						,@totalgoal		= @totalgoal
						,@TotalSetMatch	= @TotalSetMatch
						,@betcount		= @betCount_3

				IF @betcount_20 > 0  -- Set Handicap 	
					EXEC dbo.NAP_Admin_Calculate_1 
						 @matchid = @matchid
						,@bettype = 20
						,@fth = @fth
						,@fta = @fta
						,@betcount = @betcount_20

				IF @betCount_153 > 0 -- Game Handicap
				EXEC dbo.NAP_Admin_Calculate_1 
						 @matchid = @matchid
						,@bettype = 153
						,@fth = @TotalGameHomeMatch
						,@fta = @TotalGameAwayMatch
						,@betcount = @betCount_153

				IF @betcount_1301 > 0  -- Match Winner 		
					EXEC dbo.NAP_Admin_Calculate_1 
						 @matchid = @matchid
						,@bettype = 1301
						,@fth = @fth
						,@fta = @fta
						,@betcount = @betcount_1301
				IF @betCount_1302 > 0  -- Match Correct Score - Decimal 
					EXEC dbo.NAP_Admin_Calculate_4 
						 @matchid = @matchid
						,@bettype = 1302
						,@correctscore = @correctscore
						,@betcount = @betcount_1302

				IF @betcount_1303 > 0  -- Set Handicap 	
					EXEC dbo.NAP_Admin_Calculate_1 
						 @matchid = @matchid
						,@bettype = 1303
						,@fth = @fth
						,@fta = @fta
						,@betcount = @betcount_1303

				IF @betCount_1305 > 0 -- Match Total Games Odd/Even
					EXEC dbo.NAP_Admin_Calculate_2 
						 @matchid	= @matchid
						,@bettype	= 1305
						,@oddeven	= @oddeven
						,@betcount = @betcount_1305
				IF @betCount_1306 > 0 -- Match Total Games Over/Under
					EXEC dbo.NAP_Admin_Calculate_3 
						 @matchid = @matchid
						,@bettype = 1306
						,@totalgoal		= @totalgoal
						,@betcount = @betCount_1306

				IF @betCount_1308 > 0 -- Game Handicap (3rd)
					EXEC dbo.NAP_Admin_Calculate_1 
						 @matchid = @matchid
						,@bettype = 1308
						,@fth = @TotalGameHomeMatch
						,@fta = @TotalGameAwayMatch
						,@betcount = @betcount_1308
			END 
			---- END: Match Scope 

			--- START: Set(s) Scope 
			IF @SelectedSet LIKE '%[1-5]%'	
			BEGIN
				IF @betCount_154 > 0 -- Set x Winner
					EXEC dbo.NAP_Admin_Calculate_1
								 @matchid			= @matchid
								,@bettype			= 154
								,@fth				= @fth
								,@fta				= @fta 
								,@SelectedSet		= @SelectedSet
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
								,@betcount			= @betCount_154

				IF @betCount_155 > 0 -- Set x Game Handicap
					EXEC dbo.NAP_Admin_Calculate_1 
							 @matchid			= @matchid
							,@bettype			= 155
							,@fth				= @fth
							,@fta				= @fta 
							,@SelectedSet		= @SelectedSet
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
							,@betcount			= @betCount_155

				IF @betCount_156 > 0 -- Set x Total Games Over/Under 
					EXEC dbo.NAP_Admin_Calculate_3 
							 @matchid		= @matchid
							,@bettype		= 156
							,@SelectedSet	= @SelectedSet
							,@TotalGameSet1	= @TotalGameSet1
							,@TotalGameSet2	= @TotalGameSet2
							,@TotalGameSet3	= @TotalGameSet3
							,@TotalGameSet4	= @TotalGameSet4
							,@TotalGameSet5	= @TotalGameSet5
							,@betcount		= @betCount_156

				IF @betCount_1311 > 0 -- Set x Winner (3rd)
					EXEC dbo.NAP_Admin_Calculate_1 
							 @matchid			= @matchid
							,@bettype			= 1311
							,@fth				= @fth
							,@fta				= @fta 
							,@SelectedSet		= @SelectedSet
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
							,@betcount			= @betcount_1311

				IF @betCount_1312 > 0 -- Set x Total Games Over/Under (3rd)
					EXEC dbo.NAP_Admin_Calculate_3 
							 @matchid		= @matchid
							,@bettype		= 1312
							,@SelectedSet	= @SelectedSet
							,@TotalGameSet1	= @TotalGameSet1
							,@TotalGameSet2	= @TotalGameSet2
							,@TotalGameSet3	= @TotalGameSet3
							,@TotalGameSet4	= @TotalGameSet4
							,@TotalGameSet5	= @TotalGameSet5
							,@betcount		= @betCount_1312
				IF @betCount_1316 > 0 -- Set x Game Handicap (3rd)
					EXEC dbo.NAP_Admin_Calculate_1 
							 @matchid			= @matchid
							,@bettype			= 1316
							,@SelectedSet		= @SelectedSet
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
							,@betcount = @betCount_1316
				IF @betCount_1317 > 0 -- Set x Correct Score - - Decimal 
					EXEC dbo.NAP_Admin_Calculate_4 
						 @matchid			= @matchid
						,@bettype			= 1317
						,@SelectedSet		= @SelectedSet
						,@CorrectScoreSet1	= @CorrectScoreSet1
						,@CorrectScoreSet2	= @CorrectScoreSet2
						,@CorrectScoreSet3	= @CorrectScoreSet3	
						,@CorrectScoreSet4	= @CorrectScoreSet4	
						,@CorrectScoreSet5	= @CorrectScoreSet5	
						,@betcount			= @betCount_1317

				IF @betCount_1318 > 0 -- Set x Total Games Odd/Even
					EXEC dbo.NAP_Admin_Calculate_2 
						 @matchid			= @matchid
						,@bettype			= 1318
						,@oddeven			= @oddeven 
						,@oddevenht			= NULL 
						,@SelectedSet		= @SelectedSet
						,@OddEvenGameSet1	= @OddEvenGameSet1	
						,@OddEvenGameSet2	= @OddEvenGameSet2	
						,@OddEvenGameSet3	= @OddEvenGameSet3	
						,@OddEvenGameSet4	= @OddEvenGameSet4	
						,@OddEvenGameSet5	= @OddEvenGameSet5	
						,@betcount			= @betCount_1318

				IF @betCount_1324 > 0 -- Set x Game y Winner 
					EXEC dbo.NAP_Admin_Calculate_1324 
						 @matchid			= @matchid
						,@bettype			= 1324 
						,@SelectedSet		= @SelectedSet
						,@SetxGameyHomeWON	= @SetxGameyHomeWON
						,@SetxGameyAwayWON	= @SetxGameyAwayWON
						,@SetxGameyDRAW		= @SetxGameyDRAW
						,@SetxGameyREFUND	= @SetxGameyREFUND
						,@betcount			= @betCount_1324
				
			END	
		END
			
		IF @action = 'REFUND'
		BEGIN
			IF @mode = 'FT'
			BEGIN
				IF @betcount_128 > 0 
					EXEC dbo.NAP_Admin_Calculate_2 @matchid = @matchid
						,@bettype = 128
						,@oddevenht = @oddevenht
						,@betcount = @betcount_128
						,@IsSettleAbandonedMatchIBC = @IsSettleAbandonedMatchIBC
						,@IsSettleAbandonedMatch = @IsSettleAbandonedMatch
						,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair
						
				IF @betcount_4 > 0
					EXEC dbo.NAP_Admin_Calculate_4 @matchid = @matchid
						,@bettype = 4
						,@correctscore = NULL
						,@goaldiff = NULL
						,@FGLG2 = NULL
						,@betcount = @betcount_4
						,@hth = @hth
						,@hta = @hta
						,@fth = @fth
						,@fta = @fta
						,@IsSettleAbandonedMatchIBC = @IsSettleAbandonedMatchIBC
						,@IsSettleAbandonedMatch = @IsSettleAbandonedMatch
						,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair

				IF @betcount_6 > 0
					EXEC dbo.NAP_Admin_Calculate_6 @matchid = @matchid
						,@bettype = 6
						,@totalgoal = @totalgoal
						,@betcount = @betcount_6
						,@IsSettleAbandonedMatch = @IsSettleAbandonedMatch
						,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair
						,@IsSettleAbandonedMatchIBC = @IsSettleAbandonedMatchIBC

				IF @betcount_3 > 0
					EXEC dbo.NAP_Admin_Calculate_3 @matchid = @matchid
						,@bettype = 3
						,@totalgoal = @totalgoal
						,@betcount = @betcount_3
						,@IsSettleAbandonedMatch = @IsSettleAbandonedMatch
						,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair

				IF @betcount_13 > 0
					EXEC dbo.NAP_Admin_Calculate_13 @matchid = @matchid
						,@bettype = 13
						,@fth = @fth
						,@fta = @fta
						,@betcount = @betcount_13
						,@IsSettleAbandonedMatch = @IsSettleAbandonedMatch
						,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair
						,@IsSettleAbandonedMatchIBC = @IsSettleAbandonedMatchIBC

				IF @betcount_26 > 0
					EXEC dbo.NAP_Admin_Calculate_26 @matchid = @matchid
						,@bettype = 26
						,@fth = @fth
						,@fta = @fta
						,@betcount = @betcount_26
						,@IsSettleAbandonedMatch = @IsSettleAbandonedMatch
						,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair
						,@IsSettleAbandonedMatchIBC = @IsSettleAbandonedMatchIBC

				IF @betcount_27 > 0
					EXEC dbo.NAP_Admin_Calculate_27 @matchid = @matchid
						,@bettype = 27
						,@fth = @fth
						,@fta = @fta
						,@betcount = @betcount_27
						,@IsSettleAbandonedMatch = @IsSettleAbandonedMatch
						,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair
						,@IsSettleAbandonedMatchIBC = @IsSettleAbandonedMatchIBC
				
				IF @betcount_130 > 0
					EXEC dbo.NAP_Admin_Calculate_6 @matchid = @matchid
						,@bettype = 130
						,@totalgoal = @totalgoal
						,@betcount = @betcount_130
						,@IsSettleAbandonedMatch = @IsSettleAbandonedMatch
						,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair
						,@IsSettleAbandonedMatchIBC = @IsSettleAbandonedMatchIBC
						
				IF @betcount_131 > 0
					EXEC dbo.NAP_Admin_Calculate_6 @matchid = @matchid
						,@bettype = 131
						,@totalgoal = @fth
						,@betcount = @betcount_131
						,@IsSettleAbandonedMatch = @IsSettleAbandonedMatch
						,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair
						,@IsSettleAbandonedMatchIBC = @IsSettleAbandonedMatchIBC
				
				IF @betcount_132 > 0
					EXEC dbo.NAP_Admin_Calculate_6 @matchid = @matchid
						,@bettype = 132
						,@totalgoal = @fta
						,@betcount = @betcount_132
						,@IsSettleAbandonedMatch = @IsSettleAbandonedMatch
						,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair
						,@IsSettleAbandonedMatchIBC = @IsSettleAbandonedMatchIBC
						
				IF @betcount_133 > 0
					EXEC dbo.NAP_Admin_Calculate_9999 @matchid = @matchid
						,@bettype = 133
						,@fth = @fth
						,@fta = @fta
						,@hth = @hth
						,@hta = @hta
						,@betcount = @betcount_133
						,@IsSettleAbandonedMatchIBC = @IsSettleAbandonedMatchIBC
						,@IsSettleAbandonedMatch = @IsSettleAbandonedMatch
						,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair
						,@IsHTCal = @IsHTCal

				IF @betcount_134 > 0
					EXEC dbo.NAP_Admin_Calculate_9999 @matchid = @matchid
						,@bettype = 134
						,@fth = @fth
						,@fta = @fta
						,@hth = @hth
						,@hta = @hta
						,@betcount = @betcount_134
						,@IsSettleAbandonedMatchIBC = @IsSettleAbandonedMatchIBC
						,@IsSettleAbandonedMatch = @IsSettleAbandonedMatch
						,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair
						,@IsHTCal = @IsHTCal

				IF @betcount_140 > 0
					EXEC dbo.NAP_Admin_Calculate_9999 @matchid = @matchid
						,@bettype = 140
						,@fth = @fth
						,@fta = @fta
						,@hth = @hth
						,@hta = @hta
						,@betcount = @betcount_140
						,@IsSettleAbandonedMatchIBC = @IsSettleAbandonedMatchIBC
						,@IsSettleAbandonedMatch = @IsSettleAbandonedMatch
						,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair
						,@IsHTCal = @IsHTCal

				IF @betcount_141 > 0
					EXEC dbo.NAP_Admin_Calculate_9999 @matchid = @matchid
						,@bettype = 141
						,@fth = @fth
						,@fta = @fta
						,@hth = @hth
						,@hta = @hta
						,@betcount = @betcount_141
						,@IsSettleAbandonedMatchIBC = @IsSettleAbandonedMatchIBC
						,@IsSettleAbandonedMatch = @IsSettleAbandonedMatch
						,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair
						,@IsHTCal = @IsHTCal

				IF @betcount_142 > 0
					EXEC dbo.NAP_Admin_Calculate_9999 @matchid = @matchid
						,@bettype = 142
						,@fth = @fth
						,@fta = @fta
						,@hth = @hth
						,@hta = @hta
						,@betcount = @betcount_142
						,@IsSettleAbandonedMatchIBC = @IsSettleAbandonedMatchIBC
						,@IsSettleAbandonedMatch = @IsSettleAbandonedMatch
						,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair
						,@IsHTCal = @IsHTCal

				IF @betcount_144 > 0
					EXEC dbo.NAP_Admin_Calculate_3 @matchid = @matchid
						,@bettype = 144
						,@totalgoal = @totalgoal
						,@betcount = @betcount_144
						,@IsSettleAbandonedMatchIBC = @IsSettleAbandonedMatchIBC
						,@IsSettleAbandonedMatch = @IsSettleAbandonedMatch
						,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair
						
				IF @betcount_145 > 0
					EXEC dbo.NAP_Admin_Calculate_9999 @matchid = @matchid
						,@bettype = 145
						,@fth = @fth
						,@fta = @fta
						,@hth = @hth
						,@hta = @hta
						,@betcount = @betcount_145
						,@IsSettleAbandonedMatchIBC = @IsSettleAbandonedMatchIBC
						,@IsSettleAbandonedMatch = @IsSettleAbandonedMatch
						,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair
						,@IsHTCal = @IsHTCal

				IF @betcount_146 > 0
					EXEC dbo.NAP_Admin_Calculate_9999 @matchid = @matchid
						,@bettype = 146
						,@fth = @fth
						,@fta = @fta
						,@hth = @hth
						,@hta = @hta
						,@betcount = @betcount_146
						,@IsSettleAbandonedMatchIBC = @IsSettleAbandonedMatchIBC
						,@IsSettleAbandonedMatch = @IsSettleAbandonedMatch
						,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair
						,@IsHTCal = @IsHTCal

				IF @betcount_147 > 0
					EXEC dbo.NAP_Admin_Calculate_9999 @matchid = @matchid
						,@bettype = 147
						,@fth = @fth
						,@fta = @fta
						,@hth = @hth
						,@hta = @hta
						,@betcount = @betcount_147
						,@IsSettleAbandonedMatchIBC = @IsSettleAbandonedMatchIBC
						,@IsSettleAbandonedMatch = @IsSettleAbandonedMatch
						,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair
						,@IsHTCal = @IsHTCal

				IF @betcount_148 > 0
					EXEC dbo.NAP_Admin_Calculate_9999 @matchid = @matchid
						,@bettype = 148
						,@fth = @fth
						,@fta = @fta
						,@hth = @hth
						,@hta = @hta
						,@betcount = @betcount_148
						,@IsSettleAbandonedMatchIBC = @IsSettleAbandonedMatchIBC
						,@IsSettleAbandonedMatch = @IsSettleAbandonedMatch
						,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair
						,@IsHTCal = @IsHTCal

				IF @betcount_149 > 0
					EXEC dbo.NAP_Admin_Calculate_9999 @matchid = @matchid
						,@bettype = 149
						,@fth = @fth
						,@fta = @fta
						,@hth = @hth
						,@hta = @hta
						,@betcount = @betcount_149
						,@IsSettleAbandonedMatchIBC = @IsSettleAbandonedMatchIBC
						,@IsSettleAbandonedMatch = @IsSettleAbandonedMatch
						,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair
						,@IsHTCal = @IsHTCal

				IF @betcount_150 > 0
					EXEC dbo.NAP_Admin_Calculate_9999 @matchid = @matchid
						,@bettype = 150
						,@fth = @fth
						,@fta = @fta
						,@hth = @hth
						,@hta = @hta
						,@betcount = @betcount_150
						,@IsSettleAbandonedMatchIBC = @IsSettleAbandonedMatchIBC
						,@IsSettleAbandonedMatch = @IsSettleAbandonedMatch
						,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair
						,@IsHTCal = @IsHTCal

				IF @betcount_152 > 0
					EXEC dbo.NAP_Admin_Calculate_9999 @matchid = @matchid
						,@bettype = 152
						,@fth = @fth
						,@fta = @fta
						,@hth = @hth
						,@hta = @hta
						,@betcount = @betcount_152
						,@IsSettleAbandonedMatchIBC = @IsSettleAbandonedMatchIBC
						,@IsSettleAbandonedMatch = @IsSettleAbandonedMatch
						,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair
						,@IsHTCal = @IsHTCal

				IF @row_count > 0
					EXEC dbo.NAP_Admin_Calculate_RefundFT @matchid = @matchid
						,@IsExcludeBetdaq = @IsExcludeBetdaq
						,@IsExcludeBetfair = @IsExcludeBetfair
						,@IsSettleAbandonedMatchIBC = @IsSettleAbandonedMatchIBC
						,@isRefundHT = @IsRefundHT
						,@isHTCal = @isHTCal
			END

			IF @mode = 'HT'
			BEGIN
				IF @betcount_8 > 0
					EXEC dbo.NAP_Admin_Calculate_8 @matchid = @matchid
						,@bettype = 8
						,@totalht = @totalht
						,@betcount = @betcount_8
						,@IsSettleAbandonedMatch = @IsSettleAbandonedMatch
						,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair

				IF @row_count > 0
					EXEC dbo.NAP_Admin_Calculate_RefundHT @matchid = @matchid
						,@IsExcludeBetdaq = @IsExcludeBetdaq
						,@IsExcludeBetfair = @IsExcludeBetfair
			END

			IF @mode = 'ALL'
			BEGIN
				IF @betcount_3 > 0 AND (@SelectedSet IS NULL OR @SelectedSet LIKE '%6%')
					EXEC dbo.NAP_Admin_Calculate_3 
						 @matchid = @matchid
						,@bettype = 3
						,@totalgoal = @totalgoal
						,@betcount = @betcount_3
						,@IsSettleAbandonedMatch = @IsSettleAbandonedMatch
						,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair

				IF @betcount_4 > 0
					EXEC dbo.NAP_Admin_Calculate_4 
						 @matchid = @matchid
						,@bettype = 4
						,@correctscore = NULL
						,@goaldiff = NULL
						,@FGLG2 = NULL
						,@betcount = @betcount_4
						,@hth = @hth
						,@hta = @hta
						,@fth = @fth
						,@fta = @fta
						,@IsSettleAbandonedMatchIBC = @IsSettleAbandonedMatchIBC
						,@IsSettleAbandonedMatch = @IsSettleAbandonedMatch
						,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair

				IF @betcount_6 > 0
					EXEC dbo.NAP_Admin_Calculate_6 @matchid = @matchid
						,@bettype = 6
						,@totalgoal = @totalgoal
						,@betcount = @betcount_6
						,@IsSettleAbandonedMatch = @IsSettleAbandonedMatch
						,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair
						,@IsSettleAbandonedMatchIBC = @IsSettleAbandonedMatchIBC

				IF @betcount_8 > 0
					EXEC dbo.NAP_Admin_Calculate_8 @matchid = @matchid
						,@bettype = 8
						,@totalht = @totalht
						,@betcount = @betcount_8
						,@IsSettleAbandonedMatch = @IsSettleAbandonedMatch
						,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair

				IF @betcount_13 > 0
					EXEC dbo.NAP_Admin_Calculate_13 @matchid = @matchid
						,@bettype = 13
						,@fth = @fth
						,@fta = @fta
						,@betcount = @betcount_13
						,@IsSettleAbandonedMatch = @IsSettleAbandonedMatch
						,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair
						,@IsSettleAbandonedMatchIBC = @IsSettleAbandonedMatchIBC

				IF @betcount_26 > 0
					EXEC dbo.NAP_Admin_Calculate_26 @matchid = @matchid
						,@bettype = 26
						,@fth = @fth
						,@fta = @fta
						,@betcount = @betcount_26
						,@IsSettleAbandonedMatch = @IsSettleAbandonedMatch
						,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair
						,@IsSettleAbandonedMatchIBC = @IsSettleAbandonedMatchIBC

				IF @betcount_27 > 0
					EXEC dbo.NAP_Admin_Calculate_27 @matchid = @matchid
						,@bettype = 27
						,@fth = @fth
						,@fta = @fta
						,@betcount = @betcount_27
						,@IsSettleAbandonedMatch = @IsSettleAbandonedMatch
						,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair
						,@IsSettleAbandonedMatchIBC = @IsSettleAbandonedMatchIBC

				IF @betcount_30 > 0
					EXEC dbo.NAP_Admin_Calculate_4 @matchid = @matchid
						,@bettype = 30
						,@correctscore = NULL
						,@goaldiff = NULL
						,@FGLG2 = NULL
						,@hth = @hth
						,@hta = @hta
						,@fth = @fth
						,@fta = @fta
						,@betcount = @betcount_30
						,@IsSettleAbandonedMatchIBC = @IsSettleAbandonedMatchIBC
						,@IsSettleAbandonedMatch = @IsSettleAbandonedMatch
						,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair

				IF @betcount_126 > 0
					EXEC dbo.NAP_Admin_Calculate_6 @matchid = @matchid
						,@bettype = 126
						,@totalgoal = @totalht
						,@betcount = @betcount_126
						,@IsSettleAbandonedMatch = @IsSettleAbandonedMatch
						,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair
						,@IsSettleAbandonedMatchIBC = @IsSettleAbandonedMatchIBC
						
				IF @betcount_129 > 0
					EXEC dbo.NAP_Admin_Calculate_6 @matchid = @matchid
						,@bettype = 129
						,@totalgoal = @totalht
						,@betcount = @betcount_129
						,@IsSettleAbandonedMatch = @IsSettleAbandonedMatch
						,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair
						,@IsSettleAbandonedMatchIBC = @IsSettleAbandonedMatchIBC
				
				IF @betcount_130 > 0
				EXEC dbo.NAP_Admin_Calculate_6 @matchid = @matchid
						,@bettype = 130
						,@totalgoal = @totalgoal
						,@betcount = @betcount_130
						,@IsSettleAbandonedMatch = @IsSettleAbandonedMatch
						,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair
						,@IsSettleAbandonedMatchIBC = @IsSettleAbandonedMatchIBC
					
				IF @betcount_131 > 0
				EXEC dbo.NAP_Admin_Calculate_6 @matchid = @matchid
						,@bettype = 131
						,@totalgoal = @fth
						,@betcount = @betcount_131
						,@IsSettleAbandonedMatch = @IsSettleAbandonedMatch
						,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair
						,@IsSettleAbandonedMatchIBC = @IsSettleAbandonedMatchIBC
				
				IF @betcount_132 > 0
				EXEC dbo.NAP_Admin_Calculate_6 @matchid = @matchid
						,@bettype = 132
						,@totalgoal = @fta
						,@betcount = @betcount_132
						,@IsSettleAbandonedMatch = @IsSettleAbandonedMatch
						,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair
						,@IsSettleAbandonedMatchIBC = @IsSettleAbandonedMatchIBC
						
				IF @betcount_143 > 0
					EXEC dbo.NAP_Admin_Calculate_8 @matchid = @matchid
						,@bettype = 143
						,@totalht = @totalht
						,@betcount = @betcount_143
						,@IsSettleAbandonedMatchIBC = @IsSettleAbandonedMatchIBC
						,@IsSettleAbandonedMatch = @IsSettleAbandonedMatch
						,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair
				
				IF @betcount_144 > 0
					EXEC dbo.NAP_Admin_Calculate_3 @matchid = @matchid
						,@bettype = 144
						,@totalgoal = @totalgoal
						,@betcount = @betcount_144
						,@IsSettleAbandonedMatchIBC = @IsSettleAbandonedMatchIBC
						,@IsSettleAbandonedMatch = @IsSettleAbandonedMatch
						,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair
							
				IF @betcount_145 > 0
					EXEC dbo.NAP_Admin_Calculate_9999 @matchid = @matchid
						,@bettype = 145
						,@fth = @fth
						,@fta = @fta
						,@hth = @hth
						,@hta = @hta
						,@betcount = @betcount_145
						,@IsSettleAbandonedMatchIBC = @IsSettleAbandonedMatchIBC
						,@IsSettleAbandonedMatch = @IsSettleAbandonedMatch
						,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair
						,@isRefundHT = @isRefundHT
						,@IsHTCal = @IsHTCal

				IF @betcount_152 > 0
					EXEC dbo.NAP_Admin_Calculate_9999 @matchid = @matchid
						,@bettype = 152
						,@fth = @fth
						,@fta = @fta
						,@hth = @hth
						,@hta = @hta
						,@betcount = @betcount_152
						,@IsSettleAbandonedMatchIBC = @IsSettleAbandonedMatchIBC
						,@IsSettleAbandonedMatch = @IsSettleAbandonedMatch
						,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair
						,@isRefundHT = @isRefundHT
						,@IsHTCal = @IsHTCal

				IF @betCount_1324 > 0 -- Set x Game y Winner 
					EXEC dbo.NAP_Admin_Calculate_1324 
						 @matchid						= @matchid
						,@bettype						= 1324 
						,@SelectedSet					= @SelectedSet
						,@SelectedSettleFinishedGame	= @SelectedSettleFinishedGame
						,@SetxGameyHomeWON				= @SetxGameyHomeWON
						,@SetxGameyAwayWON				= @SetxGameyAwayWON
						,@SetxGameyDRAW					= @SetxGameyDRAW
						,@SetxGameyFinishedGame			= @SetxGameyFinishedGame
						,@betcount						= @betCount_1324
					

				IF @row_count > 0
					EXEC dbo.NAP_Admin_Calculate_RefundAll 
						 @matchid					= @matchid
						,@IsExcludeBetdaq			= @IsExcludeBetdaq
						,@IsExcludeBetfair			= @IsExcludeBetfair
						,@IsSettleAbandonedMatchIBC = @IsSettleAbandonedMatchIBC
						,@SelectedSet				= @SelectedSet
						,@SelectedSettleFinishedGame= @SelectedSettleFinishedGame
						,@SetxGameyFinishedGame		= @SetxGameyFinishedGame

			END

			IF @mode = 'BetDaq'
			BEGIN
				EXEC dbo.NAP_Admin_Calculate_Refund_BetDaq @matchid = @matchid
			END

			IF @mode = 'BetFair'
			BEGIN
				EXEC dbo.NAP_Admin_Calculate_Refund_BetFair @matchid = @matchid
			END
		END

		IF @action = 'REFUND-FGLG'
		BEGIN
			EXEC dbo.NAP_Admin_Calculate_RefundFGLG @matchid = @matchid
				,@action = @mode
				,@LGOnly = @LGOnly
				,@matchdate = @matchdate
		END


	END
END
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Admin_Calculate_Main] TO [vnteam] AS [dbo]