ALTER PROC [dbo].[Acc_BetList_SelWinloss_Mem2]
	@CustID			INT,
	@FromDate		DATETIME,
	@ToDate			DATETIME,
	@MoveBetsDay	SMALLDATETIME,
	@BalanceUpDay	SMALLDATETIME,
	@ShowSB			BIT = 1,
	@ShowRB			BIT = 0,
	@ShowNG			BIT = 0,
	@ShowBA			BIT = 0,
	@ShowLC			BIT = 0,
	@ShowVS			BIT = 0,
	@ShowCS  		BIT = 0, -- RNG Casino
	@TotalRows INT=0 OUTPUT,
	@SumWinlost MONEY=0 OUTPUT,
	@SumWinlostUSD MONEY=0 OUTPUT,
	@SumWinlostEUR MONEY=0 OUTPUT,
	@SumLicenseeWL MONEY=0 OUTPUT,
	@SumLicenseeWLUSD MONEY=0 OUTPUT,
	@SumLicenseeWLEUR MONEY=0 OUTPUT,
	@SumComm MONEY=0 OUTPUT,
	@SumCommUSD MONEY=0 OUTPUT,
	@SumCommEUR MONEY=0 OUTPUT,
	@SumPlayerComm    MONEY=0 OUTPUT,
	@SumPlayerCommUSD MONEY=0 OUTPUT,
	@SumPlayerCommEUR MONEY=0 OUTPUT,
	@drawfilter SMALLINT = 1,
	@Language VARCHAR(10) = 'en-us'  
AS

/*
Created: Henry 
Date: 2011-07-11
Task : Betlist for Licensee Winloss Report
DB: DBRPT/bodb02

Revisions:
	- 20110729@Henry: offer 3 new bettypes for Number Game + Combination Mixed Parlay
	- 20111208@Jim: change condition bettype<31 
	- 20120214@Jim: change to use  table ExchangeDaily by use function Lrf_f_GetExchangeDaily
	- 20120319@Henry: show main transid for sub-ticket of system parlay
	- 20120508@Jim: enhance query performance 
	- 20120802@Jim: add playercomm value 
	- 20120816@Henry: add ShowLiveCasino 
	- 20120912@Jim : add virtual sport 
    - 20130123@Daniel: Change link server alias
	- 20130527@Jim: support RNG Casino
	
Param's Explanation:
	+ @drawfilter: 'No Draw' filter is supportted (1:Normal 2:No Draw 3:No Draw for Turnover only)

*/

SET NOCOUNT ON

CREATE TABLE  #BetListByDateMem (
	Sporttype		INT,
	TransID			BIGINT,
	BetID			BIGINT,
	Bettype			INT,
	hdp1			SMALLMONEY, 
	hdp2			SMALLMONEY, 
	Modds			SMALLMONEY,
	OddsType		TINYINT,
	Odds			SMALLMONEY, 
	Stake MONEY, 
	Actual_Stake	MONEY,
	Betteam			NVARCHAR(20),
	Status			NVARCHAR(10),
	RefNO			BIGINT,	
	Transdate		DATETIME,
	Winlostdate		DATETIME,
	Winlost			MONEY,
	LicenseeWL		MONEY,
	comm			MONEY,
	playercomm		MONEY,
	Liveindicator	BIT,
	Livehomescore	SMALLINT,
	Liveawayscore	SMALLINT,
	IP				NVARCHAR(15),
	LeagueID		INT,
	MatchID			INT,
	MatchCode		NVARCHAR(50),
	Race			NVARCHAR(20),
	HomeID			INT,
	AwayID			INT, 	
	Betstatus		NVARCHAR(50),
	isNeutral		BIT,
	virtualrate		float,
	isShowOTExRate	BIT,
	currency INT,
	showtime NVARCHAR(50) -- table - shoe - hand of Live Casino
)

CREATE TABLE  #TempBetList (
	TransID			BIGINT PRIMARY KEY,
	BetID			BIGINT,
	Bettype			INT,
	hdp1			SMALLMONEY, 
	hdp2			SMALLMONEY, 
	Modds			SMALLMONEY,
	OddsType		TINYINT,
	Odds			SMALLMONEY, 
	Stake MONEY, 
	Actual_Stake	MONEY,
	Betteam			NVARCHAR(20),
	Status			NVARCHAR(10),
	RefNO			BIGINT,	
	Transdate		DATETIME,
	Winlostdate		DATETIME,
	Winlost			MONEY,
	LicenseeWL		MONEY,
	comm			MONEY,
	playercomm		MONEY,
	Liveindicator	BIT,
	Livehomescore	SMALLINT,
	Liveawayscore	SMALLINT,
	IP				NVARCHAR(50),
	currency INT,
	MatchID INT
)

declare @fdate DATETIME, @tdate datetime
select @fdate = @FromDate, @tdate = @ToDate

DECLARE	@currency INT 
SELECT	@currency = currency FROM custinfo (NOLOCK) WHERE custid = @custid

Declare @TempFromDate DATETIME
Declare @TempToDate DATETIME

