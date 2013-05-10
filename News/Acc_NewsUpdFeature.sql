ALTER PROCEDURE [dbo].[Acc_NewsUpdFeature]
	@AppID smallint,
	@NewsID int,
	@Feature smallint = 0,
	@ErrCode int = 0 Output,
	@ErrMsg nvarchar(200) = '' Output
AS
/*
Created: 20110317@Bobby
Task : Update Feature News on Accounting Site 
DB: DB06.bodb_Maintenance 
Original:


Param's Explanation:
	@Feature: 0 - normal, 1 - is feature, -1 - deleted	
*/

SET NOCOUNT ON;
IF @Feature=1
BEGIN
	EXEC dbo.Acc_NewsResetFeature @AppID, @ErrCode OUTPUT
	IF @ErrCode<>0
	BEGIN
		SELECT @ErrMsg = 'Error! Error when reset feature News ;', @ErrCode = 10102			
		RETURN
	END
	ELSE
	BEGIN
		UPDATE dbo.Acc_News WITH(ROWLOCK, UPDLOCK)
		SET 
			Feature = @Feature 
		WHERE NewsID = @NewsID AND AppID = @AppID
		IF @@Error <> 0
		BEGIN			
			SELECT @ErrMsg = 'Error! Error when updating feature News ;', @ErrCode = 10102			
			RETURN
		END
	END
END
ELSE
BEGIN 
	UPDATE dbo.Acc_News WITH(ROWLOCK, UPDLOCK)
	SET 
		Feature = @Feature 
	WHERE NewsID = @NewsID AND AppID = @AppID
	IF @@Error <> 0
	BEGIN			
		SELECT @ErrMsg = 'Error! Error when updating feature News ;', @ErrCode = 10102			
		RETURN
	END
END

GO
GRANT EXECUTE ON [dbo].[Acc_NewsUpdFeature] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_NewsUpdFeature] TO [VNTeam]
GO
