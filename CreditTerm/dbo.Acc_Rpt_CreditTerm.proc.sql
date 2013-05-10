ALTER PROCEDURE [dbo].[Acc_Rpt_CreditTerm]
	--@groupID smallint = 0,
	@checkername nvarchar(50) =null,
	@pre1 money =null,
	@pre2 money = null
AS

/*	Created by: [Khoa]
	Date: 20100105
	Task: CreditTerm report
	DB: DB06.bodb02

	Revisions:		
		- 20100105@Khoa: get currency name from cache
	Param's Explanation:

*/

SET NOCOUNT ON

create table #groupHeadLine
(
	groupID smallint PRIMARY KEY, 
	custid int, 
	PreAgreeAmount money, 
	AccountRemark nvarchar(200) COLLATE SQL_Latin1_General_CP1_CI_AS, 
	AccountRemarkDate smalldatetime, 
	username nvarchar(50),
	phone nvarchar(50), 
	Role nvarchar(10),
	currency tinyint, 
	actualrate float,
	checkerid int,
	checkername nvarchar(50)
)

create table #Balance 
(
	custid int PRIMARY KEY,
	groupID smallint, 
	Balance money, 
	username nvarchar(50), 
	Role nvarchar(10), 
	currency tinyint, 
	actualrate float
)

DECLARE @Account as table (custid int primary key, UplineID int, groupid smallint)
--Get Lists of GroupHeadLine account
INSERT INTO #groupHeadLine
SELECT
	groupID, a.custid, PreAgreeAmount, AccountRemark, AccountRemarkDate, 
	c.username,c.phone, CASE c.roleid WHEN 1 THEN 'Member' WHEN 2 THEN 'Agent' WHEN 3 THEN 'Master' WHEN 4 THEN 'Super' END Role,
	c.Currency, e.actualrate, a.checker, cr.username 
FROM custAccount a with (nolock)
	INNER JOIN customer c with (nolock) ON a.custid = c.custid
	INNER JOIN exchange e with (nolock) ON c.currency = e.exchangeid
	LEFT JOIN Customer cr with (nolock) ON a.checker = cr.custid 
WHERE IsGroupHeadline = 1

-- Get Balance of each member / agent / master / super which have info in DB06.bodb02.dbo.custAccount table
-- member
INSERT @Account(custid, uplineid, groupid)
SELECT c.custid, c.recommend, a.groupid
FROM CustInfo c with(nolock)
	inner join custAccount a with(nolock) on c.custid = a.custid
WHERE roleid = 1 and (PreAgreeAmount > 0 OR groupID > 0)

INSERT INTO #Balance (custid, groupID, Balance)
SELECT a.custid, a.groupid, IsNull(SUM(winlost-actual_stake+playercomm) ,0) balance
FROM @Account a
	INNER JOIN bettrans b with(nolock) on b.recommend = a.uplineid
WHERE b.custid = a.custid and ruben = 1 and winlostdate = winlostdate and bettype > 0 and matchid >=0
GROUP BY a.custid, a.groupid

-- agent
delete from @Account
INSERT @Account(custid, uplineid, groupid)
SELECT c.custid, 0, a.groupid
FROM CustInfo c with(nolock)
	inner join custAccount a with(nolock) on c.custid = a.custid
WHERE roleid = 2 and (PreAgreeAmount > 0 OR groupID > 0)

INSERT INTO #Balance (custid, groupID, Balance)
SELECT a.custid, a.groupid, balance	
FROM @Account a
	RIGHT JOIN (
		select recommend,
			IsNull(SUM(case when b.custid=b.recommend then winlost-actual_stake else awinlost+comm-playercomm end) ,0) +
			IsNull(SUM(case when b.custid<>b.recommend AND b.ruben=1 then winlost-actual_stake+playercomm else 0 end) ,0) Balance
		from bettrans b with(nolock)
		where recommend in (select custid from @Account)			
			and winlostdate = winlostdate and bettype>0 and matchid >=0
		group by recommend
	) b on b.recommend = a.custid

-- master
delete from @Account
INSERT @Account(custid, uplineid, groupid)
SELECT c.custid, srecommend, a.groupid
FROM CustInfo c with(nolock)
	inner join custAccount a with(nolock) on c.custid = a.custid
WHERE roleid = 3 and (PreAgreeAmount > 0 OR groupID > 0)

INSERT INTO #Balance (custid, groupID, Balance)
SELECT a.custid, a.groupid, balance	
FROM @Account a
	RIGHT JOIN (
		select mrecommend,
			IsNull(SUM(case when b.custid=b.mrecommend then winlost-actual_stake else mwinlost+acomm-comm end) ,0) + 
			IsNull(SUM(case when b.custid=b.recommend then winlost-actual_stake else awinlost+comm-playercomm end) ,0) +  
			IsNull(SUM(case when b.custid<>b.recommend AND b.custid <> b.mrecommend AND b.ruben=1 then winlost-actual_stake+playercomm else 0 end) ,0) Balance
		from bettrans b with(nolock)
		where srecommend in (select uplineid from @Account)
			and mrecommend in (select custid from @Account)
			and winlostdate = winlostdate and bettype>0 and matchid >=0
		group by mrecommend
	) b on b.mrecommend = a.custid