IF @tdate > @MoveBetsDay
BEGIN
	IF @fdate <= @MoveBetsDay 
		SET @TempFromDate =  DATEADD(DAY,1,@MoveBetsDay)
	ELSE
		SET @TempFromDate = @fdate

	IF @ShowBA = 1
	BEGIN
		--Get BA Tickets
		INSERT INTO #TempBetList
		SELECT
			b.TransID,
			ISNULL(b.BetID,0),
			b.Bettype,
			b.hdp1, 
			b.hdp2,
			b.modds,
			b.OddsType,
			b.Odds,
			b.stake,
			b.actual_stake, 
			b.betteam, --Betteam
			b.status AS Status,				
			b.refno,
			b.Transdate,	
			b.winlostdate,			
			(b.winlost-actual_stake),
			0,
			comm,
			b.playercomm ,
			b.Liveindicator,
			b.Livehomescore,
			b.Liveawayscore,
			b.IP AS IP,
			b.currency,
			b.matchid
		FROM
			dbo.bettrans AS b WITH (NOLOCK)		
			INNER JOIN DBLIC.bodb_Licensee.dbo.LicenseeBATransaction_active BA WITH (NOLOCK) ON b.transid = BA.transid
		WHERE
			b.winlostdate BETWEEN @TempFromDate AND @tdate AND
			b.custid=@custid AND
			b.statusID IN (111,112,113)
	
		--sport book
		INSERT INTO #BetListByDateMem
		SELECT
			m.Sporttype, 
			b.TransID,
			b.BetID,
			b.Bettype,
			b.hdp1, 
			b.hdp2,
			b.modds,
			b.oddstype,
			b.odds,
			b.stake,
			b.actual_stake, 
			b.betteam, --Betteam
			b.status AS Status,				
			b.refno,
			b.Transdate,	
			b.winlostdate,			
			b.Winlost,
			b.LicenseeWL,
			b.comm,	
			b.playercomm, 
			b.Liveindicator,
			b.Livehomescore,
			b.Liveawayscore,
			b.IP AS IP,
			m.LeagueID,
			m.MatchID,	
			m.MatchCode,
			'' AS Race,
			m.HomeID,
			m.AwayID, 		
			m.Betstatus,
			ISNULL(m.isNeutral, CONVERT(BIT,0)) AS IsNeutral,
			0,0,
			b.currency,
			'' As ShowTime
		FROM
			#TempBetList b
			INNER JOIN dbo.match AS m WITH (NOLOCK) ON b.matchid=m.matchid 		
		WHERE
			(b.bettype < 31 OR (b.Bettype BETWEEN 121 AND 999)) AND
			b.bettype <>10
			
		--	Outright
			INSERT INTO #BetListByDateMem
			SELECT
				l.sporttype, --Sporttype
				b.TransID,
				b.BetID,
				b.Bettype,
				0 AS hdp1, 
				0 AS hdp2, 
				b.modds,
				0 AS OddsType, 
				b.Odds, 
				b.stake,
			    b.actual_stake,  
				'' AS Betteam, --Betteam
				b.Status,				
				b.refno,
				b.Transdate,	
				b.winlostdate,						
				b.Winlost,
				b.LicenseeWL,
				b.comm,
				b.playercomm,
				0 AS LiveIndicator , 
				b.LiveHomescore, 
				b.LiveAwayscore,
				b.IP AS IP,
				m.LeagueID,
				m.OrId,--0, --MatchID	
				m.MatchCode,
				m.GroupMatch,--Race
				m.TeamID, --HomeID
				0, --AwayID		
				0, --Betstatus
				CONVERT(BIT,0) AS IsNeutral,
				0,0,
				b.currency,
				'' as ShowTime
			FROM
				#TempBetList b		
				INNER JOIN dbo.Outright AS m WITH (NOLOCK) ON b.matchid=m.orid
				INNER JOIN dbo.League AS l WITH (NOLOCK) ON m.leagueID = l.leagueID
				
			WHERE
				b.bettype = 10
				
			--Mix Parlay + System Parlay
			INSERT INTO #BetListByDateMem
			SELECT
				0, --Sporttype
				CASE WHEN bettype <> 29 THEN b.transid
				ELSE CASE WHEN ISNULL(b.BetID,0)=0 THEN b.transid ELSE betid END
				END AS transid,	
				b.BetID,
				b.bettype,
				b.hdp1, 
				b.hdp2, 
				modds,
				0 AS OddsType, 
				b.Odds, 
				b.stake,
				b.actual_stake, 
				b.betteam, --Betteam
				b.Status,				
				b.refno,
				b.Transdate,	
				b.winlostdate,						
				b.Winlost,
				b.LicenseeWL,
				b.comm,
				b.playercomm,
				b.Liveindicator,
				b.Livehomescore,
				b.Liveawayscore,
				b.IP AS IP,
				0, --LeagueID
				0, --MatchID	
				'',--MatchCode
				'',--Race
				0, --HomeID
				0, --AwayID		
				0, --Betstatus
				CONVERT(BIT,0) AS IsNeutral,
				0,0,
				b.currency,
				'' As ShowTime
			FROM
				#TempBetList b
			WHERE
				b.bettype IN (9,29) AND
				b.matchid IN (9,29)
	END

	--Sport Book
	IF @ShowSB = 1
	BEGIN
		INSERT INTO #BetListByDateMem
			SELECT
				m.Sporttype, 
				b.TransID,
				ISNULL(b.BetID,0),
				b.Bettype,
				b.hdp1, 
				b.hdp2,
				modds,
				b.OddsType,
				b.Odds,
				b.stake,
				b.actual_stake,  
				b.betteam, --Betteam
				b.status AS Status,				
				b.refno,
				b.Transdate,	
				b.winlostdate,			
				(b.winlost-actual_stake),
				- (b.winlost-actual_stake) ,
				comm,
				b.playercomm ,
				b.Liveindicator,
				b.Livehomescore,
				b.Liveawayscore,
				b.IP AS IP,
				m.LeagueID,
				m.MatchID,	
				m.MatchCode,
				'' AS Race,	
				m.HomeID,
				m.AwayID, 		
				m.Betstatus,
				ISNULL(m.isNeutral, CONVERT(BIT,0)) AS IsNeutral,
				0,0,
				b.currency,
				'' As ShowTime
			FROM
				dbo.bettrans AS b WITH (NOLOCK)		
				INNER JOIN dbo.match AS m WITH (NOLOCK) ON b.matchid=m.matchid
			WHERE
				b.winlostdate BETWEEN @TempFromDate AND @tdate AND
				b.custid=@custid AND
				(b.bettype < 31 OR (b.bettype BETWEEN 121 AND 999 ))  AND
				b.bettype NOT IN (9,29,10)	AND
				b.matchid > 0 AND
				b.statusID IN (111,112,113) AND
				b.tpositiontaking<>0
		
		-- Outright
		INSERT INTO #BetListByDateMem
			SELECT
				l.sporttype, --Sporttype
				b.TransID,
				ISNULL(b.BetID,0),
				b.Bettype,
				0 AS hdp1, 
				0 AS hdp2, 
				modds,
				0 AS OddsType, 
				b.Odds, 
				b.stake,
				b.actual_stake, 
				'' AS Betteam, --Betteam
				b.Status,				
				b.refno,
				b.Transdate,	
				b.winlostdate,						
				(b.winlost-actual_stake),
				- (b.winlost-actual_stake),
				comm ,
				b.playercomm , 
				0 AS LiveIndicator , 
				b.LiveHomescore, 
				b.LiveAwayscore,
				b.IP AS IP,
				m.LeagueID,
				m.OrId,--0, --MatchID	
				m.MatchCode,
				m.GroupMatch,--Race
				m.TeamID, --HomeID
				0, --AwayID		
				0, --Betstatus
				CONVERT(BIT,0) AS IsNeutral,
				0,0,
				b.currency,
				'' As ShowTime
			FROM
				dbo.bettrans AS b WITH (NOLOCK)		
				INNER JOIN dbo.Outright AS m WITH (NOLOCK) ON b.matchid=m.orid
				INNER JOIN dbo.League AS l WITH (NOLOCK) ON m.leagueID = l.leagueID 
			WHERE
				b.winlostdate BETWEEN @TempFromDate AND @tdate AND
				b.custid=@custid AND
				b.bettype = 10 AND
				b.statusID IN (111,112,113) AND
				b.tpositiontaking<>0
				

		-- Mix Parlay + System Parlay		
		INSERT INTO #BetListByDateMem
			SELECT
				0, --Sporttype
				CASE WHEN bettype <> 29 THEN b.transid
				ELSE CASE WHEN ISNULL(b.BetID,0)=0 THEN b.transid ELSE betid END
				END AS transid,	
				ISNULL(b.BetID,0),
				b.bettype,
				b.hdp1, 
				b.hdp2, 
				modds,
				0 AS OddsType, 
				b.Odds, 
				b.stake,
				b.actual_stake, 
				b.betteam, --Betteam
				b.Status,				
				b.refno,
				b.Transdate,	
				b.winlostdate,						
				(b.winlost-actual_stake),
				- (b.winlost-actual_stake) ,
				comm,
				b.playercomm , 
				b.Liveindicator,
				b.Livehomescore,
				b.Liveawayscore,
				b.IP AS IP,
				0, --LeagueID
				0, --MatchID	
				'',--MatchCode
				'',--Race
				0, --HomeID
				0, --AwayID		
				0, --Betstatus
				CONVERT(BIT,0) AS IsNeutral,
				0,0,
				b.currency,
				'' as ShowTime
			FROM
				dbo.bettrans b WITH (NOLOCK)	
			WHERE
				b.winlostdate BETWEEN @TempFromDate AND @tdate AND
				b.custid=@custid AND
				b.bettype IN (9,29) AND
				b.matchid IN (9,29) AND
				b.statusID IN (111,112,113) AND
				b.tpositiontaking<>0
				
	END
	
	--Number Game
	IF @ShowNG = 1
	BEGIN
		INSERT INTO #BetListByDateMem
		SELECT
			m.Sporttype, 
			b.TransID,
			ISNULL(b.BetID,0),
			b.Bettype,
			b.hdp1 AS hdp1, 
			b.hdp2 AS hdp2,
			modds,
			b.oddstype,
			b.Odds,
			b.stake,
			b.actual_stake, 
			b.betteam,
			b.status AS Status,				
			b.refno,
			b.Transdate,	
			b.winlostdate,			
			(b.winlost-actual_stake),
			- (b.winlost-actual_stake) ,
			comm,
			b.playercomm  , 
			b.Liveindicator,
			b.Livehomescore,
			b.Liveawayscore,
			b.IP AS IP,
			m.LeagueID,
			m.MatchID,	
			m.MatchCode,
			'' AS Race,	
			m.HomeID,
			m.AwayID, 		
			m.Betstatus,
			ISNULL(m.isNeutral, CONVERT(BIT,0)) AS IsNeutral,
			0,0,
			b.currency,
			'' As ShowTime
		FROM
			dbo.bettrans AS b WITH (NOLOCK)		
			INNER JOIN dbo.match AS m WITH (NOLOCK) ON b.matchid=m.matchid 		
		WHERE
			b.winlostdate BETWEEN @TempFromDate AND @tdate AND
			b.custid=@custid AND
			b.bettype BETWEEN 81 AND 120 AND
			b.statusID IN (111,112,113)
		
	END
	
	--Live Casino
	IF @ShowLC = 1
	BEGIN
		INSERT INTO #BetListByDateMem
		SELECT
			m.Sporttype, 
			b.TransID,
			ISNULL(b.BetID,0),
			b.Bettype,
			b.hdp1 AS hdp1, 
			b.hdp2 AS hdp2,
			modds,
			b.oddstype,
			b.Odds,
			b.stake,
			b.actual_stake, 
			b.betteam,
			b.status AS Status,				
			b.refno,
			b.Transdate,	
			b.winlostdate,			
			(b.winlost-actual_stake),
			- (b.winlost-actual_stake) ,
			comm,
			b.playercomm  , 
			b.Liveindicator,
			b.Livehomescore,
			b.Liveawayscore,
			b.IP AS IP,
			m.LeagueID,
			m.MatchID,	
			m.MatchCode,
			'' AS Race,	
			m.HomeID,
			m.AwayID, 		
			m.Betstatus,
			ISNULL(m.isNeutral, CONVERT(BIT,0)) AS IsNeutral,
			0,0,
			b.currency,
			ISNULL(m.showtime, '') as showtime
		FROM
			dbo.bettrans AS b WITH (NOLOCK)		
			INNER JOIN dbo.match AS m WITH (NOLOCK) ON b.matchid=m.matchid 		
		WHERE
			b.winlostdate BETWEEN @TempFromDate AND @tdate AND
			b.custid=@custid AND
			b.bettype BETWEEN 1101 AND 1199 AND
			b.statusID IN (111,112,113)
	END
	
	IF @ShowVS=1
	BEGIN
		INSERT INTO #BetListByDateMem
		SELECT
			m.Sporttype, 
			b.TransID,
			ISNULL(b.BetID,0),
			b.Bettype,
			b.hdp1 AS hdp1, 
			b.hdp2 AS hdp2,
			modds,
			b.oddstype,
			b.Odds,
			b.stake,
			b.actual_stake, 
			b.betteam,
			b.status AS Status,				
			b.refno,
			b.Transdate,	
			b.winlostdate,			
			(b.winlost-actual_stake),
			- (b.winlost-actual_stake) ,
			comm,
			b.playercomm  , 
			b.Liveindicator,
			b.Livehomescore,
			b.Liveawayscore,
			b.IP AS IP,
			m.LeagueID,
			m.MatchID,	
			m.MatchCode,
			'' AS Race,	
			m.HomeID,
			m.AwayID, 		
			m.Betstatus,
			ISNULL(m.isNeutral, CONVERT(BIT,0)) AS IsNeutral,
			0,0,
			b.currency,
			'' as showtime
		FROM
			dbo.bettrans AS b WITH (NOLOCK)		
			INNER JOIN dbo.match AS m WITH (NOLOCK) ON b.matchid=m.matchid 		
		WHERE
			b.winlostdate BETWEEN @TempFromDate AND @tdate AND
			b.custid=@custid AND
			(b.bettype BETWEEN 1201 AND 1299) AND
			b.statusID IN (111,112,113)
	END
	
	-- Horse Racing
	IF @ShowRB = 1
	BEGIN
		INSERT INTO #BetListByDateMem
			SELECT
				l.sporttype, --Sporttype
				b.TransID,
				ISNULL(b.BetID,0),
				b.Bettype,
				b.hdp1, 
				b.hdp2,
				modds,
				0 AS OddsType, 
				b.Odds, 
				b.stake,
				b.actual_stake,  
				'' AS Betteam, --Betteam
				b.Status,				
				b.refno,
				b.Transdate,	
				b.winlostdate,						
				(b.winlost-actual_stake),
				awinlost,
				comm ,
				b.playercomm  , 
				0 AS LiveIndicator , 
				b.LiveHomescore, 
				b.LiveAwayscore,
				b.IP AS IP,
				m.LeagueID,
				m.OrId,--0, --MatchID	
				m.MatchCode,
				m.GroupMatch,--Race
				m.TeamID, --HomeID
				0, --AwayID		
				0, --Betstatus
				CONVERT(BIT,0) AS IsNeutral,
				b.virtualrate,
				isnumeric(m.programID),
				b.currency,
				'' As ShowTime
			FROM
				dbo.bettrans AS b WITH (NOLOCK )		
				INNER JOIN dbo.Outright AS m WITH (NOLOCK) ON b.matchid=m.orid
				INNER JOIN dbo.League AS l WITH (NOLOCK) ON m.leagueID = l.leagueID
			WHERE
				b.winlostdate BETWEEN @TempFromDate AND @tdate AND
				b.custid=@custid AND
				b.bettype IN (31, 32, 33) AND
				b.statusID IN (111,112,113)
				
	END
	----- RNG Casino
	IF @ShowCS=1
	BEGIN
		INSERT INTO #BetListByDateMem
		SELECT
			251 Sporttype, 
			b.TransID,
			ISNULL(b.BetID,0),
			b.Bettype,
			b.hdp1 AS hdp1, 
			b.hdp2 AS hdp2,
			modds,
			b.oddstype,
			b.Odds,
			b.stake,
			b.actual_stake, 
			b.betteam,
			b.status AS Status,				
			b.refno,
			b.Transdate,	
			b.winlostdate,			
			(b.winlost-actual_stake),
			- (b.winlost-actual_stake) ,
			comm,
			b.playercomm  , 
			b.Liveindicator,
			b.Livehomescore,
			b.Liveawayscore,
			b.IP AS IP,
			0 as LeagueID,
			0 as MatchID,	
			0 as MatchCode,
			'' AS Race,	
			0 as HomeID,
			0 as AwayID, 		
			'' as Betstatus,
			CONVERT(BIT,0) AS IsNeutral,
			0,0,
			b.currency,
			'' as showtime
		FROM
			dbo.bettrans AS b WITH (NOLOCK)		
		WHERE
			b.winlostdate BETWEEN @TempFromDate AND @tdate AND
			b.custid=@custid AND
			b.bettype =71 AND
			b.statusID IN (111,112,113)
	END
	
