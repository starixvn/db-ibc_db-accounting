 USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Task_ClearBalanceAllDownlines]    Script Date: 9/25/2014 2:56:09 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/*
-- prepare for running

UPDATE Acc_ClearBalanceList WITH(ROWLOCK, UPDLOCK)
SET status = 'waiting'
WHERE isActive = 1 

*/

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
*/
BEGIN

	DECLARE @CustID int, @Username varchar(50), @TransferType INT
	DECLARE @Today datetime
	DECLARE @ErrCode int, @ErrMsg NVARCHAR(MAX) 
	DECLARE @OLD_lasttransfer datetime

	SET @today = DATEADD(dd, DATEDIFF(d, 0, CURRENT_TIMESTAMP), 0)

	-- prepare for running
	UPDATE custdb.dbo.Acc_ClearBalanceList WITH(ROWLOCK, UPDLOCK)
	SET status = 'waiting'
	WHERE LastTransfer < @today
		AND status <> 'waiting'

	WHILE (1 = 1)
	BEGIN
		IF (custdb.dbo.f_IsContinueClearBalance() = 0) BREAK -- control from outside
		
		UPDATE TOP (1) custdb.dbo.Acc_ClearBalanceList WITH(ROWLOCK, UPDLOCK)
		SET @OLD_lasttransfer = LastTransfer
			,LastTransfer = CURRENT_TIMESTAMP
			,msg = ''
			,status = 'running'
			,@CustID = custid
			,@TransferType = TransferType
		WHERE status = 'waiting'
		IF @@ROWCOUNT = 0 BREAK -- no more to transfer
			
		SELECT @Username = username 
		FROM custdb.dbo.custInfo WITH(NOLOCK)
		WHERE custid = @CustID
			AND roleid IN (2,3,4)
			
		IF @@ROWCOUNT = 0
		BEGIN
			UPDATE custdb.dbo.Acc_ClearBalanceList WITH(ROWLOCK, UPDLOCK)
			SET msg = 'InValid CustID!!!'
				,status = 'failed'
			WHERE custid = @CustID
			
			CONTINUE
		END
		
		SELECT @ErrCode = 0, @ErrMsg = ''
		
		IF @TransferTYpe = 1-- Clear All balance of members
		BEGIN
			EXEC Acc_BettransInsTransferAllMembers @AgentName =@Username
				,@UserID = 862400 -- starix2
				,@ErrMsg = @ErrMsg OUTPUT 
				,@ErrCode = @ErrCode OUTPUT
			
			IF @ErrCode <> 0
			BEGIN
				UPDATE custdb.dbo.Acc_ClearBalanceList WITH(ROWLOCK, UPDLOCK)
				SET msg = LEFT(@ErrMsg, 1000) -- just in case more than 1000 characters
					,status = 'failed'
				WHERE custid = @CustID
				
				CONTINUE
			END
			ELSE  --- successful
			BEGIN
				UPDATE custdb.dbo.Acc_ClearBalanceList WITH(ROWLOCK, UPDLOCK)
				SET status = 'completed'
				WHERE custid = @CustID
			END	
				
		END
		ELSE IF @TransferType = 2
		BEGIN
			EXEC [dbo].[Acc_ClearBalanceAllDownlines] @AgentName =@Username
				,@UserID = 862400 -- starix2
				,@ErrMsg = @ErrMsg OUTPUT 
				,@ErrCode = @ErrCode OUTPUT
			
			IF @ErrCode = 1 -- server is busy, rollback lasttransfer value, wait 5 seconds and continue
			BEGIN
				UPDATE custdb.dbo.Acc_ClearBalanceList WITH(ROWLOCK, UPDLOCK)
				SET LastTransfer = @OLD_lasttransfer
					,status = 'waiting'			
				WHERE custid = @CustID
				
				WAITFOR DELAY '00:00:05'
				CONTINUE
			END
			ELSE IF @ErrCode <> 0
			BEGIN
				UPDATE custdb.dbo.Acc_ClearBalanceList WITH(ROWLOCK, UPDLOCK)
				SET msg = LEFT(@ErrMsg, 1000) -- just in case more than 1000 characters
					,status = 'failed'
				WHERE custid = @CustID
				
				CONTINUE
			END
			ELSE  --- successful
			BEGIN
				UPDATE custdb.dbo.Acc_ClearBalanceList WITH(ROWLOCK, UPDLOCK)
				SET status = 'completed'
				WHERE custid = @CustID
			END
		END
		
	END
END
