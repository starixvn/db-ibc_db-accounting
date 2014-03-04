CREATE PROCEDURE [NAP_Set_GetNumberError]
	@AdminId		 INT,
	@NumberError INT = 0 OUTPUT
AS

/*	Creator: Kathy
	Date: 20140108
	Task: Get number error
	DB: DBTXN/BODB02
	Original: 
	History:
		
	Param's Explanation:
		@Top: 0 - Get all
		
*/
BEGIN
	SET NOCOUNT ON 
	SET @NumberError = ISNULL((SELECT COUNT(*) FROM Settled_Message with(NOLOCK) WHERE IsRead = 0 AND AdminId = @AdminId AND Message IS NOT NULL),0)
END


GO

GRANT EXECUTE ON [NAP_Set_GetNumberError] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [NAP_Set_GetNumberError] TO [vnteam] AS [dbo]
GO


