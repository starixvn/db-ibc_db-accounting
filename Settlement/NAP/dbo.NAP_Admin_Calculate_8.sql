/****** Object:  StoredProcedure [dbo].[NAP_Admin_Calculate_8]    Script Date: 08/27/2014 14:01:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[NAP_Admin_Calculate_8] @matchid INT
	,@bettype SMALLINT
	,@totalht SMALLMONEY
	,@scorediff_ht SMALLMONEY = NULL
	,@betcount INT = 0
	,@IsSettleAbandonedMatch BIT = 0
	,@IsSettleAbandonedMatchBetFair BIT = 0
	,@IsSettleAbandonedMatchIBC BIT = 0
	-- add any params, please modify script in 'special section'
AS
/*
	Created by: Kathy
	Date: 20140213
	Task: Settlement 
	DB: DBTXN/BODB02
	Original: Admin_Calculate_8

	Revisions:
		- 20140610@Kathy: Using clustered index(CIX_recommend_matchid_bettype) in DB052, DB053, DB054		
		- 20140729@Kathy: Add one more account(BF3) into BetFair's group [Redmine:#19665]
		- 20140808@Kathy: Support new 11 bettypes: 143 [Redmine:#19667]	
		- 20140818@Jamie: Correct settle  determined ticket 143 
		

	Param's Explanation:
		+ @IsSettleAbandonedMatch: Settle determined tickets for Abandoned/Postponed Match
		+ @IsSettleAbandonedMatchBetFair: Is Settlement for Betfair ticket of Abandoned/postponed match or not
*/
BEGIN
	IF @betcount = 0 AND @@SERVERNAME NOT LIKE N'DBIOM%' RETURN

	SET NOCOUNT ON

	IF @@SERVERNAME IN ('DB04', 'DB042', 'DB043', 'DB044') RETURN

	DECLARE @modds SMALLMONEY
		,@commWinRate SMALLMONEY
		,@commLostRate SMALLMONEY

	--- LAS settlement 
	IF @@SERVERNAME IN ('DB052', 'DB054', 'DB231', 'DB232') AND EXISTS (
			SELECT *
			FROM sys.databases
			WHERE NAME = 'LASDB'
			)
	BEGIN
		IF @IsSettleAbandonedMatch = 0 AND @IsSettleAbandonedMatchBetFair = 0
		BEGIN
			DECLARE @LASCommand NVARCHAR(1000)
				,@createdDate DATETIME

			SELECT @LASCommand = 'EXEC [dbo].[Admin_Calculate_8] @matchid = ' + CONVERT(NVARCHAR(10), @matchid) 
															+ ', @bettype = ' + CONVERT(NVARCHAR(10), @bettype) 
															+ ', @totalht = ' + CONVERT(NVARCHAR(10), @totalht) 
															+ ', @scorediff_ht = ' + CASE WHEN @scorediff_ht IS NULL THEN 'NULL' ELSE CONVERT(NVARCHAR(50), @scorediff_ht) END
															+ ', @IsSettleAbandonedMatchIBC = ' + CONVERT(NVARCHAR(10), @IsSettleAbandonedMatchIBC)
															+ ', @betcount = ' + CONVERT(NVARCHAR(10), @betcount)
				,@createdDate = GETDATE()

			EXEC LASDB.[dbo].[Las_GeneratingSettlementCommand] @SPName = 'Admin_Calculate_8'
				,@SQLCommand = @LASCommand
				,@CreatedDate = @createdDate
				,@StatusID = 0 -- waiting
				,@MatchID = @matchid
				,@Bettype = @bettype
				,@Status = 'waiting'
				,@BetCount = @betcount
		END
	END
	
	IF @IsSettleAbandonedMatch = 1 OR @IsSettleAbandonedMatchBetFair = 1 or @IsSettleAbandonedMatchIBC = 1
	BEGIN
		DECLARE	@comparedValue SMALLMONEY	--@totalht - 0.5 -- Get tickets had result 
		SELECT	@comparedValue = @totalht - 0.5

		UPDATE dbo.bettrans WITH (ROWLOCK, UPDLOCK)
		SET @modds = modds = CASE WHEN betteam = 'h' THEN @totalht - hdp1
								  WHEN betteam = 'a' THEN hdp1 - @totalht
								  WHEN RIGHT(betteam,1) ='u' THEN hdp1 - @totalht	-- 143 
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
				WHEN @modds >= 0.5 THEN actual_stake + stake * (CASE 
						WHEN odds < 0 THEN 1
						ELSE (CASE 
								WHEN bettype IN (143) THEN odds - 1
								ELSE odds END
								) END
						) -- WIN
				WHEN @modds <= - 0.5 THEN 0 -- LOSE	
				WHEN @modds IS NULL THEN winlost
				END
			,aWinLost = CASE 
				WHEN @modds >= 0.5 THEN stake * (CASE 
						WHEN odds < 0 THEN 1
						ELSE (CASE 
								WHEN bettype IN (143) THEN odds - 1
								ELSE odds END
								) END
						) * - apositiontaking
				WHEN @modds <= - 0.5 THEN actual_stake * apositiontaking
				WHEN @modds IS NULL THEN awinlost
				END
			,mWinLost = CASE 
				WHEN @modds >= 0.5 THEN stake * (CASE 
						WHEN odds < 0 THEN 1
						ELSE (CASE 
								WHEN bettype IN (143) THEN odds - 1
								ELSE odds END
								) END
						) * - mpositiontaking
				WHEN @modds <= - 0.5 THEN actual_stake * mpositiontaking
				WHEN @modds IS NULL THEN mwinlost
				END
			,sWinLost = CASE 
				WHEN @modds >= 0.5 THEN stake * (CASE 
						WHEN odds < 0 THEN 1
						ELSE (CASE 
								WHEN bettype IN (143) THEN odds - 1
								ELSE odds END
								) END
						) * - spositiontaking
				WHEN @modds <= - 0.5 THEN actual_stake * spositiontaking
				WHEN @modds IS NULL THEN swinlost
				END
			,PlayerComm = CASE 
				WHEN @modds >= 0.5 THEN @commWinRate * playerdiscount * stake
				WHEN @modds <= - 0.5 THEN @commLostRate * playerdiscount * stake
				WHEN @modds IS NULL THEN playercomm
				END
			,Comm = CASE 
				WHEN @modds >= 0.5 THEN @commWinRate * discount * stake * (1 - apositiontaking)
				WHEN @modds <= - 0.5 THEN @commLostRate * discount * stake * (1 - apositiontaking)
				WHEN @modds IS NULL THEN comm
				END
			,aComm = CASE 
				WHEN @modds >= 0.5 THEN @commWinRate * adiscount * stake * (1 - (mpositiontaking + apositiontaking))
				WHEN @modds <= - 0.5 THEN @commLostRate * adiscount * stake * (1 - (mpositiontaking + apositiontaking))
				WHEN @modds IS NULL THEN acomm
				END
			,sComm = CASE 
				WHEN @modds >= 0.5 THEN @commWinRate * sdiscount * stake * (1 - (spositiontaking + mpositiontaking + apositiontaking))
				WHEN @modds <= - 0.5 THEN @commLostRate * sdiscount * stake * (1 - (spositiontaking + mpositiontaking + apositiontaking))
				WHEN @modds IS NULL THEN scomm
				END
			,STATUS = CASE 
				WHEN @modds >= 0.5 THEN N'WON'
				WHEN @modds <= - 0.5 THEN N'LOSE'
				WHEN @modds IS NULL THEN status
				END
			,StatusID = CASE 
				WHEN @modds >= 0.5 THEN 112 --WON
				WHEN @modds <= - 0.5 THEN 113 --LOSE	
				WHEN @modds IS NULL THEN statusID
				END
			,ruben = case WHEN @modds IS NULL THEN ruben
						  ELSE 1
					 END
		WHERE matchid = @matchid AND bettype = @bettype AND
			--status NOT IN (N'VOID', N'REJECT')
			statusID NOT IN (101, 102) 
			AND 1 = CASE 
					WHEN @IsSettleAbandonedMatch = 1 AND (custid IN (50057, 879241, 103873, 78761, 851668, 878902) OR recommend = 1688156) THEN 1
					WHEN @IsSettleAbandonedMatchBetFair = 1 AND custid IN (2331, 1077687, 115770, 15523642) THEN 1
					WHEN @IsSettleAbandonedMatchIBC = 1 AND (custid NOT IN (50057, 879241, 103873, 78761, 851668, 878902, 2331, 1077687, 115770, 15523642) AND recommend <> 1688156) THEN 1
					ELSE 0
				END 
			AND hdp1 <= CASE WHEN @bettype = 8 AND (@IsSettleAbandonedMatch = 1  OR @IsSettleAbandonedMatchBetFair = 1)THEN @comparedValue  -- @comparedValue = @totalht - 0.5
							 WHEN @bettype <> 8 AND @IsSettleAbandonedMatchIBC = 1 THEN @comparedValue 
							 ELSE -1
						END
	END
	ELSE
	BEGIN
		IF @@SERVERNAME IN ('DB052', 'DB053', 'DB054','DB231')
		BEGIN
			DECLARE @affectedagents INT
	
			CREATE TABLE #tmpRecommend(recommend INT  PRIMARY KEY)

			INSERT INTO #tmpRecommend(recommend)
			SELECT DISTINCT recommend
			FROM dbo.bettrans (NOLOCK) WHERE matchid = @matchid and bettype = @bettype

			DECLARE @currecommend TABLE(recommend INT PRIMARY KEY)

			WHILE 1=1
			BEGIN
				DELETE
				FROM @currecommend

				DELETE TOP(100)
				FROM #tmpRecommend OUTPUT DELETED.recommend INTO @currecommend

				SET @affectedagents = @@rowcount

				UPDATE b
				SET @modds = modds = CASE 
					WHEN betteam = 'h' THEN @totalht-hdp1
					WHEN betteam = 'a' THEN hdp1-@totalht
					WHEN b.betteam = 'ho' AND @scorediff_ht > 0 THEN @totalht - b.hdp1
					WHEN b.betteam = 'hu' AND @scorediff_ht > 0 THEN b.hdp1 - @totalht
					WHEN b.betteam = 'ao' AND @scorediff_ht < 0 THEN @totalht - b.hdp1
					WHEN b.betteam = 'au' AND @scorediff_ht < 0 THEN b.hdp1 - @totalht
					WHEN b.betteam = 'do' AND @scorediff_ht = 0 THEN @totalht - b.hdp1
					WHEN b.betteam = 'du' AND @scorediff_ht = 0 THEN b.hdp1 - @totalht			
					ELSE - 1					
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
					WHEN @modds >  0.25	THEN actual_stake + stake * (case when odds<0 then 1 else (case when bettype in (143) then odds-1 else odds end) end)
					WHEN @modds =  0.25	THEN actual_stake + stake * (case when odds<0 then 1 else (case when bettype in (143) then odds-1 else odds end) end) * 0.5
					WHEN @modds =  0	THEN actual_stake
					WHEN @modds = -0.25	THEN actual_stake * 0.5
					WHEN @modds < -0.25	THEN 0
					END, 

				aWinLost = CASE
					WHEN @modds >  0.25	THEN stake * (case when odds<0 then 1 else (case when bettype in (143) then odds-1 else odds end) end) * -apositiontaking
					WHEN @modds =  0.25	THEN stake * (case when odds<0 then 1 else (case when bettype in (143) then odds-1 else odds end) end) * -apositiontaking * 0.5
					WHEN @modds =  0	THEN 0
					WHEN @modds = -0.25	THEN actual_stake * apositiontaking * 0.5
					WHEN @modds < -0.25	THEN actual_stake * apositiontaking
					END,
				mWinLost = CASE
					WHEN @modds >  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (143) then odds-1 else odds end) end) * -mpositiontaking
					WHEN @modds =  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (143) then odds-1 else odds end) end) * -mpositiontaking * 0.5
					WHEN @modds =  0    	THEN 0
					WHEN @modds = -0.25 	THEN actual_stake * mpositiontaking * 0.5
					WHEN @modds < -0.25 	THEN actual_stake * mpositiontaking
					END,
				sWinLost = CASE
					WHEN @modds >  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (143) then odds-1 else odds end) end) * -spositiontaking
					WHEN @modds =  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (143) then odds-1 else odds end) end) * -spositiontaking * 0.5
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
					statusID NOT IN (101,102)

				IF @affectedagents <> 100 
					BREAK
			END 
			DROP TABLE #tmpRecommend
		END
		ELSE
		BEGIN
			UPDATE dbo.bettrans WITH (ROWLOCK, UPDLOCK)
			SET @modds = modds = CASE 
					WHEN betteam = 'h' THEN @totalht - hdp1
					WHEN betteam = 'a' THEN hdp1 - @totalht
					WHEN betteam = 'ho' AND @scorediff_ht > 0 THEN @totalht - hdp1
					WHEN betteam = 'hu' AND @scorediff_ht > 0 THEN hdp1 - @totalht
					WHEN betteam = 'ao' AND @scorediff_ht < 0 THEN @totalht - hdp1
					WHEN betteam = 'au' AND @scorediff_ht < 0 THEN hdp1 - @totalht
					WHEN betteam = 'do' AND @scorediff_ht = 0 THEN @totalht - hdp1
					WHEN betteam = 'du' AND @scorediff_ht = 0 THEN hdp1 - @totalht			
					ELSE -1
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
					WHEN @modds > 0.25 THEN actual_stake + stake * (CASE 
							WHEN odds < 0 THEN 1
							ELSE (CASE 
									WHEN bettype IN (143) THEN odds - 1
									ELSE odds END
									) END
							)
					WHEN @modds = 0.25 THEN actual_stake + stake * (CASE 
							WHEN odds < 0 THEN 1
							ELSE (CASE 
									WHEN bettype IN (143) THEN odds - 1
									ELSE odds END
									) END
							) * 0.5
					WHEN @modds = 0 THEN actual_stake
					WHEN @modds = - 0.25 THEN actual_stake * 0.5
					WHEN @modds < - 0.25 THEN 0
					END
				,aWinLost = CASE 
					WHEN @modds > 0.25 THEN stake * (CASE 
							WHEN odds < 0 THEN 1
							ELSE (CASE 
									WHEN bettype IN (143) THEN odds - 1
									ELSE odds END
									) END
							) * - apositiontaking
					WHEN @modds = 0.25 THEN stake * (CASE 
							WHEN odds < 0 THEN 1
							ELSE (CASE 
									WHEN bettype IN (143) THEN odds - 1
									ELSE odds END
									) END
							) * - apositiontaking * 0.5
					WHEN @modds = 0 THEN 0
					WHEN @modds = - 0.25 THEN actual_stake * apositiontaking * 0.5
					WHEN @modds < - 0.25 THEN actual_stake * apositiontaking
					END
				,mWinLost = CASE 
					WHEN @modds > 0.25 THEN stake * (CASE 
							WHEN odds < 0 THEN 1
							ELSE (CASE 
									WHEN bettype IN (143) THEN odds - 1
									ELSE odds END
									) END
							) * - mpositiontaking
					WHEN @modds = 0.25 THEN stake * (CASE 
							WHEN odds < 0 THEN 1
							ELSE (CASE 
									WHEN bettype IN (143) THEN odds - 1
									ELSE odds END
									) END
							) * - mpositiontaking * 0.5
					WHEN @modds = 0 THEN 0
					WHEN @modds = - 0.25 THEN actual_stake * mpositiontaking * 0.5
					WHEN @modds < - 0.25 THEN actual_stake * mpositiontaking
					END
				,sWinLost = CASE 
					WHEN @modds > 0.25 THEN stake * (CASE 
							WHEN odds < 0 THEN 1
							ELSE (CASE 
									WHEN bettype IN (143) THEN odds - 1
									ELSE odds END
									) END
							) * - spositiontaking
					WHEN @modds = 0.25 THEN stake * (CASE 
							WHEN odds < 0 THEN 1
							ELSE (CASE 
									WHEN bettype IN (143) THEN odds - 1
									ELSE odds END
									) END
							) * - spositiontaking * 0.5
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
				statusID NOT IN (101, 102)
		END
	END
	
END


GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Admin_Calculate_8] TO [vnteam] AS [dbo]