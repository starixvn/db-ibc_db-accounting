--Get member under aff
--Test Thien

DECLARE @bal_deposit as table (custid int, currency tinyint, currencyname nvarchar(50))
insert into @bal_deposit (custid, currency, currencyname) 
select c.custid, c.currency, e.currency
from customer c(nolock) inner join exchange e (nolock) on c.currency = e.exchangeid
where username in 
('12BETMBankAUD','12BETMBankUS$','12BETMBankEURO','12BETMBankGBP','12BETMBankCHF')

--Get all member under aff
declare player_cursor cursor for 
select m.custid,m.currency,e.actualrate 
from custinfo m (nolock) inner join custinfo aff (nolock)on m.affiliateid = aff.custid
	inner join exchange e (nolock) on e.exchangeid = m.currency
--where aff.custid = @affid

Declare @transid int, @bal_custid int, @custid int
Declare @ErrCode int
Declare @ErrMsg nvarchar(200)
Declare @RefNo bigint
Declare @bal_transid int, @amount money, @currency tinyint, @bonus_amount money, @actualrate float

Declare @recommend int, @mrecommend int, @srecommend int, @apos smallmoney, @mpos smallmoney, @spos smallmoney,
	@winlost money, @actual_stake money, @iswin bit, @stake money, @awinlost money, @mwinlost money, @winlostdate smalldatetime, @deposit_bet bit, @bonus_bet bit,
	@percent_lose float 


select @winlostdate = '2008-07-01', @deposit_bet = 1, @bonus_bet = 1, @percent_lose = 1

OPEN player_cursor
FETCH NEXT FROM player_cursor into @custid, @currency, @actualrate
WHILE @@FETCH_STATUS = 0
BEGIN
	--Deposit for member
	select @amount = (11-round(rand()*10,0))*100
	select @bal_custid = custid from @bal_deposit where currency = @currency
	select @recommend = recommend, @mrecommend = mrecommend, @srecommend = srecommend, @apos = apositiontaking, 
		@mpos = mpositiontaking, @spos = spositiontaking
	from customer c (nolock) inner join custsetting cs (nolock) on c.custid = cs.custid and sporttype = 1 and bettype = 1
	where c.custid = @custid
	if @deposit_bet = 1
	begin
		EXEC dbo.Dot_Dep_BettransInsTransaction_V2 
			@amount = @amount,
			@custid = @custid,
			@bal_custid = @bal_custid,
			@transdesc = 'Deposit',
			@transid = @transid OUTPUT,
			@ErrCode = @ErrCode OUTPUT,
			@ErrMsg = @ErrMsg OUTPUT,
			@bettype = 107,
			@IsCharge = 0,
			@ip = '-',
			@RefNo = @RefNo OUTPUT,
			@bal_transid = @bal_transid OUTPUT
		if @ErrCode <> 0
		begin
			print 'Deposit fail for member:'
			print @custid
			print @ErrMsg
		end
		else
		begin
			print 'Deposit success for member:' +convert(varchar(10),@custid) + ' amount:'+convert(varchar(20),@amount)
			-- Update winlostdate for deposit
			update bettrans set winlostdate = @winlostdate where refno = @refno
		end
	end
	--Bonus for member

	select @bonus_amount = @amount*0.1
	if @bonus_bet = 1
	begin
		EXEC dbo.Dot_Dep_BettransInsTransaction_V2 
			@amount = @bonus_amount,
			@custid = @custid,
			@bal_custid = @bal_custid,
			@transdesc = 'Bonus',
			@transid = @transid OUTPUT,
			@ErrCode = @ErrCode OUTPUT,
			@ErrMsg = @ErrMsg OUTPUT,
			@bettype = 110,
			@IsCharge = 0,
			@ip = '-',
			@RefNo = @RefNo OUTPUT,
			@bal_transid = @bal_transid OUTPUT
		if @ErrCode <> 0
		begin
			print 'Bonus fail for member:'
			print @custid
			print @ErrMsg
		end
		else
		begin
			print 'Bonus success for member:' + convert(varchar(10),@custid)+' amount:'+convert(varchar(20),@bonus_amount)
			update bettrans set winlostdate = @winlostdate where refno = @refno
		end
	end
	--Place bets
	select @iswin = 0
					--convert(int,rand()*100)%2
	if @iswin = 1
		select @winlost = @percent_lose * @amount, @actual_stake = 0, @stake =@percent_lose* @amount,
				@awinlost = -@apos*(@winlost-@actual_stake), @mwinlost= -@mpos*(@winlost-@actual_stake)
	else
		select @winlost = 0, @actual_stake = @percent_lose * @amount, @stake = @percent_lose * @amount, 
				@awinlost = -@apos*(@winlost-@actual_stake), @mwinlost = -@mpos*(@winlost-@actual_stake)

	insert bettrans 
		( 
			custid, oddsid, oddsspread, hdp1, hdp2,odds, stake, status, livehomescore, liveawayscore, liveindicator, betfrom, 
			betteam, creator, refno, tpositiontaking, apositiontaking, mpositiontaking, spositiontaking,
			playerdiscount, discount, adiscount, sdiscount, actualrate, virtualrate, matchid, recommend, mrecommend, srecommend, scomm, swinlost,
			bettype, currency, winlost, actual_stake, awinlost, mwinlost, winlostdate, transdesc, ip, betcheck, ruben
		) 
		values 
		(
			@custid ,
			0, --oddsid
			0,
			0,--hdp1
			0,--hdp2
			0,--odds
			@stake, case @iswin when 0 then 'LOSE' else 'WIN' end,  0, 0,
			0, 'i', 
			'', --betteam
			@custid, 100000000000,
			(@apos + @mpos + @spos), @apos, @mpos, @spos,
			0, 0, 0, 0, @actualrate, 0,
			0, @recommend, @mrecommend, @srecommend, 0, 0,
			3, @currency, @winlost, @actual_stake, @awinlost, @mwinlost, 
			@winlostdate, '', '', '',1
		)
	FETCH NEXT FROM player_cursor into @custid, @currency, @actualrate
