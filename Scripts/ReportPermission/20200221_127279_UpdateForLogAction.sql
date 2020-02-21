/*<info serverAlias="DBLOG-bodb_CustomerLog" ></info>*/

USE bodb_CustomerLog
GO
/*
   Created: Malcolm
	Date: 2020-02-21
	Task:   update IsInternal = 1 for logAction - [Redmine: #127520]
	DB: DBLOG/bodb_CustomerLog

	Revisions:	
		- 20200221@Malcolm:  update IsInternal = 1 for logAction- [Redmine: #127520]
	Parameter's explaination:
*/

UPDATE t
     SET t.IsInternal = 1
FROM dbo.LogAction t WITH(NOLOCK)
WHERE t.ActionID = 95002




