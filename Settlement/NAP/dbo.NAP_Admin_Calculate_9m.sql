CREATE PROCEDURE [NAP_Admin_Calculate_9m]
	@matchid int,
	@fth int, @fta int,
	@hth int, @hta int,
	@matchdate datetime,
	@action varchar(10) = 'CAL',
	@TennisTotal tinyint = NULL,
	@VoidTransID varchar(2000) = '',
	@UserID INT = 0,
	
	@mode int = 0, -- new parameter, remove once already convert to new version
			-- 0 : original version, 1 : new version
	@strXML varchar(MAX) ='' OUTPUT,
	@statusID tinyint = 0,
	@winlostdate smalldatetime = NULL
	
WITH RECOMPILE
AS
/*
	Created by: Kathy
	Date: 20140213
	Task: Calculate Mix Parlay 
	DB: DBTRANS.BODB02
	Original: Admin_Calculate_9m
	
	Revision:
		
*/

IF @@SERVERNAME IN ('DB042', 'DB043', 'DB044') RETURN


IF @mode = 1
BEGIN
	Declare @odds smallmoney
	Declare @commWinRate smallmoney, @commLostRate smallmoney
	Declare @oldstatusID tinyint, @oldwinlost money, @winlost money
	Declare @xml XML

	-- get modds from XML string [edited by viet @ 20121213]
	SET @xml = convert(xml, @strXML)
 	
	declare @cal_modds as TABLE (transid bigint PRIMARY KEY, modds smallmoney, loseCnt tinyint)
	INSERT INTO @cal_modds (transid, modds, loseCnt)
	SELECT T.C.value('./@t', 'bigint'), -- transid
		isnull(T.C.value('./@m', 'smallmoney'),0), -- modds
		isnull(T.C.value('./@l', 'tinyint'),0) -- lostCnt
	from @xml.nodes('/root/r') as T(C)	


	UPDATE T
	SET
		statusID = @statusID,
		[status] = CASE @statusID
			WHEN 0 THEN 'running'
			WHEN 103 THEN 'Refund'
			WHEN 111 THEN 'DRAW'
			WHEN 112 THEN 'WON'
			WHEN 113 THEN 'LOSE'
			END,
		ruben = CASE @statusID
			WHEN 0 THEN 0
			ELSE 1
			END,
		winlostdate = @winlostdate,
		@odds = modds = CASE
			WHEN loseCnt > 0 THEN 0
			WHEN @statusID = 0 THEN 0
			ELSE m.modds
			END,
		
		@commWinRate = CASE comstatus -- 0 : pay normal, both win/lost -- 1 : pay 'double' ONLY on lost
		WHEN '0' THEN 1
		WHEN '1' THEN 0
		ELSE 1 END,
		@commLostRate = CASE comstatus
		WHEN '0' THEN 1
		WHEN '1' THEN 2
		ELSE 1 END,
		
		@winlost = winlost = CASE
			WHEN loseCnt > 0 THEN 0
			WHEN @statusID = 0 THEN 0
			ELSE stake*@odds
			END,
		awinlost = CASE 
			WHEN @statusID = 113 and loseCnt > 0  THEN  stake*apositiontaking
			WHEN @statusID IN (112, 113) THEN -stake*apositiontaking*(@odds-1)
			ELSE 0
			END,
		mwinlost = CASE
			WHEN @statusID = 113 and loseCnt > 0 THEN  stake*mpositiontaking
			WHEN @statusID IN (112, 113) THEN -stake*mpositiontaking*(@odds-1)		 
			ELSE 0
			END,
		swinlost = CASE
			WHEN @statusID = 113 and loseCnt > 0 THEN  stake*spositiontaking 
			WHEN @statusID IN (112, 113) THEN -stake*spositiontaking*(@odds-1)		
			ELSE 0
			END,

		playercomm	= CASE @statusID 
					WHEN 112 THEN @commWinRate  * stake*playerdiscount
					WHEN 113 THEN @commLostRate * stake*playerdiscount
					ELSE 0 END,
		comm		= CASE @statusID
					WHEN 112 THEN @commWinRate  * discount*stake*(1-apositiontaking)
					WHEN 113 THEN @commLostRate * discount*stake*(1-apositiontaking)
					ELSE 0 END,  
		acomm		= CASE @statusID
					WHEN 112 THEN @commWinRate  * adiscount*stake*(1-apositiontaking-mpositiontaking)
					WHEN 113 THEN @commLostRate * adiscount*stake*(1-apositiontaking-mpositiontaking)
					ELSE 0 END,
		scomm		= CASE @statusID
					WHEN 112 THEN @commWinRate  * sdiscount*stake*(1-apositiontaking-mpositiontaking-spositiontaking)
					WHEN 113 THEN @commLostRate * sdiscount*stake*(1-apositiontaking-mpositiontaking-spositiontaking)
					ELSE 0 END

	FROM dbo.bettrans T 
			INNER JOIN @cal_modds m ON T.transid = m.transid
				


		RETURN
