/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_FinanceGroupsConfig_CodesInsValidation]
	@UsernameList	NVARCHAR(MAX) = ''
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(2000) = '' OUTPUT
	,@IsAddCodes    BIT OUTPUT
	
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

	DECLARE @NRowInValid INT = 0, @NRows INT = 0

	IF ISNULL(@UsernameList, '') = ''
	BEGIN
		SELECT @ErrCode = 100, @ErrMsg = 'Please enter at least 1 Username.'
		RETURN
	END

	DECLARE @FinanceCodeTmp TABLE (CustId INT, UserName VARCHAR(30), Recommend INT, Mrecommend INT,  Srecommend INT, IsInternal BIT DEFAULT(0), RoleId INT)

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
		SET u.CustId = n.Custid, u.RoleId = n.Roleid, u.Recommend = n.recommend, u.Mrecommend = n.mrecommend, u.Srecommend = n.srecommend
	FROM @FinanceCodeTmp u
	CROSS APPLY (
		SELECT c.Custid, c.Roleid, c.recommend, c.mrecommend, c.srecommend FROM dbo.Customer c WITH(NOLOCK) WHERE c.username = u.UserName AND c.roleid <= 4
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

	SELECT @NRows = COUNT(1), @NRowInValid = COUNT(CASE WHEN ISNULL(IsInternal, 0) = 0 THEN 1 ELSE NULL END) FROM @FinanceCodeTmp

	SET @IsAddCodes = 1
	
	IF @NRows = @NRowInValid 
	BEGIN
		SET @IsAddCodes = 0
	END

	SELECT CustId, UserName, CASE WHEN ISNULL(IsInternal, 0) = 0 THEN 'Invalid' ELSE 'Valid' END AS Status, roleid
	FROM @FinanceCodeTmp 
	ORDER BY ISNULL(IsInternal, 0) DESC, UserName ASC
END
GO
