ALTER PROCEDURE [dbo].[Task_BalanceUp_SubAgent]
	@winlostdate smalldatetime,
	@preview bit = 0
AS

create table #recommend (KeyID int PRIMARY KEY IDENTITY(1,1), recommend int, ticketCount int)
create table #custid (KeyID int PRIMARY KEY IDENTITY(1,1), custid int, ticketCount int)

Declare @rKeyID int, @cKeyID int
-- Get ticketcount per agent
-- Note that data is sorted by TicketCount DESC, so that agent with less tickets will be picked first.
-- Then for the agents with high tickets (more than 10000), it will loop by member level
insert into #recommend (recommend, ticketCount)
select recommend, SUM(ticketCount)
FROM balanceTable_tmp
WHERE roleid IN (1,2)
GROUP BY recommend
ORDER BY 2, 1 --DESC

Declare @custid_list varchar(2100), @cnt int, @custid_cnt int, @rc int, @r int
Declare @keyID int, @custid_listustid int, @recommend int, @ticketCount int

SET @rKeyID = 1
SET @r = 1
NewAgentList:
SET @custid_list = ''
SET @cnt = 0
SET @custid_cnt = 0

AddAgent:
SELECT @keyID = keyID, @recommend = recommend, @ticketCount = ticketCount
FROM #recommend 
WHERE keyID = @rKeyID
--ORDER BY ticketCount

SET @rc = @@ROWCOUNT
IF @rc > 0
BEGIN
	SET @custid_list = @custid_list + CAST(@recommend as varchar(40)) + ','
	SET @cnt = @cnt + @ticketCount
	SET @custid_cnt = @custid_cnt + 1

	--DELETE FROM #recommend WHERE KeyID = @keyID
	SET @rKeyID = @rKeyID + 1
END

IF (@cnt < 5000) AND LEN(@custid_list) < 2000 AND @custid_cnt < 200 AND @rc > 0 GOTO AddAgent -- add next agent into list until condition meet

IF @custid_cnt > 0
BEGIN
	SET @custid_list = LEFT(@custid_list, LEN(@custid_list) -1)

	IF @preview = 1
	BEGIN
		PRINT CAST(@r as varchar(40)) + '  Total Ticket : ' + CAST(@cnt as varchar(40)) + '  Total recommend : ' + CAST(@custid_cnt as varchar(40)) + '   ' + @custid_list
		SET @r = @r + 1
	END
	ELSE
	BEGIN
		BEGIN TRANSACTION
		DELETE FROM dbo.balanceTable_tmp
		WHERE recommend IN (select val from dbo.strSplit(@custid_list, ','))

		EXEC dbo.ExecRep_07 @custid_list, 0, 22, @winlostdate
		COMMIT TRANSACTION

		WAITFOR DELAY '000:00:01.200'
	END
END

IF IsNull(@ticketCount,0) > 10000 GOTO PickNextAgent -- if ticketCount per 1 agent over 10000, go to loop for each custid
IF @rc > 0 GOTO NewAgentList

PickNextAgent:
SELECT @keyID = keyID, @recommend = recommend, @ticketCount = ticketCount
FROM #recommend
WHERE keyID = @rKeyID
--ORDER BY ticketCount

IF @@ROWCOUNT = 0 GOTO NoMoreAgent -- no more agent

truncate table #custid
insert into #custid (custid, ticketCount)
SELECT custid, ticketCount
FROM dbo.BalanceTable_tmp
WHERE roleid = 1 AND recommend = @recommend

NewCustIDList:
SET @custid_list = ''
SET @cnt = 0
SET @custid_cnt = 0

AddCustID:
SELECT @keyID = keyID, @custid_listustid = custid, @ticketCount = ticketCount
FROM #custid
--ORDER BY ticketCount

SET @rc = @@ROWCOUNT
IF @rc > 0
BEGIN
	SET @custid_list = @custid_list + CAST(@custid_listustid as varchar(40)) + ','
	SET @cnt = @cnt + @ticketCount
	SET @custid_cnt = @custid_cnt + 1

	DELETE FROM #custid WHERE KeyID = @keyID
END

IF (@cnt < 5000) AND LEN(@custid_list) < 2000 AND @custid_cnt < 200 AND @rc > 0 GOTO AddCustID -- loop for add another customer into list

IF @custid_cnt > 0
BEGIN
	SET @custid_list = LEFT(@custid_list, LEN(@custid_list) -1)

	IF @preview = 1
	BEGIN
		PRINT CAST(@r as varchar(40)) + '  Total Ticket : ' + CAST(@cnt as varchar(40)) + '  Total custid : ' + CAST(@custid_cnt as varchar(40)) + '   ' + @custid_list
		SET @r = @r + 1
	END
	ELSE
	BEGIN
		BEGIN TRANSACTION
		DELETE FROM dbo.balanceTable_tmp
		WHERE custid IN (select val from dbo.strSplit(@custid_list, ','))

		EXEC dbo.ExecRep_07 @custid_list, @recommend, 11, @winlostdate
		COMMIT TRANSACTION

		WAITFOR DELAY '000:00:01.000'
	END
END

IF @rc > 0 GOTO NewCustIDList -- still not empty, loop for next list of customer

--DELETE FROM #recommend WHERE recommend = @recommend
SET @rKeyID = @rKeyID + 1

IF @preview = 1
BEGIN
	SELECT @ticketCount = ticketCount
	FROM dbo.balanceTable_tmp
	WHERE custid = @recommend

	PRINT CAST(@r as varchar(40)) + '  Total Ticket : ' + CAST(@ticketCount as varchar(40)) + '   ' + CAST(@recommend as varchar(40))
	SET @r = @r + 1
END
ELSE
BEGIN
	BEGIN TRANSACTION
	DELETE FROM dbo.balanceTable_tmp
	WHERE recommend = @recommend

	EXEC dbo.ExecRep_07 '', @recommend, 2, @winlostdate
	COMMIT TRANSACTION

	WAITFOR DELAY '000:00:01.200'
END

GOTO PickNextAgent -- no more customer, loop for next agent

NoMoreAgent:



GO
GRANT VIEW DEFINITION ON [dbo].[Task_BalanceUp_SubAgent] TO [vnteam] AS [dbo]