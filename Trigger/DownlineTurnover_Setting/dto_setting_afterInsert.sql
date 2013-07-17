
ALTER TRIGGER [dbo].[dto_setting_afterInsert]
   ON  [dbo].[DownlineTurnOver_Setting]
   AFTER INSERT
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
	
	DELETE D
	FROM dbo.DownlineTurnOver_Trigger D WITH(ROWLOCK,UPDLOCK)
	INNER JOIN inserted i ON i.custid = D.srecommend AND i.matchid = D.matchid
	
	DELETE T
	FROM dbo.DownlineTurnOver_Trigger_tmp T WITH(ROWLOCK,UPDLOCK)
	INNER JOIN inserted i ON i.custid = T.srecommend AND i.matchid = T.matchid
	
    -- Insert statements for trigger here
    INSERT INTO dbo.DownlineTurnOver_Trigger (srecommend, matchid, sumstake)
    SELECT b.srecommend, b.matchid, SUM(b.stake) sumstake
    FROM dbo.bettrans b with (nolock)
		INNER JOIN inserted i ON b.srecommend = i.custid AND b.matchid = i.matchid
	WHERE
		b.statusid NOT IN (101, 102, 103)
	GROUP BY b.srecommend, b.matchid

END
