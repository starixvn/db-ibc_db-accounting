/*<info serverAlias="DBAGE-bodb02,DBEXT-bodb02,DBACC-bodb02,DBTXN-bodb02" selecters="wsv_nap,wsv_lap" isFunction="1" isNested="1"></info>*/
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
		- 20210617@Sol: deploy function to DBTXN-bobd02 - [RedmineId : #156653]
		- 20220106@Evan: Add SG Jackpot - [Redmine: #166685]
		- 20230818@Lewis: Hotfix Dup Data - bettype = 8695 [RedmineID: #192923]	
		- 20240219@Lewis: Add Live22 PromotionPrize - bettype = 7698 [RedmineID: #201011]
		- 20240626@Lewis: Add FastSpin [RedmineID: #205740]	
		 
*/

RETURN
	SELECT
		CONVERT(INT, Bettype) AS Bettype
		,CONVERT(VARCHAR(50), 'Prize') AS BettypeGroup
	FROM (
		VALUES (1699), (1906), (2199), (2399), (2999), (3899), (4298), (4299), (4300), (4600), (8695), (2499), (7698), (11295)
	) AS t (Bettype)

	UNION ALL
	SELECT Bettype, 'Contribution'
	FROM (
		VALUES (1698), (2198), (2398), (2998), (3898), (4297), (4599)
	) t (Bettype)
	 