ALTER PROCEDURE [dbo].[Acc_CustomerCheckMoveMaster]
	@supername	VARCHAR(40),
	@mastername VARCHAR(40),
	@userid		INT,	
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(200) = '' OUTPUT
AS
/*
	Created: Johnson
	Date: 2012-04-03
	Task : Check moving a master to another super
	DB: DBAGE/bodb02
	
	Revisions:
				- 20120726@Kiwi: Only IT Admin performs the moving for financial accounts (INTERNAL super/master/agent).
				- 20120821@Dan: add virtual soccer, remove FI
				- 20130920@Elodie: Add constraint to avoid the insufficient Given Credit of any new super/master/agent being moving to.
				- 20131022@Elodie: Remove checking setting for Financial and Poker products [Redmine:#6480]
	Param's Explanation:
	• @ErrCode:
		= 0: Transaction recorded successfully.
		> 0: Specific Error.
		Max errorcode 210
	• @ErrMsg: Error description.
*/

BEGIN
	SET NOCOUNT ON

	declare @startRun datetime
	declare @endRun datetime
	declare @duration int
	set @startRun = getdate()

	
	DECLARE @srecommend			INT, 
			@mrecommend			INT,
			@srecommend_old		INT, 
			@scurrency			TINYINT, 
			@mcurrency			TINYINT,
			@sdisable151_31		BIT,-- @sdisableHR -> @sdisable151_31 
			@mDisable151_31		BIT,-- @mdisableHR -> @mDisable151_31 			
			@sSyncCasino		BIT,
			@mSyncCasino		BIT,
			@sSyncBingo			BIT,
			@mSyncBingo			BIT,
			@sSyncLiveCasino	BIT,
			@mSyncLiveCasino	BIT,
			@sIsInternal		BIT,
			@mIsInternal		BIT,
			@sDisableOutright	BIT,
			@mDisableOutright	BIT,
			@sDisableCasino		BIT,
			@mDisableCasino		BIT,
			@sDisableLiveCasino	BIT,
			@mDisableLiveCasino BIT,
			@mDisable151_41		BIT,-- @mDisableOpenTote -> @mDisable151_41
			@sDisable151_41		BIT,-- @sDisableOpenTote -> @sDisable151_41
			@mDisable151_51		BIT,
			@sDisable151_51		BIT,
			@mDisable152_41		BIT,
			@sDisable152_41		BIT,
			@mDisable152_51		BIT,
			@sDisable152_51		BIT,
			@mDisable153_51		BIT,
			@sDisable153_51		BIT,
			@sDisableNumber		BIT,
			@mDisableNumber		BIT,
			@sDisableBingo		BIT,
			@mDisableBingo		BIT,
			@sClosed			BIT,	
			@mClosed			BIT,
			@sSuspended			BIT,	
			@mSuspended			BIT,
			--@sMaxTransferP2P	MONEY,
			--@mMaxTransferP2P	MONEY,
			--@sIsAutoResetP2P	BIT,
			--@mIsAutoResetP2P	BIT,
			--@sDisableP2P		BIT, 
			--@mDisableP2P		BIT, 
			--@sDisableFunP2P		BIT,
			--@mDisableFunP2P		BIT,
			@sGivenCredit		MONEY,
			@mGivenCredit		MONEY,
			@sUsedCredit		MONEY,
			@sHideVirtualSports		BIT, 
			@mHideVirtualSports		BIT,
			@AdminUser          varchar (50)

	SELECT	@srecommend			= custid, 
			@scurrency			= currency, 
			@sdisable151_31		= DisableHorseracing, 			
			@sSyncCasino		= SyncCasino,
			@sSyncBingo			= SyncBingo,
			@sSyncLiveCasino	= SyncLiveCasino,
			@sDisableOutright	= DisableOutright,
			@sDisableCasino		= DisableCasino,
			@sDisableLiveCasino = DisableLiveCasino,
			@sDisable151_41		= DisableOpenTote ,
			@sDisable151_51		= Disable151_AU,
			@sDisable152_41		= Disable152_UK,
			@sDisable152_51		= Disable152_AU,
			@sDisable153_51		= Disable153_AU,
			@sDisableBingo		= DisableBingo,
			@sDisableNumber		= DisableNumber,
			@sClosed			= closed,
			@sSuspended			= reject,
			--@sMaxTransferP2P	= MaxTransferP2P, 
			--@sIsAutoResetP2P	= IsAutoResetP2P, 
			--@sDisableP2P		= DisableP2P, 
			--@sDisableFunP2P		= DisableFunP2P,
			@sGivenCredit		= credit,
			@sHideVirtualSports = HideVirtualSports 		
	FROM	custinfo WITH (NOLOCK) 
	WHERE	username = @supername AND roleid = 4

	SELECT	@mrecommend			= custid, 
			@srecommend_old		= srecommend, 
			@mcurrency			= currency, 
			@mDisable151_31		= DisableHorseracing, 			
			@mSyncCasino		= SyncCasino,
			@mSyncLiveCasino	= SyncLiveCasino,
			@mSyncBingo			= SyncBingo,
			@mDisableOutright	= DisableOutright,
			@mDisableCasino		= DisableCasino,
			@mDisableLiveCasino = DisableLiveCasino,
			@mDisable151_41		= DisableOpenTote,
			@mDisable151_51		= Disable151_AU,
			@mDisable152_41		= Disable152_UK,
			@mDisable152_51		= Disable152_AU,
			@mDisable153_51		= Disable153_AU,
			@mDisableBingo		= DisableBingo,
			@mDisableNumber		= DisableNumber,
			@mSuspended			= reject,
			@mClosed			= closed,
			--@mMaxTransferP2P	= MaxTransferP2P, 
			--@mIsAutoResetP2P	= IsAutoResetP2P, 
			--@mDisableP2P		= DisableP2P, 
			--@mDisableFunP2P		= DisableFunP2P,
			@mGivenCredit		= credit,
			@mHideVirtualSports = HideVirtualSports
	FROM	custinfo WITH (NOLOCK) 
	WHERE	username = @mastername AND roleid = 3

	-- 20130920@Elodie: Add constraint to avoid the insufficient Given Credit of any new super/master/agent being moving to.
	SELECT @sUsedCredit = sum(credit) FROM custinfo WITH(NOLOCK) WHERE roleid = 3 AND srecommend = @srecommend
	IF ISNULL(@sGivenCredit,0) - ISNULL(@sUsedCredit,0) < ISNULL(@mGivenCredit,0)
	BEGIN
		Select @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': New super credit is insufficient to move this master.',
			@ErrCode = 100			 
		return
	END
	
	IF ISNULL(@srecommend, 0) = 0
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': super not found.',
			@ErrCode = 101					 
		RETURN
	END

	IF ISNULL(@mrecommend, 0) = 0
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': master not found.',
			@ErrCode = 102					 	
		RETURN
	END

	IF ISNULL(@srecommend_old, 0) = @srecommend
	BEGIN
		SELECT @ErrMsg = 'The master '+ @mastername +' already belongs to super '+ @supername +'.',
			@ErrCode = 103					 
		RETURN
	END

	--Check an account disabled or not 
	EXEC dbo.Acc_CustomerSelCheckEnable @username = @mastername, @ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT 
	IF @ErrCode <>0		RETURN 

	EXEC dbo.Acc_CustomerSelCheckEnable @username = @supername, @ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT 
	IF @ErrCode <>0		RETURN 


	IF @scurrency <> @mcurrency
	BEGIN
		SELECT @ErrMsg = 'Currency of super and master does not match.',
			@ErrCode = 104					 
		RETURN
	END

	--Check Internal status
	SELECT @sIsInternal = IsInternal FROM CustSuper with (nolock) WHERE custid = @srecommend
	SELECT @mIsInternal = IsInternal FROM CustMaster with (nolock) WHERE custid = @mrecommend
	IF ISNULL(@sIsInternal, 0) = 1 AND ISNULL(@mIsInternal, 0) = 0
	BEGIN
		SELECT @ErrMsg = 'Error occurs. Cannot move normal(betting) master to new internal super.',
			@ErrCode = 105					 
		RETURN
	END
	
	--20120726@Kiwi: Only IT Admin performs the moving for financial accounts (INTERNAL super/master/agent).

	SELECT @AdminUser = username FROM custinfo WITH (NOLOCK) WHERE custid = @userid
	
	
	IF ((ISNULL(@sIsInternal, 0) = 1 AND ISNULL(@mIsInternal, 0) = 1 AND (@AdminUser NOT LIKE 'dba%') AND (@AdminUser NOT LIKE 'pgm%') AND (@AdminUser NOT IN ('vndbateam','vnQaTeam'))))
	BEGIN 
			SELECT @ErrMsg = N'This function is not allowed to perform the moving for financial accounts. Please contact IT@nexcel.vn for assistance. Thanks.', 
					@ErrCode = 119
			RETURN
	END
		
	-- check is closed
	IF @sClosed = 1
	BEGIN
		SELECT @ErrMsg = 'Error occurs. Cannot move to closed super.',
			@ErrCode = 106					 
		RETURN
	END

	--Check Horse status:
	IF @sdisable151_31 = 1 AND @mDisable151_31 = 0
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': master enabled SA Racing but new super not enabled SA Racing.',
			@ErrCode = 107					 
		RETURN
	END

	--Check OpenTote
	IF @sDisable151_41 = 1 AND @mDisable151_41 = 0
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': master enabled UK/IRish Racing but new super not enabled UK/IRish Racing.',
			@ErrCode = 108				 
		RETURN
	END

	--Check Horse Racing for AU Tote
	IF @sDisable151_51 = 1 AND @mDisable151_51 = 0
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': master enabled Aust Racing but new super not enabled Aust Racing.',
			@ErrCode = 109			 
		RETURN
	END

	--Check Greyhound for UK Tote
	IF @sDisable152_41 = 1 AND @mDisable152_41 = 0
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': master enabled UK Greyhound but new super not enabled UK Greyhound.',
			@ErrCode = 110		 
		RETURN
	END

	--Check Greyhound for AU Tote
	IF @sDisable152_51 = 1 AND @mDisable152_51 = 0
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': master is enabled Aust Greyhound but new super not enabled Aust Greyhound.',
			@ErrCode = 111			 
		RETURN
	END

	--Check Harness for AU Tote
	IF @sDisable153_51 = 1 AND @mDisable153_51 = 0
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': master enabled Aust Harness but new super not enabled Aust Harness.',
			@ErrCode = 112			 
		RETURN
	END

	--Check Casino sync:
	IF @sSyncCasino = 0 AND @mSyncCasino = 1
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': master is synchronized Casino but new super is not synchronized Casino.',
			@ErrCode = 114					 
		RETURN
	END
	/*
	--Check Casino enable status
	IF @sDisableCasino = 1 AND (@mDisableCasino = 0)
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': master is enable Casino but new super is not enable Casino.',
			@ErrCode = 115
		RETURN
	END
	*/
	--Check Bingo sync
	IF @sSyncBingo = 0 AND @mSyncBingo = 1
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': master is synchronized Bingo but new super is not synchronized Bingo',
			@ErrCode = 115				 
		RETURN
	END

	--Check Casino sync:
	IF @sSyncLiveCasino = 0 AND @mSyncLiveCasino = 1
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': master is synchronized Casino but new super is not synchronized Casino.',
			@ErrCode = 116					 
		RETURN
	END

	--Check Bingo & Number status:
	IF @sdisableBingo = 1 AND @mdisableBingo = 0
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': master is enabled Bingo but new super is not enabled Bingo.',
			@ErrCode = 117					 
		RETURN
	END


	IF @sdisableNumber = 1 AND @mdisableNumber = 0
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': master is enabled Number Game but new super is not enabled Number Game.',
			@ErrCode = 118
		RETURN
	END
	
	--Check Virtual sport enable status
	if @sHideVirtualSports = 1 and @mHideVirtualSports = 0
	BEGIN
		SELECT @ErrMsg = 'Master is offered Virtual Sports but new super is not offered Virtual Sports.',
			@ErrCode = 123					 
		return
	END	


	--Check Horse,  Casino sync status:
	--no need to check for Horse
	/*IF EXISTS(SELECT 1 FROM custsetting3rd WITH (NOLOCK) WHERE custid = @mrecommend AND sporttype = 151)
		AND NOT EXISTS(SELECT 1 FROM custsetting3rd WITH (NOLOCK) WHERE custid = @srecommend AND sporttype = 151)
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': super does not have Horse Racing setting.',
			@ErrCode = 110					 
		RETURN
	END*/
	
	--Check Number Game
	IF EXISTS(SELECT 1 FROM custsetting3rd WITH (NOLOCK) WHERE custid = @mrecommend AND sporttype = 161)
		AND NOT EXISTS(SELECT 1 FROM custsetting3rd WITH (NOLOCK) WHERE custid = @srecommend AND sporttype = 161)
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': super does not have Number Game setting.',
			@ErrCode = 201					 
		RETURN
	END

	--Check Casino Syn 
	--Remove check Casino Sync
	--if exists(select 1 from custinfo with (nolock) where custid = @mrecommend and SyncCasino = 1)
	--BEGIN
	--	Select @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': master is already Casino-synchronized.',
	--		@ErrCode = 112					 
	--	return
	--END

	IF EXISTS (
			SELECT 1 
			FROM custsetting AS scs WITH (NOLOCK)
				INNER JOIN custsetting AS mcs WITH (NOLOCK) ON scs.custid = @srecommend AND mcs.custid = @mrecommend 
															AND scs.sporttype=mcs.sporttype AND scs.bettype=mcs.bettype 
			WHERE 
				(scs.bettype IN (1,2,3,7,8) AND ((scs.groupa<mcs.groupa) OR (scs.groupb<mcs.groupb) 
				OR (scs.groupc<mcs.groupc) OR (scs.groupd<mcs.groupd)))
				OR (scs.bettype NOT IN (1,2,3,7,8) AND scs.sdiscount<mcs.adiscount)
		)
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': Super''s commission for Sportbook is less than master''s commission.',
			@ErrCode = 202					 
		RETURN
	END

	--check commission for 3rd party
	IF EXISTS (
			SELECT 1 
			FROM custsetting3rd AS scs WITH (NOLOCK)
				INNER JOIN custsetting3rd AS mcs WITH (NOLOCK) ON scs.custid = @srecommend AND mcs.custid = @mrecommend 
															AND scs.sporttype=mcs.sporttype AND scs.bettype=mcs.bettype 
			WHERE scs.sdiscount<mcs.adiscount AND scs.sporttype <> 201
		)
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': Super''s commission is less than master''s commission.',
			@ErrCode = 203				 
		RETURN
	END

	--Check commission for live casino 
	IF EXISTS(
			SELECT 1 
			FROM CustSettingGame AS scs WITH(NOLOCK)
				INNER JOIN CustSettingGame mcs WITH(NOLOCK) ON mcs.custid = @mrecommend AND scs.sporttype = mcs.sporttype AND scs.bettype = mcs.bettype
			WHERE scs.custid = @srecommend AND scs.sporttype = 162 AND scs.bettype = 1101
				 AND scs.sdiscount < mcs.adiscount
	)
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @mastername + ': Super''s commission for Live Casino is less than master''s commission.',
				@ErrCode = 204
		RETURN	
	END

	--Check Position Taking
		--n4<=s3+m3<=s4		if i3=0
		--m3<=s4 and u3<=s4	if i3=1
		--u3+m3>=n4 if i3=1
		--m3<=m4

	IF EXISTS (
			SELECT 1 FROM 
				custsetting AS scs WITH (NOLOCK)
				INNER JOIN custsetting AS mcs WITH (NOLOCK) ON scs.custid = @srecommend AND mcs.custid = @mrecommend
																AND scs.sporttype=mcs.sporttype AND scs.bettype=mcs.bettype
				INNER JOIN custoverride AS sco WITH (NOLOCK) ON scs.custid = sco.custid AND scs.sporttype = sco.sporttype AND scs.bettype = sco.bettype
			WHERE	
			--n4<=s3+m3<=s4	if i3=0
			(
				((mcs.isautopositiontaking=0) AND ((mcs.spositiontaking + mcs.mpositiontaking < sco.minpositiontaking) OR (mcs.spositiontaking + mcs.mpositiontaking > scs.spositiontaking)))
				OR
				((mcs.isautolivepositiontaking=0) AND (mcs.sporttype =1) AND (mcs.bettype IN (1,3,7,8)) AND ((mcs.slivepositiontaking + mcs.mlivepositiontaking < sco.minlivepositiontaking) OR (mcs.slivepositiontaking + mcs.mlivepositiontaking > scs.slivepositiontaking)))
			)
			--m3<=s4 and u3<=s4	if i3=1
			--u3+m3>=n4 if i3=1
			OR
			(
				((mcs.isautopositiontaking=1) AND ((mcs.mpositiontaking > scs.spositiontaking) OR (mcs.autopositiontaking > scs.spositiontaking) OR (mcs.autopositiontaking + mcs.mpositiontaking < sco.minpositiontaking)))
				OR
				((mcs.isautolivepositiontaking=1) AND (mcs.sporttype =1) AND (mcs.bettype IN (1,3,7,8)) AND ((mcs.mlivepositiontaking > scs.slivepositiontaking) OR (mcs.autolivepositiontaking > scs.slivepositiontaking) OR (mcs.autolivepositiontaking + mcs.mlivepositiontaking < sco.minlivepositiontaking)))
			)	
			--m3<=m4
			OR
			(
				(mcs.mpositiontaking > scs.mpositiontaking)
				OR
				((mcs.sporttype =1) AND (mcs.bettype IN (1,3,7,8)) AND (mcs.mlivepositiontaking > scs.mlivepositiontaking))
			)	
	)
	BEGIN
		
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': Master exceeded new super position taking.',
			@ErrCode = 205				 
		RETURN
	END

	--Check Position Taking for 3rd party
		--n4<=s3+m3<=s4		if i3=0
		--m3<=s4 and u3<=s4	if i3=1
		--u3+m3>=n4 if i3=1
		--m3<=m4

	IF EXISTS (
			SELECT 1 FROM 
				custsetting3rd AS scs WITH (NOLOCK)
				INNER JOIN custsetting3rd AS mcs WITH (NOLOCK) ON scs.custid = @srecommend AND mcs.custid = @mrecommend
																AND scs.sporttype=mcs.sporttype AND scs.bettype=mcs.bettype
				INNER JOIN custoverride3rd AS sco WITH (NOLOCK) ON scs.custid = sco.custid AND scs.sporttype = sco.sporttype AND scs.bettype = sco.bettype
			WHERE
			--n4<=s3+m3<=s4	if i3=0
			(
				(scs.sporttype <> 201 AND (mcs.isautopositiontaking=0) AND ((mcs.spositiontaking + mcs.mpositiontaking < sco.minpositiontaking) OR (mcs.spositiontaking + mcs.mpositiontaking > scs.spositiontaking)))
				OR
				((mcs.isautolivepositiontaking=0) AND (mcs.sporttype =161) AND (mcs.bettype IN (85,86,87,89,90)) AND ((mcs.slivepositiontaking + mcs.mlivepositiontaking < sco.minlivepositiontaking) OR (mcs.slivepositiontaking + mcs.mlivepositiontaking > scs.slivepositiontaking)))
			)
			--m3<=s4 and u3<=s4	if i3=1
			--u3+m3>=n4 if i3=1
			OR
			(
				(scs.sporttype <> 201 AND (mcs.isautopositiontaking=1) AND ((mcs.mpositiontaking > scs.spositiontaking) OR (mcs.autopositiontaking > scs.spositiontaking) OR (mcs.autopositiontaking + mcs.mpositiontaking < sco.minpositiontaking)))
				OR
				((mcs.isautolivepositiontaking=1) AND (mcs.sporttype =161) AND (mcs.bettype IN (85,86,87,89,90)) AND ((mcs.mlivepositiontaking > scs.slivepositiontaking) OR (mcs.autolivepositiontaking > scs.slivepositiontaking) OR (mcs.autolivepositiontaking + mcs.mlivepositiontaking < sco.minlivepositiontaking)))
			)	
			--m3<=m4
			OR
			(
				(mcs.mpositiontaking > scs.mpositiontaking AND scs.sporttype <> 201)
				OR
				((mcs.sporttype =161) AND (mcs.bettype IN (85,86,87,89,90)) AND (mcs.mlivepositiontaking > scs.mlivepositiontaking))
			)		
				
	)
	BEGIN
		
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': Master exceeded new super position taking.',
			@ErrCode = 206				 
		RETURN
	END

	--Check Position Taking for Live Casino
		--n4<=s3+m3<=s4		if i3=0
		--m3<=s4 and u3<=s4	if i3=1
		--u3+m3>=n4 if i3=1
	IF @mSyncLiveCasino = 1 AND @sSyncLiveCasino = 1 AND EXISTS (
		SELECT 1
		FROM CustSettingGame scs WITH(NOLOCK) 
			INNER JOIN CustSettingGame mcs WITH(NOLOCK) ON mcs.custid = @mrecommend AND mcs.sporttype = scs.sporttype AND mcs.bettype = scs.bettype 
			INNER JOIN CustOverrideGame sco WITH(NOLOCK) ON sco.custid = @srecommend AND sco.sporttype = scs.sporttype AND sco.bettype = scs.bettype
		WHERE scs.custid = @srecommend AND scs.sporttype = 162 AND scs.bettype = 1101	
		AND (
		--n4<=s3+m3<=s4	if i3=0
		(mcs.isautopositiontaking = 0 AND ((mcs.mpositiontaking + mcs.spositiontaking < sco.minpositiontaking) OR (mcs.mpositiontaking + mcs.spositiontaking > scs.spositiontaking)))
		OR --m3<=s4 and u3<=s4	if i3=1
		(mcs.isautopositiontaking = 1 AND (mcs.mpositiontaking > scs.spositiontaking OR mcs.autopositiontaking > scs.spositiontaking OR mcs.mpositiontaking + mcs.autopositiontaking < sco.minpositiontaking))	 
		)	
	)	
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': Master exceeded new super position taking.',
			@ErrCode = 207				 
		RETURN
	END

	--Check Position Taking	
		--all a2<=a4
		--all a1<=a4
	IF EXISTS (
			SELECT 1 FROM 
				custsetting AS scs WITH (NOLOCK)
				INNER JOIN custsetting AS acs WITH (NOLOCK) ON scs.custid = @srecommend  
																AND scs.sporttype=acs.sporttype AND scs.bettype=acs.bettype
				INNER JOIN customer AS c WITH (NOLOCK) ON c.custid = acs.custid AND c.roleid IN (1,2) 
														AND c.mrecommend = @mrecommend --get member and agent			
			WHERE
			--all a<=a4
			(
				(acs.apositiontaking > scs.apositiontaking)
				OR
				((acs.sporttype =1) AND (acs.bettype IN (1,3,7,8)) AND (acs.alivepositiontaking > scs.alivepositiontaking))
			)		
	)
	BEGIN
		
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': Agent or member of existing master exceeded new super position taking.',
			@ErrCode = 208				 
		RETURN
	END

	--Check Position Taking	for 3rd party
		--all a2<=a4
		--all a1<=a4
	IF EXISTS (
			SELECT 1 FROM 
				custsetting3rd AS scs WITH (NOLOCK)
				INNER JOIN custsetting3rd AS acs WITH (NOLOCK) ON scs.custid = @srecommend  
																AND scs.sporttype=acs.sporttype AND scs.bettype=acs.bettype
				INNER JOIN customer AS c WITH (NOLOCK) ON c.custid = acs.custid AND c.roleid IN (1,2) 
														AND c.mrecommend = @mrecommend --get member and agent			
			WHERE 
			(	(acs.apositiontaking > scs.apositiontaking AND scs.sporttype <> 201)
				OR
				((acs.sporttype =161) AND (acs.bettype IN (85,86,87,89,90)) AND (acs.alivepositiontaking > scs.alivepositiontaking))
			)
	)
	BEGIN
		
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': Agent or member of existing master exceeded new super position taking.',
			@ErrCode = 209					 
		RETURN
	END

	----Check P2P :Game Comm
	--IF exists(
	--	SELECT TOP 1 1
	--	FROM dbo.P2PGROUPCOMM s WITH(NOLOCK)
	--		INNER JOIN dbo.P2PGROUPCOMM m WITH(NOLOCK)
	--			ON m.GroupID = s.GroupID
	--		WHERE  s.custid = @srecommend AND m.custid = @mrecommend
	--				AND (s.sdiscount < m.adiscount )
	--)
	--BEGIN
	--	Select @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': P2P''s commission of master is greater than P2P''s commission of new super.',
	--		@ErrCode = 210
	--	return
	--END

END

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerCheckMoveMaster] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerCheckMoveMaster] TO [vnteam] AS [dbo]