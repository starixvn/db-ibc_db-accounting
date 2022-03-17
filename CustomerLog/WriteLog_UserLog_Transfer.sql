/*<info serverAlias="DBLOG-bodb_CustomerLog,DBTXN-bodb_CustomerLog" executers="bodbDownlineNet,bodbDownlineNetView,bodbAdminNet,bodbExtAccNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[WriteLog_UserLog_Transfer]
	@UserID int, 
	@FromCustID INT, 
	@ToCustID INT, 
	@IP varchar(45)='',
	@Doing varchar(1000)=''
AS
/*
Creator: Kiwi
Date: 03/10/2009
DB: bodb_CustomerLog
Task: Insert LOGS for Trasfer function

Revisions:
	- 20211221@Danny: Extend data Type support IPv6  [Redmine: #164196]

*/

SET NOCOUNT ON;

INSERT INTO dbo.UserLog_Transfer(	UserID,
									FromCustID,
									ToCustID,
									IP,
									Doing) 
							VALUES(	@UserID,
									@FromCustID,
									@ToCustID,
									@IP,
									@Doing)

GO
