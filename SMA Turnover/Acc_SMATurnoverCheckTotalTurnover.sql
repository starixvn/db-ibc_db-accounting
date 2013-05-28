ALTER PROCEDURE [dbo].[Acc_SMATurnoverCheckTotalTurnover]
	@UserName NVARCHAR(100),
	@MatchID INT,
	@MaxTurnover MONEY,
	@Mode BIT,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
/*
	Created: Elodie
	Date: 20130515
	Task : Check if Max Turnover is less than or equal to current SMA turnover for insert/update case
	DB: DBAGE/bodb02

	Revisions:

	Parameter's explaination: 	
		@Mode:  0: check for insert case
				1: check for update case
	
*/
SET NOCOUNT ON

	DECLARE @CustID INT
	IF NOT EXISTS (SELECT 1 FROM custInfo WITH (NOLOCK) WHERE username = @UserName)
	BEGIN
		SELECT @ErrCode = 100, @ErrMsg = 'Invalid Username!'
		RETURN
	END
	SELECT @CustID = custid FROM custInfo WITH (NOLOCK) WHERE username = @UserName
	
	IF @Mode = 0
	BEGIN
		IF EXISTS (SELECT 1 FROM bettrans WITH (NOLOCK) WHERE matchid = @MatchID and srecommend = @CustID and statusID = 0)
		BEGIN
			DECLARE @TotalTurnover MONEY		
			SELECT @TotalTurnover = sum(actual_stake) FROM DBTXN.bodb02.dbo.bettrans WITH (NOLOCK) WHERE matchid = @MatchID and srecommend = @CustID and statusID = 0
			IF @MaxTurnover <= @TotalTurnover	
				SELECT @ErrCode = 101, @ErrMsg = 'Warning: Member will be unable to place bet if your new Max Turnover is less than or equal to current SMA turnover. Are you sure you want to proceed ?'				
		END	
	END
	ELSE
	BEGIN
		IF EXISTS (SELECT 1 FROM DownlineTurnover_Setting WITH (NOLOCK) WHERE matchid = @MatchID AND custID = @CustID AND TotalTurnover >= @MaxTurnover)
		BEGIN
			SELECT @ErrCode = 102, @ErrMsg = 'Warning: Member will be unable to place bet if your new Max Turnover is less than or equal to current SMA turnover. Are you sure you want to proceed ?'			
		END
	END	
	
GO
GRANT EXECUTE ON [dbo].[Acc_SMATurnoverCheckTotalTurnover] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_SMATurnoverCheckTotalTurnover] TO [vnteam]