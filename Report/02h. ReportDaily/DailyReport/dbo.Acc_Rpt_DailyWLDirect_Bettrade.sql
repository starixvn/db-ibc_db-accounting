ALTER PROCEDURE [dbo].[Acc_Rpt_DailyWLDirect_Bettrade_xpre]
	@WinlostDate	DATETIME
AS
/*	Creator: 20150723@Sophia
	Task: 2h report/ Bettrade 
	DB: DBACC/bodb02
	
	Revisions: 
		
*/


BEGIN 
SET NOCOUNT ON
 

CREATE TABLE #DepAgent (custid int primary key)

INSERT INTO #DepAgent 
SELECT	custid
FROM	dbo.custInfo with(NOLOCK)
WHERE	srecommend IN (SELECT custid FROM f_DepSuper_1('All'))
		AND roleid = 2
UNION
SELECT 5707545--BARM

SELECT	CASE WHEN dep.custid IS NULL THEN 1 ELSE 2 END AS site
		,SUM ((winlost - actual_stake) * actualrate) WinLost
		,SUM ((awinlost + mwinlost + swinlost) * actualrate) Position
		,0 AS Commission
		,SUM ((winlost - actual_stake + awinlost + mwinlost + swinlost + scomm) * actualrate) LineTotal
		,0 AS Turnover
	FROM dbo.bettrans b WITH (NOLOCK)		
		LEFT JOIN (SELECT custid FROM #DepAgent ) dep
			ON b.recommend = dep.custid
	WHERE 	b.winlostdate = @winlostdate
		AND b.Bettype = 903
		AND b.ruben = 1
		AND b.statusID NOT IN (101, 102, 103, 121)
	GROUP BY b.Bettype
		,CASE WHEN dep.custid IS NULL THEN 1 ELSE 2 END
	ORDER BY b.Bettype
		,Site


DROP TABLE #DepAgent

 

END		
GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_DailyWLDirect_Bettrade_xpre] TO [bodbAdminNet]
GO 