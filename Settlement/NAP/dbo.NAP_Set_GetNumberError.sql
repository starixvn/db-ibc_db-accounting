ALTER PROCEDURE [NAP_Set_GetNumberError] @AdminId INT
	,@NumberError INT = 0 OUTPUT
AS
/*	Creator: Kathy
	Date: 20140108
	Task: Get number error
	DB: DBTXN/BODB02
	Original: 
	History:
		- 20140404@Kathy: Count notification messages for each group (Soccer, Other Sports)
							Send email in case calculation got notify
	Param's Explanation:
		
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @tblSoccerTeam TABLE (custid INT)
	DECLARE @tblOtherSportTeam TABLE (custid INT)

	INSERT INTO @tblSoccerTeam
	SELECT	14228954			-- Keyscore1	
	UNION ALL SELECT 14228977	-- Keyscore2		
	UNION ALL SELECT 8068543	-- TRACY			
	UNION ALL SELECT 384559		-- YONG 
	UNION ALL SELECT 12978541	-- pgmHarris
	UNION ALL SELECT 4338171	-- pgmKaka  
	--UNION ALL SELECT 9503076	-- pgmJacob 

	INSERT INTO @tblOtherSportTeam
	SELECT 462523 -- IRENE		
	UNION ALL SELECT 1590728	-- OSAMMY	
	UNION ALL SELECT 622158		-- OSBONNIE		
	UNION ALL SELECT 626446		-- OSFIONA		
	UNION ALL SELECT 283830		-- OSJOHNSON1	
	UNION ALL SELECT 859948		-- OSMICKEY	
	UNION ALL SELECT 5234866	-- OSVENNY
	UNION ALL SELECT 12978541	-- pgmHarris 
	UNION ALL SELECT 4338171	-- pgmKaka 
	--UNION ALL SELECT 9503076	-- pgmJacob 

	SET @NumberError = ISNULL((
				SELECT COUNT(1)
				FROM Settled_Message s WITH (NOLOCK)
				INNER JOIN match m WITH (NOLOCK) ON m.matchid = s.MatchId
				WHERE IsRead = 0 
					AND (
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
					AND Message IS NOT NULL
				), 0)

	-- send email in case calculation got issues
	SELECT m.matchid, m.matchcode, m.homeid, m.awayid, m.sporttype, s.IP, s.Starttime, s.Action, s.Message
	FROM Settled_Message s with(NOLOCK) 
	INNER JOIN match m WITH(NOLOCK) ON m.matchid = s.MatchId
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
	AND IsSent = 0
	AND s.Message IS NOT NULL

	UPDATE s
	SET s.IsSent = 1
	FROM Settled_Message s INNER JOIN match m ON m.matchid = s.MatchId
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
	AND s.IsSent = 0
	AND s.Message IS NOT NULL

END

GO

GRANT EXECUTE ON [NAP_Set_GetNumberError] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [NAP_Set_GetNumberError] TO [vnteam] AS [dbo]
GO


