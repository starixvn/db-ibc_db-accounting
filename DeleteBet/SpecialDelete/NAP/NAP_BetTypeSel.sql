ALTER PROCEDURE [NAP_BetTypeSel]
	@Mode SMALLINT = 0 
AS
/*
Created: 20130610@Elodie
Task : Select bettypes for NAP's special delete
DB: DBAGE/bodb02
Original: Acc_BetTypeSel

Revisions:    
    - 20130813@Elodie: Add new bettype Live Bacarat and Live Roulette (1103,1104)
    
Param's Explanation:
@Mode: 
	0: Special Delete
	1: Number game
	2: Early Kick-Off
	3: TicketListing
	4: Mix Parlay 
	5: Virtual sports
*/		
SET NOCOUNT ON
--type column: 0:Sport Book, 1:Number Game, 2:Virtual Sports, 3:Live Casino
CREATE TABLE #TmpBettype (typeid INT , bettypename NVARCHAR(100), type INT, liveindicator BIT)

------ sportbook
IF @Mode = 0
BEGIN
	
	INSERT INTO #TmpBettype (typeid, bettypename, type, liveindicator)
	SELECT	typeid , typenamee as bettypename, 0 as type, CASE WHEN typeid IN (1,2,3,5,7,8,12,13,15,24,25,26,27,28,124,125) THEN 1 ELSE 0 END AS liveindicator
	FROM	bettype WITH (NOLOCK)
	WHERE	typeid IN (1,2,3,4,5,6,7,8,12,13,14,15,16,20,21,24,25,26,27,28,30) 
			OR typeid between 121 and 999
END

IF @Mode = 2
BEGIN

	INSERT INTO #TmpBettype (typeid, bettypename, type, liveindicator)
	SELECT	typeid , typenamee as bettypename, 0 as type, CASE WHEN typeid IN (1,2,3,5,7,8,12,13,15,24,25,26,27,28) THEN 1 ELSE 0 END AS liveindicator
	FROM	bettype WITH (NOLOCK)
	WHERE	typeid IN (1,2,3,4,5,6,7,8,12,13,14,15,16,20,21,24,25,26,27,28,30) 
			OR typeid = 9 
			OR typeid = 29
			OR (typeid between 121 and 999 AND typeid NOT IN (124,125))
END

IF @Mode = 3
BEGIN

	INSERT INTO #TmpBettype (typeid, bettypename, type, liveindicator)
	SELECT	typeid , typenamee as bettypename, 0 as type, CASE WHEN typeid IN (1,2,3,5,7,8,12,13,15,24,25,26,27,28,124,125) THEN 1 ELSE 0 END AS liveindicator
	FROM	bettype WITH (NOLOCK)
	WHERE	typeid IN (1,2,3,4,5,6,7,8,12,13,14,15,16,20,21,24,25,26,27,28,30) 
			OR typeid = 9 OR typeid = 29
			OR typeid between 121 and 999
	
	INSERT INTO #TmpBettype (typeid, bettypename, type, liveindicator)
	SELECT	typeid , typenamee as bettypename, 3 as type, 0 as liveindicator
	FROM	bettype WITH (NOLOCK)
	WHERE	typeid between 1101 and 1199
END

IF @Mode = 4
BEGIN

	INSERT INTO #TmpBettype (typeid, bettypename, type, liveindicator)
	SELECT	typeid , typenamee as bettypename, 0 as type, CASE WHEN typeid IN (1,2,3,5,7,8,12,13,15,24,25,26,27,28) THEN 1 ELSE 0 END AS liveindicator
	FROM	bettype WITH (NOLOCK)
	WHERE	typeid IN (1,2,3,4,5,6,7,8,12,13,14,15,16,20,21,24,25,26,27,28,30) 
			OR (typeid between 121 and 999 AND typeid NOT IN (124,125))
END

----- number game
IF @Mode IN (1, 3)
BEGIN 
	INSERT INTO #TmpBettype (typeid, bettypename, type, liveindicator)
	SELECT	typeid , typenamee as bettypename, 1 as type, 0 as liveindicator
	FROM	bettype WITH (NOLOCK)
	WHERE	typeid in (81,82,83,84,86,88,90)
	UNION
	SELECT	typeid , typenamee as bettypename, 1 as type, 1 as liveindicator
	FROM	bettype WITH (NOLOCK)
	WHERE	typeid in (85,86,87,89,90)
END 
 
----- virtual sports
IF @Mode IN (5, 3)
BEGIN 
	INSERT INTO #TmpBettype (typeid, bettypename, type, liveindicator)
	SELECT	typeid , typenamee as bettypename, 2 as type, 0 as liveindicator
	FROM	bettype WITH (NOLOCK)
	WHERE	typeid between 1201 and 1299
END 

SELECT	* 
FROM	#TmpBettype
ORDER BY typeid



GO

GRANT EXECUTE ON [NAP_BetTypeSel] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [NAP_BetTypeSel] TO [vnteam] AS [dbo]
GO


