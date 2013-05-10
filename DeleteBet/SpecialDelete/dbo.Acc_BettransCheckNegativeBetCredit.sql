ALTER PROCEDURE [dbo].[Acc_BettransCheckNegativeBetCredit]    
    @transids	VARCHAR(MAX)	= '',
    @Type bit,
    @ExcludeRunning bit = 0
AS
/*
Created by: 20121108@Elodie
Task : Check if a bet credit of customer is negative
DB: DBTRANS.bodb02

Revisions:   
	
Param's Explanation: Special bet delete option
    @transids: All ticket of customers who need to be check negative bet credit
    @Type: 
		- 0: Check negative bet credit for special delete funcion
		- 1: Check negative bet credit for recover funcion
	@ExcludeRunning: indicate status of tickets for special delete fuction
		- 0: Check negative bet credit of running tickets and settled tickets
		- 1: Check negative bet credit of settled tickets

*/
BEGIN
	SET NOCOUNT ON

	CREATE TABLE #BetDelete (transid BIGINT, custid INT)	
	DECLARE @BalanceCust TABLE (custid INT, username varchar(30),Balance Money)
	DECLARE @today SMALLDATETIME
	SET @today = convert(nvarchar(10), current_timestamp, 120)

	INSERT INTO #BetDelete (transid, custid)			
			SELECT DISTINCT transid, custid
			FROM bettrans b WITH (nolock)
			WHERE				
				b.transid IN (SELECT CONVERT(BIGINT, val) FROM dbo.strSplit(@transids, ','))
				AND winlostdate = @today	
				AND 1 = case when @Type = 0 AND @ExcludeRunning = 0 AND statusID IN (0, 1, 111, 112, 113) then 1
							 WHEN @Type = 0 AND @ExcludeRunning = 1 AND statusID IN (111, 112, 113) THEN 1
							 WHEN @Type = 1 AND statusID = 102 THEN 1
							 else 0 end					
					
	-- calculate a balance and outstanding of customer
	INSERT INTO @BalanceCust (custid, username, Balance)
	SELECT custid, username, sum(winlost - actual_stake + playercomm)
	from bettrans with (nolock) 			
	where custid in (SELECT custid FROM #BetDelete)
	group BY custid, Username
	
	CREATE TABLE #WonCust (
			custid		 INT,			
			balance		 MONEY)	
			
	IF(@Type = 0) --Check negative balance for special delete funcion
	begin
		INSERT INTO #WonCust (custid, balance)
		SELECT	b.custid, SUM (b.winlost - b.actual_stake + b.playercomm) balance
		FROM	bettrans b WITH (NOLOCK)
		WHERE	b.transid in (SELECT transid FROM #BetDelete)
		GROUP BY b.CustID
	end
	else --Check negative balance for recover funcion
	begin
		INSERT INTO #WonCust (custid, balance)
		SELECT	b.custid, SUM (b.actual_stake) balance
		FROM	bettrans b WITH (NOLOCK)
		WHERE	b.transid in (SELECT transid FROM #BetDelete)
		GROUP BY b.CustID
	end
	
	select bal.custid, bal.username, 
			case when wc.balance > 0 AND (c.credit + bal.balance - wc.balance) < 0 THEN 1 ELSE 0 END IsNegative
	from #WonCust wc 
		inner join @BalanceCust bal on wc.custid= bal.custid	
		inner join custInfo c with (NOLOCK) ON bal.custid = c.custid

	DROP TABLE #WonCust
	DROP TABLE #BetDelete		
END

GO
GRANT EXECUTE ON [dbo].[Acc_BettransCheckNegativeBetCredit] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_BettransCheckNegativeBetCredit] TO [VNTeam]