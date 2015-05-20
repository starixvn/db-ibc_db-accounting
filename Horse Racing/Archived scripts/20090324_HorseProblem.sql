drop table #tmp
Create table #tmp (transid int, custid int, actual_stake money, winlost money, status varchar(30), bettype tinyint, currency int, livehomescore tinyint, liveawayscore tinyint, scomm money)

insert into #tmp
select transid, custid, actual_stake, winlost, status, bettype , currency, livehomescore, liveawayscore, scomm
from bodb_archive.dbo.bettrans_bk with (nolock) where 
bettype in (31,32,33) and winlostdate = '2009-03-02'


-- Get Dummy User Array

Create table #Sum (currency tinyint, bettype tinyint, stake money, winlost money, scomm money, CommRate smallmoney)
INSERT INTO #Sum (currency, bettype, stake, winlost, scomm)
	SELECT
		b.currency, b.bettype,
		SUM(CASE WHEN bettype = 33 AND liveawayscore = 0 THEN actual_stake/2 ELSE actual_stake END),
		SUM(CASE WHEN bettype = 33 AND liveawayscore = 0 THEN winlost - (actual_stake/2) ELSE winlost END),
		sum(scomm)
		
	FROM
		#tmp b with (nolock)		
	WHERE
		b.[status] NOT IN (N'void', N'reject', N'refund', N'DONE')
	--	b.bettype IN (31,32,33)
	GROUP BY
		b.currency, b.bettype

Drop table #Dummy
	Create table #Dummy ([type] tinyint, [desc] varchar(10), currency tinyint, username nvarchar(50), custid int, recommend int, mrecommend int, srecommend int, actualrate float)
	-- [type] 0:TurnOver 1:WinLost 2:CommSA 3:CommIBC 4:Comm3rd

	INSERT INTO #Dummy -- TurnOver for Horseracing
		SELECT 0, 'TurnOver', c.currency, c.username, c.custid, c.recommend, c.mrecommend, c.srecommend, e.actualrate
		FROM dbo.custinfo c with (nolock)
			INNER JOIN dbo.exchange e with (nolock) ON c.currency = e.exchangeid
		WHERE
			e.exchangeid IN (SELECT distinct currency FROM #Sum) AND 
			c.username LIKE 'TO4HR' + e.currency

	INSERT INTO #Dummy -- Dividend Receivables for Horseracing
		SELECT 1, 'WinLost', c.currency, c.username, c.custid, c.recommend, c.mrecommend, c.srecommend, e.actualrate
		FROM dbo.custinfo c with (nolock)
			INNER JOIN dbo.exchange e with (nolock) ON c.currency = e.exchangeid
		WHERE
			e.exchangeid IN (SELECT distinct currency FROM #Sum) AND 
			c.username LIKE 'DivRec4HR' + e.currency

	INSERT INTO #Dummy -- Commission Expense for Horseracing
		SELECT 2, 'CommSA', c.currency, c.username, c.custid, c.recommend, c.mrecommend, c.srecommend, e.actualrate
		FROM dbo.custinfo c with (nolock)
			INNER JOIN dbo.exchange e with (nolock) ON c.currency = e.exchangeid
		WHERE
			e.exchangeid IN (SELECT distinct currency FROM #Sum) AND 
			c.username LIKE 'CommExp4HR' + e.currency

	INSERT INTO #Dummy -- Commission Income from Horseracing
		SELECT 3, 'CommIBC', c.currency, c.username, c.custid, c.recommend, c.mrecommend, c.srecommend, e.actualrate
		FROM dbo.custinfo c with (nolock)
			INNER JOIN dbo.exchange e with (nolock) ON c.currency = e.exchangeid
		WHERE
			e.exchangeid IN (SELECT distinct currency FROM #Sum) AND 
			c.username LIKE 'CommIncFrHR' + e.currency

	INSERT INTO #Dummy -- Commission Receivables from Phumelela
		SELECT 4, 'Comm3rd', c.currency, c.username, c.custid, c.recommend, c.mrecommend, c.srecommend, e.actualrate
		FROM dbo.custinfo c with (nolock)
			INNER JOIN dbo.exchange e with (nolock) ON c.currency = e.exchangeid
		WHERE
			e.exchangeid IN (SELECT distinct currency FROM #Sum) AND 
			c.username LIKE 'CommRecFrPhu' + e.currency

UPDATE #Sum
	SET CommRate = CASE
		WHEN bettype = 31 THEN  0.10  -- Win   : uses CommRate
		WHEN bettype = 32 THEN  0.10 -- Place : uses CommRate of CommID = 2
		WHEN bettype = 33 THEN (0.10 + 0.10) / 2 -- Each Way = Win & Place : calculate average commission rate
		END

---------------------

declare @currency int
select @currency = 13
select a.*, b.actual_stake, b.winlost,
	a.actual_stake - isnull(b.actual_stake,0) as stake_diff, a.winlost - isnull(b.winlost,0) as win_diff, 
	
	'Exec DBA_BettransInsTransaction ' + cast(a.custid as varchar(20)) +','+ convert(varchar(20),(a.actual_stake - isnull(b.actual_stake,0)),2) + ',' + convert(varchar(20),(a.winlost - isnull(b.winlost,0)))
from (
	SELECT
		c.custid, cm.username, 
		sum(CASE c.[type] WHEN 1 THEN s.WinLost WHEN 2 THEN s.scomm WHEN 4 THEN s.CommRate * s.stake   WHEN 0 THEN 0               WHEN 3 THEN 0 END) actual_stake,
		sum(CASE c.[type] WHEN 0 THEN s.stake                       WHEN 3 THEN s.CommRate * s.stake   WHEN 1 THEN 0 WHEN 2 THEN 0 WHEN 4 THEN 0 END) winlost
	FROM
		#Sum AS s
		INNER JOIN #Dummy AS c ON s.currency = c.currency
		inner join customer cm with (nolock) on cm.custid = c.custid
	where s.currency = @currency
	group by c.custid, cm.username
	) a
	left join 
	(SELECT
		 cm.username, s.custid, sum(actual_stake) as actual_stake, sum(winlost) as winlost
	FROM
		#tmp AS s	
		inner join customer cm with (nolock) on cm.custid = s.custid
	where s.currency =@currency and status = 'done'
	group by s.custid, cm.username) b
	on a.custid = b.custid
-----------

--Update actualrate of 2009-mar-02
select top 1 actualrate
from bodb_archive.dbo.bettrans_bk with (nolock) where 
bettype in (31,32,33) and winlostdate = '2009-03-02' and currency = 13

update bettrans set actualrate= case currency
									when 1 then 2.4									
									when 2 then 1
									when 3 then 3.6

									when 5 then 0.46									

									when 12 then 5.22
									when 13 then 0.53
									else 0
									end where creator = 360418






