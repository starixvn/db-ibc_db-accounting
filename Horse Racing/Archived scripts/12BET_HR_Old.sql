DECLARE
 @FromDate		SMALLDATETIME,  
 @ToDate		SMALLDATETIME

  
 CREATE TABLE #SAgWinLoss (  
	winlostdate		DATETIME,  
	CustID			INT, 
	sporttype		INT,  
	TurnOver		MONEY,   
	GrossComm		MONEY,   
	Winlost			MONEY,  
	Comm			MONEY,   
	AWinlost		MONEY,   
	AComm			MONEY,   
	Company			MONEY
)  

 
SELECT @FromDate = '2009-5-1'
SELECT @ToDate = '2009-5-31'

DECLARE @tmp12BETSAg	TABLE( custID INT PRIMARY KEY)  
INSERT INTO @tmp12BETSAg(custID) SELECT custID FROM dbo.f_DepSuperByCurrency('12bet')

CREATE TABLE #sum_winloss_bk(
	[winlostdate] [datetime] NULL,
	[username] [nvarchar](50) NULL,
	[custid] [int] NULL,
	[roleid] [int] NULL,
	[recommend] [int] NULL,
	[mrecommend] [int] NULL,
	[srecommend] [int] NULL,
	[turnover] [money] NULL,
	[winlost] [money] NULL,
	[awinlost] [money] NULL,
	[mwinlost] [money] NULL,
	[swinlost] [money] NULL,
	[playercomm] [money] NULL,
	[comm] [money] NULL,
	[acomm] [money] NULL,
	[scomm] [money] NULL,
	[BetCount] [int] NULL,
	[grosscomm] [money] NULL,
	[sporttype] [tinyint] NOT NULL,
	[bettype] [tinyint] NOT NULL
)

INSERT INTO #sum_winloss_bk
	(winlostdate, roleid, custid, recommend, mrecommend, srecommend, username,
	turnover, winlost, awinlost, mwinlost, swinlost,
	playercomm, comm, acomm, scomm, betcount, grosscomm,
	sporttype, bettype)
SELECT winlostdate, 3,
	ma.custid, 0 recommend, customer.mrecommend, customer.srecommend, ma.username,
	sum(CASE WHEN bettype in (33, 43) AND liveawayscore = 0 THEN stake/2 ELSE stake END) turnover,
	sum(winlost-actual_stake)  winlost,
	sum(awinlost) awinlost,
	sum(mwinlost) mwinlost,
	sum(IsNull(swinlost,0)) swinlost,
	sum(playercomm) playercomm,
	sum(comm) comm,
	sum(acomm) acomm,
	sum(IsNull(scomm,0)) scomm,
	COUNT(transid) BetCount,
	sum(scomm / (1-tpositiontaking)) grosscomm, 151, bettype
FROM
	dbo.customer with (nolock),
	dbo.customer ma with (nolock),
	DB06.bodb_archive.dbo.bettrans_bk bettrans with (nolock)
WHERE
	bettrans.custid=customer.custid 
	and bettrans.winlostdate between @FromDate AND @ToDate
	AND bettrans.status not in ('running','waiting','VOID','REJECT','REFUND')
	AND ma.custid=customer.mrecommend and customer.roleid=1 and ma.roleid=3 
	anD bettrans.srecommend IN (SELECT custid FROM @tmp12BETSAg)
	AND bettrans.bettype IN(31,32,33,41,42,43)
GROUP BY
	winlostdate, ma.custid, customer.mrecommend, customer.srecommend, 
	ma.username, bettype


INSERT INTO #SAgWinLoss  
SELECT b.winlostdate,  
	b.srecommend,   
	b.sporttype,    
	b.turnover,     
	b.grosscomm AS GrossComm,  
	b.winlost,  
	b.playercomm,  
	b.swinlost + b.mwinlost + b.awinlost,  
	b.scomm - b.playercomm,  
	- (b.swinlost + b.mwinlost + b.awinlost + b.winlost + b.scomm)     
FROM  #sum_winloss_bk b WITH(NOLOCK)

SELECT   
   CONVERT(VARCHAR(6),w.winlostdate,112) ReportType,  
   e.currency, 
   SUM(TurnOver)	AS Turnover,   
   sum(GrossComm)   AS GrossComm,  
   SUM(Winlost)		AS Winlost,  
   SUM(Comm)		AS Comm,  
   SUM(AWinlost)    AS AWinlost,  
   SUM(AComm)		AS AComm,  
   SUM(Company)		AS Company
FROM	#SAgWinLoss w   
	INNER JOIN dbo.Exchange_History h WITH (NOLOCK) ON w.winlostdate = h.winlostdate AND w.custid = h.srecommend12BET  
	INNER JOIN dbo.exchange e WITH (NOLOCK) ON h.currency = e.exchangeID
GROUP BY   
	e.currency,
    CONVERT(VARCHAR(6),w.winlostdate,112)  
ORDER BY ReportType, e.currency   

DROP TABLE #sum_winloss_bk
DROP TABLE #SAgWinLoss