END	
CLOSE player_cursor
DEALLOCATE player_cursor
--Monthly transfer
declare @month varchar(2), @year varchar(4)
select @month = convert(varchar(2),month(@winlostdate)), @year= convert(varchar(4), year(@winlostdate))
EXEC dbo.task_Aff_MonthlyTransfer 
	@Month =@month,
	@Year = @year,
	@AffMaster = '12BetAff'
	
EXEC db03.bodb02.dbo.Task_DOT_Dep_DailySummary @winlostdate

--Update aExrate for table rptDepWinLost
--update r
	--set aExRate = em.actualrate/ea.actualrate 
--from DB06.bodb_Report.dbo.rptDepWinLost r 
	--inner join DB03.bodb02.dbo.Affiliate_exchange em with(nolock) on em.exchangeid = r.currency and month(winlostdate) = month(em.updatetime) and year(winlostdate) = year(em.updatetime)
	--inner join DB03.bodb02.dbo.Affiliate_exchange ea with(nolock) on ea.exchangeid = 3 and month(winlostdate) = month(ea.updatetime) and year(winlostdate) = year(ea.updatetime)
--where winlostdate = @winlostdate

/*
--delete bet for all aff
delete from bettrans
where custid in (
select m.custid 
from custinfo m (nolock) inner join custinfo aff (nolock)on m.affiliateid = aff.custid
)
--delete transfer for aff
delete bettrans where custid in(
select custid from custinfo (nolock) where mrecommend = (select custid from customer (nolock) where username = '12BetAff') and roleid = 2
)
delete  b
from db03.bodb_report.dbo.rptDepWinlost b inner join custinfo ci (nolock) on b.custid = ci.custid 
where ci.affiliateid <> 0

delete from DB03.[12betaffiliate].dbo.Affiliate_MonthlyWinloss
delete from DB03.[12betaffiliate].dbo.Affiliate_BankTrans
delete from DB03.[12betaffiliate].dbo.Affiliate_Bettrans
*/


--Delete data for specific aff
/*
declare @affid int
select @affid = 1168091
delete  b
from db03.bodb_report.dbo.rptDepWinlost b inner join custinfo ci (nolock) on b.custid = ci.custid 
where ci.affiliateid = @affid

delete  from DB03.[12betaffiliate].dbo.Affiliate_MonthlyWinloss
where custid = @affid

delete from DB03.[12betaffiliate].dbo.Affiliate_Bettrans

delete  from DB03.[12betaffiliate].dbo.Affiliate_BankTrans
where custid = @affid

delete from bettrans 
where custid in (select distinct custid from custinfo ci (nolock) where ci.affiliateid = @affid ) 

delete from bettrans 
where refno in (select distinct refno from bettrans b (nolocK) where custid = @affid and matchid = 0) 
*/

