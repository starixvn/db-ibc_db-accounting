ALTER PROCEDURE [dbo].[DBA_ChangeCurrencyAndMoveAgent]
	@mastername		varchar(40),
	@agentname		varchar(40),
	@NewCurrency varchar(5),
	@userid			int,
	@IP				varchar(15)='',
	@ErrCode		int = 0 OUTPUT,
	@ErrMsg			nvarchar(200) = '' OUTPUT
AS

/*
Created: 
Task : Update currency and move to new master for Agent
DB: DBTRANS.bodb02
Original:

Revisions:
	- 20100109@Daniel: Added
	- 20100112@Kiwi: Amend to write log in xml format.
	- 20100205@Daniel: No allow to change currency when account is enable Casino
	- 20101019@Henry: Record execution time + Check Bingo
	- 20101225@Henry: change bettype to new range
	- 20110817@Henry: include Combination Mixed Parlay (bettype = 29)
	- 20111006@Tom:	Add bet type of P2P: 1000
	- 20120405@Hurri: Change bettype: 23101 -> 23102
	
Param's Explanation: 

*/	

SET NOCOUNT ON

declare @startRun datetime
declare @endRun datetime
declare @duration int
set @startRun = getdate()


-------For test-----------
--select @agentname = 'HIS0188'--agent name
--select @mastername = 'itmaster'--master name
--select @NewCurrency = 'UUS'

Declare @CustID int, @RoleID tinyint, @ExchangeID int, @actualrate float, @OldCurrency varchar(5),
		@syncCasino bit,@syncBingo bit
select 
	@CustID = CustID, 
	@RoleID = RoleID, 
	@OldCurrency = e.currency,
	@syncCasino = SyncCasino,
	@syncBingo = SyncBingo 	
from custinfo c with (nolock) 
	inner join exchange e with (nolock) on c.currency = e.exchangeid
where username = @agentname

---Check Casino
---Need not to chekc Disable HR and FI 
if @syncCasino = 1
BEGIN
	raisError ('This customer is already enabled Casino. Cannot Change Currency', 16, 1)
		RETURN
END

if @syncBingo = 1
BEGIN
	raisError ('This customer is already enabled Bingo. Cannot Change Currency', 16, 1)
		RETURN
END

select @ExchangeID = ExchangeID, @actualrate = actualrate
from Exchange with (nolock) where currency = @NewCurrency


--change currency on agent

Update Customer with (updlock,rowlock)  set currency = @ExchangeID where recommend = @CustID

Update Custinfo with (updlock,rowlock) set currency = @ExchangeID where recommend = @CustID

Update Bettrans with (updlock,rowlock) 
	set CurrencyName = @NewCurrency,
		currency = @ExchangeID,
		actualrate = @actualrate,
		virtualrate = @actualrate	
where recommend = @CustID
	--AND status= 'running'
	AND actualrate is NOT NULL
	and winlostdate >= convert(varchar(10),getdate(),112)
	AND bettype NOT IN (71,73,31,32,33,41,42,43,51,52,53,54,55,56,61,62,63,64,65,66,1000, 23001, 23002, 23101, 23102)


Update Bettrans with (updlock,rowlock) 
	set CurrencyName = @NewCurrency,
		currency = @ExchangeID,
		actualrate = @actualrate,
		virtualrate = @actualrate	
where recommend = @CustID
	--AND status= 'running'
	AND statusID = 0
	AND actualrate is NOT NULL
	and winlostdate < convert(varchar(10),getdate(),112)
	AND bettype IN (9,29)
	AND matchid IN (9,29)


--Move agent to new master
EXEC [dbo].[Acc_CustomerUpdMoveAgent]
		@mastername = @mastername,
		@agentname = @agentname,
		@userid = @userid,
		@IP = @IP,
		@ErrCode = @ErrCode OUTPUT,
		@ErrMsg = @ErrMsg OUTPUT


--Write log
declare @LogSPData nvarchar(200)

Select @LogSPData = '<DBA_ChangeCurrencyAndMoveAgent CustId="' + convert(varchar(30),@CustID)
					 + '" CustName="' + convert(varchar(30), @agentname) 
					 + '" Old="' + convert(varchar(10), @OldCurrency)
					 + '" New="' + convert(varchar(10),@NewCurrency) + '"/>'

set @endRun = getdate()
set @duration  = datediff (millisecond,@startRun,@endRun)

EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
	@UserID = @userid,
	@CustID = @CustID,
	@ActionID = 805,
	@TrackingValue = @LogSPData,
	@duration = @duration	
GO
GRANT VIEW DEFINITION ON [DBA_ChangeCurrencyAndMoveAgent] TO [vnteam]