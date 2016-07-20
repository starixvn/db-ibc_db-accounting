USE [bodb_Age]
GO

ALTER PROCEDURE dbo.Acc_CustGroupUpdPrimaryExtraPTGroup
	@CustID			INT,
	@GroupName		VARCHAR(50),
	@EffectiveDate	DATETIME,
	@ErrCode		TINYINT = 0 OUTPUT,
	@ErrMsg			NVARCHAR(1000) OUTPUT
AS
/*
	Creator: Percy
	Date: 20160721
	Task: Change Primary ExtraPTGroup
	DB: DBAGE.bodb_Age

	Revisions:
*/
BEGIN
	SET NOCOUNT ON

	IF @EffectiveDate < CONVERT(DATE, GETDATE())
		RETURN

	-- Update table Acc_GroupExtraPTSetting
	EXEC DBACC.bodb_ACC.dbo.Acc_GroupExtraPTSetting_Upd
		@CustID = @CustID,
		@GroupName = @GroupName,
		@EffectiveDate = @EffectiveDate,
		@ErrCode = @ErrCode OUTPUT,
		@ErrMsg = @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN

	-- Update table Acc_CustGroup
	IF @EffectiveDate = CONVERT(DATE, GETDATE()) -- set primary
	BEGIN
		UPDATE dbo.Acc_CustGroup
		SET EffectiveDate = CASE WHEN GroupName = @GroupName THEN @EffectiveDate ELSE NULL END
		WHERE CustID = @CustID
		
	END
	ELSE -- to be primary
	BEGIN
		UPDATE dbo.Acc_CustGroup
		SET EffectiveDate = CASE WHEN GroupName = @GroupName THEN @EffectiveDate ELSE NULL END
		WHERE CustID = @CustID AND EffectiveDate > CONVERT(DATE, GETDATE())
	END

END
GO

GRANT EXECUTE ON [dbo].[Acc_CustGroupUpdPrimaryExtraPTGroup] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustGroupUpdPrimaryExtraPTGroup] TO [vnteam]
GO