USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[NAP_Admin_Calculate_9_Cal]    Script Date: 09/21/2015 11:07:57 ******/
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
		- 20150914@Kathy: Change settlement flow (Remove NAP_Task_Calculate_Parlay job) [Redmine:#43566]
		- 20150807@Kathy: Using new balance table (BalCreditSportsPending,BalDebitSportsPending) [Redmine:#40125]
	Param's Explanation:
		+ @matchid: matchid of match to be settled
		+ @matchdate match date
*/
BEGIN
	SET NOCOUNT ON		
	DECLARE @statusID tinyint, @winlostdate smalldatetime		
	declare @tstime datetime, @duration int, @runcnt int = 0
	
	DECLARE @refnos as TABLE(refno bigint)
	INSERT INTO @refnos
	SELECT refno
	FROM dbo.bettransm bm WITH(ROWLOCK)
	WHERE matchid = @matchid
		AND NOT EXISTS (
			SELECT 1 FROM bettransm WITH(NOLOCK) WHERE refno = bm.refno AND statusID IN(1, 101)
		)
		
	SET @runcnt = @@ROWCOUNT
		
	INSERT INTO dbo.ParlaySettlement_trace (matchid, runcnt, starttime, endtime, doing)
	VALUES (@matchid, @runcnt, CURRENT_TIMESTAMP, NULL, 'Start running SP 9_cal')	
	
	;WITH p AS (
		SELECT parlay.refno as refno
			,SUM(CASE WHEN parlay.statusID IN (121, 103) THEN 0 ELSE 1 END) as NoRefund
			,SUM(CASE WHEN parlay.statuswinlost = 4 THEN 1 ELSE 0 END) as loseCnt
			,SUM(CASE WHEN parlay.statusID IN (0, 1) THEN 1 ELSE 0 END) as runningCnt
			,MAX(winlostdate) as matchdate_max
			,CAST(EXP(SUM(CAST(LOG(
				case parlay.statuswinlost
					when 0 then 1 -- draw
					when 1 then 1+((parlay.odds-1)/2) -- half won
					when 2 then parlay.odds -- won
					when 3 then 0.5 -- half lose
					when 4 then 0.000000000001 -- lose
					else 1 -- void/reject
				end
				) AS DECIMAL(38, 20)))) as smallmoney) as modds
		FROM (
				SELECT transid, odds, refno, statuswinlost, statusID, winlostdate FROM dbo.bettransm WITH(rowlock)						
				UNION
				SELECT transid, odds, refno, statuswinlost, statusID, winlostdate FROM dbo.bettransm14 WITH(rowlock)			
			) parlay 
		WHERE refno IN (SELECT refno FROM @refnos)						
		GROUP BY parlay.refno
	)	
	SELECT b.transid as transid					
		,CASE
				WHEN loseCnt > 0 THEN @matchdate --lose
				WHEN runningCnt > 0 THEN p.matchdate_max -- running
				WHEN NoRefund = 0 THEN p.matchdate_max-- Refund
				WHEN p.modds < 1 THEN @matchdate -- Lose
				WHEN p.modds = 1 THEN p.matchdate_max -- Draw
				ELSE winlostdate -- Won
			END as winlostdate			
		,CASE
				WHEN loseCnt > 0 THEN 113 -- Lose
				WHEN runningCnt > 0 THEN 0 -- running
				WHEN NoRefund = 0 THEN 103 -- Refund
				WHEN p.modds < 1 THEN 113 -- Lose
				WHEN p.modds = 1 THEN 111 -- Draw
				ELSE 112 -- Won
			END as statusID	
		,p.modds as modds	
	INTO  #temp_bettrans_9			
	FROM bettrans b WITH(NOLOCK)
		INNER JOIN p ON b.refno = p.refno
	WHERE b.matchid = 9		
		AND b.bettype = 9
		AND b.statusID NOT IN (101,102) --('VOID','REJECT')	
		AND (b.statusID	<> CASE
								WHEN loseCnt > 0 THEN 113 -- Lose
								WHEN runningCnt > 0 THEN 0 -- running
								WHEN NoRefund = 0 THEN 103 -- Refund
								WHEN p.modds < 1 THEN 113 -- Lose
								WHEN p.modds = 1 THEN 111 -- Draw
								ELSE 112 -- Won
							END
			OR b.winlost <> CASE WHEN loseCnt > 0 OR runningCnt > 0 THEN 0 ELSE stake * p.modds END		
		)
		
	SET @runcnt = @@rowcount
	INSERT INTO dbo.ParlaySettlement_trace (matchid, runcnt, starttime, endtime, doing)
	VALUES (@matchid, @runcnt, CURRENT_TIMESTAMP, NULL, 'start updating bettrans')		
				
	--
	DECLARE @tempStatus as TABLE (statusID tinyint, winlostdate smalldatetime, isfinished bit)
	DECLARE @tempTransID as TABLE(transID bigint, modds SMALLMONEY)
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
	DECLARE @tblDebitPending TVP_BalanceList
	DECLARE @tblCreditPending TVP_BalanceList
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
			DELETE FROM @tblCreditPending
			DELETE FROM @tblDebitPending

			DELETE TOP (1000) #temp_bettrans_9
			OUTPUT	deleted.transID, DELETED.modds into @tempTransID(transid, modds)
			WHERE	statusID = @statusID 
					AND winlostdate = @winlostdate

			SET @runcnt = @@ROWCOUNT
			IF @runcnt = 0 BREAK
			
			SET @strTransIds = STUFF((
				SELECT ',' + cast(transid as varchar(20)) + CASE WHEN NULLIF(modds,0) IS NULL THEN '' ELSE '|' + cast(modds as varchar(20)) END
				FROM @tempTransID					
				FOR XML PATH('')
			),1,1,'')
						
			-------------------------------------------------------------
			---        CAPTURE value BALANCE before settlement        ---
			---------------------------VVVV------------------------------
			INSERT INTO #BalanceBefore
			SELECT b.custid, SUM(b.winlost-b.actual_stake+b.playercomm)
			FROM dbo.bettrans b with (rowlock)
			WHERE transid IN (SELECT transid FROM @tempTransID)
			GROUP BY b.custid				
			--------------------------------------------------------------	
			SET @tstime = CURRENT_TIMESTAMP			 
						EXEC dbo.NAP_Admin_Calculate_Parlay
				@mode = 'CAL-9'
				,@strXML = @strTransIds 
				,@statusID = @statusID
				,@winlostdate = @winlostdate 
			
			SET @duration = datediff(s, @tstime, CURRENT_TIMESTAMP)				
			INSERT INTO dbo.ParlaySettlement_trace (matchid, runcnt, starttime, endtime, strXML, statusID)
			VALUES (@matchid, @runcnt, @tstime, CURRENT_TIMESTAMP, @strTransIds, @statusid)
			
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

			--INSERT INTO dbo.BalancePendingDebit (custid, balance)
			--SELECT custid, ABS(balance)
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
			
			--INSERT INTO dbo.BalancePendingCredit (custid, balance)
			--SELECT custid, balance
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