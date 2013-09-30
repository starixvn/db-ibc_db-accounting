ALTER PROCEDURE [dbo].[Acc_ExecRep_04]
	@custid int,
	@roleid tinyint,
	@action varchar(20) = '',
	@virtualmultiplier smallmoney = 0,
	@Suspended	BIT =0,
	@Closed		BIT =0,
	@disabledCS BIT =0,
	@DisableLiveCasino BIT = 0,
	@DisableVS BIT = 0,
	@EnableVS BIT = 0,
	@DisableNumberGame BIT = 0,
	@BingoStatus BIT = 0,
	@rowcount INT = 0 OUTPUT
AS 
/*
Created: 20121126@Thien
Task : Update customer/custinfo settings
DB: DBTRANS.bodb02

Revisions:
	- 20121126@Thien: implement the 'VirtualMultiplier' update
	- 20130709@Jamie: Apply Exec Rep for Update CLOSED, SUSPENDED and RNG Casino Status
	- 20130926@Kathy: Apply Exec Rep for Live Casino, Virtual sport status, Number Game, Bingo status
	
Param's Explanation:
	@Action: 
		+ 'VirtualMultiplier': Virtual Rate [@virtualmultiplier]
		+ 'Suspended': Suspended/Reject		[@Suspended]
		+ 'Closed': Closed					[@Closed]
		+ 'disabledCS': RNG Casino Status	[@disabledCS]
		+ 'DisableLiveCasino': Live Casino status [@DisableLiveCasino]
		+ 'DisableVS': Disable Virtual Sport [@DisableVS]
		+ 'EnableVS': Enable Virtual Sport [@EnableVS]
		+ 'DisableNumberGame': Number game status [@DisableNumberGame]
		+ 'BingoStatus': Bingo status [@BingoStatus]
   
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
ELSE IF @Action = 'DisableLiveCasino'
BEGIN 
	IF @roleid = 4
			UPDATE CustInfo WITH(ROWLOCK, UPDLOCK)
			SET DisableLiveCasino = @DisableLiveCasino
			WHERE srecommend = @custid 
		
	IF @roleid = 3 
		UPDATE CustInfo WITH(ROWLOCK, UPDLOCK)
		SET DisableLiveCasino = @DisableLiveCasino
		WHERE mrecommend = @custid 
		
	IF @roleid =2
		UPDATE CustInfo WITH(ROWLOCK, UPDLOCK) 
		SET DisableLiveCasino = @DisableLiveCasino
		WHERE recommend = @custid 	
END
ELSE IF @Action = 'DisableVS'
BEGIN
	if @RoleID = 4 
		update CustInfo with (ROWLOCK, UPDLOCK) 
		set DisableVirtualSports = @DisableVS 
		where SRecommend = @CustID

	if @RoleID = 3 
		update CustInfo with (ROWLOCK, UPDLOCK) 
		set DisableVirtualSports = @DisableVS 
		where MRecommend = @CustID

	if @RoleID = 2 
		update CustInfo with (ROWLOCK, UPDLOCK) 
		set DisableVirtualSports = @DisableVS 
		where Recommend = @CustID
END
ELSE IF @Action = 'EnableVS'
BEGIN
	IF @roleid = 4
		UPDATE custinfo WITH(UPDLOCK,ROWLOCK)  
			SET DisableVirtualSports = @DisableVS,  
				HideVirtualSports = CASE WHEN HideVirtualSports = 1 THEN 0 ELSE HideVirtualSports END 
		WHERE srecommend = @custid  
	
	IF @roleid = 3
		UPDATE custinfo WITH(UPDLOCK,ROWLOCK)  
			SET DisableVirtualSports = @DisableVS,  
				HideVirtualSports = CASE WHEN HideVirtualSports = 1 THEN 0 ELSE HideVirtualSports END
		WHERE mrecommend = @custid 
	IF @roleid = 2
		UPDATE custinfo WITH(UPDLOCK,ROWLOCK)  
			SET DisableVirtualSports = @DisableVS,  
				HideVirtualSports = CASE WHEN HideVirtualSports = 1 THEN 0 ELSE HideVirtualSports END 
		WHERE recommend = @custid 
END
ELSE IF @Action = 'DisableNumberGame'
BEGIN
	if @RoleID = 4 
		update CustInfo with (ROWLOCK, UPDLOCK) 
		set DisableNumber = @DisableNumberGame 
		where SRecommend = @CustID

	if @RoleID = 3 
		update CustInfo with (ROWLOCK, UPDLOCK) 
		set DisableNumber = @DisableNumberGame 
		where MRecommend = @CustID

	if @RoleID = 2 
		update CustInfo with (ROWLOCK, UPDLOCK) 
		set DisableNumber = @DisableNumberGame 
		where Recommend = @CustID
END
ELSE IF @Action = 'BingoStatus'
BEGIN
	IF @RoleID = 4
		UPDATE CustInfo WITH (ROWLOCK, UPDLOCK) SET
			DisableBingo = @BingoStatus
		WHERE SyncBingo=1 AND srecommend=@custid AND roleid in (1,2,3)
	IF @RoleID = 3
		UPDATE CustInfo WITH (ROWLOCK, UPDLOCK) SET
			DisableBingo = @BingoStatus
		WHERE SyncBingo=1 AND mrecommend=@custid AND roleid in (1,2)
	IF @RoleID = 2
		UPDATE CustInfo WITH (ROWLOCK, UPDLOCK) SET
			DisableBingo = @BingoStatus
		WHERE SyncBingo=1 AND recommend=@custid AND roleid = 1
END

GO
GRANT EXECUTE ON [dbo].[Acc_ExecRep_04] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_ExecRep_04] TO [vnteam] AS [dbo]