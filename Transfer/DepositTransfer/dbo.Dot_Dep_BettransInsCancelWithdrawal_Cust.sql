/*<info serverAlias="DBTXN-bodb02" executers="Dot_Member,Dot_Bonus" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE  [dbo].[Dot_Dep_BettransInsCancelWithdrawal_Cust]		
	@custid		INT,
	@transid	BIGINT,	
	@transdesc	NVARCHAR(300) = '',
	@ip			VARCHAR(45)='',
	@NewTransID BIGINT = 0 OUTPUT,	
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(200) = '' OUTPUT
AS
/*
DB: DBTXN/bodb02
Creator : Thien
Date : 2007-12-05
Task : withdrawal for Cancel  (in case, withdraw request been rejected , Action: record "deposit" to make balance equal)
User: NON API Licensee/12Bet

Revisions:
	- 20080924: Update actualrate, Username, @currencyName for bettrans
	- 20080926: Get winlostdate as today date
	- 20090702(vivi): check transid exist or not
	- 20091222@viet: get actualrate from exchange table instead
	- 20100320@viet: optimizing this sp to reduce loading from main DB.
	- 20100521@viet: Update for Bettrans.StatusID
	- 20101007@Henry: Change column transid from INT to BIGINT
	- 20101224@Johnson: Apply new arrange of bettype
	- 20111031@Sophia: Update balance for customer
	- 20111214@Sophia: Modify balance
	- 20121110@Viet: revise sp
	- 20121229@Daniel: fix cannot get dummy accounts based on sitename
	- 20131108@Elodie: Splitting bodb02 into CustDB (call Exchange, CustInfo, Dep_CustSuper by link database)
	- 20150606@Kathy: Migrate custDB to new server DBCust. Get cust info from DBCust.CustDB in case of replication problem  [Redmine:#36216]		
	- 20150808@Elodie: Balance Improvement [Redmine:#40125]	
	- 20151230@Cooper: add  @IsForced = 1  for execute sp Dot_BalanceDebitUpd
	- 20211112@Sol: Support IPv6 - Phase 2 - Add [Convert Ipv6 to dummy IPv4] - [Redmine: #163963]
	- 20211111@Sol: Split Transfer out of bettrans/Support IPv6 - [RedmineID: #164301]
	- 20220721@Evan: Integrate new transid [Redmine: #175640]
	- 20220724@Evan: Revise code rollback for scale-out [Redmine: #175297]
	- 20220923@Evan: Revise code rollback (issue) [Redmine: #178135]
	- 20221226@Evan: Wait for in-house service (2ms) to sync new value of rollback ticket to centraldb [Redmine: #182003]
	- 20230322@Evan: Change code write log into bodb_customerlog.UserLog_Transfer [Redmine: #185507]

Input 
    1) CustID (For Double check) 
    2) TransID (This ID is get from "B. deposit/withdrawal for approved" Output TransID )
   Output
    1) Result (@ErrCode)
    2) NewTransID (Cancel)
    
‧ @ErrCode:
	= 0: Transaction recorded successfully.
	> 0: Specific Error.
‧ @ErrMsg: Error description.
*/
SET NOCOUNT ON

---- #1 CHECK UM TRANSFER FUNCTION
EXEC DBCUST.CUSTDB.dbo.Acc_Transfer_CheckUM  
	@CustID = @custid
	,@Language = 'E'
	,@ErrMsg = @ErrMsg OUTPUT 
	,@ErrCode = @ErrCode OUTPUT
	 
IF @ErrCode <> 0  -- Function Transfer is under UM 
BEGIN
	RETURN		
END
	
DECLARE @Cust_SiteDBGroupID SMALLINT, @Server_SiteDBGroupID SMALLINT;
DECLARE @SiteGroupInfo TABLE
(	
	CustID INT,
	SiteDBGroupID SMALLINT,
	LinkedServerName  VARCHAR(512),
	ClientAccessName VARCHAR(512),
	AGIP VARCHAR (50)
)
INSERT INTO @SiteGroupInfo (SiteDBGroupID, LinkedServerName, ClientAccessName, AGIP)
EXEC DBCUST.CustDB.dbo.Acc_SiteDBConfigSel @CustID = @custid

SELECT @Cust_SiteDBGroupID = SiteDBGroupID FROM @SiteGroupInfo
SELECT @Server_SiteDBGroupID = dbo.f_Get_SiteDBGroupID()

--Check the SiteDBGroupID of CustID AND Server is match
IF ISNULL(@Cust_SiteDBGroupID,-1) <> @Server_SiteDBGroupID
BEGIN
	SELECT @ErrMsg = 'Executing on invalid server. Please check SiteDBGroupID information.', @ErrCode = 108	
	RETURN		
END

