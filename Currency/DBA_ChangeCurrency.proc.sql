ALTER PROCEDURE [dbo].[DBA_ChangeCurrency] 
	@UserName varchar(50),
	@NewCurrency varchar(5),
	@UserID	INT = 360418
AS
--REMEMBER TO CHECK THE RUNNING MIX PARLAY TICKETS
/*
Created: 
Task : Update Super currency: Update all the ticket within that day including bets and transfer trans
DB: DBTRANS.bodb02
Original:

Revisions:
	2008-11-22: Add update status disable Horseracing
	- 20090527@Kiwi: + Add checking for for Finance, Horse, Casino
					+ Use function dbo.f_GetHRAllowedCurr()
    - 20091212@Kiwi: Add to write logs
    - 20100205@Daniel: Enable back the check Casino
    - 20101019@Henry: Record execution time + Check Bingo
    - 20101225@Henry: change bettype to new range
    - 20110817@Henry: include Combination Mixed Parlay (bettype = 29)
    - 20111006@Tom:	Add bet type of P2P: 1000
    - 20120412@Hurri: Change bettype 72 -> 1000 and add more bettype 23102
	
Param's Explanation: 

*/	
SET NOCOUNT ON

declare @startRun datetime
declare @endRun datetime
declare @duration int
set @startRun = getdate()

Declare @CustID int, @RoleID tinyint, @ExchangeID int, @actualrate float,
		@syncCasino bit,@syncBingo bit, @OldCurrency varchar(5)
select	@CustID = CustID, 
		@RoleID = RoleID,
		@syncCasino = SyncCasino,
		@syncBingo = SyncBingo,
		@OldCurrency = e.currency 
from custinfo ci with (nolock)
inner join exchange e with (nolock) on ci.currency = e.exchangeid
where username = @UserName


---Check Casino
-- Need not to check Disable HR and FI 
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

if @RoleID = 4
BEGIN
	Update Customer with (updlock,rowlock) set currency = @ExchangeID where srecommend = @CustID
	
	Update Custinfo with (updlock,rowlock) set currency = @ExchangeID where srecommend = @CustID
	
	if @NewCurrency NOT IN(select currency From dbo.f_GetHRAllowedCurr())
		Update Custinfo with (updlock,rowlock) set DisableHorseracing = 1 where srecommend = @CustID

	Update Bettrans with (updlock,rowlock)
		set CurrencyName = @NewCurrency,
			currency = @ExchangeID,
			actualrate = @actualrate,
			virtualrate = @actualrate	
	where srecommend = @CustID
		--AND status= 'running'
		AND actualrate is NOT NULL
		and winlostdate >= convert(varchar(10),getdate(),112)
		AND bettype NOT IN (71,73,31,32,33,41,42,43,51,52,53,54,55,56,61,62,63,64,65,66,1000, 23001, 23002, 23101, 23102)
	
	Update Bettrans with (updlock,rowlock)
		set CurrencyName = @NewCurrency,
			currency = @ExchangeID,
			actualrate = @actualrate,
			virtualrate = @actualrate	
	where srecommend = @CustID
		--AND status = 'running'
		AND statusID = 0 
		AND actualrate is NOT NULL
		and winlostdate < convert(varchar(10),getdate(),112)
		AND bettype IN (9,29)
		AND matchid IN (9,29)
END

--Write log

declare @LogSPData nvarchar(200)
Select @LogSPData = '<DBA_ChangeCurrency CustId="' + convert(varchar(30),@CustID)
					 + '" CustName="' + convert(varchar(30), @UserName) 
					 + '" Old="' + convert(varchar(10), @OldCurrency)
					 + '" New="' + convert(varchar(10),@NewCurrency) + '"/>'

set @endRun = getdate()
set @duration  = datediff (millisecond,@startRun,@endRun)

EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
	@UserID = @UserID,
	@CustID = @CustID,
	@ActionID = 804,
	@TrackingValue = @LogSPData	,
	@duration = @duration

GO
GRANT EXECUTE ON [dbo].[DBA_ChangeCurrency] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[DBA_ChangeCurrency] TO [vnteam]