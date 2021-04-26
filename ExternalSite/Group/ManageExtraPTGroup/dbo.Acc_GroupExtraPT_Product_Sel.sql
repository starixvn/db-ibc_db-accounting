/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_GroupExtraPT_Product_Sel]
	@IsExtra BIT = 0
AS

/*
	Created by: Percy
	Date: 2017-04-13
	DB: DBACC.bodb_ACC -> DBCUST.CustDB
	Task: Manage Extra PT Group - Select offer product list [RedmineID: #74292]

	Revisions:
		- 20170926@Percy: Move table dbo.Acc_GroupExtraPT_Product from DBACC.bodb_ACC to DBCUST.CustDB [RedmineID: #83600]
		- 20200805@Sophia: Edit mode IsExtra = 1, to shwo PP [RedmineID: #138483]
		- 20210426@Sol: Alpha/NAP - Migrate from DBACC to DBCust - [Redmine: #154041]
	Param's Explanation:
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @Product TABLE (ProductId TINYINT)
	
	IF @IsExtra = 0
	BEGIN
		INSERT INTO @Product (ProductId)
		SELECT ProductId FROM dbo.Acc_DWLList WITH(NOLOCK)
		WHERE IsDeleted = 0
	END
	ELSE
	BEGIN
		INSERT INTO @Product (ProductId)
		SELECT DISTINCT ProductId FROM dbo.Acc_GroupExtraPT_Product WITH (NOLOCK)

		DELETE p
		FROM @Product p
			LEFT JOIN dbo.Acc_DWLList a WITH(NOLOCK) ON p.ProductId = a.ProductId AND a.IsDeleted = 0
		WHERE  a.ProductId IS NULL
				
	END
	
	SELECT p.ProductID, p.ProductName
	FROM DB02.bodb02.dbo.Products p WITH (NOLOCK)
	WHERE EXISTS (SELECT 1 FROM @Product gp WHERE p.ProductID = gp.ProductID)
	ORDER BY p.ProductID
END
GO