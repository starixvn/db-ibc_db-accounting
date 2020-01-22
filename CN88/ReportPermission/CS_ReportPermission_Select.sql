USE [CustDB]  
GO

CREATE PROCEDURE [dbo].[CS_ReportPermission_SELECT]

AS
/*
	Created: Malcolm
	Date: 2020-01-21
	Task:   Configuration for CN88 Headlines to view all periods - [Redmine: #127520]
	DB: DBCUST/CustDB

	Revisions:
		- 20200122@Malcolm:  Configuration for CN88 Headlines to view all periods - [Redmine: #127520]
	Parameter's explaination:
*/
BEGIN
    SET NOCOUNT ON 
	SELECT  cu.username, cu.firstname, cu.lastname, cu.currency,
			CASE 
			   WHEN cs.IsViewAllPeriod IS NULL THEN 0 
			ELSE cs.IsViewAllPeriod END AS [IsViewAllPeriod]
	FROM dbo.Customer cu WITH(NOLOCK)
		LEFT JOIN dbo.CS_ReportPermission cs WITH(NOLOCK) ON cu.custid = cs.CustID  
	WHERE cu.roleid = 0	
	ORDER BY cu.username ASC
	END
GO


