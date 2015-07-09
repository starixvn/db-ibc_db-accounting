 
 
 
/*
	Set 93% PT for super under INDO site and only for 3 currrencies (IN, IND, DDD)
*/



DECLARE @super TABLE (custid INT)

INSERT INTO @super
SELECT c.custid
FROM Customer c WITH(NOLOCK)
	INNER JOIN custsettinggame cg WITH(NOLOCK) ON c.custid = cg.custid
WHERE site = 'indo' AND currency IN (15,22,47)
AND roleid = 4 and username NOT IN ('STESTDDD')
AND cg.spositiontaking <> 0.93


-- 68 rows affected
UPDATE custsettinggame WITH(ROWLOCK,UPDLOCK)
SET spositiontaking = 0.93
WHERE custid IN (SELECT custid FROM @super)