USE [bodb02]
GO
ALTER PROCEDURE [dbo].[NAP_Admin_Calculate_9_Cal]
	@matchid int,
	@matchdate smalldatetime,
	@mode int = 0 
AS  
/*
	Created: Kathy
	Date: 20140213
	Task : Settle bettrans based on bettransm (for mix parlay)
	DB: DB02.bodb02
	Original: Admin_Calculate_9_Cal

	Revisions:
		-20140502@Kathy: Calculate the execution time

	Param's Explanation:
		+ @matchid: matchid of match to be settled
		+ @matchdate match date
		+ @mode: 1: for testing
				 0: on production
*/
BEGIN
	SET NOCOUNT ON

	Declare @subStart datetime
	Declare @commWinRate smallmoney, @commLostRate smallmoney

	-- GET List of refno concern for input match(es)
	--Declare @tmp_mrefno
	--	TABLE (matchid int, refno bigint, statuswinlost tinyint, isdone bit)  

	DECLARE @tmp_mrefno TABLE (refno bigint)

	INSERT INTO @tmp_mrefno (refno)
		SELECT distinct refno
		FROM dbo.bettransm bm WITH (ROWLOCK)
		WHERE matchid = @matchid
	
	DECLARE @temp_bettrans_9 TABLE (
		[transid] [bigint] NOT NULL ,
		[custid] [int] NOT NULL,
		[refno] [bigint] unique clustered NOT NULL ,  
		[stake] [money] NOT NULL ,  
		[status] [nvarchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,  
		[winlost] [money] NULL ,  
		[awinlost] [money] NULL ,  
		[mwinlost] [money] NULL ,  
		[swinlost] [money] NULL ,  
		[winlostdate] [smalldatetime] NULL ,  
		[apositiontaking] [smallmoney] NOT NULL ,  
		[mpositiontaking] [smallmoney] NOT NULL ,  
		[spositiontaking] [smallmoney] NOT NULL ,  
		[playerdiscount] [float] NULL ,  
		[discount] [float] NULL ,  
		[adiscount] [float] NULL,  
		[sdiscount] [float] NULL,  
		[playercomm] [money] NULL ,  
		[comm] [money] NULL ,  
		[acomm] [money] NULL,  
		[scomm] [money] NULL,  
		[ruben] [tinyint] NULL ,
		[modds] [money] null,
		[statusID] [tinyint] NULL,
		comstatus nvarchar(20) NULL,
		IsUpdated [bit] NULL,     -- this field to stored value indicate if this row been change
		tloseCnt [tinyint] NULL,
		[oldruben] [tinyint] NULL, -- this field to keep previous ticket status (running or not?)
		[oldwinlostdate] [smalldatetime] NULL
	)   
	--create index temp_index on @temp_bettrans_9 (TransID)  
	-- GET list of concern Ticket
	SET @subStart = CURRENT_TIMESTAMP
		INSERT INTO @temp_bettrans_9 ([transid], [custid], [refno], [stake], [status],
				[winlost], [awinlost], [mwinlost], [swinlost],
				[winlostdate], [apositiontaking], [mpositiontaking], [spositiontaking],
				[playerdiscount], [discount], [adiscount], [sdiscount],
				[playercomm],  [comm], [acomm], [scomm],
				[ruben], [modds],[statusID], [comstatus],
				[oldruben], [oldwinlostdate] )
		SELECT
			[transid], [custid], b.[refno], [stake], [status],
			[winlost], [awinlost], [mwinlost], [swinlost],
			[winlostdate], [apositiontaking], [mpositiontaking], [spositiontaking],
			[playerdiscount], [discount], [adiscount], [sdiscount],
			[playercomm],  [comm], [acomm], [scomm],
			[ruben], [modds],[statusID], [comstatus],
			[ruben], [winlostdate]
		FROM dbo.bettrans b WITH (ROWLOCK)
			inner join @tmp_mrefno t on b.refno = t.refno
		WHERE 
			b.matchid = 9 
			AND bettype=9    
			AND statusID NOT IN (101,102) --('VOID','REJECT')
			--AND refno IN (SELECT refno FROM @tmp_mrefno)
		
	-- Results list from both bettransm & bettransm14
	Declare @parlay
		TABLE (refno bigint, matchid int, statuswinlost tinyint, statusID int, odds smallmoney, matchdate smalldatetime)

	INSERT INTO @parlay
		SELECT bm.refno, bm.matchid, bm.statuswinlost, statusID, odds, matchdate
		FROM dbo.bettransm bm with (rowlock) INNER JOIN @tmp_mrefno tm ON bm.refno = tm.refno

	INSERT INTO @parlay
		SELECT bm.refno, bm.matchid, bm.statuswinlost, statusID, odds, matchdate
		FROM dbo.bettransm14 bm with (rowlock) INNER JOIN @tmp_mrefno tm ON bm.refno = tm.refno
	
	-- CALCULATE effective odds value  
	Declare @modds
		TABLE (m_refno bigint PRIMARY KEY, modds money, NoRefund INT, loseCnt INT, runningCnt INT, matchdate_max smalldatetime)
	INSERT INTO @modds (m_refno, modds, NoRefund, loseCnt, runningCnt, matchdate_max)
		SELECT refno,
			EXP(SUM(LOG(
			case bm.statuswinlost
				when 0 then 1 -- draw
				when 1 then 1+((bm.odds-1)/2) -- half won
				when 2 then bm.odds -- won
				when 3 then 0.5 -- half lose
				when 4 then 0.000000000001 -- lose
				else 1 -- void/reject
			end
			))) as modds,
			SUM(
			case 
				when bm.statusID IN(121, 103) then 0			
				else 1
			end
			) as NoRefund,
			SUM(case
				when bm.statuswinlost = 4 then 1
				else 0
			end) as loseCnt,
			SUM(case
				when bm.statusID IN (0,1) then 1
				else 0
			end) as runningCnt,
			MAX(matchdate) AS matchdate_max
		FROM @parlay bm
		GROUP BY refno  
	

	Declare @statusID tinyint, @odds money
	Declare @oldstatusID tinyint, @oldwinlost money, @winlost money

	UPDATE T
	SET
		@oldstatusID = statusID,
		@oldwinlost = winlost,

		@statusID = statusID = CASE
			WHEN loseCnt > 0 THEN 113 -- Lose
			WHEN runningCnt > 0 THEN 0 -- running
			WHEN NoRefund = 0 THEN 103 -- Refund
			WHEN m.modds < 1 THEN 113 -- Lose
			WHEN m.modds = 1 THEN 111 -- Draw
			ELSE 112 -- Won
			END,
		status = CASE @statusID
			WHEN 0 THEN 'running'
			WHEN 103 THEN 'Refund'
			WHEN 111 THEN 'DRAW'
			WHEN 112 THEN 'WON'
			WHEN 113 THEN 'LOSE'
			END,
		ruben = CASE @statusID
			WHEN 0 THEN 0
			ELSE 1
			END,
		winlostdate = CASE @statusID
			WHEN 0 THEN m.matchdate_max
			ELSE @matchdate
			END,
		@odds = modds = CASE
			WHEN loseCnt > 0 THEN 0
			WHEN @statusID = 0 THEN 0
			ELSE m.modds
			END,
	
		@commWinRate = CASE comstatus -- 0 : pay normal, both win/lost -- 1 : pay 'double' ONLY on lost
		WHEN '0' THEN 1
		WHEN '1' THEN 0
		ELSE 1 END,
		@commLostRate = CASE comstatus
		WHEN '0' THEN 1
		WHEN '1' THEN 2
		ELSE 1 END,
	
		@winlost = winlost = CASE
			WHEN loseCnt > 0 THEN 0
			WHEN @statusID = 0 THEN 0
			ELSE stake*@odds
			END,
		awinlost = CASE 
			WHEN @statusID = 113 and loseCnt > 0  THEN  stake*apositiontaking
			WHEN @statusID IN (112, 113) THEN -stake*apositiontaking*(@odds-1)
			ELSE 0
			END,
		mwinlost = CASE
			WHEN @statusID = 113 and loseCnt > 0 THEN  stake*mpositiontaking
			WHEN @statusID IN (112, 113) THEN -stake*mpositiontaking*(@odds-1)		 
			ELSE 0
			END,
		swinlost = CASE
			WHEN @statusID = 113 and loseCnt > 0 THEN  stake*spositiontaking 
			WHEN @statusID IN (112, 113) THEN -stake*spositiontaking*(@odds-1)		
			ELSE 0
			END,

		playercomm	= CASE @statusID 
					WHEN 112 THEN @commWinRate  * stake*playerdiscount
					WHEN 113 THEN @commLostRate * stake*playerdiscount
					ELSE 0 END,
		comm		= CASE @statusID
					WHEN 112 THEN @commWinRate  * discount*stake*(1-apositiontaking)
					WHEN 113 THEN @commLostRate * discount*stake*(1-apositiontaking)
					ELSE 0 END,  
		acomm		= CASE @statusID
					WHEN 112 THEN @commWinRate  * adiscount*stake*(1-apositiontaking-mpositiontaking)
					WHEN 113 THEN @commLostRate * adiscount*stake*(1-apositiontaking-mpositiontaking)
					ELSE 0 END,
		scomm		= CASE @statusID
					WHEN 112 THEN @commWinRate  * sdiscount*stake*(1-apositiontaking-mpositiontaking-spositiontaking)
					WHEN 113 THEN @commLostRate * sdiscount*stake*(1-apositiontaking-mpositiontaking-spositiontaking)
					ELSE 0 END,
				
		IsUpdated = CASE
			WHEN (@oldstatusID <> @statusID) OR (@oldwinlost <> @winlost) THEN 1
			ELSE 0 END,
		tloseCnt = m.loseCnt

	FROM @temp_bettrans_9 T 
			INNER JOIN @modds m ON T.refno = m.m_refno
	
	-------------------------------------------------------------------------------------  

	-- UPDATE BACK TO BETTRANS  
	-- ONLY for ticket which result change OR winlost amount change
	-- ONLY update winlostdate when
		--+new status is "RUNNING" --> update to max_matchdate
		--+current status is RUNNING (ruben = 0) and new status is NOT RUNNING --> update to @matchdate


	IF @mode = 0
	BEGIN
		BEGIN TRANSACTION
			INSERT INTO dbo.bettrans_ParlayCalculateResult (transid, custid, statusID, modds, refno, winlostdate, loseCnt, matchid)
			SELECT
				transid, custid, statusID, modds, refno,
				CASE
				WHEN statusID = 0 THEN winlostdate
				WHEN oldruben = 0 AND statusID <> 0 THEN @matchdate
				ELSE oldwinlostdate END,
				tloseCnt, @matchid
			FROM @temp_bettrans_9
			WHERE IsUpdated = 1

			IF @@ROWCOUNT = 0
				UPDATE dbo.Parlay_Calculate_Queue WITH(UPDLOCK, ROWLOCK) 
					SET IsCalculating = 2,
					duration = DATEDIFF(ms,execTime,GETDATE())
				WHERE matchid = @matchid AND IsCalculating = 1


		COMMIT TRANSACTION
	END
	ELSE -- @mode = 1
	BEGIN
		-------------------------------------------------------------
		---        CAPTURE value BALANCE before settlement        ---
		---------------------------VVVV------------------------------
		DECLARE @SkipBalanceUpdate bit
		SET @SkipBalanceUpdate = 0

		CREATE TABLE #BalanceBefore (custid int PRIMARY KEY
										, balance money
									)
		DECLARE  @TotalAccount int
				,@TotalAccount_BalanceUpdate int

		IF @SkipBalanceUpdate = 0
		BEGIN
			INSERT INTO #BalanceBefore
			SELECT b.custid, SUM(b.winlost-b.actual_stake+b.playercomm)
			FROM dbo.bettrans b with (rowlock)
				INNER JOIN @temp_bettrans_9 t ON b.transid = t.transid
			GROUP BY b.custid

			SET @TotalAccount = @@ROWCOUNT
		
			-- no data? alright, stop process.
			IF @TotalAccount = 0 
				RETURN
		END --IF @SkipBalanceUpdate = 0

		UPDATE b WITH(ROWLOCK,UPDLOCK)
		SET statusID = t.statusID
			,status = t.status
			,ruben = t.ruben
			,winlostdate = t.winlostdate
			,modds = t.modds
			,winlost = t.winlost
			,awinlost = t.awinlost
			,mwinlost = t.mwinlost
			,swinlost = t.swinlost
			,playercomm = t.playercomm
			,comm = t.comm
			,acomm = t.acomm
			,scomm = t.scomm
		FROM bettrans b 
			INNER JOIN @temp_bettrans_9 t ON b.transid = t.transid
		WHERE t.IsUpdated = 1

		-------------------------------------------------------------
		---         CAPTURE value BALANCE after settlement        ---
		---------------------------VVVV------------------------------
		CREATE TABLE #BalanceAfter (custid int PRIMARY KEY
									,balance money
									)
		IF @SkipBalanceUpdate = 0
		BEGIN
			INSERT INTO #BalanceAfter
			SELECT b.custid, SUM(b.winlost-b.actual_stake+b.playercomm)
			FROM dbo.bettrans b with (rowlock)
				INNER JOIN @temp_bettrans_9 t ON b.transid = t.transid
			GROUP BY b.custid
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
			,134 --Task_Calculate_Parlay
			,2 -- Sportsbook Parlay Settlement 
			,CustID
			,Balance
			,0
			,NULL
		FROM #Balance WITH (NOLOCK)
		WHERE Increased = 0

		DROP TABLE #BalanceBefore
		DROP TABLE #Balance
		DROP TABLE #BalanceAfter
	END		
END
---------------------------------------------------------------
---------------------------------------------------------------
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Admin_Calculate_9_Cal] TO [vnteam] AS [dbo]