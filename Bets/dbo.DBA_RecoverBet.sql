
ALTER PROCEDURE [dbo].[DBA_RecoverBet] 
	@transid BIGINT
AS
/*
Created: 
DB: DBTRANS.bodb02
Revisions:
	- 20100517@Henry: update column statusID of bettrans
	- 20101007@Henry: Change column transid from INT to BIGINT
	- 20110518@Lukas: Update HomeTotal, AwayTotal to Odds table
	- 20101028@Lukas: Update member balance
	- 20120412@Sophia: Revise update member balance
Param's Explanation:
*/

	
DECLARE @bettype SMALLINT,
		@matchid INT,
		@custid INT ,
		@balance MONEY
			
----Get data before update	
	SELECT	@custid = b.custid, @balance = (b.winlost - z.winlost), @bettype = b.bettype, @matchid =b. matchid 
	FROM	bettrans b 
	INNER JOIN zzzbettrans z WITH(NOLOCK) ON b.transid =z.transid
	WHERE   b.transid = @transid
	
	--update balance debit
	IF @balance > 0
	BEGIN		
		EXEC Dot_BalanceUpdDebit @custid = @custid, @balance = @balance
	END
	
	update bettrans
	set winlost = z.winlost, ruben= 0, statuswinlost = NULL, status ='running',statusID=0,
		creator = z.creator
		--,awinlost = z.awinlost, z.mwinlost = z.mwinlost, z.swinlost = z.swinlost, playercomm = z.playercomm,	comm  = comm, acomm = acomm, scomm = scomm
	from bettrans b inner join zzzbettrans z on b.transid =z.transid
	where b.transid = @transid

    --update balance credit	
	IF @balance < 0
	BEGIN
		SELECT @balance = ABS(@balance)
		EXEC Dot_BalanceUpdCredit @custid = @custid, @balance = @balance
	END
 


IF @bettype IN (1,3,7,8)
BEGIN
	-- update totalbets
	DECLARE @Total TABLE (oddsid INT, HomeTotal MONEY, AwayTotal MONEY)
	
	INSERT INTO @Total
	SELECT
		oddsid,
		SUM(CASE WHEN betteam='h' THEN (CASE WHEN ABS(odds) > 1 THEN ABS(odds) ELSE 1 END * b.stake * e.actualrate * (1-b.tpositiontaking)) ELSE 0 END) homeTotal,
		SUM(CASE WHEN betteam='a' THEN (CASE WHEN ABS(odds) > 1 THEN ABS(odds) ELSE 1 END * b.stake * e.actualrate * (1-b.tpositiontaking)) ELSE 0 END) awayTotal
	FROM bettrans b WITH (nolock)
		INNER JOIN exchange e WITH (nolock) ON b.currency = e.exchangeid
	WHERE bettype = @bettype AND ruben = 0 AND oddsid <> 0 and matchid = @matchid
	GROUP BY oddsid

	UPDATE odds WITH (rowlock, updlock)
	SET hometotal = t.HomeTotal, awaytotal = t.AwayTotal
	FROM @Total t WHERE odds.oddsid = t.oddsid
END

Delete from zzzbettrans where transid= @transid


GO
GRANT VIEW DEFINITION ON [dbo].[DBA_RecoverBet] TO [vnteam]