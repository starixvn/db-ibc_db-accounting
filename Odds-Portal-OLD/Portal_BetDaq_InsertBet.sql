ALTER PROCEDURE [dbo].[Portal_BetDaq_InsertBet]
	@oddsid int,
	@hdp1 smallmoney,
	@hdp2 smallmoney,
	@betteam nvarchar(10),
	@odds smallmoney,
	@stake money,
	@betdaqid int,
	@bet_IP nvarchar(15)
AS
/*
	Create: Joe
	Task: Use for portal servers
	DB: DBTXN/BODB02

	Revisions:
		- 20120529@Sophia: . Update credit/debit balance
						   . Check @@Error to rollback
		- 20131108@Elodie: Splitting bodb02 into CustDB (call CustInfo, CustSetting, Exchange by link database)					
*/

SET NOCOUNT ON

Declare @LogData nvarchar(300)
Declare @sporttype tinyint, @matchid int, @bettype smallint, @liveindicator bit
Declare @bt1 nvarchar(5), @bt2 nvarchar(5)
Declare @custid int

SELECT @sporttype = sporttype, @matchid = matchid, @bettype = bettype, @liveindicator = liveindicator
FROM dbo.odds (nolock) WHERE oddsid = @oddsid

IF @@ROWCOUNT = 0
BEGIN
	SET @custid = 25520
	SET @LogData = N'Portal Betdaq_InsertBet:ERROR:odds_not_found oddsid:' + CAST(@oddsid as nvarchar(10)) + N' betdaqid:' + CAST(@betdaqid as nvarchar(10))
	SELECT CAST(1 as tinyint) AS ErrCode
END
ELSE IF EXISTS(SELECT 1 FROM dbo.bettrans (nolock) WHERE matchid = @matchid AND bettype = @bettype AND betdaqid = @betdaqid)
BEGIN
	SET @custid = 25520
	SET @LogData = N'Portal Betdaq_InsertBet:ERROR:duplicate_betdaqid ' + CAST(@betdaqid as nvarchar(10))
	SELECT CAST(2 as tinyint) AS ErrCode
