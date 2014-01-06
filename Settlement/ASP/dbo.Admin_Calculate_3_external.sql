ALTER PROCEDURE [dbo].[Admin_Calculate_3_external] 
	@matchid	INT,
	@bettype	SMALLINT,
	@totalgoal	SMALLMONEY,
	@IsSettleAbandonedMatch bit =0,
	@IsSettleAbandonedMatchBetFair bit =0
AS

/*
	Created by:Lukas
	Date:20110112
	Task: Settlement 
	DB: DBO52/BODB02
	Original: DBO2.BODB02.dbo.[Admin_Calculate_3_db052]

	Revisions:
		- 20090423@PhuongDao: Change DB04 to DB042
		- 20100517@Henry: Update column StatusID of Bettrans (DRAW:111, WON: 112, LOSE: 113)
		- 20100521@Henry: Change to use StatusID instead of Status in WHERE statement
		- 20100625@Phuc: Force SQL engine using cluster index(CIX_recommend_matchid_bettype)(version on DB05/DB052). 
			Note: we deployed separated version for this sp one version on DB05/DB052(using CIX_recommend_matchid_bettype index)
			and original one for other DB. When edit this sp need to edit and re-deploy main version first then version on DB05/DB052.
		- 20110105@Lukas: Re-arrange bettype
		- 20110112@Lukas: Separate settlement for DB052
		- 20111021@Joe: Apply rounding winlost amount to 2 decimal places
		- 20120215@Jamie: Settle Determined tickets for Over/Under BetDaq
		- 20120822@Dan: Add virtual soccer
		- 20121019@Johnson: Check double comm losing status
		- 20140106@Elodie: Option to exclude Bet Fair tickets in refund process (Redmine:#9764)

	Param's Explanation:
		+ @IsSettleAbandonedMatch: Settle determined tickets for Abandoned/Postponed Match
		+ @IsSettleAbandonedMatchBetFair: Is Settlement for Betfair ticket of Abandoned/postponed match or not

*/
BEGIN
	SET NOCOUNT ON

	Declare @modds smallmoney, @commWinRate smallmoney, @commLostRate smallmoney

	IF @IsSettleAbandonedMatch = 1 OR @IsSettleAbandonedMatchBetFair = 1
	BEGIN
	
		UPDATE dbo.bettrans with (ROWLOCK, UPDLOCK)
		SET @modds = modds = CASE betteam
			WHEN N'h' THEN @totalgoal-hdp1
			WHEN N'a' THEN hdp1-@totalgoal
			END,		
			
		@commWinRate = CASE comstatus -- 0 : pay normal, both win/lost -- 1 : pay 'double' ONLY on lost
			WHEN '0' THEN 1
			WHEN '1' THEN 0
			ELSE 1 END,
		@commLostRate = CASE comstatus
			WHEN '0' THEN 1
			WHEN '1' THEN 2
			ELSE 1 END,		
			
		WinLost = CASE
			WHEN betteam = N'h' AND @modds >= 0.5 THEN actual_stake + stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,1203) then odds-1 else odds end) end) -- WIN
			WHEN betteam = N'a' AND @modds <= -0.5 THEN 0	-- LOSE		
			END,
		aWinLost = CASE
			WHEN betteam = N'h' AND @modds >= 0.5 THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,1203) then odds-1 else odds end) end) * -apositiontaking
			WHEN betteam = N'a' AND @modds <= -0.5 THEN actual_stake * apositiontaking
			END,
		mWinLost = CASE
			WHEN betteam = N'h' AND @modds >= 0.5 THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,1203) then odds-1 else odds end) end) * -mpositiontaking
			WHEN betteam = N'a' AND @modds <= -0.5 THEN actual_stake * mpositiontaking
			END,
		sWinLost = CASE
			WHEN betteam = N'h' AND @modds >= 0.5 THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,1203) then odds-1 else odds end) end) * -spositiontaking
			WHEN betteam = N'a' AND @modds <= -0.5 THEN actual_stake * spositiontaking
			END,
		PlayerComm = CASE
			WHEN (betteam = N'h' AND @modds >= 0.5) THEN @commWinRate * playerdiscount * stake
			WHEN (betteam = N'a' AND @modds <= -0.5) THEN @commLostRate * playerdiscount * stake
			END,
		Comm = CASE
			WHEN (betteam = N'h' AND @modds >= 0.5) THEN @commWinRate * discount * stake * (1-apositiontaking)
			WHEN (betteam = N'a' AND @modds <= -0.5) THEN @commLostRate * discount * stake * (1-apositiontaking)
			END,
		aComm = CASE
			WHEN (betteam = N'h' AND @modds >= 0.5) THEN @commWinRate * adiscount * stake * (1-(mpositiontaking+apositiontaking))
			WHEN (betteam = N'a' AND @modds <= -0.5) THEN @commLostRate * adiscount * stake * (1-(mpositiontaking+apositiontaking))
			END,
		sComm = CASE
			WHEN (betteam = N'h' AND @modds >= 0.5) THEN @commWinRate * sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking))
			WHEN (betteam = N'a' AND @modds <= -0.5) THEN @commLostRate * sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking))
			END,
		Status = CASE
			WHEN (betteam = N'h' AND @modds >= 0.5) THEN N'WON'
			WHEN (betteam = N'a' AND @modds <= -0.5) THEN N'LOSE'
			END,
		StatusID = CASE
			WHEN (betteam = N'h' AND @modds >= 0.5) THEN 112 --WON
			WHEN (betteam = N'a' AND @modds <= -0.5) THEN 113 --LOSE
			END,
		ruben=1

		WHERE
			matchid=@matchid AND
			bettype=@bettype AND
			--status NOT IN (N'VOID', N'REJECT')
			statusID NOT IN (101,102) AND 
			1 = CASE WHEN @IsSettleAbandonedMatch = 1 AND (custid IN (50057, 879241, 103873, 78761, 1077687) or recommend = 1688156) THEN 1
					 WHEN @IsSettleAbandonedMatchBetFair = 1 AND custid IN (2331, 1077687) THEN 1
					 ELSE 0 END 
			AND (hdp1 <= @totalgoal - 0.5)


	END
	ELSE 
	BEGIN

		Declare @affectedagents int

		CREATE TABLE #tmpRecommend(recommend INT  PRIMARY KEY)
		INSERT INTO #tmpRecommend(recommend)
		SELECT DISTINCT recommend
		FROM dbo.bettrans (nolock) WHERE matchid = @matchid and bettype = @bettype
		DECLARE @currecommend TABLE(recommend int PRIMARY KEY)

		WHILE 1=1
		BEGIN
			delete @currecommend
			delete top(100) from #tmpRecommend output DELETED.recommend into @currecommend
			set @affectedagents = @@rowcount
			
			UPDATE b
			SET @modds = modds = CASE betteam
				WHEN N'h' THEN @totalgoal-hdp1
				WHEN N'a' THEN hdp1-@totalgoal
				END,
				
			@commWinRate = CASE comstatus -- 0 : pay normal, both win/lost -- 1 : pay 'double' ONLY on lost
				WHEN '0' THEN 1
				WHEN '1' THEN 0
				ELSE 1 END,
			@commLostRate = CASE comstatus
				WHEN '0' THEN 1
				WHEN '1' THEN 2
				ELSE 1 END,			
				
			WinLost = CASE
				WHEN @modds >  0.25	THEN actual_stake + stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,1203) then odds-1 else odds end) end)
				WHEN @modds =  0.25	THEN actual_stake + stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,1203) then odds-1 else odds end) end) * 0.5
				WHEN @modds =  0	THEN actual_stake
				WHEN @modds = -0.25	THEN actual_stake * 0.5
				WHEN @modds < -0.25	THEN 0
				END,

			aWinLost = CASE
				WHEN @modds >  0.25	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,1203) then odds-1 else odds end) end) * -apositiontaking
				WHEN @modds =  0.25	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,1203) then odds-1 else odds end) end) * -apositiontaking * 0.5
				WHEN @modds =  0	THEN 0
				WHEN @modds = -0.25	THEN actual_stake * apositiontaking * 0.5
				WHEN @modds < -0.25	THEN actual_stake * apositiontaking
				END,
			mWinLost = CASE
				WHEN @modds >  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,1203) then odds-1 else odds end) end) * -mpositiontaking
				WHEN @modds =  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,1203) then odds-1 else odds end) end) * -mpositiontaking * 0.5
				WHEN @modds =  0    	THEN 0
				WHEN @modds = -0.25 	THEN actual_stake * mpositiontaking * 0.5
				WHEN @modds < -0.25 	THEN actual_stake * mpositiontaking
				END,
			sWinLost = CASE
				WHEN @modds >  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,1203) then odds-1 else odds end) end) * -spositiontaking
				WHEN @modds =  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,1203) then odds-1 else odds end) end) * -spositiontaking * 0.5
				WHEN @modds =  0    	THEN 0
				WHEN @modds = -0.25 	THEN actual_stake * spositiontaking * 0.5
				WHEN @modds < -0.25 	THEN actual_stake * spositiontaking
				END,

			PlayerComm = CASE
				WHEN @modds >  0.25 	THEN @commWinRate * playerdiscount * stake
				WHEN @modds =  0.25 	THEN @commWinRate * playerdiscount * stake * 0.5
				WHEN @modds =  0    	THEN 0
				WHEN @modds = -0.25 	THEN @commLostRate * playerdiscount * stake * 0.5
				WHEN @modds < -0.25 	THEN @commLostRate * playerdiscount * stake
				END,
			Comm = CASE
				WHEN @modds >  0.25 	THEN @commWinRate * discount * stake * (1-apositiontaking)
				WHEN @modds =  0.25 	THEN @commWinRate * discount * stake * (1-apositiontaking) * 0.5
				WHEN @modds =  0    	THEN 0
				WHEN @modds = -0.25 	THEN @commLostRate * discount * stake * (1-apositiontaking) * 0.5
				WHEN @modds < -0.25 	THEN @commLostRate * discount * stake * (1-apositiontaking)
				END,
			aComm = CASE
				WHEN @modds >  0.25 	THEN @commWinRate * adiscount * stake * (1-(mpositiontaking+apositiontaking))
				WHEN @modds =  0.25 	THEN @commWinRate * adiscount * stake * (1-(mpositiontaking+apositiontaking)) * 0.5
				WHEN @modds =  0    	THEN 0
				WHEN @modds = -0.25 	THEN @commLostRate * adiscount * stake * (1-(mpositiontaking+apositiontaking)) * 0.5
				WHEN @modds < -0.25 	THEN @commLostRate * adiscount * stake * (1-(mpositiontaking+apositiontaking))
				END,
			sComm = CASE
				WHEN @modds >  0.25 	THEN @commWinRate * sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking))
				WHEN @modds =  0.25 	THEN @commWinRate * sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking)) * 0.5
				WHEN @modds =  0    	THEN 0
				WHEN @modds = -0.25 	THEN @commLostRate * sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking)) * 0.5
				WHEN @modds < -0.25 	THEN @commLostRate * sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking))
				END,

			Status = CASE
				WHEN @modds > 0 THEN N'WON'
				WHEN @modds = 0 THEN N'DRAW'
				WHEN @modds < 0 THEN N'LOSE'
				END,
			StatusID = CASE
				WHEN @modds > 0 THEN 112 --WON
				WHEN @modds = 0 THEN 111 --DRAW
				WHEN @modds < 0 THEN 113 --LOSE
				END,
			ruben=1
			FROM dbo.bettrans b WITH (ROWLOCK, UPDLOCK)
				INNER JOIN @currecommend ag on b.recommend = ag.recommend
			WHERE
				matchid=@matchid AND
				bettype=@bettype AND
				--status NOT IN (N'VOID', N'REJECT')
				statusID NOT IN (101,102)

			if @affectedagents <> 100 
				break
		END
		DROP TABLE #tmpRecommend
	END
END
GO
GRANT VIEW DEFINITION ON [dbo].[Admin_Calculate_3_external] TO [vnteam] AS [dbo]