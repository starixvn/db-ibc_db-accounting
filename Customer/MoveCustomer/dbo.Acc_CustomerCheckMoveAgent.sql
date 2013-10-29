
ALTER PROCEDURE [dbo].[Acc_CustomerUpdMoveAgent]
	@mastername		varchar(40),
	@agentname		varchar(40),
	@userid			int,
	@IP				varchar(15)='',
	@ErrCode		int = 0 OUTPUT,
	@ErrMsg			nvarchar(200) = '' OUTPUT
AS
/*
Created: 
Task : Move a agent to another master
DB: DBTXN/bodb02
Original:

Revisions:
    - 20090525@Daniel: add check contraints for Horse & Finance
	- 20090528@Daniel: remove check groupe, groupf when checking commission
	- 20090716@Jamie: check auto master pt 
	- 20090828@HuyNguyen: replace [Customer] --> [OtherCust]		
	- 20090917@Phuc: Write log to dblog	
	- 20090923@Shifu: Remove checking synchronized casino constraint
	- 20090924@Jamie:  Not allowing moving master see if the total tickets under master exceed 20000
	- 20091008@Kiwi: Remove WriteLog_UserLog
	- 20091102@Kiwi: Remove RaisError and change to check total tickets from db02 to db052
	- 20091104@Jamie: Remove the input param @update 
	- 20091107@Daniel: use @temp table to cache custids for updating.
	- 20091110@Daniel: Add check internal contraint
	- 20091112@Jamie: Check DisableOutright before moving
	- 200911224@Kiwi: Use loop to update in case number of tickets is huge
	- 20091205@Kiwi: Move custsetting & custoverride to the separated tables (CustSetting3rd & CustOverride3rd).
	- 20091222@Kiwi: Apply Execution Replication (use dbo.Acc_ExecRep_00)
	- 20100114@Kiwi: Change the way to check allowed Auto Master PT and Call Acc_ExecRep_00 two times to update coming bets that not replicated to subcriptions servers yet.
	- 20100115@Jamie: Remove checking syncCasino and add the constrainst for checking syncCasino between Master and Agent 
	- 20100205@Jamie: Update the Casino status of Agent when master disabled 
	- 20100208@Lewin: Change LogSP data format
	- 20100512@Henry: Check DisableOpenTote before moving
	- 20100911@Henry: Check Number Game + Bingo before moving
	- 20101019@Henry: Record execution time
	- 20110318@Johnson: check for Greyhound and Harness
	- 20110413@Lukas: check closed/suspended
	- 20110801@Johnson: - remove bettype dead ball over/under of number game
						- add more bettype for nubmer game Warrior,  Next combo and Number Group
	- 20111019@Tom:Add check P2P Game: Status, game setting, commission.
	- 20120322@Johnson: - separate checking and moving account
						- move setting Live casino
	- 20120821@Dan: add virtual soccer, remove FI
	- 20121002@Johnson: Check double comm losing status
	- 20130218@Dan: Change linked server DB03 to DBPOLICY, DB053 to DBAGE; Write more log on DBTXN server in case of DBLOG server failure
	- 20130307@Elodie: Add Virtual HR
	- 20131029@Lukas: Apply execRep
Param's Explanation:
• @ErrCode:
    = 0: Transaction recorded successfully.
    > 0: Specific Error.
    Max errorcode: 142
• @ErrMsg: Error description.
*/

BEGIN
SET NOCOUNT ON

declare @startRun datetime
declare @endRun datetime
declare @duration int
set @startRun = getdate()

--Check permission for account site: @phuc20080213
EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[OtherCust]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
If @ErrCode <> 0
	RETURN
--end
	
