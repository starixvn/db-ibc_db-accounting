USE bodb02
GO

ALTER FUNCTION [dbo].[f_Winlimit_GetProductSetting] ()
RETURNS @ProductSetting TABLE (ProductId TINYINT, ProductName VARCHAR(50), BetType SMALLINT, IsActive_SMA BIT, IsActive_Company BIT)
AS
/*
	Created: 2015107@Patrick	
	Task: Setting SMA & Company have check max winning or not
	DB: DBTRANS/BODB02
	Revisions:
			
	Parameters Explanation:	
*/
BEGIN
	INSERT INTO @ProductSetting(ProductId, ProductName, BetType, IsActive_SMA, IsActive_Company)
	(
		SELECT a.ProductId, p.ProductName, a.BetType, a.IsActive_SMA, a.IsActive_Company
		FROM (
			--SELECT 3 AS ProductId, 81 AS BetType, 0 AS IsActive_SMA, 1 AS IsActive_Company UNION
			SELECT 4 AS ProductId, 1101 AS BetType, 1 AS IsActive_SMA, 0 AS IsActive_Company UNION --LC
			--SELECT 5, 1201, 0, 1 UNION
			--SELECT 8, 1501, 0, 1 UNION
			SELECT 12, 1701, 1, 0 UNION
			SELECT 13, 2001, 0, 1 UNION
			SELECT 17, 2008, 0, 1
		) a INNER JOIN dbo.Products p WITH(NOLOCK) ON a.ProductId = p.ProductID
	)

	RETURN
END

GO
