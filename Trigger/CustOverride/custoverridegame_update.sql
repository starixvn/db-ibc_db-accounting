ALTER TRIGGER [dbo].[custoverridegame_update] ON [dbo].[CustOverrideGame]
AFTER UPDATE
AS
/*
	Created by: ... 
	Task: Trigger for Updating custoverridegame  
	DB: DB052.BODB02 
	
	Revisions: 
	
*/
SET NOCOUNT ON;

INSERT INTO bodb_CustomerLog.dbo.custoverridegame_history
	( CustID, Bettype, Sporttype, minpositiontaking)
SELECT CustID, Bettype, Sporttype, minpositiontaking
FROM [DELETED]
GO