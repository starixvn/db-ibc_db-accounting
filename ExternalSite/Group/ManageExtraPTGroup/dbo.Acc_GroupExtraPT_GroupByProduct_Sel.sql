/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [CustDB]
GO

ALTER PROCEDURE [dbo].[Acc_GroupExtraPT_GroupByProduct_Sel]
	@ProductId TINYINT = 0 -- all product
AS

/*
	Created by: Percy
	Date: 2017-04-13
	DB: DBCUST.CustDB
	Task: Manage Extra PT Group - Select group by product [RedmineID: #74292]

	Revisions:
		- 20170926@Percy: Move this SP from DBACC.bodb_ACC to DBCUST.CustDB [RedmineID: #83600]

	Param's Explanation:
*/

BEGIN
	SET NOCOUNT ON

	SELECT DISTINCT
		gp.GroupId, gp.GroupName,
		gp.ProductID, p.ProductName,
		gp.ExtraPT,
		gp.FromDate AS EffectiveDate, gp.ToDate AS EndDate,
		CASE WHEN gp.FromDate <= CONVERT(DATE, GETDATE()) THEN 0 ELSE 1 END AS IsAllowDeleted
	FROM dbo.Acc_GroupExtraPT_Product gp WITH(NOLOCK)
		INNER JOIN DBTXN.bodb02.dbo.Products p WITH(NOLOCK) ON gp.ProductID = p.ProductID
	WHERE
		gp.Sporttype = 0 AND gp.SubProduct = ''
		AND (
			@ProductId = 0
			OR gp.ProductId = @ProductId
		)
		AND gp.ToDate >= CONVERT(DATE, GETDATE())
	ORDER BY gp.GroupId, gp.ProductID, gp.FromDate
END
GO