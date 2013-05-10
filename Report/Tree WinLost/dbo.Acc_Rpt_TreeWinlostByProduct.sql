ALTER PROCEDURE [dbo].[Acc_Rpt_TreeWinlostByProduct]  
 @winlostdate   DATETIME,    
   
 @showSB BIT=1,    
 @showNG BIT=0,    
 @ShowRB BIT=0,    
 @showLiveCasino BIT = 0,    
 @showCasino BIT=0,    
 @showP2P BIT=0,    
 @showBI BIT=0,    
 @showVS BIT = 0,  
   
 @MoveBetDays SMALLDATETIME,  
  
 @Total_8RM   MONEY = 0 OUTPUT,    
 @VirtualTotal_8RM  MONEY = 0 OUTPUT,    
 @Variance_8RM  MONEY = 0 OUTPUT,    
 @Total_BARM   MONEY = 0 OUTPUT,    
 @VirtualTotal_BARM  MONEY = 0 OUTPUT,    
 @Variance_BARM  MONEY = 0 OUTPUT   
  
AS  
  
/*    
Created by: Scott    
Date: 2012-12-14   
Task : Report Tree Win Lost    
DB: DB06.bodb02    
Original SP:     
Revisions:    
	-20130115@Scott : fix bug sum total of poker sporttype
	-20130122@Scott : Does not use #bettrans14,query data direct bettrans14
	-20130418@Scott : Update formula turnover of Racing
	
*/    
  
  
SET NOCOUNT ON  
  
DECLARE @TmpCondBettype TABLE(bettype INT , isVirtual BIT)   
DECLARE @tmpIBCFee TABLE(partnerID int,IBCFee bit)  
--DECLARE #TmpResult TABLE (Currency TINYINT,actualrate FLOAT,Turnover MONEY, Winloss MONEY,Commission MONEY)
--DECLARE #TmpResultAll TABLE (Currency TINYINT,Turnover MONEY, Winloss MONEY,Commission MONEY,Total MONEY,TurnoverRM MONEY,TotalRM MONEY,Virtual_Total MONEY,Variance MONEY)
DECLARE @CommSetting TABLE (MatchID int, IBCFee bit, ToteCommWin smallmoney, ToteCommPlace smallmoney, ToteCommWP smallmoney, ToteFee smallmoney )

CREATE TABLE #TmpResult (Currency TINYINT,actualrate FLOAT,Turnover MONEY, Winloss MONEY,Commission MONEY)
CREATE TABLE #TmpResultAll (Currency TINYINT,Turnover MONEY, Winloss MONEY,Commission MONEY,Total MONEY,TurnoverRM MONEY,TotalRM MONEY,Virtual_Total MONEY,Variance MONEY)   


    
IF @ShowSB = 1    
 INSERT INTO @TmpCondBettype(Bettype,isVirtual)   
 SELECT typeid, 1   
 FROM bettype   
 WHERE typeid < 31 OR   
   typeid BETWEEN 121 AND 999 OR   
   typeid BETWEEN 1301 AND 1334;  
  
IF @ShowNG = 1    
 INSERT INTO @TmpCondBettype(Bettype,isVirtual)   
 SELECT typeid, 1   
 FROM bettype   
 WHERE typeid BETWEEN 81 AND 120;  

IF @showLiveCasino = 1  
 INSERT INTO @TmpCondBettype(Bettype,isVirtual)   
 SELECT typeid, 0   
 FROM bettype   
 WHERE typeid BETWEEN 1101 AND 1199;  
  
IF @showCasino = 1  
 INSERT INTO @TmpCondBettype(Bettype,isVirtual)   
 SELECT typeid, 0   
 FROM bettype   
 WHERE typeid = 71  

IF @showBI = 1  
 INSERT INTO @TmpCondBettype(Bettype,isVirtual)   
 SELECT typeid, 0   
 FROM bettype   
 WHERE typeid = 73  
   
