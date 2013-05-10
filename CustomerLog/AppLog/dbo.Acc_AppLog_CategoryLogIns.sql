ALTER PROCEDURE [dbo].[Acc_AppLog_CategoryLogIns]
	@CategoryID INT,
	@LogID INT
AS
/*	Created by: Lewin
	Date: 2010-07-08
	Task: Insert categorylog
	DB: LOG.bodb_CustomerLog 

*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @CatLogID INT
	SELECT @CatLogID FROM AppLog_CategoryLog WITH (NOLOCK) WHERE CategoryID=@CategoryID and LogID = @LogID
	IF @CatLogID IS NULL
	BEGIN
		INSERT INTO AppLog_CategoryLog (CategoryID, LogID) VALUES(@CategoryID, @LogID)
		RETURN @@IDENTITY
	END
	ELSE RETURN @CatLogID
END


GO
GRANT EXECUTE ON [dbo].[Acc_AppLog_CategoryLogIns] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_AppLog_CategoryLogIns] TO [vnteam]