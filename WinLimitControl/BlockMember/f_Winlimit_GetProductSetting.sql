
ALTER FUNCTION [dbo].[f_Winlimit_GetProductSetting] ()
RETURNS @ProductSetting TABLE (ProductId TINYINT, ProductName VARCHAR(50), BetType SMALLINT, IsActive_SMA BIT, IsActive_Company BIT)
AS
/*
	Created: 2015107@Patrick	
	Task: Setting SMA & Company have check max winning or not
	DB: DBTRANS/BODB02; DBCUST/CUSTDB
	Revisions:
		- 20151224@Patrick: Support RnG Casino [Redmine: #49803]
		- 20160511@Dominic: Support Voidbridge [Redmine: #57151]
		- 20160524@Helen: Support OneRnG [Redmine: #57680]
		- 20161018@Winnie: Support Fishing World [Redmine: #58901]
	Parameters Explanation:	
*/
BEGIN
	INSERT INTO @ProductSetting(ProductId, ProductName, BetType, IsActive_SMA, IsActive_Company)
	(
		SELECT a.ProductId, p.ProductName, a.BetType, a.IsActive_SMA, a.IsActive_Company
		FROM (
			--SELECT 3 AS ProductId, 81 AS BetType, 0 AS IsActive_SMA, 1 AS IsActive_Company UNION
			SELECT 4 AS ProductId, 1101 AS BetType, 1 AS IsActive_SMA, 0 AS IsActive_Company UNION --LC
			SELECT 6, 2101, 1, 1 UNION
			--SELECT 8, 1501, 0, 1 UNION
			SELECT 12, 1701, 1, 0 UNION
			SELECT 13, 2001, 0, 1 UNION
			SELECT 17, 2008, 0, 1 UNION ALL
			SELECT 22, 4001, 1, 1 UNION ALL
			SELECT 24, 1011, 1, 1
		) a INNER JOIN DBPRO.bodb02.dbo.Products p WITH(NOLOCK) ON a.ProductId = p.ProductID
	)

	RETURN
END

