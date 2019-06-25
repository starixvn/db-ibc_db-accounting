/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet,bodbDownlineNet" isFunction="0" isNested="1"></info>*/
USE [CustDB]
GO

ALTER PROCEDURE [dbo].[CS_GroupExtraPT_Sel]
	@CustID			INT    
AS

/*
	Creator: 20190620@Sophia	
	Task: CN88 - Select ExtraPT Group Setting of Super
	DB: DBCUST.CustDB 
	
	Revisions:
		- 20190620@Sophia: initial SP[RedmineID: #114912]  
	
	Param's Explanation:
		 
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @today DATETIME 
	SELECT  @today = CONVERT(DATE, GETDATE()) 
	
	SELECT DISTINCT
		'Current' AS Type,
		GroupId, 
		GroupName,
		ProductID, 
		ExtraPT,
		FromDate AS EffectiveDate, 
		ToDate AS EndDate		
	FROM dbo.Acc_GroupExtraPTSetting WITH(NOLOCK) 
	WHERE
		SuperID = @CustID
		AND ProductID IN (1, 3)   -- SB and Non-sports (Get represent Number game)
		AND Sporttype = 0 AND SubProduct = ''
		AND @Today BETWEEN FromDate AND ToDate
	
	UNION ALL
	SELECT DISTINCT
		'New' AS Type,
		GroupId, 
		GroupName,
		ProductID, 
		ExtraPT,
		FromDate AS EffectiveDate, 
		ToDate AS EndDate		
	FROM dbo.Acc_GroupExtraPTSetting WITH(NOLOCK) 
	WHERE
		SuperID = @CustID
		AND ProductID IN (1, 3)   -- SB and Non-sports (Get represent Number game)
		AND Sporttype = 0 AND SubProduct = ''
		AND FromDate > @Today		
	ORDER BY Type, GroupId, ProductId, EffectiveDate
		
	
	
END
GO