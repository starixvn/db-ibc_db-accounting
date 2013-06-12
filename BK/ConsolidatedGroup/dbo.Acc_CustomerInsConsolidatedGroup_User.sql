
ALTER PROCEDURE [dbo].[Acc_CustomerInsConsolidatedGroup_User]
	@username VARCHAR(30),
	@GroupID INT,
	@UserID INT,
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(500) = '' OUTPUT,
	@Language VARCHAR(2)= 'E',
	@IP VARCHAR(15) = ''
AS
/*	
	Created: Sophia
	Date: 2011-07-12
	Task : Update Customer to Consolidated Group: add new member or change member to other group  
	DB: DBAGE/bodb_AGE
	Original:  
	Revisions:
		- 20130121@Dan: Move sp from DB053/bodb02 to DBAGE/bodb_AGE, change linked server DB03 to DBPOLICY
*/

SET NOCOUNT ON

DECLARE @startRun DATETIME
DECLARE @endRun DATETIME
DECLARE @duration INT
DECLARE @RoleID INT
DECLARE @db_Creator INT
DECLARE @db_CreatedDate DATETIME
DECLARE @CreateDate DATETIME

SET @startRun = getdate()
 
--Check permission for account site 
EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[ConsolidatedGroup]',@ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
IF @ErrCode <> 0
	RETURN


DECLARE @Custid INT
 
SELECT @Custid = ISNULL(Custid,0), @RoleID = ISNULL(RoleID,0 )
FROM   bodb02.dbo.Customer WITH (NOLOCK) 
WHERE  username = @username
 
SELECT @Custid = ISNULL(@Custid,0), @RoleID = ISNULL(@RoleID,0)

IF @custid  = 0
BEGIN
SELECT @ErrMsg = 'Customer is not valid.'
	 , @ErrCode = 102
	RETURN
END

IF @RoleID > 4
BEGIN 
SELECT @ErrMsg = 'Customer is not valid.'
	 , @ErrCode = 103
	RETURN
END 

--Check an account disabled or not
 EXEC bodb02.dbo.Acc_CustomerSelCheckEnable @username = @username, @ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
 IF @ErrCode <>0        
	RETURN
 

IF EXISTS ( SELECT 1
			FROM Age_CustGroup WITH (NOLOCK)
			WHERE custid = @custid	AND	isHeader = 1)
BEGIN
	SELECT @ErrMsg = 'Cannot add this user because this user is already headline in some group.'
		 , @ErrCode = 103
	RETURN
END


----
DECLARE @db_Group INT
SET @db_Group = 0
 
SELECT	@db_Group = GroupID,
		@db_Creator = Creator ,
		@db_CreatedDate = CreatedDate
FROM	Age_CustGroup WITH (NOLOCK)
WHERE   Custid = @Custid 


IF ISNULL(@db_Group,0) = @GroupID AND ISNULL(@db_Group,0) <> 0 
BEGIN
	SELECT @ErrMsg = 'This user has already been a member of this group.'
	, @ErrCode = 104
	RETURN
END


IF ISNULL(@db_Group,0) <> @GroupID AND ISNULL(@db_Group,0) <> 0 
	SELECT @ErrMsg = 'Add successfully. (Warning: This user used to be a member of the group: '+ Convert(varchar(30),@db_Group) +').'  ----warning but saved!
	, @ErrCode = 0
ELSE
	SELECT @ErrMsg = 'Add user to group successfully.' 
	, @ErrCode = 0



----update group 
SET @CreateDate = GETDATE()

UPDATE Age_CustGroup WITH (ROWLOCK, UPDLOCK) 
SET
	Remark = '',
	GroupID = @GroupID,
	RoleID = @RoleID, 
	isHeader = 0,
	Creator = @UserID,
	CreatedDate =  @CreateDate
WHERE Custid = @Custid

IF @@ROWCOUNT = 0
INSERT INTO Age_CustGroup (GroupID, CustID, RoleID, isHeader, Creator, CreatedDate, Remark)
VALUES (@GroupID, @CustID, @RoleID, 0, @UserID, @CreateDate, '')
---end


---- Write log for add customer to Consolidated Group
DECLARE @LogSPData AS NVARCHAR(MAX)
DECLARE @TrackingValue2 AS NVARCHAR(MAX)

SELECT @LogSPData = '<Acc_CustomerInsConsolidatedGroup_User Custid="' + convert (VARCHAR(20), @CustID) + '" ' +
		   'GroupID="' + convert (VARCHAR(20), @GroupID) + '" ' +
		   'IP="' + coalesce (cast (@IP AS VARCHAR(15)), space (1)) + '" ' +
		   'Creator="' + coalesce (cast (@UserID AS VARCHAR(15)), space (1)) + '" ' +
		   'CreatedDate="' + coalesce (cast (@CreateDate AS VARCHAR(20)), space (1)) + '" ' +
		   'ErrCode="' + coalesce (cast (@ErrCode AS VARCHAR(10)), space (1)) + '" ' +
		   'ErrMsg="' + @ErrMsg + '" />'

SELECT @TrackingValue2 = '<Acc_CustomerInsConsolidatedGroup_User Custid="' + convert (VARCHAR(20), @CustID) + '" ' +
	   'GroupID="' + convert (VARCHAR(20), @db_Group) + '" ' + 
	   'IP="' + coalesce (cast (@IP AS VARCHAR(15)), space (1)) + '" ' +
	   'Creator="' + coalesce (cast (@db_Creator AS VARCHAR(15)), space (1)) + '" ' +
	   'CreatedDate="' + coalesce (cast (@db_CreatedDate AS VARCHAR(20)), space (1)) + '" ' +
	   'ErrCode="' + coalesce (cast (@ErrCode AS VARCHAR(10)), space (1)) + '" ' +
	   'ErrMsg="' + @ErrMsg + '" />'


	SET @endRun = getdate()
	SET @duration  = datedIFf (millisecond,@startRun,@endRun)

	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
		@UserID = @UserID,
		@CustID = @Custid,
		@ActionID = 624,
		@TrackingValue = @LogSPData,
	    @TrackingValue2 = @TrackingValue2,
		@duration = @duration
	
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerInsConsolidatedGroup_User] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerInsConsolidatedGroup_User] TO [vnteam]