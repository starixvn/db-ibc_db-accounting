ALTER PROCEDURE [dbo].[Acc_ExecRep_09]
    @roleID INT,
    @IDs VARCHAR(MAX)
AS
  
SET NOCOUNT ON

IF (    SELECT COUNT(1)
        FROM sysobjects
        WHERE name in ('custsetting', 'custsetting3rd', 'custoverride', 'custoverride3rd')
            and type = 'u'
) < 4 RETURN

DECLARE @VALUE SMALLMONEY, @MIN SMALLMONEY, @MAX SMALLMONEY
SELECT @VALUE = 0.85, @MIN = 0, @MAX = 0.9

DECLARE @res AS TABLE (custid INT)
DECLARE @splitter CHAR(1), @string VARCHAR(MAX)

SELECT @splitter = ',', @string = @IDs

IF SUBSTRING (@string, LEN (@string), 1) <> @splitter
      SET @string= @string+@splitter

DECLARE @START INT, @word NVARCHAR(4000), @CHARINDEX INT, @i INT
SET @i=1
SET @START=1
SET @CHARINDEX= CHARINDEX( @splitter, @string, @START)
WHILE (@CHARINDEX <> 0)BEGIN
    SET @word= SUBSTRING( @string, @START, @CHARINDEX - @START)
    SET @START= @CHARINDEX +1
    SET @CHARINDEX= CHARINDEX( @splitter, @string, @START)
    INSERT INTO @res  VALUES(CAST(@word AS INT))
    SET @i=@i+1
END

IF @roleID = 1 -- member
BEGIN
    UPDATE custsetting WITH(rowlock,updlock)
    SET apositiontaking = @VALUE
        ,alivepositiontaking = CASE WHEN sporttype = 1 and bettype IN(1,3,7,8) THEN @VALUE ELSE 0 END
    WHERE custid in (SELECT custid FROM @res)
END

ELSE IF @roleID = 2 -- agent
BEGIN
    UPDATE custoverride WITH(rowlock, updlock)
    SET minpositiontaking = @MIN
        ,maxpositiontaking = @MAX
        ,minlivepositiontaking = @MIN
        ,maxlivepositiontaking = @MAX
    WHERE custid in (SELECT custid FROM @res)

    UPDATE custsetting WITH(rowlock,updlock)
    SET apositiontaking = @VALUE
        ,alivepositiontaking = CASE WHEN sporttype = 1 and bettype IN(1,3,7,8) THEN @VALUE ELSE 0 END
    WHERE custid in (SELECT custid FROM @res) 
END

ELSE IF @roleID = 3 -- master
BEGIN
    UPDATE custoverride WITH(rowlock, updlock)
    SET minpositiontaking = @MIN
        ,maxpositiontaking = @MAX
        ,minlivepositiontaking = @MIN
        ,maxlivepositiontaking = @MAX
    WHERE custid in (SELECT custid FROM @res)

    UPDATE custsetting WITH(rowlock,updlock)
    SET mpositiontaking = @VALUE
        ,mlivepositiontaking = CASE WHEN sporttype = 1 and bettype IN(1,3,7,8) THEN @VALUE ELSE 0 END
    WHERE custid in (SELECT custid FROM @res)
END

ELSE IF @roleID = 4    -- super
BEGIN
    UPDATE custoverride WITH(rowlock, updlock)
    SET minpositiontaking = @MIN
        ,maxpositiontaking = @MAX
        ,minlivepositiontaking = @MIN
        ,maxlivepositiontaking = @MAX
    WHERE custid in (SELECT custid FROM @res)

    UPDATE custsetting WITH(rowlock,updlock)
    SET spositiontaking = @VALUE
        ,mpositiontaking = @VALUE
        ,apositiontaking = @VALUE
        ,slivepositiontaking = CASE WHEN sporttype = 1 and bettype IN(1,3,7,8) THEN @VALUE ELSE 0 END
        ,mlivepositiontaking = CASE WHEN sporttype = 1 and bettype IN(1,3,7,8) THEN @VALUE ELSE 0 END
        ,alivepositiontaking = CASE WHEN sporttype = 1 and bettype IN(1,3,7,8) THEN @VALUE ELSE 0 END
    WHERE custid in (SELECT custid FROM @res)
END

