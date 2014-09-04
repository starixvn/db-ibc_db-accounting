/****** Object:  StoredProcedure [dbo].[NAP_Admin_Settlement_3]    Script Date: 09/04/2014 13:21:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[NAP_Admin_Settlement_3] @matchid INT
	,@mode VARCHAR(6) = 'CAL'
AS
/*
	Created: Viet
	Task : Covered SP for settlement
	Original SP: Admin_Settlement_3
	DB: DBTRANS.bodb02

	Revisions:
	   - 20140426@Kathy: Add 1H Total Goal (126) [Redmine:#14449]
	   - 20140617@Kathy: Apply BetRadar [Redmine:#17142]
	   - 20140807@Kathy: Support new 11 bettypes [Redmine:#19667]
	   - 20140822@Jamie: Add bet count 11 bettypes [Redmine:#19667]

	Param's Explanation:
	• @Mode:
		CAL : All BetTypes
		CAL-HT : HT Only
		CAL-FT : FT Only (All Except HT)
*/
BEGIN
	SET NOCOUNT ON;

	-- result
	DECLARE @fth				INT
			,@fta 				INT
			,@hth 				INT
			,@hta 				INT
			,@sporttype			TINYINT
			,@betstatus			NVARCHAR(50)
			,@GoalRecord		VARCHAR(50)
			,@matchCode			NVARCHAR(50)
			,@oddeven			SMALLMONEY
			,@oddevenht			SMALLMONEY
			,@oddevenhome		SMALLMONEY
			,@oddevenhome_ht	SMALLMONEY
			,@oddevenaway		SMALLMONEY
			,@oddevenaway_ht	SMALLMONEY			
			,@totalgoal			SMALLMONEY
			,@totalht			SMALLMONEY
			,@totalhome			SMALLMONEY
			,@totalaway			SMALLMONEY
			,@scorediff			SMALLMONEY
			,@scorediff_ht		SMALLMONEY
			,@correctscore		NVARCHAR(10)
			,@correctscore_ht	NVARCHAR(10)
			,@HTFT				NVARCHAR(10)
			,@isRefundHT		BIT
			
			-- for tennis
			,@TennisTotal		SMALLINT
			,@T_Home			SMALLINT
			,@T_Away			SMALLINT

	--ticket count
	DECLARE @betcount_1		INT
			,@betcount_2 	INT
			,@betcount_3 	INT
			,@betcount_4 	INT
			,@betcount_5 	INT
			,@betcount_6 	INT
			,@betcount_16 	INT
			,@betcount_20 	INT
			,@betcount_22 	INT
			,@betcount_13 	INT
			,@betcount_24 	INT
			,@betcount_25 	INT
			,@betcount_26 	INT
			,@betcount_27 	INT
			,@betcount_28 	INT
			,@betcount_121 	INT
			,@betcount_122 	INT
			,@betcount_123 	INT
			,@betcount_124 	INT
			,@betcount_128 	INT  -- HT/FT Odd/Even			
			,@betcount_130 	INT -- Exact Goal
			,@betcount_131 	INT -- Home Team Total Goal
			,@betcount_132 	INT -- Away Team Total Goal			
			,@betcount_137 	INT -- Home Team Odd/Even			
			,@betcount_139 	INT -- Away Team Odd/Even			
			,@betcount_144 	INT -- Result/Total Goals
			-- VS
			,@betcount_1201 INT
			,@betcount_1203 INT
			,@betcount_1204 INT
			,@betcount_1205 INT
			,@betcount_1206 INT
			,@betcount_1224 INT
			--HT ticket
			,@betcount_7 	INT
			,@betcount_8 	INT
			,@betcount_12 	INT
			,@betcount_15 	INT
			,@betcount_21 	INT
			,@betcount_30 	INT
			,@betcount_125 	INT
			,@betcount_126 	INT
			,@betcount_129 	INT -- 1H Exact Goal
			,@betcount_136 	INT -- 1H Home Team Odd/Even
			,@betcount_138 	INT -- 1H Away Team Odd/Even
			,@betcount_143 	INT -- 1H Result/Total Goals	
			-- BetRadar
			,@betcount_133 	INT
			,@betcount_134 	INT
			,@betcount_140 	INT
			,@betcount_141 	INT
			,@betcount_142 	INT	
			,@betcount_145 	INT
			,@betcount_146 	INT
			,@betcount_147 	INT
			,@betcount_148 	INT
			,@betcount_149 	INT
			,@betcount_150 	INT
			,@betcount_151 	INT
			,@betcount_152 	INT

	SELECT @fth = FinalHomeScore
		,@fta = FinalAwayScore
		,@hth = HTHomeScore
		,@hta = HTAwayScore
		,@sporttype = SportType
		,@betstatus = betstatus
		,@isRefundHT = CASE WHEN betstatus LIKE 'Refund HT%' THEN 1 ELSE 0 END 
		,@GoalRecord = ISNULL(GoalRecord, '')
		,@matchCode = ISNULL(matchCode, '')
	FROM DBPRO.BODB02.dbo.Match WITH (NOLOCK)
	WHERE matchid = @matchid

	IF @SportType IN (5, 6, 9, 30) -- Tennis/VolleyBall/Badminton/Squash : get TotalGamesPlayed
	BEGIN
		EXEC dbo.NAP_Admin_Settlement_2 @betstatus = @betstatus
			,@Total = @TennisTotal OUTPUT
			,@TotalHome = @T_Home OUTPUT
			,@TotalAway = @T_Away OUTPUT
	END

	IF @SportType = 10 -- Golf, using Stroke count, so swap the score to make it become normal stype
	BEGIN
		DECLARE @tmp INT

		SELECT @tmp = @fth
			  ,@fth = @fta
			  ,@fta = @tmp
	END

	SELECT @oddeven = CASE 
							WHEN @sporttype IN (5, 6, 9, 30) AND @TennisTotal > 0 THEN @TennisTotal % 2
							ELSE ((@fth + @fta) % 2)
					  END
		,@oddevenht = ((@hth + @hta) % 2)
		,@oddevenhome = CASE 
						WHEN @sporttype IN (5, 6, 9, 30) AND @T_Home > 0 THEN @T_Home % 2
						ELSE ((@fth ) % 2)
					  END
		,@oddevenhome_ht = @hth % 2
		,@oddevenaway = CASE 
							WHEN @sporttype IN (5, 6, 9, 30) AND @T_Away > 0 THEN @T_Away % 2
							ELSE ((@fta) % 2)
						END
		,@oddevenaway_ht = @hta % 2
		,@totalgoal = CASE 
						WHEN @sporttype IN (5, 6, 9, 30) AND @TennisTotal > 0 THEN @TennisTotal
						ELSE (@fth + @fta)
					  END
		,@totalht = (@hth + @hta)
		,@totalhome = @fth
		,@totalaway = @fta
		,@scorediff = (@fth - @fta)
		,@scorediff_ht = (@hth - @hta)
		,@correctscore = CAST(@fth AS NVARCHAR(6)) + ':' + CAST(@fta AS NVARCHAR(6))
		,@correctscore_ht = CAST(@hth AS NVARCHAR(6)) + ':' + CAST(@hta AS NVARCHAR(6))
		,@HTFT = CASE 
					WHEN @hth = @hta THEN '0'
					WHEN @hth > @hta THEN '1'
					ELSE '2'
				 END + ':' 
			  + CASE 
					WHEN @fth = @fta THEN '0'
					WHEN @fth > @fta THEN '1'
					ELSE '2'
				END

	IF EXISTS (
			SELECT transid
			FROM dbo.bettrans WITH (NOLOCK)
			WHERE matchid = @matchid AND bettype = 22
			) AND LEN(@GoalRecord) <> @TotalGoal
	BEGIN
		RAISERROR ('Goal record is not consistent with the score, please correct Goal record before calculating.', 16, 1)

		RETURN
	END

	IF @Mode IN ('CAL-FT', 'CAL')
	BEGIN
		SELECT @betcount_1 = ISNULL(SUM(CASE bettype
						WHEN 1 THEN 1
						ELSE 0
						END), 0)
			,@betcount_2 = ISNULL(SUM(CASE bettype
						WHEN 2 THEN 1
						ELSE 0
						END), 0)
			,@betcount_3 = ISNULL(SUM(CASE bettype
						WHEN 3 THEN 1
						ELSE 0
						END), 0)
			,@betcount_4 = ISNULL(SUM(CASE bettype
						WHEN 4 THEN 1
						ELSE 0
						END), 0)
			,@betcount_5 = ISNULL(SUM(CASE bettype
						WHEN 5 THEN 1
						ELSE 0
						END), 0)
			,@betcount_6 = ISNULL(SUM(CASE bettype
						WHEN 6 THEN 1
						ELSE 0
						END), 0)
			,@betcount_13 = ISNULL(SUM(CASE bettype
						WHEN 13 THEN 1
						ELSE 0
						END), 0)
			,@betcount_16 = ISNULL(SUM(CASE bettype
						WHEN 16 THEN 1
						ELSE 0
						END), 0)
			,@betcount_20 = ISNULL(SUM(CASE bettype
						WHEN 20 THEN 1
						ELSE 0
						END), 0)
			,@betcount_22 = ISNULL(SUM(CASE bettype
						WHEN 22 THEN 1
						ELSE 0
						END), 0)
			,@betcount_24 = ISNULL(SUM(CASE bettype
						WHEN 24 THEN 1
						ELSE 0
						END), 0)
			,@betcount_25 = ISNULL(SUM(CASE bettype
						WHEN 25 THEN 1
						ELSE 0
						END), 0)
			,@betcount_26 = ISNULL(SUM(CASE bettype
						WHEN 26 THEN 1
						ELSE 0
						END), 0)
			,@betcount_27 = ISNULL(SUM(CASE bettype
						WHEN 27 THEN 1
						ELSE 0
						END), 0)
			,@betcount_28 = ISNULL(SUM(CASE bettype
						WHEN 28 THEN 1
						ELSE 0
						END), 0)
			,@betcount_121 = ISNULL(SUM(CASE bettype
						WHEN 121 THEN 1
						ELSE 0
						END), 0)
			,@betcount_122 = ISNULL(SUM(CASE bettype
						WHEN 122 THEN 1
						ELSE 0
						END), 0)
			,@betcount_123 = ISNULL(SUM(CASE bettype
						WHEN 123 THEN 1
						ELSE 0
						END), 0)
			,@betcount_124 = ISNULL(SUM(CASE bettype
						WHEN 124 THEN 1
						ELSE 0
						END), 0)
			,@betcount_128 = ISNULL(SUM(CASE bettype
						WHEN 128 THEN 1
						ELSE 0
						END), 0)
			,@betcount_130 = ISNULL(SUM(CASE bettype
						WHEN 130 THEN 1
						ELSE 0
						END), 0)
			,@betcount_131 = ISNULL(SUM(CASE bettype
						WHEN 131 THEN 1
						ELSE 0
						END), 0)
			,@betcount_132 = ISNULL(SUM(CASE bettype
						WHEN 132 THEN 1
						ELSE 0
						END), 0)
			,@betcount_133 = ISNULL(SUM(case bettype 
						when 133 then 1 
						else 0
						end), 0)
			,@betcount_134 = ISNULL(SUM(case bettype 
						when 134 then 1 
						else 0 
						end), 0)
			,@betcount_137 = ISNULL(SUM(CASE bettype
						WHEN 137 THEN 1
						ELSE 0
						END), 0)
			,@betcount_139 = ISNULL(SUM(CASE bettype
						WHEN 139 THEN 1
						ELSE 0
						END), 0)
			,@betcount_140 = ISNULL(SUM(case bettype 
						when 140 then 1 
						else 0 
						end), 0)
			,@betcount_141 = ISNULL(SUM(case bettype 
						when 141 then 1 
						else 0 
						end), 0)
			,@betcount_142 = ISNULL(SUM(case bettype 
						when 142 then 1 
						else 0 
						end), 0)
			,@betcount_144 = ISNULL(SUM(CASE bettype
						WHEN 144 THEN 1
						ELSE 0
						END), 0)
			,@betcount_145 = ISNULL(SUM(case bettype 
						when 145 then 1 
						else 0 
						end), 0)
			,@betcount_146 = ISNULL(SUM(case bettype 
						when 146 then 1 
						else 0 
						end), 0)
			,@betcount_147 = ISNULL(SUM(case bettype 
						when 147 then 1 
						else 0 
						end), 0)
			,@betcount_148 = ISNULL(SUM(case bettype 
						when 148 then 1 
						else 0 
						end), 0)
			,@betcount_149 = ISNULL(SUM(case bettype 
						when 149 then 1 
						else 0 
						end), 0)
			,@betcount_150 = ISNULL(SUM(case bettype 
						when 150 then 1 
						else 0 
						end), 0)
			,@betcount_152 = ISNULL(SUM(case bettype 
						when 152 then 1 
						else 0 
						end), 0)
			,@betcount_1201 = ISNULL(SUM(CASE bettype
						WHEN 1201 THEN 1
						ELSE 0
						END), 0)
			,@betcount_1203 = ISNULL(SUM(CASE bettype
						WHEN 1203 THEN 1
						ELSE 0
						END), 0)
			,@betcount_1204 = ISNULL(SUM(CASE bettype
						WHEN 1204 THEN 1
						ELSE 0
						END), 0)
			,@betcount_1205 = ISNULL(SUM(CASE bettype
						WHEN 1205 THEN 1
						ELSE 0
						END), 0)
			,@betcount_1206 = ISNULL(SUM(CASE bettype
						WHEN 1206 THEN 1
						ELSE 0
						END), 0)
			,@betcount_1224 = ISNULL(SUM(CASE bettype
						WHEN 1224 THEN 1
						ELSE 0
						END), 0)
		FROM bettrans WITH (NOLOCK)
		WHERE matchid = @matchid AND bettype IN (1, 2, 3, 4, 5, 6, 13, 16, 20, 22, 24, 25, 26, 27, 28, 121, 122, 123, 124, 128, 130, 131, 132,
												133, 134, 137, 139, 140, 141, 142, 144, 145, 146, 147, 148, 149, 150, 152,
												1201, 1203, 1204, 1205, 1206, 1224)
	END

	IF @Mode IN ('CAL-HT', 'CAL') AND @SportType NOT IN (180, 181, 182, 183, 184, 185, 186)
	BEGIN
		SELECT @betcount_7 = ISNULL(SUM(CASE bettype
						WHEN 7 THEN 1
						ELSE 0
						END), 0)
			,@betcount_8 = ISNULL(SUM(CASE bettype
						WHEN 8 THEN 1
						ELSE 0
						END), 0)
			,@betcount_12 = ISNULL(SUM(CASE bettype
						WHEN 12 THEN 1
						ELSE 0
						END), 0)
			,@betcount_15 = ISNULL(SUM(CASE bettype
						WHEN 15 THEN 1
						ELSE 0
						END), 0)
			,@betcount_21 = ISNULL(SUM(CASE bettype
						WHEN 21 THEN 1
						ELSE 0
						END), 0)
			,@betcount_30 = ISNULL(SUM(CASE bettype
						WHEN 30 THEN 1
						ELSE 0
						END), 0)
			,@betcount_125 = ISNULL(SUM(CASE bettype
						WHEN 125 THEN 1
						ELSE 0
						END), 0)
			,@betcount_126 = ISNULL(SUM(CASE bettype
						WHEN 126 THEN 1
						ELSE 0
						END), 0)
			,@betcount_129 = ISNULL(SUM(CASE bettype
						WHEN 129 THEN 1
						ELSE 0
						END), 0)
			,@betcount_136 = ISNULL(SUM(CASE bettype
						WHEN 136 THEN 1
						ELSE 0
						END), 0)
			,@betcount_138 = ISNULL(SUM(CASE bettype
						WHEN 138 THEN 1
						ELSE 0
						END), 0)
			,@betcount_143 = ISNULL(SUM(CASE bettype
						WHEN 143 THEN 1
						ELSE 0
						END), 0)
			,@betcount_151 = ISNULL(SUM(case bettype
						when 151 then 1 
						else 0 
						end), 0)
		FROM bettrans WITH (NOLOCK)
		WHERE matchid = @matchid AND bettype IN (7, 8, 12, 15, 21, 30, 125, 126, 129, 136, 138, 143, 151)
	END
	
	-- call execrep SP
	EXEC dbo.NAP_Admin_Calculate_Main @matchid = @matchid
		,@mode = @mode
		,@fth = @fth
		,@fta = @fta
		,@hth = @hth
		,@hta = @hta
		,@sporttype = @sporttype
		,@betstatus = @betstatus
		,@GoalRecord = @GoalRecord
		,@matchCode = @matchCode
		,@oddeven = @oddeven
		,@oddevenht = @oddevenht
		,@oddevenhome = @oddevenhome
		,@oddevenhome_ht = @oddevenhome_ht
		,@oddevenaway = @oddevenaway
		,@oddevenaway_ht = @oddevenaway_ht
		,@totalgoal = @totalgoal
		,@totalht = @totalht
		,@totalhome = @totalhome
		,@totalaway = @totalaway
		,@scorediff = @scorediff
		,@scorediff_ht = @scorediff_ht
		,@correctscore = @correctscore
		,@correctscore_ht = @correctscore_ht
		,@HTFT = @HTFT
		,@TennisTotal = @TennisTotal
		,@T_Home = @T_Home
		,@T_Away = @T_Away
		,@isRefundHT = @isRefundHT
		,@betcount_1 = @betcount_1
		,@betcount_2 = @betcount_2
		,@betcount_3 = @betcount_3
		,@betcount_4 = @betcount_4
		,@betcount_5 = @betcount_5
		,@betcount_6 = @betcount_6
		,@betcount_16 = @betcount_16
		,@betcount_20 = @betcount_20
		,@betcount_22 = @betcount_22
		,@betcount_13 = @betcount_13
		,@betcount_24 = @betcount_24
		,@betcount_25 = @betcount_25
		,@betcount_26 = @betcount_26
		,@betcount_27 = @betcount_27
		,@betcount_28 = @betcount_28
		,@betcount_124 = @betcount_124
		,@betcount_121 = @betcount_121
		,@betcount_122 = @betcount_122
		,@betcount_123 = @betcount_123
		,@betcount_128 = @betcount_128
		,@betcount_130 = @betcount_130
		,@betcount_131 = @betcount_131
		,@betcount_132 = @betcount_132
		,@betcount_133 = @betcount_133
		,@betcount_134 = @betcount_134
		,@betcount_137 = @betcount_137
		,@betcount_139 = @betcount_139
		,@betcount_140 = @betcount_140
		,@betcount_141 = @betcount_141
		,@betcount_142 = @betcount_142
		,@betcount_144 = @betcount_144
		,@betcount_145 = @betcount_145
		,@betcount_146 = @betcount_146
		,@betcount_147 = @betcount_147
		,@betcount_148 = @betcount_148
		,@betcount_149 = @betcount_149
		,@betcount_150 = @betcount_150
		,@betcount_152 = @betcount_152
		,@betcount_1201 = @betcount_1201
		,@betcount_1203 = @betcount_1203
		,@betcount_1204 = @betcount_1204
		,@betcount_1205 = @betcount_1205
		,@betcount_1206 = @betcount_1206
		,@betcount_1224 = @betcount_1224
		,@betcount_7 = @betcount_7
		,@betcount_8 = @betcount_8
		,@betcount_12 = @betcount_12
		,@betcount_15 = @betcount_15
		,@betcount_21 = @betcount_21
		,@betcount_30 = @betcount_30
		,@betcount_125 = @betcount_125
		,@betcount_126 = @betcount_126
		,@betcount_129 = @betcount_129					
		,@betcount_136 = @betcount_136				
		,@betcount_138 = @betcount_138	
		,@betcount_143 = @betcount_143
		,@betcount_151 = @betcount_151
		,@CalledByBrokerService = 0 -- this one is called by NAP_Admin_Settlement_3 instead :)
END



GO
GRANT EXECUTE ON [dbo].[NAP_Admin_Settlement_3] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Admin_Settlement_3] TO [vnteam] AS [dbo]