

ALTER PROCEDURE [dbo].[Admin_Settlement_s161_Manual_xtest]
	@matchid int,
	@firstball_value tinyint = NULL, -- 0 means N/A
	@secondball_value tinyint = NULL, -- 0 means N/A
	@thirdball_value tinyint = NULL, -- 0 means N/A
	@IP varchar(50),
	@AdminID int, -- Admin user
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
/*
	Created by:[Viet]
	Date:[20111219]
	Task: Re-calculate for a numbers game match
	DB: DBTRANS.bodb02
	
	Revisions:
	- 20120808@Sophia: Add @ErrCode, @ErrMsg to raise error
	- 20120930@Lukas: Put servername to control SP execution
	
*/
BEGIN	

	IF @@SERVERNAME IN ('DBTRANS','DB206')
	BEGIN
		IF EXISTS(SELECT 1 FROM SystemSettings WITH (NOLOCK) WHERE VValue = 1 AND VName = 'isCalculatingNGManual')
		BEGIN
			SELECT @ErrCode = 102
			SELECT @ErrMsg = 'Another number game re-calculation is in progress, please wait a few seconds until the ongoing process has finished and try again.'
			RETURN
		END
		ELSE 
		BEGIN
			UPDATE	systemSettings WITH (ROWLOCK, UPDLOCK)
			SET		VValue = '1'
			WHERE	VName = 'isCalculatingNGManual'
		END
	END


	-- step 1: refund all
	EXEC dbo.admin_settlement_s161
	@matchid = @matchid,
	@IsLive = 0,
	@ACTION = 'Refund',
	@IP = @IP,
	@AdminID = @AdminID,
	@ErrCode = @ErrCode OUTPUT,
	@ErrMsg = @ErrMsg OUTPUT
	
	IF @ErrCode <> 0
	BEGIN
		IF @@SERVERNAME IN ('DBTRANS','DB206')
			UPDATE	systemSettings WITH (ROWLOCK, UPDLOCK)
			SET		VValue = '0'
			WHERE	VName = 'isCalculatingNGManual'
		
		RETURN
	END
	
	-- step 2: update ball result
	IF @@SERVERNAME IN ('DBTRANS','DB206')
	BEGIN
		EXEC DB02.bodb02.dbo.Acc_UpdateNumberGameBalls 
			@matchid = @matchid,
			@firstball_value = @firstball_value,
			@secondball_value = @secondball_value,
			@thirdball_value = @thirdball_value,
			@ErrCode = @ErrCode OUTPUT,
			@ErrMsg = @ErrMsg OUTPUT
		
		IF @ErrCode <> 0
		BEGIN
			
				UPDATE	systemSettings WITH (ROWLOCK, UPDLOCK)
				SET		VValue = '0'
				WHERE	VName = 'isCalculatingNGManual'
			
			RETURN
		END
	END
	
	-- step 3: FIRST ball case
	IF @firstball_value is NULL 
	BEGIN
		IF @@SERVERNAME IN ('DBTRANS','DB206')
			UPDATE	systemSettings WITH (ROWLOCK, UPDLOCK)
			SET		VValue = '0'
			WHERE	VName = 'isCalculatingNGManual'
			
		RETURN
	END

	-- calculate first ball (live) [ and HT (dead) ]
	EXEC dbo.admin_settlement_s161
	@matchid = @matchid,
	@IsLive = 1,
	@DrawSeq = 1,
	@ACTION = 'CAL',
	@IP = @IP,
	@AdminID = @AdminID,
	@ErrCode = @ErrCode OUTPUT,
	@ErrMsg = @ErrMsg OUTPUT
	
	IF @ErrCode <> 0 
	BEGIN
		IF @@SERVERNAME IN ('DBTRANS','DB206')
			UPDATE	systemSettings WITH (ROWLOCK, UPDLOCK)
			SET		VValue = '0'
			WHERE	VName = 'isCalculatingNGManual'
		
		RETURN
	END

	-- step 4: SECOND ball case
	IF @secondball_value is NULL
	BEGIN
		EXEC dbo.admin_settlement_s161
			@matchid = @matchid,
			@IsLive = 0,
			@ACTION = 'Refund-FT',
			@IP = @IP,
			@AdminID = @AdminID,			
			@ErrCode = @ErrCode OUTPUT,
			@ErrMsg = @ErrMsg OUTPUT
			
		IF @@SERVERNAME IN ('DBTRANS','DB206')
			UPDATE	systemSettings WITH (ROWLOCK, UPDLOCK)
			SET		VValue = '0'
			WHERE	VName = 'isCalculatingNGManual'
		
		RETURN
		
	END

	EXEC dbo.admin_settlement_s161
		@matchid = @matchid,
		@IsLive = 1,
		@DrawSeq = 2,
		@ACTION = 'CAL',
		@IP = @IP,
		@AdminID = @AdminID,		
		@ErrCode = @ErrCode OUTPUT,
		@ErrMsg = @ErrMsg OUTPUT
	
	IF @ErrCode <> 0 
	BEGIN
		IF @@SERVERNAME IN ('DBTRANS','DB206')
			UPDATE	systemSettings WITH (ROWLOCK, UPDLOCK)
			SET		VValue = '0'
			WHERE	VName = 'isCalculatingNGManual'
		
		RETURN
	END

	-- step 5: THIRD ball case
	IF @thirdball_value is NULL
	BEGIN
		EXEC dbo.admin_settlement_s161
			@matchid = @matchid,
			@IsLive = 0,
			@ACTION = 'Refund-FT',
			@IP = @IP,
			@AdminID = @AdminID,			
			@ErrCode = @ErrCode OUTPUT,
			@ErrMsg = @ErrMsg OUTPUT
	
		IF @@SERVERNAME IN ('DBTRANS','DB206')
			UPDATE	systemSettings WITH (ROWLOCK, UPDLOCK)
			SET		VValue = '0'
			WHERE	VName = 'isCalculatingNGManual'
		
		RETURN
	END

	-- calculate 3rd ball (live)
	EXEC dbo.admin_settlement_s161
		@matchid = @matchid,
		@IsLive = 1,
		@DrawSeq = 3,
		@ACTION = 'CAL',
		@IP = @IP,
		@AdminID = @AdminID,
		@ErrCode = @ErrCode OUTPUT,
		@ErrMsg = @ErrMsg OUTPUT
	
	IF @ErrCode <> 0 
	BEGIN
		IF @@SERVERNAME IN ('DBTRANS','DB206')
			UPDATE	systemSettings WITH (ROWLOCK, UPDLOCK)
			SET		VValue = '0'
			WHERE	VName = 'isCalculatingNGManual'
		
		RETURN
	END


	-- calculate FT (dead)
	EXEC dbo.admin_settlement_s161
		@matchid = @matchid,
		@IsLive = 0,	
		@ACTION = 'CAL',
		@IP = @IP,
		@AdminID = @AdminID,
		@ErrCode = @ErrCode OUTPUT,
		@ErrMsg = @ErrMsg OUTPUT
		
	IF @@SERVERNAME IN ('DBTRANS','DB206')
		UPDATE	systemSettings WITH (ROWLOCK, UPDLOCK)
		SET		VValue = '0'
		WHERE	VName = 'isCalculatingNGManual'
END

