ALTER PROCEDURE [dbo].[DBA_DeleteBet_Parlay]
	@transid bigint,
	@UserID int, -- pass the userid whom performs the action
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@ErrCode int = 0 OUTPUT

AS
/*
	Created:
	Task: delete parlay ticket
	Original:
	
	Revisions:
		- 20111028@Lukas: update member's balance
		- 20120412@Sophia: Revise balance debit/credit
*/
SET NOCOUNT ON

Declare @LogData nvarchar(200), @custid int, @statusID int, @balance MONEY
select @ErrCode = 0

select @custid = custid, @statusID = statusID
from bettrans (nolock)
where transid = @transid

if @statusID = 102
BEGIN
	SELECT @ErrMsg =  'ALREADY VOIDED', @ErrCode = 104	
	return
END

-- get balance
	SELECT @balance = winlost-actual_stake+playercomm
	FROM bettrans WITH(NOLOCK)
	WHERE transid = @transid AND bettype = 9
	
-- STEP 1 : BackUp
	insert into 
		zzzbettrans 
		(transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator , refno, winlostdate, betfrom, betcheck, checktime, matchid, bettype)
	select 
		 transid, custid, CURRENT_TIMESTAMP, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator , refno, winlostdate, betfrom, betcheck, checktime, matchid, bettype
	from 
		bettrans with (nolock)
	where transid = @transid
		  AND bettype = 9

-- STEP 2 : Update

	----update balance debit
	IF @balance > 0
		EXEC Dot_BalanceUpdDebit @custid = @custid, @balance = @balance
 
		update  
			bettrans with (ROWLOCK, UPDLOCK)
		SET winlost=actual_stake,ruben=1,statuswinlost=6, status = 'Void', statusID=102 , creator = @UserID,
			awinlost = 0, mwinlost = 0, swinlost = 0, playercomm = 0, comm  = 0, acomm = 0, scomm = 0
		where transid = @transid

	----update balance credit
	IF @balance < 0
	BEGIN
		SET @balance = ABS(@balance)
		EXEC Dot_BalanceUpdCredit @custid = @custid, @balance = @balance
	END

Select @LogData ='delete parlay ticket for transid ' + convert(varchar(20), @transid)
EXEC WriteLog_UserLog @UserID = @UserID, @Doing = @LogData






GO
GRANT VIEW DEFINITION ON [dbo].[DBA_DeleteBet_Parlay] TO [vnteam]