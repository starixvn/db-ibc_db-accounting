ALTER PROCEDURE [dbo].[DBA_ReInit_bettrans_forecast_agent]
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


	TRUNCATE TABLE bettrans_forecast_agent
	TRUNCATE TABLE bettrans_trigger_agent

		-- Insert statements for trigger here
	INSERT INTO	dbo.bettrans_trigger_agent
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
		bodb02.dbo.bettrans
	WHERE
		bettype IN (1,3,7,8,2,12,20,21,22,23,28,5,15)
		AND statusID IN (0,1)

