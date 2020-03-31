/*<info serverAlias="DBLOG-bodb_CustomerLog" ></info>*/

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
SELECT  95005,4,'Acc_Bettype_Ins','insert new bettypes','insert new bettypes','insert new bettypes','insert new bettypes',NULL,'insert new bettypes','insert new bettypes',null,0,'insert new bettypes','insert new bettypes'
UNION ALL
SELECT  95006,4,'Acc_Bettype_Upd','Insert new bettypes','Insert new bettypes','Insert new bettypes','Insert new bettypes',NULL,'Insert new bettypes','Insert new bettypes',null,0,'Insert new bettypes','Insert new bettypes'
UNION ALL
SELECT  95007,4,'Acc_Sporttype_Ins','Insert new Sports','Insert new Sports','Insert new Sports','Insert new Sports',NULL,'Insert new Sports','Insert new Sports',null,0,'Insert new Sports','Insert new Sports'
UNION ALL
SELECT  95007,4,'Acc_Sporttype_Upd','Update Sports','Update Sports','Update Sports','Update Sports',NULL,'Update Sports','Update Sports',null,0,'Update Sports','Update Sports'





