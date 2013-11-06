 ALTER PROCEDURE [dbo].[Acc_DailyCreatedCustomer]
	@fromdate DATETIME,
	@todate DATETIME
AS

/*	Creator: Simon
		Date: 2009-12-08
		Task: Daily Created Customers Report
		DB: DBACC/bodb02		
		
		Revisions:
			- 20130224@Lukas: move table Acc_CustDirect to new database bodb_ACC
			- 20131106@Kathy: Calculator amount of Master, Agent, Member [Redmine:#6837]
*/	

SET NOCOUNT ON

DECLARE	@tmpSAg TABLE( -- super
		CreateDate	SMALLDATETIME PRIMARY KEY,
		Amount		INT
	)
DECLARE	@tmpMAg TABLE(  -- direct master
		CreateDate	SMALLDATETIME PRIMARY KEY,
		Amount		INT
	)
DECLARE	@tmpAg TABLE(  -- direct agent
		CreateDate	SMALLDATETIME PRIMARY KEY,
		Amount		INT
	)
DECLARE @tmpMaster TABLE( -- master
		CreateDate SMALLDATETIME PRIMARY KEY,
		Amount		INT
	)

DECLARE @tmpAgent TABLE( -- agent
		CreateDate SMALLDATETIME PRIMARY KEY,
		Amount		INT
	)
DECLARE @tmpMember TABLE( -- member 
		CreateDate SMALLDATETIME PRIMARY KEY,
		Amount		INT
	)

-- Super
INSERT INTO @tmpSAg
SELECT CONVERT(CHAR(10),creatdate,120), COUNT(custid)
FROM customer WITH (NOLOCK)
WHERE roleid = 4
	AND creatdate BETWEEN @fromdate AND @todate
GROUP BY CONVERT(CHAR(10),creatdate,120)

-- Direct Master
INSERT INTO @tmpMAg
SELECT CONVERT(CHAR(10),creatdate,120), COUNT(r.custid)
FROM bodb_acc.dbo.Acc_CustDirect r  WITH (NOLOCK)
	LEFT JOIN customer c WITH (NOLOCK) ON c.srecommend = r.custid 
WHERE c.roleid = 3
	AND r.roleid = 4
	AND creatdate BETWEEN @fromdate AND @todate
GROUP BY CONVERT(CHAR(10),creatdate,120)

-- Direct Agent
INSERT INTO @tmpAg
SELECT CONVERT(CHAR(10),creatdate,120), COUNT(r.custid)
FROM bodb_acc.dbo.Acc_CustDirect r  WITH (NOLOCK)
	LEFT JOIN customer c WITH (NOLOCK) ON c.mrecommend = r.custid 
WHERE c.roleid = 2
	AND r.roleid = 3
	AND creatdate BETWEEN @fromdate AND @todate
GROUP BY CONVERT(CHAR(10),creatdate,120)

-- Master
INSERT INTO @tmpMaster
SELECT CONVERT(char(10), creatdate, 120), COUNT(c.custid)
FROM Customer c with(NOLOCK) 
where c.roleid = 3
and c.creatdate BETWEEN @fromdate AND @todate
and c.srecommend not in (SELECT r.custid FROM bodb_acc.dbo.Acc_CustDirect r  WITH (NOLOCK) WHERE r.roleid = 4)
GROUP BY CONVERT(char(10), c.creatdate, 120)

-- Agent
INSERT INTO @tmpAgent
SELECT CONVERT(char(10), creatdate, 120), COUNT(c.custid)
FROM Customer c with(NOLOCK) 
where c.roleid = 2
and c.creatdate BETWEEN @fromdate AND @todate
and c.mrecommend not in  (SELECT r.custid FROM bodb_acc.dbo.Acc_CustDirect r  WITH (NOLOCK) WHERE r.roleid = 3)
GROUP BY CONVERT(char(10), c.creatdate, 120)

-- Member
INSERT INTO @tmpMember
SELECT CONVERT(char(10), creatdate, 120), COUNT(c.custid)
FROM Customer c with(NOLOCK) 
where c.roleid = 1
and c.creatdate BETWEEN @fromdate AND @todate
GROUP BY CONVERT(char(10), c.creatdate, 120)


-- Main Process
SELECT main.CreateDate, 
	ISNULL(S.Amount,0) AmountSAg, 
	ISNULL(M.Amount,0) AmountMAg, 
	ISNULL(A.Amount,0) AmountAg,
	ISNULL(mas.Amount, 0) AmountMaster,
	ISNULL(age.Amount, 0) AmountAgent,
	ISNULL(mem.Amount, 0) AmountMember
FROM 
	(SELECT CreateDate FROM @tmpSAg UNION SELECT CreateDate FROM @tmpMAg UNION SELECT CreateDate FROM @tmpAg) main
	LEFT JOIN @tmpSAg S ON main.CreateDate=S.CreateDate
	LEFT JOIN @tmpMAg M ON main.CreateDate=M.CreateDate
	LEFT JOIN @tmpAg A ON main.CreateDate=A.CreateDate
	Left JOIN @tmpMaster mas on main.CreateDate = mas.CreateDate
	Left JOIN @tmpAgent age ON main.CreateDate = age.CreateDate
	left JOIN @tmpMember mem on main.CreateDate = mem.CreateDate
ORDER BY main.CreateDate DESC


GO
GRANT EXECUTE ON dbo.[Acc_DailyCreatedCustomer] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_DailyCreatedCustomer] TO [vnteam]