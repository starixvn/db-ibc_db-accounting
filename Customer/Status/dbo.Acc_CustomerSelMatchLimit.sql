ALTER PROCEDURE [dbo].[Acc_CustomerSelMatchLimit] 
	@custid int,
	@matchlimit smallmoney OUTPUT
AS
/*
Created: 
Task : Get max exposure value of customer
DB: DB053.bodb02
Revisions:
						
Parameters Explanation:
	
*/
SET NOCOUNT ON
Select @matchlimit = matchlimit from custinfo with (NOLOCK) where custid = @custid

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelMatchLimit] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerSelMatchLimit] TO [vnteam] AS [dbo]

 