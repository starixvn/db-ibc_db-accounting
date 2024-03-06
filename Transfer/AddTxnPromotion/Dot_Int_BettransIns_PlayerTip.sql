/*<info serverAlias="DBTXN-bodb02" executers="Svc_Tig" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Dot_Int_BettransIns_PlayerTip 
	@CustID			INT
	, @Amount		MONEY
	, @Bettype		INT				= 8700
	, @TransDesc	NVARCHAR(1000)	= ''
	, @ExtraInfo	VARCHAR(1000)	= ''
	, @IP			VARCHAR(45)		 
	, @Betfrom		NVARCHAR(4)		 
	, @APositiontaking	SMALLMONEY		
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
	Created: 20240118@Evan
	DB: DBTXN.bodb02
	Task: Insert bet ticket Player Tips [RedmineID: #198951]
	User: API Licensee (No need to check balance for API Licensee Single Wallet)
	Revisions:
		- 20240118@Evan: Initialize SP [RedmineID: #198951]
		- 20240304@Eddie: Change "Dot_Member" to "Svc_Tig" account [Redmine: #201841]
*/

BEGIN 
	SET NOCOUNT ON
	
	DECLARE @Cust_SiteDBGroupID SMALLINT, @Server_SiteDBGroupID SMALLINT;
	DECLARE @APositiontakingFixed SMALLMONEY = 0.3;
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
	SELECT @ErrCode = 0, @ErrMsg = '' 
	
	--Check the SiteDBGroupID of CustID and Server is match
	IF ISNULL(@APositiontaking,0) <> @APositiontakingFixed
	BEGIN
		SELECT @ErrMsg = 'Invalid PT. The current PT setting is '+ CAST(@APositiontakingFixed AS VARCHAR(10)) , @ErrCode = 105
		RETURN		
	END
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
		, @betteam          NVARCHAR(10)
		, @awinlost			MONEY
		, @statusID			TINYINT
		, @status			NVARCHAR(10)


	DECLARE @startTime		DATETIME
		, @insertData		NVARCHAR(4000)
		, @result			VARCHAR(50)
		, @doneinsert		DATETIME
		, @spname			VARCHAR(100)
        , @hostname			VARCHAR(100)
        , @Creator			INT
        , @WinlostDate		SMALLDATETIME
	
	SELECT @TransDate	= CURRENT_TIMESTAMP
	SELECT @WinlostDate	= CAST(@transdate AS DATE);
	
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

	SELECT @TransID		= 0
		, @RefNo		= 100000000000
		, @sporttype	= 157
		, @awinlost		= @Amount * @APositiontaking
		, @statusID		= 113
		, @status		= 'LOSE'
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

	IF ISNULL(@Amount,0) <= 0
	BEGIN
		SELECT @ErrCode = 102
			 ,@ErrMsg		= N'Invalid Amount ' + CAST(@Amount AS VARCHAR(10))
		
		GOTO FINISH
	END

	---get new transid 
	EXEC Get_Bettrans_TransID @TransID = @TransId OUTPUT	
	
	BEGIN TRY

		;WITH CTE_tempPlayerTip AS 
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
			, 0 AS oddsid
			, 0 AS odds
			, @Creator	AS creator
			, @ip AS [ip]
			, @Balance AS balance
			, @WinlostDate AS winlostdate
			, @transdate AS transdate
			, @bettype AS bettype
			, @sporttype AS matchid
			, @Amount AS stake
			, @Amount AS actual_stake
			, 0 AS winlost
			, @betteam AS betteam 
			, @Betfrom AS betfrom
			, @TransDesc AS transdesc
			, @ExtraInfo AS ExtraInfo
			, NULL AS transid2
			--------------------------
			
			, NULL AS oddsspread
			, 0 AS hdp1
			, 0 AS hdp2
			, @statusID AS [statusID]
			, @status AS [status]
			, 0 AS livehomescore
			, 0 AS liveawayscore
			, 0 AS liveindicator
			, @RefNo AS refno
			, @APositiontaking AS tpositiontaking
			, @APositiontaking AS apositiontaking
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
			, @awinlost AS awinlost
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
			, @Cust_SiteDBGroupID AS SiteDBGroupID
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
		FROM CTE_tempPlayerTip

		SELECT @doneinsert = CURRENT_TIMESTAMP

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

	IF (@ErrCode <> 0)
	BEGIN
		SELECT @logInfo += N' . Error: ' + CAST(@ErrCode AS VARCHAR(10)) + '. ErrMessage: ' + @ErrMsg
	END
		
	SELECT @logInfo = ISNULL(@result, '')	
				+ 'Insert Player Tips CustID: ' + CAST(@CustID AS VARCHAR(20)) 
				+ ', Bettype:' +  cast(isnull( @bettype,0) as varchar(10)) 
				+ ', Amount:' + CONVERT(varchar(50),isnull(@Amount,0)) 
				+ ', Transid:' +cast(isnull(@TransID,0) as varchar(20)) +';'	
				+ ', Creatorid:' + cast(isnull(@creator,0) as varchar(10))
				+ ', (' + CAST(IsNull(DATEDIFF(millisecond, @StartTime, @doneinsert),0) as varchar(50)) + ':' + CAST(IsNull(DATEDIFF(millisecond, @StartTime, CURRENT_TIMESTAMP),0) as varchar(50)) + ' ms) '
				+ N' (call ' + ISNULL(@spname, '--') + ' via ' + ISNULL(@hostname, '--') + ')'
				+ N' BetTime:' +convert(varchar(23), CURRENT_TIMESTAMP, 121) 
	
	-----------------Write Log Player Tips
	DECLARE @LogData VARCHAR(1000)

	SELECT @LogData = 
			'Insert Player Tips = ' + CAST(@CustID AS VARCHAR(20)) 
			+ ', Bettype = ' + CAST(@Bettype AS VARCHAR(10)) 
			+ ', ExtraInfo = ' + @ExtraInfo
			+ ', Amount = ' + CAST(@Amount AS VARCHAR(20))
			+ ', APositiontaking = ' + CAST(@APositiontaking AS VARCHAR(10))	
			
	BEGIN TRY
	
		EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Transfer 
								@UserID		= @creator, 
								@FromCustID = @CustID, 
								@ToCustID	= 0, 
								@IP			= @IP, 
								@Doing		= @LogData 
	END TRY
	BEGIN CATCH
		-- IF write log error: not RETURN error code
		SELECT @LogData = @LogData + ' ErrMsg: ' + ERROR_MESSAGE()
			
		EXEC bodb_customerlog.dbo.WriteLog_UserLog_Transfer 
							@UserID		= @creator, 
							@FromCustID = @CustID, 
							@ToCustID	= 0, 
							@IP			= @IP, 
							@Doing		= @LogData
	END CATCH
END
GO