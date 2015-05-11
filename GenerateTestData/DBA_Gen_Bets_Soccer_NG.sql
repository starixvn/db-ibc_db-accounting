
ALTER PROCEDURE [dbo].[DBA_Gen_Bets_Soccer_NG]
	@superID	int = 1267251,
	@sporttype	int = 1		
AS 
BEGIN
	-- PHUONG DAO : 2009-02-05 
	-- Betting for NEXTGOAL 

	DECLARE	@NoOfBet int, @i int, @NoOfOdds int, @NoOfCust int,
			@Random	 int, @MatchID int, @oddsId int, @custid int, 
			@hdp1 float, @hdp2 float, @odds smallmoney
	DECLARE @OddsIDs varchar(4000) , @CustIDs varchar(4000), 
			@string varchar(2),@pos int, @betteam varchar(1)

	SELECT @OddsIDs='', @CustIDs='' ,@string ='ah'
	SELECT @NoOfBet = 50 
	SELECT TOP 100 @CustIDs = @CustIDs + convert(varchar(10), custid) + ','
	FROM custinfo (nolock) 
	WHERE srecommend = @SuperID and roleid = 1 and closed = 0 and reject =0 

	SELECT TOP 300 @OddsIDs =  @OddsIDs + convert(varchar(10), oddsid) + ','
	FROM	odds o (nolock) 
			INNER JOIN match m (nolock) on o.matchid = m.matchid 
	WHERE	o.sporttype = @sporttype and bettype = 1 
			AND o.oddsstatus='running'
			AND m.eventstatus='running' 

	SELECT @NoOfOdds = count(oddsid) 
	FROM	odds o (nolock) 
			INNER JOIN match m (nolock) on o.matchid = m.matchid 
	WHERE	o.sporttype = @sporttype and bettype = 1 
			AND o.oddsstatus='running'
			AND m.eventstatus='running'
	SELECT @NoOfCust = count (custid ) 
	FROM custinfo (nolock) 
	WHERE srecommend = @SuperID and roleid = 1 and closed = 0 and reject =0 

	IF @NoOfOdds > 100 SELECT @NoOfOdds = 300 
	IF @NoOfCust > 100 SELECT @NoOfCust = 100 

	SELECT @i = 0 
	WHILE (@i <= @NoOfBet)
	BEGIN 
		SELECT @Random = ROUND(((@NoOfOdds - 1 - 1) * RAND() + 1), 0)	
		SELECT @oddsId = replace(dbo.Acc_SplitIndex(@OddsIDs, ',', @Random)	,',','')	
		SELECT @hdp1 = hdp1 , @hdp2 = hdp2, @odds = odds1hka FROM odds (nolock) WHERE oddsid =@oddsid 
	
		SELECT @Random = ROUND(((@NoOfCust - 1 - 1) * RAND() + 1), 0)	
		SELECT @custid = replace(dbo.Acc_SplitIndex(@CustIDs, ',', @Random),',','')	
		SELECT @pos = ceiling(rand()*(len(@string)))
		SELECT @betteam = isnull(@betteam,'') + substring(@string, @pos, 1)

		EXECUTE [dbo].[Dot_Member_PlaceBet_NG]
		   @custid = @custid
		  ,@ugroup = 'hka'
		  ,@oddsid = @oddsid
		  ,@betteam = @betteam
		  ,@hdp1 = @hdp1
		  ,@hdp2 = @hdp2
		  ,@odds = @odds
		  ,@livehomescore = 0
		  ,@liveawayscore = 0
		  ,@stake = 100
		  ,@HTTP_REF = '2_1/30/2008@http://tmember.ibc88.com/BetProcess.aspx?match=???'
		  ,@BET_IP = '202.78.228.8'
		  ,@site = '722222'

		
		SET @i = @i + 1 

	END 
END