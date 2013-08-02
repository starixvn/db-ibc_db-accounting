ALTER PROCEDURE [dbo].[Acc_Rpt_DailyWLDirect_Sporttype_Bettype_Site14] 
	@winlostdate	datetime,
	@SportType		int = 1,
	@liveindicator	bit,
	@bettype		int,
	@site			int
AS
	/*	Creator: Johnson
		Date: 2013-08-02
		Task: Report winlost summary 
		DB: DBACC/bodb02 
		
		Revisions:
		
		Parameter's Explanation:
			- @site: 1: credit
					2: deposit			
	*/
BEGIN	
	SET NOCOUNT ON 
	--Declare @temp table to contain all matches
	DECLARE @Match TABLE (matchid int, type varchar(10), primary key(matchid, type))
	CREATE TABLE #DepAgent (custid int primary key , site varchar(50))
	
	INSERT INTO #DepAgent (custid, site)
	SELECT c.custid, site
	FROM customer c WITH(NOLOCK)
		LEFT JOIN (select custid from f_DepSuper_1('All')) dep ON c.srecommend = dep.custid
	WHERE roleid = 2
		AND 1= CASE WHEN @site = 1 AND dep.custid IS NULL THEN 1
					WHEN @site = 2 AND dep.custid IS NOT NULL THEN 1 ELSE 0 END
	
	INSERT INTO @Match
	SELECT	m.matchid,
			m.type
	FROM 
		(	select matchid, leagueid, exrisk, 'match' as type from match14 with (nolock) where @bettype <> 10 AND eventdate = @winlostdate
			union all
			select orid, leagueid, 0, 'outright' as type from outright14 with (nolock) where @bettype = 10 AND eventdate = @winlostdate
		) m
	INNER JOIN league l with (nolock) ON m.leagueid = l.leagueid
	INNER JOIN sports sp with (nolock) ON l.sporttype = sp.sporttype
	WHERE	sp.sporttype = @sporttype 
			AND ExRisk = 0		

	SELECT ag.site,
		sum((winlost-actual_stake)*virtualrate) WinLost,
		sum((awinlost+mwinlost+swinlost)*virtualrate) Position,
		sum(scomm*virtualrate) Commission,	
		sum((winlost-actual_stake+awinlost+mwinlost+swinlost+scomm)*actualrate) RealLineTotal,
		sum((winlost-actual_stake+awinlost+mwinlost+swinlost+scomm)*virtualrate) VirtualLineTotal,
		sum((1-tpositiontaking)* ABS(stake) * actualrate) RealTurnover,
		sum((1-tpositiontaking)* ABS(stake) * virtualrate) VirtualTurnover
	FROM bettrans14 b with(NOLOCK)
		INNER JOIN @Match m ON b.matchid = m.matchid
		INNER JOIN #DepAgent ag ON b.recommend = ag.custid
	WHERE winlostdate = @winlostdate
		AND b.bettype = @bettype				
		AND b.statusID NOT IN (101, 102,103) 
		AND b.ruben = 1
		AND b.liveindicator = @liveindicator
	GROUP BY site
	ORDER BY site
	
	DROP TABLE #DepAgent
END	


GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_DailyWLDirect_Sporttype_Bettype_Site14] TO [bodbAdminNet]