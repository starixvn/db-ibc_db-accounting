CREATE PROCEDURE [dbo].[Acc_Rpt_DailyWLDirect_Sporttype14]
	@winlostdate	datetime,
	@LineTotal		money OUTPUT
AS
/*	Creator: Phuong Dao
	Date: 2009-03-03
	Task: Daily Report History 
	DB: DBACC/bodb02	
		
	History:
		- 20090514@PhuongDao: Winlost for Casino
		- 20090608@PhuongDao: PT Winlost Tote HR 
		- 20090722@Kiwi: Improve HR peformance by using table variable
		- 20090731@Jamie: Not to view data in range of date, but only one date at once 
		- 20090815@Jamie: Include Fixed Odds HR
		- 20091109@Kiwi: Declare @temp table to contain all matches based on @winlostdate
		- 20100331@Jamie: arrange the new structure for HR meetings 
			+ Remove hard-code FeeDue2 
			+ Remove Fixed Odds out as well
		-- 20100525@Henry: Change to use StatusID instead of Status in WHERE statement	
		- 20100611@Henry: Change mix-parlay match from 0 to 9
		- 20100916@Henry: Include Bingo + Number Game
		- 20101204@Johnson: Separate Number Game from Other Sports
		- 20110314@Johnson:- change Horse Racing to Racing
						   - Check Tote Fee is passed to Partners or not
						   - Remove Finance report
		- 20110516@Lukas: re-arrange bettype
		- 20110701@Johnson: change the programdate in LeagueDetail is the programdate in OutRight
		- 20110801@Johnson: - add new bettype system parlay
							- add more bettype for number game Warrior, Next Combo, Number Group
		- 20110824@Johnson: - remove check winlostdate with '16 Dec 2010' for sumary turnover, get from stake instead actual_stake
		- 20110824@Elly: - Correct Turnover of sports book since Sep 01, 2011
		- 20110930@Tom: 1. Add Report for P2P Games  Bettype: 1000	
						2. Hide code Report Casino and Bingo
		- 20110930@Tom: Unhide code Report Casino and Bingo
		- 20111202@Sophia: . Add new range for sportbook from 121 to 999
						   . Remove @NegativeBetEffectiveDate
		- 20120231@Sophia: Add live casino bettype from 1101 to 1199
		- 20120210@Henry: Fix system parlay turnover bug
		- 20120405@Hurri: Exclude bettype 72 (P2P bet ticket) in the calculation of Casino
		- 20120412@Hurri: Get win lost of agent 'BARM' (@WinLost_BARM)
		- 20120503@Sophia: Edit LineTotal and Comm for P2P
		- 20120514@Elodie:  Correct win lost of agent 'BARM'
		- 20120530@Elodie: Change formula of 8RM/BARM winloss
		- 20120628@Elodie: check case of matchid = orid
		- 20120814@Elodie: Add Virtual sports report
		- 20120920@Elodie: Add DisplayOrder field
		- 20121009@Elodie: Add 34 new bettypes of Tennis (1301 -> 1334)
		- 20121015@Elodie: Add EnableVirtual field, arrange the order of products to separate 2h report into 2 sections: 
								+ Section 1: all products that disable virtual currency 
								+ Section 2: all products that enable virtual currency 
		- 20121018@Lukas: use temp table to enhance performance
		- 20121102@Elodie: Use actual rate instead of virtural rate for Virtual sport	]
		- 20130408@Elodie: Add RealLineTotal field for all products that enable virtual currency
		- 20130522@Elodie: Get more fields RealTurnover, VirtualTurnover
		- 20130618@Johnson: Add NSW racing's pools from AUST
		- 20130703@Kathy: Update matchid for RnG Casino (71) and Bingo (73)
		- 20130717@Kathy: Apply Progressive Bonus: add bettype 72 for Casino
		- 20130801@Johnson: Separate win loss by credit/deposit site(1: credit, 2: deposit)		
		- 20130910@Johnson: get virtual values for all products	
		- 20140303@Dom: Add Keno
	Explanation's Param:
		- @FI_3rdShare: winloss of Third party 
		- @WinLost_BARM: winlost for outsource (We use agent 'BARM' to put all outsoucing transactions which follow BA danger customers)
		- DisplayOrder field:	1 -> 100: all products that enable virtual currency 
								101 -> 200: all products that disable virtual currency
		

*/
BEGIN
	SET NOCOUNT ON

	DECLARE @P2P_LineTotal  money			
	DECLARE @RBWinlost TABLE(site tinyint,
							winlost money,
							pos money,
							comm money,
							linetotal money,							
							turnover money
						)		
						
	CREATE TABLE #src(	
					matchid INT, 
					bettype INT, 
					site	TINYINT,
					winlost_actualrate MONEY, 
					winlost_virtualrate MONEY,
					position_actualrate MONEY, 
					position_virtualrate MONEY, 
					commission_actualrate MONEY, 
					commission_virtualrate MONEY, 
					Linetotal_actualrate MONEY,
					Linetotal_virtualrate MONEY,
					turnover_actualrate MONEY,
					turnover_virtualrate MONEY
				)

	CREATE TABLE #DepAgent (custid int primary key)
	----------------------------------------------------------------------

	--insert company's comm setting that is recieved from Phumelela into this temp table.

	DECLARE @tmpIBCFee TABLE(partnerID int,IBCFee bit)

	DECLARE @CommSetting TABLE
	(	MatchID			int,
		IBCFee			bit,
		ToteCommWin		smallmoney,
		ToteCommPlace	smallmoney,
		ToteCommWP		smallmoney,
		ToteFee			smallmoney	
	)

	INSERT INTO #DepAgent 
	SELECT custid
	FROM custInfo with(NOLOCK)
	WHERE srecommend IN (SELECT custid FROM f_DepSuper_1('All'))
		AND roleid = 2
	UNION
	SELECT 5707545--BARM

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
	SELECT	DISTINCT o.orid as matchid, t.IBCFee, p.ToteCommWin, p.ToteCommPlace, (p.ToteCommWin + p.ToteCommPlace)/2 ToteCommWP, p.ToteFee 
	FROM	outright14 o WITH (NOLOCK)
			INNER JOIN LeagueDetail p WITH (NOLOCK) ON o.leagueID = p.leagueID AND p.programDate = o.programDate
			INNER JOIN RacingMeeting r WITH(NOLOCK) ON p.leagueid = r.meetingid
			INNER JOIN @tmpIBCFee t ON r.partnerID = t.partnerID 
	WHERE	o.eventdate = @winlostdate 


	/*SELECT	@FI_3rdShare = ISNULL(sum((winlost-actual_stake)*b.actualrate),0)
	FROM	bettrans14  b WITH (NOLOCK)
	WHERE	b.ruben=1 and 
			--status NOT IN ('VOID', 'REJECT') 
			statusID NOT IN (101, 102) 
			and b.winlostdate = @winlostdate and
			b.bettype between 51 and 66 and 
			b.matchid > 0 and 
			b.custid in (SELECT custid FROM customer c with (nolock) 
											INNER JOIN exchange e with (nolock) on c.currency = e.exchangeid 
									   WHERE c.username ='FI3rdShare'+ e.currency)*/

	----------------------------------------------------------------------
	INSERT INTO @RBWinlost (site, winlost, pos, comm, Linetotal, turnover)
	SELECT	case when dep.custid is null then 1 else 2 end as site,
		sum((b.winlost -b.actual_stake)*b.actualrate) as winlost,
		sum((b.awinlost + b.mwinlost + b.swinlost)*b.actualrate) as pos,
		sum(b.scomm*b.actualrate) as comm,
		-(sum((case when bettype = 33 then bm.WLIBC else -(b.winlost -b.actual_stake)*isnull(b.oddsspread,0) end)*b.actualrate) 
								- sum(case when cs.IBCFee = 0 then 0 else (case when b.bettype = 33 then bm.TOPhum when bettype in (31,32) then b.actual_stake*(1 -b.tpositiontaking - isnull(b.oddsspread,0)) else 0 end)*b.actualrate*cs.ToteFee end) --FeeDue2 
								+ sum((case bettype when 31 then b.actual_stake*cs.ToteCommWin*(1 - b.tpositiontaking - isnull(oddsspread,0))
													when 32 then b.actual_stake*cs.ToteCommPlace*(1 - b.tpositiontaking - isnull(oddsspread,0))
													when 33 then bm.TOPhum*cs.ToteCommWP 
													else 0 end)*b.actualrate) --commIncomeIBC
								- sum(b.scomm*b.actualrate)) as realLinetotal,
		sum(case when bettype = 33 then bm.TOIBC*b.actualrate else b.actual_stake*isnull(oddsspread,0)*b.actualrate end) as turnover
			
	FROM	bettrans14 b with (nolock)
			INNER JOIN @CommSetting as cs ON b.matchid = cs.matchid  
			 left join (
				select	refno,
						sum(case when bettype = 32 and liveawayscore =0 then 0 else stake*isnull(oddsspread,0) end) TOIBC,
						-sum((winlost - stake)*isnull(oddsspread,0)) WLIBC,
						sum(case when bettype = 32 and liveawayscore = 0 then 0 when bettype = 31 or (bettype = 32 and liveawayscore <> 0) then stake*(1 -tpositiontaking - isnull(oddsspread,0)) else 0 end) TOPhum
				from	bettransm14 with (nolock)
				group by refno
			 )bm on b.transid = bm.refno
			 left join (select custid from #DepAgent) dep ON b.recommend = dep.custid 
	WHERE	b.ruben =1 
			and b.bettype in (31,32,33)
			and b.matchid >0
			and b.winlostdate = @winlostdate
			--and b.status not in ('VOID','REJECT','DONE','REFUND')	
			and b.statusID not in (101,102,103,121)
	GROUP BY case when dep.custid is null then 1 else 2 end
	---------------------------------------------------------------------------------------

	--Declare @temp table to contain all matches based on @winlostdate
	DECLARE @Match TABLE (matchid INT, sporttype smallint, type varchar(10), primary key(matchid, type))
	INSERT INTO @Match 
	SELECT	m.matchid, 
			s.sporttype,
			m.type
	FROM (
			SELECT matchid, leagueid, exrisk, matchcode, 'match' as type FROM match14 WITH (NOLOCK) WHERE eventdate = @winlostdate
			UNION ALL
			SELECT orid, leagueid, 0, matchcode, 'outright' as type FROM outright14 WITH (NOLOCK) WHERE eventdate = @winlostdate
			)m	
	INNER JOIN league l WITH (NOLOCK) ON m.leagueid = l.leagueid	
	INNER JOIN Sports s WITH (NOLOCK) ON l.sporttype = s.sporttype

	--------------------------------------------------------------------------------
	INSERT INTO #src
	SELECT	matchid, bettype,
			CASE WHEN dep.custid is null then 1 else 2 end as site, 
			SUM((winlost-actual_stake)*actualrate) winlost_actualrate,
			SUM((winlost-actual_stake)*virtualrate) winlost_virtualrate,
			SUM((awinlost+mwinlost+swinlost)* actualrate) position_actualrate,
			SUM((awinlost+mwinlost+swinlost)*virtualrate) position_virtualrate,	
			SUM(scomm*actualrate) commission_actualrate,
			SUM(scomm*virtualrate) commission_virtualrate,
			SUM((winlost-actual_stake+awinlost+mwinlost+swinlost+scomm)*actualrate) LineTotal_actualrate,
			SUM((winlost-actual_stake+awinlost+mwinlost+swinlost+scomm)*virtualrate) LineTotal_virtualrate,
			SUM((1-tpositiontaking)*ABS(stake)*actualrate) turnover_actualrate, -- don't need calculate actualrate for system parlay
			SUM((1-tpositiontaking)*ABS(CASE WHEN bettype = 29 AND betid > 0 THEN actual_stake ELSE stake END)*virtualrate) turnover_virtualrate
	FROM bettrans14 b WITH(NOLOCK)
		left join (select custid from #DepAgent) dep ON b.recommend = dep.custid 
	WHERE winlostdate = @winlostdate
		AND bettype < 19001
		AND b.statusID NOT IN (101,102,103,121) 
		AND b.ruben = 1	
	GROUP BY matchid, bettype, CASE WHEN dep.custid is null then 1 else 2 end 
	
	--Section 2: all products that enable virtual currency, DisplayOrder field:	1 -> 100
	SELECT
			case when m.sporttype> 1 THEN 2 ELSE 1 end as DisplayOrder,
			case when m.sporttype> 1 then 'Other Sports' else 'Soccer' end as SportName,
			case when m.sporttype> 1 then 2 else 1 end as SportType,			
			0 ibc,
			site,
			SUM(winLost_virtualrate) AS winlost,
			SUM(position_virtualrate) AS Position,
			sum(commission_virtualrate) AS Commission,	
			SUM(LineTotal_actualrate) AS RealLineTotal,
			SUM(Linetotal_virtualrate) AS VirtualLineTotal,
			SUM(turnover_actualrate) AS RealTurnover,
			SUM(turnover_virtualrate) AS VirtualTurnover,
			1 EnableVirtual
	FROM	#src b WITH(NOLOCK)
				INNER JOIN @Match m on b.matchid = m.matchid
	WHERE	(b.bettype < 31 
				OR b.bettype BETWEEN 121 AND 999
				OR bettype BETWEEN 1301 and 1334)	
			AND m.type = CASE WHEN b.bettype = 10 THEN 'outright' ELSE 'match' END -- 20120628@Elodie: check case of matchid = orid
	GROUP BY		
			case when m.sporttype> 1 THEN 2 ELSE 1 end,
			case when m.sporttype> 1 then 'Other Sports' else 'Soccer' end,
			case when m.sporttype> 1 then 2 else 1 end,
			site

	-- Get win lost of agent '8RM'
	UNION ALL
	SELECT
			case when m.sporttype> 1 THEN 2 ELSE 1 end as DisplayOrder,
			case when m.sporttype> 1 then 'Other Sports' else 'Soccer' end as SportName,
			case when m.sporttype> 1 then 2 else 1 end as SportType,	
			1 ibc,
			0 as site,
			-sum(winlost-actual_stake) WinLost,
			-sum(awinlost+mwinlost+swinlost) Position,
			sum(scomm) Commission,				
			-sum(winlost - actual_stake + awinlost + mwinlost + swinlost + scomm) RealLineTotal,
			-sum(winlost - actual_stake + awinlost + mwinlost + swinlost + scomm) VirtualLineTotal,
			-sum((1-tpositiontaking)*ABS(stake)) RealTurnover,
			-sum((1-tpositiontaking)*ABS(stake)) VirtualTurnover,
			0 EnableVirtual
	FROM	bettrans14 b WITH (NOLOCK)
			INNER JOIN @Match m on b.matchid = m.matchid
	WHERE	b.winlostdate = @winlostdate
			AND b.matchid > 0 
			AND b.bettype < 19001
			--AND b.status NOT IN ('VOID', 'REJECT','REFUND') 
			and b.statusID not in (101,102,103)	
			AND b.ruben = 1	
			AND b.recommend = 52466
			AND m.type = CASE WHEN b.bettype = 10 THEN 'outright' ELSE 'match' END -- 20120628@Elodie: check case of matchid = orid
	GROUP BY	
			case when m.sporttype> 1 THEN 2 ELSE 1 end,
			case when m.sporttype> 1 then 'Other Sports' else 'Soccer' end,
			case when m.sporttype> 1 then 2 else 1 end

	-- Get win lost of agent 'BARM'
	UNION ALL
	SELECT
			case when m.sporttype> 1 THEN 2 ELSE 1 end as DisplayOrder,
			case when m.sporttype> 1 then 'Other Sports' else 'Soccer' end as SportName,
			case when m.sporttype> 1 then 2 else 1 end as SportType,	
			2 ibc,
			0 as site,
			-sum(winlost-actual_stake) WinLost,
			-sum(awinlost+mwinlost+swinlost) Position,
			sum(scomm) Commission,	
			-sum(winlost - actual_stake + awinlost + mwinlost + swinlost + scomm) RealLineTotal,
			-sum(winlost - actual_stake + awinlost + mwinlost + swinlost + scomm) VirtualLineTotal,
			-sum((1-tpositiontaking)*ABS(stake)) RealTurnover,
			-sum((1-tpositiontaking)*ABS(stake)) VirtualTurnover,
			0 EnableVirtual
	FROM	bettrans14 b WITH (NOLOCK)
			INNER JOIN @Match m on b.matchid = m.matchid
	WHERE	b.winlostdate = @winlostdate
			AND b.matchid > 0 
			AND b.bettype < 19001
			--AND b.status NOT IN ('VOID', 'REJECT','REFUND') 
			and b.statusID not in (101,102,103)	
			AND b.ruben = 1	
			AND b.recommend = 5707545
			AND m.type = CASE WHEN b.bettype = 10 THEN 'outright' ELSE 'match' END -- 20120628@Elodie: check case of matchid = orid
	GROUP BY	
			case when m.sporttype> 1 THEN 2 ELSE 1 end,
			case when m.sporttype> 1 then 'Other Sports' else 'Soccer' end,
			case when m.sporttype> 1 then 2 else 1 end

	UNION ALL
	SELECT 
			3,'System Parlay', 98, 0,site,
			SUM(winlost_virtualrate) WinLost,
			SUM(position_virtualrate) Position,
			SUM(commission_virtualrate) Commission,	
			SUM(LineTotal_actualrate) AS RealLineTotal,
			SUM(Linetotal_virtualrate) AS VirtualLineTotal,	
			SUM(turnover_actualrate) RealTurnover,
			SUM(turnover_virtualrate) VirtualTurnover,
			1 EnableVirtual
	FROM	#src AS b WITH (NOLOCK)
	WHERE	bettype = 29 
			AND matchid = 29
	GROUP BY site
			
	UNION ALL
	SELECT 
			4,'Mix Parlay', 99, 0,site,
			SUM(winlost_virtualrate) WinLost,
			SUM(position_virtualrate) Position,
			SUM(commission_virtualrate) Commission,	
			SUM(LineTotal_actualrate) AS RealLineTotal,
			SUM(Linetotal_virtualrate) AS VirtualLineTotal,
			SUM(turnover_actualrate) RealTurnover,
			SUM(turnover_virtualrate) VirtualTurnover,
			1 EnableVirtual
	FROM	#src b WITH (NOLOCK)
	WHERE	bettype = 9 
			AND matchid = 9
	GROUP BY site
			
	----NUMBER GAME
	UNION ALL
	SELECT
			5,'Number Game', 161, 0, site,
			SUM(winlost_virtualrate) WinLost,
			SUM(position_virtualrate) Position,
			SUM(commission_virtualrate) Commission,	
			SUM(LineTotal_actualrate) AS RealLineTotal,
			SUM(Linetotal_virtualrate) AS VirtualLineTotal,
			SUM(turnover_actualrate) RealTurnover,
			SUM(turnover_virtualrate) VirtualTurnover,
			1 EnableVirtual
	FROM	#src b WITH (NOLOCK)			
	WHERE	b.bettype BETWEEN 81 AND 120
	GROUP BY site

	--------------------------------------------------------------------------------
	--Section 1: all products that disable virtual currency, DisplayOrder field: 101 -> 200

	UNION ALL --Racing
	SELECT	101,'Racing', 151, 0,site,
			Winlost,
			Pos Position,
			Comm Commission,
			LineTotal AS RealLineTotal,
			LineTotal AS VirtualLineTotal,
			turnover RealTurnover,
			0 VirtualTurnover,
			0 EnableVirtual
	FROM @RBWinlost

	---Live Casino
	UNION ALL
	SELECT
			102,'Live Casino',
			162,		
			0 ibc,--case recommend when 52466 then 1 else 0 end ibc,
			site,
			ISNULL(SUM(winlost_actualrate),0) WinLost,
			ISNULL(SUM(position_actualrate),0) Position,
			ISNULL(SUM(commission_actualrate),0) Commission,
			ISNULL(SUM(LineTotal_actualrate),0) AS RealLineTotal,
			ISNULL(SUM(LineTotal_virtualrate),0) AS VirtualLineTotal,
			SUM(turnover_actualrate) RealTurnover,
			SUM(turnover_virtualrate) VirtualTurnover,
			0 EnableVirtual
	FROM	#src b WITH (NOLOCK)
	WHERE	b.bettype BETWEEN 1101 AND 1199
			AND b.matchid > 0
	GROUP BY site

	----VIRTUAL SPORT
	UNION ALL
	SELECT
			103,'Virtual Sports', 180, 0, site,
			SUM(winlost_actualrate) WinLost,
			SUM(position_actualrate) Position,
			SUM(commission_actualrate) Commission,	
			SUM(LineTotal_actualrate) AS RealLineTotal,
			SUM(LineTotal_virtualrate) AS VirtualLineTotal,
			SUM(turnover_actualrate) RealTurnover,
			SUM(turnover_virtualrate) VirtualTurnover,
			0 EnableVirtual
	FROM	#src b WITH (NOLOCK)			
	WHERE	b.bettype BETWEEN 1201 AND 1299
	GROUP BY site

	----CASINO
	UNION ALL
	SELECT	104,'Casino', 251, 0,site,
			ISNULL(SUM(winlost_actualrate),0) WinLost,
			ISNULL(SUM(position_actualrate),0) Position,
			ISNULL(SUM(commission_actualrate),0) Commission,
			ISNULL(SUM(LineTotal_actualrate),0) AS RealLineTotal,
			ISNULL(SUM(LineTotal_virtualrate),0) AS VirtualLineTotal,
			0 RealTurnover,
			0 VirtualTurnover,
			0 EnableVirtual
	from	#src with (nolock)
	where 	bettype IN (71, 72)
			AND matchid IN (0, 71)
	group by site

	--P2P 
	UNION ALL
	SELECT	105,'P2P', 253, 0,
			case when dep.custid is null then 1 else 2 end as site,
			sum((winlost-actual_stake)*actualrate) WinLost,
			0 Position,
			sum(scomm *actualrate) Commission,	
			sum(-1*(odds-scomm)*actualrate) AS RealLineTotal,
			sum(-1*(odds-scomm)*virtualrate) AS VirtualLineTotal,
			0 RealTurnover,
			0 VirtualTurnover,
			0 EnableVirtual
	from	bettrans14 bettrans with (nolock)
		left join (select custid from #DepAgent) dep ON bettrans.recommend = dep.custid 
	where 	bettrans.bettype = 1000
			AND bettrans.matchid = 1000 
			and bettrans.ruben=1  
			and	bettrans.winlostdate = @winlostdate
			AND bettrans.statusID NOT IN (101, 102,103,121) 
	group by case when dep.custid is null then 1 else 2 end			
			
	--BINGO
	UNION ALL
	SELECT	106,'Bingo', 252, 0,site,
			ISNULL(SUM(winlost_actualrate),0) WinLost,
			ISNULL(SUM(position_actualrate),0) Position,
			ISNULL(SUM(commission_actualrate),0) Commission,
			ISNULL(SUM(LineTotal_actualrate),0) AS RealLineTotal,
			ISNULL(SUM(LineTotal_virtualrate),0) AS VirtualLineTotal,
			0 RealTurnover,
			0 VirtualTurnover,
			0 EnableVirtual
	from	#src with (nolock)
	where 	bettype = 73
			AND matchid IN (0, 73)	
	group by site

	----KENO
	UNION ALL
	SELECT
		107,'Keno', 202, 0, 
		ISNULL(A.site,'') [site],
		ISNULL(WinLost,0) WinLost,
		ISNULL(Position,0) Position,
		ISNULL(Commission,0) Commission,
		ISNULL(RealLineTotal,0) RealLineTotal,
		ISNULL(VirtualLineTotal,0) VirtualLineTotal,
		ISNULL(RealTurnover,0) RealTurnover,
		ISNULL(VirtualTurnover,0) VirtualTurnover,
		0 EnableVirtual
	FROM Sports(NOLOCK) s
	OUTER APPLY (
		SELECT
			site,
			SUM(ISNULL(b.winlost_actualrate,0)) WinLost,
			SUM(ISNULL(b.position_actualrate,0)) Position,
			SUM(ISNULL(b.commission_actualrate,0)) Commission,	
			SUM(ISNULL(LineTotal_actualrate,0)) AS RealLineTotal,
			SUM(ISNULL(LineTotal_actualrate,0)) AS VirtualLineTotal,
			SUM(ISNULL(turnover_actualrate,0)) RealTurnover,
			SUM(ISNULL(turnover_actualrate,0)) VirtualTurnover,
			0 EnableVirtual
		FROM	#src b WITH (NOLOCK)			
		WHERE	b.bettype BETWEEN 1501 AND 1599 
		GROUP BY site
	) A
	WHERE s.SportType = 202
	ORDER BY DisplayOrder asc, ibc, site
				
	SELECT	@LineTotal = ISNULL(SUM(LineTotal_actualrate), 0) 
	FROM	#src b WITH (NOLOCK)
	WHERE	bettype NOT IN (31,32,33,1000)	
			
	SELECT	@P2P_lineTotal = sum(-1*(odds-scomm)*actualrate) 
	FROM	bettrans14 bettrans with (nolock)
	WHERE 	bettrans.bettype = 1000
			AND bettrans.matchid = 1000 
			and bettrans.ruben=1  
			and	bettrans.winlostdate = @winlostdate
			AND bettrans.statusID NOT IN (101, 102,103,121) 

	SELECT	@LineTotal = @LineTotal + ISNULL(SUM(LineTotal),0) + ISNULL(@P2P_lineTotal,0)
	FROM @RBWinlost

	DROP TABLE #src
	DROP TABLE #DepAgent
END



GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_DailyWLDirect_Sporttype14] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_DailyWLDirect_Sporttype14] TO [vnteam]
