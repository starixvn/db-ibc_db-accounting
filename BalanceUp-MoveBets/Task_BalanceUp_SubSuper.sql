ALTER PROCEDURE [dbo].[Task_BalanceUp_SubSuper]
	@winlostdate smalldatetime,
	@preview bit = 0
AS

create table #srecommend (KeyID int PRIMARY KEY IDENTITY(1,1), srecommend int, ticketCount int)

-- Get ticketcount per Super
insert into #srecommend (srecommend, ticketCount)
select srecommend, SUM(ticketCount)
FROM balanceTable_tmp
WHERE roleid IN (3,4)
GROUP BY srecommend
ORDER BY 2 DESC

Declare @custid_list varchar(2100), @cnt int, @custid_cnt int, @rc int, @r int
Declare @keyID int, @custid_listustid int, @srecommend int, @ticketCount int

SET @r = 1
NewSuperList:
SET @custid_list = ''
SET @cnt = 0
SET @custid_cnt = 0

AddSuper:
SELECT @keyID = keyID, @srecommend = srecommend, @ticketCount = ticketCount
FROM #srecommend 
--ORDER BY ticketCount

SET @rc = @@ROWCOUNT
IF @rc > 0
BEGIN
	SET @custid_list = @custid_list + CAST(@srecommend as varchar(40)) + ','
	SET @cnt = @cnt + @ticketCount
	SET @custid_cnt = @custid_cnt + 1

	DELETE FROM #srecommend WHERE KeyID = @keyID
END

IF (@cnt < 5000) AND LEN(@custid_list) < 2000 AND @custid_cnt < 200 AND @rc > 0 GOTO AddSuper -- add next Super into list until condition meet

IF @custid_cnt > 0
BEGIN
	SET @custid_list = LEFT(@custid_list, LEN(@custid_list) -1)

	IF @preview = 1
	BEGIN
		PRINT CAST(@r as varchar(40)) + '  Total Ticket : ' + CAST(@cnt as varchar(40)) + '  Total srecommend : ' + CAST(@custid_cnt as varchar(40)) + '   ' + @custid_list
		SET @r = @r + 1
	END
	ELSE
	BEGIN
		BEGIN TRANSACTION
		DELETE FROM dbo.balanceTable_tmp
		WHERE srecommend IN (select val from dbo.strSplit(@custid_list, ','))

		EXEC dbo.ExecRep_07 @custid_list, 0, 44, @winlostdate
		COMMIT TRANSACTION

		WAITFOR DELAY '000:00:01.500'
	END
END

IF @rc > 0 GOTO NewSuperList

NoMoreSuper:



GO
GRANT VIEW DEFINITION ON [dbo].[Task_BalanceUp_SubSuper] TO [vnteam] AS [dbo]