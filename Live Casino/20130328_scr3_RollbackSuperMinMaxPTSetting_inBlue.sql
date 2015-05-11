SELECT custid
INTO #SuperIDs
FROM custInfo WITH (nolock)
WHERE username IN ('XXJ','XXK','XXO','XXP','XXQ','XXR','XXS','QD','QE','QF','QG','QJ','EA1','EA2','EA3','EA4','EA6','EA7','EA8','EA9','EAA','EAG','EAH','EAI','EAK','ET6','ET7','ET8','ET10')



-- step 1: set max/min PT, s4 = 0.7, n4 = 0.7
UPDATE custsettinggame WITH (rowlock,updlock)
SET spositiontaking = 0.7
WHERE custid in (SELECT custid FROM #SuperIDs)

UPDATE custoverridegame WITH (rowlock,updlock)
SET minpositiontaking = 0.7
WHERE custid in (SELECT custid FROM #SuperIDs)  


 
-- step 2: correct PT
SELECT
 '/* ' + CONVERT(VARCHAR(20),RowNo) + ' */ ' + sqltext
FROM (

SELECT
    ROW_NUMBER() OVER(ORDER BY custid ) AS RowNo,
    'EXEC Acc_ExecRep_09'
    + ' @srecommend =' + CONVERT(VARCHAR(20),custid)   
    + ' dddGO ' AS sqltext
FROM #SuperIDs
) t


-- step 3: s3 = s4 = 0.7
UPDATE custsettinggame WITH (rowlock,updlock)
SET spositiontaking = 0.7
WHERE custid in (SELECT c.custid
                FROM custInfo c WITH (nolock)
                INNER join CustSettingGame cs WITH (nolock) ON c.custid = cs.custid
                WHERE c.srecommend in (SELECT custid FROM #SuperIDs)
                and (cs.spositiontaking> 0.7
                and roleid = 3))
GO
DROP TABLE #SuperIDs    