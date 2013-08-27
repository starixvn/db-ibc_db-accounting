set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go

ALTER PROCEDURE [dbo].[DBA_CreateNewLicensee]
(
	@LicenseeName VARCHAR(50),
	@SuperWildCard VARCHAR(100)='',
	@ResellerID  INT=0,
	@IsSpecial BIT = 0,
	@IsAllowedNG BIT = 0,
	@IsAllowedRB BIT  =0,
	@IsAllowedDW BIT  =0,
	@ErrCode int = 0 OUTPUT , 
	@ErrMsg nvarchar(1000) = '' OUTPUT 	
)
AS 
/*
Created: Henry
Date: 20120409
Task : Procedure to create a new Licensee
DB: DB052.bodb_Licensee
Original:

Revisions:
	+20120716@Jim: add IsActive config for new licensee 
	+20121205@henry: add param @SuperWildCard
	+20130204@Jim: add param @ResellerID 
	+20130603@Jim: grant currency permission 
	+20130624@Jim: set default for new licensee on Accounting system is inactive 
	+20130725@Jim: restrict permission for DW function 
	
Param's Explanation:
	+ @IsSpecial: if 1 then update column Description to normal, or affiliate or banner depend on:
	- username ending with 01: normal
	- username ending with 02: affiliate
	- username ending with 03: banner
	- username ending with 04: income access
	+ @SuperWildCard example: 12BETSuper%
	+ @ResellerID : Reseller who new Licensee must to belong 
	+@IsAllowedDW : offer DW :1  else :0
*/
BEGIN
SET NOCOUNT ON

/*
----------------------------------------------------------------------
- New Licensee in table Licensees
- Map Agent with new Licensee to LicenseeCust
----------------------------------------------------------------------
*/

IF LTRIM(RTRIM(ISNULL(@SuperWildCard,'')))=''
	SET @SuperWildCard = @LicenseeName + 'Super%'
	


--/*Create all the agent for this licensee
--This process including create new licensee*/
EXEC DBA_CreateLicenseeAgent @LicenseeName=@LicenseeName,@SuperWildCard= @SuperWildCard, @IsSpecial=@IsSpecial

DECLARE @licenseeid INT
SELECT @licenseeid=licenseeid FROM licensees (NOLOCK)
WHERE licenseename = @LicenseeName

IF isnull(@licenseeid,0)=0
RAISERROR('Could not insert new licensee, please check again',16,1)


/*
----------------------------------------------------------------------
- Map new licensee to functions, we may remove some functions does not applied to new licensee:
+ Number game && Racing: FunctionId = 22, 23, 34, 35 (WHERE FunctionId NOT IN (22, 23, 34, 35) )
----------------------------------------------------------------------
*/

INSERT INTO [LicenseeFunctions](LicenseeId, FunctionId)
SELECT @licenseeid, FunctionId FROM [Functions] WITH (NOLOCK)
WHERE FunctionId NOT IN (SELECT FunctionId FROM [LicenseeFunctions] WITH (NOLOCK) WHERE LicenseeId = @LicenseeId)
AND (@IsAllowedNG=1 OR (@IsAllowedNG=0 AND FunctionID <> 23))
AND (@IsAllowedRB=1 OR (@IsAllowedRB=0 AND FunctionID NOT IN (22,34,35)))
AND ((@IsAllowedDW=0 AND FunctionID NOT IN (5,44,45)) OR (@IsAllowedDW=1))
-- add new licensee config into SystemLicensee 
IF NOT EXISTS (SELECT 1 FROM SystemLicensee (NOLOCK) WHERE LicenseeID=@licenseeid) 
BEGIN
	INSERT INTO SystemLicensee
	SELECT ID
		, @LicenseeID as LicenseeID
		, CASE WHEN ID IN (1,2) THEN 1 ELSE 0 END AS  IsActive 
	FROM Systems (NOLOCK) 
END 
ELSE 
BEGIN 
	INSERT INTO SystemLicensee
	SELECT ID
			, @LicenseeID as LicenseeID
			, CASE WHEN ID IN (1,2) THEN 1 ELSE 0 END AS IsActive 
	FROM Systems (NOLOCK) 
	WHERE ID NOT IN (SELECT DISTINCT SystemID FROM SystemLicensee (NOLOCK) WHERE LicenseeID=@licenseeid)
END 

