ALTER PROCEDURE [dbo].[DBA_Import_Bet_Delete]	
	@IsMain bit
AS
if @@servername = 'DWDBG1S' and @IsMain = 0
	Return

if @@servername <> 'DWDBG1S' and @IsMain = 1
	Return

if @@servername = 'DWDBG1S' --Main DB
BEGIN
	DELETE FROM bettrans
	DELETE FROM bettransm
	DELETE FROM zzzbettrans
END
ELSE
BEGIN
	TRUNCATE TABLE bettrans
	TRUNCATE TABLE bettransm
	TRUNCATE TABLE zzzbettrans	
END
--Thien