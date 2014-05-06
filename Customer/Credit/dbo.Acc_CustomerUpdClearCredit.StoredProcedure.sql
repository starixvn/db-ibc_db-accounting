ALTER PROCEDURE [dbo].[Acc_CustomerUpdClearCredit] 
	@username varchar(40),
	@userid int,
	@ReturnErrCode bit = 0,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@IP varchar(15) = '',
	@system VARCHAR(50) = ''
AS

/*	Created by: [Creator]
	DB: DBTXN/CustDB
	Task: clear credit of the specified account and all downline accounts
	Revisions:
		- 20090828@HuyNguyen: replace [Customer] --> [OtherCust]	
		- 20090915@Simon: Write Credit Log into Userlog_Credit table.	
		- 20090516@Jamie: Write the credit of all members under agency also 		
		- 20090917@Phuc: Write log to dblog	
		- 20090926@Simon: Only write log the Credit != 0.
		- 20100102@Kiwi: Modify Log.
		- 20100909@Thien: Fix for member level to count the member balance.	
		- 20121206@Scott : Check Allowed downlines during peak hour at weekend
		- 20130218@Dan: Change linked server DB03 to DBPOLICY, DB053 to DBAGE; Write more log on DBTXN server in case of DBLOG server failure
		- 20131025@Lukas: add system define permission checking when call from external accounting
		- 20131108@Elodie: Splitting bodb02 into CustDB (call bettrans by link database)
		- 20140306@Dom: add outstanding from translog
		- 20140423@Elodie: Implement SMA Turnover [Redmine:#14426]
*/

SET NOCOUNT ON

IF @system = 'EXTERNAL'
BEGIN
	--- no check permssion in case of calling from external accounting
	SET @ErrMsg = ''
END
ELSE
BEGIN
	--Check permission for account site: @phuc20080213
	EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[Credit]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
	If @ErrCode <> 0
		RETURN
	--end
END

declare @custid		int,
		@roleid		tinyint,
		@custLine	varchar(20), 
		@mrecommend INT,
		@recommend	INT
declare	@tmpCust table (custid int, Credit money)

select @custid = custid, @roleid = roleid, @mrecommend = mrecommend, @recommend = recommend from custinfo with (NOLOCK) where username = @username

if isnull(@custid,0) = 0 or isnull(@roleid, 0) > 4
BEGIN
	Select @ErrMsg = 'Error occurs. This user does not exist. Please try again!',
		@ErrCode = 101					 
	if @ReturnErrCode = 0
		RaisError (@ErrMsg, 16, 1)
	return	
END

/*--20090820@Thien: not check this function so that upline can get back the used credit
--Check disable user
		EXEC DB052.bodb02.dbo.Acc_CustomerSelCheckEnable @custid = @custid, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
	if @ErrCode <>0 return
--end
*/



--Check Allowed downlines during peak hour at weekend
EXEC DBAGE.bodb02.dbo.Acc_CustomerSelCheckAllowedDownlines	@custid=@custid,
											@roleid=@roleid,
											@isExecRep=0,
											@Language='E',
											@ErrMsg=@ErrMsg output,
											@ErrCode=@ErrCode output
IF @ErrCode <>0 RETURN
--END		