END

IF @fdate <= @MoveBetsDay
BEGIN
	IF @tdate >= @MoveBetsDay
		SET @TempToDate = @MoveBetsDay
	ELSE
		SET  @TempToDate = @tdate
	
	IF @BalanceUpDay < @fdate 
		SELECT @BalanceUpDay=@fdate

	
	
	IF @ShowBA = 1
	BEGIN
		--Get BA Tickets
		DELETE FROM #TempBetList
			
		INSERT INTO #TempBetList
		SELECT
			b.TransID,
			ISNULL(b.BetID,0),
			b.Bettype,
			b.hdp1, 
			b.hdp2,
			b.modds,
			b.OddsType,
			b.Odds,
			b.stake,
			b.actual_stake,  
			b.betteam, --Betteam
			b.status AS Status,				
			b.refno,
			b.Transdate,	
			b.winlostdate,			
			(b.winlost-actual_stake),
			0,
			comm,
			b.playercomm ,
			b.Liveindicator,
			b.Livehomescore,
			b.Liveawayscore,
			b.IP AS IP,
			b.currency,
			b.matchid
		FROM
			dbo.bettrans14 AS b WITH (NOLOCK)		
			INNER JOIN DBLIC.bodb_Licensee.dbo.LicenseeBATransaction BA WITH (NOLOCK) ON b.transid = BA.transid
		WHERE
			b.winlostdate BETWEEN @BalanceUpDay AND @TempToDate AND
			b.custid=@custid AND
			b.statusID IN (111,112,113)
	
		--sport book
		INSERT INTO #BetListByDateMem
		SELECT
			m.Sporttype, 
			b.TransID,
			b.BetID,
			b.Bettype,
			b.hdp1, 
			b.hdp2,
			b.modds,
			b.oddstype,
			b.odds,
			b.stake,
			b.actual_stake,  
			b.betteam, --Betteam
			b.status AS Status,				
			b.refno,
			b.Transdate,	
			b.winlostdate,			
			b.Winlost,
			b.LicenseeWL,
			b.comm,	
			b.playercomm, 
			b.Liveindicator,
			b.Livehomescore,
			b.Liveawayscore,
			b.IP AS IP,
			m.LeagueID,
			m.MatchID,	
			m.MatchCode,
			'' AS Race,
			m.HomeID,
			m.AwayID, 		
			m.Betstatus,
			ISNULL(m.isNeutral, CONVERT(BIT,0)) AS IsNeutral,
			0,0,
			b.currency,
			'' As ShowTime
		FROM
			#TempBetList b
			INNER JOIN dbo.match14 AS m WITH (NOLOCK) ON b.matchid=m.matchid 		
		WHERE
			(b.bettype < 31 OR (b.Bettype BETWEEN 121 AND 999 )) AND
			b.bettype <>10
			
		--	Outright
			INSERT INTO #BetListByDateMem
			SELECT
				l.sporttype, --Sporttype
				b.TransID,
				b.BetID,
				b.Bettype,
				0 AS hdp1, 
				0 AS hdp2, 
				b.modds,
				0 AS OddsType, 
				b.Odds, 
				b.stake,
				b.actual_stake,   
				'' AS Betteam, --Betteam
				b.Status,				
				b.refno,
				b.Transdate,	
				b.winlostdate,						
				b.Winlost,
				b.LicenseeWL,
				b.comm,
				b.playercomm,
				0 AS LiveIndicator , 
				b.LiveHomescore, 
				b.LiveAwayscore,
				b.IP AS IP,
				m.LeagueID,
				m.OrId,--0, --MatchID	
				m.MatchCode,
				m.GroupMatch,--Race
				m.TeamID, --HomeID
				0, --AwayID		
				0, --Betstatus
				CONVERT(BIT,0) AS IsNeutral,
				0,0,
				b.currency,
				'' As ShowTime
			FROM
				#TempBetList b		
				INNER JOIN dbo.Outright14 AS m WITH (NOLOCK) ON b.matchid=m.orid
				INNER JOIN dbo.League AS l WITH (NOLOCK) ON m.leagueID = l.leagueID
				
			WHERE
				b.bettype = 10
				
			--Mix Parlay + System Parlay
			INSERT INTO #BetListByDateMem
			SELECT
				0, --Sporttype
				CASE WHEN bettype <> 29 THEN b.transid
				ELSE CASE WHEN ISNULL(b.BetID,0)=0 THEN b.transid ELSE betid END
				END AS transid,	
				b.BetID,
				b.bettype,
				b.hdp1, 
				b.hdp2, 
				modds,
				0 AS OddsType, 
				b.Odds, 
				b.stake,
				b.actual_stake,  
				b.betteam, --Betteam
				b.Status,				
				b.refno,
				b.Transdate,	
				b.winlostdate,						
				b.Winlost,
				b.LicenseeWL,
				b.comm,
				b.playercomm,
				b.Liveindicator,
				b.Livehomescore,
				b.Liveawayscore,
				b.IP AS IP,
				0, --LeagueID
				0, --MatchID	
				'',--MatchCode
				'',--Race
				0, --HomeID
				0, --AwayID		
				0, --Betstatus
				CONVERT(BIT,0) AS IsNeutral,
				0,0,
				b.currency,
				'' As ShowTime
			FROM
				#TempBetList b
			WHERE
				b.bettype IN (9,29) AND
				b.matchid IN (9,29) 
	END

	--Sport Book
	IF @ShowSB = 1
	BEGIN	
		INSERT INTO #BetListByDateMem
			SELECT
				m.Sporttype, 
				b.TransID,
				ISNULL(b.BetID,0),
				b.Bettype,
				b.hdp1, 
				b.hdp2, 
				modds,
				b.Oddstype,
				b.Odds,
				b.stake,
				b.actual_stake,  
				b.betteam, --Betteam
				b.status AS Status,				
				b.refno,
				b.Transdate,	
				b.winlostdate,						
				(b.winlost-actual_stake),
				- (b.winlost-actual_stake),
				comm,
				b.playercomm  ,
				b.Liveindicator,
				b.Livehomescore,
				b.Liveawayscore,
				b.IP AS IP,
				m.LeagueID,
				m.MatchID,	
				m.MatchCode,
				'' AS Race,	--Race
				m.HomeID,
				m.AwayID, 		
				m.Betstatus,
				ISNULL(m.isNeutral, CONVERT(BIT,0)) AS IsNeutral,
				0,0,
				b.currency,
				'' As ShowTime
			FROM
				dbo.bettrans14 AS b WITH (NOLOCK)		
				INNER JOIN dbo.match14 AS m WITH (NOLOCK) ON b.matchid=m.matchid
			WHERE
				b.winlostdate BETWEEN @BalanceUpDay AND @TempToDate AND
				b.custid=@custid AND
				(b.bettype < 31 OR (b.bettype BETWEEN 121 AND 999 )) AND
				b.bettype NOT IN (9,29,10) AND
				b.matchid>0 AND
				b.statusID IN (111,112,113) AND
				b.tpositiontaking<>0
				

		-- Mix Parlay + System Parlay
		INSERT INTO #BetListByDateMem
			SELECT
				0, --Sporttype
				CASE WHEN bettype <> 29 THEN b.transid
				ELSE CASE WHEN ISNULL(b.BetID,0)=0 THEN b.transid ELSE betid END
				END AS transid,	
				ISNULL(b.BetID,0),
				b.bettype,
				b.hdp1, 
				b.hdp2, 
				modds,
				0 AS OddsType, 
				b.Odds, 
				b.stake,
				b.actual_stake,   
				b.betteam, --Betteam
				b.Status,				
				b.refno,
				b.Transdate,	
				b.winlostdate,						
				(b.winlost-actual_stake),
				- (b.winlost-actual_stake),
				comm ,
				b.playercomm  ,
				b.Liveindicator,
				b.Livehomescore,
				b.Liveawayscore,
				b.IP AS IP,
				0, --LeagueID
				0, --MatchID
				'',--MatchCode
				'',--Race	
				0, --HomeID
				0, --AwayID		
				0, --Betstatus
				CONVERT(BIT,0) AS isNeutral,
				0,0,
				b.currency,
				'' As ShowTime
			FROM
				dbo.bettrans14 AS b WITH (NOLOCK)	
			WHERE
				b.winlostdate BETWEEN @BalanceUpDay AND @TempToDate AND
				b.custid=@custid AND
				b.bettype IN (9,29) AND
				b.matchid IN (9,29) AND
				b.statusID IN (111,112,113) AND
				b.tpositiontaking<>0
			
		--outright		
		INSERT INTO #BetListByDateMem
			SELECT
				l.sporttype, --Sporttype
				b.TransID,
				ISNULL(b.BetID,0),
				b.Bettype,
				0 AS hdp1, 
				0 AS hdp2, 
				modds,
				0 AS OddsType, 
				b.Odds, 
				b.stake,
				b.actual_stake,  
				'' AS Betteam, --Betteam
				b.Status,				
				b.refno,
				b.Transdate,	
				b.winlostdate,						
				(b.winlost-actual_stake),
				- (b.winlost-actual_stake),
				comm ,
				b.playercomm ,
				0 AS LiveIndicator, 
				b.LiveHomescore, 
				b.LiveAwayscore,
				b.IP AS IP,
				m.LeagueID,
				m.OrId,--0, --MatchID	
				m.MatchCode,
				m.GroupMatch AS Race,--Race
				m.TeamID, --HomeID
				0, --AwayID		
				0, --Betstatus
				CONVERT(BIT,0) AS isNeutral,
				0,0,
				b.currency,
				'' As ShowTime
			FROM
				dbo.bettrans14 AS b WITH (NOLOCK)		
				INNER JOIN dbo.Outright14 AS m WITH (NOLOCK) ON b.matchid=m.orid 
				INNER JOIN dbo.League AS l WITH (NOLOCK) ON m.leagueID = l.leagueID
			WHERE
				b.winlostdate BETWEEN @BalanceUpDay AND @TempToDate AND
				b.custid=@custid AND
				b.bettype = 10 AND
				b.statusID IN (111,112,113) AND
				b.tpositiontaking<>0
				
	END	
	
	--Number Game
	IF @ShowNG = 1
	BEGIN
		INSERT INTO #BetListByDateMem
		SELECT
			m.Sporttype, 
			b.TransID,
			ISNULL(b.BetID,0),
			b.Bettype,
			b.hdp1 AS hdp1, 
			b.hdp2 AS hdp2,
			modds,
			b.Oddstype,
			b.Odds,
			b.stake,
			b.actual_stake,   		
			b.betteam,
			b.status AS Status,				
			b.refno,
			b.Transdate,	
			b.winlostdate,			
			(b.winlost-actual_stake),
			- (b.winlost-actual_stake),
			comm,
			b.playercomm ,
			b.Liveindicator,
			b.Livehomescore,
			b.Liveawayscore,
			b.IP AS IP,
			m.LeagueID,
			m.MatchID,	
			m.MatchCode,
			'' AS Race,	
			m.HomeID,
			m.AwayID, 		
			m.Betstatus,
			ISNULL(m.isNeutral, CONVERT(BIT,0)) AS IsNeutral,
			0,0,
			b.currency,
			'' As ShowTime
		FROM
			dbo.bettrans14 AS b WITH (NOLOCK)		
			INNER JOIN dbo.match14 AS m WITH (NOLOCK) ON b.matchid=m.matchid
		WHERE
			b.winlostdate BETWEEN @BalanceUpDay AND @tdate AND
			b.custid=@custid AND
			(b.bettype BETWEEN 81 AND 120) AND
			b.statusID IN (111,112,113)
	END
	
	--Live Casino
	IF @ShowLC = 1
	BEGIN
		INSERT INTO #BetListByDateMem
		SELECT
			m.Sporttype, 
			b.TransID,
			ISNULL(b.BetID,0),
			b.Bettype,
			b.hdp1 AS hdp1, 
			b.hdp2 AS hdp2,
			modds,
			b.Oddstype,
			b.Odds,
			b.stake,
			b.actual_stake,   		
			b.betteam,
			b.status AS Status,				
			b.refno,
			b.Transdate,	
			b.winlostdate,			
			(b.winlost-actual_stake),
			- (b.winlost-actual_stake),
			comm,
			b.playercomm ,
			b.Liveindicator,
			b.Livehomescore,
			b.Liveawayscore,
			b.IP AS IP,
			m.LeagueID,
			m.MatchID,	
			m.MatchCode,
			'' AS Race,	
			m.HomeID,
			m.AwayID, 		
			m.Betstatus,
			ISNULL(m.isNeutral, CONVERT(BIT,0)) AS IsNeutral,
			0,0,
			b.currency,
			ISNULL(m.showtime, '') as showtime
		FROM
			dbo.bettrans14 AS b WITH (NOLOCK)		
			INNER JOIN dbo.match14 AS m WITH (NOLOCK) ON b.matchid=m.matchid
		WHERE
			b.winlostdate BETWEEN @BalanceUpDay AND @tdate AND
			b.custid=@custid AND
			b.bettype BETWEEN 1101 AND 1199 AND
			b.statusID IN (111,112,113)
	END
	
	IF @ShowVS=1
	BEGIN
		INSERT INTO #BetListByDateMem
		SELECT
			m.Sporttype, 
			b.TransID,
			ISNULL(b.BetID,0),
			b.Bettype,
			b.hdp1 AS hdp1, 
			b.hdp2 AS hdp2,
			modds,
			b.Oddstype,
			b.Odds,
			b.stake,
			b.actual_stake,   		
			b.betteam,
			b.status AS Status,				
			b.refno,
			b.Transdate,	
			b.winlostdate,			
			(b.winlost-actual_stake),
			- (b.winlost-actual_stake),
			comm,
			b.playercomm ,
			b.Liveindicator,
			b.Livehomescore,
			b.Liveawayscore,
			b.IP AS IP,
			m.LeagueID,
			m.MatchID,	
			m.MatchCode,
			'' AS Race,	
			m.HomeID,
			m.AwayID, 		
			m.Betstatus,
			ISNULL(m.isNeutral, CONVERT(BIT,0)) AS IsNeutral,
			0,0,
			b.currency,
			'' as showtime
		FROM
			dbo.bettrans14 AS b WITH (NOLOCK)		
			INNER JOIN dbo.match14 AS m WITH (NOLOCK) ON b.matchid=m.matchid
		WHERE
			b.winlostdate BETWEEN @BalanceUpDay AND @tdate AND
			b.custid=@custid AND
			( b.bettype BETWEEN 1201 AND 1299) AND
			b.statusID IN (111,112,113)
	END
	--- RNG Casino 
	IF @ShowCS=1
	BEGIN
		INSERT INTO #BetListByDateMem
		SELECT
			251 as Sporttype, 
			b.TransID,
			ISNULL(b.BetID,0),
			b.Bettype,
			b.hdp1 AS hdp1, 
			b.hdp2 AS hdp2,
			modds,
			b.Oddstype,
			b.Odds,
			b.stake,
			b.actual_stake,   		
			b.betteam,
			b.status AS Status,				
			b.refno,
			b.Transdate,	
			b.winlostdate,			
			(b.winlost-actual_stake),
			- (b.winlost-actual_stake),
			comm,
			b.playercomm ,
			b.Liveindicator,
			b.Livehomescore,
			b.Liveawayscore,
			b.IP AS IP,
			0 as LeagueID,
			0 as MatchID,	
			0 as MatchCode,
			'' AS Race,	
			0 as HomeID,
			0 as AwayID, 		
			'' as Betstatus,
			CONVERT(BIT,0) AS IsNeutral,
			0,0,
			b.currency,
			'' as showtime
		FROM
			dbo.bettrans14 AS b WITH (NOLOCK)		
		WHERE
			b.winlostdate BETWEEN @BalanceUpDay AND @tdate AND
			b.custid=@custid AND
			b.bettype =71 AND
			b.statusID IN (111,112,113)
	END
			
	--Horse Racing
	IF @ShowRB = 1
	BEGIN
		INSERT INTO #BetListByDateMem
			SELECT
				l.sporttype, --Sporttype
				b.TransID,
				ISNULL(b.BetID,0),
				b.Bettype,
				b.hdp1, 
				b.hdp2, 
				modds,
				0 AS OddsType, 
				b.Odds, 
				b.stake,
				b.actual_stake,   
				'' AS Betteam, --Betteam
				b.Status,				
				b.refno,
				b.Transdate,	
				b.winlostdate,						
				(b.winlost-actual_stake),
				awinlost,
				comm ,
				b.playercomm,
				0 AS LiveIndicator, 
				b.LiveHomescore, 
				b.LiveAwayscore,
				b.IP AS IP,
				m.LeagueID,
				m.OrId,--0, --MatchID	
				m.MatchCode,
				m.GroupMatch AS Race,--Race
				m.TeamID, --HomeID
				0, --AwayID		
				0, --Betstatus
				CONVERT(BIT,0) AS isNeutral,
				b.virtualrate,
				isnumeric(m.programID),
				b.currency,
				'' As ShowTime
			FROM
				dbo.bettrans14 AS b WITH (NOLOCK)		
				INNER JOIN dbo.Outright14 AS m WITH (NOLOCK) ON b.matchid=m.orid 
				INNER JOIN dbo.League AS l WITH (NOLOCK) ON m.leagueID = l.leagueID
			WHERE
				b.winlostdate BETWEEN @BalanceUpDay AND @TempToDate AND
				b.custid=@custid AND
				b.bettype IN (31, 32, 33) AND
				b.statusID IN (111,112,113)
				
	END
