ALTER PROCEDURE [dbo].[Acc_Rpt_MatchWinLossByBetType]
	@fromdate datetime,
	@todate datetime
as
/*
	Task: Match Win Lost, commission, positiontaking by bettype 
	Created: 
	DB: DB06.BODB02
	Revisions:
		- 20091125@Kiwi: Remove comstatus because it's no used.	
		- 20101118@Jamie: Exclude Number Game 
		- 20120231@Sophia: Exclude Live Casino
		- 20120626@Elodie: exclude outright, HR from sportbook ( in case of matchid = orid)
		- 20130225@Elodie: Exclude Virtual sports
		- 20150526@Sophia: Apply Sport Bettype Matrix [#34486]		
		- 20150723@Sophia: Exclude data of Bettrade [#38815]
		- 20150921@Jim: support MO (#41935)
	Param's Explanation:
*/

SET NOCOUNT ON

----Get Sport Bettype Matrix------
	DECLARE @SportBettype TABLE(ProductID INT, Bettype INT,EventType INT, SubProduct VARCHAR(500),SortKey TINYINT,liveindicator BIT)
	INSERT INTO @SportBettype (ProductID  , Bettype  ,EventType ,SubProduct )
	EXEC dbo.Acc_SportBettypeMatrix_Sel_xpre @mode = 5
	
	UPDATE @SportBettype
	SET liveindicator =0
	
	INSERT INTO @SportBettype(ProductID,Bettype,EventType,SubProduct,liveindicator)
	SELECT ProductID
		 ,Bettype
		 ,EventType
		 ,SubProduct
		 ,1 AS liveindicator
	FROM @SportBettype
	WHERE liveindicator =0	
	
	UPDATE @SportBettype
	SET SortKey =  CASE  WHEN Bettype =1   AND liveindicator =0   THEN 1
						WHEN Bettype =301 AND liveindicator =0   THEN 2
						WHEN Bettype =1   AND liveindicator =1   THEN 3
						WHEN Bettype =301 AND liveindicator =1   THEN 4
						WHEN Bettype =3   AND liveindicator =0   THEN 5
						WHEN Bettype =302 AND liveindicator =0   THEN 6
						WHEN Bettype =3   AND liveindicator =1   THEN 7
						WHEN Bettype =302 AND liveindicator =1   THEN 8
						WHEN Bettype =7   AND liveindicator =0   THEN 9
						WHEN Bettype =303 AND liveindicator =0   THEN 10
						WHEN Bettype =7   AND liveindicator =1   THEN 11
						WHEN Bettype =303 AND liveindicator =1   THEN 12
						WHEN Bettype =8   AND liveindicator =0   THEN 13
						WHEN Bettype =304 AND liveindicator =0   THEN 14
						WHEN Bettype =8   AND liveindicator =1   THEN 15
						WHEN Bettype =304 AND liveindicator =1   THEN 16
						ELSE 17
						END
								
	
	DELETE	@SportBettype  
	WHERE	ProductID IN (2,3,4,5)
			OR (ProductID = 1 AND EventType = 2)
			OR (SubProduct IN ('BT-Sold','BT-Bought','BT-Comm'))

	SELECT b.liveindicator
		,s.bettype
		,m.homeid
		,m.awayid
		,sum((b.winlost - b.actual_stake) * b.actualrate) AS matchwinlost
		,isnull(m.isNeutral, CONVERT(BIT, 0)) AS IsNeutral
		,b.matchid
	FROM dbo.match m WITH (NOLOCK)
		INNER JOIN dbo.bettrans b WITH (NOLOCK)
			ON m.matchid = b.matchid
		INNER JOIN @SportBettype s
			ON s.Bettype = b.Bettype AND b.liveindicator=s.liveindicator
	WHERE m.kickofftime >= @fromdate
		AND m.kickofftime <= @todate
		AND m.eventstatus = 'completed'
		AND b.matchid > 0
		---AND m.sporttype NOT IN (161, 162, 180, 182, 183, 184, 185, 186) -- 20130225@Elodie: Exclude Virtual sports
		---AND b.bettype NOT IN (10, 31, 32, 33, 1231, 1232, 1233, 1237, 1238) --20120626@Elodie: exclude outright, HR from sportbook					
	GROUP BY b.liveindicator
		,s.bettype
		,s.SortKey
		,b.matchid
		,m.homeid
		,m.awayid
		,m.isNeutral
	ORDER BY b.matchid,s.SortKey,s.bettype



GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_MatchWinLossByBetType] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_MatchWinLossByBetType] TO [vnteam]