USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Acc_BettransInsTransaction]    Script Date: 06/15/2015 18:17:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Acc_BettransInsTransaction    Script Date: 4/10/2015 5:08:27 AM ******/
/****** Object:  Stored Procedure dbo.Acc_BettransInsTransaction    Script Date: 2/4/2015 10:53:09 AM ******/

ALTER PROCEDURE  [dbo].[Acc_BettransInsTransaction]
	@transid bigint OUTPUT,
	@custid int,
	@transdate datetime,
	@amount money,	
	@transdesc nvarchar(300),
	@UserID int,
	@IP nvarchar(15)='',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@Language varchar(2)= 'E'
AS

--Original: adminsite\account\savetransaction.asp
--ADMIN SITE
--UPDATED 02/25/2006: remove refno
--UPDATED 05/18/2007: rebuild from account
--Old: BettransIns_Admin
/*
Created: 
Task: Left menu/ Add txn
DB: DBTXN/bodb02
Revisions:
	- 20090828@HuyNguyen: replace [Customer] --> [OtherTrans]
	- 20091005@Kiwi: modify written log	and remove CustBetCredit	
	- 20100109@Henry: record column TransDate as "current_Timestamp"
	- 20100424@Henry: insert data to column StatusID of Bettrans (StatusID = 131 for bettype 101 and 102) + Update Status = 'Completed'
	- 20100806@Shifu: change function name to check permission, [AddTransaction] for [OtherTrans]
	- 20101007@Henry: Change column transid from INT to BIGINT
	- 20110513@Lukas: Re-arrange bettype
	- 20110709@Johnson: Change to use new server BD053 instead DB052
	- 20111107@Sophia: Update Balance Credit/Debit
	- 20120411@Sophia: Revise Balance Credit/Debit
	- 20120720@Thien: Check to not allow to transfer before balance up date
	- 20121103@Viet: revise sp
	- 20130201@Elodie: Change link server DB03 to DBPOLICY, DB053 to DBAGE
					   Write more log on DBTXN server in case of DBLOG server failure
	- 20131108@Elodie: Splitting bodb02 into CustDB (Call CustInfo, Exchange by link database)
	- 20141226@Tom: Update Transfer Amount in bodb_report.dbo.rptStatement table before move bet day (Redmine#15274)
	- 20150615@Kathy: Migrate custDB to new server DBCust (Move Acc_CustomerSelCheckEnable to DBCUST.CustDB) [Redmine:#36216]					   
Param's Explanation:
*/
BEGIN
SET NOCOUNT ON
DECLARE @balance money, @balance_ABS money

--Check permission for account site: @phuc20080213
EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[AddTransaction]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
If @ErrCode <> 0
	RETURN
--end
--Check disable user
	EXEC DBCUST.CustDB.dbo.Acc_CustomerSelCheckEnable @custid = @custid, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
	if @ErrCode <>0 return
--end

Declare @RefNo bigint, @bettype int, @Curr int, @CurrName nvarchar(10),@actualrate float,
		@Recommend int, @MRecommend int, @SRecommend int, @username nvarchar(50),
		@creditamt money, @debitamt money, @winlostdate smalldatetime, @roleID tinyint

select @winlostdate = convert(nvarchar(10), @Transdate,120)

--------------------------vvvvv-------------------------------------
--Check to not allow to transfer before balance up date
DECLARE @BalanceUpDay smalldatetime
SELECT TOP 1 @BalanceUpDay = winlostdate
FROM dbo.Bettrans WITH(NOLOCK)
WHERE bettype = 20000 and matchid = 0 and custid = 3

-- at this time, server is processing adding tickets into transfer_fi table. So not allow to transfer.
if datename(weekday, getdate()) in ('Thursday') AND datepart(hour, getdate())>= 12
	AND @BalanceUpDay + 7 < getdate() --this week BU not processed yet
BEGIN
	if @winlostdate < @BalanceUpDay +7 --Last Saturday
	BEGIN
		SELECT @ErrMsg =  case @Language
						when 'E' then 'Not allow to add transaction before balance up date - '+ convert(nvarchar(10), @BalanceUpDay +7 ,120)  +'.'
					end, @ErrCode = 105
		return
	END
END
ELSE IF @winlostdate < @BalanceUpDay --Before last BU date
BEGIN
	SELECT @ErrMsg =  case @Language
						when 'E' then 'Not allow to add transaction before balance up date - '+ convert(nvarchar(10), @BalanceUpDay ,120)  +'.'
					end, @ErrCode = 105
	return
END
----------------------^^^^^^----------------------------------
if @amount = 0 
BEGIN
	SELECT @ErrMsg =  case @Language
						when 'E' then 'Invalid amount.'
						when 'CS' then N'Invalid amount.'
						when 'J' then N'Invalid amount.'
						else N'Invalid amount.'
					end, @ErrCode = 104	
	return
END

if @amount > 0 --Deposit
BEGIN
	select @creditamt = abs(@amount), @debitamt = 0,
		 @BetType = 21001
