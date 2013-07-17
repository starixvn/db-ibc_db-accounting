ALTER PROCEDURE [dbo].[Task_Calculate_Parlay]
	@step int = 0
AS
/*
	Created by: Viet
	Date: 2013-07-11
	Task: Mix Parlay Settlement 
	DB: DBTXN/bodb02
	
	Revisions:
		- 20130711@Jamie: Add BalanceNegative & SET NOCOUNT ON 

*/

SET NOCOUNT ON 

Declare @SkipBalanceUpdate bit
SET @SkipBalanceUpdate = 0

Declare @matchid int, @statusID tinyint, @winlostdate smalldatetime
		,@ActionID	INT
		
SELECT	@ActionID = 134   --Task_Calculate_Parlay

-- step 1 : move data going to process into middle-table
IF @step = 1
BEGIN
	SELECT TOP (1) @statusID = statusID, @winlostdate = winlostdate
	from dbo.bettrans_Calculate_tmp with (nolock)
	GROUP BY statusID, winlostdate
	ORDER BY MIN(rowID)
	
	IF @statusID IS NOT NULL
	BEGIN
		BEGIN TRANSACTION
		DELETE subq
		OUTPUT deleted.transid, deleted.custid, deleted.statusid, deleted.winlostdate, deleted.modds, deleted.refno, deleted.loseCnt, deleted.matchid
		INTO dbo.bettrans_Calculate_job (transid, custid, statusid, winlostdate, modds, refno, loseCnt, matchid)
		FROM (
			SELECT TOP (1000) *
			FROM dbo.bettrans_Calculate_tmp
			WHERE statusID = @statusID AND winlostdate = @winlostdate
			ORDER BY rowID
		) subq
		COMMIT TRANSACTION
	END
END


-- step 2 : get the balance/update bettrans/update balance
IF @step = 2
BEGIN

	Declare @strXML varchar(MAX)
	SET @strXML = ''


	-------------------------------------------------------------
	---        CAPTURE value BALANCE before settlement        ---
	---------------------------VVVV------------------------------
	CREATE TABLE #BalanceBefore (custid int PRIMARY KEY, balance money)
	Declare @TotalAccount int, @TotalAccount_BalanceUpdate int
	IF @SkipBalanceUpdate = 0
	BEGIN
	--===
		INSERT INTO #BalanceBefore
		SELECT t.custid, SUM(winlost-actual_stake+playercomm)
		FROM dbo.bettrans b with (rowlock)
			INNER JOIN dbo.bettrans_Calculate_job t ON b.transid = t.transid
		GROUP BY t.custid

		SET @TotalAccount = @@ROWCOUNT
		
		-- no data? alright, stop process.
		IF @TotalAccount = 0 RETURN
	--===
	END --IF @SkipBalanceUpdate = 0

		SET @strXML = CONVERT(varchar(max),(
			SELECT
				transid '@t'
				,NULLIF(modds,0) '@m'
				,NULLIF(loseCnt,0) '@l'
			FROM dbo.bettrans_Calculate_job						
			FOR XML PATH('r'), ROOT('root'), TYPE
		))				

		SELECT TOP (1) @matchid = matchid, @statusID = statusID, @winlostdate = winlostdate
		FROM dbo.bettrans_Calculate_job
		
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
		
		EXEC dbo.Admin_Calculate_9 
				@statusID = @statusID, 
				@winlostdate = @winlostdate,
				@strXML = @strXML
	-------------------------------------------------------------
	---         CAPTURE value BALANCE after settlement        ---
	---------------------------VVVV------------------------------
	CREATE TABLE #BalanceAfter (custid int PRIMARY KEY, balance money)
	IF @SkipBalanceUpdate = 0
	BEGIN
	--===
		INSERT INTO #BalanceAfter
		SELECT t.custid, SUM(winlost-actual_stake+playercomm)
		FROM dbo.bettrans b with (rowlock)
			INNER JOIN dbo.bettrans_Calculate_job t ON b.transid = t.transid
		GROUP BY t.custid
	--===
	END --IF @SkipBalanceUpdate = 0

	-------------------------------------------------------------
	---                   compare BALANCE                     ---
	---------------------------VVVV------------------------------
	CREATE TABLE #Balance (custid int PRIMARY KEY, balance money, Increased bit)
	CREATE INDEX IX_Balance_Increased ON #Balance (Increased)

	INSERT INTO #Balance
	SELECT b.custid, a.balance - b.balance, CASE WHEN a.balance > b.balance THEN 1 ELSE 0 END
	FROM #BalanceBefore b
		INNER JOIN #BalanceAfter a ON b.custid = a.custid
	WHERE b.balance <> a.balance

	SET @TotalAccount_BalanceUpdate = @@ROWCOUNT


	INSERT INTO dbo.BalancePendingDebit (custid, balance)
	SELECT custid, ABS(balance)
	FROM #Balance
	WHERE Increased = 0

	INSERT INTO dbo.BalancePendingCredit (custid, balance)
	SELECT custid, balance
	FROM #Balance
	WHERE Increased = 1
	
	----
	-- Add Negative Balance into BalanceNegative table 
	----
	INSERT INTO [bodb02].[dbo].[BalanceNegative]
			   ([ExecDate]
			   ,[MatchID]
			   ,[ActionID]
			   ,[GroupID]
			   ,[CustID]
			   ,[Balance]
			   ,[StatusID]
			   ,[Remark])
	SELECT	 GETDATE()
			,@MatchID
			,@ActionID
			,2			-- Sportsbook Parlay Settlement 
			,CustID
			,Balance
			,0
			,NULL 
	FROM	#Balance WITH (NOLOCK)
	WHERE	Increased = 0
			        
	---------------------------------------------------	


	DROP TABLE #Balance
	DROP TABLE #BalanceBefore
	DROP TABLE #BalanceAfter

	---
	---
	---
	DELETE FROM dbo.bettrans_Calculate_job
	IF NOT EXISTS (SELECT TOP (1) 1 FROM dbo.bettrans_Calculate_tmp WHERE matchid = @matchid)
		DELETE FROM dbo.Parlay_WaitingList WHERE matchid = @matchid

END