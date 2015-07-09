
ALTER TRIGGER [dbo].[custOverride_update] ON [dbo].[custOverride]

AFTER UPDATE

AS
/*
	Created by: ... 
	Task: Trigger for Updating custOverride  
	DB: DB052.BODB02 
	
	Revisions: 
	
*/
SET NOCOUNT ON;

INSERT INTO bodb_CustomerLog.dbo.custOverride_history (
                    custid, bettype, sporttype, minpositiontaking,
                maxpositiontaking, minlivepositiontaking, maxlivepositiontaking)
SELECT
                    custid, bettype, sporttype, minpositiontaking,
                maxpositiontaking, minlivepositiontaking, maxlivepositiontaking
FROM [DELETED]