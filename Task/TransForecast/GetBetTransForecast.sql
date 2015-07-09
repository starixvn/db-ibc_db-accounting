ALTER   PROCEDURE [dbo].[GetBetTransForecast]
	@transid bigint
AS
-- 20120904@Viet: add new sportsbook and number bettypes
-- 20130121@Johnson: move sp from DB052.bodb02 to DBBET.BK 
insert into dbo.bets 
(transid,   hdp1, hdp2, odds,  stake, 
status,  livehomescore,  liveawayscore, liveindicator, betteam,
tpositiontaking,matchid,oddsid, ruben,  bettype,
 currency,custid,winlostdate) 
SELECT transid,   hdp1, hdp2, odds,  stake, 
status,  livehomescore,  liveawayscore, liveindicator, betteam,
tpositiontaking,matchid,oddsid, ruben,  bettype, 
currency,custid,winlostdate

-- remove  -50 : Joe : 20100627
--From BetTrans with  (nolock) Where  transid > @transid-50 and bettype<41
From bodb02.dbo.BetTrans with  (nolock) 
Where  transid > @transid --and bettype<41
and (bettype < 50 OR bettype between 81 and 999 OR bettype between 1201 and 1299)



GO
GRANT VIEW DEFINITION ON [dbo].[GetBetTransForecast] TO [vnteam]