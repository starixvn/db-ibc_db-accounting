/*<info serverAlias="DBLOG-bodb_CustomerLog" ></info>*/

USE bodb_CustomerLog
GO
/*
   Created: Malcolm
	Date: 2020-04-01
	Task: add logaction for admin/finance code when insert/delete  - [Redmine: #128128]
	DB: DBLOG/bodb_CustomerLog

	Revisions:
		- 20200401@Malcolm:  add logaction for admin/finance code when insert/delete - [Redmine: #128128]
	Parameter's explaination:
*/
Insert LogAction(ActionID, ActionTypeID,SPName,ActionNameEN,ActionNameCH,ActionNameCS,ActionNameJP,ActionNameIT,ActionNameTH,ActionNameKO,XsltContent,IsInternal,ActionNameVI,ActionNameCN)
Values(95003,4,'Acc_FinancePermissionIns','Insert Admin / finance code','Insert Admin / finance code','Insert Admin / finance code','Insert Admin / finance code',NULL,'Insert Admin / finance code','Insert Admin / finance code',null,0,'Insert Admin / finance code','Insert Admin / finance code'),

(95004,4,'Acc_FinancePermissionDel','Delete Admin / finance code','Delete Admin / finance code','Delete Admin / finance code','Delete Admin / finance code',NULL,'Delete Admin / finance code','Delete Admin / finance code',null,0,'Delete Admin / finance code','Delete Admin / finance code')

