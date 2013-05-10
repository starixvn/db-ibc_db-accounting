ALTER  PROCEDURE [dbo].[DBA_CreateLicenseeUser]
	@LicenseeName varchar(50),
	@Username varchar(50),
	@UserPwd varchar (50),
	@UserSalt varchar(50),
	@UserRole varchar(50) = 'Licensee',
	@FirstName nvarchar(50),
	@LastName nvarchar(50) = '',
	@Email varchar(50) = null,
	@Status varchar(30) = 'Open',
	@PageAccess VARCHAR(500) = '',
	@ErrMsg			NVARCHAR(200)	= '' OUTPUT,
    @ErrCode		INT				= 0 OUTPUT
AS
/*
	Created by: [20110127@Henry]
	Task: Create User and grant access to a licensee
	DB: DB052.bodb_Licensee
	Param's Explanation:
	+ @LicenseeName example: 12BET
	+ @PageAccess: TotalBets, Forecast, Reports, ManageMember, DataWarehouse, ManageAccount
	
	Revisions: 
	- 20110113@Henry: add param @PageAccess for input access
	
*/

declare @LicenseeID int
declare @UserID int

select @LicenseeID = LicenseeID from Licensees (nolock) where LicenseeName = @LicenseeName

if isnull(@LicenseeID,0) = 0
begin
	 set @ErrMsg = 'Wrong Licensee Name or this Licensee does not exist'
	 set @ErrCode = 100
	 return
end

--insert new users
if exists(select 1 from users (nolock) where Username = @Username)
begin
	select @UserID = UserID from users (nolock) where Username = @Username
end
else
begin
	insert into Users (Username, UserPwd, UserSalt, UserRole, FirstName,LastName, Email, Status)
	values (@Username,@UserPwd,@UserSalt, @UserRole, @FirstName, @LastName, @Email, @Status)
	
	set @UserID = @@identity
end

--insert new licenseeuser
if not exists(select 1 from LicenseeUser (nolock) where LicenseeID = @LicenseeID and UserID = @UserID)
begin
	insert into LicenseeUser (LicenseeID, UserID, isActive)
	values (@LicenseeID, @UserID, 1)
end
else
begin
	 set @ErrMsg = 'This user ' + @Username  + ' has already granted access to ' + @LicenseeName +  ' !'
	 set @ErrCode = 101
	 return
end

--grant access
IF CHARINDEX('TotalBets', @PageAccess) > 0 
BEGIN
	INSERT INTO [LicenseeUserFunctions](LicenseeId, UserId, FunctionId)
	SELECT DISTINCT @LicenseeId, @UserId, f.FunctionId 
	FROM [Functions] f WITH(NOLOCK)
		INNER JOIN [LicenseeFunctions] l WITH(NOLOCK) ON f.FunctionId = l.FunctionId
	WHERE l.LicenseeId =@LicenseeId			
	AND (f.FunctionId = 1 OR f.ParentId = 1)
END

IF CHARINDEX('Forecast', @PageAccess) > 0
BEGIN
	INSERT INTO [LicenseeUserFunctions](LicenseeId, UserId, FunctionId)
	SELECT DISTINCT @LicenseeId, @UserId, f.FunctionId 
	FROM [Functions] f WITH(NOLOCK)
		INNER JOIN [LicenseeFunctions] l WITH(NOLOCK) ON f.FunctionId = l.FunctionId
	WHERE l.LicenseeId =@LicenseeId			
	AND (f.FunctionId = 2 OR f.ParentId = 2)
END

 IF CHARINDEX('Reports', @PageAccess) > 0
BEGIN
	INSERT INTO [LicenseeUserFunctions](LicenseeId, UserId, FunctionId)
	SELECT DISTINCT @LicenseeId, @UserId, f.FunctionId 
	FROM [Functions] f WITH(NOLOCK)
		INNER JOIN [LicenseeFunctions] l WITH(NOLOCK) ON f.FunctionId = l.FunctionId
	WHERE l.LicenseeId =@LicenseeId			
	AND (f.FunctionId = 3 OR f.ParentId = 3)
END

 IF CHARINDEX('ManageMember', @PageAccess) > 0
BEGIN
	INSERT INTO [LicenseeUserFunctions](LicenseeId, UserId, FunctionId)
	SELECT DISTINCT @LicenseeId, @UserId, f.FunctionId 
	FROM [Functions] f WITH(NOLOCK)
		INNER JOIN [LicenseeFunctions] l WITH(NOLOCK) ON f.FunctionId = l.FunctionId
	WHERE l.LicenseeId =@LicenseeId			
	AND (f.FunctionId = 4 OR f.ParentId = 4)
END

 IF CHARINDEX('DataWarehouse', @PageAccess) > 0
BEGIN
	INSERT INTO [LicenseeUserFunctions](LicenseeId, UserId, FunctionId)
	SELECT DISTINCT @LicenseeId, @UserId, f.FunctionId 
	FROM [Functions] f WITH(NOLOCK)
		INNER JOIN [LicenseeFunctions] l WITH(NOLOCK) ON f.FunctionId = l.FunctionId
	WHERE l.LicenseeId =@LicenseeId			
	AND (f.FunctionId = 5 OR f.ParentId = 5)
END

 IF CHARINDEX('ManageAccount', @PageAccess) > 0
BEGIN
	INSERT INTO [LicenseeUserFunctions](LicenseeId, UserId, FunctionId)
	SELECT DISTINCT @LicenseeId, @UserId, f.FunctionId 
	FROM [Functions] f WITH(NOLOCK)
		INNER JOIN [LicenseeFunctions] l WITH(NOLOCK) ON f.FunctionId = l.FunctionId
	WHERE l.LicenseeId =@LicenseeId			
	AND (f.FunctionId = 6 OR f.ParentId = 6)
END


GO
GRANT VIEW DEFINITION ON [dbo].[DBA_CreateLicenseeUser] TO [vnteam] 