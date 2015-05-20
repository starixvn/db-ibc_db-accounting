USE [bodb_licensee]
GO
ALTER PROCEDURE [dbo].[DBA_CreateLicenseeUser]
	@LicenseeName varchar(50)='All',
	@Username varchar(50),
	@UserPwd varchar (50)='754A738BF99D986D8716FE00A81BC5CA32916BF6',
	@UserSalt varchar(50)='SIymwTYtl4dVMSRM5w==',
	@UserRole varchar(50) = 'Admin',
	@FirstName nvarchar(50),
	@LastName nvarchar(50) = '',
	@Email varchar(50) = null,
	@Status varchar(30) = 'Open',
	@PageAccess VARCHAR(500) = 'TotalBets,Forecast,Reports,ManageMember,DataWarehouse,CustomerReports,CustomerReports,AgencySystem',
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
		Daniel@20130312: Add pageaccess customer reports
		Jim@20130603: restrict currency permission for licensee user 
		Jim@20130823: INTernal user haven't got ManageMember 
		Jim@20140416: Add more permission Filter for Legend system
		Jim@20150112: re-structure data flow for support multi licensee 
*/

DECLARE @LicenseeID INT
		,@UserID INT
		,@i INT
		,@Max INT
DECLARE @Currency as table (CurrencyID INT)
DECLARE @TempLicensee AS TABLE (ID INT IDENTITY(1,1),LicenseeID INT)
DECLARE @AdminFunction AS TABLE (ID INT IDENTITY(1,1),FunctionID INT)

INSERT INTO @TempLicensee (LicenseeID)
SELECT DISTINCT l.LicenseeId
FROM   dbo.Licensees l WITH (NOLOCK)
INNER JOIN dbo.SystemLicensee sl WITH (NOLOCK) ON l.LicenseeID=sl.LicenseeID
INNER JOIN dbo.LicenseeReseller lr WITH (NOLOCK) ON l.LicenseeId = lr.LicenseeId
WHERE 
	sl.IsActive = 1
	AND sl.SystemID = 1
	AND l.IsDeposit = 1
	AND (@LicenseeName ='All'  OR l.LicenseeName = @LicenseeName)

SELECT  @i = 1
		,@Max = Max(ID) 
FROM @TempLicensee	

WHILE (@i <= @Max) 
BEGIN	
	SELECT @LicenseeID = LicenseeID 
	FROM @TempLicensee WHERE ID=@i
		
		INSERT INTO @currency (CurrencyID)
		SELECT DISTINCT currency
		FROM dbo.LicenseeCust WITH (NOLOCK) WHERE LicenseeID=@LicenseeID
		
		IF ISNULL(@LicenseeID,0) = 0
		BEGIN
			SET @ErrMsg = 'Wrong Licensee Name or this Licensee does not exist'
			SET @ErrCode = 100
			RETURN
		END

		--insert new users
		IF EXISTS (SELECT 1 FROM dbo.users WITH (NOLOCK) WHERE Username = @Username)
		BEGIN
			SELECT @UserID = UserID FROM  dbo.users WITH (NOLOCK) WHERE Username = @Username
		END
		ELSE
		BEGIN
			INSERT INTO dbo.Users (Username, UserPwd, UserSalt, UserRole, FirstName,LastName, Email, Status)
			VALUES (@Username,@UserPwd,@UserSalt, @UserRole, @FirstName, @LastName, @Email, @Status)
			SET @UserID = @@identity
		END

		--insert new licenseeuser and restrict currency permisson to licensee user 
		IF NOT EXISTS (SELECT 1 FROM dbo.LicenseeUser WITH (NOLOCK) WHERE LicenseeID = @LicenseeID AND UserID = @UserID)
		BEGIN
			INSERT INTO LicenseeUser (LicenseeID, UserID, isActive)
			VALUES (@LicenseeID, @UserID, 1)
			
			INSERT INTO  dbo.CurrencyUser (usrID,LicenseeID,CurrencyID,SystemID,isActive)
			SELECT DISTINCT @UserID,@LicenseeID,CurrencyID,1,1 -- systemID=1 is default from Lrf
			FROM @currency

		END
		ELSE
		BEGIN
			 SET @ErrMsg = 'This user ' + @Username  + ' has already granted access to ' + @LicenseeName +  ' !'
			 SET @ErrCode = 101
			 RETURN
		END

		DECLARE @isInternal BIT
		SELECT @isInternal=isInternal FROM dbo.Users (NOLOCK) WHERE  username=@Username


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

		IF (CHARINDEX('ManageMember', @PageAccess) > 0 )
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

		 IF (CHARINDEX('ManageAccount', @PageAccess) > 0 )
		BEGIN
				INSERT INTO [LicenseeUserFunctions](LicenseeId, UserId, FunctionId)
				SELECT DISTINCT @LicenseeId, @UserId, f.FunctionId 
				FROM [Functions] f WITH(NOLOCK)
					INNER JOIN [LicenseeFunctions] l WITH(NOLOCK) ON f.FunctionId = l.FunctionId
				WHERE l.LicenseeId =@LicenseeId			
				AND (f.FunctionId = 6 OR f.ParentId = 6)
		END

		IF CHARINDEX('CustomerReports', @PageAccess) > 0
		BEGIN
			INSERT INTO [LicenseeUserFunctions](LicenseeId, UserId, FunctionId)
			SELECT DISTINCT @LicenseeId, @UserId, f.FunctionId 
			FROM [Functions] f WITH(NOLOCK)
				INNER JOIN [LicenseeFunctions] l WITH(NOLOCK) ON f.FunctionId = l.FunctionId
			WHERE l.LicenseeId =@LicenseeId			
			AND (f.FunctionId = 52 OR f.ParentId = 52)
		END
		/* 
		IF CHARINDEX('AgencySystem', @PageAccess) > 0
		BEGIN
			INSERT INTO [LicenseeUserFunctions](LicenseeId, UserId, FunctionId)
			SELECT DISTINCT @LicenseeId, @UserId, f.FunctionId 
			FROM [Functions] f WITH(NOLOCK)
				INNER JOIN [LicenseeFunctions] l WITH(NOLOCK) ON f.FunctionId = l.FunctionId
			WHERE l.LicenseeId =@LicenseeId			
			AND (f.FunctionId = 58 OR f.ParentId = 58)
		END
		*/
	-------------------
	SELECT @i = @i + 1
END