 

ALTER TRIGGER [dbo].[bettrans_DownlineTurnOver_Setting]
   ON  [dbo].[bettrans]
   AFTER INSERT,DELETE,UPDATE
AS 
/*
Created: Joe
Task : Push data to temp table for SMA turnover management
DB: DBAGE/bodb02
Original:

Revisions:	
	
Param's Explanation: 

*/
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	Declare @rc int
	SET @rc = @@ROWCOUNT
	
	SET NOCOUNT ON;
    -- Insert statements for trigger here

	--Determine if this is an INSERT,UPDATE, or DELETE Action or a "failed delete".
	DECLARE @Action as char(1)
    SET @Action = (CASE WHEN EXISTS(SELECT * FROM DELETED)
							THEN
								CASE WHEN EXISTS(SELECT * FROM INSERTED)
									THEN 'U'  -- Set Action to Updated.
									ELSE 'D'  -- Set Action to Deleted.
								END
						WHEN EXISTS(SELECT * FROM INSERTED)
	                        THEN 'I'  -- Set Action to Insert.
                        ELSE '' -- Skip. It may have been a "failed delete".   
                    END)
                    	

	IF @Action = 'I'
	BEGIN
		INSERT INTO dbo.DownlineTurnOver_Trigger (srecommend, matchid, sumstake)
		SELECT srecommend, matchid, 
			SUM(CASE
				WHEN statusid IN (101,102,103) THEN 0
				ELSE stake
				END)
		FROM inserted		
		GROUP BY srecommend, matchid
	END
	
	ELSE IF @Action = 'U'
	BEGIN
		INSERT INTO dbo.DownlineTurnOver_Trigger (srecommend, matchid, sumstake)
		SELECT i.srecommend, i.matchid, 
			SUM(CASE
				WHEN i.statusid IN (101,102,103) AND i.statusid <> d.statusid THEN -i.stake --delete ticket
				WHEN i.statusid = 0 AND d.statusid = 102 THEN i.stake --recover ticket
				WHEN d.statusid  = 103 AND i.statusid <> d.statusid THEN i.stake -- undo or calculate after refund
				ELSE 0
				END)
		FROM inserted i INNER JOIN deleted d ON i.transid = d.transid		
		GROUP BY i.srecommend, i.matchid
	END

	ELSE IF @Action = 'D'
	BEGIN
		INSERT INTO dbo.DownlineTurnOver_Trigger (srecommend, matchid, sumstake)
		SELECT srecommend, matchid, 
			SUM(CASE
				WHEN statusid IN (101,102,103) THEN 0
				ELSE -stake
				END)
		FROM deleted		
		GROUP BY srecommend, matchid
	END
	
END

