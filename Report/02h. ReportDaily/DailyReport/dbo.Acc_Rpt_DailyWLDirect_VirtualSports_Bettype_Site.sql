ALTER PROCEDURE [dbo].[Acc_Rpt_DailyWLDirect_VirtualSports_Bettype_Site]
	@winlostdate datetime,
	@sporttype	int,
	@bettype	int,
	@site		tinyint
AS
/*	Creator: Johnson
	Date: 2013-08-01
	Task: Winloss Summary of Virtual sports by site
	DB: DBACC/bodb02
	
	Revisions:  
	
	Parameter's Explanation:
		- @site: 1: credit
					2: deposit	
*/
BEGIN
	SET NOCOUNT ON
	CREATE TABLE #DepAgent (custid int primary key , site varchar(50))
	
	INSERT INTO #DepAgent (custid, site)
	SELECT c.custid, site
	FROM customer c WITH(NOLOCK)
		LEFT JOIN (select custid from f_DepSuper_1('All')) dep ON c.srecommend = dep.custid
	WHERE roleid = 2
		AND 1= CASE WHEN @site = 1 AND dep.custid IS NULL THEN 1
					WHEN @site = 2 AND dep.custid IS NOT NULL THEN 1 ELSE 0 END
	
	
	IF @bettype IN  (1231, 1232, 1233, 1237, 1238)
	BEGIN
		SELECT		
				ag.site,
				sum((winlost-actual_stake)*actualrate) WinLost,
				sum((awinlost+mwinlost+swinlost)*actualrate) Position,
				sum(scomm*actualrate) Commission,	
				sum((winlost-actual_stake+awinlost+mwinlost+swinlost+scomm)*actualrate) LineTotal,
				sum((1-tpositiontaking)* stake * actualrate) Turnover
		FROM	bettrans b WITH (NOLOCK)
				INNER JOIN VSRaceInfo r ON r.EventID = b.matchid
				INNER JOIN #DepAgent ag ON b.recommend = ag.custid
		WHERE
				winlostdate = @winlostdate
				AND b.bettype = @bettype
				AND b.matchid > 0 			
				AND b.statusID NOT IN (101, 102, 103) --('VOID', 'REJECT','REFUND') 
				AND b.ruben = 1			
				and r.sporttype = @sporttype
		GROUP BY ag.site
		ORDER BY ag.site	
	END
	ELSE BEGIN	
		SELECT		
				s.site,
				sum((winlost-actual_stake)*actualrate) WinLost,
				sum((awinlost+mwinlost+swinlost)*actualrate) Position,
				sum(scomm*actualrate) Commission,	
				sum((winlost-actual_stake+awinlost+mwinlost+swinlost+scomm)*actualrate) LineTotal,
				sum((1-tpositiontaking)* stake * actualrate) Turnover
		FROM	bettrans b WITH (NOLOCK)
				INNER JOIN match m on b.matchid = m.matchid
				INNER JOIN #DepAgent ag ON b.recommend = ag.custid
		WHERE
				winlostdate = @winlostdate
				AND b.bettype = @bettype
				AND b.matchid > 0 			
				AND b.statusID NOT IN (101, 102, 103) --('VOID', 'REJECT','REFUND') 
				AND b.ruben = 1
				and m.sporttype = @sporttype
		GROUP BY site
		ORDER BY site
	END
	
	DROP TABLE #DepAgent
END



GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_DailyWLDirect_VirtualSports_Bettype_Site] TO [bodbAdminNet]

