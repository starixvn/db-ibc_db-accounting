/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="bodbAdminNet" viewers="" isFunction="0" isNested="1"></info>*/
USE [bodb_CustomerLog]
GO

ALTER PROCEDURE [dbo].[WriteLog_UserLog_ExchangeRate]
	@UserID INT, 
	@ExchangeID INT, 
	@actualrate FLOAT = NULL,
	@PJUnitPrice DECIMAL(19,8) = NULL,
	@IP VARCHAR(15) = '',
	@Doing VARCHAR(1000) = ''
AS

/*
	Creator: Daniel
	Date: 03/10/2009
	DB: DBLOG.bodb_CustomerLog
	Task: Insert LOGS for update exchange rate, PJUnitPrice

	Revisions:
		- 20180202@Percy: Add PJUnitPrice column [RedmineID: #89122]
*/

BEGIN
	SET NOCOUNT ON

	INSERT INTO dbo.UserLog_Exchange (UserID, ExchangeID, actualrate, PJUnitPrice, Doing, IP) 
	VALUES (@UserID, @ExchangeID, @actualrate, @PJUnitPrice, @Doing, @IP)
END
GO