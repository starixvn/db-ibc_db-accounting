/*<info serverAlias="DBTXN-bodb02" executers="bodbAdminNet"  isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Task_ResetWinning_Non3rdParty_Add]
(
	@winlostdate SMALLDATETIME,
	@custid      INT,
	@amount      MONEY,
	@transdesc   NVARCHAR(1000),
	@creator     INT,
	@ip          VARCHAR(45),
	@isExtraPT	 BIT = 0,
	@ErrCode     INT = 0 OUTPUT,  
    @ErrMsg      VARCHAR(100) = '' OUTPUT
)
AS
/*
	Created: 20140624@Logan
	Task: Insert reset winning transaction into bettrans
	DB: DBTXN.BODB02
	
	Revision:
		- 20150615@Sophia: . Apply Gold Deluxe 
						   . Remove P2P (Poker)
						   . Revise Code
						   . Apply AG Casino and Vegas Game [#37683]
		- 20160315@Percy: Add params @isExtra for new function ExtraPT [Redmine: 51721]
		- 20180412@Percy: Increase Transdesc length to 1000 [RedmineID: #92841]
		- 20190801@Sophia: Integrate CN88, use ExchangeDailyOanda instead of exchange table [Redmine: #117809]		
		- 20190826@Sophia: remove Rollback code (in CATCH block) [Redmine: #117863]
		- 20211122@Danny: Split transfer tickets out of bettrans [Redmine: #164196]
		- 20220721@Danny: get transid and refno with new generation [Redmine: #175670]
		- 20221024@Sol: Database - Sync-up Standby Server data - [RedmineID: #167261]
		- 20230609@Danny: write log [Redmine: #181595]

*/
BEGIN
	SET NOCOUNT ON 
	
	Declare @RefNum bigint = 0, @bettype int, @Curr int, @CurrName nvarchar(10),
            @actualrate float, @Recommend int, @MRecommend int, @SRecommend int,
            @username nvarchar(50), @creditamt money, @debitamt money, @roleID tinyint, @TransID BIGINT

	IF @amount > 0 --Deposit
	BEGIN
		SELECT @creditamt = abs(@amount)
			,@debitamt = 0
			,@bettype = 21001
	END
	ELSE --Withdraw
	BEGIN
		SELECT @creditamt = 0
			,@debitamt = abs(@amount)
			,@bettype = 21002
	END


	SELECT @Curr = c.Currency
		,@actualrate = eo.actualrate
		,@currName = e.currency
		,@username = c.username
		,@Recommend = c.Recommend
		,@MRecommend = c.MRecommend
		,@SRecommend = c.SRecommend
		,@roleID = roleid
	FROM CustDB.dbo.custInfo c WITH (NOLOCK)
		INNER JOIN CustDB.dbo.ExchangeDailyOanda eo WITH (NOLOCK)
			ON c.currency = eo.exchangeid and eo.exchangeDate = @winlostdate
		INNER JOIN CustDB.dbo.Exchange e WITH (NOLOCK)
			ON c.currency = e.exchangeid
	WHERE c.CustID = @custid


    ----Insert transaction
    EXEC Get_Refno_Transid @RefNo = @RefNum OUTPUT
   
	EXEC Get_Bettrans_TransID @TransID = @TransID OUTPUT

    BEGIN TRY
	    INSERT INTO dbo.transfer
        (
	        transid, custid, username, refno, transdate,
	        bettype, transdesc, winlost, actual_stake, winlostdate,
	        creator, recommend, mrecommend, srecommend, currency,
	        currencyName, actualrate, ip, statusID, RepUpdateTime
	    )
	    VALUES
	    (
	        @TransID, @CustID, @username, @RefNum, current_timestamp,
	        @bettype, @transDesc, @creditamt, @debitamt, @winlostdate,
	        @creator, @Recommend, @MRecommend, @SRecommend, @curr,
	        @currName, @actualrate, @ip, 131, SYSDATETIME()
        )
    END TRY
    
    BEGIN CATCH 
        IF @@ERROR <> 0
	    BEGIN
	        SELECT @ErrCode = 1,
	               @ErrMsg = 'Can not insert transaction! Please try again later.'			

            RETURN
        END
        
        
    END CATCH

	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Transfer
				@UserID = @creator,
				@FromCustID = 0,
				@ToCustID = @custid,
				@IP = @ip,
				@Doing = @transDesc
		BEGIN
			-- get move bet date
			DECLARE @tblMoveBetBalanceUp AS TABLE (BalanceUpDay SMALLDATETIME, MoveBetsDay SMALLDATETIME)
			DECLARE @MoveBetsDay SMALLDATETIME

			INSERT INTO @tblMoveBetBalanceUp(BalanceUpDay,MoveBetsDay)
			EXEC bodb02.dbo.Age_SelBalanceUpDay
	
			-- GET the current MB date
			SELECT @MoveBetsDay = MoveBetsDay FROM @tblMoveBetBalanceUp

		---run only in range 14
		IF (@winlostdate <= @MoveBetsDay)
		BEGIN
			DECLARE
				@alias VARCHAR(100), 
				@sqlCommand VARCHAR(MAX),
				@doNotRunInServer VARCHAR(1000),
				@remark VARCHAR(4000)

			---get server name that dont need to run
			EXEC bodb02.dbo.Get_ServerName_By_Alias @Alias  = 'DBTXN', @ServerName = @doNotRunInServer OUTPUT
			SELECT @alias = 'DBACC', @remark = 'step 5.1/5.2 -> Task_ResetWinning_Non3rdParty_Add -> Acc_StatementUpdateTransfer'

			SELECT @SqlCommand = CONCAT('EXEC DBRPT.bodb_report.dbo.Acc_StatementUpdateTransfer ', ' @custid = ',@custid,' ,@Amount = ',@amount,' ,@winlostdate = ''',CONVERT(VARCHAR(50), @winlostdate, 121), '''')
			SELECT @SqlCommand = REPLACE(@SqlCommand,'DBRPT.','')

			EXEC DBCTG.bodb02.dbo.Task_ExecRep_Wrapper 
				@ServerName = '', 
				@AliasName = @alias, 
				@SqlCommand = @SqlCommand, 
				@doNotRunInServer = @doNotRunInServer,
				@Remark = @remark
		END
	END

END

