ALTER PROCEDURE [dbo].[NAP_VoidMetricGaming_Sel]
	@MatchId			INT,
	@BetTypes			VARCHAR(1000)	= '',		
	@Event801			VARCHAR(2000) 	= '',--801 
	@Event803			VARCHAR(2000) 	= '',--803 	
	@Event804			VARCHAR(2000) 	= '',--804 
	@Event805			VARCHAR(2000) 	= ''--805 
AS
BEGIN
/*
    Created by: 20150624@Dominic
	Date: 
	Original: 
	Task: Select Metric Gaming tickets for delete
	DB: DBTXN/BODB02

	Revisions:


	Explanation's Param:


*/
	SET NOCOUNT ON
	CREATE TABLE #SpecialDeleteBets (
		transid				BIGINT,
		refno				BIGINT,
		custid				INT,
		username			VARCHAR(30),
		username2			NVARCHAR(50),
		odds				SMALLMONEY, 
		OddsType			INT, 
		transdate			DATETIME,
		bettype				SMALLINT, 
		betteam				NVARCHAR(10),
		betcheck			NVARCHAR(50),
		hdp1				SMALLMONEY, 
		hdp2				SMALLMONEY,
		IsLiveIndicator		BIT,
		livehomescore 		SMALLINT, 
		liveawayscore 		SMALLINT,
		creator				VARCHAR(30),
		Stake				MONEY,
		CurrencyName		VARCHAR(10),
		IsDeposit			TINYINT,
		site				VARCHAR(10),
		status				NVARCHAR(10), 
		mrecommend			INT, 
		recommend			INT, 
		SecAcceptFlag		BIT,
		betid				BIGINT,
		transdesc			NVARCHAR(300)
	)
	DECLARE @Event801Tbl TABLE(Custom1 VARCHAR(50))
	INSERT @Event801Tbl(Custom1)
	SELECT val FROM dbo.strSplit(@Event801, '^')
	
	DECLARE @Event803Tbl TABLE(Custom1 VARCHAR(50))
	INSERT @Event803Tbl(Custom1)
	SELECT val FROM dbo.strSplit(@Event803, '^')
	
	DECLARE @Event804Tbl TABLE(Custom1 VARCHAR(50))
	INSERT @Event804Tbl(Custom1)
	SELECT val FROM dbo.strSplit(@Event804, '^')
	
	DECLARE @Event805Tbl TABLE(Custom1 VARCHAR(50))
	INSERT @Event805Tbl(Custom1)
	SELECT val FROM dbo.strSplit(@Event805, '^')
	
	DECLARE @FromDate	DATETIME
	SELECT	@FromDate =  CONVERT(VARCHAR(10),CURRENT_TIMESTAMP,120)
		
	INSERT INTO #SpecialDeleteBets
	SELECT
		b.transid,
		b.refno,
		b.custid,
		c.username,
		c.username2,
		b.odds,   
		b.OddsType,  
		b.transdate,
		b.bettype,
		betteam,
		betcheck,
		hdp1,
		hdp2,
		b.liveindicator,
		b.livehomescore,
		b.liveawayscore,
		cr.username AS creator,	
		stake,
		b.CurrencyName, 
		CASE WHEN b.srecommend IN (SELECT custid from custDB.dbo.Dep_CustSuper with(NOLOCK)) then 1 ELSE 0 END as IsDeposit,
		ag.site,
		CASE WHEN b.status = 'running' AND ISNULL(b.SecAcceptFlag, 0) = 1 AND ISNULL(b.checktime, CURRENT_TIMESTAMP) > CURRENT_TIMESTAMP THEN 'waiting'
			 ELSE b.status 
			 END AS status,
		b.mrecommend,
		b.recommend,
		ISNULL(SecAcceptFlag,0) SecAcceptFlag,
		b.betid,
		b.transdesc
	FROM 
		bettrans b WITH (NOLOCK)
		INNER JOIN custDB.dbo.Customer c WITH (NOLOCK) ON b.custid = c.custid
		INNER JOIN custDB.dbo.customer ag WITH (NOLOCK) ON b.recommend = ag.custid
		INNER JOIN custDB.dbo.customer cr WITH (NOLOCK) ON cr.custid = b.creator
		INNER JOIN dbo.strSplit(@BetTypes,'^') s ON s.val = b.bettype
		INNER JOIN dbo.match mat WITH(NOLOCK) ON mat.matchid = b.matchid
	WHERE
		b.matchid=@MatchId 	
		AND mat.eventdate >=@FromDate
		AND statusID NOT IN (101,102 ) -- reject, void
		AND 1 = CASE WHEN b.Bettype IN (801,803,804,805) THEN CASE 
								WHEN b.Bettype = 801
									AND EXISTS(
											SELECT TOP 1 1
											FROM @Event801Tbl rs
											WHERE ISNULL(rs.Custom1,'') <> '' AND CHARINDEX('BettypeTime='+ rs.Custom1, b.transdesc,0) <> 0
										)
									THEN 1
								WHEN b.Bettype = 803
									AND EXISTS(
											SELECT TOP 1 1
											FROM @Event803Tbl rs
											WHERE ISNULL(rs.Custom1,'') <> '' AND CHARINDEX('BettypeTime='+ rs.Custom1, b.transdesc,0) <> 0
										)
									THEN 1
								WHEN b.Bettype = 804
									AND EXISTS(
											SELECT TOP 1 1
											FROM @Event804Tbl rs
											WHERE ISNULL(rs.Custom1,'') <> '' AND CHARINDEX('BettypeTime='+ rs.Custom1, b.transdesc,0) <> 0
										)
									THEN 1
								WHEN b.Bettype = 805
									AND EXISTS(
											SELECT TOP 1 1
											FROM @Event805Tbl rs
											WHERE ISNULL(rs.Custom1,'') <> '' AND CHARINDEX('BettypeTime='+ rs.Custom1, b.transdesc,0) <> 0
										)
									THEN 1
								ELSE 0
								END
					ELSE 1
					END
	UNION ALL
	SELECT
		b.translogID transid,
		b.translogID refno,
		b.custid,
		c.username,
		c.username2,
		b.odds,   
		b.custom1 OddsType,  
		b.transdate,
		b.GameID,
		NULL betteam,
		NULL betcheck,
		0 hdp1,
		0 hdp2,
		b.liveindicator liveindicator,
		NULL livehomescore,
		NULL liveawayscore,
		cr.username AS creator,	
		b.stake,
		b.CurrencyName, 
		CASE WHEN b.srecommend IN (SELECT custid from custDB.dbo.Dep_CustSuper with(NOLOCK)) then 1 ELSE 0 END as IsDeposit,
		ag.site,
		b.status,
		b.mrecommend,
		b.recommend,
		NULL SecAcceptFlag,
		NULL betid,
		b.transdesc
	FROM 
		translog b WITH (NOLOCK)
		INNER JOIN custDB.dbo.Customer c WITH (NOLOCK) ON b.custid = c.custid
		INNER JOIN custDB.dbo.customer ag WITH (NOLOCK) ON b.recommend = ag.custid
		INNER JOIN custDB.dbo.customer cr WITH (NOLOCK) ON cr.custid = b.creator
		INNER JOIN dbo.strSplit(@BetTypes,'^') s ON s.val = b.gameID
		INNER JOIN dbo.match mat WITH(NOLOCK) ON mat.matchid = b.EventID
		LEFT JOIN bettrans bs WITH(NOLOCK) ON b.gameid = bs.bettype AND bs.matchid = b.eventid AND bs.custid = b.Custid AND b.translogid = bs.refno
	WHERE
		b.EventID=@MatchId 
		AND mat.eventdate >=@FromDate
		AND b.gameid IN (801,803,804,805,806) AND bs.refno IS NULL	
		AND b.statusID NOT IN (101,102 ) -- reject, void
		AND 1 = CASE WHEN b.GameID IN (801,803,804,805) THEN CASE 
								WHEN b.GameID = 801
									AND EXISTS(
											SELECT TOP 1 1
											FROM @Event801Tbl rs
											WHERE ISNULL(rs.Custom1,'') <> '' AND CHARINDEX('BettypeTime='+ rs.Custom1, b.transdesc,0) <> 0
										)
									THEN 1
								WHEN b.GameID = 803
									AND EXISTS(
											SELECT TOP 1 1
											FROM @Event803Tbl rs
											WHERE ISNULL(rs.Custom1,'') <> '' AND CHARINDEX('BettypeTime='+ rs.Custom1, b.transdesc,0) <> 0
										)
									THEN 1
								WHEN b.GameID = 804
									AND EXISTS(
											SELECT TOP 1 1
											FROM @Event804Tbl rs
											WHERE ISNULL(rs.Custom1,'') <> '' AND CHARINDEX('BettypeTime='+ rs.Custom1, b.transdesc,0) <> 0
										)
									THEN 1
								WHEN b.GameID = 805
									AND EXISTS(
											SELECT TOP 1 1
											FROM @Event805Tbl rs
											WHERE ISNULL(rs.Custom1,'') <> '' AND CHARINDEX('BettypeTime='+ rs.Custom1, b.transdesc,0) <> 0
										)
									THEN 1
								ELSE 0
								END
					ELSE 1
					END	 
	
	----Match info
	--SELECT MATCH.homeid,
	--		MATCH.awayid,
	--		MATCH.matchcode,
	--		MATCH.eventdate,
	--		MATCH.leagueid,
	--		GETDATE() AS DATETIME,
	--		ISNULL(MATCH.isNeutral, CONVERT(BIT,0)) AS IsNeutral,
	--		0 AS IsOutright
	--FROM
	--	MATCH WITH (NOLOCK)
	--WHERE 
	--	MATCH.matchid = @MatchId
			
	--0. For Normal bets
	SELECT transid	, refno	
		   ,custid		
		   ,username	
		   ,username2	
		   ,odds		
		   ,OddsType	
		   ,transdate	
		   ,bettype		
		   ,betteam		
		   ,betcheck
		   ,hdp1		
		   ,hdp2		
		   ,IsLiveIndicator
		   ,livehomescore
		   ,liveawayscore
		   ,creator		
		   ,Stake		
		   ,CurrencyName
		   ,IsDeposit	
		   ,site		
		   ,status		
		   ,mrecommend	
		   ,recommend	
		   ,SecAcceptFlag	
		   ,betid
		   ,transdesc		 
	FROM #SpecialDeleteBets
	WHERE custid NOT IN ( SELECT CustID FROM  [f_GetBetDaqCustomer] (1)) -- Betdaq
	AND username <> '12EU' -- 12EU
	AND IsDeposit = 0
	AND mrecommend NOT IN (105181, 118473, 105183) -- MHC
	AND recommend NOT IN (11196380, 13423967, 52466) -- Foobet, 1E, 8RM
	AND custid NOT IN (1077687, 2331, 115770, 15523642) -- Betfair: BFOS, BF, ITibc102, BF3
	ORDER BY transid

	--8: For 8RM
	SELECT s.transid , s.refno		
		   ,s.custid		
		   ,s.username	
		   ,s.username2	
		   ,s.odds		
		   ,s.OddsType	
		   ,s.transdate	
		   ,s.bettype		
		   ,s.betteam	
		   ,s.betcheck	
		   ,s.hdp1		
		   ,s.hdp2		
		   ,s.IsLiveIndicator
		   ,s.livehomescore
		   ,s.liveawayscore
		   ,s.creator		
		   ,s.Stake		
		   ,s.CurrencyName
		   ,s.IsDeposit	
		   ,s.site		
		   ,s.status		
		   ,s.mrecommend	
		   ,s.recommend	
		   ,s.SecAcceptFlag	
		   ,s.betid
		   ,b.transid AS followedId
		   ,b.Username AS followedUsername
		   ,s.transdesc
	FROM #SpecialDeleteBets s
	LEFT JOIN dbo.bettrans b ON s.betid = b.transid
	WHERE s.recommend = 52466
	ORDER BY s.IsDeposit desc, s.transid
	
	--1. For Deposit bets
	SELECT transid	, refno	
		   ,custid		
		   ,username	
		   ,username2	
		   ,odds		
		   ,OddsType	
		   ,transdate	
		   ,bettype		
		   ,betteam		
		   ,betcheck
		   ,hdp1		
		   ,hdp2		
		   ,IsLiveIndicator
		   ,livehomescore
		   ,liveawayscore
		   ,creator		
		   ,Stake		
		   ,CurrencyName
		   ,IsDeposit	
		   ,site		
		   ,status		
		   ,mrecommend	
		   ,recommend	
		   ,SecAcceptFlag	
		   ,betid
		   ,transdesc
	FROM #SpecialDeleteBets
	WHERE custid NOT IN ( SELECT CustID FROM  [f_GetBetDaqCustomer] (1))
	AND username <> '12EU'
	AND IsDeposit = 1	
	AND mrecommend NOT IN (105181, 118473, 105183)
	AND recommend NOT IN (11196380, 13423967, 52466) -- Foobet: 11196380, 1E: 13423967, 8RM: 52466
	AND custid NOT IN (1077687, 2331, 115770, 15523642) -- Betfair: BFOS, BF, ITibc102, BF3
	ORDER BY transid
		
	--2. For Special bets: betdaq
	SELECT transid	, refno	
		   ,custid		
		   ,username	
		   ,username2	
		   ,odds		
		   ,OddsType	
		   ,transdate	
		   ,bettype		
		   ,betteam	
		   ,betcheck	
		   ,hdp1		
		   ,hdp2		
		   ,IsLiveIndicator
		   ,livehomescore
		   ,liveawayscore
		   ,creator		
		   ,Stake		
		   ,CurrencyName
		   ,IsDeposit	
		   ,site		
		   ,status		
		   ,mrecommend	
		   ,recommend	
		   ,SecAcceptFlag	
		   ,betid 
		   ,transdesc
	FROM #SpecialDeleteBets
	WHERE custid IN (SELECT CustID FROM  [f_GetBetDaqCustomer] (1))
	AND recommend <> 11196380
	ORDER BY IsDeposit desc, transid

	--3. For 12EU
	SELECT transid	, refno	
		   ,custid		
		   ,username	
		   ,username2	
		   ,odds		
		   ,OddsType	
		   ,transdate	
		   ,bettype		
		   ,betteam	
		   ,betcheck	
		   ,hdp1		
		   ,hdp2		
		   ,IsLiveIndicator
		   ,livehomescore
		   ,liveawayscore
		   ,creator		
		   ,Stake		
		   ,CurrencyName
		   ,IsDeposit	
		   ,site		
		   ,status		
		   ,mrecommend	
		   ,recommend	
		   ,SecAcceptFlag
		   ,betid	
		   ,transdesc 
	FROM #SpecialDeleteBets
	WHERE username = '12EU'
	ORDER BY IsDeposit desc, transid

	--4. For member of master: MHCEU (105181), MHCRM (118473), MHCUS(105183)
	SELECT transid	, refno	
		   ,custid		
		   ,username	
		   ,username2	
		   ,odds		
		   ,OddsType	
		   ,transdate	
		   ,bettype		
		   ,betteam	
		   ,betcheck	
		   ,hdp1		
		   ,hdp2		
		   ,IsLiveIndicator
		   ,livehomescore
		   ,liveawayscore
		   ,creator		
		   ,Stake		
		   ,CurrencyName
		   ,IsDeposit	
		   ,site		
		   ,status		
		   ,mrecommend	
		   ,recommend	
		   ,SecAcceptFlag
		   ,betid
		   ,transdesc	 
	FROM #SpecialDeleteBets
	WHERE mrecommend IN (105181, 118473, 105183)
	ORDER BY IsDeposit desc, transid

	--5: For member of Foobet
	SELECT transid, refno		
		   ,custid		
		   ,username	
		   ,username2	
		   ,odds		
		   ,OddsType	
		   ,transdate	
		   ,bettype		
		   ,betteam	
		   ,betcheck	
		   ,hdp1		
		   ,hdp2		
		   ,IsLiveIndicator
		   ,livehomescore
		   ,liveawayscore
		   ,creator		
		   ,Stake		
		   ,CurrencyName
		   ,IsDeposit	
		   ,site		
		   ,status		
		   ,mrecommend	
		   ,recommend	
		   ,SecAcceptFlag	
		   ,betid
		   ,transdesc
	FROM #SpecialDeleteBets 
	WHERE recommend = 11196380
	ORDER BY IsDeposit desc, transid

	--6: For Betfair
	SELECT transid	, refno	
		   ,custid		
		   ,username	
		   ,username2	
		   ,odds		
		   ,OddsType	
		   ,transdate	
		   ,bettype		
		   ,betteam		
		   ,betcheck
		   ,hdp1		
		   ,hdp2		
		   ,IsLiveIndicator
		   ,livehomescore
		   ,liveawayscore
		   ,creator		
		   ,Stake		
		   ,CurrencyName
		   ,IsDeposit	
		   ,site		
		   ,status		
		   ,mrecommend	
		   ,recommend	
		   ,SecAcceptFlag	
		   ,betid
		   ,transdesc
	FROM #SpecialDeleteBets 
	WHERE custid IN (1077687, 2331, 115770, 15523642) -- Betfair: BFOS, BF, ITibc102, BF3
	ORDER BY IsDeposit desc, transid

	--7: For ONEEXCHANGE
	SELECT transid	, refno	
		   ,custid		
		   ,username	
		   ,username2	
		   ,odds		
		   ,OddsType	
		   ,transdate	
		   ,bettype		
		   ,betteam		
		   ,betcheck
		   ,hdp1		
		   ,hdp2		
		   ,IsLiveIndicator
		   ,livehomescore
		   ,liveawayscore
		   ,creator		
		   ,Stake		
		   ,CurrencyName
		   ,IsDeposit	
		   ,site		
		   ,status		
		   ,mrecommend	
		   ,recommend	
		   ,SecAcceptFlag
		   ,betid	
		   ,transdesc
	FROM #SpecialDeleteBets 
	WHERE recommend IN (13423967)
	ORDER BY IsDeposit desc, transid

	DROP TABLE #SpecialDeleteBets

	SET NOCOUNT OFF
/*
*/
END



GO
GRANT EXECUTE ON [dbo].[NAP_VoidMetricGaming_Sel] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_VoidMetricGaming_Sel] TO [vnteam] AS [dbo]