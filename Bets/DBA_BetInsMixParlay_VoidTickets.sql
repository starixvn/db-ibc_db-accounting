ALTER PROCEDURE DBA_BetInsMixParlay_VoidTickets
	@username varchar(50),
	@transids varchar(8000)
AS
/*
Created: 
Task: Insert balanced transaction (dummy) to void duplicated mix parlay tickets of an account
DB: DBTRANS.bodb02
Original: Dot_BetInsMixParlay

Revisions:
    - 20110128@Daniel: ADD
Param's Explanation:
• @transids: transids of mix parlay tickets to void/balanced
*/
DECLARE @Source tinyint

declare 
	--for place bet
	@mixodds float,
	@refno bigint,
	@creator int,
	@BetFrom nvarchar(1),
	@date datetime,
	@BET_IP nvarchar(20),
	@betcheck nvarchar(50),
	@oddstype tinyint,
	@custid INT,
	@recommend int,
	@mrecommend int,
	@srecommend int,
	@actualrate float,
	@virtualrate float,
	@stake money,
	@actual_stake money,
	@otpositiontaking float,
	@oapositiontaking float,
	@ompositiontaking float,
	@ospositiontaking float,
	@sdiscount float,
	@discount float,
	@adiscount float,
	@playerdiscount float,
	@currency int,
	@CurrencyName nvarchar(50),
	@SettingSporttype tinyint,
	
	--for settlement
	@status varchar(10),
	@statusid tinyint,
	@ruben tinyint,
	@modds smallmoney,
	@winlost money,
	@awinlost money,
	@mwinlost money,
	@swinlost money,
	@playercomm money,
	@comm money,
	@acomm money,
	@scomm money,
	@transdesc varchar(100)
	

IF EXISTS(SELECT 1 FROM bettrans14 with (NOLOCK) WHERE transid IN(SELECT val FROM dbo.strSplit(@transids, ',')))
	SELECT @Source = 0

IF (@Source IS NULL)
	IF EXISTS(SELECT 1 FROM DB06.bodb_Archive.dbo.bettrans_bk with (NOLOCK) WHERE transid IN(SELECT val FROM dbo.strSplit(@transids, ',')))
		SELECT @Source = 1

IF(@Source IS NULL) RETURN

SELECT 
	@mixodds = 1,
	@SettingSporttype = 1,
	@betfrom = 'i',
	@date = convert(datetime, convert(varchar(20),getdate(),101)),
	@BET_IP = '202.78.230.82',
	@betcheck = 'm+x',
	@oddstype = 1,
	@ruben = 1,
	@modds = 0,
	@transdesc = 'Insert balanced transaction for duplicate mix parlay tickets ' + @transids,
	@creator = 360418

select
	@custid = ci.custid,
	@recommend = ci.recommend,
	@mrecommend = ci.mrecommend,
	@srecommend = ci.srecommend,
	@actualrate = exchange.actualrate,
	@virtualrate = exchange.actualrate, ---- 2009-3-9(Michael): withdraw virtual currency on mix parlay, correct score & total goal.(Vivi)	
	@oapositiontaking = cs.apositiontaking,
    @ompositiontaking = cs.mpositiontaking,
    @ospositiontaking = case when srecommend <= 100 then 0 else cs.spositiontaking end,
	@otpositiontaking = isnull(@ospositiontaking, 0) + isnull(@ompositiontaking, 0) + isnull(@oapositiontaking, 0),
	@sdiscount = case when srecommend<=100 then cs.adiscount else cs.sdiscount end,
	@discount = cs.discount ,
	@adiscount = cs.adiscount ,
	@playerdiscount = cs.playerdiscount,
	@currency = ci.currency,
	@CurrencyName = exchange.currency
from 
	custinfo as ci with (nolock) 
	inner join custsetting as cs with (nolock) on ci.custid = cs.custid and cs.bettype=9 and cs.sporttype=@SettingSporttype
	inner join  exchange with (nolock) on ci.currency=exchange.exchangeid 
where ci.username=@username

IF (@Source = 0)
BEGIN
	select 
		@winlost = SUM(actual_stake), 
		@actual_stake = SUM(winlost),
		@stake = SUM(winlost),
		@awinlost = -SUM(awinlost),
		@mwinlost = -SUM(mwinlost),
		@swinlost = -SUM(swinlost),
		@playercomm = -SUM(playercomm),
		@comm = -SUM(comm),
		@acomm = -SUM(acomm),
		@scomm = -SUM(scomm)
	from bettrans14 with (nolock) 
	where transid IN(SELECT val FROM dbo.strSplit(@transids, ','))
		and custid = @custid and bettype = 9 and matchid = 9
END
ELSE
BEGIN
	select 
		@winlost = SUM(actual_stake), 
		@actual_stake = SUM(winlost),
		@stake = SUM(winlost),
		@awinlost = -SUM(awinlost),
		@mwinlost = -SUM(mwinlost),
		@swinlost = -SUM(swinlost),
		@playercomm = -SUM(playercomm),
		@comm = -SUM(comm),
		@acomm = -SUM(acomm),
		@scomm = -SUM(scomm)
	from DB06.bodb_Archive.dbo.bettrans_bk with (nolock) 
	where transid IN(SELECT val FROM dbo.strSplit(@transids, ','))
		and custid = @custid and bettype = 9 and matchid = 9
END

BEGIN TRANSACTION
	declare @refn int
	UPDATE ref with (rowlock,updlock) SET @refn=refno=refno+1  WHERE  refid='refno'
	set @refno = @refn + 100000000000
COMMIT TRANSACTION

SELECT 
	@status = case when @winlost-@stake > 0 then 'WON' else 'LOSE' end,
	@statusid = case when @winlost-@stake > 0 then 112 else 113 end


insert bettrans (custid,oddsid,hdp1,hdp2,odds,betteam,stake,status,
	refno,creator,betfrom, tpositiontaking,apositiontaking,mpositiontaking,
	discount,playerdiscount,adiscount,actualrate,virtualrate,comstatus,matchid,
	winlostdate,recommend,mrecommend,bettype, currency, srecommend, sdiscount, spositiontaking, actual_stake,ip, betcheck, username, currencyName, oddstype, statusID,
	ruben, modds,
	winlost, awinlost, mwinlost, swinlost,
	playercomm, comm, acomm, scomm, transdesc)
select @custid, @SettingSporttype, 0.0, 0.0,
	@mixodds, 'a', @stake, @status,
	@refno, @creator,@BetFrom, @otpositiontaking, @oapositiontaking, @ompositiontaking,
	@discount ,@playerdiscount ,@adiscount ,@actualrate ,@virtualrate, 'm',9,
	@date,@recommend ,@mrecommend ,9, @currency,  @srecommend, @sdiscount, @ospositiontaking, @stake, @BET_IP,@betcheck, @username, @currencyName, @oddstype, @statusid,
	@ruben, @modds, 
	@winlost, @awinlost, @mwinlost, @swinlost,
	@playercomm, @comm, @acomm, @scomm, @transdesc

select scope_identity() as TransID











