ALTER PROCEDURE Acc_BettransSelDelSpecial_Outright
	@OutrightID int = 0,
	@FromRefNo bigint,
	@ToRefNo bigint,
	@UserName varchar(50) = ''
AS
SET NOCOUNT ON

/*
    Created by: Daniel
	Date: 
	Original: account\dele\teamlisting.asp
	Task: Select bets transaction need to delete
	DB: DB053.BODB02

	History:
		- ADMIN SITE
		--UPDATED Dec/06/2008: divide to 5 datasets (1 normal and 4 special bets for optional delete)
		- 20090925@khoa: Deleted option for member belong to master  MHCRM, MHCEU, MHCUS
		- 20091019@Daniel: Revert changed made by 20091006@Simon
		- 20091127@Khoa: remove table exchange
		- 20100526@Henry: Change to use StatusID instead of Status in WHERE statement
		- 20100917@Robert: include betfrom='e' into deposit group
		- 20101001@Henry: Using f_GetBetDaqCustomer to query betdaq customer
		- 20120717@Sophia: Add condition 'L' in betfrom to check Deposit
	
	Explanation's Param:

*/

CREATE TABLE #OutrightDeleteBets (transid bigint,custid int,username varchar(30),odds smallmoney,transdate datetime, creator varchar(30),Stake money,currency nvarchar(50),IsDeposit tinyint,site varchar(10),status nvarchar(10), mrecommend int)

INSERT INTO #OutrightDeleteBets
select
	b.transid,
	b.custid, 
	b.username,
	b.odds,
	b.transdate,	
	cr.username as creator,
	stake,
	b.currency, 
	case when betfrom IN ('D', 'M', 'E', 'L') then 1 else 0 end as IsDeposit,
	ag.site,
	b.status,
	b.mrecommend
from 
	bettrans b with (NOLOCK)
	--INNER JOIN customer c with (NOLOCK) ON c.custid = b.custid
	INNER JOIN customer ag with (NOLOCK) ON b.recommend = ag.custid
	INNER JOIN customer cr with (NOLOCK) ON cr.custid = b.creator	
	INNER JOIN outright o with(NOLOCK) ON b.matchid = o.orid
where
	b.bettype = 10
	--and b.status NOT IN('Void', 'Reject')
	and b.statusID NOT IN (101,102)
	and b.transid between @FromRefNo and @ToRefNo 
	and o.orid = case when @OutrightID = 0 then o.orid else @OutrightID end 
order by transid



--0.For Normal bets
SELECT * FROM #OutrightDeleteBets with (NOLOCK)
WHERE 
	custid not in ( Select CustID from  [f_GetBetDaqCustomer] (1))
	and
	username <> '12EU'
AND IsDeposit = 0
AND mrecommend not in (105181, 118473, 105183)
	
--1.For Deposit bets
SELECT * FROM #OutrightDeleteBets with (NOLOCK)
WHERE 
	custid not in ( Select CustID from  [f_GetBetDaqCustomer] (1))
	and
	username <> '12EU'
AND IsDeposit = 1	
AND mrecommend not in (105181, 118473, 105183)
	
	
--2.For Special bets
SELECT * FROM #OutrightDeleteBets with (NOLOCK)
WHERE 
custid in (Select CustID from  [f_GetBetDaqCustomer] (1))

--3.For 12EU
SELECT * FROM #OutrightDeleteBets with (NOLOCK)
WHERE 
username = '12EU'

--4.For member of master: MHCEU (105181), MHCRM (118473), MHCUS(105183)
SELECT * FROM #OutrightDeleteBets with (NOLOCK)
WHERE 
mrecommend  in (105181, 118473, 105183)


DROP TABLE #OutrightDeleteBets




GO
GRANT EXECUTE ON [dbo].Acc_BettransSelDelSpecial_Outright TO [bodbAdminNet]

GO
GRANT VIEW DEFINITION ON [dbo].[Acc_BettransSelDelSpecial_Outright] TO [VNTeam]