ALTER PROCEDURE [dbo].[Acc_Rpt_DailyWLDirect_LiveCasino]
	@winlostdate datetime
AS

/*	Creator: Sophia
	Date: 2012-02-31
	Task: Live Casino WinLost Summary report
	DB: DBACC/bodb02
	
	Revisions:
		- 20130731@Johnson: Separate win loss by credit/deposit site(1: credit, 2: deposit)				
		- 20150109@Dom: Apply sport bettype matrix
		- 20150522@Sophia: Apply Gold Deluxe and revise Sport Betype Matrix [#35359] 
		- 20150702@Sophia: Apply Microgaming and SuperBalance [#38168]
		- 20151111@Percy: Change the sport type: MGC-RNG to MGC and RNG [RedmineID: #46576]
	
*/
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


SELECT	s.ProductID, b.bettype ,
		case when dep.custid is null then 1 else 2 end as site,
		sum((winlost-actual_stake)*actualrate) WinLost,
		sum((awinlost+mwinlost+swinlost)*actualrate) Position,
		sum(scomm*actualrate) Commission,	
		sum((winlost-actual_stake+awinlost+mwinlost+swinlost+scomm)*actualrate) LineTotal,
		sum((1-tpositiontaking)*stake*actualrate) Turnover,
		sum((winlost-actual_stake)*actualrate) ExtraPT,
		sum((winlost-actual_stake)*actualrate) AfterExtraPT
FROM	bettrans b WITH (NOLOCK)
	INNER JOIN @SportBettype s ON s.bettype = b.bettype
	LEFT JOIN (select custid from #DepAgent) dep ON b.recommend = dep.custid
WHERE	b.winlostdate = @winlostdate
		AND s.ProductId IN (4,12,11,13) -- Live Casino, AG Casino, Gold Deluxe, Microgaming - Live Casino
		AND b.ruben = 1		
		AND b.statusID not in (101,102,103,121)
GROUP BY s.ProductID, b.Bettype, case when dep.custid is null then 1 else 2 end 
ORDER BY b.Bettype, site

DROP TABLE #DepAgent


GO

GRANT EXECUTE ON [dbo].[Acc_Rpt_DailyWLDirect_LiveCasino] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_DailyWLDirect_LiveCasino] TO [vnteam] AS [dbo]
GO