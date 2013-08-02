ALTER PROCEDURE [dbo].[Acc_Rpt_DailyWLDirect_Casino14]
	@winlostdate	datetime
AS
	/*	Creator: Phuong Dao
		Date: 2009-05-14
		Task: Casino WinLost Summary report
		DB: DB06.bodb02
		
		Revisions:
			- 20090731@Jamie: Not to view data in range of date, but only one date at once 	
			-- 20100525@Henry: Change to use StatusID instead of Status in WHERE statement
			- 20120405@Hurri: Exclude bettype 72 (P2P bet ticket) in the calculation of Casino
			- 20130703@Kathy: Update matchid for RnG Casino (71)
			- 20130717@Kathy: Apply Progressive Bonus: add bettype 72 for Casino
			- 20130801@Johnson: Separate win loss by credit/deposit site(1: credit, 2: deposit)			
		
	*/
BEGIN
	SET NOCOUNT ON
	CREATE TABLE #DepAgent (custid int primary key)
		
	INSERT INTO #DepAgent 
	SELECT custid
	FROM custInfo with(NOLOCK)
	WHERE srecommend IN (SELECT custid FROM f_DepSuper_1('All'))
		AND roleid = 2
				
	SELECT		
			71 bettype,
			case when dep.custid is null then 1 else 2 end as site,
			sum((winlost-actual_stake)*actualrate) WinLost,
			sum((awinlost+mwinlost+swinlost)*actualrate) Position,
			sum(scomm*actualrate) Commission,	
			sum((winlost-actual_stake+awinlost+mwinlost+swinlost+scomm)*actualrate) LineTotal,
			0 Turnover
	FROM	bettrans14 b WITH (NOLOCK)
		LEFT JOIN  (select custid from #DepAgent) dep ON b.recommend = dep.custid 		
	WHERE	b.winlostdate = @winlostdate
			AND b.bettype IN(71, 72)								--20120405@Hurri
			AND b.matchid IN (0, 71)
			--AND b.status NOT IN ('VOID', 'REJECT','done','REFUND') 
			AND b.statusID NOT IN (101, 102,103,121) 
			AND b.ruben = 1		
	GROUP BY b.Bettype, case when dep.custid is null then 1 else 2 end
	ORDER BY b.Bettype, site	
	
	DROP TABLE #DepAgent
END 

GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_DailyWLDirect_Casino14] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_DailyWLDirect_Casino14] TO [vnteam]