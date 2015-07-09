ALTER TRIGGER [dbo].[custOverride3rd_update] ON [dbo].[custOverride3rd]
AFTER UPDATE
AS
/*
	Created by: ... 
	Task: Trigger for Updating custOverride3rd  
	DB: DB052.BODB02 
	
	Revisions: 
	
*/
SET NOCOUNT ON;


INSERT INTO bodb_CustomerLog.dbo.custOverride3rd_history
                (custid, bettype, sporttype, minpositiontaking,maxpositiontaking, minlivepositiontaking, maxlivepositiontaking)
SELECT
                custid, bettype, sporttype, minpositiontaking, maxpositiontaking, minlivepositiontaking, maxlivepositiontaking
FROM [DELETED]
GO 

