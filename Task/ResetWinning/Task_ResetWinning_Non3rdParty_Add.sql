ALTER PROCEDURE [dbo].[Task_ResetWinning_Non3rdParty_Add]
(
	@winlostdate DATETIME,
	@custid      INT,
	@amount      MONEY,
	@transdesc   VARCHAR(300),
	@creator     INT,
	@ip          VARCHAR(20),
	@ErrCode     INT = 0 OUTPUT,  
    @ErrMsg      VARCHAR(100) = '' OUTPUT
)
AS
/*
	Created: 20140624@Logan
	Task: Insert reset winning transaction into bettrans
	DB: DBTXN.BODB02
	
	Revision:

*/
BEGIN
	SET NOCOUNT ON 
	
	Declare @RefNum bigint = 0, @bettype int, @Curr int, @CurrName nvarchar(10),
            @actualrate float, @Recommend int, @MRecommend int, @SRecommend int,
            @username nvarchar(50), @creditamt money, @debitamt money, @roleID tinyint

    if @amount > 0 --Deposit
	BEGIN
	    select @creditamt = abs(@amount),
               @debitamt = 0,
			   @bettype = 21001
	end
	else --Withdraw
	BEGIN
	    select @creditamt = 0,
		       @debitamt = abs(@amount),
			   @bettype = 21002
    end

    select @Curr = c.Currency,
	       @actualrate = e.actualrate,
	       @currName = e.currency,
	       @username = c.username,  
		   @Recommend = c.Recommend,
		   @MRecommend = c.MRecommend,
		   @SRecommend = c.SRecommend,
		   @roleID = roleid
      from CustDB.dbo.custInfo c with(NOLOCK)
INNER JOIN CustDB.dbo.exchange e with(NOLOCK) on c.currency = e.exchangeid
     where c.CustID = @custid

    ----Insert transaction
    EXEC Acc_SelRefNo
        @refNo = @RefNum OUTPUT

    select @RefNum = @RefNum + 100000000000

    BEGIN TRY
	    INSERT INTO bettrans
        (
	        custid, username, refno, transdate, matchid,
	        bettype, transdesc, winlost, actual_stake, winlostdate,
	        creator, recommend, mrecommend, srecommend, currency,
	        currencyName, actualrate, ruben, status, ip, statusID
	    )
	    VALUES
	    (
	        @CustID, @username, @RefNum, current_timestamp, 0,
	        @bettype, @transDesc, @creditamt, @debitamt, @winlostdate,
	        @creator, @Recommend, @MRecommend, @SRecommend, @curr,
	        @currName, @actualrate, 1, 'Completed', @ip, 131
        )
    END TRY
    
    BEGIN CATCH 
        IF @@ERROR <> 0
	    BEGIN
	        SELECT @ErrCode = 1,
	               @ErrMsg = 'Can not insert transaction! Please try again later.'

            DELETE bettrans
             WHERE bettype IN (21001, 21002)
               AND winlostdate = @winlostdate
               AND custid IN (SELECT custid
                                FROM DBACC.bodb_ACC.dbo.Acc_DWLList WITH(NOLOCK)
                               WHERE seq NOT IN (0, 4, 6)
                             )

            RETURN
        END
        
        
    END CATCH

END
GO
GRANT VIEW DEFINITION ON [dbo].[Task_ResetWinning_Non3rdParty_Add] TO [vnteam] AS [dbo]