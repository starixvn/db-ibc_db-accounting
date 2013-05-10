
ALTER PROC [dbo].[Acc_BetListByIP_Soccer]
	@custid		INT, 
	@ip			VARCHAR(15),
	@fromdate	DATETIME 
AS
/*
Created: Phuong Dao
Task : Bet List By IP and Soccer
DB: DB06.bodb02 
Original:Acc_BetListByDayAllIP

Revisions:
	- 20090514@Simon: Remove RefNo
	- 20091002@Simon: Get Odds && OddsType columns.
	- 20091003@Jamie: Remove comstatus out 
	- 20091009@Daniel: Get refund status from bettrans	
	- 20091205@Henry: Get more column: refno for viewing Mix Parlay detail
	- 20101205@Daniel: Fix swap column transid & refno due to diff column order between select statements
	- 20100611@Henry: Change mix-parlay match from 0 to 9
	- 20101201@Henry: Return winlost-actual_stake for column winlost
	- 20110408@Amy: Change function to get Odds value and odds type
	- 20110516@Lukas: re-arrange bettype
	- 20110802@Johnson: - Add column actual_stake into betlist
						- Add new bettype combination mix-parlay
	- 20111122@Sophia: Add Checktime and SecAcceptFlag to show status waiting or running
	- 20120120@Sophia: Add Showtime for Table-hand-shoe of Live Casino
					   Add sub detail for Live Casino
	- 20120426@Lukas: Show transid of mainticket for sub-tickets of system parlay
	- 20120606@Sophia: Change datatype of stake to money
	- 20120626@Elodie: exclude outright from sportbook ( in case of matchid = orid)
	- 20120629@Sophia: Remove function f_GetOddsByBettype, f_ShowOddsByBettype,f_GetChoice for odds, Oddstype, betteam
	- 20120927@Johnson: get commstatus column to check double comm losing
Param's Explanation:
• @fromdate = @winlostdate
*/
SET NOCOUNT ON

  DECLARE @Data TABLE (
        	finalhomescore	INT,
			finalawayscore	INT,
			oddsid			INT,
			leagueid		INT,
			matchid			INT,
			bettype			SMALLINT,
			transid			BIGINT,
			betid			BIGINT,
			refno			BIGINT,
			matchcode		NVARCHAR (50),
			race			NVARCHAR (50), 
			eventdate		DATETIME,
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
			OddsType		INT, 
			status			NVARCHAR (50),
			comstatus		NVARCHAR (20),
			stake			MONEY,
			actual_stake	MONEY,
			transdate		DATETIME,
			betteam			NVARCHAR (10),
			livehomescore	INT,
			liveawayscore	INT,
			liveindicator	INT,
			winlost			MONEY, 
			commission		MONEY, 
			creator			VARCHAR (50),
			username		NVARCHAR (50),
			hthomescore		INT, 
			htawayscore		INT,
			ip				NVARCHAR (15),
			sporttype		INT,
			IsNeutral		BIT,
			showtime		NVARCHAR (50)
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
	betteam			nvarchar(50)
							)  
	INSERT INTO @Data						
	SELECT  finalhomescore,
			finalawayscore,
			oddsid,
			leagueid,
			matchid,
			bettype,
			transid,
			betid,
			refno,
			matchcode,
			race, 
			eventdate,
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
			OddsType, 
			status,
			comstatus,
			stake,
			actual_stake,
			transdate,
			betteam,
			livehomescore,
			liveawayscore,
			liveindicator,
			winlost, 
			commission, 
			creator creator,
			username,
			hthomescore, 
			htawayscore,
			ip,
			1 sporttype,
			IsNeutral,
			showtime
	FROM (
			SELECT
					m.finalhomescore,
					m.finalawayscore,
					b.oddsid,
					m.leagueid,
					b.bettype,
					b.transid,
					b.betid,
					b.refno,
					m.matchcode,
					'' as race, 
					'' as eventdate, 
					b.sdiscount,
					b.adiscount,
					b.discount,
					m.homeid,
					m.awayid,
					ISNULL(b.checktime,'') checktime,
					b.hdp1,
					b.hdp2,
					b.odds, 
					b.modds,
					b.oddstype, 
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
					c.username creator,
					b.username,
					m.hthomescore, m.htawayscore,ip,
					b.matchid,
					m.IsNeutral,
					m.showtime
			FROM 	bettrans14 b with (nolock) 
					INNER JOIN match14 m with (nolock) on b.matchid= m.matchid
					INNER JOIN custInfo c with (nolock) on c.custid = b.creator
			WHERE 	b.winlostdate = @fromdate
					AND bettype < 19001 AND bettype <> 10 --20120626@Elodie: exclude outright from sportbook
					AND b.custid = @custid 
					AND m.sporttype = 1 
			
			UNION ALL 
			SELECT 
					0 finalhomescore,
					0 finalawayscore,
					0,
					0 leagueid,
					9 bettype,
					b.transid,
					b.betid,
					b.refno,
					'' matchcode,
					'' race, 
					'' as eventdate, 
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
					'' OddsType, 
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
					c.username creator,
					b.username,
					0 hthomescore, 0 htawayscore,ip,
					0 matchid,
					0 IsNeutral,
					'' as showtime
			FROM  	bettrans14 b  with (nolock) 
					INNER JOIN custInfo c  with (nolock) on c.custid = b.creator
			WHERE	b.bettype = 9 
					AND b.winlostdate=@fromdate 
					--AND b.matchid=0 
					AND b.matchid = 9
					AND b.custid = @custid 
					AND b.refno IN (SELECT RefNo FROM	bettransm14 bm WITH (nolock)
																INNER JOIN match14 m WITH (nolock) ON bm.matchid = m.MatchID
														WHERE	m.sporttype = 1)
			UNION ALL 
			SELECT 
					0 finalhomescore,
					0 finalawayscore,
					0,
					0 leagueid,
					29 bettype,
					CASE WHEN ISNULL(b.betID,0) = 0 THEN b.transid ELSE b.betID END AS transid,
					b.betid,
					b.refno,
					'' matchcode,
					'' race, 
					'' as eventdate, 
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
					'' OddsType, 
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
					c.username creator,
					b.username,
					0 hthomescore, 0 htawayscore,ip,
					0 matchid,
					0 IsNeutral,
					'' as showtime
			FROM  	bettrans14 b  with (nolock) 
					INNER JOIN custInfo c  with (nolock) on c.custid = b.creator
			WHERE	b.bettype = 29 
					AND b.winlostdate=@fromdate 
					--AND b.matchid=0 
					AND b.matchid = 29
					AND b.custid = @custid 
					AND b.refno IN (SELECT RefNo FROM	bettransm14 bm WITH (nolock)
																INNER JOIN match14 m WITH (nolock) ON bm.matchid = m.MatchID
														WHERE	m.sporttype = 1)
														
			UNION ALL 
			----------------------------------------------------------------------------
			SELECT 	m.finalhomescore,
					m.finalawayscore,
					b.oddsid,
					m.leagueid,
					b.bettype,
					b.transid,
					b.betid,
					b.refno,
					m.matchcode,
					'' race,
					'' as eventdate,
					b.sdiscount,
					b.adiscount,
					b.discount,
					m.homeid,
					m.awayid,
					ISNULL(b.checktime,'') checktime,
					b.hdp1,
					b.hdp2,
					b.odds, 
					b.modds,
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
					c.username creator,
					b.username,
					m.hthomescore, m.htawayscore,ip,
					b.matchid,
					m.IsNeutral,
					m.showtime
			FROM	bettrans b with (nolock) 
					INNER JOIN match m  with (nolock) on b.matchid = m.matchid
					INNER JOIN custInfo c with (nolock) on c.custid = b.creator
			WHERE	b.winlostdate = @fromdate 
					AND b.bettype < 19001 AND bettype <> 10 --20120626@Elodie: exclude outright from sportbook
					AND m.sporttype = 1
					AND b.custid = @custid
	
			UNION ALL
			SELECT	0 finalhomescore,
					0 finalawayscore,
					0,
					0 leagueid,
					9 bettype,
					b.transid,
					b.betid,
					b.refno,
					'' matchcode,
					'' race, 
					'' as eventdate, 
					b.sdiscount,
					b.adiscount,
					b.discount,
					0 homeid,	0 awayid,
					ISNULL(b.checktime,'') checktime,	
					0 hdp1, 0 hdp2,
					b.odds,   
					b.modds,
					'' OddsType, 
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
					c.username creator,
					b.username,
					0 hthomescore, 0 htawayscore,ip,
					b.matchid,
					0 IsNeutral,
					'' as showtime 
			FROM	bettrans b with (nolock) 
					INNER JOIN custInfo c  with (nolock) on c.custid = b.creator
			WHERE	b.winlostdate = @fromdate 
					--AND b.matchid=0 
					AND b.matchid = 9
					AND b.bettype = 9 	
					AND b.custid = @custid
					AND b.refno IN (SELECT RefNo FROM	bettransm bm WITH (nolock)
																INNER JOIN match m WITH (nolock) ON bm.matchid = m.matchid
														WHERE	m.sporttype = 1 )
			
			UNION ALL
			SELECT	0 finalhomescore,
					0 finalawayscore,
					0,
					0 leagueid,
					29 bettype,
					CASE WHEN ISNULL(b.betID,0) = 0 THEN b.transid ELSE b.betID END AS transid,
					b.betid,
					b.refno,
					'' matchcode,
					'' race, 
					'' as eventdate, 
					b.sdiscount,
					b.adiscount,
					b.discount,
					0 homeid,	0 awayid,
					ISNULL(b.checktime,'') checktime,	
					0 hdp1, 0 hdp2,
					b.odds,   
					b.modds,
					'' OddsType, 
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
					c.username creator,
					b.username,
					0 hthomescore, 0 htawayscore,ip,
					b.matchid,
					0 IsNeutral,
					'' as showtime 
			FROM	bettrans b with (nolock) 
					INNER JOIN custInfo c  with (nolock) on c.custid = b.creator
			WHERE	b.winlostdate = @fromdate 
					--AND b.matchid=0 
					AND b.matchid = 29
					AND b.bettype = 29 	
					AND b.custid = @custid
					AND b.refno IN (SELECT RefNo FROM	bettransm bm WITH (nolock)
																INNER JOIN match m WITH (nolock) ON bm.matchid = m.matchid
														WHERE	m.sporttype = 1 )
																											
			--- OUTRIGHT
			UNION ALL
			SELECT	0 finalhomescore,
					0 finalawayscore, 
					0 oddsid, 
					odds.leagueid,
					b.bettype, 
					b.transid,
					b.betid,
					b.refno,
					odds.matchcode, 
					odds.groupmatch as race, --phuong.nguyen, get HR race
					odds.eventdate as eventdate, --phuong.nguyen
					b.sdiscount,
					b.adiscount,
					b.discount,
					0 homeid,
					odds.teamid awayid,
					ISNULL(b.checktime,'') checktime,
					b.hdp1, --phuong.nguyen <2008-12-30>
					b.hdp2, --end
					b.odds,   
					b.modds,
					'' OddsType, 
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
					b.matchid,
					0 IsNeutral,
					'' as showtime 
			FROM	 
					bettrans b with (nolock)
					INNER JOIN outright odds with (nolock) on b.matchid = odds.orid
					INNER JOIN league l with (nolock) on odds.leagueid = l.leagueid
					INNER JOIN Sports s WITH (nolock) ON l.sporttype = s.sporttype 
			WHERE	b.bettype = 10 
					AND b.winlostdate = @fromdate
					AND b.custid = @custid 
					AND s.sporttype = 1 

			--- OUTRIGHT 14
			UNION ALL
			SELECT	0 finalhomescore,
					0 finalawayscore, 
					0 oddsid, 
					odds.leagueid,
					b.bettype, 
					b.transid,
					b.betid,
					b.refno,
					odds.matchcode, 
					odds.groupmatch as race, --phuong.nguyen, get HR bet list,
					odds.eventdate as eventdate, --phuong.nguyen
					b.sdiscount,
					b.adiscount,
					b.discount,
					0 homeid,
					odds.teamid awayid,
					ISNULL(b.checktime,'') checktime,
					b.hdp1, --phuong.nguyen <2008-12-30>
					b.hdp2, --end
					b.odds,   
					b.modds,
					'' OddsType, 
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
					b.matchid,
					0 IsNeutral,
					'' as showtime
			FROM 	bettrans14 b with (nolock)
					INNER JOIN outright14 odds with (nolock) on b.matchid = odds.orid
					INNER JOIN league l with (nolock) on odds.leagueid = l.leagueid
					INNER JOIN Sports s WITH (nolock) ON l.sporttype = s.sporttype 
			WHERE	b.bettype = 10
					AND b.winlostdate = @fromdate
					AND b.custid = @custid
					AND s.SportType = 1 
	) x

WHERE ip=@ip


SELECT * FROM @Data
ORDER BY 4,26

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
		BG.betteam  
	FROM bettransg BG with (NOLOCK)
	INNER JOIN @Data B ON BG.refno = B.refno
	WHERE B.Bettype between 1101 and 1199
		   

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
		BG.betteam  
	FROM bettransg14 BG with (NOLOCK)
	INNER JOIN @Data B ON BG.refno = B.refno
	WHERE B.Bettype between 1101 and 1199
				   
 SELECT * FROM @DetailData
  
GO
GRANT EXECUTE ON [dbo].[Acc_BetListByIP_Soccer] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_BetListByIP_Soccer] TO [vnteam]