END		
IF @fdate < @BalanceUpDay
BEGIN
	IF @tdate >= DATEADD(dd, -1, @BalanceUpDay)
		SET @TempToDate = DATEADD(dd, -1, @BalanceUpDay)
	ELSE
		SET @TempToDate = @tdate
	
	
		
	
	IF @ShowBA = 1
	BEGIN
		DELETE FROM #TempBetList
		
		--Get BA Tickets
		INSERT INTO #TempBetList
		SELECT
			b.TransID,
			ISNULL(b.BetID,0),
			b.Bettype,
			b.hdp1, 
			b.hdp2,
			b.modds,
			b.OddsType,
			b.Odds,
			b.stake,
			b.actual_stake,  
			b.betteam, --Betteam
			b.status AS Status,				
			b.refno,
			b.Transdate,	
			b.winlostdate,			
			(b.winlost-actual_stake),
			0,
			comm,
			b.playercomm ,
			b.Liveindicator,
			b.Livehomescore,
			b.Liveawayscore,
			b.IP AS IP,
			b.currency,
			b.matchid
		FROM
			bodb_archive.dbo.bettrans_bk AS b WITH (NOLOCK)		
			INNER JOIN DBLIC.bodb_Licensee.dbo.LicenseeBATransaction BA WITH (NOLOCK) ON b.transid = BA.transid
		WHERE
			b.winlostdate BETWEEN @fdate AND @TempToDate AND
			b.custid=@custid AND
			b.ruben = 1 AND
			b.status NOT IN ('VOID','REJECT','REFUND')
	
		--sport book
		INSERT INTO #BetListByDateMem
		SELECT
			m.Sporttype, 
			b.TransID,
			b.BetID,
			b.Bettype,
			b.hdp1, 
			b.hdp2,
			b.modds,
			b.oddstype,
			b.odds,
			b.stake,
			b.actual_stake,  
			b.betteam, --Betteam
			b.status AS Status,				
			b.refno,
			b.Transdate,	
			b.winlostdate,			
			b.Winlost,
			b.LicenseeWL,
			b.comm,	
			b.playercomm,
			b.Liveindicator,
			b.Livehomescore,
			b.Liveawayscore,
			b.IP AS IP,
			m.LeagueID,
			m.MatchID,	
			m.MatchCode,
			'' AS Race,
			m.HomeID,
			m.AwayID, 		
			m.Betstatus,
			ISNULL(m.isNeutral, CONVERT(BIT,0)) AS IsNeutral,
			0,0,
			b.currency,
			'' As ShowTime
		FROM
			#TempBetList b
			INNER JOIN bodb_archive.dbo.match_bk AS m WITH (NOLOCK) ON b.matchid=m.matchid 		
		WHERE
			(b.bettype < 31 OR (b.Bettype BETWEEN 121 AND 999 )) AND
			b.bettype NOT IN (9,29,10)
			
		--	Outright
		INSERT INTO #BetListByDateMem
		SELECT
			l.sporttype, --Sporttype
			b.TransID,
			b.BetID,
			b.Bettype,
			0 AS hdp1, 
			0 AS hdp2, 
			b.modds,
			0 AS OddsType, 
			b.Odds, 
			b.stake,
			b.actual_stake,  
			'' AS Betteam, --Betteam
			b.Status,				
			b.refno,
			b.Transdate,	
			b.winlostdate,						
			b.Winlost,
			b.LicenseeWL,
			b.comm,
			b.playercomm, 
			0 AS LiveIndicator , 
			b.LiveHomescore, 
			b.LiveAwayscore,
			b.IP AS IP,
			m.LeagueID,
			m.OrId,--0, --MatchID	
			m.MatchCode,
			m.GroupMatch,--Race
			m.TeamID, --HomeID
			0, --AwayID		
			0, --Betstatus
			CONVERT(BIT,0) AS IsNeutral,
			0,0,
			b.currency,
			'' As ShowTime
		FROM
			#TempBetList b		
			INNER JOIN bodb_archive.dbo.Outright_bk AS m WITH (NOLOCK) ON b.matchid=m.orid
			INNER JOIN dbo.League AS l WITH (NOLOCK) ON m.leagueID = l.leagueID
			
		WHERE
			b.bettype = 10
			
		--Mix Parlay + System parlay
		INSERT INTO #BetListByDateMem
		SELECT
			0, --Sporttype
			CASE WHEN bettype <> 29 THEN b.transid
				ELSE CASE WHEN ISNULL(b.BetID,0)=0 THEN b.transid ELSE betid END
				END AS transid,	
			b.BetID,
			b.bettype,
			b.hdp1, 
			b.hdp2, 
			modds,
			0 AS OddsType, 
			b.Odds, 
			b.stake,
			b.actual_stake,   
			b.betteam, --Betteam
			b.Status,				
			b.refno,
			b.Transdate,	
			b.winlostdate,						
			b.Winlost,
			b.LicenseeWL,
			b.comm,
			b.playercomm,
			b.Liveindicator,
			b.Livehomescore,
			b.Liveawayscore,
			b.IP AS IP,
			0, --LeagueID
			0, --MatchID	
			'',--MatchCode
			'',--Race
			0, --HomeID
			0, --AwayID		
			0, --Betstatus
			CONVERT(BIT,0) AS IsNeutral,
			0,0,
			b.currency,
			'' As ShowTime
		FROM
			#TempBetList b
		WHERE
			b.bettype IN (9,29) AND
			b.matchid IN (9,29)
		
		
	END
		
	--Sport Book
	IF @ShowSB = 1
	BEGIN
		INSERT INTO #BetListByDateMem
			SELECT
				m.Sporttype, 
				b.TransID,
				ISNULL(b.BetID,0),
				b.Bettype,
				b.hdp1, 
				b.hdp2,
				modds,
				b.Oddstype,
				b.Odds,
				b.stake,
				b.actual_stake,  
				b.betteam, --Betteam
				b.status AS Status,				
				b.refno,
				b.Transdate,	
				b.winlostdate,			
				(b.winlost-actual_stake),
				- (b.winlost-actual_stake),
				comm,
				b.playercomm,
				b.Liveindicator,
				b.Livehomescore,
				b.Liveawayscore,
				b.IP AS IP,
				m.LeagueID,
				m.MatchID,	
				m.MatchCode,
				'' AS Race,	
				m.HomeID,
				m.AwayID, 		
				m.Betstatus,
				ISNULL(m.isNeutral, CONVERT(BIT,0)) AS IsNeutral,
				0,0,
				b.currency,
				'' As ShowTime
			FROM
				bodb_archive.dbo.bettrans_bk AS b WITH (NOLOCK)		
				INNER JOIN bodb_archive.dbo.match_BK AS m WITH (NOLOCK) ON b.matchid=m.matchid  
			WHERE
				b.winlostdate BETWEEN @fdate AND @TempToDate AND
				b.custid=@custid AND
				b.ruben = 1 AND
				b.status NOT IN ('VOID', 'REJECT', 'REFUND') AND 
				(b.bettype < 31 OR (b.bettype BETWEEN 121 AND 999 )) AND
				b.bettype NOT IN (9,29, 10) AND
				b.tpositiontaking<>0
				
		
		-- Outright
		INSERT INTO #BetListByDateMem
			SELECT
				l.sporttype, --Sporttype
				b.TransID,
				ISNULL(b.BetID,0),
				b.Bettype,
				0 AS hdp1, 
				0 AS hdp2, 
				modds,
				0 AS OddsType, 
				b.Odds, 
				b.stake,
				b.actual_stake,  
				'' AS Betteam, --Betteam
				b.Status,				
				b.refno,
				b.Transdate,	
				b.winlostdate,						
				(b.winlost-actual_stake),
				- (b.winlost-actual_stake),
				comm,
				b.playercomm, 
				0 AS LiveIndicator , 
				b.LiveHomescore, 
				b.LiveAwayscore,
				b.IP AS IP,
				m.LeagueID,
				m.OrId,--0, --MatchID	
				m.MatchCode,
				m.GroupMatch,--Race
				m.TeamID, --HomeID
				0, --AwayID		
				0, --Betstatus
				CONVERT(BIT,0) AS IsNeutral,
				0,0,
				b.currency,
				'' As ShowTime
			FROM
				bodb_archive.dbo.bettrans_bk  AS b WITH (NOLOCK)		
				INNER JOIN bodb_archive.dbo.Outright_bk AS m WITH (NOLOCK) ON b.matchid=m.orid
				INNER JOIN dbo.League AS l WITH (NOLOCK) ON m.leagueID = l.leagueID
			WHERE
				b.winlostdate BETWEEN @fdate AND @TempToDate AND
				b.custid=@custid AND
				b.ruben = 1 AND
				b.status NOT IN ('VOID', 'REJECT', 'REFUND') AND 
				b.bettype = 10 AND
				b.tpositiontaking<>0

		-- Mix Parlay	+ System Parlay	
		INSERT INTO #BetListByDateMem
			SELECT
				0, --Sporttype
				CASE WHEN bettype <> 29 THEN b.transid
				ELSE CASE WHEN ISNULL(b.BetID,0)=0 THEN b.transid ELSE betid END
				END AS transid,	
				ISNULL(b.BetID,0),
				b.bettype,
				b.hdp1, 
				b.hdp2, 
				modds,
				0 AS OddsType, 
				b.Odds, 
				b.stake,
				b.actual_stake,   
				b.betteam, --Betteam
				b.Status,				
				b.refno,
				b.Transdate,	
				b.winlostdate,						
				(b.winlost-actual_stake),
				 - (b.winlost-actual_stake) ,
				comm ,
				b.playercomm, 
				b.Liveindicator,
				b.Livehomescore,
				b.Liveawayscore,
				b.IP AS IP,
				0, --LeagueID
				0, --MatchID	
				'',--MatchCode
				'',--Race
				0, --HomeID
				0, --AwayID		
				0, --Betstatus
				CONVERT(BIT,0) AS IsNeutral,
				0,0,
				b.currency,
				'' As ShowTime
			FROM
				bodb_archive.dbo.bettrans_bk b WITH (NOLOCK)	
			WHERE
				b.winlostdate BETWEEN @fdate AND @TempToDate AND
				b.custid=@custid AND
				b.ruben = 1 AND 
				b.status NOT IN ('VOID', 'REJECT','REFUND') AND
				b.bettype IN (9,29) AND
				--b.matchid = 0
				b.matchid IN (0,9,29) AND --should NOT remove 0 IN archive
				b.tpositiontaking<>0
	END
	
	--Number game
	IF @ShowNG = 1
	BEGIN
		INSERT INTO #BetListByDateMem
		SELECT
		m.Sporttype, 
		b.TransID,
		ISNULL(b.BetID,0),
		b.Bettype,
		b.hdp1 AS hdp1, 
		b.hdp2 AS hdp2,
		modds,
		b.Oddstype,
		b.Odds,
		b.stake,
		b.actual_stake,  		
		b.betteam,
		b.status AS Status,				
		b.refno,
		b.Transdate,	
		b.winlostdate,			
		(b.winlost-actual_stake),
		- (b.winlost-actual_stake),
		comm ,
		b.playercomm , 
		b.Liveindicator,
		b.Livehomescore,
		b.Liveawayscore,
		b.IP AS IP,
		m.LeagueID,
		m.MatchID,	
		m.MatchCode,
		'' AS Race,	
		m.HomeID,
		m.AwayID, 		
		m.Betstatus,
		ISNULL(m.isNeutral, CONVERT(BIT,0)) AS IsNeutral,
		0,0,
		b.currency,
		'' As ShowTime
	FROM
		bodb_archive.dbo.bettrans_bk AS b WITH (NOLOCK)		
		INNER JOIN bodb_archive.dbo.match_BK AS m WITH (NOLOCK) ON b.matchid=m.matchid  
	WHERE
		b.winlostdate BETWEEN @fdate AND @TempToDate AND
		b.custid=@custid AND
		b.bettype BETWEEN 81 AND 120 AND
		b.ruben = 1 AND
		b.status NOT IN ('VOID', 'REJECT', 'REFUND')
	END
	
	--Live Casino
	IF @ShowLC = 1
	BEGIN
		INSERT INTO #BetListByDateMem
		SELECT
		m.Sporttype, 
		b.TransID,
		ISNULL(b.BetID,0),
		b.Bettype,
		b.hdp1 AS hdp1, 
		b.hdp2 AS hdp2,
		modds,
		b.Oddstype,
		b.Odds,
		b.stake,
		b.actual_stake,  		
		b.betteam,
		b.status AS Status,				
		b.refno,
		b.Transdate,	
		b.winlostdate,			
		(b.winlost-actual_stake),
		- (b.winlost-actual_stake),
		comm ,
		b.playercomm , 
		b.Liveindicator,
		b.Livehomescore,
		b.Liveawayscore,
		b.IP AS IP,
		m.LeagueID,
		m.MatchID,	
		m.MatchCode,
		'' AS Race,	
		m.HomeID,
		m.AwayID, 		
		m.Betstatus,
		ISNULL(m.isNeutral, CONVERT(BIT,0)) AS IsNeutral,
		0,0,
		b.currency,
		ISNULL(m.showtime, '') as showtime
	FROM
		bodb_archive.dbo.bettrans_bk AS b WITH (NOLOCK)		
		INNER JOIN bodb_archive.dbo.match_BK AS m WITH (NOLOCK) ON b.matchid=m.matchid  
	WHERE
		b.winlostdate BETWEEN @fdate AND @TempToDate AND
		b.custid=@custid AND
		b.bettype BETWEEN 1101 AND 1199 AND
		b.ruben = 1 AND
		b.status NOT IN ('VOID', 'REJECT', 'REFUND')
	END
	
	IF ( @ShowVS=1)
	BEGIN
		INSERT INTO #BetListByDateMem
		SELECT
		m.Sporttype, 
		b.TransID,
		ISNULL(b.BetID,0),
		b.Bettype,
		b.hdp1 AS hdp1, 
		b.hdp2 AS hdp2,
		modds,
		b.Oddstype,
		b.Odds,
		b.stake,
		b.actual_stake,  		
		b.betteam,
		b.status AS Status,				
		b.refno,
		b.Transdate,	
		b.winlostdate,			
		(b.winlost-actual_stake),
		- (b.winlost-actual_stake),
		comm ,
		b.playercomm , 
		b.Liveindicator,
		b.Livehomescore,
		b.Liveawayscore,
		b.IP AS IP,
		m.LeagueID,
		m.MatchID,	
		m.MatchCode,
		'' AS Race,	
		m.HomeID,
		m.AwayID, 		
		m.Betstatus,
		ISNULL(m.isNeutral, CONVERT(BIT,0)) AS IsNeutral,
		0,0,
		b.currency,
		'' as showtime
	FROM
		bodb_archive.dbo.bettrans_bk AS b WITH (NOLOCK)		
		INNER JOIN bodb_archive.dbo.match_BK AS m WITH (NOLOCK) ON b.matchid=m.matchid  
	WHERE
		b.winlostdate BETWEEN @fdate AND @TempToDate AND
		b.custid=@custid AND
		( b.bettype BETWEEN 1201 AND 1299) AND
		b.ruben = 1 AND
		b.status NOT IN ('VOID', 'REJECT', 'REFUND')
	END
	--- RNG Casino 
	IF @ShowCS=1
	BEGIN
		INSERT INTO #BetListByDateMem
		SELECT
		251 Sporttype, 
		b.TransID,
		ISNULL(b.BetID,0),
		b.Bettype,
		b.hdp1 AS hdp1, 
		b.hdp2 AS hdp2,
		modds,
		b.Oddstype,
		b.Odds,
		b.stake,
		b.actual_stake,  		
		b.betteam,
		b.status AS Status,				
		b.refno,
		b.Transdate,	
		b.winlostdate,			
		(b.winlost-actual_stake),
		- (b.winlost-actual_stake),
		comm ,
		b.playercomm , 
		b.Liveindicator,
		b.Livehomescore,
		b.Liveawayscore,
		b.IP AS IP,
		0 as LeagueID,
		0 as MatchID,	
		0 as MatchCode,
		'' AS Race,	
		0 as HomeID,
		0 as AwayID, 		
		'' as Betstatus,
		CONVERT(BIT,0) AS IsNeutral,
		0,0,
		b.currency,
		'' as showtime
	FROM
		bodb_archive.dbo.bettrans_bk AS b WITH (NOLOCK)		
	WHERE
		b.winlostdate BETWEEN @fdate AND @TempToDate AND
		b.custid=@custid AND
		b.bettype=71 AND
		b.ruben = 1 AND
		b.status NOT IN ('VOID', 'REJECT', 'REFUND')
	END	
	-- Racebook
	IF @ShowRB = 1
	BEGIN
		INSERT INTO #BetListByDateMem
		SELECT
			l.sporttype, --Sporttype
			b.TransID,
			ISNULL(b.BetID,0),
			b.Bettype,
			b.hdp1, 
			b.hdp2,
			modds,
			0 AS OddsType, 
			b.Odds, 
			b.stake,
			b.actual_stake,   
			'' AS Betteam, --Betteam
			b.Status,				
			b.refno,
			b.Transdate,	
			b.winlostdate,						
			(b.winlost-actual_stake),
			awinlost,
			comm ,
			b.playercomm,	
			0 AS LiveIndicator , 
			b.LiveHomescore, 
			b.LiveAwayscore,
			b.IP AS IP,
			m.LeagueID,
			m.OrId,--0, --MatchID	
			m.MatchCode,
			m.GroupMatch,--Race
			m.TeamID, --HomeID
			0, --AwayID		
			0, --Betstatus
			CONVERT(BIT,0) AS IsNeutral,
			b.virtualrate,
			isnumeric(m.programID),
			b.currency,
			'' As ShowTime
		FROM
			bodb_archive.dbo.bettrans_bk AS b WITH (NOLOCK)		
			INNER JOIN bodb_archive.dbo.Outright_bk AS m WITH (NOLOCK) ON b.matchid=m.orid
			INNER JOIN dbo.League AS l WITH (NOLOCK) ON m.leagueID = l.leagueID 
		WHERE
			b.winlostdate BETWEEN @fdate AND @TempToDate AND
			b.custid=@custid AND
			b.ruben = 1 AND 
			b.status NOT IN ('VOID','REJECT','REFUND') AND
			b.bettype IN (31, 32, 33)
	END	
