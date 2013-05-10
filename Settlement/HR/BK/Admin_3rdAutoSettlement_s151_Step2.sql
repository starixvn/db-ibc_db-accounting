

ALTER PROCEDURE [dbo].[Admin_3rdAutoSettlement_s151_Step2]
	@ProgramID varchar(10),
	@raceNumber int,
	@eventdate smalldatetime,
	@Action varchar(10) = 'CAL'
AS
BEGIN

-------------------------------------------------------------
---        CAPTURE value BALANCE before settlement        ---
---------------------------VVVV------------------------------
CREATE TABLE #BalanceBefore (custid int PRIMARY KEY, balance money)
Declare @TotalAccount int, @TotalAccount_BalanceUpdate int
BEGIN
--===
	;WITH Horse AS (
		SELECT orid
		FROM dbo.outright with (nolock)
		WHERE
			ProgramID = @programID  
			AND groupmatch = CAST(@raceNumber as varchar(20))  
			AND eventdate = @EventDate  
	        AND oddsstatus = 'closed'  
	)
	INSERT INTO #BalanceBefore
	SELECT custid, SUM(winlost-actual_stake+playercomm)
	FROM dbo.bettrans b with (rowlock)
		INNER JOIN Horse h ON b.matchid = h.orid
	GROUP BY custid

	SET @TotalAccount = @@ROWCOUNT
--===
END


	-- start settlement
	IF @Action='CAL'
	BEGIN
		EXEC dbo.[Admin_3rdCalculate_s151_Reject] @ProgramID, @raceNumber, @eventdate
		EXEC dbo.[Admin_3rdCalculate_s151]     	@ProgramID, @raceNumber, @eventdate
		EXEC dbo.[Admin_3rdDummyTransfer_s151] 	@ProgramID, @raceNumber, @eventdate
	END
	ELSE
	BEGIN
		-- REFUND
		EXEC dbo.Admin_3rdCalculate_s151_Refund @ProgramID, @raceNumber, @eventdate
	END




-------------------------------------------------------------
---         CAPTURE value BALANCE after settlement        ---
---------------------------VVVV------------------------------
CREATE TABLE #BalanceAfter (custid int PRIMARY KEY, balance money)
BEGIN
--===
	;WITH Horse AS (
		SELECT orid
		FROM dbo.outright with (nolock)
		WHERE
			ProgramID = @programID  
			AND groupmatch = CAST(@raceNumber as varchar(20))  
			AND eventdate = @EventDate  
	        AND oddsstatus = 'closed'  
	)
	INSERT INTO #BalanceAfter
	SELECT custid, SUM(winlost-actual_stake+playercomm)
	FROM dbo.bettrans b with (rowlock)
		INNER JOIN Horse h ON b.matchid = h.orid
	GROUP BY custid
--===
END

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

DROP TABLE #Balance
DROP TABLE #BalanceBefore
DROP TABLE #BalanceAfter
-------------------------------------------------------------



END