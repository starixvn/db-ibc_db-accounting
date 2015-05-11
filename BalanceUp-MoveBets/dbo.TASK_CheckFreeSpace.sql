ALTER PROCEDURE [dbo].[TASK_CheckFreeSpace]
AS
BEGIN
	DECLARE @MB_Free INT 
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
	-- Free Space on G drive Less than Threshold 
	IF (@MB_Free < 10000)
	BEGIN
		PRINT @MB_Free
		RAISERROR('G: Data partition free space is now lower than 10GB ',16,1)
	END
	
	SELECT @MB_Free = MB_Free FROM #FreeSpace WHERE Drive = 'H' 
	-- (RS) Free Space on H drive Less than Threshold 
	IF (@MB_Free < 5000)
	BEGIN
		PRINT @MB_Free
		RAISERROR('H-RS: Data partition free space is now lower than 5GB ',16,1)
	END

	SELECT @MB_Free = MB_Free FROM #FreeSpace WHERE Drive = 'I' 
	-- (RS) Free Space on I drive Less than Threshold 
	IF (@MB_Free < 5000)
	BEGIN
		PRINT @MB_Free
		RAISERROR('I-RS: Data partition free space is now lower than 5GB ',16,1)
	END

	DROP TABLE #FreeSpace 

END
