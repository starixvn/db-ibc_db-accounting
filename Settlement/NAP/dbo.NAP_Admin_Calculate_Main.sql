ALTER PROCEDURE [NAP_Admin_Calculate_Main] @matchid INT
	,@mode VARCHAR(15) = 'CAL'
	,@action VARCHAR(20) = 'CAL'
	,@fth INT = NULL
	,@fta INT = NULL
	,@hth INT = NULL
	,@hta INT = NULL
	,@sporttype TINYINT = NULL
	,@betstatus NVARCHAR(50) = NULL
	,@GoalRecord VARCHAR(50) = NULL
	,@matchCode NVARCHAR(50) = NULL
	,@oddeven SMALLMONEY = NULL
	,@oddevenht SMALLMONEY = NULL
	,@totalgoal SMALLMONEY = NULL
	,@totalht SMALLMONEY = NULL
	,@goaldiff SMALLMONEY = NULL
	,@scorediff SMALLMONEY = NULL
	,@scorediff_ht SMALLMONEY = NULL
	,@correctscore NVARCHAR(10) = NULL
	,@correctscore_ht NVARCHAR(10) = NULL
	,@HTFT NVARCHAR(10) = NULL
	,@FGLG1 VARCHAR(10) = NULL
	,@FGLG2 VARCHAR(10) = NULL
	,@TennisTotal SMALLINT = NULL
	,@T_Home SMALLINT = NULL
	,@T_Away SMALLINT = NULL
	,@betcount_1 INT = NULL
	,@betcount_2 INT = NULL
	,@betcount_3 INT = NULL
	,@betcount_4 INT = NULL
	,@betcount_5 INT = NULL
	,@betcount_6 INT = NULL
	,@betcount_16 INT = NULL
	,@betcount_20 INT = NULL
	,@betcount_22 INT = NULL
	,@betcount_13 INT = NULL
	,@betcount_24 INT = NULL
	,@betcount_25 INT = NULL
	,@betcount_26 INT = NULL
	,@betcount_27 INT = NULL
	,@betcount_28 INT = NULL
	,@betcount_124 INT = NULL
	,@betcount_121 INT = NULL
	,@betcount_122 INT = NULL
	,@betcount_123 INT = NULL
	,@betcount_1201 INT = NULL
	,@betcount_1203 INT = NULL
	,@betcount_1204 INT = NULL
	,@betcount_1205 INT = NULL
	,@betcount_1206 INT = NULL
	,@betcount_1224 INT = NULL
	,@betcount_7 INT = NULL
	,@betcount_8 INT = NULL
	,@betcount_12 INT = NULL
	,@betcount_15 INT = NULL
	,@betcount_21 INT = NULL
	,@betcount_30 INT = NULL
	,@betcount_125 INT = NULL
	,@betcount_14 INT = NULL
	,@row_count INT = NULL
	,@ticket_count INT = NULL -- ticket number of bettype
	,@IsSettleAbandonedMatch BIT = 0
	,@IsSettleAbandonedMatchBetFair BIT = 0
	,@IsExcludeBetdaq BIT = 0
	,@IsExcludeBetfair BIT = 0
	,@IsSettleAbandonedMatchIBC BIT = 0
	,@LGOnly BIT = NULL
	,@matchdate DATETIME = NULL
	,@CalledByBrokerService BIT = 0
