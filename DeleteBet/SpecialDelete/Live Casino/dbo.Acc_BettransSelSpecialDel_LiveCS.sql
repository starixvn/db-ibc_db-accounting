ALTER PROCEDURE [dbo].Acc_BettransSelSpecialDel_LiveCS
	@MatchID	INT,
	@FromRefNo	BIGINT,
	@ToRefNo	BIGINT
AS
/*
	Created: 20120207@Lukas	
	Task: Select bets transaction need to delete (Live Casino)
	DB: DB053.BODB02

	History:
		- 20121107@Elodie:  Allow to void settled tickets 
							Allow user to delete deposit tickets
		- 20130702@Elodie: Add new bettype 1103, 1104							
	Explanation's Param:

*/
BEGIN
	SET NOCOUNT ON

	CREATE TABLE #SpecialDeleteBets 
	(
		transid BIGINT,
		refno BIGINT,
		custid INT,
		username VARCHAR(30),
		odds SMALLMONEY, 
		bettype SMALLINT,
		OddsType INT, 
		transdate DATETIME, 
		betteam NVARCHAR(10),
		hdp1 SMALLMONEY, 
		hdp2 SMALLMONEY,
		livehomescore SMALLINT, 
		liveawayscore SMALLINT,
		spositiontaking MONEY,
		mpositiontaking MONEY,
		apositiontaking MONEY,
		stake MONEY,
		winlost MONEY,
		comm MONEY,
		currency TINYINT,
		IsDeposit tinyint,
		site varchar(10),
		status NVARCHAR(10),
		mrecommend INT
	)
	CREATE TABLE #BettransDetail 
	(  
		refno BIGINT,  
		odds SMALLMONEY,  
		stake MONEY,
		status NVARCHAR(10),  										
		bettype SMALLINT,
		Betteam nvarchar(10)
	 )   
	
	DECLARE @today SMALLDATETIME
	SET @today = convert(nvarchar(10), current_timestamp, 120)

	INSERT INTO #SpecialDeleteBets
	SELECT
		b.transid,	
		b.refno,
		b.custid,
		b.username,
		b.odds,
		b.bettype,
		b.oddstype,			
		b.transdate,
		betteam,
		hdp1,
		hdp2,
		livehomescore,
		liveawayscore,
		b.spositiontaking,
		b.mpositiontaking,
		b.apositiontaking,
		b.stake,
		b.winlost - b.actual_stake as winlost,
		b.playercomm as comm,		
		b.currency, 
		CASE WHEN betfrom IN ('D', 'M', 'E', 'L') THEN 1 ELSE 0 END AS IsDeposit,
		ag.site,
		b.status,
		b.mrecommend
	FROM 
		bettrans b WITH (NOLOCK)
		INNER JOIN customer ag WITH (NOLOCK) ON b.recommend = ag.custid
	WHERE
		matchid=@matchid 
		AND b.transid BETWEEN @FromRefNo AND @ToRefNo
		and b.bettype in (1101, 1102, 1103, 1104)
		AND statusID NOT IN (0, 101, 102, 121) -- ('Running', 'Void', 'Reject', 'Dummy ticket')
		and winlostdate = @today
	ORDER BY IsDeposit, transid

	INSERT INTO #BettransDetail
	SELECT bg.refno, bg.odds, bg.stake, bg.status, bg.bettype, bg.betteam
	FROM #SpecialDeleteBets b
		INNER JOIN bettransG bg WITH(NOLOCK) ON b.refno = bg.refno
	
	--0. For Normal bets
	SELECT * 
	FROM #SpecialDeleteBets  WITH (NOLOCK)
	WHERE
		custid not in ( SELECT CustID FROM [f_GetBetDaqCustomer] (1))
		and username <> '12EU'
		AND IsDeposit = 0
		AND mrecommend not in (105181, 118473, 105183)	
		
	--1. For Deposit bets
	SELECT *	
	FROM #SpecialDeleteBets WITH (NOLOCK)
	WHERE 
		custid not in ( SELECT CustID FROM  [f_GetBetDaqCustomer] (1))
		AND username <> '12EU'
		AND IsDeposit = 1	
		AND mrecommend not in (105181, 118473, 105183)
		
	--2. For Special bets
	SELECT * 
	FROM #SpecialDeleteBets WITH(NOLOCK)
	WHERE 
		custid in (SELECT CustID FROM [f_GetBetDaqCustomer] (1))

	--3. For 12EU
	SELECT * 
	FROM #SpecialDeleteBets with (NOLOCK)
	WHERE 
		username = '12EU'

	--4. For member of master: MHCEU (105181), MHCRM (118473), MHCUS(105183)
	SELECT * 
	FROM #SpecialDeleteBets with (NOLOCK)
	WHERE 
		mrecommend in (105181, 118473, 105183)
		
	SELECT * FROM #BettransDetail

	DROP TABLE #SpecialDeleteBets
	DROP TABLE #BettransDetail
END

GO
GRANT VIEW DEFINITION ON [dbo].[Acc_BettransSelSpecialDel_LiveCS] TO [vnteam]
GO
GRANT EXECUTE ON [dbo].[Acc_BettransSelSpecialDel_LiveCS] TO [BodbAdminNet]
