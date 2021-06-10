/*<info serverAlias="DBAGE-bodb02,DBEXT-bodb02,DBACC-bodb02" selecters="bodbAdminNet,bodbLicenseeNet" isFunction="1" isNested="1"></info>*/
CREATE FUNCTION [dbo].[f_BettypePrizeGroup]()
RETURNS TABLE
AS

/*
	Creator: Sophia
	Date: 20210603
	Task: Get list bettype of Contribution and Jackpot
	DB: DBAGE-bodb02,DBEXT-bodb02,DBACC-bodb02
	
	Revision:
		- 20210603@Sophia: initial [Redmine: #155697]
		 
*/

RETURN
	SELECT
		CONVERT(INT, Bettype) AS Bettype
		,CONVERT(VARCHAR(50), 'Prize') AS BettypeGroup
	FROM (
		VALUES (1699), (1906), (2199), (2399), (2999), (3899), (4298), (4299), (4300)
	) AS t (Bettype)

	UNION ALL
	SELECT Bettype, 'Contribution'
	FROM (
		VALUES (1698), (2198), (2398), (2998), (3898), (4297)
	) t (Bettype)
	 