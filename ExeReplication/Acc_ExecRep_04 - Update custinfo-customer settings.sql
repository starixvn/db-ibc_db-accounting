ALTER PROCEDURE [dbo].[Acc_ExecRep_04]
	@custid int,
	@roleid tinyint,
	@action varchar(20) = '',
	@virtualmultiplier smallmoney = 0		
AS 
/*
Created: 20121126@Thien
Task : Update customer/custinfo settings
DB: DBTRANS.bodb02

Revisions:
	- 20121126@Thien: implement the 'VirtualMultiplier' update
	
   
*/

IF (SELECT COUNT(1) FROM sysobjects WHERE name IN ('custinfo', 'customer') AND type = 'U') < 2
	RETURN
	
if @action = 'VirtualMultiplier'
BEGIN
	if @roleid = 4
	BEGIN
		update custinfo with (ROWLOCK, UPDLOCK) set virtualmultiplier = @virtualmultiplier
		where srecommend = @custid
	END
	else if @roleid = 3
	BEGIN
		update custinfo with (ROWLOCK, UPDLOCK) set virtualmultiplier = @virtualmultiplier
		where mrecommend = @custid
	END
	else if @roleid = 2
	BEGIN
		update custinfo with (ROWLOCK, UPDLOCK) set virtualmultiplier = @virtualmultiplier
		where recommend = @custid
	END
	else if @roleid = 1
	BEGIN
		update custinfo with (ROWLOCK, UPDLOCK) set virtualmultiplier = @virtualmultiplier
		where custid = @custid
	END
END

GO
GRANT EXECUTE ON [dbo].[Acc_ExecRep_04] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_ExecRep_04] TO [vnteam] AS [dbo]