declare	@srecommend			int, 
			@mrecommend			int, 
			@recommend			int,
			@srecommend_old		int, 
			@mrecommend_old		int,
			@mDisableOutright	BIT,
			@aDisableOutright	BIT,
			@mDisableCasino		BIT,
			@aDisableCasino		BIT,
			@mDisableLiveCasino BIT,
			@aDisableLiveCasino BIT,
			@mDoubleCommLosing	BIT,
			@aDoubleCommLosing	BIT,			
			@aSuspended			BIT,	
			@mSuspended			BIT,
			@aMaxTransferP2P	MONEY,
			@mMaxTransferP2P	MONEY,
			@aIsAutoResetP2P	BIT,
			@mIsAutoResetP2P	BIT,
			@aDisableP2P		BIT, 
			@mDisableP2P		BIT, 
			@aDisableFunP2P		BIT,
			@mDisableFunP2P		BIT,
			@aDisableVirtualSports		BIT,
			@mDisableVirtualSports		BIT			

	select	@srecommend			= srecommend, 
			@mrecommend			= custid, 
			@mDisableOutright	= DisableOutright,			
			@mDisableCasino		= disableCasino,
			@mDisableLiveCasino = DisableLivecasino, 
			@mDoubleCommLosing	= DoubleCommLosing,			
			@mSuspended			= reject,
			@mMaxTransferP2P	= MaxTransferP2P, 
			@mIsAutoResetP2P	= IsAutoResetP2P, 
			@mDisableP2P		= DisableP2P, 
			@mDisableFunP2P		= DisableFunP2P,
			@mDisableVirtualSports = DisableVirtualSports 
	from	custinfo with (nolock) 
	where	username = @mastername and roleid = 3

	select	@recommend			= custid, 
			@srecommend_old		= srecommend, 
			@mrecommend_old		= mrecommend, 			
			@aDisableOutright	= DisableOutright,			
			@aDisableCasino		= disableCasino,
			@aDisableLiveCasino = DisableLiveCasino,	
			@aDoubleCommLosing	= DoubleCommLosing,		
			@aSuspended			= reject,
			@aMaxTransferP2P	= MaxTransferP2P, 
			@aIsAutoResetP2P	= IsAutoResetP2P, 
			@aDisableP2P		= DisableP2P, 
			@aDisableFunP2P		= DisableFunP2P,
			@aDisableVirtualSports = DisableVirtualSports  		
	from	custinfo with (NOLOCK) 
	where	username = @agentname and roleid = 2
	
EXEC DBAGE.bodb02.dbo.Acc_CustomerCheckMoveAgent @mastername = @mastername, @agentname = @agentname,@userid = @userid, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT

IF @ErrCode > 0
	RETURN
	
--Declare @temp table to contain customer info before update.
DECLARE @CustInfo TABLE (CustID INT)

INSERT INTO @CustInfo
SELECT custid FROM custinfo (NOLOCK)
WHERE recommend = @recommend

--P2PGAMESETTING table
UPDATE G_P
SET stakelevel1 = CASE WHEN M.stakelevel1 = 1 AND G_P.stakelevel1 = 1 THEN 1 ELSE 0 END,
	stakelevel2 = CASE WHEN M.stakelevel2 = 1 AND G_P.stakelevel2 = 1 THEN 1 ELSE 0 END,
	stakelevel3 = CASE WHEN M.stakelevel3 = 1 AND G_P.stakelevel3 = 1 THEN 1 ELSE 0 END,
	stakelevel4 = CASE WHEN M.stakelevel4 = 1 AND G_P.stakelevel4 = 1 THEN 1 ELSE 0 END,
	stakelevel5 = CASE WHEN M.stakelevel5 = 1 AND G_P.stakelevel5 = 1 THEN 1 ELSE 0 END
FROM P2PGameSetting G_P WITH (ROWLOCK, UPDLOCK)
	INNER JOIN 
		( SELECT * FROM dbo.P2PGameSetting m WITH(NOLOCK) WHERE custid = @mrecommend) m
			ON G_P.BETTYPE = M.BETTYPE
WHERE G_P.custid IN (SELECT custid FROM @CustInfo)