END -- IF @mode = 1


-------------------------------------------------------------------------
-------------------------------------------------------------------------

Declare @modds smallmoney

UPDATE BM
SET bettype=o.bettype 
FROM dbo.bettransm BM with (updlock)
	INNER JOIN dbo.odds o with (nolock) ON BM.oddsid = o.oddsid
WHERE
	BM.matchid=@matchid
	AND BM.bettype <> o.bettype

-- ===================================================
IF @action = 'REFUND'
BEGIN
	UPDATE dbo.bettransm
	SET winlostdate=@matchdate,[status]='Refund',statuswinlost=0,ruben=1, statusID = 103
	WHERE matchid=@matchid
		AND bettype <> 14
		AND statusID NOT IN (101,102)
	
	UPDATE dbo.BetParlayDetail
	SET winlostdate=@matchdate,statuswinlost=0, statusID = 103
	WHERE matchid=@matchid 
		AND bettype <> 14
		AND statusID NOT IN (101,102)
END
-- ===================================================
ELSE IF @action = 'REFUND-FT'
BEGIN
	UPDATE dbo.bettransm
	SET winlostdate=@matchdate,[status]='Refund',statuswinlost=0,ruben=1, statusID = 103
	WHERE matchid=@matchid AND bettype NOT IN (7,8,12,15,21,30,14)
		AND statusID NOT IN (101,102)
	
	UPDATE dbo.BetParlayDetail
	SET winlostdate=@matchdate,statuswinlost=0, statusID = 103
	WHERE matchid=@matchid AND bettype NOT IN (7,8,12,15,21,30,14)
		AND statusID NOT IN (101,102)
END
	
ELSE IF @action = 'REFUND-HT'
BEGIN
	UPDATE dbo.bettransm
	SET winlostdate=@matchdate,[status]='Refund',statuswinlost=0,ruben=1, statusID = 103
	WHERE matchid=@matchid AND bettype IN (7,8,12,15,21,30)
		AND statusID NOT IN (101,102)

	UPDATE dbo.BetParlayDetail
	SET winlostdate=@matchdate,statuswinlost=0, statusID = 103
	WHERE matchid=@matchid AND bettype IN (7,8,12,15,21,30)
		AND statusID NOT IN (101,102)
END
-- ===================================================
ELSE IF @action = 'VOID'
BEGIN
	
	DECLARE @transtbl TABLE(transid BIGINT)
	INSERT INTO @transtbl
		SELECT CONVERT(BIGINT,val) FROM dbo.strSplit(@VoidTransID,',')	

	UPDATE dbo.bettransm
	SET winlost=CASE WHEN odds>0 THEN stake ELSE stake*ABS(odds) END
		,ruben=1,statuswinlost=0, status = 'VOID', creator = @UserID,statusID = 102,winlostdate = @matchdate
	WHERE matchid=@matchid
		AND statusID NOT IN (101,102)
		AND transid IN (SELECT transid FROM @transtbl)
	
	UPDATE dbo.BetParlayDetail
	SET statuswinlost=0, statusID = 102, winlostdate=@matchdate
	WHERE matchid=@matchid
		AND statusID NOT IN (101,102)
		AND transid IN (SELECT transid FROM @transtbl)

END
-- ===================================================
ELSE IF @action = 'UNDO'
BEGIN
	UPDATE dbo.bettransm
	SET [status]='running',statuswinlost=0,ruben=0, statusID = 0
	WHERE matchid=@matchid
		AND statusID NOT IN (101,102)
	
	UPDATE dbo.BetParlayDetail
	SET statuswinlost=0, statusID = 0
	WHERE matchid=@matchid
		AND statusID NOT IN (101,102)