/*
----------------------------------------------------------------------------------------------------
- Map Admin users to this new Licensees (and create permission too)
----------------------------------------------------------------------------------------------------
*/

--Get User Admin List
DECLARE @DATA AS  TABLE (id INT  IDENTITY,UserID INT,Username VARCHAR(50))
DECLARE @i INT, @MAX INT,@UserID INT, @Username VARCHAR(50)

INSERT INTO @DATA(UserID,Username)
SELECT UserID,Username FROM  Users(NOLOCK)
WHERE userrole = 'admin'


SET @i = 0
SELECT @MAX = MAX(id) FROM @DATA

--Insert Permission for each admin user for the new licensee
WHILE @i <=@MAX
BEGIN
    SET @i = @i + 1
       SELECT @UserID=UserID,@Username=Username FROM @DATA
    WHERE id = @i
   
	IF EXISTS(SELECT 1 FROM LicenseeUser (NOLOCK) WHERE LicenseeID = @licenseeid AND UserID = @UserID)
    BEGIN
        UPDATE LicenseeUser WITH (ROWLOCK,UPDLOCK)
            SET isActive = 1,
            PageAccess = ''
        WHERE LicenseeID = @licenseeid AND UserID = @UserID
    END
    ELSE
    BEGIN
        INSERT INTO LicenseeUser (LicenseeID,UserID,isActive,PageAccess)
        VALUES (@licenseeid,@UserID,1,'')
    END
	
	
	--Total bets
	INSERT INTO [LicenseeUserFunctions](LicenseeId, UserId, FunctionId)
	SELECT DISTINCT @LicenseeId, @UserId, f.FunctionId 
	FROM [Functions] f WITH(NOLOCK)
		INNER JOIN [LicenseeFunctions] l WITH(NOLOCK) ON f.FunctionId = l.FunctionId
	WHERE l.LicenseeId =@LicenseeId			
	AND (f.FunctionId = 1 OR f.ParentId = 1)
	AND f.FunctionId NOT IN (SELECT FunctionId FROM LicenseeUserFunctions WHERE LicenseeId =@LicenseeId	AND UserId = @UserId)
		
	--forecast
	INSERT INTO [LicenseeUserFunctions](LicenseeId, UserId, FunctionId)
	SELECT DISTINCT @LicenseeId, @UserId, f.FunctionId 
	FROM [Functions] f WITH(NOLOCK)
		INNER JOIN [LicenseeFunctions] l WITH(NOLOCK) ON f.FunctionId = l.FunctionId
	WHERE l.LicenseeId =@LicenseeId			
	AND (f.FunctionId = 2 OR f.ParentId = 2)
	AND f.FunctionId NOT IN (SELECT FunctionId FROM LicenseeUserFunctions WHERE LicenseeId =@LicenseeId	AND UserId = @UserId)	
	
	--Reports
	INSERT INTO [LicenseeUserFunctions](LicenseeId, UserId, FunctionId)
	SELECT DISTINCT @LicenseeId, @UserId, f.FunctionId 
	FROM [Functions] f WITH(NOLOCK)
		INNER JOIN [LicenseeFunctions] l WITH(NOLOCK) ON f.FunctionId = l.FunctionId
	WHERE l.LicenseeId =@LicenseeId			
	AND (f.FunctionId = 3 OR f.ParentId = 3)
	AND f.FunctionId NOT IN (SELECT FunctionId FROM LicenseeUserFunctions WHERE LicenseeId =@LicenseeId	AND UserId = @UserId)	
	
	--ManageMember
	INSERT INTO [LicenseeUserFunctions](LicenseeId, UserId, FunctionId)
	SELECT DISTINCT @LicenseeId, @UserId, f.FunctionId 
	FROM [Functions] f WITH(NOLOCK)
		INNER JOIN [LicenseeFunctions] l WITH(NOLOCK) ON f.FunctionId = l.FunctionId
	WHERE l.LicenseeId =@LicenseeId			
	AND (f.FunctionId = 4 OR f.ParentId = 4)
	AND f.FunctionId NOT IN (SELECT FunctionId FROM LicenseeUserFunctions WHERE LicenseeId =@LicenseeId	AND UserId = @UserId)	
	
	--DataWarehouse
	INSERT INTO [LicenseeUserFunctions](LicenseeId, UserId, FunctionId)
	SELECT DISTINCT @LicenseeId, @UserId, f.FunctionId 
	FROM [Functions] f WITH(NOLOCK)
		INNER JOIN [LicenseeFunctions] l WITH(NOLOCK) ON f.FunctionId = l.FunctionId
	WHERE l.LicenseeId =@LicenseeId			
	AND (f.FunctionId = 5 OR f.ParentId = 5)
	AND f.FunctionId NOT IN (SELECT FunctionId FROM LicenseeUserFunctions WHERE LicenseeId =@LicenseeId	AND UserId = @UserId)	
	AND (@IsAllowedDW=1)
	--Customer Reports
	INSERT INTO [LicenseeUserFunctions](LicenseeId, UserId, FunctionId)
	SELECT DISTINCT @LicenseeId, @UserId, f.FunctionId 
	FROM [Functions] f WITH(NOLOCK)
		INNER JOIN [LicenseeFunctions] l WITH(NOLOCK) ON f.FunctionId = l.FunctionId
	WHERE l.LicenseeId =@LicenseeId			
	AND (f.FunctionId = 52 OR f.ParentId = 52)
	AND f.FunctionId NOT IN (SELECT FunctionId FROM LicenseeUserFunctions WHERE LicenseeId =@LicenseeId	AND UserId = @UserId)

	
	------------------------------
	IF @Username NOT LIKE 'CSD_111%'
	BEGIN
		--Manage Account
		INSERT INTO [LicenseeUserFunctions](LicenseeId, UserId, FunctionId)
		SELECT DISTINCT @LicenseeId, @UserId, f.FunctionId 
		FROM [Functions] f WITH(NOLOCK)
			INNER JOIN [LicenseeFunctions] l WITH(NOLOCK) ON f.FunctionId = l.FunctionId
		WHERE l.LicenseeId =@LicenseeId			
		AND (f.FunctionId = 6 OR f.ParentId = 6)
		AND f.FunctionId NOT IN (SELECT FunctionId FROM LicenseeUserFunctions WHERE LicenseeId =@LicenseeId	AND UserId = @UserId)
	END

