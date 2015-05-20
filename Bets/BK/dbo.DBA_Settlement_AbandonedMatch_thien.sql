 ALTER PROCEDURE [dbo].[DBA_Settlement_AbandonedMatch_thien]
    @Matchid INT ,
    @Action varchar(6) = 'CAL',    
    @Type INT = 3,
    @Creator INT, 
    @ErrCode SMALLINT = 0 OUTPUT,
    @ErrMsg  NVARCHAR(4000) = '' OUTPUT
AS
/*
Created: 20120203@Sophia
Task :  Execute settlement for abandoned/postponed match
DB: DBTRANS.bodb02

Revisions:
    -20120211@Thien:    + get scores from DB instead of input param
                        + change the condition of all queries to update the determined tickets only
  
Param's Explanation:
• @Action:
    CAL : All
    CAL-HT : HT Only
    CAL-FT : FT Only (All Except HT)
• @Type: 
	3: Indicate HT and FT Over/Under

• Formula:
	Over:
		totalscore - hdp1 >= 0.5 : WIN
		totalscore - hdp1 < 0.5 : REFUND
	Under:
		hdp1 - totalscore <= -0.5 : LOSE
		hdp1 - totalscore > -0.5 : REFUND

*/
SET NOCOUNT ON

Declare @totalgoal smallmoney, @totalht smallmoney, @modds smallmoney

Declare @start datetime, @stop datetime 
Declare @LogData nvarchar(200)

Declare @TicketCount int
SET @TicketCount = 0
SELECT @start = CURRENT_TIMESTAMP

DECLARE @hth INT, @hta INT, @fth INT, @fta INT

--- Get scores
SELECT	@fth = FinalHomeScore,
		@fta = FinalAwayScore,
		@hth = HTHomeScore,
		@hta = HTAwayScore,
		@totalgoal = FinalHomeScore + FinalAwayScore,
		@totalht = HTHomeScore + HTAwayScore
FROM	DB02.BODB02.dbo.Match WITH (NOLOCK) 
WHERE	matchid = @matchid



DECLARE @BettypeHT INT 

SELECT @BettypeHT = CASE @Type WHEN 1 THEN 7 
								WHEN 2 THEN 12
								WHEN 3 THEN 8
								WHEN 5 THEN 15
								WHEN 20 THEN 12
								WHEN 4 THEN 30
								WHEN 124 THEN 125
						ELSE 0 END



--********* Check permission for account 
	EXEC db03.bodb02.dbo.Acc_Con_CheckPermission @custid=@Creator,@funcname='[Settlement]',@ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
	IF @ErrCode <> 0
		RETURN
	--end


--******** Check BETDAQ tickets

IF (@action = 'CAL-HT')
BEGIN 
	IF NOT EXISTS (
				SELECT 1 
				FROM bettrans WITH (NOLOCK) 
				WHERE 
					(custid IN (50057, 879241, 103873, 78761, 1077687) or recommend = 1688156)
					AND matchid = @matchid 
					AND ruben = 0
					AND bettype =@BettypeHT
											   
			   )
	BEGIN
		SELECT	@ErrCode = 1, @ErrMsg = 'There is no BETDAQ ticket to calculate haftime.'
		RETURN
	END 
END

IF (@action = 'CAL-FT')
BEGIN 
	IF NOT EXISTS (
				SELECT 1 
				FROM bettrans WITH (NOLOCK) 
				WHERE 
					(custid IN (50057, 879241, 103873, 78761, 1077687) or recommend = 1688156)
					AND matchid = @matchid 
					AND ruben = 0
					AND bettype =@Type
											   
			   )
	BEGIN
		SELECT	@ErrCode = 2, @ErrMsg = 'There is no BETDAQ ticket to calculate fulltime.'
		RETURN
	END 
END


IF (@action = 'CAL')
BEGIN 
	IF NOT EXISTS (
				SELECT 1 
				FROM bettrans WITH (NOLOCK) 
				WHERE 
					(custid IN (50057, 879241, 103873, 78761, 1077687) or recommend = 1688156)
					AND matchid = @matchid 
					AND ruben = 0
					AND bettype IN (@Type,@BettypeHT)
											   
			   )
	BEGIN
		SELECT	@ErrCode = 3, @ErrMsg = 'There is no BETDAQ ticket to calculate all.'
		RETURN
	END 
END

--********* Check replication
DECLARE @countDBTrans int, @countDB05 int, @countDB052 int, @countDB06 int, @countDB053 int


