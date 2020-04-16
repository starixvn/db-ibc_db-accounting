/*<info serverAlias="DBACC-BODB02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_DailyTxn_FinanceBettype_Sel]  
AS  
/*
Created by: Kiet Mai
Date: Nov 24 2010
Task: daily finance transaction	
DB: DBACC.BODB02 
	Revision:
		- 20101225@Lukas: Re-arrange bettype
		- 20120405@Hurri: Add bettype 23102 (P2P Pending) into condition
		- 20181105@Louis: Credit Collection Summary  [RedmineID: #98621]
		- 20200414@Sophia: Exclude BBIN bettype [Redmine: #131358]
*/ 
BEGIN
	SET NOCOUNT ON 

	SELECT typeid, typenamee 
	FROM bettype WITH(NOLOCK)
	WHERE	typeid > 20000
			AND typeID NOT IN (23001,23002,23101,23102,23201,23202, 21008, 21009) ---(112,113,114,117,118) --Transfer to Casino/Bingo/P2P
	UNION
	SELECT 0 AS typeid, 'Coll' AS typenamee  		
END