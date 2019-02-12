USE [CustDB]
GO
 
ALTER TRIGGER [dbo].[Acc_GroupExtraPTSetting_DELETE] ON [dbo].[Acc_GroupExtraPTSetting] 
AFTER DELETE 
AS

/*  
	Created:
	DB: DBCUST.CUSTDB
  
	Revisions:
		- 20180831@Sophia: clone data from Acc_GroupExtraPTSetting to Acc_GroupExtraCommRateSetting for Poker Games [redmine: #100168]
	
*/ 
BEGIN
	SET NOCOUNT ON
	
		DELETE e
		FROM dbo.Acc_GroupExtraCommRateSetting e WITH (ROWLOCK)		
		WHERE EXISTS (
				SELECT 1 FROM DELETED d 
				WHERE e.SuperId = d.SuperId
					AND e.GroupId = d.GroupId
					AND e.ProductId = d.ProductId
					AND e.Sporttype = d.Sporttype
					AND e.SubProduct = d.SubProduct
					AND e.FromDate = d.FromDate
					AND e.ToDate = d.ToDate
					AND d.ProductId = 33
					)
			 AND e.ProductId = 33		
 
END
