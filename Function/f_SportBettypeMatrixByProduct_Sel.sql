/****** Object:  UserDefinedFunction [dbo].[f_SportBettypeMatrixByProduct_Sel]    Script Date: 12/14/2016 2:08:35 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/****** Object:  User Defined Function dbo.f_SportBettypeMatrixByProduct_Sel    Script Date: 5/12/2016 11:24:09 AM ******/

CREATE FUNCTION [dbo].[f_SportBettypeMatrixByProduct_Sel]
(
	 @ProductID		VARCHAR(500) = ''
	,@IsTest		BIT			 = 0
) 
/*
	Creator: Paul	
	Date: 20161216
	Task: Get SportType_Bettype
	DB: DBAGE.bodb02
		
	Revisions:
		
	Paramters Explanation:
 		@ProductID: list of products
		@IsTest:
			1: Get all products and bettypes
			0: Get only products and bettypes which are not being tested
*/
RETURNS TABLE
RETURN
SELECT DISTINCT
	 ma.ProductID
	,ma.BetType
FROM dbo.SportBettypeMatrix ma WITH(NOLOCK)
	INNER JOIN dbo.Products p WITH(NOLOCK) ON p.ProductID = ma.ProductID
WHERE ',' + @ProductID + ',' LIKE '%,' + cast(p.ProductID as varchar(3)) + ',%'
	AND (ma.IsTest = 0 OR ma.IsTest = @IsTest)
GO


GRANT SELECT ON [dbo].[f_SportBettypeMatrixByProduct_Sel] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[f_SportBettypeMatrixByProduct_Sel] TO [bodbAdminNet] AS [dbo]
GO

GRANT SELECT ON [dbo].[f_SportBettypeMatrixByProduct_Sel] TO [bodbDownlineNet] AS [dbo]
GO

GRANT SELECT ON [dbo].[f_SportBettypeMatrixByProduct_Sel] TO [bodbDownlineNetView] AS [dbo]
GO

GRANT SELECT ON [dbo].[f_SportBettypeMatrixByProduct_Sel] TO [bodbExtAccNet] AS [dbo]
GO

GRANT SELECT ON [dbo].[f_SportBettypeMatrixByProduct_Sel] TO [bodbLicenseeNet] AS [dbo]
GO

GRANT SELECT ON [dbo].[f_SportBettypeMatrixByProduct_Sel] TO [bodbRMSNet] AS [dbo]
GO

GRANT SELECT ON [dbo].[f_SportBettypeMatrixByProduct_Sel] TO [dwrs] AS [dbo]
GO

GRANT SELECT ON [dbo].[f_SportBettypeMatrixByProduct_Sel] TO [vnteam] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[f_SportBettypeMatrixByProduct_Sel] TO [vnteam] AS [dbo]
GO