IF @@ERROR <> 0 
	BEGIN	
		SELECT	@ErrMsg = 'Error master ' + @Mastername + ', agent ' + @agentname + ': update unsuccessfully (P2PGameSetting).',
				@ErrCode = 300
		RETURN
	END

IF exists (
	SELECT TOP 1 1 FROM 
	(SELECT * FROM dbo.P2PGameSetting a WITH(NOLOCK) WHERE a.custid = @recommend)  a
	INNER JOIN
		(SELECT * FROM dbo.P2PGameSetting m WITH(NOLOCK) WHERE m.custid = @mrecommend)   m
				ON a.BETTYPE = m.BETTYPE
	WHERE (a.stakelevel2 = 0 AND a.stakelevel3 = 0 AND a.stakelevel4 = 0 AND a.stakelevel5 = 0 )
	AND (m.stakelevel2 = 1 OR m.stakelevel3 = 1 OR m.stakelevel4 = 1 OR m.stakelevel5 = 1 )
)
BEGIN
	UPDATE G_P
	SET stakelevel1 = CASE WHEN M.stakelevel1 = 1 THEN 1 ELSE 0 END,
		stakelevel2 = CASE WHEN M.stakelevel2 = 1 THEN 1 ELSE 0 END,
		stakelevel3 = CASE WHEN M.stakelevel2 = 0 AND M.stakelevel3 = 1 THEN 1 ELSE 0 END,
		stakelevel4 = CASE WHEN M.stakelevel2 = 0 AND M.stakelevel3 = 0 AND M.stakelevel4 = 1 THEN 1 ELSE 0 END,
		stakelevel5 = CASE WHEN M.stakelevel2 = 0 AND M.stakelevel3 = 0 AND M.stakelevel4 = 0 AND M.stakelevel5 = 1 THEN 1 ELSE 0 END
	FROM P2PGameSetting G_P WITH (ROWLOCK, UPDLOCK)
		INNER JOIN 
			( SELECT * FROM dbo.P2PGameSetting m WITH(NOLOCK) WHERE custid = @mrecommend) m
				ON G_P.BETTYPE = M.BETTYPE
	WHERE G_P.custid = @recommend AND G_P.stakelevel2 = 0 AND G_P.stakelevel3 = 0 AND G_P.stakelevel4 = 0 AND G_P.stakelevel5 = 0
	
	IF @@ERROR <> 0 
	BEGIN		
			SELECT	@ErrMsg = 'Error master ' + @Mastername + ', agent ' + @agentname + ': update unsuccessfully (P2PGameSetting).',
					@ErrCode = 301
		RETURN
	END	
END

--P2PGroupComm table
UPDATE G_C 
SET sdiscount = M.sdiscount,
	adiscount  =M.adiscount
FROM P2PGroupComm G_C WITH (ROWLOCK, UPDLOCK)
	INNER JOIN 
		( SELECT * FROM dbo.P2PGROUPCOMM m WITH(NOLOCK) WHERE custid = @mrecommend) m
		ON G_C.GroupID = M.GroupID
WHERE G_C.custid IN (SELECT custid FROM @CustInfo)

IF @@ERROR <> 0 
BEGIN	
	SELECT	@ErrMsg = 'Error master ' + @Mastername + ', agent ' + @agentname + ': update unsuccessfully (P2PGroupComm).',
			@ErrCode = 302
	RETURN
END

if (@mDisableP2P = 1 and @aDisableP2P = 0) 
	OR (@mIsAutoResetP2P = 0 and @aIsAutoResetP2P = 1)
	OR (@mDisableFunP2P = 1 and @aDisableFunP2P = 0)
	OR (@mMaxTransferP2P < @aMaxTransferP2P)
	OR (@mDoubleCommLosing = 0 and @aDoubleCommLosing = 1)
