USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[NAP_Admin_Calculate_9_Cal]    Script Date: 09/16/2015 13:43:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[NAP_Admin_Calculate_9_Cal]
	@matchid int,
	@matchdate smalldatetime
AS  
/*
	Created: Kathy
	Date: 20140213
	Task : Settle bettrans based on bettransm (for mix parlay)
	DB: DBTXN/bodb02
	Original: Admin_Calculate_9_Cal

	Revisions:
		- 20140502@Kathy: Calculate the execution time
		- 20150506@Kathy: Do not calculate main ticket if subticket is still waiting or rejected [Redmine:#35336]
		- 20150609@Jamie: Correct the winlostdate of main ticket [HotFix #37418]
		- 20150720@Kathy: Correct the winlostdate of main ticket [HotFix #37418]		
		- 20150914@Kathy: Using function f_moddsParlay to calculate modds [Redmine:#43566]
	Param's Explanation:
		+ @matchid: matchid of match to be settled
		+ @matchdate match date
*/
BEGIN
	SET NOCOUNT ON	
	DECLARE @modds smallmoney, @statusID tinyint, @winlostdate smalldatetime
			,@oldstatusID tinyint, @oldwinlost money, @winlost money
	
	CREATE TABLE #temp_bettrans_9 (		
		[transid] [bigint] NOT NULL,
		[winlostdate] [smalldatetime] NULL,
		[refno] [bigint] NOT NULL,
		[statusID] [tinyint] NULL,
		[winlost] [money] NULL , 
		[stake] [money] NOT NULL ,   
		[IsUpdated] [bit] NULL     -- this field to stored value indicate if this row been change
	)
	
	INSERT INTO #temp_bettrans_9 (transid, refno, winlostdate, statusid, winlost, stake)
	SELECT transid, refno, winlostdate, statusid, winlost, stake
	FROM dbo.bettrans b WITH(NOLOCK)
	WHERE matchid = 9
		AND bettype = 9		
		AND statusID NOT IN (101,102) --('VOID','REJECT')
		AND refno IN (
			SELECT refno
			FROM dbo.bettransm bm WITH(ROWLOCK)
			WHERE matchid = @matchid
				AND NOT EXISTS (
					SELECT 1 FROM bettransm WITH(NOLOCK) WHERE refno = bm.refno AND statusID IN(1, 101)
				) -- dont calculate main ticket if subticket is still waiting or rejected
		)	
 
	UPDATE t
	SET @modds = dbo.f_moddsParlay(s.refno)
		,@oldstatusID = statusID
		,@oldwinlost = winlost
		,@statusID = statusID = CASE
			WHEN loseCnt > 0 THEN 113 -- Lose
			WHEN runningCnt > 0 THEN 0 -- running
			WHEN NoRefund = 0 THEN 103 -- Refund
			WHEN @modds < 1 THEN 113 -- Lose
			WHEN @modds = 1 THEN 111 -- Draw
			ELSE 112 -- Won
			END
		,@Winlost = winlost = CASE
								WHEN loseCnt > 0 THEN 0
								WHEN @statusId = 0 THEN 0
								ELSE stake * @modds
								END
		,winlostdate = CASE 
							WHEN @statusID IN (0, 103,111,112) THEN s.matchdate_max
							WHEN @statusID = 113 THEN @matchdate
						END
		,IsUpdated = CASE 
						WHEN (@oldstatusID <> @statusID) OR (@oldwinlost <> @winlost) THEN 1
						ELSE 0
						END
	FROM (
			SELECT bm.refno as refno
				,SUM(CASE WHEN bm.statusID IN (121, 103) THEN 0 ELSE 1 END) as NoRefund
				,SUM(CASE WHEN bm.statuswinlost = 4 THEN 1 ELSE 0 END) as loseCnt
				,SUM(CASE WHEN bm.statusID IN (0, 1) THEN 1 ELSE 0 END) as runningCnt
				,MAX(winlostdate) as matchdate_max
			FROM (
				SELECT	bm.transid, bm.refno, bm.statuswinlost, statusID, winlostdate 
				FROM	dbo.bettransm bm WITH(rowlock)						
				UNION
				SELECT	bm.transid, bm.refno, bm.statuswinlost, statusID, winlostdate 
				FROM	dbo.bettransm14 bm WITH(rowlock)			
			) bm
			GROUP BY refno
		) s
		INNER JOIN #temp_bettrans_9 t ON s.refno = t.refno

	DELETE 
	FROM	#temp_bettrans_9
	WHERE	IsUpdated = 0	
	
	DECLARE @tempStatus as TABLE (statusID tinyint, winlostdate smalldatetime, isfinished bit)
	DECLARE @tempTransID as TABLE(transID bigint)
	DECLARE @strTransIds varchar(MAX) = ''

	CREATE INDEX IX_temp_bettrans_9 ON #temp_bettrans_9 (statusid, winlostdate)
	
	INSERT INTO @tempStatus (statusID, winlostdate, isfinished)
	SELECT distinct statusID, winlostdate, 0
	FROM #temp_bettrans_9	

	-- for balance table --	
	CREATE TABLE #BalanceBefore (custid int PRIMARY KEY,balance money)	
	CREATE TABLE #BalanceAfter (custid int PRIMARY KEY,balance money)
	CREATE TABLE #Balance (custid int PRIMARY KEY, balance money, Increased bit)
	CREATE INDEX IX_Balance_Increased ON #Balance (Increased)
	-------------------

	WHILE (1 = 1)
	BEGIN
		UPDATE TOP (1) @tempStatus
		SET isfinished = 1
			,@statusID = statusID
			,@winlostdate = winlostdate
		WHERE isfinished = 0

		IF @@ROWCOUNT = 0 BREAK -- no more to do

		WHILE (1 = 1)
		BEGIN
			DELETE @tempTransID
			TRUNCATE TABLE #BalanceBefore
			TRUNCATE TABLE #BalanceAfter
			TRUNCATE TABLE #Balance

			DELETE TOP (2000) #temp_bettrans_9
			OUTPUT	deleted.transID into @tempTransID(transid)
			WHERE	statusID = @statusID 
					AND winlostdate = @winlostdate

			IF @@ROWCOUNT = 0 BREAK

			SET @strTransIds = STUFF((
				SELECT ',' + cast(transid as varchar(20)) 
				FROM @tempTransID 
				FOR XML PATH('')
			), 1,1,'')
						
			-------------------------------------------------------------
			---        CAPTURE value BALANCE before settlement        ---
			---------------------------VVVV------------------------------
			INSERT INTO #BalanceBefore
			SELECT b.custid, SUM(b.winlost-b.actual_stake+b.playercomm)
			FROM dbo.bettrans b with (rowlock)
			WHERE transid IN (SELECT transid FROM @tempTransID)
			GROUP BY b.custid				
			--------------------------------------------------------------
			
			EXEC dbo.NAP_Admin_Calculate_Parlay
				@action = 'CAL-9'
				,@strXML = @strTransIds 
				,@statusID = @statusID
				,@winlostdate = @winlostdate 

			-------------------------------------------------------------
			---         CAPTURE value BALANCE after settlement        ---
			---------------------------VVVV------------------------------
			INSERT INTO #BalanceAfter
			SELECT b.custid, SUM(b.winlost-b.actual_stake+b.playercomm)
			FROM dbo.bettrans b with(rowlock)
			WHERE transid IN (SELECT transid FROM @tempTransID)
			GROUP BY b.custid

			-------------------------------------------------------------
			---                   compare BALANCE                     ---
			---------------------------VVVV------------------------------
			INSERT INTO #Balance
			SELECT b.custid, a.balance - b.balance, CASE WHEN a.balance > b.balance THEN 1 ELSE 0 END
			FROM #BalanceBefore b
				INNER JOIN #BalanceAfter a ON b.custid = a.custid
			WHERE b.balance <> a.balance			

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
		END -- end while
	END --end while
				
	DROP TABLE #temp_bettrans_9
	DROP TABLE #BalanceBefore
	DROP TABLE #Balance
	DROP TABLE #BalanceAfter
END


GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Admin_Calculate_9_Cal] TO [vnteam] AS [dbo]