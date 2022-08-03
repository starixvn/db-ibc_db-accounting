/*<info serverAlias="DBTXN-bodb02" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_LicenseeTransfer_Job]
	@MoveBetsDay		SMALLDATETIME,
	@TransferMonthDate	SMALLDATETIME = NULL,
	@ErrCode			INT = 0 OUTPUT,
	@ErrMsg				VARCHAR(4000) = '' OUTPUT
AS
/*
	Create: 20190712@Bobby
	Task: 112454 - NAP - Automate the Finance Transfer process for Licensee
	DB: DBTXN/bodb02

	Revisions:
		- 20190712@Bobby: Initialize [redmine: #112454]
		- 20190802@Bobby: Fix bug - update remark/transdesc [redmine: #118076]
		- 20190806@Bobby: Update Licensee last month transfer information [redmine: #118247]
		- 20210315@Sol: NAP - Enhance Manage Licensee Code to support change base currency of licensees - [Redmine: #151607]
		 
*/
BEGIN
	SET NOCOUNT ON	
	
	DECLARE @isCollection 			BIT = 0
		,@language					VARCHAR(2)= 'E'
		,@currentDate				DATETIME
		,@startMonthDate			DATE
		,@endMonthDate				DATE
		,@exchangeDate				SMALLDATETIME
		,@settingEnable				TINYINT = 1
		,@strLicInfo				VARCHAR(MAX)
		,@forexUsername				VARCHAR(50) = 'MYS-Forex G/(L)'
		,@exchangeIdMYR				INT = 2
		,@ignoreRunningDate			BIT	= 0
		,@newStatus					VARCHAR(10) = 'New'
		,@statusInProgress			VARCHAR(10) = 'InProgress'
		,@completedStatus			VARCHAR(10) = 'Completed'
		,@failedStatus				VARCHAR(10) = 'Failed'
		,@retryStatusAll			VARCHAR(100)
		,@newCount					INT = 0
		,@completedCount			INT = 0
		,@failedCount				INT = 0
		,@retryEnable				BIT = 0
		,@retryCount				INT = 0
		,@transferIDCount			INT
	
	CREATE TABLE #tempLicenseeTransfer(
		LicenseeName VARCHAR(50)
		, FromCustId INT
		, FromCurrency INT
		, ToCustID INT
		, ToCurrency INT
		, ToUsername VARCHAR(50)
		, FromAmount MONEY
		, FromExRate FLOAT
		, ToExRate FLOAT
		, ToAmount MONEY
		, [Status] VARCHAR(10) DEFAULT('New')
		, TransferEnable BIT
		, MonthDate SMALLDATETIME
		, TransferDate DATETIME
		, Error VARCHAR(200)
	)
	
	CREATE TABLE #transferExrate (FromCurrency INT, ToCurrency INT, ExRate FLOAT, IsSystem BIT)
	
	SELECT @ErrCode			= 0
		,@ErrMsg			= ''
		,@retryStatusAll	= 'New-Failed'
		,@currentDate		= CURRENT_TIMESTAMP
		,@TransferMonthDate	= ISNULL(@TransferMonthDate, DATEADD(MONTH, -1, @currentDate))
		,@startMonthDate	= CAST(CONVERT(VARCHAR(7), @TransferMonthDate, 111) + '/01' AS DATE)
		,@exchangeDate		= DATEADD(DAY, -1, DATEADD(MONTH, 1, @startMonthDate))
		,@endMonthDate		= CAST(@exchangeDate AS DATE)
		,@MoveBetsDay		= CAST(@MoveBetsDay AS DATE)
	
	IF @endMonthDate > @currentDate
	BEGIN
		SELECT @ErrCode		= 100
			, @ErrMsg		= 'The month has not closed.'
		RETURN
	END
	
	IF @MoveBetsDay IS NULL
	BEGIN
		SELECT @ErrCode		= 101
			, @ErrMsg		= 'The MoveBetDate param is required.'
		RETURN
	END
	
	-- Check validation on running date & existed monthly transfer
	--IF @ignoreRunningDate = 0
	--	AND EXISTS(
	--	SELECT 1 AS StatusCode
	--	WHERE DAY(@currentDate) NOT BETWEEN 5 AND 10
	--)
	--BEGIN
	--	SELECT @ErrCode		= 102
	--		, @ErrMsg		= 'The running date is invalid.'
	--	RETURN
	--END
	
	IF EXISTS(
			SELECT TOP 1 1 AS StatusCode
			FROM dbo.LicenseeTransferPool WITH(NOLOCK)
			WHERE MonthDate = @endMonthDate
			
			UNION ALL
			SELECT TOP 1 1 AS StatusCode
			FROM DBCUST.bodb_licensee.dbo.LicenseeTransferCode sc WITH(NOLOCK)
			WHERE LastMonthDate = @endMonthDate
				AND @TransferMonthDate BETWEEN sc.FromDate AND sc.ToDate
	)
	BEGIN
		-- COLLECT the last status for the month if any
		SELECT @completedCount = SUM (CASE WHEN [Status] = @completedStatus THEN 1 ELSE 0 END)
			,@failedCount = SUM (CASE WHEN [Status] = @failedStatus THEN 1 ELSE 0 END)
			,@newCount = SUM (CASE WHEN [Status] = @newStatus THEN 1 ELSE 0 END)
		FROM dbo.LicenseeTransferPool pol  WITH(NOLOCK)
		WHERE MonthDate = @endMonthDate 
		
		-- MARK the month as completed
		IF(@failedCount = 0 AND @newCount = 0)
		BEGIN
			SELECT @ErrCode		= 0
				, @ErrMsg		= ''
			RETURN 
		END

		-- CHECK for retry
		SELECT @retryEnable = 1
		WHERE @failedCount > 0 OR @newCount > 0
		
		IF (@retryEnable = 1)
		BEGIN
			SET @retryCount += 1
			GOTO START_TRANSFER
		END

		-- MARK the historical month as transferred
		SELECT @ErrCode		= 103
			, @ErrMsg		= 'The month has ready transferred.'
		RETURN
	END
	
	-- Load IBC's code setting
	INSERT INTO #tempLicenseeTransfer(
		LicenseeName
		, FromCustId
		, ToCustID
		, FromCurrency
		, ToCurrency
		, ToUsername
		, MonthDate
	)
	SELECT cs.[site] AS LicenseeName
		,cs.custid AS FromCustId
		,sc.CustID AS ToCustID
		,cs.currency AS FromCurrency
		,ci.currency AS ToCurrency
		,ci.username AS ToUsername
		,@endMonthDate AS MonthDate
	FROM DBCUST.bodb_licensee.dbo.LicenseeTransferCode sc WITH(NOLOCK)
		INNER JOIN CustDB.dbo.custInfo ci WITH(NOLOCK) ON sc.CustID = ci.CustID
		INNER JOIN CustDB.dbo.Dep_CustSuper cs WITH(NOLOCK) ON sc.LicenseeName = cs.[site]
	WHERE @TransferMonthDate BETWEEN sc.FromDate AND sc.ToDate
		AND cs.currency <> 20
	
	-- load exchange rate from system and oanda
	INSERT INTO #transferExrate (FromCurrency, ToCurrency, ExRate, IsSystem)
	SELECT DISTINCT FromCurrency, ToCurrency, ExRate, IsSystem
	FROM (
		-- load system exrate: FromCurrency to MYR
		SELECT ex.ExchangeId AS FromCurrency, @exchangeIdMYR AS ToCurrency, ex.actualrate AS ExRate --'MYR'
			, 1 AS IsSystem
		FROM CustDB.dbo.exchange ex WITH(NOLOCK)
		WHERE EXISTS(SELECT TOP 1 1 FROM #tempLicenseeTransfer code WHERE ex.ExchangeId = code.FromCurrency)
		
		UNION ALL
		-- load system exrate: ToCurrency to MYR
		SELECT ex.exchangeid AS FromCurrency, @exchangeIdMYR AS ToCurrency
			, ex.actualrate AS ExRate
			, 1 AS IsSystem
		FROM CustDB.dbo.exchange ex WITH(NOLOCK)
		WHERE EXISTS(SELECT TOP 1 1 FROM #tempLicenseeTransfer code WHERE ex.ExchangeId = code.ToCurrency)
		
		-- load oanda exrate - direct
		UNION ALL	
		SELECT code.FromCurrency, code.ToCurrency
			, CASE 
				WHEN code.FromCurrency = code.ToCurrency THEN 1
				WHEN se.Code = 'MYR' THEN ex.MYR
				WHEN se.Code = 'USD' THEN ex.USD
				WHEN se.Code = 'EUR' THEN ex.EUR
				WHEN se.Code = 'CNY' THEN ex.CNY
				WHEN se.Code = 'IDR' THEN ex.IDR
				WHEN se.Code = 'AUD' THEN ex.AUD
				WHEN se.Code = 'CHF' THEN ex.CHF
				WHEN se.Code = 'GBP' THEN ex.GBP
				WHEN se.Code = 'SGD' THEN ex.SGD
				WHEN se.Code = 'THB' THEN ex.THB
				WHEN se.Code = 'VND' THEN ex.VND
				WHEN se.Code = 'KRW' THEN ex.KRW
				WHEN se.Code = 'JPY' THEN ex.JPY
				WHEN se.Code = 'TWD' THEN ex.TWD
				WHEN se.Code = 'PHP' THEN ex.PHP
				ELSE 1 END AS ExRate
			, 0 AS IsSystem
		FROM CustDB.dbo.ExchangeDailyOanda ex WITH(NOLOCK)
			INNER JOIN #tempLicenseeTransfer code ON ex.ExchangeId = code.FromCurrency
			INNER JOIN CustDB.dbo.exchange se WITH(NOLOCK) ON code.ToCurrency = se.exchangeid
		WHERE exchangedate = @exchangeDate AND code.FromCurrency <> code.ToCurrency
	) AS ex
	
	-- Conver lic to receive company winloss
	SELECT @strLicInfo = CAST((
			SELECT DISTINCT LicenseeName AS '@l'
			FROM #tempLicenseeTransfer AS r
			FOR XML PATH('r'), ROOT('root'), TYPE
	) AS VARCHAR(MAX))
	
	-- collect company winloss
	DECLARE @batchNumber		INT = 50
		,@companyWinloss		VARCHAR(MAX)
		,@xmlCompanyWinloss		XML
	
	BEGIN TRY
		EXEC [dbo].[Acc_LicenseeTransfer_CompanyWinlossByBatch]
			@FromDate			= @startMonthDate
		   , @ToDate			= @endMonthDate
		   , @LicenseeInfo		= @strLicInfo
		   , @MoveBetsDay		= @MoveBetsDay
		   , @BatchNumber		= @batchNumber
		   , @CompanyWinloss	= @companyWinloss OUTPUT
	END TRY
	BEGIN CATCH
		SELECT @ErrCode		= 104
			, @ErrMsg		= 'Source: ' + ERROR_PROCEDURE() + '. Line:' + CAST(ERROR_LINE() AS VARCHAR(10)) + '. Message: ' + ERROR_MESSAGE()
								+ 'Command: '
								+ 'EXEC [dbo].[Acc_LicenseeTransfer_CompanyWinlossByBatch]'  + CHAR(13)
								+ '@FromDate			= '''+ CONVERT(VARCHAR(10), @startMonthDate, 111) + ''''  + CHAR(13)
								+ ',@ToDate			= '''+ CONVERT(VARCHAR(10), @endMonthDate, 111) +'''' + CHAR(13)
								+ ',@LicenseeInfo		= '''+ CAST(@strLicInfo AS VARCHAR(MAX)) +'''' + CHAR(13)
								+ ',@MoveBetsDay		= '''+ CONVERT(VARCHAR(10), @MoveBetsDay, 111) +'''' + CHAR(13)
								+ ',@BatchNumber		= '+ CAST(@batchNumber AS VARCHAR(10)) + CHAR(13)
								+ ',@CompanyWinloss	= @companyWinloss OUTPUT'
		RETURN
	END CATCH
	
	DECLARE @tempCompanyWinloss TABLE(custid int, amount money)
	SET @xmlCompanyWinloss = CONVERT(XML, @companyWinloss)	
	
	INSERT INTO @tempCompanyWinloss (custid, amount)
	SELECT DISTINCT custid, amount
	FROM (
		SELECT T.C.value('./@c', 'int') AS custid
			,T.C.value('./@a', 'money') AS amount
		FROM @xmlCompanyWinloss.nodes('/root/r') AS T(C)
	) AS lic
	
	IF ( @CompanyWinloss IS NULL 
		OR NOT EXISTS(
			SELECT TOP 1 1 FROM @tempCompanyWinloss WHERE amount <> 0
		)
	)
	BEGIN
		SELECT @ErrCode		= 105
			, @ErrMsg		= 'Licensee(s) transfer not found.'
		RETURN
	END
	
	-- Update from amount (LIC)
	UPDATE t
	SET FromAmount = wl.amount
		,TransferEnable = 1
	FROM #tempLicenseeTransfer t
	INNER JOIN @tempCompanyWinloss wl ON t.FromCustId = wl.custid
	WHERE wl.amount <> 0
	
	-- apply from exrate
	UPDATE t
	SET t.FromExRate = CASE 
		WHEN t.FromCurrency = t.ToCurrency THEN 1
		ELSE ISNULL(ex.ExRate, 1) END
	FROM #tempLicenseeTransfer t
		LEFT JOIN #transferExrate ex 
		ON t.FromCurrency = ex.FromCurrency and ex.IsSystem = 1
	where ex.ToCurrency = @exchangeIdMYR 
	
	-- apply to exrate
	UPDATE t
	SET t.ToExRate = CASE 
		WHEN t.FromCurrency = t.ToCurrency THEN 1
		ELSE ISNULL(ex.ExRate, 1) END
	FROM #tempLicenseeTransfer t
		LEFT JOIN #transferExrate ex 
		ON t.ToCurrency = ex.FromCurrency 
		AND ex.ToCurrency = @exchangeIdMYR 
		AND ex.IsSystem = 1
		
	-- update to amount (IBC)
	UPDATE t
	SET t.ToAmount = CASE 
		WHEN t.FromCurrency = t.ToCurrency THEN t.FromAmount
		ELSE t.FromAmount * ISNULL(ex.ExRate,1) END
	FROM #tempLicenseeTransfer t
		LEFT JOIN #transferExrate ex 
		ON t.FromCurrency = ex.FromCurrency 
		AND t.ToCurrency = ex.ToCurrency
		AND ex.IsSystem = 0
	
	-- process transfer pool
	IF OBJECT_ID(N'LicenseeTransferPool') IS NOT NULL
	BEGIN
		-- just keep the last transfer transactions
		DELETE dbo.LicenseeTransferPool

		-- keep all transfer transactions month by month
		--DELETE dbo.LicenseeTransferPool WHERE MonthDate = @endMonthDate
	END
		
	INSERT INTO dbo.LicenseeTransferPool (
		LicenseeName
		, FromCustId
		, FromCurrency
		, ToCustID
		, ToCurrency
		, ToUsername
		, FromAmount
		, FromExRate
		, ToExRate
		, ToAmount
		, [Status]
		, MonthDate)
	SELECT LicenseeName
		, FromCustId
		, FromCurrency
		, ToCustID
		, ToCurrency
		, ToUsername
		, FromAmount
		, FromExRate
		, ToExRate
		, ToAmount
		, [Status]
		, MonthDate
	FROM #tempLicenseeTransfer
	WHERE TransferEnable = 1
	ORDER BY LicenseeName, FromCustId, ToCustID
	
	DECLARE @directTransfer		BIT
		, @fromCustID			INT
		, @fromAmount			MONEY
		, @toCustId				INT
		, @toUsername			VARCHAR(50)
		, @toAmount				MONEY
		, @fromExRate			FLOAT
		, @toExRate				FLOAT
		, @autoRemark			VARCHAR(200) = ''
		, @licenseeName			VARCHAR(50)
		, @execCommand			VARCHAR(MAX)
		, @createrUserName		VARCHAR(30) = 'StarixIT'
		, @createrID			INT
	
	-- INIT transfer count for the month
	SELECT @transferIDCount = MIN(TransferID)
	FROM dbo.LicenseeTransferPool WITH(NOLOCK) 
	WHERE MonthDate = @endMonthDate	
	
	SELECT TOP(1) @createrID = custid
	FROM CustDB.dbo.custInfo WITH(NOLOCK) 
	WHERE username = @createrUserName

	START_TRANSFER:
	BEGIN TRY
		WHILE @retryCount <= 3
			AND EXISTS (SELECT TOP 1 1 
				FROM dbo.LicenseeTransferPool WITH(NOLOCK) 
				WHERE MonthDate = @endMonthDate	
					AND (
						(TransferID = @transferIDCount AND [Status] = @newStatus) 
						OR (@retryCount > 0 AND CHARINDEX([Status],@retryStatusAll) > 0) 
					)
		)
		BEGIN
						
			SELECT @ErrCode 		= 0
				,@ErrMsg 			= ''
				,@fromCustId		= 0
				,@toCustId			= 0
				,@fromAmount		= 0
				,@toAmount			= 0
				,@fromExRate		= 0
				,@toExRate			= 0
				,@autoRemark		= ''
				
			SELECT @directTransfer 	= CASE WHEN FromCurrency = ToCurrency THEN 1 ELSE 0 END
				,@fromCustId		= FromCustId
				,@fromAmount		= FromAmount
				,@toCustId			= ToCustID
				,@toAmount			= ToAmount
				,@toUsername		= ToUserName
				,@fromExRate		= FromExRate
				,@toExRate			= ToExRate
				,@licenseeName		= LicenseeName
				,@autoRemark		= CS.username + ' to ' + EX.Code + ' ' + LEFT(DATENAME(MM, @endMonthDate),3) + ' ' + CAST(YEAR(@endMonthDate) AS VARCHAR(4))
				
			FROM dbo.LicenseeTransferPool P WITH(NOLOCK)
				INNER JOIN CustDB.dbo.Dep_CustSuper CS WITH(NOLOCK) ON P.FromCustId = CS.custid
				INNER JOIN CustDB.dbo.exchange EX WITH(NOLOCK) ON P.ToCurrency = EX.exchangeid
			WHERE MonthDate = @endMonthDate	
					AND (
						(TransferID = @transferIDCount AND [Status] = @newStatus) 
						OR (@retryCount > 0 AND CHARINDEX([Status],@retryStatusAll) > 0) 
					)
			
			-- SET default creator
			SET @createrID = ISNULL(@createrID, @fromCustID)

			-- UPDATE InProgress
			UPDATE dbo.LicenseeTransferPool WITH(ROWLOCK, UPDLOCK)
			SET [Status] = @statusInProgress, MonthDate = @endMonthDate, TransferDate = @currentDate
			WHERE MonthDate = @endMonthDate	
				AND FromCustId = @fromCustID 
				AND ToCustID = @toCustId
			
			-- PROCESS transfer
			IF @directTransfer = 1
			BEGIN
				SET @execCommand = 'EXEC [dbo].[Acc_BettransInsTransfer]' + CHAR(13)
					+'@FromCustID		= ' + CAST(@fromCustID AS VARCHAR(10)) + CHAR(13)
					+',@ToUserName		= ''' + @toUserName + '''' + CHAR(13)
					+',@Amount			= ' + CAST(@toAmount AS VARCHAR(15)) + CHAR(13)
					+',@ExchangeRate	= 1' + CHAR(13)
					+',@Remark			= ''' + @autoRemark + '''' + CHAR(13)
					+',@UserID			= ' + CAST(@createrID AS VARCHAR(10)) + CHAR(13)
					+',@isCollection 	= ' + CAST(@isCollection AS VARCHAR(3)) + CHAR(13)
					+',@Language		= ''' + @language + '''' + CHAR(13)
					+',@ErrCode			= @ErrCode OUTPUT' + CHAR(13)
					+',@ErrMsg			= @ErrMsg OUTPUT'

				--SELECT @ErrCode = 199, @ErrMsg = 'Test retry direct transfer'
				--EXEC direct transfer
				EXEC [dbo].[Acc_BettransInsTransfer]
					@FromCustID		= @fromCustID
					,@ToUserName	= @toUserName 
					,@Amount		= @toAmount
					,@ExchangeRate	= 1
					,@Remark		= @autoRemark
					,@UserID		= @createrID
					,@isCollection 	= @isCollection
					,@Language		= @language
					,@ErrCode		= @ErrCode OUTPUT
					,@ErrMsg		= @ErrMsg OUTPUT


			END
			ELSE
			BEGIN
				SET @execCommand = 'EXEC [dbo].[Acc_BettransInsCrossTransfer]' + CHAR(13)
					+'@FromCustID		= ' + CAST(@fromCustID AS VARCHAR(10)) + CHAR(13)
					+',@ToCustID		= ' + CAST(@toCustId AS VARCHAR(10)) + CHAR(13)
					+',@FromAmount		= ' + CAST(@fromAmount AS VARCHAR(15)) + CHAR(13)
					+',@ToAmount		= ' + CAST(@toAmount AS VARCHAR(15)) + CHAR(13)
					+',@FromExRate		= ' + CAST(@fromExRate AS VARCHAR(10)) + CHAR(13)
					+',@ToExRate		= ' + CAST(@toExRate AS VARCHAR(10)) + CHAR(13)
					+',@ForexUsername	= ''' + @forexUsername + '''' + CHAR(13)
					+',@Remark			= ''' + @autoRemark + '''' + CHAR(13)
					+',@UserID			= ' + CAST(@createrID AS VARCHAR(10)) + CHAR(13)
					+',@isCollection 	= ' + CAST(@isCollection AS VARCHAR(3)) + CHAR(13)
					+',@Language		= ''' + @language + '''' + CHAR(13)
					+',@ErrCode			= @ErrCode OUTPUT' + CHAR(13)
					+',@ErrMsg			= @ErrMsg OUTPUT'

				--SELECT @ErrCode = 199, @ErrMsg = 'Test retry cross transfer'
				-- EXEC cross transfer
				EXEC [dbo].[Acc_BettransInsCrossTransfer]
					@FromCustID		= @fromCustID,
					@ToCustID		= @toCustId,
					@FromAmount		= @fromAmount,
					@ToAmount		= @toAmount,
					@FromExRate		= @fromExRate, 
					@ToExRate		= @toExRate,
					@ForexUsername	= @forexUsername,
					@Remark			= @autoRemark,
					@UserID			= @createrID, --custid of Admin
					@isCollection 	= @isCollection,
					@Language		= @language,
					@ErrCode		= @ErrCode OUTPUT,
					@ErrMsg			= @ErrMsg OUTPUT
			END
			
			-- FOR tracing
			--PRINT 'retry(' + CAST(@retryCount AS VARCHAR(10)) + ')->transferid(' + CAST(@transferIDCount AS VARCHAR(10)) +  ')->LIC(' + @licenseeName + ')->direct(' + CAST(@directTransfer AS VARCHAR(1)) + ')->from(' + CAST(@fromCustId AS VARCHAR(10)) + ')->to(' + CAST(@toCustId AS VARCHAR(10)) + ')->error(' + @ErrMsg + ')'
			
			-- INCREASE transferCount
			SET @transferIDCount += 1
				
			IF @ErrCode <> 0
			BEGIN
				SET @ErrMsg += ' Command: ' + @execCommand 
				-- UPDATE Failed
				UPDATE dbo.LicenseeTransferPool WITH(ROWLOCK, UPDLOCK)
				SET [Status] = @failedStatus, Error = @ErrMsg
				WHERE MonthDate = @endMonthDate	
					AND FromCustId = @fromCustID 
					AND ToCustID = @toCustId
				
				-- CHECK is running in the retry mode
				IF @retryEnable = 1 AND @retryCount > 0
					BREAK
				
				-- ENABLE retry mode
				SET @retryEnable = 1				
				-- jump to the next transfer
				CONTINUE;
			END
			ELSE
			BEGIN
				-- UPDATE completed
				UPDATE dbo.LicenseeTransferPool WITH(ROWLOCK, UPDLOCK)
				SET [Status] = @completedStatus, Error = NULL
				WHERE MonthDate = @endMonthDate	
					AND FromCustId = @fromCustID 
					AND ToCustID = @toCustId
			END
		END
	
	END TRY
	BEGIN CATCH
		SELECT @ErrCode		= 199
			, @ErrMsg		= 'Error: ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) 
							+ '. Source: ' + ERROR_PROCEDURE() 
							+ '. Line: ' + CAST(ERROR_LINE() AS VARCHAR(10)) 
							+ '. Message:' + ERROR_MESSAGE() 
							+ '. Retry: ' + CAST(@retryCount AS VARCHAR(3))
							+ '. Command: ' + @execCommand

		-- UPDATE error/exception
		UPDATE dbo.LicenseeTransferPool WITH(ROWLOCK, UPDLOCK)
		SET [Status] = @failedStatus, Error = @ErrMsg
		WHERE MonthDate = @endMonthDate	
				AND FromCustId = @fromCustID 
				AND ToCustID = @toCustId
				
		-- ENABLE retry mode
		SET @retryEnable = 1
	END CATCH
	
	-- CONTROL retry condition
	IF (@retryEnable = 1 AND @retryCount < 3)
	BEGIN
		SET @retryCount += 1	
		GOTO START_TRANSFER
	END

	-- update back to bodb_licensee
	DECLARE @strLicInfoCompleted VARCHAR(MAX)
	SELECT @strLicInfoCompleted = CAST((
			SELECT DISTINCT 
				LicenseeName AS '@l',
				ToCustID AS '@c',
				FromDate AS '@fd'
			FROM (
				SELECT pol.LicenseeName, pol.ToCustID, c.FromDate
					,SUM (CASE WHEN [Status] = @completedStatus THEN 1 ELSE 0 END) AS CompletedCount
					,SUM (CASE WHEN [Status] = @failedStatus THEN 1 ELSE 0 END) AS FailedCount
					,SUM (CASE WHEN [Status] = @newStatus THEN 1 ELSE 0 END) AS NewCount
				FROM dbo.LicenseeTransferPool pol WITH(NOLOCK)
					INNER JOIN DBCUST.bodb_licensee.dbo.LicenseeTransferCode c WITH(NOLOCK)
						ON c.LicenseeName = pol.LicenseeName AND pol.ToCustID = c.CustId 
							AND @TransferMonthDate BETWEEN c.FromDate AND c.ToDate
				WHERE MonthDate = @endMonthDate 
				GROUP BY pol.LicenseeName, pol.ToCustID, c.FromDate
			) AS r
			WHERE r.FailedCount = 0 AND r.NewCount = 0 -- ALL completed
			FOR XML PATH('r'), ROOT('root'), TYPE
	) AS VARCHAR(MAX))

	EXEC DBCUST.bodb_licensee.dbo.Acc_LicenseeTransfer_Update
		@LicenseeInfo		= @strLicInfoCompleted
		,@LastMonthDate		= @endMonthDate
		,@LastTransferDate	= @currentDate
		,@ErrCode			= @ErrCode OUTPUT
		,@ErrMsg			= @ErrMsg OUTPUT
	-- end update back to bodb_licensee

	-- cleanup
	DROP TABLE #transferExrate
	DROP TABLE #tempLicenseeTransfer
END
GO
