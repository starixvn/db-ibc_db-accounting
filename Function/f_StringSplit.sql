/*<info serverAlias="DBCUST-CustDB,DBCUST-bodb_CustomerLog" executers="" isFunction="1"></info>*/
ALTER FUNCTION [dbo].[f_StringSplit]
(
	@String NVARCHAR(MAX),
	@Split	NVARCHAR(MAX)
)
RETURNS TABLE
AS

/*
	Created: 20180601@Percy
	DB: DBCUST-CustDB,DBCUST-bodb_CustomerLog : call string_split , built in function
		,DBLOG-bodb_CustomerLog,DBACC-bodb02,DBEXT-bodb02 : Keep old content
	Task: Core function - Split string

	Revisions:
		- 20180601@Percy: Initialize function [RedmineID: #87923]
		- 20181204@Paul: Deploy to DBCUST.CustDB [RedmineID: #104848]
		- 20190605@Paul: Deploy to DBCUST.bodb_CustomerLog, DBLOG.bodb_CustomerLog [Redmine: #113198]
		- 20220517@Eden: DBCUST - modify sp syntax to adapt with the SQL Server upgrade to 2019 [Redmine: #171831]  
*/

RETURN
	 SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 0)) AS Id, 
		value AS val 
	 FROM string_split(@String,@Split)  
GO