BEGIN
	UPDATE	Custinfo WITH (UPDLOCK,ROWLOCK)
	SET		DisableP2P = CASE WHEN @mDisableP2P = 1 THEN 1 ELSE DisableP2P END,
			DisableFunP2P = CASE WHEN @mDisableFunP2P = 1 THEN 1 ELSE DisableFunP2P END,
			IsAutoResetP2P = CASE WHEN @mIsAutoResetP2P = 0 THEN 0 ELSE IsAutoResetP2P END,
			MaxTransferP2P = CASE WHEN @mMaxTransferP2P < MaxTransferP2P THEN @mMaxTransferP2P ELSE MaxTransferP2P END,
			DoubleCommLosing = CASE WHEN @mDoubleCommLosing = 0 THEN 0 ELSE DoubleCommLosing END
	WHERE	custid IN(SELECT CustID FROM @CustInfo)
	IF @@ERROR <>0
	BEGIN
		Select	@ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': update unsuccessfully (custinfo).',
				@ErrCode = 303
		RETURN 
	END
END

--customer table
update customer with (ROWLOCK, UPDLOCK) set srecommend = @srecommend, mrecommend = @mrecommend 
where custid IN(SELECT CustID FROM @CustInfo)
if @@Error <> 0 
BEGIN
    --ROLLBACK TRANSACTION MANUALLY
	update customer with (ROWLOCK, UPDLOCK) set srecommend = @srecommend_old, mrecommend = @mrecommend_old
	where custid IN(SELECT CustID FROM @CustInfo)
	
	Select @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': update unsuccessfully (customer).',
		@ErrCode = 304					 
	return
END

--custinfo table
update custinfo with (ROWLOCK, UPDLOCK) 
set srecommend = @srecommend, 
	mrecommend = @mrecommend 
where  custid IN(SELECT CustID FROM @CustInfo)
if @@Error <> 0 
BEGIN
    --ROLLBACK TRANSACTION MANUALLY
	update customer with (ROWLOCK, UPDLOCK) set srecommend = @srecommend_old, mrecommend = @mrecommend_old
	where  custid IN(SELECT CustID FROM @CustInfo)
	
	update custinfo with (ROWLOCK, UPDLOCK) set srecommend = @srecommend_old, mrecommend = @mrecommend_old
	where  custid IN(SELECT CustID FROM @CustInfo)
	
	Select @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': update unsuccessfully (custinfo).',
		@ErrCode = 305				 	
	return
END

--- update suspended status
IF @mSuspended = 1 AND @aSuspended = 0
BEGIN
	UPDATE Custinfo WITH (UPDLOCK, ROWLOCK)
	SET	reject = 1 
	WHERE	custid IN(SELECT CustID FROM @CustInfo)
	IF @@ERROR <>0
	BEGIN
		SELECT	@ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': update unsuccessfully (custinfo).',
				@ErrCode = 306
		RETURN
	END
END

IF @mDisableOutright = 1 AND (@mDisableOutright <> @aDisableOutright ) 
BEGIN
	UPDATE Custinfo WITH (UPDLOCK, ROWLOCK)
	SET	DisableOutright = 1 
	WHERE	custid IN(SELECT CustID FROM @CustInfo)
	IF @@ERROR <>0
	BEGIN
		Select	@ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': update unsuccessfully (custinfo).',
				@ErrCode = 307
		RETURN 
	END
END 

IF @mDisableCasino = 1 AND (@mDisableCasino <> @aDisableCasino)
BEGIN
	UPDATE	Custinfo WITH (UPDLOCK,ROWLOCK)
	SET		DisableCasino = 1 
	WHERE	custid IN(SELECT CustID FROM @CustInfo)
	IF @@ERROR <>0
	BEGIN
		Select	@ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': update unsuccessfully (custinfo).',
				@ErrCode = 308
		RETURN 
	END
END

IF @mDisableLiveCasino = 1 AND @mDisableLiveCasino <> @aDisableLiveCasino
BEGIN
	UPDATE CustInfo WITH(UPDLOCK,ROWLOCK)
	SET DisableLiveCasino = 1
	WHERE custid IN (SELECT custid FROM @CustInfo)
	
	IF @@ERROR <> 0
	BEGIN
		Select	@ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': update unsuccessfully (custinfo).',
				@ErrCode = 309
		RETURN 
	END
