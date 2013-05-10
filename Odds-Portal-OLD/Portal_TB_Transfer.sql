ALTER PROCEDURE [dbo].[Portal_TB_Transfer]
	@agentid int,
	@from_id int,
	@to_id int,
	@amount money,
	@remark varchar(100),
	@AllowNegative bit = 0,
	@KeyID bigint
AS
/*
	Create: Joe
	Task: Use for portal servers
	DB: DBTRANS.BODB02

	Revisions:
		- 20100522@viet: Update Bettrans.StatusID
		- 20120529@Sophia: . Update credit/debit balance
						   . Check @@Error to rollback
*/


SET NOCOUNT ON

Declare @result varchar(50)
Declare @recommend int, @mrecommend int, @srecommend int, @currency tinyint
Declare @from_user varchar(50), @to_user varchar(50), @to_closed bit
Declare @from_GC money, @from_CB money, @from_Out money, @from_BC money
Declare @to_GC money, @to_CB money, @to_Out money, @to_BC money
Declare @currencyName varchar(50), @actualrate float

SET @result = ''
-- =========================================
IF @amount < 0
BEGIN
	Declare @tmp int
	SET @tmp = @from_id
	SET @from_id = @to_id
	SET @to_id = @tmp
	SET @amount = -@amount
END

-- =========================================
-- check for duplicate
	IF EXISTS (
	SELECT * FROM bettrans (nolock)
	WHERE custid = @from_id AND matchid = 0 AND bettype = 21004 AND BetID = @KeyID
	) SET @result = 'FAILED:Duplicate_Command'

-- =========================================
	SELECT
		@from_user = username, @from_GC = IsNull(credit, 0),
		@recommend = recommend, @mrecommend = mrecommend, @srecommend = srecommend,
		@currency = currency
	FROM dbo.custinfo (nolock)
	WHERE custid = @from_id AND recommend = @agentid AND roleid = 1
IF @@ROWCOUNT = 0 SET @result = 'FAILED:Not_Found_FromUser'

	SELECT
		@to_user = username, @to_GC = IsNull(credit, 0),
		@to_closed = IsNull(closed, 1)
	FROM dbo.custinfo (nolock)
	WHERE custid = @to_id AND recommend = @agentid AND roleid = 1
IF @@ROWCOUNT = 0 SET @result = 'FAILED:Not_Found_ToUser'

	SELECT
		@currencyName = currency,
		@actualrate = actualrate
	FROM dbo.exchange (nolock)
	WHERE exchangeid = @currency

IF (@from_user = @to_user) OR
NOT ((RIGHT(@from_user, 3) = '000') OR (RIGHT(@to_user, 3) = '000'))
SET @result = 'FAILED:Must_Have_Dummy'

-- =========================================
SELECT
	@from_CB  = IsNull(SUM(CASE WHEN status = 'running' THEN 0 ELSE winlost - actual_stake + playercomm END),0),
	@from_Out = IsNull(SUM(CASE WHEN status = 'running' THEN actual_stake ELSE 0 END),0)
FROM dbo.bettrans (nolock)
WHERE custid = @from_id

SELECT
	@to_CB  = IsNull(SUM(CASE WHEN status = 'running' THEN 0 ELSE winlost - actual_stake + playercomm END),0),
	@to_Out = IsNull(SUM(CASE WHEN status = 'running' THEN actual_stake ELSE 0 END),0)
FROM dbo.bettrans (nolock)
WHERE custid = @to_id

SELECT
	@from_BC = @from_GC + @from_CB - @from_Out,
	@to_BC = @to_GC + @to_CB - @to_Out

IF @AllowNegative = 0 AND @amount > @from_BC SET @result = 'FAILED:Not_Enough_Balance'

-- =========================================
Declare @transcode bigint, @wldate datetime, @doing nvarchar(200)
SET @wldate = convert(nvarchar(10), DATEADD(hour, 12, CURRENT_TIMESTAMP),120)

