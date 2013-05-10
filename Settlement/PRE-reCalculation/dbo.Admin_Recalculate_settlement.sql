

ALTER PROCEDURE [dbo].[Admin_Recalculate_settlement]
(
	@matchid	INT,
	@creator	INT,
	@fth		SMALLINT		= NULL,
	@fta		SMALLINT		= NULL,
	@hth		SMALLINT,
	@hta		SMALLINT,
	@goalrecord VARCHAR(50)		= NULL,
	@betstatus	NVARCHAR(50),
	@IP			VARCHAR(15)		= '',
	@ErrCode	INT				= 0 OUTPUT,
	@ErrMsg		NVARCHAR(200)	= '' OUTPUT,
	@DelayTime	INT				= 0 OUTPUT
)
AS
/*	
	Created by: 20111116@Lukas
	Task: re-settlement
	DB: DB052.BODB_REVIEW

	Revisions:		
		
*/
BEGIN
	
	SET NOCOUNT ON 

	DECLARE @n	INT,
			@i	INT,
			@ActionID INT
	DECLARE @action VARCHAR(10)

	DECLARE @todolist TABLE 
		(	
			ID				INT IDENTITY PRIMARY KEY,
			matchid			INT,
			actionID		INT	
		)

	INSERT INTO @todolist(matchid,ActionID)
		SELECT	MatchID,actionID
		FROM bodb_customerLog.dbo.UserLog_Settle l WITH(NOLOCK)			
		WHERE l.matchID = @matchid
		ORDER BY LogDate ASC

	SELECT	@n = @@ROWCOUNT,
			@i = 1
	
	WHILE @i <= @n
	BEGIN
		
		SELECT @ActionID = ActionID
		FROM @todolist 
		WHERE ID = @i
		
		
		IF @ActionID IN (100,101,102,103)   ---- run [Admin_Settlement_1]
		BEGIN			
			
			SET @action = CASE @ActionID WHEN 100 THEN 'CAL'
										 WHEN 101 THEN 'CAL-FT'
										 WHEN 102 THEN 'CAL-HT'
										 WHEN 103 THEN 'UNDO'
										 ELSE ''
						   END

			EXEC [Admin_Recalculate_Settlement_1]
						@matchid	 = @matchid,
						@fth		 = @fth,
						@fta		 = @fta,
						@hth		 = @hth,
						@hta		 = @hta,
						@goalrecord  = @goalrecord,
						@betstatus	 = @betstatus,
						@action		 = @action,						
						@ErrCode	 = @ErrCode OUTPUT,
						@ErrMsg		 = @ErrMsg OUTPUT
			
			IF @ErrCode <> 0
			BEGIN
				SELECT @ErrMsg = 'Please try again.'
				RETURN
			END
		END

		IF @ActionID IN (104,105,106,107,120)  ---- run [Admin_Settlement_Parlay]
		BEGIN		

			SET @action = CASE @ActionID WHEN 104 THEN 'CAL'
										 WHEN 105 THEN 'UNDO'
										 WHEN 106 THEN 'REFUND-FT'
										 WHEN 120 THEN 'REFUND-HT'
										 WHEN 107 THEN 'REFUND'
										 ELSE ''
						   END
			
			EXEC [Admin_Recalculate_Settlement_Parlay]						
						@matchid		= @matchid,
						@betstatus		= @betstatus,
						@finalhomescore = @fth,
						@finalawayscore = @fta,
						@hthomescore	= @hth,
						@htawayscore	= @hta,
						@action			= @action,	
						@ErrCode		= @ErrCode OUTPUT,
						@ErrMsg			= @ErrMsg OUTPUT
			
			IF @ErrCode <> 0
			BEGIN
				SELECT @ErrMsg = 'Please try again.'
				RETURN
			END
			
		END
		
		IF @ActionID = 108   --- Admin_Settlement_FGLG
		BEGIN
			
			EXEC [Admin_Recalculate_Settlement_FGLG]
						@matchid	 = @matchid,
						@creator	 = @creator,						
						@betstatus	 = @betstatus,
						@goalrecord  = @goalrecord,
						@IncludeLG   = 1
--						@ErrCode	 = @ErrCode OUTPUT,
--						@ErrMsg		 = @ErrMsg OUTPUT
			IF @@ERROR <> 0 --@ErrCode <> 0
			BEGIN
				SELECT @ErrMsg = 'Please try again.'
				RETURN
			END
		END

		IF @ActionID = 109   -- Admin_Settlement_Refund_All
		BEGIN
			
			EXEC [Admin_Recalculate_Settlement_Refund_All]
						@matchid		= @matchid,	
						@creator		= @creator,					
						@IsExcludeBetdaq= 0
--						@ErrCode		= @ErrCode OUTPUT,
--						@ErrMsg			= @ErrMsg OUTPUT
			
			IF @ErrCode <> 0
			BEGIN
				SELECT @ErrMsg = 'Please try again.'
				RETURN
			END
		END

		IF @ActionID = 110    -- Admin_Settlement_RefundHT
		BEGIN
			EXEC [Admin_Recalculate_Settlement_RefundHT]
						@matchid		= @matchid,
						@adminid		= @creator
--						@ErrCode		= @ErrCode OUTPUT,
--						@ErrMsg			= @ErrMsg OUTPUT
			IF @@ERROR <> 0 --@ErrCode <> 0
			BEGIN
				SELECT @ErrMsg = 'Please try again.'
				RETURN
			END
		END

		IF @ActionID = 111    -- Admin_Settlement_RefundFT
		BEGIN
			EXEC [Admin_Recalculate_Settlement_RefundFT]
						@matchid		= @matchid,
						@adminid		= @creator,
						@IsExcludeBetdaq= 0
--						@ErrCode		= @ErrCode OUTPUT,
--						@ErrMsg			= @ErrMsg OUTPUT
			IF @@ERROR <> 0 --@ErrCode <> 0
			BEGIN
				SELECT @ErrMsg = 'Please try again.'
				RETURN
			END
		END

		IF @ActionID = 112    -- Admin_Settlement_Refund_FGLG
		BEGIN
			EXEC [Admin_Recalculate_Settlement_Refund_FGLG]
						@matchid	= @matchid,
						@adminid	= @creator,
						@LGOnly		= 0
----						@ErrCode	= @ErrCode OUTPUT,
----						@ErrMsg		= @ErrMsg OUTPUT
			IF @@ERROR <> 0 --@ErrCode <> 0
			BEGIN
				SELECT @ErrMsg = 'Please try again.'
				RETURN
			END
		END

		--- Admin_Settlement_BetDaq_Move ???
		--- Admin_Settlement_s161
		SET @i = @i + 1
	END  --- end while
	
END

