ALTER PROCEDURE [dbo].[Task_ResetWinning_3rdParty_Add]
(
	@winlostdate DATETIME,
	@custid INT,
	@amount MONEY,
	@transdesc VARCHAR(300),
	@creator INT,
	@ip VARCHAR(20)
)
AS
/*
	Created: 20120729@Lukas
	Task: insert reset winning transaction into bettrans
	DB: DBTRANS.BODB02
	
	Revision:
		- 20131108@Elodie: Splitting bodb02 into CustDB (call CustInfo, Exchange by link database)
*/
BEGIN
	SET NOCOUNT ON 
	
	Declare @RefNo bigint, @bettype int, @Curr int, @CurrName nvarchar(10),@actualrate float,
			@Recommend int, @MRecommend int, @SRecommend int, @username nvarchar(50),
			@creditamt money, @debitamt money, @roleID tinyint		
	
	
	IF @amount > 0 --Deposit
	BEGIN
		select @creditamt = abs(@amount), @debitamt = 0,
			 @bettype = 21001
	END
	else --Withdraw
	BEGIN
		select @creditamt = 0, @debitamt = abs(@amount),
			 @bettype = 21002
	END

	Select @Curr = c.Currency, @actualrate = e.actualrate, @currName = e.currency,@username = c.username,  
		   @Recommend = c.Recommend, @MRecommend = c.MRecommend, @SRecommend = c.SRecommend , @roleID = roleid
	FROM CustDB.dbo.custinfo c with (NOLOCK) 
		INNER JOIN CustDB.dbo.exchange e with (NOLOCK) on c.currency = e.exchangeid 
	where c.CustID = @custid  
	
	----Insert transaction
	EXEC dbo.Acc_SelRefNo @refNo = @RefNo OUTPUT

	select @RefNo = @RefNo + 100000000000

	INSERT INTO bettrans( custid, username, refno, transdate, matchid, bettype, transdesc, winlost, actual_stake, 
						  winlostdate, creator,recommend,mrecommend,srecommend,currency, currencyName,
						  actualrate,ruben, status,ip,statusID)
	VALUES (@CustID, @username, @RefNo, current_timestamp, 0, @bettype, @transdesc, @creditamt, @debitamt, 
			@winlostdate, @creator, @Recommend, @MRecommend, @SRecommend, @curr, @currName,
			@actualrate,1, 'Completed',@ip,131)
	        
END



GO
GRANT VIEW DEFINITION ON [dbo].[Task_ResetWinning_3rdParty_Add] TO [vnteam] AS [dbo]