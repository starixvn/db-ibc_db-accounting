USE [bodb02]
GO
ALTER PROCEDURE [dbo].[NAP_Set_MatchSelCompletedHT] @Date DATETIME
	, @SportType SMALLINT = 0
	, @LeagueID INT = 0 -- 0 for ALL Leagues
	, @isReLoad BIT = 0
	, @IsManualSettlementOnly BIT = 0
AS
/*
	Created by: Kathy
	Date: 
	Task: List HT-completed matches for billing
	DB: DBTRANS.BODB02
	Original: Acc_Set_MatchSelCompletedHT
	
	Revisions:
		- 20140421@Kathy: get match status in queue
		- 20140428@Kathy: get 1H FGLG ticket info [Redmine:#14449]
		- 20140905@Kathy: exclude virtual racing bettype 1231,1232,1233
		- 20140909@Kathy: Exclude virtual racing (bettype 1231,1232,1233, 1237, 1238), outright (bettype 10, 31, 32, 33),
						 sportting solution (from 1301 -> 1334), keno (1501 -> 1599)
		- 20150422@Jamie: Manual Settlement Betradar phase 2 [Redmine: #27212]
		- 20150602@Jamie: DisplayCat = 8 ExtraTime 
		- 20150611@Jamie: Remove the contrainst  DisplayCat = 8 ExtraTime  
		- 20150811@Johnson: Exclude bettrade tickets from Sportbook [Redmine: #35921]
		- 20150729@Johnson: Exclude range bettype of Metric Gaming from settlement of SB [Redmine: #37688]
		- 20151210@Patrick: Database - Change datatype [Redmine: #48660]
		- 20160314@Patrick: Add more filter to support auto-payout [Redmine: #53262]
*/
BEGIN
	SET NOCOUNT ON

	IF @sporttype NOT IN (1, 2, 3, 32) RETURN

	DECLARE @HTOverStartMins INT, @HTOverEndMins INT, @Today DATETIME

	SELECT @LeagueID = CASE WHEN @isReLoad = 1 THEN ISNULL(@LeagueID, 0) 
						ELSE 0	END -- reload partial; search on LeagueID, not reload: get all leagues
		, @Today = GETDATE()
		, @HTOverStartMins = CASE WHEN @sporttype = 1 THEN 40 ELSE 25 END
		, @HTOverEndMins = CASE WHEN @sporttype = 1 THEN 100 ELSE 60 END

	DECLARE @tblSingle TABLE (matchid INT, seqS INT)
	DECLARE @MatchIds TABLE(MatchId INT, IsAutoPayout BIT, LeagueId INT)

	INSERT INTO @tblSingle
	SELECT matchid, MAX(IsCalculating)
	FROM dbo.Single_Calculate_Queue WITH (NOLOCK)
	WHERE Starttime > DATEADD(HH, - 1, GETDATE())
		AND IsCalculating IN (1, 0)
	GROUP BY matchid

	;WITH MatchTmp AS (
		SELECT m.matchid, m.IsAutoPayout, leagueid
	FROM DBPRO.BODB02.dbo.match m WITH (NOLOCK)
		INNER JOIN DBPRO.BODB02.dbo.match_remark mr WITH (NOLOCK) ON m.matchid = mr.matchid
	WHERE m.eventdate = @Date
		AND m.leagueID = CASE WHEN @LeagueID <> 0 THEN @LeagueID ELSE m.leagueID END 
		AND m.sporttype = @sporttype 
		AND m.eventstatus IN ('Closed', 'running', 'internal')
		AND ((DATEDIFF(MINUTE, m.kickofftime, @Today) > @HTOverStartMins 
					AND DATEDIFF(MINUTE, m.kickofftime, @Today) < @HTOverEndMins) 
				OR mr.confirmHT <> 0)
		AND mr.ishtcal = 0
	), LeagueTmp AS (
		SELECT leagueid, IsAutoPayout
		FROM DBPRO.BODB02.dbo.league l WITH (NOLOCK)
		WHERE EXISTS (SELECT TOP 1 1 FROM MatchTmp m WHERE l.leagueid = m.leagueid)
	)

	INSERT INTO @MatchIds(MatchId, IsAutoPayout)
	SELECT m.matchid
		, CASE WHEN m.IsAutoPayout IS NULL THEN ISNULL(l.IsAutoPayout, 0)
				WHEN ISNULL(m.IsAutoPayout, 0) = 1 THEN 1
			ELSE 0 END AS IsAutoPayout
	FROM MatchTmp m
		INNER JOIN LeagueTmp l ON m.leagueid = l.leagueid
	WHERE 1 = CASE WHEN @IsManualSettlementOnly = 0 THEN 1
				ELSE CASE WHEN m.IsAutoPayout IS NULL AND ISNULL(l.IsAutoPayout, 0) = 1 THEN 0
							WHEN ISNULL(m.IsAutoPayout, 0) = 1 THEN 0
						ELSE 1 END
				END

	;WITH BetStatus AS (
		SELECT b.matchid
			, COUNT(b.matchid) betcount
			, SUM(CASE WHEN bettype = 14 THEN 1 ELSE 0 END) AS cntFGLG
			, SUM(CASE WHEN bettype = 127 THEN 1 ELSE 0 END) AS cntHTFGLG
		FROM dbo.bettrans b WITH (NOLOCK, INDEX = CIX_matchid_bettype)
		WHERE EXISTS (SELECT TOP 1 1 FROM @MatchIds m WHERE b.matchid = m.MatchId)
			AND bettype <= 19000
			AND bettype NOT IN (10, 31, 32, 33, 1231, 1232, 1233, 1237, 1238)
			AND bettype NOT BETWEEN 1301 AND 1334 -- exclude sporting solution product
			AND bettype NOT BETWEEN 1501 and 1599 -- Keno
			AND bettype NOT IN (901,902,903)--bettrade
			AND bettype NOT BETWEEN 801 AND 899--Metric Gaming
		GROUP BY b.matchid
	)
	
	SELECT m.matchid
		, m.leagueid
		, hthomescore AS HalfTimeHomeScore
		, htawayscore AS HalfTimeAwayScore
		, ISNULL(mr.calculate, 0) IsCalculated
		, ISNULL(mr.multiple, 0) IsMultiCaled
		, ISNULL(mr.refund, 0) IsRefund
		, ISNULL(mr.calrefund, 0) IsCalRefund
		, m.homeid
		, m.awayid
		, m.matchcode
		, m.kickofftime
		, m.finalhomescore
		, m.finalawayscore
		, m.betstatus
		, CASE WHEN m.betstatus LIKE 'Refund FT%' THEN 'Refund FT'
				WHEN m.betstatus LIKE 'Refund HT%' THEN 'Refund HT'
				WHEN m.betstatus LIKE 'Refund%' THEN 'Refund'
			ELSE m.eventstatus END AS eventstatus
		, '' AS Foddsstatus
		, m.sporttype
		, ISNULL(m.isNeutral, CONVERT(BIT, 0)) AS IsNeutral
		, m.eventdate
		, m.goalrecord
		, CASE mr.ConfirmHT
			WHEN 0 THEN ''
			ELSE (SELECT username
					FROM CustDB.dbo.custinfo (NOLOCK)
					WHERE custid = mr.ConfirmHT) END AS suspenderHalfTime
		, '' AS suspenderFullTime
		, ISNULL(mr.IsHTCal, 0) AS IsHalfTimeCal
		, ISNULL(mr.isPending, 0) AS isPending
		, ISNULL(mr.isUndecided, 0) AS isUndecided
		, CAST(CASE WHEN hthomescore IS NOT NULL 
						AND htawayscore IS NOT NULL 
						AND finalhomescore IS NOT NULL 
						AND finalawayscore IS NOT NULL THEN 1
				ELSE 0 END AS BIT) AS IsKeyscore
		, b.betcount
		, CASE WHEN b.cntFGLG = 0 THEN 0 ELSE 1 END AS isExistFGLG
		, CASE WHEN b.cntHTFGLG = 0 THEN 0 ELSE 1 END AS isExistHTFGLG
		, t.seqS AS IsCalculatingSingle
		, mm.IsAutoPayout
		FROM DBPRO.BODB02.dbo.match m WITH (NOLOCK)
			INNER JOIN @MatchIds mm ON m.leagueid = mm.leagueid
			INNER JOIN DBPRO.BODB02.dbo.match_remark mr WITH (NOLOCK) ON m.matchid = mr.matchid
			INNER JOIN BetStatus b ON m.matchid = b.matchid
			LEFT JOIN @tblSingle t ON m.matchid = t.matchid
	ORDER BY eventstatus, matchcode
END

GO
GRANT EXECUTE ON [dbo].[NAP_Set_MatchSelCompletedHT] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Set_MatchSelCompletedHT] TO [vnteam] AS [dbo]

