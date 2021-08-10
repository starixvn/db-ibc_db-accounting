/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustGroupSelExtraPTGroupByCustID]
	@CustID			INT
	,@NoOfMember	INT = 0 OUTPUT
AS
/*
	Creator: Percy
	Date: 2016-07-25
	Task: Select ExtraPT Group by SuperID
	DB: DBACC/bodb02

	Revisions:
		- 20170413@Percy: Change way get to-be-primary group [RedmineID: #74292]
		- 20170926@Percy: Move this SP from DBAGE.bodb_Age to DBACC.bodb02 [RedmineID: #83600]
		- 20181122@Elodie: DB053/bodb_Age Migration [Redmine:#104770]
		- 20191216@Percy: Output NoOfMember param [RedmineID: #125418]

*/
BEGIN
	SET NOCOUNT ON

	DECLARE @today DATETIME
	SELECT  @today = CONVERT(DATE, GETDATE())

	DECLARE @GroupExtraPT TABLE (OrderId TINYINT, GroupName VARCHAR(50), EffectiveDate DATETIME, IsPrimary BIT)

	-- No Extra PT
	INSERT INTO @GroupExtraPT (OrderId, GroupName, EffectiveDate, IsPrimary)
	SELECT 1 AS OrderId, 'No Extra PT', NULL, 0

	-- Extra PT Group
	INSERT INTO @GroupExtraPT (OrderId, GroupName, EffectiveDate, IsPrimary)
	SELECT 2 AS OrderId, GroupName, MIN(FromDate), CASE WHEN FromDate <= @today THEN 1 ELSE 0 END
	FROM dbo.Acc_GroupExtraPTSetting WITH (NOLOCK)
	WHERE SuperId = @CustID
		AND ToDate >= @today
	GROUP BY GroupName, CASE WHEN FromDate <= @today THEN 1 ELSE 0 END

	IF NOT EXISTS (SELECT 1 FROM @GroupExtraPT WHERE IsPrimary = 1)
	BEGIN
		DECLARE @NoExtraPTDate DATETIME
		SELECT  @NoExtraPTDate = DATEADD(DAY, 1, MAX(ToDate)) FROM dbo.Acc_GroupExtraPTSetting WITH (NOLOCK) WHERE SuperId = @CustID AND ToDate < @today
		
		IF @NoExtraPTDate IS NULL
			SELECT @NoExtraPTDate = CONVERT(DATE, CreatDate) FROM dbo.Customer WITH (NOLOCK) WHERE CustId = @CustID

		UPDATE @GroupExtraPT SET EffectiveDate = @NoExtraPTDate	WHERE GroupName = 'No Extra PT'
	END

	-- Get number of members belong to super
	SELECT @NoOfMember = COUNT(1) FROM dbo.Customer WITH (NOLOCK) WHERE srecommend = @CustID AND roleid = 1

	SELECT OrderId, GroupName, EffectiveDate, IsPrimary
	FROM @GroupExtraPT
	ORDER BY OrderId, GroupName
END
GO