/*<info serverAlias="DBTXN-bodb02" executers="bodbAdminNet,bodbExtAccNet" viewers="" isFunction="0" isNested="1"></info>*/
USE [bodb02]
GO

ALTER PROCEDURE [dbo].[Acc_CustomerTotalAmountSel]
	@custid			INT
	,@TotalAmt		MONEY = 0 OUTPUT
AS
/*
	Creator: Elodie
	Date: 20150612
	Task: Get total amount by custid
	Revisions:
		- 20150707@Jim: exclude Metric Gaming running ticket from bettrans (Feature #38789)
		- 20160118@Kathy: get balance from bettransRNG & bettransLC [Redmine:#50674]
		- 20180515@Percy: Add waiting tickets on translog table [RedmineID: #95219]
		- 20210505@Sol: NAP - Alpha - Allow more time for transfer - [Redmine: #149927]
*/
BEGIN	
	DECLARE @totalAmt_bettransRNG	MONEY = 0
			,@totalAmt_bettransLC	MONEY = 0
			,@totalAmt_translog		MONEY = 0
			,@yesterday				DATE
	
	SET @yesterday = CONVERT(DATE,GETDATE() - 1)

	----get movebetday
	DECLARE @balanceUpDay SMALLDATETIME, @moveBetsDay SMALLDATETIME
	DECLARE @tblMoveBetBalanceUp AS TABLE (BalanceUpDay SMALLDATETIME, MoveBetsDay SMALLDATETIME)

	INSERT INTO @tblMoveBetBalanceUp(BalanceUpDay,MoveBetsDay)
	EXEC bodb02.dbo.Age_SelBalanceUpDay
	
	SELECT @balanceUpDay = BalanceUpDay, @moveBetsDay = MoveBetsDay FROM @tblMoveBetBalanceUp
	
	-- translog
    SELECT	@totalAmt_translog = SUM(-actual_stake)
    FROM	dbo.translog WITH(NOLOCK)
    WHERE	custid = @CustId
			AND statusID IN (0, 1)
			
	-- bettransRNG
	SELECT	@totalAmt_bettransRNG = SUM(winlost - actual_stake + playercomm)
	FROM	dbo.bettransRnG WITH(NOLOCK)
	WHERE	custid = @custID 
			AND IsSum=0
			
	-- bettransLC
	SELECT	@totalAmt_bettransLC = SUM(winlost - actual_stake + playercomm)
	FROM	dbo.bettransLC WITH(NOLOCK)
	WHERE	custid = @custID 
			AND IsSum=0
  
	-- bettrans
	SELECT  @TotalAmt = sum(winlost-actual_stake+playercomm)
    FROM	dbo.bettrans b WITH(NOLOCK)
    WHERE	custid = @CustID
			AND (
					(b.bettype NOT IN (801,802,803,804,805,806)
					AND ruben =0) 
					OR ruben <> 0
					)
			AND 1 = CASE 
						WHEN bettype = 19999 and winlostdate > @moveBetsDay THEN 0 --> get data from ticket detail
						WHEN bettype < 19999 and winlostdate <= @moveBetsDay THEN 0 --> get data from sum record
					ELSE 1 END
    
	SET @TotalAmt = ISNULL(@TotalAmt,0)
					+ ISNULL(@totalAmt_translog,0) 
					+ ISNULL(@totalAmt_bettransRNG,0) 
					+ ISNULL(@totalAmt_bettransLC,0) 
END
GO