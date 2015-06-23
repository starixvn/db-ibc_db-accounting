USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[NAP_UpdateTempVariableNumber]    Script Date: 06/23/2015 10:12:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[NAP_UpdateTempVariableNumber]
	@MatchId	INT	
	,@ActionId	TINYINT
	,@KeyId		TINYINT = 1 
	,@ErrCode	INT  = 0 OUTPUT
AS
/*
	Created by:Kathy
	Date: 20131212
	Task: insert/delete match in TempVariableNumber
	DB: DBTXN/BODB02
	

	Revisions:
	
	Param's Explanation:
		@actionid = 0: Delete
					1: Insert
					
		@KeyId = 1: match
				 2: outright
	
*/
BEGIN
	SET NOCOUNT ON
	BEGIN TRY
		IF @ActionId = 0 -- delete
		BEGIN
			DELETE FROM dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK) 
			WHERE KeyID = @KeyId AND KeyValue = @MatchId	
		END
		ELSE IF @ActionId = 1 -- insert
		BEGIN
			INSERT INTO dbo.TempVariableNumber (KeyID, KeyValue) VALUES (@KeyId, @MatchId)
		END	
	END TRY
	BEGIN CATCH
		SET @ErrCode = 100
	END CATCH
	
END


GO
GRANT EXECUTE ON [dbo].[NAP_UpdateTempVariableNumber] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_UpdateTempVariableNumber] TO [vnteam] AS [dbo]