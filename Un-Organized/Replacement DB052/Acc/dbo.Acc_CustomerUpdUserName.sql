USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Acc_CustomerUpdUserName]    Script Date: 12/13/2012 02:22:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Acc_CustomerUpdUserName_xtest    Script Date: 7/11/2012 2:15:49 AM ******/

ALTER PROC [dbo].[Acc_CustomerUpdUserName]
	@oldname varchar(30), 
	@newname varchar(30),
	@userid int = 8,	
	@ReturnCustId int = 0 output,
	@IP varchar(15) = '',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
SET NOCOUNT ON

/*
Created: 
Task : Change username 
DB: DBTRANS.bodb02
Original:

Revisions:
    - 20080213@Phuc: Check permission for account site
    - 20080815@PhuongDao: Check an account disabled or not
    - 20090218@PhuongDao: Check username2
    - 20090517@Thien: update username on bettrans and bettrans14 / write log userlog_runSP
    - 20090528@Kiwi: add checking for Casino
    - 20090701@Lee: Return custid for casino customer 
	- 20090828@HuyNguyen: replace [Customer] --> [OtherCust]	
	- 20090917@Phuc: Write log into dblog.
	- 20091008@Kiwi: Remove WriteLog_UserLog	
	- 20091112@Simon: Write Log IP
	- 20100107@Lewin: Change LogSPData format, write log by new function
	- 20101021@Henry: Record execution time
	- 20110517@Jamie: Expand the size of input name to varchar(30)
	- 20110722@Sophia: Add prefix 'Agency$' to Username2
	- 20110722@Sophia: Remove prefix 'Agency$' to Username2
	- 20110907@Lukas: Change linked-server from DB052 -> DB053
	- 20120507@Lukas: call update username in CRM system
	- 20121213@Dan: Change linked server from DB052-->DBCRM

Param's Explanation:
• @ErrCode:
    = 0: super create master successfully.
    > 0: Specific Error.
  
• @ErrMsg: Error description.
*/

declare @startRun datetime
declare @endRun datetime
declare @duration int
set @startRun = getdate()

--Check permission for account site: @phuc20080213
EXEC db03.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[OtherCust]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
If @ErrCode <> 0
	RETURN

Declare @custid int, @syncCasino bit
select @custid = custid, @syncCasino = SyncCasino from custinfo with (nolock) where username = @oldname

if @syncCasino = 1
BEGIN
	SELECT @ReturnCustId = @custid
END

if	exists(select 1 from customer with (nolock) where username = @oldname) 
	and not exists (select 1 from customer with (nolock) where username =@newname) and @newname <> ''
	and not exists (select 1 from customer with (nolock) where username2 = @newname )
	and not exists (select 1 from custsub with (nolock) where username =@newname)
BEGIN

	--CHECK an account disabled or not 
	EXEC DB053.bodb02.dbo.Acc_CustomerSelCheckEnable @username = @oldname, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output 
	if @ErrCode <>0	 return
	
	update customer with (rowlock, updlock) set username = @newname where custid = @custid
	update custinfo with (rowlock, updlock) set username = @newname where custid = @custid
	
	update bettrans with (rowlock, updlock) set username = @newname where custid = @custid
	update bettrans14 with (rowlock, updlock) set username = @newname where custid = @custid
END
else
BEGIN	
	if @oldname = @newname
		select @ErrMsg = 'An error occurs. New username and old username are the same!', @ErrCode = 101
	else
		select @ErrMsg = 'An error occurs. The user does not exist or new username is not available: ['+ @oldname + '] - ['+@newname+']', @ErrCode = 102		
	return
END
declare @LogSPData nvarchar(1000)

Select @LogSPData = '<Acc_CustomerUpdUserName  FromName="' + @oldname + '" ToName="' + @newname + '" ' +
					'userid="'+ coalesce(cast(@userid as varchar(50)),space(1))+ '" ' +
					'IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+ '" ' +
					'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1))+ '" ' +
					'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(400)),space(1))+'" />'

EXEC [DBCRM].[bodb_CRM].[dbo].[Acc_CRM_CustomerUpdUsername]
				@NewUsername = @newname,
				@CustID		 = @CustID,	
				@UserID		 = @UserID,
				@IP			 = @IP,
				@ErrCode	 = @ErrCode OUTPUT,
				@ErrMsg		 = @ErrMsg OUTPUT
IF @ErrCode <> 0
BEGIN
	SET @ErrMsg = 'Update username does not successfully. ' + @ErrMsg
	--- manually rollback
	update customer with (rowlock, updlock) set username = @oldname where custid = @custid
	update custinfo with (rowlock, updlock) set username = @oldname where custid = @custid
	
	update bettrans with (rowlock, updlock) set username = @oldname where custid = @custid
	update bettrans14 with (rowlock, updlock) set username = @oldname where custid = @custid
	
	RETURN
END

set @endRun = getdate()
set @duration  = datediff (millisecond,@startRun,@endRun)

/*605 Acc_CustomerUpdUserName Change username */
EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
	@UserID = @UserID,
	@CustID = @CustID,
	@ActionID = 605,
	@TrackingValue = @LogSPData,
	@duration = @duration
