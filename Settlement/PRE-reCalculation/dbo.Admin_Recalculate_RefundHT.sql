

ALTER PROCEDURE [dbo].[Admin_Recalculate_RefundHT]
	@matchid int
AS
/*	
	Created by: 20111116@Lukas
	Task: Refund HT 
	DB: DB052.BODB_REVIEW

	Revisions:
		- 20100818@Henry:  Allow to refund 1st Half Money Line
		- 20110912@Tom: Add new bettypes 30
				apply new bet type 1st correct score on Sport Books	
		
*/
SET NOCOUNT ON

WHILE 1=1
BEGIN
    UPDATE TOP (10000) dbo.bettrans with (ROWLOCK, UPDLOCK)
	SET
		[status] = N'Refund',
		statusID = 103,
		ruben = 1,
		winlost=actual_stake,
		awinlost=0,
		mwinlost=0,
		swinlost=0,
		playercomm=0,
		comm=0,
		acomm=0,
		scomm=0
	where
		matchid=@matchid
		--AND [status] not in (N'Void', N'Reject')
		AND statusID not in (103,101,102)
		AND bettype IN (7, 8, 15, 12,21,30) 
		
	IF @@ROWCOUNT < 10000 BREAK
END

