ALTER TRIGGER [dbo].[custsettinggame_update] ON [dbo].[CustSettingGame]
AFTER UPDATE
AS
/*
	Created by: ... 
	Task: Trigger for Updating custsettingGame  
	DB: DB052.BODB02 
	
	Revisions: 
	
*/
SET NOCOUNT ON;

INSERT INTO bodb_CustomerLog.dbo.custsettinggame_history
	( CustID, Bettype, Sporttype, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, adiscount, sdiscount, autopositiontaking, isautopositiontaking, autompositiontaking, isautompositiontaking)
SELECT CustID, Bettype, Sporttype, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, adiscount, sdiscount, autopositiontaking, isautopositiontaking, autompositiontaking, isautompositiontaking
FROM [DELETED]


GO


