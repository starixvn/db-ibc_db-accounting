USE [bodb02]
GO
 
ALTER PROCEDURE [dbo].[Acc_Rpt_TreeWinlostByCom]
	@FromDate   DATETIME,
	@ToDate   DATETIME,  
	@currency INT,	
	@showSB BIT=1,  
	@showNG BIT=0,  
	@ShowRB BIT=0,  
	@showLiveCasino BIT = 0,  
	@showCasino BIT=0,  
	@showP2P BIT=0,  
	@showBI BIT=0,  
	@showVS BIT = 0,
	@showKeno BIT=0,
	@ShowGD BIT = 0, -- Show GoldDeluxe
	@ShowMGSL BIT = 0, -- Show Metric Gaming
	@showMGC BIT=0, --Micro Gaming
	@showVG BIT=0, --Vegas Games
	@showAGCS BIT=0 --AG Casino

AS

/*  
Created by: Scott  
Date: 2012-12-17 
Task : Report Tree Win Lost  
DB: DBACC.bodb02  
Original SP:   
Revisions:  
	-20130115@Scott : fix bug sum total of poker sporttype
	-20130418@Scott : Update formula turnover of Racing
	-20130702@Dom.Cao: Add Vanriance (+\-)
	-20140304@TomVo: 
		Change Name Server (DB06) to Alias Server (DBACC)
		Add Keno Sport (202) -Bettype : 1501 - 1599
	- 20151226@Johnson: Separate virtual rate by sporttype, bettype [Redmine: #25840]	
	- 20150529@Jim: add more parameter @ShowGD,@ShowMGSL and apply sport-bettype matrix 
	- 20150710@Jim: Super Balance fix and Microgaming integration (Feature #38168)
	- 20150723@Jim: Apply Bettrade [#38815]	
*/  

SET NOCOUNT ON

DECLARE @TmpCondBettype TABLE(bettype INT , isVirtual BIT) 
DECLARE @tmpIBCFee TABLE(partnerID int,IBCFee bit)  
--DECLARE #TmpResult TABLE (srecommend INT ,username NVARCHAR(100),actualrate FLOAT,Turnover MONEY, Winloss MONEY,Commission MONEY,virtualrate SMALLINT)
--DECLARE #TmpResultAll TABLE (srecommend INT ,username NVARCHAR(100),Turnover MONEY, Winloss MONEY,Commission MONEY,Total MONEY,TurnoverRM MONEY,TotalRM MONEY,Virtual_Total MONEY,Variance MONEY, virtualrate SMALLINT)
DECLARE @CommSetting TABLE (MatchID int, IBCFee bit, ToteCommWin smallmoney, ToteCommPlace smallmoney, ToteCommWP smallmoney, ToteFee smallmoney )


CREATE TABLE #TmpResult (srecommend INT ,
						--username NVARCHAR(100), 
						actualrate FLOAT,
						Turnover MONEY, 
						Winloss MONEY,
						Commission MONEY)
						--virtualrate SMALLINT
						
CREATE TABLE #TmpResultAll (srecommend INT ,
							--username NVARCHAR(100),
							virtualratetype INT,
							Turnover MONEY, 
							Winloss MONEY,
							Commission MONEY,
							Total MONEY,
							TurnoverRM MONEY,
							TurnoverIBCVirtual MONEY,
							TotalRM MONEY,
							Virtual_Total MONEY)
							--virtualrate SMALLINT
DECLARE @SportBettype TABLE(ProductID INT,Bettype INT,EventType INT,SubProduct VARCHAR(200))
INSERT INTO @SportBettype
EXEC dbo.Acc_SportBettypeMatrix_Sel  @mode=5

IF @ShowSB = 1  
	 INSERT INTO @TmpCondBettype(Bettype,isVirtual)   
	 SELECT Bettype, 1   
	 FROM @SportBettype   
	 WHERE ProductID =1 
		AND SubProduct  NOT IN ('MG-SuperLive' ,'BT-Sold','BT-Bought','BT-Comm')

IF @ShowNG = 1  
	INSERT INTO @TmpCondBettype(Bettype,isVirtual) 
	SELECT Bettype, 1   
	 FROM @SportBettype   
	 WHERE ProductID =3  

IF @showLiveCasino = 1
	 INSERT INTO @TmpCondBettype(Bettype,isVirtual)   
	 SELECT Bettype, 0   
	 FROM @SportBettype   
	 WHERE ProductID = 4  

IF @showCasino = 1
	 INSERT INTO @TmpCondBettype(Bettype,isVirtual)   
	 SELECT Bettype, 0   
	 FROM @SportBettype   
	 WHERE ProductID = 6 
	
