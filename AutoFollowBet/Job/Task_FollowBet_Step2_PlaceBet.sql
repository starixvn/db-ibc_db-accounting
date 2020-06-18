/*<info serverAlias="DBTXN-bodb02" executers="" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Task_FollowBet_Step2_PlaceBet]
	@follow_transid BIGINT
	,@follower		INT
AS

/*
	Created:
	DB: DBTXN-bodb02

	Revisions:
		- 20120529@Sophia: . Update credit/debit balance
						   . Check @@Error to rollback
		- 20131108@Elodie: Splitting bodb02 into CustDB (call CustInfo, Exchange by link database)	
		- 20130107@Kathy: Get follower from Cust_FollowBet instead of hardcoded		
		- 20140919@Kathy: Allow to follow running ticket only [Redmine:#22392]	
		- 20141001@Lukas: remove param @betfrom on sp: DB02.bodb02.dbo.Dot_Member_Prod_Autobookie	
		- 20150311@Kathy: Support multi-follower on one customer [Redmine:#32146]
		- 20150617@Daniel: Separate custDB to new server DBCUST [Redmine:#36216]
        - 20150907@Kathy: Set virtualrate = actualrate when bettype is not applied virtualrate [Redmine:#42995] 
		- 20150805@Kathy: Using new balance table (BalCreditSports,BalDebitSports) [Redmine:#40125]
*/

