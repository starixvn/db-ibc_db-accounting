CREATE PROCEDURE [NAP_Set_MatchSelCompleted] @Date DATETIME
	,@SportType TINYINT = 0
	,@LeagueID INT = 0
	,-- 0 for ALL Leagues
	@isReLoad BIT = 0
AS
/*
	Created by: Kathy
	Date: 
	Task: List FT-completed matches for billing
	DB: DBTRANS.BODB02
	Original: Acc_Set_MatchSelCompleted

	Revisions:

	Param explanation: 
		@isReLoad: 1: reload partial matches of a league, 0: not reload
*/
BEGIN
	SET NOCOUNT ON

	SELECT @LeagueID = CASE 
			WHEN @isReLoad = 1 THEN ISNULL(@LeagueID, 0)
			ELSE 0
			END -- reload partial; search on LeagueID, not reload: get all leagues

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
		,calculate BIT
		,betcount INT
		,IsExistFGLG BIT
		,isGroup INT
		)

	DECLARE @m TABLE (
		matchid INT PRIMARY KEY
		,IsCalculated BIT
		,IsMultiCaled BIT
		,IsRefund BIT
		,IsCalRefund BIT
		,IsHalfTimeCal BIT
		,suspenderHalfTime VARCHAR(20)
		,suspenderFullTime VARCHAR(20)
		,calculate BIT
		,isPending BIT
		,isUndecided BIT
		)

	INSERT INTO @m
	SELECT m.matchid
		,isnull(mr.calculate, 0) IsCalculated
		,isnull(mr.multiple, 0) IsMultiCaled
		,isnull(mr.refund, 0) IsRefund
		,isnull(mr.calrefund, 0) IsCalRefund
		,mr.IsHTCal
		,IsNull(ht.username, '')
		,IsNull(ft.username, '')
		,mr.calculate
		,ISNULL(mr.isPending, 0) AS isPending
		,ISNULL(mr.isUndecided, 0) AS isUndecided
	FROM DBPRO.BODB02.dbo.match m WITH (NOLOCK)
		INNER JOIN DBPRO.BODB02.dbo.match_remark mr WITH (NOLOCK) ON m.matchid = mr.matchid
		LEFT OUTER JOIN CustDB.dbo.custinfo ht WITH (NOLOCK) ON mr.ConfirmHT = ht.custid
		LEFT OUTER JOIN CustDB.dbo.custinfo ft WITH (NOLOCK) ON mr.ConfirmFT = ft.custid
	WHERE m.eventdate = @Date AND m.leagueID = CASE 
			WHEN @LeagueID <> 0 THEN @LeagueID
			ELSE m.leagueID
			END AND m.sporttype = CASE 
			WHEN @sporttype = 0 THEN sporttype
			ELSE @sporttype
			END AND m.eventstatus <> N'Completed' AND (m.kickofftime < dateadd(s, - 6000, CURRENT_TIMESTAMP) OR mr.ConfirmFT > 0)

	INSERT INTO #matchList
	SELECT *
	FROM (
		SELECT m.matchid
			,m.leagueid
			,hthomescore HalfTimeHomeScore
			,htawayscore HalfTimeAwayScore
			,IsCalculated
			,IsMultiCaled
			,IsRefund
			,IsCalRefund
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
			,'' AS Foddsstatus
			,m.sporttype
			,isnull(m.isNeutral, CONVERT(BIT, 0)) AS IsNeutral
			,m.eventdate
			,m.goalrecord
			,suspenderHalfTime
			,suspenderFullTime
			,ISNULL(tm.IsHalfTimeCal, 0) AS IsHalfTimeCal
			,ISNULL(tm.IsPending, 0) AS IsPending
			,ISNULL(tm.isUndecided, 0) AS isUndecided
			,CAST(CASE 
					WHEN hthomescore IS NOT NULL AND htawayscore IS NOT NULL AND finalhomescore IS NOT NULL AND finalawayscore IS NOT NULL THEN 1
					ELSE 0
					END AS BIT) AS IsKeyscore
			,ISNULL(tm.calculate, 0) AS calculate
			,C.betcount
			,c.isExistFGLG
			,0 AS isGroup
		FROM DBPRO.BODB02.dbo.match m WITH (NOLOCK)
			INNER JOIN @m tm ON m.matchid = tm.matchid
			INNER JOIN (
			SELECT b.matchid
				,count(b.matchid) AS BetCount
				,SUM(CASE 
						WHEN bettype = 14 THEN 1
						ELSE 0
						END) AS isExistFGLG
			FROM dbo.bettrans b WITH (NOLOCK)
				INNER JOIN @m stm ON b.matchid = stm.matchid
			WHERE winlostdate = @Date
			GROUP BY b.matchid
			) AS C ON m.matchid = c.matchid
		) X

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
	FROM #matchList m
	ORDER BY m.sporttype
		,m.leagueid
		,m.isGroup
		,m.eventdate
		,m.kickofftime

	DROP TABLE #matchList
END

GO

GRANT EXECUTE ON [NAP_Set_MatchSelCompleted] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [NAP_Set_MatchSelCompleted] TO [vnteam] AS [dbo]
GO


