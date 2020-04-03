/*<info serverAlias="DBCUST-CustDB" ></info>*/
USE CustDB
GO

/*
   Created: Malcolm
	Date: 2020-04-03
	Task:   Add finance code/ finance user - [Redmine: #128128]
	DB: DBCUST/CustDB

	Revisions:
		- 20200403@Malcolm:  Add finance code/ finance user - [Redmine: #128128]
	Parameter's explaination:
*/

--for test
INSERT INTO dbo.Acc_FinancePermission (GroupId, FinanceCode,RoleId,IsView)
VALUES (1,'starix16',6,0),
(3,'starix23',6,0),
(6,'starix27',6,0),
(2,'starix47',6,0),
(5,'starix59',6,0),
(4,'starix77',6,0)
