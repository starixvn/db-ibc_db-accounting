ALTER PROCEDURE [dbo].[Acc_SMATurnoverIns]
	@UserName NVARCHAR(100),
	@MatchID INT,
	@MaxTurnover MONEY,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
/*
	Created: Elodie
	Date: 20130515
	Task : Add SMA turnover
	DB: DBTXN/bodb02

	Revisions:

	Parameter's explaination: 
	Example: EXEC Acc_SMATurnoverIns @UserName = '79AR', @MatchID = 4305908, @MaxTurnover = 10000
*/
SET NOCOUNT ON
BEGIN

	IF NOT EXISTS (SELECT 1 FROM custInfo WITH (NOLOCK) WHERE username = @UserName)
	BEGIN
		SELECT @ErrCode = 100, @ErrMsg = 'Invalid Username!'
		RETURN
	END

	IF EXISTS (SELECT 1 FROM custInfo WITH (NOLOCK) WHERE username = @UserName and roleid <> 4)
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'Invalid Username!'
		RETURN
	END

	IF NOT EXISTS (SELECT 1 FROM match WITH (NOLOCK) WHERE matchid = @MatchID)
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg = 'Match ID doesn''t exist.'
		RETURN
	END

	IF EXISTS (SELECT 1 FROM match WITH (NOLOCK) WHERE matchid = @MatchID AND ruben = 1)
	BEGIN
		SELECT @ErrCode = 103, @ErrMsg = 'You are not allowed to add super into a settled match.'
		RETURN
	END

	DECLARE @CustID INT

	SELECT @CustID = custid FROM custInfo WITH (NOLOCK) WHERE username = @UserName

	-- It has bet ticket for this match
	IF EXISTS (SELECT 1 FROM match WITH (NOLOCK) WHERE matchid = @MatchID AND eventstatus = 'running' AND ruben = 0)
	BEGIN
		DECLARE @TotalTurnover MONEY		
		SELECT @TotalTurnover = sum(actual_stake) FROM bettrans WITH (NOLOCK) WHERE matchid = @MatchID and srecommend = @CustID
		
		INSERT INTO DownlineTurnover_Setting (CustID, MatchID, MaxTurnover, TotalTurnover)
		VALUES (@CustID, @MatchID, @MaxTurnover, @TotalTurnover)
		
		UPDATE DBAGE.bodb02.dbo.DownlineTurnover_Setting
		SET TotalTurnover = @TotalTurnover
		WHERE CustID = @CustID AND matchid = @MatchID
	END
	-- It has not bet ticket for this match
	ELSE IF EXISTS (SELECT 1 FROM match WITH (NOLOCK) WHERE matchid = @MatchID AND eventstatus = 'closed' AND ruben = 0)
	BEGIN
		INSERT INTO DownlineTurnover_Setting (CustID, MatchID, MaxTurnover, TotalTurnover)
		VALUES (@CustID, @MatchID, @MaxTurnover, 0)
	END

END

GO
GRANT EXECUTE ON [dbo].[Acc_SMATurnoverIns] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_SMATurnoverIns] TO [vnteam]

