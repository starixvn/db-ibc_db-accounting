ALTER PROCEDURE [NAP_Admin_Calculate_4] @matchid INT
	,@bettype SMALLINT
	,@correctscore NVARCHAR(10)
	,@goaldiff SMALLMONEY
	,@FGLG2 NVARCHAR(10) = NULL
	,@betcount INT = 0
AS
/*
	Created by:Kathy
	Date: 20140211
	Task: Settlement 
	DB: DBTRANS.BODB02
	
	Revisions:
		- 20140426@Kathy: Add 1H FGLG (127) [Redmine:#14449]
		- 20140610@Kathy: Using cluster index(CIX_recommend_matchid_bettype) in DB052, DB053, DB054		
*/
BEGIN
	--IF @betcount = 0 AND @@SERVERNAME NOT LIKE N'DBIOM%' RETURN
	IF @@SERVERNAME IN ('DB04', 'DB042', 'DB043', 'DB044') RETURN

	SET NOCOUNT ON

	DECLARE @modds SMALLMONEY
		,@commWinRate SMALLMONEY
		,@commLostRate SMALLMONEY
		,@matchdate DATETIME

	--- LAS settlement 
	IF @@SERVERNAME IN ('DB052', 'DB054', 'DB231', 'DB232') AND EXISTS (
			SELECT *
			FROM sys.databases
			WHERE NAME = 'LASDB'
			)
	BEGIN
		DECLARE @LASCommand NVARCHAR(1000)
			,@createdDate DATETIME

		SELECT @LASCommand = 'EXEC [dbo].[Admin_Calculate_4] @matchid = ' + CONVERT(NVARCHAR(10), @matchid) + ', @bettype = ' + CONVERT(NVARCHAR(10), @bettype) + ', @correctscore = ''' + @correctscore + '''' + ', @goaldiff = ' + CONVERT(NVARCHAR(10), @goaldiff) + ', @FGLG2 = ''' + ISNULL(@FGLG2, '') + '''' + ', @betcount = ' + CONVERT(NVARCHAR(10), ISNULL(@betcount, ''))
			,@createdDate = GETDATE()

		EXEC LASDB.[dbo].[Las_GeneratingSettlementCommand] @SPName = 'Admin_Calculate_4'
			,@SQLCommand = @LASCommand
			,@CreatedDate = @createdDate
			,@StatusID = 0 -- waiting
			,@MatchID = @matchid
			,@Bettype = @bettype
			,@Status = 'waiting'
			,@BetCount = @betcount
	END

	IF @@SERVERNAME IN ('DB052', 'DB053', 'DB054','DB231')
	BEGIN
		DECLARE @affectedagents INT

		CREATE TABLE #tmpRecommend(recommend INT  PRIMARY KEY)

		INSERT INTO #tmpRecommend(recommend)
		SELECT DISTINCT recommend
		FROM dbo.bettrans WITH(NOLOCK) WHERE matchid = @matchid and bettype = @bettype

		DECLARE @currecommend TABLE(recommend INT PRIMARY KEY)
		
		WHILE 1=1
		BEGIN
			DELETE
			FROM @currecommend

			DELETE TOP(100) FROM #tmpRecommend OUTPUT DELETED.recommend INTO @currecommend
			SET @affectedagents = @@rowcount

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

			IF @affectedagents <> 100 
				BREAK
		END
		DROP TABLE #tmpRecommend
	END
	ELSE
	BEGIN
		UPDATE bettrans WITH (ROWLOCK, UPDLOCK)
		SET @modds = modds = CASE 
				WHEN (betteam = @correctscore OR betteam = @FGLG2) THEN 1
				WHEN betteam = '4:0' AND @goaldiff >= 4 AND @bettype = 30 THEN 1 -- 4UP for 1st Correct Score
				WHEN betteam = '0:4' AND @goaldiff <= - 4 AND @bettype = 30 THEN 1 -- 4UP for 1st Correct Score
				WHEN betteam = '5:0' AND @goaldiff >= 5 THEN 1
				WHEN betteam = '0:5' AND @goaldiff <= - 5 THEN 1
				ELSE - 1
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
			,WinLost = CASE 
				WHEN @modds > 0.25 THEN actual_stake + stake * (CASE WHEN odds < 0 THEN 1 ELSE (CASE WHEN bettype IN (4, 5, 6, 14, 15, 16, 30, 127, 1204, 1235) THEN odds - 1 ELSE odds END	) END )
				WHEN @modds = 0.25 THEN actual_stake + stake * (CASE WHEN odds < 0 THEN 1 ELSE (CASE WHEN bettype IN (4, 5, 6, 14, 15, 16, 30, 127, 1204, 1235) THEN odds - 1 ELSE odds END	) END ) * 0.5
				WHEN @modds = 0 THEN actual_stake WHEN @modds = - 0.25 THEN actual_stake * 0.5
				WHEN @modds < - 0.25 THEN 0
				END
			,aWinLost = CASE 
				WHEN @modds > 0.25 THEN stake * (CASE WHEN odds < 0 THEN 1 ELSE (CASE WHEN bettype IN (4, 5, 6, 14, 15, 16, 30, 127, 1204, 1235) THEN odds - 1 ELSE odds END ) END ) * - apositiontaking
				WHEN @modds = 0.25 THEN stake * (CASE WHEN odds < 0 THEN 1 ELSE (CASE WHEN bettype IN (4, 5, 6, 14, 15, 16, 30, 127, 1204, 1235) THEN odds - 1 ELSE odds END ) END ) * - apositiontaking * 0.5
				WHEN @modds = 0 THEN 0
				WHEN @modds = - 0.25 THEN actual_stake * apositiontaking * 0.5
				WHEN @modds < - 0.25 THEN actual_stake * apositiontaking
				END
			,mWinLost = CASE 
				WHEN @modds > 0.25 THEN stake * (CASE WHEN odds < 0 THEN 1 ELSE (CASE WHEN bettype IN (4, 5, 6, 14, 15, 16, 30,127, 1204, 1235) THEN odds - 1 ELSE odds END ) END ) * - mpositiontaking
				WHEN @modds = 0.25 THEN stake * (CASE WHEN odds < 0 THEN 1 ELSE (CASE WHEN bettype IN (4, 5, 6, 14, 15, 16, 30, 127, 1204, 1235) THEN odds - 1 ELSE odds END ) END ) * - mpositiontaking * 0.5
				WHEN @modds = 0 THEN 0
				WHEN @modds = - 0.25 THEN actual_stake * mpositiontaking * 0.5
				WHEN @modds < - 0.25 THEN actual_stake * mpositiontaking
				END
			,sWinLost = CASE 
				WHEN @modds > 0.25 THEN stake * (CASE WHEN odds < 0 THEN 1 ELSE (CASE WHEN bettype IN (4, 5, 6, 14, 15, 16, 30, 127, 1204, 1235) THEN odds - 1 ELSE odds END ) END ) * - spositiontaking
				WHEN @modds = 0.25 THEN stake * (CASE WHEN odds < 0 THEN 1 ELSE (CASE WHEN bettype IN (4, 5, 6, 14, 15, 16, 30, 127, 1204, 1235) THEN odds - 1 ELSE odds END ) END ) * - spositiontaking * 0.5
				WHEN @modds = 0 THEN 0
				WHEN @modds = - 0.25 THEN actual_stake * spositiontaking * 0.5
				WHEN @modds < - 0.25 THEN actual_stake * spositiontaking
				END
			,PlayerComm = CASE 
				WHEN @modds > 0.25 THEN @commWinRate * playerdiscount * stake
				WHEN @modds = 0.25 THEN @commWinRate * playerdiscount * stake * 0.5
				WHEN @modds = 0 THEN 0
				WHEN @modds = - 0.25 THEN @commLostRate * playerdiscount * stake * 0.5
				WHEN @modds < - 0.25 THEN @commLostRate * playerdiscount * stake
				END
			,Comm = CASE 
				WHEN @modds > 0.25 THEN @commWinRate * discount * stake * (1 - apositiontaking)
				WHEN @modds = 0.25 THEN @commWinRate * discount * stake * (1 - apositiontaking) * 0.5
				WHEN @modds = 0 THEN 0
				WHEN @modds = - 0.25 THEN @commLostRate * discount * stake * (1 - apositiontaking) * 0.5
				WHEN @modds < - 0.25 THEN @commLostRate * discount * stake * (1 - apositiontaking)
				END
			,aComm = CASE 
				WHEN @modds > 0.25 THEN @commWinRate * adiscount * stake * (1 - (mpositiontaking + apositiontaking))
				WHEN @modds = 0.25 THEN @commWinRate * adiscount * stake * (1 - (mpositiontaking + apositiontaking)) * 0.5
				WHEN @modds = 0 THEN 0
				WHEN @modds = - 0.25 THEN @commLostRate * adiscount * stake * (1 - (mpositiontaking + apositiontaking)) * 0.5
				WHEN @modds < - 0.25 THEN @commLostRate * adiscount * stake * (1 - (mpositiontaking + apositiontaking))
				END
			,sComm = CASE 
				WHEN @modds > 0.25 THEN @commWinRate * sdiscount * stake * (1 - (spositiontaking + mpositiontaking + apositiontaking))
				WHEN @modds = 0.25 THEN @commWinRate * sdiscount * stake * (1 - (spositiontaking + mpositiontaking + apositiontaking)) * 0.5
				WHEN @modds = 0 THEN 0
				WHEN @modds = - 0.25 THEN @commLostRate * sdiscount * stake * (1 - (spositiontaking + mpositiontaking + apositiontaking)) * 0.5
				WHEN @modds < - 0.25 THEN @commLostRate * sdiscount * stake * (1 - (spositiontaking + mpositiontaking + apositiontaking))
				END
			,STATUS = CASE 
				WHEN @modds > 0 THEN 'WON'
				WHEN @modds = 0 THEN 'DRAW'
				WHEN @modds < 0 THEN 'LOSE'
				END
			,StatusID = CASE 
				WHEN @modds > 0 THEN 112 --WON
				WHEN @modds = 0 THEN 111 --DRAW
				WHEN @modds < 0 THEN 113 --LOSE
				END
			,ruben = 1
		WHERE matchid = @matchid AND bettype = @bettype AND
			--status NOT IN ('VOID', 'REJECT')
			statusID NOT IN (101, 102)
	END

	IF @FGLG2 IS NULL OR @FGLG2 = ''
		SET @FGLG2 = @correctscore

	-------------Start:Settle FGLG for bettransm-------------
	IF @bettype in(14, 127)
	BEGIN
		SELECT @matchdate = eventdate
		FROM match WITH (NOLOCK)
		WHERE matchid = @matchid

		UPDATE dbo.bettransm WITH (UPDLOCK)
		SET @modds = CASE 
				WHEN (betteam = @correctscore OR betteam = @FGLG2) THEN 1
				ELSE - 1
				END
			,ruben = CASE 
				WHEN @modds IS NULL THEN 0
				ELSE 1
				END
			,winlostdate = @matchdate
			,[status] = CASE 
				WHEN @modds < 0 THEN N'LOSE'
				WHEN @modds > 0 THEN N'WON'
				END
			,statusID = CASE 
				WHEN @modds < 0 THEN 113 --LOSE
				WHEN @modds > 0 THEN 112 --WON
				END
			,statuswinlost = CASE 
				WHEN @modds <= - 0.5 THEN 4 -- LOSE
				WHEN @modds >= 0.5 THEN 2 -- WIN
				END
		-- ========================
		FROM dbo.bettransm WITH (INDEX = IX_matchid)
		WHERE bettype = @bettype AND matchid = @matchid AND statusID NOT IN (101, 102) --VOID, REJECT

		UPDATE dbo.betParlayDetail WITH (ROWLOCK, UPDLOCK)
		SET @modds = CASE 
				WHEN (betteam = @correctscore OR betteam = @FGLG2) THEN 1
				ELSE - 1
				END
			,winlostdate = @matchdate
			,statusID = CASE 
				WHEN @modds < 0 THEN 113 --LOSE
				WHEN @modds > 0 THEN 112 --WON
				END
			,statuswinlost = CASE 
				WHEN @modds <= - 0.5 THEN 4 -- LOSE
				WHEN @modds >= 0.5 THEN 2 -- WIN
				END
		WHERE bettype = @bettype AND matchid = @matchid AND statusID NOT IN (101, 102) --VOID, REJECT
			-------------Stop:Settle FGLG for bettransm-------------
	END
END


GO

GRANT VIEW DEFINITION ON [NAP_Admin_Calculate_4] TO [vnteam] AS [dbo]
GO


