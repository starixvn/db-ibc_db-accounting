

ALTER PROCEDURE [dbo].[Task_Delete_bettrans_running]
AS

DELETE TOP(500)
FROM bodb_AGE.dbo.bettrans_running_toDelete

DELETE TOP(500)
FROM dbo.bettrans_running_toDelete

IF @@ROWCOUNT = 0
	WAITFOR DELAY '00:00:15.000'