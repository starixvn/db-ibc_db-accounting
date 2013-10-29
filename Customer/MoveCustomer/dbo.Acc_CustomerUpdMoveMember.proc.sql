ALTER PROCEDURE [dbo].[Acc_CustomerUpdMoveMember]
	@agentname varchar(40),
	@membername varchar(40),
	@userid int,
	@IP	VARCHAR(15)='',	
	@ReturnErrCode bit = 0,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
/*
Created: 
Task : Move a member to another agent
DB: DBTXN/bodb02
Original:

Revisions:
    - 20080213@Tommy: Check permission for account site
	- 20090525@Daniel: add check contraints for Horse & Finance
	- 20090528@Daniel: Fix check commission for all sports
	- 20090716@Jamie: Check auto master PT on agent 
	- 20090828@HuyNguyen: replace [Customer] --> [OtherCust]
	- 20090917@Phuc: Write log to dblog	
	- 20091008@Kiwi: Remove WriteLog_UserLog
	- 20091112@Jamie: Check DisableOutright before moving
	- 200911224@Kiwi: Use loop to update in case number of tickets is huge
	- 20091214@Jamie: Correct member's commission
	- 20091216@Jamie: Separate 3rd Party to CustSetting3rd 
	- 20091222@Kiwi: Apply Execution Replication (dbo.Acc_ExecRep_00)
	- 20100114@Kiwi: Call Acc_ExecRep_00 two times to update coming bets that not replicated to subcriptions servers yet.
	- 20100205@Jamie: Update the CS status of Member when Agent disabled
	- 20100209@Lewin: Change sp format
	- 20100512@Henry: Check DisableOpenTote before moving
	- 20100911@Henry: Check Number Game + Bingo before moving
	- 20101019@Henry: Record execution time
	- 20110317@Johnson: check for Greyhound and Harness
	- 20110413@Lukas: check closed/suspended
	- 20110801@Johnson: - remove bettype dead ball over/under of number game
						- add more bettype for nubmer game Warrior,  Next combo and Number Group
	- 20110907@Sophia: Change Linked Server from DB052 to DB053	
	- 20110930@Johnson: Add more groups under Won currency.
	- 20111020@Tom:Add check P2P Game: Status, game setting, commission.
	- 20120322@Johnson: Check live casino
	- 20120821@Dan: add virtual soccer, remove FI
	- 20120928@Johnson: check double comm losing status 
	- 20130218@Dan: Change linked server DB03 to DBPOLICY, DB053 to DBAGE; Write more log on DBTXN server in case of DBLOG server failure
	- 20130307@Elodie: Add Virtual HR
	- 20130920@Elodie: Add constraint to avoid the insufficient Given Credit of any new super/master/agent being moving to.
	- 20131022@Elodie: Remove checking setting for Financial and Poker products [Redmine:#6480]
	
Param's Explanation:
• @ErrCode:
    = 0: Transaction recorded successfully.
    > 0: Specific Error. 
	Max errorcode:	133
• @ErrMsg: Error description.
Note: Check Disable status between Agent and Member 
*/
SET NOCOUNT ON

declare @startRun datetime
declare @endRun datetime
declare @duration int
set @startRun = getdate()

EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[OtherCust]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
If @ErrCode <> 0
	RETURN
--end

declare @srecommend				int, 
		@mrecommend				int, 
		@recommend				int, 
		@acurrency				tinyint,
		--==Member Info ==--
		@srecommend_old 		int, 
		@mrecommend_old 		int, 
		@recommend_old			int, 
		@currency_old			tinyint,
		@custid					int, 
		--== Enable/Disable HR  ==--- 
		@adisable151_31			bit,-- @adisableHR -> @adisable151_31 
		@disable151_31			bit,-- @disableHR -> @disable151_31 				
		@aDisableOutright		bit,
		@DisableOutright		bit,
		@aSyncCasino			bit,
		@SyncCasino				bit,
		@aSyncLiveCasino		bit,
		@SyncLiveCasino 		bit,
		@aSyncBingo				bit,
		@SyncBingo				bit,
		@aDisable151_41			BIT,-- @aDisableOpenTote -> @aDisable151_41
		@Disable151_41			BIT,-- @Disable151_41 -> @Disable151_41
		@aDisable151_51			BIT,
		@Disable151_51			BIT,
		@aDisable152_41			BIT,
		@Disable152_41			BIT,
		@aDisable152_51			BIT,
		@Disable152_51			BIT,
		@aDisable153_51			BIT,
		@Disable153_51			BIT,
		@aDisableBingo			BIT,
		@DisableBingo			BIT,
		@aDisableNumber			BIT,
		@DisableNumber			BIT,
		@aClosed				BIT,
		@Closed					BIT,
		@aSuspended				BIT,
		@Suspended				BIT,
		--@aMaxTransferP2P		MONEY,
		--@MaxTransferP2P			MONEY,
		--@aIsAutoResetP2P		BIT,
		--@IsAutoResetP2P			BIT,
		--@aDisableP2P			BIT, 
		--@DisableP2P				BIT, 
		--@aDisableFunP2P			BIT,
		--@DisableFunP2P			BIT,				
		@aHideVirtualSports 	BIT,
		@HideVirtualSports		BIT, 
		@aDisableVirtualSports	BIT, 
		@DisableVirtualSports	BIT,
		@aDoubleCommLosing		BIT,
		@DoubleCommLosing		BIT,
		@aGivenCredit			MONEY,
		@GivenCredit			MONEY,
		@aUsedCredit			MONEY
		
select	@srecommend			= srecommend, 
		@mrecommend			= mrecommend, 
		@recommend			= recommend,
		@acurrency			= currency, 
		@adisable151_31		= DisableHorseracing, 		
		@aDisableOutright	= DisableOutright,
		@aSyncCasino		= syncCasino,
		@aSyncLiveCasino	= SyncLiveCasino,
		@aSyncBingo			= syncBingo,
		@aDisable151_41		= DisableOpenTote,
		@aDisable151_51		= Disable151_AU,
		@aDisable152_41		= Disable152_UK,
		@aDisable152_51		= Disable152_AU,
		@aDisable153_51		= Disable153_AU,
		@aDisableBingo		= DisableBingo,
		@aDoubleCommLosing	= DoubleCommLosing,
		@aDisableNumber		= DisableNumber,
		@aClosed			= closed,
		@aSuspended			= reject,
		--@aMaxTransferP2P	= MaxTransferP2P, 
		--@aIsAutoResetP2P	= IsAutoResetP2P, 
		--@aDisableP2P		= DisableP2P, 
		--@aDisableFunP2P	= DisableFunP2P ,
		@aDisableVirtualSports = DisableVirtualSports,
		@aHideVirtualSports = HideVirtualSports,
		@aGivenCredit		= credit	
from	custinfo with (nolock)
where	username = @agentname and roleid = 2

select	@custid				= custid, 
		@recommend_old		= recommend, 
		@srecommend_old		= srecommend, 
		@mrecommend_old		= mrecommend,
		@currency_old		= currency,
		@disable151_31		= DisableHorseracing, 		
		@DisableOutright	= DisableOutright,
		@SyncCasino			= SyncCasino ,
		@SyncLiveCasino		= SyncLiveCasino,
		@SyncBingo			= SyncBingo ,
		@Disable151_41		= DisableOpenTote,
		@Disable151_51		= Disable151_AU,
		@Disable152_41		= Disable152_UK,
		@Disable152_51		= Disable152_AU,
		@Disable153_51		= Disable153_AU,
		@DisableBingo		= DisableBingo,
		@DisableNumber		= DisableNumber,
		@DoubleCommLosing	= DoubleCommLosing,
		@Closed				= closed,
		@Suspended			= reject,
		--@MaxTransferP2P		= MaxTransferP2P, 
		--@IsAutoResetP2P		= IsAutoResetP2P, 
		--@DisableP2P			= DisableP2P, 
		--@DisableFunP2P		= DisableFunP2P,
		@DisableVirtualSports = DisableVirtualSports ,
		@HideVirtualSports	= HideVirtualSports,
		@GivenCredit		= credit
