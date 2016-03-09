ALTER PROCEDURE [dbo].[Task_ResetWinning_ExtraPT_Add]
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
	Creator: Percy
	Date: 20160304
	Remark: Add new function for Reset Winning (Extra PT) [Redmine: #51721]
	DB: DBTXN.bodb02

	Revisions:

	Param's explain:

*/
BEGIN
	SET NOCOUNT ON 
	
	Declare @RefNum bigint = 0, @bettype int, @Curr int, @CurrName nvarchar(10),
            @actualrate float, @Recommend int, @MRecommend int, @SRecommend int,
            @username nvarchar(50), @creditamt money, @debitamt money, @roleID tinyint

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
		,@actualrate = e.actualrate
		,@currName = e.currency
		,@username = c.username
		,@Recommend = c.Recommend
		,@MRecommend = c.MRecommend
		,@SRecommend = c.SRecommend
		,@roleID = roleid
	FROM DBCUST.CustDB.dbo.custInfo c WITH (NOLOCK)
		INNER JOIN DBCUST.CustDB.dbo.exchange e WITH (NOLOCK)
		ON c.currency = e.exchangeid
	WHERE c.CustID = @custid


    ----Insert transaction
    EXEC DBTRANS.bodb02.dbo.Acc_SelRefNo
        @refNo = @RefNum OUTPUT

    SELECT @RefNum = @RefNum + 100000000000


	DECLARE @DummyCust AS TABLE (CustId INT)
	DECLARE @isTest BIT,@SQL NVARCHAR(100) = OBJECT_NAME(@@PROCID)

	IF  (@SQL like '%_xtest%' OR  @SQL like '%_xpre%' )
	BEGIN
		SELECT @isTest = 1
	END
	ELSE
	BEGIN
		SELECT @isTest = 0
	END


	IF @isTest = 0
	BEGIN 
		INSERT INTO @DummyCust (CustID)
		SELECT custid
		FROM DBACC.bodb_ACC.dbo.Acc_DWLList_ExtraPT WITH(NOLOCK)
	END 
	ELSE
	BEGIN 
		INSERT INTO @DummyCust (CustID)
		SELECT custid
		FROM DBACC.bodb_ACC.dbo.Acc_DWLList_ExtraPT_xtest WITH(NOLOCK)

	END 

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
               AND custid IN (SELECT custid FROM @DummyCust )

            RETURN
        END
        
        
    END CATCH

END


GO

GRANT EXECUTE ON [dbo].[Task_ResetWinning_ExtraPT_Add] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[Task_ResetWinning_ExtraPT_Add] TO [vnteam] AS [dbo]
GO