ALTER PROCEDURE  [dbo].[Acc_CustGroupDel]
	@CustID int,
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
*/
	SET NOCOUNT ON 
	
	declare @startRun datetime
	declare @endRun datetime
	declare @duration int
	set @startRun = getdate()
	
	--Check permission for account site
	
	EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[Admin_ManageExAcc]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output, @System = 'ACCOUNTING'
	If @ErrCode <> 0
		RETURN			
	
	if not exists (select 1 from Acc_CustGroup (nolock) where CustID = @CustID)
	begin
		Select @ErrMsg = 	N'This Customer does not exist'
			, @ErrCode = 101
			return
	end
	
	DECLARE @GroupName varchar(50)
	select @GroupName = GroupName from Acc_CustGroup (nolock) where CustID = @CustID
	
	DELETE FROM Acc_CustGroup WITH (ROWLOCK,UPDLOCK) WHERE CustID = @CustID
	
	
	--Write log data
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
	@TrackingValue = @LogData	,
	@duration = @duration

GO
GRANT EXECUTE ON [dbo].[Acc_CustGroupDel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustGroupDel] TO [vnteam]