IF @showVS = 1  
 INSERT INTO @TmpCondBettype(Bettype,isVirtual)   
 SELECT typeid, 0   
 FROM bettype   
 WHERE typeid BETWEEN 1201 AND 1299;  


IF @winlostdate > @MoveBetDays  
BEGIN  

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
		SELECT 101,1 --GREY-DTOTEUK  
		UNION ALL  
		SELECT 102,1 --GREY-DTOTEIRL  
		UNION ALL  
		SELECT 103,1 --GREY-TABCORP  
		UNION ALL  
		SELECT 201,1 --HAR-TABCORP  

		INSERT INTO @CommSetting (MatchID, IBCFee, ToteCommWin, ToteCommPlace, ToteCommWP, ToteFee)  
		SELECT DISTINCT o.orid as matchid, t.IBCFee, p.ToteCommWin, p.ToteCommPlace, (p.ToteCommWin + p.ToteCommPlace)/2 ToteCommWP, p.ToteFee   
		FROM outright o WITH (NOLOCK)  
			INNER JOIN LeagueDetail p WITH (NOLOCK) ON o.leagueID = p.leagueID and p.programDate = o.programDate  
			INNER JOIN RacingMeeting r WITH(NOLOCK) ON r.meetingID = p.leagueid  
			INNER JOIN @tmpIBCFee t ON r.partnerID = t.partnerID  
		WHERE o.eventdate = @winlostdate  
		
		INSERT INTO #TmpResult
		SELECT b.currency,b.actualrate,  
			-- SUM(ABS(stake)*(1 - tpositiontaking)) Turnover,  
			sum(case when bettype = 33 then bm.TOIBC*b.actualrate else b.actual_stake*isnull(oddsspread,0)*b.actualrate end) Turnover,
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
		FROM bettrans b with (nolock)  
			INNER JOIN @CommSetting as cs ON b.matchid = cs.matchid    
			LEFT JOIN ( select refno,
							sum(case when bettype = 32 and liveawayscore = 0 then 0 else stake*isnull(oddsspread,0) end) TOIBC,  
							-sum((winlost - stake)*isnull(oddsspread,0)) WLIBC,  
							sum(case when bettype = 32 and liveawayscore = 0 then 0 when bettype = 31 or (bettype = 32 and liveawayscore<>0) then stake*(1 -tpositiontaking - isnull(oddsspread,0)) else 0 end) TOPhum  
						from bettransm with (nolock)  
						group by refno  
					)bm on b.transid = bm.refno   
		WHERE b.ruben =1   
			and b.bettype in (31,32,33)  
			and b.matchid >0  
			and b.winlostdate = @winlostdate  			
			and b.statusID not in (101,102,103,121)  
		GROUP BY b.currency,b.actualrate
 
 
		INSERT INTO #TmpResultAll
		SELECT Currency, SUM(Turnover), SUM(Winloss),SUM(Commission),
			SUM(Winloss+Commission) Total,
			SUM(Turnover*actualrate) TurnoverRM,
			SUM( (Winloss+Commission)*actualrate ) TotalRM,
			SUM( (Winloss+Commission)*actualrate ) Virtual_Total ,
			0 Variance
		FROM #TmpResult
		GROUP BY Currency
	
	END
---get result for PORKER	
	IF @showP2P = 1  
	BEGIN
		
		delete #TmpResult
		
		INSERT INTO	#TmpResult
		SELECT b.currency,b.actualrate,
			0 Turnover,
			isnull(sum(-1*(odds)),0)  Winlost,   
			SUM(scomm) commission
		from bettrans b with (nolock)  
		where b.bettype = 1000  
			and b.matchid = 1000   
			and b.ruben=1    
			and b.winlostdate = @winlostdate     
			and statusID NOT in (101,102,103,121)  
		group by  b.currency,b.actualrate
		
		
		INSERT INTO #TmpResultAll
		SELECT Currency, 0  Turnover, SUM(Winloss),SUM(Commission),
			SUM(Winloss+Commission) Total,
			SUM(Turnover*actualrate) TurnoverRM,
			SUM( (Winloss+Commission)*actualrate ) TotalRM,
			SUM( (Winloss+Commission)*actualrate ) Virtual_Total ,
			0 Variance
		FROM #TmpResult
		GROUP BY Currency	
	END