END


--@currency
SELECT * INTO #TempExchange 
FROM Lrf_f_GetExchangeDaily(@FDate,@TDate)
WHERE exchangeid = @currency

--exclude draw for no draw option (2)
DELETE FROM #BetListByDateMem
WHERE @drawfilter = 2 AND status = 'DRAW' AND ABS(modds) <> 0.25


SELECT 
	@TotalRows = count(transid),
	@SumWinlost=SUM(ISNULL(winlost,0)),
	@SumLicenseeWL=SUM(ISNULL(LicenseeWL,0)),
	@SumComm=SUM(ISNULL(comm,0)) ,
	@SumPlayerComm=SUM(ISNULL(playercomm,0)),
	--USD
	@SumWinlostUSD=SUM(ISNULL(winlost*e.USD,0)),
	@SumLicenseeWLUSD=SUM(ISNULL(LicenseeWL*e.USD,0)),
	@SumCommUSD=SUM(ISNULL(comm*e.USD,0)) ,
	@SumPlayerCommUSD=SUM(ISNULL(Playercomm*e.USD,0)),
	--EUR
	@SumWinlostEUR=SUM(ISNULL(winlost*e.EUR,0)),
	@SumLicenseeWLEUR=SUM(ISNULL(LicenseeWL*e.EUR,0)),
	@SumCommEUR=SUM(ISNULL(comm*e.EUR,0)) ,
	@SumPlayerCommEUR=SUM(ISNULL(playercomm*e.EUR,0))
