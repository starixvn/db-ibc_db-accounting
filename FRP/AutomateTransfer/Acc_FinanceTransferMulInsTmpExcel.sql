ALTER PROCEDURE [dbo].[Acc_FinanceTransferMulInsTmpExcel]	
	@UserID INT,
	@ListTransfer XML,	
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(80) = '' OUTPUT
AS
/*
	Created: 
	Task : Insert new multi transactions into Acc_CustFinanceTransfer
	DB: DBACC/bodb02
	Original: 

	Revisions:		
		- 20111018@Lukas: support to insert with right order in excel file
		- 20111130@Lukas: expand the trans description length
		- 20111201@Lukas: re-arrange the transaction order in case of multiple batches.
		- 20121224@Elodie: Get the current system exchange rate
		- 20130201@Elodie: Change link server DB03 to DBPOLICY
		- 20130224@Lukas: move Acc_CustFinanceTransfer to new database bodb_acc
		- 20130521@Elodie: Get more fields such as MinActualrate, MaxActualRate, MultipliedBy... to verify more new specific cases
*/
BEGIN
SET NOCOUNT ON
			
	--Check permission for account site
	EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[AutomateFinanceTransfer]',@ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
	
	IF @ErrCode <> 0
		RETURN

	DECLARE @tblCust TABLE (
		Seq INT,
		FromCust VARCHAR(30),
		ToCust VARCHAR(30),
		Amount VARCHAR(20),
		ExRate VARCHAR(20),
		Description	NVARCHAR(200)
	)
	
	DECLARE @tblSucc TABLE (
		Seq INT,
		FromCust VARCHAR(30),
		ToCust VARCHAR(30),
		FromCurrency INT,
		ToCurrency INT,
		Amount VARCHAR(20),
		ExRate VARCHAR(20),
		Description	NVARCHAR(200),
		CurrentExRate VARCHAR(20),
		MinActualrate SMALLMONEY, 	
		MaxActualrate SMALLMONEY,
		MultipliedBy INT,
		CurrencyName VARCHAR(5)
	)

	DECLARE @tblFail TABLE (
		Seq INT,
		FromCust VARCHAR(30),
		ToCust VARCHAR(30),
		Amount VARCHAR(20),
		ExRate VARCHAR(20),
		Description	NVARCHAR(200),
		Reason NVARCHAR(100)
	)
	
	INSERT INTO @tblCust(Seq, FromCust, ToCust, Amount,	ExRate,	Description)				
	SELECT	T.C.value('./@Seq', 'int'),
			T.C.value('./@FromCust', 'varchar(30)'),
			T.C.value('./@ToCust', 'varchar(30)'),
			T.C.value('./@Amount', 'varchar(20)'),
			T.C.value('./@ExRate', 'varchar(20)'),
			T.C.value('./@Description', 'nvarchar(200)')
	FROM @ListTransfer.nodes('/ListTransfer/Transfer') AS T(C)
	
	--Validate transaction
	INSERT INTO @tblSucc(Seq, FromCust, ToCust, FromCurrency, ToCurrency, Amount, ExRate, Description, CurrentExRate, MinActualrate, MaxActualrate, MultipliedBy, CurrencyName)
	SELECT	t.Seq,			
			t.FromCust, 
			t.ToCust ,	
			c1.currency,
			c2.currency,
			t.Amount,	
			t.ExRate,	
			t.Description,
			CASE WHEN c1.currency = c2.currency THEN 1 
				 WHEN c2.currency = 2 THEN e1.actualrate 
				 WHEN c1.currency = 2 THEN 1/e2.actualrate END,
			er.MinActualRate,
			er.MaxActualRate,
			CASE WHEN c2.currency = 2 THEN e1.MultipliedBy 
				 WHEN c1.currency = 2 THEN e2.MultipliedBy
				 ELSE e1.MultipliedBy END,
			CASE WHEN c2.currency = 2 THEN e1.currency 
				 WHEN c1.currency = 2 THEN e2.currency
				 ELSE e1.currency END			
	FROM	@tblCust as t
			INNER JOIN custinfo c1 WITH (NOLOCK) on t.FromCust = c1.Username
			INNER JOIN custinfo c2 WITH (NOLOCK) ON t.ToCust = c2.Username
			INNER JOIN Exchange e1 WITH (NOLOCK) ON c1.currency = e1.exchangeid
			INNER JOIN Exchange e2 WITH (NOLOCK) ON c2.currency = e2.exchangeid
			LEFT JOIN DBPOLICY.bodb02.dbo.Acc_ExchangeRate er WITH (NOLOCK) ON er.FromExchangeID = e1.exchangeid and er.ToExchangeID = e2.exchangeid
	WHERE ISNUMERIC(Amount)=1 and ISNUMERIC(ExRate)=1
			and cast(ExRate AS FLOAT) > 0
			and cast(Amount AS FLOAT) <> 0
			and ISNULL(FromCust,'') <> '' 
			and ISNULL(ToCust,'') <> ''
			and FromCust <> ToCust
			and len(t.Description) <= 200
			
	
	--Failed Transaction
	INSERT INTO @tblFail(Seq, FromCust, ToCust, Amount,	ExRate,	Description, Reason)
	SELECT	Seq, FromCust, ToCust ,	Amount,	ExRate,	Description,  
			CASE WHEN ISNUMERIC(Amount)=0 or ISNUMERIC(ExRate)=0 or cast(ExRate AS FLOAT) <= 0 or cast(Amount AS FLOAT) = 0 THEN '<b>Invalid Amount or Actual Rate.</b>'
				 WHEN ISNULL(FromCust,'') ='' and ISNULL(ToCust,'') ='' THEN '<b>Username cannot be blanked.</b>' 
				 WHEN FromCust = ToCust THEN '<b>From Cust must different To Cust.</b>' 
				 WHEN len(Description) > 200 THEN '<b>Maximum length of Description is 200 characters</b>' 				 
				 ELSE '<b>Invalid From Cust or To Cust.</b>' END AS Reason 	
	FROM	(SELECT * FROM @tblCust WHERE Seq not in (SELECT Seq FROM @tblSucc)) AS temp
			
			
	--Insert data to temp table Acc_CustFinanceTransfer to transer after clicking "Update Now" button
	INSERT INTO bodb_acc.dbo.Acc_CustFinanceTransfer(UserId, FromCust, ToCust, Amount, ExRate, Description, Seq)
	SELECT	@UserId,
			FromCust, 
			ToCust ,	
			Amount,	
			ExRate,	
			Description,
			Seq			
	FROM	@tblSucc as t
	
	
	IF @@ERROR <> 0
	BEGIN
		SELECT	@ErrMsg = 'Insert process is unsuccessful.',
				@ErrCode = 103
		RETURN			
	END
	
	SELECT * FROM @tblSucc ORDER BY seq ASC

	SELECT * FROM @tblFail ORDER BY seq ASC
END
GO

GO
GRANT EXECUTE ON [dbo].[Acc_FinanceTransferMulInsTmpExcel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_FinanceTransferMulInsTmpExcel] TO [vnteam]