ALTER PROCEDURE [dbo].[Acc_Rpt_DailyWLDirect_Casino]
	@winlostdate	datetime
AS
	/*	Creator: Phuong Dao
		Date: 2009-05-14
		Task: Casino WinLost Summary report
		DB: DBACC/bodb02
		
		Revisions:
			- 20090731@Jamie: Not to view data in range of date, but only one date at once 
			-- 20100525@Henry: Change to use StatusID instead of Status in WHERE statement
			- 20120405@Hurri: Exclude bettype 72 (P2P bet ticket) in the calculation of Casino
			- 20130703@Kathy: Update matchid for RnG Casino (71)
			- 20130717@Kathy: Apply Progressive Bonus: add bettype 72 for Casino
			- 20130801@Johnson: Separate win loss by credit/deposit site(1: credit, 2: deposit)					   
			- 20150109@Dom: Apply sport bettype matrix
			- 20150702@Sophia: Apply Microgaming and SuperBalance [#38168]
			- 20150806@Sophia: Get Turnover of Macau and Microgaming - RNG Casino (Group Casino)
			- 20151111@Percy: Change the sport type: MGC_LC-RNG to LC and RNG [RedmineID: #46576]
			
	*/
BEGIN
	SET NOCOUNT ON

	----Get Sport Bettype Matrix------
	DECLARE @SportBettype TABLE(ProductID INT, Bettype INT,EventType INT,SubProduct VARCHAR(500))
	INSERT INTO @SportBettype
	EXEC bodb02.dbo.Acc_SportBettypeMatrix_Sel @mode = 5


	CREATE TABLE #DepAgent (custid int primary key)
	
	INSERT INTO #DepAgent 
	SELECT custid
	FROM custInfo with(NOLOCK)
	WHERE srecommend IN (SELECT custid FROM f_DepSuper_1('All'))
	AND roleid = 2
	UNION
	SELECT 5707545--BARM	
	
	SELECT	s.ProductId,	
			CASE s.ProductId WHEN 6 THEN 71
							 WHEN 14 THEN 1900
							 WHEN 13 THEN 2001
							 WHEN 17 THEN 2008
							 END AS bettype,
			case when dep.custid is null then 1 else 2 end as site,
			isnull(sum((winlost-actual_stake)*actualrate), 0 ) WinLost,
			isnull(sum((awinlost+mwinlost+swinlost)*actualrate),0) Position,
			isnull(sum(scomm*actualrate),0) Commission,	
			isnull(sum((winlost-actual_stake+awinlost+mwinlost+swinlost+scomm)*actualrate),0) LineTotal,
			isnull(sum(CASE WHEN s.ProductId = 6 THEN 0 ELSE (1-tpositiontaking)*stake*actualrate END),0) AS Turnover
	FROM	bettrans b WITH (NOLOCK)
		INNER JOIN @SportBettype s ON s.bettype = b.bettype
		left join (select custid from #DepAgent) dep ON b.recommend = dep.custid
	WHERE	b.winlostdate = @winlostdate
			AND s.ProductId IN (6, 14, 17) -- Casino, Macau, MGC-RNG
			AND b.statusID NOT IN (102, 101,121,103)  ---('VOID', 'REJECT','done','REFUND') 
			AND b.ruben = 1		
	GROUP BY s.ProductId, 
			case when dep.custid is null then 1 else 2 end,
			CASE s.ProductId WHEN 6 THEN 71
							 WHEN 14 THEN 1900
							 WHEN 13 THEN 2001
							 WHEN 17 THEN 2008
							 END 
	ORDER BY s.ProductId, site	

	--GROUP BY b.Bettype, case when dep.custid is null then 1 else 2 end 
	--ORDER BY b.Bettype, site
	
	DROP TABLE #DepAgent
END 




GO

GRANT EXECUTE ON [dbo].[Acc_Rpt_DailyWLDirect_Casino] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_DailyWLDirect_Casino] TO [vnteam] AS [dbo]
GO