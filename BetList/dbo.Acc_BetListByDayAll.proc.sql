ALTER PROCEDURE [dbo].[Acc_BetListByDayAll]
	@custid int,
	@fromdate smalldatetime,
	@language nvarchar(2) = 'en',
	@transid bigint = 0,
	@transtype INT=0
AS

/*
	Created by: [Creator]
	Date: 2008
	Task: Bet list by date 
	DB: DB053.BODB02 
	
	Revisions:
		- 20081218@PhuongNguyen: Get Isneutral from Match
		- 20081223@PhuongNguyen: Get sdiscount, adiscount, discount, placing
		- 20081230@PhuongNguyen: Get livehomescore, liveawayscore, hdp1, hdp2 for Horse Racing
		- 20081231@PhuongNguyen: Remove placing
		- 20090109@PhuongNguyen: Get eventdate
		- 20090408@PhuongDao: Get checktime as SettleTime
		- 20090508@PhuongDao: Get username form bettrans and bettrans14 table
		- 20090509@Simon: Bet List For Casino
		- 20090528@PhuongDao: Add HR Fixed Odd 
		- 20091002@Simon: Get Odds && OddsType columns.
		- 20091003@Jamie: Remove comstatus out 
		- 20091009@Daniel: Get refund status from bettrans
		- 20091015@Shifu: Get refno for Casino
		- 20091023@Simon: Displays Odds at Bet/Settle time
		- 20091205@Henry: Get more column: refno for viewing Mix Parlay detail
		- 20100306@Daniel: Query all @FromDate on winlostdate to support Finacial tickets
		- 20100409@Daniel: Support Mini game
		- 20100501@Daniel: Remove support Mini game
		- 20100524@Jamie: Show currency2's exchange rate for OpenTote 
		- 20100603@Jamie: Change datatype transid to bigint
		- 20100611@Henry: Change mix-parlay match from 0 to 9
		- 20100907@Henry: Add IBC Bingo bettype
		- 20101007@Henry: Change column transid from INT to BIGINT
		- 20101130@Henry: Add column betid for number game
		- 20101201@Henry: Return winlost-actual_stake for column winlost
		- 20110408@Amy: Change function to get Odds value and odds type
		- 20110513@Lukas: re-arrange bettype
		- 20110705@Tom:Add new parameter @transtype and modify method get creator of the bet transaction
		- 20110711@Johnson: show exchange rate for SA Tote(Pool Currency)
		- 20110725@Lukas: Get refund tickets when transtype = 1
		- 20110802@Johnson: - Add new bettype combination mix parlay.
							- Add new column actual_stake for betlist
		- 20110810@Jamie: Get betteam for Combination Parlay
		- 20111122@Sophia: Add Checktime and SecAcceptFlag to show status waiting or running
		- 20111207@Sophia: Add P2P
		- 20120120@Sophia: Add Showtime for Table-hand-shoe of Live Casino
							Add sub detail for Live Casino
		- 20120405@Hurri: Exclude bettype 72 (P2P bet ticket) in the calculation of Casino
		- 20120416@Johnson: Correct column transid for p2p
		- 20120423@Lukas: show transid of main ticket for all subticket of system parlay
		- 20120528@Lukas: return refno for matchcode column (temporarily fix)
		- 20120606@Sophia: Change datatype of stake to money
		- 20120626@Elodie: exclude outright, HR from sportbook ( in case of matchid = orid)
		- 20120629@Sophia: Remove function f_GetOddsByBettype, f_ShowOddsByBettype,f_GetChoice for odds, Oddstype, betteam
		- 20120927@Johnson: get commstatus column to check double comm losing
		- 20130227@Elodie: Add Virtual HR product
		- 20130625@Elodie: Not apply Virtual HR for bet list by IP yet at this time	
		- 20130718@Elodie: Apply core betlist
		- 20140306@Dom: Add Keno
		- 20140908@Dom:	[Redmine #22012] Update VS conditions
		
	Param's Explanation:   
		+ @transtype: 1-Betting Statement; 2-VOID/Cancelled Bet; 3-Outstanding Bet   		
*/

