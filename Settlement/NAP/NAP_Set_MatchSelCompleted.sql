USE [bodb02]
GO
ALTER PROCEDURE [dbo].[NAP_Set_MatchSelCompleted] @Date DATETIME
	, @SportType SMALLINT = 0
	, @LeagueID INT = 0-- 0 for ALL Leagues   
	, @isReLoad BIT = 0
	, @IsManualSettlementOnly BIT = 0
AS
/*
	Created by: Kathy
	Date: 
	Task: List FT-completed matches for billing
	DB: DBTRANS.BODB02
	Original: Acc_Set_MatchSelCompleted

	Revisions:
		- 20140421@Kathy: get match status in queue
		- 20140428@Kathy: get 1H FGLG ticket info [Redmine:#14449]
		- 20140701@Viet: change goalrecord to varchar(50), matchcode to nvarchar(50)
		- 20140905@Kathy: exclude virtual racing bettype 1231,1232,1233
		- 20140907@Viet: change back left join to inner join
		- 20140909@Kathy: Exclude virtual racing (bettype 1231,1232,1233, 1237, 1238), outright (bettype 10, 31, 32, 33),
						 sportting solution (from 1301 -> 1334), keno (1501 -> 1599)
		- 20141008@Jamie: Sportting Solution settlement [Redmine: #23034]
		- 20150422@Jamie: Manual Settlement Betradar phase 2 [Redmine: #27212
		- 20150602@Jamie: DisplayCat = 8 ExtraTime 
		- 20150611@Jamie: Remove the contrainst  DisplayCat = 8 ExtraTime 
		- 20150811@Johnson: Exclude bettrade tickets from sportbook [Redmine: 35921]
		- 20150729@Johnson: Exclude Metric Gaming in settlement's sportbook [Redmine: #37688]
		- 20151210@Patrick: Database - Change datatype [Redmine: #48660]
		- 20160201@Kathy: Exclude tickets of Charge Commission (bettypeid=500) [Redmine:#49727]
		- 20160314@Patrick: Add more filter to support auto-payout

	Param explanation: 
		@isReLoad: 1: reload partial matches of a league, 0: not reload
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @Today DATETIME
	SELECT @LeagueID = CASE WHEN @isReLoad = 1 THEN ISNULL(@LeagueID, 0)
						ELSE 0 END -- reload partial; search on LeagueID, not reload: get all leagues
		, @Today = GETDATE()

	DECLARE @MatchIds TABLE(MatchId INT, IsAutoPayout BIT)

	;WITH MatchTmp AS (
		SELECT m.matchid, m.IsAutoPayout, leagueid
	FROM DBPRO.BODB02.dbo.match m WITH (NOLOCK)
		INNER JOIN DBPRO.BODB02.dbo.match_remark mr WITH (NOLOCK) ON m.matchid = mr.matchid
	WHERE m.eventdate = @Date
		AND m.leagueID = CASE WHEN @LeagueID <> 0 THEN @LeagueID ELSE m.leagueID END
		AND m.sporttype = CASE WHEN @sporttype = 0 THEN m.sporttype	ELSE @sporttype	END 
		AND m.eventstatus <> N'Completed' 
		AND (m.kickofftime < DATEADD(s, - 6000, @Today) OR mr.ConfirmFT > 0)
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

	DECLARE @tblSingle TABLE (matchid INT, seqS INT)
	INSERT INTO @tblSingle
	SELECT matchid, MAX(IsCalculating)
	FROM dbo.Single_Calculate_Queue WITH (NOLOCK)
	WHERE Starttime > DATEADD(HH, - 1, GETDATE()) 
		AND IsCalculating IN (1, 0)
	GROUP BY matchid

	;WITH BetStatus AS (
		SELECT b.matchid
			, COUNT(b.matchid) AS BetCount
			, SUM(CASE WHEN bettype = 14 THEN 1	ELSE 0 END) AS cntFGLG
			, SUM(CASE WHEN bettype = 127 THEN 1 ELSE 0 END) AS cntHTFGLG
		FROM dbo.bettrans b WITH (NOLOCK, INDEX = CIX_matchid_bettype)
		WHERE EXISTS (SELECT TOP 1 1 FROM @MatchIds m WHERE b.matchid = m.MatchId) 
			AND b.bettype NOT IN (10, 31, 32, 33, 1231, 1232, 1233, 1237, 1238)
			AND bettype NOT BETWEEN 1501 and 1599 -- Keno
			AND bettype NOT IN (901,902,903)
			AND b.bettype <> 500 -- Charged commission
			AND bettype NOT BETWEEN 801 AND 899--Metric Gaming
			AND winlostdate = @Date
		GROUP BY b.matchid
	)
	SELECT m.matchid
		, m.leagueid
		, hthomescore AS HalfTimeHomeScore
		, htawayscore AS HalfTimeAwayScore
		, ISNULL(mr.calculate, 0) AS IsCalculated
		, ISNULL(mr.multiple, 0) AS IsMultiCaled
		, ISNULL(mr.refund, 0) AS IsRefund
		, ISNULL(mr.calrefund, 0) AS IsCalRefund
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
			ELSE m.eventstatus	END AS eventstatus
		, '' AS Foddsstatus
		, m.sporttype
		, ISNULL(m.isNeutral, CONVERT(BIT, 0)) AS IsNeutral
		, m.eventdate
		, m.goalrecord
		--, CASE WHEN mr.ConfirmHT = 0 THEN ''
		--	ELSE (SELECT username
		--			FROM CustDB.dbo.custinfo (NOLOCK)
		--			WHERE custid = mr.ConfirmHT) END AS suspenderHalfTime
		--, CASE WHEN mr.ConfirmFT = 0 THEN ''
		--	ELSE (SELECT username
		--			FROM CustDB.dbo.custinfo (NOLOCK)
		--			WHERE custid = mr.ConfirmFT) END AS suspenderFullTime
		, ISNULL(ht.username, '') AS suspenderHalfTime
		, ISNULL(ft.username, '') AS suspenderFullTime
		, ISNULL(mr.IsHTCal, 0) AS IsHalfTimeCal
		, ISNULL(mr.IsPending, 0) AS IsPending
		, ISNULL(mr.isUndecided, 0) AS isUndecided
		, CAST(CASE WHEN hthomescore IS NOT NULL 
						AND htawayscore IS NOT NULL 
						AND finalhomescore IS NOT NULL 
						AND finalawayscore IS NOT NULL THEN 1
				ELSE 0 END AS BIT) AS IsKeyscore
		--, ISNULL(tm.calculate, 0) AS calculate
		, CASE WHEN b.cntFGLG = 0 THEN 0 ELSE 1 END AS isExistFGLG
		, CASE WHEN b.cntHTFGLG = 0 THEN 0 ELSE 1 END AS isExistHTFGLG
		, b.BetCount
		, t.seqS AS IsCalculatingSingle
		, mm.IsAutoPayout
	FROM DBPRO.BODB02.dbo.match m WITH (NOLOCK)
		INNER JOIN @MatchIds mm ON m.matchid = mm.MatchId
		INNER JOIN DBPRO.BODB02.dbo.match_remark mr WITH (NOLOCK) ON m.matchid = mr.matchid
		INNER JOIN BetStatus b ON m.matchid = b.matchid
		LEFT JOIN CustDB.dbo.custinfo ht WITH (NOLOCK) ON mr.ConfirmHT > 0 AND mr.ConfirmHT = ht.custid
		LEFT JOIN CustDB.dbo.custinfo ft WITH (NOLOCK) ON mr.ConfirmFT > 0 AND mr.ConfirmFT = ft.custid
		LEFT JOIN @tblSingle t ON t.matchid = m.matchid
	ORDER BY m.eventstatus, m.matchcode

	-- Get TENNIS RESULT 
	SELECT	MatchId
			, ResourceId
			, HomeValue
			, AwayValue
			, ResultStatusID
			, SettlementStatusID
	FROM	DBPRO.BODB02.dbo.ResultDetail rs WITH (NOLOCK) 
	WHERE	@Sporttype IN (0,5)
			AND EXISTS (SELECT TOP 1 1 FROM @MatchIds m WHERE rs.MatchId = m.MatchId)
			AND ResourceId LIKE '0[0-5]'  
END

GO
GRANT EXECUTE ON [dbo].[NAP_Set_MatchSelCompleted] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Set_MatchSelCompleted] TO [vnteam] AS [dbo]