FROM #BetListByDateMem b
INNER JOIN 
	#TempExchange e 
	ON e.ExchangeDate = b.winlostdate   AND e.exchangeid = b.currency
	
SELECT	d.* , 
		--BASE RM
		d.stake*e.MYR		AS	StakeMYR,
		d.actual_stake*e.MYR		AS	actual_stakeMYR,
		d.winlost*e.MYR		AS	WinlostMYR,
		d.LicenseeWL*e.MYR	AS	LicenseeWLMYR,
		d.comm*e.MYR		AS	commMYR,
		d.playercomm*e.MYR  AS PlayerCommMYR,
		--BASEUSD
		d.stake*e.USD			AS	StakeUSD,
		d.actual_stake*e.USD	AS	actual_stakeUSD,
		d.winlost*e.USD			AS	WinlostUSD,
		d.LicenseeWL*e.USD		AS	LicenseeWLUSD,
		d.comm*e.USD			AS	commUSD,
		d.playercomm*e.USD		AS  playercommUSD,
		--BASEEUR
		d.stake*e.EUR			AS	StakeEUR,
		d.actual_stake*e.EUR	AS	actual_stakeEUR,
		d.winlost*e.EUR			AS	WinlostEUR,
		d.LicenseeWL*e.EUR		AS	LicenseeWLEUR,
		d.comm*e.EUR			AS	commEUR,
		d.playercomm*e.EUR		AS PlayercommEUR

