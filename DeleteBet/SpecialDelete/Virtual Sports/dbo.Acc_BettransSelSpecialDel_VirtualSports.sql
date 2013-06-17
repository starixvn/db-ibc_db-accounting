ALTER PROCEDURE [dbo].[Acc_BettransSelSpecialDel_VirtualSports]
	@MatchID int,
	@FromRefNo bigint,
	@ToRefNo bigint,	
	@hdp smallmoney = 9999,
	@bettypes varchar(128) = '',	
	@betteam1201 varchar(10) = 'ALL',
	@betteam1205 varchar(10) = 'ALL',
	@betteam1204 varchar(120) = '',
	@betteam1206 varchar(120) = '',	
	@UserName varchar(50) = ''
AS
/*
    Created by: Elodie	
	Date: 20120815
	Original: Acc_BettransSelSpecialDel
	Task: Select tickets of Virtual Sports to delete
	DB: DB053.BODB02

	History:		
		- 20130617@Johnson: change alias StakePositiontaking to stake
	Explanation's Param:	
		- @betteam1201: include Handicap(1201), Over/Under(1203), Double chance(1224) of Virtual sports
		- @betteam1205: include FT1x2(1205) of Virtual sports
		- @betteam1204: include Correct score(1204) of Virtual sports
		- @betteam1206: include Total goal(1206) of Virtual sports

*/
BEGIN
	SET NOCOUNT ON
	CREATE TABLE #SpecialDeleteBets (transid bigint,custid int,username varchar(30),odds smallmoney, transdate datetime,bettype smallint, betteam nvarchar(10),hdp1 smallmoney, hdp2 smallmoney, livehomescore smallint, liveawayscore smallint, creator varchar(30), Stake money,currency tinyint,IsDeposit tinyint,site varchar(10),status nvarchar(10), mrecommend int, recommend int)
	
	--Correct Score
	IF exists( SELECT convert(int,val) FROM dbo.strSplit(@bettypes,'^') Where convert(int,val) = 1204)
		insert into #SpecialDeleteBets
		select
			b.transid,
			b.custid,
			b.username,
			b.odds,   			
			b.transdate,
			b.bettype,
			betteam,
			hdp1,
			hdp2,
			livehomescore,
			liveawayscore,
			cr.username as creator,	
			stake,
			b.currency, 
			case when betfrom IN ('D', 'M', 'E', 'L') then 1 else 0 end as IsDeposit,
			ag.site,
			b.status,
			b.mrecommend,
			b.recommend		
		from 
			bettrans b with (NOLOCK)
			INNER JOIN customer ag with (NOLOCK) ON b.recommend = ag.custid
			INNER JOIN customer cr with (NOLOCK) ON cr.custid = b.creator
		where
			matchid=@matchid 
			and b.transid between @FromRefNo and @ToRefNo 	
			and statusID NOT IN (101,102 )
			and b.bettype = 1204
			and b.betteam in (SELECT convert(varchar,val) FROM dbo.strSplit(case when @betteam1204 = 'All' then betteam else @betteam1204 end,'^'))
	
	--Handicap, Over/Under, FT1x2, Double Chance
	insert into #SpecialDeleteBets
	select
		b.transid,
		b.custid,
		b.username,
		b.odds,   
		b.transdate,
		b.bettype,
		betteam,
		hdp1,
		hdp2,
		livehomescore,
		liveawayscore,
		cr.username as creator,	
		stake,
		b.currency, 
		case when betfrom IN ('D', 'M', 'E' ,'L') then 1 else 0 end as IsDeposit,
		ag.site,
		b.status,
		b.mrecommend,
		b.recommend
	from 
		bettrans b with (NOLOCK)
		INNER JOIN customer ag with (NOLOCK) ON b.recommend = ag.custid
		INNER JOIN customer cr with (NOLOCK) ON cr.custid = b.creator
	where
		matchid=@matchid 
		and b.transid between @FromRefNo and @ToRefNo 	
		and b.bettype in ( SELECT convert(int,val) FROM dbo.strSplit(@bettypes,'^') )
		and statusID NOT IN (101,102) --void, reject

		AND CASE
			WHEN b.bettype in (1201,1203) THEN CASE WHEN @betteam1201 = 'ALL' THEN betteam ELSE @betteam1201 END
			WHEN b.bettype in (1205) THEN CASE WHEN @betteam1205 = 'ALL' THEN betteam ELSE @betteam1205 END		
			ELSE betteam 
			END = betteam		
		AND CASE WHEN b.bettype in (1201,1203) THEN CASE 
													WHEN @hdp = 9999 THEN 1
													WHEN @hdp = (hdp1 + hdp2) THEN 1
													ELSE 0 
											 END
			ELSE 1 END = 1
		AND b.bettype NOT IN(1204,1206)

	UNION ALL

	--Total Goals
	select
		b.transid,
		b.custid,
		b.username,
		b.odds,   
		b.transdate,
		b.bettype,
		betteam,
		hdp1,
		hdp2,
		livehomescore,
		liveawayscore,
		cr.username as creator,	
		stake ,
		b.currency, 
		case when betfrom IN ('D', 'M', 'E', 'L') then 1 else 0 end as IsDeposit,
		ag.site,
		b.status,
		b.mrecommend,
		b.recommend
	from 
		dbo.bettrans b with (NOLOCK)
		INNER JOIN dbo.customer ag with (NOLOCK) ON b.recommend = ag.custid
		INNER JOIN dbo.customer cr with (NOLOCK) ON cr.custid = b.creator
	where
		matchid=@matchid 
		and b.transid between @FromRefNo and @ToRefNo 			 
		and statusID NOT IN (101,102) --void, reject		
		AND b.bettype = 1206 
		AND b.betteam  in (SELECT convert(varchar,val) FROM dbo.strSplit(case when @betteam1206 = 'All' then betteam else @betteam1206 end,'^'))
	
	--0. For Normal bets
	SELECT * FROM #SpecialDeleteBets with (NOLOCK)
	WHERE
		custid not in ( Select CustID from  [f_GetBetDaqCustomer] (1))
		and 
		username <> '12EU'
	AND IsDeposit = 0
	AND mrecommend not in (105181, 118473, 105183)
	ORDER BY transid
		
	--1. For Deposit bets
	SELECT * FROM #SpecialDeleteBets with (NOLOCK)
	WHERE 
		custid not in ( Select CustID from  [f_GetBetDaqCustomer] (1))
		and 
		username <> '12EU'
	AND IsDeposit = 1	
	AND mrecommend not in (105181, 118473, 105183)
	ORDER BY transid
		
	--2. For Special bets
	SELECT * FROM #SpecialDeleteBets with (NOLOCK)
	WHERE custid in (Select CustID from  [f_GetBetDaqCustomer] (1))
	ORDER BY IsDeposit desc, transid

	--3. For 12EU
	SELECT * FROM #SpecialDeleteBets with (NOLOCK)
	WHERE username = '12EU'
	ORDER BY IsDeposit desc, transid

	--4. For member of master: MHCEU (105181), MHCRM (118473), MHCUS(105183)
	SELECT * FROM #SpecialDeleteBets with (NOLOCK)
	WHERE mrecommend in (105181, 118473, 105183)
	ORDER BY IsDeposit desc, transid

	DROP TABLE #SpecialDeleteBets
	
	SET NOCOUNT OFF
END

GO
GRANT EXECUTE ON [dbo].[Acc_BettransSelSpecialDel_VirtualSports] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_BettransSelSpecialDel_VirtualSports] TO [vnteam] 