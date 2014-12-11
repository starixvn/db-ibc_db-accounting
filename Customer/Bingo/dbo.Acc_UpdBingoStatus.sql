USE [CustDB]
GO
ALTER PROCEDURE [dbo].[Acc_UpdBingoStatus]
	@custid INT,
	@disabledBingo BIT=NULL,
	@syncBG BIT=NULL,
	@enableDownline BIT=0,
	@ErrMsg NVARCHAR(200) = '' OUTPUT,	
	@ErrCode		int = 0 OUTPUT,
	@UserID INT = 0,
	@SubAccID INT = 0, --Sub-AccountID
	@LoginIP VARCHAR(20)='',
	@Language VARCHAR(2) = 'E'
AS
/*

Created:20100831@Jamie
Task: Update Bingo status
DB: DBTXN/bodb02
Original:

Revisions:
	- 20101021@Henry: Record execution time
	- 20110531@Amy: Check Old/New value
					Check Upline Disable Bingo, if Upline is disabled then raise error
	- 20110711@Amy: Split/amend the update command to fix the clustered index scan
	- 20110709@Johnson: Change to use new server BD053 instead DB052
	- 20120723@Jamie: add more condition SyncBingo to return or not
	- 20121206@Scott : Check Allowed downlines during peak hour at weekend 
	- 20130124@Elodie: Get an error message from f_Get_MsgNameByMsgID function by language
	- 20130307@Lukas: change linked-server alias & add more write log section
	- 20130311@Dan: Change linked server DB053 to DBAGE
	- 20130827@Johnson: Check enabled status on DBTXN instead of DBAGE
	- 20130926@Kathy: Apply exec rep
	- 20131108@Elodie: Splitting bodb02 into CustDB (Turn to use Acc_ExecRep_Cust_04)	
	- 20141125@Jamie: Use Acc_CustomerInfo_Execrep_04 instead of Acc_ExecRep_Cust_04 [Redmine:#26497]	
*/
SET NOCOUNT ON

declare @startRun datetime
declare @endRun datetime
declare @duration int
set @startRun = getdate()

--Check disable user
EXEC dbo.Acc_CustomerSelCheckEnable @custid = @custid, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
if @ErrCode <>0 return
--end

BEGIN TRY

-- Checking

DECLARE @Allow2Update BIT, @SyncBingo BIT ,@RoleID TINYINT,@UplineSyncBI BIT, @UplineEnableBI BIT, @Old_disabledBingo BIT
SELECT @SyncBingo=SyncBingo,@RoleID=RoleID,@Old_disabledBingo=disableBingo  FROM custinfo(NOLOCK) WHERE custid=@custid
IF(@RoleID IS NULL OR @roleid > 4) 
BEGIN
	SELECT @ErrCode = 100,@ErrMsg = CASE @Language WHEN 'E' THEN 'Account does not exist or invalid customer account'
											ELSE [dbo].[f_Get_MsgNamebyMsgID](40019,@Language) END	
	RETURN
END

-- Check Allowed downlines during peak hour at weekend 
IF @disabledBingo = 1 OR @enableDownline = 1
BEGIN
				EXEC DBAGE.bodb02.dbo.Acc_CustomerSelCheckAllowedDownlines	@custid=@custid,
											@roleid=@roleid,
											@isExecRep=1,
											@Language=@Language,
											@ErrMsg=@ErrMsg output,
											@ErrCode=@ErrCode output
	IF @ErrCode <>0 RETURN
END	
--End 
	
IF @SyncBingo = 0  AND @syncBG = 0 AND @disabledBingo = 0
BEGIN
	SELECT @ErrCode = 101,@ErrMsg = CASE @Language WHEN 'E' THEN 'Cannot enable Bingo for this account due to lack of settings.'
											ELSE [dbo].[f_Get_MsgNamebyMsgID](60024,@Language) END
						
	RETURN
END

IF(@roleid = 4)
	SELECT @Allow2Update=1
ELSE
BEGIN
	SELECT @UplineSyncBI = ISNULL((SyncBingo),0), @UplineEnableBI = case when DisableBingo = 0 then 1 else 0 end
	FROM custinfo(NOLOCK)
	WHERE
	custid = (SELECT CASE roleid WHEN 1 THEN recommend
								WHEN 2 THEN mrecommend
								WHEN 3 THEN srecommend END
		  FROM custinfo(NOLOCK) WHERE custid=@custid)
		  
	IF @UplineSyncBI = 1 AND ( @UplineEnableBI = 1  OR (@UplineEnableBI = 0 AND @disabledBingo = 1))
		SET @Allow2Update=1
	ELSE
		SET @Allow2Update=0
END

IF @Allow2Update = 0
BEGIN
	SELECT @ErrCode = 102,@ErrMsg = CASE @Language WHEN 'E' THEN 'Cannot enable Bingo because the upline either has Bingo disaled or does not have any settings.'
													ELSE [dbo].[f_Get_MsgNamebyMsgID](60025,@Language) END					
	RETURN
END

IF @Old_disabledBingo = @disabledBingo AND @SyncBingo=@syncBG RETURN