END
/*
	- Grant currency permission to Licensee's Users
	*/
	DECLARE @Currency AS TABLE (LicenseeID INT, CurrencyID INT)
	DECLARE @usr AS TABLE (LicenseeID INT ,UserID INT )


	INSERT INTO @Currency(LicenseeID,CurrencyID)
	SELECT DISTINCT LicenseeID,Currency CurrencyID
	FROM dbo.LicenseeCust WITH (NOLOCK)
	WHERE LicenseeID=@LicenseeID
	EXCEPT
	SELECT DISTINCT LicenseeID, CurrencyID
	FROM dbo.CurrencyUser WITH (NOLOCK )
	WHERE LicenseeID=@LicenseeID 
	
	INSERT INTO @usr (LicenseeID, UserID)
	SELECT DISTINCT LicenseeID,UserID 
	FROM dbo.LicenseeUser WITH (NOLOCK)
	WHERE LicenseeID=@LicenseeID
	
	INSERT INTO dbo.CurrencyUser(usrID,LicenseeID,CurrencyID,SystemID,isActive)
	SELECT u.UserID,u.LicenseeID,c.CurrencyID,1,1 ---SystemID=1 is default for Lrf
	FROM @usr u
		INNER JOIN 	@Currency c ON u.LicenseeID=c.LicenseeID
	
--- Add new Licensee belong to @ResellerID 
	IF @ResellerID<>0
	BEGIN
		IF NOT EXISTS(SELECT 1 FROM dbo.LicenseeReseller (NOLOCK) WHERE ResellerID=@ResellerID AND LicenseeID=@LicenseeId)
			BEGIN
				INSERT INTO [dbo].[LicenseeReseller](ResellerID,LicenseeID,TnxRate)
				SELECT @ResellerID,@LicenseeID,'0.13'
			END 
	END

------------------------------------------------------
-- Map Licencee to LicenseeBAConfig
------------------------------------------------------
EXEC DBA_LicenseeBAConfig_Ins
    @LicenseeID=@licenseeid,
    @groupa=0.0025,
    @groupb=0.005,
    @groupc=0.0075,
    @groupd=0.01,
    @1x2Comm=0.005,
    @OtherComm = 0.005,
    @EnableBA = 0,
    @UserID = 862400 --pgmViet	
	
	
END

GO
GRANT VIEW DEFINITION ON [dbo].[DBA_CreateNewLicensee] TO [vnteam] 
