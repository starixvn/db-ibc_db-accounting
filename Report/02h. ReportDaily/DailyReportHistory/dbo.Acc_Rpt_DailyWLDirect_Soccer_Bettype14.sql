ALTER PROCEDURE [dbo].[Acc_Rpt_DailyWLDirect_Soccer_Bettype14]
	@winlostdate	datetime
AS
SET NOCOUNT ON

/*	Creator: Phuong Dao
	Date: 2009-02-26
	Task: WinLost Summary report - History
	DB: DBACC/bodb02
	
	Revisions:
		- 20090714@Kiwi: Exclude 'Refund' ticket
		- 20090731@Jamie: Not to view data in range of date, but only one date at once
		- 20091109@Kiwi: Declare @temp table to contain all matches based on @winlostdate
		- 20100525@Henry: Change to use StatusID instead of Status in WHERE statement
		- 20110824@Johnson: remove check winlostdate with '16 Dec 2010' for sumary turnover, get from stake instead actual_stake
		- 20110824@Elly: - Correct Turnover of sports book since Sep 01, 2011
		- 20110826@Lukas: Modify to get bettype automatically
		- 20111202@Sophia: . Add new range for sportbook from 121 to 999
							. Remove @NegativeBetEffectiveDate
		- 20120412@Hurri: Get win lost of agent 'BARM'
		- 20120530@Elodie: Change formula of 8RM/BARM winloss
		- 20120628@Elodie: check case of matchid = orid
		- 20121018@Lukas: performance tuning 
		- 20130408@Elodie: Add RealLineTotal field for all products that enable virtual currency
		- 20130522@Elodie: Get more fields RealTurnover, VirtualTurnover
		- 20130801@Johnson: Separate win loss by credit/deposit site(1: credit, 2: deposit)		
	Param's Explanation: 
*/		

	Declare @tmpBettype table (Bettype int, DisplayOrder int)

	Insert into @tmpBettype
	select 1,  1 --'Handicap',
	UNION ALL
	Select 3,  2 --'Over/Under',
	UNION ALL
	select 7,  3 --'1st Half Handicap',
	UNION ALL
	Select 8,  4 --'1st Half Over/Under',
	UNION ALL
	select 2,  5 --'Odd/Even',
	UNION ALL
	select 5,  6 --'1x2',
	UNION ALL
	Select 4,  7 --'Correct Score',
	UNION ALL
	Select 6,  8 --'Total Goal',
	UNION ALL 
	Select 10,  10 --'Outright',

	INSERT INTO @tmpBettype
		SELECT typeid, typeid
		FROM bettype WITH(NOLOCK)
		WHERE (typeid > 10 AND typeid < 31) OR typeid BETWEEN 121 AND 999
	
	--Declare @temp table to contain all matches based on @winlostdate
	DECLARE @Match TABLE (matchid INT, matchcode NVARCHAR(50), type varchar(10), primary key(matchid, type))
	INSERT INTO @Match 
	SELECT	m.matchid, 
			m.matchcode,
			m.type
	FROM (
			SELECT matchid, leagueid, exrisk, matchcode, 'match' as type FROM MATCH14 WITH (NOLOCK) WHERE eventdate = @winlostdate
			UNION ALL
			SELECT orid, leagueid, 0, matchcode, 'outright' as type FROM outright14 WITH (NOLOCK) WHERE eventdate = @winlostdate
			)m	
	INNER JOIN league l WITH (NOLOCK) ON m.leagueid = l.leagueid	
	INNER JOIN Sports s WITH (NOLOCK) ON l.sporttype = s.sporttype 
	WHERE s.sporttype = 1

	CREATE TABLE #TempBettrans (liveindicator BIT, Bettype TINYINT, matchid INT, site TINYINT, WinLost MONEY, Position MONEY, Commission MONEY, LineTotal_actualrate MONEY, LineTotal_virtualrate MONEY, Turnover_actualrate MONEY, Turnover_virtualrate MONEY)
	INSERT INTO #TempBettrans	
	SELECT		
			liveindicator,
			Bettype,			
			matchid,
			case when dep.custid is null then 1 else 2 end as site,
			sum((winlost-actual_stake)*virtualrate) WinLost,
			sum((awinlost+mwinlost+swinlost)*virtualrate) Position,
			sum(scomm*virtualrate) Commission,	
			sum((winlost-actual_stake+awinlost+mwinlost+swinlost+scomm)*actualrate) LineTotal_actualrate,
			sum((winlost-actual_stake+awinlost+mwinlost+swinlost+scomm)*virtualrate) LineTotal_virtualrate,
			sum((1-tpositiontaking)*ABS(stake)*actualrate) Turnover_actualrate,
			sum((1-tpositiontaking)*ABS(stake)*virtualrate) Turnover_virtualrate
	FROM	bettrans14 b WITH (NOLOCK)	
		LEFT JOIN (select custid from f_DepSuper_1('All')) dep ON b.srecommend = dep.custid 		
	WHERE
			winlostdate = @winlostdate
			AND (bettype < 31 OR b.bettype BETWEEN 121 AND 999)	
			AND matchid >0		
			AND statusID NOT IN (101, 102,103) 
			AND ruben = 1			
	GROUP BY		
			liveindicator,
			Bettype,
			matchid,
			case when dep.custid is null then 1 else 2 end 	
			
	SELECT		
			b.liveindicator,
			bt.Bettype,
			case when m.matchcode like '%hedge%' then ' (hedge)' else '' end isHedge,
			site,
			sum(WinLost) winlost,
			sum(Position) position,
			sum(Commission) commission,	
			sum(LineTotal_actualrate) RealLineTotal,
			sum(LineTotal_virtualrate) VirtualLineTotal,
			sum(Turnover_actualrate) RealTurnover,
			sum(Turnover_virtualrate) VirtualTurnover
	FROM	#TempBettrans b
			INNER JOIN @Match m on b.matchid = m.matchid 	
			INNER JOIN @tmpBettype bt ON b.bettype = bt.Bettype
	WHERE   m.type = CASE WHEN b.bettype = 10 THEN 'outright' ELSE 'match' END
	GROUP BY		
			b.liveindicator,
			bt.Bettype, 
			case when m.matchcode like '%hedge%' then ' (hedge)' else '' end ,	
			bt.DisplayOrder,
			site
	ORDER BY
			b.liveindicator, bt.DisplayOrder, site		
			
	select	b.liveindicator, 
			-sum((winlost - actual_stake + awinlost + mwinlost + swinlost + scomm)*virtualrate) Winlost8RM
	FROM	bettrans14 b WITH (NOLOCK)
			INNER JOIN @Match m on b.matchid = m.matchid 
	WHERE
			winlostdate = @winlostdate
			AND (b.bettype < 31 OR b.bettype BETWEEN 121 AND 999) 
			AND b.matchid > 0 
			--AND status NOT IN ('VOID', 'REJECT','REFUND') 
			AND b.statusID NOT IN (101,102,103) 
			AND b.ruben = 1
			and recommend = 52466
			AND m.type = CASE WHEN b.bettype = 10 THEN 'outright' ELSE 'match' END -- 20120628@Elodie: check case of matchid = orid
	GROUP BY b.liveindicator
	
	-- 20120412@Hurri: Get win lost of agent 'BARM'
	select	b.liveindicator, 
			-sum((winlost - actual_stake + awinlost + mwinlost + swinlost + scomm)*virtualrate) WinlostBARM
	FROM	bettrans14 b WITH (NOLOCK)
			INNER JOIN @Match m on b.matchid = m.matchid 
	WHERE
			winlostdate = @winlostdate
			AND (b.bettype < 31 OR b.bettype BETWEEN 121 AND 999) 
			AND b.matchid > 0 
			--AND status NOT IN ('VOID', 'REJECT','REFUND') 
			AND b.statusID NOT IN (101,102,103) 
			AND b.ruben = 1
			and recommend = 5707545
			AND m.type = CASE WHEN b.bettype = 10 THEN 'outright' ELSE 'match' END -- 20120628@Elodie: check case of matchid = orid
	GROUP BY b.liveindicator


GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_DailyWLDirect_Soccer_Bettype14] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_DailyWLDirect_Soccer_Bettype14] TO [vnteam] AS [dbo]