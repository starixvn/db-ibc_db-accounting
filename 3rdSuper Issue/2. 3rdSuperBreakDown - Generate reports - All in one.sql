--DB06.bodb02
declare
    @FromDate SMALLDATETIME,
    @ToDate SMALLDATETIME

select @FromDate = '2008-5-1'
select @ToDate = '2012-7-31'

declare @custid int
 
create table #tmpCust
(
	custid int PRIMARY KEY CLUSTERED, 
	roleid int,
	currency int
)

--if @custid is not null
insert into #tmpCust
select custid, roleid, currency from bodb02.dbo.custinfo with (nolock)
where currency <> 20
	AND roleid = 1
	AND srecommend IN
	(
		select custid from bodb02.dbo.custinfo with (nolock) 
		where username like '3rdSuper%' and roleid = 4
	)

create table #tmpBal
(
	winlostdate datetime,
	refno bigint,
	custid int,
	[type] int,
	totalamt money
)

CREATE CLUSTERED INDEX #IX_tmpBal ON #tmpBal
(
	winlostdate asc,
	refno asc,
	custid asc,
	[type] asc
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)


--insert balance diff
insert into #tmpBal
select winlostdate, refno, custid, [type], sum(amt)
FROM
(
	select winlostdate, refno, b.custid, bettype [type], sum(credit-debit) amt
	from bodb_Archive.dbo.transfer_bk_3rdSuper b with (nolock)
		INNER JOIN #tmpcust c ON b.custid=c.custid
	where winlostdate >= @FromDate and winlostdate <= @ToDate
	group by winlostdate, refno, b.custid, bettype
	UNION ALL
	select accdate winlostdate, 0,  b.custid, case transtype when 'BET' then 1 when 'POS' then 2 when 'COM' then 3 else 0 end [type], sum(totalamt) amt
	from bodb_Archive.dbo.Statement_3rdSuper b with (nolock)
		INNER JOIN #tmpcust c ON b.custid=c.custid
	where accdate >= @FromDate and accdate <= @ToDate
		and transtype IN('BET','COM','POS')
	group by accdate, b.custid, transtype
	UNION ALL--insert agency cash balance diff for Casino, Bingo, P2P
	select winlostdate, 0,  b.custid, bettype [type], sum(swinlost+mwinlost+awinlost+scomm-playercomm) amt
	from bodb_Archive.dbo.bettrans_bk_3rdSuper b with (nolock)
		INNER JOIN #tmpcust c ON b.custid=c.custid
	where winlostdate >= @FromDate and winlostdate <= @ToDate
	group by winlostdate, b.custid, bettype
) A
group by winlostdate, custid, refno, [type]

--set status for outside transfers
update #tmpBal set [type] = -[type]
where refno IN(select refno from bodb_Archive.dbo.transfer_bk_3rdSuper_Out with (nolock))

--By all account
select 	
	case 
		--when a.username like 'HR%' or a.username like 'Fixed%' then 'Racing'
		when a.username like 'HR%' then 'Racing' 
		when a.username like 'Fixed%' then 'Racing Fixed'
		when a.username like 'NU%' then 'Number Game'
		when a.username like 'Cas%' then 'Casino'
		when [type] = 71 then 'Casino'
		when a.username like 'LCas%' then 'Live Casino'
		when a.username like 'BI%' then 'Bingo'
		when [type] = 73 then 'Bingo'
		when a.username like 'P2P%' then 'P2P'
		when [type] = 1000 then 'P2P'
		else case when a.username like 'FI%' then 'Finance' else 'N/A' end end Product,
	case 
		when c.username like '%WL%02' then 'Transfers to SIBC'
		when [type] IN(1,2,3,71,73,1000) then 'Auto Dummy Transfers'
		when [type] < 0 then 'Racing Payment'
		when [type] NOT IN(1,2,3,71,73,1000) and [type] > 0 then 'Finance transfers'
		else c.username end [Group],
	case when [type] in(1,2,3,71,73,1000) then 'Winloss' else 'Transfers' end Type ,
	c.username Account,
	e.Currency,
	Year(winlostdate) [Year], Month(winlostdate) [Month],
	sum(totalamt) Total,
	sum(totalamt*e.actualrate) TotalRM
from #tmpBal Bal
	inner join bodb02.dbo.custinfo c with (nolock) on Bal.custid = c.custid
	inner join bodb02.dbo.custinfo a with (nolock) on c.recommend = a.custid 
	inner join bodb02.dbo.exchange e with (nolock) on c.currency = e.exchangeid