IF @showBI = 1
	INSERT INTO @TmpCondBettype(Bettype,isVirtual)   
	 SELECT Bettype, 0   
	 FROM @SportBettype   
	 WHERE ProductID = 7
	
IF @showVS = 1
	INSERT INTO @TmpCondBettype(Bettype,isVirtual)   
	 SELECT Bettype, 0   
	 FROM @SportBettype   
	 WHERE ProductID = 5		
	
IF @showKeno = 1    
	 INSERT INTO @TmpCondBettype(Bettype,isVirtual)   
	 SELECT Bettype, 0   
	 FROM @SportBettype   
	 WHERE ProductID = 8
IF @ShowGD =1 
	 INSERT INTO @TmpCondBettype(Bettype,isVirtual)   
	 SELECT Bettype, 0   
	 FROM @SportBettype   
	 WHERE ProductID = 12
 
IF @ShowMGSL =1 
	INSERT INTO @TmpCondBettype(Bettype,isVirtual)   
	SELECT Bettype, 1   
	FROM @SportBettype   
	WHERE ProductID = 1
		AND SubProduct= 'MG-SuperLive'
IF @showMGC =1  --Micro Gaming
	INSERT INTO @TmpCondBettype(Bettype,isVirtual)   
	SELECT Bettype, 0   
	FROM @SportBettype   
	WHERE ProductID = 13

IF @showVG =1  --- VegasGame aka Macau
	INSERT INTO @TmpCondBettype(Bettype,isVirtual)   
	SELECT Bettype, 0   
	FROM @SportBettype   
	WHERE ProductID = 14	 

IF @showAGCS =1 -- AG Casino
	INSERT INTO @TmpCondBettype(Bettype,isVirtual)   
	SELECT Bettype, 0   
	FROM @SportBettype   
	WHERE ProductID = 11	

---get result for Horse Racing
	IF @ShowRB=1
	BEGIN
	
		INSERT INTO @tmpIBCFee (partnerID, IBCFee)  
		SELECT 1,1 --RACE-PHU
		UNION ALL
			SELECT 2,0 --RACE-ATRUK
		UNION ALL
			SELECT 3,0 --RACE-ATRIRL
		UNION ALL
			SELECT 4,0 --RACE-RUK
		UNION ALL
			SELECT 5,1 --RACE-TABCORP
		UNION ALL
			SELECT 6,1 --RACE-TABCORPNSW
		UNION ALL
			SELECT 101,1 --GREY-DTOTEUK
		UNION ALL
			SELECT 102,1 --GREY-DTOTEIRL
		UNION ALL
			SELECT 103,1 --GREY-TABCORP
		UNION ALL
			SELECT 104,1 --GREY-TABCORPNSW
		UNION ALL
			SELECT 201,1 --HAR-TABCORP
		UNION ALL
			SELECT 202,1 --HAR-TABCORPNSW
		
		INSERT INTO @CommSetting (MatchID, IBCFee, ToteCommWin, ToteCommPlace, ToteCommWP, ToteFee)  
		SELECT DISTINCT o.orid as matchid, t.IBCFee, p.ToteCommWin, p.ToteCommPlace, (p.ToteCommWin + p.ToteCommPlace)/2 ToteCommWP, p.ToteFee   
		FROM outright o WITH (NOLOCK)  
			INNER JOIN LeagueDetail p WITH (NOLOCK) ON o.leagueID = p.leagueID and p.programDate = o.programDate  
			INNER JOIN RacingMeeting r WITH(NOLOCK) ON r.meetingID = p.leagueid  
			INNER JOIN @tmpIBCFee t ON r.partnerID = t.partnerID  
		WHERE o.eventdate BETWEEN @FromDate AND @ToDate
		
		INSERT INTO #TmpResult -- Horse Racing
		SELECT b.srecommend,
			--cii.username,
			b.actualrate,  
			sum(case when bettype = 33 then bm.TOIBC else b.actual_stake*isnull(oddsspread,0) end) Turnover,
			-(  
			sum((case when bettype = 33 then bm.WLIBC else -(b.winlost -b.actual_stake)*isnull(b.oddsspread,0) end)) -- PTWLIBC,   
			- sum(case when cs.IBCFee = 0 then 0 else  
			(case when b.bettype = 33 then bm.TOPhum   
			when b.bettype in (31,32) then b.actual_stake*(1 -b.tpositiontaking - isnull(oddsspread,0)) else 0 end)*cs.ToteFee end) -- FeeDue2 ,  
			+ sum((case bettype when 31 then b.actual_stake*cs.ToteCommWin*(1 - b.tpositiontaking - isnull(oddsspread,0))  
			when 32 then b.actual_stake*cs.ToteCommPlace*(1 - b.tpositiontaking - isnull(oddsspread,0))  
			when 33 then bm.TOPhum*cs.ToteCommWP   
			else 0 end))-- commIncomeIBC  
			) Winloss,  
			SUM(scomm) Commission
			--(ISNULL(cii.VirtualMultiplier,1)-1)*100 VirtualRate
		FROM bettrans b with (nolock)  
			INNER JOIN @CommSetting as cs ON b.matchid = cs.matchid 
			--INNER JOIN custinfo cii WITH(NOLOCK) ON b.srecommend = cii.custid   
			LEFT JOIN ( select refno,
							sum(case when bettype = 32 and liveawayscore = 0 then 0 else stake*isnull(oddsspread,0) end) TOIBC,      
							-sum((winlost - stake)*isnull(oddsspread,0)) WLIBC,  
							sum(case when bettype = 32 and liveawayscore = 0 then 0 when bettype = 31 or (bettype = 32 and liveawayscore<>0) then stake*(1 -tpositiontaking - isnull(oddsspread,0)) else 0 end) TOPhum  
						from bettransm with (nolock)  
						group by refno  
					)bm on b.transid = bm.refno   
		WHERE b.ruben =1   
			and b.bettype in (SELECT bettype FROM @SportBettype WHERE ProductID = 2)  
			and b.matchid >0  
			and b.winlostdate BETWEEN @FromDate AND @ToDate
			and b.statusID not in (101,102,103,121) 
			and b.currency = @currency 
		GROUP BY b.srecommend,
			--cii.username,
			b.actualrate
			--cii.VirtualMultiplier
		
		INSERT INTO #TmpResultAll
		SELECT srecommend,
			--username, 
			0 virtualratetype,
			SUM(Turnover), 
			SUM(Winloss),
			SUM(Commission),
			SUM(Winloss+Commission) Total,
			SUM(Turnover*actualrate) TurnoverIBCRM,
			SUM(Turnover*actualrate) VirtualTurnoverIBC,
			SUM( (Winloss+Commission)*actualrate ) TotalRM,
			SUM( (Winloss+Commission)*actualrate ) Virtual_Total 
			--virtualrate
			
		FROM #TmpResult
		GROUP BY srecommend
				--username,
				--virtualrate
	
	END
	
