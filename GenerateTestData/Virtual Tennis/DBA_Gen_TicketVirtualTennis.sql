 ALTER PROCEDURE DBA_Gen_TicketVirtualTennis
	@CustID INT,
	@BetType INT,
	@MatchID INT,
	@StatusID TINYINT,	
	@betteam NVARCHAR(10),	
	@ErrMsg NVARCHAR(500) OUTPUT
AS
BEGIN
-- 1220：Player Win, betteam: h: player1, a: player2
-- 1235：Score Bet, betteam: 1-8 (correct score)
-- 1236：Total Points, beteam: 4,5,6,8,10,12 point

DECLARE @recommend INT, @mrecommend INT, @srecommend INT, @UserName NVARCHAR(50)
	SELECT @recommend = recommend, @mrecommend = mrecommend, @srecommend = srecommend, @UserName = username
	FROM custInfo c with (NOLOCK)
	where CustID = @CustID
	
INSERT INTO bodb02.dbo.bettrans (custid, transdate, oddsid, hdp1, hdp2, 
	odds, stake, status, winlost, awinlost, mwinlost, playercomm, comm, acomm, apositiontaking, mpositiontaking, tpositiontaking, playerdiscount, discount, adiscount, livehomescore, liveawayscore, liveindicator, 
	betteam, creator, refno, comstatus, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, 
	matchid, recommend, mrecommend, ruben, betid, statuswinlost, modds, 
	bettype, betdaqid, actual_stake, currency, ip, transdesc, sdiscount, scomm, spositiontaking, swinlost, srecommend, Username, CurrencyName, virtualrate, oddstype, statusID, currency2, balance, SecAcceptFlag, transid2, RecommDate)
SELECT top 20 @CustID, getdate(), oddsid, hdp1, hdp2, 
	case when odds<0 then odds + 2 else odds+1 end, 
	stake, status, winlost, awinlost, mwinlost, 0, 0, 0, apositiontaking, mpositiontaking, tpositiontaking, playerdiscount, discount, adiscount, b.livehomescore, b.liveawayscore, 0, 
	@betteam, b.creator, refno, comstatus, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, 
	@matchID, @recommend, @mrecommend, b.ruben, betid, statuswinlost, modds, 
	@bettype as bettype , betdaqid, actual_stake, currency, ip, transdesc, sdiscount, 0, spositiontaking, swinlost, @srecommend, @UserName, CurrencyName, virtualrate, oddstype, @statusID, currency2, balance, SecAcceptFlag, transid2, RecommDate
FROM match m with (NOLOCK) 
	INNER JOIN bettrans b WITH (NOLOCK) ON b.matchid = m.matchid
WHERE m.sporttype = 186 AND b.statusID = @StatusID
--and matchid = @OldMatchID 
--AND bettype IN (1,3,4,5,6,24)
			  
IF @@ROWCOUNT=0
begin
	select 'No data'
	return
end
END