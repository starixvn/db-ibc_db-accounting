ALTER PROCEDURE [dbo].[Task_DownlineTurnOver_Setting_sum_job]
/*
	Created: Joe
	Task: 
	DB: DBAGE/BODB02
	
	Revisions:
		- 20140408@Elodie: Support all super, direct master and direct agent
*/
AS
BEGIN
	DECLARE @rc1 INT, @rc2 INT, @rc3 INT

	TRUNCATE TABLE dbo.DownlineTurnOver_Trigger_tmp
	
	DELETE D
	OUTPUT deleted.srecommend, deleted.mrecommend, deleted.recommend, deleted.matchid, deleted.sumstake
	INTO DownlineTurnOver_Trigger_tmp (srecommend, mrecommend, recommend, matchid, sumstake)
	FROM dbo.DownlineTurnOver_Trigger D

	SET @rc1 = @@ROWCOUNT
	
	CREATE TABLE #DownlineToTmp (SMAID INT,  matchid INT, SumStake MONEY, CONSTRAINT [CIX_DownlineToTmp] PRIMARY KEY CLUSTERED (matchid, SMAID))
	CREATE TABLE #DownlineToCal (SMAID INT, matchid INT, TotalTurnover MONEY, CONSTRAINT [CIX_DownlineToCal] PRIMARY KEY CLUSTERED (matchid, SMAID))	
	CREATE TABLE #DownlineToControl (SMAID INT, matchid INT, Value INT, InheritLevel TINYINT, CONSTRAINT [CIX_DownlineToControl] PRIMARY KEY CLUSTERED (matchid, SMAID))	
	CREATE TABLE #temp (SMAID INT, matchid INT, CONSTRAINT [CIX_temp] PRIMARY KEY CLUSTERED (matchid, SMAID))
	DECLARE @MatchControl TABLE (Matchid INT PRIMARY KEY, LeagueID INT, SportID INT, Value INT, InheritLevel TINYINT)
	
	INSERT INTO #DownlineToTmp (SMAID, matchid, SumStake)
	SELECT CASE WHEN EXISTS (SELECT * FROM DBACC.bodb_ACC.dbo.Acc_CustDirect where custid = t.mrecommend) THEN recommend --Direct agent
				WHEN EXISTS (SELECT * FROM DBACC.bodb_ACC.dbo.Acc_CustDirect where custid = t.srecommend) THEN mrecommend --Direct master
				ELSE srecommend --super
			END AS SMAID, t.matchid, SumStake
	FROM DownlineTurnOver_Trigger_tmp t WITH (NOLOCK)
		INNER JOIN match m WITH (NOLOCK) ON t.matchid = m.matchid
	WHERE srecommend NOT IN (SELECT custid FROM Dep_CustSuper WITH (NOLOCK))
		AND m.sporttype < 99 AND m.eventstatus <> 'completed' AND m.matchcode NOT LIKE '%hedge%'
	
	INSERT INTO #DownlineToCal (SMAID, matchid, TotalTurnover)
	SELECT SMAID, matchid, SUM(sumstake) TotalTurnover
	FROM #DownlineToTmp t
	GROUP BY SMAID, matchid
	
	UPDATE T
	SET totalturnover = T.totalturnover + dc.totalturnover
	OUTPUT deleted.SMAID, deleted.matchid INTO #temp (SMAID, matchid)
	FROM dbo.DownlineTurnOver_Setting T
		INNER JOIN #DownlineToCal dc ON T.SMAID = dc.SMAID AND T.matchid = dc.matchid

	SET @rc2 = @@ROWCOUNT
	
	INSERT INTO #DownlineToControl (SMAID, matchid, Value, InheritLevel)
	SELECT SMAID, matchid, NULL, NULL
	FROM #DownlineToCal dc
	WHERE NOT EXISTS (SELECT * FROM #temp T WHERE dc.SMAID = T.SMAID AND dc.matchid = T.matchid)

	IF NOT EXISTS (SELECT 1 FROM #DownlineToControl)
		RETURN
	
	INSERT INTO @MatchControl (Matchid, LeagueID, SportID, Value, InheritLevel)
	SELECT DISTINCT d.matchid, m.LeagueID, m.sporttype, NULL, NULL
	FROM #DownlineToControl d
		INNER JOIN match m ON m.matchid = d.matchid

	UPDATE m
	SET Value = CASE WHEN dm.Value IS NOT NULL THEN dm.Value
					 WHEN dl.Value IS NOT NULL AND dm.Value IS NULL THEN dl.Value
					 WHEN ds.Value IS NOT NULL AND dl.Value IS NULL AND dm.Value IS NULL THEN ds.Value
					 ELSE NULL END,
		InheritLevel = CASE	 WHEN dm.Value IS NOT NULL THEN 3
							 WHEN dl.Value IS NOT NULL AND dm.Value IS NULL THEN 2
							 WHEN ds.Value IS NOT NULL AND dl.Value IS NULL AND dm.Value IS NULL THEN 1
							 ELSE NULL END
	FROM @MatchControl m
		LEFT JOIN bodb_Age.dbo.DownlineTo_MatchControl dm ON m.Matchid = dm.Matchid
		LEFT JOIN bodb_Age.dbo.DownlineTo_LeagueControl dl ON m.LeagueID = dl.LeagueID
		LEFT JOIN bodb_Age.dbo.DownlineTo_SportControl ds ON m.SportID = ds.SportID	

	UPDATE dc
	SET Value = CASE WHEN m.Value IS NULL THEN NULL
					 WHEN m.Value = 0 OR sma.Offset = 0 THEN 0	
					 ELSE m.Value + ISNULL(sma.Offset,0) END,
		InheritLevel = m.InheritLevel
	FROM #DownlineToControl dc
		 INNER JOIN @MatchControl m ON dc.matchid = m.matchid
		 LEFT JOIN bodb_Age.dbo.DownlineTo_SMAControl sma ON dc.SMAID = sma.SMAID

	UPDATE dc
	SET Value = sma.Value, InheritLevel = 4
	FROM #DownlineToControl dc
		 INNER JOIN bodb_Age.dbo.DownlineTo_Match_SMAControl sma ON dc.SMAID = sma.SMAID AND dc.matchid = sma.matchid

	INSERT INTO DownlineTurnOver_Setting (SMAID, matchid, maxturnover, totalturnover, IsNotified, Value, InheritLevel)
	SELECT dc.SMAID, dc.matchid, 
			dc.Value/100 * c.credit, 
			cal.totalturnover, 0, dc.Value, dc.InheritLevel
	FROM #DownlineToControl dc
		INNER JOIN CustInfo c WITH (NOLOCK) ON dc.SMAID = c.custid
		INNER JOIN #DownlineToCal cal ON dc.SMAID = cal.SMAID AND dc.matchid = cal.matchid
	WHERE dc.Value IS NOT NULL AND dc.Value <> 0

	SET @rc3 = @@ROWCOUNT

	PRINT '=== Delete ' + CAST(@rc1 as varchar(20)) + ' row(s), Update ' + CAST(@rc2 as varchar(20)) + ' row(s), Insert ' + CAST(@rc3 as varchar(20)) + ' row(s) ==='

	DROP TABLE #DownlineToTmp
	DROP TABLE #DownlineToCal
	DROP TABLE #DownlineToControl
	DROP TABLE #temp
END