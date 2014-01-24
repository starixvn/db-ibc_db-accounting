ALTER PROCEDURE [NAP_Set_SettledErrorSel]
	@AdminId INT,
	@Top	INT = 10
AS

/*	Creator: Kathy
	Date: 20140108
	Task: Get error message when settlement failed
	DB: DBTXN/BODB02
	Original: 
	History:
		
	Param's Explanation:
		@Top: 0 -- Get all
		
*/
BEGIN
	SET NOCOUNT ON 
	DECLARE @tblTemp TABLE ( AdminId int, MatchId int, Action varchar(10), Message varchar(300), starttime datetime, isRead bit )
	IF @Top = 0
	BEGIN
		Insert INTO @tblTemp (AdminId, MatchId, Action, Message, starttime, isRead)
			SELECT AdminId, MatchId, Action, Message, Starttime, IsRead
			FROM Settled_Message with(NOLOCK)
			WHERE AdminId = @AdminId
			AND Message IS NOT NULL 
			ORDER BY IsRead DESC, Starttime DESC

	END 
	ELSE
	BEGIN
		Insert INTO @tblTemp (AdminId, MatchId, Action, Message, starttime, isRead)
			SELECT TOP(@Top) AdminId, MatchId, Action, Message, Starttime, IsRead
			FROM Settled_Message with(NOLOCK)
			WHERE AdminId = @AdminId
			AND Message IS NOT NULL
			ORDER BY IsRead DESC, Starttime DESC
	END

	SELECT *
	FROM @tblTemp

	UPDATE Settled_Message WITH(UPDLOCK, ROWLOCK)
	SET isRead = 1
	WHERE AdminId IN (SELECT AdminId FROM @tblTemp)
	AND MatchId IN (SELECT MatchId FROM @tblTemp)

END


GO

GRANT EXECUTE ON [NAP_Set_SettledErrorSel] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [NAP_Set_SettledErrorSel] TO [vnteam] AS [dbo]
GO


