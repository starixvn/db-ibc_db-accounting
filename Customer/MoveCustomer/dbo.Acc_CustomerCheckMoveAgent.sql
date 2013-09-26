ALTER PROCEDURE [dbo].[Acc_CustomerCheckMoveAgent]
	@mastername		varchar(40),
	@agentname		varchar(40),
	@userid			int,
	@IP				varchar(15)='',
	@ErrCode		int = 0 OUTPUT,
	@ErrMsg			nvarchar(200) = '' OUTPUT
AS
/*
Created: 
Task : Check moving a agent to another master
DB: DBAGE/bodb02
Original:

Revisions:
			- 20120726@Kiwi: Only IT Admin performs the moving for financial accounts (INTERNAL super/master/agent).
			- 20120821@Dan: add virtual soccer, remove FI
			- 20130121@Dan: remove unneeded linked server call DB052
			- 20130920@Elodie: Add constraint to avoid the insufficient Given Credit of any new super/master/agent being moving to.
Param's Explanation:
• @ErrCode:
    = 0: Transaction recorded successfully.
    > 0: Specific Error.
    Max errorcode: 214
• @ErrMsg: Error description.
*/

BEGIN
	SET NOCOUNT ON
	
	declare	@srecommend			int, 
			@mrecommend			int, 
			@recommend			int,
			@srecommend_old		int, 
			@mrecommend_old		int, 
			@scurrency			tinyint, 
			@mcurrency			tinyint, 
			@acurrency			tinyint,
			@mdisable151_31		bit,-- @mdisableHR -> @mdisable151_31 
			@adisable151_31		bit,-- @adisableHR -> @adisable151_31 			
			@DisableAutoMPT		bit,
			@DisableAutoMPT_old bit,
			@mIsInternal		BIT,
			@aIsInternal		BIT,
			@mDisableOutright	BIT,
			@aDisableOutright	BIT,
			@mSyncCasino		BIT,
			@aSyncCasino		BIT,
			@mSyncLiveCasino	BIT,
			@mSyncLiveCasino_Old BIT,
			@aSyncLiveCasino	BIT,
			@mSyncBingo			BIT,
			@aSyncBingo			BIT,
			@mDisableCasino		BIT,
			@aDisableCasino		BIT,
			@mDisableLiveCasino BIT,
			@aDisableLiveCasino BIT,
			@mDisableBingo		BIT,
			@aDisableBingo		BIT,
			@mDisableNumber		BIT,
			@aDisableNumber		BIT,
			@aDisable151_41		BIT,-- @aDisableOpenTote -> @aDisable151_41
			@mDisable151_41		BIT,-- @mDisableOpenTote -> @mDisable151_41
			@aDisable151_51		BIT,
			@mDisable151_51		BIT,
			@aDisable152_41		BIT,
			@mDisable152_41		BIT,
			@aDisable152_51		BIT,
			@mDisable152_51		BIT,
			@aDisable153_51		BIT,
			@mDisable153_51		BIT,
			@aClosed			BIT,	
			@mClosed			BIT,
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
			@aGivenCredit		MONEY,
			@mGivenCredit		MONEY,
			@mUsedCredit		MONEY,
			@aHideVirtualSports		BIT,
			@mHideVirtualSports		BIT,
			@AdminUser          VARCHAR (50)


	select	@srecommend			= srecommend, 
			@mrecommend			= custid, 
			@mcurrency			= currency, 
			@scurrency			= currency, 
			@mdisable151_31		= DisableHorseracing, 			
			@mDisableOutright	= DisableOutright,
			@mSyncCasino		= syncCasino,
			@mSyncLiveCasino	= SyncLiveCasino,
			@mSyncBingo			= SyncBingo,
			@mDisableBingo		= DisableBingo,
			@mDisableNumber		= DisableNumber,
			@mDisableCasino		= disableCasino,
			@mDisableLiveCasino = DisableLivecasino, 
			@mDisable151_41		=  DisableOpenTote,
			@mDisable151_51		= Disable151_AU,
			@mDisable152_41		= Disable152_UK,
			@mDisable152_51		= Disable152_AU,
			@mDisable153_51		= Disable153_AU,	
			@mClosed			= closed,
			@mSuspended			= reject,
			@mMaxTransferP2P	= MaxTransferP2P, 
			@mIsAutoResetP2P	= IsAutoResetP2P, 
			@mDisableP2P		= DisableP2P, 
			@mDisableFunP2P		= DisableFunP2P ,
			@mGivenCredit		= credit,
			@mHideVirtualSports = HideVirtualSports
	from	custinfo with (nolock) 
	where	username = @mastername and roleid = 3

	select	@recommend			= custid, 
			@srecommend_old		= srecommend, 
			@mrecommend_old		= mrecommend, 
			@acurrency			= currency, 
			@adisable151_31		= DisableHorseracing, 			
			@aDisableOutright	= DisableOutright,
			@aSyncCasino		= syncCasino,
			@aSyncLiveCasino	= SyncLiveCasino,
			@aSyncBingo			= SyncBingo,		
			@aDisableBingo		= DisableBingo,
			@aDisableNumber		= DisableNumber,
			@aDisableCasino		= disableCasino,
			@aDisableLiveCasino = DisableLiveCasino,
			@aDisable151_41		= DisableOpenTote,
			@aDisable151_51		= Disable151_AU,
			@aDisable152_41		= Disable152_UK,
			@aDisable152_51		= Disable152_AU,
			@aDisable153_51		= Disable153_AU,
			@aClosed			= closed,
			@aSuspended			= reject,
			@aMaxTransferP2P	= MaxTransferP2P, 
			@aIsAutoResetP2P	= IsAutoResetP2P, 
			@aDisableP2P		= DisableP2P, 
			@aDisableFunP2P		= DisableFunP2P,
			@aGivenCredit		= credit,
			@aHideVirtualSports = HideVirtualSports
	from	custinfo with (NOLOCK) 
	where	username = @agentname and roleid = 2
	
	-- 20130920@Elodie: Add constraint to avoid the insufficient Given Credit of any new super/master/agent being moving to.
	SELECT @mUsedCredit = sum(credit) FROM custinfo WITH(NOLOCK) WHERE roleid = 2 AND mrecommend = @mrecommend
	IF ISNULL(@mGivenCredit,0) - ISNULL(@mUsedCredit,0) < ISNULL(@aGivenCredit,0)
	BEGIN
		Select @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': New master credit is insufficient to move this agent.',
			@ErrCode = 100			 
		return
	END
		
	SELECT @mSyncLiveCasino_Old = SyncLiveCasino FROM CustInfo WITH(NOLOCK) WHERE custid = @mrecommend_old
	
	select	@DisableAutoMPT = DisableAutoMPT 
	from	custMaster with (nolock)
	where	custid = @mrecommend

	select	@DisableAutoMPT_old = DisableAutoMPT 
	from	custMaster with (nolock)
	where	custid = @mrecommend_old 

	if isnull(@mrecommend, 0) = 0 or isnull(@srecommend, 0) = 0
	BEGIN
		Select @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': master not found.',
			@ErrCode = 101					 
		return
	END

	if isnull(@recommend, 0) = 0
	BEGIN
		Select @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': agent not found.',
			@ErrCode = 102					 
		return
	END

	if isnull(@mrecommend_old, 0) = @mrecommend
	BEGIN
		Select @ErrMsg = 'The agent '+ @agentname +' already belongs to master '+ @mastername +'.',
			@ErrCode = 103					 
		return
	END

	--Check an account disabled or not 
	EXEC dbo.Acc_CustomerSelCheckEnable @username = @mastername, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output 
	if @ErrCode <>0		return 

	EXEC dbo.Acc_CustomerSelCheckEnable @username = @agentname, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output 
	if @ErrCode <>0		return 

	if @mcurrency <> @acurrency
	BEGIN
		Select @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': currency of master and agent does not match.',
			@ErrCode = 104					 
		return
	END

	--Check Internal status
	SELECT @mIsInternal = IsInternal FROM CustMaster with (nolock) WHERE custid = @mrecommend
	SELECT @aIsInternal = IsInternal FROM CustAgent with (nolock) WHERE custid = @recommend
	IF ISNULL(@mIsInternal, 0) = 1 AND ISNULL(@aIsInternal, 0) = 0
	BEGIN
		SELECT @ErrMsg = 'Error occurs. Cannot move normal(betting) agent to new internal master.',
			@ErrCode = 105					 
		RETURN
	END
	
	--20120726@Kiwi: Only IT Admin performs the moving for financial accounts (INTERNAL super/master/agent).

	SELECT @AdminUser = username FROM custinfo WITH (NOLOCK) WHERE custid = @userid
	
	
	IF ((ISNULL(@mIsInternal, 0) = 1 AND ISNULL(@aIsInternal, 0) = 1 AND (@AdminUser NOT LIKE 'dba%') AND (@AdminUser NOT LIKE 'pgm%') AND (@AdminUser NOT IN ('vndbateam','vnQaTeam'))))
	BEGIN 
			SELECT @ErrMsg = N'This function is not allowed to perform the moving for financial accounts. Please contact IT@nexcel.vn for assistance. Thanks.', 
					@ErrCode = 119
			RETURN
	END

	-- check is closed
	IF @mClosed = 1
	BEGIN
		SELECT @ErrMsg = 'Error occurs. Cannot move to closed master.',
			@ErrCode = 106					 
		RETURN
	END

	--Check Horse enable status:
	if @mdisable151_31 = 1 and @adisable151_31 = 0
	BEGIN
		Select @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': agent enabled SA Racing but new master not enabled SA Racing.',
			@ErrCode = 107					 
		return
	END


	--Check OpenTote enable status:
	if @mDisable151_41 = 1 and @aDisable151_41 = 0
	BEGIN
		Select @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': agent enabled UK/Irish Racing but new master not enabled UK/IRish Racing.',
			@ErrCode = 108
		return
	END

	--Check Horse Racing for Aust Tote
	if @mDisable151_51 = 1 and @aDisable151_51 = 0 
	BEGIN
		Select @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': agent enabled Aust Racing but new master not enabled Aust Racing .',
			@ErrCode = 109
		return
	END

	-- Check Greyhound for UK
	if @mDisable152_41 = 1 and @aDisable152_41 = 0 
	BEGIN
		Select @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': agent enabled UK Greyhound but new master not enabled UK Greyhound.',
			@ErrCode = 110
		return
	END

	-- Check Greyhound for UK
	if @mDisable152_51 = 1 and @aDisable152_51 = 0 
	BEGIN
		Select @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': agent enabled Aust Greyhound but new master not enabled Aust Greyhound.',
			@ErrCode = 111
		return
	END

	-- Check Harness for Aust
	if @mDisable153_51 = 1 and @aDisable153_51 = 0 
	BEGIN
		Select @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': agent enabled Aust Harness but new master not enabled Aust Harness.',
			@ErrCode = 112
		return
	END

	--Check SyncCasino between Master and Agent 
	IF @mSyncCasino = 0 AND @aSyncCasino = 1
	BEGIN
		SELECT @ErrMsg = 'Error Master ' + @mastername + ', agent ' + @agentname + ': agent is synchronized Casino but new master is not synchronized Casino.',
			@ErrCode = 114					 
		RETURN
	END

	--Check Sync Live Casino
	IF @mSyncLiveCasino = 0 AND @aSyncLiveCasino = 1
	BEGIN
		SELECT @ErrMsg = 'Error Master ' + @mastername + ', agent ' + @agentname + ': agent is synchronized Casino but new master is not synchronized Casino.',
			@ErrCode = 115				 
		RETURN
	END

	/*
	--Check Casino enable status
	IF @mDisableCasino = 1 AND (@aDisableCasino = 0)
	BEGIN
		SELECT @ErrMsg = 'Error Master ' + @mastername + ', agent ' + @agentname + ': agent is enabled Casino but new master is not enabled Casino.',
			@ErrCode = 115					
		RETURN
	END
	*/
	--Check SyncBingo between Master and Agent 
	IF @mSyncBingo = 0 AND @aSyncBingo = 1
	BEGIN
		SELECT @ErrMsg = 'Error Master ' + @mastername + ', agent ' + @agentname + ': agent is synchronized Bingo but new master is not synchronized Bingo.',
			@ErrCode = 116					
		RETURN
	END

	--Check Number Game + Bingo enable status
	if @mdisableNumber = 1 and @adisableNumber = 0
	BEGIN
		Select @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': agent is enabled Number Game but new master is not enabled Number Game.',
			@ErrCode = 117					 
		return
	END
	
	--Check Virtual sport enable status
	if @mHideVirtualSports = 1 and @aHideVirtualSports = 0
	BEGIN
		Select @ErrMsg = 'Agent is offered Virtual Sports but new master is not offered Virtual Sports.',
			@ErrCode = 123					 
		return
	END		

	if @mdisableBingo = 1 and @adisableBingo = 0
	BEGIN
		Select @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': agent is enabled Bingo but new master is not enabled Bingo',
			@ErrCode = 118
		return
	END

	--Check identical auto master PT 
	if (@DisableAutoMPT_old = 0 and @DisableAutoMPT = 1)
	begin
		Select @ErrMsg = 'Error master ' + @Mastername + ': Auto Master Position Taking of new master is not allowed yet',
			@ErrCode = 119					 
		return
	end

	--Check Horse, Casino, Number Game sync status:
	if exists(select 1 from custsetting3rd with (nolock) where custid = @recommend and sporttype = 151)
		AND not exists(select 1 from custsetting3rd with (nolock) where custid = @mrecommend and sporttype = 151)
	BEGIN
		Select @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': master does not have Horse Racing setting.',
			@ErrCode = 120					 
		return
	END

	--Number Game
	if exists(select 1 from custsetting3rd with (nolock) where custid = @recommend and sporttype = 161)
		AND not exists(select 1 from custsetting3rd with (nolock) where custid = @mrecommend and sporttype = 161)
	BEGIN
		Select @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': master does not have Number Game setting.',
			@ErrCode = 122					 
		return
	END

	-- Virtual sports
	if exists(select 1 from custsetting3rd with (nolock) where custid = @recommend and sporttype = 180)
		AND not exists(select 1 from custsetting3rd with (nolock) where custid = @mrecommend and sporttype = 180)
	BEGIN
		Select @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': master does not have Virtual Sports setting.',
			@ErrCode = 124					 
		return
	END


	--Check casino Syn
	--Remove checking Casino 
	--if exists(select 1 from custinfo with (nolock) where custid = @recommend and SyncCasino = 1)
	--BEGIN
	--	Select @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': agent is already Casino-synchronized.',
	--		@ErrCode = 112					 
	--	return
	--END

	--Check commission 
	if exists (
			select 1 
			from custsetting as mcs with (NOLOCK)
				inner join custsetting as acs with (NOLOCK) on mcs.custid = @mrecommend and acs.custid = @recommend 
															and mcs.sporttype=acs.sporttype and mcs.bettype=acs.bettype 
			where 
				(mcs.bettype in (1,2,3,7,8) and ((mcs.groupa<acs.groupa) or (mcs.groupb<acs.groupb) 
				or (mcs.groupc<acs.groupc) or (mcs.groupd<acs.groupd)))
				or (mcs.bettype not in (1,2,3,7,8) and mcs.adiscount<acs.discount)
		)
	BEGIN
		Select @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': master commission is less than agent commission.',
			@ErrCode = 200					 
		return
	END

	--Check commission for 3rd party
	if exists (
			select 1 
			from custsetting3rd as mcs with (NOLOCK)
				inner join custsetting3rd as acs with (NOLOCK) on mcs.custid = @mrecommend and acs.custid = @recommend 
															and mcs.sporttype=acs.sporttype and mcs.bettype=acs.bettype 
			where mcs.adiscount<acs.discount
		)
	BEGIN
		Select @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': master commission is less than agent commission.',
			@ErrCode = 201					 
		return
	END

	--Check commission for live casino
	IF EXISTS (
			SELECT 1
			FROM CustSettingGame mcs WITH(NOLOCK) 
				INNER JOIN CustSettingGame acs WITH(NOLOCK) ON acs.custid = @recommend AND acs.sporttype = mcs.sporttype AND acs.bettype = mcs.bettype
			WHERE mcs.custid = @mrecommend AND mcs.sporttype = 162 AND mcs.bettype = 1101
				AND mcs.adiscount < acs.discount
		)
	BEGIN
		SELECT @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': master commission is less than agent commission.',
			@ErrCode = 202
		RETURN
	END

	--Check identical autoposition taking
	if exists (
		select 1 from 
			custsetting as mcs_old with (nolock)
			inner join custsetting as mcs_new with (nolock) on mcs_old.sporttype=mcs_new.sporttype and mcs_old.bettype=mcs_new.bettype						
		where
			mcs_old.custid = @mrecommend_old and  mcs_new.custid = @mrecommend
			and(	mcs_old.isautopositiontaking <> mcs_new.isautopositiontaking
					or mcs_old.isautolivepositiontaking <> mcs_new.isautolivepositiontaking
			)
	)
	BEGIN
		
		Select @ErrMsg = 'Error master ' + @Mastername + ': Auto Position Taking of new master is not matched with old master.',
			@ErrCode = 203					 
		return
	END

	--Check identical autoposition taking for 3rd Party
	if exists (
		select 1 from 
			custsetting3rd as mcs_old with (nolock)
			inner join custsetting3rd as mcs_new with (nolock) on mcs_old.sporttype=mcs_new.sporttype and mcs_old.bettype=mcs_new.bettype						
		where
			mcs_old.custid = @mrecommend_old and  mcs_new.custid = @mrecommend
			and ( mcs_old.isautopositiontaking <> mcs_new.isautopositiontaking
				  or mcs_old.isautolivepositiontaking <> mcs_new.isautolivepositiontaking
			)
	)
	BEGIN
		
		Select @ErrMsg = 'Error master ' + @Mastername + ': Auto Position Taking of new master is not matched with old master.',
			@ErrCode = 204				 
		return
	END

	--Check identical autoposition taking for live casino
	IF EXISTS (
			SELECT 1
			FROM CustSettingGame mcs_old WITH(NOLOCK)
				INNER JOIN	CustSettingGame mcs_new WITH(NOLOCK) ON mcs_new.custid = @mrecommend AND mcs_new.sporttype = mcs_old.sporttype AND mcs_new.bettype = mcs_old.bettype 
			WHERE mcs_old.custid = @mrecommend_old AND mcs_old.sporttype = 162 AND mcs_old.bettype = 1101
			AND (mcs_old.isautopositiontaking <> mcs_new.isautopositiontaking)
		)
	BEGIN
		SELECT @ErrMsg = 'Error master ' + @Mastername + ': Auto Position Taking of new master is not matched with old master.',
			@ErrCode = 205				 
		RETURN
	END

	--Check Position Taking
		--check m3_master_old <= m3_master_new

	if exists (
		select 1 from 
			custsetting as mcs_old with (nolock)
			inner join custsetting as mcs_new with (nolock) on mcs_old.sporttype=mcs_new.sporttype and mcs_old.bettype=mcs_new.bettype						
		where
			mcs_old.custid = @mrecommend_old and  mcs_new.custid = @mrecommend
			and
			(mcs_old.mpositiontaking > mcs_new.mpositiontaking
			or (mcs_old.bettype in (1,3,7,8) and mcs_old.sporttype =1 and mcs_old.mlivepositiontaking > mcs_new.mlivepositiontaking))
	)
	BEGIN	
		Select @ErrMsg = 'Error master ' + @Mastername + ': Master Position Taking of new master is less than Master Position Taking of old master.',
			@ErrCode = 206					 
		return
	END

	--Check Position Taking for 3rd Party
		--check m3_master_old <= m3_master_new

	if exists (
		select 1 from 
			custsetting3rd as mcs_old with (nolock)
			inner join custsetting3rd as mcs_new with (nolock) on mcs_old.sporttype=mcs_new.sporttype and mcs_old.bettype=mcs_new.bettype						
		where
			mcs_old.custid = @mrecommend_old and  mcs_new.custid = @mrecommend
			and (mcs_old.mpositiontaking > mcs_new.mpositiontaking
			or (mcs_old.bettype in (85,86,87,89,90) and mcs_old.sporttype =161 and mcs_old.mlivepositiontaking > mcs_new.mlivepositiontaking)
			)
	)
	BEGIN	
		Select @ErrMsg = 'Error master ' + @Mastername + ': Master Position Taking of new master is less than Master Position Taking of old master.',
			@ErrCode = 207					 
		return
	END

	--Check Position Taking for live casino
		--check m3_master_old <= m3_master_new
	
	IF @mSyncLiveCasino_Old = 1 AND @mSyncLiveCasino = 1 AND EXISTS(
			SELECT 1 
			FROM CustSettingGame mcs_old WITH(NOLOCK) 
				INNER JOIN CustSettingGame mcs_new WITH(NOLOCK) ON mcs_new.custid = @mrecommend AND mcs_new.sporttype = mcs_old.sporttype AND mcs_new.bettype = mcs_old.bettype
			WHERE mcs_old.custid = @mrecommend_old AND mcs_old.sporttype = 162 AND mcs_old.bettype = 1101
				AND mcs_old.mpositiontaking > mcs_new.mpositiontaking	
		)	
	BEGIN
		Select @ErrMsg = 'Error master ' + @Mastername + ': Master Position Taking of new master is less than Master Position Taking of old master.',
			@ErrCode = 208					 
		return
	END	
		--m2+a2<=m3		
		--check n3<=m2+a2<=l3 if im2 = 0, 
		--a2<=l3 and um2+a2>=n3 if im2 = 1
	if exists (
		select 1 from 
			custsetting as mcs with (nolock)
			inner join custsetting as acs with (nolock) on mcs.custid = @mrecommend and acs.custid = @recommend
															and mcs.sporttype=acs.sporttype and mcs.bettype=acs.bettype
			inner join custoverride as mco with (nolock) on mcs.custid = mco.custid and mcs.sporttype = mco.sporttype and mcs.bettype = mco.bettype
		where
		
		--m2+a2<=m3
		(
			(acs.mpositiontaking + acs.apositiontaking > mcs.mpositiontaking)
			or
			((mcs.sporttype =1) and (mcs.bettype in (1,3,7,8)) and (acs.mlivepositiontaking + acs.alivepositiontaking > mcs.mlivepositiontaking))
		)	
					
		--check n3<=m2+a2<=l3 if im2 = 0, 
		--a2<=l3 and um2+a2>=n3 if im2 = 1
		or
		(			
			((acs.isautompositiontaking = 0) and (acs.mpositiontaking + acs.apositiontaking > mco.maxpositiontaking or acs.mpositiontaking + acs.apositiontaking < mco.minpositiontaking))
			or 
			((acs.isautompositiontaking = 1) and (acs.apositiontaking > mco.maxpositiontaking or acs.autompositiontaking + acs.apositiontaking < mco.minpositiontaking))			
			or
			((mcs.sporttype =1) and (mcs.bettype in (1,3,7,8)) and (acs.isautolivempositiontaking = 0) and (acs.mlivepositiontaking + acs.alivepositiontaking > mco.maxlivepositiontaking or acs.mlivepositiontaking + acs.alivepositiontaking < mco.minlivepositiontaking))
			or 
			((mcs.sporttype =1) and (mcs.bettype in (1,3,7,8)) and (acs.isautolivempositiontaking = 1) and (acs.alivepositiontaking > mco.maxlivepositiontaking or acs.autolivempositiontaking + acs.alivepositiontaking < mco.minlivepositiontaking))
		)			
	)
	BEGIN	
		Select @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': Agent exceeded new master position taking.',
			@ErrCode = 209					 
		return
	END

		--Check for 3rd party
		--m2+a2<=m3	
		--check n3<=m2+a2<=l3 if im2 = 0, 
		--a2<=l3 and um2+a2>=n3 if im2 = 1
	if exists (
		select 1 from 
			custsetting3rd as mcs with (nolock)
			inner join custsetting3rd as acs with (nolock) on mcs.custid = @mrecommend and acs.custid = @recommend
															and mcs.sporttype=acs.sporttype and mcs.bettype=acs.bettype
			inner join custoverride3rd as mco with (nolock) on mcs.custid = mco.custid and mcs.sporttype = mco.sporttype and mcs.bettype = mco.bettype
		where
		--m2+a2<=m3
		(
			(acs.mpositiontaking + acs.apositiontaking > mcs.mpositiontaking)
			or
			((mcs.sporttype =161) and (mcs.bettype in (85,86,87,89,90)) and (acs.mlivepositiontaking + acs.alivepositiontaking > mcs.mlivepositiontaking))
		)			
		--check n3<=m2+a2<=l3 if im2 = 0, 
		--a2<=l3 and um2+a2>=n3 if im2 = 1
		or
		(
			((acs.isautompositiontaking = 0) and (acs.mpositiontaking + acs.apositiontaking > mco.maxpositiontaking or acs.mpositiontaking + acs.apositiontaking < mco.minpositiontaking))
			or 
			((acs.isautompositiontaking = 1) and (acs.apositiontaking > mco.maxpositiontaking or acs.autompositiontaking + acs.apositiontaking < mco.minpositiontaking))			
			or
			((mcs.sporttype =161) and (mcs.bettype in (85,86,87,89,90)) and (acs.isautolivempositiontaking = 0) and (acs.mlivepositiontaking + acs.alivepositiontaking > mco.maxlivepositiontaking or acs.mlivepositiontaking + acs.alivepositiontaking < mco.minlivepositiontaking))
			or 
			((mcs.sporttype =161) and (mcs.bettype in (85,86,87,89,90)) and (acs.isautolivempositiontaking = 1) and (acs.alivepositiontaking > mco.maxlivepositiontaking or acs.autolivempositiontaking + acs.alivepositiontaking < mco.minlivepositiontaking))
		)			
	)
	BEGIN	
		Select @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': Agent exceeded new master position taking.',
			@ErrCode = 210					 
		return
	END

		--Check for live casino
		--m2+a2<=m3
		--n3<= im = 0? m2+a2 : um2 + a2
	IF @aSyncLiveCasino = 1 AND @mSyncLiveCasino = 1 AND EXISTS(
			SELECT 1
			FROM CustSettingGame mcs WITH(NOLOCK) 
				INNER JOIN CustSettingGame acs WITH(NOLOCK) ON acs.custid = @recommend AND mcs.sporttype = acs.sporttype AND acs.bettype = mcs.bettype 
				INNER JOIN CustOverrideGame mco WITH(NOLOCK) ON mco.custid = @mrecommend AND mco.sporttype = mcs.sporttype AND mco.bettype = mcs.bettype
			WHERE mcs.custid = @mrecommend AND mcs.sporttype = 162 AND mcs.bettype = 1101			
				AND (-- m2+a2<=m3
					acs.mpositiontaking + acs.apositiontaking > mcs.mpositiontaking OR 
					--n3<=m2+a2
					(acs.isautompositiontaking = 0 AND acs.mpositiontaking + acs.apositiontaking < mco.minpositiontaking)
					OR
					(acs.isautompositiontaking = 1 AND acs.autompositiontaking + acs.apositiontaking < mco.minpositiontaking)
				)
		)
	BEGIN
		SELECT @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': Agent exceeded new master position taking.',
			@ErrCode = 211
		RETURN
	END
		
	--Check Position Taking	
		--all a2<=a4
		--all a1<=a4
	if exists (
			select 1 from 
				custsetting as scs with (nolock)
				inner join custsetting as acs with (nolock) on scs.custid = @srecommend  
																and scs.sporttype=acs.sporttype and scs.bettype=acs.bettype
				inner join customer as c with (nolock) on c.custid = acs.custid and c.roleid in (1,2) 
														and c.recommend = @recommend --get member and agent			
			where
			--all a<=a4
			(
				(acs.apositiontaking > scs.apositiontaking)
				or
				((acs.sporttype =1) and (acs.bettype in (1,3,7,8)) and (acs.alivepositiontaking > scs.alivepositiontaking))
			)
	)
	BEGIN	
		Select @ErrMsg = 'Error master ' + @Mastername + ', agent ' + @agentname + ': Agent or member exceeded new super position taking.',
			@ErrCode = 212					 

		return
	END

	--Check Position Taking	for 3rd party
		--all a2<=a4
		--all a1<=a4
	if exists (
			select 1 from 
				custsetting3rd as scs with (nolock)
				inner join custsetting3rd as acs with (nolock) on scs.custid = @srecommend  
																and scs.sporttype=acs.sporttype and scs.bettype=acs.bettype
				inner join customer as c with (nolock) on c.custid = acs.custid and c.roleid in (1,2) 
														and c.recommend = @recommend --get member and agent			
			where 
			(acs.apositiontaking > scs.apositiontaking)
			or
			((acs.sporttype =161) and (acs.bettype in (85,86,87,89,90)) and (acs.alivepositiontaking > scs.alivepositiontaking))
	)
	BEGIN	
		Select @ErrMsg = 'Error master ' + @Mastername + ', agent ' + @agentname + ': Agent or member exceeded new super position taking.',
			@ErrCode = 213				 

		return
	END

	--Check P2P :Game Comm
	IF exists(
		SELECT TOP 1 1
		FROM dbo.P2PGROUPCOMM m WITH(NOLOCK)
			INNER JOIN dbo.P2PGROUPCOMM a WITH(NOLOCK)
				ON a.GroupID = M.GroupID
			WHERE  m.custid = @mrecommend AND A.custid = @recommend
					AND (m.adiscount < a.discount )
	)
	BEGIN
		Select @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': P2P''s commission of agent is is greater than P2P''s commission of new master .',
			@ErrCode = 214
		return
	END
END

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerCheckMoveAgent] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerCheckMoveAgent] TO [vnteam] AS [dbo]