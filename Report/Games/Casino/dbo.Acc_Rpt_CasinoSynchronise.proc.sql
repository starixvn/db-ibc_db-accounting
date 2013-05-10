ALTER PROCEDURE [dbo].[Acc_Rpt_CasinoSynchronise]
	@Keyword nvarchar(20) = '',
	@SearchBy bit, -- 0: Casino  ;  1: IBC.
	@RoleID tinyint = 0 output
AS
/*	Created by: Anh Tuan
	Date: 2009-03-25
	DB: DB05.BODB02
	Task: Get Casino unSynchronised List.	
*/

SET NOCOUNT ON

Declare @CustID int
	
Select @CustID = CustID, @RoleID=RoleID
FROM 	custinfo WITH (nolock)
Where	username = @Keyword 
		
select custid, username, roleid, srecommend, mrecommend, recommend, disableCasino 
from custinfo WITH (nolock)
where syncCasino = @SearchBy and (srecommend=@CustID or mrecommend=@CustID or recommend=@CustID or CustID=@CustID)
order by srecommend,mrecommend asc,recommend asc,username asc

GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_CasinoSynchronise] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_CasinoSynchronise] TO [vnteam]