-- super
delete from @Account
INSERT @Account(custid, uplineid, groupid)
SELECT c.custid, 0, a.groupid
FROM CustInfo c with(nolock)
	inner join custAccount a with(nolock) on c.custid = a.custid
WHERE roleid = 4 and (PreAgreeAmount > 0 OR groupID > 0)

INSERT INTO #Balance (custid, groupID, Balance)
SELECT a.custid, a.groupid, balance	
FROM @Account a
	RIGHT JOIN (
		select srecommend,
			IsNull(SUM(case when b.custid=b.srecommend then winlost-actual_stake else swinlost+scomm-acomm end) ,0) +
			IsNull(SUM(case when b.custid=b.mrecommend then winlost-actual_stake else mwinlost+acomm- comm end) ,0) + 
			IsNull(SUM(case when b.custid=b.recommend  then winlost-actual_stake else awinlost+comm-playercomm end) ,0)  +
			IsNull(SUM(case when b.custid<>b.recommend AND b.custid <> b.mrecommend AND b.custid <> b.srecommend AND b.ruben=1 then winlost-actual_stake+playercomm else 0 end) ,0) Balance
		from bettrans b with(nolock)
		where srecommend in (select custid from @Account)			
			and winlostdate = winlostdate and bettype>0 and matchid >=0
		group by srecommend
	) b on b.srecommend = a.custid

UPDATE #Balance
SET
	username = c.Username,
	Role = CASE c.roleid WHEN 1 THEN 'Member' WHEN 2 THEN 'Agent' WHEN 3 THEN 'Master' WHEN 4 THEN 'Super' END,
	currency = c.Currency, actualrate = e.actualrate
FROM
	custInfo c with (nolock)
	INNER JOIN exchange e with (nolock) ON c.currency = e.exchangeid
	INNER JOIN #Balance b ON c.custid = b.custid

--Groups:
SELECT
	a.groupID,
	b.Username, b.currency, b.Role,
	b.Balance, b.Balance * b.actualrate Balance_Base,
	a.PreAgreeAmount, a.AccountRemark, 
	g.phone, g.checkerid, g.checkername,
	a.AccountRemarkDate,
	CASE
	WHEN ABS(b.Balance) > a.PreAgreeAmount THEN 1
	ELSE 0 END OverLimit
FROM
	custAccount a with (nolock)
	INNER JOIN #Balance b ON a.custid = b.custid
	INNER JOIN #groupHeadLine g ON a.groupID = g.groupID 
WHERE
	a.groupID = 0 
	and isnull(g.checkername, '') = coalesce(@checkername, isnull(g.checkername, ''))
	and isnull(a.preAgreeAmount, 0) >= coalesce(@pre1, isnull(a.preAgreeAmount, 0))
	and isnull(a.preAgreeAmount, 0) <= coalesce(@pre2, isnull(a.preAgreeAmount, 0))
				   
UNION ALL
SELECT
	g.groupID,
	g.Username, g.currency, g.Role,
	b.TotalBalance Balance, b.TotalBalance_Base Balance_Base,
	g.PreAgreeAmount, g.AccountRemark, 
	g.phone, g.checkerid,g.checkername,
	g.AccountRemarkDate,
	b.OverLimit
FROM
	(SELECT
		b.groupID,
		SUM(b.Balance * b.actualrate)/h.actualrate TotalBalance,
		SUM(b.Balance * b.actualrate) TotalBalance_Base,
		CASE
		WHEN ABS(SUM(b.Balance * b.actualrate)/h.actualrate) > h.preAgreeAmount THEN 1
		ELSE 0 END OverLimit
	FROM
		#Balance b
		INNER JOIN #groupHeadLine h ON b.groupID = h.groupID
	WHERE
		b.groupID > 0 AND h.preAgreeAmount > 0
	GROUP BY
		b.groupID, h.actualrate, h.preAgreeAmount
	) b
	INNER JOIN #groupHeadLine g ON b.groupID = g.groupID
WHERE 
	isnull(g.checkername, '') = coalesce(@checkername, isnull(g.checkername, ''))
	and isnull(g.preAgreeAmount, 0) >= coalesce(@pre1, isnull(g.preAgreeAmount, 0))
	and isnull(g.preAgreeAmount, 0) <= coalesce(@pre2, isnull(g.preAgreeAmount, 0))

ORDER BY 
	b.currency, 
	groupID,
	OverLimit desc, 	
	AccountRemarkDate DESC
-------------------------------------------------------------

--Groups'detail:
SELECT
	a.groupID,b.custid,
	b.Username, b.currency, b.Role,
	b.Balance, b.Balance* b.actualrate Balance_Base,
	(b.Balance*b.actualrate) / g.actualrate Balance_Group,
	a.AccountRemark, a.AccountRemarkDate,
	a.IsGroupHeadLine,
	g.phone, g.checkerid
FROM
	custAccount a with (nolock)
	INNER JOIN #Balance b ON a.custid = b.custid
	INNER JOIN #groupHeadLine g ON a.groupID = g.groupID
ORDER BY
	a.groupID,
	a.IsGroupHeadLine DESC, 
	a.AccountRemarkDate DESC
---------------------------------------------------------------\

--END 


drop table #groupHeadLine
drop table #Balance
GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_CreditTerm] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_CreditTerm] TO [vnteam]