


USE [bodb_CustomerLog]
GO
/****** Object:  StoredProcedure [dbo].[Task_DeleteHistoryLogData]    Script Date: 05/23/2013 03:16:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Task_DeleteHistoryLogData]
AS
/*
	Created: 
	Task: delete old data in history tables
	DB: DBLOG/bodb_customerLog
	
	Revisions:
		- 20130523@Lukas: add more tables that need to delete old data
*/
BEGIN
	DECLARE @LastKeepDate datetime
	SELECT @LastKeepDate = dateadd(d, -60, getdate())

	SET NOCOUNT ON
	-------------------custSetting_history-------------------
	WHILE 1=1
	BEGIN
		DELETE TOP(1000) FROM dbo.custSetting_history WITH(ROWLOCK,UPDLOCK) where updateTime < @LastKeepDate
	      
		IF @@ROWCOUNT < 1000
			BREAK

		WAITFOR DELAY '000:00:00.200'
	END

	WHILE 1=1
	BEGIN
		DELETE TOP(1000) FROM dbo.custSetting3rd_history WITH(ROWLOCK,UPDLOCK) where updateTime < @LastKeepDate
	      
		IF @@ROWCOUNT < 1000
			BREAK

		WAITFOR DELAY '000:00:00.200'
	END

	-------------------custOverride_history-------------------
	WHILE 1=1
	BEGIN
		DELETE TOP(1000) FROM dbo.custOverride_history WITH(ROWLOCK,UPDLOCK) where updateTime < @LastKeepDate
	      
		IF @@ROWCOUNT < 1000
			BREAK

		WAITFOR DELAY '000:00:00.200'
	END

	WHILE 1=1
	BEGIN
		DELETE TOP(1000) FROM dbo.custOverride3rd_history WITH(ROWLOCK,UPDLOCK) where updateTime < @LastKeepDate
	      
		IF @@ROWCOUNT < 1000
			BREAK

		WAITFOR DELAY '000:00:00.200'
	END
	-------------------CustInfo_history-------------------
	WHILE 1=1
	BEGIN
		DELETE TOP(1000) FROM dbo.CustInfo_history WITH(ROWLOCK,UPDLOCK) where updateTime < @LastKeepDate
	      
		IF @@ROWCOUNT < 1000
			BREAK

		WAITFOR DELAY '000:00:00.200'
	END

	-------------------P2PGameSetting_history-------------------
	WHILE 1=1
	BEGIN
		DELETE TOP(1000) FROM dbo.P2PGameSetting_history WITH(ROWLOCK,UPDLOCK) where updateTime < @LastKeepDate
	      
		IF @@ROWCOUNT < 1000
			BREAK

		WAITFOR DELAY '000:00:00.200'
	END


	-------------------P2PGroupComm_history-------------------
	WHILE 1=1
	BEGIN
		DELETE TOP(1000) FROM dbo.P2PGroupComm_history WITH(ROWLOCK,UPDLOCK) where updateTime < @LastKeepDate
	      
		IF @@ROWCOUNT < 1000
			BREAK

		WAITFOR DELAY '000:00:00.200'
	END


	-------------------Live Casino setting history-------------------
	WHILE 1=1
	BEGIN
		DELETE TOP(1000) FROM dbo.custsettingGame_history WITH(ROWLOCK,UPDLOCK) where updateTime < @LastKeepDate
	      
		IF @@ROWCOUNT < 1000
			BREAK

		WAITFOR DELAY '000:00:00.200'
	END

	WHILE 1=1
	BEGIN
		DELETE TOP(1000) FROM dbo.custoverrideGame_history WITH(ROWLOCK,UPDLOCK) where updateTime < @LastKeepDate
	      
		IF @@ROWCOUNT < 1000
			BREAK

		WAITFOR DELAY '000:00:00.200'
	END
	
	-------------------deposit customer setting history-------------------
	WHILE 1=1
	BEGIN
		DELETE TOP(1000) FROM dbo.Dep_custsetting_history WITH(ROWLOCK,UPDLOCK) where updateTime < @LastKeepDate
	      
		IF @@ROWCOUNT < 1000
			BREAK

		WAITFOR DELAY '000:00:00.200'
	END

	WHILE 1=1
	BEGIN
		DELETE TOP(1000) FROM dbo.Dep_custsetting3rd_history WITH(ROWLOCK,UPDLOCK) where updateTime < @LastKeepDate
	      
		IF @@ROWCOUNT < 1000
			BREAK

		WAITFOR DELAY '000:00:00.200'
	END
	SET NOCOUNT OFF

END
