/*<info serverAlias="DBTXN-bodb02" executers="wsv_nap" isFunction="0" isNested="0"></info>*/
USE [bodb02]
GO

ALTER PROCEDURE [dbo].[Acc_BalanceMemberSelectAll]
	@Username	VARCHAR(30)
	,@UserID	INT
AS

/*
	Created:
	DB: DBTXN.bodb02
	Task: NAP Accounting - Admin - Compare Balance

	Revisions:
		- 20181122@Percy: Initialize SP [RedmineID: #105106]
		- 20210505@Sol: NAP - Alpha - Allow more time for transfer - [Redmine: #149927]
		- 20211122@Danny: Split transfer tickets out of bettrans [Redmine: #164196]
    	- 20230227@Evan: Balance-Up support transfer 247 [Redmine: #173554] 
		- 20240523@Tacy: NAP - Permission controls on real currency [redmineID: #202523]

*/

BEGIN
	SET NOCOUNT ON
	
	DECLARE
		@CustId INT
		,@TotalCash MONEY -- total cash
		,@OutStanding MONEY -- outstanding
		,@CreditSports MONEY, @DebitSports MONEY -- BalCreditSports/BalDebitSports
		,@CreditCasino MONEY, @DebitCasino MONEY -- BalCreditCasino/BalDebitCasino
		,@CreditOthers MONEY, @DebitOthers MONEY -- BalCreditOthers/BalDebitOthers
		,@CreditTransfer MONEY, @DebitTransfer MONEY -- BalCreditTransfer/BalDebitTransfer
		,@CreditNetPosition MONEY, @DebitNetPosition MONEY -- BalNetPosition (credit/debit)
		,@CreditBonusWallet MONEY, @DebitBonusWallet MONEY -- BonusWalletCredit/BonusWalletDebit

	----get movebetday
	DECLARE @balanceUpDay SMALLDATETIME, @moveBetsDay SMALLDATETIME
	DECLARE @tblMoveBetBalanceUp AS TABLE (BalanceUpDay SMALLDATETIME, MoveBetsDay SMALLDATETIME)

	INSERT INTO @tblMoveBetBalanceUp(BalanceUpDay,MoveBetsDay)
	EXEC bodb02.dbo.Age_SelBalanceUpDay
	
	SELECT @balanceUpDay = BalanceUpDay, @moveBetsDay = MoveBetsDay FROM @tblMoveBetBalanceUp

		DECLARE @tmp TABLE (siteid INT,site NVARCHAR(50), SpecialGroup TINYINT )
	DECLARE @tmpExchange TABLE (exchangeID INT, Currency NVARCHAR(50), OfferSite TINYINT)

	DECLARE @tmpUserid VARCHAR(50)
	
	SELECT @tmpUserid=CAST(@UserID AS VARCHAR(50))
	
	DECLARE @SearchQuery VARCHAR(1024), @SearchCurrency VARCHAR(1024)

	--get deny site
	SELECT @SearchQuery = 'SELECT * 
		FROM OPENQUERY(DBPOL, 
		''SELECT siteid, site, SpecialGroup FROM NAP_UserControl.dbo.f_GetDeniedSiteByUser ( ''''' + @tmpUserid + ''''')'')'

	INSERT INTO @tmp (siteid, site, SpecialGroup)
	EXECUTE(@SearchQuery)
	
	--get deny currency
    SELECT @SearchCurrency = 'SELECT * 
	FROM OPENQUERY(DBPOL, 
	''SELECT exchangeID, Currency, OfferSite FROM NAP_UserControl.dbo.f_GetDeniedCurrencyByUser ( ''''' + @tmpUserid + ''''')'')'

	INSERT INTO  @tmpExchange (exchangeID, Currency, OfferSite)
	EXECUTE(@SearchCurrency)

	SELECT @CustId = custid FROM CustDB.dbo.Customer c WITH (NOLOCK) 
	WHERE username = @Username AND roleId = 1
		AND c.Site NOT IN (SELECT Site FROM @tmp)
		AND c.currency NOT IN (SELECT exchangeID FROM @tmpExchange)

	IF @CustId IS NOT NULL
	BEGIN
		-- Net Position
		SELECT @CreditNetPosition = SUM(ISNULL(Credit, 0)), @DebitNetPosition = SUM(ISNULL(Debit, 0)) FROM dbo.BalNetPosition WITH (NOLOCK) WHERE CustID = @CustId
	
		-- Balance group tables
		SELECT @CreditSports		= SUM(ISNULL(Balance, 0)) FROM dbo.BalCreditSports		WITH (NOLOCK) WHERE CustID = @CustId
		SELECT @DebitSports			= SUM(ISNULL(Balance, 0)) FROM dbo.BalDebitSports		WITH (NOLOCK) WHERE CustID = @CustId
		SELECT @CreditCasino		= SUM(ISNULL(Balance, 0)) FROM dbo.BalCreditCasino		WITH (NOLOCK) WHERE CustID = @CustId
		SELECT @DebitCasino			= SUM(ISNULL(Balance, 0)) FROM dbo.BalDebitCasino		WITH (NOLOCK) WHERE CustID = @CustId
		SELECT @CreditOthers		= SUM(ISNULL(Balance, 0)) FROM dbo.BalCreditOthers		WITH (NOLOCK) WHERE CustID = @CustId
		SELECT @DebitOthers			= SUM(ISNULL(Balance, 0)) FROM dbo.BalDebitOthers		WITH (NOLOCK) WHERE CustID = @CustId
		SELECT @CreditTransfer		= SUM(ISNULL(Balance, 0)) FROM dbo.BalCreditTransfer	WITH (NOLOCK) WHERE CustID = @CustId
		SELECT @DebitTransfer		= SUM(ISNULL(Balance, 0)) FROM dbo.BalDebitTransfer		WITH (NOLOCK) WHERE CustID = @CustId
		SELECT @CreditBonusWallet	= SUM(ISNULL(Amount, 0))  FROM dbo.BonusWalletCredit	WITH (NOLOCK) WHERE CustID = @CustId
		SELECT @DebitBonusWallet	= SUM(ISNULL(Amount, 0))  FROM dbo.BonusWalletDebit		WITH (NOLOCK) WHERE CustID = @CustId

		-- Total cash of tickets (bettrans/translog/bettransRnG/bettransLC + Net Position)
		CREATE TABLE #BalanceInfo (winlostdate SMALLDATETIME, bettype INT, statusId TINYINT, winlost MONEY, actual_stake MONEY, playercomm MONEY)

		CREATE TABLE #SportBettype (bettype INT, refTable TINYINT)
		INSERT INTO #SportBettype (bettype, refTable)
		SELECT DISTINCT bettype, refTable FROM dbo.SportBettypeMatrix WITH (NOLOCK) WHERE RefTable <> 0

		DECLARE @yesterday SMALLDATETIME
		SELECT  @yesterday = DATEADD(DAY, -1, CONVERT(DATE, GETDATE()))
		
		-- bettrans
		INSERT INTO #BalanceInfo (winlostdate, bettype, statusId, winlost, actual_stake, playercomm)
		SELECT winlostdate, bettype, statusId, SUM(winlost), SUM(actual_stake), SUM(playercomm)
		FROM dbo.bettrans WITH (NOLOCK)
		WHERE 
			custid = @CustId
			AND winlostdate > @moveBetsDay
		GROUP BY winlostdate, bettype, statusId

		-- transfer
		INSERT INTO #BalanceInfo (winlostdate, bettype, statusId, winlost, actual_stake, playercomm)
		SELECT winlostdate, bettype, 131 AS statusId, SUM(winlost), SUM(actual_stake), SUM(playercomm) -- hard statusID for removing key lookup
		FROM dbo.transfer WITH (NOLOCK)
		WHERE 
			custid = @CustId AND
			1 = CASE WHEN bettype = 19999 AND winlostdate > @moveBetsDay THEN 0 --> new sum
					WHEN bettype = 20000 AND winlostdate > @balanceUpDay THEN 0 --> new bal
					WHEN winlostdate < @balanceUpDay THEN 0 --> old data
				ELSE 1 END
		GROUP BY winlostdate, bettype, statusId

		DELETE b
		FROM #BalanceInfo b
		WHERE EXISTS (SELECT 1 FROM #SportBettype s WHERE b.bettype = s.bettype AND s.refTable IN (1,2))
			AND b.winlostdate >= @yesterday

		DELETE b
		FROM #BalanceInfo b
		WHERE EXISTS (SELECT 1 FROM #SportBettype s WHERE b.bettype = s.bettype)
			AND b.statusId IN (0,1)

		DROP TABLE #SportBettype

			-- translog
		INSERT INTO #BalanceInfo (statusId, actual_stake)
		SELECT 0 AS statusId, SUM(actual_stake)
		FROM dbo.translog WITH (NOLOCK)
		WHERE custid = @CustId AND statusId IN (0,1)

			-- bettransRnG
		INSERT INTO #BalanceInfo (statusId, winlost, actual_stake, playercomm)
		SELECT statusId, SUM(winlost), SUM(actual_stake), SUM(playercomm)
		FROM dbo.bettransRnG WITH (NOLOCK)
		WHERE custid = @CustId
			AND (statusId IN (0,1) OR winlostdate >= @yesterday)
		GROUP BY statusId

			-- bettransLC
		INSERT INTO #BalanceInfo (statusId, winlost, actual_stake, playercomm)
		SELECT statusId, SUM(winlost), SUM(actual_stake), SUM(playercomm)
		FROM dbo.bettransLC WITH (NOLOCK)
		WHERE custid = @CustId
			AND (statusId IN (0,1) OR winlostdate >= @yesterday)
		GROUP BY statusId

		SELECT	@TotalCash		= SUM(CASE WHEN statusId IN (0,1) THEN 0 ELSE ISNULL(winlost, 0) - ISNULL(actual_stake, 0) + ISNULL(playercomm, 0) END)
				,@OutStanding	= SUM(CASE WHEN statusId IN (0,1) THEN ISNULL(actual_stake, 0) ELSE 0 END)
		FROM #BalanceInfo
		
		DROP TABLE #BalanceInfo
	END
	
	-- Return data
	SELECT
		@CustId				AS CustId
		,@Username			AS Username
		,@TotalCash			AS TotalCash
		,@OutStanding		AS OutStanding
		,@CreditSports		AS CreditSports
		,@DebitSports		AS DebitSports
		,@CreditCasino		AS CreditCasino
		,@DebitCasino		AS DebitCasino
		,@CreditOthers		AS CreditOthers
		,@DebitOthers		AS DebitOthers
		,@CreditTransfer	AS CreditTransfer
		,@DebitTransfer		AS DebitTransfer
		,@CreditNetPosition	AS CreditNetPosition
		,@DebitNetPosition	AS DebitNetPosition
		,@CreditBonusWallet	AS CreditBonusWallet
		,@DebitBonusWallet	AS DebitBonusWallet
	WHERE @CustId IS NOT NULL
END
GO