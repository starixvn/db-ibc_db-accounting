USE [bodb02]
GO
ALTER PROCEDURE [dbo].[NAP_Admin_Calculate_25] @matchid INT
	,@bettype SMALLINT
	,@scorediff SMALLMONEY
	,@isRefundHT BIT = 0
	,@betcount INT = 0
AS
/*
	Created by: Kathy
	Date:20140211
	Task: Settlement 
	DB: DBTRANS.BODB02
	
	Revisions:
		- 20150415@Jamie: Settlement Betradar phase 2 [Redmine: #27212]
		- 20151125@Patrick: Apply 28 Live Bettypes for Settlement [Redmine:#47843]
		- 20151209@Patrick: Database - Change datatype [Redmine: #48660]
*/
BEGIN
	IF @betcount = 0 AND @@SERVERNAME NOT LIKE N'DBIOM%' RETURN

	IF @@SERVERNAME IN ('DB04', 'DB042', 'DB043', 'DB044') RETURN

	SET NOCOUNT ON

	--- LAS settlement 
	IF @@SERVERNAME IN ('DB052', 'DB054', 'DB231', 'DB232','DB215') AND EXISTS (
			SELECT *
			FROM sys.databases
			WHERE NAME = 'LASDB'
			)
	BEGIN
		DECLARE @LASCommand NVARCHAR(1000)
			,@createdDate DATETIME

		SELECT @LASCommand = 'EXEC [dbo].[Admin_Calculate_25] @matchid = ' + CONVERT(NVARCHAR(10), @matchid) + ', @bettype = ' + CONVERT(NVARCHAR(10), @bettype) + ', @scorediff = ' + CONVERT(NVARCHAR(10), @scorediff) + ', @betcount = ' + CONVERT(NVARCHAR(10), ISNULL(@betcount, ''))
			,@createdDate = GETDATE()

		EXEC LASDB.[dbo].[Las_GeneratingSettlementCommand] @SPName = 'Admin_Calculate_25'
			,@SQLCommand = @LASCommand
			,@CreatedDate = @createdDate
			,@StatusID = 0 -- waiting
			,@MatchID = @matchid
			,@Bettype = @bettype
			,@Status = 'waiting'
			,@BetCount = @betcount
	END

	DECLARE @modds MONEY
		,@commWinRate SMALLMONEY
		,@commLostRate SMALLMONEY

	UPDATE bettrans WITH (ROWLOCK, UPDLOCK)
	SET @modds = CASE 
			-- draw no bet
			WHEN bettype IN (25,185,191,411) AND @scorediff = 0 THEN 0
			WHEN bettype IN (25,185,191,411) AND betteam = 'h' AND @scorediff > 0 THEN 1
			WHEN bettype IN (25,185,191,411) AND betteam = 'a' AND @scorediff < 0 THEN 1
				-- home no bet
			WHEN bettype = 121 AND @scorediff > 0 THEN 0
			WHEN bettype = 121 AND betteam = 'x' AND @scorediff = 0 THEN 1
			WHEN bettype = 121 AND betteam = 'a' AND @scorediff < 0 THEN 1
				-- away no bet
			WHEN bettype = 122 AND @scorediff < 0 THEN 0
			WHEN bettype = 122 AND betteam = 'h' AND @scorediff > 0 THEN 1
			WHEN bettype = 122 AND betteam = 'x' AND @scorediff = 0 THEN 1
				-- draw/no draw		
			WHEN bettype = 123 AND betteam = 'h' AND @scorediff = 0 THEN 1
			WHEN bettype = 123 AND betteam = 'a' AND @scorediff <> 0 THEN 1
			ELSE - 1
			END
		,modds = @modds
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
							WHEN bettype IN (4, 5, 6, 13, 15, 16, 24, 25, 26, 27, 28, 121, 122, 123,185,191,411) THEN odds - 1
							ELSE odds END
							) END
					)
			WHEN @modds = 0.25 THEN actual_stake + stake * (CASE 
					WHEN odds < 0 THEN 1
					ELSE (CASE 
							WHEN bettype IN (4, 5, 6, 13, 15, 16, 24, 25, 26, 27, 28, 121, 122, 123,185,191,411) THEN odds - 1
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
							WHEN bettype IN (4, 5, 6, 13, 15, 16, 24, 25, 26, 27, 28, 121, 122, 123,185,191,411) THEN odds - 1
							ELSE odds END
							) END
					) * - apositiontaking
			WHEN @modds = 0.25 THEN stake * (CASE 
					WHEN odds < 0 THEN 1
					ELSE (CASE 
							WHEN bettype IN (4, 5, 6, 13, 15, 16, 24, 25, 26, 27, 28, 121, 122, 123,185,191,411) THEN odds - 1
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
							WHEN bettype IN (4, 5, 6, 13, 15, 16, 24, 25, 26, 27, 28, 121, 122, 123,185,191,411) THEN odds - 1
							ELSE odds END
							) END
					) * - mpositiontaking
			WHEN @modds = 0.25 THEN stake * (CASE 
					WHEN odds < 0 THEN 1
					ELSE (CASE 
							WHEN bettype IN (4, 5, 6, 13, 15, 16, 24, 25, 26, 27, 28, 121, 122, 123,185,191,411) THEN odds - 1
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
							WHEN bettype IN (4, 5, 6, 13, 15, 16, 24, 25, 26, 27, 28, 121, 122, 123,185,191,411) THEN odds - 1
							ELSE odds END
							) END
					) * - spositiontaking
			WHEN @modds = 0.25 THEN stake * (CASE 
					WHEN odds < 0 THEN 1
					ELSE (CASE 
							WHEN bettype IN (4, 5, 6, 13, 15, 16, 24, 25, 26, 27, 28, 121, 122, 123,185,191,411) THEN odds - 1
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
		AND 1 = CASE WHEN @bettype = 185 and @isRefundHT = 1 THEN 0 ELSE 1 END
END
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Admin_Calculate_25] TO [vnteam] AS [dbo]