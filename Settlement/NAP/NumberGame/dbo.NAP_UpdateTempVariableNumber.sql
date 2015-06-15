ALTER PROCEDURE [dbo].[NAP_UpdateTempVariableNumber]
	@MatchId	INT	
	,@ActionId	TINYINT
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
	
*/
BEGIN
	SET NOCOUNT ON
	BEGIN TRY
		IF @ActionId = 0 -- delete
		BEGIN
			DELETE FROM dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK) 
			WHERE KeyID = 1 AND KeyValue = @MatchId	
		END
		ELSE IF @ActionId = 1 -- insert
		BEGIN
			INSERT INTO dbo.TempVariableNumber (KeyID, KeyValue) VALUES (1, @MatchId)
		END	
	END TRY
	BEGIN CATCH
		SET @ErrCode = 100
	END CATCH
	
END

GO
GRANT EXECUTE ON [dbo].NAP_UpdateTempVariableNumber TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].NAP_UpdateTempVariableNumber TO [vnteam] AS [dbo]