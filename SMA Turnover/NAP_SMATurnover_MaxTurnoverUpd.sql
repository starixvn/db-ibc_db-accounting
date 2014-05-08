ALTER PROCEDURE [dbo].[NAP_SMATurnover_MaxTurnoverUpd]
	@UpdMode TINYINT,
	@EventID INT = 0,
	@SMAID INT = 0,
	@Offset INT = NULL
AS
/*
	Created: Elodie
	Date: 20140416
	Task : Update max turnover
	DB: DBAGE/bodb02

	Revisions:
	
	Parameter's explaination: 
		@UpdMode: --Insert/Update/Delete Sport setting
				  0: Change max turnover because sport setting is updated
				  1: Change max turnover because sport setting is deleted

				  --Insert/Update/Delete League setting
				  2: Change max turnover because league setting which have sport setting is inserted a specific value (X)					 
				  3: + Change max turnover because league setting is inserted a unlimited value (U)
					 + Change max turnover because league setting is updated from a specific value to a unlimited value (X -> U)
					 + Change max turnover because league setting which does not have sport setting is deleted a specific value
				  4: Change max turnover because league setting is updated from a specific value to a another specific value (X -> X1)
				  5: Change max turnover because league setting which have sport setting is deleted a specific value (X)

				  --Insert/Update/Delete Match setting
				  6: Change max turnover because match setting which have sport setting or league setting is inserted a specific value (X)					 
				  7: + Change max turnover because match setting is inserted a unlimited value (U)
					 + Change max turnover because match setting is updated from a specific value to a unlimited value (X -> U)
					 + Change max turnover because match setting which does not have sport setting and league setting is deleted a specific value
				  8: Change max turnover because match setting is updated from a specific value to a another specific value (X -> X1)
				  9: Change max turnover because match setting which have sport setting or league setting is deleted a specific value (X)

				  --Insert/Update/Delete Match_SMA setting
				  10: Change max turnover because Match_SMA setting which have sport setting or league setting or match setting is inserted a specific value (X)
				  11: + Change max turnover because Match_SMA setting is inserted a unlimited value (U)
					  + Change max turnover because Match_SMA setting is updated from a specific value to a unlimited value (X -> U)
					  + Change max turnover because Match_SMA setting which does not have sport setting and league setting and match setting is deleted a specific value
				  12: Change max turnover because Match_SMA setting is updated from a specific value to a another specific value (X -> X1)
				  13: Change max turnover because Match_SMA setting which have sport setting or league setting or match setting is deleted a specific value (X)
					
				  --Insert/Update/Delete SMA setting
				  14: + Change max turnover because SMA setting is inserted
					  + Change max turnover because SMA setting is updated from a specific value to a unlimited value (X -> U) 
				  15: Change max turnover because SMA setting is updated from a specific value to a another specific value (X -> X1) 
				  16: Change max turnover because SMA setting is deleted a specific value (X) 

				  --Update given credit
				  17: Change max turnover because given credit is updated

		@EventID: sportID or leagueID or matchID
	Example: EXEC NAP_SMATurnover_MaxTurnoverUpd @UpdMode = 0, @EventID = 1
	
*/
BEGIN
	SET NOCOUNT ON	

	--Change max turnover because sport setting is updated
	IF @UpdMode = 0 
	BEGIN
		UPDATE s
		SET Value = sc.Value + ISNULL(sma.Offset,0), maxturnover = c.credit/100 * (sc.Value + ISNULL(sma.Offset,0))
		FROM DownlineTurnOver_Setting s WITH (ROWLOCK,UPDLOCK)
			INNER JOIN CustInfo c WITH (NOLOCK) ON s.SMAID = c.custid
			INNER JOIN match m WITH (NOLOCK) ON s.matchid = m.matchid
			INNER JOIN bodb_AGE.dbo.DownlineTo_SportControl sc WITH (NOLOCK) ON m.sporttype= sc.SportID
			LEFT JOIN bodb_AGE.dbo.DownlineTo_SMAControl sma WITH (NOLOCK) ON s.SMAID = sma.SMAID			
		WHERE eventstatus <> 'completed' AND m.sporttype = @EventID AND s.InheritLevel = 1
	END
	
	--Change max turnover because sport setting is deleted
	IF @UpdMode = 1 
	BEGIN
		DELETE DownlineTurnOver_Setting 
		WHERE InheritLevel = 1 AND matchid IN (	SELECT matchid 
												FROM match m WITH (NOLOCK) 
												WHERE eventstatus <> 'completed' AND m.sporttype = @EventID)
	END

	--Change max turnover because league setting which have sport setting is inserted a specific value (X)
	IF @UpdMode = 2 
	BEGIN
		UPDATE s
		SET Value = lc.Value + ISNULL(sma.Offset,0), maxturnover = c.credit/100 * (lc.Value + ISNULL(sma.Offset,0)), InheritLevel = 2
		FROM DownlineTurnOver_Setting s WITH (ROWLOCK,UPDLOCK)
			INNER JOIN CustInfo c WITH (NOLOCK) ON s.SMAID = c.custid
			INNER JOIN match m WITH (NOLOCK) ON s.matchid = m.matchid
			INNER JOIN bodb_AGE.dbo.DownlineTo_LeagueControl lc WITH (NOLOCK) ON m.leagueid= lc.LeagueID
			LEFT JOIN bodb_AGE.dbo.DownlineTo_SMAControl sma WITH (NOLOCK) ON s.SMAID = sma.SMAID			
		WHERE eventstatus <> 'completed' AND m.leagueid = @EventID AND s.InheritLevel = 1
	END

	--Change max turnover because league setting is inserted a unlimited value (U)
	--Change max turnover because league setting is updated from a specific value to a unlimited value (X -> U)
	--Change max turnover because league setting which does not have sport setting is deleted
	IF @UpdMode = 3 
	BEGIN
		DELETE DownlineTurnOver_Setting 
		WHERE InheritLevel NOT IN (3,4) AND matchid IN (SELECT matchid 
														FROM match m WITH (NOLOCK) 
														WHERE eventstatus <> 'completed' AND m.leagueid = @EventID)
	END

	--Change max turnover because league setting is updated from a specific value to a another specific value (X -> X1)
	IF @UpdMode = 4 
	BEGIN
		UPDATE s
		SET Value = lc.Value + ISNULL(sma.Offset,0), maxturnover = c.credit/100 * (lc.Value + ISNULL(sma.Offset,0))
		FROM DownlineTurnOver_Setting s WITH (ROWLOCK,UPDLOCK)
			INNER JOIN CustInfo c WITH (NOLOCK) ON s.SMAID = c.custid
			INNER JOIN match m WITH (NOLOCK) ON s.matchid = m.matchid
			INNER JOIN bodb_AGE.dbo.DownlineTo_LeagueControl lc WITH (NOLOCK) ON m.leagueid= lc.LeagueID
			LEFT JOIN bodb_AGE.dbo.DownlineTo_SMAControl sma WITH (NOLOCK) ON s.SMAID = sma.SMAID
		WHERE eventstatus <> 'completed' AND m.leagueid = @EventID AND s.InheritLevel = 2
	END

	--Change max turnover because league setting which have sport setting is deleted a specific value
	IF @UpdMode = 5
	BEGIN
		UPDATE s
		SET Value = sc.Value + ISNULL(sma.Offset,0), maxturnover = c.credit/100 * (sc.Value + ISNULL(sma.Offset,0)), InheritLevel = 1
		FROM DownlineTurnOver_Setting s WITH (ROWLOCK,UPDLOCK)
			INNER JOIN CustInfo c WITH (NOLOCK) ON s.SMAID = c.custid
			INNER JOIN match m WITH (NOLOCK) ON s.matchid = m.matchid
			INNER JOIN bodb_AGE.dbo.DownlineTo_SportControl sc WITH (NOLOCK) ON m.sporttype= sc.SportID
			LEFT JOIN bodb_AGE.dbo.DownlineTo_SMAControl sma WITH (NOLOCK) ON s.SMAID = sma.SMAID
		WHERE eventstatus <> 'completed' AND m.leagueid = @EventID AND s.InheritLevel = 2
	END

	--Change max turnover because match setting which have sport setting or league setting is inserted a specific value (X)
	IF @UpdMode = 6
	BEGIN
		UPDATE s
		SET Value = mc.Value + ISNULL(sma.Offset,0), maxturnover = c.credit/100 * (mc.Value + ISNULL(sma.Offset,0)), InheritLevel = 3
		FROM DownlineTurnOver_Setting s WITH (ROWLOCK,UPDLOCK)
			INNER JOIN CustInfo c WITH (NOLOCK) ON s.SMAID = c.custid
			INNER JOIN match m WITH (NOLOCK) ON s.matchid = m.matchid
			INNER JOIN bodb_AGE.dbo.DownlineTo_MatchControl mc WITH (NOLOCK) ON m.matchid= mc.MatchID
			LEFT JOIN bodb_AGE.dbo.DownlineTo_SMAControl sma WITH (NOLOCK) ON s.SMAID = sma.SMAID
		WHERE eventstatus <> 'completed' AND m.matchid = @EventID AND s.InheritLevel <> 4
	END

	--Change max turnover because match setting is inserted a unlimited value (U)
	--Change max turnover because match setting is updated from a specific value to a unlimited value (X -> U)
	--Change max turnover because match setting which does not have sport setting or league setting is deleted a specific value
	IF @UpdMode = 7
	BEGIN
		DELETE DownlineTurnOver_Setting 
		WHERE InheritLevel <> 4 AND matchid IN (SELECT matchid 
												FROM match m WITH (NOLOCK) 
												WHERE eventstatus <> 'completed' AND m.matchid = @EventID)
	END

	--Change max turnover because match setting is updated from a specific value to a another specific value (X -> X1)
	IF @UpdMode = 8
	BEGIN
		UPDATE s
		SET Value = mc.Value + ISNULL(sma.Offset,0), maxturnover = c.credit/100 * (mc.Value + ISNULL(sma.Offset,0))
		FROM DownlineTurnOver_Setting s WITH (ROWLOCK,UPDLOCK)
			INNER JOIN CustInfo c WITH (NOLOCK) ON s.SMAID = c.custid
			INNER JOIN match m WITH (NOLOCK) ON s.matchid = m.matchid
			INNER JOIN bodb_AGE.dbo.DownlineTo_MatchControl mc WITH (NOLOCK) ON m.matchid= mc.MatchID
			LEFT JOIN bodb_AGE.dbo.DownlineTo_SMAControl sma WITH (NOLOCK) ON s.SMAID = sma.SMAID
		WHERE eventstatus <> 'completed' AND m.matchid = @EventID AND s.InheritLevel = 3
	END

	--Change max turnover because match setting which have sport setting or league setting is deleted a specific value
	IF @UpdMode = 9
	BEGIN
		UPDATE s
		SET Value = CASE WHEN lc.Value IS NOT NULL THEN lc.Value ELSE sc.Value END + ISNULL(sma.Offset,0), 
			maxturnover = c.credit/100 * (CASE WHEN lc.Value IS NOT NULL THEN lc.Value ELSE sc.Value END + ISNULL(sma.Offset,0)),
			InheritLevel = CASE WHEN lc.Value IS NOT NULL THEN 2 ELSE 1 END
		FROM DownlineTurnOver_Setting s WITH (ROWLOCK,UPDLOCK)
			INNER JOIN CustInfo c WITH (NOLOCK) ON s.SMAID = c.custid
			INNER JOIN match m WITH (NOLOCK) ON s.matchid = m.matchid
			LEFT JOIN bodb_AGE.dbo.DownlineTo_LeagueControl lc WITH (NOLOCK) ON lc.LeagueID= m.leagueid
			LEFT JOIN bodb_AGE.dbo.DownlineTo_SportControl sc WITH (NOLOCK) ON sc.SportID= m.sporttype
			LEFT JOIN bodb_AGE.dbo.DownlineTo_SMAControl sma WITH (NOLOCK) ON s.SMAID = sma.SMAID
		WHERE eventstatus <> 'completed' AND m.matchid = @EventID AND s.InheritLevel = 3
	END

	--Change max turnover because Match_SMA setting which have sport setting or league setting or match setting is inserted a specific value (X)
	IF @UpdMode = 10
	BEGIN
		UPDATE s
		SET Value = msc.Value, maxturnover = c.credit/100 * msc.Value, InheritLevel = 4
		FROM DownlineTurnOver_Setting s WITH (ROWLOCK,UPDLOCK)
			INNER JOIN CustInfo c WITH (NOLOCK) ON s.SMAID = c.custid
			INNER JOIN match m WITH (NOLOCK) ON s.matchid = m.matchid
			INNER JOIN bodb_AGE.dbo.DownlineTo_Match_SMAControl msc WITH (NOLOCK) ON m.matchid= msc.MatchID AND s.SMAID = msc.SMAID
		WHERE eventstatus <> 'completed' AND m.matchid = @EventID AND s.SMAID = @SMAID AND s.InheritLevel IN (1,2,3)
	END

	--Change max turnover because Match_SMA setting is inserted a unlimited value (U)
	--Change max turnover because Match_SMA setting is updated from a specific value to a unlimited value (X -> U)
	--Change max turnover because Match_SMA setting which does not have sport setting and league setting and match setting is deleted a specific value
	IF @UpdMode = 11
	BEGIN
		DELETE DownlineTurnOver_Setting 
		WHERE SMAID = @SMAID AND MatchID = @EventID 
			AND matchid IN (SELECT matchid 
							FROM match m WITH (NOLOCK) 
							WHERE eventstatus <> 'completed')
	END	  

	--Change max turnover because Match_SMA setting is updated from a specific value to a another specific value (X -> X1)
	IF @UpdMode = 12
	BEGIN
		UPDATE s
		SET Value = msc.Value, maxturnover = c.credit/100 * msc.Value
		FROM DownlineTurnOver_Setting s WITH (ROWLOCK,UPDLOCK)
			INNER JOIN CustInfo c WITH (NOLOCK) ON s.SMAID = c.custid
			INNER JOIN match m WITH (NOLOCK) ON s.matchid = m.matchid
			INNER JOIN bodb_AGE.dbo.DownlineTo_Match_SMAControl msc WITH (NOLOCK) ON s.matchid= msc.MatchID AND s.SMAID = msc.SMAID
		WHERE eventstatus <> 'completed' AND s.matchid = @EventID AND s.SMAID = @SMAID AND s.InheritLevel = 4
	END

	--Change max turnover because Match_SMA setting which have sport setting or league setting or match setting is deleted a specific value
	IF @UpdMode = 13
	BEGIN
		UPDATE s
		SET Value = CASE	WHEN mc.Value IS NOT NULL THEN mc.Value
							WHEN lc.Value IS NOT NULL AND mc.Value IS NULL THEN lc.Value 
							WHEN sc.Value IS NOT NULL AND lc.Value IS NULL AND mc.Value IS NULL THEN sc.Value END + ISNULL(sma.Offset,0), 
			maxturnover = c.credit/100 * (CASE	WHEN mc.Value IS NOT NULL THEN mc.Value
												WHEN lc.Value IS NOT NULL AND mc.Value IS NULL THEN lc.Value 
												WHEN sc.Value IS NOT NULL AND lc.Value IS NULL AND mc.Value IS NULL THEN sc.Value END + ISNULL(sma.Offset,0)), 
			InheritLevel = CASE	WHEN mc.Value IS NOT NULL THEN 3
								WHEN lc.Value IS NOT NULL AND mc.Value IS NULL THEN 2 
								WHEN sc.Value IS NOT NULL AND lc.Value IS NULL AND mc.Value IS NULL THEN 1 END
		FROM DownlineTurnOver_Setting s WITH (ROWLOCK,UPDLOCK)
			INNER JOIN CustInfo c WITH (NOLOCK) ON s.SMAID = c.custid
			INNER JOIN match m WITH (NOLOCK) ON s.matchid = m.matchid
			LEFT JOIN bodb_AGE.dbo.DownlineTo_MatchControl mc WITH (NOLOCK) ON mc.MatchID= m.matchid
			LEFT JOIN bodb_AGE.dbo.DownlineTo_LeagueControl lc WITH (NOLOCK) ON lc.LeagueID= m.leagueid
			LEFT JOIN bodb_AGE.dbo.DownlineTo_SportControl sc WITH (NOLOCK) ON sc.SportID= m.sporttype
			LEFT JOIN bodb_AGE.dbo.DownlineTo_SMAControl sma WITH (NOLOCK) ON s.SMAID = sma.SMAID
		WHERE eventstatus <> 'completed' AND s.matchid = @EventID AND s.SMAID = @SMAID AND s.InheritLevel = 4
	END

	--Change max turnover because SMA setting is inserted
	--Change max turnover because SMA setting is updated from a specific value to a unlimited value (X -> U) 
	IF @UpdMode = 14
	BEGIN
		IF @Offset = 0
		BEGIN
			DELETE DownlineTurnOver_Setting WHERE SMAID = @SMAID AND matchid IN (SELECT matchid FROM  match WITH (NOLOCK) WHERE eventstatus <> 'completed') AND InheritLevel <> 4
		END
		ELSE
		BEGIN
			UPDATE s
			SET Value = s.Value + sc.Offset,
				maxturnover = c.credit/100 * (s.Value + sc.Offset)
			FROM DownlineTurnOver_Setting s WITH (ROWLOCK,UPDLOCK)
				INNER JOIN CustInfo c WITH (NOLOCK) ON s.SMAID = c.custid
				INNER JOIN match m WITH (NOLOCK) ON s.matchid = m.matchid
				INNER JOIN bodb_Age.dbo.DownlineTo_SMAControl sc WITH (NOLOCK) ON sc.SMAID = s.SMAID
			WHERE eventstatus <> 'completed' AND s.SMAID = @SMAID AND s.InheritLevel <> 4
		END
	END

	--Change max turnover because SMA setting is updated from a specific value to a another specific value (X -> X1)
	IF @UpdMode = 15
	BEGIN
		UPDATE s
		SET Value = s.Value + (sc.Offset - @Offset),
			maxturnover = c.credit/100 * (s.Value + (sc.Offset - @Offset))
		FROM DownlineTurnOver_Setting s WITH (ROWLOCK,UPDLOCK)
			INNER JOIN CustInfo c WITH (NOLOCK) ON s.SMAID = c.custid
			INNER JOIN match m WITH (NOLOCK) ON s.matchid = m.matchid
			INNER JOIN bodb_Age.dbo.DownlineTo_SMAControl sc WITH (NOLOCK) ON sc.SMAID = s.SMAID
		WHERE eventstatus <> 'completed' AND s.SMAID = @SMAID AND s.InheritLevel <> 4
	END

	--Change max turnover because SMA setting is deleted a specific value (X) 
	IF @UpdMode = 16
	BEGIN
		UPDATE s
		SET Value = s.Value - @Offset,
			maxturnover = c.credit/100 * (s.Value - @Offset)
		FROM DownlineTurnOver_Setting s WITH (ROWLOCK,UPDLOCK)
			INNER JOIN CustInfo c WITH (NOLOCK) ON s.SMAID = c.custid
			INNER JOIN match m WITH (NOLOCK) ON s.matchid = m.matchid
		WHERE eventstatus <> 'completed' AND s.SMAID = @SMAID AND s.InheritLevel <> 4
	END

	--Change max turnover because given credit is updated
	IF @UpdMode = 17
	BEGIN
		UPDATE s
		SET maxturnover = c.credit/100 * s.Value
		FROM DownlineTurnOver_Setting s WITH (ROWLOCK,UPDLOCK)
			INNER JOIN DBTXN.CustDB.dbo.CustInfo c WITH (NOLOCK) ON s.SMAID = c.custid
			INNER JOIN match m WITH (NOLOCK) ON s.matchid = m.matchid
		WHERE eventstatus <> 'completed' AND s.SMAID = @SMAID
	END

	--IF @UpdMode = 4
	--BEGIN
	--	UPDATE s
	--	SET Value = sec.Value, maxturnover = sec.Value * c.credit
	--	FROM DownlineTurnOver_Setting s WITH (ROWLOCK,UPDLOCK)
	--		INNER JOIN bodbAGE.dbo.DownlineTo_Match_SMAControl sec WITH (NOLOCK) ON s.SMAID = sec.SMAID AND s.matchid = sec.matchid
	--		INNER JOIN CustInfo c WITH (NOLOCK) ON sec.SMAID = c.custid
	--	WHERE eventstatus <> 'completed' AND s.SMAID = @SMAID AND s.matchid = @EventID
	--END
	--ELSE IF @UpdMode = 5
	--BEGIN
	--	UPDATE s
	--	SET maxturnover = s.Value * c.credit
	--	FROM DownlineTurnOver_Setting s WITH (ROWLOCK,UPDLOCK)
	--		INNER JOIN CustInfo c WITH (NOLOCK) ON s.SMAID = c.custid
	--		INNER JOIN match m WITH (NOLOCK) ON s.matchid = m.matchid
	--	WHERE eventstatus <> 'completed' AND s.SMAID = @SMAID
	--END
	--ELSE IF @UpdMode = 6
	--BEGIN
	--	IF @Offset = 0
	--	BEGIN
	--		DELETE DownlineTurnOver_Setting WHERE SMAID = @SMAID AND matchid IN (SELECT matchid FROM  match WITH (NOLOCK) WHERE eventstatus <> 'completed')
	--	END
	--	ELSE
	--	BEGIN
	--		UPDATE s
	--		SET Value = s.Value + sc.Offset,
	--			maxturnover = (s.Value + sc.Offset) * c.credit
	--		FROM DownlineTurnOver_Setting s WITH (ROWLOCK,UPDLOCK)
	--			INNER JOIN CustInfo c WITH (NOLOCK) ON s.SMAID = c.custid
	--			INNER JOIN match m WITH (NOLOCK) ON s.matchid = m.matchid
	--			INNER JOIN bodb_Age.dbo.DownlineTo_SMAControl sc WITH (NOLOCK) ON sc.SMAID = s.SMAID
	--		WHERE eventstatus <> 'completed' AND s.SMAID = @SMAID
	--	END
	--END
	--ELSE
	--BEGIN
	--	DECLARE @DownlineToControl TABLE (SMAID INT, matchid INT, Value INT)
	--	DECLARE @MatchControl TABLE (Matchid INT, LeagueID INT, SportID INT, Value INT)

	--	INSERT INTO @DownlineToControl (SMAID, matchid)
	--	SELECT s.SMAID, s.matchid
	--	FROM DownlineTurnOver_Setting s WITH (NOLOCK)
	--		INNER JOIN match m WITH (NOLOCK) ON s.matchid = m.matchid
	--	WHERE eventstatus <> 'completed' AND 
	--		1 = CASE WHEN @UpdMode = 0 AND m.sporttype = @EventID THEN 1 
	--					WHEN @UpdMode = 1 AND m.leagueid = @EventID THEN 1 
	--					WHEN @UpdMode = 2 AND m.matchID = @EventID THEN 1 
	--					WHEN @UpdMode = 3 AND m.matchID = @EventID AND s.SMAID = @SMAID THEN 1 
	--					ELSE 0 END

	--	IF NOT EXISTS (SELECT 1 FROM @DownlineToControl)
	--		RETURN

	--	INSERT INTO @MatchControl (Matchid, LeagueID, SportID, Value)
	--	SELECT DISTINCT d.matchid, m.LeagueID, m.sporttype, NULL
	--	FROM @DownlineToControl d
	--		INNER JOIN match m ON m.matchid = d.matchid

	--	UPDATE m
	--	SET Value = CASE WHEN dm.Value IS NOT NULL THEN dm.Value
	--						WHEN dl.Value IS NOT NULL AND dm.Value IS NULL THEN dl.Value
	--						WHEN ds.Value IS NOT NULL AND dl.Value IS NULL AND dm.Value IS NULL THEN ds.Value
	--						ELSE NULL END
	--	FROM @MatchControl m
	--		LEFT JOIN bodb_Age.dbo.DownlineTo_MatchControl dm ON m.Matchid = dm.Matchid
	--		LEFT JOIN bodb_Age.dbo.DownlineTo_LeagueControl dl ON m.LeagueID = dl.LeagueID
	--		LEFT JOIN bodb_Age.dbo.DownlineTo_SportControl ds ON m.SportID = ds.SportID	

	--	UPDATE dc
	--	SET Value = CASE WHEN m.Value IS NULL THEN NULL
	--						WHEN m.Value = 0 OR sma.Offset = 0 THEN 0						 
	--						ELSE m.Value + ISNULL(sma.Offset,0) END
	--	FROM @DownlineToControl dc
	--			INNER JOIN @MatchControl m ON dc.matchid = m.matchid
	--			LEFT JOIN bodb_Age.dbo.DownlineTo_SMAControl sma ON dc.SMAID = sma.SMAID

	--	DELETE FROM DownlineTurnOver_Setting
	--	WHERE EXISTS (SELECT 1 FROM @DownlineToControl dc 
	--					WHERE dc.matchid = DownlineTurnOver_Setting.matchid 
	--						AND dc.SMAID = DownlineTurnOver_Setting.SMAID 
	--						AND (dc.Value IS NULL OR dc.Value = 0))

	--	UPDATE DownlineTurnOver_Setting WITH (ROWLOCK,UPDLOCK)
	--	SET Value = dc.Value, 
	--		maxturnover = dc.Value * c.credit
	--	FROM @DownlineToControl dc
	--		INNER JOIN CustInfo c WITH (NOLOCK) ON dc.SMAID = c.custid	
	--	WHERE NOT EXISTS (SELECT 1 FROM bodb_Age.dbo.DownlineTo_Match_SMAControl ms WITH (NOLOCK) WHERE dc.matchID = ms.matchID AND dc.SMAID = ms.SMAID)
	--END
END

GO
GRANT EXECUTE ON [dbo].[NAP_SMATurnover_MaxTurnoverUpd] TO [bodbadminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_SMATurnover_MaxTurnoverUpd] TO [vnteam]