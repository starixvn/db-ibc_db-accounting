ALTER FUNCTION [dbo].[f_GroupBettype] 
()
RETURNS @GroupBettype TABLE (Bettype SMALLINT, GroupTypeId SMALLINT)
AS 
/*
	Created: 20141016@Sophia
	Task :	Get grouped bettype for Sporting Solution and BetRadar
	DB:		DBAGE/bodb02, DBEXT/bodb02, DBACC/bodb02
 	Revisions: 
		- 20150414@Sophia: Support BetRadar

*/

BEGIN 
	-------- Grouped bettype for Sporting Solution

	INSERT INTO @GroupBettype (Bettype, GroupTypeId)
	VALUES (153, 153)
	INSERT INTO @GroupBettype (Bettype, GroupTypeId)
	VALUES (1308, 153)

	INSERT INTO @GroupBettype (Bettype, GroupTypeId)
	VALUES (154, 154)	
	INSERT INTO @GroupBettype (Bettype, GroupTypeId)
	VALUES (1311, 154)


	INSERT INTO @GroupBettype (Bettype, GroupTypeId)
	VALUES (155, 155)	
	INSERT INTO @GroupBettype (Bettype, GroupTypeId)
	VALUES (1316, 155)

	INSERT INTO @GroupBettype (Bettype, GroupTypeId)
	VALUES (156, 156)
	INSERT INTO @GroupBettype (Bettype, GroupTypeId)
	VALUES (1312, 156)
	
	INSERT INTO @GroupBettype (Bettype, GroupTypeId)
	VALUES (1, 1)
	INSERT INTO @GroupBettype (Bettype, GroupTypeId)
	VALUES (1303, 1)

	INSERT INTO @GroupBettype (Bettype, GroupTypeId)
	VALUES (2, 2)
	INSERT INTO @GroupBettype (Bettype, GroupTypeId)
	VALUES (1305, 2)

	INSERT INTO @GroupBettype (Bettype, GroupTypeId)
	VALUES (3, 3)
	INSERT INTO @GroupBettype (Bettype, GroupTypeId)
	VALUES (1306, 3)

	INSERT INTO @GroupBettype (Bettype, GroupTypeId)
	VALUES (20, 20)
	INSERT INTO @GroupBettype (Bettype, GroupTypeId)
	VALUES (1301, 20)


	-------- Grouped bettype for BetRadar
	INSERT INTO @GroupBettype (Bettype, GroupTypeId)
	VALUES (157, 2)

	INSERT INTO @GroupBettype (Bettype, GroupTypeId)
	VALUES (22, 22)
	INSERT INTO @GroupBettype (Bettype, GroupTypeId)
	VALUES (160, 22)
	
	INSERT INTO @GroupBettype (Bettype, GroupTypeId)
	VALUES (144, 144)
	INSERT INTO @GroupBettype (Bettype, GroupTypeId)
	VALUES (163, 144)

	INSERT INTO @GroupBettype (Bettype, GroupTypeId)
	VALUES (18, 18)
	INSERT INTO @GroupBettype (Bettype, GroupTypeId)
	VALUES (178, 18)

	INSERT INTO @GroupBettype (Bettype, GroupTypeId)
	VALUES (17, 17)
	INSERT INTO @GroupBettype (Bettype, GroupTypeId)
	VALUES (183, 17)

	INSERT INTO @GroupBettype (Bettype, GroupTypeId)
	VALUES (11, 11)
	INSERT INTO @GroupBettype (Bettype, GroupTypeId)
	VALUES (199, 11)


	RETURN
END

GO 
GRANT SELECT ON [dbo].[f_GroupBettype] TO [bodbDownlineNet]
GO 
GRANT SELECT ON [dbo].[f_GroupBettype] TO [bodbDownlineNetView]
GO 