AS
/*
	Created: Viet
	Task : Covered SP for settlement
	Original SP: Admin_Settlement_3
	DB: EXECREP SP (DBTrans_Bet)

	Revisions:
		-20140304@Kathy: Execute settlement for abandoned/postponed matches- Clean Sheet, Both/One/Neither team to score, To Win To Nil 

	Param's Explanation:
		@action			@mode
		 CAL			 CAL, CAL-HT, CAL-FT, UNDO, CAL-FGLG
		 REFUND			 ALL, HT, FT, FGLG, BetDaq, BetFair
*/
BEGIN
	SET NOCOUNT ON;

	IF @@SERVERNAME IN ('DB052', 'DB053', 'DB054', 'DB06', 'DB231', 'DB232') AND @CalledByBrokerService = 0
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
			,@totalgoal = ' + CASE 
				WHEN @totalgoal IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @totalgoal)
				END + '
			,@totalht = ' + CASE 
				WHEN @totalht IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @totalht)
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
			,@betcount_124 = ' + CASE 
				WHEN @betcount_124 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @betcount_124)
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
			,@betcount_14 = ' + CASE 
				WHEN @betcount_14 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @betcount_14)
				END + '
			,@row_count = ' + CASE 
				WHEN @row_count IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @row_count)
				END + '
			,@ticket_count = ' + CASE 
				WHEN @ticket_count IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @ticket_count)
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
					EXEC dbo.NAP_Admin_Calculate_1 @matchid
						,1201
						,@fth
						,@fta
						,@betcount_1201

					-- bettype 1203 : Virtual Over/Under
					EXEC dbo.NAP_Admin_Calculate_3 @matchid
						,1203
						,@totalgoal
						,@betcount_1203

					-- bettype 1204 : Virtual Correct Score
					EXEC dbo.NAP_Admin_Calculate_4 @matchid
						,1204
						,@correctscore
						,@scorediff
						,NULL
						,@betcount_1204

					-- bettype 1205 : Virtual 1x2
					EXEC dbo.NAP_Admin_Calculate_5 @matchid
						,1205
						,@scorediff
						,@betcount_1205

					-- bettype 1206 : Virtual Total Goal
					EXEC dbo.NAP_Admin_Calculate_6 @matchid
						,1206
						,@totalgoal
						,@betcount_1206

					-- bettype 1224 : Virtual Double Chance 
					EXEC dbo.NAP_Admin_Calculate_24 @matchid
						,1224
						,@scorediff
						,@betcount_1224
				END
				ELSE
				BEGIN
					-- bettype 1 : Handicap
					-- IF @betcount_1 > 0
					EXEC dbo.NAP_Admin_Calculate_1 @matchid
						,1
						,@fth
						,@fta
						,@betcount_1

					-- bettype 20 : Money Line
					-- IF @betcount_20 > 0 
					IF @SportType = 154
						-- for horse racing fixodds swap win positions to resuse calculating SP 
						EXEC dbo.NAP_Admin_Calculate_1 @matchid
							,20
							,@fta
							,@fth
							,@betcount_20
					ELSE
						EXEC dbo.NAP_Admin_Calculate_1 @matchid
							,20
							,@fth
							,@fta
							,@betcount_20

					-- bettype 124: FT 1x2 HDP 
					EXEC dbo.NAP_Admin_Calculate_1 @matchid
						,124
						,@fth
						,@fta
						,@betcount_124 ---parametter @betcount has not used, will be removed later

					-- bettype 2 : Odd/Even
					-- IF @betcount_2 > 0  
					EXEC dbo.NAP_Admin_Calculate_2 @matchid
						,2
						,@oddeven
						,@betcount_2

					-- bettype 3 : Over/Under
					-- IF @betcount_3 > 0
					EXEC dbo.NAP_Admin_Calculate_3 @matchid
						,3
						,@totalgoal
						,@betcount_3

					-- bettype 4, 16 : Correct Score
					-- IF @betcount_4 > 0
					EXEC dbo.NAP_Admin_Calculate_4 @matchid
						,4
						,@correctscore
						,@scorediff
						,NULL
						,@betcount_4

					-- bettype 5 : 1x2
					-- IF @betcount_5 > 0
					EXEC dbo.NAP_Admin_Calculate_5 @matchid
						,5
						,@scorediff
						,@betcount_5

					-- bettype 6 : Total Goal
					-- IF @betcount_6 > 0
					EXEC dbo.NAP_Admin_Calculate_6 @matchid
						,6
						,@totalgoal
						,@betcount_6

					-- bettype 13 : Clean Sheet 
					-- IF @betcount_13 > 0 
					EXEC dbo.NAP_Admin_Calculate_13 @matchid
						,13
						,@fth
						,@fta
						,@betcount_13

					-- bettype 16 : HT/FT		
					-- IF @betcount_16 > 0	
					EXEC dbo.NAP_Admin_Calculate_4 @matchid
						,16
						,@HTFT
						,@scorediff
						,NULL
						,@betcount_16 --reuse 

					-- bettype 22 : Next Goal	
					-- IF @betcount_22 > 0
					EXEC dbo.NAP_Admin_Calculate_22 @matchid
						,22
						,@GoalRecord
						,@betcount_22

					-- bettype 24 : Double Chance 
					-- IF @betcount_24 > 0
					EXEC dbo.NAP_Admin_Calculate_24 @matchid
						,24
						,@scorediff
						,@betcount_24

					-- bettype 25 : Draw no bet 
					-- IF @betcount_25 > 0
					EXEC dbo.NAP_Admin_Calculate_25 @matchid
						,25
						,@scorediff
						,@betcount_25

					-- bettype 26 : Both/One/Neither team to score  
					-- IF @betcount_26 > 0 
					EXEC dbo.NAP_Admin_Calculate_26 @matchid
						,26
						,@fth
						,@fta
						,@betcount_26

					-- bettype 27 : To win to nil 
					-- IF @betcount_27 > 0 
					EXEC dbo.NAP_Admin_Calculate_27 @matchid
						,27
						,@fth
						,@fta
						,@betcount_27

					-- bettype 28 : 3-way handicap
					-- IF @betcount_28 > 0 
					EXEC dbo.NAP_Admin_Calculate_28 @matchid
						,28
						,@fth
						,@fta
						,@betcount_28

					-- bettype 121 : Home no bet 
					-- IF @betcount_121 > 0
					EXEC dbo.NAP_Admin_Calculate_25 @matchid
						,121
						,@scorediff
						,@betcount_121

					-- bettype 122 : Away no bet 
					-- IF @betcount_121 > 0
					EXEC dbo.NAP_Admin_Calculate_25 @matchid
						,122
						,@scorediff
						,@betcount_122

					-- bettype 123 : Draw/No Draw
					-- IF @betcount_123 > 0
					EXEC dbo.NAP_Admin_Calculate_25 @matchid
						,123
						,@scorediff
						,@betcount_123
				END
			END

			IF @Mode IN ('CAL-HT', 'CAL') AND @SportType NOT IN (180, 181, 182, 183, 184, 185, 186)
			BEGIN
				-- exec in all cases, both 'FT' and 'HT'
				-- bettype 7 : 1st Handicap
				-- IF @betcount_7 > 0
				EXEC dbo.NAP_Admin_Calculate_7 @matchid
					,7
					,@hth
					,@hta
					,@betcount_7

				-- bettype 21: 1st moneyline
				-- IF @betcount_21 > 0
				EXEC dbo.NAP_Admin_Calculate_7 @matchid
					,21
					,@hth
					,@hta
					,@betcount_21

				-- bettype 125 : 1st 1x2 Handicap
				EXEC dbo.NAP_Admin_Calculate_7 @matchid
					,125
					,@hth
					,@hta
					,@betcount_125 ---parametter @betcount has not used, will be removed later

				-- bettype 8 : 1st Over/Under
				-- IF @betcount_8 > 0
				EXEC dbo.NAP_Admin_Calculate_8 @matchid
					,8
					,@totalht
					,@betcount_8

				-- bettype 12 : 1st Odd/Even
				-- IF @betcount_12 > 0
				EXEC dbo.NAP_Admin_Calculate_2 @matchid
					,12
					,@oddevenht
					,@betcount_12

				-- bettype 15 : 1st 1x2
				-- IF @betcount_15 > 0
				EXEC dbo.NAP_Admin_Calculate_5 @matchid
					,15
					,@scorediff_ht
					,@betcount_15

				-- bettype 30: 1st Correct Score (Reuse with bettype 4)
				-- IF @betcount_30 > 0
				EXEC dbo.NAP_Admin_Calculate_4 @matchid
					,30
					,@correctscore_ht
					,@scorediff_ht
					,NULL
					,@betcount_30
			END

			IF @Mode = 'UNDO'
			BEGIN
				EXEC dbo.NAP_Admin_Calculate_Undo @matchid
			END

			IF @Mode = 'CAL-FGLG'
			BEGIN
				EXEC dbo.NAP_Admin_Calculate_4 @matchid
					,@betcount_14
					,@FGLG1
					,0
					,@FGLG2
					,@ticket_count
			END
		END

		IF @action = 'REFUND'
		BEGIN
			IF @mode = 'FT'
			BEGIN
				IF @betcount_3 IS NOT NULL
					EXEC dbo.NAP_Admin_Calculate_3 @matchid = @matchid
						,@bettype = @betcount_3
						,@totalgoal = @totalgoal
						,@betcount = @ticket_count
						,@IsSettleAbandonedMatch = @IsSettleAbandonedMatch
						,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair

				-- NAP_Admin_Calculate_13
				IF @betcount_13 IS NOT NULL
					EXEC dbo.NAP_Admin_Calculate_13 @matchid = @matchid
						,@bettype = 13
						,@fth = @fth
						,@fta = @fta
						,@betcount = @ticket_count
						,@IsSettleAbandonedMatch = @IsSettleAbandonedMatch
						,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair
						,@IsSettleAbandonedMatchIBC = @IsSettleAbandonedMatchIBC

				-- NAP_Admin_Calculate_26
				IF @betcount_26 IS NOT NULL
					EXEC dbo.NAP_Admin_Calculate_26 @matchid = @matchid
						,@bettype = 26
						,@fth = @fth
						,@fta = @fta
						,@betcount = @ticket_count
						,@IsSettleAbandonedMatch = @IsSettleAbandonedMatch
						,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair
						,@IsSettleAbandonedMatchIBC = @IsSettleAbandonedMatchIBC

				-- NAP_Admin_Calculate_27
				IF @betcount_27 IS NOT NULL
					EXEC dbo.NAP_Admin_Calculate_27 @matchid = @matchid
						,@bettype = 27
						,@fth = @fth
						,@fta = @fta
						,@betcount = @ticket_count
						,@IsSettleAbandonedMatch = @IsSettleAbandonedMatch
						,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair
						,@IsSettleAbandonedMatchIBC = @IsSettleAbandonedMatchIBC

				IF @row_count IS NOT NULL
					EXEC dbo.NAP_Admin_Calculate_RefundFT @matchid = @matchid
						,@IsExcludeBetdaq = @IsExcludeBetdaq
						,@IsExcludeBetfair = @IsExcludeBetfair
						,@IsSettleAbandonedMatchIBC = @IsSettleAbandonedMatchIBC
						,@fth = @fth
						,@fta = @fta
			END

			IF @mode = 'HT'
			BEGIN
				IF @betcount_8 IS NOT NULL
					EXEC dbo.NAP_Admin_Calculate_8 @matchid = @matchid
						,@bettype = @betcount_8
						,@totalht = @totalht
						,@betcount = @ticket_count
						,@IsSettleAbandonedMatch = @IsSettleAbandonedMatch
						,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair

				IF @row_count IS NOT NULL
					EXEC dbo.NAP_Admin_Calculate_RefundHT @matchid = @matchid
						,@IsExcludeBetdaq = @IsExcludeBetdaq
						,@IsExcludeBetfair = @IsExcludeBetfair
			END

			IF @mode = 'ALL'
			BEGIN
				-- NAP_Admin_Calculate_3
				IF @betcount_3 IS NOT NULL
					EXEC dbo.NAP_Admin_Calculate_3 @matchid = @matchid
						,@bettype = @betcount_3
						,@totalgoal = @totalgoal
						,@betcount = @ticket_count
						,@IsSettleAbandonedMatch = @IsSettleAbandonedMatch
						,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair

				-- NAP_Admin_Calculate_8
				IF @betcount_8 IS NOT NULL
					EXEC dbo.NAP_Admin_Calculate_8 @matchid = @matchid
						,@bettype = @betcount_8
						,@totalht = @totalht
						,@betcount = @ticket_count
						,@IsSettleAbandonedMatch = @IsSettleAbandonedMatch
						,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair

				-- NAP_Admin_Calculate_13
				IF @betcount_13 IS NOT NULL
					EXEC dbo.NAP_Admin_Calculate_13 @matchid = @matchid
						,@bettype = 13
						,@fth = @fth
						,@fta = @fta
						,@betcount = @ticket_count
						,@IsSettleAbandonedMatch = @IsSettleAbandonedMatch
						,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair
						,@IsSettleAbandonedMatchIBC = @IsSettleAbandonedMatchIBC

				-- NAP_Admin_Calculate_26
				IF @betcount_26 IS NOT NULL
					EXEC dbo.NAP_Admin_Calculate_26 @matchid = @matchid
						,@bettype = 26
						,@fth = @fth
						,@fta = @fta
						,@betcount = @ticket_count
						,@IsSettleAbandonedMatch = @IsSettleAbandonedMatch
						,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair
						,@IsSettleAbandonedMatchIBC = @IsSettleAbandonedMatchIBC

				-- NAP_Admin_Calculate_27
				IF @betcount_27 IS NOT NULL
					EXEC dbo.NAP_Admin_Calculate_27 @matchid = @matchid
						,@bettype = 27
						,@fth = @fth
						,@fta = @fta
						,@betcount = @ticket_count
						,@IsSettleAbandonedMatch = @IsSettleAbandonedMatch
						,@IsSettleAbandonedMatchBetFair = @IsSettleAbandonedMatchBetFair
						,@IsSettleAbandonedMatchIBC = @IsSettleAbandonedMatchIBC

				-- NAP_Admin_Calculate_RefundAll
				IF @row_count IS NOT NULL
					EXEC dbo.NAP_Admin_Calculate_RefundAll @matchid = @matchid
						,@IsExcludeBetdaq = @IsExcludeBetdaq
						,@IsExcludeBetfair = @IsExcludeBetfair
						,@IsSettleAbandonedMatchIBC = @IsSettleAbandonedMatchIBC
						,@fth = @fth
						,@fta = @fta
			END

			IF @mode = 'FGLG'
			BEGIN
				EXEC dbo.NAP_Admin_Calculate_RefundFGLG @matchid = @matchid
					,@LGOnly = @LGOnly
					,@matchdate = @matchdate
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
	END
END

GO

GRANT VIEW DEFINITION ON [NAP_Admin_Calculate_Main] TO [vnteam] AS [dbo]
GO


