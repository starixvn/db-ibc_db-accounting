/*<info serverAlias="DBAGE-bodb02" executers="bodbAdminNet"  isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerSelBalanceInfo]
	@CustId		INT = NULL,
	@CustIdList	VARCHAR(MAX) = NULL,
	@MoveBetDay SMALLDATETIME = NULL
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

	Param's Explaination:
		- @CustId: single cust
		- @CustIdList: multiple cust
*/

BEGIN
	SET NOCOUNT ON

	-- Get Balance Information --
	CREATE TABLE #balanceInfo (CustId INT, totalBalance MONEY, TotalBalance_RM MONEY, YesterdayTotalBalance MONEY, YesterdayTotalBalance_RM MONEY)

	IF @CustId IS NULL AND ISNULL(@CustIdList, '') = ''
	BEGIN
		SELECT CustId, totalBalance, TotalBalance_RM, YesterdayTotalBalance, YesterdayTotalBalance_RM FROM #balanceInfo
		RETURN
	END
	
	DECLARE @today DATETIME, @yesterday DATETIME, @SQLCust NVARCHAR(MAX)
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
	DECLARE @balanceUpDay SMALLDATETIME, @moveBetsDay SMALLDATETIME
	DECLARE @tblMoveBetBalanceUp AS TABLE (BalanceUpDay SMALLDATETIME, MoveBetsDay SMALLDATETIME)

	IF (@MoveBetDay IS NULL)
	BEGIN
		INSERT INTO @tblMoveBetBalanceUp(BalanceUpDay,MoveBetsDay)
		EXEC bodb02.dbo.Age_SelBalanceUpDay

		SELECT @balanceUpDay = BalanceUpDay, @moveBetsDay = MoveBetsDay FROM @tblMoveBetBalanceUp
	END
	ELSE
	BEGIN
		SELECT @moveBetsDay = @MoveBetDay
	END
  
	
	CREATE TABLE #CustInfo (CustId INT PRIMARY KEY, RoleId TINYINT)

	IF @CustId IS NOT NULL
	BEGIN
		INSERT INTO #CustInfo (CustId, RoleId)
		SELECT custid, roleid
		FROM dbo.custInfo WITH(NOLOCK)
		WHERE custid = @custID
			AND roleid < 5
	END
	ELSE
	BEGIN
		INSERT INTO #CustInfo (CustId, RoleId)
		SELECT custid, roleid
		FROM dbo.custInfo c WITH(NOLOCK)
		WHERE EXISTS (SELECT TOP 1 1 FROM dbo.strSplit(@CustIdList, ',')s WHERE c.custid = s.val)
			AND roleid < 5
	END

	IF NOT EXISTS (SELECT TOP 1 1 FROM #CustInfo)
	BEGIN
		SELECT CustId, totalBalance, TotalBalance_RM, YesterdayTotalBalance, YesterdayTotalBalance_RM FROM #balanceInfo
		RETURN
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
			SUM(CASE WHEN (winlostdate <= @yesterday OR b.bettype > 20000) THEN winlost-actual_stake+playercomm ELSE 0 END) AS YesterdayTotalBalance, 
			SUM((CASE WHEN (winlostdate <= @yesterday OR b.bettype > 20000) THEN winlost-actual_stake+playercomm ELSE 0 END) * ActualRate) AS YesterdayTotalBalance_RM
		FROM dbo.bettrans b WITH(NOLOCK) 
		WHERE EXISTS (SELECT TOP 1 1 FROM #CustInfo c WHERE b.custid = c.CustId AND c.RoleId = 1)
			AND b.ruben = 1			
			AND (
				b.winlostdate < @yesterday
				OR NOT EXISTS (SELECT 1 FROM #SportBettype s WHERE s.Bettype = b.bettype)  -- exclude  bettype of bettransRNG and bettransLC
				)
			AND 1 = CASE 
						WHEN bettype = 19999 and winlostdate > @moveBetsDay THEN 0 --> get data from ticket detail
						WHEN bettype < 19999 and winlostdate <= @moveBetsDay THEN 0 --> get data from sum record
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
			AND statusID NOT IN (0,1) 
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
			AND statusID NOT IN (0,1) 
			AND winlostdate >= @yesterday
		GROUP BY CustId
	END
		-- agent
	IF EXISTS (SELECT TOP 1 1 FROM #CustInfo WHERE RoleId = 2)
	BEGIN
		-- bettrans
		INSERT INTO #balanceInfo (CustId, TotalBalance, TotalBalance_RM, YesterdayTotalBalance, YesterdayTotalBalance_RM)
		SELECT
			recommend,			
			SUM((CASE WHEN b.custid = b.recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END)
			+ (CASE WHEN b.custid <> b.recommend THEN winlost-actual_stake+playercomm ELSE 0 END)) TotalBalance,
			
			SUM (((CASE WHEN b.custid = b.recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END)
			+ (CASE WHEN b.custid <> b.recommend THEN winlost-actual_stake+playercomm ELSE 0 END)) * ActualRate) TotalBalance_RM,
			
			SUM((CASE WHEN b.custid = b.recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END)			
			+ (CASE WHEN b.custid <> b.recommend THEN winlost-actual_stake+playercomm ELSE 0 END)) YesterdayTotalBalance,
			
			SUM(((CASE WHEN b.custid = b.recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END)
			+ (CASE WHEN b.custid <> b.recommend THEN winlost-actual_stake+playercomm ELSE 0 END)) * ActualRate) YesterdayTotalBalance_RM	
			
		FROM dbo.bettrans b WITH(NOLOCK)			
		WHERE EXISTS (SELECT TOP 1 1 FROM #CustInfo c WHERE b.recommend = c.CustId AND c.RoleId = 2)
			AND b.ruben = 1
			AND b.winlostdate < @yesterday
			AND 1 = CASE 
						WHEN bettype = 19999 and winlostdate > @moveBetsDay THEN 0 --> get data from ticket detail
						WHEN bettype < 19999 and winlostdate <= @moveBetsDay THEN 0 --> get data from sum record
					ELSE 1 END
		GROUP BY recommend
						
		 
		;WITH Bettrans_CTE AS (
			SELECT 
				recommend, Winlostdate, Bettype,				
				SUM((CASE WHEN custid = recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END) 
				+ (CASE WHEN custid <> recommend THEN winlost-actual_stake+playercomm ELSE 0 END)) AS TotalBalance,
				
				SUM(((CASE WHEN custid = recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END) 
				+ (CASE WHEN custid <> recommend THEN winlost-actual_stake+playercomm ELSE 0 END)) * ActualRate) AS TotalBalance_RM,
				
				SUM((CASE WHEN (winlostdate = @yesterday OR b.bettype > 20000) 
						  THEN CASE WHEN custid = recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END 
						  ELSE 0 END ) 
				+ (CASE WHEN custid <> recommend AND (winlostdate = @yesterday OR b.bettype > 20000) THEN winlost-actual_stake+playercomm ELSE 0 END)) AS YesterdayTotalBalance,
				
				SUM(((CASE WHEN (winlostdate = @yesterday OR b.bettype > 20000) 
						  THEN CASE WHEN custid = recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END 
						  ELSE 0 END ) 
				+ (CASE WHEN custid <> recommend AND (winlostdate = @yesterday OR b.bettype > 20000) THEN winlost-actual_stake+playercomm ELSE 0 END)) * ActualRate) AS YesterdayTotalBalance_RM				
			FROM dbo.bettrans b WITH (NOLOCK)    
			WHERE EXISTS (SELECT TOP 1 1 FROM #CustInfo c WHERE b.recommend = c.CustId AND c.RoleId = 2)
				AND b.ruben = 1
				AND b.winlostdate >= @yesterday
				AND 1 = CASE 
							WHEN bettype = 19999 and winlostdate > @moveBetsDay THEN 0 --> get data from ticket detail
							WHEN bettype < 19999 and winlostdate <= @moveBetsDay THEN 0 --> get data from sum record
						ELSE 1 END
			GROUP BY recommend, Winlostdate, Bettype
			)
		INSERT INTO #balanceInfo (CustId, TotalBalance, TotalBalance_RM, YesterdayTotalBalance, YesterdayTotalBalance_RM)
		SELECT  recommend,
				SUM (TotalBalance) AS TotalBalance,
				SUM (TotalBalance_RM) AS TotalBalance_RM,
				SUM (YesterdayTotalBalance) AS YesterdayTotalBalance,
				SUM (YesterdayTotalBalance_RM) AS YesterdayTotalBalance_RM			   
		FROM Bettrans_CTE b
		WHERE NOT EXISTS (SELECT 1 FROM #SportBettype s WHERE s.Bettype = b.bettype)  -- exclude  bettype of bettransRNG and bettransLC
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
			AND statusID NOT IN (0,1) 
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
			AND statusID NOT IN (0,1) AND winlostdate >= @yesterday
		GROUP BY recommend
	END
		-- master
	IF EXISTS (SELECT TOP 1 1 FROM #CustInfo WHERE RoleId = 3)
	BEGIN
		-- bettrans
		INSERT INTO #balanceInfo (CustId, totalBalance, TotalBalance_RM, YesterdayTotalBalance, YesterdayTotalBalance_RM)
		SELECT
			mrecommend,			
			SUM(
				  (CASE WHEN b.custid = b.mrecommend THEN winlost-actual_stake ELSE mwinlost+acomm-comm END)
				+ (CASE WHEN b.custid = b.recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END)
				+ (CASE WHEN b.custid <> b.recommend AND b.custid <> b.mrecommend THEN winlost-actual_stake+playercomm ELSE 0 END)
				) totalBalance, 			
			SUM((
				  (CASE WHEN b.custid = b.mrecommend THEN winlost-actual_stake ELSE mwinlost+acomm-comm END)
				+ (CASE WHEN b.custid = b.recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END)
				+ (CASE WHEN b.custid <> b.recommend AND b.custid <> b.mrecommend THEN winlost-actual_stake+playercomm ELSE 0 END)
				)* ActualRate ) TotalBalance_RM, 			
			SUM(
				  (CASE WHEN b.custid = b.mrecommend THEN winlost-actual_stake ELSE mwinlost+acomm-comm END)
				+ (CASE WHEN b.custid = b.recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END)
				+ (CASE WHEN b.custid <> b.recommend AND b.custid <> b.mrecommend THEN winlost-actual_stake+playercomm ELSE 0 END)
				) YesterdayTotalBalance, 			
			SUM((
				  (CASE WHEN b.custid = b.mrecommend THEN winlost-actual_stake ELSE mwinlost+acomm-comm END)
				+ (CASE WHEN b.custid = b.recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END)
				+ (CASE WHEN b.custid <> b.recommend AND b.custid <> b.mrecommend THEN winlost-actual_stake+playercomm ELSE 0 END)
				)* ActualRate ) YesterdayTotalBalance_RM			
		FROM dbo.bettrans b WITH(NOLOCK) 
		WHERE EXISTS (SELECT TOP 1 1 FROM #CustInfo c WHERE b.mrecommend = c.CustId AND c.RoleId = 3)		
			AND b.ruben = 1
			AND b.winlostdate < @yesterday
			AND 1 = CASE 
						WHEN bettype = 19999 and winlostdate > @moveBetsDay THEN 0 --> get data from ticket detail
						WHEN bettype < 19999 and winlostdate <= @moveBetsDay THEN 0 --> get data from sum record
					ELSE 1 END
		GROUP BY mrecommend
		
		
		 
		;WITH Bettrans_CTE AS (
			SELECT 
				mrecommend, Winlostdate, Bettype,				
				SUM(
					  (CASE WHEN custid = mrecommend THEN winlost-actual_stake ELSE mwinlost+acomm-comm END)
					+ (CASE WHEN custid = recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END) 
					+ (CASE WHEN custid <> recommend AND b.custid <> b.mrecommend THEN winlost-actual_stake+playercomm ELSE 0 END)
					) AS TotalBalance,
					
				SUM((
					(CASE WHEN custid = mrecommend THEN winlost-actual_stake ELSE mwinlost+acomm-comm END)
					+ (CASE WHEN custid = recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END) 
					+ (CASE WHEN custid <> recommend AND b.custid <> b.mrecommend THEN winlost-actual_stake+playercomm ELSE 0 END)) * ActualRate
					) AS TotalBalance_RM,
				
				SUM(
					+(CASE WHEN (winlostdate = @yesterday OR b.bettype > 20000) 
							  THEN CASE WHEN custid = mrecommend THEN winlost-actual_stake ELSE mwinlost+acomm-comm END
							  ELSE 0 END )						   
					+(CASE WHEN (winlostdate = @yesterday OR b.bettype > 20000) 
							  THEN CASE WHEN custid = recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END 
							  ELSE 0 END ) 
					+ (CASE WHEN custid <> recommend AND b.custid <> b.mrecommend AND (winlostdate = @yesterday OR b.bettype > 20000) THEN winlost-actual_stake+playercomm ELSE 0 END)
					) AS YesterdayTotalBalance,
				
				SUM((
					+ (CASE WHEN (winlostdate = @yesterday OR b.bettype > 20000) 
							  THEN CASE WHEN custid = mrecommend THEN winlost-actual_stake ELSE mwinlost+acomm-comm END
							  ELSE 0 END )
					+ (CASE WHEN (winlostdate = @yesterday OR b.bettype > 20000) 
							  THEN CASE WHEN custid = recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END 
							  ELSE 0 END ) 
					+ (CASE WHEN custid <> recommend AND b.custid <> b.mrecommend AND (winlostdate = @yesterday OR b.bettype > 20000) THEN winlost-actual_stake+playercomm ELSE 0 END)) * ActualRate
					) AS YesterdayTotalBalance_RM				
			FROM dbo.bettrans b WITH (NOLOCK)    
			WHERE EXISTS (SELECT TOP 1 1 FROM #CustInfo c WHERE b.mrecommend = c.CustId AND c.RoleId = 3)		
				AND b.ruben = 1
				AND b.winlostdate >= @yesterday
				AND 1 = CASE 
							WHEN bettype = 19999 and winlostdate > @moveBetsDay THEN 0 --> get data from ticket detail
							WHEN bettype < 19999 and winlostdate <= @moveBetsDay THEN 0 --> get data from sum record
						ELSE 1 END
			GROUP BY mrecommend, Winlostdate, Bettype
			)
		INSERT INTO #balanceInfo (CustId, TotalBalance, TotalBalance_RM, YesterdayTotalBalance, YesterdayTotalBalance_RM)
		SELECT  mrecommend,
				SUM (TotalBalance) AS TotalBalance,
				SUM (TotalBalance_RM) AS TotalBalance_RM,
				SUM (YesterdayTotalBalance) AS YesterdayTotalBalance,
				SUM (YesterdayTotalBalance_RM) AS YesterdayTotalBalance_RM			   
		FROM Bettrans_CTE b
		WHERE NOT EXISTS (SELECT 1 FROM #SportBettype s WHERE s.Bettype = b.bettype)  -- exclude  bettype of bettransRNG and bettransLC
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
			AND statusID NOT IN (0,1) 
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
			AND statusID NOT IN (0,1) 
			AND winlostdate >= @yesterday
		GROUP BY mrecommend

	END
		-- super
	IF EXISTS (SELECT TOP 1 1 FROM #CustInfo WHERE RoleId = 4)
	BEGIN
		-- bettrans
		INSERT INTO #balanceInfo (CustId, totalBalance, TotalBalance_RM, YesterdayTotalBalance, YesterdayTotalBalance_RM)
		SELECT
			srecommend,			
			SUM(
				  (CASE WHEN b.custid = b.srecommend THEN winlost-actual_stake ELSE swinlost+scomm-acomm END)
				+ (CASE WHEN b.custid = b.mrecommend THEN winlost-actual_stake ELSE mwinlost+acomm-comm END)
				+ (CASE WHEN b.custid = b.recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END)
				+ (CASE WHEN b.custid <> b.recommend AND b.custid <> b.mrecommend AND b.custid <> b.srecommend THEN winlost-actual_stake+playercomm ELSE 0 END)
				) totalBalance, 			
			SUM((
				  (CASE WHEN b.custid = b.srecommend THEN winlost-actual_stake ELSE swinlost+scomm-acomm END)
				+ (CASE WHEN b.custid = b.mrecommend THEN winlost-actual_stake ELSE mwinlost+acomm-comm END)
				+ (CASE WHEN b.custid = b.recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END)
				+ (CASE WHEN b.custid <> b.recommend AND b.custid <> b.mrecommend AND b.custid <> b.srecommend THEN winlost-actual_stake+playercomm ELSE 0 END)
				)* ActualRate ) TotalBalance_RM, 			
			SUM(
				  (CASE WHEN b.custid = b.srecommend THEN winlost-actual_stake ELSE swinlost+scomm-acomm END)
				+ (CASE WHEN b.custid = b.mrecommend THEN winlost-actual_stake ELSE mwinlost+acomm-comm END)
				+ (CASE WHEN b.custid = b.recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END)
				+ (CASE WHEN b.custid <> b.recommend AND b.custid <> b.mrecommend AND b.custid <> b.srecommend THEN winlost-actual_stake+playercomm ELSE 0 END)
				) YesterdayTotalBalance, 			
			SUM((
				  (CASE WHEN b.custid = b.srecommend THEN winlost-actual_stake ELSE swinlost+scomm-acomm END)
				+ (CASE WHEN b.custid = b.mrecommend THEN winlost-actual_stake ELSE mwinlost+acomm-comm END)
				+ (CASE WHEN b.custid = b.recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END)
				+ (CASE WHEN b.custid <> b.recommend AND b.custid <> b.mrecommend AND b.custid <> b.srecommend THEN winlost-actual_stake+playercomm ELSE 0 END)
				)* ActualRate ) YesterdayTotalBalance_RM			
		FROM dbo.bettrans b WITH(NOLOCK) 
			
		WHERE EXISTS (SELECT TOP 1 1 FROM #CustInfo c WHERE b.srecommend = c.CustId AND c.RoleId = 4)	
			AND b.ruben = 1
			AND b.winlostdate < @yesterday
			AND 1 = CASE 
						WHEN bettype = 19999 and winlostdate > @moveBetsDay THEN 0 --> get data from ticket detail
						WHEN bettype < 19999 and winlostdate <= @moveBetsDay THEN 0 --> get data from sum record
					ELSE 1 END
		GROUP BY srecommend
		
		 
		;WITH Bettrans_CTE AS (
			SELECT 
				srecommend, Winlostdate, Bettype,				
				SUM(
					  (CASE WHEN b.custid = b.srecommend THEN winlost-actual_stake ELSE swinlost+scomm-acomm END)
					+ (CASE WHEN custid = mrecommend THEN winlost-actual_stake ELSE mwinlost+acomm-comm END)
					+ (CASE WHEN custid = recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END) 
					+ (CASE WHEN custid <> recommend AND b.custid <> b.mrecommend AND b.custid <> b.srecommend THEN winlost-actual_stake+playercomm ELSE 0 END)
					) AS TotalBalance,
					
				SUM((
					(CASE WHEN b.custid = b.srecommend THEN winlost-actual_stake ELSE swinlost+scomm-acomm END)
					+ (CASE WHEN custid = mrecommend THEN winlost-actual_stake ELSE mwinlost+acomm-comm END)
					+ (CASE WHEN custid = recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END) 
					+ (CASE WHEN custid <> recommend AND b.custid <> b.mrecommend AND b.custid <> b.srecommend  THEN winlost-actual_stake+playercomm ELSE 0 END)) * ActualRate
					) AS TotalBalance_RM,
				
				SUM(
					(CASE WHEN (winlostdate = @yesterday OR b.bettype > 20000) 
							  THEN CASE WHEN custid = srecommend THEN winlost-actual_stake ELSE swinlost+scomm-acomm END
							  ELSE 0 END )	
					+(CASE WHEN (winlostdate = @yesterday OR b.bettype > 20000) 
							  THEN CASE WHEN custid = mrecommend THEN winlost-actual_stake ELSE mwinlost+acomm-comm END
							  ELSE 0 END )						   
					+(CASE WHEN (winlostdate = @yesterday OR b.bettype > 20000) 
							  THEN CASE WHEN custid = recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END 
							  ELSE 0 END ) 
					+ (CASE WHEN custid <> recommend AND b.custid <> b.mrecommend AND b.custid <> b.srecommend AND (winlostdate = @yesterday OR b.bettype > 20000) THEN winlost-actual_stake+playercomm ELSE 0 END)
					) AS YesterdayTotalBalance,
				
				SUM((
					(CASE WHEN (winlostdate = @yesterday OR b.bettype > 20000) 
							  THEN CASE WHEN custid = srecommend THEN winlost-actual_stake ELSE swinlost+scomm-acomm END
							  ELSE 0 END )	
					+ (CASE WHEN (winlostdate = @yesterday OR b.bettype > 20000) 
							  THEN CASE WHEN custid = mrecommend THEN winlost-actual_stake ELSE mwinlost+acomm-comm END
							  ELSE 0 END )
					+ (CASE WHEN (winlostdate = @yesterday OR b.bettype > 20000) 
							  THEN CASE WHEN custid = recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END 
							  ELSE 0 END ) 
					+ (CASE WHEN custid <> recommend AND b.custid <> b.mrecommend AND b.custid <> b.srecommend AND (winlostdate = @yesterday OR b.bettype > 20000) THEN winlost-actual_stake+playercomm ELSE 0 END)) * ActualRate
					) AS YesterdayTotalBalance_RM				
			FROM dbo.bettrans b WITH (NOLOCK)    
			WHERE EXISTS (SELECT TOP 1 1 FROM #CustInfo c WHERE b.srecommend = c.CustId AND c.RoleId = 4)	
				AND b.ruben = 1
				AND b.winlostdate >= @yesterday
				AND 1 = CASE 
							WHEN bettype = 19999 and winlostdate > @moveBetsDay THEN 0 --> get data from ticket detail
							WHEN bettype < 19999 and winlostdate <= @moveBetsDay THEN 0 --> get data from sum record
						ELSE 1 END
			GROUP BY srecommend, Winlostdate, Bettype
			)
		INSERT INTO #balanceInfo (CustId, TotalBalance, TotalBalance_RM, YesterdayTotalBalance, YesterdayTotalBalance_RM)
		SELECT  srecommend,
				SUM (TotalBalance) AS TotalBalance,
				SUM (TotalBalance_RM) AS TotalBalance_RM,
				SUM (YesterdayTotalBalance) AS YesterdayTotalBalance,
				SUM (YesterdayTotalBalance_RM) AS YesterdayTotalBalance_RM			   
		FROM Bettrans_CTE b
		WHERE NOT EXISTS (SELECT 1 FROM #SportBettype s WHERE s.Bettype = b.bettype)  -- exclude  bettype of bettransRNG and bettransLC
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
	END

		--headline
	IF EXISTS (SELECT TOP 1 1 FROM #CustInfo WHERE RoleId = 0)
	BEGIN
		-- headline - SMA(s) Cash 
		SELECT DISTINCT c.CustID AS SuperID
			, c.UplineID AS HeadlineID
		INTO #tempSuper
		FROM dbo.CustSuper c WITH (NOLOCK) 
		--INNER JOIN dbo.CS_CustSuper cs ON c.custid = cs.CustId
		INNER JOIN #CustInfo ci ON c.UplineID = ci.custid
		WHERE ci.RoleId = 0
		
		-- before yesterday
		INSERT INTO #balanceInfo (CustId, totalBalance, TotalBalance_RM, YesterdayTotalBalance, YesterdayTotalBalance_RM)
		SELECT
			cs.HeadlineID
			,0 AS totalBalance
			,0 AS totalBalance_RM
			,SUM(bal.totalBalance)	AS YesterdayTotalBalance
			,SUM(bal.totalBalance * actualrate) AS YesterdayTotalBalance_RM
		FROM dbo.bettrans b WITH(NOLOCK)
			INNER JOIN #tempSuper cs ON cs.SuperID = b.srecommend
			CROSS APPLY (
				 SELECT 
				 (CASE WHEN b.custid = b.srecommend THEN winlost-actual_stake ELSE swinlost+scomm-acomm END)
					+ (CASE WHEN b.custid = b.mrecommend THEN winlost-actual_stake ELSE mwinlost+acomm-comm END)
					+ (CASE WHEN b.custid = b.recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END)
					+ (CASE WHEN b.custid <> b.recommend AND b.custid <> b.mrecommend AND b.custid <> b.srecommend THEN winlost-actual_stake+playercomm ELSE 0 END) AS totalBalance
			) AS bal
		WHERE b.winlostdate < @yesterday
			AND b.ruben = 1
			AND 1 = CASE 
						WHEN bettype = 19999 and winlostdate > @moveBetsDay THEN 0 --> get data from ticket detail
						WHEN bettype < 19999 and winlostdate <= @moveBetsDay THEN 0 --> get data from sum record
					ELSE 1 END
		GROUP BY cs.HeadlineID

		-- yesterday & today
		;WITH Bettrans_CTE AS (
			SELECT 
				cs.HeadlineID
				,Bettype
				,0 AS TotalBalance
				,0 AS TotalBalance_RM
				,SUM(bal.YesterdayTotalBalance) AS YesterdayTotalBalance
				,SUM(bal.YesterdayTotalBalance * actualrate) AS YesterdayTotalBalance_RM
			FROM dbo.bettrans b WITH (NOLOCK)    
			INNER JOIN #tempSuper cs ON cs.SuperID = b.srecommend
			CROSS APPLY (
				SELECT (
						(CASE WHEN (winlostdate = @yesterday OR b.bettype > 20000) 
							  THEN CASE WHEN custid = srecommend THEN winlost-actual_stake ELSE swinlost+scomm-acomm END
							  ELSE 0 END )	
						+(CASE WHEN (winlostdate = @yesterday OR b.bettype > 20000) 
								  THEN CASE WHEN custid = mrecommend THEN winlost-actual_stake ELSE mwinlost+acomm-comm END
								  ELSE 0 END )						   
						+(CASE WHEN (winlostdate = @yesterday OR b.bettype > 20000) 
								  THEN CASE WHEN custid = recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END 
								  ELSE 0 END ) 
						+ (CASE WHEN custid <> recommend AND b.custid <> b.mrecommend AND b.custid <> b.srecommend AND (winlostdate = @yesterday OR b.bettype > 20000) THEN winlost-actual_stake+playercomm ELSE 0 END)
					) AS YesterdayTotalBalance -- up to yesterday

			) AS bal
			WHERE winlostdate >= @yesterday AND winlostdate <= @today
				AND b.ruben = 1
				AND 1 = CASE 
							WHEN bettype = 19999 and winlostdate > @moveBetsDay THEN 0 --> get data from ticket detail
							WHEN bettype < 19999 and winlostdate <= @moveBetsDay THEN 0 --> get data from sum record
						ELSE 1 END
			GROUP BY cs.HeadlineID, Bettype
		)
		INSERT INTO #balanceInfo (CustId, TotalBalance, TotalBalance_RM, YesterdayTotalBalance, YesterdayTotalBalance_RM)
		SELECT  HeadlineID,
				SUM (TotalBalance) AS TotalBalance,
				SUM (TotalBalance_RM) AS TotalBalance_RM,
				SUM (YesterdayTotalBalance) AS YesterdayTotalBalance,
				SUM (YesterdayTotalBalance_RM) AS YesterdayTotalBalance_RM			   
		FROM Bettrans_CTE b
		WHERE NOT EXISTS (SELECT 1 FROM #SportBettype s WHERE s.Bettype = b.bettype)  -- exclude  bettype of bettransRNG and bettransLC
		GROUP BY HeadlineID
 
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
		WHERE statusID NOT IN (0,1) 
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
		WHERE statusID NOT IN (0,1) 
			AND winlostdate >= @yesterday AND winlostdate <= @today
		GROUP BY cs.HeadlineID

		-- headline cash
		INSERT INTO #balanceInfo (CustId, totalBalance, TotalBalance_RM, YesterdayTotalBalance, YesterdayTotalBalance_RM)
		SELECT b.custid
			,0
			,0
			, SUM(b.winlost-b.actual_stake) AS YesterdayTotalCash
			, SUM((b.winlost-b.actual_stake) * actualRate) AS YesterdayTotalCash_RM
		FROM dbo.bettrans b WITH(NOLOCK)
		WHERE EXISTS (SELECT TOP 1 1 FROM #CustInfo t WHERE b.custid = t.custid AND RoleId = 0)
			AND b.matchid = 0
			AND b.bettype >= 20000
			AND b.winlostdate <= @today
		GROUP BY b.custid

		DROP TABLE #tempSuper
	END

	SELECT
		ci.CustId,
		SUM(ISNULL(bal.TotalBalance, 0)) TotalBalance,
		SUM(ISNULL(bal.TotalBalance_RM, 0)) TotalBalance_RM,
		SUM(ISNULL(bal.YesterdayTotalBalance, 0)) YesterdayTotalBalance,
		SUM(ISNULL(bal.YesterdayTotalBalance_RM, 0)) YesterdayTotalBalance_RM		
	FROM #CustInfo ci
	LEFT JOIN #balanceInfo bal ON ci.CustId = bal.custid
	GROUP BY ci.CustId

	DROP TABLE #SportBettype
	DROP TABLE #balanceInfo
	DROP TABLE #CustInfo
END
GO