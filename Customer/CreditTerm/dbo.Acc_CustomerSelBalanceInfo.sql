/*<info serverAlias="DBAGE-bodb02" executers="wsv_nap"  isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerSelBalanceInfo]
	@CustId		INT = NULL,
	@CustIdList	VARCHAR(MAX) = NULL,
	@MoveBetDay SMALLDATETIME = NULL,
	@BalanceUpDay SMALLDATETIME = NULL

AS
/*
	Creator: Percy
	Date: 2017-04-19
	DB: DBAGE.bodb02 
	Task: Get Balance Information of Customer(s)

	Revisions:
		- 20170419@Percy: Initialize SP [RedmineID: #72339]
		- 20180328@Percy: Missing insert bettransRnG [RedmineID: #92678]
		- 20190531@Sophia: Add YesterdayTotalBalance, YesterdayTotalBalance_RM, TotalBalance_RM [Redmine: #113650]
		- 20190910@Bobby: Implement headline - balance info [Redmine:119961]
		- 20210505@Sol: NAP - Alpha - Allow more time for transfer - [Redmine: #149927]
		- 20211122@Danny: Split transfer tickets out of bettrans [Redmine: #164196]
		- 20230227@Evan: Balance-Up support transfer 247 [Redmine: #173554]
		- 20230606@Lewis: Add 3rd Party Pending transfer column [Redmine: #188648]
		- 20231110@Bobby: Tuning perf - put index hint option [Redmine: #196544]
		- 20240314@Bobby: EC enhancement [Redmine: #202276]
		- 20240918@Bobby: SabaWallet - Reward Program [Redmine: #209191]

	Param's Explaination:
		- @CustId: single cust
		- @CustIdList: multiple cust
*/
BEGIN
	SET NOCOUNT ON

	DROP TABLE IF EXISTS #SportBettype
	DROP TABLE IF EXISTS #balanceInfo
	DROP TABLE IF EXISTS #CustInfo

	-- Get Balance Information --
	CREATE TABLE #balanceInfo (CustId INT, totalBalance MONEY, TotalBalance_RM MONEY, YesterdayTotalBalance MONEY, YesterdayTotalBalance_RM MONEY, PendingTransfer3rd MONEY, PendingTransfer3rd_RM MONEY
		, RewardPending MONEY, RewardPending_RM MONEY
		, RewardBalance MONEY, RewardBalance_RM MONEY
		, RewardCurrencyID INT
		, RewardMaxTransId BIGINT
	);

	CREATE TABLE #CustInfo (CustId INT PRIMARY KEY, RoleId TINYINT);

	INSERT INTO #CustInfo (CustId, RoleId)
	SELECT custid, roleid
	FROM dbo.custInfo WITH(NOLOCK)
	WHERE custid = @custID
		AND roleid < 5
	UNION 
	SELECT custid, roleid
	FROM dbo.custInfo c WITH(NOLOCK)
	WHERE EXISTS (SELECT TOP 1 1 FROM STRING_SPLIT(@CustIdList, ',')s WHERE c.custid = s.value)
		AND roleid < 5

	IF @@ROWCOUNT = 0 
		GOTO RS_OUTPUT;
	

	--TODO: Process balance info
	DECLARE @today SMALLDATETIME, @yesterday SMALLDATETIME
	SELECT  @today = CONVERT(DATE, GETDATE())
	SELECT  @yesterday = DATEADD(DAY, -1, @today)

	-- Get bettype --
	DECLARE @isTest BIT = 0
	SELECT  @isTest = dbo.f_CheckSPVersion(@@PROCID)
	
	CREATE TABLE #SportBettype (bettype INT, RefTable TINYINT)
	INSERT INTO #SportBettype (bettype, RefTable)
	SELECT bettype, RefTable FROM dbo.f_SportBettypeMatrix_Sel (0, 0, 0, 2, '', '', @isTest)
	WHERE RefTable IN (1,2) ---- Bettype of BettransRNG, BettransLC

	-- get move bet date
	DECLARE @BUDay SMALLDATETIME, @moveBetsDay SMALLDATETIME

	IF (@MoveBetDay IS NULL OR @BalanceUpDay IS NULL)
	BEGIN
		EXEC dbo.NAP_Admin_GetMovebetDate @MovebetDate = @moveBetsDay OUTPUT
		EXEC dbo.NAP_Admin_GetBalanceUpDate @BalanceUpDate = @BUDay OUTPUT
	END
	ELSE
	BEGIN
		SELECT @moveBetsDay = @MoveBetDay
		SELECT @BUDay = @BalanceUpDay
	END

	-- member
	IF EXISTS (SELECT TOP 1 1 FROM #CustInfo WHERE RoleId = 1)
	BEGIN
		-- bettrans
		INSERT INTO #balanceInfo (CustId, totalBalance, TotalBalance_RM, YesterdayTotalBalance, YesterdayTotalBalance_RM)
		SELECT
			CustId,
			SUM(winlost-actual_stake+playercomm) AS totalBalance,
			SUM((winlost-actual_stake+playercomm) * ActualRate) AS TotalBalance_RM, 
			SUM(CASE WHEN (winlostdate <= @yesterday) THEN winlost-actual_stake+playercomm ELSE 0 END) AS YesterdayTotalBalance, 
			SUM((CASE WHEN (winlostdate <= @yesterday) THEN winlost-actual_stake+playercomm ELSE 0 END) * ActualRate) AS YesterdayTotalBalance_RM
		FROM dbo.bettrans b WITH(NOLOCK) 
		WHERE EXISTS (SELECT TOP 1 1 FROM #CustInfo c WHERE b.custid = c.CustId AND c.RoleId = 1)
			AND (
				b.winlostdate < @yesterday
				OR NOT EXISTS (SELECT 1 FROM #SportBettype s WHERE s.Bettype = b.bettype)  -- exclude  bettype of bettransRNG and bettransLC
				)
			AND b.statusID IN (111, 112, 113)
			AND b.winlostdate > @moveBetsDay
		GROUP BY CustId

		-- transfer
		INSERT INTO #balanceInfo (CustId, totalBalance, TotalBalance_RM, YesterdayTotalBalance, YesterdayTotalBalance_RM,PendingTransfer3rd, PendingTransfer3rd_RM)
		SELECT
			CustId,
			SUM(CASE WHEN b.Bettype IN (21008,21009) THEN 0 
						ELSE winlost-actual_stake+playercomm 
					 END ) AS totalBalance,
			SUM(CASE WHEN b.Bettype IN (21008,21009) THEN 0 
						ELSE (winlost-actual_stake+playercomm) * ActualRate 
					 END) AS TotalBalance_RM, 
			SUM(CASE WHEN b.Bettype IN (21008,21009) THEN 0 
						ELSE winlost-actual_stake+playercomm 
					 END) AS YesterdayTotalBalance, 
			SUM(CASE WHEN b.Bettype IN (21008,21009) THEN 0 
						ELSE (winlost-actual_stake+playercomm) * ActualRate 
					 END) AS YesterdayTotalBalance_RM,
			SUM(CASE WHEN b.Bettype IN (21008,21009) THEN -(winlost-actual_stake) 
						ELSE 0 
					 END) AS PendingTransfer3rd,
			SUM(CASE WHEN b.Bettype IN (21008,21009) THEN -(winlost-actual_stake) * b.ActualRate
						ELSE 0 
					 END) AS PendingTransfer3rd_RM
		FROM dbo.transfer b WITH(NOLOCK) 
		WHERE EXISTS (SELECT TOP 1 1 FROM #CustInfo c WHERE b.custid = c.CustId AND c.RoleId = 1)		
			  AND 1 = CASE WHEN bettype = 19999 AND winlostdate > @moveBetsDay THEN 0 --> new sum
                        WHEN bettype = 20000 AND winlostdate > @BUDay THEN 0 --> new bal
                        WHEN winlostdate < @BUDay THEN 0 --> old data
                    ELSE 1 END
		GROUP BY CustId

		-- bettransRnG
		INSERT INTO #balanceInfo (CustId, totalBalance, TotalBalance_RM, YesterdayTotalBalance, YesterdayTotalBalance_RM)
		SELECT
			CustId,
			SUM(winlost-actual_stake+playercomm) totalBalance,
			SUM((winlost-actual_stake+playercomm) * ActualRate) AS TotalBalance_RM,
			SUM(CASE WHEN winlostdate = @yesterday THEN winlost-actual_stake+playercomm ELSE 0 END) AS YesterdayTotalBalance,
			SUM((CASE WHEN winlostdate = @yesterday THEN winlost-actual_stake+playercomm ELSE 0 END) * ActualRate) AS YesterdayTotalBalance_RM
		FROM dbo.bettransRnG b WITH(NOLOCK)
		WHERE EXISTS (SELECT TOP 1 1 FROM #CustInfo c WHERE b.custid = c.CustId AND c.RoleId = 1)
			AND statusID IN (111, 112, 113)
			AND winlostdate >= @yesterday
		GROUP BY CustId

		-- bettransLC
		INSERT INTO #balanceInfo (CustId, totalBalance, TotalBalance_RM, YesterdayTotalBalance, YesterdayTotalBalance_RM)
		SELECT
			CustId,
			SUM(winlost-actual_stake+playercomm) totalBalance,
			SUM((winlost-actual_stake+playercomm) * ActualRate) AS TotalBalance_RM,
			SUM(CASE WHEN winlostdate = @yesterday THEN winlost-actual_stake+playercomm ELSE 0 END) AS YesterdayTotalBalance,
			SUM((CASE WHEN winlostdate = @yesterday THEN winlost-actual_stake+playercomm ELSE 0 END) * ActualRate) AS YesterdayTotalBalance_RM
		FROM dbo.bettransLC b WITH(NOLOCK)
		WHERE EXISTS (SELECT TOP 1 1 FROM #CustInfo c WHERE b.custid = c.CustId AND c.RoleId = 1)
			AND statusID IN (111, 112, 113)
			AND winlostdate >= @yesterday
		GROUP BY CustId
		;

		--TODO: SabaWallet
		INSERT INTO #balanceInfo (CustId, RewardPending, RewardPending_RM, RewardBalance, RewardBalance_RM, RewardCurrencyID, RewardMaxTransId)
		SELECT c.CustId, 0 AS RewardPending, 0 AS RewardPending_RM,
			SUM(sw.Amount) AS RewardBalance, SUM(sw.Amount*sw.ActualRate) AS RewardBalance_RM,
			sw.CurrencyID, MAX(sw.TransId) AS RewardMaxTransId
		FROM dbo.SabaWalletTicket sw  WITH(NOLOCK)
			INNER JOIN #CustInfo c ON sw.custid = c.CustId AND c.RoleId = 1
		WHERE (POWER(2, c.RoleId - 1) & ISNULL(sw.PaymentStatus, 0)) = 0 -- bit0
			AND sw.StatusId = 0 -- NOT completed
			AND sw.WalletID = 2
		GROUP BY c.CustId, sw.CurrencyID
		;
	END
	-- agent
	IF EXISTS (SELECT TOP 1 1 FROM #CustInfo WHERE RoleId = 2)
	BEGIN
		-- transfer
		INSERT INTO #balanceInfo (CustId, TotalBalance, TotalBalance_RM, YesterdayTotalBalance, YesterdayTotalBalance_RM,PendingTransfer3rd, PendingTransfer3rd_RM)
		SELECT
			recommend,			
			SUM(CASE WHEN b.Bettype IN (21008,21009) THEN 0
						ELSE (CASE WHEN b.custid = b.recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END) + (CASE WHEN b.custid <> b.recommend THEN winlost-actual_stake+playercomm ELSE 0 END)
					 END) TotalBalance,
			
			SUM (CASE WHEN b.Bettype IN (21008,21009) THEN 0
						ELSE ((CASE WHEN b.custid = b.recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END) + (CASE WHEN b.custid <> b.recommend THEN winlost-actual_stake+playercomm ELSE 0 END)) * ActualRate
					  END) TotalBalance_RM,
			
			SUM(CASE WHEN b.Bettype IN (21008, 21009) THEN 0 
						ELSE ((CASE WHEN b.custid = b.recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END) + (CASE WHEN b.custid <> b.recommend THEN winlost-actual_stake+playercomm ELSE 0 END)) 
					 END) YesterdayTotalBalance,
			
			SUM(CASE WHEN b.Bettype IN (21008, 21009) THEN 0 
						ELSE (((CASE WHEN b.custid = b.recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END) + (CASE WHEN b.custid <> b.recommend THEN winlost-actual_stake+playercomm ELSE 0 END)) * ActualRate) 
					 END) YesterdayTotalBalance_RM,
					 
			SUM(CASE WHEN b.Bettype IN (21008, 21009) THEN -(b.Winlost - b.Actual_Stake) 
						ELSE 0 END) AS PendingTransfer3rd,
								 
			SUM(CASE WHEN b.Bettype IN (21008, 21009) THEN -(b.Winlost - b.Actual_Stake) * b.ActualRate
						ELSE 0 END) AS PendingTransfer3rd_RM

		FROM dbo.transfer b WITH(NOLOCK)			
		WHERE EXISTS (SELECT TOP 1 1 FROM #CustInfo c WHERE b.recommend = c.CustId AND c.RoleId = 2)
			AND 1 = CASE WHEN bettype = 19999 AND winlostdate > @moveBetsDay THEN 0 --> new sum
                        WHEN bettype = 20000 AND winlostdate > @BUDay THEN 0 --> new bal
                        WHEN winlostdate < @BUDay THEN 0 --> old data
                    ELSE 1 END
		GROUP BY recommend
			
		--bettrans	
		;WITH Bettrans_CTE AS (
			SELECT 
				recommend, Winlostdate, Bettype,				
				SUM(awinlost+comm + winlost-actual_stake) AS TotalBalance,
				SUM((awinlost+comm + winlost-actual_stake) * ActualRate) AS TotalBalance_RM,
				SUM(CASE WHEN (winlostdate <= @yesterday) THEN awinlost+comm + winlost-actual_stake ELSE 0 END) AS YesterdayTotalBalance,
				SUM(CASE WHEN (winlostdate <= @yesterday) THEN awinlost+comm + winlost-actual_stake ELSE 0 END * ActualRate) AS YesterdayTotalBalance_RM					
			FROM dbo.bettrans b WITH (NOLOCK)    
			WHERE EXISTS (SELECT TOP 1 1 FROM #CustInfo c WHERE b.recommend = c.CustId AND c.RoleId = 2)
				AND b.statusID IN (111, 112, 113)
				AND b.winlostdate > @moveBetsDay
			GROUP BY recommend, Winlostdate, Bettype
			)
		INSERT INTO #balanceInfo (CustId, TotalBalance, TotalBalance_RM, YesterdayTotalBalance, YesterdayTotalBalance_RM)
		SELECT  recommend,
				SUM (TotalBalance) AS TotalBalance,
				SUM (TotalBalance_RM) AS TotalBalance_RM,
				SUM (YesterdayTotalBalance) AS YesterdayTotalBalance,
				SUM (YesterdayTotalBalance_RM) AS YesterdayTotalBalance_RM
		FROM Bettrans_CTE b
		WHERE b.Winlostdate < @yesterday OR NOT EXISTS (SELECT 1 FROM #SportBettype s WHERE s.Bettype = b.bettype)  -- exclude  bettype of bettransRNG and bettransLC
		GROUP BY recommend

		-- bettransRnG
		INSERT INTO #balanceInfo (CustId, totalBalance, TotalBalance_RM, YesterdayTotalBalance, YesterdayTotalBalance_RM)
		SELECT
			recommend,
			SUM((awinlost+comm-playercomm)+ (winlost-actual_stake+playercomm)) as totalBalance,			
			SUM(((awinlost+comm-playercomm)+ (winlost-actual_stake+playercomm))* ActualRate) as TotalBalance_RM, 
			SUM(CASE WHEN winlostdate = @yesterday THEN ((awinlost+comm-playercomm)+ (winlost-actual_stake+playercomm)) ELSE 0 END) AS YesterdayTotalBalance,
			SUM(CASE WHEN winlostdate = @yesterday THEN ((awinlost+comm-playercomm)+ (winlost-actual_stake+playercomm))* ActualRate ELSE 0 END) AS YesterdayTotalBalance_RM	
		FROM dbo.bettransRnG b WITH(NOLOCK)
		WHERE EXISTS (SELECT TOP 1 1 FROM #CustInfo c WHERE b.recommend = c.CustId AND c.RoleId = 2)
			AND statusID IN (111,112,113) 
			AND winlostdate >= @yesterday			
		GROUP BY recommend

		-- bettransLC
		INSERT INTO #balanceInfo (CustId, totalBalance, TotalBalance_RM, YesterdayTotalBalance, YesterdayTotalBalance_RM)
		SELECT
			recommend,
			SUM((awinlost+comm-playercomm)+ (winlost-actual_stake+playercomm)) as totalBalance,			
			SUM(((awinlost+comm-playercomm)+ (winlost-actual_stake+playercomm))* ActualRate) as TotalBalance_RM, 
			SUM(CASE WHEN winlostdate = @yesterday THEN ((awinlost+comm-playercomm)+ (winlost-actual_stake+playercomm)) ELSE 0 END) AS YesterdayTotalBalance,
			SUM(CASE WHEN winlostdate = @yesterday THEN ((awinlost+comm-playercomm)+ (winlost-actual_stake+playercomm))* ActualRate ELSE 0 END) AS YesterdayTotalBalance_RM	
		FROM dbo.bettransLC b WITH(NOLOCK)
		WHERE EXISTS (SELECT TOP 1 1 FROM #CustInfo c WHERE b.recommend = c.CustId AND c.RoleId = 2)
			AND statusID IN (111,112,113)  
			AND winlostdate >= @yesterday
		GROUP BY recommend
		;

		--TODO: SabaWallet
		INSERT INTO #balanceInfo (CustId, RewardPending, RewardPending_RM, RewardBalance, RewardBalance_RM, RewardCurrencyID, RewardMaxTransId)
		SELECT c.CustId, 
			SUM(IIF((POWER(2, c.RoleId - 2) & ISNULL(sw.PaymentStatus, 0)) = 0, sw.Amount, 0)) AS RewardPending,
			SUM(IIF((POWER(2, c.RoleId - 2) & ISNULL(sw.PaymentStatus, 0)) = 0, sw.Amount*sw.ActualRate, 0)) AS RewardPending_RM,
			SUM(IIF((POWER(2, c.RoleId - 1) & ISNULL(sw.PaymentStatus, 0)) = 0, sw.Amount, 0)) AS RewardBalance, 
			SUM(IIF((POWER(2, c.RoleId - 1) & ISNULL(sw.PaymentStatus, 0)) = 0, sw.Amount*sw.ActualRate, 0)) AS RewardBalance_RM, 
			sw.CurrencyID, 
			MAX(sw.TransId) AS RewardMaxTransId
		FROM dbo.SabaWalletTicket sw  WITH(NOLOCK)
			INNER JOIN #CustInfo c ON sw.recommend = c.CustId AND c.RoleId = 2
		WHERE sw.WalletID = 2
		GROUP BY c.CustId, sw.CurrencyID
		;
	END
	-- master
	IF EXISTS (SELECT TOP 1 1 FROM #CustInfo WHERE RoleId = 3)
	BEGIN
		--bettrans
		;WITH Bettrans_CTE AS (
			SELECT 
				mrecommend, Winlostdate, Bettype,				
				SUM( mwinlost + acomm +  awinlost + winlost - actual_stake) AS TotalBalance,
				SUM((mwinlost+acomm + awinlost + winlost-actual_stake) * ActualRate) AS TotalBalance_RM,
				SUM(CASE WHEN (winlostdate <= @yesterday) THEN mwinlost + acomm + awinlost + winlost - actual_stake ELSE 0 END) AS YesterdayTotalBalance,
				SUM((CASE WHEN (winlostdate <= @yesterday) THEN mwinlost + acomm + awinlost + winlost - actual_stake ELSE 0 END) * ActualRate) AS YesterdayTotalBalance_RM
			FROM dbo.bettrans b WITH (NOLOCK)    
			WHERE EXISTS (SELECT TOP 1 1 FROM #CustInfo c WHERE b.mrecommend = c.CustId AND c.RoleId = 3)		
				AND b.statusID IN (111, 112, 113)  
				AND b.winlostdate > @moveBetsDay
			GROUP BY mrecommend, Winlostdate, Bettype
			)
		INSERT INTO #balanceInfo (CustId, TotalBalance, TotalBalance_RM, YesterdayTotalBalance, YesterdayTotalBalance_RM)
		SELECT  mrecommend,
				SUM (TotalBalance) AS TotalBalance,
				SUM (TotalBalance_RM) AS TotalBalance_RM,
				SUM (YesterdayTotalBalance) AS YesterdayTotalBalance,
				SUM (YesterdayTotalBalance_RM) AS YesterdayTotalBalance_RM
		FROM Bettrans_CTE b
		WHERE b.Winlostdate < @yesterday OR NOT EXISTS (SELECT 1 FROM #SportBettype s WHERE s.Bettype = b.bettype)  -- exclude  bettype of bettransRNG and bettransLC
		GROUP BY mrecommend

		-- transfer
		INSERT INTO #balanceInfo (CustId, totalBalance, TotalBalance_RM, YesterdayTotalBalance, YesterdayTotalBalance_RM,PendingTransfer3rd, PendingTransfer3rd_RM)
		SELECT
			mrecommend,			
			SUM(CASE WHEN b.Bettype IN (21008,21009) THEN 0
						ELSE ( 
								  (CASE WHEN b.custid = b.mrecommend THEN winlost-actual_stake ELSE mwinlost+acomm-comm END)
								+ (CASE WHEN b.custid = b.recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END)
								+ (CASE WHEN b.custid <> b.recommend AND b.custid <> b.mrecommend THEN winlost-actual_stake+playercomm ELSE 0 END)
							 )
					 END) totalBalance, 			
			SUM(CASE WHEN b.Bettype IN (21008,21009) THEN 0
						ELSE (
								  (CASE WHEN b.custid = b.mrecommend THEN winlost-actual_stake ELSE mwinlost+acomm-comm END)
								+ (CASE WHEN b.custid = b.recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END)
								+ (CASE WHEN b.custid <> b.recommend AND b.custid <> b.mrecommend THEN winlost-actual_stake+playercomm ELSE 0 END)
							 ) * ActualRate 
					 END) TotalBalance_RM, 			
			
			SUM(CASE WHEN b.Bettype IN (21008, 21009) THEN 0 
						ELSE (
								  (CASE WHEN b.custid = b.mrecommend THEN winlost-actual_stake ELSE mwinlost+acomm-comm END)
								+ (CASE WHEN b.custid = b.recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END)
								+ (CASE WHEN b.custid <> b.recommend AND b.custid <> b.mrecommend THEN winlost-actual_stake+playercomm ELSE 0 END)
							 ) 
					 END) YesterdayTotalBalance, 			
			
			SUM(CASE WHEN b.Bettype IN (21008, 21009) THEN 0 
						ELSE (
								  (CASE WHEN b.custid = b.mrecommend THEN winlost-actual_stake ELSE mwinlost+acomm-comm END)
								+ (CASE WHEN b.custid = b.recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END)
								+ (CASE WHEN b.custid <> b.recommend AND b.custid <> b.mrecommend THEN winlost-actual_stake+playercomm ELSE 0 END)
							 ) * ActualRate 
					 END ) YesterdayTotalBalance_RM,

			SUM(CASE WHEN b.Bettype IN (21008, 21009) THEN -(b.Winlost - b.Actual_Stake) 
						ELSE 0 
					 END) AS PendingTransfer3rd,

			SUM(CASE WHEN b.Bettype IN (21008, 21009) THEN -(b.Winlost - b.Actual_Stake) * b.ActualRate
						ELSE 0 
					 END) AS PendingTransfer3rd_RM

		FROM dbo.transfer b WITH(NOLOCK) 
		WHERE EXISTS (SELECT TOP 1 1 FROM #CustInfo c WHERE b.mrecommend = c.CustId AND c.RoleId = 3)		
			AND 1 = CASE WHEN bettype = 19999 AND winlostdate > @moveBetsDay THEN 0 --> new sum
                        WHEN bettype = 20000 AND winlostdate > @BUDay THEN 0 --> new bal
                        WHEN winlostdate < @BUDay THEN 0 --> old data
                    ELSE 1 END
		GROUP BY mrecommend
		
		-- bettransRnG
		INSERT INTO #balanceInfo (CustId, totalBalance, TotalBalance_RM, YesterdayTotalBalance, YesterdayTotalBalance_RM)
		SELECT
			mrecommend,
			SUM((mwinlost+acomm-comm)+ (awinlost+comm-playercomm)+ (winlost-actual_stake+playercomm)) as totalBalance,			
			SUM(((mwinlost+acomm-comm)+(awinlost+comm-playercomm)+ (winlost-actual_stake+playercomm))* ActualRate) as TotalBalance_RM, 
			SUM(CASE WHEN winlostdate = @yesterday THEN ((mwinlost+acomm-comm)+(awinlost+comm-playercomm)+ (winlost-actual_stake+playercomm)) ELSE 0 END) AS YesterdayTotalBalance,
			SUM(CASE WHEN winlostdate = @yesterday THEN ((mwinlost+acomm-comm)+(awinlost+comm-playercomm)+ (winlost-actual_stake+playercomm))* ActualRate ELSE 0 END) AS YesterdayTotalBalance_RM
		FROM dbo.bettransRnG b WITH(NOLOCK)
		WHERE EXISTS (SELECT TOP 1 1 FROM #CustInfo c WHERE b.mrecommend = c.CustId AND c.RoleId = 3)
			AND b.statusID IN (111, 112, 113)
			AND winlostdate >= @yesterday
		GROUP BY mrecommend

		-- bettransLC
		INSERT INTO #balanceInfo (CustId, totalBalance, TotalBalance_RM, YesterdayTotalBalance, YesterdayTotalBalance_RM)
		SELECT
			mrecommend,
			SUM((mwinlost+acomm-comm)+ (awinlost+comm-playercomm)+ (winlost-actual_stake+playercomm)) as totalBalance,			
			SUM(((mwinlost+acomm-comm)+(awinlost+comm-playercomm)+ (winlost-actual_stake+playercomm))* ActualRate) as TotalBalance_RM, 
			SUM(CASE WHEN winlostdate = @yesterday THEN ((mwinlost+acomm-comm)+(awinlost+comm-playercomm)+ (winlost-actual_stake+playercomm)) ELSE 0 END) AS YesterdayTotalBalance,
			SUM(CASE WHEN winlostdate = @yesterday THEN ((mwinlost+acomm-comm)+(awinlost+comm-playercomm)+ (winlost-actual_stake+playercomm))* ActualRate ELSE 0 END) AS YesterdayTotalBalance_RM
		FROM dbo.bettransLC b WITH(NOLOCK)
		WHERE EXISTS (SELECT TOP 1 1 FROM #CustInfo c WHERE b.mrecommend = c.CustId AND c.RoleId = 3)
			AND b.statusID IN (111, 112, 113)
			AND winlostdate >= @yesterday
		GROUP BY mrecommend
		;

		--TODO: SabaWallet
		INSERT INTO #balanceInfo (CustId, RewardPending, RewardPending_RM, RewardBalance, RewardBalance_RM, RewardCurrencyID, RewardMaxTransId)
		SELECT c.CustId, 
			SUM(IIF((POWER(2, c.RoleId - 2) & ISNULL(sw.PaymentStatus, 0)) = 0, sw.Amount, 0)) AS RewardPending,
			SUM(IIF((POWER(2, c.RoleId - 2) & ISNULL(sw.PaymentStatus, 0)) = 0, sw.Amount*sw.ActualRate, 0)) AS RewardPending_RM,
			SUM(IIF((POWER(2, c.RoleId - 1) & ISNULL(sw.PaymentStatus, 0)) = 0, sw.Amount, 0)) AS RewardBalance, 
			SUM(IIF((POWER(2, c.RoleId - 1) & ISNULL(sw.PaymentStatus, 0)) = 0, sw.Amount*sw.ActualRate, 0)) AS RewardBalance_RM, 
			sw.CurrencyID, 
			MAX(sw.TransId) AS RewardMaxTransId
		FROM dbo.SabaWalletTicket sw  WITH(NOLOCK)
			INNER JOIN #CustInfo c ON sw.mrecommend = c.CustId AND c.RoleId = 3
		WHERE sw.WalletID = 2
		GROUP BY c.CustId, sw.CurrencyID
		;

	END
	-- super
	IF EXISTS (SELECT TOP 1 1 FROM #CustInfo WHERE RoleId = 4)
	BEGIN
		-- bettrans
		;WITH Bettrans_CTE AS (
			SELECT 
				srecommend, Winlostdate, Bettype,				
				SUM( swinlost+scomm + mwinlost+ awinlost + winlost-actual_stake) AS TotalBalance,
				SUM((swinlost+scomm + mwinlost+ awinlost + winlost-actual_stake)  * ActualRate) AS TotalBalance_RM,
				SUM(CASE WHEN (winlostdate <= @yesterday) THEN swinlost+scomm + mwinlost+ awinlost + winlost-actual_stake ELSE 0 END) AS YesterdayTotalBalance,
				SUM((CASE WHEN (winlostdate <= @yesterday) THEN swinlost+scomm + mwinlost+ awinlost + winlost-actual_stake ELSE 0 END) * ActualRate) AS YesterdayTotalBalance_RM				
			FROM dbo.bettrans b WITH (NOLOCK)    
			WHERE EXISTS (SELECT TOP 1 1 FROM #CustInfo c WHERE b.srecommend = c.CustId AND c.RoleId = 4)	
				AND b.statusID IN (111, 112, 113)
				AND b.winlostdate > @moveBetsDay
			GROUP BY srecommend, Winlostdate, Bettype
			)
		INSERT INTO #balanceInfo (CustId, TotalBalance, TotalBalance_RM, YesterdayTotalBalance, YesterdayTotalBalance_RM)
		SELECT  srecommend,
				SUM (TotalBalance) AS TotalBalance,
				SUM (TotalBalance_RM) AS TotalBalance_RM,
				SUM (YesterdayTotalBalance) AS YesterdayTotalBalance,
				SUM (YesterdayTotalBalance_RM) AS YesterdayTotalBalance_RM
		FROM Bettrans_CTE b
		WHERE b.winlostdate < @yesterday  OR NOT EXISTS (SELECT 1 FROM #SportBettype s WHERE s.Bettype = b.bettype)  -- exclude  bettype of bettransRNG and bettransLC
		GROUP BY srecommend

		-- transfer
		INSERT INTO #balanceInfo (CustId, totalBalance, TotalBalance_RM, YesterdayTotalBalance, YesterdayTotalBalance_RM,PendingTransfer3rd, PendingTransfer3rd_RM)
		SELECT
			srecommend,			
			SUM(CASE WHEN b.Bettype IN (21008,21009) THEN 0
						ELSE (
								  (CASE WHEN b.custid = b.srecommend THEN winlost-actual_stake ELSE swinlost+scomm-acomm END)
								+ (CASE WHEN b.custid = b.mrecommend THEN winlost-actual_stake ELSE mwinlost+acomm-comm END)
								+ (CASE WHEN b.custid = b.recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END)
								+ (CASE WHEN b.custid <> b.recommend AND b.custid <> b.mrecommend AND b.custid <> b.srecommend THEN winlost-actual_stake+playercomm ELSE 0 END)
							 )
					 END) totalBalance, 			
			SUM(CASE WHEN b.Bettype IN (21008,21009) THEN 0
						ELSE (
								  (CASE WHEN b.custid = b.srecommend THEN winlost-actual_stake ELSE swinlost+scomm-acomm END)
								+ (CASE WHEN b.custid = b.mrecommend THEN winlost-actual_stake ELSE mwinlost+acomm-comm END)
								+ (CASE WHEN b.custid = b.recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END)
								+ (CASE WHEN b.custid <> b.recommend AND b.custid <> b.mrecommend AND b.custid <> b.srecommend THEN winlost-actual_stake+playercomm ELSE 0 END)
							 ) * ActualRate 
					 END) TotalBalance_RM,	
			SUM(CASE WHEN b.Bettype IN (21008, 21009) THEN 0 
						ELSE (
								  (CASE WHEN b.custid = b.srecommend THEN winlost-actual_stake ELSE swinlost+scomm-acomm END)
								+ (CASE WHEN b.custid = b.mrecommend THEN winlost-actual_stake ELSE mwinlost+acomm-comm END)
								+ (CASE WHEN b.custid = b.recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END)
								+ (CASE WHEN b.custid <> b.recommend AND b.custid <> b.mrecommend AND b.custid <> b.srecommend THEN winlost-actual_stake+playercomm ELSE 0 END)
							 )
					 END) YesterdayTotalBalance,
			SUM(CASE WHEN b.Bettype IN (21008, 21009) THEN 0 
						ELSE (
							  (CASE WHEN b.custid = b.srecommend THEN winlost-actual_stake ELSE swinlost+scomm-acomm END)
							+ (CASE WHEN b.custid = b.mrecommend THEN winlost-actual_stake ELSE mwinlost+acomm-comm END)
							+ (CASE WHEN b.custid = b.recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END)
							+ (CASE WHEN b.custid <> b.recommend AND b.custid <> b.mrecommend AND b.custid <> b.srecommend THEN winlost-actual_stake+playercomm ELSE 0 END)
							 ) * ActualRate  
					 END) YesterdayTotalBalance_RM,
			SUM(CASE WHEN b.Bettype IN (21008, 21009) THEN -(b.Winlost - b.Actual_Stake) ELSE 0 END) PendingTransfer3rd,
			SUM(CASE WHEN b.Bettype IN (21008, 21009) THEN -(b.Winlost - b.Actual_Stake) * b.ActualRate ELSE 0 END) PendingTransfer3rd_RM
		FROM dbo.transfer b WITH(NOLOCK, INDEX=IX_srecommend) 
		WHERE EXISTS (SELECT TOP 1 1 FROM #CustInfo c WHERE b.srecommend = c.CustId AND c.RoleId = 4)	
			AND 1 = CASE WHEN bettype = 19999 AND winlostdate > @moveBetsDay THEN 0 --> new sum
                        WHEN bettype = 20000 AND winlostdate > @BUDay THEN 0 --> new bal
                        WHEN winlostdate < @BUDay THEN 0 --> old data
                    ELSE 1 END
		GROUP BY srecommend
		
		-- bettransRnG
		INSERT INTO #balanceInfo (CustId, totalBalance, TotalBalance_RM, YesterdayTotalBalance, YesterdayTotalBalance_RM)
		SELECT
			srecommend,
			SUM((swinlost+scomm-acomm)+(mwinlost+acomm-comm)+ (awinlost+comm-playercomm)+ (winlost-actual_stake+playercomm)) as totalBalance,			
			SUM(((swinlost+scomm-acomm)+(mwinlost+acomm-comm)+(awinlost+comm-playercomm)+ (winlost-actual_stake+playercomm))* ActualRate) as TotalBalance_RM, 
			SUM(CASE WHEN winlostdate = @yesterday THEN ((swinlost+scomm-acomm)+(mwinlost+acomm-comm)+(awinlost+comm-playercomm)+ (winlost-actual_stake+playercomm)) ELSE 0 END) AS YesterdayTotalBalance,
			SUM(CASE WHEN winlostdate = @yesterday THEN ((swinlost+scomm-acomm)+(mwinlost+acomm-comm)+(awinlost+comm-playercomm)+ (winlost-actual_stake+playercomm))* ActualRate ELSE 0 END) AS YesterdayTotalBalance_RM
		FROM dbo.bettransRnG b WITH(NOLOCK)
		WHERE EXISTS (SELECT TOP 1 1 FROM #CustInfo c WHERE b.srecommend = c.CustId AND c.RoleId = 4)
			AND statusID NOT IN (0,1) 
			AND winlostdate >= @yesterday
		GROUP BY srecommend

		-- bettransLC
		INSERT INTO #balanceInfo (CustId, totalBalance, TotalBalance_RM, YesterdayTotalBalance, YesterdayTotalBalance_RM)
		SELECT
			srecommend,
			SUM((swinlost+scomm-acomm)+(mwinlost+acomm-comm)+ (awinlost+comm-playercomm)+ (winlost-actual_stake+playercomm)) as totalBalance,			
			SUM(((swinlost+scomm-acomm)+(mwinlost+acomm-comm)+(awinlost+comm-playercomm)+ (winlost-actual_stake+playercomm))* ActualRate) as TotalBalance_RM, 
			SUM(CASE WHEN winlostdate = @yesterday THEN ((swinlost+scomm-acomm)+(mwinlost+acomm-comm)+(awinlost+comm-playercomm)+ (winlost-actual_stake+playercomm)) ELSE 0 END) AS YesterdayTotalBalance,
			SUM(CASE WHEN winlostdate = @yesterday THEN ((swinlost+scomm-acomm)+(mwinlost+acomm-comm)+(awinlost+comm-playercomm)+ (winlost-actual_stake+playercomm))* ActualRate ELSE 0 END) AS YesterdayTotalBalance_RM
		FROM dbo.bettransLC b WITH(NOLOCK)
		WHERE EXISTS (SELECT TOP 1 1 FROM #CustInfo c WHERE b.srecommend = c.CustId AND c.RoleId = 4)
			AND statusID NOT IN (0,1) 
			AND winlostdate >= @yesterday
		GROUP BY srecommend
		;

		--TODO: SabaWallet
		INSERT INTO #balanceInfo (CustId, RewardPending, RewardPending_RM, RewardBalance, RewardBalance_RM, RewardCurrencyID, RewardMaxTransId)
		SELECT c.CustId, 
			SUM(IIF((POWER(2, c.RoleId - 2) & ISNULL(sw.PaymentStatus, 0)) = 0, sw.Amount, 0)) AS RewardPending,
			SUM(IIF((POWER(2, c.RoleId - 2) & ISNULL(sw.PaymentStatus, 0)) = 0, sw.Amount*sw.ActualRate, 0)) AS RewardPending_RM,
			SUM(IIF((POWER(2, c.RoleId - 1) & ISNULL(sw.PaymentStatus, 0)) = 0, sw.Amount, 0)) AS RewardBalance, 
			SUM(IIF((POWER(2, c.RoleId - 1) & ISNULL(sw.PaymentStatus, 0)) = 0, sw.Amount*sw.ActualRate, 0)) AS RewardBalance_RM, 
			sw.CurrencyID, 
			MAX(sw.TransId) AS RewardMaxTransId
		FROM dbo.SabaWalletTicket sw  WITH(NOLOCK)
			INNER JOIN #CustInfo c ON sw.srecommend = c.CustId AND c.RoleId = 4
		WHERE sw.WalletID = 2
		GROUP BY c.CustId, sw.CurrencyID
	END
	--headline
	IF EXISTS (SELECT TOP 1 1 FROM #CustInfo WHERE RoleId = 0)
	BEGIN
		DROP TABLE IF EXISTS #tempSuper;
		CREATE TABLE #tempSuper(SuperID INT PRIMARY KEY, HeadlineID INT, RoleId TINYINT);

		-- headline - SMA(s) Cash 
		INSERT INTO #tempSuper (SuperID, HeadlineID, RoleId)
		SELECT DISTINCT c.CustID AS SuperID, ci.RoleId
			, c.UplineID AS HeadlineID
		FROM dbo.CustSuper c WITH (NOLOCK) 
		--INNER JOIN dbo.CS_CustSuper cs ON c.custid = cs.CustId
		INNER JOIN #CustInfo ci ON c.UplineID = ci.custid
		WHERE ci.RoleId = 0
		
		-- bettrans
		;WITH Bettrans_CTE AS (
			SELECT 
				cs.HeadlineID
				,Bettype
				,winlostdate
				,0 AS TotalBalance
				,0 AS TotalBalance_RM
				,SUM(CASE WHEN (winlostdate <= @yesterday) THEN swinlost + scomm + mwinlost + awinlost + winlost- actual_stake  ELSE 0 END) AS YesterdayTotalBalance
				,SUM( (CASE WHEN (winlostdate <= @yesterday) THEN swinlost+scomm + mwinlost + awinlost  + winlost-actual_stake  ELSE 0 END) * actualrate) AS YesterdayTotalBalance_RM
			FROM dbo.bettrans b WITH (NOLOCK)    
			INNER JOIN #tempSuper cs ON cs.SuperID = b.srecommend
			WHERE  winlostdate <= @today
				AND b.statusID IN (111, 112, 113) 
				AND b.winlostdate > @moveBetsDay
			GROUP BY cs.HeadlineID, Bettype, winlostdate
		)
		INSERT INTO #balanceInfo (CustId, TotalBalance, TotalBalance_RM, YesterdayTotalBalance, YesterdayTotalBalance_RM)
		SELECT  HeadlineID,
				SUM (TotalBalance) AS TotalBalance,
				SUM (TotalBalance_RM) AS TotalBalance_RM,
				SUM (YesterdayTotalBalance) AS YesterdayTotalBalance,
				SUM (YesterdayTotalBalance_RM) AS YesterdayTotalBalance_RM
		FROM Bettrans_CTE b
		WHERE winlostdate < @yesterday OR NOT EXISTS (SELECT 1 FROM #SportBettype s WHERE s.Bettype = b.bettype)  -- exclude  bettype of bettransRNG and bettransLC
		GROUP BY HeadlineID

		INSERT INTO #balanceInfo (CustId, totalBalance, TotalBalance_RM, YesterdayTotalBalance, YesterdayTotalBalance_RM,PendingTransfer3rd, PendingTransfer3rd_RM)
		SELECT
			cs.HeadlineID
			,0 AS totalBalance
			,0 AS totalBalance_RM
			,SUM(bal.totalBalance)	AS YesterdayTotalBalance
			,SUM(bal.totalBalance * actualrate) AS YesterdayTotalBalance_RM
			,SUM(bal.PendingTransfer3rd) AS PendingTransfer3rd
			,SUM(bal.PendingTransfer3rd * b.ActualRate) AS PendingTransfer3rd_RM
		FROM dbo.transfer b WITH(NOLOCK, INDEX=IX_srecommend)
			INNER JOIN #tempSuper cs ON cs.SuperID = b.srecommend
			CROSS APPLY (
				 SELECT 
					CASE WHEN b.Bettype IN (21008, 21009) THEN 0 
							ELSE
								  (CASE WHEN b.custid = b.srecommend THEN winlost-actual_stake ELSE swinlost+scomm-acomm END)
								+ (CASE WHEN b.custid = b.mrecommend THEN winlost-actual_stake ELSE mwinlost+acomm-comm END)
								+ (CASE WHEN b.custid = b.recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END)
								+ (CASE WHEN b.custid <> b.recommend AND b.custid <> b.mrecommend AND b.custid <> b.srecommend THEN winlost-actual_stake+playercomm ELSE 0 END) 
						 END AS totalBalance,
					CASE WHEN b.Bettype IN (21008, 21009) THEN - (b.Winlost - b.Actual_Stake) 
							ELSE 0 
						 END AS PendingTransfer3rd
			) AS bal
		WHERE 1 = CASE WHEN bettype = 19999 AND winlostdate > @moveBetsDay THEN 0 --> new sum
                        WHEN bettype = 20000 AND winlostdate > @BUDay THEN 0 --> new bal
                        WHEN winlostdate < @BUDay THEN 0 --> old data
                    ELSE 1 END
		GROUP BY cs.HeadlineID

		-- bettransRnG
		INSERT INTO #balanceInfo (CustId, totalBalance, TotalBalance_RM, YesterdayTotalBalance, YesterdayTotalBalance_RM)
		SELECT
			cs.HeadlineID
			,0 AS totalBalance		
			,0 AS TotalBalance_RM
			,SUM(CASE WHEN winlostdate = @yesterday THEN ((swinlost+scomm-acomm)+(mwinlost+acomm-comm)+(awinlost+comm-playercomm)+ (winlost-actual_stake+playercomm)) ELSE 0 END) AS YesterdayTotalBalance
			,SUM(CASE WHEN winlostdate = @yesterday THEN ((swinlost+scomm-acomm)+(mwinlost+acomm-comm)+(awinlost+comm-playercomm)+ (winlost-actual_stake+playercomm))* ActualRate ELSE 0 END) AS YesterdayTotalBalance_RM
		FROM dbo.bettransRnG b WITH(NOLOCK)
		INNER JOIN #tempSuper cs ON cs.SuperID = b.srecommend
		WHERE  b.statusID IN (111, 112, 113) 
			AND winlostdate >= @yesterday AND winlostdate <= @today
		GROUP BY cs.HeadlineID

		-- bettransLC
		INSERT INTO #balanceInfo (CustId, totalBalance, TotalBalance_RM, YesterdayTotalBalance, YesterdayTotalBalance_RM)
		SELECT
			cs.HeadlineID
			,0 AS totalBalance
			,0 AS TotalBalance_RM
			,SUM(CASE WHEN winlostdate = @yesterday THEN ((swinlost+scomm-acomm)+(mwinlost+acomm-comm)+(awinlost+comm-playercomm)+ (winlost-actual_stake+playercomm)) ELSE 0 END) AS YesterdayTotalBalance
			,SUM(CASE WHEN winlostdate = @yesterday THEN ((swinlost+scomm-acomm)+(mwinlost+acomm-comm)+(awinlost+comm-playercomm)+ (winlost-actual_stake+playercomm))* ActualRate ELSE 0 END) AS YesterdayTotalBalance_RM
		FROM dbo.bettransLC b WITH(NOLOCK)
		INNER JOIN #tempSuper cs ON cs.SuperID = b.srecommend
		WHERE b.statusID IN (111, 112, 113) 
			AND winlostdate >= @yesterday AND winlostdate <= @today
		GROUP BY cs.HeadlineID

		-- headline cash
		INSERT INTO #balanceInfo (CustId, totalBalance, TotalBalance_RM, YesterdayTotalBalance, YesterdayTotalBalance_RM,PendingTransfer3rd, PendingTransfer3rd_RM)
		SELECT b.custid
			,0
			,0
			,SUM(CASE WHEN b.Bettype IN (21008, 21009) THEN 0 
						ELSE b.winlost-b.actual_stake 
					  END) AS YesterdayTotalCash
			,SUM(CASE WHEN b.Bettype IN (21008, 21009) THEN 0 
						ELSE (b.winlost-b.actual_stake) * actualRate
					  END) AS YesterdayTotalCash_RM
			,SUM(CASE WHEN b.Bettype IN (21008, 21009) THEN -(b.Winlost - b.Actual_Stake) 
						ELSE 0 
					  END) AS PendingTransfer3rd
			,SUM(CASE WHEN b.Bettype IN (21008, 21009) THEN -(b.Winlost - b.Actual_Stake) * b.ActualRate
						ELSE 0 
					  END) AS PendingTransfer3rd_RM
		FROM dbo.transfer b WITH(NOLOCK)
		WHERE EXISTS (SELECT TOP 1 1 FROM #CustInfo t WHERE b.custid = t.custid AND RoleId = 0)
			AND b.bettype >= 20000
			AND 1 = CASE WHEN bettype = 20000 AND winlostdate > @BUDay THEN 0 --> new bal
						WHEN winlostdate < @BUDay THEN 0 --> old data
					ELSE 1 END
			AND b.winlostdate <= @today
		GROUP BY b.custid
		;

		--TODO: SabaWallet
		INSERT INTO #balanceInfo (CustId, RewardPending, RewardPending_RM, RewardBalance, RewardBalance_RM, RewardCurrencyID, RewardMaxTransId)
		SELECT c.CustId, 
			SUM(IIF((POWER(2, c.RoleId - 2) & ISNULL(sw.PaymentStatus, 0)) = 0, sw.Amount, 0)) AS RewardPending,
			SUM(IIF((POWER(2, c.RoleId - 2) & ISNULL(sw.PaymentStatus, 0)) = 0, sw.Amount*sw.ActualRate, 0)) AS RewardPending_RM,
			SUM(IIF((POWER(2, c.RoleId - 1) & ISNULL(sw.PaymentStatus, 0)) = 0, sw.Amount, 0)) AS RewardBalance, 
			SUM(IIF((POWER(2, c.RoleId - 1) & ISNULL(sw.PaymentStatus, 0)) = 0, sw.Amount*sw.ActualRate, 0)) AS RewardBalance_RM, 
			sw.CurrencyID, 
			MAX(sw.TransId) AS RewardMaxTransId
		FROM dbo.SabaWalletTicket sw  WITH(NOLOCK)
			INNER JOIN #tempSuper ts ON sw.srecommend = ts.SuperID
		WHERE sw.WalletID = 2
		GROUP BY ts.SuperID, sw.CurrencyID
		;

	END

	--TODO: output result
	RS_OUTPUT:
	;WITH CTE_Reward AS (
		SELECT bal.CustId,
			SUM(ISNULL(bal.RewardPending, 0))		AS RewardPending,
			SUM(ISNULL(bal.RewardPending_RM, 0))	AS RewardPending_RM,
			SUM(ISNULL(bal.RewardBalance, 0))		AS RewardBalance,
			SUM(ISNULL(bal.RewardBalance_RM, 0))	AS RewardBalance_RM,
			ISNULL(ex.Code, '') AS RewardCurrency,
			MAX(bal.RewardMaxTransId) AS RewardMaxTransId
		FROM #balanceInfo bal 
			LEFT JOIN dbo.exchange ex on ex.ExchangeId = bal.RewardCurrencyID
		WHERE bal.RewardCurrencyID > 0
		GROUP BY bal.CustId, ex.Code
	)
	SELECT
		ci.CustId,
		SUM(ISNULL(bal.TotalBalance, 0)) TotalBalance,
		SUM(ISNULL(bal.TotalBalance_RM, 0)) TotalBalance_RM,
		SUM(ISNULL(bal.YesterdayTotalBalance, 0)) YesterdayTotalBalance,
		SUM(ISNULL(bal.YesterdayTotalBalance_RM, 0)) YesterdayTotalBalance_RM,
		SUM(ISNULL(bal.PendingTransfer3rd,0)) PendingTransfer3rd,
		SUM(ISNULL(bal.PendingTransfer3rd_RM,0)) PendingTransfer3rd_RM,
		MAX(ISNULL(rw.RewardPending, 0)) AS RewardPending,
		MAX(ISNULL(rw.RewardPending_RM, 0)) AS RewardPending_RM,
		MAX(ISNULL(rw.RewardBalance, 0)) AS RewardBalance,
		MAX(ISNULL(rw.RewardBalance_RM, 0)) AS RewardBalance_RM,
		MAX(ISNULL(rw.RewardCurrency, '')) AS RewardCurrency,
		MAX(rw.RewardMaxTransId) AS RewardMaxTransId
	FROM #CustInfo ci
		LEFT JOIN #balanceInfo bal ON ci.CustId = bal.custid
		LEFT JOIN CTE_Reward rw ON rw.CustId = ci.CustId
	GROUP BY ci.CustId
	;
END