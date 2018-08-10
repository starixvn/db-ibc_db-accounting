/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,bodbDownlineNet,bodbExtAccNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerUpdTransferOption]
	@CustId INT,
	@TransferOption VARCHAR(8),
	@UserID INT = 0,
	@IP VARCHAR(15) = '',
	@SubAccID INT = 0, --Sub-AccountID
	@Language VARCHAR(2) = 'E',
	@ReturnErrCode BIT = 0,	
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(200) = '' OUTPUT
AS
/*
Created: 
Task : Update transfer option.
DB: DBTXN/CustDB
Original: 

Revisions:
	- 20090818@Phuc: check page access and check upline closed first(call Age_CustSubCheckPageAccess)
	- 20090828@HuyNguyen: replace [Customer] --> [OtherCust]		
    - 20090402@Phuc: write log into DBLog.
    - 20091008@Kiwi: Remove WriteLog_UserLog
    - 20100413@Kiwi: Move to Update transferoption to CustSuper/CustMaster/CustAgent
    - 20101021@Henry: Record execution time
    - 20110603@Amy: Write log Old value
	- 20110907@Lukas: Change linked-server from DB052 -> DB053
	- 20130208@Elodie: Change link server DB03 to DBPOLICY, DB053 to DBAGE
					   Write more log on DBTXN server in case of DBLOG server failure
	- 20150610@Kathy: Migrate custDB to new server DBCust (Move Acc_CustomerSelCheckEnable to DBCUST.CustDB, Change Age_CustomerSelCheckBelonging -> Age_CustomerSelCheckBelongingByCustID) [Redmine:#36216]
	- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]
						  
Param's Explanation:
*/
BEGIN
	SET NOCOUNT ON

	declare @startRun datetime
	declare @endRun datetime
	declare @duration int
	set @startRun = getdate()

	DECLARE @Old_TransferOption TINYINT

	--------------------------
	-- ***Check Downline Belonging***
	DECLARE @roleid TINYINT
	EXEC dbo.Age_CustomerSelCheckBelongingByCustID 
	@SessionCustID = @UserID, 
	@Custid = @CustId,
	@roleid = @roleid OUTPUT
	IF (@roleid = 0) RETURN
	---------------------------

	--Check permission for account site: @phuc20080213
	EXEC NAP_UserControl.dbo.Acc_Con_CheckPermission @custid=@userid,@funcname='[OtherCust]',@ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
	IF @ErrCode <> 0
	BEGIN
		IF @ReturnErrCode = 0
			RAISERROR (@ErrMsg, 16, 1)
		RETURN
	END
	--end
	--Check disable user
	EXEC dbo.Acc_CustomerSelCheckEnable @custid = @custid, @ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
	IF @ErrCode <>0 RETURN
	--end

	DECLARE @TransferOption_dec TINYINT

	SELECT @roleid = roleid FROM custinfo WITH (NOLOCK) WHERE custid = @custid
	SELECT @TransferOption_dec = dbo.F_Binary_Decimal(@TransferOption)
	/*
	--update himself:
	IF (@roleid = 4 AND @Custid >= 100)--normal super
		OR
		(@roleid = 3)--master
		OR
		(
			--(@roleid = 2 AND exists(select 1 from customer with (nolock) where custid = @custid and srecommend < 100))--agent of direct master
			--OR
			(EXISTS(SELECT 1 FROM customer WITH (NOLOCK) WHERE transferoption = 0 AND custid = (SELECT mrecommend FROM customer WITH (NOLOCK) WHERE custid = @custid))) --master of the agent is allowed to transfer all day 
		)
			UPDATE customer SET transferoption = @TransferOption_dec WHERE custid = @CustId
	*/

	--update downline: 
	IF (@roleid = 4) AND (@Custid >= 100)--normal super
	BEGIN	
		SELECT @Old_TransferOption = TransferOption FROM CustSuper WITH (nolock) WHERE custid= @custid
		
		IF @Old_TransferOption = @TransferOption_dec RETURN
		--Update Super himself
		UPDATE CustSuper WITH (ROWLOCK, UPDLOCK) SET TransferOption = @TransferOption_dec
		WHERE custid = @custid
		
		--Update Master Level
		UPDATE CustMaster WITH (ROWLOCK, UPDLOCK) SET TransferOption = @TransferOption_dec
		WHERE custid IN (SELECT custid FROM custinfo (NOLOCK) WHERE srecommend = @custid AND roleid = 3)

		--Update Agent Level
		UPDATE CustAgent WITH (ROWLOCK, UPDLOCK) SET TransferOption = @TransferOption_dec
		WHERE custid IN (SELECT custid FROM custinfo (NOLOCK) WHERE srecommend = @custid AND roleid = 2)		
	END
	ELSE IF (@roleid = 3) --master
	BEGIN
		select @Old_TransferOption = TransferOption from CustMaster with (nolock) where custid= @custid
		
		IF @Old_TransferOption = @TransferOption_dec RETURN

		--Update Master himself
		UPDATE CustMaster WITH (ROWLOCK, UPDLOCK) SET TransferOption = @TransferOption_dec
		WHERE custid = @custid

		--Update Agent Level
		UPDATE CustAgent WITH (ROWLOCK, UPDLOCK) SET TransferOption = @TransferOption_dec
		WHERE custid IN (SELECT custid FROM custinfo (NOLOCK) WHERE mrecommend = @custid AND roleid = 2)		
	END
	-- master of the agent is allowed to transfer all day 
	ELSE IF (EXISTS(SELECT 1 FROM CustMaster WITH (NOLOCK) WHERE TransferOption = 0 AND custid = (SELECT mrecommend FROM custinfo WITH (NOLOCK) WHERE custid = @custid)))
	BEGIN
		select @Old_TransferOption = TransferOption from CustAgent with (nolock) where custid= @custid
		
		IF @Old_TransferOption = @TransferOption_dec RETURN

		UPDATE CustAgent WITH (ROWLOCK, UPDLOCK) SET TransferOption = @TransferOption_dec
		WHERE custid = @custid
	END

	DECLARE @LogSPData varchar(3000)
	DECLARE @TrackingValue2 varchar(3000)

	Select @LogSPData = '<Acc_CustomerUpdTransferOption CustId="'+ coalesce(cast(@CustId as varchar(50)),space(1)) + '" '+
						'TransferOption="'+ coalesce(cast(@TransferOption as varchar(8)),space(1))+'" '+
						'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" '+
						'IP="'+ coalesce(cast(@IP as varchar(15)),space(1)) + '" '+
						'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),space(1)) + '" '+
						'Language="'+ coalesce(cast(@Language as varchar(2)),space(1))+'" '+
						'ReturnErrCode="'+ coalesce(cast(@ReturnErrCode as varchar(50)),space(1)) + '" '+
						'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" '+
						'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(400)),space(1))+'" />'
						
	Select @TrackingValue2 = '<Acc_CustomerUpdTransferOption CustId="'+ coalesce(cast(@CustId as varchar(50)),space(1)) + '" '+
						'TransferOption="'+ coalesce(cast(dbo.F_Decimal_Binary(@Old_TransferOption) as varchar(8)),space(1))+'" '+
						'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" '+
						'IP="'+ coalesce(cast(@IP as varchar(15)),space(1)) + '" '+
						'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),space(1)) + '" '+
						'Language="'+ coalesce(cast(@Language as varchar(2)),space(1))+'" '+
						'ReturnErrCode="'+ coalesce(cast(@ReturnErrCode as varchar(50)),space(1)) + '" '+
						'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" '+
						'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(400)),space(1))+'" />'

	set @endRun = getdate()
	set @duration  = datediff (millisecond,@startRun,@endRun)

	/*700 Acc_CustomerUpdTransferOption Update Transfer Condition */
	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
			@UserID = @UserID,
			@CustID = @CustID,
			@ActionID = 700,
			@TrackingValue = @LogSPData,
			@TrackingValue2 = @TrackingValue2,
			@duration = @duration
	END TRY
	BEGIN CATCH
		Select @LogSPData = '<Acc_CustomerUpdTransferOption CustId="'+ coalesce(cast(@CustId as varchar(50)),space(1)) + '" '+
						'TransferOption="'+ coalesce(cast(@TransferOption as varchar(8)),space(1))+'" '+
						'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" '+
						'IP="'+ coalesce(cast(@IP as varchar(15)),space(1)) + '" '+
						'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),space(1)) + '" '+
						'Language="'+ coalesce(cast(@Language as varchar(2)),space(1))+'" '+
						'ReturnErrCode="'+ coalesce(cast(@ReturnErrCode as varchar(50)),space(1)) + '" '+
						'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" '+
						'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(400)),space(1))+ ' ' + error_message() + '" />'
						
	Select @TrackingValue2 = '<Acc_CustomerUpdTransferOption CustId="'+ coalesce(cast(@CustId as varchar(50)),space(1)) + '" '+
						'TransferOption="'+ coalesce(cast(dbo.F_Decimal_Binary(@Old_TransferOption) as varchar(8)),space(1))+'" '+
						'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" '+
						'IP="'+ coalesce(cast(@IP as varchar(15)),space(1)) + '" '+
						'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),space(1)) + '" '+
						'Language="'+ coalesce(cast(@Language as varchar(2)),space(1))+'" '+
						'ReturnErrCode="'+ coalesce(cast(@ReturnErrCode as varchar(50)),space(1)) + '" '+
						'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" '+
						'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(400)),space(1))+ ' ' + error_message() + '" />'
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
			@UserID = @UserID,
			@CustID = @CustID,
			@ActionID = 700,
			@TrackingValue = @LogSPData,
			@TrackingValue2 = @TrackingValue2,
			@duration = @duration
	END CATCH
END
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdTransferOption] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdTransferOption] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdTransferOption] TO [bodbExtAccNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdTransferOption] TO [vnteam] AS [dbo]