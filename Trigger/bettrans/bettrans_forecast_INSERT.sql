ALTER TRIGGER [dbo].[bettrans_forecast_INSERT]
   ON  [dbo].[bettrans]
   AFTER INSERT
AS 
/*
Created: 
Task : 
DB: DBAGE/bodb02
Original:

Revisions:
	- 20130121@Dan: update trriger because moving bettrans_trigger_agent table to new bodb_AGE DB 
	
Param's Explanation: 

*/	
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
INSERT INTO	bodb_AGE.dbo.bettrans_trigger_agent
(
	transid, transdate, recommend, mrecommend, srecommend,
	matchid, bettype, statusID, hdp1, hdp2, liveindicator, livehomescore, liveawayscore,
	betteam, odds, stake, apositiontaking, mpositiontaking, spositiontaking,
	countas
)
SELECT
	transid, transdate, recommend, mrecommend, srecommend,
	matchid, bettype, statusID, hdp1, hdp2, liveindicator, livehomescore, liveawayscore,
	betteam, odds, stake, apositiontaking, mpositiontaking, spositiontaking,
	1
FROM
	inserted
WHERE
	bettype IN (1,3,7,8,2,12,20,21,22,23,28,5,15)
	--AND liveindicator = 1
	AND statusID IN (0,1)
END
GO


