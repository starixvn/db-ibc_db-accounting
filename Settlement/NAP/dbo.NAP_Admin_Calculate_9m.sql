ALTER PROCEDURE [NAP_Admin_Calculate_9m] @matchid INT
	,@fth INT
	,@fta INT
	,@hth INT
	,@hta INT
	,@matchdate DATETIME
	,@action VARCHAR(10) = 'CAL'
	,@TennisTotal TINYINT = NULL
	,@VoidTransID VARCHAR(2000) = ''
	,@UserID INT = 0
	,@mode INT = 0
	,-- new parameter, remove once already convert to new version
	-- 0 : original version, 1 : new version
	@strXML VARCHAR(MAX) = '' OUTPUT
	,@statusID TINYINT = 0
	,@winlostdate SMALLDATETIME = NULL WITH RECOMPILE
AS
/*
	Created by: Kathy
	Date: 20140213
	Task: Calculate Mix Parlay 
	DB: DBTRANS.BODB02
	Original: Admin_Calculate_9m
	
	Revision:
		
*/
BEGIN
	IF @@SERVERNAME IN ('DB042', 'DB043', 'DB044') RETURN

	IF @mode = 1
	BEGIN
		DECLARE @odds SMALLMONEY
		DECLARE @commWinRate SMALLMONEY
			,@commLostRate SMALLMONEY
		DECLARE @oldstatusID TINYINT
			,@oldwinlost MONEY
			,@winlost MONEY
		DECLARE @xml XML

		-- get modds from XML string [edited by viet @ 20121213]
		SET @xml = convert(XML, @strXML)

		DECLARE @cal_modds AS TABLE (
			transid BIGINT PRIMARY KEY
			,modds SMALLMONEY
			,loseCnt TINYINT
			)

		INSERT INTO @cal_modds (
			transid
			,modds
			,loseCnt
			)
		SELECT T.C.value('./@t', 'bigint')
			,-- transid
			isnull(T.C.value('./@m', 'smallmoney'), 0)
			,-- modds
			isnull(T.C.value('./@l', 'tinyint'), 0) -- lostCnt
		FROM @xml.nodes('/root/r') AS T(C)

		UPDATE T
		SET statusID = @statusID
			,[status] = CASE @statusID
				WHEN 0 THEN 'running'
				WHEN 103 THEN 'Refund'
				WHEN 111 THEN 'DRAW'
				WHEN 112 THEN 'WON'
				WHEN 113 THEN 'LOSE'
				END
			,ruben = CASE @statusID
				WHEN 0 THEN 0
				ELSE 1
				END
			,winlostdate = @winlostdate
			,@odds = modds = CASE 
				WHEN loseCnt > 0 THEN 0
				WHEN @statusID = 0 THEN 0
				ELSE m.modds
				END
			,@commWinRate = CASE comstatus -- 0 : pay normal, both win/lost -- 1 : pay 'double' ONLY on lost
				WHEN '0' THEN 1
				WHEN '1' THEN 0
				ELSE 1
				END
			,@commLostRate = CASE comstatus
				WHEN '0' THEN 1
				WHEN '1' THEN 2
				ELSE 1
				END
			,@winlost = winlost = CASE 
				WHEN loseCnt > 0 THEN 0
				WHEN @statusID = 0 THEN 0
				ELSE stake * @odds
				END
			,awinlost = CASE 
				WHEN @statusID = 113 AND loseCnt > 0 THEN stake * apositiontaking
				WHEN @statusID IN (112, 113) THEN - stake * apositiontaking * (@odds - 1)
				ELSE 0
				END
			,mwinlost = CASE 
				WHEN @statusID = 113 AND loseCnt > 0 THEN stake * mpositiontaking
				WHEN @statusID IN (112, 113) THEN - stake * mpositiontaking * (@odds - 1)
				ELSE 0
				END
			,swinlost = CASE 
				WHEN @statusID = 113 AND loseCnt > 0 THEN stake * spositiontaking
				WHEN @statusID IN (112, 113) THEN - stake * spositiontaking * (@odds - 1)
				ELSE 0
				END
			,playercomm = CASE @statusID
				WHEN 112 THEN @commWinRate * stake * playerdiscount
				WHEN 113 THEN @commLostRate * stake * playerdiscount
				ELSE 0
				END
			,comm = CASE @statusID
				WHEN 112 THEN @commWinRate * discount * stake * (1 - apositiontaking)
				WHEN 113 THEN @commLostRate * discount * stake * (1 - apositiontaking)
				ELSE 0
				END
			,acomm = CASE @statusID
				WHEN 112 THEN @commWinRate * adiscount * stake * (1 - apositiontaking - mpositiontaking)
				WHEN 113 THEN @commLostRate * adiscount * stake * (1 - apositiontaking - mpositiontaking)
				ELSE 0
				END
			,scomm = CASE @statusID
				WHEN 112 THEN @commWinRate * sdiscount * stake * (1 - apositiontaking - mpositiontaking - spositiontaking)
				WHEN 113 THEN @commLostRate * sdiscount * stake * (1 - apositiontaking - mpositiontaking - spositiontaking)
				ELSE 0
				END
		FROM dbo.bettrans T
			INNER JOIN @cal_modds m ON T.transid = m.transid

		RETURN
	END -- IF @mode = 1

	-------------------------------------------------------------------------
	-------------------------------------------------------------------------
	DECLARE @modds SMALLMONEY

	UPDATE BM
	SET bettype = o.bettype
	FROM dbo.bettransm BM WITH (UPDLOCK)
		INNER JOIN dbo.odds o WITH (NOLOCK) ON BM.oddsid = o.oddsid
	WHERE BM.matchid = @matchid AND BM.bettype <> o.bettype

	-- ===================================================
	IF @action = 'REFUND'
	BEGIN
		UPDATE dbo.bettransm
		SET winlostdate = @matchdate
			,[status] = 'Refund'
			,statuswinlost = 0
			,ruben = 1
			,statusID = 103
		WHERE matchid = @matchid AND bettype <> 14 AND statusID NOT IN (101, 102)

		UPDATE dbo.BetParlayDetail
		SET winlostdate = @matchdate
			,statuswinlost = 0
			,statusID = 103
		WHERE matchid = @matchid AND bettype <> 14 AND statusID NOT IN (101, 102)
	END
			-- ===================================================
	ELSE IF @action = 'REFUND-FT'
	BEGIN
		UPDATE dbo.bettransm
		SET winlostdate = @matchdate
			,[status] = 'Refund'
			,statuswinlost = 0
			,ruben = 1
			,statusID = 103
		WHERE matchid = @matchid AND bettype NOT IN (7, 8, 12, 15, 21, 30, 14) AND statusID NOT IN (101, 102)

		UPDATE dbo.BetParlayDetail
		SET winlostdate = @matchdate
			,statuswinlost = 0
			,statusID = 103
		WHERE matchid = @matchid AND bettype NOT IN (7, 8, 12, 15, 21, 30, 14) AND statusID NOT IN (101, 102)
	END
	ELSE IF @action = 'REFUND-HT'
	BEGIN
		UPDATE dbo.bettransm
		SET winlostdate = @matchdate
			,[status] = 'Refund'
			,statuswinlost = 0
			,ruben = 1
			,statusID = 103
		WHERE matchid = @matchid AND bettype IN (7, 8, 12, 15, 21, 30) AND statusID NOT IN (101, 102)

		UPDATE dbo.BetParlayDetail
		SET winlostdate = @matchdate
			,statuswinlost = 0
			,statusID = 103
		WHERE matchid = @matchid AND bettype IN (7, 8, 12, 15, 21, 30) AND statusID NOT IN (101, 102)
	END
			-- ===================================================
	ELSE IF @action = 'VOID'
	BEGIN
		DECLARE @transtbl TABLE (transid BIGINT)

		INSERT INTO @transtbl
		SELECT CONVERT(BIGINT, val)
		FROM dbo.strSplit(@VoidTransID, ',')

		UPDATE dbo.bettransm
		SET winlost = CASE 
				WHEN odds > 0 THEN stake
				ELSE stake * ABS(odds)
				END
			,ruben = 1
			,statuswinlost = 0
			,STATUS = 'VOID'
			,creator = @UserID
			,statusID = 102
			,winlostdate = @matchdate
		WHERE matchid = @matchid AND statusID NOT IN (101, 102) AND transid IN (
				SELECT transid
				FROM @transtbl
				)

		UPDATE dbo.BetParlayDetail
		SET statuswinlost = 0
			,statusID = 102
			,winlostdate = @matchdate
		WHERE matchid = @matchid AND statusID NOT IN (101, 102) AND transid IN (
				SELECT transid
				FROM @transtbl
				)
	END
			-- ===================================================
	ELSE IF @action = 'UNDO'
	BEGIN
		UPDATE dbo.bettransm
		SET [status] = 'running'
			,statuswinlost = 0
			,ruben = 0
			,statusID = 0
		WHERE matchid = @matchid AND statusID NOT IN (101, 102)

		UPDATE dbo.BetParlayDetail
		SET statuswinlost = 0
			,statusID = 0
		WHERE matchid = @matchid AND statusID NOT IN (101, 102)
	END
			-- ===================================================
			-- ===================================================
	ELSE IF @action = 'CAL'
	BEGIN
		UPDATE dbo.bettransm WITH (UPDLOCK)
		SET @modds = CASE bettype
				WHEN 1 THEN -- Handicap
					CASE betteam
						WHEN N'h' THEN (hdp2 - hdp1) + (@fth - livehomescore) - (@fta - liveawayscore)
						WHEN N'a' THEN (hdp1 - hdp2) - (@fth - livehomescore) + (@fta - liveawayscore)
						END
				WHEN 7 THEN -- 1st Handicap
					CASE betteam
						WHEN N'h' THEN (hdp2 - hdp1) + (@hth - livehomescore) - (@hta - liveawayscore)
						WHEN N'a' THEN (hdp1 - hdp2) - (@hth - livehomescore) + (@hta - liveawayscore)
						END
				WHEN 3 THEN -- Over/Under
					CASE betteam
						WHEN N'h' THEN (CASE 
								WHEN @TennisTotal IS NULL THEN @fth + @fta
								ELSE @TennisTotal END
								) - hdp1
						WHEN N'a' THEN hdp1 - (CASE 
								WHEN @TennisTotal IS NULL THEN @fth + @fta
								ELSE @TennisTotal END
								)
						END
				WHEN 8 THEN -- 1st Over/Under
					CASE betteam
						WHEN N'h' THEN (@hth + @hta) - hdp1
						WHEN N'a' THEN hdp1 - (@hth + @hta)
						END
				WHEN 2 THEN -- Odd/Even
					CASE 
						WHEN (betteam = N'h') AND (
								(CASE 
									WHEN @TennisTotal IS NULL THEN @fth + @fta
									ELSE @TennisTotal END
									) & 1 = 1
								) THEN 1
						WHEN (betteam = N'a') AND (
								(CASE 
									WHEN @TennisTotal IS NULL THEN @fth + @fta
									ELSE @TennisTotal END
									) & 1 = 0
								) THEN 1
						ELSE - 1
						END
				WHEN 12 THEN -- 1st Odd/Even
					CASE 
						WHEN (betteam = N'h') AND ((@hth + @hta) & 1 = 1) THEN 1
						WHEN (betteam = N'a') AND ((@hth + @hta) & 1 = 0) THEN 1
						ELSE - 1
						END
				WHEN 4 THEN -- Correct Score
					CASE 
						WHEN betteam = (CAST(@fth AS VARCHAR(4)) + ':' + CAST(@fta AS VARCHAR(4))) THEN 1
						WHEN betteam = '5:0' AND (@fth - @fta) >= 5 THEN 1
						WHEN betteam = '0:5' AND (@fth - @fta) <= - 5 THEN 1
						ELSE - 1
						END
				WHEN 30 THEN -- 1st Correct Score
					CASE 
						WHEN betteam = (CAST(@hth AS VARCHAR(4)) + ':' + CAST(@hta AS VARCHAR(4))) THEN 1
						WHEN betteam = '4:0' AND (@hth - @hta) >= 4 THEN 1 -- 4UP for 1st Correct Score
						WHEN betteam = '0:4' AND (@hth - @hta) <= - 4 THEN 1 -- 4UP for 1st Correct Score
						WHEN betteam = '5:0' AND (@hth - @hta) >= 5 THEN 1
						WHEN betteam = '0:5' AND (@hth - @hta) <= - 5 THEN 1
						ELSE - 1
						END
				WHEN 16 THEN -- HT/FT
					CASE 
						WHEN betteam = CASE 
								WHEN @hth = @hta THEN '0'
								WHEN @hth > @hta THEN '1'
								ELSE '2'
								END + ':' + CASE 
								WHEN @fth = @fta THEN '0'
								WHEN @fth > @fta THEN '1'
								ELSE '2'
								END THEN 1
						ELSE - 1
						END
				WHEN 5 THEN -- 1x2
					CASE 
						WHEN (betteam = N'1') AND (@fth > @fta) THEN 1
						WHEN (betteam = N'2') AND (@fta > @fth) THEN 1
						WHEN (betteam = N'x') AND (@fth = @fta) THEN 1
						ELSE - 1
						END
				WHEN 15 THEN -- 1st 1x2
					CASE 
						WHEN (betteam = N'1') AND (@hth > @hta) THEN 1
						WHEN (betteam = N'2') AND (@hta > @hth) THEN 1
						WHEN (betteam = N'x') AND (@hth = @hta) THEN 1
						ELSE - 1
						END
				WHEN 6 THEN -- Total Goal
					CASE 
						WHEN (CASE 
								WHEN @TennisTotal IS NULL THEN @fth + @fta
								ELSE @TennisTotal END >= cast(left(betteam, 1) AS INT) AND CASE 
								WHEN @TennisTotal IS NULL THEN @fth + @fta
								ELSE @TennisTotal END <= (CASE 
									WHEN right(betteam, 1) = 'r' THEN 999
									ELSE cast(right(betteam, 1) AS INT) END
									)
								) THEN 1
						ELSE - 1
						END
				WHEN 13 THEN -- Clean Sheet
					CASE 
						WHEN betteam = 'hy' AND @fta = 0 THEN 1
						WHEN betteam = 'hn' AND @fta > 0 THEN 1
						WHEN betteam = 'ay' AND @fth = 0 THEN 1
						WHEN betteam = 'an' AND @fth > 0 THEN 1
						ELSE - 1
						END
				WHEN 20 THEN -- Money Line
					CASE betteam
						WHEN N'h' THEN @fth - @fta
						ELSE @fta - @fth
						END
				WHEN 21 THEN -- 1st Money Line
					CASE betteam
						WHEN N'h' THEN @hth - @hta
						ELSE @hta - @hth
						END
				WHEN 24 THEN -- Double Chance
					CASE 
						WHEN betteam = '1X' AND (@fth - @fta) >= 0 THEN 1
						WHEN betteam = '2X' AND (@fth - @fta) <= 0 THEN 1
						WHEN betteam = '12' AND (@fth - @fta) <> 0 THEN 1
						ELSE - 1
						END
				WHEN 25 THEN -- Draw No Bet
					CASE 
						WHEN (@fth - @fta) = 0 THEN 0
						WHEN betteam = 'h' AND (@fth - @fta) > 0 THEN 1
						WHEN betteam = 'a' AND (@fth - @fta) < 0 THEN 1
						ELSE - 1
						END
				WHEN 26 THEN -- Both/One/Neither team to score
					CASE 
						WHEN betteam = 'b' AND (@fth > 0 AND @fta > 0) THEN 1
						WHEN betteam = 'o' AND ((@fth > 0 AND @fta = 0) OR (@fta > 0 AND @fth = 0)) THEN 1
						WHEN betteam = 'n' AND (@fth = 0 AND @fta = 0) THEN 1
						ELSE - 1
						END
				WHEN 27 THEN -- To win to nil
					CASE 
						WHEN betteam = 'h' AND (@fth > @fta AND @fta = 0) THEN 1
						WHEN betteam = 'a' AND (@fta > @fth AND @fth = 0) THEN 1
						ELSE - 1
						END
				WHEN 28 THEN -- 3-way handicap
					CASE 
						WHEN betteam = '1' AND (hdp2 - hdp1 + @fth - @fta) > 0 THEN 1
						WHEN betteam = '2' AND (hdp1 - hdp2 + @fta - @fth) > 0 THEN 1
						WHEN betteam = 'x' AND ((hdp1 - hdp2) - (@fth - @fta)) = 0 THEN 1
						ELSE - 1
						END
				WHEN 121 THEN -- home no bet
					CASE 
						WHEN (@fth - @fta) > 0 THEN 0
						WHEN betteam = 'x' AND (@fth - @fta) = 0 THEN 1
						WHEN betteam = 'a' AND (@fth - @fta) < 0 THEN 1
						ELSE - 1
						END
				WHEN 122 THEN -- away no bet
					CASE 
						WHEN (@fth - @fta) < 0 THEN 0
						WHEN betteam = 'h' AND (@fth - @fta) > 0 THEN 1
						WHEN betteam = 'x' AND (@fth - @fta) = 0 THEN 1
						ELSE - 1
						END
				WHEN 123 THEN -- draw/no draw
					CASE 
						WHEN betteam = 'h' AND (@fth - @fta) = 0 THEN 1
						WHEN betteam = 'a' AND (@fth - @fta) <> 0 THEN 1
						ELSE - 1
						END
				ELSE NULL -- Not support bettype
				END
			,-- CASE bettype
			-- ========================
			ruben = CASE 
				WHEN @modds IS NULL THEN 0
				ELSE 1
				END
			,winlostdate = @matchdate
			,[status] = CASE 
				WHEN @modds IS NULL THEN N'running'
				WHEN @modds = 0 THEN N'DRAW'
				WHEN @modds < 0 THEN N'LOSE'
				WHEN @modds > 0 THEN N'WON'
				END
			,statusID = CASE 
				WHEN @modds IS NULL THEN 0
				WHEN @modds = 0 THEN 111
				WHEN @modds < 0 THEN 113
				WHEN @modds > 0 THEN 112
				END
			,statuswinlost = CASE 
				WHEN @modds <= - 0.5 THEN 4 -- LOSE
				WHEN @modds >= 0.5 THEN 2 -- WIN
				WHEN @modds > 0 THEN 1 -- Half WIN
				WHEN @modds < 0 THEN 3 -- Half LOSE
				ELSE 0 -- DRAW
				END
		-- ========================
		FROM dbo.bettransm WITH (INDEX = IX_matchid)
		WHERE matchid = @matchid AND bettype <> 14 AND statusID NOT IN (101, 102)

		-- BetParlayDetail
		UPDATE pd
		SET @modds = CASE bettype
				WHEN 1 THEN -- Handicap
					CASE betteam
						WHEN N'h' THEN (hdp2 - hdp1) + (@fth - livehomescore) - (@fta - liveawayscore)
						WHEN N'a' THEN (hdp1 - hdp2) - (@fth - livehomescore) + (@fta - liveawayscore)
						END
				WHEN 7 THEN -- 1st Handicap
					CASE betteam
						WHEN N'h' THEN (hdp2 - hdp1) + (@hth - livehomescore) - (@hta - liveawayscore)
						WHEN N'a' THEN (hdp1 - hdp2) - (@hth - livehomescore) + (@hta - liveawayscore)
						END
				WHEN 3 THEN -- Over/Under
					CASE betteam
						WHEN N'h' THEN (CASE 
								WHEN @TennisTotal IS NULL THEN @fth + @fta
								ELSE @TennisTotal END
								) - hdp1
						WHEN N'a' THEN hdp1 - (CASE 
								WHEN @TennisTotal IS NULL THEN @fth + @fta
								ELSE @TennisTotal END
								)
						END
				WHEN 8 THEN -- 1st Over/Under
					CASE betteam
						WHEN N'h' THEN (@hth + @hta) - hdp1
						WHEN N'a' THEN hdp1 - (@hth + @hta)
						END
				WHEN 2 THEN -- Odd/Even
					CASE 
						WHEN (betteam = N'h') AND (
								(CASE 
									WHEN @TennisTotal IS NULL THEN @fth + @fta
									ELSE @TennisTotal END
									) & 1 = 1
								) THEN 1
						WHEN (betteam = N'a') AND (
								(CASE 
									WHEN @TennisTotal IS NULL THEN @fth + @fta
									ELSE @TennisTotal END
									) & 1 = 0
								) THEN 1
						ELSE - 1
						END
				WHEN 12 THEN -- 1st Odd/Even
					CASE 
						WHEN (betteam = N'h') AND ((@hth + @hta) & 1 = 1) THEN 1
						WHEN (betteam = N'a') AND ((@hth + @hta) & 1 = 0) THEN 1
						ELSE - 1
						END
				WHEN 4 THEN -- Correct Score
					CASE 
						WHEN betteam = (CAST(@fth AS VARCHAR(4)) + ':' + CAST(@fta AS VARCHAR(4))) THEN 1
						WHEN betteam = '5:0' AND (@fth - @fta) >= 5 THEN 1
						WHEN betteam = '0:5' AND (@fth - @fta) <= - 5 THEN 1
						ELSE - 1
						END
				WHEN 30 THEN -- 1st Correct Score
					CASE 
						WHEN betteam = (CAST(@hth AS VARCHAR(4)) + ':' + CAST(@hta AS VARCHAR(4))) THEN 1
						WHEN betteam = '4:0' AND (@hth - @hta) >= 4 THEN 1 -- 4UP for 1st Correct Score
						WHEN betteam = '0:4' AND (@hth - @hta) <= - 4 THEN 1 -- 4UP for 1st Correct Score
						WHEN betteam = '5:0' AND (@hth - @hta) >= 5 THEN 1
						WHEN betteam = '0:5' AND (@hth - @hta) <= - 5 THEN 1
						ELSE - 1
						END
				WHEN 16 THEN -- HT/FT
					CASE 
						WHEN betteam = CASE 
								WHEN @hth = @hta THEN '0'
								WHEN @hth > @hta THEN '1'
								ELSE '2'
								END + ':' + CASE 
								WHEN @fth = @fta THEN '0'
								WHEN @fth > @fta THEN '1'
								ELSE '2'
								END THEN 1
						ELSE - 1
						END
				WHEN 5 THEN -- 1x2
					CASE 
						WHEN (betteam = N'1') AND (@fth > @fta) THEN 1
						WHEN (betteam = N'2') AND (@fta > @fth) THEN 1
						WHEN (betteam = N'x') AND (@fth = @fta) THEN 1
						ELSE - 1
						END
				WHEN 15 THEN -- 1st 1x2
					CASE 
						WHEN (betteam = N'1') AND (@hth > @hta) THEN 1
						WHEN (betteam = N'2') AND (@hta > @hth) THEN 1
						WHEN (betteam = N'x') AND (@hth = @hta) THEN 1
						ELSE - 1
						END
				WHEN 6 THEN -- Total Goal
					CASE 
						WHEN (CASE 
								WHEN @TennisTotal IS NULL THEN @fth + @fta
								ELSE @TennisTotal END >= cast(left(betteam, 1) AS INT) AND CASE 
								WHEN @TennisTotal IS NULL THEN @fth + @fta
								ELSE @TennisTotal END <= (CASE 
									WHEN right(betteam, 1) = 'r' THEN 999
									ELSE cast(right(betteam, 1) AS INT) END
									)
								) THEN 1
						ELSE - 1
						END
				WHEN 13 THEN -- Clean Sheet
					CASE 
						WHEN betteam = 'hy' AND @fta = 0 THEN 1
						WHEN betteam = 'hn' AND @fta > 0 THEN 1
						WHEN betteam = 'ay' AND @fth = 0 THEN 1
						WHEN betteam = 'an' AND @fth > 0 THEN 1
						ELSE - 1
						END
				WHEN 20 THEN -- Money Line
					CASE betteam
						WHEN N'h' THEN @fth - @fta
						ELSE @fta - @fth
						END
				WHEN 21 THEN -- 1st Money Line
					CASE betteam
						WHEN N'h' THEN @hth - @hta
						ELSE @hta - @hth
						END
				WHEN 24 THEN -- Double Chance
					CASE 
						WHEN betteam = '1X' AND (@fth - @fta) >= 0 THEN 1
						WHEN betteam = '2X' AND (@fth - @fta) <= 0 THEN 1
						WHEN betteam = '12' AND (@fth - @fta) <> 0 THEN 1
						ELSE - 1
						END
				WHEN 25 THEN -- Draw No Bet
					CASE 
						WHEN (@fth - @fta) = 0 THEN 0
						WHEN betteam = 'h' AND (@fth - @fta) > 0 THEN 1
						WHEN betteam = 'a' AND (@fth - @fta) < 0 THEN 1
						ELSE - 1
						END
				WHEN 26 THEN -- Both/One/Neither team to score
					CASE 
						WHEN betteam = 'b' AND (@fth > 0 AND @fta > 0) THEN 1
						WHEN betteam = 'o' AND ((@fth > 0 AND @fta = 0) OR (@fta > 0 AND @fth = 0)) THEN 1
						WHEN betteam = 'n' AND (@fth = 0 AND @fta = 0) THEN 1
						ELSE - 1
						END
				WHEN 27 THEN -- To win to nil
					CASE 
						WHEN betteam = 'h' AND (@fth > @fta AND @fta = 0) THEN 1
						WHEN betteam = 'a' AND (@fta > @fth AND @fth = 0) THEN 1
						ELSE - 1
						END
				WHEN 28 THEN -- 3-way handicap
					CASE 
						WHEN betteam = '1' AND (hdp2 - hdp1 + @fth - @fta) > 0 THEN 1
						WHEN betteam = '2' AND (hdp1 - hdp2 + @fta - @fth) > 0 THEN 1
						WHEN betteam = 'x' AND ((hdp1 - hdp2) - (@fth - @fta)) = 0 THEN 1
						ELSE - 1
						END
				WHEN 121 THEN -- home no bet
					CASE 
						WHEN (@fth - @fta) > 0 THEN 0
						WHEN betteam = 'x' AND (@fth - @fta) = 0 THEN 1
						WHEN betteam = 'a' AND (@fth - @fta) < 0 THEN 1
						ELSE - 1
						END
				WHEN 122 THEN -- away no bet
					CASE 
						WHEN (@fth - @fta) < 0 THEN 0
						WHEN betteam = 'h' AND (@fth - @fta) > 0 THEN 1
						WHEN betteam = 'x' AND (@fth - @fta) = 0 THEN 1
						ELSE - 1
						END
				WHEN 123 THEN -- draw/no draw
					CASE 
						WHEN betteam = 'h' AND (@fth - @fta) = 0 THEN 1
						WHEN betteam = 'a' AND (@fth - @fta) <> 0 THEN 1
						ELSE - 1
						END
				ELSE NULL -- Not support bettype
				END
			,-- CASE bettype
			-- ========================
			winlostdate = @matchdate
			,statusID = CASE 
				WHEN @modds IS NULL THEN 0
				WHEN @modds = 0 THEN 111
				WHEN @modds < 0 THEN 113
				WHEN @modds > 0 THEN 112
				END
			,statuswinlost = CASE 
				WHEN @modds <= - 0.5 THEN 4 -- LOSE
				WHEN @modds >= 0.5 THEN 2 -- WIN
				WHEN @modds > 0 THEN 1 -- Half WIN
				WHEN @modds < 0 THEN 3 -- Half LOSE
				ELSE 0 -- DRAW
				END
		-- ========================
		FROM dbo.BetParlayDetail pd WITH (UPDLOCK, INDEX = IX_matchid)
		WHERE bettype <> 14 AND matchid = @matchid AND statusID NOT IN (101, 102)
	END
END
	-- ===================================================
	-- ===================================================


GO

GRANT VIEW DEFINITION ON [NAP_Admin_Calculate_9m] TO [vnteam] AS [dbo]
GO


