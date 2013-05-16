ALTER PROCEDURE [dbo].[Acc_SMATurnoverMatchSel]
	@MatchID INT,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
/*
	Created: Elodie
	Date: 20130515
	Task : Retrieve match information by matchid
	DB: DBAGE/bodb02

	Revisions:

	Parameter's explaination: 
	
*/
SET NOCOUNT ON

IF NOT EXISTS (SELECT 1 FROM match WITH (NOLOCK) WHERE matchid = @MatchID)
BEGIN
	SELECT @ErrCode = 100, @ErrMsg = 'Match ID doesn''t exist.'
	RETURN
END
IF EXISTS (SELECT 1 FROM match WITH (NOLOCK) WHERE matchid = @MatchID AND ruben = 1)
BEGIN
	SELECT @ErrCode = 101, @ErrMsg = 'You are not allowed to add super into a settled match.'
	RETURN
END

SELECT leagueid, eventdate, homeid, awayid
FROM match m WITH (NOLOCK)	
WHERE matchid = @MatchID	

GO
GRANT EXECUTE ON [dbo].[Acc_SMATurnoverMatchSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_SMATurnoverMatchSel] TO [vnteam]

--EXEC Acc_SMATurnoverMatchSel @MatchID = 4305925