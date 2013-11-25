ALTER PROCEDURE [dbo].[Acc_DailyCreatedCustomer_Details]
	@Date DATETIME,
	@RoleID INT,
	@IsDirect BIT  = 1
AS

/*	Creator: Simon
		Date: 2009-12-08
		Task: Daily Created Customers Detail Report
		DB: DBACC/bodb02		
		
		Revisions:
			- 20130224@Lukas: move table Acc_CustDirect to new database bodb_ACC
			- 20131106@Kathy: [Redmine:#6837]
					+ Add @IsDirect
					+ Add Master, Agent, Member's detail
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
	Order BY c.creatdate DESC, c.username
End
-- Direct Master & Master list
ELSE IF (@RoleID=3) 
Begin
	IF @IsDirect = 1
	BEGIN
		SELECT c.custid, c.UserName, c.CreatDate, o.UserName Creator
		FROM bodb_acc.dbo.Acc_CustDirect r  WITH (NOLOCK)
			LEFT JOIN customer c WITH (NOLOCK) ON c.srecommend = r.custid 
			LEFT JOIN CustInfo o with(nolock) on o.custid = c.Creator  
		WHERE c.RoleID = 3
			AND r.RoleID = 4
			AND CONVERT(CHAR(10),c.creatdate,120) = @Date
		Order BY c.creatdate DESC, c.username
	END
	ELSE IF @IsDirect = 0
	BEGIN
		SELECT c.custid, c.username, c.creatdate, ci.username as creator
		FROM Customer c with(NOLOCK)
		Left JOIN custInfo ci WITH(NOLOCK) ON ci.custid = c.creator
		where c.roleid = 3
			AND c.srecommend not in (SELECT r.custid FROM bodb_acc.dbo.Acc_CustDirect r  WITH (NOLOCK) WHERE r.roleid = 4)
			AND CONVERT(CHAR(10),c.creatdate,120) = @Date
		ORDER BY c.creatdate DESC, c.username
	END
	
End
-- Direct Agent & Agent list
ELSE IF @RoleID = 2
Begin
	IF @IsDirect = 1
	BEGIN
		SELECT c.custid, c.UserName, c.CreatDate, o.UserName Creator
		FROM bodb_acc.dbo.Acc_CustDirect r  WITH (NOLOCK)
			LEFT JOIN customer c WITH (NOLOCK) ON c.mrecommend = r.custid 
			LEFT JOIN CustInfo o with(nolock) on o.custid = c.Creator  
		WHERE c.RoleID = 2
			AND r.RoleID = 3
			AND CONVERT(CHAR(10),c.creatdate,120) = @Date
		Order BY c.creatdate DESC, c.username
	END
	ELSE IF @IsDirect = 0
	BEGIN
		SELECT c.custid, c.username, c.creatdate, ci.username as Creator
		FROM Customer c with(NOLOCK)
		Left JOIN custInfo ci WITH(NOLOCK) ON ci.custid = c.creator
		where c.roleid = 2
			and c.mrecommend not in (SELECT r.custid FROM bodb_acc.dbo.Acc_CustDirect r  WITH (NOLOCK) WHERE r.roleid = 3)
			and  CONVERT(CHAR(10),c.creatdate,120) = @Date
		Order BY c.creatdate DESC, c.username
	END
End
ELSE IF @RoleId = 1 -- Member list
BEGIN
	SELECT c.custid, c.username, c.creatdate, ci.username as Creator
		FROM Customer c with(NOLOCK)
		Left JOIN custInfo ci WITH(NOLOCK) ON ci.custid = c.creator
		where c.roleid = 1
			and  CONVERT(CHAR(10),c.creatdate,120) = @Date
		Order BY c.creatdate DESC, c.username
END




GO
GRANT EXECUTE ON dbo.[Acc_DailyCreatedCustomer_Details] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_DailyCreatedCustomer_Details] TO [vnteam]