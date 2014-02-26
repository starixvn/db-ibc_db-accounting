CREATE PROCEDURE [NAP_Set_MatchSelCompletedHT] @Date DATETIME
	,@SportType TINYINT = 0
	,@LeagueID INT = 0
	,-- 0 for ALL Leagues
	@isReLoad BIT = 0
AS
/*
	Created by: Kathy
	Date: 
	Task: List HT-completed matches for billing
	DB: DBTRANS.BODB02
	Original: Acc_Set_MatchSelCompletedHT
	
	Revisions:
		
*/
BEGIN
	SET NOCOUNT ON

	IF @sporttype NOT IN (1, 2, 3, 32) RETURN

	DECLARE @HTOverStartMins INT
		,@HTOverEndMins INT

	SELECT @LeagueID = CASE 
			WHEN @isReLoad = 1 THEN ISNULL(@LeagueID, 0)
			ELSE 0
			END -- reload partial; search on LeagueID, not reload: get all leagues

	SELECT @HTOverStartMins = CASE 
			WHEN @sporttype = 1 THEN 40
			ELSE 25
			END
		,@HTOverEndMins = CASE 
			WHEN @sporttype = 1 THEN 100
			ELSE 60
			END

	CREATE TABLE #matchList (
		matchid INT
		,leagueid INT
		,HalfTimeHomeScore INT
		,HalfTimeAwayScore INT
		,IsCalculated BIT
		,IsMultiCaled BIT
		,IsRefund BIT
		,IsCalRefund BIT
		,homeid INT
		,awayid INT
		,matchcode NVARCHAR(50)
		,kickofftime DATETIME
		,finalhomescore INT
		,finalawayscore INT
		,betstatus NVARCHAR(50)
		,eventstatus NVARCHAR(50)
		,Foddsstatus VARCHAR(10)
		,sporttype TINYINT
		,IsNeutral BIT
		,eventdate DATETIME
		,goalrecord VARCHAR(50)
		,suspenderHalfTime NVARCHAR(50)
		,suspenderFullTime NVARCHAR(50)
		,IsHalfTimeCal BIT
		,isPending BIT
		,isUndecided BIT
		,IsKeyscore BIT
		,betcount INT
		,IsExistFGLG BIT
		,isGroup INT
		)

	INSERT INTO #matchList
	SELECT *
	FROM (
		SELECT m.matchid
			,m.leagueid
			,HalfTimeHomeScore
			,HalfTimeAwayScore
			,isnull(m.calculate, 0) IsCalculated
			,isnull(m.multiple, 0) IsMultiCaled
			,isnull(m.refund, 0) IsRefund
			,isnull(m.calrefund, 0) IsCalRefund
			,m.homeid
			,m.awayid
			,m.matchcode
			,m.kickofftime
			,m.finalhomescore
			,m.finalawayscore
			,m.betstatus
			,CASE 
				WHEN m.betstatus LIKE 'Refund FT%' THEN 'Refund FT'
				WHEN m.betstatus LIKE 'Refund HT%' THEN 'Refund HT'
				WHEN m.betstatus LIKE 'Refund%' THEN 'Refund'
				ELSE m.eventstatus
				END AS eventstatus
			,Foddsstatus
			,m.sporttype
			,isnull(m.isNeutral, CONVERT(BIT, 0)) AS IsNeutral
			,m.eventdate
			,m.goalrecord
			,CASE m.confirmHalfTime
				WHEN 0 THEN ''
				ELSE (
						SELECT username
						FROM CustDB.dbo.custinfo(NOLOCK)
						WHERE custid = m.confirmHalfTime
						)
				END suspenderHalfTime
			,
			--case m.ConfirmFT when 0 then '' else (select username from custinfo (nolock) where custid = m.ConfirmFT ) end suspenderFT,     
			'' AS suspenderFullTime
			,ISNULL(m.IsHalfTimeCal, 0) AS IsHalfTimeCal
			,ISNULL(m.isPending, 0) AS isPending
			,ISNULL(m.isUndecided, 0) AS isUndecided
			,CAST(CASE 
					WHEN HalfTimeHomeScore IS NOT NULL AND HalfTimeAwayScore IS NOT NULL AND finalhomescore IS NOT NULL AND finalawayscore IS NOT NULL THEN 1
					ELSE 0
					END AS BIT) AS IsKeyscore
			,c.betcount
			,CASE 
				WHEN c.cntFGLG = 0 THEN 0
				ELSE 1
				END AS isExistFGLG
			,0 AS isGroup
		FROM (
			SELECT m.matchid
				,m.leagueid
				,hthomescore AS HalfTimeHomeScore
				,htawayscore AS HalfTimeAwayScore
				,mr.calculate
				,mr.multiple
				,mr.refund
				,mr.calrefund
				,m.homeid
				,m.awayid
				,m.matchcode
				,m.kickofftime
				,m.finalhomescore
				,m.finalawayscore
				,m.betstatus
				,m.eventstatus
				,'' AS Foddsstatus
				,m.sporttype
				,m.isNeutral
				,m.eventdate
				,m.goalrecord
				,mr.confirmHT AS confirmHalfTime
				,mr.confirmFT AS confirmFullTime
				,mr.IsHTCal AS IsHalfTimeCal
				,mr.isPending
				,mr.isUndecided
			FROM DBPRO.BODB02.dbo.match m WITH (NOLOCK)
				INNER JOIN DBPRO.BODB02.dbo.match_remark mr WITH (NOLOCK) ON m.matchid = mr.matchid
			WHERE m.eventdate = @Date AND m.leagueID = CASE 
					WHEN @LeagueID <> 0 THEN @LeagueID
					ELSE m.leagueID
					END AND m.sporttype = @sporttype AND m.eventstatus IN ('Closed', 'running', 'internal') AND ((datediff(minute, m.kickofftime, CURRENT_TIMESTAMP) > @HTOverStartMins AND datediff(minute, m.kickofftime, CURRENT_TIMESTAMP) < @HTOverEndMins) OR mr.confirmHT <> 0) AND mr.ishtcal = 0
			) m
			INNER JOIN (
			SELECT bettrans.matchid
				,count(bettrans.matchid) betcount
				,SUM(CASE 
						WHEN bettype = 14 THEN 1
						ELSE 0
						END) AS cntFGLG
			FROM bettrans WITH (NOLOCK) --(NOLOCK, index=CIX_matchid_bettype),  
				JOIN DBPRO.BODB02.dbo.match WITH (NOLOCK) ON match.matchid = bettrans.matchid
			WHERE match.eventdate = @Date AND BETTYPE <= 19000 AND match.eventstatus IN ('Closed', 'running', 'internal') AND match.sporttype = @sporttype
			GROUP BY bettrans.matchid
			) c ON m.matchid = c.matchid
		) x

	UPDATE #matchList
	SET isGroup = CASE 
			WHEN eventstatus = 'Running' THEN 1
			WHEN eventstatus = 'Closed' THEN 2
			WHEN eventstatus = 'completed' THEN 3
			WHEN eventstatus LIKE '%Refund%' THEN 3
			ELSE 0
			END

	UPDATE m
	SET m.isGroup = ml.isGroup
	FROM #matchList m
		INNER JOIN #matchList ml ON ml.sporttype = m.sporttype AND ml.homeid = m.homeid AND ml.awayid = m.awayid AND ml.leagueid = m.leagueid AND ml.isGroup <> 0
	WHERE m.isGroup = 0

	SELECT *
	FROM #matchList
	ORDER BY sporttype
		,leagueid
		,isGroup
		,eventdate
		,kickofftime

	DROP TABLE #matchList
END

GO

GRANT EXECUTE ON [NAP_Set_MatchSelCompletedHT] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [NAP_Set_MatchSelCompletedHT] TO [vnteam] AS [dbo]
GO