END

-- VS
IF @mDisableVirtualSports = 1 AND (@mDisableVirtualSports <> @aDisableVirtualSports)
BEGIN
	UPDATE	Custinfo WITH (UPDLOCK,ROWLOCK)
	SET		DisableVirtualSports = 1 
	WHERE	custid IN(SELECT CustID FROM @CustInfo)
	IF @@ERROR <>0
	BEGIN
		Select	@ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': update unsuccessfully (custinfo).',
				@ErrCode = 310
		RETURN 
	END
END

/*
IF @mDisableBingo = 1 AND (@mDisableBingo <> @aDisableBingo)
BEGIN
	UPDATE	Custinfo WITH (UPDLOCK,ROWLOCK)
	SET		DisableBingo = 1 
	WHERE	custid IN(SELECT CustID FROM @CustInfo)
	IF @@ERROR <>0
		Select	@ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': update unsuccessfully (custinfo).',
				@ErrCode = 138
	RETURN 
END
IF @mDisableNumber = 1 AND (@mDisableNumber <> @aDisableNumber)
BEGIN
	UPDATE	Custinfo WITH (UPDLOCK,ROWLOCK)
	SET		DisableNumber = 1 
	WHERE	custid IN(SELECT CustID FROM @CustInfo)
	IF @@ERROR <>0
		Select	@ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': update unsuccessfully (custinfo).',
				@ErrCode = 139
	RETURN 
END
*/

--Apply ExeReplication
-- call Acc_ExecRep_00 two times to update coming bets that not replicated to subcriptions servers yet.
EXEC dbo.Acc_ExecRep_00 
	@custid = 0,
	@recommend = @recommend,
	@recommend_old = 0,
	@mrecommend = @mrecommend,
	@mrecommend_old = @mrecommend_old,
	@srecommend = @srecommend,
	@srecommend_old = @srecommend_old,
	@roleid = 2,
	@ErrCode = @ErrCode OUTPUT,
	@ErrMsg = @ErrMsg OUTPUT
IF @ErrCode <> 0 RETURN 

EXEC dbo.Acc_ExecRep_00 
	@custid = 0,
	@recommend = @recommend,
	@recommend_old = 0,
	@mrecommend = @mrecommend,
	@mrecommend_old = @mrecommend_old,
	@srecommend = @srecommend,
	@srecommend_old = @srecommend_old,
	@roleid = 2,
	@ErrCode = @ErrCode OUTPUT,
	@ErrMsg = @ErrMsg OUTPUT
IF @ErrCode <> 0 RETURN


--when separate code we must use EXEC Acc_CustomerUpdAgent_MinMaxPositiontaking @recommend = @recommend, @mrecommend = @mrecommend, @srecommend = @srecommend
--Check & update n4<=s1+m1+a1<=l4
--EXEC dbo.Acc_CustomerUpdAgent_MinMaxPositiontaking @recommend = @recommend, @mrecommend = @mrecommend, @srecommend = @srecommend
EXEC dbo.Acc_CustSetting_04 @recommend = @recommend, @mrecommend = @mrecommend, @srecommend = @srecommend, @roleid = 2
EXEC dbo.Acc_CustSetting3rd_04 @recommend = @recommend, @mrecommend = @mrecommend, @srecommend = @srecommend, @roleid = 2, @mode = 'number'
	
EXEC dbo.Acc_CustomerUpdAgentHR_MinMaxPositiontaking @recommend = @recommend, @mrecommend = @mrecommend, @srecommend = @srecommend
EXEC dbo.Acc_CustomerUpdAgentLiveCS_MaxPositiontaking @recommend = @recommend
EXEC dbo.Acc_CustomerUpdAgentVS_MinMaxPositiontaking  @sporttype=180, @bettype = 1201, @recommend = @recommend, @mrecommend = @mrecommend, @srecommend = @srecommend
EXEC dbo.Acc_CustomerUpdAgentVS_MinMaxPositiontaking  @sporttype=181, @bettype = 1231, @recommend = @recommend, @mrecommend = @mrecommend, @srecommend = @srecommend
EXEC dbo.Acc_CustomerUpdAgentVS_MinMaxPositiontaking  @sporttype=186, @bettype = 1220, @recommend = @recommend, @mrecommend = @mrecommend, @srecommend = @srecommend

