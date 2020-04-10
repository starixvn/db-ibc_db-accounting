/*<info serverAlias="DBCUST-CustDB" ></info>*/
USE CustDB
GO

/*
   Created: Malcolm
	Date: 2020-04-03
	Task:   Remove finance code/ finance user - [Redmine: #128128]
	DB: DBCUST/CustDB

	Revisions:
		- 20200403@Malcolm:  Remove finance code/ finance user - [Redmine: #128128]
	Parameter's explaination:
*/

--for test
DELETE 
FROM dbo.Acc_FinancePermission
WHERE GroupId = 1 AND FinanceCode ='starix16'
      OR GroupId = 3 AND FinanceCode ='starix23'
	  OR GroupId = 6 AND FinanceCode ='starix27'
	  OR GroupId = 2 AND FinanceCode ='starix47'
	  OR GroupId = 5 AND FinanceCode ='starix59'
	  OR GroupId = 4 AND FinanceCode ='starix77'

	  
