ALTER FUNCTION [dbo].[f_GroupBettype] 
()
RETURNS @GroupBettype TABLE (Bettype SMALLINT, GroupTypeId SMALLINT)
AS 
/*
	Created: 20141016@Sophia
	Task :	Get grouped bettype for tennis 
	DB:		DBAGE/bodb02, DBAGE/bodb_AGE
 	Revisions: 

*/

BEGIN 

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

	RETURN
END

GO 
GRANT SELECT ON [dbo].[f_GroupBettype] TO [bodbDownlineNet]
GO 
GRANT SELECT ON [dbo].[f_GroupBettype] TO [bodbDownlineNetView]
GO 