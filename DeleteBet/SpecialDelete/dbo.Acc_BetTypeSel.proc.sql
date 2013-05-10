ALTER PROCEDURE [dbo].[Acc_BetTypeSel]
	@Mode SMALLINT = 0 
AS
/*
Created: 20090121@[Phuc]
Task : Select bettypes for special delete
DB: DB053.bodb02
Original:

Revisions:    
    - 20090205@PhuongNguyen: Add new bet type Next Goal 
	- 20091230@Khoa: remove TypeNamee
	- 20100820@Lukas: Add new bet type: 1st Money Line (only for baseball) bettypeID = 21
	- 20101208@Johnson: Add some bettypes for EURO site include 13,24,25,26,27,28
	- 20110922@Tom: Add new bettypes 30, apply new bet type 1st correct score on Sport Books	
	- 20111005@Sophia: . Add parametter @Mode to separate bettype for Special delete or Number game or Early Kick-Off or Ticketlisting...
					   . Remove bettype = 22 Next Goal not to use anymore 
    - 20111202@Sophia: Add new range of Sportbook from 121 to 999
	- 20111214@Sophia: revise the sp 
	- 20111223@Lukas: Add more bettype system parlay 29 
	- 20120719@Sophia: Add betype 90 (Number Wheel) for Live and Pre game
	- 20120815@Elodie: Add bettype of Virtual sports
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
--type column: 0:Sport Book, 1:Number Game, 2:Virtual Sports
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
GRANT EXECUTE ON [dbo].[Acc_BetTypeSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_BetTypeSel] TO [VNTeam]