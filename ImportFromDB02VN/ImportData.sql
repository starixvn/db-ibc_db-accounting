--Import Main DB
---------------------------------
Exec DBA_Import_Odds_Info @isMain = 1
GO
Exec DBA_Import_Odds_Small @isMain = 1
GO
------------------------
Declare @StrCurrency varchar(200)
select @StrCurrency = '2, 3, 12, 20, 13, 37, 33'

--Bettrans
Exec DBA_Import_Bet	@StrCurrency = @StrCurrency, @isMain = 1

--Bettrans14
Exec DBA_Import_Bet14 @StrCurrency = @StrCurrency, @isMain = 1
GO


--Import Main DB
---------------------------------
Exec DBA_Import_Odds_Info @isMain = 0
GO
Exec DBA_Import_Odds_Small @isMain = 0
GO
------------------------

Declare @StrCurrency varchar(200)
select @StrCurrency = '2, 3, 12, 20, 13, 37, 33'
--Bettrans
Exec DBA_Import_Bet	@StrCurrency = @StrCurrency, @isMain = 0

--Bettrans14
Exec DBA_Import_Bet14 @StrCurrency = @StrCurrency, @isMain = 0
----------------



	TRUNCATE TABLE EventStats
	TRUNCATE TABLE exchange
	TRUNCATE TABLE league
	TRUNCATE TABLE LeaguePattern
	TRUNCATE TABLE match
	TRUNCATE TABLE match_remark
	TRUNCATE TABLE match_streaming
	TRUNCATE TABLE match14
	TRUNCATE TABLE odds
	TRUNCATE TABLE odds14
	TRUNCATE TABLE outright
	TRUNCATE TABLE outright14

	TRUNCATE TABLE team
	TRUNCATE TABLE TeamPattern
	
	TRUNCATE TABLE BETTRANs
	TRUNCATE TABLE BETTRANsm



/* Process Import:
	+ Bets:
		- bettrans, bettransm, zzzbettrans
	+ Bets14:
		- bettrans14, bettransm14, sum_winloss
	
	+ Odds Info: 
		bettype,Dot_Admin_LeagueDisplayMode,Dot_Match_Favor,exchange,
		league,LeaguePattern,match_streaming,Site,Sports,team,TeamPattern
	+ Odds small:
		EventStats,match,match_remark,odds,outright
	+ Odds14:
		match14,odds14,outright14
		
	
Currency: 
	- 2, 3, 12, 20
	- 37, 33

12BETSuperUS$ 791080 3
12BETSuperRM	836218	 2
AB88SuperRMB	932253	13
HI	641918	33
SCM	398615	2
HIS	400973	2
ITSA	179457	20
S6US	706886	3
SSP	689422	37
WWR 1131889 13
SA-GBP 12 12

(791080,836218,932253,641918,398615,400973,179457,706886,689422,1131889,12)
select ci.username,ci.custid,total,hr,cs,ci.currency from
(
select srecommend,
	count(*) total,
	sum(case when bettype in (71,72) then 1 else 0 end) as cs,
	sum(case when bettype in (31,32,33,41,42,43) then 1 else 0 end) as HR
from bettrans (nolock) where currency in 
(12)
--(2,3,12,20,13,37,33)
group by srecommend
) b
inner join custinfo ci (nolock) on b.srecommend = ci.custid
order by total desc, cs desc,hr desc


*/
