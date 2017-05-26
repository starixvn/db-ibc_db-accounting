USE [bodb_Age]
GO

ALTER PROCEDURE [dbo].[Acc_CustGroupSelExtraPTGroupByCustID]
	@CustID INT
AS
/*
	Creator: Percy
	Date: 2016-07-25
	Task: Select ExtraPT Group by SuperID
	DB: DBAGE.bodb_Age

	Revisions:
		- 20170413@Percy: Change way get to-be-primary group [RedmineID: #74292]

*/
BEGIN
	SET NOCOUNT ON

	DECLARE @today DATETIME
	SELECT  @today = CONVERT(DATE, GETDATE())

	DECLARE @GroupExtraPT TABLE (GroupId INT, GroupName VARCHAR(50), EffectiveDate DATETIME, [Primary] BIT)
	DECLARE @SQL NVARCHAR(MAX)
	SELECT  @SQL = 'SELECT * FROM OPENQUERY(DBACC, ''SELECT GroupId, GroupName, EffectiveDate, [Primary] FROM bodb_Acc.dbo.f_GetAllGroupExtraPTByCustId(' + CONVERT(NVARCHAR(15), @CustID) + ')'')'

	INSERT INTO @GroupExtraPT (GroupId, GroupName, EffectiveDate, [Primary])
	EXEC (@SQL)

	SELECT
		c.GroupName,
		CASE WHEN e.[Primary] = 1 THEN e.EffectiveDate ELSE NULL END AS EffectiveDate,
		e.[Primary] AS IsPrimary
	FROM
		(
			SELECT GroupName FROM dbo.Acc_CustGroup WITH(NOLOCK) WHERE CustID = @CustID
			UNION SELECT 'No Extra PT'
		) c
		INNER JOIN @GroupExtraPT e ON c.GroupName = e.GroupName
	ORDER BY CASE WHEN e.GroupId = 0 THEN 0 ELSE 1 END, e.GroupName
END
GO

GRANT EXECUTE ON [dbo].[Acc_CustGroupSelExtraPTGroupByCustID] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustGroupSelExtraPTGroupByCustID] TO [vnteam]
GO