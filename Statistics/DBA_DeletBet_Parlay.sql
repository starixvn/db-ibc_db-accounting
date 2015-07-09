 CREATE PROCEDURE [dbo].[DBA_DeleteBet_Parlay]
	@transid bigint,
	@UserID int,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@ErrCode int = 0 OUTPUT

AS

SET NOCOUNT ON

Declare @LogData nvarchar(200), @custid int
select @ErrCode = 0

select @custid = custid 
from bettrans (nolock)
where transid = @transid

-- STEP 1 : BackUp
	insert into 
		zzzbettrans 
		(transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator , refno, comstatus, winlostdate, betfrom, betcheck, checktime, matchid, bettype)
	select 
		 transid, custid, CURRENT_TIMESTAMP, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator , refno, comstatus, winlostdate, betfrom, betcheck, checktime, matchid, bettype
	from 
		bettrans with (nolock)
	where transid = @transid
		  AND bettype = 9

-- STEP 2 : Update
--	begin tran
		update  
			bettrans with (ROWLOCK, UPDLOCK)
		SET winlost=actual_stake,ruben=1,statuswinlost=6, status = 'Void', creator = @UserID,
			awinlost = 0, mwinlost = 0, swinlost = 0, playercomm = 0, comm  = 0, acomm = 0, scomm = 0
		where transid = @transid

--	commit tran

update custbetcredit with (ROWLOCK, UPDLOCK) 
set resync = 1
where custid = @custid

Select @LogData ='delete parlay bet for transid ' + convert(varchar(20), @transid)
EXEC WriteLog_UserLog @UserID = @UserID, @Doing = @LogData