from	custinfo with (nolock) 
where	username = @membername and roleid = 1

-- 20130920@Elodie: Add constraint to avoid the insufficient Given Credit of any new super/master/agent being moving to.
SELECT @aUsedCredit = sum(credit) FROM custinfo WITH(NOLOCK) WHERE roleid = 1 AND recommend = @recommend
IF ISNULL(@aGivenCredit,0) - ISNULL(@aUsedCredit,0) < ISNULL(@GivenCredit,0)
BEGIN
	Select @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': New agent credit is insufficient to move this member.',
		@ErrCode = 100			 
	return
END

if isnull(@recommend, 0) = 0
BEGIN
	Select @ErrMsg = 'Error agent ' + @agentname + ': agent not found.',
		@ErrCode = 101					 
	if @ReturnErrCode = 0
		RaisError (@ErrMsg, 16, 1)
	return
END

if isnull(@recommend_old, 0) = 0
BEGIN
	Select @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': agent not found.',
		@ErrCode = 102					 
	if @ReturnErrCode = 0
		RaisError (@ErrMsg, 16, 1)
	return
END

if isnull(@recommend, 0) = @recommend_old
BEGIN
	Select @ErrMsg = 'Error occurs. The member '+ @membername +' already belongs to agent '+ @agentname +'.',
		@ErrCode = 103					 
	if @ReturnErrCode = 0
		RaisError (@ErrMsg, 16, 1)
	return
END
--check an account disabled or not 
EXEC DBAGE.bodb02.dbo.Acc_CustomerSelCheckEnable @username = @membername, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output 
if @ErrCode <>0		return 

EXEC DBAGE.bodb02.dbo.Acc_CustomerSelCheckEnable @username = @agentname, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output 
if @ErrCode <>0		return 

if @currency_old <> @acurrency
BEGIN
	Select @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': currency of new agent and member does not match.',
		@ErrCode = 104					 
	if @ReturnErrCode = 0
		RaisError (@ErrMsg, 16, 1)
	return
END

----------------------------------
-- check is closed
IF @aClosed = 1
BEGIN
	SELECT @ErrMsg = 'Error occurs. Cannot move to closed agent.',
		@ErrCode = 105
	RETURN
END

--Check Horse  enable status:
if @adisable151_31 = 1 and @disable151_31 = 0
BEGIN
	Select @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': member is enabled SA Racing but new agent is not enabled SA Racing.',
		@ErrCode = 106					 
	if @ReturnErrCode = 0
		RaisError (@ErrMsg, 16, 1)
	return
END

--Check OpenTote
if @aDisable151_41 = 1 and @Disable151_41 = 0
BEGIN
	Select @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': member is enabled UK/IRish Racing but new agent is not enabled UK/IRish Racing.',
		@ErrCode = 107				 
	if @ReturnErrCode = 0
		RaisError (@ErrMsg, 16, 1)
	return
END

--Check Horse Racing for AU Tote
if @aDisable151_51 = 1 and @Disable151_51 = 0
BEGIN
	Select @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': member is enabled Aust Racing but new agent is not enabled Aust Racing.',
		@ErrCode = 108
	if @ReturnErrCode = 0
		RaisError (@ErrMsg, 16, 1)
	return
END

--Check Greyhound for UK Tote
if @aDisable152_41 = 1 and @Disable152_41 = 0
BEGIN
	Select @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': member is enabled UK Greyhound but new agent is not enabled UK Greyhound.',
		@ErrCode = 109				 
	if @ReturnErrCode = 0
		RaisError (@ErrMsg, 16, 1)
	return
END

--Check Greyhound for AU Tote
if @aDisable152_51 = 1 and @Disable152_51 = 0
BEGIN
	Select @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': member is enabled Aust Greyhound but new agent is not enabled Aust Greyhound.',
		@ErrCode = 110				 
	if @ReturnErrCode = 0
		RaisError (@ErrMsg, 16, 1)
	return
END

--Check Harness for AU Tote
if @aDisable153_51 = 1 and @Disable153_51 = 0
BEGIN
	Select @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': member is enabled Aust Harness but new agent is not enabled Aust Harness.',
		@ErrCode = 111				 
	if @ReturnErrCode = 0
		RaisError (@ErrMsg, 16, 1)
	return
END

--Check VS enable status:
IF @aHideVirtualSports = 1 and @HideVirtualSports = 0
BEGIN
	Select @ErrMsg = 'Member is offered Virtual Sports but new agent is not offered Virtual Sports.',
		@ErrCode = 112					 
	if @ReturnErrCode = 0
		RaisError (@ErrMsg, 16, 1)
	return
END

--Check CS SyncCasino between Agent and Member 
IF @aSyncCasino = 0 AND @SyncCasino = 1 
BEGIN
	SELECT @ErrMsg = 'Error Agent ' + @agentname + ', member ' + @membername + ': member is synchronized Casino but new agent is not synchronized Casino.',
		@ErrCode = 113	
	if @ReturnErrCode = 0
		RaisError (@ErrMsg, 16, 1)
	return	
END 

--Check SyncBingo between Agent and Member 
IF @aSyncBingo = 0 AND @SyncBingo = 1 
BEGIN
	SELECT @ErrMsg = 'Error Agent ' + @agentname + ', member ' + @membername + ': member is synchronized Bingo but new agent is not synchronized Bingo.',
		@ErrCode = 114	
	if @ReturnErrCode = 0
		RaisError (@ErrMsg, 16, 1)
	return	
END 

--Check Bingo & Number enable status:
if @adisableBingo = 1 and @disableBingo = 0
BEGIN
	Select @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': member is enabled Bingo but new agent is not enabled Bingo.',
		@ErrCode = 115					 
	if @ReturnErrCode = 0
		RaisError (@ErrMsg, 16, 1)
	return
END

if @adisableNumber = 1 and @disableNumber = 0
BEGIN
	Select @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': member is enabled Number Game but new agent is not enabled Number Game.',
		@ErrCode = 116
	if @ReturnErrCode = 0
		RaisError (@ErrMsg, 16, 1)
	return
END

IF @aSyncLiveCasino = 0 AND @SyncLiveCasino = 1
BEGIN
	Select @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': member is synchronized Live Casino but new agent is not synchronized Live Casino.',
		@ErrCode = 117
	if @ReturnErrCode = 0
		RaisError (@ErrMsg, 16, 1)
	return
END

----------------------------------
--Check Horse, Casino sync status:
if exists(select 1 from custsetting3rd with (nolock) where custid = @custid and sporttype = 151)
	AND not exists(select 1 from custsetting3rd with (nolock) where custid = @recommend and sporttype = 151)
BEGIN
	Select @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': agent does not have Horse Racing setting.',
		@ErrCode = 201					 
	if @ReturnErrCode = 0
		RaisError (@ErrMsg, 16, 1)
	return
END

--number game
if exists(select 1 from custsetting3rd with (nolock) where custid = @custid and sporttype = 161)
	AND not exists(select 1 from custsetting3rd with (nolock) where custid = @recommend and sporttype = 161)
BEGIN
	Select @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': agent does not have Number Game setting.',
		@ErrCode = 202				 
	if @ReturnErrCode = 0
		RaisError (@ErrMsg, 16, 1)
	return
END

if exists(select 1 from custinfo with (nolock) where custid = @custid and SyncCasino = 1)
BEGIN
	Select @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': member is already Casino-synchronized.',
		@ErrCode = 203					 
	if @ReturnErrCode = 0
		RaisError (@ErrMsg, 16, 1)
	return
END

--bingo
if exists(select 1 from custinfo with (nolock) where custid = @custid and SyncBingo = 1)
BEGIN
	Select @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': member is already Bingo-synchronized.',
		@ErrCode = 204					 
	if @ReturnErrCode = 0
		RaisError (@ErrMsg, 16, 1)
	return
END
--live casino
IF EXISTS (SELECT 1 FROM CustInfo WITH(NOLOCK) WHERE custid = @custid AND SyncLiveCasino = 1)
BEGIN
	Select @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': member is already live Casino-synchronized.',
		@ErrCode = 205					 
	if @ReturnErrCode = 0
		RaisError (@ErrMsg, 16, 1)
	return
