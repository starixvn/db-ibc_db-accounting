ALTER PROCEDURE [dbo].[NAP_Admin_Calculate_4] @matchid INT
	,@bettype						SMALLINT
	,@correctscore					NVARCHAR(10) = NULL
	,@goaldiff						SMALLMONEY	 = NULL 
	,@FGLG2							NVARCHAR(10) = NULL
	,@hth							INT = 0
	,@hta							INT = 0
	,@fth							INT = 0
	,@fta							INT = 0
	,@SelectedSet					VARCHAR(50) = NULL
	,@CorrectScoreSet1				NVARCHAR(10)= NULL 
	,@CorrectScoreSet2				NVARCHAR(10)= NULL 
	,@CorrectScoreSet3				NVARCHAR(10)= NULL 
	,@CorrectScoreSet4				NVARCHAR(10)= NULL 
	,@CorrectScoreSet5				NVARCHAR(10)= NULL 
	,@betcount						INT = 0
	,@IsSettleAbandonedMatch		BIT = 0
	,@IsSettleAbandonedMatchIBC		BIT = 0
	,@IsSettleAbandonedMatchBetFair BIT = 0
	
AS
/*
	Created by:Kathy
	Date: 20140211
	Task: Settlement 
	DB: DBTRANS.BODB02
	
	Revisions:
		- 20140426@Kathy: Add 1H FGLG (127) [Redmine:#14449]
		- 20140610@Kathy: Using clustered index(CIX_recommend_matchid_bettype) in DB052, DB053, DB054	
		- 20140725@Kathy: Settle determined tickets for Correct Score(4,30)[Redmine:#19310]
		- 20140822@Jamie: Check @correctscore and @goaldiff NULL 
		- 20141017@Jamie: Sporting Solution for Tennis [Redmine:#23034]

	Param's Explanation:
		
		
*/
BEGIN
	SET NOCOUNT ON

	--IF @betcount = 0 AND @@SERVERNAME NOT LIKE N'DBIOM%' RETURN

	IF @@SERVERNAME IN ('DB04', 'DB042', 'DB043', 'DB044') RETURN	

	DECLARE @modds SMALLMONEY
		,@commWinRate SMALLMONEY
		,@commLostRate SMALLMONEY
		,@matchdate DATETIME

	--- LAS settlement 
	IF @@SERVERNAME IN ('DB052', 'DB054', 'DB231', 'DB232','DB215') AND EXISTS (
			SELECT *
			FROM sys.databases
			WHERE NAME = 'LASDB'
			)
	BEGIN
		IF (@IsSettleAbandonedMatch = 0 AND @IsSettleAbandonedMatchBetFair = 0 ) or @IsSettleAbandonedMatchIBC = 1
			BEGIN
				DECLARE @LASCommand NVARCHAR(1000)
					,@createdDate DATETIME

				SELECT @LASCommand = 'EXEC [dbo].[Admin_Calculate_4] @matchid = ' + CONVERT(NVARCHAR(10), @matchid) 
																+ ', @bettype = ' + CONVERT(NVARCHAR(10), @bettype) 
																+ ', @correctscore = ' + CASE WHEN @correctscore IS NULL THEN 'NULL' ELSE '''' + CONVERT(NVARCHAR(50), @correctscore) + '''' END
																+ ', @goaldiff = ' + CASE WHEN @goaldiff IS NULL THEN 'NULL' ELSE CONVERT(NVARCHAR(10), @goaldiff) END
																+ ', @FGLG2 = ''' + ISNULL(@FGLG2, '') + '''' 
																+ ', @hth = ' + CONVERT(NVARCHAR(10), @hth) 
																+ ', @hta = ' + CONVERT(NVARCHAR(10), @hta) 
																+ ', @fth = ' + CONVERT(NVARCHAR(10), @fth) 
																+ ', @fta = ' + CONVERT(NVARCHAR(10), @fta) 
																+ ', @IsSettleAbandonedMatchIBC = ' + CONVERT(NVARCHAR(10), @IsSettleAbandonedMatchIBC)
																+ ', @betcount = ' + CONVERT(NVARCHAR(10), ISNULL(@betcount, ''))
																
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
	END

	IF @@SERVERNAME IN ('DB052', 'DB053', 'DB054','DB231','DB215')
	BEGIN
		DECLARE @affectedagents INT

		CREATE TABLE #tmpRecommend(recommend INT  PRIMARY KEY)

		INSERT INTO #tmpRecommend(recommend)
		SELECT DISTINCT recommend
		FROM dbo.bettrans WITH(NOLOCK) WHERE matchid = @matchid and bettype = @bettype

		DECLARE @currecommend TABLE(recommend INT PRIMARY KEY)
		
		IF @IsSettleAbandonedMatchIBC = 1 OR @IsSettleAbandonedMatch = 1 OR @IsSettleAbandonedMatchBetFair = 1
		BEGIN
			WHILE 1=1
			BEGIN
				DELETE
				FROM @currecommend

				DELETE TOP(100) FROM #tmpRecommend OUTPUT DELETED.recommend INTO @currecommend
				SET @affectedagents = @@rowcount

				UPDATE b
				SET @modds = modds = CASE
					WHEN b.betteam NOT IN ('0:4', '4:0') AND @bettype = 30 AND (@hth > LEFT(b.betteam,1) OR @hta > RIGHT(b.betteam,1) ) THEN -1			
					WHEN b.betteam NOT IN ('0:5', '5:0') AND @bettype = 4 AND (@fth > LEFT(b.betteam,1) OR @fta > RIGHT(b.betteam,1) ) THEN -1			
					ELSE NULL
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
					WHEN @modds >  0.25	THEN actual_stake + stake * (case when odds<0 then 1 else (case when bettype in (4,30,1302) then odds-1 else odds end) end)
					WHEN @modds =  0.25	THEN actual_stake + stake * (case when odds<0 then 1 else (case when bettype in (4,30,1302) then odds-1 else odds end) end) * 0.5
					WHEN @modds =  0	THEN actual_stake
					WHEN @modds = -0.25	THEN actual_stake * 0.5
					WHEN @modds < -0.25	THEN 0
					WHEN @modds IS NULL then winlost
					END,

				aWinLost = CASE
					WHEN @modds >  0.25	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,30,1302) then odds-1 else odds end) end) * -apositiontaking
					WHEN @modds =  0.25	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,30,1302) then odds-1 else odds end) end) * -apositiontaking * 0.5
					WHEN @modds =  0	THEN 0
					WHEN @modds = -0.25	THEN actual_stake * apositiontaking * 0.5
					WHEN @modds < -0.25	THEN actual_stake * apositiontaking
					WHEN @modds IS NULL then aWinLost
					END,
				mWinLost = CASE
					WHEN @modds >  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,30,1302) then odds-1 else odds end) end) * -mpositiontaking
					WHEN @modds =  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,30,1302) then odds-1 else odds end) end) * -mpositiontaking * 0.5
					WHEN @modds =  0    	THEN 0
					WHEN @modds = -0.25 	THEN actual_stake * mpositiontaking * 0.5
					WHEN @modds < -0.25 	THEN actual_stake * mpositiontaking
					WHEN @modds IS NULL then mWinLost
					END,
				sWinLost = CASE
					WHEN @modds >  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,30,1302) then odds-1 else odds end) end) * -spositiontaking
					WHEN @modds =  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,30,1302) then odds-1 else odds end) end) * -spositiontaking * 0.5
					WHEN @modds =  0    	THEN 0
					WHEN @modds = -0.25 	THEN actual_stake * spositiontaking * 0.5
					WHEN @modds < -0.25 	THEN actual_stake * spositiontaking
					WHEN @modds IS NULL then sWinLost
					END,

				PlayerComm = CASE
					WHEN @modds >  0.25 	THEN @commWinRate * playerdiscount * stake
					WHEN @modds =  0.25 	THEN @commWinRate * playerdiscount * stake * 0.5
					WHEN @modds =  0    	THEN 0
					WHEN @modds = -0.25 	THEN @commLostRate * playerdiscount * stake * 0.5
					WHEN @modds < -0.25 	THEN @commLostRate * playerdiscount * stake
					WHEN @modds IS NULL then PlayerComm
					END,
				Comm = CASE
					WHEN @modds >  0.25 	THEN @commWinRate * discount * stake * (1-apositiontaking)
					WHEN @modds =  0.25 	THEN @commWinRate * discount * stake * (1-apositiontaking) * 0.5
					WHEN @modds =  0    	THEN 0
					WHEN @modds = -0.25 	THEN @commLostRate * discount * stake * (1-apositiontaking) * 0.5
					WHEN @modds < -0.25 	THEN @commLostRate * discount * stake * (1-apositiontaking)
					WHEN @modds IS NULL then Comm
					END,
				aComm = CASE
					WHEN @modds >  0.25 	THEN @commWinRate * adiscount * stake * (1-(mpositiontaking+apositiontaking))
					WHEN @modds =  0.25 	THEN @commWinRate * adiscount * stake * (1-(mpositiontaking+apositiontaking)) * 0.5
					WHEN @modds =  0    	THEN 0
					WHEN @modds = -0.25 	THEN @commLostRate * adiscount * stake * (1-(mpositiontaking+apositiontaking)) * 0.5
					WHEN @modds < -0.25 	THEN @commLostRate * adiscount * stake * (1-(mpositiontaking+apositiontaking))
					WHEN @modds IS NULL then aComm
					END,
				sComm = CASE
					WHEN @modds >  0.25 	THEN @commWinRate * sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking))
					WHEN @modds =  0.25 	THEN @commWinRate * sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking)) * 0.5
					WHEN @modds =  0    	THEN 0
					WHEN @modds = -0.25 	THEN @commLostRate * sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking)) * 0.5
					WHEN @modds < -0.25 	THEN @commLostRate * sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking))
					WHEN @modds IS NULL then sComm
					END,

				Status = CASE
					WHEN @modds > 0 THEN 'WON'
					WHEN @modds = 0 THEN 'DRAW'
					WHEN @modds < 0 THEN 'LOSE'
					WHEN @modds IS NULL then Status
					END,
				StatusID = CASE
					WHEN @modds > 0 THEN 112 --WON
					WHEN @modds = 0 THEN 111 --DRAW
					WHEN @modds < 0 THEN 113 --LOSE
					WHEN @modds IS NULL then StatusID
					END,
				ruben= CASE when @modds IS NULL THEN ruben
							ELSE 1
					   END
				FROM dbo.bettrans b WITH (ROWLOCK, UPDLOCK)
					INNER JOIN @currecommend ag on b.recommend = ag.recommend
				WHERE
					matchid=@matchid AND
					bettype=@bettype AND
					statusID NOT IN (101,102)
					AND 1 = CASE 
								WHEN @IsSettleAbandonedMatch = 1 AND (custid IN (50057, 879241, 103873, 78761, 851668, 878902) OR b.recommend = 1688156) THEN 1
								WHEN @IsSettleAbandonedMatchBetFair = 1 AND custid IN (2331, 1077687, 115770, 15523642) THEN 1
								WHEN @IsSettleAbandonedMatchIBC = 1 AND (custid NOT IN (50057, 879241, 103873, 78761, 851668, 878902, 2331, 1077687, 115770, 15523642) AND b.recommend <> 1688156) THEN 1
								ELSE 0
							END
				IF @affectedagents <> 100 
					BREAK
			END
		END
		ELSE
		BEGIN
			WHILE 1=1
			BEGIN
				DELETE
				FROM @currecommend

				DELETE TOP(100) FROM #tmpRecommend OUTPUT DELETED.recommend INTO @currecommend
				SET @affectedagents = @@rowcount

				UPDATE b
				SET 
				
				@correctscore	= CASE  WHEN bettype = 1317 AND @SelectedSet LIKE '%1%' AND BetID = 801 THEN @CorrectScoreSet1
										WHEN bettype = 1317 AND @SelectedSet LIKE '%2%' AND BetID = 802 THEN @CorrectScoreSet2
										WHEN bettype = 1317 AND @SelectedSet LIKE '%3%' AND BetID = 803 THEN @CorrectScoreSet3
										WHEN bettype = 1317 AND @SelectedSet LIKE '%4%' AND BetID = 804 THEN @CorrectScoreSet4
										WHEN bettype = 1317 AND @SelectedSet LIKE '%5%' AND BetID = 805 THEN @CorrectScoreSet5
										ELSE @correctscore END 					
				,@modds = modds = CASE
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
					WHEN @modds >  0.25	THEN actual_stake + stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,14,15,16,30,127,1204,1235,1302,1317) then odds-1 else odds end) end)
					WHEN @modds =  0.25	THEN actual_stake + stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,14,15,16,30,127,1204,1235,1302,1317) then odds-1 else odds end) end) * 0.5
					WHEN @modds =  0	THEN actual_stake
					WHEN @modds = -0.25	THEN actual_stake * 0.5
					WHEN @modds < -0.25	THEN 0
					END,

				aWinLost = CASE
					WHEN @modds >  0.25	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,14,15,16,30,127,1204,1235,1302,1317) then odds-1 else odds end) end) * -apositiontaking
					WHEN @modds =  0.25	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,14,15,16,30,127,1204,1235,1302,1317) then odds-1 else odds end) end) * -apositiontaking * 0.5
					WHEN @modds =  0	THEN 0
					WHEN @modds = -0.25	THEN actual_stake * apositiontaking * 0.5
					WHEN @modds < -0.25	THEN actual_stake * apositiontaking
					END,
				mWinLost = CASE
					WHEN @modds >  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,14,15,16,30,127,1204,1235,1302,1317) then odds-1 else odds end) end) * -mpositiontaking
					WHEN @modds =  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,14,15,16,30,127,1204,1235,1302,1317) then odds-1 else odds end) end) * -mpositiontaking * 0.5
					WHEN @modds =  0    	THEN 0
					WHEN @modds = -0.25 	THEN actual_stake * mpositiontaking * 0.5
					WHEN @modds < -0.25 	THEN actual_stake * mpositiontaking
					END,
				sWinLost = CASE
					WHEN @modds >  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,14,15,16,30,127,1204,1235,1302,1317) then odds-1 else odds end) end) * -spositiontaking
					WHEN @modds =  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,14,15,16,30,127,1204,1235,1302,1317) then odds-1 else odds end) end) * -spositiontaking * 0.5
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
					bettype=@bettype 
					AND statusID NOT IN (101,102)
					AND 1 = CASE WHEN @bettype <> 1317  THEN 1 
								 WHEN @bettype = 1317 AND @SelectedSet LIKE '%1%' AND BetID = 801 THEN 1
								 WHEN @bettype = 1317 AND @SelectedSet LIKE '%2%' AND BetID = 802 THEN 1
								 WHEN @bettype = 1317 AND @SelectedSet LIKE '%3%' AND BetID = 803 THEN 1
								 WHEN @bettype = 1317 AND @SelectedSet LIKE '%4%' AND BetID = 804 THEN 1
								 WHEN @bettype = 1317 AND @SelectedSet LIKE '%5%' AND BetID = 805 THEN 1
								 ELSE 0 END 

				IF @affectedagents <> 100 
					BREAK
			END
		END
		DROP TABLE #tmpRecommend
	END
	ELSE -- DBTrans
	BEGIN
		IF @IsSettleAbandonedMatchIBC = 1 OR @IsSettleAbandonedMatch = 1 OR @IsSettleAbandonedMatchBetFair = 1
		BEGIN
			UPDATE bettrans WITH (ROWLOCK, UPDLOCK)
			SET @modds = modds = CASE 
					WHEN betteam NOT IN ('0:4', '4:0') AND @bettype = 30 AND (@hth > LEFT(betteam,1) OR @hta > RIGHT(betteam,1) ) THEN -1			
					WHEN betteam NOT IN ('0:5', '5:0') AND @bettype = 4 AND (@fth > LEFT(betteam,1) OR @fta > RIGHT(betteam,1) ) THEN -1			
					ELSE NULL 
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
					WHEN @modds > 0.25 THEN actual_stake + stake * (CASE WHEN odds < 0 THEN 1 ELSE (CASE WHEN bettype IN (4, 5, 6, 14, 15, 16, 30, 127, 1204, 1235,1302,1317) THEN odds - 1 ELSE odds END	) END )
					WHEN @modds = 0.25 THEN actual_stake + stake * (CASE WHEN odds < 0 THEN 1 ELSE (CASE WHEN bettype IN (4, 5, 6, 14, 15, 16, 30, 127, 1204, 1235,1302,1317) THEN odds - 1 ELSE odds END	) END ) * 0.5
					WHEN @modds = 0 THEN actual_stake WHEN @modds = - 0.25 THEN actual_stake * 0.5
					WHEN @modds < - 0.25 THEN 0
					WHEN @modds IS NULL THEN winlost
					END
				,aWinLost = CASE 
					WHEN @modds > 0.25 THEN stake * (CASE WHEN odds < 0 THEN 1 ELSE (CASE WHEN bettype IN (4, 5, 6, 14, 15, 16, 30, 127, 1204, 1235,1302,1317) THEN odds - 1 ELSE odds END ) END ) * - apositiontaking
					WHEN @modds = 0.25 THEN stake * (CASE WHEN odds < 0 THEN 1 ELSE (CASE WHEN bettype IN (4, 5, 6, 14, 15, 16, 30, 127, 1204, 1235,1302,1317) THEN odds - 1 ELSE odds END ) END ) * - apositiontaking * 0.5
					WHEN @modds = 0 THEN 0
					WHEN @modds = - 0.25 THEN actual_stake * apositiontaking * 0.5
					WHEN @modds < - 0.25 THEN actual_stake * apositiontaking
					WHEN @modds IS NULL THEN awinlost
					END
				,mWinLost = CASE 
					WHEN @modds > 0.25 THEN stake * (CASE WHEN odds < 0 THEN 1 ELSE (CASE WHEN bettype IN (4, 5, 6, 14, 15, 16, 30,127, 1204, 1235,1302,1317) THEN odds - 1 ELSE odds END ) END ) * - mpositiontaking
					WHEN @modds = 0.25 THEN stake * (CASE WHEN odds < 0 THEN 1 ELSE (CASE WHEN bettype IN (4, 5, 6, 14, 15, 16, 30, 127, 1204, 1235,1302,1317) THEN odds - 1 ELSE odds END ) END ) * - mpositiontaking * 0.5
					WHEN @modds = 0 THEN 0
					WHEN @modds = - 0.25 THEN actual_stake * mpositiontaking * 0.5
					WHEN @modds < - 0.25 THEN actual_stake * mpositiontaking
					WHEN @modds IS NULL THEN mwinlost
					END
				,sWinLost = CASE 
					WHEN @modds > 0.25 THEN stake * (CASE WHEN odds < 0 THEN 1 ELSE (CASE WHEN bettype IN (4, 5, 6, 14, 15, 16, 30, 127, 1204, 1235,1302,1317) THEN odds - 1 ELSE odds END ) END ) * - spositiontaking
					WHEN @modds = 0.25 THEN stake * (CASE WHEN odds < 0 THEN 1 ELSE (CASE WHEN bettype IN (4, 5, 6, 14, 15, 16, 30, 127, 1204, 1235,1302,1317) THEN odds - 1 ELSE odds END ) END ) * - spositiontaking * 0.5
					WHEN @modds = 0 THEN 0
					WHEN @modds = - 0.25 THEN actual_stake * spositiontaking * 0.5
					WHEN @modds < - 0.25 THEN actual_stake * spositiontaking
					WHEN @modds IS NULL THEN swinlost
					END
				,PlayerComm = CASE 
					WHEN @modds > 0.25 THEN @commWinRate * playerdiscount * stake
					WHEN @modds = 0.25 THEN @commWinRate * playerdiscount * stake * 0.5
					WHEN @modds = 0 THEN 0
					WHEN @modds = - 0.25 THEN @commLostRate * playerdiscount * stake * 0.5
					WHEN @modds < - 0.25 THEN @commLostRate * playerdiscount * stake
					WHEN @modds IS NULL THEN playercomm
					END
				,Comm = CASE 
					WHEN @modds > 0.25 THEN @commWinRate * discount * stake * (1 - apositiontaking)
					WHEN @modds = 0.25 THEN @commWinRate * discount * stake * (1 - apositiontaking) * 0.5
					WHEN @modds = 0 THEN 0
					WHEN @modds = - 0.25 THEN @commLostRate * discount * stake * (1 - apositiontaking) * 0.5
					WHEN @modds < - 0.25 THEN @commLostRate * discount * stake * (1 - apositiontaking)
					WHEN @modds IS NULL THEN comm
					END
				,aComm = CASE 
					WHEN @modds > 0.25 THEN @commWinRate * adiscount * stake * (1 - (mpositiontaking + apositiontaking))
					WHEN @modds = 0.25 THEN @commWinRate * adiscount * stake * (1 - (mpositiontaking + apositiontaking)) * 0.5
					WHEN @modds = 0 THEN 0
					WHEN @modds = - 0.25 THEN @commLostRate * adiscount * stake * (1 - (mpositiontaking + apositiontaking)) * 0.5
					WHEN @modds < - 0.25 THEN @commLostRate * adiscount * stake * (1 - (mpositiontaking + apositiontaking))
					WHEN @modds IS NULL THEN acomm
					END
				,sComm = CASE 
					WHEN @modds > 0.25 THEN @commWinRate * sdiscount * stake * (1 - (spositiontaking + mpositiontaking + apositiontaking))
					WHEN @modds = 0.25 THEN @commWinRate * sdiscount * stake * (1 - (spositiontaking + mpositiontaking + apositiontaking)) * 0.5
					WHEN @modds = 0 THEN 0
					WHEN @modds = - 0.25 THEN @commLostRate * sdiscount * stake * (1 - (spositiontaking + mpositiontaking + apositiontaking)) * 0.5
					WHEN @modds < - 0.25 THEN @commLostRate * sdiscount * stake * (1 - (spositiontaking + mpositiontaking + apositiontaking))
					WHEN @modds IS NULL THEN scomm
					END
				,STATUS = CASE 
					WHEN @modds > 0 THEN 'WON'
					WHEN @modds = 0 THEN 'DRAW'
					WHEN @modds < 0 THEN 'LOSE'
					WHEN @modds IS NULL THEN status
					END
				,StatusID = CASE 
					WHEN @modds > 0 THEN 112 --WON
					WHEN @modds = 0 THEN 111 --DRAW
					WHEN @modds < 0 THEN 113 --LOSE
					WHEN @modds IS NULL THEN statusID
					END
				,ruben = CASE when @modds IS NULL THEN ruben
							ELSE 1
					     END
			WHERE matchid = @matchid AND bettype = @bettype 
			    AND	statusID NOT IN (101, 102)
				AND 1 = CASE WHEN @IsSettleAbandonedMatch = 1 AND (custid IN (50057, 879241, 103873, 78761, 851668, 878902) OR recommend = 1688156) THEN 1
							 WHEN @IsSettleAbandonedMatchBetFair = 1 AND custid IN (2331, 1077687, 115770, 15523642) THEN 1
							 WHEN @IsSettleAbandonedMatchIBC = 1 AND (custid NOT IN (50057, 879241, 103873, 78761, 851668, 878902, 2331, 1077687, 115770, 15523642) AND recommend <> 1688156) THEN 1
							 ELSE 0
						END
		END
		ELSE
		BEGIN
			UPDATE bettrans WITH (ROWLOCK, UPDLOCK)
			SET 
				@correctscore	= CASE  WHEN bettype = 1317 AND @SelectedSet LIKE '%1%' AND BetID = 801 THEN @CorrectScoreSet1
										WHEN bettype = 1317 AND @SelectedSet LIKE '%2%' AND BetID = 802 THEN @CorrectScoreSet2
										WHEN bettype = 1317 AND @SelectedSet LIKE '%3%' AND BetID = 803 THEN @CorrectScoreSet3
										WHEN bettype = 1317 AND @SelectedSet LIKE '%4%' AND BetID = 804 THEN @CorrectScoreSet4
										WHEN bettype = 1317 AND @SelectedSet LIKE '%5%' AND BetID = 805 THEN @CorrectScoreSet5
										ELSE @correctscore END
				,@modds = modds = CASE 
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
					WHEN @modds > 0.25 THEN actual_stake + stake * (CASE WHEN odds < 0 THEN 1 ELSE (CASE WHEN bettype IN (4, 5, 6, 14, 15, 16, 30, 127, 1204, 1235,1302,1317) THEN odds - 1 ELSE odds END	) END )
					WHEN @modds = 0.25 THEN actual_stake + stake * (CASE WHEN odds < 0 THEN 1 ELSE (CASE WHEN bettype IN (4, 5, 6, 14, 15, 16, 30, 127, 1204, 1235,1302,1317) THEN odds - 1 ELSE odds END	) END ) * 0.5
					WHEN @modds = 0 THEN actual_stake WHEN @modds = - 0.25 THEN actual_stake * 0.5
					WHEN @modds < - 0.25 THEN 0
					END
				,aWinLost = CASE 
					WHEN @modds > 0.25 THEN stake * (CASE WHEN odds < 0 THEN 1 ELSE (CASE WHEN bettype IN (4, 5, 6, 14, 15, 16, 30, 127, 1204, 1235,1302,1317) THEN odds - 1 ELSE odds END ) END ) * - apositiontaking
					WHEN @modds = 0.25 THEN stake * (CASE WHEN odds < 0 THEN 1 ELSE (CASE WHEN bettype IN (4, 5, 6, 14, 15, 16, 30, 127, 1204, 1235,1302,1317) THEN odds - 1 ELSE odds END ) END ) * - apositiontaking * 0.5
					WHEN @modds = 0 THEN 0
					WHEN @modds = - 0.25 THEN actual_stake * apositiontaking * 0.5
					WHEN @modds < - 0.25 THEN actual_stake * apositiontaking
					END
				,mWinLost = CASE 
					WHEN @modds > 0.25 THEN stake * (CASE WHEN odds < 0 THEN 1 ELSE (CASE WHEN bettype IN (4, 5, 6, 14, 15, 16, 30,127, 1204, 1235,1302,1317) THEN odds - 1 ELSE odds END ) END ) * - mpositiontaking
					WHEN @modds = 0.25 THEN stake * (CASE WHEN odds < 0 THEN 1 ELSE (CASE WHEN bettype IN (4, 5, 6, 14, 15, 16, 30, 127, 1204, 1235,1302,1317) THEN odds - 1 ELSE odds END ) END ) * - mpositiontaking * 0.5
					WHEN @modds = 0 THEN 0
					WHEN @modds = - 0.25 THEN actual_stake * mpositiontaking * 0.5
					WHEN @modds < - 0.25 THEN actual_stake * mpositiontaking
					END
				,sWinLost = CASE 
					WHEN @modds > 0.25 THEN stake * (CASE WHEN odds < 0 THEN 1 ELSE (CASE WHEN bettype IN (4, 5, 6, 14, 15, 16, 30, 127, 1204, 1235,1302,1317) THEN odds - 1 ELSE odds END ) END ) * - spositiontaking
					WHEN @modds = 0.25 THEN stake * (CASE WHEN odds < 0 THEN 1 ELSE (CASE WHEN bettype IN (4, 5, 6, 14, 15, 16, 30, 127, 1204, 1235,1302,1317) THEN odds - 1 ELSE odds END ) END ) * - spositiontaking * 0.5
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
			WHERE matchid = @matchid 
				AND bettype = @bettype 
				AND statusID NOT IN (101,102)
					AND 1 = CASE WHEN @bettype <> 1317  THEN 1 
								 WHEN @bettype = 1317 AND @SelectedSet LIKE '%1%' AND BetID = 801 THEN 1
								 WHEN @bettype = 1317 AND @SelectedSet LIKE '%2%' AND BetID = 802 THEN 1
								 WHEN @bettype = 1317 AND @SelectedSet LIKE '%3%' AND BetID = 803 THEN 1
								 WHEN @bettype = 1317 AND @SelectedSet LIKE '%4%' AND BetID = 804 THEN 1
								 WHEN @bettype = 1317 AND @SelectedSet LIKE '%5%' AND BetID = 805 THEN 1
								 ELSE 0 END 
		END
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
GRANT VIEW DEFINITION ON [dbo].[NAP_Admin_Calculate_4] TO [vnteam] AS [dbo]