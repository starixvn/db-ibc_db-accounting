ALTER PROCEDURE [Admin_Calculate_4_external]
	@matchid int,
	@bettype smallint,
	@correctscore nvarchar(10),
	@goaldiff smallmoney,
	@FGLG2 nvarchar(10) = NULL,
	@betcount int = 0
AS

/*
	Created by:[]
	Date:[]
	Task: Settlement 
	DB: DB053.BODB02
	
	Revisions:
		- 20090113: Include the Settle FGLG for bettransm
		- 20100517@Henry: Update column StatusID of Bettrans (DRAW:111, WON: 112, LOSE: 113) + Bettransm (WON: 112, LOSE: 113)
		- 20100521@Henry: Change to use StatusID instead of Status in WHERE statement
		- 20100625@Phuc: Force SQL engine using cluster index(CIX_recommend_matchid_bettype)(version on DB05/DB052). 
			Note: we deployed separated version for this sp one version on DB05/DB052(using CIX_recommend_matchid_bettype index)
			and original one for other DB. When edit this sp need to edit and re-deploy main version first then version on DB05/DB052.
		- 20110105@Lukas: Re-arrange bettype
		- 20110923@Tom: Add new bettypes 30
				apply new bet type 1st correct score on Sport Books	
		- 20111003@Joe: rounding winlost/commission to 2 decimal places
		- 20111019@Jamie: Exclude VOID/REJECT tickets for FG/LG in bettransm 
		- 20120426@Lukas: Get from production & exclude DB044
		- 20120801@Dan: add 4UP for 1st correct score
		- 20120815@Dan: Add virtual soccer
		- 20121017@Lukas: correct bettypeid 1204 for virtual sports
		- 20121019@Johnson: Check double comm losing status
		- 20121126@Dan: Add bettype 1235 for Virtual Tennis
		- 20140421@Kathy: Add 1H FGLG bettypes (127) [Redmine:#14718]
*/


SET NOCOUNT ON
Declare @modds smallmoney, @commWinRate smallmoney, @commLostRate smallmoney, @matchdate datetime


	
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
		SET @modds = modds = CASE
			WHEN (betteam = @correctscore OR betteam = @FGLG2) THEN 1
			WHEN betteam = '4:0' AND @goaldiff >=  4 and @bettype=30 THEN 1 -- 4UP for 1st Correct Score
			WHEN betteam = '0:4' AND @goaldiff <=  -4 and @bettype=30 THEN 1 -- 4UP for 1st Correct Score
			WHEN betteam = '5:0' AND @goaldiff >=  5 THEN 1
			WHEN betteam = '0:5' AND @goaldiff <= -5 THEN 1
			ELSE -1
			END,
			
		@commWinRate = CASE comstatus -- 0 : pay normal, both win/lost -- 1 : pay 'double' ONLY on lost
			WHEN '0' THEN 1
			WHEN '1' THEN 0 
			ELSE 1 END,
		@commLostRate = CASE comstatus
			WHEN '0' THEN 1
			WHEN '1' THEN 2 
			ELSE 1 END,--'s','m'
			
		WinLost = CASE
			WHEN @modds >  0.25	THEN actual_stake + stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,14,15,16,30,127,1204,1235) then odds-1 else odds end) end)
			WHEN @modds =  0.25	THEN actual_stake + stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,14,15,16,30,127,1204,1235) then odds-1 else odds end) end) * 0.5
			WHEN @modds =  0	THEN actual_stake
			WHEN @modds = -0.25	THEN actual_stake * 0.5
			WHEN @modds < -0.25	THEN 0
			END,

		aWinLost = CASE
			WHEN @modds >  0.25	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,14,15,16,30,127,1204,1235) then odds-1 else odds end) end) * -apositiontaking
			WHEN @modds =  0.25	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,14,15,16,30,127,1204,1235) then odds-1 else odds end) end) * -apositiontaking * 0.5
			WHEN @modds =  0	THEN 0
			WHEN @modds = -0.25	THEN actual_stake * apositiontaking * 0.5
			WHEN @modds < -0.25	THEN actual_stake * apositiontaking
			END,
		mWinLost = CASE
			WHEN @modds >  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,14,15,16,30,127,1204,1235) then odds-1 else odds end) end) * -mpositiontaking
			WHEN @modds =  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,14,15,16,30,127,1204,1235) then odds-1 else odds end) end) * -mpositiontaking * 0.5
			WHEN @modds =  0    	THEN 0
			WHEN @modds = -0.25 	THEN actual_stake * mpositiontaking * 0.5
			WHEN @modds < -0.25 	THEN actual_stake * mpositiontaking
			END,
		sWinLost = CASE
			WHEN @modds >  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,14,15,16,30,127,1204,1235) then odds-1 else odds end) end) * -spositiontaking
			WHEN @modds =  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,14,15,16,30,127,1204,1235) then odds-1 else odds end) end) * -spositiontaking * 0.5
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
			WHEN @modds > 0 THEN 'WON'
			WHEN @modds = 0 THEN 'DRAW'
			WHEN @modds < 0 THEN 'LOSE'
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
			--status NOT IN ('VOID', 'REJECT')
			statusID NOT IN (101,102)

		if @affectedagents <> 100 
			break
	END
	DROP TABLE #tmpRecommend
	


	IF @FGLG2 IS NULL OR @FGLG2 = ''
		SET @FGLG2 = @correctscore

	-------------Start:Settle FGLG for bettransm-------------
	if @bettype in( 14, 127)
	BEGIN
		select @matchdate=eventdate from match with (NOLOCK) where matchid=@matchid

		UPDATE dbo.bettransm with (updlock)
		SET
			@modds =
				case 
					WHEN (betteam = @correctscore OR betteam = @FGLG2) THEN 1					
					ELSE -1
				END,
			ruben = CASE WHEN @modds IS NULL THEN 0 ELSE 1 END,
			winlostdate=@matchdate,
			[status]=
				case
					when @modds<0 then N'LOSE'
					when @modds>0 then N'WON'
				end ,
			statusID = 
				case
					when @modds<0 then 113 --LOSE
					when @modds>0 then 112 --WON
				end ,
			statuswinlost=
				case
					when @modds<=-0.5 then 4 -- LOSE
					when @modds>= 0.5 then 2 -- WIN
				end
		-- ========================
		FROM dbo.bettransm with (INDEX=IX_matchid)
		WHERE	bettype = @bettype 
				AND matchid = @matchid
				AND statusID NOT IN (101,102) --VOID, REJECT
				
		UPDATE dbo.betParlayDetail WITH(ROWLOCK,UPDLOCK)
		SET
			@modds =
				case 
					WHEN (betteam = @correctscore OR betteam = @FGLG2) THEN 1					
					ELSE -1
				END,
			winlostdate=@matchdate,
			statusID = 
				case
					when @modds<0 then 113 --LOSE
					when @modds>0 then 112 --WON
				end ,
			statuswinlost=
				case
					when @modds<=-0.5 then 4 -- LOSE
					when @modds>= 0.5 then 2 -- WIN
				end
		WHERE	bettype = @bettype 
				AND matchid = @matchid
				AND statusID NOT IN (101,102) --VOID, REJECT
				
	END 
	-------------Stop:Settle FGLG for bettransm-------------




GO
GRANT VIEW DEFINITION ON [dbo].[Admin_Calculate_4_external] TO [vnteam] 