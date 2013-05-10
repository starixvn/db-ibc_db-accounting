
ALTER PROCEDURE [dbo].[Admin_Calculate_5_external]
	@matchid int,
	@bettype smallint,
	@whowin smallmoney,
	@betcount int = 0
AS
/*
	Created by:[]
	Date:[]
	Task: Settlement 
	DB: DBO2.BODB02
	
	Revisions:
	- 20100424@Henry: Update column StatusID of Bettrans (DRAW:111, WON: 112, LOSE: 113)
	- 20100521@Henry: Change to use StatusID instead of Status in WHERE statement
	- 20100625@Phuc: Force SQL engine using cluster index(CIX_recommend_matchid_bettype)(version on DB05/DB052). 
		Note: we deployed separated version for this sp one version on DB05/DB052(using CIX_recommend_matchid_bettype index)
		and original one for other DB. When edit this sp need to edit and re-deploy main version first then version on DB05/DB052.
	- 20110105@Lukas: Re-arrange bettype
	- 20120426@Lukas: Get from production & exclude DB044
	- 20120815@Dan: Add virtual soccer
	- 20121018@Johnson: Merge code for checking double comm losing from production
*/
	SET NOCOUNT ON
	Declare @modds smallmoney, @commWinRate smallmoney, @commLostRate smallmoney

	Declare @affectedagents int
	CREATE TABLE #tmpRecommend(recommend INT  PRIMARY KEY)
	INSERT INTO #tmpRecommend(recommend)
	SELECT DISTINCT recommend
	FROM dbo.bettrans (nolock) WHERE matchid = @matchid and bettype = @bettype
	
	DECLARE @currecommend TABLE(recommend int PRIMARY KEY)
	
	WHILE 1 = 1 
	BEGIN
		delete @currecommend
		delete top(100) from #tmpRecommend output DELETED.recommend into @currecommend
	
		Set @affectedagents = @@rowcount
	
		UPDATE b WITH(ROWLOCK, UPDLOCK)
		SET @modds = modds = CASE
			WHEN betteam = '1' AND @whowin > 0 THEN 1
			WHEN betteam = '2' AND @whowin < 0 THEN 1
			WHEN betteam = 'X' AND @whowin = 0 THEN 1
			ELSE -1
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
				WHEN @modds >  0.25	THEN actual_stake + stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,15,16,1205) then odds-1 else odds end) end)
				WHEN @modds =  0.25	THEN actual_stake + stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,15,16,1205) then odds-1 else odds end) end) * 0.5
				WHEN @modds =  0	THEN actual_stake
				WHEN @modds = -0.25	THEN actual_stake * 0.5
				WHEN @modds < -0.25	THEN 0
				END,

			aWinLost = CASE
				WHEN @modds >  0.25	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,15,16,1205) then odds-1 else odds end) end) * -apositiontaking
				WHEN @modds =  0.25	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,15,16,1205) then odds-1 else odds end) end) * -apositiontaking * 0.5
				WHEN @modds =  0	THEN 0
				WHEN @modds = -0.25	THEN actual_stake * apositiontaking * 0.5
				WHEN @modds < -0.25	THEN actual_stake * apositiontaking
				END,
			mWinLost = CASE
				WHEN @modds >  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,15,16,1205) then odds-1 else odds end) end) * -mpositiontaking
				WHEN @modds =  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,15,16,1205) then odds-1 else odds end) end) * -mpositiontaking * 0.5
				WHEN @modds =  0    	THEN 0
				WHEN @modds = -0.25 	THEN actual_stake * mpositiontaking * 0.5
				WHEN @modds < -0.25 	THEN actual_stake * mpositiontaking
				END,
			sWinLost = CASE
				WHEN @modds >  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,15,16,1205) then odds-1 else odds end) end) * -spositiontaking
				WHEN @modds =  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,15,16,1205) then odds-1 else odds end) end) * -spositiontaking * 0.5
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
		FROM bettrans b 
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
	GO 