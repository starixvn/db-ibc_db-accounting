/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_FinanceCrossTransferMulInsTmpExcel]	
	@UserID INT,
	@arrFromCust VARCHAR(4000),
	@arrToCust VARCHAR(4000),	
	@arrAmount VARCHAR(4000),
	@arrToAmount VARCHAR(4000),	
	@arrDescription NVARCHAR(4000),
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(80) = '' OUTPUT
AS
/*
	Created: 20111003@Lukas
	Task : Insert new multi cross-currency transactions into Acc_CustFinanceTransfer
	DB: DBACC/bodb02
	Original: 
		
	Revisions:		
		- 20111130@Lukas: expand the trans description length
		- 20130201@Elodie: Change link server DB03 to DBPOLICY
		- 20130224@Lukas: Move Acc_CustFinanceTransfer to new database bodb_acc		
		- 20130418@Lukas: hot fix modify condition of checking valid amount	  
		- 20180808@Helen: Get code from PRO + DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]
*/
BEGIN
SET NOCOUNT ON
			
	--Check permission for account site
	EXEC NAP_UserControl.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[AutomateFinanceTransfer]',@ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
	
	IF @ErrCode <> 0
		RETURN

	DECLARE @tblCust TABLE (
		Rank int,
		FromCust VARCHAR(30),
		ToCust VARCHAR(30),		
		Amount VARCHAR(20),
		ToAmount VARCHAR(20),		
		Description	NVARCHAR(200)
	)
	
	DECLARE @tblSucc TABLE (
		Rank int,
		FromCust VARCHAR(30),
		ToCust VARCHAR(30),
		Amount VARCHAR(20),
		ToAmount VARCHAR(20),		
		Description	NVARCHAR(200),
		Reason NVARCHAR(100)
	)

	DECLARE @tblFail TABLE (
		FromCust VARCHAR(30),
		ToCust VARCHAR(30),
		Amount VARCHAR(20),		
		ToAmount VARCHAR(20),
		Description	NVARCHAR(200),
		Reason NVARCHAR(100)
	)
	-- check if there is no (char(8)) at the end of string
	IF (SELECT CHARINDEX(CHAR(8),@arrFromCust,LEN(@arrFromCust))) = 0
		OR 
		(SELECT CHARINDEX(CHAR(8),@arrToCust,LEN(@arrToCust))) = 0
		OR 
		(SELECT CHARINDEX(CHAR(8),@arrAmount,LEN(@arrAmount))) = 0
		OR 
		(SELECT CHARINDEX(CHAR(8),@arrToAmount,LEN(@arrToAmount))) = 0
		OR 
		(SELECT CHARINDEX(CHAR(8),@arrDescription,LEN(@arrDescription))) = 0
	BEGIN
		SELECT	@ErrMsg = 'Param input is invalid.',
				@ErrCode = 100
		RETURN	
	END

	INSERT INTO @tblCust(Rank, FromCust, ToCust, Amount, ToAmount, Description)
	SELECT	fc.Rank AS Rank,
			fc.val AS FromCust, 
			tc.val AS ToCust,
			fa.Val AS Amount,
			ta.val AS ToAmount,
			de.Val AS Description
	FROM	dbo.strSplit(@arrFromCust, CHAR(8)) fc
			INNER JOIN dbo.strSplit(@arrToCust, CHAR(8)) tc ON fc.RANK = tc.RANK
			INNER JOIN dbo.strSplit(@arrAmount, CHAR(8)) fa ON fc.RANK = fa.RANK
			INNER JOIN dbo.strSplit(@arrToAmount,CHAR(8)) ta ON fa.RANK = ta.RANK	
			INNER JOIN dbo.strSplit(@arrDescription, CHAR(8)) de ON ta.RANK=de.RANK
			
	
	--Validate transaction
	INSERT INTO @tblSucc(Rank, FromCust, ToCust, Amount, ToAmount, Description)
	SELECT	t.Rank,			
			FromCust, 
			ToCust ,	
			Amount,	
			ToAmount,
			Description
	FROM	@tblCust AS t
			INNER JOIN custinfo c1 WITH(NOLOCK) ON t.FromCust = c1.Username
			INNER JOIN custinfo c2 WITH(NOLOCK) ON t.ToCust = c2.Username
	WHERE	ISNUMERIC(Amount)=1 
			AND ISNUMERIC(ToAmount)=1
			AND CONVERT(MONEY,Amount)/CONVERT(MONEY,ToAmount) > 0 -- check if same sign
			AND CONVERT(MONEY,Amount) <> 0
			AND CONVERT(MONEY,ToAmount) <> 0
			AND ISNULL(FromCust,'') <> '' 
			AND ISNULL(ToCust,'') <> ''
			AND FromCust <> ToCust
			AND LEN(Description) <= 200
			AND c1.currency <> c2.currency
			
	--Failed Transaction
	INSERT INTO @tblFail(FromCust, ToCust ,	Amount,	ToAmount, Description, Reason)
	SELECT	FromCust, ToCust, Amount, ToAmount, Description,
			CASE WHEN ISNUMERIC(Amount)=0 OR ISNUMERIC(ToAmount)= 0 OR CONVERT(MONEY,Amount)/CONVERT(MONEY,ToAmount) < 0 THEN '<b>Invalid Amount.</b>'
				 WHEN ISNULL(FromCust,'') = ''  OR ISNULL(ToCust,'') = '' THEN '<b>Username cannot be blanked.</b>' 
				 WHEN FromCust = ToCust THEN '<b>From Cust must different To Cust.</b>' 
				 WHEN LEN(Description) > 200 THEN '<b>Maximum length of Description is 200 characters</b>' 
				 WHEN c1.currency = c2.currency THEN '<b>Not support the same currency</b>' 
				 ELSE '<b>Invalid From Cust or To Cust.</b>' END AS Reason 	

	FROM	(	SELECT * 
				FROM @tblCust 
				WHERE Rank NOT IN (SELECT Rank FROM @tblSucc)
			) AS temp 
			INNER JOIN custinfo c1 WITH(NOLOCK) ON temp.FromCust = c1.username
			INNER JOIN custinfo c2 WITH(NOLOCK) ON temp.ToCust = c2.username
			

	--Insert data to temp table Acc_CustFinanceTransfer to transer after clicking "Update Now" button
	INSERT INTO bodb_acc.dbo.Acc_CustFinanceTransfer(UserId, FromCust, ToCust, Amount, ToAmount, Description, ExRate)
	SELECT	@UserId,
			FromCust, 
			ToCust ,	
			Amount,
			ToAmount,	
			Description,
			-1
	FROM	@tblSucc AS t
	
	
	IF @@ERROR <> 0
	BEGIN
		SELECT	@ErrMsg = 'Insert process is unsuccessful.',
				@ErrCode = 103
		RETURN			
	END
	
	SELECT * FROM @tblSucc
	
	SELECT * FROM @tblFail 

END
GO