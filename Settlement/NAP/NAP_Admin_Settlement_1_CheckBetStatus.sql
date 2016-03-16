USE [bodb02]
GO
ALTER PROCEDURE [dbo].[NAP_Admin_Settlement_1_CheckBetStatus] @MatchId INT
	, @HTDone BIT = 0 OUTPUT
	, @FTDone BIT = 0 OUTPUT
AS
/*	Creator: 20160303@Patrick
	Task: Select status of bet ticket
	DB: DBTXN/BODB02
	Original: NAP_Admin_Settlement_1
	
	Revisions:
		
	Param's Explanation:
 
*/
BEGIN
	DECLARE @BetStatus TABLE (FTBet BIT, InRunning INT)
	DECLARE @HalfTimeBetTypeIds VARCHAR(1024)

	SELECT @HalfTimeBetTypeIds = COALESCE(@HalfTimeBetTypeIds + ',' + CAST(bettype AS NVARCHAR), CAST(bettype AS NVARCHAR))
	FROM dbo.f_GetHalfTimeBetType() f

	SELECT @HalfTimeBetTypeIds = ',' + @HalfTimeBetTypeIds + ','

	SELECT CASE WHEN CHARINDEX(',' + CAST(b.bettype AS VARCHAR) + ',', @HalfTimeBetTypeIds) > 0 THEN 0 ELSE 1 END
		, SUM(CASE WHEN b.statusID IN (101, 102) THEN 0 ELSE 1 END)
		, SUM(CASE WHEN b.statusID = 0 THEN 1 ELSE 0 END)
	FROM dbo.bettrans b WITH(NOLOCK)
	WHERE b.matchid = @MatchId
		AND b.bettype NOT IN (10, 31, 32, 33, 1231, 1232, 1233, 1237, 1238) -- Outright, VSRacing
		AND b.bettype NOT BETWEEN 1501 AND 1599 -- Keno
		AND b.bettype NOT BETWEEN 801 AND 899--Metric Gaming
		AND b.bettype NOT IN (135, 160, 164, 168, 169, 173, 174, 175, 176, 180, 192, 193, 210, 211, 212, 213, 214, 215, 216, 217) --Auto settle Betradar
	GROUP BY CASE WHEN CHARINDEX(',' + CAST(b.bettype AS VARCHAR) + ',', @HalfTimeBetTypeIds) > 0 THEN 0 ELSE 1 END

	IF NOT EXISTS (SELECT 1 FROM @BetStatus WHERE FTBet = 0)
		INSERT INTO @BetStatus VALUES (0, 0)

	IF NOT EXISTS (SELECT 1 FROM @BetStatus WHERE FTBet = 1)
		INSERT INTO @BetStatus VALUES (1, 0)

	SELECT @HTDone = CASE InRunning WHEN 0 THEN 1 ELSE 0 END
	FROM @BetStatus
	WHERE FTBet = 0

	SELECT @FTDone = CASE InRunning WHEN 0 THEN 1 ELSE 0 END
	FROM @BetStatus
	WHERE FTBet = 1

END
GO