------------------------------

	INSERT INTO #TmpResultAll  
	SELECT b.currency,  
		-- SUM(ABS(stake)*(1 - tpositiontaking)) Turnover,  
		SUM(ABS(CASE WHEN b.bettype in(71,73) then 0 ELSE stake END )*(1 - tpositiontaking)) Turnover,
		SUM(swinlost + mwinlost + awinlost + winlost-actual_stake) Winloss,  
		SUM(scomm) commission,    
		SUM(swinlost + mwinlost + awinlost + winlost-actual_stake+scomm) total,   
		SUM(ABS(stake)*(1 - tpositiontaking)*actualrate) TurnoverRM,  
		SUM((swinlost + mwinlost + awinlost + winlost-actual_stake+scomm)*actualrate)  TotalRM ,  
		SUM((swinlost + mwinlost + awinlost + winlost-actual_stake+scomm)*(CASE WHEN t.isvirtual = 1 THEN b.virtualrate ELSE actualrate END)) Virtual_Total,  
		(SUM((swinlost + mwinlost + awinlost + winlost-actual_stake+scomm)*actualrate))-  
		(SUM((swinlost + mwinlost + awinlost + winlost-actual_stake+scomm)*(CASE WHEN t.isvirtual = 1 THEN b.virtualrate ELSE actualrate END))) variance  
	FROM bettrans b WITH(NOLOCK)   
		INNER JOIN @TmpCondBettype t on t.bettype = b.bettype   
	WHERE winlostdate = @winlostdate  
		AND b.ruben = 1    
		AND b.statusID NOT IN (101, 102, 103,121)     
	GROUP BY b.currency    


	SELECT	@Total_8RM = -SUM((swinlost + mwinlost + awinlost + winlost-actual_stake+scomm)*actualrate),    
			@VirtualTotal_8RM = -SUM((swinlost + mwinlost + awinlost + winlost-actual_stake+scomm)*(CASE WHEN t.isvirtual = 1 THEN b.virtualrate ELSE actualrate END)),  
			@Variance_8RM=@Total_8RM-@VirtualTotal_8RM  
	FROM bettrans b WITH(NOLOCK)    
		INNER JOIN @TmpCondBettype t on t.bettype = b.bettype   
	WHERE recommend = 52466 AND    
		ruben=1 AND    
		winlostdate = @winlostdate   AND   
		b.statusID NOT IN (101, 102, 103,121)  

	SELECT	@Total_BARM = -SUM((swinlost + mwinlost + awinlost + winlost-actual_stake+scomm)*actualrate),    
			@VirtualTotal_BARM = -SUM((swinlost + mwinlost + awinlost + winlost-actual_stake+scomm)*(CASE WHEN t.isvirtual = 1 THEN b.virtualrate ELSE actualrate END)),  
			@Variance_BARM=@Total_BARM-@VirtualTotal_BARM  
	FROM bettrans b WITH(NOLOCK)   
		INNER JOIN @TmpCondBettype t on t.bettype = b.bettype   
	WHERE recommend = 5707545 AND    
		ruben=1 AND    
		winlostdate = @winlostdate  AND  
		b.statusID NOT IN (101, 102, 103,121)  
		
---resultset

	SELECT currency, SUM(Turnover) Turnover,SUM(Winloss) Winloss, SUM(Commission) Commission, SUM(total) total,
		SUM(TurnoverRM) TurnoverRM,SUM (TotalRM) TotalRM,SUM(Virtual_Total) Virtual_Total,SUM(variance) variance
	FROM #TmpResultAll
	GROUP BY currency


    
