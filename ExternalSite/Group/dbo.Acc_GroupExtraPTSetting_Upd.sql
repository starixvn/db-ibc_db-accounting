USE [bodb_ACC]
GO

ALTER PROCEDURE dbo.Acc_GroupExtraPTSetting_Upd
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

	DECLARE @FromDate DATETIME
	SELECT  @FromDate = MIN(FromDate) FROM dbo.Acc_GroupExtraPTSetting WITH(NOLOCK) WHERE SuperId = @CustID AND GroupName = @GroupName AND @EffectiveDate BETWEEN FromDate AND ToDate

	IF @FromDate IS NOT NULL
	BEGIN
		SELECT
			@ErrCode = 101,
			@ErrMsg = N'The group ' + @GroupName + N' has already been the primary group since ' + CONVERT(NVARCHAR(10), @FromDate, 101) 
		RETURN
	END
	
	-- Update old setting
	DECLARE @Curr_Primary TABLE (GroupName VARCHAR(50), IsDeleted BIT)
	INSERT INTO @Curr_Primary (GroupName, IsDeleted)
	SELECT DISTINCT
		GroupName,
		CASE WHEN FromDate >= @EffectiveDate THEN 1 ELSE 0 END
	FROM dbo.Acc_GroupExtraPTSetting WITH(NOLOCK) WHERE SuperId = @CustID AND @EffectiveDate BETWEEN FromDate AND ToDate

	UPDATE dbo.Acc_GroupExtraPTSetting
	SET ToDate = DATEADD(DAY, -1, @EffectiveDate)
	WHERE SuperId = @CustID AND GroupName IN (SELECT GroupName FROM @Curr_Primary WHERE IsDeleted = 0)

	DELETE dbo.Acc_GroupExtraPTSetting
	WHERE SuperId = @CustID AND GroupName IN (SELECT GroupName FROM @Curr_Primary WHERE IsDeleted = 1)

	-- Insert new setting
	DECLARE @GroupID INT
	SELECT  @GroupID = GroupID FROM dbo.Acc_DWLList_ExtraPT WITH(NOLOCK) WHERE GroupName = @GroupName

	INSERT INTO dbo.Acc_GroupExtraPTSetting (SuperId, GroupId, GroupName, ProductId, Sporttype, SubProduct, ExtraPT, FromDate, ToDate)
	SELECT DISTINCT @CustID, @GroupID, @GroupName, ProductId, Sporttype, SubProduct, ExtraPT, @EffectiveDate, '99991231'
	FROM dbo.Acc_GroupExtraPTSetting WITH(NOLOCK) WHERE SuperId = @CustID
END
GO

GRANT EXECUTE ON [dbo].[Acc_GroupExtraPTSetting_Upd] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_GroupExtraPTSetting_Upd] TO [vnteam]
GO