
ALTER PROCEDURE [dbo].[Acc_CustomerUpdConsolidatedGroup]
	@username VARCHAR(30),
	@Remark NVARCHAR(500),
	@UserID INT,
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(500) = '' OUTPUT,
	@Language VARCHAR(2)= 'E',
	@IP VARCHAR(15) = ''
AS
/*	
	Created: Sophia
	Date: 2011-07-12
	Task : Set Consolidated Group  
	DB: DBAGE/bodb_AGE
	Original:  
	
	Revisions:
	- 20110816@Sophia: This sp only add a new group headline
	- 20130121@Dan: Move sp from DB053/bodb02 to DBAGE/bodb_AGE, change linked server DB03 to DBPOLICY
	
*/

SET NOCOUNT ON

DECLARE @StartRun DATETIME
DECLARE @EndRun DATETIME
DECLARE @Duration INT
DECLARE @RoleID INT
SET @StartRun = getdate()

DECLARE @CreatedDate DATETIME

DECLARE @GroupID INT,  
		@isHeader BIT

Declare @NewGroupID INT, 
		@db_GroupID INT, 
		@db_isHeader BIT,
		@NotFound BIT,
		@db_Remark NVARCHAR(200),
		@db_RoleID INT 

SET @ErrCode = 0
SET @ErrMsg = ''
SET @NewGroupID = 0 
      
--Check permission for account site 
EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @CustID=@UserID, @funcname='[ConsolidatedGroup]', @ErrCode=@ErrCode OUTPUT, @ErrMsg=@ErrMsg OUTPUT
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

IF @RoleID = 1 ----- Member can not Group Headline
BEGIN 
SELECT @ErrMsg = 'Customer is not valid.'
	 , @ErrCode = 104
	RETURN
END 


EXEC bodb02.dbo.Acc_CustomerSelCheckEnable @CustID = @CustID, @ErrCode=@ErrCode OUTPUT, @ErrMsg=@ErrMsg OUTPUT
	IF @ErrCode <>0 
 RETURN


SET @NotFound = 0

SELECT @NewGroupID = MAX(GroupID) + 1
FROM Age_CustGroup WITH (NOLOCK)

IF ISNULL(@NewGroupID, 0) = 0 SELECT @NewGroupID = isnull(@NewGroupID,0) + 1
 

SET @db_GroupID = NULL

SELECT @db_GroupID = GroupID
	 , @db_RoleID = RoleID
	 , @db_isHeader = isHeader
	 , @db_Remark = Remark
FROM   Age_CustGroup WITH (NOLOCK)
WHERE  CustID = @CustID
 


IF @db_GroupID IS NULL
SELECT @NotFound = 1

SELECT @db_GroupID = isnull(@db_GroupID, 0)
	 , @db_isHeader = isnull(@db_isHeader, 0)

IF	   @NotFound = 1 
SELECT @ErrMsg = 'New group created.'
	 , @GroupID = @NewGroupID
	 , @isHeader = 1
  

IF @NotFound = 0  AND @db_isHeader = 0  
BEGIN
	SELECT @ErrMsg = 'New group created.'
		 , @GroupID = @NewGroupID
		 , @isHeader = 1
END 
 

----
 
SELECT	@db_GroupID = GroupID 
FROM	Age_CustGroup WITH (NOLOCK)
WHERE   Custid = @Custid 

IF ISNULL(@db_GroupID,0) <> 0 
BEGIN
	SELECT  @ErrMsg = 'New group created. (Warning: This user used to be a member of the group: '+ Convert(varchar(30),@db_GroupID)  +').'
			, @ErrCode = 0
END

----
IF @NotFound = 0 AND @db_isHeader = 1  
BEGIN 
	SELECT @ErrMsg = 'This group has already existed.'
		 , @ErrCode = 105
		 , @GroupID = @db_GroupID
		 , @isHeader = 1
	RETURN 
 END 



---UPDATE Age_CustGroup	
SET @CreatedDate = GETDATE()

UPDATE  Age_CustGroup WITH (ROWLOCK, UPDLOCK) 
SET		Remark = @Remark,
		GroupID = @GroupID,
		RoleID = @RoleID,
		isHeader = @isHeader,
		Creator = @UserID,
		CreatedDate = @CreatedDate
WHERE	CustID = @CustID

IF @@ROWCOUNT = 0
INSERT INTO Age_CustGroup (GroupID, CustID, RoleID, isHeader, Creator, CreatedDate, Remark)
VALUES (@GroupID, @CustID, @RoleID, @isHeader, @UserID, @CreatedDate, @Remark)
---end 

---Write log 
DECLARE @LogSPData AS NVARCHAR(MAX) 


SELECT @LogSPData = '<Acc_CustomerUpdConsolidatedGroup GroupID="' + convert (VARCHAR(20), @GroupID) + '" ' + 
       'CustID="' + convert (VARCHAR(20), @CustID) + '" ' +
	   'RoleID="' + convert (VARCHAR(20), @RoleID) + '" ' +
	   'Remark="' + dbo.f_EncodeXMLValue (coalesce (cast (@Remark AS NVARCHAR(200)), space (1))) + '" ' +
	   'isHeader="' + coalesce (cast (@isHeader AS VARCHAR(10)), space (1)) + '" ' +
	   'IP="' + coalesce (cast (@IP AS VARCHAR(15)), space (1)) + '" ' +
	   'Creator="' + coalesce (cast (@UserID AS VARCHAR(15)), space (1)) + '" ' +
	   'CreatedDate="' + coalesce (cast (@CreatedDate AS VARCHAR(20)), space (1)) + '" ' +
	   'ErrCode="' + coalesce (cast (@ErrCode AS VARCHAR(10)), space (1)) + '" ' +
	   'ErrMsg="' + @ErrMsg + '" />'



SET @EndRun = getdate()
SET @Duration  = datedIFf (millisecond,@StartRun,@EndRun)

/*623	Acc_CustomerUpdConsolidatedGroup	Update Consolidated Group*/
EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
	@UserID = @UserID,
	@CustID = @CustID,
	@ActionID = 623,
	@TrackingValue = @LogSPData,
	@TrackingValue2 = NULL,
	@Duration = @Duration
		 
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdConsolidatedGroup] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdConsolidatedGroup] TO [vnteam]