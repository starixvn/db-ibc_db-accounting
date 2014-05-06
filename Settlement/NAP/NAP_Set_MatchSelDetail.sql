ALTER PROCEDURE [NAP_Set_MatchSelDetail] @matchid INT
	,@excludeRefundFGLG BIT = 0
AS
/*
	Created by: 20120913
	Task: Update score 
	DB: DBTRANS.BODB02 
	Original: [Acc_Set_MatchSelScore], Acc_Set_MatchSelForBill
	
	Revisions:			
		- 20140304@Kathy: Execute settlement for abandoned/postponed matches- Clean Sheet, Both/One/Neither team to score, To Win To Nil 
		- 20140423@Kathy: Remove check weekend peak-hour

*/
BEGIN
	SET NOCOUNT ON

	DECLARE @IsExistFGLG BIT
		,@IsExistLG BIT
		,@IsHTOnly BIT
		,@IsLive BIT
		,@IsSettleAbandonedMatchIBC BIT
		,@sporttype TINYINT

	SELECT @IsExistLG = 0
		,@IsExistFGLG = 0
		,@IsHTOnly = 0
		,@IsLive = 0
		,@IsSettleAbandonedMatchIBC = 0

	SELECT @sporttype = sporttype
	FROM match WITH (NOLOCK)
	WHERE matchid = @matchid

	IF @excludeRefundFGLG = 0
	BEGIN
		IF EXISTS (
				SELECT TOP 1 1
				FROM bettrans WITH (NOLOCK)
				WHERE matchid = @matchid AND bettype = 14 AND right(BETTEAM, 1) = '2' AND statusID NOT IN (101, 102)
				)
			SELECT @IsExistLG = 1
		ELSE IF EXISTS (
				SELECT TOP 1 1
				FROM bettransm WITH (NOLOCK)
				WHERE matchid = @matchid AND bettype = 14 AND right(BETTEAM, 1) = '2' AND statusID NOT IN (101, 102)
				)
			SELECT @IsExistLG = 1

		IF (@IsExistLG = 0)
		BEGIN
			IF EXISTS (
					SELECT TOP 1 1
					FROM bettrans WITH (NOLOCK)
					WHERE matchid = @matchid AND bettype = 14 AND statusID NOT IN (101, 102)
					)
				SELECT @IsExistFGLG = 1
			ELSE IF EXISTS (
					SELECT TOP 1 1
					FROM bettransm WITH (NOLOCK)
					WHERE matchid = @matchid AND bettype = 14 AND statusID NOT IN (101, 102)
					)
				SELECT @IsExistFGLG = 1
		END
		ELSE
			SELECT @IsExistFGLG = 1
	END
	ELSE
	BEGIN
		IF EXISTS (
				SELECT TOP 1 1
				FROM bettrans WITH (NOLOCK)
				WHERE matchid = @matchid AND bettype = 14 AND right(BETTEAM, 1) = '2' AND statusID NOT IN (101, 102, 103)
				)
			SELECT @IsExistLG = 1
		ELSE IF EXISTS (
				SELECT TOP 1 1
				FROM bettransm WITH (NOLOCK)
				WHERE matchid = @matchid AND bettype = 14 AND right(BETTEAM, 1) = '2' AND statusID NOT IN (101, 102, 103)
				)
			SELECT @IsExistLG = 1

		IF (@IsExistLG = 0)
		BEGIN
			IF EXISTS (
					SELECT TOP 1 1
					FROM bettrans WITH (NOLOCK)
					WHERE matchid = @matchid AND bettype = 14 AND statusID NOT IN (101, 102, 103)
					)
				SELECT @IsExistFGLG = 1
			ELSE IF EXISTS (
					SELECT TOP 1 1
					FROM bettransm WITH (NOLOCK)
					WHERE matchid = @matchid AND bettype = 14 AND statusID NOT IN (101, 102, 103)
					)
				SELECT @IsExistFGLG = 1
		END
		ELSE
			SELECT @IsExistFGLG = 1
	END

	IF (
			EXISTS (
				--HT Soccer
				SELECT 1
				FROM DBPRO.BODB02.dbo.match m WITH (NOLOCK)
					INNER JOIN DBPRO.BODB02.dbo.match_remark mr WITH (NOLOCK) ON m.matchid = mr.matchid
				WHERE m.matchid = @matchid AND sporttype = 1 AND datediff(minute, kickofftime, CURRENT_TIMESTAMP) < 100 AND (datediff(minute, kickofftime, CURRENT_TIMESTAMP) > 45 OR isnull(ConfirmHT, 0) > 0) AND isnull(ConfirmFT, 0) = 0
				)
			)
	BEGIN
		SELECT @IsHTOnly = 1
	END

	IF (
			EXISTS (
				SELECT 1
				FROM bettrans WITH (NOLOCK)
				WHERE bettype IN (13, 26, 27) AND matchid = @matchid AND statusID NOT IN (101, 102, 103) AND ruben = 0 AND (custid NOT IN (50057, 879241, 103873, 78761, 851668, 878902, 2331, 1077687, 115770) AND recommend <> 1688156)
				) AND @sporttype = 1
			)
	BEGIN
		SELECT @IsSettleAbandonedMatchIBC = 1

		IF EXISTS (
				SELECT 1
				FROM bettrans WITH (NOLOCK)
				WHERE matchid = @matchid AND bettype IN (13, 26, 27) AND statusID NOT IN (101, 102) AND ruben = 1 AND (custid NOT IN (50057, 879241, 103873, 78761, 851668, 878902, 2331, 1077687, 115770) AND recommend <> 1688156)
				) OR @sporttype <> 1
		BEGIN
			SELECT @IsSettleAbandonedMatchIBC = 0
		END
	END

	DECLARE @status TABLE (
		[Group] TINYINT
		,BetCount INT
		,InRunning INT
		)

	INSERT INTO @status
	SELECT CASE -- 0:FT , 1:HT , 2:FGLG
			WHEN bettype IN (7, 8, 12, 15, 21, 30, 125) THEN 1
			WHEN bettype = 14 THEN 2
			ELSE 0
			END
		,
		--SUM(CASE WHEN [status] IN (N'VOID',N'REJECT') THEN 0 ELSE 1 END),
		SUM(CASE 
				WHEN [statusID] IN (101, 102) THEN 0
				ELSE 1
				END)
		,
		--SUM(CASE WHEN [status] = N'running' THEN 1 ELSE 0 END)
		SUM(CASE 
				WHEN [statusID] = 0 THEN 1
				ELSE 0
				END)
	FROM bettrans WITH (NOLOCK)
	WHERE matchid = @matchid AND bettype NOT BETWEEN 1301 AND 1334
	GROUP BY CASE 
			WHEN bettype IN (7, 8, 12, 15, 21, 30, 125) THEN 1
			WHEN bettype = 14 THEN 2
			ELSE 0
			END

	IF NOT EXISTS (
			SELECT *
			FROM @status
			WHERE [Group] = 0
			)
		INSERT INTO @status
		VALUES (
			0
			,0
			,0
			)

	IF NOT EXISTS (
			SELECT *
			FROM @status
			WHERE [Group] = 1
			)
		INSERT INTO @status
		VALUES (
			1
			,0
			,0
			)

	IF NOT EXISTS (
			SELECT *
			FROM @status
			WHERE [Group] = 2
			)
		INSERT INTO @status
		VALUES (
			2
			,0
			,0
			)

	DECLARE @FTStatus NVARCHAR(10)
		,@HTStatus NVARCHAR(10)
		,@FGLGStatus NVARCHAR(10)

	SELECT @FTStatus = CASE 
			WHEN betcount = 0 THEN N'No Ticket'
			WHEN inRunning = 0 THEN N'Calculated'
			ELSE N'Running'
			END
	FROM @status
	WHERE [Group] = 0

	SELECT @HTStatus = CASE 
			WHEN betcount = 0 THEN N'No Ticket'
			WHEN inRunning = 0 THEN N'Calculated'
			ELSE N'Running'
			END
	FROM @status
	WHERE [Group] = 1

	SELECT @FGLGStatus = CASE 
			WHEN betcount = 0 THEN N'No Ticket'
			WHEN inRunning = 0 THEN N'Calculated'
			ELSE N'Running'
			END
	FROM @status
	WHERE [Group] = 2

	IF EXISTS (
			SELECT TOP 1 1
			FROM bettrans(NOLOCK)
			WHERE matchid = @matchid AND liveindicator = 1
			)
		SELECT @IsLive = 1

	SELECT match.sporttype
		,match.betstatus
		,hthomescore AS HalfTimeHomeScore
		,htawayscore AS HalfTimeAwayScore
		,datediff(minute, kickofftime, CURRENT_TIMESTAMP) playtime
		,match.leagueid
		,match.matchid
		,match.homeid
		,match.awayid
		,match.matchcode
		,match.kickofftime
		,match.finalhomescore
		,match.finalawayscore
		,match.eventstatus
		,isnull(mr.refund, 0) IsRefund
		,isnull(mr.calrefund, 0) IsCalRefund
		,isnull(mr.calculate, 0) IsCalculated
		,isnull(mr.multiple, 0) IsMultiCaled
		,isnull(match.isNeutral, CONVERT(BIT, 0)) AS IsNeutral
		,mr.ishtcal AS IsHalfTimeCal
		,match.GoalRecord
		,mr.ConfirmHT
		,mr.ConfirmFT
		,@HTStatus HTStatus
		,@FTStatus FTStatus
		,@FGLGStatus fglgstatus
		,@IsExistFGLG AS IsExistFGLG
		,@IsExistLG AS IsExistLG
		,@IsHTOnly AS IsHTOnly
		,@IsLive AS IsLive
		,@IsSettleAbandonedMatchIBC IsSettleAbandonedMatchIBC
	FROM DBPRO.BODB02.dbo.match WITH (NOLOCK)
		LEFT OUTER JOIN DBPRO.BODB02.dbo.match_remark mr WITH (NOLOCK) ON match.matchid = mr.matchid
	WHERE match.matchid = @matchid
END

GO

GRANT EXECUTE ON [NAP_Set_MatchSelDetail] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [NAP_Set_MatchSelDetail] TO [vnteam] AS [dbo]
GO