if @roleid = 4
BEGIN
	Select @custLine =' all lines of super '
	Update custinfo with (ROWLOCK, UPDLOCK) set credit = 0 
	output deleted.custid, deleted.Credit into @tmpCust(custid, Credit)
	where srecommend = @custid AND Credit != 0  

	IF NOT EXISTS (SELECT 1 FROM DBACC.bodb_Acc.dbo.Acc_CustDirect WITH (NOLOCK) WHERE custid = @custid) --real super
	BEGIN
		IF EXISTS (SELECT 1 
					FROM DBAGE.bodb02.dbo.DownlineTurnOver_Setting s WITH (NOLOCK) 
						INNER JOIN bodb02.dbo.match m WITH (NOLOCK) ON s.matchid = m.matchid
					WHERE SMAID = @custid AND eventstatus <> 'completed')
			EXEC DBAGE.bodb02.dbo.NAP_SMATurnover_MaxTurnoverUpd @UpdMode = 17, @SMAID = @custid
	END
	ELSE --dummy super
	BEGIN
		IF EXISTS (SELECT 1 
					FROM DBAGE.bodb02.dbo.DownlineTurnOver_Setting s WITH (NOLOCK) 
						INNER JOIN bodb02.dbo.match m WITH (NOLOCK) ON s.matchid = m.matchid
					WHERE SMAID = @mrecommend AND eventstatus <> 'completed')
			EXEC DBAGE.bodb02.dbo.NAP_SMATurnover_MaxTurnoverUpd @UpdMode = 17, @SMAID = @mrecommend
	END
END
else if @roleid = 3
BEGIN
	Select @custLine =' all lines of master '
	Update custinfo with (ROWLOCK, UPDLOCK) set credit = 0 
	output deleted.custid, deleted.Credit into @tmpCust(custid, Credit)
	where mrecommend = @custid AND Credit != 0 

	IF EXISTS (SELECT 1 FROM DBACC.bodb_Acc.dbo.Acc_CustDirect WITH (NOLOCK) WHERE custid = @custid) --dummy master
	BEGIN
		IF EXISTS (SELECT 1 
					FROM DBAGE.bodb02.dbo.DownlineTurnOver_Setting s WITH (NOLOCK) 
						INNER JOIN bodb02.dbo.match m WITH (NOLOCK) ON s.matchid = m.matchid
					WHERE SMAID = @recommend AND eventstatus <> 'completed')
			EXEC DBAGE.bodb02.dbo.NAP_SMATurnover_MaxTurnoverUpd @UpdMode = 17, @SMAID = @recommend
	END

END
else if @roleid = 2
BEGIN
	Select @custLine =' all lines of agent '
	Update custinfo with (ROWLOCK, UPDLOCK) set credit = 0 
	output deleted.custid, deleted.Credit into @tmpCust(custid, Credit)
	where recommend = @custid AND Credit != 0 
END
else if @roleid = 1
BEGIN
	Select @custLine =' member '
	
	DECLARE @TotalAmt money
	
	select  @TotalAmt = sum(winlost-actual_stake+playercomm)
    from bodb02.dbo.bettrans with (nolock)
    where custid = @CustID
    
    select @TotalAmt = isnull(@TotalAmt, 0)
	SELECT  @TotalAmt = @TotalAmt + ISNULL(SUM(-actual_stake), 0) FROM bodb02.dbo.translog WITH(NOLOCK) WHERE custid=@custid AND statusID=0
		
	Update custinfo with (ROWLOCK, UPDLOCK) 
	set credit = case when @TotalAmt >= 0 then 0 else abs(@TotalAmt) end
	output deleted.custid, deleted.Credit into @tmpCust(custid, Credit)
	where custid = @custid AND Credit != 0 
END

-- Write Log Credit
Declare @LogSPCredit varchar(500)
Select @LogSPCredit = 'Clear credit of' + @custLine + ': '+ @username 

BEGIN TRY
	INSERT INTO DBLOG.bodb_CustomerLog.dbo.userlog_Credit(userid, custid, OldValue, NewValue, ip, doing, ActionID)
	SELECT	@UserID, custid, Credit, 0, @ip, @LogSPCredit, 1201 
	FROM	@tmpCust 
END TRY
BEGIN CATCH
	Select @LogSPCredit = @LogSPCredit + ' ErrMsg=' + error_message()
	
	INSERT INTO bodb_CustomerLog.dbo.userlog_Credit(userid, custid, OldValue, NewValue, ip, doing, ActionID)
	SELECT	@UserID, custid, Credit, 0, @ip, @LogSPCredit, 1201 
	FROM	@tmpCust
END CATCH


GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdClearCredit] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdClearCredit] TO [bodbExtAccNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdClearCredit] TO [vnteam]  