END

--VS
if exists(select 1 from custsetting3rd with (nolock) where custid = @custid and sporttype = 180)
	AND not exists(select 1 from custsetting3rd with (nolock) where custid = @recommend and sporttype = 180)

BEGIN
	Select @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': agent does not have Virtual Sports setting.',
		@ErrCode = 206					 
	if @ReturnErrCode = 0
		RaisError (@ErrMsg, 16, 1)
	return
END

--Check identical auto master position taking
if exists (
	select 1 from 
		custsetting as acs_old with (nolock)
		inner join custsetting as acs_new with (nolock) on acs_old.sporttype=acs_new.sporttype and acs_old.bettype=acs_new.bettype						
	where
		acs_old.custid = @recommend_old and  acs_new.custid = @recommend
		and(	acs_old.isautompositiontaking <> acs_new.isautompositiontaking
				or acs_old.isautolivempositiontaking <> acs_new.isautolivempositiontaking
		)
)
BEGIN
	
	Select @ErrMsg = 'Error agent ' + @agentname + ': Auto Mater Position Taking of new agent is not matched with old agent.',
		@ErrCode = 300					 
	if @ReturnErrCode = 0
		RaisError (@ErrMsg, 16, 1)
	return
END

--Check identical auto master position taking 3rd
if exists (
	select 1 from 
		custsetting3rd as acs_old with (nolock)
		inner join custsetting3rd as acs_new with (nolock) on acs_old.sporttype=acs_new.sporttype and acs_old.bettype=acs_new.bettype						
	where 
		acs_old.custid = @recommend_old and  acs_new.custid = @recommend
		and	( (acs_old.isautompositiontaking <> acs_new.isautompositiontaking AND acs_new.sporttype <> 201)
			or acs_old.isautolivempositiontaking <> acs_new.isautolivempositiontaking
		)
)
BEGIN
	
	Select @ErrMsg = 'Error agent ' + @agentname + ': Auto Mater Position Taking of new agent is not matched with old agent.',
		@ErrCode = 301					 
	if @ReturnErrCode = 0
		RaisError (@ErrMsg, 16, 1)
	return
END

--Check identical auto master position taking for live casino
IF EXISTS (
		SELECT 1
		FROM CustSettingGame acs_old WITH(NOLOCK) 
			INNER JOIN CustSettingGame acs_new WITH(NOLOCK) ON acs_new.custid = @recommend AND acs_new.sporttype = acs_old.sporttype AND acs_new.bettype = acs_old.bettype
		WHERE acs_old.custid = @recommend_old AND acs_old.sporttype = 162 AND acs_old.bettype = 1101
			AND acs_old.isautompositiontaking <> acs_new.isautompositiontaking
	)
BEGIN
	Select @ErrMsg = 'Error agent ' + @agentname + ': Auto Mater Position Taking of new agent is not matched with old agent.',
		@ErrCode = 302					 
	if @ReturnErrCode = 0
		RaisError (@ErrMsg, 16, 1)
	return
END

----Check P2P :Game Setting
--IF exists(
--	SELECT TOP 1 1
--	FROM dbo.P2PGROUPCOMM me WITH(NOLOCK)
--		INNER JOIN dbo.P2PGROUPCOMM a WITH(NOLOCK)
--			ON a.GroupID = me.GroupID
--		WHERE  me.custid = @custid AND A.custid = @recommend
--				AND (a.discount < me.playerdiscount )
--)
--BEGIN
--	Select @ErrMsg = 'Error agent ' + @agentname + ', member ' + @membername + ': P2P''s commission of member is greater than P2P''s commission of new agent .',
--		@ErrCode = 303
--	return
--END

----------------------------
DECLARE
	@apositiontaking_1 SMALLMONEY,
	@apositiontaking_2 SMALLMONEY,
	@apositiontaking_3 SMALLMONEY,
	@apositiontaking_4 SMALLMONEY,
	@apositiontaking_5 SMALLMONEY,
	@apositiontaking_6 SMALLMONEY,
	@apositiontaking_7 SMALLMONEY,
	@apositiontaking_8 SMALLMONEY,
	@apositiontaking_9 SMALLMONEY,
	@apositiontaking_10 SMALLMONEY,
	
	@alivepositiontaking_1 SMALLMONEY,
	@alivepositiontaking_3 SMALLMONEY,
	@alivepositiontaking_7 SMALLMONEY,
	@alivepositiontaking_8 SMALLMONEY,
	
	@v2apositiontaking_1 SMALLMONEY,
	@v2apositiontaking_2 SMALLMONEY,
	@v2apositiontaking_3 SMALLMONEY,
	@v2apositiontaking_7 SMALLMONEY,
	@v2apositiontaking_8 SMALLMONEY,
	--@v2apositiontaking_9 SMALLMONEY,
	@v2apositiontaking_20 SMALLMONEY,
	
	@v3apositiontaking_1 SMALLMONEY,
	@v3apositiontaking_2 SMALLMONEY,
	@v3apositiontaking_3 SMALLMONEY,
	@v3apositiontaking_20 SMALLMONEY,

	@v5apositiontaking_1 SMALLMONEY,
	@v5apositiontaking_2 SMALLMONEY,
	@v5apositiontaking_3 SMALLMONEY,
	@v5apositiontaking_20 SMALLMONEY,

	@v8apositiontaking_1 SMALLMONEY,
	@v8apositiontaking_3 SMALLMONEY,
	@v8apositiontaking_20 SMALLMONEY,

	@v10apositiontaking_1 SMALLMONEY,
	@v10apositiontaking_2 SMALLMONEY,
	@v10apositiontaking_3 SMALLMONEY,
	@v10apositiontaking_20 SMALLMONEY,

	@v11apositiontaking_1 SMALLMONEY,
	@v11apositiontaking_20 SMALLMONEY,
	
	@v99apositiontaking_1 SMALLMONEY,
	@v99apositiontaking_2 SMALLMONEY,
	@v99apositiontaking_3 SMALLMONEY,
	@v99apositiontaking_9 SMALLMONEY,
	@v99apositiontaking_20 SMALLMONEY,

	--@v201apositiontaking_2 SMALLMONEY,
	--@v201apositiontaking_3 SMALLMONEY,
	
	@v151apositiontaking_31 SMALLMONEY,
	@v151apositiontaking_32 SMALLMONEY,
	@v151apositiontaking_41 SMALLMONEY,
	@v151apositiontaking_42 SMALLMONEY,
	@v151apositiontaking_51 SMALLMONEY,
	@v151apositiontaking_52 SMALLMONEY,
	@v152apositiontaking_41 SMALLMONEY,
	@v152apositiontaking_42 SMALLMONEY,
	@v152apositiontaking_51 SMALLMONEY,
	@v152apositiontaking_52 SMALLMONEY,
	@v153apositiontaking_51 SMALLMONEY,
	@v153apositiontaking_52 SMALLMONEY,
	
	@v161apositiontaking_81 SMALLMONEY,
	@v161apositiontaking_83 SMALLMONEY,
	--@v161apositiontaking_85 SMALLMONEY,
	@v161apositiontaking_86 SMALLMONEY,
	@v161apositiontaking_88 SMALLMONEY,
	
	@v161alivepositiontaking_85 SMALLMONEY,
	@v161alivepositiontaking_86 SMALLMONEY,
	@v161alivepositiontaking_87 SMALLMONEY,
	@v161alivepositiontaking_89 SMALLMONEY,
	@v161alivepositiontaking_90 SMALLMONEY,
	--livecasino
	@v162apositiontaking_1101 SMALLMONEY, 
	--VS
	@v180apositiontaking_1201 SMALLMONEY,
	@v181apositiontaking_1231 SMALLMONEY,
	@v186apositiontaking_1220 SMALLMONEY
	

