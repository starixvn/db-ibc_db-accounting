USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[NAP_Task_Calculate_Parlay]    Script Date: 08/07/2015 13:21:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.NAP_Task_Calculate_Parlay    Script Date: 02/05/2014 2:55:50 PM ******/
/****** Object:  Stored Procedure dbo.NAP_Task_Calculate_Parlay    Script Date: 3/17/2014 4:21:08 PM ******/

ALTER PROCEDURE [dbo].[NAP_Task_Calculate_Parlay] @step INT = 0
AS
/*
	Created by: Kathy
	Date: 20140218
	Task: Mix Parlay Settlement 
	DB: DBTXN/bodb02
	
	Revisions:
		- 20140502@Kathy: Calculate the execution time
		- 20150807@Kathy: Using new balance table (BalCreditSportsPending,BalDebitSportsPending) [Redmine:#40125]
		
*/
SET NOCOUNT ON

DECLARE @SkipBalanceUpdate BIT

SET @SkipBalanceUpdate = 0

DECLARE @matchid INT
	,@statusID TINYINT
	,@winlostdate SMALLDATETIME
	,@ActionID INT

SELECT @ActionID = 134 --Task_Calculate_Parlay

-- step 1 : move data going to process into middle-table
IF @step = 1
BEGIN
	SELECT TOP (1) @statusID = statusID
		,@winlostdate = winlostdate
	FROM dbo.bettrans_ParlayCalculateResult WITH (NOLOCK)
	GROUP BY statusID
		,winlostdate
	ORDER BY MIN(rowID)

	IF @statusID IS NOT NULL
	BEGIN
		BEGIN TRANSACTION

		DELETE subq
		OUTPUT deleted.transid
			,deleted.custid
			,deleted.statusid
			,deleted.winlostdate
			,deleted.modds
			,deleted.refno
			,deleted.loseCnt
			,deleted.matchid
		INTO dbo.bettrans_ParlayCalculateTransmission(transid, custid, statusid, winlostdate, modds, refno, loseCnt, matchid)
		FROM (
			SELECT TOP (100) *
			FROM dbo.bettrans_ParlayCalculateResult
			WHERE statusID = @statusID AND winlostdate = @winlostdate
			ORDER BY rowID
			) subq

		COMMIT TRANSACTION
	END
END

