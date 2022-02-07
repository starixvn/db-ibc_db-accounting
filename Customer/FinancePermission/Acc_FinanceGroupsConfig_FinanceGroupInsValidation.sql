/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_FinanceGroupsConfig_FinanceGroupInsValidation]
	@FinanceCode	VARCHAR(MAX) = ''
	,@FinanceUser	VARCHAR(MAX) = ''
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(2000) = '' OUTPUT
	,@IsCreateGroup BIT OUTPUT
	
AS
/*
	Created: 20220114@Malcolm
	Task :  NAP - Admin - Finance Groups Config - Add new Finance Group
	DB: DBCUST/CUSTDB

	Revisions:
		- 20220114@Malcolm: Initialize SP [Redmine: #164833]

	Param's Explanation:
		               
*/

BEGIN
	SET NOCOUNT ON

	SELECT @FinanceCode = ISNULL(@FinanceCode, ''), @FinanceUser = ISNULL(@FinanceUser, '')

	IF @FinanceCode = '' OR @FinanceUser = ''
	BEGIN
		SELECT @ErrCode = 100, @ErrMsg = 'Please enter at least 1 Username or 1 Finance Code.'
		RETURN
	END
	
	DECLARE @DepartmentGroupId INT

	DECLARE @ABS TABLE (custid int)

	INSERT INTO @ABS(custid)
	SELECT 5452637 --ABS014
	UNION SELECT 5452639 --ABS015
	UNION SELECT 5519908 --ABS016
	UNION SELECT 5519911 --ABS017
	UNION SELECT 5519914 --ABS018
	UNION SELECT 5519916 --ABS019
	UNION SELECT 5519917 --ABS020
	UNION SELECT 5519919 --ABS021
	UNION SELECT 5519921 --ABS022
	UNION SELECT 5519922 --ABS023
	UNION SELECT 5519924 --ABS024
	UNION SELECT 5519926 --ABS025
	UNION SELECT 5848823 --ABS026
	UNION SELECT 6081162 --ABSJackyTING.

	DECLARE @FinanceCodeTmp TABLE (CustId INT, UserName VARCHAR(30), Recommend INT, Mrecommend INT,  Srecommend INT, IsInternal BIT, RoleId INT)

	INSERT INTO @FinanceCodeTmp (UserName)
	SELECT DISTINCT LTRIM(RTRIM(f.val)) AS UserName
	FROM dbo.f_StringSplit(@FinanceCode, ',') f
	OPTION (MAXRECURSION 0)

	DECLARE @FinanceUserTmp TABLE (CustId INT, UserName VARCHAR(30), GroupId INT, Status VARCHAR(20) DEFAULT ('Invalid'), RoleId INT)

	INSERT INTO @FinanceUserTmp (UserName)
	SELECT DISTINCT LTRIM(RTRIM(f.val)) AS UserName
	FROM dbo.f_StringSplit(@FinanceUser, ',') f
	OPTION (MAXRECURSION 0)

	IF (SELECT COUNT(1) FROM @FinanceUserTmp) > 50
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'Maximum limit at 50 Usernames.'
		RETURN
	END

	IF (SELECT COUNT(1) FROM @FinanceCodeTmp) > 100
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg = 'Maximum limit at 100 Finance Codes.'
		RETURN
	END

	SELECT @DepartmentGroupId = GroupID FROM NAP_UserControl.dbo.acc_groupinfo WITH(NOLOCK) WHERE GroupName  = 'Finance' AND System = 'ACCOUNTING'

	-- Check finance User
	BEGIN 
		UPDATE u
			SET u.CustId =n.custid, u.Status = CASE WHEN ISNULL(n.closed, 0) = 1 THEN 'Closed' ELSE 'Active' END, u.RoleId = n.roleid
		FROM @FinanceUserTmp u
		CROSS APPLY (
			SELECT c.custid, c.closed, c.roleid FROM dbo.custInfo c WITH(NOLOCK) WHERE c.username = u.UserName AND c.roleid >= 5
		) AS n

		UPDATE u
			SET u.Status = 'Invalid'
		FROM @FinanceUserTmp u
		WHERE NOT EXISTS (
			SELECT 1 FROM NAP_UserControl.dbo.acccustomer a WITH(NOLOCK) 
			WHERE a.custid = u.CustId 
				AND (a.GroupID = @DepartmentGroupId OR u.UserName LIKE 'Starix%')
				AND a.custid NOT IN (SELECT Custid FROM @ABS)
		) 

		UPDATE u
			SET u.GroupId = n.GroupId
		FROM @FinanceUserTmp u
		CROSS APPLY (
			SELECT f.GroupId
			FROM dbo.Acc_FinancePermission f WITH(NOLOCK)
			WHERE f.FinanceCode = u.UserName AND f.RoleId >= 5
		) AS n
	END
	
	-- Check finance Code
	BEGIN
		UPDATE f
			SET f.Recommend = n.recommend, f.Mrecommend = n.mrecommend, f.Srecommend = n.srecommend, f.RoleId = n.roleid, f.CustId = n.custid
		FROM @FinanceCodeTmp f
		CROSS APPLY(SELECT c.custid, c.recommend, mrecommend, c.srecommend, c.roleid
			FROM dbo.Customer c WITH(NOLOCK)
			WHERE c.username = f.UserName AND c.roleid <= 4
		) AS n

		UPDATE f
			SET f.IsInternal = n.IsInternal
		FROM @FinanceCodeTmp f
		CROSS APPLY(SELECT s.IsInternal FROM dbo.CustSuper s WITH(NOLOCK)WHERE s.custid = f.CustId) AS n

		UPDATE f
			SET f.IsInternal = n.IsInternal
		FROM @FinanceCodeTmp f
		CROSS APPLY(SELECT s.IsInternal FROM dbo.CustMaster s WITH(NOLOCK)WHERE s.custid = f.CustId) AS n
		WHERE f.IsInternal IS NULL

		UPDATE f
			SET f.IsInternal = n.IsInternal
		FROM @FinanceCodeTmp f
		CROSS APPLY(SELECT s.IsInternal FROM dbo.CustAgent s WITH(NOLOCK) WHERE s.custid = f.CustId) AS n
		WHERE f.IsInternal IS NULL

		UPDATE f
			SET f.IsInternal = n.IsInternal
		FROM @FinanceCodeTmp f
		CROSS APPLY(SELECT s.IsInternal FROM dbo.CustAgent s WITH(NOLOCK)WHERE s.custid = f.Recommend) AS n
		WHERE f.RoleId = 1
	END
	
	SET @IsCreateGroup = 0

	IF EXISTS(SELECT 1 FROM @FinanceUserTmp WHERE Status <> 'Invalid')
		OR EXISTS(SELECT 1 FROM @FinanceCodeTmp WHERE ISNULL(IsInternal, 0) = 1)
	BEGIN
		SET @IsCreateGroup = 1
	END 

	SELECT CustId, UserName, Status, GroupId, RoleId
	FROM @FinanceUserTmp 
	ORDER BY Status ASC, UserName ASC

	SELECT CustId, UserName, CASE WHEN ISNULL(IsInternal, 0) = 0 THEN 'Invalid' ELSE 'Valid' END AS Status, RoleId
	FROM @FinanceCodeTmp
	ORDER BY ISNULL(IsInternal, 0) DESC, UserName ASC

END
GO