SELECT @apositiontaking_1 = apositiontaking, @alivepositiontaking_1 = alivepositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=1 AND sporttype=1
SELECT @apositiontaking_3 = apositiontaking, @alivepositiontaking_3 = alivepositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=3 AND sporttype=1
SELECT @apositiontaking_7 = apositiontaking, @alivepositiontaking_7 = alivepositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=7 AND sporttype=1
SELECT @apositiontaking_8 = apositiontaking, @alivepositiontaking_8 = alivepositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=8 AND sporttype=1
SELECT @apositiontaking_2 = apositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=2 AND sporttype=1
SELECT @apositiontaking_4 = apositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=4 AND sporttype=1
SELECT @apositiontaking_5 = apositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=5 AND sporttype=1
SELECT @apositiontaking_6 = apositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=6 AND sporttype=1
SELECT @apositiontaking_9 = apositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=9 AND sporttype=1
SELECT @apositiontaking_10 = apositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=10 AND sporttype=1

SELECT @v2apositiontaking_1 = apositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=1 AND sporttype=2
SELECT @v2apositiontaking_2 = apositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=2 AND sporttype=2
SELECT @v2apositiontaking_3 = apositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=3 AND sporttype=2
SELECT @v2apositiontaking_7 = apositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=7 AND sporttype=2
SELECT @v2apositiontaking_8 = apositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=8 AND sporttype=2
--SELECT @v2apositiontaking_9 = apositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=9 AND sporttype=2
SELECT @v2apositiontaking_20 = apositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=20 AND sporttype=2

SELECT @v3apositiontaking_1 = apositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=1 AND sporttype=3
SELECT @v3apositiontaking_2 = apositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=2 AND sporttype=3
SELECT @v3apositiontaking_3 = apositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=3 AND sporttype=3
SELECT @v3apositiontaking_20 = apositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=20 AND sporttype=3

SELECT @v5apositiontaking_1 = apositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=1 AND sporttype=5
SELECT @v5apositiontaking_2 = apositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=2 AND sporttype=5
SELECT @v5apositiontaking_3 = apositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=3 AND sporttype=5
SELECT @v5apositiontaking_20 = apositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=20 AND sporttype=5

SELECT @v8apositiontaking_1 = apositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=1 AND sporttype=8
SELECT @v8apositiontaking_3 = apositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=3 AND sporttype=8
SELECT @v8apositiontaking_20 = apositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=20 AND sporttype=8

SELECT @v10apositiontaking_1 = apositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=1 AND sporttype=10
SELECT @v10apositiontaking_2 = apositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=2 AND sporttype=10
SELECT @v10apositiontaking_3 = apositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=3 AND sporttype=10
SELECT @v10apositiontaking_20 = apositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=20 AND sporttype=10

SELECT @v11apositiontaking_1 = apositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=1 AND sporttype=11
SELECT @v11apositiontaking_20 = apositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=20 AND sporttype=11

SELECT @v99apositiontaking_1 = apositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=1 AND sporttype=99
SELECT @v99apositiontaking_2 = apositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=2 AND sporttype=99
SELECT @v99apositiontaking_3 = apositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=3 AND sporttype=99
SELECT @v99apositiontaking_9 = apositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=9 AND sporttype=99
SELECT @v99apositiontaking_20 = apositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=20 AND sporttype=99

--SELECT @v201apositiontaking_2 = apositiontaking FROM custsetting3rd WITH (NOLOCK) WHERE custid = @custid AND bettype=2 AND sporttype=201
--SELECT @v201apositiontaking_3 = apositiontaking FROM custsetting3rd WITH (NOLOCK) WHERE custid = @custid AND bettype=3 AND sporttype=201

SELECT @v151apositiontaking_31 = apositiontaking FROM custsetting3rd WITH (NOLOCK) WHERE custid = @custid AND bettype=31 AND sporttype=151
SELECT @v151apositiontaking_32 = apositiontaking FROM custsetting3rd WITH (NOLOCK) WHERE custid = @custid AND bettype=32 AND sporttype=151
SELECT @v151apositiontaking_41 = apositiontaking FROM custsetting3rd WITH (NOLOCK) WHERE custid = @custid AND bettype=41 AND sporttype=151
SELECT @v151apositiontaking_42 = apositiontaking FROM custsetting3rd WITH (NOLOCK) WHERE custid = @custid AND bettype=42 AND sporttype=151
SELECT @v151apositiontaking_51 = apositiontaking FROM custsetting3rd WITH (NOLOCK) WHERE custid = @custid AND bettype=51 AND sporttype=151
SELECT @v151apositiontaking_52 = apositiontaking FROM custsetting3rd WITH (NOLOCK) WHERE custid = @custid AND bettype=52 AND sporttype=151
SELECT @v152apositiontaking_41 = apositiontaking FROM custsetting3rd WITH (NOLOCK) WHERE custid = @custid AND bettype=41 AND sporttype=152
SELECT @v152apositiontaking_42 = apositiontaking FROM custsetting3rd WITH (NOLOCK) WHERE custid = @custid AND bettype=42 AND sporttype=152
SELECT @v152apositiontaking_51 = apositiontaking FROM custsetting3rd WITH (NOLOCK) WHERE custid = @custid AND bettype=51 AND sporttype=152
SELECT @v152apositiontaking_52 = apositiontaking FROM custsetting3rd WITH (NOLOCK) WHERE custid = @custid AND bettype=52 AND sporttype=152
SELECT @v153apositiontaking_51 = apositiontaking FROM custsetting3rd WITH (NOLOCK) WHERE custid = @custid AND bettype=51 AND sporttype=153
SELECT @v153apositiontaking_52 = apositiontaking FROM custsetting3rd WITH (NOLOCK) WHERE custid = @custid AND bettype=52 AND sporttype=153

SELECT @v161apositiontaking_81 = apositiontaking FROM custsetting3rd WITH (NOLOCK) WHERE custid = @custid AND bettype=81 AND sporttype=161
SELECT @v161apositiontaking_83 = apositiontaking FROM custsetting3rd WITH (NOLOCK) WHERE custid = @custid AND bettype=83 AND sporttype=161
--SELECT @v161apositiontaking_85 = apositiontaking FROM custsetting3rd WITH (NOLOCK) WHERE custid = @custid AND bettype=85 AND sporttype=161
SELECT @v161apositiontaking_86 = apositiontaking FROM custsetting3rd WITH (NOLOCK) WHERE custid = @custid AND bettype=86 AND sporttype=161
SELECT @v161apositiontaking_88 = apositiontaking FROM custsetting3rd WITH (NOLOCK) WHERE custid = @custid AND bettype=88 AND sporttype=161

SELECT @v161alivepositiontaking_85 = alivepositiontaking FROM custsetting3rd WITH (NOLOCK) WHERE custid = @custid AND bettype=85 AND sporttype=161
SELECT @v161alivepositiontaking_86 = alivepositiontaking FROM custsetting3rd WITH (NOLOCK) WHERE custid = @custid AND bettype=86 AND sporttype=161
SELECT @v161alivepositiontaking_87 = alivepositiontaking FROM custsetting3rd WITH (NOLOCK) WHERE custid = @custid AND bettype=87 AND sporttype=161
SELECT @v161alivepositiontaking_89 = alivepositiontaking FROM custsetting3rd WITH (NOLOCK) WHERE custid = @custid AND bettype=89 AND sporttype=161
SELECT @v161alivepositiontaking_90 = alivepositiontaking FROM custsetting3rd WITH (NOLOCK) WHERE custid = @custid AND bettype=90 AND sporttype=161

SELECT @v162apositiontaking_1101 = apositiontaking FROM CustSettingGame WITH(NOLOCK) WHERE custid = @custid AND sporttype = 162 AND bettype = 1101

SELECT @v180apositiontaking_1201 = apositiontaking FROM custsetting3rd WITH (NOLOCK) WHERE custid = @custid AND bettype=1201 AND sporttype=180
SELECT @v181apositiontaking_1231 = apositiontaking FROM custsetting3rd WITH (NOLOCK) WHERE custid = @custid AND bettype=1231 AND sporttype=181
SELECT @v186apositiontaking_1220 = apositiontaking FROM custsetting3rd WITH (NOLOCK) WHERE custid = @custid AND bettype=1220 AND sporttype=186


