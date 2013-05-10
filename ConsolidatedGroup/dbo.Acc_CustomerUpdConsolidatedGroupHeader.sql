 SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
ALTER PROCEDURE [dbo].[Acc_CustomerUpdConsolidatedGroupHeader]
	@CustID INT,
	@GroupID INT,
	@UserID INT,
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(200) = '' OUTPUT,
	@Language VARCHAR(2)= 'E',
	@IP VARCHAR(15) = ''
AS
/*	
	Created: Sophia
	Date: 2011-07-12
	Task : Change Consolidated Group Header
	DB: DBAGE/bodb_AGE
	Original:  
	Revisions:	
	- 20130121@Dan: Move sp from DB053/bodb02 to DBAGE/bodb_AGE, change linked server DB03 to DBPOLICY

*/

SET NOCOUNT ON

DECLARE @startRun DATETIME
DECLARE @endRun DATETIME
DECLARE @duration INT
DECLARE @db_CustID INT 
SET @startRun = getdate()

DECLARE @db_Creator INT
DECLARE @db_CreatedDate DATETIME
DECLARE @CreatedDate DATETIME

--Check permission for account  
EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @CustID=@UserID,@funcname='[ConsolidatedGroup]',@ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
IF @ErrCode <> 0
	RETURN

--Check an account disabled or not
 EXEC bodb02.dbo.Acc_CustomerSelCheckEnable @CustID = @CustID, @ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
 IF @ErrCode <>0  
	RETURN


IF NOT EXISTS (	SELECT TOP 1 1
				FROM Age_CustGroup WITH (NOLOCK)
				WHERE CustID = @CustID  AND GroupID = @GroupID)
BEGIN
	SELECT @ErrMsg = 'This user does not belong to this group.',
		   @ErrCode = 101
	RETURN
END

IF EXISTS (	SELECT TOP 1 1
				FROM Age_CustGroup WITH (NOLOCK)
				WHERE CustID = @CustID  AND GroupID = @GroupID AND RoleID = 1)
BEGIN
	SELECT @ErrMsg = 'Headline can''t be a member.',
		   @ErrCode = 102
	RETURN
END


SELECT  @db_CustID = CustID,
		@db_Creator = Creator,
		@db_CreatedDate = CreatedDate  
FROM Age_CustGroup WITH (NOLOCK)
WHERE GroupID = @GroupID AND isHeader = 1

----change group header

SET @CreatedDate = GETDATE()

UPDATE	Age_CustGroup WITH (UPDLOCK , ROWLOCK)
SET		isHeader = 0,
		Creator = @UserID,
		CreatedDate = @CreatedDate
WHERE	GroupID = @GroupID AND isHeader = 1

UPDATE  Age_CustGroup WITH (UPDLOCK , ROWLOCK)
SET		isHeader = 1,
		Creator = @UserID,
		CreatedDate = @CreatedDate
WHERE   CustID = @CustID

---Write Log
DECLARE @LogData nvarchar(1000)
DECLARE @TrackingValue2 nvarchar(1000)


SELECT @LogData = '<Acc_CustomerUpdConsolidatedGroupHeader CustID="' + convert (VARCHAR(20), @CustID) + '" ' +
	   'GroupID="' + convert (VARCHAR(20), @GroupID) + '" ' +
	   'IP="' + coalesce (cast (@IP AS VARCHAR(15)), space (1)) + '" ' +
	   'Creator="' + coalesce (cast (@UserID AS VARCHAR(15)), space (1)) + '" ' +
	   'CreatedDate="' + coalesce (cast (@CreatedDate AS VARCHAR(20)), space (1)) + '" ' +
	   'ErrCode="' + coalesce (cast (@ErrCode AS VARCHAR(10)), space (1)) + '" ' +
	   'ErrMsg="' + @ErrMsg + '" />'

SELECT @TrackingValue2 = '<Acc_CustomerUpdConsolidatedGroupHeader CustID="' + convert (VARCHAR(20), @db_CustID) + '" ' +
	   'GroupID="' + convert (VARCHAR(20), @GroupID) + '" ' +
	   'IP="' + coalesce (cast (@IP AS VARCHAR(15)), space (1)) + '" ' +
	   'Creator="' + coalesce (cast (@db_Creator AS VARCHAR(15)), space (1)) + '" ' +
	   'CreatedDate="' + coalesce (cast (@db_CreatedDate AS VARCHAR(20)), space (1)) + '" ' +
	   'ErrCode="' + coalesce (cast (@ErrCode AS VARCHAR(10)), space (1)) + '" ' +
	   'ErrMsg="' + @ErrMsg + '" />'


SET @endRun = getdate()
SET @duration  = datedIFf (millisecond,@startRun,@endRun)

EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
	@UserID = @UserID,
	@CustID = @CustID,
	@ActionID = 626,
	@TrackingValue = @LogData,
	@TrackingValue2=@TrackingValue2,
	@duration = @duration

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdConsolidatedGroupHeader] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdConsolidatedGroupHeader] TO [vnteam]