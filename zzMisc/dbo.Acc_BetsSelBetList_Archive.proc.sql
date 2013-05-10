USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Acc_BetsSelBetList]    Script Date: 03/03/2008 13:07:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Acc_BetsSelBetList_Archive]
	@FromDate datetime,
	@CustID int
AS

SET NOCOUNT ON

select bettype.typenamee as typename, 
	bettrans.refno, 
	bettrans.bettype, 
	bettrans.transid, 
	match.matchcode, 
	a.teamname home, 
	b.teamname away, 
	bettrans.hdp1, 
	bettrans.hdp2, 
	bettrans.odds,
	bettrans.status, 
	bettrans.stake, 
	bettrans.transdate transdate, 
	case when bettype = 16 then dbo.f_GetHTFTChoice(bettrans.betteam) else bettrans.betteam end betteam,
	bettrans.comstatus, 
	bettrans.spositiontaking, 
	bettrans.mpositiontaking, 
	bettrans.apositiontaking, 
	bettrans.liveindicator, 
	bettrans.modds, 
	bettrans.custid
	,bettrans.livehomescore, bettrans.liveawayscore, match.finalhomescore, match.finalawayscore,
	l.leaguename,
	l.leaguenametc as sportname
from bettype with (nolock), 
	bodb_archive07.dbo.bettrans_bk bettrans with (nolock),
	bodb_archive.dbo.match_bk match with (nolock), 
	team a with (nolock), 
	team b with (nolock),
	league l with (nolock) 
where a.teamid=match.homeid and 
	b.teamid=match.awayid and
	l.leagueid=match.leagueid and
	bettrans.matchid=match.matchid and 
	bettype.typeid=bettrans.bettype and  
	bettrans.transdate>= @FromDate and	
	bettrans.custid = @Custid 	

-------------------------------------------------

UNION ALL

select bettype.typenamee as typename, 
	bettrans.refno, 
	bettrans.bettype, 
	bettrans.transid, 
	match.matchcode, 
	a.teamname home, 
	b.teamname away, 
	bettrans.hdp1, 
	bettrans.hdp2, 
	bettrans.odds,
	bettrans.status, 
	bettrans.stake, 
	bettrans.transdate transdate, 
	case when bettype = 16 then dbo.f_GetHTFTChoice(bettrans.betteam) else bettrans.betteam end betteam,
	bettrans.comstatus, 
	bettrans.spositiontaking, 
	bettrans.mpositiontaking, 
	bettrans.apositiontaking, 
	bettrans.liveindicator, 
	bettrans.modds, 
	bettrans.custid
	,bettrans.livehomescore, bettrans.liveawayscore, match.finalhomescore, match.finalawayscore,
	l.leaguename,
	l.leaguenametc as sportname
from bettype with (nolock), 
	bettrans with (nolock),
	match with (nolock), 
	team a with (nolock), 
	team b with (nolock),
	league l with (nolock) 
where a.teamid=match.homeid and 
	b.teamid=match.awayid and
	l.leagueid=match.leagueid and
	bettrans.matchid=match.matchid and 
	bettype.typeid=bettrans.bettype and  	
	bettrans.custid = @Custid 

order by bettrans.transid



GO
GRANT EXECUTE ON [dbo].[Acc_BetsSelBetList_Archive] TO [bodbAdminNet]