FROM	#BetListByDateMem d 
		INNER JOIN #TempExchange e 
		ON e.ExchangeDate =  d.winlostdate AND e.exchangeid = d.currency
ORDER BY TransID 

DECLARE @BettransDetail TABLE(  
	refno BIGINT,  
	odds SMALLMONEY,  
	stake MONEY,
	status NVARCHAR(10),  
	apositiontaking SMALLMONEY,  
	bettype SMALLINT,
	Betteam nvarchar (10),
	stakeMYR MONEY,
	stakeUSD MONEY,
	stakeEUR MONEY
	 )   

IF @ShowRB = 1
begin
	IF @tdate > @MoveBetsDay 
	BEGIN
		INSERT INTO @BettransDetail
		SELECT 
			BM.refno, 
			BM.odds, 
			BM.stake,
			BM.status, 
			BM.apositiontaking, 
			BM.bettype  ,
			BM.Betteam,
			BM.stake * e.MYR as stakeMYR,
			BM.stake * e.USD as stakeUSD,
			BM.stake * e.EUR as stakeEUR
		FROM bettransm BM WITH (NOLOCK)
		INNER JOIN #BetListByDateMem B ON BM.refno = B.transid
		INNER JOIN #TempExchange e 
		ON e.ExchangeDate =  b.winlostdate AND e.exchangeid = b.currency
		WHERE B.Bettype IN (33,43)
	END
		
	IF @fdate <= @MoveBetsDay
	BEGIN
		INSERT INTO @BettransDetail
		SELECT 
			BM.refno, 
			BM.odds, 
			BM.stake,
			BM.status, 
			BM.apositiontaking, 
			BM.bettype  ,
			BM.Betteam  ,
			BM.stake * e.MYR as stakeMYR,
			BM.stake * e.USD as stakeUSD,
			BM.stake * e.EUR as stakeEUR
		FROM bettransm14 BM WITH (NOLOCK)
		INNER JOIN #BetListByDateMem B ON BM.refno = B.transid
		INNER JOIN #TempExchange e 
		ON e.ExchangeDate =  b.winlostdate AND e.exchangeid = b.currency
		WHERE B.Bettype IN (33,43)
	END	
	
	IF @fdate < @BalanceUpDay
	BEGIN
		INSERT INTO @BettransDetail
		SELECT 
			BM.refno, 
			BM.odds, 
			BM.stake,
			BM.status, 
			BM.apositiontaking, 
			BM.bettype  ,
			BM.Betteam,
			BM.stake * e.MYR as stakeMYR,
			BM.stake * e.USD as stakeUSD,
			BM.stake * e.EUR as stakeEUR
		FROM bodb_archive.dbo.bettransm BM WITH (NOLOCK)
		INNER JOIN #BetListByDateMem B ON BM.refno = B.transid
		INNER JOIN #TempExchange e ON e.ExchangeDate = b.winlostdate   AND e.exchangeid = b.currency
		WHERE B.Bettype IN (33,43)
	END
