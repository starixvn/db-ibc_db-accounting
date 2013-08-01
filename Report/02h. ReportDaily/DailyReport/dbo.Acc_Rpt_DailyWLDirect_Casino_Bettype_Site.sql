ALTER PROCEDURE [dbo].[Acc_Rpt_DailyWLDirect_Casino_Bettype_Site]
	@winlostdate	datetime,
	@site			tinyint
AS
	/*	Creator: Johnson
		Date: 2013-08-01
		Task: Casino WinLost Summary report by site
		DB: DBACC/bodb02
		
		Revisions: 
		
		Parameter's Explanation:
			- @site: 1: credit
					2: deposit	
	*/
BEGIN
	SET NOCOUNT ON
	CREATE TABLE #super (custid int primary key , site varchar(50))

	INSERT INTO #super (custid, site)
	SELECT c.custid, site
	FROM customer c WITH(NOLOCK)
		LEFT JOIN (select custid from f_DepSuper_1('All')) dep ON c.custid = dep.custid
	WHERE roleid = 4
		AND 1= CASE WHEN @site = 1 AND dep.custid IS NULL THEN 1
					WHEN @site = 2 AND dep.custid IS NOT NULL THEN 1 ELSE 0 END
			
	SELECT		
			s.site,
			sum((winlost-actual_stake)*actualrate) WinLost,
			sum((awinlost+mwinlost+swinlost)*actualrate) Position,
			sum(scomm*actualrate) Commission,	
			sum((winlost-actual_stake+awinlost+mwinlost+swinlost+scomm)*actualrate) LineTotal,
			0 Turnover
	FROM	bettrans b WITH (NOLOCK)
		INNER JOIN #super s ON b.srecommend = s.custid
	WHERE	b.winlostdate = @winlostdate
			AND b.bettype IN(71, 72)								--20120405@Hurri
			AND b.matchid IN (0, 71)
			--AND b.status NOT IN ('VOID', 'REJECT','done','REFUND') 
			AND b.statusID NOT IN (102, 101,121,103) 
			AND b.ruben = 1		
	GROUP BY s.site
	ORDER BY s.site
	
	DROP TABLE #super
END

GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_DailyWLDirect_Casino_Bettype_Site] TO [bodbAdminNet]