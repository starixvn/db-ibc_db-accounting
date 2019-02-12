USE [CustDB]
GO

 ALTER TRIGGER [dbo].[Acc_GroupExtraPTSetting_INSERT] ON [dbo].[Acc_GroupExtraPTSetting] 
 AFTER INSERT 
 AS

/*  
	Created:
	DB: DBCUST.CUSTDB
  
	Revisions:
		- 20180831@Sophia: Copy data from Acc_GroupExtraPTSetting to Acc_GroupExtraCommRateSetting for Poker Games [redmine: #100168]
	
*/

BEGIN
	SET NOCOUNT ON	
	
	INSERT INTO dbo.Acc_GroupExtraCommRateSetting 
	( 
		SuperId,
		GroupId,
		GroupName,
		ProductId,
		Sporttype,
		SubProduct,
		ExtraCommRate,
		FromDate,
		ToDate
	)
	SELECT
		SuperId,
		GroupId,
		GroupName,
		ProductId,
		Sporttype,
		SubProduct,
		ExtraPT,
		FromDate,
		ToDate
	FROM INSERTED
	WHERE ProductId = 33
END

