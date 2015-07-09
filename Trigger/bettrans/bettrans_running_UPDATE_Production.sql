 ALTER TRIGGER [dbo].[bettrans_running_UPDATE]
   ON  [dbo].[bettrans]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
    CREATE TABLE #list (transid bigint PRIMARY KEY, tag tinyint)
    CREATE INDEX IX_tag ON #list (tag)
	
	INSERT INTO #list (transid, tag)
    SELECT
		i.transid, 
		CASE
		WHEN i.ruben = 0 AND d.ruben = 1 THEN 1 -- unsettle : add back again
		WHEN i.ruben = 1 AND d.ruben = 0 THEN 2 -- settle/reject/void etc. : delete it
		WHEN i.statusid = 0 AND d.statusid = 1 THEN 3 -- waiting->running : update it
		END
	FROM
		INSERTED i
		INNER JOIN DELETED d ON i.transid = d.transid
	
	IF EXISTS (SELECT 1 FROM #list WHERE tag = 1)
		INSERT INTO dbo.bettrans_running (
			[transid],[transdate],[matchid],[refno],[odds],[bettype],[betteam],
			[hdp1],[hdp2],[oddstype],[modds],[stake],[actual_stake],[liveindicator],[livehomescore],[liveawayscore],
			[status],[statusID],[ruben],[betid],[SecAcceptFlag],[checktime],
			[username],[custid],[recommend],[mrecommend],[srecommend],
			[apositiontaking],[mpositiontaking],[spositiontaking],[tpositiontaking],[discount],[adiscount],[sdiscount],
			[IP]
		)
		SELECT
			i.[transid],[transdate],[matchid],[refno],[odds],[bettype],[betteam],
			[hdp1],[hdp2],[oddstype],[modds],[stake],[actual_stake],[liveindicator],[livehomescore],[liveawayscore],
			[status],[statusID],[ruben],[betid],[SecAcceptFlag],[checktime],
			[username],[custid],[recommend],[mrecommend],[srecommend],
			[apositiontaking],[mpositiontaking],[spositiontaking],[tpositiontaking],[discount],[adiscount],[sdiscount],
			[IP]
		FROM INSERTED i
			INNER JOIN #list l ON i.transid = l.transid AND l.tag = 1

	IF EXISTS (SELECT 1 FROM #list WHERE tag = 3)
		UPDATE BR
		SET statusid = i.statusid,
			[status]= i.[status],
			checktime = i.checktime
		FROM dbo.bettrans_running BR
			INNER JOIN INSERTED i ON BR.transid = i.transid
			INNER JOIN #list l ON i.transid = l.transid AND l.tag = 3

	IF EXISTS (SELECT 1 FROM #list WHERE tag = 2)
		INSERT INTO dbo.bettrans_running_toDelete (transid)
		SELECT transid
		FROM #list l
		WHERE l.tag = 2
	/*	DELETE br
		FROM dbo.bettrans_running br
			INNER JOIN #list l ON br.transid = l.transid AND l.tag = 2
	*/
	
END