END
-- ===================================================
-- ===================================================
ELSE IF @action = 'CAL'
BEGIN
	UPDATE dbo.bettransm with (updlock)
	SET
		@modds =
			CASE bettype
				when 1 then -- Handicap
					CASE betteam
					WHEN N'h' THEN (hdp2-hdp1) + (@fth - livehomescore) - (@fta - liveawayscore) 
					WHEN N'a' THEN (hdp1-hdp2) - (@fth - livehomescore) + (@fta - liveawayscore)
					END
				when 7 then -- 1st Handicap
					CASE betteam
					WHEN N'h' THEN (hdp2-hdp1) + (@hth - livehomescore) - (@hta - liveawayscore) 
					WHEN N'a' THEN (hdp1-hdp2) - (@hth - livehomescore) + (@hta - liveawayscore)
					END

				when 3 then -- Over/Under
					CASE betteam
					WHEN N'h' THEN (case when @TennisTotal IS NULL then @fth+@fta else @TennisTotal end) - hdp1 
					WHEN N'a' THEN hdp1 - (case when @TennisTotal IS NULL then @fth+@fta else @TennisTotal end)
					END
				when 8 then -- 1st Over/Under
					CASE betteam
					WHEN N'h' THEN (@hth+@hta) - hdp1
					WHEN N'a' THEN hdp1 - (@hth+@hta)
					END
				when 2 then -- Odd/Even
					case 
						when (betteam = N'h') AND ((case when @TennisTotal IS NULL then @fth+@fta else @TennisTotal end)&1 = 1) then 1
						when (betteam = N'a') AND ((case when @TennisTotal IS NULL then @fth+@fta else @TennisTotal end)&1 = 0) then 1
						else -1
					end
				when 12 then -- 1st Odd/Even
					case 
						when (betteam = N'h') AND ((@hth+@hta)&1 = 1) then 1
						when (betteam = N'a') AND ((@hth+@hta)&1 = 0) then 1
						else -1
					end
				when 4 then -- Correct Score
					case
					when betteam = ( CAST(@fth as varchar(4)) + ':' + CAST(@fta as varchar(4)) ) THEN 1
					when betteam = '5:0' AND (@fth - @fta) >=  5 THEN 1
					when betteam = '0:5' AND (@fth - @fta) <= -5 THEN 1
					else -1
					end
				when 30 then -- 1st Correct Score
					case
					when betteam = ( CAST(@hth as varchar(4)) + ':' + CAST(@hta as varchar(4)) ) THEN 1
					WHEN betteam = '4:0' AND (@hth - @hta) >=  4 THEN 1 -- 4UP for 1st Correct Score
					WHEN betteam = '0:4' AND (@hth - @hta) <=  -4 THEN 1 -- 4UP for 1st Correct Score
					when betteam = '5:0' AND (@hth - @hta) >=  5 THEN 1
					when betteam = '0:5' AND (@hth - @hta) <= -5 THEN 1
					else -1
					end					
				when 16 then -- HT/FT
					case
					when betteam =
						CASE WHEN @hth = @hta THEN '0' WHEN @hth > @hta THEN '1' ELSE '2' END + ':' +
						CASE WHEN @fth = @fta THEN '0' WHEN @fth > @fta THEN '1' ELSE '2' END
						THEN 1
					else -1
					end

				when 5 then -- 1x2
					case
					when (betteam = N'1') AND (@fth > @fta) then 1
					when (betteam = N'2') AND (@fta > @fth) then 1
					when (betteam = N'x') AND (@fth = @fta) then 1
					else -1
					end
				when 15 then -- 1st 1x2
					case 
					when (betteam = N'1') AND (@hth > @hta) then 1
					when (betteam = N'2') AND (@hta > @hth) then 1
					when (betteam = N'x') AND (@hth = @hta) then 1
					else -1
					end

				when 6 then -- Total Goal
					case when (
							case when @TennisTotal IS NULL then @fth+@fta else @TennisTotal end >= cast(left(betteam,1)as int) and
							case when @TennisTotal IS NULL then @fth+@fta else @TennisTotal end <= (
									case when right(betteam,1) = 'r' then 999 else 
									cast(right(betteam,1) as int) end
									)
							)  
					then 1 else -1 end

				when 13 then -- Clean Sheet
					CASE
						WHEN betteam = 'hy' AND @fta = 0 THEN 1
						WHEN betteam = 'hn' AND @fta > 0 THEN 1
						WHEN betteam = 'ay' AND @fth = 0 THEN 1
						WHEN betteam = 'an' AND @fth > 0 THEN 1
						ELSE -1
					END
				when 20 then -- Money Line
					CASE betteam
						WHEN N'h' THEN @fth - @fta
						ELSE @fta - @fth
					END
				when 21 then -- 1st Money Line
					CASE betteam
						WHEN N'h' THEN @hth - @hta
						ELSE @hta - @hth
					END
				when 24 then -- Double Chance
					CASE
						WHEN betteam = '1X' AND (@fth - @fta) >= 0 THEN 1
						WHEN betteam = '2X' AND (@fth - @fta) <= 0 THEN 1
						WHEN betteam = '12' AND (@fth - @fta) <> 0 THEN 1
						ELSE -1
					END
				when 25 then -- Draw No Bet
					CASE
						WHEN (@fth - @fta) = 0 THEN 0
						WHEN betteam = 'h' AND (@fth - @fta) > 0 THEN 1
						WHEN betteam = 'a' AND (@fth - @fta) < 0 THEN 1
						ELSE -1
					END
				when 26 then -- Both/One/Neither team to score
					CASE
						WHEN betteam = 'b' AND  (@fth > 0 AND @fta >0 ) THEN 1
						WHEN betteam = 'o' AND ((@fth > 0 and @fta = 0) OR (@fta > 0 and @fth = 0)) THEN 1
						WHEN betteam = 'n' AND  (@fth = 0 AND @fta = 0) THEN 1
						ELSE -1
					END
				when 27 then -- To win to nil
					CASE
						WHEN betteam = 'h' AND (@fth > @fta AND @fta = 0 ) THEN 1
						WHEN betteam = 'a' AND (@fta > @fth AND @fth = 0 ) THEN 1
						ELSE -1
					END
				when 28 then -- 3-way handicap
					CASE
						WHEN betteam = '1' AND ( hdp2 - hdp1 + @fth - @fta) > 0 THEN 1
						WHEN betteam = '2' AND ( hdp1 - hdp2 + @fta - @fth) > 0 THEN 1
						WHEN betteam = 'x' AND ((hdp1 - hdp2) - (@fth - @fta)) = 0 THEN 1
						ELSE -1
					END
				when 121 then -- home no bet
					CASE
						WHEN (@fth - @fta) > 0 THEN 0
						WHEN betteam = 'x' AND (@fth - @fta) = 0 THEN 1
						WHEN betteam = 'a' AND (@fth - @fta) < 0 THEN 1
						ELSE -1
					END
				when 122 then -- away no bet
					CASE
						WHEN (@fth - @fta) < 0 THEN 0
						WHEN betteam = 'h' AND (@fth - @fta) > 0 THEN 1
						WHEN betteam = 'x' AND (@fth - @fta) = 0 THEN 1
						ELSE -1
					END
				when 123 then -- draw/no draw
					CASE						
						WHEN betteam = 'h' AND (@fth - @fta) = 0 THEN 1
						WHEN betteam = 'a' AND (@fth - @fta) <> 0 THEN 1
						ELSE -1
					END
			ELSE
				NULL  -- Not support bettype
			END, -- CASE bettype
	-- ========================
		ruben = CASE WHEN @modds IS NULL THEN 0 ELSE 1 END,
		winlostdate=@matchdate,
		[status]=
			case
				when @modds IS NULL then N'running'
				when @modds=0 then N'DRAW'
				when @modds<0 then N'LOSE'
				when @modds>0 then N'WON'
			end ,
		statusID = 
			case
				when @modds IS NULL then 0
				when @modds=0 then 111
				when @modds<0 then 113
				when @modds>0 then 112
			end ,
		statuswinlost=
			case
				when @modds<=-0.5 then 4 -- LOSE
				when @modds>= 0.5 then 2 -- WIN
				when @modds>0 then 1 -- Half WIN
				when @modds<0 then 3 -- Half LOSE
				else 0	-- DRAW
			end
	-- ========================
	FROM dbo.bettransm with (INDEX=IX_matchid)
	WHERE 
		matchid = @matchid
		AND bettype <> 14
		AND statusID NOT IN (101,102)
	
	-- BetParlayDetail
	UPDATE pd
	SET
		@modds =
			CASE bettype
				when 1 then -- Handicap
					CASE betteam
					WHEN N'h' THEN (hdp2-hdp1) + (@fth - livehomescore) - (@fta - liveawayscore) 
					WHEN N'a' THEN (hdp1-hdp2) - (@fth - livehomescore) + (@fta - liveawayscore)
					END
				when 7 then -- 1st Handicap
					CASE betteam
					WHEN N'h' THEN (hdp2-hdp1) + (@hth - livehomescore) - (@hta - liveawayscore) 
					WHEN N'a' THEN (hdp1-hdp2) - (@hth - livehomescore) + (@hta - liveawayscore)
					END

				when 3 then -- Over/Under
					CASE betteam
					WHEN N'h' THEN (case when @TennisTotal IS NULL then @fth+@fta else @TennisTotal end) - hdp1 
					WHEN N'a' THEN hdp1 - (case when @TennisTotal IS NULL then @fth+@fta else @TennisTotal end)
					END
				when 8 then -- 1st Over/Under
					CASE betteam
					WHEN N'h' THEN (@hth+@hta) - hdp1
					WHEN N'a' THEN hdp1 - (@hth+@hta)
					END
				when 2 then -- Odd/Even
					case 
						when (betteam = N'h') AND ((case when @TennisTotal IS NULL then @fth+@fta else @TennisTotal end)&1 = 1) then 1
						when (betteam = N'a') AND ((case when @TennisTotal IS NULL then @fth+@fta else @TennisTotal end)&1 = 0) then 1
						else -1
					end
				when 12 then -- 1st Odd/Even
					case 
						when (betteam = N'h') AND ((@hth+@hta)&1 = 1) then 1
						when (betteam = N'a') AND ((@hth+@hta)&1 = 0) then 1
						else -1
					end
				when 4 then -- Correct Score
					case
					when betteam = ( CAST(@fth as varchar(4)) + ':' + CAST(@fta as varchar(4)) ) THEN 1
					when betteam = '5:0' AND (@fth - @fta) >=  5 THEN 1
					when betteam = '0:5' AND (@fth - @fta) <= -5 THEN 1
					else -1
					end
				when 30 then -- 1st Correct Score
					case
					when betteam = ( CAST(@hth as varchar(4)) + ':' + CAST(@hta as varchar(4)) ) THEN 1
					WHEN betteam = '4:0' AND (@hth - @hta) >=  4 THEN 1 -- 4UP for 1st Correct Score
					WHEN betteam = '0:4' AND (@hth - @hta) <=  -4 THEN 1 -- 4UP for 1st Correct Score
					when betteam = '5:0' AND (@hth - @hta) >=  5 THEN 1
					when betteam = '0:5' AND (@hth - @hta) <= -5 THEN 1
					else -1
					end					
				when 16 then -- HT/FT
					case
					when betteam =
						CASE WHEN @hth = @hta THEN '0' WHEN @hth > @hta THEN '1' ELSE '2' END + ':' +
						CASE WHEN @fth = @fta THEN '0' WHEN @fth > @fta THEN '1' ELSE '2' END
						THEN 1
					else -1
					end

				when 5 then -- 1x2
					case
					when (betteam = N'1') AND (@fth > @fta) then 1
					when (betteam = N'2') AND (@fta > @fth) then 1
					when (betteam = N'x') AND (@fth = @fta) then 1
					else -1
					end
				when 15 then -- 1st 1x2
					case 
					when (betteam = N'1') AND (@hth > @hta) then 1
					when (betteam = N'2') AND (@hta > @hth) then 1
					when (betteam = N'x') AND (@hth = @hta) then 1
					else -1
					end

				when 6 then -- Total Goal
					case when (
							case when @TennisTotal IS NULL then @fth+@fta else @TennisTotal end >= cast(left(betteam,1)as int) and
							case when @TennisTotal IS NULL then @fth+@fta else @TennisTotal end <= (
									case when right(betteam,1) = 'r' then 999 else 
									cast(right(betteam,1) as int) end
									)
							)  
					then 1 else -1 end

				when 13 then -- Clean Sheet
					CASE
						WHEN betteam = 'hy' AND @fta = 0 THEN 1
						WHEN betteam = 'hn' AND @fta > 0 THEN 1
						WHEN betteam = 'ay' AND @fth = 0 THEN 1
						WHEN betteam = 'an' AND @fth > 0 THEN 1
						ELSE -1
					END
				when 20 then -- Money Line
					CASE betteam
						WHEN N'h' THEN @fth - @fta
						ELSE @fta - @fth
					END
				when 21 then -- 1st Money Line
					CASE betteam
						WHEN N'h' THEN @hth - @hta
						ELSE @hta - @hth
					END
				when 24 then -- Double Chance
					CASE
						WHEN betteam = '1X' AND (@fth - @fta) >= 0 THEN 1
						WHEN betteam = '2X' AND (@fth - @fta) <= 0 THEN 1
						WHEN betteam = '12' AND (@fth - @fta) <> 0 THEN 1
						ELSE -1
					END
				when 25 then -- Draw No Bet
					CASE
						WHEN (@fth - @fta) = 0 THEN 0
						WHEN betteam = 'h' AND (@fth - @fta) > 0 THEN 1
						WHEN betteam = 'a' AND (@fth - @fta) < 0 THEN 1
						ELSE -1
					END
				when 26 then -- Both/One/Neither team to score
					CASE
						WHEN betteam = 'b' AND  (@fth > 0 AND @fta >0 ) THEN 1
						WHEN betteam = 'o' AND ((@fth > 0 and @fta = 0) OR (@fta > 0 and @fth = 0)) THEN 1
						WHEN betteam = 'n' AND  (@fth = 0 AND @fta = 0) THEN 1
						ELSE -1
					END
				when 27 then -- To win to nil
					CASE
						WHEN betteam = 'h' AND (@fth > @fta AND @fta = 0 ) THEN 1
						WHEN betteam = 'a' AND (@fta > @fth AND @fth = 0 ) THEN 1
						ELSE -1
					END
				when 28 then -- 3-way handicap
					CASE
						WHEN betteam = '1' AND ( hdp2 - hdp1 + @fth - @fta) > 0 THEN 1
						WHEN betteam = '2' AND ( hdp1 - hdp2 + @fta - @fth) > 0 THEN 1
						WHEN betteam = 'x' AND ((hdp1 - hdp2) - (@fth - @fta)) = 0 THEN 1
						ELSE -1
					END
				when 121 then -- home no bet
					CASE
						WHEN (@fth - @fta) > 0 THEN 0
						WHEN betteam = 'x' AND (@fth - @fta) = 0 THEN 1
						WHEN betteam = 'a' AND (@fth - @fta) < 0 THEN 1
						ELSE -1
					END
				when 122 then -- away no bet
					CASE
						WHEN (@fth - @fta) < 0 THEN 0
						WHEN betteam = 'h' AND (@fth - @fta) > 0 THEN 1
						WHEN betteam = 'x' AND (@fth - @fta) = 0 THEN 1
						ELSE -1
					END
				when 123 then -- draw/no draw
					CASE						
						WHEN betteam = 'h' AND (@fth - @fta) = 0 THEN 1
						WHEN betteam = 'a' AND (@fth - @fta) <> 0 THEN 1
						ELSE -1
					END
			ELSE
				NULL  -- Not support bettype
			END, -- CASE bettype
	-- ========================
		winlostdate=@matchdate,
		statusID = 
			case
				when @modds IS NULL then 0
				when @modds=0 then 111
				when @modds<0 then 113
				when @modds>0 then 112
			end ,
		statuswinlost=
			case
				when @modds<=-0.5 then 4 -- LOSE
				when @modds>= 0.5 then 2 -- WIN
				when @modds>0 then 1 -- Half WIN
				when @modds<0 then 3 -- Half LOSE
				else 0	-- DRAW
			end
	-- ========================
	FROM dbo.BetParlayDetail pd with (updlock, INDEX=IX_matchid)
	WHERE bettype <> 14 AND matchid = @matchid AND statusID NOT IN (101,102)
END
-- ===================================================
-- ===================================================


GO

GRANT VIEW DEFINITION ON [NAP_Admin_Calculate_9m] TO [vnteam] AS [dbo]
GO


