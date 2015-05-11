--------------------------------------------------------------------------------
--Create bet data for Financial (must generate FA Event's data before run this)
--------------------------------------------------------------------------------
declare @MatchIDs varchar(4000)--contains index event IDs to be bet
declare @CustIDs varchar(4000)--contains Customer acc used to place bet
declare @NoOfEvents int, @NoOfCust int
declare @Random int--store random number for random odds, stake, ....
declare @BetCount int, @NoOfBets int
declare @SuperID int, @CustID int, @Matchid int, @Stake int, @bettype int, @transid int, @OU int, @hdp2 int
declare @MinStake int, @MaxStake int

--Bet setting:
select @SuperID = 1234--super of the member accounts used to place bet (limit to 300 accounts)
select @NoOfBets = 100--number of bets to place
select @MinStake = 50, @MaxStake = 500

--delete all ralated HR bets
--delete bettrans where bettype IN(51, 52)
--UPDATE custBetCredit with (rowlock, updlock)
--SET ReSync = 1
--WHERE custid IN(SELECT custid FROM custinfo where srecommend = @SuperID and roleid = 1 and closed = 0 and reject = 0)

--get FA event (match) into string for random choice:
select @MatchIDs = ''
select @MatchIDs = @MatchIDs + convert(varchar(10), matchid) + ',' from match where sporttype=201 and EventStatus = 'running' order by matchid

if @MatchIDs = '' 
BEGIN
	PRINT 'Cannot bet! No Finacial events running!'
	return
END 

select @CustIDs = ''
select top 300 @CustIDs = @CustIDs + convert(varchar(10), custid) + ','
from custinfo 
where srecommend = @SuperID and roleid = 1 and closed = 0 and reject = 0
order by custid 

select @NoOfEvents = count(*) from match where sporttype = 201 and EventStatus = 'running'
select @NoOfCust = count(*) from custinfo where srecommend = @SuperID and roleid = 1 and closed = 0 and reject = 0
select @NoOfCust = case when @NoOfCust > 300 then 300 else @NoOfCust end


--Place bet (random odds)

select @BetCount = 0
WHILE(@BetCount <= @NoOfBets)
BEGIN
	--Get random horse (odds):
	select @Random = ROUND(((@NoOfEvents - 1 - 1) * RAND() + 1), 0)
	select @Matchid = dbo.Acc_SplitIndex(@MatchIDs, ',', @Random)
	
	--Get random Stake:
	select @Stake = ROUND(((@MaxStake - @MinStake -1) * RAND() + @MinStake), 0)

	--Get random bettype (5 min, 1 hour):
	--select @bettype = ROUND(((52 - 51) * RAND() + 51), 0)
	
	select @bettype = ROUND(5* rand(),0) + (51 + ROUND(rand(),0)*10)
	--Get random betteam (over/under):
	select @OU = ROUND(((2 - 1) * RAND() + 1), 0)

	--Get random index's result:
	select @hdp2 = ROUND(((360 - 340) * RAND() + 340), 0)


	--Get random customer:
	select @Random = ROUND(((@NoOfCust - 1 - 1) * RAND() + 1), 0)
	select @CustID = Replace(dbo.Acc_SplitIndex(@CustIDs, ',', @Random), ',','')
	
	--Place bet------------------------------------------------------------------------------
	
	Declare @currency tinyint, @betteam char(1),
		@recommend int, @mrecommend int, @srecommend int, @Username nvarchar(50), @virtualrate float

	SELECT
		@Username = username,
		@currency = currency,
		@recommend = IsNull(recommend,0), @mrecommend = IsNull(mrecommend,0), @srecommend = IsNull(srecommend,0)
	FROM dbo.custinfo (nolock)
	WHERE custid = @custid AND roleid = 1

	Declare @actualrate float, @eminbet money, @CurrencyName nvarchar(10)
	SELECT
		@CurrencyName = currency,
		@actualrate = actualrate,
		@virtualrate = 1.5
	FROM dbo.exchange (nolock) WHERE exchangeid = @currency	
	

	Declare
		@apos smallmoney, @mpos smallmoney, @spos smallmoney, @tpos smallmoney,
		@playerdiscount decimal(9,8), @adiscount decimal(9,8), @mdiscount decimal(9,8), @sdiscount decimal(9,8)

	Declare @eventdate smalldatetime

	SELECT
		@apos = apositiontaking,		@mpos = mpositiontaking,
		@spos = spositiontaking,
		@playerdiscount = IsNull(playerdiscount,0),
		@adiscount = IsNull(discount,0),
		@mdiscount = IsNull(adiscount,0),
		@sdiscount = IsNull(sdiscount,0)
	FROM dbo.custsetting (nolock) where sporttype = 201 and custid = @custid 	
	
	SELECT @eventdate = eventdate FROM match WHERE matchid = @matchid
	select @betteam = case when @OU=1 then 'h' else 'a' end

	insert bettrans 
	( 		custid, oddsid, oddsspread, hdp1, hdp2,odds, stake, status, livehomescore, liveawayscore, liveindicator, betfrom, 
		betteam, creator, refno, tpositiontaking, apositiontaking, mpositiontaking, spositiontaking,
		playerdiscount, discount, adiscount, sdiscount, actualrate, virtualrate, matchid, recommend, mrecommend, srecommend, scomm, swinlost,
		bettype, currency, actual_stake, winlostdate, transdesc, ip, username, betcheck
	) 
	values 
	(
		@custid ,
		0, --oddsid
		0,
		350,--hdp1
		@hdp2,--hdp2
		100,--odds
		@stake, 'running',  0, 0,
		1, 'i', 
		@betteam, --betteam
		@custid, 100000000000,
		(@apos + @mpos + @spos), @apos, @mpos, @spos,
		@playerdiscount, @adiscount, @mdiscount, @sdiscount, @actualrate, @virtualrate,
		@matchid, @recommend, @mrecommend, @srecommend, 0, 0,
		@bettype, @currency, @stake, 
		@eventdate, '', '', @username, ''
	)
	------------------------------------------------------------------------------------------------------------------
	select @BetCount = @BetCount + 1
END
