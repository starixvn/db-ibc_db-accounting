/*<info serverAlias="DBACC-bodb_ACC" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/

USE [bodb_ACC]
GO

ALTER PROCEDURE [dbo].[Acc_GroupExtraPT_GroupByProduct_Sel]
	@ProductId TINYINT = 0 -- all product
AS

/*
	Created by: Percy
	Date: 2017-04-13
	DB: DBACC.bodb_ACC
	Task: Manage Extra PT Group - Select group by product [RedmineID: #74292]

	Revisions:

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
		INNER JOIN bodb02.dbo.Products p WITH(NOLOCK) ON gp.ProductID = p.ProductID
	WHERE
		gp.Sporttype = 0 AND gp.SubProduct = ''
		AND (
			@ProductId = 0
			OR gp.ProductId = @ProductId
		)
		AND gp.ToDate >= CONVERT(DATE, GETDATE())
	ORDER BY gp.GroupId, gp.ProductID, gp.FromDate
END