group by 
	case 
		--when a.username like 'HR%' or a.username like 'Fixed%' then 'Racing'
		when a.username like 'HR%' then 'Racing' 
		when a.username like 'Fixed%' then 'Racing Fixed'
		when a.username like 'NU%' then 'Number Game'
		when a.username like 'Cas%' then 'Casino'
		when [type] = 71 then 'Casino'
		when a.username like 'LCas%' then 'Live Casino'
		when a.username like 'BI%' then 'Bingo'
		when [type] = 73 then 'Bingo'
		when a.username like 'P2P%' then 'P2P'
		when [type] = 1000 then 'P2P'
		else case when a.username like 'FI%' then 'Finance' else 'N/A' end end,
	case 
		when c.username like '%WL%02' then 'Transfers to SIBC'
		when [type] IN(1,2,3,71,73,1000) then 'Auto Dummy Transfers'
		when [type] < 0 then 'Racing Payment'
		when [type] NOT IN(1,2,3,71,73,1000) and [type] > 0 then 'Finance transfers'
		else c.username end,
	case when [type] in(1,2,3,71,73,1000) then 'Winloss' else 'Transfers' end ,
	c.username,
	e.Currency,
	Year(winlostdate), Month(winlostdate)
order by Currency, [year], [month],  Product, [Group], [type], account

--detail Racing Payment
select distinct b.RefNo, b.winlostdate Date, e.Currency,
	 c1.username [IBC Code From], c2.username [IBC Code To], 
	totalamt Total, totalamt*actualrate TotalRM
from #tmpBal b
	inner join bodb_Archive.dbo.transfer_bk_3rdSuper_Out o with (nolock) on b.refno = o.refno
	inner join bodb02.dbo.custinfo c1 with (nolock) on b.custid = c1.custid
	inner join bodb02.dbo.custinfo c2 with (nolock) on o.custid = c2.custid
	inner join bodb02.dbo.exchange e with (nolock) on c1.currency = e.exchangeid
where c1.username not like '%WL%02'
	and [type] < 0
order by currency, b.winlostdate, refno


--detail Finance transfers
select b.RefNo, b.winlostdate Date, e.Currency 
	c1.username [Code From/To], 
	b.totalamt Total, b.totalamt*actualrate TotalRM
from #tmpBal b
	inner join bodb02.dbo.custinfo c1 with (nolock) on b.custid = c1.custid
	inner join bodb02.dbo.exchange e with (nolock) on c1.currency = e.exchangeid
where b.[type] NOT IN(1,2,3,71,73,1000) and b.[type] > 0
	and c1.username not like '%WL%02'
order by refno, currency, b.winlostdate

--split racing dummy transfers into IBC profit and Amt due to partner
select 	
	--c.username Account,
	e.Currency,
	Year(winlostdate) [Year], Month(winlostdate) [Month],
	
	sum
	(
		case when c.username like 'AmtoteFee%' 
			or c.username like 'TO4HR%'
			or c.username like 'TO4BW%'
			or c.username like 'CommRecFrPhu%' 
			or c.username like 'CommRecFrBW%' 
			or c.username like 'DivRec4HR%'
			or c.username like 'Payout4BW%'
			or c.username like 'PGIFee%'
		then totalamt else 0 end
	) [Amt Due To Partner],

	sum
	(
		case when c.username like 'CommIncFrHR%' 
			or c.username like 'CommIncFrFixed%' 
			or c.username like 'FeeDue2%'
			or c.username like 'CommExp4HR%'
			or c.username like 'CommExp4Fixed%'
			or c.username like 'WLFrPT%'
			or c.username like 'WLFrFixed%'
		then totalamt else 0 end
	) [IBC Profit],

	sum
	(
		case when c.username like 'AmtoteFee%' 
			or c.username like 'TO4HR%'
			or c.username like 'TO4BW%'
			or c.username like 'CommRecFrPhu%' 
			or c.username like 'CommRecFrBW%' 
			or c.username like 'DivRec4HR%'
			or c.username like 'Payout4BW%'
			or c.username like 'PGIFee%'
		then totalamt*actualrate else 0 end
	) [Amt Due To Partner RM],

	sum
	(
		case when c.username like 'CommIncFrHR%' 
			or c.username like 'CommIncFrFixed%' 
			or c.username like 'FeeDue2%'
			or c.username like 'CommExp4HR%'
			or c.username like 'CommExp4Fixed%'
			or c.username like 'WLFrPT%'
			or c.username like 'WLFrFixed%'
		then totalamt*actualrate else 0 end
	) [IBC Profit RM]

from #tmpBal Bal
	inner join bodb02.dbo.custinfo c with (nolock) on Bal.custid = c.custid
	inner join bodb02.dbo.custinfo a with (nolock) on c.recommend = a.custid 
	inner join bodb02.dbo.exchange e with (nolock) on c.currency = e.exchangeid
where (a.username like 'HR%' OR a.username like 'Fixed%')
	and c.username not like '%WL%02'
	and [type] IN(1,2,3,71,73,1000)
group by 
	--c.username,
	e.Currency,
	Year(winlostdate), Month(winlostdate)
order by Currency, [year], [month]

drop table #tmpcust
drop table #tmpBal

