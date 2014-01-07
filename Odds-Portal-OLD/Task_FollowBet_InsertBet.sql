ALTER PROCEDURE [Task_FollowBet_InsertBet]
AS
/*
	Create:  
	Task:  
	DB: DBTRANS.BODB02

	Revisions:
		- 20120529@Sophia: . Update credit/debit balance
						   . Check @@Error to rollback
		- 20131108@Elodie: Splitting bodb02 into CustDB (call CustInfo, Exchange by link database)	
		- 20130107@Kathy: Get follower from Cust_FollowBet instead of hardcoded				   
*/
SET NOCOUNT ON

Declare @follow_transid bigint, @matchid int, @oddsid int, 
	@bettype smallint, @betteam nvarchar(1), @liveindicator bit,
	@stake money, @odds smallmoney

Declare	@apos smallmoney, @mpos smallmoney, @spos smallmoney, @tpos smallmoney,
	@playerdiscount decimal(9,8), @adiscount decimal(9,8), @mdiscount decimal(9,8), @sdiscount decimal(9,8)

Declare @custid int, @transid bigint, @rc int, @custBet int
Declare @LogData nvarchar(300), @Err int

SELECT TOP 1
	@follow_transid = transid,	@matchid = matchid, @oddsid = oddsid, 
	@bettype = bettype, @betteam = betteam, @liveindicator = liveindicator,
	@stake = follow_stake, @odds = odds, 
	--@apos = apos, @mpos = mpos, @spos = spos,
	@apos = 0, @mpos = 0, @spos = 0,
	--@playerdiscount = pdis, @adiscount = dis, @mdiscount = adis, @sdiscount = sdis
	@playerdiscount = 0, @adiscount = 0, @mdiscount = 0, @sdiscount = 0,
	@custBet = custid
FROM dbo.Task_FollowBet_Details


	--SET @custid = 
	--	6153451 -- BARM001
	--	--73103 -- ITK998001
	SELECT @custid = (SELECT Follower
						FROM CustDB.dbo.Cust_FollowBet
						where custid = @custBet)

	SELECT ISNULL(@custid, 6153451)
	--=====================================

		Declare @currency tinyint, @recommend int, @mrecommend int, @srecommend int, @CurrencyName nvarchar(10),
				@Username nvarchar(50), @VirtualMultiplier smallmoney, @virtualrate float, @betactualrate float,
				@autosuspend bit

		SELECT
			@Username = username, @recommend = IsNull(recommend,0), @mrecommend = IsNull(mrecommend,0), @srecommend = IsNull(srecommend,0),
			@currency = currency, @VirtualMultiplier = IsNull(VirtualMultiplier, 1),
			@autosuspend = IsNull(autosuspend, 0)
		FROM CustDB.dbo.custinfo (nolock)
		WHERE custid = @custid AND roleid = 1

		SELECT @betactualrate = actualrate, @virtualrate = @VirtualMultiplier * actualrate, @CurrencyName = currency
		FROM CustDB.dbo.exchange (nolock)
		WHERE exchangeid = @currency

	--=====================================


	--=====================================
	Declare @betstake money, @betactual_stake money
	Declare @stake_to_company money
	
	SELECT
		@betstake = @stake,
		@betactual_stake = CASE WHEN @odds > 0 THEN @stake ELSE ABS(@odds) * @stake END,
		@tpos = @apos + @mpos + @spos,
		@stake_to_company = @stake * (1-@tpos) * @betactualrate

		--Update pending debit balance	 
		INSERT INTO BalancePendingDebit (custid,Balance)
		VALUES (@custid, @betactual_stake)

		INSERT INTO dbo.bettrans
		(   
		custid, oddsid, oddsspread, hdp1, hdp2,odds, stake, actual_stake, 
		[status], statusID, livehomescore, liveawayscore, liveindicator, betfrom, betteam, creator, refno, 
		tpositiontaking, apositiontaking, mpositiontaking, spositiontaking,  
		playerdiscount, discount, adiscount, sdiscount, actualrate, virtualrate,  
		matchid, recommend, mrecommend, srecommend, scomm, swinlost,  
		bettype, currency, winlostdate, transdesc, 
		ip, Username, CurrencyName)
		SELECT
		@custid ,@oddsid, 0, hdp1, hdp2, @odds, @betstake, @betactual_stake, 
		b.status, b.statusID, livehomescore, liveawayscore, @liveindicator, 'i', @betteam,  @custid, 100000000000 ,  
		@tpos, @apos, @mpos, @spos, @playerdiscount, @adiscount, @mdiscount, @sdiscount, @betactualrate, @virtualrate,  
		@matchid, @recommend, @mrecommend, @srecommend, 0, 0,  
		@bettype, @currency, winlostdate, 
		'Follow from ' + username + ' transid:' + CAST(@follow_transid as varchar(30)) + ' delay ' + CAST(DATEDIFF(millisecond, transdate, CURRENT_TIMESTAMP) as varchar(20)) + ' ms', 
		'', @Username, @CurrencyName
		FROM
			dbo.bettrans b with (nolock)
		WHERE
			transid = @follow_transid
			AND statusID <> 101
		
	SELECT @Err = @@ERROR , @rc = @@ROWCOUNT, @transid=scope_identity()  
				
	IF @Err <> 0
	BEGIN		
		--Rollback Balance   
		INSERT INTO BalancePendingCredit (custid,Balance)
		VALUES (@custid, @betactual_stake)
		
		RETURN
	END 
		
	IF @rc > 0
	BEGIN
	--=====================================
		update odds with (rowlock, UPDLOCK)
		set
			hometotal=hometotal+ (case when @betteam='h' then (@stake*@betactualrate) else 0 end ) ,  
			awaytotal=awaytotal+ (case when @betteam='a' then (@stake*@betactualrate) else 0 end )   
		where
			oddsid=@oddsid

		EXEC DB02.bodb02.dbo.Dot_Member_Prod_Autobookie
			@custid = @custid,
			@oddsid = @oddsid,
			@matchid = @matchid,
			@odds = @odds,
			@bettype = @bettype,
			@betteam = @betteam,
			@betfrom = 'i',
			@stake_to_company = @stake_to_company,
			@currency = @currency,
			@autosuspend = @autosuspend,
			@liveindicator = @liveindicator

	--=====================================
		SET @LogData=N'Follow betting custid:' + cast(isnull( @custid,'x') as nvarchar(10)) + N' insert bet oddsid:' +  cast(isnull( @oddsid,'x') as nvarchar(10))
		+ N' at ' + CONVERT(nvarchar(10),CAST(isnull(@odds,0) as float)) + ' bet ' + cast(isnull(@betteam,'x') as nvarchar(10))  
		+ N' stake:' + CONVERT(nvarchar(50),isnull(@stake,0))   
		+ N' transid:' +cast(isnull( @transid,'x') as nvarchar(20))   
		+ N' ip:--system--'
		+ N' from:' + CAST(@follow_transid as nvarchar(30))
		
		EXEC dbo.logfile @custid, @logdata
	END -- if @rc > 0

DELETE FROM dbo.Task_FollowBet_Details
WHERE transid = @follow_transid



GO
GRANT VIEW DEFINITION ON [dbo].[Task_FollowBet_InsertBet] TO [vnteam] AS [dbo]