/*<info serverAlias="DBTXN-bodb02" executers="bodbDownlineNet,bodbDownlineNetView,bodbLicenseeNet" viewers="" isFunction="0" isNested="1"></info>*/
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
		- 20171220@Patrick: check data ready on replicated servers also [RedmineID: #88152]
		- 20180323@Percy: Enhancement notification [RedmineID: #92391]
*/

BEGIN
	SET NOCOUNT ON

	SELECT  @EndProcessingTime = NULL
	
	DECLARE @CurrentDateTime DATETIME
	SELECT  @CurrentDateTime = GETDATE()

	DECLARE @Config_EndTime VARCHAR(50), @IsArchivingBet VARCHAR(1), @IsMovingBet VARCHAR(1)
		, @IsArchivingBet_Local_DB053 VARCHAR(1), @IsMovingBet_Local_DB053 VARCHAR(1)
		, @IsArchivingBet_Local_DB052 VARCHAR(1), @IsMovingBet_Local_DB052 VARCHAR(1)
		, @IsArchivingBet_Local_DB06 VARCHAR(1), @IsMovingBet_Local_DB06 VARCHAR(1)

	SELECT  @IsArchivingBet = VValue FROM dbo.SystemSettings WITH(NOLOCK) WHERE VName = 'isArchivingBet' -- BU flags
	SELECT  @IsArchivingBet = ISNULL(@IsArchivingBet, '0')

	SELECT  @IsMovingBet = VValue FROM dbo.SystemSettings WITH(NOLOCK) WHERE VName = 'isMovingBet' -- MB flags
	SELECT  @IsMovingBet = ISNULL(@IsMovingBet, '0')

	--//DB053
	SELECT @IsArchivingBet_Local_DB053 = VValue FROM DBAGE.bodb02.dbo.SystemSettings WITH(NOLOCK) WHERE VName = 'isArchivingBet_Local'
	SELECT @IsArchivingBet_Local_DB053 = ISNULL(@IsArchivingBet_Local_DB053, '0')
	SELECT @IsMovingBet_Local_DB053 = VValue FROM DBAGE.bodb02.dbo.SystemSettings WITH(NOLOCK) WHERE VName = 'isMovingBet_Local'
	SELECT @IsMovingBet_Local_DB053 = ISNULL(@IsMovingBet_Local_DB053, '0')

	--//DB06
	SELECT @IsArchivingBet_Local_DB06 = VValue FROM DBACC.bodb02.dbo.SystemSettings WITH(NOLOCK) WHERE VName = 'isArchivingBet_Local'
	SELECT @IsArchivingBet_Local_DB06 = ISNULL(@IsArchivingBet_Local_DB06, '0')
	SELECT @IsMovingBet_Local_DB06 = VValue FROM DBACC.bodb02.dbo.SystemSettings WITH(NOLOCK) WHERE VName = 'isMovingBet_Local'
	SELECT @IsMovingBet_Local_DB06 = ISNULL(@IsMovingBet_Local_DB06, '0')

	--//DB052
	SELECT @IsArchivingBet_Local_DB052 = VValue FROM DBLIC.bodb02.dbo.SystemSettings WITH(NOLOCK) WHERE VName = 'isArchivingBet_Local'
	SELECT @IsArchivingBet_Local_DB052 = ISNULL(@IsArchivingBet_Local_DB052, '0')
	SELECT @IsMovingBet_Local_DB052 = VValue FROM DBLIC.bodb02.dbo.SystemSettings WITH(NOLOCK) WHERE VName = 'isMovingBet_Local'
	SELECT @IsMovingBet_Local_DB052 = ISNULL(@IsMovingBet_Local_DB052, '0')

	-- checking condition
	IF @IsArchivingBet = '0' AND @IsMovingBet = '0'
		AND @IsArchivingBet_Local_DB053 = '0' AND @IsMovingBet_Local_DB053 = '0'
		AND @IsArchivingBet_Local_DB052 = '0' AND @IsMovingBet_Local_DB052 = '0'
		AND @IsArchivingBet_Local_DB06 = '0' AND @IsMovingBet_Local_DB06 = '0'
	BEGIN -- done MB/BU process
		SELECT @EndProcessingTime = NULL
	END
	ELSE
	BEGIN
		-- get end time from config
		SELECT @Config_EndTime = VValue FROM dbo.SystemSettings WITH(NOLOCK) WHERE VName = 'schDataProcessingEndTime'
		
		IF CONVERT(DATETIME, @Config_EndTime) > @CurrentDateTime
		BEGIN
			SELECT @EndProcessingTime = CONVERT(DATETIME, @Config_EndTime)
		END
		ELSE
		BEGIN
			-- extend time of config: 15 mins
			SELECT @EndProcessingTime = DATEADD(MINUTE, 15, CONVERT(DATETIME, @Config_EndTime))

			UPDATE dbo.SystemSettings WITH (ROWLOCK, UPDLOCK)
			SET VValue = CONVERT(VARCHAR(50), @EndProcessingTime, 121)
			WHERE VName = 'schDataProcessingEndTime'
		END
	END
END
GO