IF (@action = 'CAL-HT')
BEGIN
	select	@countDBTrans = count(1) 
	from	bettrans with (nolock) 
	where	(custid IN (50057, 879241, 103873, 78761, 1077687) or recommend = 1688156)
			AND matchid = @matchid 
			AND ruben = 0
			AND bettype = @BettypeHT

	select @countDB052 = count(1) 
	from DB052.bodb02.dbo.bettrans with (nolock) 
	where (custid IN (50057, 879241, 103873, 78761, 1077687) or recommend = 1688156)
			AND matchid = @matchid 
			AND ruben = 0
			AND bettype = @BettypeHT

	select @countDB06 = count(1) 
	from DB06.bodb02.dbo.bettrans with (nolock)
	where (custid IN (50057, 879241, 103873, 78761, 1077687) or recommend = 1688156)
			AND matchid = @matchid 
			AND ruben = 0
			AND bettype = @BettypeHT

	select @countDB053 = count(1) 
	from DB053.bodb02.dbo.bettrans with (nolock) 
	where (custid IN (50057, 879241, 103873, 78761, 1077687) or recommend = 1688156)
			AND matchid = @matchid 
			AND ruben = 0
			AND bettype = @BettypeHT

END
ELSE IF (@action = 'CAL-FT')
BEGIN
	select	@countDBTrans = count(1) 
	from	bettrans with (nolock) 
	where	(custid IN (50057, 879241, 103873, 78761, 1077687) or recommend = 1688156)
			AND matchid = @matchid 
			AND ruben = 0
			AND bettype = @Type

	select @countDB052 = count(1) 
	from DB052.bodb02.dbo.bettrans with (nolock) 
	where (custid IN (50057, 879241, 103873, 78761, 1077687) or recommend = 1688156)
			AND matchid = @matchid 
			AND ruben = 0
			AND bettype = @Type

	select @countDB06 = count(1) 
	from DB06.bodb02.dbo.bettrans with (nolock)
	where (custid IN (50057, 879241, 103873, 78761, 1077687) or recommend = 1688156)
			AND matchid = @matchid 
			AND ruben = 0
			AND bettype = @Type

	select @countDB053 = count(1) 
	from DB053.bodb02.dbo.bettrans with (nolock) 
	where (custid IN (50057, 879241, 103873, 78761, 1077687) or recommend = 1688156)
			AND matchid = @matchid 
			AND ruben = 0
			AND bettype = @Type

END
ELSE IF (@action = 'CAL')
BEGIN
	select	@countDBTrans = count(1) 
	from	bettrans with (nolock) 
	where	(custid IN (50057, 879241, 103873, 78761, 1077687) or recommend = 1688156)
			AND matchid = @matchid 
			AND ruben = 0
			AND bettype IN (@Type,@BettypeHT)

	select @countDB052 = count(1) 
	from DB052.bodb02.dbo.bettrans with (nolock) 
	where (custid IN (50057, 879241, 103873, 78761, 1077687) or recommend = 1688156)
			AND matchid = @matchid 
			AND ruben = 0
			AND bettype IN (@Type,@BettypeHT)

	select @countDB06 = count(1) 
	from DB06.bodb02.dbo.bettrans with (nolock)
	where (custid IN (50057, 879241, 103873, 78761, 1077687) or recommend = 1688156)
			AND matchid = @matchid 
			AND ruben = 0
			AND bettype IN (@Type,@BettypeHT)

	select @countDB053 = count(1) 
	from DB053.bodb02.dbo.bettrans with (nolock) 
	where (custid IN (50057, 879241, 103873, 78761, 1077687) or recommend = 1688156)
			AND matchid = @matchid 
			AND ruben = 0
			AND bettype IN (@Type,@BettypeHT)
END

IF (@countDBTrans <> @countDB052 OR @countDBTrans <> @countDB06 OR @countDBTrans <> @countDB053)
BEGIN
	SELECT 
		@ErrCode = 4, 
		@ErrMsg = 'System is not ready to calculate this match. Please try again after few minutes.'    
	RETURN
END


CREATE TABLE #BalanceBefore (custid INT, balance money)
CREATE TABLE #BalanceAfter (custid int, balance money)


