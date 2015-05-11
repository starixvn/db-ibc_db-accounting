ALTER TRIGGER [dbo].[bettrans_running_INSERT]
   ON  [dbo].[bettrans]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
	INSERT INTO dbo.bettrans_running (
		[transid],[transdate],[matchid],[refno],[odds],[bettype],[betteam],
		[hdp1],[hdp2],[oddstype],[modds],[stake],[actual_stake],[liveindicator],[livehomescore],[liveawayscore],
		[status],[statusID],[ruben],[comstatus],[betid],[SecAcceptFlag],[checktime],
		[username],[custid],[recommend],[mrecommend],[srecommend],
		[apositiontaking],[mpositiontaking],[spositiontaking],[tpositiontaking],[discount],[adiscount],[sdiscount],
		[IP]
	)
	SELECT
		[transid],[transdate],[matchid],[refno],[odds],[bettype],[betteam],
		[hdp1],[hdp2],[oddstype],[modds],[stake],[actual_stake],[liveindicator],[livehomescore],[liveawayscore],
		[status],[statusID],[ruben],[comstatus],[betid],[SecAcceptFlag],[checktime],
		[username],[custid],[recommend],[mrecommend],[srecommend],
		[apositiontaking],[mpositiontaking],[spositiontaking],[tpositiontaking],[discount],[adiscount],[sdiscount],
		[IP]
	FROM INSERTED
	WHERE statusID IN (0,1)
END