END  
  
  
IF @winlostdate <= @MoveBetDays  
BEGIN


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
		SELECT 101,1 --GREY-DTOTEUK  
		UNION ALL  
		SELECT 102,1 --GREY-DTOTEIRL  
		UNION ALL  
		SELECT 103,1 --GREY-TABCORP  
		UNION ALL  
		SELECT 201,1 --HAR-TABCORP  

		INSERT INTO @CommSetting (MatchID, IBCFee, ToteCommWin, ToteCommPlace, ToteCommWP, ToteFee)  
		SELECT DISTINCT o.orid as matchid, t.IBCFee, p.ToteCommWin, p.ToteCommPlace, (p.ToteCommWin + p.ToteCommPlace)/2 ToteCommWP, p.ToteFee   
		FROM outright14 o WITH (NOLOCK)  
			INNER JOIN LeagueDetail p WITH (NOLOCK) ON o.leagueID = p.leagueID and p.programDate = o.programDate  
			INNER JOIN RacingMeeting r WITH(NOLOCK) ON r.meetingID = p.leagueid  
			INNER JOIN @tmpIBCFee t ON r.partnerID = t.partnerID  
		WHERE o.eventdate = @winlostdate  
		
		INSERT INTO #TmpResult
		SELECT b.currency,b.actualrate,  
			-- SUM(ABS(stake)*(1 - tpositiontaking)) Turnover,  
			sum(case when bettype = 33 then bm.TOIBC*b.actualrate else b.actual_stake*isnull(oddsspread,0)*b.actualrate end) Turnover,
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
		FROM bettrans14 b with (nolock)  
			INNER JOIN @CommSetting as cs ON b.matchid = cs.matchid    
			LEFT JOIN ( select refno,
							sum(case when bettype = 32 and liveawayscore = 0 then 0 else stake*isnull(oddsspread,0) end) TOIBC,  
							-sum((winlost - stake)*isnull(oddsspread,0)) WLIBC,  
							sum(case when bettype = 32 and liveawayscore = 0 then 0 when bettype = 31 or (bettype = 32 and liveawayscore<>0) then stake*(1 -tpositiontaking - isnull(oddsspread,0)) else 0 end) TOPhum  
						from bettransm14 with (nolock)  
						group by refno  
					)bm on b.transid = bm.refno   
		WHERE b.ruben =1   
			and b.bettype in (31,32,33)  
			and b.matchid >0  
			and b.winlostdate = @winlostdate  			
			and b.statusID not in (101,102,103,121)  
		GROUP BY b.currency,b.actualrate
 
 
		INSERT INTO #TmpResultAll
		SELECT Currency, SUM(Turnover), SUM(Winloss),SUM(Commission),
			SUM(Winloss+Commission) Total,
			SUM(Turnover*actualrate) TurnoverRM,
			SUM( (Winloss+Commission)*actualrate ) TotalRM,
			SUM( (Winloss+Commission)*actualrate ) Virtual_Total ,
			0 Variance
		FROM #TmpResult
		GROUP BY Currency
	
	END
---get result for PORKER	
	IF @showP2P = 1  
	BEGIN
		
		delete #TmpResult
		
		INSERT INTO	#TmpResult
		SELECT b.currency,b.actualrate,
			0 Turnover,
			isnull(sum(-1*(odds)),0)  Winlost,   
			SUM(scomm) commission
		from bettrans14 b with (nolock)  
		where b.bettype = 1000  
			and b.matchid = 1000   
			and b.ruben=1    
			and b.winlostdate = @winlostdate     
			and statusID NOT in (101,102,103,121)  
		group by  b.currency,b.actualrate
		
		
		INSERT INTO #TmpResultAll
		SELECT Currency, 0  Turnover, SUM(Winloss),SUM(Commission),
			SUM(Winloss+Commission) Total,
			SUM(Turnover*actualrate) TurnoverRM,
			SUM( (Winloss+Commission)*actualrate ) TotalRM,
			SUM( (Winloss+Commission)*actualrate ) Virtual_Total ,
			0 Variance
		FROM #TmpResult
		GROUP BY Currency	
	END
