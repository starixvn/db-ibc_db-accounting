CREATE PROCEDURE [dbo].[Acc_AllStatement_Full]
	@custid int,
	@fromdate datetime,
	@todate datetime,
	@BalanceUpDay smalldatetime
 AS
 
 /*
	Created by: Henry
	Date: 2009 Oct 16
	Task: Get Statement report
	DB: DB06.BODB02 
	
	Revisions:
		- 20091016@Henry: Create New (Copy logic from Acc_AllStatement)
		
 */
SET NOCOUNT ON

Declare @roleid int
SELECT @roleid = roleid FROM customer (nolock) WHERE custid = @custid


DECLARE @StatementTable TABLE(
	accdate datetime,
	totalamt money,
	transtype nvarchar(100),
	transdesc nvarchar(100),
	creator varchar(50)
)

IF @fromdate < @BalanceUpDay
BEGIN
	insert into @StatementTable
	select 
		accdate,
		totalamt,
		transtype,
		transdesc, 
		'' creator 
	from bodb_Report.dbo.Statement with (nolock) 
	WHERE custid = @custid AND accdate between @fromdate and Dateadd(day,-1,@BalanceUpDay) 
	order by accdate, case when transdesc like '%opening balance%' then custid else accdate end, transdesc
END

IF @todate >= @BalanceUpDay
BEGIN
	IF @roleid = 1
	BEGIN
		insert into @StatementTable
		select 
			transdate accdate,
			sum(winlost-actual_stake) totalamt,
			typenamee transtype,
			transdesc, 
			isnull(c.username,'') Creator  
		from bettrans with (nolock) inner join bettype with (nolock) on bettype.typeid=bettrans.bettype 
		left join customer c with (nolock) on bettrans.creator = c.custid 
		where 
			bettype = 100 
			and bettrans.custid=@custid 
			and winlostdate between @fromdate and @todate 
		group by typenamee,transdesc,transdate,transid, c.username
		UNION
		select 
			winlostdate accdate,
			sum(winlost-actual_stake) totalamt,
			'BET' transtype, 
			'Betting' transdesc, 
			'' Creator 
		from bettrans with (nolock) 
		where 
			bettype between 1 and 99 
			and custid=@custid 
			and winlostdate between @fromdate and @todate 
		group by winlostdate
		
		UNION ALL	
		select 
			winlostdate accdate,
			sum(playercomm) totalamt,
			'COM' transtype, 
			'Commission' transdesc ,
			'' Creator 
		from bettrans with (nolock)  
		where 
			bettype between 1 and 99 
			and custid=@custid 
			and winlostdate between @fromdate and @todate 
			and playercomm<>0 
		group by winlostdate

		UNION ALL
		select 
			transdate accdate,
			sum(winlost-actual_stake) totalamt,
			typenamee transtype,
			transdesc, 
			isnull(c.username,'') Creator  
		from bettrans with (nolock) inner join bettype with (nolock) on bettype.typeid=bettrans.bettype 
		left join customer c with (nolock) on bettrans.creator = c.custid 
		where 
			bettype > 100 
			and bettrans.custid=@custid 
			and winlostdate between @fromdate and @todate 
		group by typenamee,transdesc,transdate,transid, c.username

		-- customer deleted/void ticket
		UNION ALL
		select distinct 
			eventdate accdate,
			0 totalamt,
			'BET' transtype, 
			'Cancelled/Deleted Bets' transdesc, 
			'' Creator 
		from zzzbettrans with (nolock), match (nolock)
		where 
			zzzbettrans.matchid = match.matchid 
			and bettype between 1 and 99 
			and custid=@custid 
			and eventdate between @fromdate and @todate 
		group by eventdate
		
		--Remove All
		UNION ALL
		select distinct 
			eventdate accdate,
			0 totalamt,
			'BET' transtype, 
			'Cancelled/Deleted Bets' transdesc, 
			'' Creator 
		from zzzbettrans with (nolock), match14 match (nolock)
		where 
			zzzbettrans.matchid = match.matchid 
			and bettype between 1 and 99 
			and custid=@custid 
			and eventdate between @fromdate and @todate 
		group by eventdate
		order by 1
	END

	-- AGENT
	IF @roleid = 2 
	BEGIN
		insert into @StatementTable
		select 
			transdate accdate,
			sum(winlost-actual_stake) totalamt ,
			typenamee transtype,
			transdesc , 
			isnull(c.username,'') Creator 
		from bettrans with (nolock) 
		inner join bettype with (nolock) on bettype.typeid=bettrans.bettype 
		left join customer c with (nolock) on bettrans.creator = c.custid 
		where 
			bettype = 100 
			and bettrans.custid=@custid 
			and winlostdate between @fromdate and @todate 
			group by typenamee,transdesc,transdate,transid, c.username
		
		UNION
		
		select 
			transdate accdate,
			sum(winlost-actual_stake) totalamt ,
			typenamee transtype,
			transdesc , 
			isnull(c.username,'') Creator 
		from bettrans with (nolock) 
		inner join bettype with (nolock) on bettype.typeid=bettrans.bettype 
		left join customer c with (nolock) on bettrans.creator = c.custid 
		where 
			bettype > 100 
			and bettrans.custid=@custid 
			and winlostdate between @fromdate and @todate 
			group by typenamee,transdesc,transdate,transid, c.username
			
		UNION ALL
		select 
			winlostdate accdate,
			sum(awinlost) totalamt,
			'POS' transtype, 
			'Position' transdesc, 
			'' Creator 
		from bettrans with (nolock) 
		where 
			bettype between 1 and 99 
			and recommend=@custid 
			and winlostdate between @fromdate and @todate 
			group by winlostdate 
		having sum(awinlost) <> 0
		
		UNION ALL
		select 
			winlostdate accdate,
			sum(comm-playercomm) totalamt,
			'COM' transtype, 
			'Commission' transdesc, 
			'' Creator 
		from bettrans  with (nolock)  
		where 
			bettype between 1 and 99 
			and recommend=@custid 
			and winlostdate between @fromdate and @todate 
		group by winlostdate 
		having sum(comm-playercomm) <> 0
		order by 1
	END

	-- MASTER
	IF @roleid = 3
	BEGIN
		insert into @StatementTable
		select 
			transdate accdate,
			sum(winlost-actual_stake) totalamt ,
			typenamee transtype,
			transdesc, 
			isnull(c.username,'') Creator  
		from bettrans with (nolock) 
		inner join bettype  with (nolock) on bettype.typeid=bettrans.bettype 
		left join customer c with (nolock) on bettrans.creator = c.custid 
		where 
			bettype = 100 
			and bettrans.custid=@custid 
			and winlostdate between @fromdate and @todate 
			group by typenamee,transdesc,transdate,transid, c.username
		UNION
		select 
			transdate accdate,
			sum(winlost-actual_stake) totalamt ,
			typenamee transtype,
			transdesc, 
			isnull(c.username,'') Creator  
		from bettrans with (nolock) 
		inner join bettype  with (nolock) on bettype.typeid=bettrans.bettype 
		left join customer c with (nolock) on bettrans.creator = c.custid 
		where 
			bettype > 100 
			and bettrans.custid=@custid 
			and winlostdate between @fromdate and @todate 
			group by typenamee,transdesc,transdate,transid, c.username
	
		UNION ALL
		select 
			winlostdate accdate,
			sum(mwinlost) totalamt,
			'POS' transtype, 
			'Position' transdesc, 
			'' Creator 
		from bettrans with (nolock) 
		where 
			bettype between 1 and 99 
			and mrecommend=@custid 
			and winlostdate between @fromdate and @todate 
			group by winlostdate 
		having sum(mwinlost) <> 0
	
		UNION ALL
		select 
			winlostdate accdate,
			sum(acomm-comm) totalamt,
			'COM' transtype, 
			'Commission' transdesc, '' Creator  
		from bettrans  with (nolock)  
		where 
			bettype between 1 and 99 
			and mrecommend=@custid 
			and winlostdate between @fromdate and @todate 
			group by winlostdate 
		having sum(acomm-comm) <> 0
		order by 1
	END

	-- SUPER
	IF @roleid = 4
	BEGIN
		insert into @StatementTable
		select 
			transdate accdate,
			sum(winlost-actual_stake) totalamt ,
			typenamee transtype, 
			transdesc, 
			isnull(c.username,'') as Creator 
		from bettrans with (nolock) 
		inner join  bettype  with (nolock) on bettype.typeid=bettrans.bettype  
		left join customer c with (nolock) on bettrans.creator = c.custid  
		where 
		bettype = 100 
		and  bettrans.custid=@custid 
		and bettype.typeid=bettrans.bettype  
		and winlostdate between @fromdate and @todate 
		group by typenamee,transdesc,transdate,transid, c.username
		UNION
		select 
			transdate accdate,
			sum(winlost-actual_stake) totalamt ,
			typenamee transtype, 
			transdesc, 
			isnull(c.username,'') as Creator 
		from bettrans with (nolock) 
		inner join  bettype  with (nolock) on bettype.typeid=bettrans.bettype  
		left join customer c with (nolock) on bettrans.creator = c.custid  
		where 
		bettype > 100 
		and  bettrans.custid=@custid 
		and bettype.typeid=bettrans.bettype  
		and winlostdate between @fromdate and @todate 
		group by typenamee,transdesc,transdate,transid, c.username
	
		UNION ALL
		select 
			winlostdate accdate,
			sum(swinlost) totalamt,
			'POS' transtype, 
			'Position' transdesc, 
			'' as Creator 
		from bettrans with (nolock) 
		where 
			bettype between 1 and 99 
			and srecommend=@custid 
			and winlostdate between @fromdate and @todate 
			group by winlostdate having sum(swinlost) <> 0
	
		UNION ALL
		select 
			winlostdate accdate,
			sum(scomm-acomm) totalamt,
			'COM' transtype, 
			'Commission' transdesc, 
			'' as Creator 
		from bettrans  with (nolock)  
		where 
			bettype between 1 and 99 
			and srecommend=@custid 
			and winlostdate between @fromdate and @todate 
			group by winlostdate 
		having sum(scomm-acomm) <> 0
		order by 1
	END

END


SELECT * FROM @StatementTable


GO
GRANT EXECUTE ON [dbo].[Acc_AllStatement_Full] TO [bodbAdminNet]
GO
