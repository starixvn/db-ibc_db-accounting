--------------------------------------------------------------------------------
--Create bet data for Horseracing (must generate HR Event's data before run this)
--------------------------------------------------------------------------------
declare @OddsIDs varchar(4000)--contains oddsIDs to be bet
declare @CustIDs varchar(4000)--contains Customer acc used to place bet
declare @NoOfOdds int, @NoOfCust int
declare @Random int--store random number for random odds, stake, ....
declare @BetCount int, @NoOfBets int, @odds smallmoney
declare @SuperID int, @CustID int, @OddsID int, @Stake int, @bettype int, @transid int, @CommType int
declare @MinStake int, @MaxStake int

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
	
	--Get random customer:
	select @Random = ROUND(((@NoOfCust - 1 - 1) * RAND() + 1), 0)
	select @CustID = replace(dbo.Acc_SplitIndex(@CustIDs, ',', @Random), ',','')
	
	--update cust setting
	update custinfo set credit = 1000000, maxpermatch=1000000 where custid = @CustID

	--Place bet outright:
	exec dbo.Dot_Member_PlaceBet 
		@custid=@custid,--custid
		@ugroup=N'a',
		@oddsid=@oddsid,--oddsid
		@betteam=N'outright',@hdp1=0,@hdp2=0,@odds=@odds,@livehomescore=0,@liveawayscore=0,
		@stake=@Stake,--stake
		@HTTP_REF=N'http://tmember.ibc88.com/outright/betprocess.aspx',@BET_IP=N'202.78.228.8',@site=N''

	select @transid = ident_current('bettrans')
	
	--update bet info to make it like Horseracing bet:
	
	select @CommType = minstake from league with (nolock)
	where leagueid = (select leagueid from outright with (nolock) where orid = (select matchid from bettrans with (nolock) where transid = @transid))
	
	update bettrans SET
		betteam = case @bettype when 31 then 'WIN' when 32 then 'PLACE' when 33 then 'E-WAY' end,
		bettype = @bettype,
		sdiscount = cs.sdiscount,
		adiscount = cs.adiscount,
		discount = cs.discount,
		playerdiscount = cs.playerdiscount,
		apositiontaking = 0, mpositiontaking = 0, spositiontaking = 0, tpositiontaking = 0
	from custsetting cs 
	where 
		cs.custid = @custid 
		and transid = @transid
		and sporttype = 151
		and cs.bettype = case @CommType when 1 then 31 when 2 then 32 end

	select @BetCount = @BetCount + 1
END
