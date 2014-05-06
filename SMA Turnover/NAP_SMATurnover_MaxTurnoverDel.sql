ALTER PROCEDURE [dbo].[NAP_SMATurnover_MaxTurnoverDel]
	@UpdMode BIT,
	@EventID INT = 0,
	@SMAID INT = 0
AS
/*
	Created: Elodie
	Date: 20140416
	Task : Update max turnover
	DB: DBAGE/bodb02

	Revisions:
	
	Parameter's explaination: 
		@UpdMode: 0: Change max turnover because sport setting is change
				  1: Change max turnover because league setting is change
				  2: Change max turnover because match setting is change
				  3: Change max turnover because SMA setting by event is deleted
				  4: Change max turnover because SMA setting by event is updated
				  5: Change max turnover because given credit is updated
		@EventID: sportID or leagueID or matchID
	Example: EXEC NAP_SMATurnover_MaxTurnoverUpd @UpdMode = 0
	
*/
BEGIN
	SET NOCOUNT ON	
	DECLARE @Match TABLE (MatchID INT)
	INSERT INTO @Match (MatchID)
	SELECT MatchID 
	FROM bodbAGE.dbo.DownlineTo_MatchControl mc WITH (NOLOCK) 
		INNER JOIN League l WITH (NOLOCK) ON mc.matchID = l.matchID
	WHERE l.leagueid = @EventID
	UNION ALL
	SELECT MatchID 
	FROM bodbAGE.dbo.DownlineTo_Match_SMAControl msc WITH (NOLOCK) 
		INNER JOIN League l WITH (NOLOCK) ON msc.matchID = l.matchID
	WHERE l.leagueid = @EventID

	DELETE DownlineTurnOver_Setting 
	IF @UpdMode = 4
	BEGIN
		UPDATE s
		SET Value = sec.Value, maxturnover = sec.Value * c.credit
		FROM DownlineTurnOver_Setting s WITH (ROWLOCK,UPDLOCK)
			INNER JOIN bodbAGE.dbo.DownlineTo_Match_SMAControl sec WITH (NOLOCK) ON s.SMAID = sec.SMAID AND s.matchid = sec.matchid
			INNER JOIN CustInfo c WITH (NOLOCK) ON sec.SMAID = c.custid
		WHERE eventstatus <> 'completed' AND s.SMAID = @SMAID AND s.matchid = @EventID
	END
	ELSE IF @UpdMode = 5
	BEGIN
		UPDATE s
		SET maxturnover = s.Value * c.credit
		FROM DownlineTurnOver_Setting s WITH (ROWLOCK,UPDLOCK)
			INNER JOIN CustInfo c WITH (NOLOCK) ON s.SMAID = c.custid
			INNER JOIN match m WITH (NOLOCK) ON s.matchid = m.matchid
		WHERE eventstatus <> 'completed' AND s.SMAID = @SMAID
	END
	ELSE
	BEGIN
		DECLARE @DownlineToControl TABLE (SMAID INT, matchid INT, Value INT)
		DECLARE @MatchControl TABLE (Matchid INT, LeagueID INT, SportID INT, Value INT)

		INSERT INTO @DownlineToControl (SMAID, matchid)
		SELECT s.SMAID, s.matchid
		FROM DownlineTurnOver_Setting s WITH (NOLOCK)
			INNER JOIN match m WITH (NOLOCK) ON s.matchid = m.matchid
		WHERE eventstatus <> 'completed' AND 
			1 = CASE WHEN @UpdMode = 0 AND m.sporttype = @EventID THEN 1 
						WHEN @UpdMode = 1 AND m.leagueid = @EventID THEN 1 
						WHEN @UpdMode = 2 AND m.matchID = @EventID THEN 1 
						WHEN @UpdMode = 3 AND m.matchID = @EventID AND s.SMAID = @SMAID THEN 1 
						ELSE 0 END

		IF NOT EXISTS (SELECT 1 FROM @DownlineToControl)
			RETURN

		INSERT INTO @MatchControl (Matchid, LeagueID, SportID, Value)
		SELECT DISTINCT d.matchid, m.LeagueID, m.sporttype, NULL
		FROM @DownlineToControl d
			INNER JOIN match m ON m.matchid = d.matchid

		UPDATE m
		SET Value = CASE WHEN dm.Value IS NOT NULL THEN dm.Value
							WHEN dl.Value IS NOT NULL AND dm.Value IS NULL THEN dl.Value
							WHEN ds.Value IS NOT NULL AND dl.Value IS NULL AND dm.Value IS NULL THEN ds.Value
							ELSE NULL END
		FROM @MatchControl m
			LEFT JOIN bodb_Age.dbo.DownlineTo_MatchControl dm ON m.Matchid = dm.Matchid
			LEFT JOIN bodb_Age.dbo.DownlineTo_LeagueControl dl ON m.LeagueID = dl.LeagueID
			LEFT JOIN bodb_Age.dbo.DownlineTo_SportControl ds ON m.SportID = ds.SportID	

		UPDATE dc
		SET Value = CASE WHEN m.Value IS NULL THEN NULL
							WHEN m.Value = 0 OR sma.Offset = 0 THEN 0						 
							ELSE m.Value + ISNULL(sma.Offset,0) END
		FROM @DownlineToControl dc
				INNER JOIN @MatchControl m ON dc.matchid = m.matchid
				LEFT JOIN bodb_Age.dbo.DownlineTo_SMAControl sma ON dc.SMAID = sma.SMAID

		DELETE FROM DownlineTurnOver_Setting
		WHERE EXISTS (SELECT 1 FROM @DownlineToControl dc 
						WHERE dc.matchid = DownlineTurnOver_Setting.matchid 
							AND dc.SMAID = DownlineTurnOver_Setting.SMAID 
							AND (dc.Value IS NULL OR dc.Value = 0))

		UPDATE DownlineTurnOver_Setting WITH (ROWLOCK,UPDLOCK)
		SET Value = dc.Value, 
			maxturnover = dc.Value * c.credit
		FROM @DownlineToControl dc
			INNER JOIN CustInfo c WITH (NOLOCK) ON dc.SMAID = c.custid	
		WHERE NOT EXISTS (SELECT 1 FROM bodb_Age.dbo.DownlineTo_Match_SMAControl ms WITH (NOLOCK) WHERE dc.matchID = ms.matchID AND dc.SMAID = ms.SMAID)
	END
END

GO
GRANT EXECUTE ON [dbo].[NAP_SMATurnover_MaxTurnoverUpd] TO [bodbadminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_SMATurnover_MaxTurnoverUpd] TO [vnteam]