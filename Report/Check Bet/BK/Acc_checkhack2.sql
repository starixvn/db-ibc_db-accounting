ALTER PROCEDURE [dbo].[Acc_CheckHack2]
	@winlostdate datetime
as 
/*	
	Created by: []
	Date: []
	Task: Check the difference between data backup and current data of ticket 
	DB: DBBET.BK
	Revisions:
		- 20110810@Viet: exclude UUS from ticket's recovery
		- 20120808@Elodie: show the detailed information of ticket's recovery
		- 20130121@Johnson: move sp from DB052.BODB02 to DBBET.BK
	Param's explanation:
		- SQL execution: exec Acc_CheckHack2 @winlostdate='Aug  2 2012 12:00:00:000AM'
	
*/
Begin
	SET NOCOUNT ON 
	/*
	declare @check1 int,@check2 int

	select @check1=count(*)
	from bettrans a with (nolock) 
		inner join bk.dbo.bets b with (nolock) on a.transid=b.transid
	where (a.stake<>b.stake or a.odds<>b.odds or a.betteam <>b.betteam or a.betteam <>b.betteam or a.tpositiontaking<>b.tpositiontaking)
		and a.winlostdate=@winlostdate
		 AND a.bettype NOT IN (31,32,33)  
		 AND b.bettype NOT IN (31,32,33)  
		 AND a.currency <> 20

	select @check2=count(*)
	from bettrans a with (nolock) 
		inner join bk.dbo.betsreject b with (nolock) on a.transid=b.transid
	where (a.status<>b.status) 
		and a.winlostdate=@winlostdate 
		and a.custid<>98632
		and b.currency <> 20

	select @check1 as check1,@check2 as check2 */
	
	--Check ticket of sport book, P2P, numbergame..., but Casino
	select  bt.transid, 
			bt.bettype,
			bt.stake as NewStake, 
			b.stake as OldStake, 
			bt.odds as NewOdds,
			case when bt.bettype IN (31,32,33,41,42,43) then bt.odds else b.odds end as OldOdds, 
			bt.betteam as NewBetteam,
			case when bt.bettype IN (31,32,33,41,42,43) then bt.betteam else b.betteam end as OldBetteam, 
			bt.tpositiontaking as NewPT, 
			b.tpositiontaking as OldPT, 
			bt.status as NewStatus, 
			bt.status as OldStatus
	from bodb02.dbo.bettrans bt with (NOLOCK)
		inner join dbo.bets b WITH (NOLOCK) ON bt.transid = b.transid	
	where bt.winlostdate=@winlostdate
		and bt.currency <> 20
		and (bt.bettype < 50  or bt.bettype between 81 AND 19000)
		and ((bt.stake<>b.stake or bt.tpositiontaking<>b.tpositiontaking)
			or ((bt.odds<>b.odds or bt.betteam<>b.betteam) and bt.bettype NOT IN (31,32,33,41,42,43))
			)										 			
		
	UNION ALL
	
	select  bt.transid, 
			bt.bettype,
			bt.stake as NewStake, b.stake as OldStake, 
			bt.odds as NewOdds, b.odds as OldOdds, 
			bt.betteam as NewBetteam, b.betteam as OldBetteam, 
			bt.tpositiontaking as NewPT, b.tpositiontaking as OldPT, 
			bt.status as NewStatus, b.status as OldStatus
	from bodb02.dbo.bettrans bt with (NOLOCK)
		inner join dbo.betsreject b with (nolock) on bt.transid=b.transid
	where (bt.status<>b.status)
		and bt.winlostdate=@winlostdate
		and bt.custid<>98632
		and bt.currency <> 20	
		
	ORDER BY bt.transid
End

GO
GRANT EXECUTE ON [dbo].[Acc_CheckHack2] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CheckHack2] TO [vnteam]
