ALTER PROCEDURE [NAP_Set_SettledErrorSel] @AdminId INT
	,@Top INT = 10
AS
/*	Creator: Kathy
	Date: 20140108
	Task: Get error message when settlement failed
	DB: DBTXN/BODB02
	Original: 

	History:
		- 20140404@Kathy: Get all notification messages for each group (Soccer, Other Sports)
		
	Param's Explanation:
		@Top: 0 -- Get all
		
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @numberRow INT
	DECLARE @tblSoccerTeam TABLE (custid INT)
	DECLARE @tblOtherSportTeam TABLE (custid INT)

	INSERT INTO @tblSoccerTeam
	SELECT	14228954			-- Keyscore1	
	UNION ALL SELECT 14228977	-- Keyscore2		
	UNION ALL SELECT 8068543	-- TRACY			
	UNION ALL SELECT 384559		-- YONG 
	UNION ALL SELECT 12978541	-- pgmHarris 
	--UNION ALL SELECT 9503076	-- pgmJacob 
	UNION ALL SELECT 4338171	-- pgmKaka 


	INSERT INTO @tblOtherSportTeam
	SELECT 462523 -- IRENE		
	UNION ALL SELECT 1590728	-- OSAMMY	
	UNION ALL SELECT 622158		-- OSBONNIE		
	UNION ALL SELECT 626446		-- OSFIONA		
	UNION ALL SELECT 283830		-- OSJOHNSON1	
	UNION ALL SELECT 859948		-- OSMICKEY	
	UNION ALL SELECT 5234866	-- OSVENNY
	UNION ALL SELECT 12978541	-- pgmHarris 
	--UNION ALL SELECT 9503076	-- pgmJacob 
	UNION ALL SELECT 4338171	-- pgmKaka 

	SELECT @numberRow = COUNT(1)
	FROM Settled_Message s WITH (NOLOCK)
		INNER JOIN match m WITH (NOLOCK) ON m.matchid = s.MatchId
	WHERE (
			(
				s.AdminId IN (
					SELECT custid
					FROM @tblSoccerTeam
					) AND @AdminId IN (
					SELECT custid
					FROM @tblSoccerTeam
					) AND m.sporttype = 1
				) OR (
				s.AdminId IN (
					SELECT custid
					FROM @tblOtherSportTeam
					) AND @AdminId IN (
					SELECT custid
					FROM @tblOtherSportTeam
					) AND m.sporttype <> 1
				) OR (s.AdminId = @AdminId)
			)

	DECLARE @tblTemp TABLE (
		AdminId INT
		,matchcode NVARCHAR(50)
		,homeid INT
		,awayid INT
		,Action VARCHAR(10)
		,Message VARCHAR(300)
		,starttime DATETIME
		,isRead BIT
		)

	IF @Top = 0
	BEGIN
		INSERT INTO @tblTemp (
			AdminId
			,matchcode
			,homeid
			,awayid
			,Action
			,Message
			,starttime
			,isRead
			)
		SELECT s.AdminId
			,m.matchcode
			,m.homeid
			,m.awayid
			,s.Action
			,s.Message
			,s.Starttime
			,s.IsRead
		FROM Settled_Message s WITH (NOLOCK)
			INNER JOIN match m WITH (NOLOCK) ON m.matchid = s.MatchId
		WHERE (
				(
					s.AdminId IN (
						SELECT custid
						FROM @tblSoccerTeam
						) AND @AdminId IN (
						SELECT custid
						FROM @tblSoccerTeam
						) AND m.sporttype = 1
					) OR (
					s.AdminId IN (
						SELECT custid
						FROM @tblOtherSportTeam
						) AND @AdminId IN (
						SELECT custid
						FROM @tblOtherSportTeam
						) AND m.sporttype <> 1
					) OR (s.AdminId = @AdminId)
				) AND Message IS NOT NULL
		ORDER BY IsRead
			,Starttime
			,CASE 
				WHEN AdminId = @AdminId THEN 0
				ELSE 1
				END
	END
	ELSE
	BEGIN
		INSERT INTO @tblTemp (
			AdminId
			,matchcode
			,homeid
			,awayid
			,Action
			,Message
			,starttime
			,isRead
			)
		SELECT TOP (@Top) s.AdminId
			,m.matchcode
			,m.homeid
			,m.awayid
			,s.Action
			,s.Message
			,s.Starttime
			,s.IsRead
		FROM Settled_Message s WITH (NOLOCK)
			INNER JOIN match m WITH (NOLOCK) ON m.matchid = s.MatchId
		WHERE (
				(
					s.AdminId IN (
						SELECT custid
						FROM @tblSoccerTeam
						) AND @AdminId IN (
						SELECT custid
						FROM @tblSoccerTeam
						) AND m.sporttype = 1
					) OR (
					s.AdminId IN (
						SELECT custid
						FROM @tblOtherSportTeam
						) AND @AdminId IN (
						SELECT custid
						FROM @tblOtherSportTeam
						) AND m.sporttype <> 1
					) OR (s.AdminId = @AdminId)
				) AND Message IS NOT NULL
		ORDER BY IsRead
			,Starttime
			,CASE 
				WHEN AdminId = @AdminId THEN 0
				ELSE 1
				END
	END

	SELECT ISNULL(@numberRow, 0) AS NumberRow

	SELECT *
	FROM @tblTemp

	UPDATE Settled_Message WITH (UPDLOCK, ROWLOCK)
	SET isRead = 1
	WHERE AdminId = @AdminId AND IsRead = 0
END

GO

GRANT EXECUTE ON [NAP_Set_SettledErrorSel] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [NAP_Set_SettledErrorSel] TO [vnteam] AS [dbo]
GO


