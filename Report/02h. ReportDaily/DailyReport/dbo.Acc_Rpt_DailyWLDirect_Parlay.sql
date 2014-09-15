 ALTER PROCEDURE [dbo].[Acc_Rpt_DailyWLDirect_Parlay]
	@winlostdate	DATETIME
AS
	/*
		Created: Johnson
		Date: 2014-09-11
		Task: Daily Winloss Summary for Parlay
		DB: DBACC/bodb02
		
		Revisions:
		
	*/
BEGIN
	SET NOCOUNT ON 
	CREATE TABLE #DepAgent (custid int PRIMARY KEY)
	
	--deposit agents
	INSERT INTO #DepAgent 
	SELECT custid
	FROM custInfo with(NOLOCK)
	WHERE srecommend IN (SELECT custid FROM f_DepSuper_1('All'))
		AND roleid = 2
	UNION
	SELECT 5707545--BARM
	
	SELECT	CASE WHEN bettype = 29 THEN 1 ELSE 2 END AS DisplayOrder,
			CASE WHEN bettype = 29 THEN 'System Parlay' ELSE 'Mix Parlay' END as SportName,			
			CASE WHEN dep.custid is null THEN 1 ELSE 2 END as site,
			bettype, 
			SUM((winlost-actual_stake)*virtualrate) Winlost,
			SUM((awinlost+mwinlost+swinlost)*virtualrate) Position,
			SUM(scomm*virtualrate) Commission,
			SUM((winlost-actual_stake+awinlost+mwinlost+swinlost+scomm)*actualrate) RealLineTotal,
			SUM((winlost-actual_stake+awinlost+mwinlost+swinlost+scomm)*virtualrate) VirtualLineTotal,
			SUM((1-tpositiontaking)*ABS(stake)*actualrate) RealTurnover, -- don't need calculate actualrate for system parlay
			SUM((1-tpositiontaking)*ABS(CASE WHEN bettype = 29 AND betid > 0 THEN actual_stake ELSE stake END)*virtualrate) VirtualTurnover,			
			1 EnableVirtual
	FROM bettrans b WITH(NOLOCK)
		left join (select custid FROM #DepAgent) dep ON b.recommend = dep.custid
	WHERE winlostdate = @winlostdate
		AND bettype IN (9,29)
		AND b.statusID NOT IN (101,102,103,121) 
		AND b.ruben = 1	
	GROUP BY CASE WHEN bettype = 29 THEN 1 ELSE 2 END,
			CASE WHEN bettype = 29 THEN 'System Parlay' ELSE 'Mix Parlay' END,			
			CASE WHEN dep.custid is null THEN 1 ELSE 2 END ,
			bettype
	
	DROP TABLE #DepAgent
END

GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_DailyWLDirect_Parlay] TO [bodbAdminNet]

	