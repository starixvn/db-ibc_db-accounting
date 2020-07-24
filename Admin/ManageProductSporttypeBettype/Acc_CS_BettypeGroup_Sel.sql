/*<info serverAlias="DBPRO-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE  dbo.Acc_CS_BettypeGroup_Sel

AS
/*
Created: 20200328@Malcolm
Task :  NAP Manage CS_SportBettypeMatrix
DB: DBPRO/bodb02
Original:

	Revisions:
		- 20200328@Malcolm: NAP Manage CS_SportBettypeMatrix [Redmine: #131241]
		
*/
BEGIN
    SET NOCOUNT ON

    SELECT	typeid,
			typenamee
	FROM bettype WITH(NOLOCK)
	WHERE typeid < 19999


END

