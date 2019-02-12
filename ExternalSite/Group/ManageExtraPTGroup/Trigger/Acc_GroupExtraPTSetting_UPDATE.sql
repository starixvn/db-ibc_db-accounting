USE [CustDB]
GO

ALTER TRIGGER [dbo].[Acc_GroupExtraPTSetting_UPDATE] ON [dbo].[Acc_GroupExtraPTSetting] 
AFTER UPDATE 
AS

/*  
	Created:
	DB: DBCUST.CUSTDB
  
	Revisions:
		- 20180831@Sophia: Copy data from Acc_GroupExtraPTSetting to Acc_GroupExtraCommRateSetting for Poker Games [redmine: #100168]
	
*/ 
BEGIN
	SET NOCOUNT ON

		UPDATE e 
		SET ExtraCommRate = i.ExtraPT,
			FromDate= i.FromDate,
			ToDate = i.ToDate
		FROM dbo.Acc_GroupExtraCommRateSetting e WITH (ROWLOCK)
			INNER JOIN INSERTED i ON e.SuperId = i.SuperId
					AND e.GroupId = i.GroupId
					AND e.ProductId = i.ProductId
					AND e.Sporttype = i.Sporttype
					AND e.SubProduct = i.SubProduct
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
			 AND i.ProductId = 33		
 
END

