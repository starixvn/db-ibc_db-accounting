USE [bodb02]
GO
ALTER  PROCEDURE [dbo].Acc_Rpt_GamesActive_Products   
 
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
WHERE ProductID IN (3,6,7,4,11,12,14)
UNION ALL
SELECT
	CONVERT(INT,0) ProductID
	,'MG-SuperLive' ProductName
ORDER BY ProductID ASC
 
GO
GRANT EXECUTE ON [dbo].Acc_Rpt_GamesActive_Products  TO [bodbAdminNet]  
GO
GRANT VIEW DEFINITION ON [dbo].Acc_Rpt_GamesActive_Products  TO [vnteam]  