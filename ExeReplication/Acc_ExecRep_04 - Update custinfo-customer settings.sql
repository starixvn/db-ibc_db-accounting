ALTER PROCEDURE [dbo].[Acc_ExecRep_04]
	@custid int,
	@roleid tinyint,
	@action varchar(20) = '',
	@virtualmultiplier smallmoney = 0,
	@Suspended	BIT =0,
	@Closed		BIT =0,
	@disabledCS BIT =0		
AS 
/*
Created: 20121126@Thien
Task : Update customer/custinfo settings
DB: DBTRANS.bodb02

Revisions:
	- 20121126@Thien: implement the 'VirtualMultiplier' update
	- 20130709@Jamie: Apply Exec Rep for Update CLOSED, SUSPENDED and RNG Casino Status
	
Param's Explanation:
	@Action: 
		+ 'VirtualMultiplier': Virtual Rate [@virtualmultiplier]
		+ 'Suspended': Suspended/Reject		[@Suspended]
		+ 'Closed': Closed					[@Closed]
		+ 'disabledCS': RNG Casino Status	[@disabledCS]
   
*/
SET NOCOUNT ON 
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
ELSE IF @Action ='Suspended'
BEGIN
	if @RoleID = 4 
	BEGIN
		UPDATE	CustInfo with (ROWLOCK, UPDLOCK) 
		SET		Reject = @Suspended 
		WHERE	SRecommend = @CustID
	END
	ELSE IF @RoleID = 3 
	BEGIN
		UPDATE	CustInfo with (ROWLOCK, UPDLOCK) 
		SET		Reject = @Suspended 
		WHERE	MRecommend = @CustID
	END
	ELSE IF @RoleID = 2 
	BEGIN
		UPDATE	CustInfo with (ROWLOCK, UPDLOCK) 
		SET		Reject = @Suspended 
		WHERE	Recommend = @CustID
	END
END
ELSE IF @Action='Closed'
BEGIN
	IF @RoleID = 4 
	BEGIN
		UPDATE	custinfo WITH (ROWLOCK, UPDLOCK) 
		SET		closed = @closed 
		WHERE	srecommend = @custid
	END
	ELSE IF @RoleID = 3 
	BEGIN
		UPDATE	custinfo WITH (ROWLOCK, UPDLOCK) 
		SET		closed = @closed 
		WHERE	mrecommend = @custid
	END
	ELSE IF @RoleID = 2 
	BEGIN
		UPDATE	custinfo WITH (ROWLOCK, UPDLOCK) 
		SET		closed = @closed 
		WHERE	recommend = @custid
	END	
END
ELSE IF @Action ='disabledCS'
BEGIN
	IF @RoleID = 4
	BEGIN
		UPDATE	CustInfo WITH (ROWLOCK, UPDLOCK) 
		SET		DisableCasino = @disabledCS
		WHERE	SyncCasino=1 AND srecommend=@custid AND roleid BETWEEN 1 AND 3 
	END
	ELSE IF @RoleID = 3
	BEGIN
		UPDATE	CustInfo WITH (ROWLOCK, UPDLOCK) 
		SET		DisableCasino = @disabledCS
		WHERE	SyncCasino=1 AND mrecommend=@custid AND roleid BETWEEN 1 AND 2 
	END
	ELSE IF @RoleID = 2
	BEGIN
		UPDATE	CustInfo WITH (ROWLOCK, UPDLOCK) 
		SET		DisableCasino = @disabledCS
		WHERE	SyncCasino=1 AND recommend=@custid AND roleid = 1
	END
END

GO
GRANT EXECUTE ON [dbo].[Acc_ExecRep_04] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_ExecRep_04] TO [vnteam] AS [dbo]