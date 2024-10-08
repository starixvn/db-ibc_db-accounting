/*<info serverAlias="DBCUST-CustDB" executers="wsv_nap" viewers="vnteam" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Acc_FinanceTransferMulInsTmpExcel]	
	@UserID INT,
	@ListTransfer XML,	
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(80) = '' OUTPUT
AS
/*
	Created: 
	Task : Insert new multi transactions into Acc_CustFinanceTransfer
	DB: DBACC/bodb02 -> DBCUST.CustDB
	Original: 

	Revisions:		
		- 20111018@Lukas: support to insert with right order in excel file
		- 20111130@Lukas: expand the trans description length
		- 20111201@Lukas: re-arrange the transaction order in case of multiple batches.
		- 20121224@Elodie: Get the current system exchange rate
		- 20130201@Elodie: Change link server DB03 to DBPOLICY
		- 20130224@Lukas: move Acc_CustFinanceTransfer to new database bodb_acc
		- 20130521@Elodie: Get more fields such as MinActualrate, MaxActualRate, MultipliedBy... to verify more new specific cases
		- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]
		- 20181112@Sophia: Add @IsCollection [redmine: #98621]
		- 20210426@Sol: Alpha/NAP - Migrate from DBACC to DBCust - [Redmine: #154041]
		- 20230322@Danny: Enhance invalid transaction checking[Redmine: #184731]
		- 20240729@Lewis: Scale Out DBCust - Remove Linked Server [Redmine : #206895]
*/
BEGIN
SET NOCOUNT ON
			

	DECLARE @tblCust TABLE (
		Seq INT,
		FromCust VARCHAR(30),
		ToCust VARCHAR(30),
		Amount VARCHAR(20),
		ExRate VARCHAR(20),
		Description	NVARCHAR(200),
		IsCollection BIT
	)

	DECLARE @tblInfo TABLE (
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
		CurrencyName VARCHAR(5),
		IsCollection BIT,
		FromCurrCode VARCHAR(12),
		ToCurrCode VARCHAR(12),
		FromCurrName NVARCHAR(50),
		ToCurrName NVARCHAR(50)
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
		CurrencyName VARCHAR(5),
		IsCollection BIT,
		FromCurrName NVARCHAR(50),
		ToCurrName NVARCHAR(50),
		FromCurrCode VARCHAR(12),
		ToCurrCode VARCHAR(12)
	)

	DECLARE @tblFail TABLE (
		Seq INT,
		FromCust VARCHAR(30),
		ToCust VARCHAR(30),
		Amount VARCHAR(20),
		ExRate VARCHAR(20),
		Description	NVARCHAR(200),
		Reason NVARCHAR(100),
		IsCollection BIT
	)
	
	INSERT INTO @tblCust(Seq, FromCust, ToCust, Amount,	ExRate,	Description, IsCollection)				
	SELECT	T.C.value('./@Seq', 'int'),
			T.C.value('./@FromCust', 'varchar(30)'),
			T.C.value('./@ToCust', 'varchar(30)'),
			T.C.value('./@Amount', 'varchar(20)'),
			T.C.value('./@ExRate', 'varchar(20)'),
			T.C.value('./@Description', 'nvarchar(200)'),
			T.C.value('./@IsCollection', 'BIT')
	FROM @ListTransfer.nodes('/ListTransfer/Transfer') AS T(C)
	
	--Validate transaction
	INSERT INTO @tblInfo(Seq, FromCust, ToCust, FromCurrency, ToCurrency, Amount, ExRate, Description, CurrentExRate, MinActualrate, MaxActualrate, MultipliedBy, CurrencyName, IsCollection, FromCurrCode, ToCurrCode, FromCurrName, ToCurrName)
	SELECT	t.Seq,			
			t.FromCust, 
			t.ToCust ,	
			c1.currency,
			c2.currency,
			t.Amount,	
			t.ExRate,	
			t.Description,
			CASE WHEN e1.Currency = e2.Currency THEN 1 
				 WHEN e2.Code = 'MYR' THEN e1.actualrate 
				 WHEN e1.Code = 'MYR' THEN 1/e2.actualrate 
				 ELSE e1.actualrate / e2.actualrate  END,
			er.MinActualRate,
			er.MaxActualRate,
			CASE WHEN e2.Code = 'MYR' THEN e1.MultipliedBy 
				 WHEN e1.Code = 'MYR' THEN e2.MultipliedBy
				 ELSE e1.MultipliedBy END,
			CASE WHEN c2.currency = 2 THEN e1.currency 
				 WHEN c1.currency = 2 THEN e2.currency
				 ELSE e1.currency END,
			t.IsCollection,
			e1.Code,
			e2.Code,
			e1.currency,
			e2.currency
			
	FROM	@tblCust as t
			LEFT JOIN custinfo c1 WITH (NOLOCK) on t.FromCust = c1.Username
			LEFT JOIN custinfo c2 WITH (NOLOCK) ON t.ToCust = c2.Username
			LEFT JOIN Exchange e1 WITH (NOLOCK) ON c1.currency = e1.exchangeid
			LEFT JOIN Exchange e2 WITH (NOLOCK) ON c2.currency = e2.exchangeid
			LEFT JOIN DBTXN.bodb02.dbo.Acc_ExchangeRate er WITH (NOLOCK) ON er.FromExchangeID = e1.exchangeid and er.ToExchangeID = e2.exchangeid

	INSERT INTO @tblSucc(Seq, FromCust, ToCust, FromCurrency, ToCurrency, Amount, ExRate, Description, CurrentExRate, MinActualrate, MaxActualrate, MultipliedBy,CurrencyName, IsCollection, FromCurrName, ToCurrName, FromCurrCode, ToCurrCode)
	SELECT	Seq, FromCust, ToCust, FromCurrency, ToCurrency, Amount, ExRate, Description, CurrentExRate, MinActualrate, MaxActualrate, MultipliedBy, CurrencyName, IsCollection, FromCurrName, ToCurrName, FromCurrCode, ToCurrCode
	FROM	@tblInfo as t
	WHERE ISNUMERIC(Amount)=1 and ISNUMERIC(ExRate)=1
			AND CAST(ExRate AS FLOAT) > 0
			AND CAST(Amount AS FLOAT) <> 0
			AND ISNULL(FromCust,'') <> '' 
			AND ISNULL(ToCust,'') <> ''
			AND FromCust <> ToCust
			AND LEN(t.Description) <= 200
			AND (  	
						(FromCurrName = ToCurrName AND CAST(ExRate AS FLOAT) = 1)
					OR	(FromCurrCode = ToCurrCode AND FromCurrName <> ToCurrName)
					OR ( FromCurrCode = 'MYR' AND ToCurrCode <> 'MYR')
					OR ( ToCurrCode = 'MYR' AND FromCurrCode <> 'MYR')
				)
	
	--Failed Transaction
	INSERT INTO @tblFail(Seq, FromCust, ToCust, Amount,	ExRate,	Description, Reason, IsCollection)
	SELECT	Seq, FromCust, ToCust ,	Amount,	ExRate,	Description,  
			CASE WHEN ISNUMERIC(Amount)=0 or ISNUMERIC(ExRate)=0 or cast(ExRate AS FLOAT) <= 0 or CAST(Amount AS FLOAT) = 0 THEN '<b>Invalid Amount or Actual Rate.</b>'
				 WHEN ISNULL(FromCust,'') ='' and ISNULL(ToCust,'') ='' THEN '<b>Username cannot be blanked.</b>' 
				 WHEN FromCust = ToCust THEN '<b>From Cust must different To Cust.</b>' 
				 WHEN LEN(Description) > 200 THEN '<b>Maximum length of Description is 200 characters</b>' 	
				 WHEN FromCurrName = ToCurrName AND CAST(ExRate AS FLOAT) <> 1 THEN '<b>Same currency name, but actual rate is different 1.</b>'
				 WHEN FromCurrCode <> ToCurrCode AND FromCurrCode <> 'MYR' AND ToCurrCode <> 'MYR' THEN '<b>From Cust and To Cust must belong same currency code.</b>'
				 ELSE '<b>Invalid From Cust or To Cust.</b>' END AS Reason
			, IsCollection
	FROM (SELECT *  FROM @tblInfo WHERE Seq not in (SELECT Seq FROM @tblSucc)) AS temp
				
	--Insert data to temp table Acc_CustFinanceTransfer to transer after clicking "Update Now" button
	INSERT INTO dbo.Acc_CustFinanceTransfer(UserId, FromCust, ToCust, Amount, ExRate, Description, Seq, IsCollection)
	SELECT	@UserId,
			FromCust, 
			ToCust ,	
			Amount,	
			ExRate,	
			Description,
			Seq,
			IsCollection			
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