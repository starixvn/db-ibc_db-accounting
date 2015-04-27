USE [bodb02]
GO
ALTER PROCEDURE [dbo].[NAP_Admin_Calculate_1] 
     @matchid INT
	,@bettype				SMALLINT
	,@fth					SMALLMONEY	= NULL
	,@fta					SMALLMONEY	= NULL 
	,@SelectedSet			VARCHAR(50) = NULL 
	,@TotalGameHomeSet1		SMALLMONEY	= NULL 
	,@TotalGameHomeSet2		SMALLMONEY	= NULL 
	,@TotalGameHomeSet3		SMALLMONEY	= NULL 
	,@TotalGameHomeSet4		SMALLMONEY	= NULL 
	,@TotalGameHomeSet5		SMALLMONEY	= NULL 
	,@TotalGameAwaySet1		SMALLMONEY	= NULL 
	,@TotalGameAwaySet2		SMALLMONEY	= NULL 
	,@TotalGameAwaySet3		SMALLMONEY	= NULL 
	,@TotalGameAwaySet4		SMALLMONEY	= NULL 
	,@TotalGameAwaySet5		SMALLMONEY	= NULL 
	,@isRefundHT			BIT = 0
	,@betcount				INT = 0
	-- add any params, please modify script in 'special section'
AS
/*
	Created by: Kathy
	Date:20140211
	Task: Settlement 
	DB: DBTRANS.BODB02
	
	Revisions:
		- 20140610@Kathy: Using clustered index(CIX_recommend_matchid_bettype) in DB052, DB053, DB054		
		- 20141017@Jamie: Sporting Solution for Tennis [Redmine:#23034]
		- 20150415@Jamie: Settlement Betradar phase 2 [Redmine: #27212]
		
*/
BEGIN
	IF @betcount = 0 AND @@SERVERNAME NOT LIKE N'DBIOM%' RETURN

	SET NOCOUNT ON

	DECLARE @modds SMALLMONEY
		,@commWinRate SMALLMONEY
		,@commLostRate SMALLMONEY
		,@RemoteCount INT

	IF @@SERVERNAME IN ('DB04', 'DB042', 'DB043', 'DB044') RETURN

	--- LAS settlement 
	IF @@SERVERNAME IN ('DB052', 'DB054', 'DB231', 'DB232','DB215') AND EXISTS (
			SELECT *
			FROM sys.databases
			WHERE NAME = 'LASDB'
			)
	BEGIN
		DECLARE @LASCommand NVARCHAR(1000)
			,@createdDate DATETIME

		SELECT @LASCommand = 'EXEC [dbo].[Admin_Calculate_1] @matchid = ' + CONVERT(NVARCHAR(10), @matchid) + ', @bettype = ' + CONVERT(NVARCHAR(10), @bettype) + ', @fth = ' + CONVERT(NVARCHAR(10), @fth) + ', @fta = ' + CONVERT(NVARCHAR(10), @fta) + ', @betcount = ' + CONVERT(NVARCHAR(10), @betcount)
			,@createdDate = GETDATE()

		EXEC LASDB.[dbo].[Las_GeneratingSettlementCommand] @SPName = 'Admin_Calculate_1'
			,@SQLCommand = @LASCommand
			,@CreatedDate = @createdDate
			,@StatusID = 0 -- waiting
			,@MatchID = @matchid
			,@Bettype = @bettype
			,@Status = 'waiting'
			,@BetCount = @betcount
	END

	IF @@SERVERNAME IN ('DB052', 'DB053', 'DB054','DB231','DB215')
	BEGIN
		DECLARE @affectedagents INT

		CREATE TABLE #tmpRecommend(recommend INT  PRIMARY KEY)

		INSERT INTO #tmpRecommend(recommend)
		SELECT DISTINCT recommend
		FROM dbo.bettrans WITH(NOLOCK) WHERE matchid = @matchid and bettype = @bettype

		DECLARE @currecommend TABLE(recommend int PRIMARY KEY)

		WHILE 1=1
		BEGIN
			DELETE 
			FROM @currecommend

			DELETE TOP (100)
			FROM #tmpRecommend OUTPUT DELETED.recommend INTO @currecommend

			SET @affectedagents = @@rowcount

			UPDATE b
			SET 
			
			@fth = CASE WHEN bettype IN (154,155,1311, 1316) AND BetID = 801 AND @SelectedSet LIKE '%1%' THEN @TotalGameHomeSet1 
						WHEN bettype IN (154,155,1311, 1316) AND BetID = 802 AND @SelectedSet LIKE '%2%' THEN @TotalGameHomeSet2 
						WHEN bettype IN (154,155,1311, 1316) AND BetID = 803 AND @SelectedSet LIKE '%3%' THEN @TotalGameHomeSet3 
						WHEN bettype IN (154,155,1311, 1316) AND BetID = 804 AND @SelectedSet LIKE '%4%' THEN @TotalGameHomeSet4 
						WHEN bettype IN (154,155,1311, 1316) AND BetID = 805 AND @SelectedSet LIKE '%5%' THEN @TotalGameHomeSet5
						ELSE @fth END 
			,@fta = CASE WHEN bettype IN (154,155,1311, 1316) AND BetID = 801 AND @SelectedSet LIKE '%1%' THEN @TotalGameAwaySet1 
						 WHEN bettype IN (154,155,1311, 1316) AND BetID = 802 AND @SelectedSet LIKE '%2%' THEN @TotalGameAwaySet2
						 WHEN bettype IN (154,155,1311, 1316) AND BetID = 803 AND @SelectedSet LIKE '%3%' THEN @TotalGameAwaySet3 
						 WHEN bettype IN (154,155,1311, 1316) AND BetID = 804 AND @SelectedSet LIKE '%4%' THEN @TotalGameAwaySet4 
						 WHEN bettype IN (154,155,1311, 1316) AND BetID = 805 AND @SelectedSet LIKE '%5%' THEN @TotalGameAwaySet5
						 ELSE @fta END 	
			,@modds = modds = CASE betteam
				WHEN N'h' THEN (hdp2-hdp1) + (@fth - livehomescore) - (@fta - liveawayscore) 
				WHEN N'a' THEN (hdp1-hdp2) - (@fth - livehomescore) + (@fta - liveawayscore)
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
				WHEN @modds >  0.25	THEN actual_stake + stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,1201) then odds-1 else odds end) end)
				WHEN @modds =  0.25	THEN actual_stake + stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,1201) then odds-1 else odds end) end) * 0.5
				WHEN @modds =  0	THEN actual_stake
				WHEN @modds = -0.25	THEN actual_stake * 0.5
				WHEN @modds < -0.25	THEN 0
				END,

			aWinLost = CASE
				WHEN @modds >  0.25	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,1201) then odds-1 else odds end) end) * -apositiontaking
				WHEN @modds =  0.25	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,1201) then odds-1 else odds end) end) * -apositiontaking * 0.5
				WHEN @modds =  0	THEN 0
				WHEN @modds = -0.25	THEN actual_stake * apositiontaking * 0.5
				WHEN @modds < -0.25	THEN actual_stake * apositiontaking
				END,
			mWinLost = CASE
				WHEN @modds >  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,1201) then odds-1 else odds end) end) * -mpositiontaking
				WHEN @modds =  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,1201) then odds-1 else odds end) end) * -mpositiontaking * 0.5
				WHEN @modds =  0    	THEN 0
				WHEN @modds = -0.25 	THEN actual_stake * mpositiontaking * 0.5
				WHEN @modds < -0.25 	THEN actual_stake * mpositiontaking
				END,
			sWinLost = CASE
				WHEN @modds >  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,1201) then odds-1 else odds end) end) * -spositiontaking
				WHEN @modds =  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,1201) then odds-1 else odds end) end) * -spositiontaking * 0.5
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
				matchid=@matchid 
				AND Bettype = @bettype
				AND statusID NOT IN (101,102) -- REJECT & VOID 
				AND 1 = CASE WHEN @bettype = 183 and @isRefundHT = 1 THEN 0 ELSE 1 END
				AND 1 = CASE WHEN @Bettype NOT IN (154,155,1311, 1316) THEN 1
							 WHEN @Bettype IN (154,155,1311, 1316) AND @SelectedSet LIKE '%1%' AND BetID = 801 THEN 1
							 WHEN @Bettype IN (154,155,1311, 1316) AND @SelectedSet LIKE '%2%' AND BetID = 802 THEN 1
							 WHEN @Bettype IN (154,155,1311, 1316) AND @SelectedSet LIKE '%3%' AND BetID = 803 THEN 1
							 WHEN @Bettype IN (154,155,1311, 1316) AND @SelectedSet LIKE '%4%' AND BetID = 804 THEN 1
							 WHEN @Bettype IN (154,155,1311, 1316) AND @SelectedSet LIKE '%5%' AND BetID = 805 THEN 1
							 ELSE 0 END 

			IF @affectedagents <> 100
				BREAK
		END

		DROP TABLE #tmpRecommend
	END
	ELSE
	BEGIN
		UPDATE dbo.bettrans WITH (ROWLOCK, UPDLOCK)
		SET @fth = CASE WHEN bettype IN (154,155,1311, 1316) AND BetID = 801 AND @SelectedSet LIKE '%1%' THEN @TotalGameHomeSet1 
						WHEN bettype IN (154,155,1311, 1316) AND BetID = 802 AND @SelectedSet LIKE '%2%' THEN @TotalGameHomeSet2 
						WHEN bettype IN (154,155,1311, 1316) AND BetID = 803 AND @SelectedSet LIKE '%3%' THEN @TotalGameHomeSet3 
						WHEN bettype IN (154,155,1311, 1316) AND BetID = 804 AND @SelectedSet LIKE '%4%' THEN @TotalGameHomeSet4 
						WHEN bettype IN (154,155,1311, 1316) AND BetID = 805 AND @SelectedSet LIKE '%5%' THEN @TotalGameHomeSet5
						ELSE @fth END 
			,@fta = CASE WHEN bettype IN (154,155,1311, 1316) AND BetID = 801 AND @SelectedSet LIKE '%1%' THEN @TotalGameAwaySet1 
						 WHEN bettype IN (154,155,1311, 1316) AND BetID = 802 AND @SelectedSet LIKE '%2%' THEN @TotalGameAwaySet2
						 WHEN bettype IN (154,155,1311, 1316) AND BetID = 803 AND @SelectedSet LIKE '%3%' THEN @TotalGameAwaySet3 
						 WHEN bettype IN (154,155,1311, 1316) AND BetID = 804 AND @SelectedSet LIKE '%4%' THEN @TotalGameAwaySet4 
						 WHEN bettype IN (154,155,1311, 1316) AND BetID = 805 AND @SelectedSet LIKE '%5%' THEN @TotalGameAwaySet5
						 ELSE @fta END		
			,@modds = modds = CASE betteam
				WHEN N'h' THEN (hdp2 - hdp1) + (@fth - livehomescore) - (@fta - liveawayscore)
				WHEN N'a' THEN (hdp1 - hdp2) - (@fth - livehomescore) + (@fta - liveawayscore)
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
			,--'s','m'
			WinLost = CASE 
				WHEN @modds > 0.25 THEN actual_stake + stake * (CASE 
						WHEN odds < 0 THEN 1
						ELSE (CASE 
								WHEN bettype IN (4, 5, 6, 1201) THEN odds - 1
								ELSE odds END
								) END
						)
				WHEN @modds = 0.25 THEN actual_stake + stake * (CASE 
						WHEN odds < 0 THEN 1
						ELSE (CASE 
								WHEN bettype IN (4, 5, 6, 1201) THEN odds - 1
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
								WHEN bettype IN (4, 5, 6, 1201) THEN odds - 1
								ELSE odds END
								) END
						) * - apositiontaking
				WHEN @modds = 0.25 THEN stake * (CASE 
						WHEN odds < 0 THEN 1
						ELSE (CASE 
								WHEN bettype IN (4, 5, 6, 1201) THEN odds - 1
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
								WHEN bettype IN (4, 5, 6, 1201) THEN odds - 1
								ELSE odds END
								) END
						) * - mpositiontaking
				WHEN @modds = 0.25 THEN stake * (CASE 
						WHEN odds < 0 THEN 1
						ELSE (CASE 
								WHEN bettype IN (4, 5, 6, 1201) THEN odds - 1
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
								WHEN bettype IN (4, 5, 6, 1201) THEN odds - 1
								ELSE odds END
								) END
						) * - spositiontaking
				WHEN @modds = 0.25 THEN stake * (CASE 
						WHEN odds < 0 THEN 1
						ELSE (CASE 
								WHEN bettype IN (4, 5, 6, 1201) THEN odds - 1
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
				WHEN @modds > 0 THEN N'WON'
				WHEN @modds = 0 THEN N'DRAW'
				WHEN @modds < 0 THEN N'LOSE'
				END
			,StatusID = CASE 
				WHEN @modds > 0 THEN 112 --WON
				WHEN @modds = 0 THEN 111 --DRAW
				WHEN @modds < 0 THEN 113 --LOSE
				END
			,ruben = 1
		WHERE matchid = @matchid 
			AND bettype = @bettype 
			AND statusID NOT IN (101,102) -- REJECT & VOID 
			AND 1 = CASE WHEN @bettype = 183 and @isRefundHT = 1 THEN 0 ELSE 1 END
			AND 1 = CASE WHEN @Bettype NOT IN (154,155,1311, 1316) THEN 1
							WHEN @Bettype IN (154,155,1311, 1316) AND @SelectedSet LIKE '%1%' AND BetID = 801 THEN 1
							WHEN @Bettype IN (154,155,1311, 1316) AND @SelectedSet LIKE '%2%' AND BetID = 802 THEN 1
							WHEN @Bettype IN (154,155,1311, 1316) AND @SelectedSet LIKE '%3%' AND BetID = 803 THEN 1
							WHEN @Bettype IN (154,155,1311, 1316) AND @SelectedSet LIKE '%4%' AND BetID = 804 THEN 1
							WHEN @Bettype IN (154,155,1311, 1316) AND @SelectedSet LIKE '%5%' AND BetID = 805 THEN 1
							ELSE 0 END 
	END
END
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Admin_Calculate_1] TO [vnteam] AS [dbo]