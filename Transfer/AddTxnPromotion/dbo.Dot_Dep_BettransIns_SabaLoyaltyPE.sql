/*<info serverAlias="DBTXN-bodb02" executers="Dot_Member" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE dbo.Dot_Dep_BettransIns_SabaLoyaltyPE 
	@CustID			INT
	, @ExtraInfo	VARCHAR(1000)
	, @Amount		MONEY
	, @Bettype		INT				= 17003
	, @Betfrom		NVARCHAR(3)		= 'd'
	, @TransDesc	NVARCHAR(1000)	= ''
	, @Total		MONEY			= NULL
	, @TransID2		BIGINT			= NULL
	, @IP			VARCHAR(45)		= ''
	, @Creator		INT				= NULL
	, @Ugroup		NVARCHAR(12)	= ''
	, @Site			nvarchar(50)	= ''

	------------------------------------------
	, @TransID 		BIGINT			= 0 OUTPUT
	, @TransDate	DATETIME		= NULL OUTPUT
	, @RefNo 		BIGINT			= 0 OUTPUT
	, @Balance      MONEY			= NULL OUTPUT
	, @ErrCode 		INT				= 0 OUTPUT
	, @ErrMsg 		NVARCHAR(200)	= '' OUTPUT
AS
/*
	Created: 20200731@Sol
	DB: DBTXN.bodb02
	Task: 138216 - Deposit - Saba Loyalty Program - bettype 17003

	Revisions:
		- 20200731@Sol: Initialize SP [RedmineID: #138216]
		- 20211112@Sol: Support IPv6 - Phase 2 - [Redmine: #163963]
		- 20220721@Evan: Integrate new transid - [Redmine: #175640]
		- 20220724@Evan: Revise code rollback for scale-out [Redmine: #175297]
		- 20220924@Sophia: Fix SiteDBGroupID missing in bettrans [Redmine: #178163]
		- 20221226@Evan: Wait for in-house service (2ms) to sync new value of rollback ticket to centraldb [Redmine: #182003]
		- 20221010@Evan: Betfrom Length Extensions [Redmine: #178059]
						 Revise code using ExchangeDailyOanda to get actualrate

*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @Cust_SiteDBGroupID SMALLINT, @Server_SiteDBGroupID SMALLINT;
	DECLARE @SiteGroupInfo TABLE
	(	
		CustID INT,
		SiteDBGroupID SMALLINT,
		LinkedServerName  VARCHAR(512),
		ClientAccessName VARCHAR(512),
		AGIP VARCHAR (50)
	)
	INSERT INTO @SiteGroupInfo (SiteDBGroupID, LinkedServerName, ClientAccessName, AGIP)
	EXEC CustDB.dbo.Acc_SiteDBConfigSel @CustID = @CustID

	SELECT @Cust_SiteDBGroupID = SiteDBGroupID FROM @SiteGroupInfo
	SELECT @Server_SiteDBGroupID = dbo.f_Get_SiteDBGroupID()
	
	--Check the SiteDBGroupID of CustID and Server is match
	IF ISNULL(@Cust_SiteDBGroupID,-1) <> @Server_SiteDBGroupID
	BEGIN
		SELECT @ErrMsg = 'Executing on invalid server. Please check SiteDBGroupID information.', @ErrCode = 107	
		RETURN		
	END
	
	DECLARE @username		VARCHAR(50)
		, @currency			TINYINT
		, @currencyName		VARCHAR(5)
		, @actualrate		FLOAT
		, @mrecommend		INT
		, @recommend		INT
		, @srecommend		INT
		, @roleid			TINYINT
		, @sporttype		INT
		, @oddsID			INT
		, @odds             SMALLMONEY
		, @originalOdds		SMALLMONEY
		, @betteam          NVARCHAR(10)
		, @stake			MONEY
		, @actual_stake		MONEY
		, @winlost			MONEY


	DECLARE @startTime		DATETIME
		, @logInfo			NVARCHAR(MAX)
		, @insertData		NVARCHAR(4000)
		, @result			VARCHAR(50)
		, @doneinsert		DATETIME
		, @BetTime			DATETIME
		, @spname			VARCHAR(100)
        , @hostname			VARCHAR(100)
		, @WinlostDate		SMALLDATETIME
	
	SELECT @WinlostDate	= CAST(ISNULL(@transdate,CURRENT_TIMESTAMP) AS DATE);

	--Check Account
	SELECT @username	= ci.username
		, @currency		= ci.currency
		, @currencyName = e.currency
		, @actualrate	= ISNULL(edo.actualrate,e.actualrate)
		, @mrecommend	= ci.mrecommend
		, @recommend	= ci.recommend
		, @srecommend	= cs.custid --> check is deposit member
		, @roleid		= ci.roleid
	FROM CustDB.dbo.custinfo AS ci WITH (NOLOCK)
	INNER JOIN CustDB.dbo.exchange AS e WITH (NOLOCK)
		ON ci.currency = e.exchangeid
	LEFT JOIN CustDB.dbo.ExchangeDailyOanda AS edo WITH (NOLOCK)
		ON ci.currency = edo.exchangeid AND edo.ExchangeDate = @WinlostDate
	LEFT JOIN CustDB.dbo.Dep_CustSuper cs WITH(NOLOCK) 
		ON ci.srecommend = cs.custid
	WHERE ci.custid = @custid

	SELECT @TransDate	= CURRENT_TIMESTAMP
		, @TransID		= 0
		, @RefNo		= 100000000000
		, @sporttype	= 246
		, @oddsID		= 0
		, @odds			= 0
		, @stake		= 0
		, @actual_stake = 0
		, @winlost		= @Amount
		, @Creator		= ISNULL(@Creator, @CustID)


	SELECT @startTime	= CURRENT_TIMESTAMP
		, @result		= ''
		, @insertData	= ''
		, @spname		= OBJECT_NAME(@@PROCID)
        , @hostname		= HOST_NAME()
		, @logInfo		= ''


	IF (@username IS NULL 
		OR ISNULL(@roleid,0) <> 1 
		OR @srecommend IS NULL -- NOT member account
	)
	BEGIN
		SELECT @ErrCode = 101
			,@ErrMsg		= N'Invalid member account with @CustID=' + CAST(@CustID AS VARCHAR(10))

		GOTO FINISH
	END

	IF (ISNULL(@ExtraInfo,'') = ''
		OR ISNULL(@Amount,0) <= 0 -- Invalid promotion prize
	)
	BEGIN
		SELECT @ErrCode = 102
			,@ErrMsg		= N'Invalid promotion prize @ExtraInfo=' + ISNULL(@ExtraInfo,'NULL') + ',@Amount ' + CAST(@Amount AS VARCHAR(10))
		
		GOTO FINISH
	END
	---get new transid 
	EXEC Get_Bettrans_TransID @TransID = @TransId OUTPUT	
		
	BEGIN TRY
		;
		WITH CTE_tempPromotionPrize AS 
		(
			SELECT @TransId AS TransId
			, @CustID AS CustId
			, @username AS username
			, @currency AS currency
			, @currencyName AS currencyName
			, @actualrate AS actualrate
			, @actualrate AS virtualrate
			, @recommend AS recommend
			, @mrecommend AS  mrecommend
			, @srecommend AS srecommend
			, @oddsid AS oddsid
			, @odds AS odds
			, @Creator	AS creator
			, @ip AS [ip]
			, @Balance AS balance
			, @WinlostDate AS winlostdate
			, @transdate AS transdate
			, @bettype AS bettype
			, @sporttype AS matchid
			, @stake AS stake
			, @actual_stake AS actual_stake
			, @winlost AS winlost
			, @betteam AS betteam
			, @Betfrom AS betfrom
			, @TransDesc AS transdesc
			, @ExtraInfo AS ExtraInfo
			, @TransID2 AS transid2
			--------------------------
			
			, NULL AS oddsspread
			, 0 AS hdp1
			, 0 AS hdp2
			, 112 AS [statusID]
			, 'WON' AS [status]
			, 0 AS livehomescore
			, 0 AS liveawayscore
			, 0 AS liveindicator
			, @RefNo AS refno
			, 0 AS tpositiontaking
			, 0 AS apositiontaking
			, 0 AS mpositiontaking
			, 0 AS spositiontaking
			, 0 AS playerdiscount
			, 0 AS discount
			, 0 AS adiscount
			, 0 AS sdiscount
			, NULL AS SecAcceptFlag
			, NULL AS checktime
			, 0 AS playercomm
			, 0 AS comm
			, 0 AS acomm
			, 0 AS scomm
			, 0 AS awinlost
			, 0 AS mwinlost
			, 0 AS swinlost
			, NULL AS betcheck
			, NULL AS oddstype
			, NULL AS currency2
			, NULL AS recommdate
			, NULL AS betid
			, NULL AS statuswinlost
			, 1 AS modds
			, 1 AS ruben
			, 0 AS comstatus
			, NULL AS betdaqid
			, NULL AS WalletType
			, NULL AS BonusID
			, NULL AS RefCode
			, @Cust_SiteDBGroupID as SiteDBGroupID
		)
		INSERT INTO dbo.bettrans (
			TransId, custid, oddsid, oddsspread, hdp1, hdp2,
			bettype, currency, actual_stake, winlostdate, transdesc,
			odds, modds, stake, [status], [statusID], 
			livehomescore, liveawayscore, liveindicator, betfrom, betteam, creator, refno,
			tpositiontaking, apositiontaking, mpositiontaking, spositiontaking,
			playerdiscount, discount, adiscount, sdiscount,
			actualrate, virtualrate, SecAcceptFlag ,checktime,
			matchid, recommend, mrecommend, srecommend, 
			scomm, acomm, comm, playercomm,
			winlost,swinlost, mwinlost, awinlost,
			[ip], Username, CurrencyName, betcheck, oddstype,
			balance, transid2,recommdate,betid,ruben,comstatus,betdaqid,ExtraInfo,WalletType,BonusID,RefCode, RepUpdateTime, SiteDBGroupID
		) 
		SELECT 
			TransId, custid, oddsid, oddsspread, hdp1, hdp2,
			bettype, currency, actual_stake, winlostdate, transdesc,
			odds, modds, stake, [status], [statusID], 
			livehomescore, liveawayscore, liveindicator, betfrom, betteam, creator, refno,
			tpositiontaking, apositiontaking, mpositiontaking, spositiontaking,
			playerdiscount, discount, adiscount, sdiscount,
			actualrate, virtualrate, SecAcceptFlag ,checktime,
			matchid, recommend, mrecommend, srecommend, 
			scomm, acomm, comm, playercomm,
			winlost,swinlost, mwinlost, awinlost,
			[ip], Username, CurrencyName, betcheck, oddstype, 
			balance, transid2,recommdate,betid,ruben,comstatus,betdaqid,ExtraInfo,WalletType,BonusID,RefCode, SYSDATETIME(), SiteDBGroupID
		FROM CTE_tempPromotionPrize

		SELECT @doneinsert = CURRENT_TIMESTAMP

		SET @insertData= N' oddsid:' +  cast(isnull(@oddsid,0) as varchar(10)) 
                            + N' bettype:' +  cast(isnull( @bettype,0) as varchar(10)) 
                            + N' at ' + CONVERT(varchar(10),CAST(isnull(@odds,0) as float)) + '(' + @ugroup + ')'
                            + N' (org:' + CONVERT(varchar(10),CAST(isnull(@originalOdds,0) as float)) + ')'
                            + N' bet ' + CAST(ISNULL(@betteam,'') as nvarchar(10))
                            + N' stake:' + CONVERT(varchar(50),isnull(@stake,0)) 
                            + N' transid:' +cast(isnull(@TransID,0) as varchar(20)) +';'

		-- update account balance
		EXEC dbo.Dot_BalanceCreditUpd @CustID = @CustID
			, @balance	= @Amount
			, @type		= 4 --others
			, @ErrCode	= @ErrCode OUTPUT
		IF (@ErrCode <> 0)
		BEGIN
			SELECT @ErrMsg = 'Insert balance credit failed.', @ErrCode = 109
				,@result = 'failed-balance'

			WAITFOR DELAY '000:00:00.002' -- wait for in-house service

			--Manually rollback bettrans
			UPDATE dbo.bettrans WITH(ROWLOCK)
			SET custid = 0,
				srecommend = 0,
				mrecommend = 0,
				recommend = 0,
				ruben = 1,
				[status] = 'Completed',
				statusID = 131,
				winlost = 0,
				swinlost = 0,
				mwinlost = 0,
				awinlost = 0,
				actual_stake = 0,
				stake = 0,
				RepUpdateTime = SYSDATETIME()
			WHERE transid = @TransID
				
			GOTO FINISH
		END
		
		-- GET final total balance
		EXEC [dbo].[Dot_BalanceMemberSel]
			@custID		= @CustID
			, @balance	= @Balance OUTPUT
	END TRY
	BEGIN CATCH
		SELECT @ErrMsg = 'Insert transaction failed.', @ErrCode = 108
			,@result = 'failed-bet'
		
		WAITFOR DELAY '000:00:00.002' -- wait for in-house service
				
		--Manually rollback bettrans
		UPDATE dbo.bettrans WITH(ROWLOCK)
		SET custid = 0,
			srecommend = 0,
			mrecommend = 0,
			recommend = 0,
			ruben = 1,
			[status] = 'Completed',
			statusID = 131,
			winlost = 0,
			swinlost = 0,
			mwinlost = 0,
			awinlost = 0,
			actual_stake = 0,
			stake = 0,
			RepUpdateTime = SYSDATETIME()
		WHERE transid = @TransID
				
		GOTO FINISH
	END CATCH

	------------------
	FINISH:
	------------------

	SELECT @logInfo = ISNULL(@result, '')
            + N' ' + (select dbo.f_GetBetfromType(@betfrom)) 
            + N' betting custid:' + cast(isnull( @custid,0) as varchar(10))
            + N' insert bet' +  ISNULL(@insertData,'')
            + N' ip:' + cast(isnull(@IP,'x') as varchar(45)) 
            + N' NBC:' + CAST(IsNull(@balance - @actual_stake,0) as varchar(50)) 
            + N' NBT:' + CAST(isnull(@total,-1) as varchar(50)) 
            + N' (' + CAST(IsNull(DATEDIFF(millisecond, @StartTime, @doneinsert),0) as varchar(50)) + ':' + CAST(IsNull(DATEDIFF(millisecond, @StartTime, CURRENT_TIMESTAMP),0) as varchar(50)) + ' ms) ' + @site
            + N' creatorid:' + cast(isnull(@creator,0) as varchar(10))
            + N' (call ' + ISNULL(@spname, '--') + ' via ' + ISNULL(@hostname, '--') + ')'
            + N' transid2:' +cast(isnull(@transid2,0) as varchar(20))
            + N' BetTime:' +convert(varchar(23), isnull(@BetTime,CURRENT_TIMESTAMP), 121)
	
	IF (@ErrCode <> 0)
	BEGIN
		SELECT @logInfo += N' . Error: ' + CAST(@ErrCode AS VARCHAR(10)) + '. ErrMessage: ' + @ErrMsg
	END

	-----------------Write Log Promotion Prize----------------------
	BEGIN TRY
		DECLARE @LogData VARCHAR(300)

		SELECT @LogData = 
				'Insert promotion amount CustID = ' + CAST(@CustID AS VARCHAR(20)) 
				+ ', Bettype = ' + CAST(@Bettype AS VARCHAR(10)) 
				+ ', ExtraInfo = ' + @ExtraInfo
				+ ', Amount = ' + CAST(@Amount AS VARCHAR(20))
	
		EXEC dbo.WriteLog_UserLog @UserID = @CustID, @Doing = @LogData
	END TRY
	BEGIN CATCH
		-- IF write log error: not RETURN error code
	END CATCH

	-- RETURN loginfo to write log
	SELECT @logInfo AS LogInfo

END
GO