-- Update itself
UPDATE CustInfo SET
	DisableBingo = ISNULL(@disabledBingo, DisableBingo),
	SyncBingo = @syncBG --CASE @syncBG WHEN 1 THEN 1 ELSE SyncBingo END
WHERE custid=@custid

-- Update downline
IF @disabledBingo = 1 OR @enableDownline = 1
BEGIN
	--20130926@Kathy: Apply ExecRep 
	EXEC [Acc_CustomerInfo_Execrep_04]
		@CustID		= @CustID,
		@RoleID		= @RoleID,
		@Action		= 'BingoStatus',
		@BingoStatus = @disabledBingo    
END 	
END TRY
BEGIN CATCH
	SELECT @ErrCode = 103, @ErrMsg = 'System error!'	
END CATCH

--Log data
--Log data
DECLARE @LogData NVARCHAR(4000)
DECLARE @TrackingValue2 NVARCHAR(4000)
---------------------------
select @LogData ='<Acc_UpdBingoStatus custid="'+ coalesce(cast(@custid as varchar(50)),space(1)) + '" ' +
'disabledBG="'+ coalesce(cast(@disabledBingo as varchar(50)),space(1)) + '" ' +
'syncBG="'+ coalesce(cast(@syncBG as varchar(50)),space(1)) + '" ' +
'enableDownline="'+ coalesce(cast(@enableDownline as varchar(50)),space(1)) + '" ' +
'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" ' +
'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(400)),space(1)) + '" ' +
'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" ' +
'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),space(1)) + '" ' +
'LoginIP="'+ coalesce(cast(@LoginIP as varchar(20)),space(1)) + '" ' +
'Language="'+ coalesce(cast(@Language as varchar(2)),space(1))  + '" />'

select @TrackingValue2 ='<Acc_UpdBingoStatus custid="'+ coalesce(cast(@custid as varchar(50)),space(1)) + '" ' +
'disabledBG="'+ coalesce(cast(@Old_disabledBingo as varchar(50)),space(1)) + '" ' +
'syncBG="'+ coalesce(cast(@SyncBingo as varchar(50)),space(1)) + '" ' +
'enableDownline="'+ coalesce(cast(@enableDownline as varchar(50)),space(1)) + '" ' +
'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" ' +
'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(400)),space(1)) + '" ' +
'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" ' +
'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),space(1)) + '" ' +
'LoginIP="'+ coalesce(cast(@LoginIP as varchar(20)),space(1)) + '" ' +
'Language="'+ coalesce(cast(@Language as varchar(2)),space(1))  + '" />'

set @endRun = getdate()
set @duration  = datediff (millisecond,@startRun,@endRun)

BEGIN TRY
	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
		@UserID = @UserID, 
		@CustID = @custid,
		@ActionID = 1121,
		@TrackingValue = @LogData,
		@TrackingValue2 = @TrackingValue2,
		@duration = @duration
END TRY
BEGIN CATCH
	select @LogData ='<Acc_UpdBingoStatus custid="'+ coalesce(cast(@custid as varchar(50)),space(1)) + '" ' +
					'disabledBG="'+ coalesce(cast(@disabledBingo as varchar(50)),space(1)) + '" ' +
					'syncBG="'+ coalesce(cast(@syncBG as varchar(50)),space(1)) + '" ' +
					'enableDownline="'+ coalesce(cast(@enableDownline as varchar(50)),space(1)) + '" ' +
					'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" ' +
					'ErrMsg="'+ coalesce(cast(ERROR_MESSAGE() as varchar(2000)),space(1)) + '" ' +
					'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" ' +
					'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),space(1)) + '" ' +
					'LoginIP="'+ coalesce(cast(@LoginIP as varchar(20)),space(1)) + '" ' +
					'Language="'+ coalesce(cast(@Language as varchar(2)),space(1))  + '" />'

					select @TrackingValue2 ='<Acc_UpdBingoStatus custid="'+ coalesce(cast(@custid as varchar(50)),space(1)) + '" ' +
					'disabledBG="'+ coalesce(cast(@Old_disabledBingo as varchar(50)),space(1)) + '" ' +
					'syncBG="'+ coalesce(cast(@SyncBingo as varchar(50)),space(1)) + '" ' +
					'enableDownline="'+ coalesce(cast(@enableDownline as varchar(50)),space(1)) + '" ' +
					'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" ' +
					'ErrMsg="'+ coalesce(cast(ERROR_MESSAGE() as varchar(2000)),space(1)) + '" ' +
					'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" ' +
					'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),space(1)) + '" ' +
					'LoginIP="'+ coalesce(cast(@LoginIP as varchar(20)),space(1)) + '" ' +
					'Language="'+ coalesce(cast(@Language as varchar(2)),space(1))  + '" />'

	EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
		@UserID = @UserID, 
		@CustID = @custid,
		@ActionID = 1121,
		@TrackingValue = @LogData,
		@TrackingValue2 = @TrackingValue2,
		@duration = @duration
END CATCH

GO
GRANT EXECUTE ON [dbo].[Acc_UpdBingoStatus] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Acc_UpdBingoStatus] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Acc_UpdBingoStatus] TO [bodbExtAccNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_UpdBingoStatus] TO [vnteam] AS [dbo]