/*<info serverAlias="DBCUST-CustDB" executers="wsv_nap" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Acc_FinanceGroupsConfig_UsersInsValidation]
	@UsernameList	VARCHAR(MAX) = ''
	,@ValidCustIds  NVARCHAR(MAX) = ''
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(2000) = '' OUTPUT
	,@IsAssignUsers BIT OUTPUT
AS
/*
	Created: 20220114@Malcolm
	Task :  NAP - Admin - Finance Groups Config - Add Users to Group - Validation
	DB: DBCUST/CUSTDB

	Revisions:
		- 20220114@Malcolm: Initialize SP [Redmine: #164833]
		- 20220614@Danny: Use String_split built-in function [RemineID: #171831]
		- 20240809@Lewis: Scale Out DBCust - Remove Linked Server [Redmine : #206895]
		
	Param's Explanation:		
		               
*/

BEGIN
	SET NOCOUNT ON

	IF @UsernameList = ''
	BEGIN
		SELECT @ErrCode = 100, @ErrMsg = 'Please enter at least 1 Username.'
		RETURN
	END

	DECLARE @NRowInValid INT = 0, @NRows INT = 0

	DECLARE @FinanceUserTmp TABLE (CustId INT, UserName VARCHAR(30), GroupId INT, Status VARCHAR(20) DEFAULT ('Invalid'), RoleId INT)

	INSERT INTO @FinanceUserTmp (UserName)
	SELECT DISTINCT LTRIM(RTRIM(f.value)) AS UserName
	FROM STRING_SPLIT(@UsernameList, ',') f

	IF (SELECT COUNT(1) FROM @FinanceUserTmp) > 50
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'Maximum limit at 50 Usernames.'
		RETURN
	END

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
		SELECT 1 
		FROM string_split(@ValidCustIds,',') a
		WHERE a.value = u.CustId
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