END
else --Withdraw
BEGIN
	select @creditamt = 0, @debitamt = abs(@amount),
		 @BetType = 21002
END

Select @Curr = c.Currency, @actualrate = e.actualrate, @currName = e.currency,@username = c.username,  
	   @Recommend = c.Recommend, @MRecommend = c.MRecommend, @SRecommend = c.SRecommend , @roleID = roleid
from CustDB.dbo.Custinfo c with (NOLOCK) 
	INNER JOIN CustDB.dbo.Exchange e with (NOLOCK) on c.currency = e.exchangeid 
where c.CustID = @CustID
if @@rowcount = 0
BEGIN
	SELECT @ErrMsg =  case @Language
						when 'E' then 'Invalid customer.'
						when 'CS' then N'Invalid customer.'
						when 'J' then N'Invalid customer.'
						else N'Invalid customer'
					end, @ErrCode = 102	
	return
END

SELECT @balance = @creditamt - @debitamt

----Update balance Debit
IF @roleID = 1
BEGIN 
	IF @balance < 0 
	BEGIN 
		SELECT @balance_ABS = ABS(@balance)
		EXEC Dot_BalanceUpdDebit @CustID = @custid, @balance = @balance_ABS  
	END
END

----Insert transaction
EXEC dbo.Acc_SelRefNo @refNo = @RefNo OUTPUT

select @RefNo = @RefNo + 100000000000

INSERT INTO dbo.bettrans( custid, username, refno, transdate, matchid, bettype, transdesc, winlost, actual_stake, 
					  winlostdate, creator,recommend,mrecommend,srecommend,currency, currencyName,
					  actualrate,ruben, status,ip,statusID)
VALUES (@CustID, @username, @RefNo, current_timestamp, 0, @bettype, @transdesc, @creditamt, @debitamt, 
        @winlostdate, @UserID, @Recommend, @MRecommend, @SRecommend, @curr, @currName,
        @actualrate,1, 'Completed',@ip,131)

if @@ERROR <> 0
BEGIN
	--rollback Debit Balance
	IF @roleID = 1
	BEGIN 
		IF @balance < 0 
		BEGIN 
			SELECT @balance_ABS = ABS(@balance)
			EXEC Dot_BalanceUpdCredit @CustID = @custid, @balance = @balance_ABS  
		END
	END

	delete bettrans where custid = @custid and refno = @refno and matchid = 0	
	Select @ErrMsg = 'Insert trans failed. Please try again.', @ErrCode = 103		
	return
END
Select @TransID = @@IDENTITY

-- Update Transfer Amount in bodb_report.dbo.rptStatement table before move bet day
DECLARE @MoveBetsDay DATETIME
SELECT @MoveBetsDay = MAX(eventdate)
FROM dbo.match14 WITH (NOLOCK)

IF @winlostdate <= @MoveBetsDay
BEGIN
				EXEC [DBRPT].bodb_report.dbo.[Acc_StatementUpdateTransfer]
		@custid = @custid
		,@Amount = @amount
		,@winlostdate = @winlostdate
		,@ErrCode = @ErrCode OUTPUT
		,@ErrMsg = @ErrMsg OUTPUT

	if @@ERROR <> 0
	BEGIN
		--rollback Debit Balance
		IF @roleID = 1
		BEGIN 
			IF @balance < 0 
			BEGIN 
				SELECT @balance_ABS = ABS(@balance)
				EXEC Dot_BalanceUpdCredit @CustID = @custid, @balance = @balance_ABS  
			END
		END

		delete bettrans where custid = @custid and refno = @refno and matchid = 0	
		Select @ErrMsg = 'Insert trans failed. Please try again.', @ErrCode = 104		
		return
	END

END

-----Update balance Credit
IF @roleID = 1
BEGIN 
	IF @balance > 0 
	BEGIN 
		EXEC Dot_BalanceUpdCredit @CustID = @custid, @balance = @balance 
	END
END

declare @LogData nvarchar(200)
Select @LogData = 'Add transaction for :' + convert(varchar(20), @CustID) + ' with amount ' + convert(varchar(20), @amount) + ' Ref.NO ' + convert(varchar(20), @RefNo) + ' TransID ' + convert(varchar(20), @TransID)  

BEGIN TRY
	EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Transfer @UserID = @UserID, @FromCustID = 0, @ToCustID = @CustID, @IP = @IP, @Doing = @LogData
END TRY
BEGIN CATCH
	Select @LogData = @LogData + ' ErrMsg=' + error_message()
	EXEC bodb_customerlog.dbo.WriteLog_UserLog_Transfer @UserID = @UserID, @FromCustID = 0, @ToCustID = @CustID, @IP = @IP, @Doing = @LogData
END CATCH

END

GO
GRANT EXECUTE ON [dbo].[Acc_BettransInsTransaction] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_BettransInsTransaction] TO [ITVivi] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_BettransInsTransaction] TO [vnteam] AS [dbo]