-- step 2 : get the balance/update bettrans/update balance
IF @step = 2
BEGIN
	IF NOT EXISTS (
			SELECT TOP (1) 1
			FROM dbo.bettrans_ParlayCalculateTransmission
			) RETURN

	DECLARE @strXML VARCHAR(MAX)

	SET @strXML = ''

	-------------------------------------------------------------
	---        CAPTURE value BALANCE before settlement        ---
	---------------------------VVVV------------------------------
	CREATE TABLE #BalanceBefore (
		custid INT PRIMARY KEY
		,balance MONEY
		)

	DECLARE @TotalAccount INT
		,@TotalAccount_BalanceUpdate INT

	IF @SkipBalanceUpdate = 0
	BEGIN
		--===
		INSERT INTO #BalanceBefore
		SELECT t.custid
			,SUM(winlost - actual_stake + playercomm)
		FROM dbo.bettrans b WITH (ROWLOCK)
			INNER JOIN dbo.bettrans_ParlayCalculateTransmission t ON b.transid = t.transid
		GROUP BY t.custid

		SET @TotalAccount = @@ROWCOUNT

		-- no data? alright, stop process.
		IF @TotalAccount = 0 RETURN
				--===
	END --IF @SkipBalanceUpdate = 0

	SET @strXML = CONVERT(VARCHAR(max), (
				SELECT transid '@t'
					,NULLIF(modds, 0) '@m'
					,NULLIF(loseCnt, 0) '@l'
				FROM dbo.bettrans_ParlayCalculateTransmission
				FOR XML PATH('r')
					,ROOT('root')
					,TYPE
				))

	SELECT TOP (1) @matchid = matchid
		,@statusID = statusID
		,@winlostdate = winlostdate
	FROM dbo.bettrans_ParlayCalculateTransmission

	---- use this SP called when on UAT
	--		EXEC dbo.Admin_Calculate_9m  -- the first 6 params can be passed any values in case of @mode = 1
	--		@matchid	= 0,
	--		@fth		= 0, 
	--		@fta		= 0,
	--		@hth		= 0, 
	--		@hta		= 0,
	--		@matchdate	= '2013-01-01',
	--		@mode = 1,
	--		@statusID = @statusID, @winlostdate = @winlostdate,
	--		@strXML = @strXML
		EXEC dbo.NAP_Admin_Calculate_Parlay @mode = 'CAL-9'
		,@statusID = @statusID
		,@winlostdate = @winlostdate
		,@strXML = @strXML

	--EXEC dbo.Admin_Calculate_9 
	--		@statusID = @statusID, 
	--		@winlostdate = @winlostdate,
	--		@strXML = @strXML
	-------------------------------------------------------------
	---         CAPTURE value BALANCE after settlement        ---
	---------------------------VVVV------------------------------
	CREATE TABLE #BalanceAfter (
		custid INT PRIMARY KEY
		,balance MONEY
		)

	IF @SkipBalanceUpdate = 0
	BEGIN
		--===
		INSERT INTO #BalanceAfter
		SELECT t.custid
			,SUM(winlost - actual_stake + playercomm)
		FROM dbo.bettrans b WITH (ROWLOCK)
			INNER JOIN dbo.bettrans_ParlayCalculateTransmission t ON b.transid = t.transid
		GROUP BY t.custid
			--===
	END --IF @SkipBalanceUpdate = 0

	-------------------------------------------------------------
	---                   compare BALANCE                     ---
	---------------------------VVVV------------------------------
	CREATE TABLE #Balance (
		custid INT PRIMARY KEY
		,balance MONEY
		,Increased BIT
		)
	
	DECLARE @tblDebitPending BalanceList
	DECLARE @tblCreditPending BalanceList
	
	CREATE INDEX IX_Balance_Increased ON #Balance (Increased)

	INSERT INTO #Balance
	SELECT b.custid
		,a.balance - b.balance
		,CASE 
			WHEN a.balance > b.balance THEN 1
			ELSE 0
			END
	FROM #BalanceBefore b
		INNER JOIN #BalanceAfter a ON b.custid = a.custid
	WHERE b.balance <> a.balance

	SET @TotalAccount_BalanceUpdate = @@ROWCOUNT

	--INSERT INTO dbo.BalancePendingDebit (
	--	custid
	--	,balance
	--	)
	--SELECT custid
	--	,ABS(balance)
	--FROM #Balance
	--WHERE Increased = 0
	
	INSERT INTO @tblDebitPending (custID, balance)
	SELECT	custid, ABS(balance)
	FROM	#Balance
	WHERE	Increased = 0
	
	IF @@rowcount <> 0
		EXEC dbo.Dot_BalancePendingDebitIns 
			@BalancePending = @tblDebitPending
			,@Type			= 1 -- Sports
			
	--INSERT INTO dbo.BalancePendingCredit (
	--	custid
	--	,balance
	--	)
	--SELECT custid
	--	,balance
	--FROM #Balance
	--WHERE Increased = 1

	INSERT INTO @tblCreditPending (custID, balance)
	SELECT	custid, balance
	FROM	#Balance
	WHERE	Increased = 1
	
	IF @@rowcount <> 0
		EXEC dbo.Dot_BalancePendingCreditIns 
			@BalancePending = @tblCreditPending
			,@Type			= 1 -- Sports
	----
	-- Add Negative Balance into BalanceNegative table 
	----
	INSERT INTO [bodb02].[dbo].[BalanceNegative] (
		[ExecDate]
		,[MatchID]
		,[ActionID]
		,[GroupID]
		,[CustID]
		,[Balance]
		,[StatusID]
		,[Remark]
		)
	SELECT GETDATE()
		,@MatchID
		,@ActionID
		,2 -- Sportsbook Parlay Settlement 
		,CustID
		,Balance
		,0
		,NULL
	FROM #Balance WITH (NOLOCK)
	WHERE Increased = 0

	---------------------------------------------------	
	DROP TABLE #Balance

	DROP TABLE #BalanceBefore

	DROP TABLE #BalanceAfter

	---
	---
	---
	DELETE
	FROM dbo.bettrans_ParlayCalculateTransmission

	IF NOT EXISTS (
			SELECT TOP (1) 1
			FROM dbo.bettrans_ParlayCalculateResult
			WHERE matchid = @matchid
			)
		UPDATE dbo.Parlay_Calculate_Queue WITH (UPDLOCK, ROWLOCK)
		SET IsCalculating = 2,
			duration = DATEDIFF(ms,execTime,GETDATE())
		WHERE matchid = @matchid AND IsCalculating = 1
END

GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Task_Calculate_Parlay] TO [vnteam] AS [dbo]