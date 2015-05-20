ALTER PROCEDURE [dbo].[DBA_Match_Hedge_Ins]
	@matchid		INT,
	@NewMatchCode	NVARCHAR(20) ='',
	@isCopyTicket bit = 0
AS
/*	Created: Hurri
	Task: Create new hedge match

	Param's Explanation:
		@MatchID: Available real match
		@isCopyTicket: flag copy ticket of real match for hedge match (1: copy, 0: don't copy)
*/
BEGIN
	SET NOCOUNT ON 

	IF not exists (SELECT 1 FROM match WHERE matchid = @matchid)
	BEGIN
		RaisError ('MatchID does not exists', 16, 1)	
		return
	END
	Declare @leagueid int, @homeid int, @awayid int, @eventdate datetime, @kickofftime datetime, @eventstatus nvarchar(50), @matchcode nvarchar(50), @creator int

	SELECT @leagueid = leagueid
		 , @homeid = homeid
		 , @awayid = awayid
		 , @eventdate = eventdate
		 , @kickofftime = kickofftime
		 , @eventstatus = 'internal'
		 , @matchcode = CASE @NewMatchCode WHEN '' THEN 'hedge0000ex' + matchcode ELSE 'hedge0000ex' + @NewMatchCode END
		 , @creator = 8
	FROM
		match WITH (NOLOCK)
	WHERE
		matchid = @matchid

	INSERT INTO match (leagueid, homeid, awayid, eventdate, kickofftime, eventstatus, matchcode, creator)
	VALUES (@leagueid, @homeid, @awayid, @eventdate, @kickofftime, @eventstatus, @matchcode, 8)

	IF (@isCopyTicket = 1)
	BEGIN
		DECLARE @NewHedgeMatchID INT
		SELECT	@NewHedgeMatchID = SCOPE_IDENTITY()
		PRINT	'New Hedge Match: ' print @NewHedgeMatchID 
		
		INSERT INTO bettrans (custid
							, transdate
							, oddsid
							, hdp1
							, hdp2
							, odds
							, stake
							, status
							, winlost
							, awinlost
							, mwinlost
							, playercomm
							, comm
							, acomm
							, apositiontaking
							, mpositiontaking
							, tpositiontaking
							, playerdiscount
							, discount
							, adiscount
							, livehomescore
							, liveawayscore
							, liveindicator
							, betteam
							, creator
							, refno
							, comstatus
							, winlostdate
							, betfrom
							, betcheck
							, checktime
							, oddsspread
							, actualrate
							, matchid
							, recommend
							, mrecommend
							, ruben
							, betid
							, statuswinlost
							, modds
							, bettype
							, betdaqid
							, actual_stake
							, currency
							, ip
							, transdesc
							, sdiscount
							, scomm
							, spositiontaking
							, swinlost
							, srecommend
							, Username
							, CurrencyName
							, virtualrate
							, oddstype
							, statusID
							, currency2
							, balance
							, SecAcceptFlag)
		SELECT custid
			 , transdate
			 , oddsid
			 , hdp1
			 , hdp2
			 , odds
			 , stake
			 , status
			 , winlost
			 , awinlost
			 , mwinlost
			 , playercomm
			 , comm
			 , acomm
			 , apositiontaking
			 , mpositiontaking
			 , tpositiontaking
			 , playerdiscount
			 , discount
			 , adiscount
			 , livehomescore
			 , liveawayscore
			 , liveindicator
			 , betteam
			 , creator
			 , refno
			 , comstatus
			 , winlostdate
			 , betfrom
			 , betcheck
			 , checktime
			 , oddsspread
			 , actualrate
			 , @NewHedgeMatchID
			 , recommend
			 , mrecommend
			 , ruben
			 , betid
			 , statuswinlost
			 , modds
			 , bettype
			 , betdaqid
			 , actual_stake
			 , currency
			 , ip
			 , transdesc
			 , sdiscount
			 , scomm
			 , spositiontaking
			 , swinlost
			 , srecommend
			 , Username
			 , CurrencyName
			 , virtualrate
			 , oddstype
			 , statusID
			 , currency2
			 , balance
			 , SecAcceptFlag
		FROM bettrans with (NOLOCK)
		WHERE matchid = @matchid
	END
END