/*
------------ SUPER ----------------
DECLARE @ids VARCHAR(MAX)
SELECT @ids = ''

SELECT @ids = @ids + CASE @ids WHEN '' THEN '' ELSE ',' END + CAST(custid AS VARCHAR(10))
FROM dep_custsuper WITH(nolock)

EXEC Acc_ExecRep_09 @roleID = 4, @ids = @ids -- super
GO
------------ /SUPER ----------------

------------ MASTER ----------------
DECLARE @ids VARCHAR(MAX)
SELECT @ids = ''

SELECT @ids = @ids + CASE @ids WHEN '' THEN '' ELSE ',' END + CAST(custid AS VARCHAR(10))
FROM custinfo WITH(nolock)
WHERE srecommend in (SELECT custid FROM dep_custsuper WITH(nolock))
    and roleid = 3

EXEC Acc_ExecRep_09 @roleID = 3, @ids = @ids -- master
GO
------------ /MASTER ----------------

------------ AGENT ----------------
CREATE TABLE #agentList (custid INT, done BIT)

INSERT INTO #agentList(custid, done)
SELECT custid, 0
FROM custinfo WITH(nolock)
WHERE srecommend in (SELECT custid FROM dep_custsuper WITH(nolock))
    and roleid = 2

DECLARE @ids VARCHAR(MAX), @rowcount INT

WHILE (1=1)
BEGIN
    SELECT @ids = ''

    UPDATE TOP (350) #agentList
    SET    done = 1
        ,@ids = @ids + CASE @ids WHEN '' THEN '' ELSE ',' END + CAST(custid AS VARCHAR(10))  
    WHERE done = 0

    SELECT @rowcount = @@ROWCOUNT

    EXEC Acc_ExecRep_09 @roleID = 2, @ids = @ids

    WAITFOR DELAY '00:00:01'
    IF @rowcount < 350 BREAK
END

DROP TABLE #agentList
------------ /AGENT ----------------
zzzzzzzzz
------------ MEMBER ----------------
CREATE TABLE #memberList (custid INT, done BIT)

INSERT INTO #memberList(custid, done)
SELECT custid, 0
FROM custinfo WITH(nolock)
WHERE srecommend in (SELECT custid FROM dep_custsuper WITH(nolock))
    and roleid = 1

DECLARE @ids VARCHAR(MAX), @rowcount INT

WHILE (1=1)
BEGIN
    SELECT @ids = ''

    UPDATE TOP (350) #memberList
    SET    done = 1
        ,@ids = @ids + CASE @ids WHEN '' THEN '' ELSE ',' END + CAST(custid AS VARCHAR(10))  
    WHERE done = 0

    SELECT @rowcount = @@ROWCOUNT

    EXEC Acc_ExecRep_09 @roleID = 1, @ids = @ids

    WAITFOR DELAY '00:00:01'
    IF @rowcount < 350 BREAK
END
GO

-- matches need to be re-calculated
SELECT DISTINCT matchid
FROM bettrans WITH(nolock)
WHERE custid in (SELECT custid FROM #memberList)  
    and winlostdate = @today -- '16 Apr 2012'
    and (bettype <= 30 OR bettype between 121 and 1000)
    and bettype not in (9,10,29)
    and statusid in (111,112,113)
    and apositiontaking <> 0.85       

-- MP/SP tickets that need to be re-calculated
SELECT refno
FROM bettrans WITH(nolock)
WHERE custid in (SELECT custid FROM #memberList)  
    and winlostdate = @today -- '16 Apr 2012'
    and bettype in (9,29)
    and statusid in (111,112,113)
    and apositiontaking <> 0.85       

-- outright events that need to be re-calculated
SELECT DISTINCT matchid
FROM bettrans WITH(nolock)
WHERE custid in (SELECT custid FROM #memberList)  
    and winlostdate = @today -- '16 Apr 2012'
    and bettype = 10
    and statusid in (111,112,113)
    and apositiontaking <> 0.85   

-- update tickets
UPDATE bettrans WITH(rowlock, updlock)
SET apositiontaking = 0.85
    ,tpositiontaking = 0.85
WHERE custid in (SELECT custid FROM #memberList)  
    and winlostdate >= @today -- '16 Apr 2012'
    and (bettype <= 30 OR bettype between 121 and 1000)
    and apositiontaking <> 0.85

--drop table #memberList
------------ /MEMBER ----------------
*/