ALTER PROCEDURE [NAP_Admin_Settlement_3] @matchid INT
	,@mode VARCHAR(6) = 'CAL'
AS
/*
	Created: Viet
	Task : Covered SP for settlement
	Original SP: Admin_Settlement_3
	DB: DBTRANS.bodb02

	Revisions:
	   
	Param's Explanation:
	• @Mode:
		CAL : All BetTypes
		CAL-HT : HT Only
		CAL-FT : FT Only (All Except HT)
*/
BEGIN
	SET NOCOUNT ON;

	-- result
	DECLARE @fth INT
	DECLARE @fta INT
	DECLARE @hth INT
	DECLARE @hta INT
	DECLARE @sporttype TINYINT
	DECLARE @betstatus NVARCHAR(50)
	DECLARE @GoalRecord VARCHAR(50)
	DECLARE @matchCode NVARCHAR(50)
	DECLARE @oddeven SMALLMONEY
	DECLARE @oddevenht SMALLMONEY
	DECLARE @totalgoal SMALLMONEY
	DECLARE @totalht SMALLMONEY
	DECLARE @scorediff SMALLMONEY
	DECLARE @scorediff_ht SMALLMONEY
	DECLARE @correctscore NVARCHAR(10)
	DECLARE @correctscore_ht NVARCHAR(10)
	DECLARE @HTFT NVARCHAR(10)
	-- for tennis
	DECLARE @TennisTotal SMALLINT
	DECLARE @T_Home SMALLINT
	DECLARE @T_Away SMALLINT
	--ticket count
	DECLARE @betcount_1 INT
	DECLARE @betcount_2 INT
	DECLARE @betcount_3 INT
	DECLARE @betcount_4 INT
	DECLARE @betcount_5 INT
	DECLARE @betcount_6 INT
	DECLARE @betcount_16 INT
	DECLARE @betcount_20 INT
	DECLARE @betcount_22 INT
	DECLARE @betcount_13 INT
	DECLARE @betcount_24 INT
	DECLARE @betcount_25 INT
	DECLARE @betcount_26 INT
	DECLARE @betcount_27 INT
	DECLARE @betcount_28 INT
	DECLARE @betcount_124 INT
	DECLARE @betcount_121 INT
	DECLARE @betcount_122 INT
	DECLARE @betcount_123 INT
	DECLARE @betcount_1201 INT
	DECLARE @betcount_1203 INT
	DECLARE @betcount_1204 INT
	DECLARE @betcount_1205 INT
	DECLARE @betcount_1206 INT
	DECLARE @betcount_1224 INT
	DECLARE @betcount_7 INT
	DECLARE @betcount_8 INT
	DECLARE @betcount_12 INT
	DECLARE @betcount_15 INT
	DECLARE @betcount_21 INT
	DECLARE @betcount_30 INT
	DECLARE @betcount_125 INT
	DECLARE @betcount_126 INT

	SELECT @fth = FinalHomeScore
		,@fta = FinalAwayScore
		,@hth = HTHomeScore
		,@HTA = HTAwayScore
		,@sporttype = SportType
		,@betstatus = betstatus
		,@GoalRecord = IsNull(GoalRecord, '')
		,@matchCode = IsNull(matchCode, '')
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

		SET @tmp = @fth
		SET @fth = @fta
		SET @fta = @tmp
	END

	SET @oddeven = CASE 
			WHEN @sporttype IN (5, 6, 9, 30) AND @TennisTotal > 0 THEN @TennisTotal % 2
			ELSE ((@fth + @fta) % 2)
			END
	SET @oddevenht = ((@hth + @hta) % 2)
	SET @totalgoal = CASE 
			WHEN @sporttype IN (5, 6, 9, 30) AND @TennisTotal > 0 THEN @TennisTotal
			ELSE (@fth + @fta)
			END
	SET @totalht = (@hth + @hta)
	SET @scorediff = (@fth - @fta)
	SET @scorediff_ht = (@hth - @hta)
	SET @correctscore = CAST(@fth AS NVARCHAR(6)) + ':' + CAST(@fta AS NVARCHAR(6))
	SET @correctscore_ht = CAST(@hth AS NVARCHAR(6)) + ':' + CAST(@hta AS NVARCHAR(6))
	SET @HTFT = CASE 
			WHEN @hth = @hta THEN '0'
			WHEN @hth > @hta THEN '1'
			ELSE '2'
			END + ':' + CASE 
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
		WHERE matchid = @matchid AND bettype IN (1, 2, 3, 4, 5, 6, 13, 16, 20, 22, 24, 25, 26, 27, 28, 121, 122, 123, 124, 1201, 1203, 1204, 1205, 1206, 1224)
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
		FROM bettrans WITH (NOLOCK)
		WHERE matchid = @matchid AND bettype IN (7, 8, 12, 15, 21, 30, 125, 126)
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
		,@totalgoal = @totalgoal
		,@totalht = @totalht
		,@scorediff = @scorediff
		,@scorediff_ht = @scorediff_ht
		,@correctscore = @correctscore
		,@correctscore_ht = @correctscore_ht
		,@HTFT = @HTFT
		,@TennisTotal = @TennisTotal
		,@T_Home = @T_Home
		,@T_Away = @T_Away
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
		,@CalledByBrokerService = 0 -- this one is called by NAP_Admin_Settlement_3 instead :)
END


GO

GRANT EXECUTE ON [NAP_Admin_Settlement_3] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [NAP_Admin_Settlement_3] TO [vnteam] AS [dbo]
GO


