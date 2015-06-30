ALTER TRIGGER [dbo].[custsettinggame_update] ON [dbo].[CustSettingGame]
AFTER UPDATE
AS
/*
	Created by: ... 
	Task: Trigger for Updating custsettingGame  
	DB: DBEXT/BODB02 
	
	Revisions: 
		- 20140207@Johnson: add setting history for user online opus game
	
*/
BEGIN
	SET NOCOUNT ON;

	CREATE TABLE #settings 
		(		
			[CustID] [int],
			[Bettype] [smallint] ,
			[Sporttype] [smallint] ,
			[apositiontaking] [smallmoney] ,
			[mpositiontaking] [smallmoney] ,
			[spositiontaking] [smallmoney] ,
			[playerdiscount] [decimal](9, 8),
			[discount] [decimal](9, 8) ,
			[adiscount] [decimal](9, 8) ,
			[sdiscount] [decimal](9, 8) ,
			[autopositiontaking] [smallmoney],
			[isautopositiontaking] [bit],
			[autompositiontaking] [smallmoney],
			[isautompositiontaking] [bit]
		)


	INSERT INTO #settings
		( CustID, Bettype, Sporttype, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, adiscount, sdiscount, autopositiontaking, isautopositiontaking, autompositiontaking, isautompositiontaking)
	SELECT CustID, Bettype, Sporttype, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, adiscount, sdiscount, autopositiontaking, isautopositiontaking, autompositiontaking, isautompositiontaking
	FROM [DELETED]

	--Insert history setting into CustSettingGame_history
	INSERT INTO bodb_CustomerLog.dbo.custsetting_history
		( CustID, Bettype, Sporttype, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, adiscount, sdiscount, autopositiontaking, isautopositiontaking, autompositiontaking, isautompositiontaking)
	SELECT CustID, Bettype, Sporttype, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, adiscount, sdiscount, autopositiontaking, isautopositiontaking, autompositiontaking, isautompositiontaking
	FROM #settings

	--Check if update opus settings
	IF EXISTS (SELECT TOP (1) 1 FROM #settings where sporttype = 163)
	BEGIN
		--check user online opus casino
		;WITH T as 
		(
			SELECT custid
			FROM bettrans with(NOLOCK)
			WHERE custid IN (SELECT custid FROM #settings)
				AND bettype IN (23301,23302)
				AND statusid = 0
				AND matchid = 0
		)
		
		INSERT INTO bodb_CustomerLog.dbo.custsettingOpusHistory
           ([CustID]
           ,[Bettype]
           ,[Sporttype]
           ,[apositiontaking]
           ,[mpositiontaking]
           ,[spositiontaking]
           ,[playerdiscount]
           ,[discount]
           ,[adiscount]
           ,[sdiscount]
           )
		SELECT [CustID]
           ,[Bettype]
           ,[Sporttype]
           ,[apositiontaking]
           ,[mpositiontaking]
           ,[spositiontaking]
           ,[playerdiscount]
           ,[discount]
           ,[adiscount]
           ,[sdiscount]
		FROM #settings
		WHERE custid IN (SELECT custid FROM T)
			AND sporttype = 163         
     
	END
END
GO


