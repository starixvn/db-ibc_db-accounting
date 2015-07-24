Use [BK]
GO 
ALTER PROCEDURE [dbo].[Acc_Rpt_CheckBet]
	@winlostdate datetime
as 
/*	
	Created by: Elodie
	Date: 20120816
	Task: Check the difference between data backup and current data of ticket 
	DB: DBBET/BK		
	Revisions:
		- 20121009@Elodie: Add 34 new bettypes of Tennis (1301 -> 1334)
		- 20130121@Johnson: move sp from DB052.BODB02 to DBBET.BK
		- 20130225@Elodie: Add Virtual Horse Racing report
		- 20141211@Sophia: change the range of bettypes of Tennis (1301 -> 1399)
		- 20141224@Dom: Apply Sport Bettype Matrix 
		- 20150724@Sophia: Exclude data of Bettrade [#38815] 

	Param's explanation:
		- SQL execution: exec Acc_Rpt_CheckBet @winlostdate='Aug  13 2012 12:00:00:000AM'
	
*/
Begin
	SET NOCOUNT ON 	
	 
		----Get Sport Bettype Matrix------
	DECLARE @SportBettype TABLE(ProductID INT, Bettype INT,EventType INT,SubProduct VARCHAR(500))
	INSERT INTO @SportBettype
	EXEC Acc_SportBettypeMatrix_Sel @mode = 5, @ProductId = 1

	DELETE	@SportBettype  
	WHERE	SubProduct IN ( 'BT-Sold','BT-Bought','BT-Comm') 
	

	declare @CheckNormalBet int, @CheckRejectBet int
	
	select @CheckNormalBet = count(1)
	from bodb02.dbo.bettrans bt with (nolock) 
		inner join dbo.bets b with (nolock) on bt.transid=b.transid		
		inner join @SportBettype s on s.bettype = b.bettype
	where bt.winlostdate=@winlostdate
			AND bt.currency <> 20
			AND s.productid in(1,2,3,5)
			/*and (
					bt.bettype < 31  or bt.bettype between 121 AND 999 or bt.bettype between 1301 AND 1399 --sportbook
					OR bt.bettype BETWEEN 81 AND 120 --number game					
					OR bt.bettype IN (31,32,33,41,42,43) --racing
					OR bt.bettype BETWEEN 1201 AND 1299 --virtual sports
				)*/
			and ((bt.stake<>b.stake or bt.tpositiontaking<>b.tpositiontaking)
				or (bt.odds<>b.odds and s.ProductID <> 2 )
				or (bt.betteam<>b.betteam and bt.bettype NOT IN (SELECT bettype FROM @SportBettype WHERE (ProductID=2) OR (ProductID=5 AND EventType =3))) --NOT IN (31,32,33,41,42,43, 1231,1232,1233,1237,1238)
				or ((bt.matchid<>b.matchid) AND ((s.ProductID=2) OR (s.ProductID = 1 AND s.EventType = 2))) --IN (31,32,33,41,42,43,10)
				or ((bt.oddsid<>b.oddsid) AND (s.ProductID = 5 AND s.EventType = 3))---- bt.bettype IN (1231,1232,1233,1237,1238))
				)	
		
	select @CheckRejectBet = count(1)
	from bodb02.dbo.bettrans bt with (nolock) 
		inner join dbo.betsreject b with (nolock) on bt.transid=b.transid
		inner join @SportBettype sbt on sbt.bettype = b.bettype
	where bt.winlostdate=@winlostdate
		and bt.custid<>98632
		and (bt.status<>b.status) 
		and b.currency <> 20
		AND productid in(1,2,3,5)
		/*and (
				bt.bettype < 31  or bt.bettype between 121 AND 999 or bt.bettype between 1301 AND 1399 --sportbook
				OR bt.bettype BETWEEN 81 AND 120 --number game					
				OR bt.bettype IN (31,32,33,41,42,43) --racing
				OR bt.bettype BETWEEN 1201 AND 1299 --virtual sports
			)*/

	select @CheckNormalBet as CheckNormalBet,@CheckRejectBet as CheckRejectBet 	
End

GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_CheckBet] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_CheckBet] TO [vnteam]

