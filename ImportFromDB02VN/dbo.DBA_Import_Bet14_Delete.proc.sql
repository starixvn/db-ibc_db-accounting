ALTER PROCEDURE [dbo].[DBA_Import_Bet14_Delete]	
	@IsMain bit
AS
if @@servername = 'DWDBG1S' and @IsMain = 0
	Return

if @@servername <> 'DWDBG1S' and @IsMain = 1
	Return

if @@servername = 'DWDBG1S' --Main DB
BEGIN
	DELETE FROM Bettrans14
	DELETE FROM bettransm14
	DELETE FROM sum_winloss
END
ELSE
BEGIN
	TRUNCATE TABLE Bettrans14
	TRUNCATE TABLE bettransm14
	TRUNCATE TABLE sum_winloss	
END