/*<info serverAlias="DBAGE-bodb02" executers="bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="1" isNested="1"></info>*/
USE [bodb02]
GO

ALTER FUNCTION [dbo].[U3_f_GetProductList]
(
)
RETURNS VARCHAR(MAX)
AS

/*
	Created by Percy
	Date: 2017-08-30
	DB: DBAGE.bodb02
	Task: NAP U3 - Get offer product Id list

	Revisions:
		- 20170830@Percy: Create new function [RedmineID: #76770]
*/

BEGIN
	DECLARE @ProductIds VARCHAR(MAX)

	SELECT  @ProductIds = '3,4,7,26'

	RETURN  @ProductIds
END
GO