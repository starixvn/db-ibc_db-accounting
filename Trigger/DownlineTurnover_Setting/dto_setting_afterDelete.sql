ALTER TRIGGER [dbo].[dto_setting_afterDelete]
   ON  [dbo].[DownlineTurnOver_Setting]
   AFTER DELETE
AS 
/*
Created: Joe
Task : 
DB: DBAGE/bodb02
Original:

Revisions:	
	
Param's Explanation: 

*/	
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
    INSERT INTO dbo.DownlineTurnOver_Setting_Delete (custid, matchid)
    SELECT custid, matchid
    FROM deleted

END