---get result for PORKER	
	IF @showP2P = 1  
	BEGIN
		
		TRUNCATE TABLE #TmpResult
		
		INSERT INTO	#TmpResult
		SELECT b.srecommend,
			--cs.username,
			b.actualrate,
			0 Turnover,
			ISNULL(SUM(-1*(odds)),0)  Winlost,   
			SUM(scomm) commission
			--(ISNULL(cs.VirtualMultiplier,0)-1)*100 virtualrate		
		FROM bettrans b with (nolock)  
			INNER JOIN custinfo cs WITH(NOLOCK) ON b.srecommend = cs.custid   
		where b.bettype IN( SELECT bettype FROM @SportBettype WHERE ProductID = 9)
			and b.matchid = 1000   
			and b.ruben=1    
			and b.winlostdate BETWEEN @FromDate AND @ToDate
			and statusID NOT in (101,102,103,121)  
			and b.currency = @currency 
		GROUP BY b.srecommend,
				--cs.username,
				b.actualrate
				--cs.VirtualMultiplier
		
		
		INSERT INTO #TmpResultAll
		SELECT srecommend,
			--username,  
			0 AS VirtualRateType,
			0  Turnover, 
			SUM(Winloss),
			SUM(Commission),
			SUM(Winloss+Commission) Total,
			0 TurnoverRM,
			0 VirtualTurnoverRM,
			SUM( (Winloss+Commission)*actualrate ) TotalRM,
			SUM( (Winloss+Commission)*actualrate ) Virtual_Total 
			--virtualrate
		FROM #TmpResult
		GROUP BY srecommend--,username--,virtualrate
	END
------------------------------


