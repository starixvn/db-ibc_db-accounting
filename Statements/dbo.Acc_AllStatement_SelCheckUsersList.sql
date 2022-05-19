/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_AllStatement_SelCheckUsersList]
	@userlist varchar(6000),
	@UserId	INT
	
AS
 
 /*
	Created by: KhoaTran
	Date: 20100203
	Task: Check the users list is valid or not
	DB: DBACC.bodb02
	
	Revisions:	
		- 20220519@Evan: Revise sp (check permission of finance account) [Redmine: #168299]

 */

SET NOCOUNT ON
BEGIN

	DECLARE @TEMP_USER_VALID TABLE (Custid int, UserName varchar(50), Recommend int, Mrecommend int, Srecommend int) 	
	DECLARE @TEMP_USER_LIST TABLE (UserName varchar(50), IsValid bit DEFAULT ((0))) 
	DECLARE @GroupId SMALLINT = -1

	SELECT @GroupId = ISNULL(GroupId,-1)
	FROM Acc_FinancePermission f WITH(NOLOCK)
		INNER JOIN Customer c WITH(NOLOCK) ON f.FinanceCode = c.username
	WHERE c.custid = @UserId AND c.roleid > 4

	INSERT INTO @TEMP_USER_LIST (username)
	SELECT DISTINCT LTRIM(RTRIM(f.value)) as username
	FROM STRING_SPLIT(@userlist, ',') f 
	
	INSERT INTO @TEMP_USER_VALID (Custid,UserName,Recommend,Mrecommend,Srecommend)
	SELECT c.custid,c.username,c.recommend,c.mrecommend,c.srecommend 
	FROM @TEMP_USER_LIST a 
		JOIN custInfo c WITH(NOLOCK) ON a.UserName = c.username

	UPDATE t
	SET t.IsValid = 1
	FROM @TEMP_USER_LIST t JOIN @TEMP_USER_VALID b ON t.UserName = b.UserName
		LEFT JOIN dbo.Customer s WITH(NOLOCK) ON b.Srecommend = s.custid
		LEFT JOIN dbo.Customer m WITH(NOLOCK) ON b.Mrecommend = m.custid
		LEFT JOIN dbo.Customer a WITH(NOLOCK) ON b.Recommend  = a.custid
		LEFT JOIN dbo.Customer p WITH(NOLOCK) ON b.Custid     = p.custid
		OUTER APPLY 
		(
			SELECT TOP 1 ISNULL(IsInternal,0) IsInternal FROM CustSuper  WITH (NOLOCK) WHERE p.custid    = custid AND p.roleid = 4
			UNION ALL 
			SELECT TOP 1 ISNULL(IsInternal,0) IsInternal FROM CustMaster WITH (NOLOCK) WHERE p.custid    = custid AND p.roleid = 3
			UNION ALL 
			SELECT TOP 1 ISNULL(IsInternal,0) IsInternal FROM CustAgent  WITH (NOLOCK) WHERE p.custid    = custid AND  p.roleid = 2
			UNION ALL 
			SELECT TOP 1 ISNULL(IsInternal,0) IsInternal FROM CustAgent  WITH (NOLOCK) WHERE p.recommend = custid AND  p.roleid = 1
		) l
		OUTER APPLY (
			SELECT TOP 1  f.IsView
			FROM dbo.Acc_FinancePermission f WITH(NOLOCK)
			WHERE  f.FinanceCode IN (s.username, m.username, a.username, p.username)
					AND f.GroupId = @GroupId
					AND l.IsInternal = 1
					AND @GroupId NOT IN (-1, 1)
			ORDER BY f.RoleId ASC
		) cr			 
	WHERE 
		 (@GroupId = 1 OR ISNULL(cr.IsView, ~l.IsInternal) = 1 OR (@GroupId = 0 AND ISNULL(cr.IsView, 1) = 1))
	
	SELECT UserName, IsValid FROM @TEMP_USER_LIST ORDER BY IsValid, UserName

END
GO