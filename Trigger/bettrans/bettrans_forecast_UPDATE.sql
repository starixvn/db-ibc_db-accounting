USE [bodb02]
GO

/****** Object:  Trigger [dbo].[bettrans_forecast_UPDATE]    Script Date: 01/24/2013 02:52:30 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TRIGGER [dbo].[bettrans_forecast_UPDATE] 
   ON  [dbo].[bettrans]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
/*
Created: 
Task : 
DB: DBAGE/bodb02
Original:

Revisions:
	- 20130121@Dan: update trriger because moving bettrans_trigger_agent table to new bodb_AGE DB 
	
Param's Explanation:

statusID
  1 : waiting
  0 : running

waiting -> running (1->0)   : remove 1, add 0
waiting -> reject  (1->101) : remove 1, add nothing
running -> void    (0->1xx) : remove 0, add nothing
running -> settle  (0->1xx) : remove 0, add nothing
reject  -> running (1xx->0) : remove nothing, add 0
void  -> running (1xx->0) : remove nothing, add 0
                  summary = remove 0/1, add 0
*/

	SET NOCOUNT ON;

    -- Insert statements for trigger here
	Declare @cnt int
	SELECT @cnt = COUNT(*) FROM INSERTED

	--IF @cnt <= 100
	BEGIN
	
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
			betteam, odds, -stake, apositiontaking, mpositiontaking, spositiontaking,
			-1
		FROM
			deleted
		WHERE
			bettype IN (1,3,7,8,2,12,20,21,22,23,28,5,15)
			--AND liveindicator = 1
			AND statusID IN (0,1)

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
			AND statusID = 0
	END /*
	ELSE
	BEGIN
		INSERT INTO	dbo.bettrans_trigger_agent
		(
			transid, transdate, recommend, mrecommend, srecommend,
			matchid, bettype, statusID, hdp1, hdp2, liveindicator, livehomescore, liveawayscore,
			betteam, odds, stake, apositiontaking, mpositiontaking, spositiontaking,
			countas
		)
		SELECT
			MIN(transid), MIN(transdate), recommend, MIN(mrecommend), MIN(srecommend),
			matchid, bettype, statusID, hdp1, hdp2, liveindicator, livehomescore, liveawayscore,
			betteam, odds, -SUM(stake), apositiontaking, mpositiontaking, spositiontaking,
			SUM(-1)
		FROM
			deleted
		WHERE
			bettype IN (1,3,7,8,2,12,20,21,22,23,28,5,15)
			--AND liveindicator = 1
			AND statusID IN (0,1)
		GROUP BY
			recommend, 
			matchid, bettype, statusID, hdp1, hdp2, liveindicator, livehomescore, liveawayscore,
			betteam, odds, apositiontaking, mpositiontaking, spositiontaking
		

		INSERT INTO	dbo.bettrans_trigger_agent
		(
			transid, transdate, recommend, mrecommend, srecommend,
			matchid, bettype, statusID, hdp1, hdp2, liveindicator, livehomescore, liveawayscore,
			betteam, odds, stake, apositiontaking, mpositiontaking, spositiontaking,
			countas
		)
		SELECT
			MIN(transid), MIN(transdate), recommend, MIN(mrecommend), MIN(srecommend),
			matchid, bettype, statusID, hdp1, hdp2, liveindicator, livehomescore, liveawayscore,
			betteam, odds, SUM(stake), apositiontaking, mpositiontaking, spositiontaking,
			SUM(1)
		FROM
			inserted
		WHERE
			bettype IN (1,3,7,8,2,12,20,21,22,23,28,5,15)
			--AND liveindicator = 1
			AND statusID = 0
		GROUP BY
			recommend,
			matchid, bettype, statusID, hdp1, hdp2, liveindicator, livehomescore, liveawayscore,
			betteam, odds, apositiontaking, mpositiontaking, spositiontaking
		
	END */
END
GO


