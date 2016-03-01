USE bodb02
GO

/****** Object:  UserDefinedTableType [dbo].[BalanceList]    Script Date: 3/1/2016 9:05:16 AM ******/
CREATE TYPE [dbo].[TVP_BalanceChange] AS TABLE(
	custid INT
	, balance MONEY
	, balanceType TINYINT
)
GO

ALTER PROCEDURE [dbo].[NAP_SpecialDelete_VoidBetIdList_BanlanceUpd]
	@BeforeUpd	TVP_BalanceChange	READONLY
	,@AfterUpd	TVP_BalanceChange	READONLY
AS
/* Created by: Bobby  
 Task:  VOID BY BET ID (Running & Settled tickets)  
 DB: DBTXN/bodb02  
 Original:   
   
 Revisions:  
  
 Param's Explanation:   
	 
 Dependences:
	1. TABLE #balanceGame (custid INT, winlostdate SMALLDATETIME, balance MONEY)
	
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @tblDebitPending TVP_BalanceList
	DECLARE @tblCreditPending TVP_BalanceList
		
	DECLARE @tblDebitOthersPending TVP_BalanceList
	DECLARE @tblCreditOthersPending TVP_BalanceList
	 
	DECLARE @tblDebitCasinoPending TVP_BalanceList
	DECLARE @tblCreditCasinoPending TVP_BalanceList
	
	select * from @BeforeUpd
	select * from @AfterUpd
	
	--BALANCE Credit
	INSERT INTO @tblCreditPending (custid,Balance)  
	SELECT	a.custid, (a.balance - b.balance) as Balance  
	FROM	@BeforeUpd b  
	INNER JOIN @AfterUpd a    
		ON	a.custid = b.custid  
	WHERE  (a.balance - b.balance) > 0
		AND a.balanceType = 1
		AND b.balanceType = 1  
		
	IF @@rowcount <> 0
		EXEC dbo.Dot_BalancePendingCreditIns 
			@BalancePending = @tblCreditPending
			,@Type			= 1 -- Sports
	
	
	INSERT INTO @tblCreditCasinoPending (custid,Balance)  
	SELECT  a.custid, (a.balance - b.balance) as Balance  
	FROM  @BeforeUpd b  
		INNER JOIN @AfterUpd a    
			ON	a.custid = b.custid  
	WHERE  (a.balance - b.balance) > 0
			AND a.balanceType = 3
			AND b.balanceType = 3

	IF @@rowcount <> 0
		EXEC dbo.Dot_BalancePendingCreditIns 
			@BalancePending = @tblCreditCasinoPending
			,@Type			= 3 -- Casino
		
	INSERT INTO @tblCreditOthersPending (custid,Balance)  
	SELECT  a.custid, (a.balance - b.balance) as Balance  
	FROM	@BeforeUpd b  
		INNER JOIN @AfterUpd a    
			ON	a.custid = b.custid  
	WHERE  (a.balance - b.balance) > 0
			AND a.balanceType = 4
			AND b.balanceType = 4
		
	IF @@rowcount <> 0
		EXEC dbo.Dot_BalancePendingCreditIns 
			@BalancePending = @tblCreditOthersPending
			,@Type			= 4 -- Others
	
	 --update balance credit game
	UPDATE bal
	SET Balance = bal.Balance + ABS(tmp.balance)
	FROM dbo.BalanceCreditGame bal WITH(ROWLOCK, UPDLOCK)
		INNER JOIN #balanceGame tmp ON bal.custid = tmp.custid AND bal.winlostdate = tmp.winlostdate
	WHERE tmp.balance < 0

	INSERT INTO dbo.BalanceCreditGame(CustId, WinlostDate, Balance)
	SELECT b.custid, b.winlostdate, ABS(b.balance)
	FROM #balanceGame b
		LEFT JOIN dbo.BalanceCreditGame bal ON bal.custid = b.custid AND bal.winlostdate = b.winlostdate
	WHERE bal.CustId IS NULL AND b.balance < 0
	
	
	--BALANCE Debit
	INSERT INTO @tblDebitPending (custid,Balance)  
	SELECT  a.custid, ABS(a.balance - b.balance) as Balance  
	FROM  @BeforeUpd b  
		INNER JOIN @AfterUpd a    
			ON	a.custid = b.custid  
	WHERE  (a.balance - b.balance) < 0  
			AND a.balanceType = 1
			AND b.balanceType = 1
		
	IF @@rowcount <> 0
		EXEC dbo.Dot_BalancePendingDebitIns 
			@BalancePending = @tblDebitPending
			,@Type			= 1 -- Sports
	 
	INSERT INTO @tblDebitCasinoPending (custid,Balance)  
	SELECT  a.custid, ABS(a.balance - b.balance) as Balance  
	FROM  @BeforeUpd b  
		INNER JOIN @AfterUpd a    
			ON	a.custid = b.custid  
	WHERE	(a.balance - b.balance) < 0 
			AND a.balanceType = 3
			AND b.balanceType = 3 

	IF @@rowcount <> 0
		EXEC dbo.Dot_BalancePendingDebitIns 
			@BalancePending = @tblDebitCasinoPending
			,@Type			= 3 -- Casino
	 
	INSERT INTO @tblDebitOthersPending (custid,Balance)  
	SELECT  a.custid, ABS(a.balance - b.balance) as Balance  
	FROM  @BeforeUpd b  
		INNER JOIN @AfterUpd a    
			ON a.custid = b.custid  
	WHERE   (a.balance - b.balance) < 0  
			AND a.balanceType = 4
			AND b.balanceType = 4

	IF @@rowcount <> 0
		EXEC dbo.Dot_BalancePendingDebitIns 
			@BalancePending = @tblDebitOthersPending
			,@Type			= 4 -- Others
		
	--update balance debit game	
	UPDATE bal
	SET Balance = bal.Balance + tmp.balance
	FROM dbo.BalanceDebitGame bal WITH(ROWLOCK, UPDLOCK)
		INNER JOIN #balanceGame tmp ON bal.custid = tmp.custid AND bal.winlostdate = tmp.winlostdate
	WHERE tmp.balance > 0

	INSERT INTO dbo.BalanceDebitGame(CustId, WinlostDate, Balance)
	SELECT b.custid, b.winlostdate, b.balance
	FROM #balanceGame b
		LEFT JOIN dbo.BalanceDebitGame bal ON bal.custid = b.custid AND bal.winlostdate = b.winlostdate
	WHERE bal.CustId IS NULL AND b.balance > 0
	
	
	RETURN
END
GO
USE [bodb02]
GO
