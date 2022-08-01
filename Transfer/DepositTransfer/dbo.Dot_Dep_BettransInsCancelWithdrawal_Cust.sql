/*<info serverAlias="DBTXN-bodb02" executers="Dot_Member,Dot_Bonus" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE  [dbo].[Dot_Dep_BettransInsCancelWithdrawal_Cust]		
	@custid		int,
	@transid	bigint,	
	@transdesc	nvarchar(300) = '',
	@ip			varchar(45)='',
	@NewTransID bigint = 0 OUTPUT,	
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
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

declare @trans_custid int,
	@username varchar(50),
	@currency tinyint,
	@currencyName varchar(5),
	@transdate datetime,
	@bettype int,
	@newBettype int,
	@amount money,
	
	@actualrate float,
	@winlost money,
	@actual_stake money,
	@mrecommend int,
	@recommend int,
	@srecommend int,
	@roleid tinyint,
	@balance money,
	@site varchar(20),
	
	--Balance Account info
	@bal_custid int,
	@bal_mrecommend int,
	@bal_recommend int,
	@bal_srecommend int,
	@bal_Username varchar(50),
	@winlostdate smalldatetime,
	
	@RefNo bigint,
	@DDEP int,
	@DWIT int,
	@DCAN int

Select @ErrCode = 0,
	@ErrMsg = '',
	@DDEP = 22001,
	@DWIT = 22002,
	@DCAN = 22003

select @amount = actual_stake,
		@bettype = bettype,
		@RefNo = refno,
		@trans_custid = custid,		
		@currency = currency,
		@currencyName = currencyName,
		@srecommend = srecommend
from dbo.Transfer t with(nolock)
where transid = @transid

if @trans_custid <> @custid
BEGIN
	Select @ErrMsg = 'Invalid CustID.', @ErrCode = 101
	return
END

SELECT @site = site, @username = username from CustDB.dbo.DEP_custsuper d with(nolock) where custid=@srecommend

IF @@rowcount = 0
	SELECT @site = site, @username = username from DBCUST.CustDB.dbo.DEP_custsuper d with(nolock) where custid=@srecommend

declare @CustIDs as table (custid int, isReal bit)

INSERT INTO @CustIDs (custid, isreal) values (@custid, 1)

INSERT INTO @CustIDs (custid, isreal)
SELECT c.custid, 0
from CustDB.dbo.custinfo c with(nolock)
	inner join CustDB.dbo.custinfo a with(nolock) on a.custid = c.recommend
where c.roleid = 1
	and ( a.username = LTRIM(RTRIM(@site))+'ACC' + @currencyName + '01'
			or a.username = left(@username, charindex('Super', @username)-1) +'ACC' + @currencyName + '01')
IF @@rowcount = 0
BEGIN
	INSERT INTO @CustIDs (custid, isreal)
	SELECT c.custid, 0
	from DBCUST.CustDB.dbo.custinfo c with(nolock)
		inner join DBCUST.CustDB.dbo.custinfo a with(nolock) on a.custid = c.recommend
	where c.roleid = 1
		and ( a.username = LTRIM(RTRIM(@site))+'ACC' + @currencyName + '01'
				or a.username = left(@username, charindex('Super', @username)-1) +'ACC' + @currencyName + '01')
END
	
DECLARE @TransID_TEMP as table(RowID int IDENTITY(1,1), transid bigint, custid int, balance money )

INSERT INTO @TransID_TEMP
SELECT TransID , custid, (winlost - actual_stake) as balance 
FROM dbo.transfer t with(nolock) 
WHERE bettype = 22002
	and custid in (select custid from @CustIDs)
	and refno = @refno
 
IF @@ROWCOUNT = 0
BEGIN
	Select @ErrMsg = 'transfer data not found.', @ErrCode = 105
	return
END

DECLARE @Balance_TEMP as table(custid int, balance money, isPos bit)
INSERT INTO @Balance_TEMP
SELECT custid, ABS(SUM(balance)) as balance, CASE WHEN sum(balance) > 0 THEN 0 ELSE 1 END  
FROM @TransID_TEMP 
GROUP BY custid
 
select @actualrate = actualrate
from CustDB.dbo.exchange e with(NOLOCK)
where exchangeid = @currency

IF @@rowcount = 0	
	select @actualrate = actualrate
	from DBCUST.CustDB.dbo.exchange e with(NOLOCK)
	where exchangeid = @currency

--20080926: Get winlostdate as today date
select @winlostdate = convert(nvarchar(10), current_timestamp, 120)

if @bettype <> @DWIT
BEGIN
	Select @ErrMsg = 'This transaction is not a withdrawal.', @ErrCode = 102		
	return
END

if exists (select 1 from dbo.Transfer t with(nolock) where refno = @RefNo and bettype = @DCAN and custid = @custid)
BEGIN
	Select @ErrMsg = 'This transaction has been cancelled before.', @ErrCode = 103		
	return
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
		
	--EXEC Dot_BalanceUpdDebit @CustID = @curCustID, @Balance = @curBalance 
	EXEC Dot_BalanceDebitUpd @CustID = @curCustID, @balance = @curBalance, @type = 2 , @IsForced = 1  -- 20151230 cooper add @IsForced = 1

	FETCH NEXT FROM CUR INTO @curCustID, @curBalance 
END
CLOSE CUR 
DEALLOCATE CUR


select @transdate = current_timestamp

DECLARE @Cur_TransID bigint;
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
	select @NewTransID, custid, username, @refno, @transdate, @DCAN, @transdesc, actual_stake, winlost, @winlostdate,
		 creator, recommend, mrecommend, srecommend, currency, @actualrate, currencyname, 131, @ip, SYSDATETIME()
	from dbo.Transfer t WITH(nolock) where transid = @Cur_TransID

	SET @Cnt = @Cnt + 1
	SET @Cur_TransID = NULL

END

if @@ERROR <> 0
BEGIN

	--Manually rollback
	UPDATE dbo.Transfer WITH(ROWLOCK)
	SET	custid = 0, 
		Recommend = 0, 
		MRecommend = 0, 
		SRecommend = 0, 
		Winlost = 0, 
		Actual_Stake = 0, 
		RepUpdateTime = SYSDATETIME()
	WHERE refno = @RefNo and bettype = @DCAN AND CustId IN (select custid from @TransID_TEMP)
	
	Select @ErrMsg = 'Insert transaction failed.', @ErrCode = 106
	--rollback balance
			
		DECLARE CUR CURSOR FOR	SELECT	CustID, Balance 
								FROM	@Balance_TEMP 
								WHERE	IsPos = 0
		OPEN CUR
		FETCH NEXT FROM CUR INTO @curCustID, @curBalance 
		WHILE @@FETCH_STATUS = 0
		BEGIN
			
			--EXEC Dot_BalanceUpdCredit @CustID = @curCustID, @Balance = @curBalance 
			EXEC Dot_BalanceCreditUpd @CustID = @curCustID, @balance = @curBalance, @type = 2

			FETCH NEXT FROM CUR INTO @curCustID, @curBalance 
		END
		CLOSE CUR 
		DEALLOCATE CUR
	
	return
END

Update dbo.Transfer WITH(ROWLOCK, UPDLOCK)
	SET transdesc = transdesc + ' (withdrawal cancelled)',
		RepUpdateTime = SYSDATETIME()
WHERE transid in (select transid from @TransID_TEMP)
	
---update credit balance		
	DECLARE CUR CURSOR FOR	SELECT	CustID, Balance 
							FROM	@Balance_TEMP 
							WHERE	IsPos > 0
	OPEN CUR
	FETCH NEXT FROM CUR INTO @curCustID, @curBalance  
	WHILE @@FETCH_STATUS = 0
	BEGIN
		--EXEC Dot_BalanceUpdCredit @CustID = @curCustID, @Balance = @curBalance 
		EXEC Dot_BalanceCreditUpd @CustID = @curCustID, @balance = @curBalance, @type = 2
		FETCH NEXT FROM CUR INTO @curCustID, @curBalance 
	END
	CLOSE CUR 
	DEALLOCATE CUR


---------------------------------------------------------------------------------------------------

declare @LogData varchar(300)

Select @LogData = 
			'Cancel withdrawal trans custid = ' + convert(varchar(20), @custid) + ', old transid = ' + convert(varchar(20), @transid) + ', amount = ' + convert(varchar(20), @amount)

EXEC dbo.WriteLog_UserLog @UserID = @custid, @Doing = @LogData


GO