------------------------------
  
INSERT INTO #TmpResultAll   
SELECT b.currency,  
 --SUM(ABS(stake)*(1 - tpositiontaking)) Turnover,  
 SUM(ABS(CASE WHEN b.bettype in(71,73) then 0 ELSE stake END )*(1 - tpositiontaking)) Turnover,
 SUM(swinlost + mwinlost + awinlost + winlost-actual_stake) Winloss,  
 SUM(scomm) commission,    
 SUM(swinlost + mwinlost + awinlost + winlost-actual_stake+scomm) total,   
 SUM(ABS(stake)*(1 - tpositiontaking)*actualrate) TurnoverRM,  
 SUM((swinlost + mwinlost + awinlost + winlost-actual_stake+scomm)*actualrate)  TotalRM ,  
 SUM((swinlost + mwinlost + awinlost + winlost-actual_stake+scomm)*(CASE WHEN t.isvirtual = 1 THEN b.virtualrate ELSE actualrate END)) Virtual_Total,  
 (SUM((swinlost + mwinlost + awinlost + winlost-actual_stake+scomm)*actualrate))-  
  (SUM((swinlost + mwinlost + awinlost + winlost-actual_stake+scomm)*(CASE WHEN t.isvirtual = 1 THEN b.virtualrate ELSE actualrate END))) variance  
FROM bettrans14 b WITH(NOLOCK)   
 INNER JOIN @TmpCondBettype t on t.bettype = b.bettype   
WHERE winlostdate =@winlostdate   
   AND b.ruben = 1    
   AND b.statusID NOT IN (101, 102, 103)     
 GROUP BY b.currency    
  
  
SELECT @Total_8RM = -SUM((swinlost + mwinlost + awinlost + winlost-actual_stake+scomm)*actualrate),    
  @VirtualTotal_8RM = -SUM((swinlost + mwinlost + awinlost + winlost-actual_stake+scomm)*(CASE WHEN t.isvirtual = 1 THEN b.virtualrate ELSE actualrate END)),  
  @Variance_8RM=@Total_8RM-@VirtualTotal_8RM  
FROM bettrans14 b WITH(NOLOCK)    
 INNER JOIN @TmpCondBettype t on t.bettype = b.bettype   
WHERE recommend = 52466 AND    
  ruben=1 AND    
  winlostdate = @winlostdate   AND   
  b.statusID NOT IN (101, 102, 103)  
    
SELECT @Total_BARM = -SUM((swinlost + mwinlost + awinlost + winlost-actual_stake+scomm)*actualrate),    
  @VirtualTotal_BARM = -SUM((swinlost + mwinlost + awinlost + winlost-actual_stake+scomm)*(CASE WHEN t.isvirtual = 1 THEN b.virtualrate ELSE actualrate END)),  
  @Variance_BARM=@Total_BARM-@VirtualTotal_BARM  
FROM bettrans14 b WITH(NOLOCK)   INNER JOIN @TmpCondBettype t on t.bettype = b.bettype   
WHERE recommend = 5707545 AND    
  ruben=1 AND    
  winlostdate = @winlostdate  AND  
    b.statusID NOT IN (101, 102, 103)  
    
    
    ---resultset

	SELECT currency, SUM(Turnover) Turnover,SUM(Winloss) Winloss, SUM(Commission) Commission, SUM(total) total,
		SUM(TurnoverRM) TurnoverRM,SUM (TotalRM) TotalRM,SUM(Virtual_Total) Virtual_Total,SUM(variance) variance
	FROM #TmpResultAll
	GROUP BY currency
	
	
END   

GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_TreeWinlostByProduct] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_TreeWinlostByProduct] TO [vnteam] AS [dbo]