print  'Move member '+@membername+' from agent id '+convert(varchar(20), @recommend_old)+' to agent '+@agentname+' (id ' + convert(varchar(20), @recommend)+')'

----P2PGAMESETTING table
--UPDATE G_P
--SET stakelevel1 = CASE WHEN s.stakelevel1 = 1 AND G_P.stakelevel1 = 1 THEN 1 ELSE 0 END,
--	stakelevel2 = CASE WHEN s.stakelevel2 = 1 AND G_P.stakelevel2 = 1 THEN 1 ELSE 0 END,
--	stakelevel3 = CASE WHEN s.stakelevel3 = 1 AND G_P.stakelevel3 = 1 THEN 1 ELSE 0 END,
--	stakelevel4 = CASE WHEN s.stakelevel4 = 1 AND G_P.stakelevel4 = 1 THEN 1 ELSE 0 END,
--	stakelevel5 = CASE WHEN s.stakelevel5 = 1 AND G_P.stakelevel5 = 1 THEN 1 ELSE 0 END
--FROM P2PGameSetting G_P WITH (ROWLOCK, UPDLOCK)
--	INNER JOIN 
--		( SELECT * FROM dbo.P2PGameSetting s WITH(NOLOCK) WHERE custid = @srecommend) s
--			ON G_P.BETTYPE = s.BETTYPE
--WHERE G_P.custid = @CustID

--IF @@ERROR <> 0 
--	BEGIN
--		IF @@ERROR <>0
--			SELECT	@ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': update unsuccessfully (P2PGameSetting).',
--					@ErrCode = 500
--		RETURN
--	END

--if (@aDisableP2P = 1 and @DisableP2P = 0) 
--	OR (@aIsAutoResetP2P = 0 and @IsAutoResetP2P = 1)
--	OR (@aDisableFunP2P = 1 and @DisableFunP2P = 0)
--	OR (@aMaxTransferP2P < @MaxTransferP2P)
--	OR (@aDisableVirtualSports = 1 and @DisableVirtualSports = 0)
--	OR (@aDoubleCommLosing = 0 and @DoubleCommLosing = 1)
--BEGIN
--	UPDATE	Custinfo WITH (UPDLOCK,ROWLOCK)
--	SET		DisableP2P = CASE WHEN @aDisableP2P = 1 THEN 1 ELSE DisableP2P END,
--			DisableFunP2P = CASE WHEN @aIsAutoResetP2P = 1 THEN 1 ELSE DisableFunP2P END,
--			IsAutoResetP2P = CASE WHEN @aDisableFunP2P = 0 THEN 0 ELSE IsAutoResetP2P END,
--			MaxTransferP2P = CASE WHEN @aMaxTransferP2P < MaxTransferP2P THEN @aMaxTransferP2P ELSE MaxTransferP2P END,
--			DisableVirtualSports = CASE WHEN @aDisableVirtualSports = 1 THEN 1 ELSE DisableVirtualSports END ,
--			DoubleCommLosing = CASE WHEN @aDoubleCommLosing = 0 THEN 0 ELSE DoubleCommLosing END
--	WHERE	custid = @CustID
--	IF @@ERROR <>0
--	BEGIN
--		Select	@ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': update unsuccessfully (custinfo).',
--				@ErrCode = 501
--		RETURN 
--	END
--END

----P2PGroupComm table
--UPDATE G_C 
--SET sdiscount = a.sdiscount,
--	adiscount  =a.adiscount,
--	discount  =a.discount
--FROM P2PGroupComm G_C WITH (ROWLOCK, UPDLOCK)
--	INNER JOIN 
--		( SELECT * FROM dbo.P2PGROUPCOMM a WITH(NOLOCK) WHERE custid = @recommend) a
--		ON G_C.GroupID = a.GroupID
--WHERE G_C.custid = @custid

--IF @@ERROR <> 0 
--BEGIN
--	IF @@ERROR <>0
--		SELECT	@ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': update unsuccessfully (custinfo).',
--				@ErrCode = 502
--	RETURN
--END

if (@aDoubleCommLosing = 0 and @DoubleCommLosing = 1)
BEGIN
	UPDATE	Custinfo WITH (UPDLOCK,ROWLOCK)
	SET		DoubleCommLosing = CASE WHEN @aDoubleCommLosing = 0 THEN 0 ELSE DoubleCommLosing END
	WHERE	custid = @CustID
	IF @@ERROR <>0
	BEGIN
		Select	@ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': update unsuccessfully (custinfo).',
				@ErrCode = 501
		RETURN 
	END
END

--customer table
update customer with (ROWLOCK, UPDLOCK) set srecommend = @srecommend, mrecommend = @mrecommend,
											recommend = @recommend
where custid = @custid
if @@Error <> 0 
BEGIN
	
	--ROLLBACK TRANSACTION MANUALLY
	update customer with (ROWLOCK, UPDLOCK) set srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											recommend = @recommend_old
	where custid = @custid

	Select @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': update unsuccessfully (customer).',
		@ErrCode = 503				 
	if @ReturnErrCode = 0
		RaisError (@ErrMsg, 16, 1)
	
	return
END

--custinfo table
update custinfo with (ROWLOCK, UPDLOCK) set srecommend = @srecommend, mrecommend = @mrecommend,
											recommend = @recommend
where custid = @custid
if @@Error <> 0 
BEGIN
	--ROLLBACK TRANSACTION MANUALLY
	update customer with (ROWLOCK, UPDLOCK) set srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											recommend = @recommend_old
	where custid = @custid
	
	update custinfo with (ROWLOCK, UPDLOCK) set srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											recommend = @recommend_old
	where custid = @custid

	Select @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': update unsuccessfully (custinfo).',
		@ErrCode = 504					 
	if @ReturnErrCode = 0
		RaisError (@ErrMsg, 16, 1)
	
	return
END

EXEC dbo.Acc_CustomerUpdMember_PositionTaking 
	@custid = @custid,
	@apositiontaking_1 = @apositiontaking_1,
	@apositiontaking_2 = @apositiontaking_2,
	@apositiontaking_3 = @apositiontaking_3,
	@apositiontaking_4 = @apositiontaking_4,
	@apositiontaking_5 = @apositiontaking_5,
	@apositiontaking_6 = @apositiontaking_6,
	@apositiontaking_7 = @apositiontaking_7,
	@apositiontaking_8 = @apositiontaking_8,
	@apositiontaking_9 = @apositiontaking_9,
	@apositiontaking_10 = @apositiontaking_10,
	@alivepositiontaking_1 = @alivepositiontaking_1,
	@alivepositiontaking_3 = @alivepositiontaking_3,
	@alivepositiontaking_7 = @alivepositiontaking_7,
	@alivepositiontaking_8 = @alivepositiontaking_8,
	@v2apositiontaking_1 = @v2apositiontaking_1,
	@v2apositiontaking_2 = @v2apositiontaking_2,
	@v2apositiontaking_3 = @v2apositiontaking_3,
	@v2apositiontaking_7 = @v2apositiontaking_7,
	@v2apositiontaking_8 = @v2apositiontaking_8,
	--@v2apositiontaking_9 = @v2apositiontaking_9,
	@v2apositiontaking_20 = @v2apositiontaking_20,
	@v3apositiontaking_1 = @v3apositiontaking_1,
	@v3apositiontaking_2 = @v3apositiontaking_2,
	@v3apositiontaking_3 = @v3apositiontaking_3,
	@v3apositiontaking_20 = @v3apositiontaking_20,
	@v5apositiontaking_1 = @v5apositiontaking_1,
	@v5apositiontaking_2 = @v5apositiontaking_2,
	@v5apositiontaking_3 = @v5apositiontaking_3,
	@v5apositiontaking_20 = @v5apositiontaking_20,
	@v8apositiontaking_1 = @v8apositiontaking_1,
	@v8apositiontaking_3 = @v8apositiontaking_3,
	@v8apositiontaking_20 = @v8apositiontaking_20,
	@v10apositiontaking_1 = @v10apositiontaking_1,
	@v10apositiontaking_2 = @v10apositiontaking_2,
	@v10apositiontaking_3 = @v10apositiontaking_3,
	@v10apositiontaking_20 = @v10apositiontaking_20,
	@v11apositiontaking_1 = @v11apositiontaking_1,
	@v11apositiontaking_20 = @v11apositiontaking_20,	
	@v99apositiontaking_1 = @v99apositiontaking_1,
	@v99apositiontaking_2 = @v99apositiontaking_2,
	@v99apositiontaking_3 = @v99apositiontaking_3,
	@v99apositiontaking_9 = @v99apositiontaking_9,
	@v99apositiontaking_20 = @v99apositiontaking_20,
	@v161apositiontaking_81 = @v161apositiontaking_81,   
	@v161apositiontaking_83 = @v161apositiontaking_83,   
	--@v161apositiontaking_85 = @v161apositiontaking_85,   
	@v161apositiontaking_86 = @v161apositiontaking_86,   
	@v161apositiontaking_88 = @v161apositiontaking_88,  
	  
	@v161alivepositiontaking_85 = @v161alivepositiontaking_85,  
	@v161alivepositiontaking_86 = @v161alivepositiontaking_86, 
	@v161alivepositiontaking_87 = @v161alivepositiontaking_87,
	@v161alivepositiontaking_89 = @v161alivepositiontaking_89,  
	@v161alivepositiontaking_90 = @v161alivepositiontaking_90,
	
	@UserID = @UserID,
	@ErrCode = @ErrCode OUTPUT,
	@ErrMsg = @ErrMsg OUTPUT

