DECLARE @mindate_sum datetime, @maxdate_sum datetime

SELECT @mindate_sum = min(winlostdate), @maxdate_sum = max(winlostdate)
FROM ABSum_winloss WITH(NOLOCK)

DECLARE @fromdate datetime, @todate datetime

select @fromdate = '2012-01-01', @todate = '2012-01-14'
DECLARE @sql nvarchar(4000)

select @sql ='
INSERT INTO DB052.bodb02.dbo.ABSum_Winloss2 (winlostdate, punterid, leagueid, matchid, bettype, currency, statusid, turnover, comm, winlost, betcount)
SELECT
	b.winlostdate, ab.punterid , m.leagueid, m.matchid, b.bettype, b.currency, b.statusid,
	SUM(stake) turnover,
	SUM(playercomm) comm,
	SUM(winlost - actual_stake) winlost,
	COUNT(1) betcount
FROM DB052.bodb02.dbo.ABTransaction ab WITH(NOLOCK) 
	INNER JOIN bodb_archive.dbo.bettrans_bk b WITH(NOLOCK, INDEX = ix_transid) ON ab.transid = b.transid 
	INNER JOIN bodb_archive.dbo.match_bk m WITH(NOLOCK) ON b.matchid = m.matchid
WHERE b.winlostdate BETWEEN ''' + convert(varchar(10),@fromdate,120) + ''' AND ''' + convert(varchar(10),@todate,120) +'''
GROUP BY b.winlostdate,ab.punterid, m.leagueid, m.matchid, b.bettype, b.currency, b.statusid
'

EXEC sp_executesql @sql

INSERT INTO ABSum_Winloss2 (winlostdate, punterid, leagueid, matchid, bettype, currency, statusid, turnover, comm, winlost, betcount)
SELECT
	b.winlostdate, ab.punterid , m.leagueid, m.matchid, b.bettype, b.currency, b.statusid,
	SUM(stake) turnover,
	SUM(playercomm) comm,
	SUM(winlost - actual_stake) winlost,
	COUNT(1) betcount
FROM ABTransaction ab WITH(NOLOCK) 
	INNER JOIN bettrans14 b WITH(NOLOCK) ON ab.transid = b.transid 
	INNER JOIN match14 m WITH(NOLOCK) ON b.matchid = m.matchid
WHERE b.winlostdate <= @maxdate_sum
GROUP BY b.winlostdate,ab.punterid, m.leagueid, m.matchid, b.bettype, b.currency, b.statusid
 