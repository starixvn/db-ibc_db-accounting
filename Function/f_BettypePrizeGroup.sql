/*<info serverAlias="DBAGE-bodb02,DBEXT-CustDB,DBACC-bodb02" executers="bodbAdminNet,bodbExtAccNet" isFunction="1" isNested="1"></info>*/
ALTER FUNCTION [dbo].[f_BettypePrizeGroup]()
/*
	Creator: Sophia
	Date: 20210603
	Task: Get list bettype of Contribution and Jackpot  [Redmine: #155697]
	DB: DBAGE-bodb02,DBEXT-CustDB, DBACC-bodb02
	
	Revision:
		- 20210603@Sophia: initial [Redmine: #155697]
		 
*/
RETURNS TABLE
RETURN

	SELECT 1699 AS Bettype, 'Prize'  AS BettypeGroup
	UNION ALL 
	SELECT 1906, 'Prize' 
	UNION ALL 
	SELECT 2199, 'Prize' 
	UNION ALL 
	SELECT 2399, 'Prize' 
	UNION ALL 
	SELECT 2999, 'Prize' 
	UNION ALL 
	SELECT 3150, 'Prize' 
	UNION ALL 
	SELECT 3899, 'Prize' 	
	UNION ALL 
	SELECT 4298, 'Prize' 
	UNION ALL 
	SELECT 4299, 'Prize' 
	UNION ALL 
	SELECT 4300, 'Prize' 
	
	UNION ALL 
	
	SELECT 1698, 'Contribution' 
	UNION ALL 
	SELECT 2198, 'Contribution' 
	UNION ALL 
	SELECT 2398, 'Contribution' 
	UNION ALL 
	SELECT 2998, 'Contribution' 
	UNION ALL 
	SELECT 3898, 'Contribution' 
	UNION ALL 
	SELECT 4297, 'Contribution' 
	
  
GO 

 