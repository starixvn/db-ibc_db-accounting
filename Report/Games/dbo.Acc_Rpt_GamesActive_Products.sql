USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Acc_Rpt_GamesActive_Products]    Script Date: 09/08/2015 14:48:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER  PROCEDURE [dbo].[Acc_Rpt_GamesActive_Products]   
 
AS  
/*
 Created: Jim
 Task : Get Product List for Report Number of Active Game
 DB: DBAGE/bodb02  
 Original:  
  
 Revisions:
*/
SELECT
	ProductID
	,ProductName
FROM dbo.Products WITH (NOLOCK)
WHERE ProductID IN (3,6,7,4,11,12,13,14,15)
UNION ALL
SELECT
	CONVERT(INT,-1) ProductID
	,'MG-SuperLive' ProductName
ORDER BY ProductID ASC
 
 GO
GRANT EXECUTE ON [dbo].Acc_Rpt_GamesActive_Products  TO [bodbAdminNet]  
GO
GRANT VIEW DEFINITION ON [dbo].Acc_Rpt_GamesActive_Products  TO [vnteam]  
