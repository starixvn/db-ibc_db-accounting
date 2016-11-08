USE [bodb02]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE dbo.NAP_Admin_Calculate_221 @matchid INT
	, @result VARCHAR(MAX)
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
	
	IF @@SERVERNAME IN ('DB04', 'DB042', 'DB043', 'DB044') RETURN
	    
    DECLARE @modds			MONEY
			,@commWinRate	SMALLMONEY
			,@commLostRate	SMALLMONEY
			,@xmlData		XML
			,@Top			INT 

	SET @xmlData = CONVERT(XML, @result)
	SET @Top = 2147483647
	
	CREATE TABLE #tblTransIds(transid BIGINT PRIMARY KEY, BetOption TINYINT)	
	
	;WITH TmpData AS (
		SELECT T.C.value('../@Id', 'SMALLINT') AS Bettype
			, T.C.value('./@p', 'TINYINT') AS Position
			, T.C.value('./@r', 'TINYINT') AS BetOption
		FROM @xmlData.nodes('/r/b/r') AS T(C)
	)
	INSERT INTO #tblTransIds (transid, BetOption)
	SELECT	b.transid, t.BetOption
	FROM	tmpData t
		CROSS APPLY(
			SELECT	TOP (@Top) b.transid
			FROM	dbo.bettrans b WITH(ROWLOCK)
			WHERE	b.matchid = @matchid
					AND b.bettype = t.bettype
					AND b.hdp1 = t.Position
					AND b.statusID NOT IN (101, 102)
		)b
	
	IF @action = 'CAL'
	BEGIN		
		UPDATE b
			SET @modds = CASE WHEN betteam > 0 AND (CAST(hdp2 AS INT) & t.betoption) > 0 THEN 1
							WHEN betteam = 0 AND (CAST(hdp2 AS INT) & (t.betoption ^ 65535)) > 0 THEN 1
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
				WHEN @modds > 0.25 THEN actual_stake + stake * (CASE WHEN odds < 0 THEN 1 ELSE (CASE WHEN bettype IN (221,222,223,224,225) THEN odds - 1 ELSE odds END) END)
				WHEN @modds = 0.25 THEN actual_stake + stake * (CASE WHEN odds < 0 THEN 1 ELSE (CASE WHEN bettype IN (221,222,223,224,225) THEN odds - 1 ELSE odds END) END) * 0.5
				WHEN @modds = 0 THEN actual_stake
				WHEN @modds = -0.25 THEN actual_stake * 0.5
				WHEN @modds < -0.25 THEN 0
			END
			, aWinLost = CASE 
				WHEN @modds > 0.25 THEN stake * (CASE WHEN odds < 0 THEN 1 ELSE (CASE WHEN bettype IN (221,222,223,224,225) THEN odds - 1 ELSE odds END) END) * -apositiontaking
				WHEN @modds = 0.25 THEN stake * (CASE WHEN odds < 0 THEN 1 ELSE (CASE WHEN bettype IN (221,222,223,224,225) THEN odds - 1 ELSE odds END) END) * -apositiontaking * 0.5
				WHEN @modds = 0 THEN 0
				WHEN @modds = -0.25 THEN actual_stake * apositiontaking * 0.5
				WHEN @modds < -0.25 THEN actual_stake * apositiontaking
			END
			, mWinLost = CASE
				WHEN @modds > 0.25 THEN stake * (CASE WHEN odds < 0 THEN 1 ELSE (CASE WHEN bettype IN (221,222,223,224,225) THEN odds - 1 ELSE odds END) END) * -mpositiontaking
				WHEN @modds = 0.25 THEN stake * (CASE WHEN odds < 0 THEN 1 ELSE (CASE WHEN bettype IN (221,222,223,224,225) THEN odds - 1 ELSE odds END) END) * -mpositiontaking * 0.5
				WHEN @modds = 0 THEN 0
				WHEN @modds = -0.25 THEN actual_stake * mpositiontaking * 0.5
				WHEN @modds < -0.25 THEN actual_stake * mpositiontaking
				END
			, sWinLost = CASE
				WHEN @modds > 0.25 THEN stake * (CASE WHEN odds < 0 THEN 1 ELSE (CASE WHEN bettype IN (221,222,223,224,225) THEN odds - 1 ELSE odds END) END) * -spositiontaking
				WHEN @modds = 0.25 THEN stake * (CASE WHEN odds < 0 THEN 1 ELSE (CASE WHEN bettype IN (221,222,223,224,225) THEN odds - 1 ELSE odds END) END) * -spositiontaking * 0.5
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
			FROM	dbo.bettrans b WITH (ROWLOCK, UPDLOCK)
				INNER JOIN #tblTransIds t
					ON b.transid = t.transid
	END
	ELSE IF @action = 'UNDO'
	BEGIN
		UPDATE	b
			SET STATUS = 'running'
				, statusID = 0
				, winlost = 0
				, awinlost = 0
				, mwinlost = 0
				, swinlost = 0
				, playercomm = 0
				, comm = 0
				, acomm = 0
				, scomm = 0
				, ruben = 0
		FROM	dbo.bettrans b WITH (ROWLOCK, UPDLOCK)
			INNER JOIN #tblTransIds t
				ON	b.transid = t.transid				
	END
	ELSE IF @action = 'REFUND'
	BEGIN
		UPDATE	b
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
		FROM	dbo.bettrans b WITH (ROWLOCK, UPDLOCK)
			INNER JOIN #tblTransIds t
				ON	b.transid = t.transid	
	END
END
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Admin_Calculate_221] TO [vnteam] AS [dbo]