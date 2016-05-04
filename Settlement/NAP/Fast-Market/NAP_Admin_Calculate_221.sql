USE [bodb02]
GO
ALTER PROCEDURE dbo.NAP_Admin_Calculate_221 @matchid INT
    , @bettype SMALLINT
    , @hdp1 INT = NULL 
    , @betoption INT = NULL
    , @betcount INT = 0
	, @action VARCHAR(20)
AS
/*
    Created: 20160428@Patrick
    Task: Fast Market - Calculate
    DB: DBTXN/BODB02
    Original:

    Revisions:

    Param's Explanation:

*/
BEGIN
    SET NOCOUNT ON
	IF @betcount = 0 AND @@SERVERNAME NOT LIKE N'DBIOM%' RETURN

    DECLARE @modds MONEY, @commWinRate SMALLMONEY, @commLostRate SMALLMONEY
		, @invbetoption INT

	SET @invbetoption = @betoption ^ 65535

    IF @@SERVERNAME IN ('DB04', 'DB042', 'DB043', 'DB044') RETURN
	    
	IF @action = 'CAL'
	BEGIN
		IF @@SERVERNAME IN ('DB052', 'DB053', 'DB054','DB231','DB215')
		BEGIN
			DECLARE @affectedagents INT
			CREATE TABLE #tmpRecommend(recommend INT  PRIMARY KEY)

			INSERT INTO #tmpRecommend(recommend)
			SELECT DISTINCT recommend
			FROM dbo.bettrans WITH(NOLOCK) WHERE matchid = @matchid and bettype = @bettype

			DECLARE @currecommend TABLE(recommend INT PRIMARY KEY)

			WHILE 1 = 1
			BEGIN
				DELETE 
				FROM @currecommend

				DELETE TOP(100) 
				FROM #tmpRecommend OUTPUT DELETED.recommend INTO @currecommend

				SET @affectedagents = @@rowcount

				UPDATE b
				SET @modds = CASE WHEN betteam > 0 AND (CAST(hdp2 AS INT) & @betoption) > 0 THEN 1
								WHEN betteam = 0 AND (CAST(hdp2 AS INT) & @invbetoption) > 0 THEN 1
							ELSE -1 END
				, modds = @modds
				, @commWinRate = CASE comstatus -- 0 : pay normal, both win/lost -- 1 : pay 'double' ONLY on lost
									WHEN '0' THEN 1
									WHEN '1' THEN 0
								ELSE 1 END
				, @commLostRate = CASE comstatus
									WHEN '0' THEN 1
									WHEN '1' THEN 2
								ELSE 1 END
                
				, WinLost = CASE 
					WHEN @modds > 0.25 THEN actual_stake + stake * (CASE WHEN odds < 0 THEN 1 ELSE (CASE WHEN bettype IN (221,222,223,224) THEN odds - 1 ELSE odds END) END)
					WHEN @modds = 0.25 THEN actual_stake + stake * (CASE WHEN odds < 0 THEN 1 ELSE (CASE WHEN bettype IN (221,222,223,224) THEN odds - 1 ELSE odds END) END) * 0.5
					WHEN @modds = 0 THEN actual_stake
					WHEN @modds = -0.25 THEN actual_stake * 0.5
					WHEN @modds < -0.25 THEN 0
				END
				, aWinLost = CASE 
					WHEN @modds > 0.25 THEN stake * (CASE WHEN odds < 0 THEN 1 ELSE (CASE WHEN bettype IN (221,222,223,224) THEN odds - 1 ELSE odds END) END) * -apositiontaking
					WHEN @modds = 0.25 THEN stake * (CASE WHEN odds < 0 THEN 1 ELSE (CASE WHEN bettype IN (221,222,223,224) THEN odds - 1 ELSE odds END) END) * -apositiontaking * 0.5
					WHEN @modds = 0 THEN 0
					WHEN @modds = -0.25    THEN actual_stake * apositiontaking * 0.5
					WHEN @modds < -0.25    THEN actual_stake * apositiontaking
				END
				, mWinLost = CASE
					WHEN @modds > 0.25 THEN stake * (CASE WHEN odds < 0 THEN 1 ELSE (CASE WHEN bettype IN (221,222,223,224) THEN odds - 1 ELSE odds END) END) * -mpositiontaking
					WHEN @modds = 0.25 THEN stake * (CASE WHEN odds < 0 THEN 1 ELSE (CASE WHEN bettype IN (221,222,223,224) THEN odds - 1 ELSE odds END) END) * -mpositiontaking * 0.5
					WHEN @modds = 0 THEN 0
					WHEN @modds = -0.25 THEN actual_stake * mpositiontaking * 0.5
					WHEN @modds < -0.25 THEN actual_stake * mpositiontaking
					END
				, sWinLost = CASE
					WHEN @modds > 0.25 THEN stake * (CASE WHEN odds < 0 THEN 1 ELSE (CASE WHEN bettype IN (221,222,223,224) THEN odds - 1 ELSE odds END) END) * -spositiontaking
					WHEN @modds = 0.25 THEN stake * (CASE WHEN odds < 0 THEN 1 ELSE (CASE WHEN bettype IN (221,222,223,224) THEN odds - 1 ELSE odds END) END) * -spositiontaking * 0.5
					WHEN @modds = 0 THEN 0
					WHEN @modds = -0.25 THEN actual_stake * spositiontaking * 0.5
					WHEN @modds < -0.25 THEN actual_stake * spositiontaking
				 END
				, PlayerComm = CASE
					WHEN @modds >  0.25 THEN @commWinRate * playerdiscount * stake
					WHEN @modds =  0.25 THEN @commWinRate * playerdiscount * stake * 0.5
					WHEN @modds =  0 THEN 0
					WHEN @modds = -0.25 THEN @commLostRate * playerdiscount * stake * 0.5
					WHEN @modds < -0.25 THEN @commLostRate * playerdiscount * stake
					END
				, Comm = CASE
					WHEN @modds > 0.25 THEN @commWinRate * discount * stake * (1-apositiontaking)
					WHEN @modds = 0.25 THEN @commWinRate * discount * stake * (1-apositiontaking) * 0.5
					WHEN @modds = 0 THEN 0
					WHEN @modds = -0.25 THEN @commLostRate * discount * stake * (1-apositiontaking) * 0.5
					WHEN @modds < -0.25 THEN @commLostRate * discount * stake * (1-apositiontaking)
					END
				, aComm = CASE
					WHEN @modds > 0.25 THEN @commWinRate * adiscount * stake * (1-(mpositiontaking+apositiontaking))
					WHEN @modds = 0.25 THEN @commWinRate * adiscount * stake * (1-(mpositiontaking+apositiontaking)) * 0.5
					WHEN @modds = 0 THEN 0
					WHEN @modds = -0.25 THEN @commLostRate * adiscount * stake * (1-(mpositiontaking+apositiontaking)) * 0.5
					WHEN @modds < -0.25 THEN @commLostRate * adiscount * stake * (1-(mpositiontaking+apositiontaking))
					END
				, sComm = CASE
					WHEN @modds > 0.25 THEN @commWinRate * sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking))
					WHEN @modds = 0.25 THEN @commWinRate * sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking)) * 0.5
					WHEN @modds = 0 THEN 0
					WHEN @modds = -0.25 THEN @commLostRate * sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking)) * 0.5
					WHEN @modds < -0.25 THEN @commLostRate * sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking))
					END

				, Status = CASE
					WHEN @modds > 0 THEN N'WON'
					WHEN @modds = 0 THEN 'DRAW'
					WHEN @modds < 0 THEN N'LOSE'
					END
				, StatusID = CASE
					WHEN @modds > 0 THEN 112 --WON
					WHEN @modds = 0 THEN 111 --DRAW
					WHEN @modds < 0 THEN 113 --LOSE
					END
				, ruben = 1
				FROM dbo.bettrans b WITH (ROWLOCK, UPDLOCK)
					INNER JOIN @currecommend ag on b.recommend = ag.recommend
				WHERE matchid=@matchid
					AND bettype = @bettype 
					AND statusID NOT IN (101, 102)
					AND hdp1 = @hdp1

				IF @affectedagents <> 100 
					BREAK
			END
		END
		ELSE
		BEGIN
			UPDATE b
				SET @modds = CASE WHEN betteam > 0 AND (CAST(hdp2 AS INT) & @betoption) > 0 THEN 1
								WHEN betteam = 0 AND (CAST(hdp2 AS INT) & @invbetoption) > 0 THEN 1
							ELSE -1 END
				, modds = @modds
				, @commWinRate = CASE comstatus -- 0 : pay normal, both win/lost -- 1 : pay 'double' ONLY on lost
									WHEN '0' THEN 1
									WHEN '1' THEN 0
								ELSE 1 END
				, @commLostRate = CASE comstatus
									WHEN '0' THEN 1
									WHEN '1' THEN 2
								ELSE 1 END
                
				, WinLost = CASE 
					WHEN @modds > 0.25 THEN actual_stake + stake * (CASE WHEN odds < 0 THEN 1 ELSE (CASE WHEN bettype IN (221,222,223,224) THEN odds - 1 ELSE odds END) END)
					WHEN @modds = 0.25 THEN actual_stake + stake * (CASE WHEN odds < 0 THEN 1 ELSE (CASE WHEN bettype IN (221,222,223,224) THEN odds - 1 ELSE odds END) END) * 0.5
					WHEN @modds = 0 THEN actual_stake
					WHEN @modds = -0.25 THEN actual_stake * 0.5
					WHEN @modds < -0.25 THEN 0
				END
				, aWinLost = CASE 
					WHEN @modds > 0.25 THEN stake * (CASE WHEN odds < 0 THEN 1 ELSE (CASE WHEN bettype IN (221,222,223,224) THEN odds - 1 ELSE odds END) END) * -apositiontaking
					WHEN @modds = 0.25 THEN stake * (CASE WHEN odds < 0 THEN 1 ELSE (CASE WHEN bettype IN (221,222,223,224) THEN odds - 1 ELSE odds END) END) * -apositiontaking * 0.5
					WHEN @modds = 0 THEN 0
					WHEN @modds = -0.25 THEN actual_stake * apositiontaking * 0.5
					WHEN @modds < -0.25 THEN actual_stake * apositiontaking
				END
				, mWinLost = CASE
					WHEN @modds > 0.25 THEN stake * (CASE WHEN odds < 0 THEN 1 ELSE (CASE WHEN bettype IN (221,222,223,224) THEN odds - 1 ELSE odds END) END) * -mpositiontaking
					WHEN @modds = 0.25 THEN stake * (CASE WHEN odds < 0 THEN 1 ELSE (CASE WHEN bettype IN (221,222,223,224) THEN odds - 1 ELSE odds END) END) * -mpositiontaking * 0.5
					WHEN @modds = 0 THEN 0
					WHEN @modds = -0.25 THEN actual_stake * mpositiontaking * 0.5
					WHEN @modds < -0.25 THEN actual_stake * mpositiontaking
					END
				, sWinLost = CASE
					WHEN @modds > 0.25 THEN stake * (CASE WHEN odds < 0 THEN 1 ELSE (CASE WHEN bettype IN (221,222,223,224) THEN odds - 1 ELSE odds END) END) * -spositiontaking
					WHEN @modds = 0.25 THEN stake * (CASE WHEN odds < 0 THEN 1 ELSE (CASE WHEN bettype IN (221,222,223,224) THEN odds - 1 ELSE odds END) END) * -spositiontaking * 0.5
					WHEN @modds = 0 THEN 0
					WHEN @modds = -0.25 THEN actual_stake * spositiontaking * 0.5
					WHEN @modds < -0.25 THEN actual_stake * spositiontaking
				 END
				, PlayerComm = CASE
					WHEN @modds > 0.25 THEN @commWinRate * playerdiscount * stake
					WHEN @modds = 0.25 THEN @commWinRate * playerdiscount * stake * 0.5
					WHEN @modds = 0 THEN 0
					WHEN @modds = -0.25 THEN @commLostRate * playerdiscount * stake * 0.5
					WHEN @modds < -0.25 THEN @commLostRate * playerdiscount * stake
					END
				, Comm = CASE
					WHEN @modds > 0.25 THEN @commWinRate * discount * stake * (1-apositiontaking)
					WHEN @modds = 0.25 THEN @commWinRate * discount * stake * (1-apositiontaking) * 0.5
					WHEN @modds = 0 THEN 0
					WHEN @modds = -0.25 THEN @commLostRate * discount * stake * (1-apositiontaking) * 0.5
					WHEN @modds < -0.25 THEN @commLostRate * discount * stake * (1-apositiontaking)
					END
				, aComm = CASE
					WHEN @modds > 0.25 THEN @commWinRate * adiscount * stake * (1-(mpositiontaking+apositiontaking))
					WHEN @modds = 0.25 THEN @commWinRate * adiscount * stake * (1-(mpositiontaking+apositiontaking)) * 0.5
					WHEN @modds = 0 THEN 0
					WHEN @modds = -0.25 THEN @commLostRate * adiscount * stake * (1-(mpositiontaking+apositiontaking)) * 0.5
					WHEN @modds < -0.25 THEN @commLostRate * adiscount * stake * (1-(mpositiontaking+apositiontaking))
					END
				, sComm = CASE
					WHEN @modds > 0.25 THEN @commWinRate * sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking))
					WHEN @modds = 0.25 THEN @commWinRate * sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking)) * 0.5
					WHEN @modds = 0 THEN 0
					WHEN @modds = -0.25 THEN @commLostRate * sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking)) * 0.5
					WHEN @modds < -0.25 THEN @commLostRate * sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking))
					END

				, Status = CASE
					WHEN @modds > 0 THEN N'WON'
					WHEN @modds = 0 THEN 'DRAW'
					WHEN @modds < 0 THEN N'LOSE'
					END
				, StatusID = CASE
					WHEN @modds > 0 THEN 112 --WON
					WHEN @modds = 0 THEN 111 --DRAW
					WHEN @modds < 0 THEN 113 --LOSE
					END
				, ruben = 1
				FROM dbo.bettrans b WITH (ROWLOCK, UPDLOCK)
				WHERE matchid=@matchid
					AND bettype = @bettype 
					AND statusID NOT IN (101, 102)
					AND hdp1 = @hdp1
		END
	END
	ELSE IF @action = 'UNDO'
	BEGIN
		UPDATE dbo.bettrans WITH (ROWLOCK, UPDLOCK)
		SET ruben = 0
			, STATUS = 'running'
			, statusID = 0
			, winlost = 0
			, awinlost = 0
			, mwinlost = 0
			, swinlost = 0
			, playercomm = 0
			, comm = 0
			, acomm = 0
			, scomm = 0
		WHERE matchid = @matchid
			AND bettype = @bettype
			AND StatusID NOT IN (0, 1, 102, 101) ---('running','waiting','void','reject')
			AND hdp1 = @hdp1
				
	END
	ELSE IF @action = 'REFUND'
	BEGIN
		UPDATE dbo.bettrans WITH (ROWLOCK, UPDLOCK)
		SET status = N'Refund'
			, statusID = 103
			, winlost = actual_stake
			, awinlost = 0
			, mwinlost = 0
			, swinlost = 0
			, playercomm = 0
			, comm = 0
			, acomm = 0
			, scomm = 0
			, ruben = 1
			, statuswinlost = 0
        WHERE matchid = @matchid 
			AND statusID NOT IN (103, 101, 102) 
			AND bettype = @bettype
			AND hdp1 = @hdp1
	END
END
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Admin_Calculate_221] TO [vnteam] AS [dbo]