ALTER PROCEDURE [dbo].[Acc_AllStatement]
	@custid int,
	@fromdate datetime,
	@todate datetime
 AS
 --Statement 1
SET NOCOUNT ON
Declare @roleid int
SELECT @roleid = roleid FROM customer (nolock) WHERE custid = @custid
SET NOCOUNT OFF

set transaction isolation level read uncommitted
IF @roleid = 1
BEGIN
select winlostdate accdate,sum(winlost-actual_stake) totalamt,'BET' transtype, 'Betting' transdesc from bettrans with (nolock) where 
bettype between 1 and 99 and custid=@custid and winlostdate between @fromdate and @todate group by winlostdate
union ALL
select winlostdate accdate,sum(playercomm) totalamt,'COM' transtype, 'Commission' transdesc from bettrans  with (nolock)  where 
bettype between 1 and 99 and custid=@custid and winlostdate between @fromdate and @todate and playercomm<>0 group by winlostdate
/*union
select winlostdate accdate,sum(winlost-actual_stake) totalamt,'BET' transtype, 'Betting' transdesc from bettrans with (nolock) where 
bettype=99 and custid=@custid and winlostdate between @fromdate and @todate group by winlostdate
union
select winlostdate accdate,sum(playercomm) totalamt,'COM' transtype, 'Commission' transdesc from bettrans  with (nolock)  where 
bettype=99 and custid=@custid and winlostdate between @fromdate and @todate and playercomm<>0 group by winlostdate
*/
union ALL
select transdate accdate,sum(winlost-actual_stake) totalamt,typenamee transtype,transdesc  from bettrans  with (nolock)  ,bettype  with (nolock)  where 
bettype >= 100 and custid=@custid and bettype.typeid=bettrans.bettype  and winlostdate between @fromdate and @todate group by
  typenamee,transdesc,transdate,transid

-- customer deleted/void ticket
UNION ALL
select distinct eventdate accdate,0 totalamt,'BET' transtype, 'Cancelled/Deleted Bets' transdesc from zzzbettrans with (nolock), match (nolock)
where zzzbettrans.matchid = match.matchid and
bettype between 1 and 99 and custid=@custid and eventdate between @fromdate and @todate group by eventdate
UNION ALL
select distinct eventdate accdate,0 totalamt,'BET' transtype, 'Cancelled/Deleted Bets' transdesc from zzzbettrans with (nolock), match14 match (nolock)
where zzzbettrans.matchid = match.matchid and
bettype between 1 and 99 and custid=@custid and eventdate between @fromdate and @todate group by eventdate

order by 1
END

IF @roleid = 2 
BEGIN
select transdate accdate,sum(winlost-actual_stake) totalamt ,typenamee transtype,transdesc  from bettrans  with (nolock)  ,bettype  with (nolock)  where 
bettype >= 100 and custid=@custid and bettype.typeid=bettrans.bettype  and winlostdate between @fromdate and @todate group by
  typenamee,transdesc,transdate,transid
-- AGENT
union ALL
select winlostdate accdate,sum(awinlost) totalamt,'POS' transtype, 'Position' transdesc from bettrans with (nolock) where 
bettype between 1 and 99 and recommend=@custid and winlostdate between @fromdate and @todate group by winlostdate having sum(awinlost) <> 0
union ALL
select winlostdate accdate,sum(comm-playercomm) totalamt,'COM' transtype, 'Commission' transdesc from bettrans  with (nolock)  where 
bettype between 1 and 99 and recommend=@custid and winlostdate between @fromdate and @todate group by winlostdate having sum(comm-playercomm) <> 0

order by 1
END

IF @roleid = 3
BEGIN
select transdate accdate,sum(winlost-actual_stake) totalamt ,typenamee transtype,transdesc  from bettrans  with (nolock)  ,bettype  with (nolock)  where 
bettype >= 100 and custid=@custid and bettype.typeid=bettrans.bettype  and winlostdate between @fromdate and @todate group by
  typenamee,transdesc,transdate,transid
-- MASTER
union ALL
select winlostdate accdate,sum(mwinlost) totalamt,'POS' transtype, 'Position' transdesc from bettrans with (nolock) where 
bettype between 1 and 99 and mrecommend=@custid and winlostdate between @fromdate and @todate group by winlostdate having sum(mwinlost) <> 0
union ALL
select winlostdate accdate,sum(acomm-comm) totalamt,'COM' transtype, 'Commission' transdesc from bettrans  with (nolock)  where 
bettype between 1 and 99 and mrecommend=@custid and winlostdate between @fromdate and @todate group by winlostdate having sum(acomm-comm) <> 0

order by 1
END


IF @roleid = 4
BEGIN
select transdate accdate,sum(winlost-actual_stake) totalamt ,typenamee transtype,transdesc  from bettrans  with (nolock)  ,bettype  with (nolock)  where 
bettype >= 100 and custid=@custid and bettype.typeid=bettrans.bettype  and winlostdate between @fromdate and @todate group by
  typenamee,transdesc,transdate,transid
-- SUPER
union ALL
select winlostdate accdate,sum(swinlost) totalamt,'POS' transtype, 'Position' transdesc from bettrans with (nolock) where 
bettype between 1 and 99 and srecommend=@custid and winlostdate between @fromdate and @todate group by winlostdate having sum(swinlost) <> 0
union ALL
select winlostdate accdate,sum(scomm-acomm) totalamt,'COM' transtype, 'Commission' transdesc from bettrans  with (nolock)  where 
bettype between 1 and 99 and srecommend=@custid and winlostdate between @fromdate and @todate group by winlostdate having sum(scomm-acomm) <> 0

order by 1
END




GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

GRANT  EXECUTE  ON [dbo].[Acc_AllStatement]  TO [bodbAdminNet]
GO

