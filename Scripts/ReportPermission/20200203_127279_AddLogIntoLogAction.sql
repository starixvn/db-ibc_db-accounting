/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="bodbAdminNet"  isFunction="0" isNested="0"></info>*/

USE bodb_CustomerLog
GO
/*
   Created: Malcolm
	Date: 2020-02-04
	Task:   Configuration for CN88 Headlines to view all periods - [Redmine: #127520]
	DB: DBLOG/bodb_CustomerLog

	Revisions:
		- 20200122@Malcolm:  Configuration for CN88 Headlines to view all periods - [Redmine: #127520]
	Parameter's explaination:
*/
Insert LogAction(ActionID, ActionTypeID,SPName,ActionNameEN,ActionNameCH,ActionNameCS,ActionNameJP,ActionNameIT,ActionNameTH,ActionNameKO,XsltContent,IsInternal,ActionNameVI,ActionNameCN)
Values(95002,4,'CS_ReportPermission_Upd','Update view all periods','Update view all periods','Update view all periods','Update view all periods',NULL,'Update view all periods','Update view all periods',null,0,'Update view all periods','Update view all periods')