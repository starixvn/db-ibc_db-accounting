ALTER PROCEDURE [dbo].[DBA_ReInit_bettrans_running]
AS
/*
Created: 
Task : 
DB: DBAGE/bodb_AGE
Original:

Revisions:
	- 20130121@Dan: Move sp from DB053/bodb02 to DBAGE/bodb_AGE
	
Param's Explanation: 

*/	

	TRUNCATE TABLE bettrans_running
	
    -- Insert statements for trigger here
	INSERT INTO dbo.bettrans_running (
		[transid],[transdate],[matchid],[refno],[odds],[bettype],[betteam],
		[hdp1],[hdp2],[oddstype],[modds],[stake],[actual_stake],[liveindicator],[livehomescore],[liveawayscore],
		[status],[statusID],[ruben],[betid],[SecAcceptFlag],[checktime],
		[username],[custid],[recommend],[mrecommend],[srecommend],
		[apositiontaking],[mpositiontaking],[spositiontaking],[tpositiontaking],[discount],[adiscount],[sdiscount],
		[IP]
	)
	SELECT
		[transid],[transdate],[matchid],[refno],[odds],[bettype],[betteam],
		[hdp1],[hdp2],[oddstype],[modds],[stake],[actual_stake],[liveindicator],[livehomescore],[liveawayscore],
		[status],[statusID],[ruben],[betid],[SecAcceptFlag],[checktime],
		[username],[custid],[recommend],[mrecommend],[srecommend],
		[apositiontaking],[mpositiontaking],[spositiontaking],[tpositiontaking],[discount],[adiscount],[sdiscount],
		[IP]
	FROM bodb02.dbo.bettrans
	WHERE statusID IN (0,1)

