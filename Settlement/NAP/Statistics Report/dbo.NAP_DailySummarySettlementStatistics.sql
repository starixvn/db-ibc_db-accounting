ALTER PROCEDURE dbo.NAP_DailySummarySettlementStatistics @Date DATETIME
AS
/*
	Created by: Kathy
	Date: 20150227
	Task: Statistics report (logs) for settlement [Redmine:#23264]
	DB: DB06.BODB02
	
	Revisions:
		
		
*/


BEGIN	
	SET NOCOUNT ON
	
	DECLARE @tblSingle TABLE (
		KeyId			INT
		,MatchId		INT
		,StartTime		DATETIME
		,ExecTime		DATETIME
		,Duration		INT
		)
	DECLARE @tblParlay TABLE (
		KeyId			INT
		,MatchId		INT
		,StartTime		DATETIME
		,ExecTime		DATETIME
		,Duration		INT
		)

	CREATE TABLE #DB06Logs (
		MatchId			INT
		,[Action]		NVARCHAR(50)
		,KeyId			INT
		,FinishTime		DATETIME
		,QueueType		BIT
		)

	INSERT INTO @tblSingle (
		KeyId
		,MatchId
		,StartTime
		,ExecTime
		,Duration
		)
	SELECT KeyId
		,MatchId
		,StartTime
		,ExecTime
		,Duration
	FROM DBTXN.bodb02.dbo.Single_Calculate_Queue WITH (NOLOCK)
	WHERE CONVERT(VARCHAR(10), StartTime, 120) <= @Date
		AND IsCalculating NOT IN (0, 1)

	INSERT INTO @tblParlay (
		KeyId
		,MatchId
		,StartTime
		,ExecTime
		,Duration
		)
	SELECT KeyId
		,MatchId
		,StartTime
		,ExecTime
		,Duration
	FROM DBTXN.bodb02.dbo.Parlay_Calculate_Queue WITH (NOLOCK)
	WHERE CONVERT(VARCHAR(10), StartTime, 120) <= @Date
		AND IsCalculating NOT IN (0, 1)

	;WITH Result
	AS (
		SELECT ROW_NUMBER() OVER (
				PARTITION BY KeyId ORDER BY CreationTime DESC
				) AS RowId
			,MatchId
			,[Action]
			,KeyId
			,DATEADD(MILLISECOND, Duration, CreationTime) AS FinishTime
			,QueueType
		FROM DB06.bodb02.sb.Logs
		WHERE [Action] IS NOT NULL
			AND CONVERT(VARCHAR(10), CreationTime, 120) = @Date
		)
	INSERT INTO #DB06Logs (
		MatchId
		,[Action]
		,KeyId
		,FinishTime
		,QueueType
		)
	SELECT MatchId
		,[Action]
		,KeyId
		,FinishTime
		,QueueType
	FROM Result
	WHERE RowId = 1

	INSERT INTO SettlementStatistics (
		MatchId
		,Action
		,StartTime
		,ExecTime
		,FinishTime
		,repFinishTime
		)
	SELECT l.MatchId
		,l.[Action]
		,MAX(s.Starttime) AS StartTime
		,MAX(s.ExecTime) AS ExecTime
		,MAX(DATEADD(MILLISECOND, s.Duration, s.ExecTime)) AS FinishTime
		,MAX(FinishTime) AS repFinishTime
	FROM #DB06Logs l
		INNER JOIN @tblSingle s ON s.KeyId = l.KeyId
		AND QueueType = 0
	GROUP BY l.Matchid
		,l.[Action]
	
	UNION ALL
	SELECT l.MatchId
		,l.[Action]
		,MAX(p.Starttime) AS StartTime
		,MAX(p.ExecTime) AS ExecTime
		,MAX(DATEADD(MILLISECOND, p.Duration, p.ExecTime)) AS FinishTime
		,MAX(FinishTime) AS repFinishTime
	FROM #DB06Logs l
		INNER JOIN @tblParlay p ON p.KeyId = l.KeyId
		AND QueueType = 1
	GROUP BY l.Matchid
		,l.[Action]
	ORDER BY ExecTime
	
	DROP TABLE #DB06Logs
END

