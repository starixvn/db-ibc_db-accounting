ALTER PROCEDURE [dbo].[Dot_Dep_BettransInsCancelWithdrawal_viet]		
	@custid		int,
	@transid	bigint,	
	@transdesc	nvarchar(300) = '',
	@ip			nvarchar(15)='',
	@NewTransID bigint = 0 OUTPUT,	
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
/*
DB: DBTRANS.bodb02
Creator : Thien
Date : 2007-12-05
Task : withdrawal for Cancel  (in case, withdraw request been rejected , Action: record "deposit" to make balance equal)
History:
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
Input 
    1) CustID (For Double check) 
    2) TransID (This ID is get from "B. deposit/withdrawal for approved" Output TransID )
   Output
    1) Result (@ErrCode)
    2) NewTransID (Cancel)
    
• @ErrCode:
	= 0: Transaction recorded successfully.
	> 0: Specific Error.
• @ErrMsg: Error description.
*/
SET NOCOUNT ON


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
		@currencyName = currencyName 
from bettrans with (nolock)
where transid = @transid

if @trans_custid <> @custid
BEGIN
	Select @ErrMsg = 'Invalid CustID.', @ErrCode = 101
	return
END

declare @CustIDs as table (custid int, isReal bit)

INSERT INTO @CustIDs (custid, isreal) values (@custid, 1)

INSERT INTO @CustIDs (custid, isreal)
SELECT c.custid, 0
from dbo.custinfo c with(nolock)
	inner join dbo.custinfo a with(nolock) on a.custid = c.recommend
where c.roleid = 1
	and a.username = '12BETACC' + @currencyName + '01'
	
DECLARE @TransID_TEMP as table(transid bigint, custid int, balance money )

INSERT INTO @TransID_TEMP
SELECT TransID , custid, (winlost - actual_stake) as balance 
FROM Bettrans with(nolock) 
WHERE matchID = 0
	and bettype = 22002
	and custid in (select custid from @CustIDs)
	and refno = @refno
 
IF @@ROWCOUNT = 0
BEGIN
	Select @ErrMsg = 'bettrans data not found.', @ErrCode = 105
	return
END

DECLARE @Balance_TEMP as table(custid int, balance money, isPos bit)
INSERT INTO @Balance_TEMP
SELECT custid, ABS(SUM(balance)) as balance, CASE WHEN sum(balance) > 0 THEN 0 ELSE 1 END  
FROM @TransID_TEMP 
GROUP BY custid
 
select @actualrate = actualrate
from exchange with (NOLOCK)
where exchangeid = @currency

--20080926: Get winlostdate as today date
select @winlostdate = convert(nvarchar(10), current_timestamp, 120)

if @bettype <> @DWIT
BEGIN
	Select @ErrMsg = 'This transaction is not a withdrawal.', @ErrCode = 102		
	return
END

if exists (select 1 from bettrans with (nolock) where refno = @RefNo and bettype = @DCAN and matchid=0 and custid = @custid)
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
		
		EXEC Dot_BalanceUpdDebit @CustID = @curCustID, @Balance = @curBalance 

		FETCH NEXT FROM CUR INTO @curCustID, @curBalance 
	END
	CLOSE CUR 
	DEALLOCATE CUR


select @transdate = current_timestamp
	
INSERT INTO bettrans 
	(custid, username, refno, transdate, matchid, bettype, transdesc, winlost, actual_stake, winlostdate, 
	 creator,recommend,mrecommend,srecommend,currency, actualrate, currencyName, ruben, status, statusID, ip)
select custid, username, @refno, @transdate, 0, @DCAN, @transdesc, actual_stake, winlost, @winlostdate,
	 creator, recommend, mrecommend, srecommend, currency, @actualrate, currencyname, 1, 'Completed', 131, @ip
from bettrans (nolock) where transid in (select transid from @TransID_TEMP)

if @@ERROR <> 0
BEGIN
	--Manually rollback
	--DELETE FROM bettrans where refno = @RefNo and matchid = 0 and bettype = 108
	Select @ErrMsg = 'Insert transaction failed.', @ErrCode = 106
	--rollback balance
			
		DECLARE CUR CURSOR FOR	SELECT	CustID, Balance 
								FROM	@Balance_TEMP 
								WHERE	IsPos = 0
		OPEN CUR
		FETCH NEXT FROM CUR INTO @curCustID, @curBalance 
		WHILE @@FETCH_STATUS = 0
		BEGIN
			
			EXEC Dot_BalanceUpdCredit @CustID = @curCustID, @Balance = @curBalance 

			FETCH NEXT FROM CUR INTO @curCustID, @curBalance 
		END
		CLOSE CUR 
		DEALLOCATE CUR
	
	return
END
Select @NewTransID = @@IDENTITY

Update Bettrans WITH (ROWLOCK, UPDLOCK)
SET transdesc = transdesc + ' (withdrawal cancelled)'
WHERE transid in (select transid from @TransID_TEMP)


	
---update credit balance		
	DECLARE CUR CURSOR FOR	SELECT	CustID, Balance 
							FROM	@Balance_TEMP 
							WHERE	IsPos > 0
	OPEN CUR
	FETCH NEXT FROM CUR INTO @curCustID, @curBalance  
	WHILE @@FETCH_STATUS = 0
	BEGIN
		EXEC Dot_BalanceUpdCredit @CustID = @curCustID, @Balance = @curBalance 
		
		FETCH NEXT FROM CUR INTO @curCustID, @curBalance 
	END
	CLOSE CUR 
	DEALLOCATE CUR


---------------------------------------------------------------------------------------------------

declare @LogData varchar(300)

Select @LogData = 
			'Cancel withdrawal trans custid = ' + convert(varchar(20), @custid) + ', old transid = ' + convert(varchar(20), @transid) + ', amount = ' + convert(varchar(20), @amount)

EXEC dbo.WriteLog_UserLog @UserID = @custid, @Doing = @LogData
