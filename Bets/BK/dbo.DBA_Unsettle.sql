
ALTER PROCEDURE [dbo].[DBA_Unsettle] 
	@matchid int
As

/*
Created: []
Task : unsettle

DB: DBTRANS.bodb02
Original: 

Revisions: 
	- 20100825@Lukas: Update last time modify (changetime column) for match table
	- 20110826@Sophia: add linked server DB02. Change server to DBTRANS instead of DB02

*/

Declare @matchdate smalldatetime


Update bettrans set ruben = 0, status = 'running',
	winlost = 0, awinlost = 0, mwinlost = 0, swinlost = 0,
	playercomm = 0, comm = 0, acomm = 0, scomm = 0
where matchid = @matchid and status in ('WON', 'DRAW', 'LOSE')

Update DB02.BODB02.dbo.Match WITH(ROWLOCK,UPDLOCK) set eventstatus = 'closed', changetime = getdate()
where matchid = @matchid

UPDATE dbo.bettransm WITH(ROWLOCK,UPDLOCK)
	SET [status]='running',statuswinlost=0,ruben=0
	WHERE matchid=@matchid

select @matchdate= eventdate from DB02.BODB02.dbo.Match WITH (nolock) where matchid = @matchid


exec [dbo].[Admin_Calculate_9] @matchid = @matchid, @matchdate = @matchdate


select * from bettransm (nolock) where matchid = 433793


