USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Task_ClearBalanceAllDownlines]    Script Date: 08/10/2016 14:14:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 

ALTER PROCEDURE [dbo].[Task_ClearBalanceAllDownlines]
(
	@isConfirmed BIT
)
AS
/*
	Created:
	DB: DBTXN/bodb02
	Task: Clear balance for downlines of agent
	
	Revisions: 
	- 20140925@Johnson: Add option clear balance for all members under agent and remove column isActive
	- 20150617@Daniel: Separating custDB to new server DBCUST [Redmine:#36216]		
	- 20150701@Kathy: Correct condition to break WHILE loop [Redmine:#36216]
	- 20160810@Lukas: Add finished time for each SMA customer		
*/
BEGIN

	DECLARE @CustID int, @Username varchar(50), @TransferType INT
	DECLARE @Today datetime, @finishedtime datetime
	DECLARE @ErrCode int, @ErrMsg NVARCHAR(MAX), @msg VARCHAR(1000) 
	DECLARE @OLD_lasttransfer datetime

	SET @today = CURRENT_TIMESTAMP

	-- prepare for running
		EXEC DBCUST.custDB.dbo.Task_UpdClearBalanceList @mode = 0

	WHILE (1 = 1)
	BEGIN
		IF (dbo.f_IsContinueClearBalance() = 0) BREAK -- control from outside

		SELECT TOP 1
		  @CustID = custid,
		  @TransferType = TransferType		
		  ,@OLD_lasttransfer = LastTransfer  
		FROM DBCUST.custdb.dbo.Acc_ClearBalanceList WITH(NOLOCK)
		WHERE [status] = 'waiting'

		--IF(@CustID IS NULL) BREAK -- no more to transfer
		IF @@rowcount = 0 BREAK -- no more to transfer
		
		EXEC DBCUST.custDB.dbo.Task_UpdClearBalanceList 
		  @custid = @custid,
		  @status = 'running',
		  @LastTransfer = @today,
		  @msg = ''
  					
		SELECT @Username = username 
		FROM custdb.dbo.custInfo WITH(NOLOCK)
		WHERE custid = @CustID
			AND roleid IN (2,3,4)
			
		IF @@ROWCOUNT = 0
		BEGIN
		
		    EXEC DBCUST.custDB.dbo.Task_UpdClearBalanceList 
			 @custid = @custid,
			 @status = 'failed',
			 @msg = 'InValid CustID!!!'		  	
			
			CONTINUE
		END
		
		SELECT @ErrCode = 0, @ErrMsg = ''
		
		IF @TransferTYpe = 1-- Clear All balance of members
		BEGIN
			EXEC Acc_BettransInsTransferAllMembers @AgentName =@Username
				,@UserID = 862400 -- starix2
				,@ErrMsg = @ErrMsg OUTPUT 
				,@ErrCode = @ErrCode OUTPUT
			
			SET @finishedtime = GETDATE()
			
			IF @ErrCode <> 0
			BEGIN
				SET @msg = LEFT(@ErrMsg, 1000)						
				EXEC DBCUST.custDB.dbo.Task_UpdClearBalanceList 
				    @custid = @custid,
				    @status = 'failed',
				    @LastTransfer = @finishedtime,
				    @msg = @msg -- just in case more than 1000 characters					 			
				
				CONTINUE
			END
			ELSE  --- successful
			BEGIN				
				EXEC DBCUST.custDB.dbo.Task_UpdClearBalanceList 				   
				    @custid = @custid,
				    @status = 'completed',
				    @LastTransfer = @finishedtime		
			END	
				
		END
		ELSE IF @TransferType = 2
		BEGIN
			EXEC [dbo].[Acc_ClearBalanceAllDownlines] @AgentName =@Username
				,@UserID = 862400 -- starix2
				,@ErrMsg = @ErrMsg OUTPUT 
				,@ErrCode = @ErrCode OUTPUT
				
			SET @finishedtime = GETDATE()
			IF @ErrCode = 1 -- server is busy, rollback lasttransfer value, wait 5 seconds and continue
			BEGIN
			
				EXEC DBCUST.custDB.dbo.Task_UpdClearBalanceList 
				    @custid = @custid,
				    @status = 'waiting',
				    @LastTransfer = @OLD_lasttransfer				    		
				
				WAITFOR DELAY '00:00:05'
				CONTINUE
			END
			ELSE IF @ErrCode <> 0
			BEGIN
				SET @msg = LEFT(@ErrMsg, 1000)				
				
				EXEC DBCUST.custDB.dbo.Task_UpdClearBalanceList 
				    @custid = @custid,
				    @status = 'failed',
				    @LastTransfer = @finishedtime,
				    @msg = @msg -- just in case more than 1000 characters
				    						
				CONTINUE
			END
			ELSE  --- successful
			BEGIN				 
				
				EXEC DBCUST.custDB.dbo.Task_UpdClearBalanceList 
				    @custid = @custid,
				    @status = 'completed',
				    @LastTransfer = @finishedtime
				    
			END
		END
		
	END
END