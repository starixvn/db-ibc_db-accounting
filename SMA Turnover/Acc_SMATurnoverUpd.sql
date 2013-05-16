ALTER PROCEDURE [dbo].[Acc_SMATurnoverUpd]
	@CustID INT,
	@MatchID INT,
	@MaxTurnover MONEY,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
/*
	Created: Elodie
	Date: 20130515
	Task : Update max turnover for SMA
	DB: DBTXN/bodb02

	Revisions:

	Parameter's explaination: 
	
*/
SET NOCOUNT ON
BEGIN
	IF EXISTS (SELECT 1 FROM match WITH (NOLOCK) WHERE matchid = @MatchID AND ruben = 1)
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'You are not allowed to update max turnover of a settled match.'
		RETURN
	END

	UPDATE DownlineTurnover_Setting WITH (ROWLOCK,UPDLOCK)
	SET MaxTurnover = @MaxTurnover
	WHERE CustID = @CustID AND matchid = @MatchID
END

GO
GRANT EXECUTE ON [dbo].[Acc_SMATurnoverUpd] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_SMATurnoverUpd] TO [vnteam]