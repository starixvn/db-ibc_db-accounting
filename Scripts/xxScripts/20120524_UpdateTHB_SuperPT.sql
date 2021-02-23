
DECLARE @THBsupers TABLE (custid INT)
INSERT INTO @THBsupers
          SELECT     1528421    ----    B10T
UNION ALL SELECT     1528422    ----    B11T
UNION ALL SELECT     1536432    ----    B12T
UNION ALL SELECT     1538057    ----    B13T
UNION ALL SELECT     1538175    ----    B14T
UNION ALL SELECT     1538183    ----    B15T
UNION ALL SELECT     1538997    ----    B16T
UNION ALL SELECT     1539009    ----    B17T
UNION ALL SELECT     1539693    ----    B18T
UNION ALL SELECT     1539698    ----    B19T
UNION ALL SELECT     1523261    ----    B1T
UNION ALL SELECT     1588140    ----    B24T
UNION ALL SELECT     1588145    ----    B25T
UNION ALL SELECT     2508822    ----    B26T
UNION ALL SELECT     2541779    ----    B27T
UNION ALL SELECT     1528410    ----    B2T
UNION ALL SELECT     1528413    ----    B4T
UNION ALL SELECT     1517951    ----    B5T
UNION ALL SELECT     1528414    ----    B6T
UNION ALL SELECT     1528418    ----    B7T
UNION ALL SELECT     1528419    ----    B8T
UNION ALL SELECT     1528420    ----    B9T
UNION ALL SELECT     1517030    ----    BT
UNION ALL SELECT     1537683    ----    KHT
UNION ALL SELECT     3642574    ----    KJT
UNION ALL SELECT     1539908    ----    MKTB
UNION ALL SELECT     2421122    ----    SABT
UNION ALL SELECT     1558372    ----    SBBT
UNION ALL SELECT     1584515    ----    SHHT
UNION ALL SELECT     1113450    ----    SM
UNION ALL SELECT     2388779    ----    STEB
UNION ALL SELECT     1563929    ----    STESTTHB


--- update PT Live Casino
UPDATE custsettinggame WITH(ROWLOCK,UPDLOCK)
SET spositiontaking = 0.8,
    mpositiontaking = 0.75,
    apositiontaking = 0.7
WHERE custid IN (SELECT custid FROM @THBsupers)

--- update PT Number Game non live
UPDATE custsetting3rd WITH(ROWLOCK,UPDLOCK)
SET spositiontaking = 0.8,
    mpositiontaking = 0.75,
    apositiontaking = 0.7
WHERE custid IN (SELECT custid FROM @THBsupers)
AND sporttype = 161 AND bettype IN (81,83,86,88)

-- update PT Number Game live
UPDATE custsetting3rd WITH(ROWLOCK,UPDLOCK)
SET slivepositiontaking = 0.8,
    mlivepositiontaking = 0.75,
    alivepositiontaking = 0.7
WHERE custid IN (SELECT custid FROM @THBsupers)
AND sporttype = 161 AND bettype IN (85,86,87,89,90)


-- update PT soccer & other sport non live
UPDATE custsetting WITH(ROWLOCK,UPDLOCK)
SET spositiontaking = 0.8,
    mpositiontaking = 0.75,
    apositiontaking = 0.7
WHERE custid IN (SELECT custid FROM @THBsupers)

-- update PT soccer live
UPDATE custsetting WITH(ROWLOCK,UPDLOCK)
SET slivepositiontaking = 0.8,
    mlivepositiontaking = 0.75,
    alivepositiontaking = 0.7
WHERE custid IN (SELECT custid FROM @THBsupers)
AND sporttype = 1 AND bettype IN (1,3,7,8)