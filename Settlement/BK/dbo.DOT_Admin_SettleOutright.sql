ALTER PROCEDURE [dbo].[DOT_Admin_SettleOutright]
	@matchid int,
	@status nvarchar(10),
	@deadheat float = 1
AS
 
 
/*	Created by:  
	Date:  
	Task:  
	DB: DBTRANS.bodb02
	Revisions:
	- 20110906@Sophia: Add Linked Server DB02.BODB02.dbo for outright
	
	Param's Explanation:
	- @deadheat = fraction of deadheat to divide (1,2,3  etc)
		 
*/


if (@status='won')
begin
	update DB02.BODB02.dbo.outright with (updlock,rowlock) 
	set oddsstatus = 'Completed', 
		eventdate = convert(char(10),getdate(),111), 
		[status] = 'WON',
		changetime = getdate() 
	where orid = @matchid
	
	update bettrans with (updlock,rowlock)
	set	[status] = 'WON',
		ruben = 1 ,
		winlostdate = convert(char(10),getdate(),111),
		statuswinlost = 2,
		Swinlost = -(odds-1) * spositiontaking * stake / @deadheat,
		mwinlost = -(odds-1) * mpositiontaking * stake / @deadheat,
		awinlost = -(odds-1) * apositiontaking * stake / @deadheat,
		winlost = (((odds-1)/@deadheat)+1) * stake ,
		Scomm = (1-spositiontaking-mpositiontaking-apositiontaking) * sdiscount * stake,
		acomm = (1-mpositiontaking-apositiontaking) * adiscount * stake,
		comm  = (1-apositiontaking) * discount * stake,
		playercomm = playerdiscount * stake,
		statusID = 112
	where matchid = @matchid and bettype = 10 and statusID NOT IN (101, 102) -- 101:reject, 102:void
end 
else if (@status='lose')
begin
	Update DB02.BODB02.dbo.outright with (updlock,rowlock)
	set oddsstatus = 'Completed', 
		eventdate = convert(char(10),getdate(),111), 
		[status] = 'LOSE',
		changetime = getdate() 
	where orid = @matchid
	
	update bettrans with (updlock,rowlock)
	set	[status] = 'LOSE',
		ruben = 1 ,
		winlostdate=convert(char(10),getdate(),111),
		statuswinlost = 4,
		Swinlost = spositiontaking * stake,
		mwinlost = mpositiontaking * stake,
		awinlost = apositiontaking * stake,
		winlost =0,
		Scomm = (1-spositiontaking-mpositiontaking-apositiontaking) * sdiscount * stake,
		acomm = (1-mpositiontaking-apositiontaking) * adiscount * stake,
		comm  = (1-apositiontaking) * discount * stake,
		playercomm = playerdiscount * stake,
		statusID = 113
	where matchid = @matchid and bettype = 10 and statusID NOT IN (101, 102) -- 101:reject, 102:void
end
ELSE IF @status = 'Refund'
BEGIN
	UPDATE DB02.BODB02.dbo.outright with (updlock,rowlock)
	SET oddsstatus = 'Completed', 
		eventdate = convert(char(10),getdate(),111), 
		[status] = 'Refund',
		changetime = getdate() 
	WHERE orid = @matchid
	
	UPDATE dbo.bettrans with (updlock,rowlock)
	SET	[status] = 'Refund',
		ruben = 1 ,
		winlostdate=convert(char(10),getdate(),111),
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
GRANT VIEW DEFINITION ON [dbo].[DOT_Admin_SettleOutright] TO [vnteam]