if @ErrCode > 0
BEGIN
	--ROLLBACK TRANSACTION MANUALLY
	update customer with (ROWLOCK, UPDLOCK) set srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											recommend = @recommend_old
	where custid = @custid
	
	update custinfo with (ROWLOCK, UPDLOCK) set srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											recommend = @recommend_old
	where custid = @custid
	
	if @ReturnErrCode = 0
		RaisError (@ErrMsg, 16, 1)	
	return
END

EXEC dbo.Acc_CustomerUpdMemberHR_PositionTaking 
	@custid = @custid,
	@v151apositiontaking_31 = @v151apositiontaking_31,
	@v151apositiontaking_32 = @v151apositiontaking_32,
	@v151apositiontaking_41 = @v151apositiontaking_41,
	@v151apositiontaking_42 = @v151apositiontaking_42,
	@v151apositiontaking_51 = @v151apositiontaking_51,
	@v151apositiontaking_52 = @v151apositiontaking_52,
	@v152apositiontaking_41 = @v152apositiontaking_41,
	@v152apositiontaking_42 = @v152apositiontaking_42,
	@v152apositiontaking_51 = @v152apositiontaking_51,
	@v152apositiontaking_52 = @v152apositiontaking_52,
	@v153apositiontaking_51 = @v153apositiontaking_51,
	@v153apositiontaking_52 = @v153apositiontaking_52,
	@UserID = @UserID,
	@ErrCode = @ErrCode OUTPUT,
	@ErrMsg = @ErrMsg OUTPUT

if @ErrCode > 0
BEGIN
	--ROLLBACK TRANSACTION MANUALLY
	update customer with (ROWLOCK, UPDLOCK) set srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											recommend = @recommend_old
	where custid = @custid
	
	update custinfo with (ROWLOCK, UPDLOCK) set srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											recommend = @recommend_old
	where custid = @custid
	
	if @ReturnErrCode = 0
		RaisError (@ErrMsg, 16, 1)	
	return
END

EXEC dbo.Acc_CustomerUpdMemberLiveCS_Positiontaking
	@custid  = @custid,
	@v162apositiontaking_1101 = @v162apositiontaking_1101,
	
	@UserID	= @UserID,	
	@ErrCode = @ErrCode OUTPUT,
	@ErrMsg	 = @ErrMsg OUTPUT	

IF @ErrCode > 0
BEGIN
	--ROLLBACK TRANSACTION MANUALLY
	update customer with (ROWLOCK, UPDLOCK) set srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											recommend = @recommend_old
	where custid = @custid
	
	update custinfo with (ROWLOCK, UPDLOCK) set srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											recommend = @recommend_old
	where custid = @custid
	
	if @ReturnErrCode = 0
		RaisError (@ErrMsg, 16, 1)	
	return
END

-- VS
DECLARE @ErrCode_1 VARCHAR(300)

EXEC dbo.Acc_CustomerUpdMemberVS_Positiontaking
	@custid  = @custid,
	@sporttype	= 180,
	@bettype = 1201 ,
	@a1 = @v180apositiontaking_1201,
	
	@UserID	= @UserID,	
	@ErrCode = @ErrCode_1 OUTPUT,
	@ErrMsg	 = @ErrMsg OUTPUT	

IF CHARINDEX('-101', @ErrCode_1) = 0
BEGIN
	--ROLLBACK TRANSACTION MANUALLY
	update customer with (ROWLOCK, UPDLOCK) set srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											recommend = @recommend_old
	where custid = @custid
	
	update custinfo with (ROWLOCK, UPDLOCK) set srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											recommend = @recommend_old
	where custid = @custid
	
	if @ReturnErrCode = 0
		RaisError (@ErrMsg, 16, 1)	
	return
END

-- Virtual HR
EXEC dbo.Acc_CustomerUpdMemberVS_Positiontaking
	@custid  = @custid,
	@sporttype	= 181,
	@bettype = 1231 ,
	@a1 = @v181apositiontaking_1231,
	
	@UserID	= @UserID,	
	@ErrCode = @ErrCode_1 OUTPUT,
	@ErrMsg	 = @ErrMsg OUTPUT	

IF CHARINDEX('-101', @ErrCode_1) = 0
BEGIN
	--ROLLBACK TRANSACTION MANUALLY
	update customer with (ROWLOCK, UPDLOCK) set srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											recommend = @recommend_old
	where custid = @custid
	
	update custinfo with (ROWLOCK, UPDLOCK) set srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											recommend = @recommend_old
	where custid = @custid
	
	if @ReturnErrCode = 0
		RaisError (@ErrMsg, 16, 1)	
	return
END

-- Virtual Tennis
EXEC dbo.Acc_CustomerUpdMemberVS_Positiontaking
	@custid  = @custid,
	@sporttype	= 186,
	@bettype = 1220,
	@a1 = @v186apositiontaking_1220,
	
	@UserID	= @UserID,	
	@ErrCode = @ErrCode_1 OUTPUT,
	@ErrMsg	 = @ErrMsg OUTPUT	

IF CHARINDEX('-101', @ErrCode_1) = 0
BEGIN
	--ROLLBACK TRANSACTION MANUALLY
	update customer with (ROWLOCK, UPDLOCK) set srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											recommend = @recommend_old
	where custid = @custid
	
	update custinfo with (ROWLOCK, UPDLOCK) set srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											recommend = @recommend_old
	where custid = @custid
	
	if @ReturnErrCode = 0
		RaisError (@ErrMsg, 16, 1)	
	return
END

--- update suspended status
IF @aSuspended = 1 AND @Suspended = 0
BEGIN
	UPDATE Custinfo WITH (UPDLOCK, ROWLOCK)
	SET	reject = 1 
	WHERE	custid = @custid
	IF @@ERROR <>0
	BEGIN
		Select @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': update unsuccessfully (custinfo).',
		@ErrCode = 505
		if @ReturnErrCode = 0
			RaisError (@ErrMsg, 16, 1)
		return
	END
END

IF @aDisableOutright = 1 AND (@aDisableOutright <> @DisableOutright)
BEGIN 

	UPDATE Custinfo WITH (UPDLOCK,ROWLOCK)
	SET DisableOutright = 1 
	WHERE custid = @custid 
	IF @@ERROR<>0
	BEGIN
		Select @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': update unsuccessfully (custinfo).',
		@ErrCode = 506
		if @ReturnErrCode = 0
			RaisError (@ErrMsg, 16, 1)
		return
	END 
