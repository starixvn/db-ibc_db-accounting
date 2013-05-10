ALTER PROCEDURE Acc_IOM_BettransSelDelSpecial_Outright
	@OutrightID int = 0,
	@FromRefNo bigint,
	@ToRefNo bigint,
	@UserName varchar(50) = ''
AS
SET NOCOUNT ON
/*
    Created by: Elodie
	Date: 20120704
	Original: Acc_BettransSelDelSpecial_Outright
	Task: Select bets transaction need to delete for Outright
	DB: DB053.BODB02

	Revisions:
	
	Explanation's Param:

*/
select
	b.transid,
	b.custid, 
	b.username,
	b.odds,
	b.transdate,	
	cr.username as creator,
	stake,
	b.currency, 
	1 as IsDeposit,
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
	and b.statusID NOT IN (101,102)
	and b.transid between @FromRefNo and @ToRefNo 
	and o.orid = case when @OutrightID = 0 then o.orid else @OutrightID end 
order by transid

GO
GRANT EXECUTE ON [dbo].Acc_IOM_BettransSelDelSpecial_Outright TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_IOM_BettransSelDelSpecial_Outright] TO [VNTeam]