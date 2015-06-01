USE bodb02
GO

ALTER PROCEDURE [dbo].[Acc_BetListByIP_OtherSports]
	@custid		INT, 
	@ip			VARCHAR(15),
	@fromdate	DATETIME 
AS
/*
Created: Phuong Dao
Task : Bet List By IP and Other Sports
DB: DBACC/bodb02 
Original: Acc_BetListByDayAllIP
Revisions:
	- 20090509@Simon: Bet List For Casino
	- 20090528@PhuongDao: Add HR Fixed Odd 
	- 20091002@Simon: Get Odds && OddsType columns.
	- 20091003@Jamie: Remove comstatus out 
	- 20091009@Daniel: Get refund status from bettrans
	- 20091015@Shifu: Get refno
	- 20091023@Simon: Displays Odds at Bet/Settle time
	- 20091205@Henry: Get more column: refno for viewing Mix Parlay detail
	- 20100524@Jamie: Show currency2's exchange rate for OpenTote 
	- 20100611@Henry: Change mix-parlay match from 0 to 9
	- 20100907@Henry: Add IBC Bingo bettype
	- 20101130@Henry: Add column betid for number game
	- 20101201@Henry: Return winlost-actual_stake for column winlost
	- 20110408@Amy: Change function to get Odds value and odds type
	- 20110516@Lukas: re-arrange bettype
	- 20110711@Johnson: show exchange rate for SA Tote
	- 20110802@Johnson: - Add new bettype combination mix-parlay
						- Add new column actual_stake into betlist
	- 20111122@Sophia: Add Checktime and SecAcceptFlag to show status waiting or running
	- 20111207@Sophia: Add P2P
	- 20120120@Sophia: Add Showtime for Table-hand-shoe of Live Casino
					   Add sub detail for Live Casino
	- 20120321@Sophia: Select @Data table (fix bug) 
	- 20120405@Hurri: Exclude bettype 72 (P2P bet ticket) in the calculation of Casino
	- 20120410@Hurri: change matchid 0 -> 1000 for bettype 1000
	- 20120417@Johnson: Correct column transid for p2p	
	- 20120423@Lukas: show transid of main ticket for all subticket of system parlay
	- 20120606@Sophia: Change datatype of stake to money
	- 20120626@Elodie: exclude outright, HR from sportbook ( in case of matchid = orid)
	- 20120629@Sophia: Remove function f_GetOddsByBettype, f_ShowOddsByBettype for odds, Oddstype
	- 20120927@Johnson: get commstatus column to check double comm losing
	- 20121029@Elodie: Get matchid column
	- 20130227@Elodie: Add Virtual HR product
	- 20130625@Elodie: Not apply Virtual HR for bet list by IP yet at this time	
	- 20130703@Kathy: Update matchid for RnG Casino(71) and Bingo(73)
	- 20130718@Elodie: Apply core betlist
	- 20131126@Lukas: get sporttype column in VSRaceinfo instead of hardcode
	- 20140306@Dom: Add Keno
	- 20140908@Dom:	[Redmine #22012] Update VS conditions
	- 20141103@Dom: Apply sport bettype matrix
	- 20150506@Tom: Support Gold Deluxe Product [#34847]
	- 20150506@Bobby: Add transdesc column for metric gaming bettypes (801-899)
	
Param's Explanation:
	• @fromdate = @winlostdate
	
*/
BEGIN
	SET NOCOUNT ON

	----Get Sport Bettype Matrix------
	DECLARE @SportBettype TABLE(ProductID INT, Bettype INT,EventType INT)
	INSERT INTO @SportBettype
	EXEC bodb02.dbo.Acc_SportBettypeMatrix_Sel @mode=4

	  DECLARE @Data TABLE (
				finalhomescore	INT,
				finalawayscore	INT,
				oddsid			INT,
				leagueid		INT,
				bettype			SMALLINT,
				transid			BIGINT,
				betid			BIGINT, 
				refno			BIGINT,
				matchid			INT,
				matchcode		NVARCHAR (50),			
				race			NVARCHAR (50), 
				eventdate		DATETIME,
				virtualrate		FLOAT, --in case OpenTote, it's currency2's exRate 
				isShowOTExRate  BIT, --show OpenTote ExRate or not 
				sdiscount		DECIMAL (9, 8),
				adiscount		DECIMAL (9, 8),
				discount		DECIMAL (9, 8),
				homeid			INT,
				awayid			INT,
				settleTime		DATETIME,
				hdp1			SMALLMONEY,
				hdp2			SMALLMONEY,
				odds			SMALLMONEY,   
				modds			SMALLMONEY,
				finalodds		SMALLMONEY,
				finalodds2		SMALLMONEY,
				OddsType		INT, 
				status			NVARCHAR (50),
				comstatus		NVARCHAR(20),
				stake			MONEY,
				actual_stake	MONEY,
				transdate		DATETIME,
				betteam			NVARCHAR (10),
				spositiontaking smallmoney,
				mpositiontaking smallmoney,
				apositiontaking smallmoney,
				spositiontaking2 smallmoney,
				mpositiontaking2 smallmoney,
				apositiontaking2 smallmoney,
				livehomescore	INT,
				liveawayscore	INT,
				liveindicator	BIT,
				winlost			MONEY, 
				commission		MONEY, 
				scomm			MONEY,	
				acomm			MONEY,
				comm			MONEY,
				awinlost		MONEY,
				mwinlost		MONEY,
				swinlost		MONEY,
				creator			VARCHAR (50),
				username		NVARCHAR (50),
				hthomescore		INT, 
				htawayscore		INT,
				ip				NVARCHAR (15),
				betfrom			nvarchar (1),
				sporttype		INT,
				IsNeutral		BIT,
				showtime		NVARCHAR (50),
				winlostdate		smalldatetime,
				BetCheck		NVARCHAR(50),
				transdesc		NVARCHAR(300)
			)
			
		DECLARE @DetailData TABLE (
			refno			nvarchar(50), 
			odds			smallmoney, 
			stake			money,
			status			nvarchar(50),
			apositiontaking smallmoney, 
			mpositiontaking smallmoney, 
			spositiontaking smallmoney,
			bettype			smallint,
			betteam			nvarchar(50),
			TransDesc		varchar(300)
		)  
								
		INSERT INTO @Data
		SELECT  finalhomescore,	
				finalawayscore,	
				oddsid,			
				leagueid,		
				bettype,			
				transid,			
				betid,			
				refno,			
				matchid,			
				matchcode,		
				race,			
				eventdate,		
				virtualrate,		
				isShowOTExRate,  
				sdiscount,		
				adiscount,		
				discount,		
				homeid,			
				awayid,			
				checktime settleTime,		
				hdp1,			
				hdp2,			
				odds,			
				modds,			
				finalodds,		
				finalodds2,		
				OddsType,		
				status,			
				comstatus,		
				stake,			
				actual_stake,	
				transdate,		
				betteam,			
				0 spositiontaking, -- unuse in this report
				0 mpositiontaking, -- unuse in this report
				0 apositiontaking, -- unuse in this report		
				0 spositiontaking2,-- unuse in this report
				0 mpositiontaking2,-- unuse in this report
				0 apositiontaking2,-- unuse in this report
				livehomescore,	
				liveawayscore,	
				liveindicator,	
				winlost,			
				commission,		
				0 scomm, -- unuse in this report			
				0 acomm, -- unuse in this report			
				0 comm,	-- unuse in this report		
				awinlost,		
				mwinlost,		
				swinlost,		
				creator,			
				username,		
				hthomescore,		
				htawayscore,		
				ip,				
				betfrom,			
				sporttype,		
				IsNeutral,		
				showtime,
				winlostdate,
				BetCheck,
				transdesc
		FROM (
				SELECT
						match.finalhomescore,
						match.finalawayscore,
						b.oddsid,
						match.leagueid,
						b.bettype,
						b.transid,
						isnull(b.BetID,0) as BetID,
						b.refno,
						match.matchcode,
						'' as race, 
						'' as eventdate, 
						0 as virtualrate,
						0 as isShowOTExRate,
						b.sdiscount,
						b.adiscount,
						b.discount,
						match.homeid,
						match.awayid,
						ISNULL(b.checktime,'') checktime,
						b.hdp1,
						b.hdp2,
						b.odds,
						b.modds,
						0 finalodds,
						0 finalodds2,
						b.oddstype , 					
						b.status,
						CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,  
						b.stake,
						b.actual_stake,
						b.transdate,
						b.betteam,					
						b.livehomescore,
						b.liveawayscore,
						b.liveindicator,
						(b.winlost-b.actual_stake)  winlost,
						b.playercomm as commission, 
						creator.username creator,
						b.username,
						match.hthomescore, match.htawayscore,ip,
						match.sporttype,
						b.matchid,
						match.IsNeutral,
						match.showtime,
						b.awinlost,
						b.mwinlost,
						b.swinlost,
						b.betfrom,
						b.winlostdate,
						b.betcheck,
						CASE WHEN b.bettype BETWEEN 801 AND 899 THEN b.transdesc ELSE '' END AS transdesc
						
				FROM 	bettrans14 b with (nolock) 
						INNER JOIN match14 match with (nolock) on b.matchid= match.matchid
						INNER JOIN custInfo creator with (nolock) on creator.custid = b.creator
						INNER JOIN @SportBettype s ON s.Bettype = b.bettype
				WHERE 	b.winlostdate = @fromdate
						and s.eventtype = 1
						--AND bettype < 19001 AND bettype NOT IN (10,31,32,33,41,42,43/*,1231,1232,1233,1237,1238*/) 
						--AND b.bettype NOT BETWEEN 1501 AND 1599 --20120626@Elodie: exclude outright, HR from sportbook
						--AND b.bettype NOT IN (SELECT  bettype FROM dbo.f_VSHorseRacingByBettype())
						AND b.custid = @custid 
						AND match.sporttype <> 1 
				
				UNION ALL 
				SELECT 
						0 finalhomescore,
						0 finalawayscore,
						0,
						0 leagueid,
						9 bettype,
						b.transid,
						isnull(b.BetID,0) as BetID,
						b.refno,
						'' matchcode,
						'' race, 
						'' as eventdate, 
						0 as virtualrate,
						0 as isShowOTExRate,
						b.sdiscount,
						b.adiscount,
						b.discount,
						0 homeid, 
						0 awayid,
						ISNULL(b.checktime,'') checktime,
						0 hdp1,
						0 hdp2,
						b.odds,   
						b.modds,
						0 finalodds,
						0 finalodds2,
						' ' OddsType, 
						b.status,
						CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,  
						b.stake,
						b.actual_stake,
						b.transdate,
						b.betteam,					
						0 livehomescore, 
						0 liveawayscore,
						0 liveindicator,
						(b.winlost-b.actual_stake)  winlost,
						b.playercomm as commission, 
						creator.username creator,
						b.username,
						0 hthomescore, 0 htawayscore,ip,
						0 sporttype,  
						0 matchid,
						0 IsNeutral,
						'' as showtime,
						b.awinlost,
						b.mwinlost,
						b.swinlost,
						b.betfrom,
						b.winlostdate ,
						b.betcheck,
						'' AS transdesc
				FROM  	bettrans14 b  with (nolock) 
						inner join custInfo creator  with (nolock) on creator.custid = b.creator
				WHERE	b.bettype = 9 
						AND b.winlostdate=@fromdate 
						--AND b.matchid=0 
						AND b.matchid = 9
						AND b.custid = @custid 
						AND b.refno IN (SELECT RefNo FROM	bettransm14 b WITH (nolock)
																	INNER JOIN match14 m WITH (nolock) ON b.matchid = m.MatchID
															WHERE	m.sporttype <> 1)
				UNION ALL 
				SELECT 
						0 finalhomescore,
						0 finalawayscore,
						0,
						0 leagueid,
						29 bettype,
						CASE WHEN ISNULL(b.betID,0) = 0 THEN b.transid ELSE b.betID END AS transid,
						isnull(b.BetID,0) as BetID,
						b.refno,
						'' matchcode,
						'' race, 
						'' as eventdate, 
						0 as virtualrate,
						0 as isShowOTExRate,
						b.sdiscount,
						b.adiscount,
						b.discount,
						0 homeid, 
						0 awayid,
						ISNULL(b.checktime,'') checktime,
						0 hdp1,
						0 hdp2,
						b.odds,   
						b.modds,
						0 finalodds,
						0 finalodds2,
						' ' OddsType, 
						b.status,
						CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,  
						b.stake,
						b.actual_stake,
						b.transdate,
						b.betteam,					
						0 livehomescore, 
						0 liveawayscore,
						0 liveindicator,
						(b.winlost-b.actual_stake)  winlost,
						b.playercomm as commission, 
						creator.username creator,
						b.username,
						0 hthomescore, 0 htawayscore,ip,
						0 sporttype,  
						0 matchid,
						0 IsNeutral,
						'' as showtime,
						b.awinlost,
						b.mwinlost,
						b.swinlost,
						b.betfrom,
						b.winlostdate  ,
						b.betcheck,
						'' AS transdesc
				FROM  	bettrans14 b  with (nolock) 
						inner join custInfo creator  with (nolock) on creator.custid = b.creator
				WHERE	b.bettype = 29 
						AND b.winlostdate=@fromdate 
						--AND b.matchid=0 
						AND b.matchid = 29
						AND b.custid = @custid 
						AND b.refno IN (SELECT RefNo FROM	bettransm14 b WITH (nolock)
																	INNER JOIN match14 m WITH (nolock) ON b.matchid = m.MatchID
															WHERE	m.sporttype <> 1)
															
				UNION ALL
				----------------------------------------------------------------------------
				SELECT 	match.finalhomescore,
						match.finalawayscore,
						b.oddsid,
						match.leagueid,
						b.bettype,
						b.transid,
						isnull(b.BetID,0) as BetID,
						b.refno,
						match.matchcode,
						'' race,
						'' as eventdate,
						0 as virtualrate,
						0 as isShowOTExRate,
						b.sdiscount,
						b.adiscount,
						b.discount,
						match.homeid,
						match.awayid,
						ISNULL(b.checktime,'') checktime,
						b.hdp1,
						b.hdp2,
						b.odds, 
						b.modds,
						0 finalodds,
						0 finalodds2,
						b.oddstype ,
						CASE WHEN b.status = 'running' AND IsNull(b.SecAcceptFlag, 0) = 1 and IsNull(b.checktime, CURRENT_TIMESTAMP) > CURRENT_TIMESTAMP THEN 'waiting'
							 ELSE b.status 
						END as status,
						CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,  
						b.stake,
						b.actual_stake,
						b.transdate,
						b.betteam,					
						b.livehomescore,
						b.liveawayscore,
						b.liveindicator,
						(b.winlost-b.actual_stake)  winlost,
						b.playercomm as commission, 
						creator.username creator,
						b.username,
						match.hthomescore, match.htawayscore,ip,
						match.sporttype,
						b.matchid,
						match.IsNeutral,
						match.showtime,
						b.awinlost,
						b.mwinlost,
						b.swinlost,
						b.betfrom,
						b.winlostdate ,
						b.betcheck,
						'' AS transdesc
				FROM	bettrans b with (nolock) 
						INNER JOIN match  with (nolock) on b.matchid = match.matchid
						INNER JOIN custInfo creator with (nolock) on creator.custid = b.creator
						INNER JOIN @SportBettype s ON s.Bettype = b.bettype
				WHERE	b.winlostdate = @fromdate 
						--AND b.bettype < 19001 AND bettype NOT IN (10,31,32,33,41,42,43/*,1231,1232,1233,1237,1238*/) 
						--AND b.bettype NOT BETWEEN 1501 AND 1599 --20120626@Elodie: exclude outright, HR from sportbook
						--AND b.bettype NOT IN (SELECT  bettype FROM dbo.f_VSHorseRacingByBettype())
						AND s.eventtype = 1 and b.bettype <> 10
						AND match.sporttype <> 1
						AND b.custid = @custid
		
				UNION ALL
				SELECT	0 finalhomescore,
						0 finalawayscore,
						0,
						0 leagueid,
						9 bettype,
						b.transid,
						isnull(b.BetID,0) as BetID,
						b.refno,
						'' matchcode,
						'' race, 
						'' as eventdate, 
						0 as virtualrate ,
						0 as isShowOTExRate,
						b.sdiscount,
						b.adiscount,
						b.discount,
						0 homeid,	0 awayid,
						ISNULL(b.checktime,'') checktime,	
						0 hdp1, 0 hdp2,
						b.odds,   
						b.modds,
						0 finalodds,
						0 finalodds2,
						' ' OddsType, 
						b.status,
						CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,  
						b.stake,
						b.actual_stake,
						b.transdate,
						b.betteam,					
						0 livehomescore, 
						0 liveawayscore,
						0 liveindicator,
						(b.winlost-b.actual_stake)  winlost,
						b.playercomm as commission, 
						creator.username creator,
						b.username,
						0 hthomescore, 0 htawayscore,ip,
						0 sporttype,
						b.matchid,
						0 IsNeutral,
						'' as showtime,
						b.awinlost,
						b.mwinlost,
						b.swinlost,
						b.betfrom,
						b.winlostdate ,
						b.betcheck,
						'' AS transdesc
				FROM	bettrans b with (nolock) 
						INNER JOIN custInfo creator  with (nolock) on creator.custid = b.creator
				WHERE	b.winlostdate = @fromdate 
						--AND b.matchid=0 
						AND b.matchid = 9
						AND b.bettype = 9 	
						AND b.custid = @custid
						AND b.refno IN (SELECT RefNo FROM	bettransm b WITH (nolock)
																	INNER JOIN match m WITH (nolock) ON b.matchid = m.matchid
															WHERE	m.sporttype <> 1 )
				
				UNION ALL
				SELECT	0 finalhomescore,
						0 finalawayscore,
						0,
						0 leagueid,
						29 bettype,
						CASE WHEN ISNULL(b.betID,0) = 0 THEN b.transid ELSE b.betID END AS transid,
						isnull(b.BetID,0) as BetID,
						b.refno,
						'' matchcode,
						'' race, 
						'' as eventdate, 
						0 as virtualrate ,
						0 as isShowOTExRate,
						b.sdiscount,
						b.adiscount,
						b.discount,
						0 homeid,	0 awayid,
						ISNULL(b.checktime,'') checktime,	
						0 hdp1, 0 hdp2,
						b.odds,   
						b.modds,
						0 finalodds,
						0 finalodds2,
						' ' OddsType, 
						b.status,
						CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,  
						b.stake,
						b.actual_stake,
						b.transdate,
						b.betteam,					
						0 livehomescore, 
						0 liveawayscore,
						0 liveindicator,
						(b.winlost-b.actual_stake)  winlost,
						b.playercomm as commission, 
						creator.username creator,
						b.username,
						0 hthomescore, 0 htawayscore,ip,
						0 sporttype,
						b.matchid,
						0 IsNeutral,
						'' as showtime,
						b.awinlost,
						b.mwinlost,
						b.swinlost,
						b.betfrom,
						b.winlostdate  ,
						b.betcheck,
						'' AS transdesc
				FROM	bettrans b with (nolock) 
						INNER JOIN custInfo creator  with (nolock) on creator.custid = b.creator
				WHERE	b.winlostdate = @fromdate 
						--AND b.matchid=0 
						AND b.matchid = 29
						AND b.bettype = 29 	
						AND b.custid = @custid
						AND b.refno IN (SELECT RefNo FROM	bettransm b WITH (nolock)
																	INNER JOIN match m WITH (nolock) ON b.matchid = m.matchid
															WHERE	m.sporttype <> 1 )
																									
				--- OUTRIGHT
				UNION ALL
				SELECT	0 finalhomescore,
						0 finalawayscore, 
						0 oddsid, 
						odds.leagueid,
						b.bettype, 
						b.transid,
						isnull(b.BetID,0) as BetID,
						b.refno,
						odds.matchcode, 
						odds.groupmatch as race, --phuong.nguyen, get HR race
						odds.eventdate as eventdate, --phuong.nguyen
						b.virtualrate,
						--isnumeric(odds.programID) as isShowOTExRate,
						CASE WHEN b.currency2 IS NULL THEN CONVERT(BIT,0) ELSE CONVERT(BIT,1) END AS isShowOTExRate,
						b.sdiscount,
						b.adiscount,
						b.discount,					
						case when b.bettype = 10 then 0 else odds.teamid end homeid,
						case WHEN b.bettype = 10 THEN odds.teamid ELSE 0 end awayid,
						ISNULL(b.checktime,'') checktime,
						b.hdp1, --phuong.nguyen <2008-12-30>
						b.hdp2, --end
						b.odds,   
						b.modds,
						bmOdd.finalodds,
						bmOdd.finalodds2,
						' ' OddsType, 
						b.status, 
						CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,  
						b.stake, 
						b.actual_stake,
						b.transdate, 
						b.betteam, 					
						b.livehomescore, --phuong.nguyen <2008-12-30>
						b.liveawayscore, --end
						0 liveindicator, 
						(b.winlost-b.actual_stake)  winlost,
						b.playercomm as commission, 
						CASE b.custid WHEN b.creator THEN b.Username ELSE '' END creator,
						b.username,
						0 hthomescore, 0 htawayscore,ip, 
						s.sporttype,
						b.matchid,
						0 IsNeutral,
						'' as showtime,
						b.awinlost,
						b.mwinlost,
						b.swinlost,
						b.betfrom,
						b.winlostdate,
						b.betcheck,
						'' AS transdesc
				FROM	 
						bettrans b with (nolock)
						INNER JOIN outright odds with (nolock) on b.matchid = odds.orid
						INNER JOIN league l with (nolock) on odds.leagueid = l.leagueid
						INNER JOIN Sports s WITH (nolock) ON l.sporttype = s.sporttype 
						INNER JOIN @SportBettype sbt ON sbt.Bettype = b.bettype
						LEFT JOIN (			
							SELECT	t.refno, t.finalodds, f.finalodds finalodds2
							FROM	bettransm t WITH (NOLOCK)
									INNER JOIN bettransm f WITH (NOLOCK) ON t.refno = f.refno 
							WHERE	t.bettype = 41 AND f.bettype = 42
						)bmOdd on b.transid = bmOdd.refno 
				WHERE	sbt.eventtype=2 --b.bettype in (10,31,32,33,41,42,43) --phuong.nguyen, get HR bet list
						AND b.winlostdate = @fromdate
						AND b.custid = @custid 
						AND s.sporttype <> 1 

				--- OUTRIGHT 14
				UNION ALL
				SELECT	0 finalhomescore,
						0 finalawayscore, 
						0 oddsid, 
						odds.leagueid,
						b.bettype, 
						b.transid,
						isnull(b.BetID,0) as BetID,
						b.refno,
						odds.matchcode, 
						odds.groupmatch as race, --phuong.nguyen, get HR bet list,
						odds.eventdate as eventdate, --phuong.nguyen
						b.virtualrate,
						--isnumeric(odds.programID) as isShowOTExRate,
						CASE WHEN b.currency2 IS NULL THEN CONVERT(BIT,0) ELSE CONVERT(BIT,1) END AS isShowOTExRate,
						b.sdiscount,
						b.adiscount,
						b.discount,
						case when b.bettype = 10 then 0 else odds.teamid end homeid,
						case WHEN b.bettype = 10 THEN odds.teamid ELSE 0 end awayid,
						ISNULL(b.checktime,'') checktime, 
						b.hdp1, --phuong.nguyen <2008-12-30>
						b.hdp2, --end
						b.odds,   
						b.modds,
						bmOdd.finalodds,
						bmOdd.finalodds2,
						' ' OddsType, 
						b.status,
						CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,   
						b.stake, 
						b.actual_stake,
						b.transdate, 
						b.betteam, 					
						b.livehomescore, --phuong.nguyen <2008-12-30>
						b.liveawayscore, --end
						0 liveindicator, 
						(b.winlost-b.actual_stake)  winlost,
						b.playercomm as commission, 
						CASE b.custid WHEN b.creator THEN b.username ELSE '' END creator, 
						b.username,
						0 hthomescore, 0 htawayscore,ip, 	
						s.sporttype,
						b.matchid,
						0 IsNeutral,
						'' as showtime,
						b.awinlost,
						b.mwinlost,
						b.swinlost,
						b.betfrom,
						b.winlostdate  ,
						b.betcheck,
						'' AS transdesc
				FROM 	bettrans14 b with (nolock)
						INNER JOIN outright14 odds with (nolock) on b.matchid = odds.orid
						INNER JOIN league l with (nolock) on odds.leagueid = l.leagueid
						INNER JOIN Sports s WITH (nolock) ON l.sporttype = s.sporttype 
						INNER JOIN @SportBettype sbt ON sbt.Bettype = b.bettype
						LEFT JOIN (			
							SELECT	t.refno, t.finalodds, f.finalodds finalodds2
							FROM	bettransm14 t WITH (NOLOCK)
									INNER JOIN bettransm14 f WITH (NOLOCK) ON t.refno = f.refno 
							WHERE	t.bettype = 41 AND f.bettype = 42
						)bmOdd on b.transid = bmOdd.refno 
				WHERE	sbt.eventtype=2 --b.bettype in (10,31,32,33,41,42,43)
						AND b.winlostdate = @fromdate
						AND b.custid = @custid
						AND s.SportType <>1 
						
				--- Casino
				UNION ALL
				SELECT	0 finalhomescore,
						0 finalawayscore, 
						0 oddsid, 
						0 leagueid,
						b.bettype, 
						b.betid transid,
						isnull(b.BetID,0) as BetID,
						b.refno,
						CONVERT(varchar(50),b.refno) matchcode, 
						'' as race, --phuong.nguyen, get HR bet list,
						'' as eventdate, --phuong.nguyen
						0 as virtualrate,
						0 as isShowOTExRate,
						b.sdiscount,
						b.adiscount,
						b.discount,
						0 homeid,
						0 awayid,
						ISNULL(b.checktime,'') checktime, 
						b.hdp1, --phuong.nguyen <2008-12-30>
						b.hdp2, --end
						b.odds,  
						b.modds,
						0 finalodds,
						0 finalodds2, 
						' ' OddsType, 
						b.status,
						CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,  
						b.stake, 
						b.actual_stake,
						b.transdate, 
						b.betteam, 					
						b.livehomescore, --phuong.nguyen <2008-12-30>
						b.liveawayscore, --end
						0 liveindicator, 
						(b.winlost-b.actual_stake)  winlost,
						b.playercomm as commission, 
						CASE b.custid WHEN b.creator THEN b.username ELSE '' END creator, 
						b.username,
						0 hthomescore, 0 htawayscore,ip, 	
						251 AS sporttype, --sporttype, sporttype,
						b.matchid,
						0 IsNeutral,
						'' as showtime,
						b.awinlost,
						b.mwinlost,
						b.swinlost,
						b.betfrom,
						b.winlostdate ,
						b.betcheck,
						'' AS transdesc
				FROM 	bettrans b with (nolock)
				INNER JOIN @SportBettype s ON s.Bettype = b.bettype
				WHERE	s.ProductID = 6
						--b.bettype = 71								--20120405@Hurri
						--AND b.matchid IN (0, 71)
						AND b.winlostdate = @fromdate
						AND b.custid = @custid
						
				--- Casino 14
				UNION ALL
				SELECT	0 finalhomescore,
						0 finalawayscore, 
						0 oddsid, 
						0 leagueid,
						b.bettype, 
						b.betid transid,
						isnull(b.BetID,0) as BetID,
						b.refno,
						CONVERT(varchar(50),b.refno) matchcode,
						'' as race, --phuong.nguyen, get HR bet list,
						'' as eventdate, --phuong.nguyen
						0 as virtualrate,
						0 as isShowOTExRate,
						b.sdiscount,
						b.adiscount,
						b.discount,
						0 homeid,
						0 awayid,
						ISNULL(b.checktime,'') checktime, 
						b.hdp1, --phuong.nguyen <2008-12-30>
						b.hdp2, --end
						b.odds,   
						b.modds,
						0 finalodds,
						0 finalodds2,
						' ' OddsType, 
						b.status, 
						CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,  
						b.stake, 
						b.actual_stake,
						b.transdate, 
						b.betteam, 					
						b.livehomescore, --phuong.nguyen <2008-12-30>
						b.liveawayscore, --end
						0 liveindicator, 
						(b.winlost-b.actual_stake)  winlost,
						b.playercomm as commission, 
						CASE b.custid WHEN b.creator THEN b.username ELSE '' END creator, 
						b.username,
						0 hthomescore, 0 htawayscore,ip, 	
						251 sporttype,-- sporttype
						b.matchid,
						0 IsNeutral,
						'' as showtime,
						b.awinlost,
						b.mwinlost,
						b.swinlost,
						b.betfrom,
						b.winlostdate  ,
						b.betcheck,
						'' AS transdesc
				FROM 	bettrans14 b with (nolock)
				INNER JOIN @SportBettype s ON s.Bettype = b.bettype
				WHERE	s.ProductID = 6
						--b.bettype = 71								--20120405@Hurri
						--AND b.matchid in (0, 71)
						AND b.winlostdate = @fromdate
						AND b.custid = @custid
						
				--- IBC Bingo
				UNION ALL
				SELECT	0 finalhomescore,
						0 finalawayscore, 
						0 oddsid, 
						0 leagueid,
						b.bettype, 
						b.betid transid,
						isnull(b.BetID,0) as BetID,
						b.refno,
						CONVERT(varchar(50),b.refno) matchcode, 
						'' as race, 
						'' as eventdate, 
						0 as virtualrate,
						0 as isShowOTExRate,
						b.sdiscount,
						b.adiscount,
						b.discount,
						0 homeid,
						0 awayid,
						ISNULL(b.checktime,'') checktime, 
						b.hdp1, 
						b.hdp2,
						b.odds,  
						b.modds,
						0 finalodds,
						0 finalodds2, 
						' ' OddsType, 
						b.status,
						CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,  
						b.stake, 
						b.actual_stake,
						b.transdate, 
						b.betteam, 					
						b.livehomescore,
						b.liveawayscore, 
						0 liveindicator, 
						(b.winlost-b.actual_stake)  winlost,
						b.playercomm as commission, 
						CASE b.custid WHEN b.creator THEN b.username ELSE '' END creator, 
						b.username,
						0 hthomescore, 0 htawayscore,ip, 	
						252 AS sporttype, 
						b.matchid,
						0 IsNeutral,
						'' as showtime,
						b.awinlost,
						b.mwinlost,
						b.swinlost,
						b.betfrom,
						b.winlostdate ,
						b.betcheck,
						'' AS transdesc
				FROM 	bettrans b with (nolock)
				INNER JOIN @SportBettype s ON s.Bettype = b.bettype
				WHERE	s.ProductID = 7
						--b.bettype = 73
						--AND b.matchid in (0, 73)
						AND b.winlostdate = @fromdate
						AND b.custid = @custid
						
				--- IBC Bingo 14
				UNION ALL
				SELECT	0 finalhomescore,
						0 finalawayscore, 
						0 oddsid, 
						0 leagueid,
						b.bettype, 
						b.betid transid,
						isnull(b.BetID,0) as BetID,
						b.refno,
						CONVERT(varchar(50),b.refno) matchcode,
						'' as race, 
						'' as eventdate, 
						0 as virtualrate,
						0 as isShowOTExRate,
						b.sdiscount,
						b.adiscount,
						b.discount,
						0 homeid,
						0 awayid,
						ISNULL(b.checktime,'') checktime, 
						b.hdp1, 
						b.hdp2, 
						b.odds,   
						b.modds,
						0 finalodds,
						0 finalodds2,
						' ' OddsType, 
						b.status, 
						CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,  
						b.stake, 
						b.actual_stake,
						b.transdate, 
						b.betteam, 					
						b.livehomescore, 
						b.liveawayscore,
						0 liveindicator, 
						(b.winlost-b.actual_stake)  winlost,
						b.playercomm as commission, 
						CASE b.custid WHEN b.creator THEN b.username ELSE '' END creator, 
						b.username,
						0 hthomescore, 0 htawayscore,ip, 	
						252 sporttype,
						b.matchid,
						0 IsNeutral,
						'' as showtime,
						b.awinlost,
						b.mwinlost,
						b.swinlost,
						b.betfrom,
						b.winlostdate  ,
						b.betcheck,
						'' AS transdesc
				FROM 	bettrans14 b with (nolock)
				INNER JOIN @SportBettype s ON s.Bettype = b.bettype
				WHERE	s.ProductID = 7
						--b.bettype = 73
						--AND b.matchid in (0, 73)
						AND b.winlostdate = @fromdate
						AND b.custid = @custid

				--- IBC keno
				UNION ALL
				SELECT	0 finalhomescore,
						0 finalawayscore, 
						0 oddsid, 
						0 leagueid,
						b.bettype, 
						b.betid transid,
						isnull(b.BetID,0) as BetID,
						b.refno,
						CONVERT(varchar(50),b.refno) matchcode, 
						'' as race, 
						'' as eventdate, 
						0 as virtualrate,
						0 as isShowOTExRate,
						b.sdiscount,
						b.adiscount,
						b.discount,
						0 homeid,
						0 awayid,
						ISNULL(b.checktime,'') checktime, 
						b.hdp1, 
						b.hdp2,
						b.odds,  
						b.modds,
						0 finalodds,
						0 finalodds2, 
						' ' OddsType, 
						b.status,
						CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,  
						b.stake, 
						b.actual_stake,
						b.transdate, 
						d.ChoiceId betteam,   
						b.livehomescore,
						b.liveawayscore, 
						0 liveindicator, 
						(b.winlost-b.actual_stake)  winlost,
						b.playercomm as commission, 
						CASE b.custid WHEN b.creator THEN b.username ELSE '' END creator, 
						b.username,
						0 hthomescore, 0 htawayscore,ip, 	
						202 AS sporttype, 
						d.GameId matchid,
						0 IsNeutral,
						'' as showtime,
						b.awinlost,
						b.mwinlost,
						b.swinlost,
						b.betfrom,
						b.winlostdate ,
						b.betcheck,
						'' AS transdesc
				FROM 	bettrans b with (nolock)
				INNER JOIN @SportBettype s ON s.Bettype = b.bettype
				outer apply dbo.[f_ParseTransDesc](b.TransDesc, b.bettype) d
				WHERE	s.ProductID = 8
						--b.bettype BETWEEN 1501 AND 1599
						AND b.winlostdate = @fromdate
						AND b.custid = @custid

				UNION ALL -- keno translog
				SELECT	0 finalhomescore,
						0 finalawayscore, 
						0 oddsid, 
						0 leagueid,
						b.gameid, 
						0 transid,
						0 as BetID,
						b.translogid,
						'' matchcode, 
						'' as race, 
						'' as eventdate, 
						0 as virtualrate,
						0 as isShowOTExRate,
						b.sdiscount,
						b.adiscount,
						b.discount,
						0 homeid,
						0 awayid,
						'' checktime, 
						0 hdp1, 
						0 hdp2,
						b.odds,  
						0 modds,
						0 finalodds,
						0 finalodds2, 
						' ' OddsType, 
						b.status,
						0 as comstatus,  
						b.stake, 
						b.actual_stake,
						b.transdate, 
						d.ChoiceId betteam,   
						0 livehomescore,
						0 liveawayscore, 
						0 liveindicator, 
						(-b.actual_stake)  winlost,
						0 commission, 
						CASE b.custid WHEN b.creator THEN b.username ELSE '' END creator, 
						b.username,
						0 hthomescore, 0 htawayscore,ip, 	
						202 AS sporttype, 
						d.GameId matchid,
						0 IsNeutral,
						'' as showtime,
						0 awinlost,
						0 mwinlost,
						0 swinlost,
						b.betfrom,
						b.winlostdate ,
						'' betcheck,
						'' AS transdesc
				FROM 	translog b with (nolock)
				INNER JOIN @SportBettype s ON s.Bettype = b.gameID
				outer apply dbo.[f_ParseTransDesc](b.TransDesc, b.gameid) d
				WHERE	s.ProductID = 8
						--b.gameID BETWEEN 1501 AND 1599
						AND b.winlostdate = @fromdate
						AND b.custid = @custid
						AND b.statusID = 0
						
				--- IBC keno 14
				UNION ALL
				SELECT	0 finalhomescore,
						0 finalawayscore, 
						0 oddsid, 
						0 leagueid,
						b.bettype, 
						b.betid transid,
						isnull(b.BetID,0) as BetID,
						b.refno,
						CONVERT(varchar(50),b.refno) matchcode,
						'' as race, 
						'' as eventdate, 
						0 as virtualrate,
						0 as isShowOTExRate,
						b.sdiscount,
						b.adiscount,
						b.discount,
						0 homeid,
						0 awayid,
						ISNULL(b.checktime,'') checktime, 
						b.hdp1, 
						b.hdp2, 
						b.odds,   
						b.modds,
						0 finalodds,
						0 finalodds2,
						' ' OddsType, 
						b.status, 
						CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,  
						b.stake, 
						b.actual_stake,
						b.transdate, 
						d.ChoiceId betteam,   
						b.livehomescore, 
						b.liveawayscore,
						0 liveindicator, 
						(b.winlost-b.actual_stake)  winlost,
						b.playercomm as commission, 
						CASE b.custid WHEN b.creator THEN b.username ELSE '' END creator, 
						b.username,
						0 hthomescore, 0 htawayscore,ip, 	
						202 sporttype,
						d.GameId matchid,
						0 IsNeutral,
						'' as showtime,
						b.awinlost,
						b.mwinlost,
						b.swinlost,
						b.betfrom,
						b.winlostdate  ,
						b.betcheck,
						'' AS transdesc
				FROM 	bettrans14 b with (nolock)
				INNER JOIN @SportBettype s ON s.Bettype = b.bettype
				outer apply dbo.[f_ParseTransDesc](b.TransDesc, b.bettype) d
				WHERE	s.ProductID = 8
						--b.bettype BETWEEN 1501 AND 1599
						AND b.winlostdate = @fromdate
						AND b.custid = @custid
						
				--- P2P
				UNION ALL
				SELECT	0 finalhomescore,
						0 finalawayscore, 
						0 oddsid, 
						0 leagueid,
						b.bettype, 
						b.transid,
						isnull(b.BetID,0) as BetID,
						b.refno,
						'' matchcode, 
						'' as race, --phuong.nguyen, get HR bet list,
						'' as eventdate, --phuong.nguyen
						0 as virtualrate,
						0 as isShowOTExRate,
						b.sdiscount,
						b.adiscount,
						b.discount,
						0 homeid,
						0 awayid,
						ISNULL(b.checktime,'') checktime, 
						b.hdp1, --phuong.nguyen <2008-12-30>
						b.hdp2, --end
						b.odds,  
						b.modds,
						0 finalodds,
						0 finalodds2, 
						' ' OddsType, 
						b.status,
						CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,  
						b.stake, 
						b.actual_stake,
						b.transdate, 
						b.betteam, 					
						b.livehomescore, --phuong.nguyen <2008-12-30>
						b.liveawayscore, --end
						0 liveindicator, 
						(b.winlost-b.actual_stake)  winlost,
						b.playercomm as commission, 
						CASE b.custid WHEN b.creator THEN b.username ELSE '' END creator, 
						b.username,
						0 hthomescore, 0 htawayscore,ip, 	
						253 AS sporttype, --sporttype, sporttype,
						b.matchid,
						0 IsNeutral,
						'' as showtime,
						b.awinlost,
						b.mwinlost,
						b.swinlost,
						b.betfrom,
						b.winlostdate  ,
						b.betcheck,
						'' AS transdesc
				FROM 	bettrans b with (nolock)
				WHERE	b.bettype = 1000
						AND b.matchid = 1000 
						AND b.winlostdate = @fromdate
						AND b.custid = @custid
						
				--- P2P 14
				UNION ALL
				SELECT	0 finalhomescore,
						0 finalawayscore, 
						0 oddsid, 
						0 leagueid,
						b.bettype, 
						b.transid,
						isnull(b.BetID,0) as BetID,
						b.refno,
						'' matchcode,
						'' as race, --phuong.nguyen, get HR bet list,
						'' as eventdate, --phuong.nguyen
						0 as virtualrate,
						0 as isShowOTExRate,
						b.sdiscount,
						b.adiscount,
						b.discount,
						0 homeid,
						0 awayid,
						ISNULL(b.checktime,'') checktime, 
						b.hdp1, --phuong.nguyen <2008-12-30>
						b.hdp2, --end
						b.odds,   
						b.modds,
						0 finalodds,
						0 finalodds2,
						' ' OddsType, 					
						b.status, 
						CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,  
						b.stake, 
						b.actual_stake,
						b.transdate, 
						b.betteam, 					
						b.livehomescore, --phuong.nguyen <2008-12-30>
						b.liveawayscore, --end
						0 liveindicator, 
						(b.winlost-b.actual_stake)  winlost,
						b.playercomm as commission, 
						CASE b.custid WHEN b.creator THEN b.username ELSE '' END creator, 
						b.username,
						0 hthomescore, 0 htawayscore,ip, 	
						253 sporttype,-- sporttype
						b.matchid,
						0 IsNeutral,
						'' as showtime,
						b.awinlost,
						b.mwinlost,
						b.swinlost,
						b.betfrom,
						b.winlostdate  ,
						b.betcheck,
						'' AS transdesc
						
				FROM 	bettrans14 b with (nolock)
				WHERE	b.bettype = 1000
						AND b.matchid = 1000 
						AND b.winlostdate = @fromdate
						AND b.custid = @custid
						
				-- Virtual HR
				UNION ALL
				SELECT	0 finalhomescore,
						0 finalawayscore, 
						b.oddsid, 
						r.LeagueID,
						b.bettype, 
						b.transid,
						'' as BetID,
						b.refno,
						convert(nvarchar(50),o.RacerNum) matchcode, --Horse Number
						b.oddsid as Race, -- OutrightID
						'' EventDate,
						0 as virtualrate,
						0 as isShowOTExRate,
						b.sdiscount,
						b.adiscount,
						b.discount,
						o.RacerID as homeID, 
						0 as awayID,
						'' checktime, 
						b.hdp1, 
						b.hdp2, 
						b.odds,   
						b.modds,
						0 finalodds,
						0 finalodds2,
						'' OddsType, 					
						b.status, 
						CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,  
						b.stake, 
						b.actual_stake,
						b.transdate, 
						'' as betteam, 					
						b.livehomescore,
						b.liveawayscore,
						0 liveindicator, 
						(b.winlost-b.actual_stake)  winlost,
						b.playercomm as commission, 
						CASE b.custid WHEN b.creator THEN b.username ELSE '' END creator, 
						b.username,
						0 hthomescore, 0 htawayscore,ip, 	
						r.SportType sporttype,
						b.matchid,
						0 IsNeutral,
						convert(nvarchar(50), r.EventTime) as showtime, -- race name					
						b.awinlost,
						b.mwinlost,
						b.swinlost,
						b.betfrom,
						b.winlostdate,
						b.betcheck,
						'' AS transdesc
				FROM 	bettrans b with (nolock)
						INNER JOIN VSOutright o WITH (NOLOCK) ON b.oddsid = o.Orid
						INNER JOIN VSRaceInfo r WITH (NOLOCK) ON r.EventID = o.EventID
						INNER JOIN @SportBettype s ON s.BetType = b.BetType 
				WHERE	s.ProductID = 5
						AND s.EventType = 3
						--b.bettype in (/*1231, 1232, 1233, 1237, 1238*/SELECT  bettype FROM dbo.f_VSHorseRacingByBettype())
						AND b.winlostdate = @fromdate
						AND b.custid = @custid		

				-- Virtual HR 14
				UNION ALL
				SELECT	0 finalhomescore,
						0 finalawayscore, 
						b.oddsid, 
						r.LeagueID,
						b.bettype, 
						b.transid,
						'' as BetID,
						b.refno,
						convert(nvarchar(50),o.RacerNum) matchcode, --Horse Number
						b.oddsid as Race, -- OutrightID
						'' EventDate,
						0 as virtualrate,
						0 as isShowOTExRate,
						b.sdiscount,
						b.adiscount,
						b.discount,
						o.RacerID as homeID, 
						0 as awayID,
						'' checktime, 
						b.hdp1, 
						b.hdp2, 
						b.odds,   
						b.modds,
						0 finalodds,
						0 finalodds2,
						'' OddsType, 					
						b.status, 
						CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,  
						b.stake, 
						b.actual_stake,
						b.transdate, 
						'' as betteam, 					
						b.livehomescore,
						b.liveawayscore,
						0 liveindicator, 
						(b.winlost-b.actual_stake)  winlost,
						b.playercomm as commission, 
						CASE b.custid WHEN b.creator THEN b.username ELSE '' END creator, 
						b.username,
						0 hthomescore, 0 htawayscore,ip, 	
						r.SportType sporttype,
						b.matchid,
						0 IsNeutral,
						convert(nvarchar(50), r.EventTime) as showtime, -- race name  					
						b.awinlost,
						b.mwinlost,
						b.swinlost,
						b.betfrom,
						b.winlostdate,
						b.betcheck,
						'' AS transdesc
						
				FROM 	bettrans14 b with (nolock)
						INNER JOIN VSOutright14 o WITH (NOLOCK) ON b.oddsid = o.Orid
						INNER JOIN VSRaceInfo r WITH (NOLOCK) ON r.EventID = o.EventID
						INNER JOIN @SportBettype s ON s.BetType = b.BetType 
				WHERE	s.ProductID = 5
						AND s.EventType = 3
						--b.bettype in (/*1231, 1232, 1233, 1237, 1238*/SELECT  bettype FROM dbo.f_VSHorseRacingByBettype())
						AND b.winlostdate = @fromdate
						AND b.custid = @custid
						
			UNION ALL--GOLD DELUXE
				SELECT	0 finalhomescore,
						0 finalawayscore, 
						0 oddsid, 
						0 leagueid,
						b.bettype, 
						b.transid,
						isnull(b.BetID,0) as BetID,
						b.refno,
						'' matchcode, 
						'' as race, 
						'' as eventdate, 
						0 as virtualrate,
						0 as isShowOTExRate,
						b.sdiscount,
						b.adiscount,
						b.discount,
						0 homeid,
						0 awayid,
						ISNULL(b.checktime,'') checktime, 
						b.hdp1, 
						b.hdp2,
						b.odds,  
						b.modds,
						0 finalodds,
						0 finalodds2, 
						' ' OddsType, 
						b.status,
						CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,  
						b.stake, 
						b.actual_stake,
						b.transdate, 
						b.betteam,   
						b.livehomescore,
						b.liveawayscore, 
						0 liveindicator, 
						(b.winlost-b.actual_stake)  winlost,
						b.playercomm as commission, 
						CASE b.custid WHEN b.creator THEN b.username ELSE '' END creator, 
						b.username,
						0 hthomescore, 0 htawayscore,ip, 	
						255 AS sporttype, 
						b.matchid,
						0 IsNeutral,
						'' as showtime,
						b.awinlost,
						b.mwinlost,
						b.swinlost,
						b.betfrom,
						b.winlostdate ,
						b.betcheck,
						'' AS transdesc
				FROM 	bettrans b with (nolock)
				INNER JOIN @SportBettype s ON s.Bettype = b.bettype
				WHERE	s.ProductID = 12
						AND b.winlostdate = @fromdate
						AND b.custid = @custid

				UNION ALL -- GOLD DELUXE translog
				SELECT	0 finalhomescore,
						0 finalawayscore, 
						0 oddsid, 
						0 leagueid,
						b.gameid, 
						0 transid,
						0 as BetID,
						b.translogid,
						'' matchcode, 
						'' as race, 
						'' as eventdate, 
						0 as virtualrate,
						0 as isShowOTExRate,
						b.sdiscount,
						b.adiscount,
						b.discount,
						0 homeid,
						0 awayid,
						'' checktime, 
						0 hdp1, 
						0 hdp2,
						b.odds,  
						0 modds,
						0 finalodds,
						0 finalodds2, 
						' ' OddsType, 
						b.status,
						0 as comstatus,  
						b.stake, 
						b.actual_stake,
						b.transdate, 
						b.GameID3rd betteam,   
						0 livehomescore,
						0 liveawayscore, 
						0 liveindicator, 
						(-b.actual_stake)  winlost,
						0 commission, 
						CASE b.custid WHEN b.creator THEN b.username ELSE '' END creator, 
						b.username,
						0 hthomescore, 0 htawayscore,ip, 	
						255 AS sporttype, 
						NULL matchid,
						0 IsNeutral,
						'' as showtime,
						0 awinlost,
						0 mwinlost,
						0 swinlost,
						b.betfrom,
						b.winlostdate ,
						'' betcheck,
						'' AS transdesc					
						
				FROM 	dbo.translog b with (nolock)
				INNER JOIN @SportBettype s ON s.Bettype = b.gameID
				WHERE	s.ProductID = 12
						AND b.winlostdate = @fromdate
						AND b.custid = @custid
						AND b.statusID = 0
						
				--- GOLD DELUXE Bettrans 14
				UNION ALL
				SELECT	0 finalhomescore,
						0 finalawayscore, 
						0 oddsid, 
						0 leagueid,
						b.bettype, 
						b.transid transid,
						isnull(b.BetID,0) as BetID,
						b.refno,
						'' matchcode,
						'' as race, 
						'' as eventdate, 
						0 as virtualrate,
						0 as isShowOTExRate,
						b.sdiscount,
						b.adiscount,
						b.discount,
						0 homeid,
						0 awayid,
						ISNULL(b.checktime,'') checktime, 
						b.hdp1, 
						b.hdp2, 
						b.odds,   
						b.modds,
						0 finalodds,
						0 finalodds2,
						' ' OddsType, 
						b.status, 
						CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,  
						b.stake, 
						b.actual_stake,
						b.transdate, 
						b.betteam,   
						b.livehomescore, 
						b.liveawayscore,
						0 liveindicator, 
						(b.winlost-b.actual_stake)  winlost,
						b.playercomm as commission, 
						CASE b.custid WHEN b.creator THEN b.username ELSE '' END creator, 
						b.username,
						0 hthomescore, 0 htawayscore,ip, 	
						255 sporttype,
						b.matchid,
						0 IsNeutral,
						'' as showtime,
						b.awinlost,
						b.mwinlost,
						b.swinlost,
						b.betfrom,
						b.winlostdate  ,
						b.betcheck,
						'' AS transdesc
				FROM 	bettrans14 b with (nolock)
				INNER JOIN @SportBettype s ON s.Bettype = b.bettype
				WHERE	s.ProductID = 12
						AND b.winlostdate = @fromdate
						AND b.custid = @custid
						
		
		) x

	WHERE ip=@ip

	ORDER BY 4,26

	IF EXISTS (SELECT TOP 1 1 
			FROM @SportBettype sp 
				INNER JOIN @Data d
					ON d.bettype = sp.bettype 
			WHERE ProductID in (4,12)) 
	BEGIN
	 INSERT INTO @DetailData
		SELECT 
			BG.refno,
			BG.odds, 
			BG.stake,
			BG.status,
			BG.apositiontaking, 
			BG.mpositiontaking, 
			BG.spositiontaking,
			BG.bettype,
			BG.betteam,
			BG.TransDesc  
		FROM bettransg BG with (NOLOCK)  
			INNER JOIN @SportBettype sp ON BG.bettype = sp.bettype AND sp.Productid in (4)
			INNER JOIN @Data B ON BG.CustID = @CustID AND (sp.Productid in (4) AND BG.refno = B.refno AND BG.bettype = B.bettype)
		UNION ALL
		SELECT 
			BG.refno,
			BG.odds, 
			BG.stake,
			BG.status,
			BG.apositiontaking, 
			BG.mpositiontaking, 
			BG.spositiontaking,
			BG.bettype,
			BG.betteam,
			BG.TransDesc   
		FROM bettransg BG with (NOLOCK)  
			INNER JOIN @SportBettype sp ON BG.bettype = sp.bettype AND sp.Productid in (12)
			INNER JOIN @Data B ON BG.CustID = @CustID AND (sp.Productid in (12) AND BG.refno = B.transid AND BG.bettype = B.bettype)

		INSERT INTO @DetailData
		SELECT 
			BG.refno,
			BG.odds, 
			BG.stake,
			BG.status,
			BG.apositiontaking, 
			BG.mpositiontaking, 
			BG.spositiontaking,
			BG.bettype,
			BG.betteam,
			BG.TransDesc    
		FROM bettransg14 BG with (NOLOCK)  
			INNER JOIN @SportBettype sp ON BG.bettype = sp.bettype AND sp.Productid in (4)
			INNER JOIN @Data B ON  (BG.refno = B.refno AND BG.CustID = @CustID AND sp.Productid in (4))
		UNION ALL
		SELECT 
			BG.refno,
			BG.odds, 
			BG.stake,
			BG.status,
			BG.apositiontaking, 
			BG.mpositiontaking, 
			BG.spositiontaking,
			BG.bettype,
			BG.betteam,
			BG.TransDesc    
		FROM bettransg14 BG with (NOLOCK)  
			INNER JOIN @SportBettype sp ON BG.bettype = sp.bettype AND sp.Productid in (12)
			INNER JOIN @Data B ON  (BG.refno = B.transid AND BG.CustID = @CustID AND sp.Productid in (12))
	END

	SELECT	* FROM @Data
	ORDER BY 4, 26
			   
	SELECT * FROM @DetailData
END
GO
GRANT EXECUTE ON [dbo].[Acc_BetListByIP_OtherSports] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_BetListByIP_OtherSports] TO [vnteam]