END 
/*
--Bingo & Number Game
IF @aDisableBingo = 1 AND (@aDisableBingo <> @DisableBingo)
BEGIN 

	UPDATE Custinfo WITH (UPDLOCK,ROWLOCK)
	SET DisableBingo = 1 
	WHERE custid = @custid 
	IF @@ERROR<>0
	BEGIN
		Select @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': update unsuccessfully (custinfo).',
		@ErrCode = 136
		if @ReturnErrCode = 0
			RaisError (@ErrMsg, 16, 1)
		return
	END 
END 

IF @aDisableNumber = 1 AND (@aDisableNumber <> @DisableNumber)
BEGIN 

	UPDATE Custinfo WITH (UPDLOCK,ROWLOCK)
	SET DisableNumber = 1 
	WHERE custid = @custid 
	IF @@ERROR<>0
	BEGIN
		Select @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': update unsuccessfully (custinfo).',
		@ErrCode = 137
		if @ReturnErrCode = 0
			RaisError (@ErrMsg, 16, 1)
		return
	END 
END 
*/

--Apply ExeReplication
-- call Acc_ExecRep_00 two times to update coming bets that not replicated to subcriptions servers yet.
EXEC dbo.Acc_ExecRep_00 
	@custid = @custid,
	@recommend = @recommend,
	@recommend_old = @recommend_old,
	@mrecommend = @mrecommend,
	@mrecommend_old = @mrecommend_old,
	@srecommend = @srecommend,
	@srecommend_old = @srecommend_old,
	@roleid = 1,
	@ErrCode = @ErrCode OUTPUT,
	@ErrMsg = @ErrMsg OUTPUT
IF @ErrCode<>0 RETURN

EXEC dbo.Acc_ExecRep_00 
	@custid = @custid,
	@recommend = @recommend,
	@recommend_old = @recommend_old,
	@mrecommend = @mrecommend,
	@mrecommend_old = @mrecommend_old,
	@srecommend = @srecommend,
	@srecommend_old = @srecommend_old,
	@roleid = 1,
	@ErrCode = @ErrCode OUTPUT,
	@ErrMsg = @ErrMsg OUTPUT
IF @ErrCode<>0 RETURN

--Update Member's Comm
DECLARE	@ugroup VARCHAR(5)
SELECT	@ugroup= ugroup FROM Customer WITH (NOLOCK) WHERE custid = @custid
--super 
UPDATE	cs WITH (UPDLOCK,ROWLOCK)
SET		sdiscount = CASE WHEN scs.bettype IN (1,2,3,7,8) 
								THEN( case	when @ugroup in ('a','hka','dea') then scs.groupa 
											when @ugroup in ('b','hkb','deb') then scs.groupb  
											when @ugroup in ('c','hkc','dec') then scs.groupc  
											when @ugroup in ('d','hkd','ded') then scs.groupd
											else scs.sdiscount end)
						 ELSE scs.sdiscount END 
FROM	CustSetting scs WITH (NOLOCK)
		INNER JOIN CustSetting cs ON scs.custid = @srecommend AND cs.custid = @custid 
										AND scs.sporttype = cs.sporttype AND scs.bettype = cs.bettype 
WHERE	(scs.bettype in (1,2,3,7,8) 
			and	cs.sdiscount > case	when @ugroup in ('a','hka','dea') then scs.groupa 
									when @ugroup in ('b','hkb','deb') then scs.groupb  
									when @ugroup in ('c','hkc','dec') then scs.groupc  
									when @ugroup in ('d','hkd','ded') then scs.groupd
									else scs.sdiscount end)
		or (scs.bettype not in (1,2,3,7,8) and scs.sdiscount< cs.sdiscount)

IF @@ERROR<>0
BEGIN
		Select @ErrMsg = 'update super commission unsuccessfully.',
		@ErrCode = 506					 
		if @ReturnErrCode = 0
			RaisError (@ErrMsg, 16, 1)
		return
END

--super 3rd

UPDATE	cs WITH (UPDLOCK,ROWLOCK)
SET		sdiscount = scs.sdiscount
FROM	CustSetting3rd scs WITH (NOLOCK)
		INNER JOIN CustSetting3rd cs ON scs.custid = @srecommend AND cs.custid = @custid 
										AND scs.sporttype = cs.sporttype AND scs.bettype = cs.bettype 
WHERE	scs.sdiscount< cs.sdiscount
IF @@ERROR<>0
BEGIN
		Select @ErrMsg = 'update super commission unsuccessfully.',
		@ErrCode = 507				 
		if @ReturnErrCode = 0
			RaisError (@ErrMsg, 16, 1)
		return
END
--live casino

UPDATE cs WITH(UPDLOCK,ROWLOCK)
SET sdiscount = scs.sdiscount
FROM CustSettingGame scs WITH(NOLOCK)
	INNER JOIN CustSettingGame cs ON scs.custid = @srecommend AND scs.sporttype = cs.sporttype AND scs.bettype = cs.bettype
WHERE cs.custid = @custid AND cs.sporttype = 162 AND cs.bettype = 1101
	AND scs.sdiscount < cs.sdiscount

IF @@ERROR<>0
BEGIN
		Select @ErrMsg = 'update super commission unsuccessfully.',
		@ErrCode = 508				 
		if @ReturnErrCode = 0
			RaisError (@ErrMsg, 16, 1)
		return
END

--master
UPDATE	cs WITH (UPDLOCK,ROWLOCK)
SET		adiscount = CASE WHEN mcs.bettype IN (1,2,3,7,8) 
								THEN (case	when @ugroup in ('a','hka','dea') then mcs.groupa 
											when @ugroup in ('b','hkb','deb') then mcs.groupb  
											when @ugroup in ('c','hkc','dec') then mcs.groupc  
											when @ugroup in ('d','hkd','ded') then mcs.groupd
											else mcs.adiscount end )
						  ELSE mcs.adiscount END 
FROM	CustSetting mcs WITH (NOLOCK)
		INNER JOIN CustSetting cs ON mcs.custid = @mrecommend AND cs.custid = @custid 
										AND mcs.sporttype = cs.sporttype AND mcs.bettype = cs.bettype 
WHERE	(mcs.bettype in (1,2,3,7,8) 
			and	cs.adiscount > case	when @ugroup in ('a','hka','dea') then mcs.groupa 
									when @ugroup in ('b','hkb','deb') then mcs.groupb  
									when @ugroup in ('c','hkc','dec') then mcs.groupc  
									when @ugroup in ('d','hkd','ded') then mcs.groupd
									else mcs.adiscount end)
		or (mcs.bettype not in (1,2,3,7,8) and mcs.adiscount< cs.adiscount)
IF @@ERROR<>0
BEGIN
		Select @ErrMsg = 'update master commission unsuccessfully.',
		@ErrCode = 509					 
		if @ReturnErrCode = 0
			RaisError (@ErrMsg, 16, 1)
		return
END

--master 3rd
UPDATE	cs WITH (UPDLOCK,ROWLOCK)
SET		adiscount = mcs.adiscount 
FROM	CustSetting3rd mcs WITH (NOLOCK)
		INNER JOIN CustSetting3rd cs ON mcs.custid = @mrecommend AND cs.custid = @custid 
										AND mcs.sporttype = cs.sporttype AND mcs.bettype = cs.bettype 
WHERE	mcs.adiscount< cs.adiscount
IF @@ERROR<>0
BEGIN
		Select @ErrMsg = 'update master commission unsuccessfully.',
		@ErrCode = 510					 
		if @ReturnErrCode = 0
			RaisError (@ErrMsg, 16, 1)
		return
END
--live casino
UPDATE cs WITH(UPDLOCK,ROWLOCK) 
SET adiscount = mcs.adiscount
FROM CustSettingGame mcs WITH(NOLOCK) 
	INNER JOIN CustSettingGame cs ON mcs.custid = @mrecommend AND mcs.sporttype = cs.sporttype AND mcs.bettype = cs.bettype 
WHERE cs.custid = @custid AND cs.sporttype = 162 AND cs.bettype = 1101
	AND mcs.adiscount < cs.adiscount

IF @@ERROR <> 0
BEGIN
	Select @ErrMsg = 'update master commission unsuccessfully.',
		@ErrCode = 511					 
		if @ReturnErrCode = 0
			RaisError (@ErrMsg, 16, 1)
		return
