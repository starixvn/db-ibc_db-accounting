--------------------------------------------------------------------------------
--Create bet data for Horseracing (must generate HR Event's data before run this)
--------------------------------------------------------------------------------
declare @OddsIDs varchar(4000)--contains oddsIDs to be bet
declare @CustIDs varchar(4000)--contains Customer acc used to place bet
declare @NoOfOdds int, @NoOfCust int
declare @Random int--store random number for random odds, stake, ....
declare @BetCount int, @NoOfBets int, @odds smallmoney
declare @SuperID int, @CustID int, @OddsID int, @Stake int, @bettype int, @transid int, @CommType int
declare @MinStake int, @MaxStake int, @CommID int

--Bet setting:
select @SuperID = 1168165--super of the member accounts used to place bet (limit to 300 accounts)
--HRTest - 1168310
select @NoOfBets = 100--number of bets to place
select @MinStake = 50, @MaxStake = 500

--delete all ralated HR bets
--delete bettrans where bettype IN(31, 32, 33)
--UPDATE custBetCredit with (rowlock, updlock)
--SET ReSync = 1
--WHERE custid IN(SELECT custid FROM custinfo where srecommend = @SuperID and roleid = 1 and closed = 0 and reject = 0)

--get HR races (odds) into string for random choice:
select @OddsIDs = ''
select @OddsIDs = @OddsIDs + convert(varchar(10), orid) + ',' from outright where len(matchcode) = 2 and OddsStatus = 'running' order by orid

if @OddsIDs = ''
BEGIN
	PRINT 'Cannot bet! No Horse events running!'
	return
END 

select @CustIDs = ''
select top 100 @CustIDs = @CustIDs + convert(varchar(10), custid) + ','
from custinfo 
where srecommend = @SuperID and roleid = 1 and closed = 0 and reject = 0
order by custid 

--select @CustIDs = left(@CustIDs, len(@CustIDs)-1)

select @NoOfOdds = count(*) from outright where len(matchcode) = 2 and OddsStatus = 'running'
select @NoOfCust = count(*) from custinfo where srecommend = @SuperID and roleid = 1 and closed = 0 and reject = 0
select @NoOfCust = case when @NoOfCust > 300 then 300 else @NoOfCust end


--Place bet (random odds)
select @BetCount = 0
WHILE(@BetCount <= @NoOfBets)
BEGIN
	--Get random horse (odds):
	select @Random = ROUND(((@NoOfOdds - 1 - 1) * RAND() + 1), 0)
	select @OddsID = replace(dbo.Acc_SplitIndex(@OddsIDs, ',', @Random), ',','')
	
	select @odds = odds from outright o(nolock) where o.orid = @oddsID 
	--Get random Stake:
	select @Stake = ROUND(((@MaxStake - @MinStake -1) * RAND() + @MinStake), 0)

	--Get random bettype (win, place, e-way):
	select @bettype = ROUND(((33 - 31) * RAND() + 31), 0)
	--Commission type 
	SELECT @CommID = ROUND( RAND() + 1, 0)
	--Get random customer:
	select @Random = ROUND(((@NoOfCust - 1 - 1) * RAND() + 1), 0)
	select @CustID = replace(dbo.Acc_SplitIndex(@CustIDs, ',', @Random), ',','')
	
	--update cust setting
	update custinfo set credit = 1000000, maxpermatch=1000000 where custid = @CustID


	exec [dbo].[Dot_Member_PlaceBet3rd]
		@custid = @custid,
		@SportType =151,	--151(horse racing)/201(finance)
		@BetType =@bettype,	--31(win)/32(place)/33(winplace)/51(5min)/52(1hr)
		@oddsid = @oddsid,	--151(orid)/201(matchid)
		@betteam ='horse',	--horse/h(call)/a(put)
		@hdp1  = 0,
		@hdp2  = 0,
		@odds =@odds,
		@livehomescore = 0,
		@liveawayscore = 0,
		@stake =@stake,
		@HTTP_REF ='TESTHR',
		@BET_IP ='',
		@site ='Best-Odds',
		@betfrom = 'i',
		@creator = 8,
		@CommID = @CommID --151(horse racing) input

	select top 1 @transid = transid from bettrans where bettype in (31,32,33) order by transid desc

	EXEC dbo.Dot_Member_Confirm3rd 
		@transid = @transid,
		@IsSuccess = 1,
		@refno = '111'	
	select @BetCount = @BetCount + 1
END
