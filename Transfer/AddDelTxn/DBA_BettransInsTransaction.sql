ALTER PROCEDURE [dbo].[DBA_BettransInsTransaction]
	@custid int,	
	@actual_stake money,
	@winlost money,
	@winlostdate datetime = '2009-03-02',
	
	@transdesc nvarchar(300) = 'Horse racing correction trans',
	@UserID int = 360418,
	@IP nvarchar(15) = '',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@Language varchar(2)= 'E'
AS

SET NOCOUNT ON

/*
Created: 
DB: DBTXN/bodb02
Revisions:
	- 20091012@Kiwi: modify written log	and remove CustBetCreditUpdResync	
	- 20100424@Henry: insert data to column StatusID of Bettrans (StatusID = 131 for bettype 101 and 102)+ Update Status = 'Completed'
	- 20101007@Henry: Change column transid from INT to BIGINT
	- 20101225@Henry: change bettype to new range
	- 20111028@Sophia: update balance
	- 20120412@Sophia: Revise balance credit/debit
	- 20130201@Elodie: Write more log on DBTXN server in case of DBLOG server failure
Param's Explanation:
*/

Declare @RefNo bigint, @bettype int, @Curr int, @CurrName nvarchar(10),@actualrate float,
		@Recommend int, @MRecommend int, @SRecommend int, @username nvarchar(50), @transid bigint,
		@balance money, @balance_ABS money


if @actual_stake = 0 and @winlost = 0
BEGIN
	SELECT @ErrMsg =  case @Language
						when 'E' then 'Invalid amount.'
						when 'CS' then N'Invalid amount.'
						when 'J' then N'Invalid amount.'
						else N'Invalid amount.'
					end, @ErrCode = 104	
	return
END

if @winlost - @actual_stake  > 0 --Deposit
BEGIN
	select @BetType = 21001
END
else --Withdraw
BEGIN
	select @BetType = 21002
END

Select @Curr = c.Currency, @actualrate = e.actualrate, @currName = e.currency,@username = c.username,  
	   @Recommend = c.Recommend, @MRecommend = c.MRecommend, @SRecommend = c.SRecommend 
from Custinfo c with (NOLOCK) 
	INNER JOIN Exchange e with (NOLOCK) on c.currency = e.exchangeid 
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

---update balance debit
SELECT @balance = @winlost - @actual_stake
IF 	@balance < 0 
	BEGIN 
		SELECT @balance_ABS = ABS(@balance)
		EXEC Dot_BalanceUpdDebit @custid = @custid, @balance = @balance_ABS
	END 

---insert transaction
EXEC dbo.Acc_SelRefNo @refNo = @RefNo OUTPUT

select @RefNo = @RefNo + 100000000000

INSERT INTO bettrans( custid, username, refno, transdate, matchid, bettype, transdesc, winlost, actual_stake, 
					  winlostdate, creator,recommend,mrecommend,srecommend,currency, currencyName,
					  actualrate,ruben, status,ip,statusID)
VALUES (@CustID, @username, @RefNo, current_TIMESTAMP, 0, @bettype, @transdesc, @winlost, @actual_stake, 
        @winlostdate, @UserID, @Recommend, @MRecommend, @SRecommend, @curr, @currName,
        @actualrate,1, 'Completed', @ip,131)

---update balance credit       
	IF  @balance > 0 
	BEGIN 
		EXEC Dot_BalanceUpdCredit @custid = @custid, @balance = @balance
	END
        
        
select @transid = @@IDENTITY

if @@ERROR <> 0
BEGIN
	delete bettrans where refno = @refno and matchid = 0
	Select @ErrMsg = 'Insert trans failed. Please try again.', @ErrCode = 103		
	return
END

declare @LogData varchar(200)
Select @LogData = 'Add transaction for :' + convert(varchar(20), @CustID) + ' Ref.NO ' + convert(varchar(20), @RefNo) + ' TransID ' + convert(varchar(20), @TransID)  

BEGIN TRY
	EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Transfer @UserID = @UserID, @FromCustID = 0, @ToCustID = @CustID, @IP = @IP, @Doing = @LogData
END TRY
BEGIN CATCH
	Select @LogData = @LogData + ' ErrMsg=' + error_message()
	EXEC bodb_customerlog.dbo.WriteLog_UserLog_Transfer @UserID = @UserID, @FromCustID = 0, @ToCustID = @CustID, @IP = @IP, @Doing = @LogData
END CATCH

GO
GRANT VIEW DEFINITION ON [dbo].[DBA_BettransInsTransaction] TO [VNTeam]
GO 