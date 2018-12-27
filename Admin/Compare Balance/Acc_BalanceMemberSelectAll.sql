/*<info serverAlias="DBTXN-bodb02" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
USE [bodb02]
GO

ALTER PROCEDURE [dbo].[Acc_BalanceMemberSelectAll]
	@Username NVARCHAR(50)
AS

/*
	Created:
	DB: DBTXN.bodb02
	Task: NAP Accounting - Admin - Compare Balance

	Revisions:
		- 20181122@Percy: Initialize SP [RedmineID: #105106]
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

	SELECT @CustId = custid FROM CustDB.dbo.custInfo WITH (NOLOCK) WHERE username = @Username AND roleId = 1

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
		WHERE custid = @CustId
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