 ALTER PROCEDURE [dbo].[DBA_Match_BetDaq_Ins]
	@MatchID		INT,
	@NewMatchCode	NVARCHAR(20) ='BetDaqxxx'
AS
/*	Created: Jamie
	Task: Create new match for BetDaq

	Param's Explanation:
		@MatchID : Old Match
*/
BEGIN
	SET NOCOUNT ON 
	DECLARE @eventdate DATETIME, @NewMatchID INT
	SELECT	@eventdate = CONVERT(VARCHAR(10), CURRENT_TIMESTAMP, 120)
	INSERT INTO Match( leagueid, homeid, awayid, eventdate, eventstatus, matchcode,creator)
	SELECT	leagueid, homeid, awayid, @eventdate, 'running', @NewMatchcode,8
	FROM	Match WITH (NOLOCK)
	WHERE	matchid = @MatchID 
	
	SELECT	@NewMatchID = SCOPE_IDENTITY()
	PRINT	'NEW MATCH:' print @NewMatchID 
		
	INSERT INTO Odds (matchid, bettype, hdp1, hdp2, odds1a, odds2a, oddsstatus, liveindicator, creator)
	SELECT	@NewMatchID, bettype, hdp1, hdp2, odds1a, odds2a, 'running', 0,8
	FROM	Odds WITH (NOLOCK)
	WHERE	matchid = @matchid  		

END