INSERT INTO #TmpResultAll
SELECT b.srecommend,
	--cs.username,
	CASE WHEN t.isVirtual = 0 THEN 0 ELSE CASE WHEN b.virtualrate-b.actualrate < 0 THEN -1 WHEN b.virtualrate-b.actualrate > 0 THEN 1 ELSE 0 END END VirtualRateType,  
	SUM(ABS(CASE WHEN b.bettype in(71,73) then 0 ELSE stake END )*(1 - tpositiontaking)) Turnover,
	SUM(swinlost + mwinlost + awinlost + winlost-actual_stake) Winloss,
	SUM(scomm) commission,  
	SUM(swinlost + mwinlost + awinlost + winlost-actual_stake+scomm) total, 
	SUM(ABS( CASE WHEN b.bettype in(71,73) then 0 ELSE stake END )*(1 - tpositiontaking)*actualrate) TurnoverRM,
	SUM(ABS( CASE WHEN b.bettype in(71,73) then 0 ELSE stake END )*(1 - tpositiontaking)*(CASE WHEN t.isvirtual = 1 THEN b.virtualrate ELSE actualrate END)) TurnoverIBCVirtual,
	SUM((swinlost + mwinlost + awinlost + winlost-actual_stake+scomm)*actualrate)  TotalRM	,
	SUM((swinlost + mwinlost + awinlost + winlost-actual_stake+scomm)*(CASE WHEN t.isvirtual = 1 THEN b.virtualrate ELSE actualrate END)) Virtual_Total
	--(ISNULL(cs.virtualmultiplier,1)-1)*100 virtualrate
FROM bettrans b WITH(NOLOCK) 
	INNER JOIN @TmpCondBettype t ON t.bettype = b.bettype 
	--INNER JOIN custinfo cs WITH(NOLOCK) ON b.srecommend = cs.custid
WHERE winlostdate BETWEEN @FromDate AND @ToDate
   and b.ruben = 1  
   AND b.statusID NOT IN (101, 102, 103)   
   and b.currency = @currency
GROUP BY b.srecommend ,
		--cs.username,
		--cs.virtualmultiplier,
		CASE WHEN t.isVirtual = 0 THEN 0 ELSE CASE WHEN b.virtualrate-b.actualrate < 0 THEN -1 WHEN b.virtualrate-b.actualrate > 0 THEN 1 ELSE 0 END END   

SELECT b.srecommend,
	cs.UserName,
	SUM(Turnover) Turnover,
	SUM(Winloss) Winloss, 
	SUM(Commission) Commission, 
	SUM(total) total,
	SUM(TurnoverRM) TurnoverRM,
	SUM(TurnoverIBCVirtual) Virtual_Turnover,
	SUM(TotalRM) TotalRM,
	SUM(Virtual_Total) Virtual_Total,
	SUM(CASE WHEN virtualratetype=1 THEN totalrm-virtual_total ELSE 0 END) [WLVariance+],
	SUM(CASE WHEN virtualratetype=-1 THEN totalrm-virtual_total ELSE 0 END) [WLVariance-],
	SUM(CASE WHEN virtualratetype=1 THEN TurnoverRM-TurnoverIBCVirtual ELSE 0 END) [TOVariance+],
	SUM(CASE WHEN virtualratetype=-1 THEN TurnoverRM-TurnoverIBCVirtual ELSE 0 END) [TOVariance-],
	ISNULL(cs.virtualmultiplier,1) EnableVirtualrate
FROM #TmpResultAll b
INNER JOIN custinfo cs WITH(NOLOCK) ON b.srecommend = cs.custid
GROUP BY b.srecommend,ISNULL(cs.virtualmultiplier,1),cs.username
ORDER BY username	

SELECT cs.username
		,vr.custid
		,vr.sporttype
		,vr.bettype
		,vr.islive
		,vr.virtualMultiplier
FROM custinfo cs WITH(NOLOCK) 
	INNER JOIN CustVirtualRate vr WITH(NOLOCK) ON cs.custid = vr.custid
WHERE cs.custid IN (SELECT DISTINCT srecommend FROM #TmpResultAll)
	AND cs.virtualMultiplier = 1
ORDER BY username,sporttype,islive DESC, bettype

DROP TABLE #TmpResult
DROP TABLE #TmpResultAll


--END

/*

[Acc_Rpt_TreeWinlostByProduct_xtest]
	@FromDate   ='20130618',
	@ToDate   ='20160630',

	@showSB =1,
	@showNG =1,
	@ShowRB =1,
	@showLiveCasino = 1,
	@showCasino =1,
	@showP2P =1,
	@showBI =1,
	@showVS = 1,
	@ShowKeno = 1

[Acc_Rpt_TreeWinlostByCom_xtest]
	@FromDate   = '20130618',
	@ToDate   = '20160630',  
	@currency =1,	
	
	@showSB =1,  
	@showNG =1,  
	@ShowRB =1,  
	@showLiveCasino = 1,  
	@showCasino =1,  
	@showP2P =1,  
	@showBI =1,  
	@showVS = 1,
	@ShowKeno = 1


 
 */
GO 
 GRANT EXECUTE ON [dbo].[Acc_Rpt_TreeWinlostByCom] TO [bodbAdminNet]
GO 
 GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_TreeWinlostByCom] TO [vnteam]
GO 