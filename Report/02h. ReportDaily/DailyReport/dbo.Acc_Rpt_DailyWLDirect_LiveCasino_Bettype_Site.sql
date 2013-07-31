 ALTER PROCEDURE [dbo].[Acc_Rpt_DailyWLDirect_LiveCasino_Bettype_Site]
	@winlostdate DATETIME,
	@bettype	INT,
	@site		TINYINT
 AS
	/*
		Creator: Johnson
		Date: 2013-07-31
		Task: Report winlost summary for live casino by site
		DB: DBACC/bodb02 
		
		Revisions:
		
		Parameter's Explanation:
			- @site: 1: credit
					2: deposit	
	*/
SET NOCOUNT ON
	CREATE TABLE #super (custid int primary key , site varchar(50))

	INSERT INTO #super (custid, site)
	SELECT c.custid, site
	FROM customer c WITH(NOLOCK)
		LEFT JOIN (select custid from f_DepSuper_1('All')) dep ON c.custid = dep.custid
	WHERE roleid = 4
		AND 1= CASE WHEN @site = 1 AND dep.custid IS NULL THEN 1
					WHEN @site = 2 AND dep.custid IS NOT NULL THEN 1 ELSE 0 END
		
	SELECT	s.site,
		sum((winlost-actual_stake)*actualrate) WinLost,
		sum((awinlost+mwinlost+swinlost)*actualrate) Position,
		sum(scomm*actualrate) Commission,	
		sum((winlost-actual_stake+awinlost+mwinlost+swinlost+scomm)*actualrate) LineTotal,
		sum((1-tpositiontaking)*stake*actualrate) Turnover
	FROM	bettrans b WITH (NOLOCK)
		INNER JOIN #super s ON b.srecommend = s.custid
	WHERE	b.winlostdate = @winlostdate
			AND b.bettype = @bettype
			AND b.ruben = 1		
			AND b.statusID not in (101,102,103,121)
	GROUP BY site
	ORDER BY site


GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_DailyWLDirect_LiveCasino_Bettype_Site] TO [bodbAdminNet]
	