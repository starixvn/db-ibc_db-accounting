ALTER PROCEDURE [dbo].[Acc_Rpt_MatchWinLoss2_Sporttype]
	@winlostdate datetime,
	@Sporttype nvarchar(100),
	@Bettype int = 0,
	@LiveIndicator bit = 0
AS
	/*	Creator: Elodie	
		Date: 20120827
		Task: Report winlost by sport type and bet type
		DB: DB06.BODB02		
	
		History:
			- 20121009@Elodie: Add 34 new bettypes of Tennis (1301 -> 1334)
			
		Explanation's Param:

	*/
BEGIN	
	SET NOCOUNT ON	
	create table #bettrans (matchid int, bettype int, liveindicator bit, winlost money, pos money, comm money, virtualcomm money, linetotal money, virtuallinetotal money)
	create index IX_bettype on #bettrans(bettype, liveindicator)		
	
	insert into #bettrans
	select b.matchid, bettype, liveindicator, 
		   sum((winlost-actual_stake)*actualrate) winlost,
		   sum((awinlost+mwinlost+swinlost)*actualrate) pos,
		   sum((scomm)*actualrate) comm,   
		   sum((scomm)*virtualrate) VirtualComm,
		   sum((winlost-actual_stake + awinlost+mwinlost+swinlost + scomm)*actualrate) as LineTotal,
		   sum((winlost-actual_stake + awinlost+mwinlost+swinlost + scomm)*virtualrate) as VirtualLineTotal
	from bettrans b with(nolock, index=CIX_matchid_bettype)
	where winlostdate = @winlostdate and b.ruben=1 and statusID NOT IN (101,102,103)
	group by b.matchid, bettype,liveindicator
  
	select 
		b.bettype,
		b.liveindicator,		
		m.matchcode,
		m.kickofftime,
		b.matchid,
		m.homeid,
		m.awayid,
		isnull(m.isNeutral, CONVERT(BIT,0)) as IsNeutral,
        b.winlost,
        b.pos,
        b.comm,   
        b.VirtualComm,
        b.LineTotal,
        b.VirtualLineTotal
    from	#bettrans b with (nolock)
			inner join match m with (nolock) on m.matchid=b.matchid
			inner join league l with (nolock) on l.leagueid=m.leagueid
    where               
            ((bettype < 31 AND bettype <> 10) 
            OR bettype between 121 and 999 
            OR bettype BETWEEN 1301 and 1334) and --20120626@Elodie: exclude outright from sportbook					           
			l.leaguenametc = case when (l.leaguenametc = '' or l.leaguenametc is null) and @Sporttype = 'Other Sports' then l.leaguenametc else @Sporttype end and
			b.bettype = case when @Bettype = 0 then b.bettype else @Bettype end and
			b.liveindicator = case when @Bettype = 0 then b.liveindicator else @LiveIndicator end
    order by b.bettype, b.liveindicator desc, m.matchcode       
END

GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_MatchWinLoss2_Sporttype] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_MatchWinLoss2_Sporttype] TO [vnteam] 