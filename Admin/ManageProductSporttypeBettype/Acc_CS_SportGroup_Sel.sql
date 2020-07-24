/*<info serverAlias="DBPRO-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE  dbo.Acc_CS_SportGroup_Sel

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
	
	SELECT  t.ProductId,
		    t.SportTypeGroup,
			t.DisplaySport,
			CASE WHEN t.SportTypeGroup = 9 THEN 'Parlay' 
				 WHEN t.SportTypeGroup = 99 THEN 'Other Sports'
				 WHEN t.SportTypeGroup = 13 THEN 'Virtual Sports'
			ELSE STUFF(d.SportName,1,1,'') END AS DisplaySportName
	FROM CS_f_SportTypeGroup_OrderSel(1) t
		CROSS APPLY(
					SELECT N'\' + SportName 
					FROM dbo.Sports WITH(NOLOCK) 
					WHERE Sporttype IN (SELECT Val FROM dbo.strSplit(t.DisplaySport, ',')) FOR XML PATH('')
		) AS d(SportName)
END

