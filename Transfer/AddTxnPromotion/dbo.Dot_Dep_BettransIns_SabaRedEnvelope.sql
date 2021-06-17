/*<info serverAlias="DBTXN-bodb02" executers="Dot_Member" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE dbo.Dot_Dep_BettransIns_SabaRedEnvelope
	@CustID			INT
	, @ExtraInfo	VARCHAR(1000)	= NULL
	, @Amount		MONEY
	, @Bettype		INT				= 17004
	, @Betfrom		NVARCHAR(1)		= 'd'
	, @TransDesc	NVARCHAR(1000)	= ''
	, @Total		MONEY			= NULL
	, @TransID2		BIGINT			= NULL
	, @IP			NVARCHAR(15)	= ''
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
	, @LogInfo		VARCHAR(300)	= '' OUTPUT
AS
/*
	Created: 20210202@Sophia
	DB: DBTXN.bodb02
	Task: Insert bet ticket SabaRedEnvelope - bettype 17004 - offer Credit & Deposit [Redmine: #149923]

	Revisions:
		- 20210202@Sophia: Initialize SP [RedmineID: #149923]
		
	Example: 
			DECLARE 
				 @TransID 		BIGINT		 
				, @TransDate	DATETIME 
				, @RefNo 		BIGINT	 
				, @Balance      MONEY	 
				, @ErrCode 		INT		 
				, @ErrMsg 		NVARCHAR(200) 
				, @LogInfo		VARCHAR(300)

			EXEC Dot_Dep_BettransIns_SabaRedEnvelope
				@CustID			= 738486
				, @ExtraInfo	= NULL
				, @Amount		= 100
				, @Bettype		= 17004
				, @Betfrom		= 'd'   --- 'i' for credit , 'd' for deposit
				, @TransDesc	= ''
				, @Total		= NULL
				, @TransID2		= NULL
				, @IP			= ''
				, @Creator		= 8
				, @Ugroup		= ''
				, @Site			= ''
				------------------------------------------
				, @TransID 		= @TransID OUTPUT
				, @TransDate	= @TransDate OUTPUT
				, @RefNo 		= @RefNo OUTPUT
				, @Balance      = @Balance OUTPUT
				, @ErrCode 		= @ErrCode OUTPUT
				, @ErrMsg 		= @ErrMsg OUTPUT
				, @LogInfo		= @LogInfo OUTPUT
			  
			  SELECT  @TransID AS TransID, @TransDate AS TransDate, @RefNo AS RefNo, @Balance AS Balance, @ErrCode AS ErrCode, @ErrMsg AS ErrMsg, @LogInfo AS LogInfo
*/
BEGIN
	SET NOCOUNT ON

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
		, @betteam          NVARCHAR(10)
		, @stake			MONEY
		, @actual_stake		MONEY
		, @winlost			MONEY


	DECLARE @startTime		DATETIME		
		, @result			VARCHAR(50)
		, @doneinsert		DATETIME
		, @BetTime			DATETIME
		, @spname			VARCHAR(100)
        , @hostname			VARCHAR(100)
		

	--Check Account - offer Credit & Deposit
	SELECT @username	= ci.username
		, @currency		= ci.currency
		, @currencyName = e.currency
		, @actualrate	= e.actualrate
		, @mrecommend	= ci.mrecommend
		, @recommend	= ci.recommend
		, @srecommend	= ci.srecommend 
		, @roleid		= ci.roleid
	FROM CustDB.dbo.custinfo AS ci WITH (NOLOCK)
	INNER JOIN CustDB.dbo.exchange AS e WITH (NOLOCK)
		ON ci.currency = e.exchangeid
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
		, @spname		= OBJECT_NAME(@@PROCID)
        , @hostname		= HOST_NAME()
		, @logInfo		= ''


	IF (@username IS NULL 
		OR ISNULL(@roleid,0) <> 1 
	)
	BEGIN
		SELECT @ErrCode = 101
			,@ErrMsg		= N'Invalid member account with @CustID=' + CAST(ISNULL(@CustID,0) AS VARCHAR(10))

		GOTO FINISH
	END

	IF (ISNULL(@Amount,0) <= 0 -- Invalid Amount
		)
	BEGIN
		SELECT @ErrCode = 102
			 ,@ErrMsg		= N'Invalid Amount ' + CAST(@Amount AS VARCHAR(10))
		
		GOTO FINISH
	END

	BEGIN TRY
	
		-- GET balance before
		EXEC [dbo].[Dot_BalanceMemberSel]
			@custID		= @CustID
			, @balance	= @Balance OUTPUT			
			
		;
		WITH CTE_tempPromotionPrize AS 
		(
			SELECT @CustID AS CustId
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
			, CAST(@transdate AS DATE) AS winlostdate
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
		)
		INSERT INTO dbo.bettrans (
			custid, oddsid, oddsspread, hdp1, hdp2,
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
			balance, transid2,recommdate,betid,ruben,comstatus,betdaqid,ExtraInfo,WalletType,BonusID,RefCode
		) 
		SELECT 
			custid, oddsid, oddsspread, hdp1, hdp2,
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
			balance, transid2,recommdate,betid,ruben,comstatus,betdaqid,ExtraInfo,WalletType,BonusID,RefCode
		FROM CTE_tempPromotionPrize

		-- insert into bettrans
		SELECT @TransID = SCOPE_IDENTITY(), @doneinsert = CURRENT_TIMESTAMP

		-- update account balance
		EXEC dbo.Dot_BalanceCreditUpd @CustID = @CustID
			, @balance	= @Amount
			, @type		= 4 --others
			, @ErrCode	= @ErrCode OUTPUT
		IF (@ErrCode <> 0)
		BEGIN
			SELECT @ErrMsg = 'Insert balance credit failed.', @ErrCode = 109
				,@result = 'failed-balance'

			--Manually rollback bettrans
			DELETE dbo.bettrans WHERE transid = @TransID
				
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
				
		--Manually rollback bettrans
		DELETE dbo.bettrans WHERE transid = @TransID
				
		GOTO FINISH
	END CATCH

	------------------
	FINISH:
	------------------

	SELECT @logInfo = ISNULL(@result, '')	
				+ 'Insert Red Envelope Amount CustID = ' + CAST(@CustID AS VARCHAR(20)) 
				+ ', bettype:' +  cast(isnull( @bettype,0) as varchar(10)) 
				+ ', Amount:' + CONVERT(varchar(50),isnull(@Amount,0)) 
				+ ', transid:' +cast(isnull(@TransID,0) as varchar(20)) +';'	
				+ ', creatorid:' + cast(isnull(@creator,0) as varchar(10))
				+ ', (' + CAST(IsNull(DATEDIFF(millisecond, @StartTime, @doneinsert),0) as varchar(50)) + ':' + CAST(IsNull(DATEDIFF(millisecond, @StartTime, CURRENT_TIMESTAMP),0) as varchar(50)) + ' ms) '
	
	IF (@ErrCode <> 0)
	BEGIN
		SELECT @logInfo += N' . Error: ' + CAST(@ErrCode AS VARCHAR(10)) + '. ErrMessage: ' + @ErrMsg
	END

	-----------------Write Log Red Envelope ----------------------
	BEGIN TRY	
	
		EXEC dbo.WriteLog_UserLog @UserID = @CustID, @Doing = @LogInfo
	END TRY
	BEGIN CATCH
		-- IF write log error: not RETURN error code
	END CATCH

 
END
GO