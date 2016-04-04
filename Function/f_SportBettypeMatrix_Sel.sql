USE [bodb02]
GO
/****** Object:  UserDefinedFunction [dbo].[f_SportBettypeMatrix_Sel]    Script Date: 04/01/2016 02:50:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/****** Object:  User Defined Function dbo.f_SportBettypeMatrix_Sel    Script Date: 3/23/2016 2:46:17 PM ******/
ALTER FUNCTION [dbo].[f_SportBettypeMatrix_Sel]
(
	 @ProductID		TINYINT		 = 0
	,@SportType		SMALLINT	 = 0
	,@BetType		SMALLINT	 = 0
	,@IsLive		TINYINT		 = 2
	,@SubProduct	VARCHAR(500) = ''
	,@ProductPrefix VARCHAR(500) = ''
	,@IsTest		BIT			 = 0
) 
/*
	Creator: Percy	
	Date: 20160323
	Task: Get SportType_Bettype
	DB: DBAGE.bodb02, DBEXT.bodb02, DBACC.bodb02, DBEAS.bodb_EAS, DBPRO.bodb02, DBDWH.bodb02
		
	Revisions:
		
	Paramters Explanation:
 		@ProductID, @SportType, @BetType
			0	: get all
			<>0 : check condition
		@IsLive : check paramer
			0	: None-live
			1	: Live
			2	: None-live & Live
		@ProductPrefix:
			''  : get all
			<>'': Check ProductPrefix column on dbo.Product table
		@IsTest:
			1: Get all products and bettypes
			0: Get only products and bettypes which are not being tested
*/

RETURNS TABLE
RETURN
SELECT DISTINCT
	 ma.ProductID
	,ma.BetType
	,ma.EventType
	,ma.SubProduct
FROM dbo.SportBettypeMatrix ma WITH(NOLOCK)
INNER JOIN dbo.Products p WITH(NOLOCK)
	ON p.ProductID = ma.ProductID
WHERE   (@ProductID		= 0  OR  ma.ProductID	= @ProductID)
	AND (@SportType		= 0  OR  ma.SportType	= @SportType)
	AND (@BetType		= 0  OR  ma.BetType		= @BetType)			
	AND (@IsLive		= 2  OR  ma.IsLive		= @IsLive)
	AND (@SubProduct	= '' OR  ma.SubProduct	= @SubProduct)
	AND (@ProductPrefix = '' OR  p.ProductPrefix IN (SELECT val FROM strSplit(@ProductPrefix, ',')))
	AND (ma.IsTest		= 0	 OR  ma.IsTest		= @IsTest)
GO
GRANT VIEW DEFINITION ON [dbo].[f_SportBettypeMatrix_Sel] TO [bodbAdminNet] AS [dbo]
GO
GRANT SELECT ON [dbo].[f_SportBettypeMatrix_Sel] TO [bodbDownlineNet] AS [dbo]
GO
GRANT SELECT ON [dbo].[f_SportBettypeMatrix_Sel] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[f_SportBettypeMatrix_Sel] TO [vnteam] AS [dbo]