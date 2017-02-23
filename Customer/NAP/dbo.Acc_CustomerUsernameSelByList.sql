USE [bodb02]
GO

ALTER PROCEDURE [dbo].[Acc_CustomerUsernameSelByList]
	@Username VARCHAR(MAX),
	@RoleId TINYINT
AS

/*
	Creator: Percy
	Date: 2017-02-23
	DB: DBACC.bodb02
	Task: Get username list by suggest username

	Revisions:

	Param's Explanation:
		- @Username: input list of suggest username
		- @RoleId: search by roleId, if @RoleId = 0: associated account, return @Username
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @_Username VARCHAR(MAX), @_UsernameCust VARCHAR(MAX)
	
	SELECT  @Username = LTRIM(RTRIM(@Username))

	IF @RoleId = 0 /* associated account */ OR @Username = '' /* all */
	BEGIN
		SELECT Username = @Username
		
		RETURN
	END
	
	CREATE TABLE #username (Username VARCHAR(50))	

	IF CHARINDEX(',', @Username) = 0 -- input 1 item
	BEGIN
		INSERT INTO #username (Username)
		SELECT username
		FROM dbo.Customer WITH(NOLOCK)
		WHERE username LIKE @Username + '%' AND roleid = @RoleId

		IF @Username NOT LIKE '%[^0-9]%'
		BEGIN
			INSERT INTO #username (Username)
			SELECT username FROM dbo.Customer WITH(NOLOCK) WHERE custid = @Username AND roleid = @RoleId
		END
	END
	ELSE
	BEGIN
		;WITH CTE_Username AS (
			SELECT LTRIM(RTRIM(val)) AS Username FROM dbo.strSplit(@Username, ',')
		)
		INSERT INTO #username (Username)
		SELECT c.username
		FROM dbo.Customer c WITH(NOLOCK)
		WHERE EXISTS (SELECT 1 FROM CTE_Username cc WHERE c.Username = cc.Username) AND roleid = @RoleId

		;WITH CTE_CustId AS (
			SELECT LTRIM(RTRIM(val)) AS CustId FROM dbo.strSplit(@Username, ',')
			WHERE LTRIM(RTRIM(val)) NOT LIKE '%[^0-9]%'
		)
		INSERT INTO #username (Username)
		SELECT c.username
		FROM dbo.Customer c WITH(NOLOCK)
		WHERE EXISTS (SELECT 1 FROM CTE_CustId cc WHERE c.custid = cc.CustId) AND roleid = @RoleId
	END

	DELETE Duplicated 
	FROM (
		SELECT ROW_NUMBER() OVER (PARTITION BY Username ORDER BY (SELECT NULL)) AS cnt
		FROM #username
	) Duplicated
	WHERE Duplicated.cnt > 1

	SELECT @_Username= STUFF((SELECT ',' + username FROM #username FOR XML PATH ('')), 1, 1, '')
	SELECT Username = @_Username

	DROP TABLE #username
END
GO

GRANT EXECUTE ON [dbo].[Acc_CustomerUsernameSelByList] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUsernameSelByList] TO [vnteam] AS [dbo]
GO