IF (@result = '') AND (@amount > 0)
BEGIN
	EXECUTE @transcode = transcode_return
	SET @transcode = @transcode + 200000000000
	
	---Insert debit balance for @from_id
	EXEC Dot_BalanceUpdDebit @CustID = @from_id, @balance = @amount  
		
	INSERT INTO bettrans 
		(creator, custid, refno, transdate, matchid, bettype, transdesc, winlost, actual_stake,
		actualrate, username, currencyname,
		comstatus, status, statusID, ruben, winlostdate, currency, recommend, mrecommend, srecommend,
		BetID)
	VALUES (@agentid, @from_id, @transcode, CURRENT_TIMESTAMP, 0, 21004, 'Transfer to ' + @to_user + ' (' + @remark + ')', 0, @amount,
		@actualrate, @from_user, @currencyName,
		@transcode, 'Completed', 131, 1, @wldate, @currency, @recommend, @mrecommend, @srecommend,
		@KeyID)
		
	IF @@ERROR <> 0
	BEGIN
		SET @result = 'FAILED:Insert_transaction_Error' 
		
		--Manually rollback
		DELETE FROM bettrans where custid = @from_id AND matchid = 0 AND bettype = 21004 AND refno = @transcode

		--Rollback Balance for @from_id   
		EXEC Dot_BalanceUpdCredit @custid = @from_id, @Balance = @amount
		
		SELECT	@result Result, @Amount Amount,
				@from_user from_user, @from_BC from_BC, @from_Out from_Out,
				@to_user to_user, @to_BC to_BC, @to_Out to_Out,
				IsNull(@transcode, 0) refno	
		RETURN
	END	
		
				
	INSERT INTO bettrans
		(creator, custid, refno, transdate, matchid, bettype, transdesc, winlost, actual_stake, 
		actualrate, username, currencyname,
		comstatus, status, statusID, ruben, winlostdate, currency, recommend, mrecommend, srecommend)
	VALUES (@agentid, @to_id, @transcode, CURRENT_TIMESTAMP, 0, 21004, 'Transfer from ' + @from_user + ' (' + @remark + ')', @amount, 0,
		@actualrate, @to_user, @currencyName,
		@transcode, 'Completed', 131, 1, @wldate, @currency, @recommend, @mrecommend, @srecommend)
	
	IF @@ERROR <> 0
	BEGIN
		Select @result = 'FAILED:Insert_transaction_Error' 
		
		--Manually rollback
		DELETE FROM bettrans where custid = @from_id AND matchid = 0 AND bettype = 21004 AND refno = @transcode
		DELETE FROM bettrans where custid = @to_id AND matchid = 0 AND bettype = 21004 AND refno = @transcode
		
		--Rollback Balance for @from_id   
		EXEC Dot_BalanceUpdCredit @custid = @from_id, @Balance = @amount
		
		SELECT	@result Result, @Amount Amount,
				@from_user from_user, @from_BC from_BC, @from_Out from_Out,
				@to_user to_user, @to_BC to_BC, @to_Out to_Out,
				IsNull(@transcode, 0) refno								
		RETURN
	END	
		
	---Insert credit balance for @to_id
	EXEC Dot_BalanceUpdCredit @CustID = @to_id, @balance = @amount 

	UPDATE dbo.custBetCredit
	SET ReSync = 1 WHERE custid = CASE RIGHT(@from_user, 3) WHEN '000' THEN @to_id ELSE @from_id END

	SET @doing = 'Transfer from ' + CAST(@from_id as nvarchar) + ' to ' + CAST(@to_id as nvarchar) + ' Amount:' + CONVERT(nvarchar, @amount, 2) + ' Ref:' + CAST(@transcode as nvarchar) + ' (' + @remark + ') AllowNeg:' + CAST(@AllowNegative as varchar(10))
	EXECUTE dbo.logfile @recommend, @doing
END

-- Re-open "To" account, if it's closed
--IF @result = '' AND @to_closed = 1 UPDATE custinfo SET closed = 0 WHERE custid = @to_id

IF @result = '' SET @result = '0'
SELECT
	IsNull(@result, '0') Result, IsNull(@Amount, 0) Amount,
	@from_user from_user, @from_BC from_BC, @from_Out from_Out,
	@to_user to_user, @to_BC to_BC, @to_Out to_Out,
	IsNull(@transcode, 0) refno




GO
GRANT EXECUTE ON [dbo].[Portal_TB_Transfer] TO [Portal]
GO
GRANT VIEW DEFINITION ON [dbo].[Portal_TB_Transfer] TO [vnteam]