BEGIN
	SET NOCOUNT ON
	
	DECLARE @matchid	INT
		,@oddsid		INT
		,@bettype		SMALLINT
		,@betteam		NVARCHAR(1)
		,@liveindicator BIT
		,@stake			MONEY
		,@odds			SMALLMONEY			
		,@transid		BIGINT
		,@rc			INT
		,@custBet		INT
		,@LogData		NVARCHAR(300)
		,@Err			INT
		,@sporttype		SMALLINT 
	
	SELECT @matchid		= t.matchid
		,@oddsid		= t.oddsid
		,@bettype		= t.bettype
		,@betteam		= t.betteam
		,@liveindicator = t.liveindicator
		,@stake			= t.follow_stake
		,@odds			= t.odds		
		,@custBet		= t.custid
		,@sporttype		= t.sporttype
	FROM dbo.Task_FollowBet_Details t WITH(NOLOCK)
		INNER JOIN dbo.bettrans b WITH(NOLOCK) ON b.transid = t.transid
	WHERE t.transid = @follow_transid
	AND t.follower = @follower

		
	--SELECT @custid = (
	--	SELECT TOP (1) Follower
	--	FROM CustDB.dbo.Cust_FollowBet WITH(NOLOCK)
	--	WHERE custid = @custBet
	--	)

	--SELECT @custid = ISNULL(@custid, 6153451)

	--=====================================
	DECLARE @currency			TINYINT
		,@recommend				INT
		,@mrecommend			INT
		,@srecommend			INT
		,@CurrencyName			NVARCHAR(10)
		,@Username				NVARCHAR(50)
		,@enableVirtualMultiplier	BIT
		,@VirtualMultiplier		SMALLMONEY = 0
		,@virtualrate			FLOAT
		,@betactualrate			FLOAT
		,@autosuspend			BIT		

	SELECT @Username		= username
		,@recommend			= ISNULL(recommend, 0)
		,@mrecommend		= ISNULL(mrecommend, 0)
		,@srecommend		= ISNULL(srecommend, 0)
		,@currency			= currency
		,@enableVirtualMultiplier = ISNULL(VirtualMultiplier, 1)
		,@autosuspend		= ISNULL(autosuspend, 0)
	FROM CustDB.dbo.custinfo WITH(NOLOCK)
	WHERE custid = @follower 
		AND roleid = 1

	--IF @enableVirtualMultiplier = 1 -- enable virtual rate
	--BEGIN
	--SELECT @VirtualMultiplier = virtualMultiplier
	--FROM DBCUST.custdb.dbo.CustVirtualRate WITH(NOLOCK)
	--WHERE custid = @follower 
	--	AND sporttype = @sporttype
	--	AND bettype = @bettype 
	--	AND isLive = @liveindicator
	--END
	
	SELECT @betactualrate	= actualrate
		,@virtualrate		= CASE WHEN ISNULL(@VirtualMultiplier,0) <> 0 THEN @VirtualMultiplier * actualrate ELSE actualrate END
		,@CurrencyName		= currency
	FROM CustDB.dbo.exchange WITH(NOLOCK)
	WHERE exchangeid = @currency

	--=====================================
	--=====================================
	DECLARE @betstake		MONEY
		,@betactual_stake	MONEY
		,@stake_to_company	MONEY

	SET @betstake = @stake
	SET @betactual_stake = CASE WHEN @odds > 0 THEN @stake ELSE ABS(@odds) * @stake END
	SET @stake_to_company = @stake * @betactualrate -- NO PT for uplines, then all stake go to HOUSE

	----Update pending debit balance	 
	--INSERT INTO BalancePendingDebit (custid, Balance)
	--VALUES (@follower, @betactual_stake)
	
	-- update debit balance
																																																																EXEC dbo.Dot_BalanceDebitUpd 
		@custID		= @follower
		,@balance	= @betactual_stake
		,@type		= 1 -- Sports
		,@isforced	= 1
	
	INSERT INTO dbo.bettrans (
		custid
		,oddsid
		,oddsspread
		,hdp1
		,hdp2
		,odds
		,stake
		,actual_stake
		,[status]
		,statusID
		,livehomescore
		,liveawayscore
		,liveindicator
		,betfrom
		,betteam
		,creator
		,refno
		,tpositiontaking
		,apositiontaking
		,mpositiontaking
		,spositiontaking
		,playerdiscount
		,discount
		,adiscount
		,sdiscount
		,actualrate
		,virtualrate
		,matchid
		,recommend
		,mrecommend
		,srecommend
		,scomm
		,swinlost
		,bettype
		,currency
		,winlostdate
		,transdesc
		,ip
		,Username
		,CurrencyName
		,betid
		)
	SELECT @follower
		,@oddsid
		,0
		,hdp1
		,hdp2
		,@odds
		,@betstake
		,@betactual_stake
		,b.STATUS
		,b.statusID
		,livehomescore
		,liveawayscore
		,@liveindicator
		,'i'
		,@betteam
		,@follower
		,100000000000		
		,0 -- tpos
		,0 -- apos
		,0 -- mpos
		,0 -- spos
		,0 -- playerdiscount
		,0 -- adiscount
		,0 -- mdiscount
		,0 -- sdiscount
		,@betactualrate
		,@virtualrate
		,@matchid
		,@recommend
		,@mrecommend
		,@srecommend
		,0
		,0
		,@bettype
		,@currency
		,winlostdate
		,'Follow from ' + username + ' transid:' + CAST(@follow_transid AS VARCHAR(30)) + ' delay ' + CAST(DATEDIFF(millisecond, transdate, CURRENT_TIMESTAMP) AS VARCHAR(20)) + ' ms'
		,''
		,@Username
		,@CurrencyName
		,@follow_transid
	FROM dbo.bettrans b WITH(NOLOCK)
	WHERE transid = @follow_transid 
		AND statusID = 0

	SELECT @Err = @@ERROR
		,@rc = @@ROWCOUNT
		,@transid = scope_identity()

	IF @Err <> 0
	BEGIN
		----Rollback Balance   
		--INSERT INTO BalancePendingCredit (custid, Balance)
		--VALUES (@follower,@betactual_stake)

		-- Rollback balance
																																																																																																																																EXEC dbo.Dot_BalanceCreditUpd
			@custID = @follower
			,@balance = @betactual_stake
			,@type = 1 -- Sports
			
		RETURN
	END

	IF @rc > 0
	BEGIN
		--=====================================
		UPDATE odds WITH(ROWLOCK, UPDLOCK)
		SET hometotal = hometotal + (CASE WHEN @betteam = 'h' THEN (@stake * @betactualrate) ELSE 0 END)
			,awaytotal = awaytotal + (CASE WHEN @betteam = 'a' THEN (@stake * @betactualrate) ELSE 0 END)
		WHERE oddsid = @oddsid

		EXEC DBPRO.bodb02.dbo.Dot_Member_Prod_Autobookie @custid = @follower
			,@oddsid = @oddsid
			,@matchid = @matchid
			,@odds = @odds
			,@bettype = @bettype
			,@betteam = @betteam
			--,@betfrom = 'i'
			,@stake_to_company = @stake_to_company
			,@currency = @currency
			,@autosuspend = @autosuspend
			,@liveindicator = @liveindicator

		--=====================================
		SET @LogData = N'Follow betting custid:' + CAST(ISNULL(@follower, 'x') AS NVARCHAR(10)) + N' insert bet oddsid:' + CAST(ISNULL(@oddsid, 'x') AS NVARCHAR(10)) + N' at ' + CONVERT(NVARCHAR(10), CAST(ISNULL(@odds, 0) AS FLOAT)) + ' bet ' + CAST(ISNULL(@betteam, 'x') AS NVARCHAR(10)) + N' stake:' + CONVERT(NVARCHAR(50), ISNULL(@stake, 0)) + N' transid:' + CAST(ISNULL(@transid, 'x') AS NVARCHAR(20)) + N' ip:--system--' + N' from:' + CAST(@follow_transid AS NVARCHAR(30))

		EXEC dbo.logfile @follower, @logdata
	END -- if @rc > 0

	DELETE FROM dbo.Task_FollowBet_Details WITH(UPDLOCK, ROWLOCK)
	WHERE transid = @follow_transid	
	AND follower = @follower	
	
	WAITFOR DELAY '000:00:01' -- WAIT 1 second, then back to the 1st step (list ticket)
END