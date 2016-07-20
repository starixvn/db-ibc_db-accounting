USE [bodb_Age]
GO

ALTER PROCEDURE dbo.Acc_CustGroupSelExtraPTGroupByCustID
	@CustID INT
AS
/*
	Creator: Percy
	Date: 2016-07-25
	Task: Select ExtraPT Group by SuperID
	DB: DBAGE.bodb_Age

	Revisions:

*/
BEGIN
	SET NOCOUNT ON

	DECLARE @today DATETIME
	SELECT  @today = CONVERT(DATE, GETDATE())

	DECLARE @GroupExtraPT TABLE (GroupName NVARCHAR(100), OrderID SMALLINT)

	INSERT INTO @GroupExtraPT (GroupName, OrderID)
	SELECT GroupName, 10 FROM OPENQUERY(DBACC, 'SELECT GroupName FROM bodb_Acc.dbo.Acc_DWLList_ExtraPT WITH(NOLOCK)')
	UNION SELECT N'No Extra PT', 1

	SELECT
		c.GroupName,
		CASE WHEN c.EffectiveDate = (SELECT MAX(EffectiveDate) FROM dbo.Acc_CustGroup WITH(NOLOCK) WHERE EffectiveDate <= @today AND CustID = c.CustID) THEN c.EffectiveDate ELSE NULL END AS EffectiveDate
	FROM
		dbo.Acc_CustGroup c WITH(NOLOCK)
		INNER JOIN @GroupExtraPT e ON c.GroupName = e.GroupName
	WHERE c.CustID = @CustID
	ORDER BY e.OrderID, e.GroupName
END
GO

GRANT EXECUTE ON [dbo].[Acc_CustGroupSelExtraPTGroupByCustID] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustGroupSelExtraPTGroupByCustID] TO [vnteam]
GO