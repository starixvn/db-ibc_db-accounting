ALTER PROCEDURE [dbo].[NAP_Admin_Result_Update_1s]
  @Command						VARCHAR(100) 
 ,@MatchID						INT
 ,@ResourceIDs					VARCHAR(MAX)= NULL 
 ,@Results						VARCHAR(MAX)= NULL 
 ,@IsAuto						BIT			= 0 
 ,@creator						INT			= 0 
AS 
/*
	Created by: Jamie
	Date: 20140204
	Task: Update the result of Tennis 
	DB: DBPRO/bodb02 

	Revision

	Param's Explanation: 
*/
BEGIN
	SET NOCOUNT ON 

	DECLARE	@tmpResourceIDs	TABLE(
		 ID			INT IDENTITY(1,1)
		,ResourceID	VARCHAR(20)
	)
	INSERT INTO @tmpResourceIDs(ResourceID)
	SELECT	Val FROM dbo.StrSplit(@ResourceIDs,',')

	IF @Command ='NAP_Admin_Settlement_Auto_1s-CAL'
	BEGIN
		IF @IsAuto = 1 
		BEGIN
			UPDATE	ResultDetail WITH (UPDLOCK,ROWLOCK)
			SET		 ResultStatusID		= 2		-- Auto Settlement 
					,SettlementStatusID	= 4		-- Completed
					,LastModifyBy		= @Creator 
					,LastModifyDate		= GETDATE() 
			WHERE	MatchID = @MatchID
					AND ResourceID IN (SELECT ResourceID FROM @tmpResourceIDs)
		END
		ELSE IF @IsAuto = 0 
		BEGIN 
			DECLARE	@tmpResults TABLE(
				 ID			INT IDENTITY(1,1)
				,HomeValue	VARCHAR(20)
			)
			INSERT INTO @tmpResults(HomeValue)
			SELECT	Val FROM dbo.StrSplit(@Results,',') WHERE @Results IS NOT NULL 

			MERGE	ResultDetail AS TARGET
			USING(
				SELECT	 @MatchID AS MatchID
						,r.ResourceID 
						,t.HomeValue 
				FROM	@tmpResourceIDs r 
						INNER JOIN @tmpResults t ON r.ID = t.ID 
			) AS SOURCE ON (TARGET.MatchID = SOURCE.MatchID AND TARGET.ResourceID = SOURCE.ResourceID)
			WHEN	MATCHED THEN				 
					UPDATE SET
						TARGET.HomeValue			= SOURCE.HomeValue
						,TARGET.AwayValue			= NULL 
						,TARGET.ResultStatusID		= 5		-- Manual Settlement 
						,TARGET.SettlementStatusID	= 4		-- Completed
						,TARGET.LastModifyBy		= @Creator 
						,TARGET.LastModifyDate		= GETDATE() 
			WHEN	NOT MATCHED BY TARGET THEN 
					INSERT(
							MatchID
						,ResourceID
						,HomeValue
						,AwayValue
						,ResultStatusID
						,SettlementStatusID
						,CreateBy
						,CreateDate
						,LastModifyBy
						,LastModifyDate
					)
					VALUES(
						 SOURCE.MatchID
						,SOURCE.ResourceID
						,SOURCE.HomeValue
						,NULL
						,5 -- Manual Settlement 
						,4 -- Completed
						,@Creator
						,GETDATE()
						,@Creator
						,GETDATE()
					);		
		END

	END 
	/* END - @Command = 'NAP_Admin_Settlement_Auto_1s-CAL' */
	ELSE IF @Command ='NAP_Admin_Settlement_Auto_1s-UNDO'
	BEGIN
		UPDATE	ResultDetail WITH (UPDLOCK,ROWLOCK)
		SET		 HomeValue			= NULL 
				,AwayValue			= NULL 
				,ResultStatusID		= 0		-- Initial 
				,SettlementStatusID	= 0		-- Initial
				,LastModifyBy		= @Creator 
				,LastModifyDate		= GETDATE() 
		WHERE	MatchID = @MatchID
				AND ResourceID IN (SELECT ResourceID FROM @tmpResourceIDs)
	END
	/* END - @Command = 'NAP_Admin_Settlement_Auto_1s-UNDO' */
	ELSE IF @Command ='NAP_Admin_Settlement_Auto_1s-REFUND'
	BEGIN
		UPDATE	ResultDetail WITH (UPDLOCK,ROWLOCK)
		SET		 ResultStatusID		= 5		--  
				,SettlementStatusID	= 1		-- Refund
				,LastModifyBy		= @Creator 
				,LastModifyDate		= GETDATE() 
		WHERE	MatchID = @MatchID
				AND ResourceID IN (SELECT ResourceID FROM @tmpResourceIDs)		
	END 
	/* END - @Command = 'NAP_Admin_Settlement_Auto_1s-REFUND' */
END
GO
GRANT EXECUTE ON [dbo].[NAP_Admin_Result_Update_1s] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Admin_Result_Update_1s] TO [vnteam]