ALTER PROCEDURE [dbo].[Acc_DailyCreatedCustomer_Details]
	@Date DATETIME,
	@RoleID INT
AS

/*	Creator: Simon
		Date: 2009-12-08
		Task: Daily Created Customers Detail Report
		DB: DBACC/bodb02		
		
		Revisions:
			- 20130224@Lukas: move table Acc_CustDirect to new database bodb_ACC
*/	

SET NOCOUNT ON

SET @Date=CONVERT(CHAR(10),@Date,120)

-- Super List
if (@RoleID=4)  
Begin
	SELECT c.custid, c.UserName, c.CreatDate, o.UserName Creator
	FROM customer c WITH (NOLOCK)
		LEFT JOIN CustInfo o with(nolock) on o.custid = c.Creator  
	WHERE c.RoleID = 4
		AND CONVERT(CHAR(10),c.creatdate,120) = @Date
	ORDER BY c.UserName DESC
End
-- Direct Master List
ELSE IF (@RoleID=3) 
Begin
	SELECT c.custid, c.UserName, c.CreatDate, o.UserName Creator
	FROM bodb_acc.dbo.Acc_CustDirect r  WITH (NOLOCK)
		LEFT JOIN customer c WITH (NOLOCK) ON c.srecommend = r.custid 
		LEFT JOIN CustInfo o with(nolock) on o.custid = c.Creator  
	WHERE c.RoleID = 3
		AND r.RoleID = 4
		AND CONVERT(CHAR(10),c.creatdate,120) = @Date
	ORDER BY c.UserName DESC
End
-- Direct Agent List
ELSE -- @RoleID==2
Begin
	SELECT c.custid, c.UserName, c.CreatDate, o.UserName Creator
	FROM bodb_acc.dbo.Acc_CustDirect r  WITH (NOLOCK)
		LEFT JOIN customer c WITH (NOLOCK) ON c.mrecommend = r.custid 
		LEFT JOIN CustInfo o with(nolock) on o.custid = c.Creator  
	WHERE c.RoleID = 2
		AND r.RoleID = 3
		AND CONVERT(CHAR(10),c.creatdate,120) = @Date
	ORDER BY c.UserName DESC
End

GO
GRANT EXECUTE ON dbo.[Acc_DailyCreatedCustomer_Details] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_DailyCreatedCustomer_Details] TO [vnteam]