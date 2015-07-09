 /* 
-- Delete current data 1st
Delete bettrans
where custid in (select m.custid
				 from custinfo m (nolock) 
					inner join DB03.bodb02.dbo.Affiliate_custinfo aff (nolock)on m.affiliateid = aff.custid
				 where aff.status ='Approved'
				)
	and bettype not in (99,100)

Delete bettrans
where custid in (select m.custid
				 from custinfo m (nolock) 
					inner join DB03.bodb02.dbo.Affiliate_custinfo aff (nolock)on m.custid = aff.custid
				 where aff.status ='Approved')
and bettype not in (99,100)

delete DB03.bodb02.dbo.Affiliate_bettrans where bettype = 105
delete DB06.bodb_report.dbo.RptDepWinlost
*/

--DECLARE @Winlostdate smalldatetime
--SELECT @Winlostdate = '2009-3-5'
---------


DECLARE @bal_deposit as table (custid int, currency tinyint, currencyname nvarchar(50))
insert into @bal_deposit (custid, currency, currencyname) 
select c.custid, c.currency, e.currency
from customer c(nolock) inner join exchange e (nolock) on c.currency = e.exchangeid
where username in 
('12BetMBAUD','12BetMBCHF','12BetMBEuro','12BetMBGBP','12BetMBRM','12BetMBTB','12BetMBUS$','12BetMBUUS')

DECLARE @AFF_exchange as table (updatetime smalldatetime, exchange float)
insert into @AFF_exchange (updatetime, exchange) 
select updatetime, actualrate 
from DB03.bodb02.dbo.Affiliate_exchange with(nolock) 
where exchangeid=3
	
--Get all member under aff
declare player_cursor cursor for 
select m.custid,m.currency,e.actualrate
from custinfo m (nolock) 
	inner join customer c with(nolock) on m.custid=c.custid
	inner join custinfo aff (nolock)on m.affiliateid = aff.custid
	inner join exchange e (nolock) on e.exchangeid = m.currency
where c.creatdate <@winlostdate


Declare @transid int, @bal_custid int, @custid int
Declare @ErrCode int
Declare @ErrMsg nvarchar(200)
Declare @RefNo bigint
Declare @bal_transid int, @amount money, @currency tinyint, @bonus_amount money, @actualrate float

Declare @recommend int, @mrecommend int, @srecommend int, @apos smallmoney, @mpos smallmoney, @spos smallmoney,
	@winlost money, @actual_stake money, @islose bit, @stake money, @awinlost money, @mwinlost money, @deposit_bet bit, @bonus_bet bit,
	@percent_lose float, @isNext bit


select @deposit_bet = 1, @bonus_bet = 1, @percent_lose = 1

OPEN player_cursor
FETCH NEXT FROM player_cursor into @custid, @currency, @actualrate
WHILE @@FETCH_STATUS = 0
BEGIN	
	
		
	--Deposit for member
	select @amount = (11-round(rand()*10,0))*7
	
	-- viet -- check member current balance
	DECLARE @CurrentBalanceMem money
	select @CurrentBalanceMem = isnull(sum(case when ruben = 1 then (winlost-actual_stake + playercomm)*isnull(e.actualrate,1)/isnull(ae.exchange,1) else 0 end), 0)
	FROM 
		customer c with(nolock)	
		left join bettrans b with(nolock) on b.custid=c.custid
		left join DB03.bodb02.dbo.Affiliate_exchange e with(nolock) on e.exchangeid=c.currency and datediff(month,b.winlostdate,updatetime)=0
		left join @AFF_exchange ae on datediff(month,b.winlostdate,ae.updatetime)=0
	WHERE c.custid = @custid
   
   if @amount >@CurrentBalanceMem 
   BEGIN
		select @isNext = convert(int,rand()*100)%2
		if @isNext = 1 FETCH NEXT FROM player_cursor into @custid, @currency, @actualrate
		
		DECLARE @DEP_Amount money
		SELECT @DEP_Amount = @amount*10
		-- DEPOSIT
		select @bal_custid = custid from @bal_deposit where currency = @currency
		
		if @deposit_bet = 1
		begin
			EXEC dbo.Dot_Dep_BettransInsTransaction_V2 
				@amount = @DEP_Amount,
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
				print 'Deposit success for member:' +convert(varchar(10),@custid) + ' amount:'+convert(varchar(20),@DEP_Amount)
				-- Update winlostdate for deposit
				update bettrans set winlostdate = @winlostdate where refno = @refno
			end
		end
		--Bonus for member

		select @bonus_amount = @DEP_Amount*0.1
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
   END

	select @recommend = recommend, @mrecommend = mrecommend, @srecommend = srecommend, @apos = apositiontaking, 
		@mpos = mpositiontaking, @spos = spositiontaking
	from customer c (nolock) inner join custsetting cs (nolock) on c.custid = cs.custid and sporttype = 1 and bettype = 1
	where c.custid = @custid
	
	--Place bets
	if @amount=0 FETCH NEXT FROM player_cursor into @custid, @currency, @actualrate
	select @amount = FLOOR(@amount/10)*10 -- bet amount
	select @islose = convert(int,rand()*100)%2
	if @islose = 0
		BEGIN
			select @islose = convert(int,rand()*100)%2
			if @islose = 0
				select @winlost = @percent_lose * @amount, @actual_stake = 0, @stake =@percent_lose* @amount,
						@awinlost = -@apos*(@winlost-@actual_stake), @mwinlost= -@mpos*(@winlost-@actual_stake)
			else
				select @winlost = 0, @actual_stake = @percent_lose * @amount, @stake = @percent_lose * @amount, 
						@awinlost = -@apos*(@winlost-@actual_stake), @mwinlost = -@mpos*(@winlost-@actual_stake)
		END
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
			@stake, case @islose when 1 then 'LOSE' else 'WIN' end,  0, 0,
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


/*
-- Bet summary
EXEC db06.bodb02.dbo.Task_DOT_Dep_DailySummary @winlostdate

*/

/*
--Monthly transfer
declare @month varchar(2), @year varchar(4)
select @month = convert(varchar(2),month(@winlostdate)), @year= convert(varchar(4), year(@winlostdate))
EXEC dbo.task_Aff_MonthlyTransfer 
	@Month =@month,
	@Year = @year,
	@AffMaster = '12BetAff'

*/	