update custsetting with (ROWLOCK, UPDLOCK) set sdiscount=discount 
where custid in (select custid from customer with (NOLOCK) where recommend = @recommend and roleid=1) and isnull(sdiscount, 0) < discount

update custsetting with (ROWLOCK, UPDLOCK) set adiscount=discount 
where custid in (select custid from customer with (NOLOCK) where recommend = @recommend and roleid=1) and isnull(adiscount, 0) < discount

--correct commission for 3rd party
update custsetting3rd with (ROWLOCK, UPDLOCK) set sdiscount=discount 
where custid in (select custid from customer with (NOLOCK) where recommend = @recommend and roleid=1) and isnull(sdiscount, 0) < discount

update custsetting3rd with (ROWLOCK, UPDLOCK) set adiscount=discount 
where custid in (select custid from customer with (NOLOCK) where recommend = @recommend and roleid=1) and isnull(adiscount, 0) < discount

--correct commission for live casino
UPDATE CustSettingGame WITH(ROWLOCK,UPDLOCK) SET sdiscount = discount
WHERE custid IN (SELECT custid FROM Customer WITH(NOLOCK) WHERE recommend = @recommend AND roleid = 1) AND ISNULL(sdiscount,0) < discount

UPDATE CustSettingGame WITH(ROWLOCK,UPDLOCK) SET adiscount = discount
WHERE custid IN (SELECT custid FROM Customer WITH(NOLOCK) WHERE recommend = @recommend AND roleid = 1) AND ISNULL(adiscount,0) < discount

declare @LogSPData varchar(8000)

SELECT  @LogSPData = '<Acc_CustomerUpdMoveAgent AgentName="' + @agentname + 
					'" OldMasterId="' + CONVERT(VARCHAR(20), @mrecommend_old) + 
					'" NewMasterName="' + @mastername + 
					'" NewMasterId="' + CONVERT(VARCHAR(20), @mrecommend) + 
					'" Userid="' + COALESCE(CAST(@userid AS VARCHAR(50)), SPACE(1)) + 
					'" IP="' + @IP + '" />'

set @endRun = getdate()
set @duration  = datediff (millisecond,@startRun,@endRun)

BEGIN TRY
	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		@UserID = @UserID,
		@CustID = @recommend,
		@ActionID = 606, 
		@TrackingValue = @LogSPData,
		@duration = @duration
END TRY
BEGIN CATCH
	SELECT  @LogSPData = '<Acc_CustomerUpdMoveAgent AgentName="' + @agentname + 
					'" OldMasterId="' + CONVERT(VARCHAR(20), @mrecommend_old) + 
					'" NewMasterName="' + @mastername + 
					'" NewMasterId="' + CONVERT(VARCHAR(20), @mrecommend) + 
					'" Userid="' + COALESCE(CAST(@userid AS VARCHAR(50)), SPACE(1)) + 
					'" IP="' + @IP + 
					'" ErrCode="' + coalesce(cast(ERROR_NUMBER() as varchar(50)),space(1)) + 
					'" ErrMsg="' + coalesce(ERROR_MESSAGE(),space(1)) + '" />'
					
	EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		@UserID = @UserID,
		@CustID = @recommend,
		@ActionID = 606, 
		@TrackingValue = @LogSPData,
		@duration = @duration	
END CATCH		
	
END


GO
GRANT EXECUTE ON [dbo].[Acc_CustomerCheckMoveAgent] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerCheckMoveAgent] TO [vnteam] AS [dbo]