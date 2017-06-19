USE [bodb02]
GO

ALTER PROCEDURE [dbo].[Acc_CheckProcessingData]
	@EndProcessingTime	DATETIME = NULL OUTPUT
AS

/*
	Created by Percy
	DB: DBTXN.bodb02
	Task: Check data processing due to Move Bet/Balance Up process

	Revisions:
		- 20170609@Percy: Create new [RedmineID: #78487]
*/

BEGIN
	SET NOCOUNT ON

	SELECT  @EndProcessingTime = NULL
	
	DECLARE @CurrentDateTime DATETIME
	SELECT  @CurrentDateTime = GETDATE()

	DECLARE @Config_EndTime VARCHAR(50), @IsArchivingBet VARCHAR(1), @IsMovingBet VARCHAR(1)

	SELECT  @IsArchivingBet = VValue FROM dbo.SystemSettings WITH(NOLOCK) WHERE VName = 'isArchivingBet' -- BU flags
	SELECT  @IsArchivingBet = ISNULL(@IsArchivingBet, '0')

	SELECT  @IsMovingBet = VValue FROM dbo.SystemSettings WITH(NOLOCK) WHERE VName = 'isMovingBet' -- MB flags
	SELECT  @IsMovingBet = ISNULL(@IsMovingBet, '0')

	--set default value
	IF @IsArchivingBet = '1' OR @IsMovingBet = '1'
	BEGIN
		SELECT @EndProcessingTime = DATEADD(MINUTE, 15, @CurrentDateTime) -- default end time = currentime + 15 mins
	END
	-- get end time from config
	SELECT @Config_EndTime = VValue FROM dbo.SystemSettings WITH(NOLOCK) WHERE VName = 'schDataProcessingEndTime'

	IF CONVERT(DATETIME, @Config_EndTime) > @CurrentDateTime
	BEGIN
		SELECT @EndProcessingTime = CONVERT(DATETIME, @Config_EndTime)
	END
END
GO
GRANT EXECUTE ON [dbo].[Acc_CheckProcessingData] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Acc_CheckProcessingData] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Acc_CheckProcessingData] TO [bodbLicenseeNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CheckProcessingData] TO [vnteam] AS [dbo]
GO