/*<info serverAlias="DBLOG-bodb_CustomerLog" ></info>*/

USE bodb_CustomerLog
GO
/*
   Created: Malcolm
	Date: 2020-04-16
    Task: Manage Products/Sporttype/Bettype - [Redmine: #131241]
	DB: DBLOG/bodb_CustomerLog

	Revisions:
		- 20200416@Malcolm:  Task: Manage Products/Sporttype/Bettype - [Redmine: #131241]
	Parameter's explaination:
*/
Insert LogAction(ActionID, ActionTypeID,SPName,ActionNameEN,ActionNameCH,ActionNameCS,ActionNameJP,ActionNameIT,ActionNameTH,ActionNameKO,XsltContent,IsInternal,ActionNameVI,ActionNameCN)
SELECT  95013,4,'Acc_SportBettypeMatrix_Ins','Insert into SportBettypeMatrix table','Insert into SportBettypeMatrix table','Insert into SportBettypeMatrix table','Insert into SportBettypeMatrix table',NULL,'Insert into SportBettypeMatrix table','Insert into SportBettypeMatrix table',null,0,'Insert into SportBettypeMatrix table','Insert into SportBettypeMatrix table'
UNION ALL
SELECT  95014,4,'Acc_SportBettypeMatrix_Upd','Update SportBettypeMatrix table','Update SportBettypeMatrix table','Update SportBettypeMatrix table','Update SportBettypeMatrix table',NULL,'Update SportBettypeMatrix table','Update SportBettypeMatrix table',null,0,'Update SportBettypeMatrix table','Update SportBettypeMatrix table'





