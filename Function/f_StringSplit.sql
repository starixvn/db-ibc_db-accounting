/*<info serverAlias="DBEXT-bodb02,DBCUST-CustDB,DBCUST-bodb_CustomerLog,DBLOG-bodb_CustomerLog,DBACC-bodb02" executers="" isFunction="1"></info>*/
ALTER FUNCTION [dbo].[f_StringSplit]
(
	@String NVARCHAR(MAX),
	@Split	NVARCHAR(MAX)
)
RETURNS TABLE
AS

/*
	Created: 20180601@Percy
	DB: DBEXT-bodb02, DBCUST-CustDB
	Task: Core function - Split string

	Revisions:
		- 20180601@Percy: Initialize function [RedmineID: #87923]
		- 20181204@Paul: Deploy to DBCUST.CustDB [RedmineID: #104848]
		- 20190605@Paul: Deploy to DBCUST.bodb_CustomerLog, DBLOG.bodb_CustomerLog [Redmine: #113198]
*/

RETURN
	WITH CTE_Split AS
	(
		SELECT 1 AS Id, CONVERT(BIGINT, 0) AS Index1, CHARINDEX(@Split, @String) AS Index2
		UNION ALL
		SELECT Id + 1, Index2 + LEN(@Split), CHARINDEX(@Split, @String, Index2 + LEN(@Split))
		FROM CTE_Split
		WHERE Index2 > 0
	)
	SELECT Id, SUBSTRING(@String, Index1, COALESCE(NULLIF(Index2, 0), LEN(@string) + 1) - Index1) AS val
	FROM CTE_Split
GO