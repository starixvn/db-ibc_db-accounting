/*<info serverAlias="DBLOG-bodb_CustomerLog" ></info>*/

USE bodb_CustomerLog
GO
/*
   Created: Malcolm
	Date: 2020-03-31
    Task: Manage Products/Sporttype/Bettype - [Redmine: #131241]
	DB: DBLOG/bodb_CustomerLog

	Revisions:
		- 20200331@Malcolm:  Task: Manage Products/Sporttype/Bettype - [Redmine: #131241]
	Parameter's explaination:
*/
Insert LogAction(ActionID, ActionTypeID,SPName,ActionNameEN,ActionNameCH,ActionNameCS,ActionNameJP,ActionNameIT,ActionNameTH,ActionNameKO,XsltContent,IsInternal,ActionNameVI,ActionNameCN)
SELECT  95005,4,'Acc_Bettype_Ins','Insert new bettypes','Insert new bettypes','Insert new bettypes','Insert new bettypes',NULL,'Insert new bettypes','Insert new bettypes',null,0,'Insert new bettypes','Insert new bettypes'
UNION ALL
SELECT  95006,4,'Acc_Bettype_Upd','Update new bettypes','Update new bettypes','Update new bettypes','Update new bettypes',NULL,'Update new bettypes','Update new bettypes',null,0,'Update new bettypes','Update new bettypes'
UNION ALL
SELECT  95007,4,'Acc_Sporttype_Ins','Insert new Sports','Insert new Sports','Insert new Sports','Insert new Sports',NULL,'Insert new Sports','Insert new Sports',null,0,'Insert new Sports','Insert new Sports'
UNION ALL
SELECT  95008,4,'Acc_Sporttype_Upd','Update Sports','Update Sports','Update Sports','Update Sports',NULL,'Update Sports','Update Sports',null,0,'Update Sports','Update Sports'





