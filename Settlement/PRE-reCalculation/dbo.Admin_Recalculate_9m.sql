

ALTER PROCEDURE [dbo].[Admin_Recalculate_9m]
	@matchid int,
	@fth int, 
	@fta int,
	@hth int, 
	@hta int,
	@matchdate datetime,
	@action varchar(10) = 'CAL',
	@TennisTotal tinyint = NULL
WITH RECOMPILE
AS
/*
	Created by:
	Task: Calculate Mix Parlay 
	DB: DBTRANS.BODB02
	
	Revision:
		- 20100424@Henry: Update column StatusID of Bettransm
		- 20100827@Jamie: 1st Money Line 
		- 20110221@Viet: Let this SP to run at DB04 as well (Requested by Eddie.Chen)
		- 20110624@Viet: Offer 'Refund-HT'
		- 20110806@Joe:
				-- remove big block of BEGIN/END for DB042 skipping, using RETURN instead.
				-- add support code for VOID
				-- add support code for live parlay
		- 20110822@Lukas: (merge code)
				- Include System Parlay
		- 20110923@Viet: exclude "void" tickets too (Joe has modified it from production @ 20110806, but it's somehow gone)
		- 20110912@Tom: Add new bettypes 30
				apply new bet type 1st correct score on Sport Books			
		- 20111025@Tom: exclude bettype = 14 when action is Refund/Refund-FT.
*/

BEGIN



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
		FROM dbo.bettransm with (ROWLOCK)
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
		FROM dbo.BetParlayDetail pd with (updlock)
		WHERE bettype <> 14 AND matchid = @matchid AND statusID NOT IN (101,102)
	END


END

GO
GRANT VIEW DEFINITION ON [dbo].[Admin_Recalculate_9m] TO [VNTeam]
GO 