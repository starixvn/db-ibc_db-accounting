 ALTER PROCEDURE [dbo].[Acc_Rpt_DailyWLDirect_LiveCasino14]
	@winlostdate datetime
AS

/*	Creator: Sophia
	Date: 2012-02-31
	Task: Live Casino WinLost Summary report
	DB: DBACC/bodb02
	
	Revisions:
		- 20130801@Johnson: Separate win loss by credit/deposit site(1: credit, 2: deposit)			
		- 20150109@Dom: Apply sport bettype matrix
	
*/
SET NOCOUNT ON

----Get Sport Bettype Matrix------
DECLARE @SportBettype TABLE(ProductID INT, Bettype INT,EventType INT)
INSERT INTO @SportBettype
EXEC bodb02.dbo.Acc_SportBettypeMatrix_Sel @mode=4,@ProductId=7

CREATE TABLE #DepAgent (custid int primary key)
	
INSERT INTO #DepAgent 
SELECT custid
FROM custInfo with(NOLOCK)
WHERE srecommend IN (SELECT custid FROM f_DepSuper_1('All'))
	AND roleid = 2
UNION
SELECT 5707545--BARM

SELECT	b.bettype bettype,
		case when dep.custid is null then 1 else 2 end as site,
		sum((winlost-actual_stake)*actualrate) WinLost,
		sum((awinlost+mwinlost+swinlost)*actualrate) Position,
		sum(scomm*actualrate) Commission,	
		sum((winlost-actual_stake+awinlost+mwinlost+swinlost+scomm)*actualrate) LineTotal,
		sum((1-tpositiontaking)*stake*actualrate) Turnover
FROM	bettrans14 b WITH (NOLOCK)
	INNER JOIN @SportBettype s ON s.bettype = b.bettype
	LEFT JOIN (select custid from #DepAgent) dep ON b.recommend = dep.custid 		
WHERE	b.winlostdate = @winlostdate
		--AND b.bettype BETWEEN 1101 AND 1199	
		AND b.ruben = 1		
		AND b.statusID not in (101,102,103,121)
GROUP BY b.Bettype, case when dep.custid is null then 1 else 2 end
ORDER BY b.Bettype, site

DROP TABLE #DepAgent


GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_DailyWLDirect_LiveCasino14] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_DailyWLDirect_LiveCasino14] TO [vnteam]