------*********************************************************************************
------------ For Over Under
IF @Type = 3
BEGIN 
	

	
	----Check valid score

	IF @Action = 'CAL-HT'  AND @totalht IS NULL
	BEGIN 
		SELECT @ErrCode = 5, @ErrMsg = 'Please choose @hth, @hta to calculate halftime.'  
		RETURN
	END 
	ELSE
	IF @Action = 'CAL-FT' AND @totalgoal IS NULL
	BEGIN 
		SELECT  @ErrCode = 6, @ErrMsg = 'Please choose @fth, @fta to calculate fulltime.'  
		RETURN  
	END
	ELSE 
	IF @Action = 'CAL' AND (@totalgoal IS NULL OR @totalht IS NULL)
	BEGIN 
		SELECT  @ErrCode = 7, @ErrMsg = 'Please choose @fth, @fta, @hth, @hta to calculate all.'  
		RETURN  
	END 	
	

	 
	IF @Action IN( 'CAL-HT', 'CAL') AND @totalht IS NOT NULL
	BEGIN	
		--- Count Tickets
		SELECT @TicketCount= @TicketCount + COUNT(1)
		FROM bettrans WITH (NOLOCK)
		WHERE
			matchid=@matchid AND
			bettype=8 AND
			statusID NOT IN (101,102) AND 
			(custid IN (50057, 879241, 103873, 78761, 1077687) or recommend = 1688156) AND
			ruben = 0
			and (hdp1 <= @totalht - 0.5)

		----------------------------------------------
		---CAPTURE value BALANCE before settlement ---
		---------------------------VVVV---------------
		INSERT INTO #BalanceBefore
		SELECT custid, SUM(winlost-actual_stake+playercomm) 
		FROM dbo.bettrans with (rowlock)
		WHERE
			matchid=@matchid AND
			bettype=8 AND			
			--status NOT IN (N'VOID', N'REJECT')
			statusID NOT IN (101,102) AND 
			(custid IN (50057, 879241, 103873, 78761, 1077687) or recommend = 1688156) AND
			ruben = 0
			and (hdp1 <= @totalht - 0.5)
		GROUP BY custid

			
		UPDATE dbo.bettrans with (ROWLOCK, UPDLOCK)
		SET @modds = modds = CASE betteam
			WHEN N'h' THEN @totalht-hdp1
			WHEN N'a' THEN hdp1-@totalht
			END,
		WinLost = CASE
			WHEN betteam = N'h' AND @modds >= 0.5 THEN actual_stake + stake * (case when odds<0 then 1 else odds end) -- WIN
			WHEN betteam = N'a' AND @modds <= -0.5 THEN 0	-- LOSE			
			END,
		aWinLost = CASE
			WHEN betteam = N'h' AND @modds >= 0.5 THEN stake * (case when odds<0 then 1 else odds end) * -apositiontaking
			WHEN betteam = N'a' AND @modds <= -0.5 THEN actual_stake * apositiontaking
			END,
		mWinLost = CASE
			WHEN betteam = N'h' AND @modds >= 0.5 THEN stake * (case when odds<0 then 1 else odds end) * -mpositiontaking
			WHEN betteam = N'a' AND @modds <= -0.5 THEN actual_stake * mpositiontaking			
			END,
		sWinLost = CASE
			WHEN betteam = N'h' AND @modds >= 0.5 THEN stake * (case when odds<0 then 1 else odds end) * -spositiontaking
			WHEN betteam = N'a' AND @modds <= -0.5 THEN actual_stake * spositiontaking			
			END,
		PlayerComm = CASE
			WHEN (betteam = N'h' AND @modds >= 0.5) THEN playerdiscount * stake
			WHEN (betteam = N'a' AND @modds <= -0.5) THEN playerdiscount * stake			
			END,
		Comm = CASE
			WHEN (betteam = N'h' AND @modds >= 0.5) THEN discount * stake * (1-apositiontaking)
			WHEN (betteam = N'a' AND @modds <= -0.5) THEN discount * stake * (1-apositiontaking)			
			END,
		aComm = CASE
			WHEN (betteam = N'h' AND @modds >= 0.5) THEN adiscount * stake * (1-(mpositiontaking+apositiontaking))
			WHEN (betteam = N'a' AND @modds <= -0.5) THEN adiscount * stake * (1-(mpositiontaking+apositiontaking))			
			END,
		sComm = CASE
			WHEN (betteam = N'h' AND @modds >= 0.5) THEN sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking))
			WHEN (betteam = N'a' AND @modds <= -0.5) THEN sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking))
			END,
		Status = CASE
			WHEN (betteam = N'h' AND @modds >= 0.5) THEN N'WON'
			WHEN (betteam = N'a' AND @modds <= -0.5) THEN N'LOSE'			
			END,
		StatusID = CASE
			WHEN (betteam = N'h' AND @modds >= 0.5) THEN 112 --WON
			WHEN (betteam = N'a' AND @modds <= -0.5) THEN 113 --LOSE			
			END,
		ruben=1

		WHERE
			matchid=@matchid AND
			bettype=8 AND			
			--status NOT IN (N'VOID', N'REJECT')
			statusID NOT IN (101,102) AND 
			(custid IN (50057, 879241, 103873, 78761, 1077687) or recommend = 1688156) AND
			ruben = 0
			and (hdp1 <= @totalht - 0.5)
			

	IF @@ROWCOUNT <> 0 
	BEGIN	
	----------------------------------------------
	--- CAPTURE value BALANCE after settlement HT---
	-----------------VVVV-------------------------

		INSERT INTO #BalanceAfter
		SELECT custid, SUM(winlost-actual_stake+playercomm) 
		FROM dbo.bettrans with (rowlock)
		WHERE
			matchid=@matchid AND
			bettype=8 AND 
			(custid IN (50057, 879241, 103873, 78761, 1077687) or recommend = 1688156) AND
			ruben = 1
			and (hdp1 <= @totalht - 0.5)
		GROUP BY custid
	END
