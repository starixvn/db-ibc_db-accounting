CREATE PROCEDURE DBA_CheckDiskSpace
AS

Print '----------------START-----------------'
PRINT @@SERVERNAME
DECLARE  @MB_Free INT
CREATE TABLE #FreeSpace(Drive CHAR(1), MB_Free INT)

INSERT INTO #FreeSpace EXEC xp_fixeddrives

SELECT @MB_Free = MB_Free FROM #FreeSpace WHERE Drive = 'C'
-- Free Space on C drive Less than Threshold
IF (@MB_Free < 500)
BEGIN
    PRINT @MB_Free
    RAISERROR('C: OS and system database partition free space is now lower than 500MB ',16,1)
END

SELECT @MB_Free = MB_Free FROM #FreeSpace WHERE Drive = 'G'
-- Free Space on H drive Less than Threshold
IF (@MB_Free < 500)
BEGIN
    PRINT @MB_Free
    RAISERROR('G: Data partition free space is now lower than 500MB ',16,1)
END

SELECT @MB_Free = MB_Free FROM #FreeSpace WHERE Drive = 'H'
-- Free Space on H drive Less than Threshold
IF (@MB_Free < 500)
BEGIN
    PRINT @MB_Free
    RAISERROR('H: Data partition free space is now lower than 500MB ',16,1)
END

SELECT @MB_Free = MB_Free FROM #FreeSpace WHERE Drive = 'I'
-- Free Space on I drive Less than Threshold
IF (@MB_Free < 500)
BEGIN
    PRINT @MB_Free
    RAISERROR('I: Data partition free space is now lower than 500MB ',16,1)
END

SELECT @MB_Free = MB_Free FROM #FreeSpace WHERE Drive = 'R'
-- Free Space on I drive Less than Threshold
IF (@MB_Free < 500)
BEGIN
    PRINT @MB_Free
    RAISERROR('R: Data partition free space is now lower than 500MB ',16,1)
END

DROP TABLE #FreeSpace
Print '----------------END-----------------'

GO
