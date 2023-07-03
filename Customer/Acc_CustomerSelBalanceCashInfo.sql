/*<info serverAlias="DBAGE-bodb02,DBSIG-bodb02" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView,bodbExtAccNet" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerSelBalanceCashInfo]
	@CustId INT
AS

/*
	Created by Percy
	Date: 2017-10-18
	DB: DBAGE.bodb02
	Task: Get Balance Information of Customer

	Revisions:
		- 20171018@Percy: Get Balance Information of Customer by CustID [RedmineID: #84692]
		- 20180416@Sophia: Enhance performance high CPU for WC2018 [Redmine: #93100]
		- 20181003@Helen: Modify code to adapt indexes changed on DB053 [Redmine:101405]
		- 20190910@Bobby: Implement headline - balance info [Redmine:119961]
		- 20191225@Johnson: enhance sp get max transdate [redmine: #125894]
		- 20200602@Percy: Separate PendingTransfer3rd from Cash and Balance [RedmineID: #135200]
		- 20210505@Sol: NAP - Alpha - Allow more time for transfer - [Redmine: #149927]
		- 20211122@Danny: Split transfer tickets out of bettrans [Redmine: #164196]
		- 20220801@Sophia: Scale out DBTRANS, add metadata at SiteDB, remove DisableAutoMPT [RedmineID: #175253]
		- 20221104@Evan: Enhance performance get max transid [RedmineID: #180141]
		- 20230227@Evan: Balance-Up support transfer 247 [Redmine: #173554]
		- 20230706@Danny: deploy SP to SiteDB03 [Redmine: #181595]

	Param's Explaination:
		- @CustId: custid
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @yesterday SMALLDATETIME, @today SMALLDATETIME
	SELECT @today =   CAST(CURRENT_TIMESTAMP AS DATE)
		, @yesterday = CONVERT(DATE, DATEADD(DAY, -1, @today))

	-- get move bet date
	DECLARE @balanceUpDay SMALLDATETIME, @moveBetsDay SMALLDATETIME
	DECLARE @tblMoveBetBalanceUp AS TABLE (BalanceUpDay SMALLDATETIME, MoveBetsDay SMALLDATETIME)

	INSERT INTO @tblMoveBetBalanceUp(BalanceUpDay,MoveBetsDay)
	EXEC bodb02.dbo.Age_SelBalanceUpDay

	SELECT @balanceUpDay = BalanceUpDay, @moveBetsDay = MoveBetsDay FROM @tblMoveBetBalanceUp

	-- Get bettype --
	DECLARE @isTest BIT = 0
	SELECT  @isTest = dbo.f_CheckSPVersion(@@PROCID)
	
	CREATE TABLE #SportBettype (bettype INT, RefTable TINYINT)
	INSERT INTO #SportBettype (bettype, RefTable)
	SELECT bettype, RefTable FROM dbo.f_SportBettypeMatrix_Sel (0, 0, 0, 2, '', '', @isTest)

	DECLARE @roleID TINYINT, @srecommend INT, @ID INT = 1

	SELECT  @roleID = roleid , @srecommend = srecommend FROM DBCUST.CustDB.dbo.custInfo WITH(NOLOCK) WHERE custid = @custID
	
	IF ISNULL(@roleID, 5) > 4
	BEGIN
		RETURN
	END

	DECLARE @transdate DATETIME, @UsedCredit MONEY, @transid BIGINT, @transferid BIGINT
	
	DECLARE @MinDate SMALLDATETIME
	SELECT 	@MinDate = MIN (Winlostdate)
	FROM 	dbo.bettrans b WITH (NOLOCK)
	WHERE 	b.srecommend = @srecommend
			AND b.ruben = 0	
		
	-- Get Balance Information --
	CREATE TABLE #BalanceInfo
	(
		superCash MONEY, yesterday_superCash MONEY, superOutstanding MONEY,
		masterCash MONEY, yesterday_masterCash MONEY, masterOutstanding MONEY,
		agentCash MONEY, yesterday_agentCash MONEY, agentOutstanding MONEY,
		memberCash MONEY, yesterday_memberCash MONEY, memberOutstanding MONEY,
		PendingTransfer3rd MONEY DEFAULT (0)
	)

    IF @roleid = 1
	BEGIN
		
		SELECT @transid = MAX(transid) FROM bettrans WITH (NOLOCK) 
		WHERE custid = @custid
		OPTION(OPTIMIZE FOR	(@custid = -1))

		SELECT @transferid = MAX(transid) FROM dbo.Transfer WITH (NOLOCK) 
		WHERE custid = @custid
		AND bettype NOT IN (20000,19999)
		OPTION (OPTIMIZE FOR(@custid = -1))

		SELECT @transdate = MAX(transdate)
		FROM 
		(
			SELECT transdate FROM bettrans WITH (NOLOCK) WHERE transid = @transid
			UNION ALL
			SELECT transdate FROM dbo.Transfer WITH (NOLOCK) WHERE transid = @transferid
		) x

		-- bettransRNG
		INSERT INTO #BalanceInfo (memberCash, yesterday_memberCash, memberOutstanding)
		SELECT 
			SUM(CASE WHEN statusID NOT IN (0,1) THEN winlost-actual_stake+playercomm ELSE 0 END) memberCash,
			SUM(CASE WHEN statusID NOT IN (0,1) AND winlostdate = @yesterday THEN winlost-actual_stake+playercomm ELSE 0 END) yesterday_memberCash,
			SUM(CASE WHEN statusID IN (0,1) THEN ABS(actual_stake) ELSE 0 END) memberOutstanding
	    FROM dbo.bettransRNG WITH(NOLOCK)
		WHERE custid = @custid
			AND (winlostdate >= @yesterday
			OR statusID IN (0,1))

		-- bettransLC
		INSERT INTO #BalanceInfo (memberCash, yesterday_memberCash, memberOutstanding)
		SELECT 
			SUM(CASE WHEN statusID NOT IN (0,1) THEN winlost-actual_stake+playercomm ELSE 0 END) memberCash,
			SUM(CASE WHEN statusID NOT IN (0,1) AND winlostdate = @yesterday THEN winlost-actual_stake+playercomm ELSE 0 END) yesterday_memberCash,
			SUM(CASE WHEN statusID IN (0,1) THEN ABS(actual_stake) ELSE 0 END) memberOutstanding
	    FROM dbo.bettransLC WITH(NOLOCK)
		WHERE custid = @custid
			AND (winlostdate >= @yesterday
			OR statusID IN (0,1))

		-- translog
		INSERT INTO #BalanceInfo (memberCash, yesterday_memberCash, memberOutstanding)
		SELECT 0, 0, ABS(actual_stake)
	    FROM dbo.translog t WITH(NOLOCK)
		WHERE custid = @custid
			AND statusID IN (0,1)

		-- bettrans
		INSERT INTO #BalanceInfo (memberCash, yesterday_memberCash, memberOutstanding)
		SELECT 0, 0, ABS(actual_stake)
		FROM dbo.bettrans b WITH(NOLOCK)
		WHERE b.custid = @custid
			AND b.ruben = 0
			AND NOT EXISTS (SELECT TOP 1 1 FROM #SportBettype s WHERE s.Bettype = b.bettype AND s.RefTable <> 0)

		INSERT INTO #BalanceInfo (memberCash, yesterday_memberCash, memberOutstanding, PendingTransfer3rd)
		SELECT
			SUM( winlost-actual_stake+playercomm),
			SUM(CASE WHEN (winlostdate <= @yesterday) THEN winlost-actual_stake+playercomm ELSE 0 END),
			0,
			0
		FROM dbo.bettrans b WITH(NOLOCK)
		WHERE b.custid = @custid
			AND b.statusID IN (111, 112, 113)
			AND (
				b.winlostdate < @yesterday
				OR NOT EXISTS (SELECT TOP 1 1 FROM #SportBettype s WHERE s.Bettype = b.bettype AND s.RefTable IN (1, 2))
			)
			AND b.winlostdate > @moveBetsDay
		
		-- transfer
		INSERT INTO #BalanceInfo (memberCash, yesterday_memberCash, memberOutstanding, PendingTransfer3rd)
		SELECT
			SUM(CASE WHEN b.bettype IN (21008, 21009) THEN 0 ELSE winlost-actual_stake+playercomm END),
			SUM(CASE WHEN b.bettype IN (21008, 21009) THEN 0 ELSE winlost-actual_stake+playercomm END),
			0,
			SUM(CASE WHEN b.bettype IN (21008, 21009) THEN -(winlost-actual_stake) ELSE 0 END)
		FROM dbo.transfer b WITH(NOLOCK)
		WHERE b.custid = @custid
			AND 1 = CASE WHEN bettype = 19999 AND winlostdate > @moveBetsDay THEN 0 --> new sum
                        WHEN bettype = 20000 AND winlostdate > @balanceUpDay THEN 0 --> new bal
                        WHEN winlostdate < @balanceUpDay THEN 0 --> old data
                    ELSE 1 END

		SELECT
			SUM(memberCash) AS Cash,
			SUM(yesterday_memberCash) AS yesterday_Cash,
			SUM(memberOutstanding) AS outstanding,
			@transdate AS lastTxn
		FROM #BalanceInfo
    END 
    ELSE IF @roleid = 2
    BEGIN
	    SELECT @UsedCredit = SUM(credit)  
	    FROM DBCUST.CustDB.dbo.custinfo WITH(NOLOCK)
	    WHERE roleid = 1 AND recommend = @custid
		
		SELECT @transid = MAX(transid) FROM bettrans WITH (NOLOCK) 
		WHERE recommend = @custid
		OPTION(OPTIMIZE FOR	(@custid = -1))

		SELECT @transferid = MAX(transid) FROM dbo.Transfer WITH (NOLOCK) 
		WHERE recommend = @custid
		AND bettype NOT IN (20000,19999)
		OPTION (OPTIMIZE FOR(@custid = -1))

		SELECT @transdate = MAX(transdate)
		FROM 
		(
			SELECT transdate FROM bettrans WITH (NOLOCK) WHERE transid = @transid
			UNION ALL
			SELECT transdate FROM dbo.Transfer WITH (NOLOCK) WHERE transid = @transferid
		) x
		
		-- bettransRNG
		INSERT INTO #BalanceInfo (agentCash, yesterday_agentCash, agentOutstanding, memberCash, yesterday_memberCash, memberOutstanding)
		SELECT 
			SUM(CASE WHEN statusID NOT IN (0,1) THEN awinlost+comm-playercomm ELSE 0 END) agentCash,
			SUM(CASE WHEN statusID NOT IN (0,1) AND winlostdate = @yesterday THEN awinlost+comm-playercomm ELSE 0 END) yesterday_agentCash,
			SUM(CASE WHEN statusID IN (0,1) THEN ABS(actual_stake * apositiontaking) ELSE 0 END) agentOutstanding,
			SUM(CASE WHEN statusID NOT IN (0,1) THEN winlost-actual_stake+playercomm ELSE 0 END) memberCash,
			SUM(CASE WHEN statusID NOT IN (0,1) AND winlostdate = @yesterday THEN winlost-actual_stake+playercomm ELSE 0 END) yesterday_memberCash,
			SUM(CASE WHEN statusID IN (0,1) THEN ABS(actual_stake) ELSE 0 END) memberOutstanding
	    FROM dbo.bettransRNG WITH(NOLOCK)
		WHERE recommend = @custid
			AND (winlostdate >= @yesterday
			OR statusID IN (0,1))

		-- bettransLC
		INSERT INTO #BalanceInfo (agentCash, yesterday_agentCash, agentOutstanding, memberCash, yesterday_memberCash, memberOutstanding)
		SELECT 
			SUM(CASE WHEN statusID NOT IN (0,1) THEN awinlost+comm-playercomm ELSE 0 END) agentCash,
			SUM(CASE WHEN statusID NOT IN (0,1) AND winlostdate = @yesterday THEN awinlost+comm-playercomm ELSE 0 END) yesterday_agentCash,
			SUM(CASE WHEN statusID IN (0,1) THEN ABS(actual_stake * apositiontaking) ELSE 0 END) agentOutstanding,
			SUM(CASE WHEN statusID NOT IN (0,1) THEN winlost-actual_stake+playercomm ELSE 0 END) memberCash,
			SUM(CASE WHEN statusID NOT IN (0,1) AND winlostdate = @yesterday THEN winlost-actual_stake+playercomm ELSE 0 END) yesterday_memberCash,
			SUM(CASE WHEN statusID IN (0,1) THEN ABS(actual_stake) ELSE 0 END) memberOutstanding
	    FROM dbo.bettransLC WITH(NOLOCK)
		WHERE recommend = @custid
			AND (winlostdate >= @yesterday
			OR statusID IN (0,1))

		-- translog
		INSERT INTO #BalanceInfo (agentCash, yesterday_agentCash, agentOutstanding, memberCash, yesterday_memberCash, memberOutstanding)
		SELECT 0, 0, SUM(ABS(actual_stake*apositiontaking)), 0, 0, SUM(ABS(actual_stake))
	    FROM dbo.translog t WITH(NOLOCK)
		WHERE recommend = @custid
			AND statusID IN (0,1)

		-- bettrans 
		; WITH Bettrans_CTE AS (
				SELECT  Winlostdate, bettype , 
						SUM(ABS(actual_stake*apositiontaking)) AS agentOutstanding, 
						SUM(ABS(actual_stake)) AS memberOutstanding
				FROM dbo.bettrans b WITH(NOLOCK)   
				WHERE b.recommend = @custid
					AND b.ruben = 0	
					AND b.winlostdate >= @MinDate
				GROUP BY Winlostdate, bettype
			)			
		INSERT INTO #BalanceInfo (agentCash, yesterday_agentCash, agentOutstanding, memberCash, yesterday_memberCash, memberOutstanding)
		SELECT 0, 0, SUM(agentOutstanding), 0, 0, SUM(memberOutstanding)
		FROM Bettrans_CTE b 
		WHERE NOT EXISTS (SELECT TOP 1 1 FROM #SportBettype s WHERE s.Bettype = b.bettype AND s.RefTable <> 0)
		
		
		;WITH Bettrans_CTE AS (
		SELECT Winlostdate, Bettype,
			SUM(awinlost+comm-playercomm) AS agentCash,
			SUM(CASE WHEN (winlostdate <= @yesterday) THEN awinlost+comm-playercomm ELSE 0 END) AS yesterday_agentCash,
			SUM(winlost-actual_stake+playercomm ) AS memberCash,
			SUM(CASE WHEN winlostdate <= @yesterday THEN winlost-actual_stake+playercomm ELSE 0 END) AS yesterday_memberCash
		FROM dbo.bettrans b WITH(NOLOCK)
		WHERE b.recommend = @custid
			AND b.statusID IN (111, 112, 113)  
			AND b.winlostdate > @moveBetsDay
		GROUP BY Winlostdate, Bettype
		)	
		INSERT INTO #BalanceInfo (agentCash, yesterday_agentCash, agentOutstanding, memberCash, yesterday_memberCash, memberOutstanding, PendingTransfer3rd)
		SELECT	SUM(agentCash),
				SUM(yesterday_agentCash),
				0 AS agentOutstanding,
				SUM(memberCash),
				SUM(yesterday_memberCash),
				0 AS memberOutstanding,
				0 AS PendingTransfer3rd
		FROM Bettrans_CTE b
		WHERE	b.winlostdate < @yesterday  
				OR NOT EXISTS (SELECT TOP 1 1 FROM #SportBettype s WHERE s.Bettype = b.bettype AND s.RefTable IN (1, 2))

		INSERT INTO #BalanceInfo (agentCash, yesterday_agentCash, agentOutstanding, memberCash, yesterday_memberCash, memberOutstanding, PendingTransfer3rd)
		SELECT  SUM(CASE WHEN b.bettype IN (21008, 21009) THEN 0 ELSE CASE WHEN custid = recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END END) AS agentCash,
				SUM(CASE WHEN b.bettype IN (21008, 21009) THEN 0 ELSE CASE WHEN custid = recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END END) AS yesterday_agentCash,
				0 agentOutstanding,
				SUM(CASE WHEN b.bettype IN (21008, 21009) THEN 0 ELSE CASE WHEN custid <> recommend THEN winlost-actual_stake+playercomm ELSE 0 END END) AS memberCash,
				SUM(CASE WHEN b.bettype IN (21008, 21009) THEN 0 ELSE CASE WHEN custid <> recommend THEN winlost-actual_stake+playercomm ELSE 0 END END) AS yesterday_memberCash,
				0 memberOutstanding,
				SUM(CASE WHEN b.bettype IN (21008, 21009) THEN -(winlost-actual_stake) ELSE 0 END) AS PendingTransfer3rd
			FROM dbo.transfer b WITH(NOLOCK)
			WHERE b.recommend = @custid
				AND 1 = CASE WHEN bettype = 19999 AND winlostdate > @moveBetsDay THEN 0 --> new sum
		                    WHEN bettype = 20000 AND winlostdate > @balanceUpDay THEN 0 --> new bal
		                    WHEN winlostdate < @balanceUpDay THEN 0 --> old data
		                ELSE 1 END

		SELECT
			SUM(agentCash) AS agentCash,
			SUM(yesterday_agentCash) AS yesterday_agentCash,
			SUM(agentOutstanding) AS agentPositionTaking,
			SUM(memberCash) AS customerCash,
			SUM(yesterday_memberCash) AS yesterday_customerCash,
			SUM(memberOutstanding) AS customerOutstanding,
			SUM(PendingTransfer3rd) AS PendingTransfer3rd,
			@transdate AS lastTxn,
			@UsedCredit AS agentUsedCredit
		FROM #BalanceInfo
    END
    ELSE IF @roleid = 3
    BEGIN
	   
	    SELECT @UsedCredit = SUM(credit)  
	    FROM DBCUST.CustDB.dbo.custinfo WITH(NOLOCK) 
	    WHERE roleid=2 
		    AND mrecommend = @custid
		
		SELECT @transid = MAX(transid) FROM bettrans WITH (NOLOCK) 
		WHERE mrecommend = @custid
		OPTION(OPTIMIZE FOR	(@custid = -1))

		SELECT @transferid = MAX(transid) FROM dbo.Transfer WITH (NOLOCK) 
		WHERE mrecommend = @custid
			AND bettype NOT IN (20000,19999)
		OPTION (OPTIMIZE FOR(@custid = -1))

		SELECT @transdate = MAX(transdate)
		FROM
		(
			SELECT transdate  FROM bettrans WITH(NOLOCK) WHERE transid = @transid
			UNION ALL
			SELECT transdate  FROM dbo.Transfer WITH(NOLOCK) WHERE transid = @transferid
		) x
						
		-- bettransRNG
		INSERT INTO #BalanceInfo (masterCash, yesterday_masterCash, masterOutstanding, agentCash, yesterday_agentCash, memberCash, yesterday_memberCash, memberOutstanding)
		SELECT 
			SUM(CASE WHEN statusID NOT IN (0,1) THEN mwinlost+acomm-comm ELSE 0 END) masterCash,
			SUM(CASE WHEN statusID NOT IN (0,1) AND winlostdate = @yesterday THEN mwinlost+acomm-comm ELSE 0 END)  yesterday_masterCash,
			SUM(CASE WHEN statusID IN (0,1) THEN ABS(actual_stake * mpositiontaking) ELSE 0 END) masterOutstanding,
			SUM(CASE WHEN statusID NOT IN (0,1) THEN awinlost+comm-playercomm ELSE 0 END) agentCash,
			SUM(CASE WHEN statusID NOT IN (0,1) AND winlostdate = @yesterday THEN awinlost+comm-playercomm ELSE 0 END) yesterday_agentCash,
			SUM(CASE WHEN statusID NOT IN (0,1) THEN winlost-actual_stake+playercomm ELSE 0 END) memberCash,
			SUM(CASE WHEN statusID NOT IN (0,1) AND winlostdate = @yesterday THEN winlost-actual_stake+playercomm ELSE 0 END) yesterday_memberCash,
			SUM(CASE WHEN statusID IN (0,1) THEN ABS(actual_stake) ELSE 0 END) memberOutstanding
	    FROM dbo.bettransRNG WITH(NOLOCK)
		WHERE mrecommend = @custid
			AND (winlostdate >= @yesterday
			OR statusID IN (0,1))

		-- bettransLC
		INSERT INTO #BalanceInfo (masterCash, yesterday_masterCash, masterOutstanding, agentCash, yesterday_agentCash, memberCash, yesterday_memberCash, memberOutstanding)
		SELECT 
			SUM(CASE WHEN statusID NOT IN (0,1) THEN mwinlost+acomm-comm ELSE 0 END) masterCash,
			SUM(CASE WHEN statusID NOT IN (0,1) AND winlostdate = @yesterday THEN mwinlost+acomm-comm ELSE 0 END)  yesterday_masterCash,
			SUM(CASE WHEN statusID IN (0,1) THEN ABS(actual_stake * mpositiontaking) ELSE 0 END) masterOutstanding,
			SUM(CASE WHEN statusID NOT IN (0,1) THEN awinlost+comm-playercomm ELSE 0 END) agentCash,
			SUM(CASE WHEN statusID NOT IN (0,1) AND winlostdate = @yesterday THEN awinlost+comm-playercomm ELSE 0 END) yesterday_agentCash,
			SUM(CASE WHEN statusID NOT IN (0,1) THEN winlost-actual_stake+playercomm ELSE 0 END) memberCash,
			SUM(CASE WHEN statusID NOT IN (0,1) AND winlostdate = @yesterday THEN winlost-actual_stake+playercomm ELSE 0 END) yesterday_memberCash,
			SUM(CASE WHEN statusID IN (0,1) THEN ABS(actual_stake) ELSE 0 END) memberOutstanding
	    FROM dbo.bettransLC WITH(NOLOCK)
		WHERE mrecommend = @custid
			AND (winlostdate >= @yesterday
			OR statusID IN (0,1))

		-- translog
		INSERT INTO #BalanceInfo (masterCash, yesterday_masterCash, masterOutstanding, agentCash, yesterday_agentCash, memberCash, yesterday_memberCash, memberOutstanding)
		SELECT 0, 0, SUM(ABS(actual_stake*mpositiontaking)), 0, 0, 0, 0, SUM(ABS(actual_stake))
	    FROM dbo.translog t WITH(NOLOCK)
		WHERE mrecommend = @custid
			AND statusID IN (0,1)

		-- bettrans /* need check custid = recommend due to sum/balance/transfer tickets */
		; WITH Bettrans_CTE AS (
			SELECT  Winlostdate, bettype,
					SUM(ABS(actual_stake*mpositiontaking)) AS masterOutstanding,
					SUM(ABS(actual_stake)) AS memberOutstanding
			FROM dbo.bettrans b WITH(NOLOCK)
			WHERE b.mrecommend  = @CustId 
				AND b.recommend <> 0     --- level Agent and Customer
				AND b.ruben = 0
				AND b.winlostdate >= @MinDate
			GROUP BY Winlostdate, bettype
			 
			)		
		INSERT INTO #BalanceInfo (masterCash, yesterday_masterCash, masterOutstanding, agentCash, yesterday_agentCash, memberCash, yesterday_memberCash, memberOutstanding)
		SELECT 0, 0, SUM(masterOutstanding), 0, 0, 0, 0, SUM(memberOutstanding)
		FROM  Bettrans_CTE  b
		WHERE NOT EXISTS (SELECT TOP 1 1 FROM #SportBettype s WHERE s.Bettype = b.bettype AND s.RefTable <> 0)		
						
		; WITH Bettrans_CTE AS (
			SELECT  Winlostdate, bettype,
					SUM(mwinlost+acomm-comm) AS masterCash,
					SUM(CASE WHEN (winlostdate <= @yesterday) THEN mwinlost+acomm-comm ELSE 0 END) AS yesterday_masterCash,
					SUM(awinlost+comm-playercomm) AS agentCash,
					SUM(CASE WHEN (winlostdate <= @yesterday) THEN awinlost+comm-playercomm  ELSE 0 END) AS yesterday_agentCash,
					SUM(winlost-actual_stake+playercomm) AS memberCash,
					SUM(CASE WHEN (winlostdate <= @yesterday) THEN winlost-actual_stake+playercomm ELSE 0 END) AS yesterday_memberCash
				FROM dbo.bettrans b WITH(NOLOCK)
				WHERE   
					b.mrecommend = @CustId 
					AND b.statusID IN (111, 112, 113)
					AND b.winlostdate > @moveBetsDay
				GROUP BY Winlostdate, bettype
			)
		INSERT INTO #BalanceInfo (masterCash, yesterday_masterCash, masterOutstanding, agentCash, yesterday_agentCash, memberCash, yesterday_memberCash, memberOutstanding, PendingTransfer3rd)
		SELECT
			SUM(masterCash),
			SUM(yesterday_masterCash),
			0,
			SUM(agentCash),
			SUM(yesterday_agentCash),
			SUM(memberCash),
			SUM(yesterday_memberCash),
			0,
			0
		FROM Bettrans_CTE b
		WHERE b.winlostdate < @yesterday OR  NOT EXISTS (SELECT TOP 1 1 FROM #SportBettype s WHERE s.Bettype = b.bettype AND s.RefTable IN (1, 2))

		INSERT INTO #BalanceInfo (masterCash, yesterday_masterCash, masterOutstanding, agentCash, yesterday_agentCash, memberCash, yesterday_memberCash, memberOutstanding, PendingTransfer3rd)
		SELECT  SUM(CASE WHEN b.bettype IN (21008, 21009) THEN 0 ELSE CASE WHEN b.CustID = b.mrecommend THEN winlost-actual_stake ELSE mwinlost+acomm-comm END END) AS masterCash,
				SUM(CASE WHEN b.bettype IN (21008, 21009) THEN 0 ELSE CASE WHEN b.CustID = b.mrecommend THEN winlost-actual_stake ELSE mwinlost+acomm-comm END END) AS yesterday_masterCash,
				0 AS  masterOutstanding,
				SUM(CASE WHEN b.bettype IN (21008, 21009) THEN 0 ELSE CASE WHEN b.custid = b.recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END END) AS agentCash,
				SUM(CASE WHEN b.bettype IN (21008, 21009) THEN 0 ELSE CASE WHEN b.custid = b.recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END END) AS yesterday_agentCash,
				SUM(CASE WHEN b.bettype IN (21008, 21009) THEN 0 ELSE CASE WHEN b.custid <> b.recommend AND b.custid <> b.mrecommend THEN winlost-actual_stake+playercomm ELSE 0 END END) AS memberCash,
				SUM(CASE WHEN b.bettype IN (21008, 21009) THEN 0 ELSE CASE WHEN b.custid <> b.recommend AND b.custid <> b.mrecommend THEN winlost-actual_stake+playercomm ELSE 0 END END) AS yesterday_memberCash,
				0 AS memberOutstanding,
				SUM(CASE WHEN b.bettype IN (21008, 21009) THEN -(winlost-actual_stake) ELSE 0 END) AS PendingTransfer3rd
			FROM dbo.transfer b WITH(NOLOCK)
			WHERE   
				b.mrecommend = @CustId 
				AND 1 = CASE WHEN bettype = 19999 AND winlostdate > @moveBetsDay THEN 0 --> new sum
	                        WHEN bettype = 20000 AND winlostdate > @balanceUpDay THEN 0 --> new bal
	                        WHEN winlostdate < @balanceUpDay THEN 0 --> old data
                    	ELSE 1 END

		SELECT
			SUM(masterCash) AS masterCash,
			SUM(yesterday_masterCash) AS yesterday_masterCash,
			SUM(masterOutstanding) AS masterPositionTaking,
			SUM(agentCash) AS agentCash,
			SUM(yesterday_agentCash) AS yesterday_agentCash,
			SUM(memberCash) AS customerCash,
			SUM(yesterday_memberCash) AS yesterday_customerCash,
			SUM(memberOutstanding) AS customerOutstanding,
			SUM(PendingTransfer3rd) AS PendingTransfer3rd,
			@transdate AS lastTxn,
			@UsedCredit AS masterUsedCredit
		FROM #BalanceInfo
    END
    ELSE IF @roleid = 4
    BEGIN
	    SELECT @UsedCredit = SUM(credit) 
	    FROM DBCUST.CustDB.dbo.custinfo WITH(NOLOCK)
	    WHERE roleid=3
		     AND srecommend = @custid 	    	

		SELECT @transid = MAX(transid) FROM bettrans WITH (NOLOCK) 
		WHERE srecommend = @custid
		OPTION(OPTIMIZE FOR	(@custid = -1))

		SELECT @transferid = MAX(transid) FROM dbo.Transfer WITH (NOLOCK) 
		WHERE srecommend = @custid
			AND bettype NOT IN (20000,19999)
		OPTION (OPTIMIZE FOR(@custid = -1))
		
		SELECT @transdate = MAX(transdate) 
		FROM (
			SELECT transdate FROM bettrans WITH (NOLOCK) WHERE transid = @transid
			UNION ALL
			SELECT transdate FROM dbo.Transfer WITH (NOLOCK) WHERE transid = @transferid
		) x
		    	
		-- bettransRNG
		INSERT INTO #BalanceInfo (superCash, yesterday_superCash, superOutstanding, masterCash, yesterday_masterCash, agentCash, yesterday_agentCash, memberCash, yesterday_memberCash, memberOutstanding)
		SELECT 
		SUM(CASE WHEN statusID NOT IN (0,1) THEN swinlost+scomm-acomm ELSE 0 END),
			SUM(CASE WHEN statusID NOT IN (0,1) AND winlostdate = @yesterday THEN swinlost+scomm-acomm ELSE 0 END),
			SUM(CASE WHEN statusID IN (0,1) THEN ABS(actual_stake * spositiontaking) ELSE 0 END),
			SUM(CASE WHEN statusID NOT IN (0,1) THEN mwinlost+acomm-comm ELSE 0 END),
			SUM(CASE WHEN statusID NOT IN (0,1) AND winlostdate = @yesterday THEN mwinlost+acomm-comm ELSE 0 END),
			SUM(CASE WHEN statusID NOT IN (0,1) THEN awinlost+comm-playercomm ELSE 0 END),
			SUM(CASE WHEN statusID NOT IN (0,1) AND winlostdate = @yesterday THEN awinlost+comm-playercomm ELSE 0 END),
			SUM(CASE WHEN statusID NOT IN (0,1) THEN winlost-actual_stake+playercomm ELSE 0 END),
			SUM(CASE WHEN statusID NOT IN (0,1) AND winlostdate = @yesterday THEN winlost-actual_stake+playercomm ELSE 0 END),
			SUM(CASE WHEN statusID IN (0,1) THEN ABS(actual_stake) ELSE 0 END)
	    FROM dbo.bettransRNG WITH(NOLOCK)
		WHERE srecommend = @custid
			AND (
				statusID IN (0,1)
				OR winlostdate >= @yesterday
			)

		-- bettransLC
		INSERT INTO #BalanceInfo (superCash, yesterday_superCash, superOutstanding, masterCash, yesterday_masterCash, agentCash, yesterday_agentCash, memberCash, yesterday_memberCash, memberOutstanding)
		SELECT 
			SUM(CASE WHEN statusID NOT IN (0,1) THEN swinlost+scomm-acomm ELSE 0 END),
			SUM(CASE WHEN statusID NOT IN (0,1) AND winlostdate = @yesterday THEN swinlost+scomm-acomm ELSE 0 END),
			SUM(CASE WHEN statusID IN (0,1) THEN ABS(actual_stake * spositiontaking) ELSE 0 END),
			SUM(CASE WHEN statusID NOT IN (0,1) THEN mwinlost+acomm-comm ELSE 0 END),
			SUM(CASE WHEN statusID NOT IN (0,1) AND winlostdate = @yesterday THEN mwinlost+acomm-comm ELSE 0 END),
			SUM(CASE WHEN statusID NOT IN (0,1) THEN awinlost+comm-playercomm ELSE 0 END),
			SUM(CASE WHEN statusID NOT IN (0,1) AND winlostdate = @yesterday THEN awinlost+comm-playercomm ELSE 0 END),
			SUM(CASE WHEN statusID NOT IN (0,1) THEN winlost-actual_stake+playercomm ELSE 0 END),
			SUM(CASE WHEN statusID NOT IN (0,1) AND winlostdate = @yesterday THEN winlost-actual_stake+playercomm ELSE 0 END),
			SUM(CASE WHEN statusID IN (0,1) THEN ABS(actual_stake) ELSE 0 END)
	    FROM dbo.bettransLC WITH(NOLOCK)
		WHERE srecommend = @custid
			AND (
				statusID IN (0,1)
				OR winlostdate >= @yesterday
			)

		-- translog
		INSERT INTO #BalanceInfo (superCash, yesterday_superCash, superOutstanding, masterCash, yesterday_masterCash, agentCash, yesterday_agentCash, memberCash, yesterday_memberCash, memberOutstanding)
		SELECT 0, 0, SUM(ABS(actual_stake*spositiontaking)), 0, 0, 0, 0, 0, 0, SUM(ABS(actual_stake))
	    FROM dbo.translog t WITH(NOLOCK)
		WHERE srecommend = @custid
			AND statusID IN (0,1)

		-- bettrans 
		; WITH Bettrans_CTE AS (		
			SELECT WinlostDate, bettype,
				   SUM(ABS(actual_stake*spositiontaking)) AS superOutstanding, 
				   SUM(ABS(actual_stake)) AS memberOutstanding
			FROM dbo.bettrans b WITH(NOLOCK)
			WHERE  
				b.srecommend = @CustId
				AND b.ruben = 0
				AND b.winlostdate >= @MinDate			
			GROUP By WinlostDate, bettype
			)
		INSERT INTO #BalanceInfo (superCash, yesterday_superCash, superOutstanding, masterCash, yesterday_masterCash, agentCash, yesterday_agentCash, memberCash, yesterday_memberCash, memberOutstanding)
		SELECT 0, 0, SUM(superOutstanding), 0, 0, 0, 0, 0, 0, SUM(memberOutstanding) 
		FROM Bettrans_CTE b
		WHERE  NOT EXISTS (SELECT TOP 1 1 FROM #SportBettype s WHERE s.Bettype = b.bettype AND s.RefTable <> 0)

		;WITH Bettrans_CTE AS (
			SELECT winlostdate, Bettype,
					SUM(swinlost+scomm-acomm) superCash,
					SUM(CASE WHEN (winlostdate <= @yesterday) THEN swinlost+scomm-acomm ELSE 0 END) AS yesterday_superCash,	
					SUM(mwinlost+acomm-comm) AS masterCash,
					SUM(CASE WHEN (winlostdate <= @yesterday) THEN mwinlost+acomm-comm ELSE 0 END) as yesterday_masterCash,
					SUM(CASE WHEN custid = recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END) as agentCash,
					SUM(CASE WHEN (winlostdate <= @yesterday) THEN awinlost+comm-playercomm ELSE 0 END) as yesterday_agentCash,
					SUM(winlost-actual_stake+playercomm) as memberCash,
					SUM(CASE WHEN (winlostdate <= @yesterday) THEN winlost-actual_stake+playercomm ELSE 0 END) as yesterday_memberCash
			FROM dbo.bettrans b WITH(NOLOCK)
			WHERE 
				b.srecommend = @CustId
				AND b.statusID IN (111, 112, 113)
				AND b.winlostdate > @moveBetsDay
	
			GROUP BY winlostdate, Bettype 
		 )
		INSERT INTO #BalanceInfo (superCash, yesterday_superCash, superOutstanding, masterCash, yesterday_masterCash, agentCash, yesterday_agentCash, memberCash, yesterday_memberCash, memberOutstanding, PendingTransfer3rd)
		SELECT
			SUM(superCash),
			SUM(yesterday_superCash),
			0 superOutstanding,
			SUM(masterCash),
			SUM(yesterday_masterCash),
			SUM(agentCash),
			SUM(yesterday_agentCash),
			SUM(memberCash),
			SUM(yesterday_memberCash),
			0 memberOutstanding,
			0 PendingTransfer3rd
		FROM Bettrans_CTE b
		WHERE b.winlostdate < @yesterday OR  NOT EXISTS (SELECT TOP 1 1 FROM #SportBettype s WHERE s.Bettype = b.bettype AND s.RefTable IN (1, 2))

		INSERT INTO #BalanceInfo (superCash, yesterday_superCash, superOutstanding, masterCash, yesterday_masterCash, agentCash, yesterday_agentCash, memberCash, yesterday_memberCash, memberOutstanding, PendingTransfer3rd)
		SELECT	SUM(CASE WHEN b.bettype IN (21008, 21009) THEN 0 ELSE CASE WHEN custid = srecommend THEN winlost-actual_stake ELSE swinlost+scomm-acomm END END) superCash,
				SUM(CASE WHEN b.bettype IN (21008, 21009) THEN 0 ELSE CASE WHEN custid = srecommend THEN winlost-actual_stake ELSE swinlost+scomm-acomm END END) yesterday_superCash,	
				0 superOutstanding,
				SUM(CASE WHEN b.bettype IN (21008, 21009) THEN 0 ELSE CASE WHEN custid = mrecommend THEN winlost-actual_stake ELSE mwinlost+acomm-comm END END) masterCash,
				SUM(CASE WHEN b.bettype IN (21008, 21009) THEN 0 ELSE CASE WHEN custid = mrecommend THEN winlost-actual_stake ELSE mwinlost+acomm-comm END END) yesterday_masterCash,
				SUM(CASE WHEN b.bettype IN (21008, 21009) THEN 0 ELSE CASE WHEN custid = recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END END)  agentCash,
				SUM(CASE WHEN b.bettype IN (21008, 21009) THEN 0 ELSE CASE WHEN custid = recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END END)  yesterday_agentCash,
				SUM(CASE WHEN b.bettype IN (21008, 21009) THEN 0 ELSE CASE WHEN custid <> recommend AND custid <> mrecommend AND custid <> srecommend THEN winlost-actual_stake+playercomm ELSE 0 END END) as memberCash,
				SUM(CASE WHEN b.bettype IN (21008, 21009) THEN 0 ELSE CASE WHEN custid <> recommend AND custid <> mrecommend AND custid <> srecommend THEN winlost-actual_stake+playercomm ELSE 0 END END) as yesterday_memberCash,
				0 memberOutstanding,
				SUM(CASE WHEN b.bettype IN (21008, 21009) THEN -(winlost-actual_stake) ELSE 0 END) AS PendingTransfer3rd
		FROM dbo.transfer b WITH(NOLOCK)
		WHERE 
			b.srecommend = @CustId
			AND 1 = CASE WHEN bettype = 19999 AND winlostdate > @moveBetsDay THEN 0 --> new sum
	                    WHEN bettype = 20000 AND winlostdate > @balanceUpDay THEN 0 --> new bal
	                    WHEN winlostdate < @balanceUpDay THEN 0 --> old data
	                ELSE 1 END
		GROUP BY winlostdate, Bettype 

		SELECT
			SUM(superCash) AS superCash,
			SUM(yesterday_superCash) AS yesterday_superCash,
			SUM(superOutstanding) AS superPositionTaking,
			SUM(masterCash) AS masterCash,
			SUM(yesterday_masterCash) AS yesterday_masterCash,
			SUM(agentCash) AS agentCash,
			SUM(yesterday_agentCash) AS yesterday_agentCash,
			SUM(memberCash) AS customerCash,
			SUM(yesterday_memberCash) AS yesterday_customerCash,
			SUM(memberOutstanding) AS customerOutstanding,
			SUM(PendingTransfer3rd) AS PendingTransfer3rd,
			@transdate AS lastTxn,
			@UsedCredit AS superUsedCredit
		FROM #BalanceInfo
    END
	ELSE IF @roleid = 0
	BEGIN
		SELECT ISNULL(bal.yesterday_headlineCash, 0) AS yesterday_headlineCash
		FROM (
			VALUES (@custid)
		) AS ci (custid)
		OUTER APPLY (
			SELECT 
				SUM(b.winlost-b.actual_stake) AS yesterday_headlineCash
			FROM dbo.transfer b WITH(NOLOCK)
			WHERE b.custid = @custid
				AND b.bettype >= 20000
				AND 1 = CASE WHEN b.bettype = 20000 AND b.winlostdate > @BalanceUpDay THEN 0 --> new bal
							WHEN b.winlostdate < @BalanceUpDay THEN 0 --> old data
						ELSE 1 END
				AND b.winlostdate <= @today
		) AS bal
	END
	DROP TABLE #SportBettype
	DROP TABLE #BalanceInfo
END
GO