END
ELSE
BEGIN
	IF @bettype IN (1,3,7,8)
		SET @betteam = LEFT(@betteam, 1)
		
	ELSE IF @bettype IN (5,15)
		SELECT
			@hdp1 = 0, @hdp2 = 0, @odds = @odds + 1,
			@betteam = CASE @betteam
				WHEN 'h' THEN '1'
				WHEN 'a' THEN '2'
				ELSE 'x' END
				
	ELSE IF @bettype IN (4,16)
	BEGIN
		SELECT
			@odds = @odds + 1,
			@hdp1 = LEFT(@betteam, 1),
			@hdp2 = RIGHT(@betteam, 1),
			@betteam = LEFT(@betteam, 1) + ':' + RIGHT(@betteam, 1)

	END


	SET @custid = CASE 
		WHEN @sporttype = 8 THEN 879241 -- BQUSMLB
		WHEN @sporttype IN (2, 3, 4) THEN 103873 -- BQUSNBA
		ELSE 50057 END -- BQUS888
		
	-- testing phase
	--IF @bettype IN (4,16) SET @custid = 73103


	--=====================================
		Declare @matchdate datetime
		SELECT @matchdate = eventdate
		FROM dbo.match (nolock)
		WHERE matchid = @matchid

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
		Declare
			@apos smallmoney, @mpos smallmoney, @spos smallmoney, @tpos smallmoney,
			@playerdiscount decimal(9,8), @adiscount decimal(9,8), @mdiscount decimal(9,8), @sdiscount decimal(9,8)

		Declare @CustSettingBettype smallint
		Declare @CustSettingSporttype tinyint

		SET @CustSettingSporttype = case
			when @bettype in (13,24,25,26,27,28) then 1  -- for bet type :13,24,25,26,27,28
			when @sporttype = 26 then 3		-- Football(3) for Rugby(26) (Vivi)
			when @sporttype = 32 then 2		-- Basketball(2) for Netball(32) (Victor)
			when @sporttype NOT IN (1,2,3,5,8,10,11,151,161) then 99
			else @sporttype end

		SET @CustSettingBettype = case
			--when @bettype between 51 and 56 then 3						--Get Over/Under for Financial bettype from 51 to 56 (Thien)
			--when @bettype between 61 and 66 then 2						--Get Odd/Even for Financial bettype from 61 to 66 (Thien)
			when @bettype = 82 then 81						--Get 1st ball Over/Under for Last ball Over/Under
			when @bettype = 84 then 83						--Get 1st ball Odd/Even for Last ball Odd/Even
			when @bettype in (13,24,25,26,27,28) then 1     -- for bet type :13,24,25,26,27,28
			when @sporttype in (3,8,26) AND @bettype = 7 then 1	--Get Fulltime Handicap for 1st Handicap
			when @sporttype in (3,8,26) AND @bettype = 8 then 3	--Get Fulltime Over/Under for 1st Over/Under
			when @sporttype = 8 AND @bettype = 21 then 20	--Get Fulltime moneyline for 1st money
			when @sporttype = 11 AND @bettype = 3 then 1	--Motorsport (11) don't have OverUnder (3) setting, get from HDP (1)
			when @bettype = 15 then 5						--Get Fulltime 1x2 for 1st 1x2
			when @bettype = 12 then 2						--20080620: Get Fulltime OE for 1st OE (Thien)
			when @bettype in (16,14) then 4					--Get CorrectScore for HTFT, FGLG
			when @bettype in (32,33) then 31				--20081223_Thien: Get WIN for PLACE and WIN/PLACE for HorseRacing TOTE
			when @bettype in (42,43) then 41				--20090811_Thien: Get WIN for PLACE and WIN/PLACE for HorseRacing FIXED ODDS
			when @bettype = 22 then 1						--20090205_Vivi:  don't have Next Goal (22) setting, get from HDP (1)
			else @bettype end

		SET  @CustSettingBettype = case
			when @sporttype = 26 and @bettype = 5 then 1	--20090317_Vivi: don't have Rugby(26) FT.1X2 setting, get from Footbal(3)+HDP(1)
			when @CustSettingSporttype >= 2 AND @CustSettingBettype = 5 then 2
			when @CustSettingBettype not in (1,2,3,4,5,6,7,8,9,10,20,21,22,31,41,81,83,85,86,87,88,89) then 2
			else @CustSettingBettype end

		SELECT
			@apos = IsNull(CASE @sporttype WHEN 1 THEN case @liveindicator when 1 then CASE @bettype WHEN 2 THEN apositiontaking ELSE alivepositiontaking END else apositiontaking end ELSE apositiontaking END,0),			@mpos = IsNull(CASE @sporttype WHEN 1 THEN case @liveindicator when 1 then CASE @bettype WHEN 2 THEN mpositiontaking ELSE mlivepositiontaking END else mpositiontaking end ELSE mpositiontaking END,0),
			@spos = CASE
					WHEN @srecommend <= 100 THEN 0
					ELSE IsNull(CASE @sporttype WHEN 1 THEN case @liveindicator when 1 then CASE @bettype WHEN 2 THEN spositiontaking ELSE slivepositiontaking END else spositiontaking end ELSE spositiontaking END,0)
					END,
			@playerdiscount = IsNull(playerdiscount,0),
			@adiscount = IsNull(discount,0),
			@mdiscount = IsNull(adiscount,0),
			@sdiscount = IsNull(CASE WHEN @srecommend <= 100 THEN adiscount ELSE sdiscount END,0)
		FROM CustDB.dbo.custsetting (nolock)
		WHERE custid =@custid 
			AND bettype=@CustSettingBettype		
			AND sporttype=@CustSettingSporttype 


	--=====================================
	Declare @transid bigint
	Declare @betstake money, @betactual_stake money
	Declare @stake_to_company money
	SELECT
		@betstake = @stake,
		@betactual_stake = CASE WHEN @odds > 0 THEN @stake ELSE ABS(@odds) * @stake END,
		@tpos = @apos + @mpos + @spos,
		@stake_to_company = @stake * (1-@tpos) * @betactualrate

		---Update pending debit balance	 
		INSERT INTO BalancePendingDebit (custid,Balance)
		VALUES (@custid, @betactual_stake)
		

		INSERT bettrans   
		(   
		custid, oddsid, oddsspread, hdp1, hdp2,odds, stake, actual_stake, 
		[status], statusID, livehomescore, liveawayscore, liveindicator, betfrom, betteam, creator, refno, comstatus,
		tpositiontaking, apositiontaking, mpositiontaking, spositiontaking,  
		playerdiscount, discount, adiscount, sdiscount, actualrate, virtualrate,  
		matchid, recommend, mrecommend, srecommend, scomm, swinlost,  
		bettype, currency, winlostdate, transdesc, ip, Username, CurrencyName, betdaqid)   
		VALUES   
		(  
		@custid ,@oddsid, 0, @hdp1, @hdp2, @odds, @betstake, @betactual_stake, 
		N'running', 0, 0, 0, @liveindicator, 'i', @betteam,  @custid, 100000000000 , '0',
		@tpos, @apos, @mpos, @spos, @playerdiscount, @adiscount, @mdiscount, @sdiscount, @betactualrate, @virtualrate,  
		@matchid, @recommend, @mrecommend, @srecommend, 0, 0,  
		@bettype,@currency,   
		@matchdate, '', @bet_IP, @Username, @CurrencyName, @betdaqid
		)

		IF @@ERROR <> 0
		BEGIN
			--Manually rollback
			DELETE FROM bettrans WITH (ROWLOCK,UPDLOCK)     
			WHERE custid = @custid AND matchid = @matchid AND bettype = @bettype AND betdaqid = @betdaqid

			--Rollback Balance   
			INSERT INTO BalancePendingCredit (custid,Balance)
			VALUES (@custid, @betactual_stake)
			
			
			SELECT CAST(3 as tinyint) AS ErrCode 	
			RETURN
		END 
		
		SELECT @transid=scope_identity()  

	--=====================================
		IF @bettype IN (1,2,3,7,8)
		BEGIN
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
				--@betfrom = 'i',
				@stake_to_company = @stake_to_company,
				@currency = @currency,
				@autosuspend = @autosuspend,
				@liveindicator = @liveindicator

		END
		ELSE IF @bettype IN (5,15)
		BEGIN
			     IF @betteam = '1' UPDATE odds with (rowlock, UPDLOCK) SET com1total = com1total + CASE WHEN @odds <= 1.5 THEN @stake_to_company ELSE @stake_to_company*(@odds-1) END WHERE oddsid = @oddsid
			ELSE IF @betteam = 'X' UPDATE odds with (rowlock, UPDLOCK) SET comXtotal = comXtotal + CASE WHEN @odds <= 1.5 THEN @stake_to_company ELSE @stake_to_company*(@odds-1) END WHERE oddsid = @oddsid
			ELSE IF @betteam = '2' UPDATE odds with (rowlock, UPDLOCK) SET com2total = com2total + CASE WHEN @odds <= 1.5 THEN @stake_to_company ELSE @stake_to_company*(@odds-1) END WHERE oddsid = @oddsid

			EXEC DB02.bodb02.dbo.Dot_Member_Prod_Autobookie_1X2
				@custid = @custid,
				@oddsid = @oddsid,
				@matchid = @matchid,
				@odds = @odds,
				@bettype = @bettype,
				@betteam = @betteam,
				--@betfrom = 'i',
				@stake_to_company = @stake_to_company,
				@currency = @currency,
				@autosuspend = @autosuspend,
				@liveindicator = @liveindicator
		END
		ELSE IF @bettype IN (4,16)
		BEGIN
			EXEC DB02.bodb02.[dbo].[Dot_Member_Prod_Autobookie_CS_HTFT]
				@custid = @custid,
				@oddsid = @oddsid,
				@matchid = @matchid,
				@odds = @odds,
				@bettype = @bettype,
				@betteam = @betteam,
				--@betfrom = 'i',
				@stake_to_company = @stake_to_company,
				@currency = @currency,
				@autosuspend = @autosuspend,
				@liveindicator = @liveindicator
		END

	--=====================================
		SET @LogData=N'Portal betting custid:' + cast(isnull( @custid,'x') as nvarchar(10)) + N' insert bet oddsid:' +  cast(isnull( @oddsid,'x') as nvarchar(10))   
		+ N' at ' + CONVERT(nvarchar(10),CAST(isnull(@odds,0) as float)) + ' bet ' + cast(isnull(@betteam,'x') as nvarchar(10))  
		+ N' stake:' + CONVERT(nvarchar(50),isnull(@stake,0))   
		+ N' transid:' +cast(isnull( @transid,'x') as nvarchar(20))   
		+ N' ip:' + cast(isnull(@bet_IP,'x') as nvarchar(16))
		+ N' betdaqid:' + CAST(@betdaqid as nvarchar(10))
		
		SELECT CAST(0 as tinyint) AS ErrCode
END

EXEC dbo.logfile @custid, @logdata

GO
GRANT VIEW DEFINITION ON [dbo].[Portal_BetDaq_InsertBet] TO [vnteam] AS [dbo]