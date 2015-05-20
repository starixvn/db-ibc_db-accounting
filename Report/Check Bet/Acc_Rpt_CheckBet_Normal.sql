ALTER PROCEDURE [dbo].[Acc_Rpt_CheckBet_Normal]
	@winlostdate datetime
as 
/*	
	Created by: Elodie
	Date: 20120816
	Task: Show the difference between data backup and current data of normal ticket in detail
	DB: DBBET/BK
	Revisions:
		- 20120917@Elodie: enhance performance
		- 20121009@Elodie: Add 34 new bettypes of Tennis (1301 -> 1334)
		- 20130121@Johnson: move sp from DB052.BODB02 to DBBET.BK
		- 20130225@Elodie: Add Virtual Horse Racing report
	Param's explanation:		
	
*/
Begin
	SET NOCOUNT ON 	
	CREATE TABLE #tmp(transid BIGINT)
    --insert into #tmp
    INSERT INTO #tmp
    SELECT bt.transid
    FROM bodb02.dbo.bettrans bt WITH (nolock) 
        INNER join dbo.bets b WITH (nolock) ON bt.transid=b.transid        
    WHERE bt.winlostdate=@winlostdate
            AND bt.currency <> 20
            and (
                    bt.bettype < 31  or bt.bettype between 121 AND 999 or bt.bettype between 1301 AND 1334 --sportbook
                    OR bt.bettype BETWEEN 81 AND 120 --number game                    
                    OR bt.bettype IN (31,32,33,41,42,43) --racing
                    OR bt.bettype BETWEEN 1201 AND 1299 --virtual sports
                )
            and ((bt.stake<>b.stake or bt.tpositiontaking<>b.tpositiontaking)
                or (bt.odds<>b.odds and bt.bettype NOT IN (31,32,33,41,42,43))
				or (bt.betteam<>b.betteam and bt.bettype NOT IN (31,32,33,41,42,43, 1231,1232,1233,1237,1238))
				or ((bt.matchid<>b.matchid) and bt.bettype IN (31,32,33,41,42,43,10))
				or ((bt.oddsid<>b.oddsid) and bt.bettype IN (1231,1232,1233,1237,1238))
                )    
                
	DECLARE @Match TABLE (matchid int, homeid int, awayid int, matchcode nvarchar(50), type varchar(10))
	
	INSERT INTO @Match
	SELECT	matchid,
			homeid,
			awayid,
			matchcode,
			'match' as type
	FROM bodb02.dbo.match with (NOLOCK) where eventdate = @winlostdate
		
	UNION ALL	
	SELECT	orid as matchid,
			0 as homeid,
			teamid as awayid,
			matchcode,
			'outright' as type
	FROM bodb02.dbo.outright with (NOLOCK) where eventdate = @winlostdate
	
	UNION ALL	
	SELECT	orid as matchid,
			0 as homeid,
			RacerID as awayid,
			convert(NVARCHAR(50), RacerNum) matchcode,
			'VSOutright' as type
	FROM bodb02.dbo.VSOutright with (NOLOCK) where eventdate = @winlostdate
		
	--Check ticket of sport book, racing, numbergame, virtual sports but Casino, P2P, Live CS, Bingo	
	select  bt.transid, 
			bt.transdate,
			bt.CurrencyName,
			bt.bettype,
			bt.Username,
			bt.stake as NewStake, 
			b.stake as OldStake, 
			bt.odds as NewOdds,
			case when bt.bettype IN (31,32,33,41,42,43) then bt.odds else b.odds end as OldOdds, 			
			bt.betteam as NewBetteam,
			case when bt.bettype IN (31,32,33,41,42,43) then bt.betteam else b.betteam end as OldBetteam, 
			m1.homeid,
			m1.awayid as NewAwayID,			
			case when bt.bettype IN (31,32,33,41,42,43,10) then m2.awayid else m1.awayid end as OldAwayID,			
			m1.matchcode as NewMatchCode,		
			case when bt.bettype IN (31,32,33,41,42,43,10) then m2.matchcode else m1.matchcode end as OldMatchCode,		
			bt.liveindicator,
			bt.hdp1,
			bt.oddstype,
			bt.tpositiontaking as NewPT, 
			b.tpositiontaking as OldPT, 
			bt.status, 		
			c.username as Creator
	from bodb02.dbo.bettrans bt with (NOLOCK)
		inner join dbo.bets b WITH (NOLOCK) ON bt.transid = b.transid	
		inner join bodb02.dbo.custinfo c with (nolock) on bt.creator = c.custid		
		inner JOIN @Match m1 on bt.matchid = m1.matchid
		inner JOIN @Match m2 on b.matchid = m2.matchid
	where bt.transid in (SELECT transid from #tmp)		
		AND m1.type = CASE  WHEN b.bettype IN (31,32,33,41,42,43,10) THEN 'outright'
							ELSE 'match' END
		AND bt.bettype NOT IN (1231,1232,1233,1237,1238)
		
	-- Virtual HR		
	UNION ALL
	select  bt.transid, 
			bt.transdate,
			bt.CurrencyName,
			bt.bettype,
			bt.Username,
			bt.stake as NewStake, 
			b.stake as OldStake, 
			bt.odds as NewOdds,
			b.odds as OldOdds, 			
			bt.betteam as NewBetteam,
			bt.betteam as OldBetteam, 
			m1.homeid,
			m1.awayid as NewAwayID,			
			m2.awayid as OldAwayID,			
			m1.matchcode as NewMatchCode,		
			m2.matchcode as OldMatchCode,
			bt.liveindicator,
			bt.hdp1,
			bt.oddstype,
			bt.tpositiontaking as NewPT, 
			b.tpositiontaking as OldPT, 
			bt.status, 		
			c.username as Creator
	from bodb02.dbo.bettrans bt with (NOLOCK)
		inner join dbo.bets b WITH (NOLOCK) ON bt.transid = b.transid	
		inner join bodb02.dbo.custinfo c with (nolock) on bt.creator = c.custid		
		inner JOIN @Match m1 on bt.oddsid = m1.matchid
		inner JOIN @Match m2 on b.oddsid = m2.matchid
	where bt.transid in (SELECT transid from #tmp)		
		AND m1.type = 'VSOutright'
		AND bt.bettype IN (1231,1232,1233,1237,1238)
		
	order BY bt.transid
	
	DROP TABLE #tmp
End

GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_CheckBet_Normal] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_CheckBet_Normal] TO [vnteam]
 