CREATE PROCEDURE [NAP_Admin_Calculate_6] @matchid INT
	,@bettype SMALLINT
	,@totalgoal SMALLMONEY
	,@betcount INT = 0
AS
/*
	Created by: Kathy
	Date: 20140211
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
		- 20121031@Dan: update betteam for virtual soccer
*/
BEGIN
	IF @betcount = 0 AND @@SERVERNAME NOT LIKE N'DBIOM%' RETURN

	IF @@SERVERNAME IN ('DB04', 'DB042', 'DB043', 'DB044') RETURN

	SET NOCOUNT ON

	--- LAS settlement 
	IF @@SERVERNAME IN ('DB052', 'DB054', 'DB231')
	BEGIN
		DECLARE @LASCommand NVARCHAR(1000)
			,@createdDate DATETIME

		SELECT @LASCommand = 'EXEC [dbo].[Admin_Calculate_6] @matchid = ' + CONVERT(NVARCHAR(10), @matchid) + ', @bettype = ' + CONVERT(NVARCHAR(10), @bettype) + ', @totalgoal = ' + CONVERT(NVARCHAR(10), @totalgoal) + ', @betcount = ' + CONVERT(NVARCHAR(10), ISNULL(@betcount, ''))
			,@createdDate = GETDATE()

		EXEC LASDB.[dbo].[Las_GeneratingSettlementCommand] @SPName = 'Admin_Calculate_6'
			,@SQLCommand = @LASCommand
			,@CreatedDate = @createdDate
			,@StatusID = 0 -- waiting
			,@MatchID = @matchid
			,@Bettype = @bettype
			,@Status = 'waiting'
			,@BetCount = @betcount
	END

	DECLARE @modds SMALLMONEY
		,@commWinRate SMALLMONEY
		,@commLostRate SMALLMONEY

	UPDATE bettrans WITH (ROWLOCK, UPDLOCK)
	SET @modds = modds = CASE 
			WHEN bettype = 1206 AND betteam = cast(cast(@totalgoal AS TINYINT) AS VARCHAR(5)) THEN 1
			WHEN betteam = '0-1' AND @totalgoal <= 1 THEN 1
			WHEN betteam = '2-3' AND @totalgoal IN (2, 3) THEN 1
			WHEN betteam = '4-6' AND @totalgoal IN (4, 5, 6) THEN 1
			WHEN betteam = '7-over' AND @totalgoal >= 7 THEN 1
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
			WHEN @modds > 0.25 THEN actual_stake + stake * (CASE 
					WHEN odds < 0 THEN 1
					ELSE (CASE 
							WHEN bettype IN (4, 5, 6, 1206) THEN odds - 1
							ELSE odds END
							) END
					)
			WHEN @modds = 0.25 THEN actual_stake + stake * (CASE 
					WHEN odds < 0 THEN 1
					ELSE (CASE 
							WHEN bettype IN (4, 5, 6, 1206) THEN odds - 1
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
							WHEN bettype IN (4, 5, 6, 1206) THEN odds - 1
							ELSE odds END
							) END
					) * - apositiontaking
			WHEN @modds = 0.25 THEN stake * (CASE 
					WHEN odds < 0 THEN 1
					ELSE (CASE 
							WHEN bettype IN (4, 5, 6, 1206) THEN odds - 1
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
							WHEN bettype IN (4, 5, 6, 1206) THEN odds - 1
							ELSE odds END
							) END
					) * - mpositiontaking
			WHEN @modds = 0.25 THEN stake * (CASE 
					WHEN odds < 0 THEN 1
					ELSE (CASE 
							WHEN bettype IN (4, 5, 6, 1206) THEN odds - 1
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
							WHEN bettype IN (4, 5, 6, 1206) THEN odds - 1
							ELSE odds END
							) END
					) * - spositiontaking
			WHEN @modds = 0.25 THEN stake * (CASE 
					WHEN odds < 0 THEN 1
					ELSE (CASE 
							WHEN bettype IN (4, 5, 6, 1206) THEN odds - 1
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
		--status NOT IN ('VOID', 'REJECT')
		statusID NOT IN (101, 102)
END

GO

GRANT VIEW DEFINITION ON [NAP_Admin_Calculate_6] TO [vnteam] AS [dbo]
GO


