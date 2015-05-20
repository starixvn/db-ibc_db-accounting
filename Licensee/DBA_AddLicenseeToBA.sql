ALTER PROCEDURE [dbo].[DBA_AddLicenseeToBA]
(
	@LicenseeID		INT,
	@Rate MONEY = 0.13
)
AS
/*
Created: Henry
Date: 20120702
Task : Add licensee to BA Reseller
DB: DB052.bodb_Licensee
Original:

Revisions:
	
	
Param's Explanation:
	
*/
BEGIN

SET NOCOUNT ON

DECLARE @TempGroupID AS TABLE (id INT IDENTITY,GroupID INT)
DECLARE @TempUserID AS TABLE (id INT IDENTITY,UserID INT)
DECLARE @i INT, @max INT,@GroupID INT, @UserID INT

IF NOT EXISTS(SELECT 1 FROM	LicenseeBAConfig (NOLOCK) WHERE LicenseeID = @LicenseeID AND EnableBA = 1)
BEGIN
	print 'This licensee is not offer BA yet!'
	RETURN
END

IF NOT EXISTS(SELECT 1 FROM	LicenseeReseller (NOLOCK) WHERE LicenseeID = @LicenseeID AND ResellerID = 3 )
BEGIN
	--Add Licensee to BA reseller
	INSERT INTO LicenseeReseller (ResellerID,LicenseeID,TnxRate)
	VALUES (3,@LicenseeID,@Rate)
END

--insert Licensee to BA reseller to OA group (OA_GroupLicensees)

INSERT INTO @TempGroupID(GroupID)
SELECT DISTINCT GroupID FROM OA_GroupLicensees (NOLOCK)

SET @i = 0
SELECT @MAX = MAX(id) FROM @TempGroupID

WHILE @i < @MAX
BEGIN
    SET @i = @i + 1
    SELECT @GroupID = GroupID FROM @TempGroupID WHERE id = @i
    
    IF EXISTS (SELECT 1 FROM OA_GroupLicensees (NOLOCK) WHERE GroupID = @GroupID AND ResellerID <> 3 AND LicenseeID = @LicenseeID)
    BEGIN
		IF NOT EXISTS (SELECT 1 FROM OA_GroupLicensees (NOLOCK) WHERE GroupID=@GroupID AND ResellerID = 3 AND LicenseeID = @LicenseeID)
		BEGIN
			INSERT INTO	OA_GroupLicensees (GroupID,ResellerID,LicenseeID) VALUES (@GroupID,3,@LicenseeID)
		END
    END 
END

--insert Licensee to BA reseller to OA Users (OA_UserLicensees)
INSERT INTO @TempUserID(UserID)
SELECT DISTINCT UserID FROM OA_UserLicensees (NOLOCK)

SET @i = 0
SELECT @MAX = MAX(id) FROM @TempUserID

WHILE @i < @MAX
BEGIN
	SET @i = @i + 1
	SELECT @UserID = UserID FROM @TempUserID WHERE id = @i
	
	IF EXISTS (SELECT 1 FROM OA_UserLicensees (NOLOCK) WHERE UserID = @UserID AND ResellerID <> 3 AND LicenseeID = @LicenseeID)
    BEGIN
		IF NOT EXISTS (SELECT 1 FROM OA_UserLicensees (NOLOCK) WHERE UserID=@UserID AND ResellerID = 3 AND LicenseeID = @LicenseeID)
		BEGIN
			INSERT INTO	OA_UserLicensees (UserID,ResellerID,LicenseeID) VALUES (@UserID,3,@LicenseeID)
		END
    END 
END


--insert justin,martin,anthony to SpecialBA for this license
DELETE FROM @TempUserID
INSERT INTO @TempUserID(UserID)
select userid from users (nolock)
where username IN ('justin','martin','anthony')
and UserRole = 'admin' and isInternal = 0

SET @i = 0
SELECT @MAX = MAX(id) FROM @TempUserID

WHILE @i < @MAX
BEGIN
	SET @i = @i + 1
	SELECT @UserID = UserID FROM @TempUserID WHERE id = @i
	
	if not exists (select 1 from [LicenseeUserFunctions] where licenseeid=@LicenseeId and Userid=@UserId AND Functionid = 54)
	BEGIN
		INSERT INTO [LicenseeUserFunctions](LicenseeId, UserId, FunctionId)
		SELECT @LicenseeId, @UserId, 54
	end
END
 

END

GO
GRANT VIEW DEFINITION ON [dbo].[DBA_AddLicenseeToBA] TO [vnteam] 