END	
	


	IF @Action IN ('CAL-FT', 'CAL') AND @totalgoal IS NOT NULL
	BEGIN		
		--- Count Tickets
		SELECT @TicketCount= @TicketCount + COUNT(1)
		FROM bettrans WITH (NOLOCK)
		WHERE
			matchid=@matchid AND
			bettype=3 AND
			statusID NOT IN (101,102) AND 
			(custid IN (50057, 879241, 103873, 78761, 1077687) or recommend = 1688156) AND
			ruben = 0
			and (hdp1 <= @totalgoal - 0.5)

		----------------------------------------------
		--- CAPTURE value BALANCE before settlement ---
		--------------------VVVV---------------------
		INSERT INTO #BalanceBefore
		SELECT custid, SUM(winlost-actual_stake+playercomm)    
		FROM dbo.bettrans with (rowlock)
		WHERE	matchid=@matchid AND
				bettype=3 AND
				statusID NOT IN (101,102) AND 
				(custid IN (50057, 879241, 103873, 78761, 1077687) or recommend = 1688156) AND
				ruben = 0
				and (hdp1 <= @totalgoal - 0.5)
		GROUP BY custid

		UPDATE dbo.bettrans with (ROWLOCK, UPDLOCK)
		SET @modds = modds = CASE betteam
			WHEN N'h' THEN @totalgoal-hdp1
			WHEN N'a' THEN hdp1-@totalgoal
			END,		
		WinLost = CASE
			WHEN betteam = N'h' AND @modds >= 0.5 THEN actual_stake + stake * (case when odds<0 then 1 else odds end) -- WIN
			WHEN betteam = N'a' AND @modds <= -0.5 THEN 0	-- LOSE		
			END,
		aWinLost = CASE
			WHEN betteam = N'h' AND @modds >= 0.5 THEN stake * (case when odds<0 then 1 else odds end) * -apositiontaking
			WHEN betteam = N'a' AND @modds <= -0.5 THEN actual_stake * apositiontaking
			END,
		mWinLost = CASE
			WHEN betteam = N'h' AND @modds >= 0.5 THEN stake * (case when odds<0 then 1 else odds end) * -mpositiontaking
			WHEN betteam = N'a' AND @modds <= -0.5 THEN actual_stake * mpositiontaking
			END,
		sWinLost = CASE
			WHEN betteam = N'h' AND @modds >= 0.5 THEN stake * (case when odds<0 then 1 else odds end) * -spositiontaking
			WHEN betteam = N'a' AND @modds <= -0.5 THEN actual_stake * spositiontaking
			END,
		PlayerComm = CASE
			WHEN (betteam = N'h' AND @modds >= 0.5) THEN playerdiscount * stake
			WHEN (betteam = N'a' AND @modds <= -0.5) THEN playerdiscount * stake
			END,
		Comm = CASE
			WHEN (betteam = N'h' AND @modds >= 0.5) THEN discount * stake * (1-apositiontaking)
			WHEN (betteam = N'a' AND @modds <= -0.5) THEN discount * stake * (1-apositiontaking)
			END,
		aComm = CASE
			WHEN (betteam = N'h' AND @modds >= 0.5) THEN adiscount * stake * (1-(mpositiontaking+apositiontaking))
			WHEN (betteam = N'a' AND @modds <= -0.5) THEN adiscount * stake * (1-(mpositiontaking+apositiontaking))
			END,
		sComm = CASE
			WHEN (betteam = N'h' AND @modds >= 0.5) THEN sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking))
			WHEN (betteam = N'a' AND @modds <= -0.5) THEN sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking))
			END,
		Status = CASE
			WHEN (betteam = N'h' AND @modds >= 0.5) THEN N'WON'
			WHEN (betteam = N'a' AND @modds <= -0.5) THEN N'LOSE'
			END,
		StatusID = CASE
			WHEN (betteam = N'h' AND @modds >= 0.5) THEN 112 --WON
			WHEN (betteam = N'a' AND @modds <= -0.5) THEN 113 --LOSE
			END,
		ruben=1

		WHERE
			matchid=@matchid AND
			bettype=3 AND
			--status NOT IN (N'VOID', N'REJECT')
			statusID NOT IN (101,102) AND 
			(custid IN (50057, 879241, 103873, 78761, 1077687) or recommend = 1688156) AND
			ruben = 0
			and (hdp1 <= @totalgoal - 0.5)
		
	IF @@ROWCOUNT <> 0 
	BEGIN			
	-------------------------------------------------
	---  CAPTURE value BALANCE after settlement FT---
	---------------------------VVVV-------------------		

		INSERT INTO #BalanceAfter
		SELECT custid, SUM(winlost-actual_stake+playercomm) 
		FROM dbo.bettrans with (rowlock)
		WHERE matchid = @matchid 
			 AND bettype = 3
			 AND (custid IN (50057, 879241, 103873, 78761, 1077687) or recommend = 1688156) 
			 AND statusID NOT IN (101,102) 
			 AND ruben = 1
			 and (hdp1 <= @totalgoal - 0.5)
		GROUP BY custid
	END 
