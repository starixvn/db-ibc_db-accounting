ALTER PROCEDURE [dbo].[Admin_Calculate_10]
	@matchid int,
	@status nvarchar(10),
	@deadheat float = 1,
	@winlostdate smalldatetime = NULL
	
AS
/*
Created: 
Task : execRep sp for outright settlement

DB: DBTRANS.bodb02
Original: 

Revisions:
	- 20120202@Thien: receive @winlostdate param from outside SP, to resolve late replication in DBDW/2
	- 20121018@Johnson: Merge code for checking double comm losing from production
Param's Explanation:

*/
SET NOCOUNT ON

Declare @commWinRate smallmoney, @commLostRate smallmoney
-- @deadheat = fraction of deadheat to divide (1,2,3  etc)

if @winlostdate IS NULL
BEGIN
	select @winlostdate = convert(char(10),getdate(),111)
END

if (@status='won')
begin
	update bettrans with (updlock,rowlock)
	set	@commWinRate = CASE comstatus -- 0 : pay normal, both win/lost -- 1 : pay 'double' ONLY on lost
		WHEN '0' THEN 1
		WHEN '1' THEN 0 
		ELSE 1 END,
						
		[status] = 'WON',
		ruben = 1 ,
		winlostdate = @winlostdate, --convert(char(10),getdate(),111),
		statuswinlost = 2,
		Swinlost = -(odds-1) * spositiontaking * stake / @deadheat,
		mwinlost = -(odds-1) * mpositiontaking * stake / @deadheat,
		awinlost = -(odds-1) * apositiontaking * stake / @deadheat,
		winlost = (((odds-1)/@deadheat)+1) * stake ,
		Scomm = @commWinRate * (1-spositiontaking-mpositiontaking-apositiontaking) * sdiscount * stake,
		acomm = @commWinRate * (1-mpositiontaking-apositiontaking) * adiscount * stake,
		comm  = @commWinRate * (1-apositiontaking) * discount * stake,
		playercomm = @commWinRate * playerdiscount * stake,
		statusID = 112
	where matchid = @matchid and bettype = 10 and statusID NOT IN (101, 102) -- 101:reject, 102:void
end 
else if (@status='lose')
begin
	update bettrans with (updlock,rowlock)
	set	@commLostRate = CASE comstatus
		WHEN '0' THEN 1
		WHEN '1' THEN 2 
		ELSE 1 END,--'s','m'
	
		[status] = 'LOSE',
		ruben = 1 ,
		winlostdate = @winlostdate,
		statuswinlost = 4,
		Swinlost = spositiontaking * stake,
		mwinlost = mpositiontaking * stake,
		awinlost = apositiontaking * stake,
		winlost =0,
		Scomm = @commLostRate * (1-spositiontaking-mpositiontaking-apositiontaking) * sdiscount * stake,
		acomm = @commLostRate * (1-mpositiontaking-apositiontaking) * adiscount * stake,
		comm  = @commLostRate * (1-apositiontaking) * discount * stake,
		playercomm = @commLostRate * playerdiscount * stake,
		statusID = 113
	where matchid = @matchid and bettype = 10 and statusID NOT IN (101, 102) -- 101:reject, 102:void
end
ELSE IF @status = 'Refund'
BEGIN
	UPDATE dbo.bettrans with (updlock,rowlock)
	SET	[status] = 'Refund',
		ruben = 1 ,
		winlostdate = @winlostdate,
		statuswinlost = 4,
		swinlost = 0, mwinlost = 0, awinlost = 0,
		winlost = actual_stake,
		scomm = 0,
		acomm = 0,
		comm  = 0,
		playercomm = 0,
		statusID = 103
	where matchid = @matchid and bettype = 10 and statusID NOT IN (101, 102) -- 101:reject, 102:void
END


GO
GRANT EXECUTE ON [dbo].[Admin_Calculate_10] TO [ibc_admin]
GO
GRANT VIEW DEFINITION ON [dbo].[Admin_Calculate_10] TO [vnteam]