DECLARE @trans_custid INT,
	@username VARCHAR(50),
	@currency TINYINT,
	@currencyName VARCHAR(5),
	@transdate DATETIME,
	@bettype INT,
	@newBettype INT,
	@amount MONEY,
	
	@actualrate FLOAT,
	@winlost MONEY,
	@actual_stake MONEY,
	@mrecommend INT,
	@recommend INT,
	@srecommend INT,
	@roleid TINYINT,
	@balance MONEY,
	@site VARCHAR(20),
	
	--Balance Account info
	@bal_custid INT,
	@bal_mrecommend INT,
	@bal_recommend INT,
	@bal_srecommend INT,
	@bal_Username VARCHAR(50),
	@winlostdate SMALLDATETIME,
	
	@RefNo BIGINT,
	@DDEP INT,
	@DWIT INT,
	@DCAN INT

SELECT @ErrCode = 0,
	@ErrMsg = '',
	@DDEP = 22001,
	@DWIT = 22002,
	@DCAN = 22003

SELECT @amount = actual_stake,
		@bettype = bettype,
		@RefNo = refno,
		@trans_custid = custid,		
		@currency = currency,
		@currencyName = currencyName,
		@srecommend = srecommend
FROM dbo.Transfer t WITH(NOLOCK)
WHERE transid = @transid

IF @trans_custid <> @custid
BEGIN
	SELECT @ErrMsg = 'Invalid CustID.', @ErrCode = 101
	RETURN
END

SELECT @site = site, @username = username FROM CustDB.dbo.DEP_custsuper d WITH(NOLOCK) WHERE custid=@srecommend

IF @@ROWCOUNT = 0
	SELECT @site = site, @username = username FROM DBCUST.CustDB.dbo.DEP_custsuper d WITH(NOLOCK) WHERE custid=@srecommend

DECLARE @CustIDs AS TABLE (custid INT, isReal BIT)

INSERT INTO @CustIDs (custid, isreal) VALUES (@custid, 1)

INSERT INTO @CustIDs (custid, isreal)
SELECT c.custid, 0
FROM CustDB.dbo.custinfo c WITH(NOLOCK)
	INNER JOIN CustDB.dbo.custinfo a WITH(NOLOCK) on a.custid = c.recommend
WHERE c.roleid = 1
	AND ( a.username = LTRIM(RTRIM(@site))+'ACC' + @currencyName + '01'
			or a.username = LEFT(@username, CHARINDEX('Super', @username)-1) +'ACC' + @currencyName + '01')
IF @@ROWCOUNT = 0
BEGIN
	INSERT INTO @CustIDs (custid, isreal)
	SELECT c.custid, 0
	FROM DBCUST.CustDB.dbo.custinfo c WITH(NOLOCK)
		INNER JOIN DBCUST.CustDB.dbo.custinfo a WITH(NOLOCK) on a.custid = c.recommend
	WHERE c.roleid = 1
		AND ( a.username = LTRIM(RTRIM(@site))+'ACC' + @currencyName + '01'
				or a.username = LEFT(@username, CHARINDEX('Super', @username)-1) +'ACC' + @currencyName + '01')
END
	
DECLARE @TransID_TEMP AS TABLE(RowID INT IDENTITY(1,1), transid BIGINT, custid INT, balance MONEY )

INSERT INTO @TransID_TEMP
SELECT TransID , custid, (winlost - actual_stake) as balance 
FROM dbo.transfer t WITH(NOLOCK) 
WHERE bettype = 22002
	AND custid in (SELECT custid FROM @CustIDs)
	AND refno = @refno
 
IF @@ROWCOUNT = 0
BEGIN
	SELECT @ErrMsg = 'transfer data not found.', @ErrCode = 105
	RETURN
END

DECLARE @Balance_TEMP AS TABLE(custid INT, balance MONEY, isPos BIT)
INSERT INTO @Balance_TEMP
SELECT custid, ABS(SUM(balance)) as balance, CASE WHEN SUM(balance) > 0 THEN 0 ELSE 1 END  
FROM @TransID_TEMP 
GROUP BY custid
 
SELECT @actualrate = actualrate
FROM CustDB.dbo.exchange e WITH(NOLOCK)
WHERE exchangeid = @currency

IF @@ROWCOUNT = 0	
	SELECT @actualrate = actualrate
	FROM DBCUST.CustDB.dbo.exchange e WITH(NOLOCK)
	WHERE exchangeid = @currency

--20080926: Get winlostdate as today date
SELECT @winlostdate = CONVERT(NVARCHAR(10), CURRENT_TIMESTAMP, 120)

IF @bettype <> @DWIT
BEGIN
	SELECT @ErrMsg = 'This transaction is not a withdrawal.', @ErrCode = 102		
	RETURN
END

IF exists (SELECT 1 FROM dbo.Transfer t WITH(NOLOCK) WHERE refno = @RefNo AND bettype = @DCAN AND custid = @custid)
BEGIN
	SELECT @ErrMsg = 'This transaction has been cancelled before.', @ErrCode = 103		
	RETURN
END

---update debit balance
DECLARE	@curCustID		INT,	
		@curBalance		MONEY
		
			
DECLARE CUR CURSOR FOR	SELECT	CustID, Balance 
						FROM	@Balance_TEMP 
						WHERE	IsPos = 0
