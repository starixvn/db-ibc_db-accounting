ALTER PROCEDURE [dbo].[Acc_Rpt_DailyWLDirect_Casino_Bettype_Site14]
		@winlostdate DATETIME
		,@ProductId TINYINT
		,@site TINYINT
		,@bettype INT 

AS
	/*	Creator: Johnson
		Date: 2013-08-02
		Task: Casino WinLost Summary report by site
		DB: DBACC/bodb02
		
		Revisions: 
			- 20130906@Johnson: get virtual values by virtual rate instead of actual rate			
			- 20150703@Sophia: Apply Microgaming and SuperBalance [#38168]
			- 20150806@Sophia: Get Turnover of Macau and Microgaming - RNG Casino (Group Casino)

		Parameter's Explanation:
			- @site: 1: credit
					2: deposit	
			- @ProductId: ProductId of SportBettypeMatrix
			- @bettype : No need now, will enhance later
	*/
BEGIN
	SET NOCOUNT ON
	----Get Sport Bettype Matrix------
	DECLARE @SportBettype TABLE(ProductID INT, Bettype INT,EventType INT,SubProduct VARCHAR(500))
	INSERT INTO @SportBettype
	EXEC bodb02.dbo.Acc_SportBettypeMatrix_Sel @mode = 5


	CREATE TABLE #DepAgent (custid int primary key , site varchar(50))
	
	INSERT INTO #DepAgent (custid, site)
	SELECT c.custid, site
	FROM customer c WITH(NOLOCK)
		LEFT JOIN (select custid from f_DepSuper_1('All')) dep ON c.srecommend = dep.custid
	WHERE roleid = 2
		AND 1= CASE WHEN @site = 1 AND dep.custid IS NULL THEN 1
					WHEN @site = 2 AND dep.custid IS NOT NULL THEN 1 ELSE 0 END
		AND c.custid NOT IN (52466,5707545)--8RM, BARM
	
	INSERT INTO #DepAgent (custid, site)
	SELECT 52466,'XYZBET' WHERE @site = 1--8RM
	UNION
	SELECT 5707545,'BEST-ODDS' WHERE @site =2 --BARM
	
	SELECT		
			ag.site,
			sum((winlost-actual_stake)*actualrate) WinLost,
			sum((awinlost+mwinlost+swinlost)*actualrate) Position,
			sum(scomm*actualrate) Commission,	
			sum((winlost-actual_stake+awinlost+mwinlost+swinlost+scomm)*actualrate) RealLineTotal,
			sum((winlost-actual_stake+awinlost+mwinlost+swinlost+scomm)*virtualrate) VirtualLineTotal,
			sum(CASE WHEN s.ProductId = 6 THEN 0 ELSE (1-tpositiontaking)*stake*actualrate END) AS RealTurnover,
			sum(CASE WHEN s.ProductId = 6 THEN 0 ELSE (1-tpositiontaking)*stake*actualrate END) AS VirtualTurnover
	FROM	bettrans14 b WITH (NOLOCK)
		INNER JOIN @SportBettype s ON s.bettype = b.bettype
		INNER JOIN #DepAgent ag ON b.recommend = ag.custid
	WHERE	b.winlostdate = @winlostdate
			AND s.ProductId = @ProductId
			AND (
					s.ProductId = 6 -- Casino
					OR s.ProductId = 14  --- Vegas Games
					OR (s.ProductId = 13 AND SubProduct = 'MGC-RNG')-- Microgaming - RNG Casino	
				) 

			--AND b.bettype IN(71, 72)								--20120405@Hurri
			--AND b.matchid IN (0, 71)
			--AND b.status NOT IN ('VOID', 'REJECT','done','REFUND') 
			AND b.statusID NOT IN (102, 101,121,103) 
			AND b.ruben = 1		
	GROUP BY ag.site
	ORDER BY ag.site
	
	DROP TABLE #DepAgent
END

GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_DailyWLDirect_Casino_Bettype_Site14] TO [bodbAdminNet]