END

------------------------------------------------------------------------------		
-------------------------------------------------------------
---                   compare BALANCE                     ---
---------------------------VVVV------------------------------

CREATE TABLE #Balance (custid int , balance money, Increased bit)
CREATE INDEX IX_Balance_Increased ON #Balance (Increased)

INSERT INTO #Balance
SELECT b.custid, a.balance-b.balance, CASE WHEN a.balance > b.balance THEN 1 ELSE 0 END
FROM 
	(SELECT SUM(balance) as balance, CustID FROM #BalanceBefore GROUP BY CustID)  b
	INNER JOIN (SELECT SUM(balance) as balance, CustID FROM #BalanceAfter GROUP BY CustID) a 
	ON b.custid = a.custid
WHERE b.balance <> a.balance


INSERT INTO dbo.BalancePendingDebit (custid, balance)
SELECT custid, ABS(balance)
FROM #Balance
WHERE Increased = 0

INSERT INTO dbo.BalancePendingCredit (custid, balance)
SELECT custid, balance
FROM #Balance
WHERE Increased = 1

DROP TABLE #Balance
DROP TABLE #BalanceBefore
DROP TABLE #BalanceAfter



-------------------------------------------------------------
---                      WRITE LOG                        ---
---------------------------VVVV------------------------------
	SELECT @stop = CURRENT_TIMESTAMP

	SELECT @LogData = 'Calculate (' + @action + ') for Abandoned/Postponed match - '
		+ CASE @Type WHEN 3 THEN 'Over/Under' END + ' Matchid:' + CAST(@matchid as nvarchar(10)) 
		+ ' Score:' + CAST(ISNULL(@fth,0) as nvarchar(10)) + '-' + CAST(ISNULL(@fta,0) as nvarchar(10)) + ' HT:' + CAST(@hth as nvarchar(10)) + '-' + CAST(@hta as nvarchar(10)) 
		+ ') (' + CAST(DATEDIFF(millisecond, @start, @stop) as nvarchar(50)) + ' ms)'
	EXEC dbo.WriteLog_UserLog  @creator, @LogData


	--Write Log Settle
	DECLARE @Remark varchar(500), @ActionID int
	SELECT @ActionID = CASE @Action 
			WHEN 'CAL' THEN 123 
			WHEN 'CAL-FT' THEN 124 
			WHEN 'CAL-HT' THEN 125 
		END
	SELECT @Remark = 'Duration:' + CAST(DATEDIFF(millisecond, @start, @stop) as nvarchar(50)) + ' ms' 
		+ ' TC:' + CAST(ISNULL(@ticketCount,0) as varchar(20)) 
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle
		@UserID = @creator,
		@Matchid = @matchid,
		@ActionID = @ActionID,
		@finalhomescore = @fth,
		@finalawayscore = @fta,  
		@hthomescore = @hth,
		@htawayscore = @hta,
		@GoalRecord = '',
		@betstatus = '',
		@Remark = @Remark

END 

SELECT	@ErrCode = 0, @ErrMsg = 'Settle successful.' 



GO
GRANT VIEW DEFINITION ON [dbo].[DBA_Settlement_AbandonedMatch_thien] TO [vnteam]
