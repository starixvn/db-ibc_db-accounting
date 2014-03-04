CREATE PROCEDURE [NAP_Set_SettledErrorSel] @AdminId INT
	,@Top INT = 10
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

	DECLARE @numberRow INT

	SET @numberRow = 0

	SELECT @numberRow = COUNT(1)
	FROM Settled_Message WITH (NOLOCK)
	WHERE AdminId = @AdminId

	DECLARE @tblTemp TABLE (
		AdminId INT
		,MatchId INT
		,Action VARCHAR(10)
		,Message VARCHAR(300)
		,starttime DATETIME
		,isRead BIT
		)

	IF @Top = 0
	BEGIN
		INSERT INTO @tblTemp (
			AdminId
			,MatchId
			,Action
			,Message
			,starttime
			,isRead
			)
		SELECT AdminId
			,MatchId
			,Action
			,Message
			,Starttime
			,IsRead
		FROM Settled_Message WITH (NOLOCK)
		WHERE AdminId = @AdminId AND Message IS NOT NULL
		ORDER BY IsRead
			,Starttime DESC
	END
	ELSE
	BEGIN
		INSERT INTO @tblTemp (
			AdminId
			,MatchId
			,Action
			,Message
			,starttime
			,isRead
			)
		SELECT TOP (@Top) AdminId
			,MatchId
			,Action
			,Message
			,Starttime
			,IsRead
		FROM Settled_Message WITH (NOLOCK)
		WHERE AdminId = @AdminId AND Message IS NOT NULL
		ORDER BY IsRead
			,Starttime DESC
	END

	SELECT @numberRow AS NumberRow

	SELECT *
	FROM @tblTemp

	UPDATE Settled_Message WITH (UPDLOCK, ROWLOCK)
	SET isRead = 1
	WHERE AdminId IN (
			SELECT AdminId
			FROM @tblTemp
			) AND MatchId IN (
			SELECT MatchId
			FROM @tblTemp
			)
END

GO

GRANT EXECUTE ON [NAP_Set_SettledErrorSel] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [NAP_Set_SettledErrorSel] TO [vnteam] AS [dbo]
GO