END
--agent 
UPDATE	cs WITH (UPDLOCK,ROWLOCK)
SET		cs.discount = CASE	WHEN acs.bettype IN (1,2,3,7,8) 
									THEN (case	when @ugroup in ('a','hka','dea') then acs.groupa 
												when @ugroup in ('b','hkb','deb') then acs.groupb  
												when @ugroup in ('c','hkc','dec') then acs.groupc  
												when @ugroup in ('d','hkd','ded') then acs.groupd
												else acs.discount end)
							ELSE acs.discount END 
FROM	CustSetting acs WITH (NOLOCK)
		INNER JOIN CustSetting cs ON acs.custid = @recommend AND cs.custid = @custid 
										AND acs.sporttype = cs.sporttype AND acs.bettype = cs.bettype 
WHERE	(acs.bettype in (1,2,3,7,8)  
			and	cs.discount > case	when @ugroup in ('a','hka','dea') then acs.groupa 
									when @ugroup in ('b','hkb','deb') then acs.groupb  
									when @ugroup in ('c','hkc','dec') then acs.groupc  
									when @ugroup in ('d','hkd','ded') then acs.groupd
									else acs.discount end
		)
		or (acs.bettype not in (1,2,3,7,8) and acs.discount< cs.discount)
IF @@ERROR<>0
BEGIN
		Select @ErrMsg = 'update agent commission unsuccessfully.',
		@ErrCode = 512					 
		if @ReturnErrCode = 0
			RaisError (@ErrMsg, 16, 1)
		return
END

--agent 3rd
UPDATE	cs WITH (UPDLOCK,ROWLOCK)
SET		cs.discount = acs.discount
FROM	CustSetting3rd acs WITH (NOLOCK)
		INNER JOIN CustSetting3rd cs ON acs.custid = @recommend AND cs.custid = @custid 
										AND acs.sporttype = cs.sporttype AND acs.bettype = cs.bettype 
WHERE	acs.discount< cs.discount
IF @@ERROR<>0
BEGIN
		Select @ErrMsg = 'update agent commission unsuccessfully.',
		@ErrCode = 513					 
		if @ReturnErrCode = 0
			RaisError (@ErrMsg, 16, 1)
		return
END

--live casino
UPDATE cs WITH(UPDLOCK,ROWLOCK) 
SET cs.discount = acs.discount
FROM CustSettingGame acs WITH(NOLOCK)
	INNER JOIN CustSettingGame cs ON acs.custid = @recommend AND acs.sporttype = cs.sporttype AND acs.bettype = cs.bettype 
WHERE cs.custid = @custid AND cs.sporttype = 162 AND cs.bettype = 1101 
	AND acs.discount < cs.discount

IF @@ERROR <> 0
BEGIN
	Select @ErrMsg = 'update agent commission unsuccessfully.',
		@ErrCode = 514					 
		if @ReturnErrCode = 0
			RaisError (@ErrMsg, 16, 1)
		return
END	
	
	
--member 
UPDATE	cs WITH (UPDLOCK,ROWLOCK)
SET		playerdiscount = CASE	WHEN acs.bettype IN (1,2,3,7,8) 
									THEN (case	when @ugroup in ('a','hka','dea') then acs.groupa 
												when @ugroup in ('b','hkb','deb') then acs.groupb  
												when @ugroup in ('c','hkc','dec') then acs.groupc  
												when @ugroup in ('d','hkd','ded') then acs.groupd
												else acs.discount end)
								ELSE acs.discount END
FROM	CustSetting acs WITH (NOLOCK)
		INNER JOIN CustSetting cs ON acs.custid = @recommend AND cs.custid = @custid 
									 AND acs.sporttype = cs.sporttype AND acs.bettype = cs.bettype 
WHERE	(acs.bettype in (1,2,3,7,8) 
			and	cs.playerdiscount > case	when @ugroup in ('a','hka','dea') then acs.groupa 
											when @ugroup in ('b','hkb','deb') then acs.groupb  
											when @ugroup in ('c','hkc','dec') then acs.groupc  
											when @ugroup in ('d','hkd','ded') then acs.groupd
											else acs.discount end)
		OR (acs.bettype not in (1,2,3,7,8) and acs.discount< cs.playerdiscount)
IF @@ERROR<>0
BEGIN
		Select @ErrMsg = 'update commission unsuccessfully.',
		@ErrCode = 515					 
		if @ReturnErrCode = 0
			RaisError (@ErrMsg, 16, 1)
		return
END
--member 3rd
UPDATE	cs WITH (UPDLOCK,ROWLOCK)
SET		playerdiscount = acs.discount 
FROM	CustSetting3rd acs WITH (NOLOCK)
		INNER JOIN CustSetting3rd cs ON acs.custid = @recommend AND cs.custid = @custid 
									 AND acs.sporttype = cs.sporttype AND acs.bettype = cs.bettype 

WHERE	acs.discount< cs.playerdiscount
IF @@ERROR<>0
BEGIN
		Select @ErrMsg = 'update commission unsuccessfully.',
		@ErrCode = 516				 
		if @ReturnErrCode = 0
			RaisError (@ErrMsg, 16, 1)
		return
END
--live casino 
UPDATE cs WITH(UPDLOCK,ROWLOCK)
SET playerdiscount = acs.discount
FROM CustSettingGame acs WITH(NOLOCK) 
	INNER JOIN CustSettingGame cs ON acs.custid = @recommend AND acs.sporttype = cs.sporttype AND acs.bettype = cs.bettype 
WHERE cs.custid = @custid AND cs.sporttype = 162 AND cs.bettype = 1101 
	AND acs.discount < cs.playerdiscount

IF @@ERROR<>0
BEGIN
		Select @ErrMsg = 'update commission unsuccessfully.',
		@ErrCode = 517				 
		if @ReturnErrCode = 0
			RaisError (@ErrMsg, 16, 1)
		return
END

DECLARE @LogSPData VARCHAR(8000)
SELECT  @LogSPData = '<Acc_CustomerUpdMoveMember  MemberName="' + @membername + '" OldAgentId="'
            + CONVERT(VARCHAR(20), @recommend_old) + '" NewAgentName="' + @agentname+ '" '
            + 'NewAgentId="' + CONVERT(VARCHAR(20), @recommend) + '" '  
			+'userid="' + COALESCE(CAST(@userid AS VARCHAR(50)), SPACE(1)) + '" '
			+'ReturnErrCode="' + COALESCE(CAST(@ReturnErrCode AS VARCHAR(50)), SPACE(1)) + '" '
			+'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(50)), SPACE(1)) + '" ' 
			+'ErrMsg="' + COALESCE(CAST(@ErrMsg AS VARCHAR(400)), SPACE(1)) + '" />'

set @endRun = getdate()
set @duration  = datediff (millisecond,@startRun,@endRun)

BEGIN TRY
/*615	Acc_CustomerUpdMoveMember	Move member to new Agent*/
    EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		@UserID = @UserID,
		@CustID = @custid,
        @ActionID = 615, 
		@TrackingValue = @LogSPData,
		@duration = @duration
END TRY
BEGIN CATCH
	SELECT  @LogSPData = '<Acc_CustomerUpdMoveMember  MemberName="' + @membername + '" OldAgentId="'
            + CONVERT(VARCHAR(20), @recommend_old) + '" NewAgentName="' + @agentname+ '" '
            + 'NewAgentId="' + CONVERT(VARCHAR(20), @recommend) + '" '  
			+'userid="' + COALESCE(CAST(@userid AS VARCHAR(50)), SPACE(1)) + '" '
			+'ReturnErrCode="' + COALESCE(CAST(@ReturnErrCode AS VARCHAR(50)), SPACE(1)) + '" '
			+'ErrCode="' + COALESCE(CAST(ERROR_NUMBER() AS VARCHAR(50)),SPACE(1)) + '" ' 
			+'ErrMsg="' + COALESCE(ERROR_MESSAGE(),SPACE(1)) + '" />'
    EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		@UserID = @UserID,
		@CustID = @custid,
        @ActionID = 615, 
		@TrackingValue = @LogSPData,
		@duration = @duration	
END CATCH

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdMoveMember] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdMoveMember] TO [vnteam]