ALTER PROCEDURE [dbo].[Acc_CheckDuplicateTickets]	
	@date datetime,
	@lasttransID bigint = 0
with recompile
AS
-- DB06.bodb02
SET NOCOUNT ON

IF @@servername = 'DWDBG1S'
begin
	select * from vtest
end
else
begin
	declare @_date datetime
	select @_date = @date

	;WITH B as (
		select custid, odds, stake, balance, status,bettype,winlostdate, username,
				min(transid) refno1, max(transid) refno2, 
				min(transdate) bettime1,max(transdate) bettime2, 
				datediff(ms,min(transdate),max(transdate)) timediff
		from bettrans with(nolock)
		where matchid > 0
			and bettype < 19000
			and custid not in (50057,879241,103873) --betdaq
			and DATEADD(dd, DATEDIFF(dd, 0, transdate), 0) = @_date
			and winlostdate >= @_date
			and custid > 0
			and transid > @lasttransID
		group by custid, odds, stake, balance, status, bettype,winlostdate, username
		having count(*) > 1 and datediff(ss,min(transdate),max(transdate))<1
	)
	SELECT username, custid, typenamee,winlostdate, balance, stake, odds, status,
		refno1, refno2, bettime1, bettime2, timediff
	FROM B b
		INNER JOIN bettype bt with(nolock) on b.bettype = bt.typeid	
	ORDER BY refno1 desc
end



GO
GRANT EXECUTE ON [dbo].[Acc_CheckDuplicateTickets] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CheckDuplicateTickets] TO [vnteam]