/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_FinanceGroupsConfig_CodesInsValidation]
	@UsernameList	NVARCHAR(MAX)
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(2000) = '' OUTPUT
	
AS
/*
	Created: 20220114@Malcolm
	Task :  NAP - Admin - Finance Groups Config - Add Codes to Group
	DB: DBCUST/CUSTDB

	Revisions:
		- 20220114@Malcolm: Initialize SP [Redmine: #164833]
		
	Param's Explanation:	
	
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @NRows INT, @NRowInValid INT

	IF ISNULL(@UsernameList, '') = ''
	BEGIN
		SELECT @ErrCode = 100, @ErrMsg = 'Please enter at least 1 Username.'
		RETURN
	END

	DECLARE @FinanceCodeTmp TABLE (CustId INT, UserName VARCHAR(30), RoleId INT)

	INSERT INTO @FinanceCodeTmp (UserName)
	SELECT DISTINCT LTRIM(RTRIM(f.val)) AS UserName
	FROM dbo.f_StringSplit(@UsernameList, ',') f
	OPTION (MAXRECURSION 0)

	IF (SELECT COUNT(1) FROM @FinanceCodeTmp) > 100
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'Maximum limit at 100 Usernames.'
		RETURN
	END

	UPDATE u
		SET u.CustId = n.Custid, u.RoleId = n.Roleid
	FROM @FinanceCodeTmp u
	CROSS APPLY (
		SELECT c.Custid, c.Roleid FROM dbo.Customer c WITH(NOLOCK) WHERE c.username = u.UserName AND c.roleid <= 4
	) AS n

	SELECT @NRows = COUNT(1), @NRowInValid = COUNT(CASE WHEN CustId IS NULL THEN 1 ELSE NULL END) FROM @FinanceCodeTmp

	SELECT CustId, UserName, CASE WHEN CustId IS NULL THEN 'Invalid' ELSE '' END AS [Status], roleid
	FROM @FinanceCodeTmp 

	SELECT @NRows AS [NRows], @NRowInValid AS [NRowInValid]

END
GO
