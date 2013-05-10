 ALTER PROCEDURE [dbo].[Acc_OperatorSelByID]   
 @CustID int  
AS  
/*
Created: 
Task : Get the information of operator by custID
DB: DB053.bodb02
Revisions:
						
Parameters Explanation:
	
*/
SET NOCOUNT ON  
Select  
 CustID, UserName, FirstName, LastName, Address, City, State, Country, Postal, Email, Phone, MobilePhone, Fax, RoleID   
from Customer with (NOLOCK)   
where CustID = @CustID  

GO
GRANT EXECUTE ON [dbo].[Acc_OperatorSelByID] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_OperatorSelByID] TO [vnteam] AS [dbo]