OPEN CUR
FETCH NEXT FROM CUR INTO @curCustID, @curBalance 
WHILE @@FETCH_STATUS = 0
BEGIN
		
	EXEC Dot_BalanceDebitUpd @CustID = @curCustID, @balance = @curBalance, @type = 2 , @IsForced = 1  -- 20151230 cooper add @IsForced = 1

	FETCH NEXT FROM CUR INTO @curCustID, @curBalance 
END
CLOSE CUR 
DEALLOCATE CUR


SELECT @transdate = CURRENT_TIMESTAMP

DECLARE @Cur_TransID BIGINT;
DECLARE @MaxRowID INT, @Cnt INT = 1;
SElECT @MaxRowID = MAX(RowID) FROM @TransID_TEMP

WHILE @Cnt <= @MaxRowID
BEGIN
	---get new transid 
	EXEC Get_Bettrans_TransID @TransID = @NewTransID OUTPUT

	SELECT @Cur_TransID = transid FROM @TransID_TEMP WHERe RowID = @Cnt

	INSERT INTO dbo.Transfer 
	(TransId, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake, winlostdate, 
	 creator,recommend,mrecommend,srecommend,currency, actualrate, currencyName, statusID, ip, RepUpdateTime)
	SELECT @NewTransID, custid, username, @refno, @transdate, @DCAN, @transdesc, actual_stake, winlost, @winlostdate,
		 creator, recommend, mrecommend, srecommend, currency, @actualrate, currencyname, 131, @ip, SYSDATETIME()
	FROM dbo.Transfer t WITH(NOLOCK) WHERE transid = @Cur_TransID

	IF @@ERROR <> 0
	BEGIN
	
		SELECT @ErrMsg = 'Insert transaction failed.', @ErrCode = 106

		WAITFOR DELAY '000:00:00.002' -- wait for in-house service

		--Manually rollback
		UPDATE dbo.Transfer WITH(ROWLOCK)
		SET	custid = 0, 
			Recommend = 0, 
			MRecommend = 0, 
			SRecommend = 0, 
			Winlost = 0, 
			Actual_Stake = 0, 
			RepUpdateTime = SYSDATETIME()
		WHERE refno = @RefNo AND bettype = @DCAN AND CustId IN (SELECT custid FROM @TransID_TEMP)
	
		--rollback balance
		DECLARE CUR CURSOR FOR	SELECT	CustID, Balance 
								FROM	@Balance_TEMP 
								WHERE	IsPos = 0
		OPEN CUR
		FETCH NEXT FROM CUR INTO @curCustID, @curBalance 
		WHILE @@FETCH_STATUS = 0
		BEGIN
 
 			EXEC Dot_BalanceCreditUpd @CustID = @curCustID, @balance = @curBalance, @type = 2

			FETCH NEXT FROM CUR INTO @curCustID, @curBalance 
		END
		CLOSE CUR 
		DEALLOCATE CUR
	
		RETURN
	END

	SET @Cnt = @Cnt + 1
	SET @Cur_TransID = NULL

END


	UPDATE dbo.Transfer WITH(ROWLOCK, UPDLOCK)
		SET transdesc = ISNULL(transdesc,'') + ' (withdrawal cancelled)',
			RepUpdateTime = SYSDATETIME()
	WHERE transid in (SELECT transid FROM @TransID_TEMP)
		
	---update credit balance		
	DECLARE CUR CURSOR FOR	SELECT	CustID, Balance 
							FROM	@Balance_TEMP 
							WHERE	IsPos > 0
	OPEN CUR
	FETCH NEXT FROM CUR INTO @curCustID, @curBalance  
	WHILE @@FETCH_STATUS = 0
	BEGIN
		EXEC Dot_BalanceCreditUpd @CustID = @curCustID, @balance = @curBalance, @type = 2
		FETCH NEXT FROM CUR INTO @curCustID, @curBalance 
	END
	CLOSE CUR 
	DEALLOCATE CUR


---------------------------------------------------------------------------------------------------

DECLARE @LogData VARCHAR(1000)

SELECT @LogData = 
			'Cancel withdrawal trans custid = ' + CONVERT(VARCHAR(20), @custid) + ', old transid = ' + CONVERT(VARCHAR(20), @transid) + ', amount = ' + CONVERT(VARCHAR(20), @amount)

BEGIN TRY	
	
		EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Transfer 
								@UserID		= @custid, 
								@FromCustID = @custid, 
								@ToCustID	= 0, 
								@IP			= @IP, 
								@Doing		= @LogData 
END TRY
BEGIN CATCH
	-- IF write log error: not RETURN error code
	SELECT @LogData = @LogData + ' ErrMsg: ' + ERROR_MESSAGE()
		
	EXEC bodb_customerlog.dbo.WriteLog_UserLog_Transfer 
						@UserID		= @custid, 
						@FromCustID = @custid, 
						@ToCustID	= 0, 
						@IP			= @IP, 
						@Doing		= @LogData
END CATCH

GO
