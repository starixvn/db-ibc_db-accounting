

ALTER PROC [dbo].[Acc_BettransSelSpecialDel_NumberGame_xtest]
	@MatchID	INT,
	@FromRefNo	BIGINT,
	@ToRefNo	BIGINT,
	@Live		VARCHAR(100) = '',	-- bettype for live-ball
	@Dead		VARCHAR(100) = '',  -- bettype for dead-ball
	@UserName	VARCHAR(50)	 = ''
AS
/*
	Created by: Lukas
	Date: 
	Original: account\dele\teamlisting.asp
	Task: Select bets transaction need to delete (Number Game)
	DB: DB053.BODB02

	History:
		- 20110408@Amy: Change function to get Odds value and odds type
		- 20111122@Sophia: Add Checktime and SecAcceptFlag to show status waiting or running
		- 20120629@Sophia: Remove function f_GetOddsByBettype, f_ShowOddsByBettype,f_GetChoice for odds, Oddstype, betteam
		- 20120716@Sophia: Add condition 'L' in betfrom to check Deposit
		
	Explanation's Param:

*/
BEGIN
	SET NOCOUNT ON

	CREATE TABLE #SpecialDeleteBets 
				(
					transid BIGINT,
					custid INT,
					username VARCHAR(30),
					odds SMALLMONEY, 
					OddsType INT, 
					transdate DATETIME,
					bettype SMALLINT, 
					betteam NVARCHAR(10),
					hdp1 SMALLMONEY, 
					hdp2 SMALLMONEY,
					livehomescore SMALLINT, 
					liveawayscore SMALLINT,
					creator VARCHAR(30),
					StakePositiontaking MONEY,
					currency TINYINT,
					IsDeposit TINYINT,
					site VARCHAR(10),
					status NVARCHAR(10), 
					mrecommend INT, 
					recommend INT, 
					liveindicator BIT,
					transid2 BIGINT
				)


	INSERT INTO #SpecialDeleteBets
	SELECT * FROM
	(
		SELECT
			b.transid,
			b.custid,
			b.username,
			b.odds,   
			b.OddsType,  
			b.transdate,
			b.bettype,
			betteam,
			hdp1,
			hdp2,
			livehomescore,
			liveawayscore,
			cr.username AS creator,	
			stake AS StakePositiontaking,
			b.currency, 
			CASE WHEN betfrom IN ('D', 'M', 'E', 'L') THEN 1 ELSE 0 END AS IsDeposit,
			ag.site,
			CASE WHEN b.status = 'running' AND IsNull(b.SecAcceptFlag, 0) = 1 and IsNull(b.checktime, CURRENT_TIMESTAMP) > CURRENT_TIMESTAMP THEN 'waiting'
				 ELSE b.status 
			     END as status,
			b.mrecommend,
			b.recommend,
			b.liveindicator,
			b.transid2
		FROM 
			bettrans b WITH (NOLOCK)
			--INNER JOIN customer  with (NOLOCK) ON customer.custid=b.custid
			INNER JOIN customer ag WITH (NOLOCK) ON b.recommend = ag.custid
			INNER JOIN customer cr WITH (NOLOCK) ON cr.custid = b.creator
		WHERE
			matchid=@matchid 
			AND b.transid BETWEEN @FromRefNo AND @ToRefNo
			AND statusID NOT IN (101,102,121)   ---- Void, Reject, 121: dummy ticket
			AND
			(   
				(
					b.bettype IN (SELECT CONVERT(INT,val) FROM dbo.strSplit(@Dead,'^'))
					AND 
					b.liveindicator = 0 
				)
				 OR
				(
					b.bettype IN (SELECT CONVERT(INT,val) FROM dbo.strSplit(@Live,'^'))
					AND 
					b.liveindicator = 1 
				)
			) 	
	) AS special
	ORDER BY 
		IsDeposit DESC, transid



	--0. For Normal bets
	SELECT * 
	FROM #SpecialDeleteBets WITH (NOLOCK)
	WHERE
		custid not in ( SELECT CustID FROM [f_GetBetDaqCustomer] (1))
		and 
		username <> '12EU'
		AND IsDeposit = 0
		AND mrecommend not in (105181, 118473, 105183)

		
	--1. For Deposit bets
	SELECT *	
	FROM #SpecialDeleteBets WITH (NOLOCK)
	WHERE 
		custid not in ( SELECT CustID FROM  [f_GetBetDaqCustomer] (1))
		AND 
		username <> '12EU'
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


	DROP TABLE #SpecialDeleteBets
END