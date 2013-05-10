
ALTER PROCEDURE  [dbo].[Acc_CustGroupAddByUsername]
	@Username varchar(50),
	@GroupName varchar(50),
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(1000) = '' OUTPUT,
	@UserID int 
AS
/*
	Created by: [Henry]
	Date: 2011-04-01
	Task: Insert an existing customer to External AccSite Group
	DB: DBAGE/bodb_AGE 
	
	Revisions:
		- 20110429@Jamie: Remove prefix DBLOG when call write log
		- 20110913@Jamie: Put linked server DBLOG because switching to DB053
		- 20110927@Lukas: modify to be able to put 1 customer into 2 groups
		- 20130121@Dan: Move sp from DB053/bodb02 to DBAGE/bodb_AGE, change linked server DB03 to DBPOLICY, DB06 to DBARC

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
		
	
	DECLARE @RoleID INT
	DECLARE @CustID INT, @SiteID int
	DECLARE @Currency INT
	DECLARE @SiteName varchar (50)
	
	SELECT 
		@RoleID = RoleID,@CustID = CustID ,@Currency = Currency, @SiteName = [Site]
	FROM 
		DBARC.bodb02.dbo.Customer with (nolock)
	WHERE 
		Username = @Username
	
	--Check custid
	if isnull(@CustID,0) = 0
	begin
		Select @ErrMsg = 	N'This username is invalid!'	
			, @ErrCode = 101
			return
	end
	
	--Check RoleID, should be super role
	if isnull(@RoleID,0) <> 4
	begin
		Select @ErrMsg = 	N'The role of this username is not super, please check again !'	
			, @ErrCode = 102
			return
	end
	
	--Check belonging group currency
	
	IF (@Currency NOT IN (SELECT exchangeID from bodb02.dbo.[f_CurrencyBySystem](@GroupName)))
	begin
		Select @ErrMsg = 	N'The currency of this username does not belong to this group !'
			, @ErrCode = 103
			return
	end
	
	--Check belonging site
	select @SiteID = SiteId From bodb02.dbo.[Site] (nolock) 
	where [site] = @SiteName
	
	IF (@SiteID NOT IN (SELECT siteid from bodb02.dbo.[f_SiteBySystem] (@GroupName)))
	begin
		Select @ErrMsg = 	N'The site of this username does not belong to this group !'
			, @ErrCode = 104
			return
	end
	
	
	if exists (select 1 from Acc_CustGroup (nolock) where CustID = @CustID AND GroupName = @GroupName)
	begin
		Select @ErrMsg = 	N'This username was added before, please check again!'
					
			, @ErrCode = 105
			return
	end
	
	insert into Acc_CustGroup (CustID,RoleID,GroupName)
	values (@CustID, @RoleID,@GroupName)
	
	
	
	--Write log data
	declare @LogData nvarchar(1000)
	
	SET @LogData = '<Acc_CustGroupAddByUsername UserID="' + CONVERT(VARCHAR(20), @UserID)
	+ '" CustID="' + CONVERT(VARCHAR(50), @CustID)
	+ '" Username="' + CONVERT(VARCHAR(50), @Username)
	+ '" Group="' + CONVERT(VARCHAR(50), @GroupName) + '" />'

	set @endRun = getdate()
	set @duration  = datediff (millisecond,@startRun,@endRun)

	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
	@UserID = @UserID,
	@CustID = @CustID,
	@ActionID = 618,
	@TrackingValue = @LogData	,
	@duration = @duration

GO
GRANT EXECUTE ON [dbo].[Acc_CustGroupAddByUsername] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustGroupAddByUsername] TO [vnteam]