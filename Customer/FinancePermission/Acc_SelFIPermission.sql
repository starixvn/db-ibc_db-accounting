/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_SelFIPermission]
	@UserID INT,
	@username VARCHAR(30),
	@CheckCustId TINYINT = 1
	
AS
/*
Created: 20200212@Tiara
Task :  Arrange detail permission for finance account 
DB: DBCUST/CUSTDB
Original:

	Revisions:
		- 20200211@Tiara: Arrange detail permission for finance account [Redmine: #128128]
		- 20200317@malcolm :  Arrange detail permission for finance account [Redmine: #128128]
	Param's Explanation:
		- @username : CustId, Username or nickname
		- @CheckCustId = 0 Only check Username or nickname
		               = 1 check CustId, Username or nickname
		- 
		               
*/

BEGIN
DECLARE @IsView BIT = NULL,@Username_s  VARCHAR(30), @Username_m VARCHAR(30), @Username_r VARCHAR(30) , @Username_p VARCHAR(30), 
		@GroupId SMALLINT = -1, @CustId INT, @Roleid SMALLINT, @Username_Login NVARCHAR(50), @IsInternal BIT = 0

SELECT @Username_Login =  username FROM Customer WITH (NOLOCK) WHERE custid = @UserID

SELECT @GroupId = ISNULL(GroupId,-1) 
FROM dbo.Acc_FinancePermission WITH(NOLOCK) 
WHERE FinanceCode = @Username_Login AND RoleId > 4

IF @GroupId = 1
   SELECT @IsView = 1
		
IF @IsView IS  NULL 
BEGIN
    
    EXEC @CustId = dbo.f_GetCustIDFromUsernameOrCustId @username, @CheckCustId


	SELECT @Username_s = Su.username, 
           @Username_m = Ma.username, 
		   @Username_r = Ag.username, 
		   @Username_p = p.username, 
		   @Roleid     = p.roleid,
		   @IsInternal = ISNULL(f.IsInternal, 0)
	FROM dbo.Customer p WITH(NOLOCK)
	     LEFT JOIN dbo.Customer Ag WITH (NOLOCK) ON p.recommend  = Ag.custid
		 LEFT JOIN dbo.Customer Ma WITH (NOLOCK) ON p.mrecommend = Ma.custid
		 LEFT JOIN dbo.Customer Su WITH (NOLOCK) ON p.srecommend = Su.custid	
		 OUTER APPLY 
			(
			     SELECT TOP 1  IsInternal  FROM CustSuper  WITH (NOLOCK) WHERE p.custid    = custid AND p.roleid  = 4
				 UNION ALL 
				 SELECT TOP 1  IsInternal  FROM CustMaster WITH (NOLOCK) WHERE p.custid    = custid AND p.roleid  = 3
				 UNION ALL 
				 SELECT TOP 1  IsInternal  FROM CustAgent  WITH (NOLOCK) WHERE p.custid    = custid AND  p.roleid = 2
				 UNION ALL 
				 SELECT TOP 1  IsInternal  FROM CustAgent  WITH (NOLOCK) WHERE p.recommend = custid AND  p.roleid = 1
			) f
	 WHERE p.custid = @CustId
	/*
      IF @GroupId = -1 OR @IsInternal <> 1 THEN @IsView = NULL (@IsView is not changed)
	  IF @GroupId <> -1 AND @IsInternal = 1
			IF Acc_FinancePermission contain Financode which in (supername, mastername, agentname, playername)
			       IsView = IsView of Username having minimum roleid (ORDER BY RoleId ASC)
	        ELSE IsView = NULL (@IsView is not changed)
	*/
	SELECT TOP(1) @IsView = f.IsView
	FROM dbo.Acc_FinancePermission f WITH(NOLOCK)
	WHERE FinanceCode IN (@Username_s, @Username_m, @Username_r, @Username_p) 
		  AND GroupId = @GroupId 
		  AND f.RoleId BETWEEN 1 AND 4
		  AND @GroupId <> -1
		  AND @IsInternal = 1		  
	ORDER BY RoleId ASC

END
/*
   IF @GroupId = 0 (groupIT)
		IF @IsView <> NULL THEN @IsView = @IsView
		ELSE 1 , allow to view all finance code which not in Acc_FinancePermission table (@GroupId = 0)
   IF @GroupId <> 0 
        IF @IsView <> NULL THEN @IsView = @IsView
		IF @IsView = NULL
		   @IsView = 1 WHEN @IsInternal = 0 (Isn't finance account)
		   @IsView = 0 WHEN @IsInternal = 1 (Is Finance account)
*/
SELECT CASE WHEN @GroupId <> 0 THEN ISNULL(@IsView, ~@IsInternal) ELSE ISNULL(@IsView, 1) END  IsView
END
GO
