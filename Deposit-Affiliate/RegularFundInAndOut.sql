 declare @fdate smalldatetime, @tdate smalldatetime, @minDeposit money, @minWithdrawal money, @turnover money

SELECT @fdate = '2008-01-01', 
	@tdate = '2009-05-19',
	@minDeposit = 1000,
	@minWithdrawal = 1000,
	@turnover = 500
-----------------------

CREATE TABLE #temp(custid int, ddate smalldatetime, deposit money, wdate smalldatetime, withdrawal money, turnover money)
INSERT INTO #TEMP(custid, ddate, deposit, wdate, withdrawal)
select t1.*, t2.winlostdate, t2.withdrawal
FROM
(
	select b.custid,b.winlostdate,sum(b.deposit) as deposit 
	from bodb_report.dbo.rptdepwinlost b (nolock)            
	where winlostdate between @fdate and @tdate
		and srecommend in (1015419,1015427,791081,836212,836218,836226,836203,791080,916498,179457)
	group by b.custid,b.winlostdate
	having sum(deposit) > @minDeposit
)t1
inner join
(
	select b.custid,b.winlostdate,withdrawal
	from bodb_report.dbo.rptdepwinlost b (nolock)
	where winlostdate between @fdate and @tdate
		and srecommend in (1015419,1015427,791081,836212,836218,836226,836203,791080,916498,179457)
		and withdrawal > @minWithdrawal
)t2 on t1.custid=t2.custid
where datediff(day,t1.winlostdate,t2.winlostdate) between 0 and 3 

UPDATE #TEMP
set turnover = x.turnover
from (
		select t.custid, ddate, wdate, sum(r.turnover) turnover
		from bodb_report.dbo.rptDepWinlost r with(nolock)
			inner join #TEMP t on r.custid=t.custid
		where winlostdate between ddate and wdate
		group by t.custid, ddate, wdate
	   )x
where #TEMP.custid=x.custid and #TEMP.ddate=x.ddate and #TEMP.wdate=x.wdate

select c.username, t.ddate, t.deposit, t.wdate, t.withdrawal, t.turnover 
from #TEMP t
	inner join custinfo c with(nolock) on t.custid=c.custid
where turnover <= @turnover 
order by 3

drop table #TEMP