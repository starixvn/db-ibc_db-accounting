USE [bodb_Age]
GO

ALTER PROCEDURE  [dbo].[Acc_CustGroupDel]
	@CustID int,
	@GroupName	VARCHAR(50),
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@UserID int 
AS
/*
	Created by: [Henry]
	Date: 2011-04-01
	Task: Remove a customer out of Acc_CustGroup
	DB: DBAGE/bodb_AGE 
	
	Revisions:
		- 20110429@Jamie: Remove prefix DBLOG when call write log
		- 20110913@Jamie: Put linked server DBLOG because switching to DB053
		- 20130121@Dan: Move sp from DB053/bodb02 to DBAGE/bodb_AGE, change linked server DB03 to DBPOLICY
		- 20160727@Percy: Add parameter @GroupName to remove only @CustID from @GroupName [RemdineID: #60883]
*/
	SET NOCOUNT ON 
	
	declare @startRun datetime
	declare @endRun datetime
	declare @duration int
	set @startRun = getdate()
	
	-- Check permission for account site
	EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission
		@CustID = @UserID,
		@FuncName = '[Admin_ManageExAcc]',
		@ErrCode = @ErrCode OUTPUT,
		@ErrMsg = @ErrMsg OUTPUT,
		@System = 'ACCOUNTING'
	
	IF @ErrCode <> 0
		RETURN		
	
	if not exists (select 1 from Acc_CustGroup (nolock) where CustID = @CustID)
	begin
		Select
			@ErrMsg = 	N'This Customer does not exist',
			@ErrCode = 101
		return
	end

	if not exists (select 1 from Acc_CustGroup (nolock) where CustID = @CustID AND GroupName = @GroupName)
	begin
		Select
			@ErrMsg = 	N'This Customer does not belong to this group!',
			@ErrCode = 102
		return
	end

	-- Check Extra PT Group
	IF EXISTS (SELECT 1 FROM OPENQUERY(DBACC, 'SELECT GroupName FROM bodb_Acc.dbo.Acc_DWLList_ExtraPT WITH(NOLOCK)') WHERE GroupName = @GroupName)
	BEGIN
		-- delete setting
		EXEC DBACC.bodb_ACC.dbo.Acc_GroupExtraPTSetting_Upd
			@CustID = @CustID,
			@GroupName = @GroupName,
			@EffectiveDate = NULL, -- delete
			@UserID = @UserID,
			@ErrCode = @ErrCode OUTPUT,
			@ErrMsg	= @ErrMsg OUTPUT

		IF @ErrCode <> 0
			RETURN
	END

	DELETE FROM Acc_CustGroup WITH (ROWLOCK,UPDLOCK) WHERE CustID = @CustID AND GroupName = @GroupName
	
	-- Write log data
	declare @LogData nvarchar(1000)
	SET @LogData = '<Acc_CustGroupDel UserID="' + CONVERT(VARCHAR(20), @UserID)
					+ '" CustID="' + CONVERT(VARCHAR(50), @CustID)
					+ '" Group="' + CONVERT(VARCHAR(50), @GroupName) + '" />'

	set @endRun = getdate()
	set @duration  = datediff (millisecond,@startRun,@endRun)

	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		@UserID = @UserID,
		@CustID = @CustID,
		@ActionID = 619,
		@TrackingValue = @LogData,
		@duration = @duration

GO
GRANT EXECUTE ON [dbo].[Acc_CustGroupDel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustGroupDel] TO [vnteam]