BEGIN
    SET NOCOUNT ON;
    DECLARE @tmpStatus TABLE (
        [statusID] TINYINT);
    IF (@transtype = 1)
        BEGIN
            INSERT INTO @tmpStatus ([statusID])
            SELECT 111
            UNION ALL
            SELECT 112
            UNION ALL
            SELECT 113
			UNION ALL
			SELECT 103
        END
    ELSE
        IF (@transtype = 2)
            BEGIN
                INSERT INTO @tmpStatus ([statusID])
                SELECT 101
                UNION ALL
                SELECT 102;
            END
        ELSE
            IF (@transtype = 3)
                BEGIN
                    INSERT INTO @tmpStatus ([statusID])
                    SELECT 0
                    UNION ALL
                    SELECT 1;
                END
    DECLARE @Data TABLE (
        SportType      INT           ,
        leagueid       INT           ,
        homeid         INT           ,
        awayid         INT           ,
        matchcode      NVARCHAR (50) ,
        race           NVARCHAR (50) , --phuong.nguyen, add new field for Horse Racing race
        eventdate      DATETIME      , --phuong.nguyen, get eventdate
        virtualrate    FLOAT         , -- in case OpenToe, it's currency2's exchange rate 
        isShowOTExRate BIT           , -- Show OpenTote currency2's exchange rate or not 
        sdiscount      DECIMAL (9, 8),
        adiscount      DECIMAL (9, 8),
        discount       DECIMAL (9, 8),
        settletime     DATETIME      ,
        matchid        INT           ,
        transid        BIGINT        ,
        betid          BIGINT        ,
        refno          BIGINT        ,
        transdate      DATETIME      ,
        OddsId         INT           ,
        bettype        SMALLINT      ,
        hdp1           SMALLMONEY    ,
        hdp2           SMALLMONEY    ,
        odds           SMALLMONEY    ,
        modds          SMALLMONEY    ,
        finalodds      SMALLMONEY    ,
        finalodds2     SMALLMONEY    ,
        oddstype       INT           ,
        betteam        NVARCHAR (10) ,
        status         NVARCHAR (50) ,
        betstatus      NVARCHAR (50) ,
        comstatus	   NVARCHAR(50)	 ,
        stake          MONEY         ,
        actual_stake   MONEY		 ,
        winlost        MONEY         ,
        commission     MONEY         ,
        livehomescore  INT           ,
        liveawayscore  INT           ,
        liveindicator  BIT           ,
        finalhomescore INT           ,
        finalawayscore INT           ,
        hthomescore    INT           ,
        htawayscore    INT           ,
        Creator        VARCHAR (50)  ,
        ip             NVARCHAR (15) ,
        Username       VARCHAR (50)  ,
        IsNeutral      BIT           ,
        showtime		NVARCHAR(50) ,
        spositiontaking smallmoney,
		mpositiontaking smallmoney,
		apositiontaking smallmoney,
		spositiontaking2 smallmoney,
		mpositiontaking2 smallmoney,
		apositiontaking2 smallmoney,
		betfrom			nvarchar (1),
		scomm			money,	
		acomm			money,
		comm			money,
		awinlost		money,
		mwinlost		money,
		swinlost		money,
		winlostdate		smalldatetime
        );
        
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
        
    IF EXISTS (SELECT 1
               FROM   match14 WITH (NOLOCK)
               WHERE  eventdate = @fromdate)
        BEGIN
            -- single bet
            INSERT INTO @Data
            SELECT m.sporttype,
                   m.leagueid,
                   m.homeid,
                   m.awayid,
                   m.matchcode,
                   '' AS race, --phuong.nguyen, add Horse Racing race,
                   '' AS eventdate, --get eventdate
                   0,
                   0,
                   b.sdiscount,
                   b.adiscount,
                   b.discount,
                   ISNULL(b.checktime, '') AS settletime,
                   m.matchid,
                   b.transid,
                   ISNULL(b.BetID, 0),
                   b.refno,
                   b.transdate,
                   b.oddsid,
                   b.bettype,
                   b.hdp1,
                   b.hdp2,
                   b.odds,
                   b.modds,
                   0 AS finalodds,
                   0 AS finalodds2,
                   b.oddstype,
                   b.betteam,
                   b.status,
                   m.betstatus,
                   CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,                                      
                   b.stake,
                   b.actual_stake,
                   (b.winlost - b.actual_stake) AS winlost,
                   b.playercomm,
                   b.livehomescore,
                   b.liveawayscore,
                   b.liveindicator,
                   m.finalhomescore,
                   m.finalawayscore,
                   m.hthomescore,
                   m.htawayscore,
                   b.CREATOR, --creator.username creator, 
                   b.ip,
                   b.Username,
                   ISNULL(m.isNeutral, CONVERT (BIT, 0)) AS IsNeutral, --phuong.nguyen, get isneutral from Match14
                   m.showtime,
                   0 spositiontaking, -- unuse in this report
				   0 mpositiontaking, -- unuse in this report
				   0 apositiontaking, -- unuse in this report		
				   0 spositiontaking2,-- unuse in this report
				   0 mpositiontaking2,-- unuse in this report
				   0 apositiontaking2,-- unuse in this report
				   b.betfrom,
				   0 scomm, -- unuse in this report			
				   0 acomm, -- unuse in this report			
				   0 comm,	-- unuse in this report	
				   awinlost,		
				   mwinlost,		
				   swinlost,
				   b.winlostdate
            FROM   dbo.bettrans14 AS b WITH (NOLOCK)
                   INNER JOIN
                   dbo.match14 AS m WITH (NOLOCK)
                   ON b.matchid = m.matchid
            --INNER JOIN	customer AS creator WITH (NOLOCK) ON creator.custid = b.creator
            WHERE  b.custid = @custid
                   AND b.winlostdate = @fromdate
                   AND b.bettype < 19001 AND b.bettype NOT IN (10, 31, 32, 33, 41, 42, 43/*, 1231,1232,1233,1237,1238*/) and 
				   b.bettype NOT BETWEEN 1501 and 1599 AND --20120626@Elodie: exclude outright, HR from sportbook
				   b.bettype NOT IN (SELECT  bettype FROM dbo.f_VSHorseRacingByBettype())
                   AND b.statusID IN (SELECT [statusID] FROM   @tmpStatus);
                                      
			-- Virtual HR
            INSERT INTO @Data
            SELECT r.SportType,
                   r.LeagueID,                   
                   o.RacerID as homeid,
                   0 as awayid,
                   o.RacerNum as matchcode,
                   b.oddsid as Race,
                   o.EventDate,
                   0,
                   0,
                   b.sdiscount,
                   b.adiscount,
                   b.discount,
                   ISNULL(b.checktime, '') AS settletime,
                   b.matchid,
                   b.transid,
                   ISNULL(b.BetID, 0),
                   b.refno,
                   b.transdate,
                   b.oddsid,
                   b.bettype,
                   b.hdp1,
                   b.hdp2,
                   b.odds,
                   b.modds,
                   0 AS finalodds,
                   0 AS finalodds2,
                   b.oddstype,
                   '' as betteam,
                   b.status,
                   '' as betstatus,
                   CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,                                      
                   b.stake,
                   b.actual_stake,
                   (b.winlost - b.actual_stake) AS winlost,
                   b.playercomm,
                   b.livehomescore,
                   b.liveawayscore,
                   0 as liveindicator,
                   0 as finalhomescore,
                   0 as finalawayscore,
                   0 as hthomescore,
                   0 as htawayscore,
                   b.CREATOR, --creator.username creator, 
                   b.ip,
                   b.Username,
                   CONVERT (BIT, 0) AS IsNeutral,
                   '' as showtime,
                   0 spositiontaking, -- unuse in this report
				   0 mpositiontaking, -- unuse in this report
				   0 apositiontaking, -- unuse in this report		
				   0 spositiontaking2,-- unuse in this report
				   0 mpositiontaking2,-- unuse in this report
				   0 apositiontaking2,-- unuse in this report
				   b.betfrom,
				   0 scomm, -- unuse in this report			
				   0 acomm, -- unuse in this report			
				   0 comm,	-- unuse in this report	
				   awinlost,		
				   mwinlost,		
				   swinlost,
				   b.winlostdate
            FROM   dbo.bettrans14 b WITH (NOLOCK)
                   INNER JOIN VSOutright14 o WITH (NOLOCK) ON b.oddsid = o.Orid
                   INNER JOIN VSRaceInfo r WITH (NOLOCK) ON r.EventID = o.EventID
            WHERE  b.custid = @custid
                   AND b.winlostdate = @fromdate
                   AND b.bettype in (/*1231, 1232, 1233, 1237, 1238*/SELECT bettype FROM dbo.f_VSHorseRacingByBettype())
                   AND b.statusID IN (SELECT statusID FROM @tmpStatus)
                                      						                                   
            -- CASINO 
            INSERT INTO @Data
            SELECT 251, --sporttype,
                   0, --leagueid,
                   0, --homeid,
                   0, --awayid,		
                   CONVERT (VARCHAR (50), b.refno) AS matchcode, --matchcode, 
                   '' AS race,
                   '' AS eventdate, --get eventdate
                   0,
                   0,
                   b.sdiscount,
                   b.adiscount,
                   b.discount,
                   ISNULL(b.checktime, '') AS settletime,
                   0, --matchid, 
                   b.refno AS transid,
                   ISNULL(b.BetID, 0),
                   b.refno,
                   b.transdate,
                   b.oddsid,
                   b.bettype,
                   b.hdp1,
                   b.hdp2,
                   b.odds,
                   b.modds,
                   0 AS finalodds,
                   0 AS finalodds2,
                   '' AS oddstype,
                   b.betteam,
                   b.status AS status,
                   '' AS betstatus, --m.betstatus, 
                   CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,                  
                   b.stake,
                   b.actual_stake,
                   (b.winlost - b.actual_stake) AS winlost,
                   b.playercomm,
                   b.livehomescore,
                   b.liveawayscore,
                   b.liveindicator,
                   0, --finalhomescore, 
                   0, --finalawayscore, 
                   0, --hthomescore, 
                   0, --htawayscore,
                   b.CREATOR, --creator.username creator, 
                   b.ip,
                   b.Username,
                   0 AS IsNeutral,
                   '' AS showtime,
                   0 spositiontaking, -- unuse in this report
				   0 mpositiontaking, -- unuse in this report
				   0 apositiontaking, -- unuse in this report		
				   0 spositiontaking2,-- unuse in this report
				   0 mpositiontaking2,-- unuse in this report
				   0 apositiontaking2,-- unuse in this report
				   b.betfrom,
				   0 scomm, -- unuse in this report			
				   0 acomm, -- unuse in this report			
				   0 comm,	-- unuse in this report	
				   awinlost,		
				   mwinlost,		
				   swinlost,
				   b.winlostdate
            FROM   dbo.bettrans14 AS b WITH (NOLOCK)
            --INNER JOIN	customer AS creator WITH (NOLOCK) ON creator.custid = b.creator
            WHERE  b.custid = @custid
                   AND b.winlostdate = @fromdate
                   AND bettype = 71								--20120405@Hurri
                   AND b.statusID IN (SELECT [statusID]
                                      FROM   @tmpStatus);
            -- IBC Bingo 
            INSERT INTO @Data
            SELECT 252, --sporttype,
                   0, --leagueid,
                   0, --homeid,
                   0, --awayid,		
                   CONVERT (VARCHAR (50), b.refno) AS matchcode, --matchcode, 
                   '' AS race,
                   '' AS eventdate, --get eventdate
                   0,
                   0,
                   b.sdiscount,
                   b.adiscount,
                   b.discount,
                   ISNULL(b.checktime, '') AS settletime,
                   0, --matchid, 
                   b.refno AS transid,
                   ISNULL(b.BetID, 0),
                   b.refno,
                   b.transdate,
                   b.oddsid,
                   b.bettype,
                   b.hdp1,
                   b.hdp2,
                   b.odds,
                   b.modds,
                   0 AS finalodds,
                   0 AS finalodds2,
                   '' AS oddstype,
                   b.betteam,
                   b.status AS status,
                   '' AS betstatus, --m.betstatus, 
                   CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,                  
                   b.stake,
                   b.actual_stake,
                   (b.winlost - b.actual_stake) AS winlost,
                   b.playercomm,
                   b.livehomescore,
                   b.liveawayscore,
                   b.liveindicator,
                   0, --finalhomescore, 
                   0, --finalawayscore, 
                   0, --hthomescore, 
                   0, --htawayscore,
                   b.CREATOR, --creator.username creator, 
                   b.ip,
                   b.Username,
                   0 AS IsNeutral,
                   '' AS showtime,
                   0 spositiontaking, -- unuse in this report
				   0 mpositiontaking, -- unuse in this report
				   0 apositiontaking, -- unuse in this report		
				   0 spositiontaking2,-- unuse in this report
				   0 mpositiontaking2,-- unuse in this report
				   0 apositiontaking2,-- unuse in this report
				   b.betfrom,
				   0 scomm, -- unuse in this report			
				   0 acomm, -- unuse in this report			
				   0 comm,	-- unuse in this report	
				   awinlost,		
				   mwinlost,		
				   swinlost,
				   b.winlostdate
            FROM   dbo.bettrans14 AS b WITH (NOLOCK)
            --INNER JOIN customer AS creator WITH (NOLOCK)	ON creator.custid = b.creator
            WHERE  b.custid = @custid
                   AND b.winlostdate = @fromdate
                   AND bettype = 73
                   AND b.statusID IN (SELECT [statusID]
                                      FROM   @tmpStatus);
			-- IBC keno 
            INSERT INTO @Data
            SELECT 202, --sporttype,
                   0, --leagueid,
                   0, --homeid,
                   0, --awayid,		
                   CONVERT (VARCHAR (50), b.refno) AS matchcode, --matchcode, 
                   '' AS race,
                   '' AS eventdate, --get eventdate
                   0,
                   0,
                   b.sdiscount,
                   b.adiscount,
                   b.discount,
                   ISNULL(b.checktime, '') AS settletime,
                   d.GameId matchid, --matchid, 
                   b.refno AS transid,
                   ISNULL(b.BetID, 0),
                   b.refno,
                   b.transdate,
                   b.oddsid,
                   b.bettype,
                   b.hdp1,
                   b.hdp2,
                   b.odds,
                   b.modds,
                   0 AS finalodds,
                   0 AS finalodds2,
                   '' AS oddstype,
                   d.ChoiceId betteam,   
                   b.status AS status,
                   '' AS betstatus, --m.betstatus, 
                   CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,                  
                   b.stake,
                   b.actual_stake,
                   (b.winlost - b.actual_stake) AS winlost,
                   b.playercomm,
                   b.livehomescore,
                   b.liveawayscore,
                   b.liveindicator,
                   0, --finalhomescore, 
                   0, --finalawayscore, 
                   0, --hthomescore, 
                   0, --htawayscore,
                   b.CREATOR, --creator.username creator, 
                   b.ip,
                   b.Username,
                   0 AS IsNeutral,
                   '' AS showtime,
                   0 spositiontaking, -- unuse in this report
				   0 mpositiontaking, -- unuse in this report
				   0 apositiontaking, -- unuse in this report		
				   0 spositiontaking2,-- unuse in this report
				   0 mpositiontaking2,-- unuse in this report
				   0 apositiontaking2,-- unuse in this report
				   b.betfrom,
				   0 scomm, -- unuse in this report			
				   0 acomm, -- unuse in this report			
				   0 comm,	-- unuse in this report	
				   awinlost,		
				   mwinlost,		
				   swinlost,
				   b.winlostdate
            FROM   dbo.bettrans14 AS b WITH (NOLOCK)
			outer apply dbo.[f_ParseTransDesc](b.TransDesc, b.bettype) d
            --INNER JOIN customer AS creator WITH (NOLOCK)	ON creator.custid = b.creator
            WHERE  b.custid = @custid
                   AND b.winlostdate = @fromdate
                   AND bettype BETWEEN 1501 and 1599
                   AND b.statusID IN (SELECT [statusID]
                                      FROM   @tmpStatus);
			
			-- P2P 
            INSERT INTO @Data
            SELECT 253, --sporttype,
                   0, --leagueid,
                   0, --homeid,
                   0, --awayid,		
                   '' matchcode, --matchcode, 
                   '' AS race,
                   '' AS eventdate, --get eventdate
                   0,
                   0,
                   b.sdiscount,
                   b.adiscount,
                   b.discount,
                   ISNULL(b.checktime, '') AS settletime,
                   0, --matchid, 
                   b.transid,
                   ISNULL(b.BetID, 0),
                   b.refno,
                   b.transdate,
                   b.oddsid,
                   b.bettype,
                   b.hdp1,
                   b.hdp2,
                   b.odds,
                   b.modds,
                   0 AS finalodds,
                   0 AS finalodds2,
                   '' AS oddstype,
                   b.betteam,
                   b.status AS status,
                   '' AS betstatus, --m.betstatus, 
                   CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,                  
                   b.stake,
                   b.actual_stake,
                   (b.winlost - b.actual_stake) AS winlost,
                   b.playercomm,
                   b.livehomescore,
                   b.liveawayscore,
                   b.liveindicator,
                   0, --finalhomescore, 
                   0, --finalawayscore, 
                   0, --hthomescore, 
                   0, --htawayscore,
                   b.CREATOR, --creator.username creator, 
                   b.ip,
                   b.Username,
                   0 AS IsNeutral,
                   '' AS showtime,
                   0 spositiontaking, -- unuse in this report
				   0 mpositiontaking, -- unuse in this report
				   0 apositiontaking, -- unuse in this report		
				   0 spositiontaking2,-- unuse in this report
				   0 mpositiontaking2,-- unuse in this report
				   0 apositiontaking2,-- unuse in this report
				   b.betfrom,
				   0 scomm, -- unuse in this report			
				   0 acomm, -- unuse in this report			
				   0 comm,	-- unuse in this report	
				   awinlost,		
				   mwinlost,		
				   swinlost,
				   b.winlostdate
            FROM   dbo.bettrans14 AS b WITH (NOLOCK)
            --INNER JOIN	customer AS creator WITH (NOLOCK) ON creator.custid = b.creator
            WHERE  b.custid = @custid
                   AND b.winlostdate = @fromdate
                   AND bettype = 1000
                   AND b.statusID IN (SELECT [statusID]
                                      FROM   @tmpStatus);

            -- mixed parlay
            INSERT INTO @Data
            SELECT 0,
                   0,
                   0,
                   0,
                   '',
                   '' AS race,
                   '' AS eventdate, --get eventdate
                   0,
                   0,
                   b.sdiscount,
                   b.adiscount,
                   b.discount,
                   ISNULL(b.checktime, '') AS settletime,
                   0,
                   b.transid,
                   ISNULL(b.BetID, 0),
                   b.refno,
                   b.transdate,
                   0,
                   9,
                   0,
                   0,
                   b.odds,
                   b.modds,
                   0 AS finalodds,
                   0 AS finalodds2,
                   '' AS oddstype,
                   '',
                   b.status,
                   '' AS betstatus,
                   CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,                  
                   b.stake,
                   b.actual_stake,
                   (b.winlost - b.actual_stake) AS winlost,
                   b.playercomm,
                   0,
                   0,
                   0,
                   0,
                   0,
                   0,
                   0,
                   b.CREATOR, --creator.username creator, 
                   b.ip,
                   b.Username,
                   CONVERT (BIT, 0) AS IsNeutral,
                   '' AS showtime,
                   0 spositiontaking, -- unuse in this report
				   0 mpositiontaking, -- unuse in this report
				   0 apositiontaking, -- unuse in this report		
				   0 spositiontaking2,-- unuse in this report
				   0 mpositiontaking2,-- unuse in this report
				   0 apositiontaking2,-- unuse in this report
				   b.betfrom,
				   0 scomm, -- unuse in this report			
				   0 acomm, -- unuse in this report			
				   0 comm,	-- unuse in this report	
				   awinlost,		
				   mwinlost,		
				   swinlost,
				   b.winlostdate
            FROM   dbo.bettrans14 AS b WITH (NOLOCK)
            --INNER JOIN customer AS creator WITH (NOLOCK)	ON creator.custid = b.creator
            WHERE  b.custid = @custid
                   AND b.winlostdate = @fromdate
                   --and b.matchid=0 
                   AND b.matchid = 9
                   AND b.bettype = 9
                   AND b.statusID IN (SELECT [statusID]
                                      FROM   @tmpStatus);
            
            -- combination mixed parlay
            INSERT INTO @Data
            SELECT 0,
                   0,
                   0,
                   0,
                   '',
                   '' AS race,
                   '' AS eventdate, --get eventdate
                   0,
                   0,
                   b.sdiscount,
                   b.adiscount,
                   b.discount,
                   ISNULL(b.checktime, '') AS settletime,
                   0,
                   CASE WHEN ISNULL(b.betID,0) = 0 THEN b.transid ELSE b.betID END AS transid,
                   ISNULL(b.BetID, 0),
                   b.refno,
                   b.transdate,
                   0,
                   29,
                   0,
                   0,
                   b.odds,
                   b.modds,
                   0 AS finalodds,
                   0 AS finalodds2,
                   '' AS oddstype,
                   b.betteam,
                   b.status,
                   '' AS betstatus,
                   CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,   
                   b.stake,
                   b.actual_stake,
                   (b.winlost - b.actual_stake) AS winlost,
                   b.playercomm,
                   0,
                   0,
                   0,
                   0,
                   0,
                   0,
                   0,
                   b.CREATOR, --creator.username creator, 
                   b.ip,
                   b.Username,
                   CONVERT (BIT, 0) AS IsNeutral,
                   '' AS showtime,
                   0 spositiontaking, -- unuse in this report
				   0 mpositiontaking, -- unuse in this report
				   0 apositiontaking, -- unuse in this report		
				   0 spositiontaking2,-- unuse in this report
				   0 mpositiontaking2,-- unuse in this report
				   0 apositiontaking2,-- unuse in this report
				   b.betfrom,
				   0 scomm, -- unuse in this report			
				   0 acomm, -- unuse in this report			
				   0 comm,	-- unuse in this report	
				   awinlost,		
				   mwinlost,		
				   swinlost,
				   b.winlostdate
            FROM   dbo.bettrans14 AS b WITH (NOLOCK)
            --INNER JOIN customer AS creator WITH (NOLOCK)	ON creator.custid = b.creator
            WHERE  b.custid = @custid
                   AND b.winlostdate = @fromdate
                   --and b.matchid=0 
                   AND b.matchid = 29
                   AND b.bettype = 29
                   AND b.statusID IN (SELECT [statusID]
                                      FROM   @tmpStatus);
                                      
            -- outright
            INSERT INTO @Data
            SELECT l.sporttype,
                   o.leagueid,
                   o.teamid,
                   0,
                   o.matchcode,
                   o.groupmatch AS race,
                   o.eventdate AS eventdate, --get eventdate
                   b.virtualrate,
                   --ISNUMERIC(o.programID),
                   CASE WHEN b.currency2 IS NULL THEN CONVERT(BIT,0) ELSE CONVERT(BIT,1) END AS isShowOTExRate,
                   b.sdiscount,
                   b.adiscount,
                   b.discount,
                   ISNULL(b.checktime, '') AS settletime,
                   '',
                   b.transid,
                   ISNULL(b.BetID, 0),
                   b.refno,
                   b.transdate,
                   o.orid,
                   b.bettype,
                   b.hdp1,
                   b.hdp2, --end
                   b.odds,
                   b.modds,
                   bmOdd.finalodds,
                   bmOdd.finalodds2,
                   '' AS oddstype,
                   '',
                   b.status,
                   '',
                   CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,   
                   b.stake,
                   b.actual_stake,
                   (b.winlost - b.actual_stake) AS winlost,
                   b.playercomm,
                   b.livehomescore,
                   b.liveawayscore, --end
                   0,
                   0,
                   0,
                   0,
                   0,
                   b.CREATOR, --creator.username creator, 
                   b.ip,
                   b.Username,
                   CONVERT (BIT, 0) AS IsNeutral,
                   '' AS showtime,
                   0 spositiontaking, -- unuse in this report
				   0 mpositiontaking, -- unuse in this report
				   0 apositiontaking, -- unuse in this report		
				   0 spositiontaking2,-- unuse in this report
				   0 mpositiontaking2,-- unuse in this report
				   0 apositiontaking2,-- unuse in this report
				   b.betfrom,
				   0 scomm, -- unuse in this report			
				   0 acomm, -- unuse in this report			
				   0 comm,	-- unuse in this report	
				   awinlost,		
				   mwinlost,		
				   swinlost,
				   b.winlostdate
            FROM   dbo.bettrans14 AS b WITH (NOLOCK)
                   INNER JOIN
                   dbo.outright14 AS o WITH (NOLOCK)
                   ON b.matchid = o.orid
                   INNER JOIN
                   dbo.league AS l WITH (NOLOCK)
                   ON o.leagueid = l.leagueid
                   --INNER JOIN	customer AS creator WITH (NOLOCK)	ON creator.custid = b.creator
                   LEFT OUTER JOIN
                   (SELECT t.refno,
                           t.finalodds,
                           f.finalodds AS finalodds2
                    FROM   bettransm14 AS t WITH (NOLOCK)
                           INNER JOIN
                           bettransm14 AS f WITH (NOLOCK)
                           ON t.refno = f.refno
                    WHERE  t.bettype = 41
                           AND f.bettype = 42) AS bmOdd
                   ON b.transid = bmOdd.refno
            WHERE  b.custid = @custid
                   AND b.bettype IN (10, 31, 32, 33, 41, 42, 43) --phuong.nguyen, get HR bet list
                   AND b.winlostdate = @fromdate
                   AND b.statusID IN (SELECT [statusID]
                                      FROM   @tmpStatus);
        END
    ELSE
        BEGIN
            -- single bet
            INSERT INTO @Data
            SELECT m.sporttype,
                   m.leagueid,
                   m.homeid,
                   m.awayid,
                   m.matchcode,
                   '' AS race,
                   '' AS eventdate, --get eventdate
                   0,
                   0,
                   b.sdiscount,
                   b.adiscount,
                   b.discount,
                   ISNULL(b.checktime, '') AS settletime,
                   m.matchid,
                   b.transid,
                   ISNULL(b.BetID, 0),
                   b.refno,
                   b.transdate,
                   b.oddsid,
                   b.bettype,
                   b.hdp1,
                   b.hdp2,
                   b.odds,
                   b.modds,
                   0 AS finalodds,
                   0 AS finalodds2,
                   b.oddstype,
                   b.betteam,
                   CASE WHEN b.status = 'running' AND IsNull(b.SecAcceptFlag, 0) = 1 and IsNull(b.checktime, CURRENT_TIMESTAMP) > CURRENT_TIMESTAMP THEN 'waiting'
						ELSE b.status 
				   END as status,
                   m.betstatus,
                   CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,   
                   b.stake,
                   b.actual_stake,
                   (b.winlost - b.actual_stake) AS winlost,
                   b.playercomm,
                   b.livehomescore,
                   b.liveawayscore,
                   b.liveindicator,
                   m.finalhomescore,
                   m.finalawayscore,
                   m.hthomescore,
                   m.htawayscore,
                   b.CREATOR, --creator.username creator, 
                   b.ip,
                   b.Username,
                   ISNULL(m.isNeutral, CONVERT (BIT, 0)) AS IsNeutral, --phuong.nguyen, get isneutral from Match
                   m.showtime,
                   0 spositiontaking, -- unuse in this report
				   0 mpositiontaking, -- unuse in this report
				   0 apositiontaking, -- unuse in this report		
				   0 spositiontaking2,-- unuse in this report
				   0 mpositiontaking2,-- unuse in this report
				   0 apositiontaking2,-- unuse in this report
				   b.betfrom,
				   0 scomm, -- unuse in this report			
				   0 acomm, -- unuse in this report			
				   0 comm,	-- unuse in this report	
				   awinlost,		
				   mwinlost,		
				   swinlost,
				   b.winlostdate
            FROM   dbo.bettrans AS b WITH (NOLOCK)
                   INNER JOIN
                   dbo.match AS m WITH (NOLOCK)
                   ON b.matchid = m.matchid
            --INNER JOIN	customer AS creator WITH (NOLOCK)	ON creator.custid = b.creator
            --phuong.nguyen, remove left join match_remark
            WHERE  b.custid = @custid
                   AND b.winlostdate = @fromdate
                   AND b.bettype < 19001 AND b.bettype not in (10,31,32,33,41,42,43/*,1231,1232,1233,1237,1238*/)
				   AND b.bettype not BETWEEN 1501 and 1599 --20120626@Elodie: exclude outright, HR from sportbook
				   AND b.bettype NOT IN (SELECT  bettype FROM dbo.f_VSHorseRacingByBettype())
                   AND b.statusID IN (SELECT [statusID] FROM   @tmpStatus)

			-- Virtual HR
            INSERT INTO @Data
            SELECT r.SportType,
                   r.LeagueID,
                   o.RacerID as homeid,
                   0 as awayid,
                   o.RacerNum as matchcode,
                   b.oddsid as Race,
                   o.EventDate,
                   0,
                   0,
                   b.sdiscount,
                   b.adiscount,
                   b.discount,
                   ISNULL(b.checktime, '') AS settletime,
                   b.matchid,
                   b.transid,
                   ISNULL(b.BetID, 0),
                   b.refno,
                   b.transdate,
                   b.oddsid,
                   b.bettype,
                   b.hdp1,
                   b.hdp2,
                   b.odds,
                   b.modds,
                   0 AS finalodds,
                   0 AS finalodds2,
                   b.oddstype,
                   '' as betteam,
                   b.status,
                   '' as betstatus,
                   CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,                                      
                   b.stake,
                   b.actual_stake,
                   (b.winlost - b.actual_stake) AS winlost,
                   b.playercomm,
                   b.livehomescore,
                   b.liveawayscore,
                   0 as liveindicator,
                   0 as finalhomescore,
                   0 as finalawayscore,
                   0 as hthomescore,
                   0 as htawayscore,
                   b.CREATOR, --creator.username creator, 
                   b.ip,
                   b.Username,
                   CONVERT (BIT, 0) AS IsNeutral,
                   '' as showtime,
                   0 spositiontaking, -- unuse in this report
				   0 mpositiontaking, -- unuse in this report
				   0 apositiontaking, -- unuse in this report		
				   0 spositiontaking2,-- unuse in this report
				   0 mpositiontaking2,-- unuse in this report
				   0 apositiontaking2,-- unuse in this report
				   b.betfrom,
				   0 scomm, -- unuse in this report			
				   0 acomm, -- unuse in this report			
				   0 comm,	-- unuse in this report	
				   awinlost,		
				   mwinlost,		
				   swinlost,
				   b.winlostdate
            FROM   dbo.bettrans b WITH (NOLOCK)
                   INNER JOIN VSOutright o WITH (NOLOCK) ON b.oddsid = o.Orid
                   INNER JOIN VSRaceInfo r WITH (NOLOCK) ON r.EventID = o.EventID
            WHERE  b.custid = @custid
                   AND b.winlostdate = @fromdate
                   AND b.bettype in (/*1231, 1232, 1233, 1237, 1238*/SELECT  bettype FROM dbo.f_VSHorseRacingByBettype())
                   AND b.statusID IN (SELECT statusID FROM @tmpStatus)
                                                         
            -- CASINO 
            INSERT INTO @Data
            SELECT 251, --sporttype,
                   0, --leagueid,
                   0, --homeid,
                   0, --awayid,		
                   --'' AS matchcode,
					 CONVERT (VARCHAR (50), b.refno) AS matchcode, --matchcode, 
                   '' AS race,
                   '' AS eventdate, --get eventdate
                   0,
                   0,
                   b.sdiscount,
                   b.adiscount,
                   b.discount,
                   '' AS settletime,
                   0, --matchid, 
                   b.refno AS transid,
                   ISNULL(b.BetID, 0),
                   b.refno,
                   b.transdate,
                   b.oddsid,
                   b.bettype,
                   b.hdp1,
                   b.hdp2,
                   b.odds,
                   b.modds,
                   0 AS finalodds,
                   0 AS finalodds2,
                   '' AS oddstype,
                   b.betteam,
                   b.status,
                   '' AS betstatus, --m.betstatus, 
                   CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,   
                   b.stake,
                   b.actual_stake,
                   (b.winlost - b.actual_stake) AS winlost,
                   b.playercomm,
                   b.livehomescore,
                   b.liveawayscore,
                   b.liveindicator,
                   0, --finalhomescore, 
                   0, --finalawayscore, 
                   0, --hthomescore, 
                   0, --htawayscore,
                   b.CREATOR, --creator.username creator, 
                   b.ip,
                   b.Username,
                   0 AS IsNeutral,
                   '' AS showtime,
                   0 spositiontaking, -- unuse in this report
				   0 mpositiontaking, -- unuse in this report
				   0 apositiontaking, -- unuse in this report		
				   0 spositiontaking2,-- unuse in this report
				   0 mpositiontaking2,-- unuse in this report
				   0 apositiontaking2,-- unuse in this report
				   b.betfrom,
				   0 scomm, -- unuse in this report			
				   0 acomm, -- unuse in this report			
				   0 comm,	-- unuse in this report	
				   awinlost,		
				   mwinlost,		
				   swinlost,
				   b.winlostdate
            FROM   dbo.bettrans AS b WITH (NOLOCK)
            --INNER JOIN	customer AS creator WITH (NOLOCK)	ON creator.custid = b.creator
            WHERE  b.custid = @custid
                   AND b.winlostdate = @fromdate
                   AND bettype = 71								--20120405@Hurri
                   AND b.statusID IN (SELECT [statusID]
                                      FROM   @tmpStatus);
            --ibc bingo	
            INSERT INTO @Data
            SELECT 252, --sporttype,
                   0, --leagueid,
                   0, --homeid,
                   0, --awayid,		
                   CONVERT (VARCHAR (50), b.refno) AS matchcode,
                   '' AS race,
                   '' AS eventdate, --get eventdate
                   0,
                   0,
                   b.sdiscount,
                   b.adiscount,
                   b.discount,
                   '' AS settletime,
                   0, --matchid, 
                   b.refno AS transid,
                   ISNULL(b.BetID, 0),
                   b.refno,
                   b.transdate,
                   b.oddsid,
                   b.bettype,
                   b.hdp1,
                   b.hdp2,
                   b.odds,
                   b.modds,
                   0 AS finalodds,
                   0 AS finalodds2,
                   '' AS oddstype,
                   b.betteam,
                   b.status,
                   '' AS betstatus, --m.betstatus, 
                   CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,   
                   b.stake,
                   b.actual_stake,
                   (b.winlost - b.actual_stake) AS winlost,
                   b.playercomm,
                   b.livehomescore,
                   b.liveawayscore,
                   b.liveindicator,
                   0, --finalhomescore, 
                   0, --finalawayscore, 
                   0, --hthomescore, 
                   0, --htawayscore,
                   b.CREATOR, --creator.username creator, 
                   b.ip,
                   b.Username,
                   0 AS IsNeutral,
                   '' AS showtime,
                   0 spositiontaking, -- unuse in this report
				   0 mpositiontaking, -- unuse in this report
				   0 apositiontaking, -- unuse in this report		
				   0 spositiontaking2,-- unuse in this report
				   0 mpositiontaking2,-- unuse in this report
				   0 apositiontaking2,-- unuse in this report
				   b.betfrom,
				   0 scomm, -- unuse in this report			
				   0 acomm, -- unuse in this report			
				   0 comm,	-- unuse in this report	
				   awinlost,		
				   mwinlost,		
				   swinlost,
				   b.winlostdate
            FROM   dbo.bettrans AS b WITH (NOLOCK)
            --INNER JOIN	customer AS creator WITH (NOLOCK) ON creator.custid = b.creator
            WHERE  b.custid = @custid
                   AND b.winlostdate = @fromdate
                   AND bettype = 73
                   AND b.statusID IN (SELECT [statusID]
                                      FROM   @tmpStatus);
			--ibc keno	
            INSERT INTO @Data
            SELECT 202, --sporttype,
                   0, --leagueid,
                   0, --homeid,
                   0, --awayid,		
                   CONVERT (VARCHAR (50), b.refno) AS matchcode,
                   '' AS race,
                   '' AS eventdate, --get eventdate
                   0,
                   0,
                   b.sdiscount,
                   b.adiscount,
                   b.discount,
                   '' AS settletime,
                   d.GameId matchid, --matchid, 
                   b.refno AS transid,
                   ISNULL(b.BetID, 0),
                   b.refno,
                   b.transdate,
                   b.oddsid,
                   b.bettype,
                   b.hdp1,
                   b.hdp2,
                   b.odds,
                   b.modds,
                   0 AS finalodds,
                   0 AS finalodds2,
                   '' AS oddstype,
                   d.ChoiceId,
                   b.status,
                   '' AS betstatus, --m.betstatus, 
                   CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,   
                   b.stake,
                   b.actual_stake,
                   (b.winlost - b.actual_stake) AS winlost,
                   b.playercomm,
                   b.livehomescore,
                   b.liveawayscore,
                   b.liveindicator,
                   0, --finalhomescore, 
                   0, --finalawayscore, 
                   0, --hthomescore, 
                   0, --htawayscore,
                   b.CREATOR, --creator.username creator, 
                   b.ip,
                   b.Username,
                   0 AS IsNeutral,
                   '' AS showtime,
                   0 spositiontaking, -- unuse in this report
				   0 mpositiontaking, -- unuse in this report
				   0 apositiontaking, -- unuse in this report		
				   0 spositiontaking2,-- unuse in this report
				   0 mpositiontaking2,-- unuse in this report
				   0 apositiontaking2,-- unuse in this report
				   b.betfrom,
				   0 scomm, -- unuse in this report			
				   0 acomm, -- unuse in this report			
				   0 comm,	-- unuse in this report	
				   awinlost,		
				   mwinlost,		
				   swinlost,
				   b.winlostdate
            FROM   dbo.bettrans AS b WITH (NOLOCK)
			outer apply dbo.[f_ParseTransDesc](b.TransDesc, b.bettype) d
            --INNER JOIN	customer AS creator WITH (NOLOCK) ON creator.custid = b.creator
            WHERE  b.custid = @custid
                   AND b.winlostdate = @fromdate
                   AND bettype BETWEEN 1501 AND 1599
                   AND b.statusID IN (SELECT [statusID] FROM   @tmpStatus)
			UNION ALL
			SELECT 202, --sporttype,
                   0, --leagueid,
                   0, --homeid,
                   0, --awayid,		
                   '' AS matchcode,
                   '' AS race,
                   '' AS eventdate, --get eventdate
                   0,
                   0,
                   b.sdiscount,
                   b.adiscount,
                   b.discount,
                   '' AS settletime,
                   d.GameId matchid, --matchid, 
                   0 transid,
                   0 BetID,
                   b.translogid,
                   b.transdate,
                   0 oddsid,
                   b.gameID,
                   0 hdp1,
                   0 hdp2,
                   b.odds,
                   0 modds,
                   0 AS finalodds,
                   0 AS finalodds2,
                   '' AS oddstype,
                   d.ChoiceId betteam,   
                   b.status,
                   '' AS betstatus, --m.betstatus, 
                   0 as comstatus,   
                   b.stake,
                   b.actual_stake,
                   (-b.actual_stake) AS winlost,
                   0 playercomm,
                   0 livehomescore,
                   0 liveawayscore,
                   0 liveindicator,
                   0, --finalhomescore, 
                   0, --finalawayscore, 
                   0, --hthomescore, 
                   0, --htawayscore,
                   b.CREATOR, --creator.username creator, 
                   b.ip,
                   b.Username,
                   0 AS IsNeutral,
                   '' AS showtime,
                   0 spositiontaking, -- unuse in this report
				   0 mpositiontaking, -- unuse in this report
				   0 apositiontaking, -- unuse in this report		
				   0 spositiontaking2,-- unuse in this report
				   0 mpositiontaking2,-- unuse in this report
				   0 apositiontaking2,-- unuse in this report
				   b.betfrom,
				   0 scomm, -- unuse in this report			
				   0 acomm, -- unuse in this report			
				   0 comm,	-- unuse in this report	
				   0 awinlost,		
				   0 mwinlost,		
				   0 swinlost,
				   b.winlostdate
            FROM   dbo.translog AS b WITH (NOLOCK)
			outer apply dbo.[f_ParseTransDesc](b.TransDesc, b.gameid) d
            WHERE  b.custid = @custid
                   AND b.winlostdate = @fromdate
                   AND b.gameID BETWEEN 1501 AND 1599
                   AND b.statusID = 0
				   AND EXISTS(SELECT [statusID] FROM   @tmpStatus t WHERE t.statusID = 0);

		 -- P2P 
            INSERT INTO @Data
            SELECT 253, --sporttype,
                   0, --leagueid,
                   0, --homeid,
                   0, --awayid,		
                   '' AS matchcode,
                   '' AS race,
                   '' AS eventdate, --get eventdate
                   0,
                   0,
                   b.sdiscount,
                   b.adiscount,
                   b.discount,
                   '' AS settletime,
                   0, --matchid, 
                   b.transid,
                   ISNULL(b.BetID, 0),
                   b.refno,
                   b.transdate,
                   b.oddsid,
                   b.bettype,
                   b.hdp1,
                   b.hdp2,
                   b.odds,
                   b.modds,
                   0 AS finalodds,
                   0 AS finalodds2,
                   '' AS oddstype,
                   b.betteam,
                   b.status,
                   '' AS betstatus, --m.betstatus, 
                   CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,   
                   b.stake,
                   b.actual_stake,
                   (b.winlost - b.actual_stake) AS winlost,
                   b.playercomm,
                   b.livehomescore,
                   b.liveawayscore,
                   b.liveindicator,
                   0, --finalhomescore, 
                   0, --finalawayscore, 
                   0, --hthomescore, 
                   0, --htawayscore,
                   b.CREATOR, --creator.username creator, 
                   b.ip,
                   b.Username,
                   0 AS IsNeutral,
                   '' AS showtime,
                   0 spositiontaking, -- unuse in this report
				   0 mpositiontaking, -- unuse in this report
				   0 apositiontaking, -- unuse in this report		
				   0 spositiontaking2,-- unuse in this report
				   0 mpositiontaking2,-- unuse in this report
				   0 apositiontaking2,-- unuse in this report
				   b.betfrom,
				   0 scomm, -- unuse in this report			
				   0 acomm, -- unuse in this report			
				   0 comm,	-- unuse in this report	
				   awinlost,		
				   mwinlost,		
				   swinlost,
				   b.winlostdate
            FROM   dbo.bettrans AS b WITH (NOLOCK)
            --INNER JOIN	customer AS creator WITH (NOLOCK)	ON creator.custid = b.creator
            WHERE  b.custid = @custid
                   AND b.winlostdate = @fromdate
                   AND bettype = 1000
                   AND b.statusID IN (SELECT [statusID]
                                      FROM   @tmpStatus);

            -- mixed parlay
            INSERT INTO @Data
            SELECT 0,
                   0,
                   0,
                   0,
                   '',
                   '' AS race,
                   '' AS eventdate, --get eventdate
                   0,
                   0,
                   b.sdiscount,
                   b.adiscount,
                   b.discount,
                   ISNULL(b.checktime, '') AS settletime,
                   '',
                   b.transid,
                   ISNULL(b.BetID, 0),
                   b.refno,
                   b.transdate,
                   0,
                   9,
                   0,
                   0,
                   b.odds,
                   b.modds,
                   0 AS finalodds,
                   0 AS finalodds2,
                   '' AS oddstype,
                   '',
                   b.status,
                   '' AS betstatus,
                   CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,   
                   b.stake,
                   b.actual_stake,
                   (b.winlost - b.actual_stake) AS winlost,
                   b.playercomm,
                   0,
                   0,
                   0,
                   0,
                   0,
                   0,
                   0,
                   b.CREATOR, --creator.username creator, 
                   b.ip,
                   b.Username,
                   CONVERT (BIT, 0) AS IsNeutral,
                   '' AS showtime,
                   0 spositiontaking, -- unuse in this report
				   0 mpositiontaking, -- unuse in this report
				   0 apositiontaking, -- unuse in this report		
				   0 spositiontaking2,-- unuse in this report
				   0 mpositiontaking2,-- unuse in this report
				   0 apositiontaking2,-- unuse in this report
				   b.betfrom,
				   0 scomm, -- unuse in this report			
				   0 acomm, -- unuse in this report			
				   0 comm,	-- unuse in this report	
				   awinlost,		
				   mwinlost,		
				   swinlost,
				   b.winlostdate
            FROM   dbo.bettrans AS b WITH (NOLOCK)
            --INNER JOIN	customer AS creator WITH (NOLOCK)	ON creator.custid = b.creator
            WHERE  b.custid = @custid
                   AND b.winlostdate = @fromdate
                   --and b.matchid=0 
                   AND b.matchid = 9
                   AND b.bettype = 9
                   AND b.statusID IN (SELECT [statusID]
                                      FROM   @tmpStatus);
			
			 -- combination mixed parlay
            INSERT INTO @Data
            SELECT 0,
                   0,
                   0,
                   0,
                   '',
                   '' AS race,
                   '' AS eventdate, --get eventdate
                   0,
                   0,
                   b.sdiscount,
                   b.adiscount,
                   b.discount,
                   ISNULL(b.checktime, '') AS settletime,
                   '',
                   CASE WHEN ISNULL(b.betID,0) = 0 THEN b.transid ELSE b.betID END AS transid,
                   ISNULL(b.BetID, 0),
                   b.refno,
                   b.transdate,
                   0,
                   29,
                   0,
                   0,
                   b.odds,
                   b.modds,
                   0 AS finalodds,
                   0 AS finalodds2,
                   '' AS oddstype,
                   b.betteam,
                   b.status,
                   '' AS betstatus,
                   CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,   
                   b.stake,
                   b.actual_stake,
                   (b.winlost - b.actual_stake) AS winlost,
                   b.playercomm,
                   0,
                   0,
                   0,
                   0,
                   0,
                   0,
                   0,
                   b.CREATOR, --creator.username creator, 
                   b.ip,
                   b.Username,
                   CONVERT (BIT, 0) AS IsNeutral,
                   '' AS showtime,
                   0 spositiontaking, -- unuse in this report
				   0 mpositiontaking, -- unuse in this report
				   0 apositiontaking, -- unuse in this report		
				   0 spositiontaking2,-- unuse in this report
				   0 mpositiontaking2,-- unuse in this report
				   0 apositiontaking2,-- unuse in this report
				   b.betfrom,
				   0 scomm, -- unuse in this report			
				   0 acomm, -- unuse in this report			
				   0 comm,	-- unuse in this report	
				   awinlost,		
				   mwinlost,		
				   swinlost,
				   b.winlostdate
            FROM   dbo.bettrans AS b WITH (NOLOCK)
            --INNER JOIN	customer AS creator WITH (NOLOCK)	ON creator.custid = b.creator
            WHERE  b.custid = @custid
                   AND b.winlostdate = @fromdate
                   --and b.matchid=0 
                   AND b.matchid = 29
                   AND b.bettype = 29
                   AND b.statusID IN (SELECT [statusID]
                                      FROM   @tmpStatus);
                                                                           
            -- outright
            INSERT INTO @Data
            SELECT l.sporttype,
                   o.leagueid,
                   o.teamid,
                   0,
                   o.matchcode,
                   o.groupmatch AS race,
                   o.eventdate AS eventdate, --get eventdate
                   b.virtualrate,
                   --ISNUMERIC(o.programID),
                  CASE WHEN b.currency2 IS NULL THEN CONVERT(BIT,0) ELSE CONVERT(BIT,1) END AS isShowOTExRate,
                   b.sdiscount,
                   b.adiscount,
                   b.discount,
                   '' AS settletime,
                   '',
                   b.transid,
                   ISNULL(b.BetID, 0),
                   b.refno,
                   b.transdate,
                   o.orid,
                   b.bettype,
                   b.hdp1,
                   b.hdp2, --end
                   b.odds,
                   b.modds,
                   bmOdd.finalodds,
                   bmOdd.finalodds2,
                   '' AS oddstype,
                   '',
				   b.status,
                   '',
                   CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,   
                   b.stake,
                   b.actual_stake,
                   (b.winlost - b.actual_stake) AS winlost,
                   b.playercomm,
                   b.livehomescore,
                   b.liveawayscore, --end
                   0,
                   0,
                   0,
                   0,
                   0,
                   b.CREATOR, --creator.username creator, 
                   b.ip,
                   b.Username,
                   CONVERT (BIT, 0) AS IsNeutral,
                   '' AS showtime,
                   0 spositiontaking, -- unuse in this report
				   0 mpositiontaking, -- unuse in this report
				   0 apositiontaking, -- unuse in this report		
				   0 spositiontaking2,-- unuse in this report
				   0 mpositiontaking2,-- unuse in this report
				   0 apositiontaking2,-- unuse in this report
				   b.betfrom,
				   0 scomm, -- unuse in this report			
				   0 acomm, -- unuse in this report			
				   0 comm,	-- unuse in this report	
				   awinlost,		
				   mwinlost,		
				   swinlost,
				   b.winlostdate
            FROM   dbo.bettrans AS b WITH (NOLOCK)
                   INNER JOIN
                   dbo.outright AS o WITH (NOLOCK)
                   ON b.matchid = o.orid
                   INNER JOIN
                   dbo.league AS l WITH (NOLOCK)
                   ON o.leagueid = l.leagueid
                   --INNER JOIN	customer AS creator WITH (NOLOCK) ON creator.custid = b.creator
                   LEFT OUTER JOIN
                   (SELECT t.refno,
                           t.finalodds,
                           f.finalodds AS finalodds2
                    FROM   bettransm AS t WITH (NOLOCK)
                           INNER JOIN
                           bettransm AS f WITH (NOLOCK)
                           ON t.refno = f.refno
                    WHERE  t.bettype = 41
                           AND f.bettype = 42) AS bmOdd
                   ON b.transid = bmOdd.refno
            WHERE  b.custid = @custid
                   AND b.bettype IN (10, 31, 32, 33, 41, 42, 43)
                   AND b.winlostdate = @fromdate
                   AND b.statusID IN (SELECT [statusID]
                                      FROM   @tmpStatus);
        END
    UPDATE  @Data
        SET tblTemp.Creator = cu.username
    FROM    @Data AS tblTemp
            INNER JOIN
            Customer AS cu WITH (NOLOCK)
            ON cu.custid = tblTemp.Creator;
    IF @transid = 0
        SELECT   *
        FROM     @Data
        ORDER BY transid;
    ELSE
        SELECT *
        FROM   @Data
        WHERE  transid = @transid;
END

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
GRANT EXECUTE ON [dbo].[Acc_BetListByDayAll] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_BetListByDayAll] TO [bodbExtAccNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_BetListByDayAll] TO [vnteam]
 