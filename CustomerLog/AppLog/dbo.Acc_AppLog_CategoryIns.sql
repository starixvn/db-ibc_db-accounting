ALTER PROCEDURE [dbo].[Acc_AppLog_CategoryIns]
	-- Add the parameters for the function here
	@CategoryName nvarchar(64),
	@LogID int
AS
/*	Created by: Lewin
	Date: 2010-07-08
	Task: Insert categorylog
	DB: LOG.bodb_CustomerLog 

*/
BEGIN
	SET NOCOUNT ON;
    DECLARE @CatID INT
	SELECT @CatID = CategoryID FROM AppLog_Category WITH (NOLOCK) WHERE CategoryName = @CategoryName
	IF @CatID IS NULL
	BEGIN
		INSERT INTO AppLog_Category (CategoryName) VALUES(@CategoryName)
		SELECT @CatID = @@IDENTITY
	END

	EXEC dbo.Acc_AppLog_CategoryLogIns @CategoryID = @CatID, @LogID = @LogID 

	RETURN @CatID
END


GO
GRANT EXECUTE ON [dbo].[Acc_AppLog_CategoryIns] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_AppLog_CategoryIns] TO [vnteam]