END	

IF @ShowLC=1
BEGIN
	IF @tdate > @MoveBetsDay 
	BEGIN
		INSERT INTO @BettransDetail
		SELECT 
			BG.refno, 
			BG.odds, 
			BG.stake,
			BG.status, 
			BG.apositiontaking, 
			BG.bettype  ,
			BG.Betteam,
			BG.stake * e.MYR as stakeMYR,
			BG.stake * e.USD as stakeUSD,
			BG.stake * e.EUR as stakeEUR
		FROM bettransg BG WITH (NOLOCK)
		INNER JOIN #BetListByDateMem B ON BG.refno = B.refno and BG.custid = @CustID
		INNER JOIN #TempExchange e 
		ON e.ExchangeDate =  b.winlostdate AND e.exchangeid = b.currency
		WHERE B.Bettype BETWEEN 1101 AND 1199
	END
		
	IF @fdate <= @MoveBetsDay
	BEGIN
		INSERT INTO @BettransDetail
		SELECT 
			BG.refno, 
			BG.odds, 
			BG.stake,
			BG.status, 
			BG.apositiontaking, 
			BG.bettype  ,
			BG.Betteam  ,
			BG.stake * e.MYR as stakeMYR,
			BG.stake * e.USD as stakeUSD,
			BG.stake * e.EUR as stakeEUR
		FROM bettransg14 BG WITH (NOLOCK)
		INNER JOIN #BetListByDateMem B ON BG.refno = B.refno and BG.custid = @CustID
		INNER JOIN #TempExchange e 
		ON e.ExchangeDate =  b.winlostdate AND e.exchangeid = b.currency
		WHERE B.Bettype BETWEEN 1101 AND 1199
	END	
	
	IF @fdate < @BalanceUpDay
	BEGIN
		INSERT INTO @BettransDetail
		SELECT 
			BG.refno, 
			BG.odds, 
			BG.stake,
			BG.status, 
			BG.apositiontaking, 
			BG.bettype  ,
			BG.Betteam  ,
			BG.stake * e.MYR as stakeMYR,
			BG.stake * e.USD as stakeUSD,
			BG.stake * e.EUR as stakeEUR
		FROM bodb_archive.dbo.bettransG BG WITH (NOLOCK)
		INNER JOIN #BetListByDateMem B ON BG.refno = B.refno and BG.custid = @CustID
		INNER JOIN #TempExchange e  ON e.ExchangeDate = b.winlostdate   AND e.exchangeid = b.currency
		WHERE B.Bettype BETWEEN 1101 AND 1199
	END
END
	
SELECT * FROM @BettransDetail ORDER BY RefNo,Bettype	

DROP TABLE #TempBetList	
DROP TABLE #BetListByDateMem
DROP TABLE #TempExchange

GO
GRANT EXECUTE ON [dbo].[Acc_BetList_SelWinloss_Mem2] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_BetList_SelWinloss_Mem2] TO [bodbLicenseeNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_BetList_SelWinloss_Mem2] TO [vnteam]
