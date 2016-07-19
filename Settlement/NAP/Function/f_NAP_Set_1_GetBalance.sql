USE [bodb02]
GO

ALTER FUNCTION [dbo].[f_NAP_Set_1_GetBalance] (@MatchId INT
	, @Action VARCHAR(10)
	, @Mode TINYINT)
RETURNS @MembersBalance TABLE (CustId INT, Balance MONEY)
AS
/*	Creator: 20160303@Patrick
	Task: Get balance of members
	DB: DBTXN/BODB02
	Original: NAP_Admin_Settlement_1
	
	Revisions:
		- 20160713@Patrick: PH-AIO phase 2 (67 bettypes ) [Redmine:#53154]
		
	Param's Explanation:
		@Mode: 1: Used for Auto payout process
			   2: Used for Manual settle process
 
*/
BEGIN
	
	IF @Action IN ('CAL', 'CAL-FT')
	BEGIN
		WITH BetTradeTransId AS (
			SELECT transid
			FROM dbo.bettrans b WITH(NOLOCK)
			WHERE matchid = @matchid 
				AND b.bettype NOT IN (14, 127)
				AND b.bettype NOT IN (10, 31, 32, 33, 1231, 1232, 1233, 1237, 1238) -- Outright, VSRacing
				AND b.bettype NOT BETWEEN 1501 AND 1599 -- Keno
				AND b.bettype NOT IN (SELECT BetType FROM dbo.f_Set_GetGroupBettypes() WHERE GroupId = 8)
				--(135, 160, 164, 168, 169, 173, 174, 175, 176, 180, 192, 193, 210, 211, 212, 213, 214, 215, 216, 217) -- Auto settle Betradar
				AND betdaqid = 0--bettrade tickets
		)

		INSERT INTO @MembersBalance(custid, balance)
		SELECT b.custid, SUM(b.winlost - b.actual_stake + b.playercomm) as balance
		FROM dbo.bettrans b WITH (ROWLOCK)
		WHERE b.matchid = @matchid
			AND b.bettype NOT IN (14, 127)
			AND b.bettype NOT IN (10, 31, 32, 33, 1231, 1232, 1233, 1237, 1238) -- Outright, VSRacing
			AND b.bettype NOT BETWEEN 1501 AND 1599 -- Keno
			AND b.bettype NOT BETWEEN 801 AND 899--Metric Gaming
			AND b.bettype NOT IN (SELECT BetType FROM dbo.f_Set_GetGroupBettypes() WHERE GroupId = 8)
			--(135, 160, 164, 168, 169, 173, 174, 175, 176, 180, 192, 193, 210, 211, 212, 213, 214, 215, 216, 217) -- Auto settle Betradar
			AND 1 = CASE WHEN b.bettype IN (901, 902, 903) AND b.refno IN (SELECT transid FROM BetTradeTransId) THEN 1 
						 WHEN b.bettype NOT IN (901, 902, 903) THEN 1
					ELSE 0 END
		GROUP BY b.custid

		--SET @TotalAccount = @@ROWCOUNT
	END
	ELSE IF @Action = 'CAL-HT'
	BEGIN
		WITH BetTradeTransId AS (
			SELECT transid
			FROM dbo.bettrans b WITH(NOLOCK)
			WHERE b.matchid = @matchid 
				AND EXISTS (SELECT TOP 1 1 
							FROM dbo.f_Set_GetGroupBettypes() f 
							WHERE f.GroupId IN (1, 5)
								AND f.bettype = b.bettype
								AND 1 = CASE WHEN @Mode = 2 THEN 1
											 WHEN @Mode = 1 AND f.IsUsedGoalRecordValue = 0 THEN 1
											 ELSE 0 END)
				-- IN (7, 8, 12, 15, 21, 30, 125, 126, 129, 136, 138, 143, 151, 165, 167, 179, 181, 182, 188, 191, 200, 201, 202, 203, 204, 205, 207, 209, 303, 304, 403, 404, 410, 411, 412, 414)
				--AND b.bettype NOT IN (135, 160, 164, 168, 169, 173, 174, 175, 176, 180, 192, 193, 210, 211, 212, 213, 214, 215, 216, 217)
				AND betdaqid = 0--bettrade tickets
		)

		INSERT INTO @MembersBalance
		SELECT b.custid, SUM(b.winlost - b.actual_stake + b.playercomm) as balance
		FROM dbo.bettrans b WITH (ROWLOCK)
		WHERE b.matchid = @matchid 
				AND EXISTS (SELECT TOP 1 1 
							FROM dbo.f_Set_GetGroupBettypes() f 
							WHERE f.GroupId IN (1, 5)
								AND f.bettype = b.bettype
								AND 1 = CASE WHEN @Mode = 2 THEN 1
											 WHEN @Mode = 1 AND f.IsUsedGoalRecordValue = 0 THEN 1
											 ELSE 0 END)
				-- IN (7, 8, 12, 15, 21, 30, 125, 126, 129, 136, 138, 143, 151, 165, 167, 179, 181, 182, 188, 191, 200, 201, 202, 203, 204, 205, 207, 209, 901, 902, 903, 303, 304, 403, 404, 410, 411, 412, 414)
				--AND b.bettype NOT IN (135, 160, 164, 168, 169, 173, 174, 175, 176, 180, 192, 193, 210, 211, 212, 213, 214, 215, 216, 217)
				AND 1 = CASE WHEN b.bettype IN (901, 902, 903) AND b.refno IN (SELECT transid FROM BetTradeTransId) THEN 1 
							 WHEN b.bettype NOT IN (901, 902, 903) THEN 1
						ELSE 0 END
		GROUP BY b.custid

		--SET @TotalAccount = @@ROWCOUNT
	END
	ELSE IF @Action = 'UNDO'
	BEGIN
		WITH BetTradeTransId AS (
			SELECT transid
			FROM dbo.bettrans b WITH(NOLOCK)
			WHERE b.matchid = @matchid
				AND b.bettype NOT IN (10, 31, 32, 33, 1231, 1232, 1233, 1237, 1238) -- Outright, VSRacing
				AND b.bettype NOT BETWEEN 1501 AND 1599 -- Keno
				AND b.bettype NOT IN (SELECT BetType FROM dbo.f_Set_GetGroupBettypes() WHERE GroupId = 8)
				--(135, 160, 164, 168, 169, 173, 174, 175, 176, 180, 192, 193, 210, 211, 212, 213, 214, 215, 216, 217)
				AND betdaqid = 0--bettrade tickets
		)
			
		INSERT INTO @MembersBalance
		SELECT b.custid, SUM(b.winlost - b.actual_stake + b.playercomm) as balance
		FROM dbo.bettrans b WITH (ROWLOCK)
		WHERE b.matchid = @matchid
			AND b.bettype NOT IN (10, 31, 32, 33, 1231, 1232, 1233, 1237, 1238) -- Outright, VSRacing
			AND b.bettype NOT BETWEEN 1501 AND 1599 -- Keno
			AND b.bettype NOT BETWEEN 801 AND 899--Metric Gaming
			AND b.bettype NOT IN (SELECT BetType FROM dbo.f_Set_GetGroupBettypes() WHERE GroupId = 8)
			--(135, 160, 164, 168, 169, 173, 174, 175, 176, 180, 192, 193, 210, 211, 212, 213, 214, 215, 216, 217)
			AND 1 = CASE WHEN b.bettype IN (901, 902, 903) AND b.refno IN (SELECT transid FROM BetTradeTransId) THEN 1 
						 WHEN b.bettype NOT IN (901, 902, 903) THEN 1
					ELSE 0 END
		GROUP BY b.custid
	END
	RETURN
END
GO
