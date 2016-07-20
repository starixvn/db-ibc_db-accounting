USE [bodb_Age]
GO

ALTER FUNCTION [dbo].[GetAllGroupByCustId]
(
	@CustID INT
)

/*
	Creator: Percy
	Date: 20160720
	DBAGE.bodb_Age
	Remark: get all group by superId

	Revisions:
*/

RETURNS @CustGroup TABLE (NormalGroup NVARCHAR(MAX), ExtraPTGroup NVARCHAR(MAX))
AS
BEGIN
	DECLARE @GroupDate TABLE (GroupName NVARCHAR(100), FromDate DATETIME, ToDate DATETIME)
	DECLARE @OpenQuery NVARCHAR(MAX)
	SELECT  @OpenQuery = 
		'SELECT * FROM OPENQUERY(DBACC, ''SELECT GroupName,MIN(FromDate),MIN(ToDate) FROM Acc_GroupExtraPTSetting WITH(NOLOCK)
											WHERE SuperId = ' + CONVERT(NVARCHAR(20), @CustID) + ' GROUP BY GroupId, GroupName '')'
	INSERT INTO @GroupDate (GroupName, FromDate, ToDate)
	EXEC (@OpenQuery)

	;WITH CTE AS
	(
		SELECT
			c.CustID,
			CASE WHEN g.FromDate IS NULL THEN c.GroupName ELSE '' END AS Normal,
			CASE WHEN g.FromDate IS NULL THEN '' ELSE c.GroupName +','+CONVERT(VARCHAR(10), g.FromDate, 120)+','+CONVERT(NVARCHAR(1),IsPayOut) END AS Extra
		FROM
			dbo.Acc_CustGroup c WITH(NOLOCK)
			LEFT JOIN @GroupDate g ON c.GroupName = g.GroupName
		WHERE c.CustID = @CustID
	)
	INSERT INTO @CustGroup
	SELECT
		(SELECT STUFF((SELECT ';' + Normal FROM CTE FOR XML PATH('')), 1, 1, '')) AS NormalGroup,
		(SELECT STUFF((SELECT ';' + Extra  FROM CTE FOR XML PATH('')), 1, 1, '')) AS ExtraPTGroup
	FROM CTE
	GROUP BY CustID

	RETURN
END