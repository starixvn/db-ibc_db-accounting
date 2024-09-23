/*<info serverAlias="DBAGE-bodb02" executers="wsv_nap,wsv_alp,wsv_alpv,wsv_xnap" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerSelBalanceReward]
	@CustId INT,
	@RoleId	TINYINT = NULL,
	@RewardPending MONEY = NULL OUTPUT, 
	@RewardBalance MONEY = NULL OUTPUT,
	@RewardCurrency VARCHAR(10) = NULL OUTPUT,
	@MaxTransId BIGINT = NULL OUTPUT,
	@MinWinlostdate SMALLDATETIME = NULL OUTPUT
AS
/*
	Created by: 20240826@Bobby
	Task: 209633 - CreditReward - Select balance info
	DB: DBAGE.bodb02
	
	Revisions:
		- 20240826@Bobby: Init [Redmine: #209633]
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @roleIdCheck TINYINT;

	SELECT @roleIdCheck =  ISNULL(@roleId, 0);
	IF @roleIdCheck = 0
		SELECT TOP(1) @roleIdCheck = roleId FROM dbo.Customer c WITH(NOLOCK) WHERE custid = @CustId;

	SELECT 
		@RewardPending	= RewardPending, 
		@RewardBalance	= RewardBalance,
		@RewardCurrency = ISNULL(ex.Code, ''),
		@MaxTransId		= MaxTransId,
		@MinWinlostdate	= MinWinlostdate
	FROM (
		SELECT sw.CurrencyID,
			0,
			SUM(IIF((POWER(2, @roleIdCheck - 1) & ISNULL(sw.PaymentStatus, 0)) = 0, sw.Amount, 0)),
			MAX(sw.TransId), MIN(sw.WinlostDate)
		FROM dbo.SabaWalletTicket sw  WITH(NOLOCK)
		WHERE @roleIdCheck = 1
			AND sw.CustID = @custid
			AND sw.StatusId = 0 -- NOT completed
			AND sw.WalletID = 2
		GROUP BY sw.CurrencyID

		UNION ALL
		SELECT sw.CurrencyID,
			SUM(IIF((POWER(2, @roleIdCheck - 2) & ISNULL(sw.PaymentStatus, 0)) = 0, sw.Amount, 0)),
			SUM(IIF((POWER(2, @roleIdCheck - 1) & ISNULL(sw.PaymentStatus, 0)) = 0, sw.Amount, 0)),
			MAX(sw.TransId), MIN(sw.WinlostDate)
		FROM dbo.SabaWalletTicket sw  WITH(NOLOCK)
		WHERE @roleIdCheck = 2
			AND sw.recommend = @custid
			AND sw.WalletID = 2
		GROUP BY sw.CurrencyID

		UNION ALL
		SELECT sw.CurrencyID,
			SUM(IIF((POWER(2, @roleIdCheck - 2) & ISNULL(sw.PaymentStatus, 0)) = 0, sw.Amount, 0)),
			SUM(IIF((POWER(2, @roleIdCheck - 1) & ISNULL(sw.PaymentStatus, 0)) = 0, sw.Amount, 0)),
			MAX(sw.TransId), MIN(sw.WinlostDate)
		FROM dbo.SabaWalletTicket sw  WITH(NOLOCK)
		WHERE @roleIdCheck = 3
			AND sw.mrecommend = @custid
			AND sw.WalletID = 2
		GROUP BY sw.CurrencyID

		UNION ALL
		SELECT sw.CurrencyID,
			SUM(IIF((POWER(2, @roleIdCheck - 2) & ISNULL(sw.PaymentStatus, 0)) = 0, sw.Amount, 0)),
			SUM(IIF((POWER(2, @roleIdCheck - 1) & ISNULL(sw.PaymentStatus, 0)) = 0, sw.Amount, 0)),
			MAX(sw.TransId), MIN(sw.WinlostDate)
		FROM dbo.SabaWalletTicket sw  WITH(NOLOCK)
		WHERE @roleIdCheck = 4
			AND sw.srecommend = @custid
			AND sw.WalletID = 2
		GROUP BY sw.CurrencyID
	) AS sw (CurrencyID, RewardPending, RewardBalance, MaxTransId, MinWinlostdate)
	LEFT JOIN dbo.exchange ex on ex.ExchangeId = sw.CurrencyID
	;
END