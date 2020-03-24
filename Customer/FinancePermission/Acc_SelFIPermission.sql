/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_SelFIPermission]
	@UserID INT,
	@username VARCHAR(30),
	@CheckCustId TINYINT = 0
	
AS
/*
Created: 20200212@Tiara
Task :  Arrange detail permission for finance account 
DB: DBCUST/CUSTDB
Original:

	Revisions:
		- 20200211@Tiara: Arrange detail permission for finance account [Redmine: #128128]
		- 20200317@malcolm :  Arrange detail permission for finance account [Redmine: #128128]
*/

BEGIN
DECLARE @IsView BIT = NULL,@Username_s  NVARCHAR(50), @Username_m NVARCHAR(50), @Username_r NVARCHAR(50) , @Username_p NVARCHAR(50), 
		@GroupId SMALLINT = 0, @CustId INT, @Roleid SMALLINT, @Username_Login NVARCHAR(50)

SELECT @Username_Login =  username FROM Customer WITH (NOLOCK) WHERE custid = @UserID

SELECT @GroupId = ISNULL(GroupId,0) 
FROM dbo.Acc_FinancePermission WITH(NOLOCK) 
WHERE FinanceCode = @Username_Login AND RoleId > 4

IF @GroupId = 1
   SELECT @IsView = 1
		
IF @IsView IS  NULL
BEGIN
    EXEC @CustId = DBACC.bodb02.dbo.f_GetCustIDFromUsernameOrCustId @username, @CheckCustId


	SELECT @Username_s = Su.username, 
           @Username_m = Ma.username, 
		   @Username_r = Ag.username, 
		   @Username_p = p.username, 
		   @Roleid     = p.roleid
	FROM dbo.Customer p WITH(NOLOCK)
	     LEFT JOIN dbo.Customer Ag WITH (NOLOCK) ON p.recommend  = Ag.custid
		 LEFT JOIN dbo.Customer Ma WITH (NOLOCK) ON p.mrecommend = Ma.custid
		 LEFT JOIN dbo.Customer Su WITH (NOLOCK) ON p.srecommend = Su.custid	      
	 WHERE p.custid = @CustId

	SELECT TOP(1) @IsView = CASE WHEN @GroupId = 0 THEN 0 
								 ELSE IsView END
	FROM dbo.Acc_FinancePermission f WITH(NOLOCK)
	WHERE FinanceCode IN (@Username_s, @Username_m, @Username_r, @Username_p) 
		  AND GroupId = @GroupId  OR (@GroupId = 0)
		  AND f.RoleId BETWEEN 1 AND 4
	ORDER BY RoleId ASC

END

SELECT ISNULL(@IsView,1) AS IsView

END
