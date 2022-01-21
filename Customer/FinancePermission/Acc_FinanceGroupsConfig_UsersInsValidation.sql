/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Acc_FinanceGroupsConfig_UsersInsValidation]
	@UsernameList	VARCHAR(MAX) = ''
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(2000) = '' OUTPUT
	,@IsAssignUsers BIT OUTPUT
	,@NRows         INT OUTPUT
AS
/*
	Created: 20220114@Malcolm
	Task :  NAP - Admin - Finance Groups Config - Add Users to Group
	DB: DBCUST/CUSTDB

	Revisions:
		- 20220114@Malcolm: Initialize SP [Redmine: #164833]
		
	Param's Explanation:		
		               
*/

BEGIN
	SET NOCOUNT ON

	IF @UsernameList = ''
	BEGIN
		SELECT @ErrCode = 100, @ErrMsg = 'Please enter at least 1 Username.'
		RETURN
	END

	DECLARE @NRowInValid INT = 0, @DepartmentGroupId INT

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

	DECLARE @FinanceUserTmp TABLE (CustId INT, UserName VARCHAR(30), GroupId INT, Status VARCHAR(20) DEFAULT ('Invalid'), RoleId INT)

	INSERT INTO @FinanceUserTmp (UserName)
	SELECT DISTINCT LTRIM(RTRIM(f.val)) AS UserName
	FROM dbo.f_StringSplit(@UsernameList, ',') f
	OPTION (MAXRECURSION 0)

	IF (SELECT COUNT(1) FROM @FinanceUserTmp) > 50
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'Maximum limit at 50 Usernames.'
		RETURN
	END

	SELECT @DepartmentGroupId = GroupID FROM NAP_UserControl.dbo.acc_groupinfo WITH(NOLOCK) WHERE GroupName  = 'Finance' AND System = 'ACCOUNTING'

	UPDATE u
		SET u.CustId = n.CustId, u.RoleId = n.Roleid, u.Status = CASE WHEN ISNULL(n.closed, 0) = 0 THEN 'Active' ELSE 'Closed' END
	FROM @FinanceUserTmp u
	CROSS APPLY (
		SELECT c.custid, c.roleid, c.closed FROM dbo.CustInfo c WITH(NOLOCK) WHERE c.username = u.UserName AND c.roleid >= 5
	) AS n

	UPDATE u
		SET u.Status = 'Invalid'
	FROM @FinanceUserTmp u
	WHERE NOT EXISTS (
		SELECT 1 FROM NAP_UserControl.dbo.acccustomer a WITH(NOLOCK) 
		WHERE a.custid = u.CustId 
			AND a.GroupID = @DepartmentGroupId 
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

	SELECT @NRows = COUNT(1), @NRowInValid = COUNT(CASE WHEN Status = 'Invalid' THEN 1 ELSE NULL END)  FROM @FinanceUserTmp 

	SET @IsAssignUsers = 1

	IF @NRows = @NRowInValid
	BEGIN
		SET @IsAssignUsers = 0
	END

	SELECT CustId, UserName, Status, GroupId, roleid FROM @FinanceUserTmp 
	ORDER BY Status ASC, UserName ASC
END
GO
