ALTER PROC [dbo].[Acc_VirtualRateMulSelCheck]	
	@UserID INT,
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(200) = '' OUTPUT
AS
/*
	Created: 
	Task : Check data on Acc_CustVirtualRate
	DB: DBACC/BODB_ACC
	Original: 
	Revisions:	
		- 20090812@Simon: Check data on Acc_CustVirtualRate
		- 20091116@Daniel: Change to check permission on dedicated function [UploadVR]
		- 20100112@Simon: improve performance by using @tmpExistUser table to check exist in the system.
		- 20130224@Lukas: move sp to new database bodb_ACC
						& change linked-server from db03 to DBPOLICY
*/
BEGIN
SET NOCOUNT ON
		
	--Check permission for account site
	EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[UploadVR]',@ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
	IF @ErrCode <> 0
		RETURN
	
	DECLARE @tmpFail TABLE (
		UserName	NVARCHAR(20),
		Reason		NVARCHAR(80)
	)

	-- The table contents username exist in custinfo
	DECLARE @tmpExistUser TABLE (
		UserName	NVARCHAR(20) PRIMARY KEY
	)
	INSERT INTO @tmpExistUser
	SELECT 	v.UserName
	FROM	dbo.Acc_CustVirtualRate v WITH (NOLOCK) 
			INNER JOIN custinfo c WITH (NOLOCK) ON c.username=v.username
	GROUP BY v.UserName


	INSERT INTO @tmpFail
	SELECT 	UserName, 
			'This username is repeated '+ CAST(COUNT(UserName) AS VARCHAR(20))+' times.' AS reason
	FROM	dbo.Acc_CustVirtualRate WITH (NOLOCK)
	WHERE	UserID=@UserID 
	GROUP BY UserName 
	HAVING COUNT(UserName)>1
	UNION ALL
	SELECT	t.username,
			'This username does not exist in the system.' AS reason 
	FROM	
	(
			SELECT	username FROM dbo.Acc_CustVirtualRate WITH (NOLOCK) WHERE	UserID=@UserID 
			EXCEPT (
				SELECT	UserName
				FROM	@tmpExistUser
			)
		) t
	
	DELETE FROM dbo.Acc_CustVirtualRate WHERE userid = @userid AND username IN (SELECT username FROM @tmpFail)
	
	SELECT * FROM dbo.Acc_CustVirtualRate WITH (NOLOCK) 
	WHERE	UserID=@UserID 
	ORDER BY username

	SELECT username, '-' AS virtualrate, reason FROM @tmpFail 

END


GO
GRANT EXECUTE ON [dbo].[Acc_VirtualRateMulSelCheck] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_VirtualRateMulSelCheck] TO [vnteam]
